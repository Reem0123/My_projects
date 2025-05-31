import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

class UserProfileCard extends StatefulWidget {
  const UserProfileCard({super.key});

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
    _fetchUserData();
  }


  @override
void dispose() {
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  super.dispose();
}

  Future<void> _fetchUserData() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'يجب تسجيل الدخول أولاً';
        });
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'لم يتم العثور على بيانات المستخدم';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'حدث خطأ في جلب البيانات: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('بطاقة المكتبة',style: TextStyle(color: Color(0xFF139799),fontWeight: FontWeight.bold, ),),
          centerTitle: true,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Color(0xFF139799)),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : userData == null
                    ? const Center(child: Text('لا توجد بيانات متاحة'))
                    : Center(
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Container(
                            width: 600,
                            height: 350,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    
                                    Text(
                                      'بطاقة المكتبة',
                                      style: TextStyle(
                                        fontSize: 24, 
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF139799),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                         
                                          Container(
                                            margin: const EdgeInsets.only(left: 10, bottom:100),
                                            child: CircleAvatar(
                                              radius: 50, 
                                              backgroundColor: Colors.grey[200],
                                              backgroundImage: userData!['profile_image'] != null &&
                                                      (userData!['profile_image'] as String).isNotEmpty
                                                  ? CachedNetworkImageProvider(
                                                      userData!['profile_image'] as String)
                                                  : null,
                                              child: userData!['profile_image'] == null ||
                                                      (userData!['profile_image'] as String).isEmpty
                                                  ? Icon(Icons.person, size: 50, color: Colors.grey)
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                               
                                                _buildInlineInfoRow(
                                                  label1: 'الإسم', 
                                                  value1: userData!['first name'] as String,
                                                  label2: 'اللقب', 
                                                  value2: userData!['last name'] as String,
                                                  
                                                ),
                                               
                                                _buildInlineInfoRow(
                                                  label1: 'تاريخ الميلاد', 
                                                  value1: _formatDate(userData!['birth date']),
                                                  label2: 'مكان الميلاد', 
                                                  value2: userData!['birth place'] as String,
                                                ),
                                              
                                                // هذا هو الجزء المعدل لعرض العنوان
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        'العنوان: ',
                                                        style: TextStyle(
                                                          fontSize: 16, 
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF139799),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          '${userData!['residence State']} - ${userData!['residence city']}',
                                                          style: const TextStyle(
                                                            fontSize: 16, 
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              
                                                // تم إزالة البريد الإلكتروني هنا وترك الهاتف فقط
                                                _buildInfoItem('الهاتف', userData!['phone number'] as String),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),
                                    Divider(thickness: 1.5, color: Colors.grey),
                                    const SizedBox(height: 10),

                                  
                                    Text(
                                      'رقم العضوية: ${FirebaseAuth.instance.currentUser?.uid.substring(0, 8).toUpperCase()}',
                                      style: TextStyle(
                                        fontSize: 18, 
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF139799),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildInlineInfoRow({
    required String label1, 
    required String value1,
    required String label2, 
    required String value2,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10), 
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(label1, value1),
          ),
          const SizedBox(width: 20), 
          Expanded(
            child: _buildInfoItem(label2, value2),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            color: Color(0xFF139799),
          ),
        ),
        const SizedBox(width: 8), 
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16, 
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '--/--/----';
    
    if (date is Timestamp) {
      DateTime d = date.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } else if (date is DateTime) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return date.toString();
  }
}