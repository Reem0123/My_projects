import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:libyyapp/mainPagesAdmin/editBookForm.dart';
import 'package:libyyapp/mainPagesAdmin/ShowpageAdmin.dart';

class LibraryCatalogadminScreen extends StatefulWidget {
  const LibraryCatalogadminScreen({Key? key}) : super(key: key);

  @override
  _LibraryCatalogadminScreenState createState() => _LibraryCatalogadminScreenState();
}

class _LibraryCatalogadminScreenState extends State<LibraryCatalogadminScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<QueryDocumentSnapshot> allBooks = [];
  List<QueryDocumentSnapshot> filteredBooks = [];
  List<QueryDocumentSnapshot> searchSuggestions = [];
  bool isLoading = true;
  String _searchQuery = '';
  Timer? _searchTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      QuerySnapshot booksSnapshot = await FirebaseFirestore.instance
          .collection('Books')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        allBooks = booksSnapshot.docs;
        filteredBooks = allBooks;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading books: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في جلب البيانات')),
      );
    }
  }

  void _filterBooks(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
      
      if (query.isEmpty) {
        filteredBooks = allBooks;
        searchSuggestions = [];
      } else {
        final queryLower = query.toLowerCase();
        
        searchSuggestions = allBooks.where((book) {
          final title = book['BookTitle']?.toString().toLowerCase() ?? '';
          final author = book['Auther']?.toString().toLowerCase() ?? '';
          return title.startsWith(queryLower) || author.startsWith(queryLower);
        }).toList();
        
        filteredBooks = allBooks.where((book) {
          final title = book['BookTitle']?.toString().toLowerCase() ?? '';
          final author = book['Auther']?.toString().toLowerCase() ?? '';
          return title.startsWith(queryLower) || author.startsWith(queryLower);
        }).toList();
      }
    });
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty || !text.toLowerCase().startsWith(query.toLowerCase())) {
      return Text(text, style: TextStyle(color: Colors.grey));
    }

    final matchedText = text.substring(0, query.length);
    final remainingText = text.substring(query.length);

    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.grey),
        children: [
          TextSpan(
            text: matchedText,
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          TextSpan(text: remainingText),
        ],
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      filteredBooks = allBooks;
      searchSuggestions = [];
    });
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'قائمة جميع الكتب', 
            style: TextStyle(
              color: Color(0xFF139799), 
              fontWeight: FontWeight.bold
            ),
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  textDirection: TextDirection.rtl,
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintTextDirection: TextDirection.rtl,
                    hintText: 'ابحث عن كتاب أو  مؤلف ...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF139799)),
                    suffixIcon: _isSearching
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  ),
                  onChanged: (value) {
                    _searchTimer?.cancel();
                    _searchTimer = Timer(const Duration(milliseconds: 300), () {
                      _filterBooks(value);
                    });
                  },
                ),
                if (searchSuggestions.isNotEmpty && _searchQuery.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Directionality(
                       textDirection: TextDirection.rtl,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: searchSuggestions.length > 5 ? 5 : searchSuggestions.length,
                        itemBuilder: (context, index) {
                          final book = searchSuggestions[index];
                          final title = book['BookTitle'] ?? 'بدون عنوان';
                          final author = book['Auther'] ?? 'بدون مؤلف';
                          
                          return ListTile(
                            
                            title: _buildHighlightedText(title, _searchQuery),
                            subtitle: _buildHighlightedText(author, _searchQuery),
                            onTap: () {
                              _showBookDetails(context, book);
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (!_isSearching) Expanded(
            child: _buildBooksList(allBooks),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksList(List<QueryDocumentSnapshot> books) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (books.isEmpty) {
      return Center(
        child: Text(
          'لا توجد كتب متاحة',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return _buildBookCard(books[index]);
      },
    );
  }

  Widget _buildBookCard(QueryDocumentSnapshot book) {
    final String title = book['BookTitle'] ?? 'بدون عنوان';
    final String author = book['Auther'] ?? 'بدون مؤلف';
    final String imageUrl = book['ImageUrl'] ?? '';
    final String status = book['status'] ?? 'متاح';
    final int availableCopies = book['availableCopies'] ?? 0;
    final bool isHidden = book['isHidden'] ?? false;

    Color statusColor = status == 'متاح' ? Colors.green : Colors.orange;

    return GestureDetector(
      onLongPress: () {
        _showBookOptions(context, book);
      },
      onTap: () {
        _showBookDetails(context, book);
      },
      child: Card(
        
        color: Colors.white,
        elevation: 3,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.book),
                      )
                    : Center(child: Icon(Icons.book)),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      author,
                      style: TextStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text('$availableCopies متاحة'),
                      ],
                    ),
                    if (isHidden)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.visibility_off, size: 16, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              'مخفي',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ],
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

  void _showBookOptions(BuildContext context, QueryDocumentSnapshot book) {
    final bool isHidden = book['isHidden'] ?? false;

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
                  title: Text('تعديل الكتاب'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditBookForm(bookData: book),
                      ),
                    ).then((_) => _loadBooks());
                  },
                ),
                ListTile(
                  leading: Icon(isHidden ? Icons.visibility : Icons.visibility_off, 
                      color: isHidden ? Colors.green : Colors.orange),
                  title: Text(isHidden ? 'إظهار في الواجهة' : 'إخفاء من الواجهة'),
                  onTap: () {
                    Navigator.pop(context);
                    if (isHidden) {
                      _unhideBook(book);
                    } else {
                      _hideBook(book);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('حذف نهائي'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, book);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _hideBook(QueryDocumentSnapshot book) async {
    try {
      await FirebaseFirestore.instance
          .collection('Books')
          .doc(book.id)
          .update({'isHidden': true});
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إخفاء الكتاب بنجاح')),
      );
      
      _loadBooks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إخفاء الكتاب')),
      );
    }
  }

  Future<void> _unhideBook(QueryDocumentSnapshot book) async {
    try {
      await FirebaseFirestore.instance
          .collection('Books')
          .doc(book.id)
          .update({'isHidden': false});
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إظهار الكتاب بنجاح')),
      );
      
      _loadBooks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إظهار الكتاب')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, QueryDocumentSnapshot book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('حذف نهائي'),
            content: Text('هل أنت متأكد من حذف هذا الكتاب نهائياً؟ لا يمكن التراجع عن هذه العملية.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteBook(book);
                },
                child: Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteBook(QueryDocumentSnapshot book) async {
    try {
      await FirebaseFirestore.instance
          .collection('Books')
          .doc(book.id)
          .delete();
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف الكتاب نهائياً')),
      );
      
      _loadBooks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف الكتاب')),
      );
    }
  }

  void _showBookDetails(BuildContext context, QueryDocumentSnapshot book) {
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminBookDetailsScreen(bookData: book),
      ),
    ).catchError((error) {
      print('Error navigating to book details: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء فتح تفاصيل الكتاب')),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }
}