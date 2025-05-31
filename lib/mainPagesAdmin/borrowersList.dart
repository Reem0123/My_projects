import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libyyapp/firebase_api.dart';

class BorrowersListScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final DocumentSnapshot bookData;

  const BorrowersListScreen({
    Key? key,
    required this.bookId,
    required this.bookTitle,
    required this.bookData,
  }) : super(key: key);

  @override
  State<BorrowersListScreen> createState() => _BorrowersListScreenState();
}

class _BorrowersListScreenState extends State<BorrowersListScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late Stream<QuerySnapshot> _allBorrowersStream;
  late Stream<QuerySnapshot> _activeBorrowersStream;
  late Stream<QuerySnapshot> _pendingBorrowersStream; 
  late Stream<QuerySnapshot> _returnedBorrowersStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  
    _allBorrowersStream = FirebaseFirestore.instance
        .collection('BorrowRequestsList')
        .where('bookId', isEqualTo: widget.bookId)
        .orderBy('requestDate', descending: true)
        .snapshots();
    
    _activeBorrowersStream = FirebaseFirestore.instance
        .collection('BorrowRequestsList')
        .where('bookId', isEqualTo: widget.bookId)
        .where('status', isEqualTo: 'active')
        .orderBy('requestDate', descending: true)
        .snapshots();
    
    _pendingBorrowersStream = FirebaseFirestore.instance
        .collection('BorrowRequestsList')
        .where('bookId', isEqualTo: widget.bookId)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestDate', descending: true)
        .snapshots();
    
    _returnedBorrowersStream = FirebaseFirestore.instance
        .collection('BorrowRequestsList')
        .where('bookId', isEqualTo: widget.bookId)
        .where('status', isEqualTo: 'returned')
        .orderBy('returnedDate', descending: true)
        .snapshots();
        _scheduleReturnDateChecks();
  }

  

   void _scheduleReturnDateChecks() {
    Timer.periodic(Duration(minutes: 30), (timer) async {
      final now = DateTime.now();
      final activeRequests = await FirebaseFirestore.instance
          .collection('BorrowRequestsList')
          .where('bookId', isEqualTo: widget.bookId)
          .where('status', isEqualTo: 'active')
          .get();

      for (final request in activeRequests.docs) {
        final returnDate = (request['returnDate'] as Timestamp).toDate();
        if (returnDate.isBefore(now) ){
          
          if (!request['overdueNotificationSent']) {
            await _sendOverdueNotification(request);
          }
        }
      }
    });
  }

  
  Future<void> _sendOverdueNotification(QueryDocumentSnapshot request) async {
    try {
      final userId = request['userId'];
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc['fcmToken'] != null) {
        await FirebaseApi().sendReturnExpiredNotification(
          userToken: userDoc['fcmToken'],
          userId: userId,
          bookId: widget.bookId,
          bookTitle: widget.bookTitle,
        );

       
        await request.reference.update({
          'overdueNotificationSent': true,
          'isOverdue': true,
        });
      }
    } catch (e) {
      print(' فشل في إرسال إشعار التأخير: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approveBookReceiving(BuildContext context, String userId, String requestId, {String? waitingListId}) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(
          FirebaseFirestore.instance.collection('BorrowRequestsList').doc(requestId)
        );
        
        if (doc['status'] != 'pending') {
          throw Exception('حالة الطلب غير صالحة للتحديث');
        }
        
        transaction.update(doc.reference, {
          'status': 'active',
          'activationDate': FieldValue.serverTimestamp(),
          'returnDate': DateTime.now().add(Duration(days: 15)),
        });
      });

      if (waitingListId != null) {
        await _confirmWaitingUserResponse(waitingListId);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تأكيد استلام الكتاب بنجاح'))
        );
      }
    } catch (e) {
      print(' فشل تأكيد الاستلام: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التأكيد: ${e.toString()}'))
        );
      }
    }
  }

  Future<void> _rejectBookReceiving(BuildContext context, String userId, String requestId) async {
    try {
      
      final requestDoc = await FirebaseFirestore.instance
          .collection('BorrowRequestsList')
          .doc(requestId)
          .get();

      if (!requestDoc.exists || requestDoc['status'] != 'pending') {
        throw Exception('حالة الطلب غير صالحة للتحديث أو تم تحديثها مسبقاً');
      }

     
      await requestDoc.reference.update({
        'status': 'pending',
        'receivingExpired': true,
        'expiredAt': FieldValue.serverTimestamp(),
      });

      
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc['fcmToken'] != null) {
        await FirebaseApi().sendBookReceivingExpiredNotification(
          userToken: userDoc['fcmToken'],
          userId: userId,
          bookId: widget.bookId,
          bookTitle: widget.bookTitle,
        );
      }

     
      await _checkNextWaitingUser(widget.bookId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم رفض استلام الكتاب وتم تحريره للمستخدم التالي'))
        );
      }
    } catch (e) {
      print(' فشل رفض الاستلام: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في رفض الاستلام: ${e.toString()}'))
        );
      }
    }
  }

  Future<void> _returnBook(BuildContext context, String userId, String requestId) async {
    try {
      
      final String bookId = widget.bookId;
    
      await FirebaseFirestore.instance
          .collection('BorrowRequestsList')
          .doc(requestId)
          .update({
            'status': 'returned',
            'returnedDate': DateTime.now(),
          });

      
      await _checkNextWaitingUser(bookId);

    } catch (e) {
      print(' حدث خطأ أثناء إرجاع الكتاب: ${e.toString()}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إرجاع الكتاب: ${e.toString()}'))
        );
      }
    }
  }

  Future<void> _checkNextWaitingUser(String bookId) async {
    try {
      print(' بدء البحث عن المستخدم التالي في قائمة الانتظار...');
      
      
      final nextUserQuery = await FirebaseFirestore.instance
          .collection('WaitingList')
          .where('bookId', isEqualTo: bookId)
          .where('status', isEqualTo: 'waiting')
          .orderBy('requestDate', descending: false) 
          .limit(1)
          .get();

      if (nextUserQuery.docs.isNotEmpty) {
        final nextUserDoc = nextUserQuery.docs.first;
        final nextUserId = nextUserDoc['userId'];
        final nextRequestId = nextUserDoc.id;
        
       
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(nextUserId)
            .get();
            
        final nextUserToken = userDoc['fcmToken'] as String? ?? '';

        print('👤 تم العثور على المستخدم التالي: $nextUserId');

       
        await nextUserDoc.reference.update({
          'status': 'notified',
          'notificationTime': DateTime.now(),
          'expiryTime': DateTime.now().add(Duration(hours: 24)),
          'notified': true,
        });

        
        if (nextUserToken.isNotEmpty) {
          await FirebaseApi().sendBookAvailableNotification(
            userToken: nextUserToken,
            bookId: bookId,
            userId: nextUserId,
          );
          print(' تم إرسال إشعار للمستخدم التالي');
        }

       
        _scheduleReservationCheck(bookId, nextRequestId, nextUserId);
      } else {
        print(' لا يوجد مستخدمين في قائمة الانتظار، جاري تحرير الكتاب...');
        
       
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final bookDoc = await transaction.get(
            FirebaseFirestore.instance.collection('Books').doc(bookId)
          );
          
          if (bookDoc.exists) {
            final currentCopies = bookDoc['availableCopies'] ?? 0;
            final totalCopies = bookDoc['copies'] ?? 0;
            final newAvailableCopies = (currentCopies + 1).clamp(0, totalCopies);
            
            transaction.update(bookDoc.reference, {
              'availableCopies': newAvailableCopies,
              'status': newAvailableCopies > 0 ? 'متاح' : 'غير متاح',
            });
            
            print(' تم تحديث النسخ المتاحة إلى: $newAvailableCopies');
          }
        });
      }
    } catch (e) {
      print(' خطأ في _checkNextWaitingUser: $e');
      
    }
  }

  void _scheduleReservationCheck(String bookId, String waitingRequestId, String userId) async {
    try {
      final firebaseApi = FirebaseApi();
      
      
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
      final bookDoc = await FirebaseFirestore.instance.collection('Books').doc(bookId).get();
      
      if (!userDoc.exists || !bookDoc.exists) {
        throw Exception('المستخدم أو الكتاب غير موجود');
      }

      final userToken = userDoc['fcmToken'] as String? ?? '';
      final bookTitle = bookDoc['BookTitle'] as String? ?? '';

      
      Timer(Duration(hours: 24), () async {
        final requestDoc = await FirebaseFirestore.instance
            .collection('WaitingList')
            .doc(waitingRequestId)
            .get();

        if (requestDoc.exists && requestDoc['status'] == 'notified') {
          try {
            
            await requestDoc.reference.update({
              'status': 'expired',
              'expiredAt': DateTime.now(),
            });

            
            if (userToken.isNotEmpty) {
              await firebaseApi.sendReservationExpiredNotification(
                userToken: userToken,
                userId: userId,
                bookId: bookId,
                bookTitle: bookTitle,
              );
            }

            
            await _checkNextWaitingUser(bookId);
          } catch (e) {
            print(' خطأ في تحديث حالة انتهاء المهلة: $e');
          }
        }
      });
    } catch (e) {
      print(' خطأ في جدولة التحقق من انتهاء المهلة: $e');
    }
  }

  Future<void> _confirmWaitingUserResponse(String waitingListId) async {
    try {
      await FirebaseFirestore.instance
          .collection('WaitingList')
          .doc(waitingListId)
          .update({
            'status': 'responded',
            'respondedDate': DateTime.now(),
          });
      
      print('تم تحديث حالة المستخدم في قائمة الانتظار بنجاح');
    } catch (e) {
      print('حدث خطأ أثناء تحديث حالة المستخدم في قائمة الانتظار: $e');
      throw e;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  String _formatRemainingTime(DateTime returnDate) {
  final now = DateTime.now();
  final remaining = returnDate.difference(now);
  
  if (remaining.isNegative) {
    return 'متأخر';
  }
  
  final days = remaining.inDays;
  final hours = remaining.inHours.remainder(24);
  final minutes = remaining.inMinutes.remainder(60);
  
  return '${days} أيام ${hours} ساعات ${minutes} دقائق';
}

 Widget _buildBorrowerCard(QueryDocumentSnapshot borrower) {
  final data = borrower.data() as Map<String, dynamic>;
  final userEmail = data['userEmail'] as String? ?? 'غير متوفر';
  final userId = data['userId'] as String? ?? '';
  final requestId = borrower.id;
  final status = data['status'] as String? ?? 'active';
  final isActive = status == 'active';
  final isPending = status == 'pending';
  final isReturned = status == 'returned';
  final isReceivingExpired = data['receivingExpired'] as bool? ?? false;
  final isOverdue = data['isOverdue'] as bool? ?? false;

  final requestDate = data['requestDate'] != null 
      ? (data['requestDate'] as Timestamp).toDate().toString().split(' ')[0]
      : 'غير محدد';
  
  final returnDate = data['returnDate'] != null 
      ? (data['returnDate'] as Timestamp).toDate()
      : null;
  
  final formattedReturnDate = returnDate != null 
      ? returnDate.toString().split(' ')[0]
      : 'غير محدد';
  
  final returnedDate = data['returnedDate'] != null 
      ? (data['returnedDate'] as Timestamp).toDate()
      : null;

  final formattedReturnedDate = returnedDate != null
      ? returnedDate.toString().split(' ')[0]
      : null;

  final expiryDate = data['expiryDate'] != null 
    ? (data['expiryDate'] as Timestamp).toDate()
    : null;

  final expiredAt = data['expiredAt'] != null
      ? (data['expiredAt'] as Timestamp).toDate().toString().split(' ')[0]
      : null;

  
  Duration? lateDuration;
  if (isReturned && returnDate != null && returnedDate != null && returnedDate.isAfter(returnDate)) {
    lateDuration = returnedDate.difference(returnDate);
  }

  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 3,
    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.white, 
            isReceivingExpired
              ? const Color(0xFFFFEBEE)
              : isPending 
                ? const Color(0xFFFFF8E1)
                : isActive 
                  ? (isOverdue ? const Color(0xFFFFF0F0) : const Color(0xFFF5F9FF))
                  : const Color(0xFFF0F7F4)
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isReceivingExpired
                          ? Icons.timer_off
                          : isPending 
                            ? Icons.hourglass_empty
                            : isActive 
                              ? Icons.person 
                              : Icons.check_circle_outline,
                        color: isReceivingExpired
                          ? Colors.red
                          : isPending 
                            ? Colors.orange
                            : isActive 
                              ? (isOverdue ? Colors.red : const Color(0xFF3E7BFA))
                              : Colors.green,
                        size: 20
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isReceivingExpired
                      ? Colors.red.withOpacity(0.1)
                      : isPending 
                        ? Colors.orange.withOpacity(0.1)
                        : isActive 
                          ? (isOverdue ? Colors.red.withOpacity(0.1) : const Color(0xFF3E7BFA).withOpacity(0.1))
                          : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isReceivingExpired
                      ? 'منتهية'
                      : isPending 
                        ? 'معلق'
                        : isActive 
                          ? (isOverdue ? 'متأخر' : 'نشط')
                          : 'تم الإرجاع',
                    style: TextStyle(
                      fontSize: 12,
                      color: isReceivingExpired
                        ? Colors.red
                        : isPending 
                          ? Colors.orange
                          : isActive 
                            ? (isOverdue ? Colors.red : const Color(0xFF3E7BFA))
                            : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isReceivingExpired
                  ? const Color(0xFFFFEBEE)
                  : isPending 
                    ? const Color(0xFFFFF8E1)
                    : isActive
                      ? (isOverdue ? const Color(0xFFFFF0F0) : const Color(0xFFEDF3FF))
                      : const Color(0xFFEDF7ED),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: isReceivingExpired
                          ? Colors.red
                          : isPending 
                            ? Colors.orange
                            : isActive 
                              ? (isOverdue ? Colors.red : const Color(0xFF3E7BFA))
                              : Colors.green,
                        size: 18
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تاريخ الطلب: $requestDate',
                        style: const TextStyle(
                          fontSize: 14, 
                          color: Color(0xFF4A4E69),
                        ),
                      ),
                    ],
                  ),

                  if (isReceivingExpired && expiredAt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_off,
                          color: Colors.red,
                          size: 18
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'انتهت مهلة الاستلام في: $expiredAt',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (isPending && expiryDate != null) ...[
                    const SizedBox(height: 8),
                    StreamBuilder<DateTime>(
                      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                      builder: (context, snapshot) {
                        final now = DateTime.now();
                        final bool isExpired = !expiryDate.isAfter(now);

                        
                        if (isExpired && !isReceivingExpired) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _rejectBookReceiving(context, userId, requestId);
                          });
                        }

                        return Row(
                          children: [
                            Icon(
                              Icons.timer,
                              color: isExpired ? Colors.red : Colors.orange,
                              size: 18
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isExpired 
                                  ? 'انتهت مهلة الاستلام'
                                  : 'الوقت المتبقي: ${_formatDuration(expiryDate.difference(now))}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isExpired ? Colors.red : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  
                  if (isActive || isReturned) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          color: isActive 
                            ? (isOverdue ? Colors.red : const Color(0xFF3E7BFA))
                            : Colors.green,
                          size: 18
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'تاريخ الإرجاع المتوقع: $formattedReturnDate',
                          style: TextStyle(
                            fontSize: 14,
                            color: isActive 
                              ? (isOverdue ? Colors.red : const Color(0xFF4A4E69))
                              : const Color(0xFF4A4E69),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (isActive && returnDate != null) ...[
                    const SizedBox(height: 8),
                    StreamBuilder<DateTime>(
                      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                      builder: (context, snapshot) {
                        final now = DateTime.now();
                        final bool isOverdue = returnDate.isBefore(now);

                        return Row(
                          children: [
                            Icon(
                              Icons.timer,
                              color: isOverdue ? Colors.red : const Color(0xFF3E7BFA),
                              size: 18
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOverdue 
                                  ? 'متأخر عن الإرجاع'
                                  : 'الوقت المتبقي: ${_formatRemainingTime(returnDate)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isOverdue ? Colors.red : const Color(0xFF3E7BFA),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  
                  if (formattedReturnedDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'تاريخ الإرجاع الفعلي: $formattedReturnedDate',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (isReturned && lateDuration != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_off, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'تم الإرجاع متأخراً بمقدار: ${lateDuration.inDays} أيام و ${lateDuration.inHours.remainder(24)} ساعات',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (isActive && isOverdue) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'تأخر في الإرجاع',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            if (isActive) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: const Text('تأكيد إرجاع الكتاب'),
                          content: const Text('هل تريد تأكيد إرجاع الكتاب؟'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('إلغاء', 
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await _returnBook(context, userId, requestId);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF139799),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('تأكيد'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF139799),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.book_online),
                  label: const Text(
                    'إرجاع الكتاب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
            
            if (isPending && !isReceivingExpired) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: const Text('تأكيد استلام الكتاب'),
                          content: const Text('هل تريد تأكيد استلام الكتاب؟'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('إلغاء', 
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await _approveBookReceiving(context, userId, requestId);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('تأكيد الاستلام'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('تأكيد الاستلام'),
                ),
              ),
            ],
            
            if (isReceivingExpired) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'انتهت مهلة استلام الكتاب ولم يتم تأكيد الاستلام',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

  Widget _buildBorrowersList(Stream<QuerySnapshot> borrowersStream) {
    return StreamBuilder<QuerySnapshot>(
      stream: borrowersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('حدث خطأ: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final borrowers = snapshot.data?.docs ?? [];

        if (borrowers.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد استعارات في هذا التصنيف',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: borrowers.length,
          itemBuilder: (context, index) {
            return _buildBorrowerCard(borrowers[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "سجل استعارات كتاب ${widget.bookTitle}",
            style: const TextStyle(
              color: Color(0xFF139799),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Color(0xFF139799)),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF139799),
            labelColor: const Color(0xFF139799),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'الكل'),
              Tab(text: 'المعلقة'),
              Tab(text: 'النشطة'),
              Tab(text: 'المرجعة'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBorrowersList(_allBorrowersStream),
            _buildBorrowersList(_pendingBorrowersStream),
            _buildBorrowersList(_activeBorrowersStream),
            _buildBorrowersList(_returnedBorrowersStream),
          ],
        ),
      ),
    );
  }
}