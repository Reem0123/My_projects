import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:intl/intl.dart' as intl;
import 'package:libyyapp/firebase_api.dart';
import 'package:libyyapp/mainPagesAdmin/editNewsForm.dart';
import 'package:libyyapp/widgets/textformfield.dart';

class Newsadmin extends StatefulWidget {
  const Newsadmin({super.key});

  @override
  State<Newsadmin> createState() => _NewsadminState();
}

class _NewsadminState extends State<Newsadmin> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


Future<void> _deleteNews(String docId) async {
  try {
    await _firestore.collection('News').doc(docId).delete();
    print("done deleting news ");
        
  } catch (e) {
      print("error during deleting : ${e.toString()}");
    
  }
}


void _showEditDeleteOptions(String docId, Map<String, dynamic> newsData) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Color(0xFF139799)),
                title: Text("تعديل الخبر", style: TextStyle(fontFamily: 'Zain')),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditPage(docId, newsData);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text("حذف الخبر", style: TextStyle(fontFamily: 'Zain')),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNews(docId);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

// دالة الانتقال إلى صفحة التعديل
void _navigateToEditPage(String docId, Map<String, dynamic> newsData) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditNewsPage(
        docId: docId,
        initialTitle: newsData['title'],      
        initialContent: newsData['content'],   
        initialImageUrl: newsData['imageUrl'],
      ),
    ),
  );
}

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

              return GestureDetector(
                onLongPress: () {
                  _showEditDeleteOptions(
                    newsItem.id,
                    {
                      'title': newsItem['title'],
                      'content': newsItem['content'],
                      'imageUrl': newsItem['imageUrl'],
                    },
                  );
                },
                child: Card(
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
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AddNewsPage()));
        },
        backgroundColor: Color(0xFF139799),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class AddNewsPage extends StatefulWidget {
  const AddNewsPage({super.key});

  @override
  State<AddNewsPage> createState() => _AddNewsPageState();
}

class _AddNewsPageState extends State<AddNewsPage> with SingleTickerProviderStateMixin {
  bool isShowing = false;
  bool isLoading = false;
  File? _selectedImage;
  
  late Animation<Offset> _animation;
  late AnimationController _animationController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  OverlayEntry? _overlayEntry;
  
  final cloudinary = CloudinaryPublic(
    'dyvgalhtd', 
    'my_app_preset', 
    cache: false,
  );

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: Duration(milliseconds: 500)
    );
    _animation = Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0)).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  void showTopSnackBar(String message) {
    if (isShowing) {
      _animationController.forward(from: 0);
      return;
    }

    isShowing = true;
    _overlayEntry = _createOverlayEntry(message);
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();

    Future.delayed(Duration(seconds: 2), () {
      _animationController.reverse().then((_) {
        _overlayEntry?.remove();
        isShowing = false;
      });
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _captureImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? capturedImage = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (capturedImage != null) {
      setState(() {
        _selectedImage = File(capturedImage.path);
      });
    }
  }

  Future<String?> _uploadImageToCloudinary() async {
    if (_selectedImage == null) return null;
    
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _selectedImage!.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'news_images',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      throw e;
    }
  }

  Future<void> addNews() async {
  setState(() {
    isLoading = true;
  });
  
  try {
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImageToCloudinary();
    }
    
    final newsTitle = _titleController.text.trim();
    final newsContent = _contentController.text.trim();
    
    
    await FirebaseFirestore.instance.collection('News').add({
      'title': newsTitle,
      'content': newsContent,
      'imageUrl': imageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    
    if (mounted) {
      Navigator.pop(context);
    }

  
    _sendNewsNotificationInBackground(
      newsTitle: newsTitle,
      newsContent: newsContent,
    );
    
   
    _titleController.clear();
    _contentController.clear();
    if (mounted) {
      setState(() {
        _selectedImage = null;
      });
    }
    
    print("تمت إضافة الخبر بنجاح");
    
  } catch (error) {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
      print("حدث خطأ أثناء إضافة الخبر: ${error.toString()}");
      showTopSnackBar("حدث خطأ أثناء إضافة الخبر");
    }
  }
}

void _sendNewsNotificationInBackground({
  required String newsTitle,
  required String newsContent,
}) async {
  try {
    final firebaseApi = FirebaseApi();
    await firebaseApi.sendNewNewsNotification(
      newsTitle: newsTitle,
      newsContent: newsContent,
    );
  } catch (e) {
    print('Failed to send news notification: $e');
  }
}
  OverlayEntry _createOverlayEntry(String message) {
    return OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: MediaQuery.of(context).size.width * 0.1,
        width: MediaQuery.of(context).size.width * 0.8,
        child: SlideTransition(
          position: _animation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Zain', fontSize: 16, color: Colors.black),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "اختر مصدر الصورة",
                  style: TextStyle(
                    fontFamily: 'Zain',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        _captureImage();
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Color(0xFF139799).withOpacity(0.1),
                            child: Icon(
                              Icons.camera_alt,
                              size: 30,
                              color: Color(0xFF139799),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text("الكاميرا", style: TextStyle(fontFamily: 'Zain')),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickImage();
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Color(0xFF139799).withOpacity(0.1),
                            child: Icon(
                              Icons.photo_library,
                              size: 30,
                              color: Color(0xFF139799),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text("المعرض", style: TextStyle(fontFamily: 'Zain')),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إضافة خبر جديد",
          style: TextStyle(
            color: Color(0xFF139799),
            fontFamily: 'Zain',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Color(0xFF139799)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              
              GestureDetector(
                onTap: () {
                  _showImageSourceOptions();
                },
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: Color(0xFF139799),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "إضافة صورة للخبر",
                              style: TextStyle(
                                fontFamily: 'Zain',
                                color: Color(0xFF139799),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 20),
              CustomTextForm(
                hinttext: "عنوان الخبر ", 
                myController: _titleController, 
                icon: Icons.title,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "محتوى الخبر ",
                  hintStyle: TextStyle(fontFamily: 'Zain'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF139799)),
                  ),
                  prefixIcon: Icon(Icons.article, color: Color(0xFF139799)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (_titleController.text.trim().isEmpty) {
                          showTopSnackBar("الرجاء إدخال عنوان الخبر");
                          return;
                        }
                        if (_contentController.text.trim().isEmpty) {
                          showTopSnackBar("الرجاء إدخال محتوى الخبر");
                          return;
                        }
                        addNews();
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Color(0xFF139799),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("إضافة الخبر",
                        style: TextStyle(
                          fontFamily: 'Zain',
                          fontSize: 18,
                          color: Colors.white,
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