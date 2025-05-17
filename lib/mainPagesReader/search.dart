import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:libyyapp/mainPagesAdmin/ShowpageAdmin.dart';
import 'package:libyyapp/mainPagesReader/showpage.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _searchTimer;
  final Map<String, List<DocumentSnapshot>> _searchCache = {};
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

   
    final cacheKey = query + _selectedCategories.join();
    if (_searchCache.containsKey(cacheKey)) {
      setState(() {
        _searchResults = _searchCache[cacheKey]!;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      Query queryRef = FirebaseFirestore.instance
          .collection('Books')
          .where('searchKeywords', arrayContains: query.toLowerCase())
          .orderBy('BookTitle')
          .limit(20);

     
      if (_selectedCategories.isNotEmpty) {
        queryRef = queryRef.where('Category', whereIn: _selectedCategories);
      }

      final result = await queryRef.get();

      setState(() {
        _searchResults = result.docs;
        _isLoading = false;
        _searchCache[cacheKey] = result.docs; 
      });
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في الاتصال بقاعدة البيانات';
        _isLoading = false;
      });
      debugPrint('Firebase error: ${e.message}');
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع';
        _isLoading = false;
      });
      debugPrint('Unexpected error: $e');
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _errorMessage = '';
    });
    _searchFocusNode.requestFocus();
  }

  void _showCategoryFilter(BuildContext context) async {
    final categories = await FirebaseFirestore.instance
        .collection('Books')
        .get()
        .then((snapshot) => snapshot.docs
            .map((doc) => doc['Category'] as String?)
            .where((category) => category != null)
            .toSet()
            .toList());

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تصفية حسب التصنيف'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index]!;
                return CheckboxListTile(
                  title: Text(category),
                  value: _selectedCategories.contains(category),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, _selectedCategories),
              child: const Text('تم'),
            ),
          ],
        ),
      ),
    );

    if (selected != null && _searchController.text.isNotEmpty) {
      _searchBooks(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'بحث عن الكتب',
            style: TextStyle(
              color: Color(0xFF139799),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF139799)),
      ),
      body: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن كتاب...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF139799)),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFF139799)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFF139799)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFF139799), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      _searchTimer?.cancel();
                      _searchTimer = Timer(const Duration(milliseconds: 500), () {
                        _searchBooks(value);
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Color(0xFF139799)),
                  onPressed: () => _showCategoryFilter(context),
                ),
              ],
            ),
          ),

        
          if (_selectedCategories.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedCategories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Chip(
                      label: Text(_selectedCategories[index]),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedCategories.removeAt(index);
                        });
                        if (_searchController.text.isNotEmpty) {
                          _searchBooks(_searchController.text);
                        }
                      },
                      backgroundColor: const Color(0xFF139799).withOpacity(0.1),
                    ),
                  );
                },
              ),
            ),

          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Color(0xFF139799)),
            ),

        
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),

          
          Expanded(
            child: _isSearching
                ? _searchResults.isEmpty && !_isLoading
                    ? const Center(
                        child: Text(
                          'لا توجد نتائج',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final book = _searchResults[index].data() as Map<String, dynamic>;
                          return _buildBookCard(book, _searchResults[index]);
                        },
                      )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 60, color: Color(0xFF139799)),
                        SizedBox(height: 16),
                        Text(
                          'ابحث عن الكتب المتاحة',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book, DocumentSnapshot document) {
    final String title = book['BookTitle'] ?? 'بدون عنوان';
    final String author = book['Auther'] ?? 'بدون مؤلف';
    final String imageUrl = book['ImageUrl'] ?? '';
    final String status = book['status'] ?? 'متاح';
    final int availableCopies = book['availableCopies'] ?? 0;

    Color statusColor = status == 'متاح' 
        ? Colors.green 
        : status == 'غير متاح' 
          ? Colors.orange 
          : Colors.red;

    return GestureDetector(
      onTap: () async {
      try {
        
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(bookData: document),
            ),
          );
          return;
        }

        
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final role = userDoc['role'] as String? ?? 'reader';
          
          if (role == 'admin') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminBookDetailsScreen(bookData: document),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailsScreen(bookData: document),
              ),
            );
          }
        } else {
         
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(bookData: document),
            ),
          );
        }
      } catch (e) {
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsScreen(bookData: document),
          ),
        );
      }
    },
      child: Card(
        elevation: 3,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[200],
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(color: Color(0xFF139799)),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.book, size: 50, color: Colors.grey),
                      )
                    : const Center(
                        child: Icon(Icons.book, size: 50, color: Colors.grey),
                      ),
              ),
            ),

            
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    author,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
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
                      Text(
                        '$availableCopies متاحة',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}