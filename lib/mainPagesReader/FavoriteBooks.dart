import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:libyyapp/mainPagesReader/showpage.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<DocumentSnapshot> _favoriteBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .orderBy('addedAt', descending: true)
          .get();


      List<Future<DocumentSnapshot>> bookFutures = [];
      for (var favDoc in snapshot.docs) {
        String bookId = favDoc['bookId'];
        bookFutures.add(
          FirebaseFirestore.instance.collection('Books').doc(bookId).get(),
        );
      }

      List<DocumentSnapshot> books = await Future.wait(bookFutures);
      
      setState(() {
        _favoriteBooks = books.where((book) => book.exists).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('كتبي المفضلة',style: TextStyle(color: Color(0xFF139799)),),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Color(0xFF139799)),
      ),
      body: _isLoading
          ?  Center(child: CircularProgressIndicator())
          : _favoriteBooks.isEmpty
              ? Center(child: Text('لا توجد كتب في المفضلة بعد'))
              : GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _favoriteBooks.length,
                  itemBuilder: (context, index) {
                    return Directionality(
                        textDirection: TextDirection.rtl,
                      child: BookCard(
                        bookData: _favoriteBooks[index],
                      ),
                    );
                  },
                ),
    );
  }
}