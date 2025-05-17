import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:libyyapp/mainPagesReader/showpage.dart';

class BorrowHistoryScreen extends StatefulWidget {
  const BorrowHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BorrowHistoryScreen> createState() => _BorrowHistoryScreenState();
}

class _BorrowHistoryScreenState extends State<BorrowHistoryScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<QuerySnapshot> _allBorrowsStream;
  late Stream<QuerySnapshot> _activeBorrowsStream;
  late Stream<QuerySnapshot> _pendingBorrowsStream;
  late Stream<QuerySnapshot> _returnedBorrowsStream;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;

 
  final Color primaryColor = const Color(0xFF139799);
  final Color secondaryColor = const Color(0xFF2D3142);
  final Color accentColor = const Color(0xFF98C1D9);
  
  
  final Color pendingColor = const Color(0xFFFF9800);
  final Color activeColor = const Color(0xFF3E7BFA);
  final Color returnedColor = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBorrowData();
  }

  void _loadBorrowData() {
    final userId = _auth.currentUser?.uid;

    if (userId != null) {
      
      _allBorrowsStream = _firestore
          .collection('BorrowRequestsList')
          .where('userId', isEqualTo: userId)
          .orderBy('requestDate', descending: true)
          .snapshots();

      
      _activeBorrowsStream = _firestore
          .collection('BorrowRequestsList')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('requestDate', descending: true)
          .snapshots();

      
      _pendingBorrowsStream = _firestore
          .collection('BorrowRequestsList')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('requestDate', descending: true)
          .snapshots();

      
      _returnedBorrowsStream = _firestore
          .collection('BorrowRequestsList')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'returned')
          .orderBy('returnedDate', descending: true)
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

  Widget _buildBorrowCard(QueryDocumentSnapshot borrow) {
    final data = borrow.data() as Map<String, dynamic>;
    final bookId = data['bookId'] as String? ?? '';
    final bookTitle = data['bookTitle'] as String? ?? 'كتاب غير معروف';
    final status = data['status'] as String? ?? 'pending';
    final isActive = status == 'active';
    final isPending = status == 'pending';
    final isReturned = status == 'returned';

    
    final coverUrl = data['coverUrl'] as String? ?? '';

   
    final requestDate = data['requestDate'] != null
        ? (data['requestDate'] as Timestamp).toDate().toString().split(' ')[0]
        : 'غير محدد';

    final returnDate = data['returnDate'] != null
        ? (data['returnDate'] as Timestamp).toDate().toString().split(' ')[0]
        : 'غير محدد';

    final returnedDate = data['returnedDate'] != null
        ? (data['returnedDate'] as Timestamp).toDate().toString().split(' ')[0]
        : null;

    final expiryDate = data['expiryDate'] != null
        ? (data['expiryDate'] as Timestamp).toDate().toString().split(' ')[0]
        : null;

   
    Color statusColor = isPending ? pendingColor : isActive ? activeColor : returnedColor;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
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
                            isPending ? 'طلب معلق' : 
                            isActive ? 'استعارة نشطة' : 'تمت الإعادة',
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
                  
                  if (isPending && expiryDate != null)
                    _buildDateRow(
                      Icons.timer_outlined,
                      'تنتهي صلاحية الطلب:',
                      expiryDate,
                      pendingColor,
                    ),
                  
                  if (isActive)
                    _buildDateRow(
                      Icons.event_note_outlined,
                      'موعد الإرجاع:',
                      returnDate,
                      activeColor,
                    ),
                  
                  if (isReturned && returnedDate != null)
                    _buildDateRow(
                      Icons.check_circle_outline,
                      'تم الإرجاع:',
                      returnedDate,
                      returnedColor,
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

  Widget _buildBorrowsList(Stream<QuerySnapshot> borrowsStream) {
    return StreamBuilder<QuerySnapshot>(
      stream: borrowsStream,
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

        final borrows = snapshot.data?.docs ?? [];

        if (borrows.isEmpty) {
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
                  'لا توجد استعارات في هذا القسم',
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
          itemCount: borrows.length,
          itemBuilder: (context, index) {
            return _buildBorrowCard(borrows[index]);
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
          "سجل استعاراتي",
          style: TextStyle(
            color: Color(0xFF139799),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF139799)),
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
                  Tab(text: 'المعلقة'),
                  Tab(text: 'النشطة'),
                  Tab(text: 'المرجعة'),
                ],
              ),
            ),
            
            
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBorrowsList(_allBorrowsStream),
                        _buildBorrowsList(_pendingBorrowsStream),
                        _buildBorrowsList(_activeBorrowsStream),
                        _buildBorrowsList(_returnedBorrowsStream),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}