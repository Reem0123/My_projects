import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoreadminPage extends StatefulWidget {
  const MoreadminPage({super.key});

  @override
  State<MoreadminPage> createState() => _MoreadminPageState();
}

class _MoreadminPageState extends State<MoreadminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('Users').doc(user.uid).get();
    setState(() {
      _isAdmin = doc.exists && doc.data()?['role'] == 'admin';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Center(child: Text('المزيد',style: TextStyle(color: Color(0xFF139799),fontWeight: FontWeight.bold),)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Color(0xFF139799)),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          children: [
            _buildSettingItem(
              context: context,
              title: 'الأسئلة الشائعة',
              icon: Icons.help_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FAQPage(isAdmin: _isAdmin)),
                );
              },
            ),
            Divider(height: 1,),
            
            _buildInfoCard(
              title: 'ساعات العمل والموقع',
              content: '''
                8 AM - 4 PM
              ولاية عنابة وسط المدينة بجانب دار الثقافة
                              ''',
              icon: Icons.access_time,
            ),
            SizedBox(height: 10,),
            _buildInfoCard(
              title: 'تواصل معنا',
              content: 'BerketSouleimanLibrary@gmail.com',
              icon: Icons.contact_mail,
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content, required IconData icon}) {
    return Card(
      color: const Color.fromARGB(237, 255, 255, 255),
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF139799)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF139799)),
            const SizedBox(width: 15),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16)),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF139799)),
          ],
        ),
      ),
    );
  }
}

class FAQPage extends StatefulWidget {
  final bool isAdmin;
  const FAQPage({super.key, required this.isAdmin});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأسئلة الشائعة',style: TextStyle(color: Color(0xFF139799),fontWeight: FontWeight.bold),),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Color(0xFF139799)),
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF139799),
              child: const Icon(Icons.add,color: Colors.white,),
              onPressed: () => _showAddFAQDialog(context),
            )
          : null,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('FAQs').orderBy('createdAt').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('لا توجد أسئلة متاحة حالياً'));
            }

            final faqs = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                final faq = faqs[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(
                      faq['question'],
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          faq['answer'],
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      if (widget.isAdmin)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteFAQ(faq.id),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showAddFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('إضافة سؤال جديد',style: TextStyle(color: Color(0xFF139799)),),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    labelText: 'السؤال',

                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _answerController,
                  decoration: const InputDecoration(
                    labelText: 'الإجابة',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء',style: TextStyle(color: Color.fromARGB(255, 94, 94, 94))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF139799),
              ),
              onPressed: () {
                _addFAQ();
                Navigator.pop(context);
              },
              child: const Text('حفظ',style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addFAQ() async {
    if (_questionController.text.isEmpty || _answerController.text.isEmpty) {
      return;
    }

    await _firestore.collection('FAQs').add({
      'question': _questionController.text,
      'answer': _answerController.text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _questionController.clear();
    _answerController.clear();
  }

  Future<void> _deleteFAQ(String id) async {
    await _firestore.collection('FAQs').doc(id).delete();
  }
}