import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libyyapp/mainPagesReader/showpage.dart';

class ReservationHistoryScreen extends StatefulWidget {
  const ReservationHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ReservationHistoryScreen> createState() => _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState extends State<ReservationHistoryScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<QuerySnapshot> _allReservationsStream;
  late Stream<QuerySnapshot> _waitingReservationsStream;
  late Stream<QuerySnapshot> _notifiedReservationsStream;
  late Stream<QuerySnapshot> _expiredReservationsStream;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;

 
  final Color primaryColor = const Color(0xFF139799);
  final Color secondaryColor = const Color(0xFF2D3142);
  final Color accentColor = const Color(0xFF98C1D9);
  
 
  final Color waitingColor = const Color(0xFFFF9800);
  final Color notifiedColor = const Color(0xFF3E7BFA); 
  final Color expiredColor = const Color(0xFFF44336); 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReservationData();
  }

  void _loadReservationData() {
    final userId = _auth.currentUser?.uid;

    if (userId != null) {
      
      _allReservationsStream = _firestore
          .collection('WaitingList')
          .where('userId', isEqualTo: userId)
          .orderBy('requestDate', descending: true)
          .snapshots();

     
      _waitingReservationsStream = _firestore
          .collection('WaitingList')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'waiting')
          .orderBy('requestDate', descending: true)
          .snapshots();

     
      _notifiedReservationsStream = _firestore
          .collection('WaitingList')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'notified')
          .orderBy('notificationTime', descending: true)
          .snapshots();

     
      _expiredReservationsStream = _firestore
          .collection('WaitingList')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'expired')
          .orderBy('expiredAt', descending: true)
          .snapshots();

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildReservationCard(QueryDocumentSnapshot reservation) {
    final data = reservation.data() as Map<String, dynamic>;
    final bookId = data['bookId'] as String? ?? '';
    final bookTitle = data['bookTitle'] as String? ?? 'كتاب غير معروف';
    final status = data['status'] as String? ?? 'waiting';
    final isWaiting = status == 'waiting';
    final isNotified = status == 'notified';
    final isExpired = status == 'expired';

    
    final coverUrl = data['coverUrl'] as String? ?? '';

    
    final requestDate = data['requestDate'] != null
        ? (data['requestDate'] as Timestamp).toDate().toString().split(' ')[0]
        : 'غير محدد';

    final notificationDate = data['notificationTime'] != null
        ? (data['notificationTime'] as Timestamp).toDate().toString().split(' ')[0]
        : null;

    final expiryDate = data['expiryTime'] != null
        ? (data['expiryTime'] as Timestamp).toDate().toString().split(' ')[0]
        : null;

    final expiredAt = data['expiredAt'] != null
        ? (data['expiredAt'] as Timestamp).toDate().toString().split(' ')[0]
        : null;

    
    Color statusColor = isWaiting ? waitingColor : isNotified ? notifiedColor : expiredColor;

    
    String statusText = isWaiting ? 'في انتظار الإشعار' : 
                       isNotified ? 'تم الإشعار' : 'انتهت المهلة';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
           
            Row(
              children: [
                
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: coverUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              Icon(Icons.book, color: primaryColor),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.book,
                            color: primaryColor,
                            size: 30,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
           
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildDateRow(
                    Icons.calendar_today,
                    'تاريخ الطلب:',
                    requestDate,
                    secondaryColor,
                  ),
                  
                  if (isWaiting)
                    _buildDateRow(
                      Icons.hourglass_empty,
                      'حالة الطلب:',
                      'في انتظار توفر الكتاب',
                      waitingColor,
                    ),
                  
                  if (isNotified && notificationDate != null)
                    _buildDateRow(
                      Icons.notifications_active,
                      'تاريخ الإشعار:',
                      notificationDate,
                      notifiedColor,
                    ),
                  
                  if (isNotified && expiryDate != null)
                    _buildDateRow(
                      Icons.timer,
                      'تنتهي المهلة:',
                      expiryDate,
                      notifiedColor,
                    ),
                  
                  if (isExpired && expiredAt != null)
                    _buildDateRow(
                      Icons.timer_off,
                      'انتهت المهلة:',
                      expiredAt,
                      expiredColor,
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
           
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  if (bookId.isNotEmpty) {
                    try {
                      DocumentSnapshot bookDoc = await FirebaseFirestore.instance
                          .collection('Books')
                          .doc(bookId)
                          .get();
                          
                      if (bookDoc.exists) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailsScreen(bookData: bookDoc),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('لا يمكن العثور على تفاصيل الكتاب')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ أثناء جلب بيانات الكتاب: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('لا يمكن عرض تفاصيل الكتاب')),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: primaryColor),
                ),
                child: Text(
                  'عرض تفاصيل الكتاب',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(IconData icon, String label, String date, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            date,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList(Stream<QuerySnapshot> reservationsStream, String emptyMessage) {
    return StreamBuilder<QuerySnapshot>(
      stream: reservationsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('حدث خطأ: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        final reservations = snapshot.data?.docs ?? [];

        if (reservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            return _buildReservationCard(reservations[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "سجل حجوزاتي",
          style: TextStyle(
            color: Color(0xFF139799),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF139799),
      ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: primaryColor,
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'الكل'),
                  Tab(text: 'في الانتظار'),
                  Tab(text: 'تم الإشعار'),
                  Tab(text: 'انتهت المهلة'),
                ],
              ),
            ),
            
            
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildReservationsList(_allReservationsStream, 'لا توجد حجوزات في سجلك'),
                        _buildReservationsList(_waitingReservationsStream, 'لا توجد حجوزات في انتظار الإشعار'),
                        _buildReservationsList(_notifiedReservationsStream, 'لا توجد حجوزات تم إشعارك بها'),
                        _buildReservationsList(_expiredReservationsStream, 'لا توجد حجوزات منتهية الصلاحية'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}