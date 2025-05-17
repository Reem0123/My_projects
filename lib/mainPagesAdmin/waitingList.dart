import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WaitingListScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final DocumentSnapshot bookData;

  const WaitingListScreen({
    Key? key,
    required this.bookId,
    required this.bookTitle,
    required this.bookData,
  }) : super(key: key);

  @override
  State<WaitingListScreen> createState() => _WaitingListScreenState();
}

class _WaitingListScreenState extends State<WaitingListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<QuerySnapshot> _waitingStream;
  late Stream<QuerySnapshot> _notifiedStream;
  late Stream<QuerySnapshot> _respondedStream;
  late Stream<QuerySnapshot> _expiredStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    
    _waitingStream = FirebaseFirestore.instance
        .collection('WaitingList')
        .where('bookId', isEqualTo: widget.bookId)
        .where('status', isEqualTo: 'waiting')
        .orderBy('requestDate', descending: false)
        .snapshots();
    
    _notifiedStream = FirebaseFirestore.instance
        .collection('WaitingList')
        .where('bookId', isEqualTo: widget.bookId)
        .where('status', isEqualTo: 'notified')
        .orderBy('notificationTime', descending: false)
        .snapshots();
    
    _respondedStream = FirebaseFirestore.instance
        .collection('WaitingList')
        .where('bookId', isEqualTo: widget.bookId)
        .where('status', isEqualTo: 'responded')
        .orderBy('responseDate', descending: false)
        .snapshots();
    
    _expiredStream = FirebaseFirestore.instance
        .collection('WaitingList')
        .where('bookId', isEqualTo: widget.bookId)
        .where('status', isEqualTo: 'expired')
        .orderBy('expiredAt', descending: false)
        .snapshots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  
  void _showWaitingDetails(BuildContext context, Map<String, dynamic> userData, int? position) {
    final userEmail = userData['userEmail'] as String? ?? 'غير متوفر';
    final requestDate = userData['requestDate'] != null 
        ? (userData['requestDate'] as Timestamp).toDate().toString().split(' ')[0]
        : 'غير محدد';
    final status = userData['status'] as String? ?? 'waiting';
    final isNotified = status != 'waiting';
    final notificationTime = userData['notificationTime'] != null 
        ? (userData['notificationTime'] as Timestamp).toDate().toString()
        : 'لم يتم الإشعار بعد';
    final expiryTime = userData['expiryTime'] != null 
        ? (userData['expiryTime'] as Timestamp).toDate().toString()
        : 'غير متوفر';
    final responseTime = userData['responseDate'] != null 
        ? (userData['responseDate'] as Timestamp).toDate().toString()
        : 'لم يستجب بعد';
    final expiredAt = userData['expiredAt'] != null 
        ? (userData['expiredAt'] as Timestamp).toDate().toString()
        : 'غير متوفر';

    String statusText;
    Color statusColor;
    switch (status) {
      case 'waiting':
        statusText = 'في انتظار الإشعار';
        statusColor = Colors.grey;
        break;
      case 'notified':
        statusText = 'تم إشعاره (في انتظار الاستجابة)';
        statusColor = Colors.orange;
        break;
      case 'responded':
        statusText = 'تم الاستجابة واستعارة الكتاب';
        statusColor = Colors.green;
        break;
      case 'expired':
        statusText = 'انتهت المهلة دون استجابة';
        statusColor = Colors.red;
        break;
      default:
        statusText = 'غير معروف';
        statusColor = Colors.grey;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: status == 'waiting' && position != null
              ? Text('تفاصيل الانتظار - الترتيب: $position')
              : const Text('تفاصيل الانتظار'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('البريد الإلكتروني: $userEmail'),
                const SizedBox(height: 8),
                Text('تاريخ طلب الانتظار: $requestDate'),
                const SizedBox(height: 8),
                if (status == 'waiting' && position != null) ...[
                  Text('ترتيب الانتظار: $position', 
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'الحالة: $statusText',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                if (isNotified) ...[
                  Text('وقت الإشعار: $notificationTime'),
                  const SizedBox(height: 8),
                ],
                
                if (status == 'notified') ...[
                  Text('المهلة تنتهي في: $expiryTime'),
                  const SizedBox(height: 8),
                ],
                
                if (status == 'responded') ...[
                  Text('وقت الاستجابة: $responseTime'),
                  const SizedBox(height: 8),
                ],
                
                if (status == 'expired') ...[
                  Text('انتهت المهلة في: $expiredAt'),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildUserList(Stream<QuerySnapshot> stream, String emptyMessage, String statusType) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
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

        final users = snapshot.data?.docs ?? [];

        if (users.isEmpty) {
          return Center(
            child: Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;
            final userEmail = data['userEmail'] as String? ?? 'غير متوفر';
            
            
            String dateInfo;
            Icon icon;
            
            switch (statusType) {
              case 'waiting':
                final requestDate = data['requestDate'] != null 
                    ? (data['requestDate'] as Timestamp).toDate().toString().split(' ')[0]
                    : 'غير محدد';
                dateInfo = 'تاريخ الطلب: $requestDate';
                icon = const Icon(Icons.hourglass_empty, size: 16, color: Colors.grey);
                break;
              case 'notified':
                final notificationDate = data['notificationTime'] != null 
                    ? (data['notificationTime'] as Timestamp).toDate().toString().split(' ')[0]
                    : 'غير محدد';
                final expiryDate = data['expiryTime'] != null 
                    ? (data['expiryTime'] as Timestamp).toDate().toString().split(' ')[0]
                    : '';
                dateInfo = 'تم الإشعار: $notificationDate - المهلة: $expiryDate';
                icon = const Icon(Icons.notifications_active, size: 16, color: Colors.orange);
                break;
              case 'responded':
                final responseDate = data['responseDate'] != null 
                    ? (data['responseDate'] as Timestamp).toDate().toString().split(' ')[0]
                    : 'غير محدد';
                dateInfo = 'استجاب بتاريخ: $responseDate';
                icon = const Icon(Icons.check_circle, size: 16, color: Colors.green);
                break;
              case 'expired':
                final expiredDate = data['expiredAt'] != null 
                    ? (data['expiredAt'] as Timestamp).toDate().toString().split(' ')[0]
                    : 'غير محدد';
                dateInfo = 'انتهت المهلة: $expiredDate';
                icon = const Icon(Icons.timer_off, size: 16, color: Colors.red);
                break;
              default:
                dateInfo = '';
                icon = const Icon(Icons.info, size: 16, color: Colors.grey);
            }

            
            final int? position = statusType == 'waiting' ? index + 1 : null;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    _showWaitingDetails(context, data, position);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            statusType == 'waiting'
                                ? CircleAvatar(
                                    backgroundColor: const Color(0xFF139799).withOpacity(0.1),
                                    child: Text(
                                      position.toString(),
                                      style: const TextStyle(
                                        color: Color(0xFF139799),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : CircleAvatar(
                                    backgroundColor: _getColorForStatus(statusType).withOpacity(0.1),
                                    child: Text(
                                      userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        color: _getColorForStatus(statusType),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          userEmail,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                      ),
                                      if (statusType == 'waiting') ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF139799).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'الترتيب: $position',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF139799),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getColorForStatus(statusType).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(statusType),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _getColorForStatus(statusType),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            icon,
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dateInfo,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF777777),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  
  Color _getColorForStatus(String status) {
    switch (status) {
      case 'waiting':
        return Colors.grey;
      case 'notified':
        return Colors.orange;
      case 'responded':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return const Color(0xFF139799);
    }
  }

  
  String _getStatusText(String status) {
    switch (status) {
      case 'waiting':
        return 'في انتظار الإشعار';
      case 'notified':
        return 'تم الإشعار (في المهلة)';
      case 'responded':
        return 'تم استعارة الكتاب';
      case 'expired':
        return 'انتهت المهلة';
      default:
        return 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "قائمة الانتظار - ${widget.bookTitle}",
            style: const TextStyle(
              color: Color(0xFF139799),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Color(0xFF139799)),
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF139799),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF139799),
            tabs: const [
              Tab(text: 'في الانتظار'),
              Tab(text: 'تم إشعارهم'),
              Tab(text: 'استجابوا'),
              Tab(text: 'انتهت المهلة'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            
            _buildUserList(
              _waitingStream,
              'لا يوجد حاليا مستخدمين في انتظار إشعار',
              'waiting',
            ),
            
            _buildUserList(
              _notifiedStream,
              'لا يوجد مستخدمين تم إشعارهم',
              'notified',
            ),
           
            _buildUserList(
              _respondedStream,
              'لا يوجد مستخدمين استجابوا للإشعار',
              'responded',
            ),
           
            _buildUserList(
              _expiredStream,
              'لا يوجد مستخدمين انتهت مهلتهم',
              'expired',
            ),
          ],
        ),
      ),
    );
  }
}