import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class NewsUser extends StatefulWidget {
  const NewsUser({super.key});

  @override
  State<NewsUser> createState() => _NewsUserState();
}

class _NewsUserState extends State<NewsUser> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text("الأخبار والأنشطة",
            style: TextStyle(
              color: Color(0xFF139799),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Zain',
            ),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Color(0xFF139799)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('News').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ في تحميل الأخبار', style: TextStyle(fontFamily: 'Zain')));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFF139799)));
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "لا توجد أخبار متاحة حالياً",
                style: TextStyle(fontFamily: 'Zain', fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var newsItem = snapshot.data!.docs[index];
              Timestamp timestamp = newsItem['createdAt'] as Timestamp;
              DateTime date = timestamp.toDate();
              String formattedDate = intl.DateFormat('yyyy/MM/dd - hh:mm a').format(date);

              return Card(
                color: const Color.fromARGB(228, 255, 255, 255),
                margin: EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                   
                    if (newsItem['imageUrl'] != null && newsItem['imageUrl'].toString().isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          newsItem['imageUrl'],
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            newsItem['title'],
                            style: TextStyle(
                              fontFamily: 'Zain',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF139799),
                            ),
                            textAlign: TextAlign.right,
                          ),
                          SizedBox(height: 8),
                          Text(
                            newsItem['content'],
                            style: TextStyle(
                              fontFamily: 'Zain',
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          SizedBox(height: 12),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontFamily: 'Zain',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}