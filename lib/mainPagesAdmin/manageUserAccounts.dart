import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

class ManageUserAccounts extends StatefulWidget {
  const ManageUserAccounts({super.key});

  @override
  State<ManageUserAccounts> createState() => _ManageUserAccountsState();
}

class _ManageUserAccountsState extends State<ManageUserAccounts> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleUserAccountStatus(String userId, bool isDisabled) async {
    try {
      await _firestore.collection('Users').doc(userId).update({
        'disabled': !isDisabled,
        'disabledAt': isDisabled ? null : DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isDisabled ? 'تم تفعيل الحساب بنجاح' : 'تم تعطيل الحساب بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'قائمة القراء المسجلين',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF139799),
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF139799)),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('Users')
                            .where('role', isEqualTo: 'reader')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('حدث خطأ في جلب البيانات'),
                            );
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text('لا يوجد قراء مسجلين حالياً'),
                            );
                          }

                          return ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              var userData = snapshot.data!.docs[index];
                              bool isDisabled = userData['disabled'] ?? false;
                              String fullName = '${userData['first name'] ?? ''} ${userData['last name'] ?? ''}'.trim();

                              return Card(
                                color: Colors.white,
                                margin: EdgeInsets.only(bottom: 12),
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            fullName.isNotEmpty ? fullName : 'بدون اسم',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isDisabled ? Colors.grey : Colors.black,
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDisabled ? Colors.red[100] : Colors.green[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isDisabled ? 'معطل' : 'نشط',
                                              style: TextStyle(
                                                color: isDisabled ? Colors.red : Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'البريد الإلكتروني: ${userData['email'] ?? 'غير متوفر'}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'الهاتف: ${userData['phone number'] ?? 'غير متوفر'}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'مكان الإقامة: ${userData['residence city'] ?? ''} - ${userData['residence State'] ?? ''}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () => _toggleUserAccountStatus(
                                          userData.id,
                                          isDisabled,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDisabled ? Colors.green : Colors.red,
                                          minimumSize: Size(double.infinity, 40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          isDisabled ? 'تفعيل الحساب' : 'تعطيل الحساب',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}