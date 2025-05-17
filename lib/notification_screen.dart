import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:libyyapp/mainPagesReader/showpage.dart';
import 'dart:async';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<DocumentSnapshot> _bookAvailableNotifications = [];
  final List<DocumentSnapshot> _newBookNotifications = [];
  final List<DocumentSnapshot> _newNewsNotifications = [];
  final List<DocumentSnapshot> _receivingExpiryNotifications = [];
  final List<DocumentSnapshot> _returnExpiryNotifications = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  Timer? _timer;
  final Map<String, String> _waitingListStatuses = {};
  final Map<String, dynamic> _waitingListResponseDates = {};
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _setupNotificationsStream().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _markNotificationsAsRead();
        }
      });
    });
    _startTimer();
  }

  Future<void> _setupNotificationsStream() async {
    if (currentUserId == null) return;

    setState(() => _isLoading = true);
    await _fetchWaitingListData();

    _notificationsSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _bookAvailableNotifications.clear();
              _newBookNotifications.clear();
              _newNewsNotifications.clear();
              _receivingExpiryNotifications.clear();

              for (var doc in snapshot.docs) {
                final data = doc.data();
                final type = data['type'] as String?;
                
                if (type == 'book_available') {
                  _bookAvailableNotifications.add(doc);
                } else if (type == 'new_book') {
                  _newBookNotifications.add(doc);
                } else if (type == 'new_news') {
                  _newNewsNotifications.add(doc);
                } else if (type == 'return_expired') {
                  _returnExpiryNotifications.add(doc);
                }else if (type == 'book_receiving_expired') { 
                  _receivingExpiryNotifications.add(doc);
                }
              }
              
              _isLoading = false;
            });
          }
        });
  }

  Future<void> _fetchWaitingListData() async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

   
    final querySnapshot = await FirebaseFirestore.instance
        .collection('WaitingList')
        .where('userId', isEqualTo: userId)
        .get();

    final statuses = <String, String>{};
    final responseDates = <String, dynamic>{};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final bookId = data['bookId'] as String?;
      final status = data['status'] as String?;
      final responseDate = data['responseDate'];
      
      if (bookId != null && status != null) {
        statuses[bookId] = status;
        if (responseDate != null) {
          responseDates[bookId] = responseDate;
        }
      }
    }

    if (mounted) {
      setState(() {
        _waitingListStatuses.clear();
        _waitingListStatuses.addAll(statuses);
        
        _waitingListResponseDates.clear();
        _waitingListResponseDates.addAll(responseDates);
      });
      print(' تم تحديث بيانات قائمة الانتظار: ${_waitingListStatuses}');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching waiting list data: $e');
    }
  }
}

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _markNotificationsAsRead() async {
    try {
      final allNotifications = [
        ..._bookAvailableNotifications,
        ..._newBookNotifications,
        ..._receivingExpiryNotifications,
        ..._newNewsNotifications
      ];

      if (allNotifications.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      
      for (var doc in allNotifications) {
        if (doc.exists && (doc.data() as Map<String, dynamic>)['isRead'] == false) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      
      await batch.commit();
      print(' تم تحديث جميع الإشعارات كمقروءة');
    } catch (e) {
      print(' فشل في تحديث الإشعارات: $e');
    }
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "الإشعارات",
            style: TextStyle(
              color: Color(0xFF139799),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Color(0xFF139799)),
        
      ),
      body: _buildAllNotifications(),
      ),
    );
  }

  Widget _buildAllNotifications() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF139799)),
      );
    }

    if (_bookAvailableNotifications.isEmpty && 
        _newBookNotifications.isEmpty && 
        _newNewsNotifications.isEmpty &&
        _receivingExpiryNotifications.isEmpty) { 
      return _buildEmptyNotifications();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_newBookNotifications.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              "كتب جديدة",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
          ),
          ..._newBookNotifications.map((doc) => NewBookNotificationCard(
            doc: doc,
            onViewDetails: (String bookId) => _navigateToBookDetails(bookId),
          )),
          const SizedBox(height: 24),
        ],
        if (_bookAvailableNotifications.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              "كتب متاحة",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
          ),
          ..._bookAvailableNotifications.map((doc) => BookAvailableNotificationCard(
            doc: doc,
            onBorrow: (String bookId) => _navigateToBookDetails(bookId),
            refreshCallback: _refreshNotifications,
            waitingListStatus: _waitingListStatuses[doc['bookId']] ?? 'notified',
            responseDate: _waitingListResponseDates[doc['bookId']],
          )),
          const SizedBox(height: 24),
        ],

        if (_returnExpiryNotifications.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                "انتهاء مدة الإرجاع",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
              ),
            ),),
            ..._returnExpiryNotifications.map((doc) => ReturnExpiryNotificationCard(
              doc: doc,
              onViewDetails: (String bookId) => _navigateToBookDetails(bookId),
            )),
            const SizedBox(height: 24),
          ],

        if (_receivingExpiryNotifications.isNotEmpty) ...[ 
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              "انتهاء مهلةاستلام الكتاب",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
          ),
          ..._receivingExpiryNotifications.map((doc) => ExpiryNotificationCard(
            doc: doc,
            onViewDetails: (String bookId) => _navigateToBookDetails(bookId),
          )),
          const SizedBox(height: 24),
        ],

        if (_newNewsNotifications.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              "أخبار جديدة",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
          ),
          ..._newNewsNotifications.map((doc) => NewNewsNotificationCard(
            doc: doc,
          )),
        ],
      ],
    );
  }

  void _refreshNotifications() {
  if (mounted) {
    setState(() {
      _isLoading = true;
    });
    _fetchWaitingListData().then((_) {
      _setupNotificationsStream().then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          print(' تم تحديث الإشعارات بنجاح');
        }
      });
    });
  }
}

  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "لا توجد إشعارات حالياً",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _navigateToBookDetails(String bookId) async {
  try {
    DocumentSnapshot bookSnapshot = await FirebaseFirestore.instance
        .collection('Books')
        .doc(bookId)
        .get();

    if (bookSnapshot.exists) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Books')
          .where(FieldPath.documentId, isEqualTo: bookId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsScreen(
              bookData: querySnapshot.docs.first,
            ),
          ),
        );
        
       
        if (result == true) {
          _refreshNotifications();
        }
      } else {
        throw Exception('الكتاب غير موجود');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكتاب غير موجود')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
    );
  }
}
}

class ExpiryNotificationCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Function(String bookId) onViewDetails;

  const ExpiryNotificationCard({
    super.key,
    required this.doc,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'إشعار انتهاء المهلة';
    final body = data['body'] ?? 'انتهت مهلة حجز الكتاب';
    final timestamp = data['timestamp'];
    final bookId = data['bookId'] ?? '';
    final bookData = data['bookData'] as Map<String, dynamic>?;
    final bookTitle = bookData?['title'] ?? 'الكتاب';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.white, Color(0xFFFFF1F1)],
          ),
          border: Border.all(
            color: const Color(0xFFFF3B30).withOpacity(0.2),
            width: 1,
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.timer_off_outlined,
                            color: Color(0xFFFF3B30),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatNotificationTime(timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF3B30),
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
                  color: const Color(0xFFFFEBEE)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_outlined,
                          color: Color(0xFFFF3B30),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            body.isNotEmpty ? body : 'انتهت مهلة حجز كتاب "$bookTitle"',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A4E69),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'يمكنك تقديم طلب استعارة جديد إذا كان الكتاب لا يزال متاحاً',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A4E69),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onViewDetails(bookId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text(
                    'عرض تفاصيل الكتاب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatNotificationTime(dynamic timestamp) {
    if (timestamp == null) return 'غير محدد';

    DateTime notificationTime;
    if (timestamp is Timestamp) {
      notificationTime = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        notificationTime = DateTime.parse(timestamp);
      } catch (e) {
        return 'غير محدد';
      }
    } else {
      return 'غير محدد';
    }

    final now = DateTime.now();
    final difference = now.difference(notificationTime);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }
}

class ReturnExpiryNotificationCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Function(String bookId) onViewDetails;

  const ReturnExpiryNotificationCard({
    super.key,
    required this.doc,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'إشعار انتهاء المدة';
    final body = data['body'] ?? 'انتهت مدة إرجاع الكتاب';
    final timestamp = data['timestamp'];
    final bookId = data['bookId'] ?? '';
    final bookData = data['bookData'] as Map<String, dynamic>?;
    final bookTitle = bookData?['title'] ?? 'الكتاب';
    final daysLate = data['daysLate'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.white, Color(0xFFFFF1F1)],
          ),
          border: Border.all(
            color: const Color(0xFFFF3B30).withOpacity(0.3),
            width: 1,
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFF3B30),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatNotificationTime(timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF3B30),
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
                  color: const Color(0xFFFFEBEE)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_off_outlined,
                          color: Color(0xFFFF3B30),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            body.isNotEmpty ? body : 'انتهت مدة استعارة كتاب "$bookTitle"',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A4E69),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      daysLate > 0 
                          ? 'متأخر بمقدار $daysLate ${daysLate == 1 ? 'يوم' : 'أيام'}'
                          : 'يجب إرجاع الكتاب فوراً',
                      style: TextStyle(
                        fontSize: 14,
                        color: daysLate > 0 ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onViewDetails(bookId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.book_outlined),
                  label: const Text(
                    'عرض تفاصيل الكتاب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatNotificationTime(dynamic timestamp) {
    if (timestamp == null) return 'غير محدد';

    DateTime notificationTime;
    if (timestamp is Timestamp) {
      notificationTime = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        notificationTime = DateTime.parse(timestamp);
      } catch (e) {
        return 'غير محدد';
      }
    } else {
      return 'غير محدد';
    }

    final now = DateTime.now();
    final difference = now.difference(notificationTime);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }
}


class BookAvailableNotificationCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Function(String bookId) onBorrow;
  final VoidCallback refreshCallback;
  final String waitingListStatus;
  final dynamic responseDate;

  const BookAvailableNotificationCard({
    super.key,
    required this.doc,
    required this.onBorrow,
    required this.refreshCallback,
    required this.waitingListStatus,
    this.responseDate,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'إشعار';
    final body = data['body'] ?? '';
    final timestamp = data['timestamp'];
    final bookId = data['bookId'] ?? '';
    final bookData = data['bookData'] as Map<String, dynamic>?;
    final bookTitle = bookData?['title'] ?? 'كتاب';

    final hasResponded = waitingListStatus == 'responded';
    final isExpired = waitingListStatus == 'expired';

    final notificationTime = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();
    final expiryTime = notificationTime.add(const Duration(hours: 24));

    final remainingPercentage = _getTimeRemainingPercentage(expiryTime);
    final timeRemainingColor = _getColorForTimeRemaining(expiryTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: hasResponded 
                ? [Colors.white, const Color(0xFFEFFCF6)] 
                : isExpired
                  ? [Colors.white, const Color(0xFFFFF1F1)]
                  : [Colors.white, const Color(0xFFF5F9FF)],
          ),
          border: Border.all(
            color: hasResponded 
                ? const Color(0xFF34C759).withOpacity(0.2)
                : isExpired
                  ? const Color(0xFFFF3B30).withOpacity(0.2)
                  : const Color(0xFF139799).withOpacity(0.2),
            width: 1,
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: hasResponded
                                ? const Color(0xFF34C759).withOpacity(0.1)
                                : isExpired
                                  ? const Color(0xFFFF3B30).withOpacity(0.1)
                                  : const Color(0xFF139799).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            hasResponded 
                                ? Icons.check_circle 
                                : isExpired
                                  ? Icons.timer_off
                                  : Icons.check_circle_outlined,
                            color: hasResponded 
                                ? const Color(0xFF34C759)
                                : isExpired
                                  ? const Color(0xFFFF3B30)
                                  : const Color(0xFF139799),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hasResponded 
                                ? "تم الاستجابة للإشعار"
                                : isExpired
                                  ? "انتهت المهلة للاستجابة"
                                  : title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasResponded
                          ? const Color(0xFF34C759).withOpacity(0.1)
                          : isExpired
                            ? const Color(0xFFFF3B30).withOpacity(0.1)
                            : const Color(0xFF3E7BFA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatNotificationTime(timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: hasResponded 
                            ? const Color(0xFF34C759)
                            : isExpired
                              ? const Color(0xFFFF3B30)
                              : const Color(0xFF3E7BFA),
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
                  color: hasResponded 
                      ? const Color(0xFFEFFCF6)
                      : isExpired
                        ? const Color(0xFFFFF1F1)
                        : const Color(0xFFEDF3FF)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.book_outlined,
                          color: hasResponded 
                              ? const Color(0xFF34C759)
                              : isExpired
                                ? const Color(0xFFFF3B30)
                                : const Color(0xFF3E7BFA),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hasResponded 
                                ? 'تم الاستجابة لطلب استعارة كتاب "$bookTitle" بنجاح.'
                                : isExpired
                                  ? 'انتهت مهلة الاستجابة لطلب استعارة كتاب "$bookTitle".'
                                  : (body.isNotEmpty 
                                      ? body 
                                      : 'الكتاب "$bookTitle" متاح لك الآن. يرجى تقديم طلب استعارة قبل انتهاء المهلة.'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A4E69),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (!hasResponded && !isExpired) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined, 
                                color: timeRemainingColor, 
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'الوقت المتبقي:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatRemainingTime(expiryTime),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: timeRemainingColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: remainingPercentage,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(timeRemainingColor),
                          minHeight: 6,
                        ),
                      ),
                    ] else if (hasResponded) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_available_outlined,
                            color: Color(0xFF34C759),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'تمت الاستجابة: ${_formatResponseDate(responseDate)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A4E69),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ] else if (isExpired) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer_off_outlined,
                            color: Color(0xFFFF3B30),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'انتهت المهلة: ${_formatNotificationTime(expiryTime)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A4E69),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    onBorrow(bookId);
                    refreshCallback();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasResponded 
                        ? const Color(0xFF34C759)
                        : isExpired
                          ? const Color(0xFFFF3B30)
                          : const Color(0xFF139799),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  icon: Icon(
                    hasResponded 
                        ? Icons.visibility_outlined 
                        : isExpired
                          ? Icons.watch_later_outlined
                          : Icons.menu_book),
                  label: Text(
                    hasResponded 
                        ? 'عرض تفاصيل الكتاب'
                        : isExpired
                          ? 'انتهت المهلة'
                          : 'تقديم طلب استعارة',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatResponseDate(dynamic date) {
    if (date == null) return 'غير محدد';
    
    try {
      if (date is Timestamp) {
        final responseTime = date.toDate();
        return '${responseTime.day}/${responseTime.month}/${responseTime.year} - ${responseTime.hour}:${responseTime.minute.toString().padLeft(2, '0')}';
      } else if (date is String) {
        return date;
      } else if (date is DateTime) {
        return '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return 'غير محدد';
      }
    } catch (e) {
      return 'غير محدد';
    }
  }

  static String _formatNotificationTime(dynamic timestamp) {
    if (timestamp == null) return 'غير محدد';

    DateTime notificationTime;
    if (timestamp is Timestamp) {
      notificationTime = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        notificationTime = DateTime.parse(timestamp);
      } catch (e) {
        return 'غير محدد';
      }
    } else {
      return 'غير محدد';
    }

    final now = DateTime.now();
    final difference = now.difference(notificationTime);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }

  static String _formatRemainingTime(DateTime expiryDateTime) {
    final now = DateTime.now();
    final remaining = expiryDateTime.difference(now);

    if (remaining.isNegative) {
      return 'انتهت المهلة';
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (days > 0) {
      return '${days} يوم ${hours} ساعة';
    } else if (hours > 0) {
      return '${hours} ساعة ${minutes} دقيقة';
    } else if (minutes > 0) {
      return '${minutes} دقيقة ${seconds} ثانية';
    } else {
      return '${seconds} ثانية';
    }
  }

  static double _getTimeRemainingPercentage(DateTime expiryDateTime) {
    final now = DateTime.now();
    final remaining = expiryDateTime.difference(now);
    const totalWaitingPeriod = 24 * 60 * 60;

    if (remaining.isNegative) return 0;
    return remaining.inSeconds / totalWaitingPeriod;
  }

  static Color _getColorForTimeRemaining(DateTime expiryDateTime) {
    final now = DateTime.now();
    final remaining = expiryDateTime.difference(now);

    if (remaining.isNegative) {
      return Colors.red;
    } else if (remaining.inHours < 4) {
      return Colors.red;
    } else if (remaining.inHours < 12) {
      return Colors.orange;
    } else {
      return const Color(0xFF139799);
    }
  }
}
class NewBookNotificationCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final Function(String bookId) onViewDetails;

  const NewBookNotificationCard({
    super.key,
    required this.doc,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'إشعار';
    final body = data['body'] ?? '';
    final timestamp = data['timestamp'];
    final bookId = data['bookId'] ?? '';
    final bookData = data['bookData'] as Map<String, dynamic>?;

    final bookTitle = bookData?['title'] ?? 'كتاب جديد';
    final bookAuthor = bookData?['author'] ?? 'مؤلف غير معروف';
    final bookCover = bookData?['coverImage'] ?? '';
    final categories = bookData?['categories'] != null
        ? List<String>.from(bookData!['categories'])
        : <String>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.white, Color(0xFFF5F9FF)],
          ),
          border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.2),
            width: 1,
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.new_releases_outlined,
                            color: Color(0xFF6C63FF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatNotificationTime(timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C63FF),
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
                  color: const Color(0xFFF3F0FF)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bookCover.isNotEmpty)
                      Center(
                        child: Container(
                          height: 120,
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            image: DecorationImage(
                              image: NetworkImage(bookCover),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (bookCover.isNotEmpty) const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        const Icon(
                          Icons.book_outlined,
                          color: Color(0xFF6C63FF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            body.isNotEmpty
                                ? body
                                : 'تمت إضافة "$bookTitle" إلى المكتبة',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A4E69),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: Color(0xFF6C63FF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'المؤلف: $bookAuthor',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4A4E69),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (categories.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            color: Color(0xFF6C63FF),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'التصنيفات: ${categories.join('، ')}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4A4E69),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onViewDetails(bookId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text(
                    'عرض تفاصيل الكتاب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatNotificationTime(dynamic timestamp) {
    if (timestamp == null) return 'غير محدد';

    DateTime notificationTime;
    if (timestamp is Timestamp) {
      notificationTime = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        notificationTime = DateTime.parse(timestamp);
      } catch (e) {
        return 'غير محدد';
      }
    } else {
      return 'غير محدد';
    }

    final now = DateTime.now();
    final difference = now.difference(notificationTime);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }
}

class NewNewsNotificationCard extends StatelessWidget {
  final DocumentSnapshot doc;

  const NewNewsNotificationCard({
    super.key,
    required this.doc,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'إشعار';
    
    final timestamp = data['timestamp'];
    final newsTitle = data['newsTitle'] ?? 'خبر جديد';
    final newsContent = data['newsContent'] ?? '';
    final imageUrl = data['imageUrl'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.white, Color(0xFFF5F9FF)],
          ),
          border: Border.all(
            color: const Color(0xFF139799).withOpacity(0.2),
            width: 1,
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF139799).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.new_releases_outlined,
                            color: Color(0xFF139799),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF139799).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatNotificationTime(timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF139799),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              
              if (imageUrl.isNotEmpty) const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFEDF3FF)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newsTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      newsContent,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A4E69),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatNotificationTime(dynamic timestamp) {
    if (timestamp == null) return 'غير محدد';

    DateTime notificationTime;
    if (timestamp is Timestamp) {
      notificationTime = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        notificationTime = DateTime.parse(timestamp);
      } catch (e) {
        return 'غير محدد';
      }
    } else {
      return 'غير محدد';
    }

    final now = DateTime.now();
    final difference = now.difference(notificationTime);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }
}