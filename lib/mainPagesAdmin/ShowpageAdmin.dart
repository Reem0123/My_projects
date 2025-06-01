import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:libyyapp/mainPagesAdmin/borrowersList.dart';
import 'package:libyyapp/mainPagesAdmin/editBookForm.dart';
import 'package:libyyapp/mainPagesAdmin/waitingList.dart';



class Showpageadmin extends StatefulWidget {
  const Showpageadmin({super.key});
  @override
  State<Showpageadmin> createState() => _ShowpageadminState();
}

class _ShowpageadminState extends State<Showpageadmin> {
  Map<String, List<QueryDocumentSnapshot>> categorizedBooks = {};
  List<String> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Books')
        .where('isHidden', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

       print("عدد الكتب الجديدة: ${querySnapshot.docs.length}");


    for (var doc in querySnapshot.docs) {
      print("عنوان الكتاب: ${doc['BookTitle']}, isHidden: ${doc['isHidden']}");
    }

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
  if (e is FirebaseException) {
    print("Firebase error code: ${e.code}");
    print("Firebase error message: ${e.message}");
  }
  setState(() {
    isLoading = false;
  });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed("AddBookForm");
        },
        child: Icon(Icons.add, color: Colors.white), 
        backgroundColor: Color(0xFF139799), 
        tooltip: 'إضافة',
        shape: CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      backgroundColor: Colors.white,
      body: Directionality(
          textDirection:TextDirection.rtl,
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
                backgroundColor: Colors.white,
                child: categories.isEmpty
                  ? Center(
                      child: Text(
                        "لا توجد كتب حاليًا",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding:  EdgeInsets.all(10),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        String category = categories[index];
                        List<QueryDocumentSnapshot> books = categorizedBooks[category] ?? [];
                        
                        return Column(
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
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(context,MaterialPageRoute(builder: (context) => 
                                        CategoryBooksScreen(
                                          categoryName: category,
                                          books: books,
                                          isAdmin: true,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
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
                            
                            SizedBox(height: 20),
                            
                            
                            SizedBox(
                              height: 280,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: books.length,
                                itemBuilder: (context, bookIndex) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 15),
                                    child: BookCard(
                                      bookData: books[bookIndex],
                                      isAdmin: true,
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            SizedBox(height: 30),
                          ],
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
  final bool isAdmin;
  
  const CategoryBooksScreen({
    Key? key,
    required this.categoryName,
    required this.books,
    this.isAdmin = false,
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
      floatingActionButton: isAdmin ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed("AddBookForm");
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFF139799),
        tooltip: 'إضافة',
        shape: CircleBorder(),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 3,
              mainAxisSpacing: 10,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return BookCard(
                bookData: books[index],
                isAdmin: isAdmin,
              );
            },
          ),
        ),
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  final QueryDocumentSnapshot bookData;
  final bool isAdmin;

  const BookCard({
    required this.bookData,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final String title = bookData['BookTitle'] ?? 'بدون عنوان';
    final String author = bookData['Auther'] ?? 'بدون مؤلف';
    final String imageUrl = bookData.data() != null && 
                     (bookData.data() as Map<String, dynamic>).containsKey('ImageUrl') 
                     ? bookData['ImageUrl'] 
                     : '';
    final String status = bookData.data() != null && 
                    (bookData.data() as Map<String, dynamic>).containsKey('status') 
                    ? bookData['status'] 
                    : 'متاح';
    final int availableCopies = bookData.data() != null && 
                    (bookData.data() as Map<String, dynamic>).containsKey('availableCopies') 
                    ? bookData['availableCopies'] 
                    : 0;
    Color statusColor;
    switch (status) {
      case 'متاح':
        statusColor = Colors.green;
        break;
      case 'غير متاح':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.green;
    }
    
    return GestureDetector(
      onTap: () {
        
          Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminBookDetailsScreen(bookData: bookData),
      ),
    );
       
      },
      onLongPress: (){
        _showAdminOptions(context, bookData);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 160,
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
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF139799),
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
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

void _showAdminOptions(BuildContext context, QueryDocumentSnapshot bookData) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Color(0xFF139799)),
                title: Text('تعديل معلومات الكتاب'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditBookForm(
                        bookData: bookData,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.visibility_off, color: Colors.orange),
                title: Text('إخفاء الكتاب من الواجهة الرئيسية'),
                onTap: () {
                  Navigator.pop(context);
                  _showHideConfirmation(context, bookData);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}


void _showHideConfirmation(BuildContext context, QueryDocumentSnapshot bookData) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('إخفاء الكتاب'),
          content: Text('هل أنت متأكد من إخفاء هذا الكتاب من الواجهة الرئيسية؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('Books')
                    .doc(bookData.id)
                    .update({'isHidden': true});
                Navigator.of(context).pop();
                print('تم إخفاء الكتاب بنجاح');
                
                Navigator.of(context).pushReplacementNamed('HomeAdmin');
              },
              child: Text('إخفاء', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
    },
  );
}
}

class AdminBookDetailsScreen extends StatefulWidget {
  final DocumentSnapshot  bookData;
  
  const AdminBookDetailsScreen({
    Key? key,
    required this.bookData,
  }) : super(key: key);

  @override
  State<AdminBookDetailsScreen> createState() => _AdminBookDetailsScreenState();
}

class _AdminBookDetailsScreenState extends State<AdminBookDetailsScreen> {
  List<QueryDocumentSnapshot> currentBorrowers = [];
  List<QueryDocumentSnapshot> waitingUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBorrowersAndWaitingList();
  }
Future<void> _loadBorrowersAndWaitingList() async {
  try {
    setState(() {
      isLoading = true;
    });
    
    
    QuerySnapshot borrowersSnapshot = await FirebaseFirestore.instance
        .collection('BorrowRequestsList')
        .where('bookId', isEqualTo: widget.bookData.id)
        .get();

    QuerySnapshot waitingSnapshot = await FirebaseFirestore.instance
        .collection('WaitingList')  
        .where('bookId', isEqualTo: widget.bookData.id)
        .get();

    setState(() {
      currentBorrowers = borrowersSnapshot.docs;
      waitingUsers = waitingSnapshot.docs;
      isLoading = false;
    });
  } catch (e) {
    print('Error loading data: $e');
    setState(() {
      currentBorrowers = [];
      waitingUsers = [];
      isLoading = false;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    final book = widget.bookData;
    final String title = book['BookTitle'] ?? 'بدون عنوان';
    final String author = book['Auther'] ?? 'بدون مؤلف';
    final String imageUrl = book['ImageUrl'] ?? '';
    final int availableCopies = book['availableCopies'] ?? 0;
    final int totalCopies = book['copies'] ?? 0;
    final String status = book['status'] ?? 'متاح';
    final String category = book['Category'] ?? 'غير مصنف';

    Color statusColor = status == 'متاح' 
        ? Colors.green 
        : status == 'غير متاح' 
          ? Colors.orange 
          : Colors.red;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Center(
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

                    SizedBox(height: 10),
                    
                     
                    if (book['description'] != null && book['description'].toString().trim().isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          Text(
                            'وصف الكتاب:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF139799),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            book['description'],
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    
                
      
                      SizedBox(height: 20),
      
                     
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey[300]!))
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BorrowersListScreen(
                                  bookId: book.id, 
                                  bookTitle: title, 
                                  bookData:book,
                                ),
                              ),
                            );
                             _loadBorrowersAndWaitingList();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'سجل الاستعارة(${currentBorrowers.length})',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF139799)),
                              ],
                            ),
                          ),
                        ),
                      ),
      
                    
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey[300]!))
                        ),
                        child: InkWell(
                          onTap: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WaitingListScreen(
                                  bookId: book.id, 
                                  bookTitle: title, 
                                  bookData:book,
                                ),
                              ),
                            );
                             _loadBorrowersAndWaitingList();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'قائمة الانتظار (${waitingUsers.length})',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF139799)),
                              ],
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
}