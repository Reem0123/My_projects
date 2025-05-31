import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

class Showpage extends StatefulWidget {
  const Showpage({super.key});

  @override
  State<Showpage> createState() => _ShowpageState();
}

class _ShowpageState extends State<Showpage> {
  Map<String, List<QueryDocumentSnapshot>> categorizedBooks = {};
  List<String> categories = [];
  bool isLoading = true;
 
  @override
  void initState() {
    super.initState();
    getData();
    _setupUnreadNotificationsListener();
  }

  void _setupUnreadNotificationsListener() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (currentUserId == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        
        setState(() {
         
        });
      }
    });
  }

  getData() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Books')
          .where('isHidden', isEqualTo: false) 
          .orderBy('createdAt', descending: true)
          .get();

      Map<String, List<QueryDocumentSnapshot>> tempCategorizedBooks = {};
      
      for (var doc in querySnapshot.docs) {
        String category = doc['Category'] ?? 'عام';
        
        if (!tempCategorizedBooks.containsKey(category)) {
          tempCategorizedBooks[category] = [];
        }
        
        tempCategorizedBooks[category]!.add(doc);
      }
      
      List<String> categoryList = tempCategorizedBooks.keys.toList();
      
      setState(() {
        categorizedBooks = tempCategorizedBooks;
        categories = categoryList;
        isLoading = false;
      });
      
    } catch (e) {
      print("Error getting documents: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildNotificationIcon() {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return IconButton(
        icon: Icon(Icons.notifications_active, color: Color(0xFF139799)),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('يجب تسجيل الدخول أولاً لعرض الإشعارات'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;
        
        return badges.Badge(
          badgeContent: Text(
            unreadCount.toString(),
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          badgeStyle: badges.BadgeStyle(
            badgeColor: Colors.red,
            padding: EdgeInsets.all(5),
          ),
          position: badges.BadgePosition.topEnd(top: -5, end: -5),
          showBadge: unreadCount > 0,
          child: IconButton(
            icon: Icon(
              Icons.notifications_active,
              color: Color(0xFF139799),
              size: 40,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed("/notification_screen");
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: _buildNotificationIcon(),
      ),
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    isLoading = true;
                    categorizedBooks.clear();
                    categories.clear();
                  });
                  await getData();
                },
                child: categories.isEmpty
                    ? Center(
                        child: Text(
                          "لا توجد كتب حاليًا",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(top: 0, left: 16, right: 16, bottom: 16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          String category = categories[index];
                          List<QueryDocumentSnapshot> books = categorizedBooks[category] ?? [];
                          
                          return Padding(
                            padding: EdgeInsets.only(top: index == 0 ? 0 : 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CategoryBooksScreen(
                                              categoryName: category,
                                              books: books,
                                            ),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.grey[200],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      child: Text(
                                        'عرض الكل',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: 12),
                                
                                Container(
                                  height: 280,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: books.length,
                                    itemBuilder: (context, bookIndex) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          left: bookIndex < books.length - 1 ? 15 : 0,
                                        ),
                                        child: BookCard(
                                          bookData: books[bookIndex],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}

class CategoryBooksScreen extends StatelessWidget {
  final String categoryName;
  final List<QueryDocumentSnapshot> books;
  
  const CategoryBooksScreen({
    Key? key,
    required this.categoryName,
    required this.books,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          categoryName,
          style: TextStyle(
            color: Color(0xFF139799),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Color(0xFF139799)),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return BookCard(
                bookData: books[index],
              );
            },
          ),
        ),
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  final DocumentSnapshot bookData;

  const BookCard({
    required this.bookData,
  });

  @override
  Widget build(BuildContext context) {
    final String title = bookData['BookTitle'] ?? 'بدون عنوان';
    final String author = bookData['Auther'] ?? 'بدون مؤلف';
    final String imageUrl = bookData['ImageUrl'] ?? '';
    final String status = bookData['status'] ?? 'متاح';
    final int availableCopies = bookData['availableCopies'] ?? 0;
    
    Color statusColor = status == 'متاح' ? Colors.green : Colors.orange;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsScreen(bookData: bookData),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 170,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          
          SizedBox(height: 10),
          
          SizedBox(
            width: 150,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          SizedBox(height: 4),
          
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              SizedBox(
                width: 125,
                child: Text(
                  author,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 4),
          
          Row(
            children: [
              Icon(Icons.book, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.copy, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                "النسخ المتاحة: $availableCopies",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BookDetailsScreen extends StatefulWidget {
  final DocumentSnapshot bookData;
  
  const BookDetailsScreen({
    Key? key,
    required this.bookData,
  }) : super(key: key);

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  bool isCurrentUserBorrower = false;
  bool isUserInWaitingList = false;
  bool isUserNotifiedForBook = false;
  bool isUserRequestExpired = false;
  bool isPendingRequest = false;
  bool isLoading = true;
  bool _isBookFavorite = false;
  bool _isCheckingFavorite = true;
  bool _isAccountDisabled = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  double _userRating = 0;
  bool _hasUserRated = false;
  String _userComment = '';
  List<Map<String, dynamic>> _reviews = [];
  bool _loadingReviews = true;
  double _averageRating = 0;
  int _totalRatings = 0;

  @override
  void initState() {
    super.initState();
    checkUserStatus();
    _checkIfBookIsFavorite();
    _setupBorrowRequestListener();
    _checkAccountStatus();
    _loadBookReviews();
    _checkUserRating();
  }

  Future<void> _loadBookReviews() async {
  try {
    QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
        .collection('bookReviews')
        .where('bookId', isEqualTo: widget.bookData.id)
        .orderBy('timestamp', descending: true)
        .get();

    double totalRating = 0;
    List<Map<String, dynamic>> reviews = [];

    for (var doc in reviewsSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      
      reviews.add({
        'id': doc.id, 
        'userId': data['userId'], 
        'rating': data['rating'],
        'comment': data['comment'],
        'timestamp': data['timestamp'],
        'userName': data['userName'] ?? 'مستخدم',
        'userPhotoUrl': data['userPhotoUrl'] ?? '',
      });

      totalRating += data['rating'] ?? 0;
    }

    double avgRating = reviews.isNotEmpty ? totalRating / reviews.length : 0;

    setState(() {
      _reviews = reviews;
      _averageRating = avgRating;
      _totalRatings = reviews.length;
      _loadingReviews = false;
    });
  } catch (e) {
    print('Error loading reviews: $e');
    setState(() {
      _loadingReviews = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('حدث خطأ في تحميل التقييمات')),
    );
  }
}

  Future<void> _checkUserRating() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot userRating = await FirebaseFirestore.instance
          .collection('bookReviews')
          .where('bookId', isEqualTo: widget.bookData.id)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (userRating.docs.isNotEmpty) {
        var data = userRating.docs.first.data() as Map<String, dynamic>;
        setState(() {
          _userRating = data['rating']?.toDouble() ?? 0;
          _userComment = data['comment'] ?? '';
          _hasUserRated = true;
        });
      }
    } catch (e) {
      print('Error checking user rating: $e');
    }
  }

  Future<void> _submitRating() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('يجب تسجيل الدخول لتقييم الكتاب')),
    );
    return;
  }

  if (_userRating == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('الرجاء اختيار تقييم من 1 إلى 5 نجوم')),
    );
    return;
  }

  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .get();

    String firstName = userDoc['first name'] ?? '';
    String lastName = userDoc['last name'] ?? '';
    String fullName = '$firstName $lastName'.trim();
    if (fullName.isEmpty) {
      fullName = user.email?.split('@').first ?? 'مستخدم';
    }
    
    
    String userPhotoUrl = '';
    if (userDoc.exists && userDoc.data() != null) {
      final userData = userDoc.data() as Map<String, dynamic>;
      userPhotoUrl = userData['profile_image']?.toString() ?? '';
    }

    QuerySnapshot existingRating = await FirebaseFirestore.instance
        .collection('bookReviews')
        .where('bookId', isEqualTo: widget.bookData.id)
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (existingRating.docs.isNotEmpty) {
      await existingRating.docs.first.reference.update({
        'rating': _userRating,
        'comment': _userComment,
        'timestamp': FieldValue.serverTimestamp(),
        'userName': fullName,
        'userPhotoUrl': userPhotoUrl,
      });
    } else {
      await FirebaseFirestore.instance.collection('bookReviews').add({
        'bookId': widget.bookData.id,
        'userId': user.uid,
        'userName': fullName,
        'userPhotoUrl': userPhotoUrl,
        'rating': _userRating,
        'comment': _userComment,
        'timestamp': FieldValue.serverTimestamp(),
        'bookTitle': widget.bookData['BookTitle'] ?? 'بدون عنوان',
      });
    }

    await _updateBookRating();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('شكراً لتقييمك!')),
    );

    await _loadBookReviews();
    setState(() {
      _hasUserRated = true;
    });
  } catch (e) {
    print('Error submitting rating: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('حدث خطأ أثناء حفظ التقييم: ${e.toString()}')),
    );
  }
}

  Future<void> _updateBookRating() async {
    try {
      QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
          .collection('bookReviews')
          .where('bookId', isEqualTo: widget.bookData.id)
          .get();

      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += doc['rating'] ?? 0;
      }

      double avgRating = reviewsSnapshot.docs.isNotEmpty 
          ? totalRating / reviewsSnapshot.docs.length 
          : 0;

      await FirebaseFirestore.instance
          .collection('Books')
          .doc(widget.bookData.id)
          .update({
            'averageRating': avgRating,
            'totalRatings': reviewsSnapshot.docs.length,
          });
    } catch (e) {
      print('Error updating book rating: $e');
    }
  }

  void _showRatingDialog() {
   
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double tempRating = _userRating; 
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: Colors.white,
                title: Center(child: Text('قيم هذا الكتاب',style: TextStyle(color: Color(0xFF139799)),)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('كم نجمة تعطي لهذا الكتاب؟'),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < tempRating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 30,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                tempRating = index + 1.0; 
                              });
                            },
                          );
                        }),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'تعليقك (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          _userComment = value;
                        },
                        controller: TextEditingController(text: _userComment),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('إلغاء',style: TextStyle(color: Color(0xFF139799)),),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _userRating = tempRating; 
                      });
                      Navigator.of(context).pop();
                      _submitRating();
                    },
                    child: Text('حفظ التقييم',style: TextStyle(color: Color(0xFF139799)),),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _setupBorrowRequestListener() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseFirestore.instance
        .collection('BorrowRequestsList')
        .where('userId', isEqualTo: userId)
        .where('bookId', isEqualTo: widget.bookData.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final status = snapshot.docs.first['status'];
        _safeSetState(() {
          isPendingRequest = status == 'pending';
          isCurrentUserBorrower = status == 'active';
        });
      }
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _checkIfBookIsFavorite() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _safeSetState(() {
        _isCheckingFavorite = false;
        _isBookFavorite = false;
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('bookId', isEqualTo: widget.bookData.id)
          .limit(1)
          .get();

      _safeSetState(() {
        _isBookFavorite = snapshot.docs.isNotEmpty;
        _isCheckingFavorite = false;
      });
    } catch (e) {
      print('Error checking favorite status: $e');
      _safeSetState(() {
        _isCheckingFavorite = false;
        _isBookFavorite = false;
      });
    }
  }

  Future<void> _checkAccountStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .get();
        
      if (userDoc.exists) {
        _safeSetState(() {
          _isAccountDisabled = userDoc['disabled'] ?? false;
        });
      }
    } catch (e) {
      print('Error checking account status: $e');
    }
  }

  Future<void> checkUserStatus() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      _safeSetState(() {
        isLoading = false;
      });
      return;
    }

    try {
      QuerySnapshot activeRequests = await FirebaseFirestore.instance
          .collection('BorrowRequestsList')
          .where('bookId', isEqualTo: widget.bookData.id)
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'active')
          .get();

      QuerySnapshot pendingRequests = await FirebaseFirestore.instance
          .collection('BorrowRequestsList')
          .where('bookId', isEqualTo: widget.bookData.id)
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      QuerySnapshot waitingRequests = await FirebaseFirestore.instance
          .collection('WaitingList')
          .where('bookId', isEqualTo: widget.bookData.id)
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'waiting')
          .get();
      
      QuerySnapshot notifiedRequests = await FirebaseFirestore.instance
          .collection('WaitingList')
          .where('bookId', isEqualTo: widget.bookData.id)
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'notified')
          .get();
      
      QuerySnapshot expiredRequests = await FirebaseFirestore.instance
          .collection('WaitingList')
          .where('bookId', isEqualTo: widget.bookData.id)
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'expired')
          .get();
      
      _safeSetState(() {
        isCurrentUserBorrower = activeRequests.docs.isNotEmpty;
        isPendingRequest = pendingRequests.docs.isNotEmpty;
        isUserInWaitingList = waitingRequests.docs.isNotEmpty;
        isUserNotifiedForBook = notifiedRequests.docs.isNotEmpty;
        isUserRequestExpired = expiredRequests.docs.isNotEmpty;
        isLoading = false;
      });
      _checkExpiredNotifications();
    } catch (e) {
      print('Error checking user status: $e');
      _safeSetState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkExpiredNotifications() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      QuerySnapshot notifiedRequests = await FirebaseFirestore.instance
          .collection('WaitingList')
          .where('userId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'notified')
          .get();

      final now = DateTime.now();
      
      for (var doc in notifiedRequests.docs) {
        final notificationData = doc.data() as Map<String, dynamic>;
        final notificationTime = (notificationData['notificationDate'] as Timestamp).toDate();
        final expiryTime = notificationTime.add(Duration(hours: 24));
        
        if (now.isAfter(expiryTime)) {
          await doc.reference.update({
            'status': 'expired',
            'expiryDate': now,
          });
          
          _safeSetState(() {
            isUserNotifiedForBook = false;
            isUserRequestExpired = true;
          });
        }
      }
    } catch (e) {
      print('Error checking expired notifications: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يجب تسجيل الدخول لإضافة إلى المفضلة')),
      );
      return;
    }

    _safeSetState(() {
      _isCheckingFavorite = true;
    });

    try {
      if (_isBookFavorite) {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: user.uid)
            .where('bookId', isEqualTo: widget.bookData.id)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          await snapshot.docs.first.reference.delete();
        }
      } else {
        await FirebaseFirestore.instance.collection('favorites').add({
          'userId': user.uid,
          'bookId': widget.bookData.id,
          'addedAt': DateTime.now(),
          'bookTitle': widget.bookData['BookTitle'] ?? 'بدون عنوان',
          'bookImage': widget.bookData['ImageUrl'] ?? '',
          'bookAuthor': widget.bookData['Auther'] ?? 'بدون مؤلف',
        });
      }

      _safeSetState(() {
        _isBookFavorite = !_isBookFavorite;
        _isCheckingFavorite = false;
      });
    } catch (e) {
      print('Error toggling favorite: $e');
      _safeSetState(() {
        _isCheckingFavorite = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحديث المفضلة')),
      );
    }
  }

  Future<void> _submitBorrowRequest(BuildContext context) async {
    try {
      bool isConnected = await _checkInternetConnection();
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت')),
        );
        return;
      }
      
      bool firebaseOk = await _checkFirebaseSetup();
      if (!firebaseOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('هناك مشكلة في الاتصال بقاعدة البيانات، حاول مرة أخرى لاحقًا')),
        );
        return;
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('يرجى تسجيل الدخول أولاً لاستعارة الكتاب')),
        );
        return;
      }
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'تأكيد الاستعارة',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'هل أنت متأكد من طلبك؟',
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _processBorrowRequest(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF139799),
                ),
                child: Text('تأكيد'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    }
  }

  Future<void> _processBorrowRequest(BuildContext context) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('خطأ'),
              content: Text('يجب تسجيل الدخول أولاً لتقديم طلب استعارة'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('حسناً'),
                ),
              ],
            );
          },
        );
        return;
      }

      final String userId = currentUser.uid;
      final String bookId = widget.bookData.id;
      String? waitingListDocId;
      
      if (isUserNotifiedForBook) {
        QuerySnapshot notifiedRequests = await FirebaseFirestore.instance
            .collection('WaitingList')
            .where('bookId', isEqualTo: bookId)
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'notified')
            .get();
        
        if (notifiedRequests.docs.isNotEmpty) {
          waitingListDocId = notifiedRequests.docs.first.id;
          await notifiedRequests.docs.first.reference.update({
            'status': 'responded',
            'responseDate': DateTime.now(),
          });
        }
      }
      
      DocumentReference bookRef = FirebaseFirestore.instance.collection('Books').doc(bookId);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot bookSnapshot = await transaction.get(bookRef);
        
        if (!bookSnapshot.exists) {
          throw Exception("الكتاب غير موجود!");
        }
        
        Map<String, dynamic> bookData = bookSnapshot.data() as Map<String, dynamic>;
        
        if (!isUserNotifiedForBook) {
          int availableCopies = bookData['availableCopies'] ?? 0;
          
          if (availableCopies <= 0) {
            throw Exception("لا توجد نسخ متاحة لهذا الكتاب!");
          }
          
          int newAvailableCopies = availableCopies - 1;
          String newStatus = newAvailableCopies > 0 ? 'متاح' : 'غير متاح';
          
          transaction.update(bookRef, {
            'availableCopies': newAvailableCopies,
            'status': newStatus,
          });
        }
      });
      
      final DateTime requestDate = DateTime.now();
      final DateTime returnDate = requestDate.add(Duration(days: 15));
      final DateTime expiryDate = requestDate.add(Duration(hours: 24));
      
      Map<String, dynamic> requestData = {
        'userId': userId,
        'bookId': bookId,
        'requestDate': requestDate,
        'returnDate': returnDate,
        'expiryDate': expiryDate,
        'status': 'pending',
        'bookTitle': widget.bookData['BookTitle'] ?? 'بدون عنوان',
        'userEmail': currentUser.email ?? 'غير متوفر',
        'fromNotification': isUserNotifiedForBook,
        'waitingListDocId': waitingListDocId,
      };
      
      await FirebaseFirestore.instance
        .collection('BorrowRequestsList')
        .add(requestData);

      _safeSetState(() {
        isPendingRequest = true;
        isCurrentUserBorrower = false;
        isUserNotifiedForBook = false;
        isUserInWaitingList = false;
      });

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('تأكيد الطلب'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تم تقديم طلب استعارة بنجاح'),
                SizedBox(height: 8),
                Text('يرجى التوجه إلى المكتبة لاستلام الكتاب خلال 24 ساعة', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                SizedBox(height: 8),
                Text('تاريخ انتهاء صلاحية الطلب: ${_formatDateTime(expiryDate)}', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('تاريخ الإرجاع بعد الاستلام: ${_formatDate(returnDate)}', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('حسناً'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('خطأ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('حدث خطأ أثناء تقديم الطلب:'),
                SizedBox(height: 8),
                Text('${e.toString()}', style: TextStyle(color: Colors.red)),
                SizedBox(height: 16),
                Text('يرجى التحقق من اتصالك بالإنترنت وحالة تسجيل الدخول ثم المحاولة مرة أخرى.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('حسناً'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<bool> _checkFirebaseSetup() async {
    try {
      await FirebaseFirestore.instance.collection('Books').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
  
  Future<void> _addToWaitingList(BuildContext context) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('خطأ'),
              content: Text('يجب تسجيل الدخول أولاً للانضمام إلى قائمة الانتظار'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('حسناً'),
                ),
              ],
            );
          },
        );
        return;
      }

      final String userId = currentUser.uid;
      final String bookId = widget.bookData.id;
      
      QuerySnapshot existingRequests = await FirebaseFirestore.instance
          .collection('WaitingList')
          .where('bookId', isEqualTo: bookId)
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['waiting', 'notified'])
          .get();
      
      if (existingRequests.docs.isNotEmpty) {
        throw Exception("أنت بالفعل في قائمة الانتظار لهذا الكتاب!");
      }
      
      final DateTime requestDate = DateTime.now();
      
      await FirebaseFirestore.instance.collection('WaitingList').add({
        'userId': userId,
        'bookId': bookId,
        'requestDate': requestDate,
        'status': 'waiting',
        'notified': false,
        'bookTitle': widget.bookData['BookTitle'] ?? 'بدون عنوان',
        'userEmail': currentUser.email ?? 'غير متوفر',
      });
      
      _safeSetState(() {
        isUserInWaitingList = true;
        isUserNotifiedForBook = false;
        isUserRequestExpired = false;
      });
      
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('تأكيد'),
            content: Text(
              'تم إضافتك بنجاح إلى قائمة الانتظار. سيتم إشعارك عندما يصبح الكتاب متاحًا للاستعارة.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('حسناً'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('خطأ'),
            content: Text('حدث خطأ أثناء الانضمام إلى قائمة الانتظار: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('حسناً'),
              ),
            ],
          );
        },
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }


  void _showEditRatingDialog() {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) return;

  
  final userReview = _reviews.firstWhere(
    (review) => review['userId'] == currentUserId,
    orElse: () => {},
  );

  if (userReview.isEmpty) return;

  double tempRating = userReview['rating']?.toDouble() ?? 0;
  TextEditingController commentController = TextEditingController(text: userReview['comment'] ?? '');

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: Colors.white,
              title: Center(child: Text('تعديل تقييمك', style: TextStyle(color: Color(0xFF139799)))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('كم نجمة تعطي لهذا الكتاب الآن؟'),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < tempRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 30,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              tempRating = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        labelText: 'تعديل تعليقك',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('إلغاء', style: TextStyle(color: Color(0xFF139799))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('bookReviews')
                          .doc(userReview['id'])
                          .update({
                            'rating': tempRating,
                            'comment': commentController.text,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                      
                      setState(() {
                        _userRating = tempRating;
                        _userComment = commentController.text;
                      });

                      
                      await _loadBookReviews();

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم تحديث تقييمك بنجاح')),
                      );
                    } catch (e) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ أثناء تحديث التقييم: $e')),
                      );
                    }
                  },
                  child: Text('حفظ التغييرات', style: TextStyle(color: Color(0xFF139799))),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  Widget _buildBorrowButton() {
    if (_isAccountDisabled) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Text(
          'تم تعطيل حسابك حالياً. لا يمكنك استعارة الكتب الآن',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => _submitBorrowRequest(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF139799),
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        'تقديم طلب استعارة',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPendingButton() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber, width: 1),
          ),
          child: Text(
            'لديك طلب معلق - يرجى الحضور لاستلام الكتاب خلال 24 ساعة وإلا سيتم إلغاء طلبك',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.amber.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: Icon(Icons.hourglass_top),
          label: Text(
            'طلبك معلق - في انتظار الاستلام',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotifiedButton() {
    if (_isAccountDisabled) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Text(
          'تم تعطيل حسابك حالياً. لا يمكنك استعارة الكتب الآن',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green, width: 1),
          ),
          child: Text(
            'الكتاب أصبح متوفراً الآن، يمكنك تقديم طلب استعارة. إذا لم تستجب سيتم إلغاء العملية',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _submitBorrowRequest(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF139799),
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: Icon(Icons.book),
          label: Text(
            'استعارة الكتاب',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredButton() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red, width: 1),
          ),
          child: Text(
            'انتهت مهلتك للاستجابة لإشعار توفر الكتاب. يمكنك الانضمام لقائمة الانتظار مرة أخرى',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _addToWaitingList(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: Icon(Icons.watch_later),
          label: Text(
            'انضم إلى قائمة الانتظار مرة أخرى',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingListButton() {
    if (_isAccountDisabled) {
      return _buildDisabledAccountMessage();
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.watch_later, color: Colors.orange),
          SizedBox(width: 8),
          Text(
            'أنت في قائمة الانتظار لهذا الكتاب',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowedButton() {
    return ElevatedButton.icon(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: Icon(Icons.check_circle),
      label: Text(
        'تمت استعارة هذا الكتاب مسبقاً',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDisabledAccountMessage() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Text(
        'تم تعطيل حسابك حالياً. لا يمكنك حجز الكتب الآن',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }




  Widget _buildRatingSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 30),
      Divider(thickness: 1),
      SizedBox(height: 10),
      Text(
        'تقييم الكتاب',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF139799),
        ),
      ),
      SizedBox(height: 10),
      
     
      Row(
        children: [
          Text(
            'التقييم العام: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < _averageRating.floor()
                    ? Icons.star
                    : (_averageRating - index > 0.5 ? Icons.star_half : Icons.star_border),
                color: Colors.amber,
                size: 24,
              );
            }),
          ),
          SizedBox(width: 16),
          Text(
            '(${_averageRating.toStringAsFixed(1)})', 
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(width: 20),
          Text(
            '(${_totalRatings} ${_totalRatings == 1 ? 'تقييم' : 'تقييمات'})', 
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
      
      
      if (_hasUserRated)
        Padding(
          padding: EdgeInsets.only(top: 10),
          child: TextButton(
            onPressed: () {
              _showEditRatingDialog();
            },
            child: Text(
              'تعديل التقييم',
              style: TextStyle(
                color: Color(0xFF139799),
                fontSize: 16,
              ),
            ),
          ),
        )
      else
        Padding(
          padding: EdgeInsets.only(top: 10),
          child: ElevatedButton(
            onPressed: _showRatingDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[50],
              foregroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('أضف تقييمك للكتاب'),
          ),
        ),
      
     
      SizedBox(height: 20),
      Text(
        'آراء القراء',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF139799),
        ),
      ),
      SizedBox(height: 10),
      
      if (_loadingReviews)
        Center(child: CircularProgressIndicator())
      else if (_reviews.isEmpty)
        Text('لا توجد تقييمات بعد، كن أول من يقيم هذا الكتاب!')
      else
        Column(
          children: _reviews.map((review) {
            return Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: review['userPhotoUrl']?.isNotEmpty == true
                            ? Colors.transparent
                            : Colors.blueGrey,
                        backgroundImage: review['userPhotoUrl']?.isNotEmpty == true
                            ? NetworkImage(review['userPhotoUrl'])
                            : null,
                        child: review['userPhotoUrl']?.isNotEmpty == true
                            ? null
                            : Icon(Icons.person, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review['userName'] ?? 'مستخدم',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < (review['rating'] ?? 0)
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (review['comment']?.isNotEmpty == true) ...[
                    SizedBox(height: 8),
                    Text(review['comment']),
                  ],
                  SizedBox(height: 8),
                  Text(
                    _formatDate((review['timestamp'] as Timestamp).toDate()),
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    final String title = widget.bookData['BookTitle'] ?? 'بدون عنوان';
    final String author = widget.bookData['Auther'] ?? 'بدون مؤلف';
    final String category = widget.bookData['Category'] ?? 'غير مصنف';
    final String imageUrl = widget.bookData['ImageUrl'] ?? '';
    final String status = widget.bookData['status'] ?? 'متاح';
    final int availableCopies = widget.bookData['availableCopies'] ?? 0;
    final int totalCopies = widget.bookData['copies'] ?? 0;
    
    Color statusColor = status == 'متاح' ? Colors.green : Colors.orange;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(
            title,
            style: TextStyle(
              color: Color(0xFF139799),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Color(0xFF139799)),
          actions: [
            IconButton(
              icon: _isCheckingFavorite
                  ? CircularProgressIndicator()
                  : Icon(
                      _isBookFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isBookFavorite ? Color(0xFF139799) : Color(0xFF139799),
                      size: 30,
                    ),
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 200,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 10),
                    
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'المؤلف: $author',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 6),
                    
                    Row(
                      children: [
                        Icon(Icons.category, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'التصنيف: $category',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 6),
                    
                    Row(
                      children: [
                        Icon(Icons.book, color: Colors.grey),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'الحالة: $status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 6),
                    
                    Row(
                      children: [
                        Icon(Icons.copy, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'النسخ المتاحة: $availableCopies من أصل $totalCopies',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),

                    if (widget.bookData['description'] != null && 
                        widget.bookData['description'].toString().trim().isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          Text(
                            'وصف الكتاب:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF139799),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            widget.bookData['description'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    
                    
                    SizedBox(height: 20),
                    
                    Center(
                      child: Column(
                        children: [
                          if (isCurrentUserBorrower)
                            _buildBorrowedButton()
                          else if (isPendingRequest)
                            _buildPendingButton()
                          else if (isUserNotifiedForBook)
                            _buildNotifiedButton()
                          else if (isUserRequestExpired)
                            _buildExpiredButton()
                          else if (isUserInWaitingList)
                            _buildWaitingListButton()
                          else if (availableCopies > 0)
                            _buildBorrowButton()
                          else
                            _isAccountDisabled 
                              ? _buildDisabledAccountMessage()
                              : ElevatedButton.icon(
                                  onPressed: () => _addToWaitingList(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: Icon(Icons.watch_later),
                                  label: Text(
                                    'احجز الكتاب وانضم إلى قائمة الانتظار',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                   
                    _buildRatingSection(),
                  ],
                ),
              ),
      ),
    );
  }
}