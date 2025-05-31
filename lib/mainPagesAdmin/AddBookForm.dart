import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:libyyapp/firebase_api.dart';
import 'package:libyyapp/widgets/textformfield.dart';

class Addbookform extends StatefulWidget {
  const Addbookform({super.key});

  @override
  State<Addbookform> createState() => _AddbookformState();
}

class _AddbookformState extends State<Addbookform> with SingleTickerProviderStateMixin {
  bool isShowing = false;
  bool isLoading = false; 
  File? _selectedImage; 

  late Animation<Offset> _animation;
  late AnimationController _animationController;
  final TextEditingController _autherController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _copiesController = TextEditingController(); 
  final TextEditingController _descriptionController = TextEditingController();
  OverlayEntry? _overlayEntry;
  final TextEditingController _titleController = TextEditingController();
  
  
  final cloudinary = CloudinaryPublic(
    'dyvgalhtd', 
    'my_app_preset', 
    cache: false,
  );

  @override
  void dispose() {
    _titleController.dispose();
    _autherController.dispose();
    _categoryController.dispose();
    _copiesController.dispose(); 
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _animation = Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0)).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),);
    _copiesController.text = "1"; 
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
          folder: 'book_covers', 
        ),
      );
      
      //return image url
      return response.secureUrl;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      throw e;
    }
  }

  
  Future<void> addBook() async {
  setState(() {
    isLoading = true;
  });
  
  try {
    // get image url from cloudinary
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImageToCloudinary();
    }
    
    int copies = int.tryParse(_copiesController.text.trim()) ?? 1;
    String status = copies > 0 ? 'متاح' : 'مستعار';
    
    // generating keywords for the search 
    List<String> searchKeywords = _generateSearchKeywords(
      _titleController.text.trim(),
      _autherController.text.trim()
    );
    
    DocumentReference newBookRef = await FirebaseFirestore.instance.collection('Books').add({
      'BookTitle': _titleController.text.trim(),
      'Auther': _autherController.text.trim(),
      'Category': _categoryController.text.trim(),
      'description': _descriptionController.text.trim(),
      'ImageUrl': imageUrl ?? '',
      'status': status,
      'copies': copies,
      'availableCopies': copies,
      'createdAt': FieldValue.serverTimestamp(),
      'searchKeywords': searchKeywords,
      'isHidden': false, // تم إضافة هذا الحقل مع قيمة افتراضية false
    });

    if (mounted) {
      Navigator.of(context).pushReplacementNamed("HomeAdmin");
    }

    _sendNewBookNotification(
      bookTitle: _titleController.text.trim(),
      author: _autherController.text.trim(),
      category: _categoryController.text.trim(),
      bookId: newBookRef.id,
    );
    
  } catch (error) {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
      showTopSnackBar("حدث خطأ أثناء إضافة الكتاب: ${error.toString()}");
      print('Error: ${error.toString()}');
    }
  }
}


List<String> _generateSearchKeywords(String title, String author) {
  
  String processText(String text) {
    return text.replaceAll(' ', '').replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').toLowerCase();
  }

  String processedTitle = processText(title);
  String processedAuthor = processText(author);

  Set<String> keywords = {};

  //generate key words from the title
  for (int i = 1; i <= processedTitle.length; i++) {
    keywords.add(processedTitle.substring(0, i));
  }

  //generate key words from the author 
  for (int i = 1; i <= processedAuthor.length; i++) {
    keywords.add(processedAuthor.substring(0, i));
  }

  
  keywords.add(processedTitle);
  keywords.add(processedAuthor);

  return keywords.toList();
}


  Future<void> _sendNewBookNotification({
  required String bookTitle,
  required String author,
  required String category,
  required String bookId,
}) async {
  try {
    final firebaseApi = FirebaseApi();
    await firebaseApi.sendNewBookNotification(
      bookTitle: bookTitle,
      author: author,
      category: category,
      bookId: bookId,
    );
  } catch (e) {
    print(' error during sending the new book notifications : $e');
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

  @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
  final textScaleFactor = MediaQuery.of(context).textScaleFactor;

  return Scaffold(
    appBar: AppBar(
      title: Text(
        "إضافة كتاب جديد",
        style: TextStyle(
          color: Color(0xFF139799),
          fontSize: screenWidth * 0.045 * textScaleFactor,
          fontWeight: FontWeight.bold,
          fontFamily: 'Zain',
        ),
      ),
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Color(0xFF139799)),
      elevation: 4,
    ),
    body: SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: isPortrait ? screenHeight * 0.02 : screenHeight * 0.01,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover Image
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Container(
                    width: isPortrait ? screenWidth * 0.6 : screenWidth * 0.4,
                    height: isPortrait ? screenHeight * 0.3 : screenHeight * 0.5,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),],
                      border: Border.all(
                        color: Color(0xFF139799).withOpacity(0.3),
                        width: 1.5,
                      ),
                      
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
                                size: screenWidth * 0.15,
                                color: Color(0xFF139799),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Text(
                                "إضافة صورة الكتاب",
                                style: TextStyle(
                                  fontFamily: 'Zain',
                                  color: Color(0xFF139799),
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.035 * textScaleFactor,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // Form Fields
              CustomTextForm(
                hinttext: "عنوان الكتاب",
                myController: _titleController,
                icon: Icons.title_rounded,
                iconSize: screenWidth * 0.06,
                fontSize: screenWidth * 0.04,
              ),
              SizedBox(height: screenHeight * 0.02),

              CustomTextForm(
                hinttext: "اسم المؤلف",
                myController: _autherController,
                icon: Icons.person,
                iconSize: screenWidth * 0.06,
                fontSize: screenWidth * 0.04,
              ),
              SizedBox(height: screenHeight * 0.02),

              CustomTextForm(
                hinttext: "تصنيف الكتاب",
                myController: _categoryController,
                icon: Icons.category,
                iconSize: screenWidth * 0.06,
                fontSize: screenWidth * 0.04,
              ),
              SizedBox(height: screenHeight * 0.02),

              CustomTextForm(
                hinttext: "عدد النسخ",
                myController: _copiesController,
                icon: Icons.copy,
                keyboardType: TextInputType.number,
                iconSize: screenWidth * 0.06,
                fontSize: screenWidth * 0.04,
              ),
              SizedBox(height: screenHeight * 0.02),

              CustomTextForm(
                hinttext: "وصف الكتاب (اختياري)",
                myController: _descriptionController,
                icon: Icons.description,
                maxLines: 3,
                iconSize: screenWidth * 0.06,
                fontSize: screenWidth * 0.04,
              ),
              SizedBox(height: screenHeight * 0.04),

              // Submit Button
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        String title = _titleController.text.trim();
                        String author = _autherController.text.trim();
                        String category = _categoryController.text.trim();
                        String copies = _copiesController.text.trim();

                        if (title.isEmpty || author.isEmpty) {
                          showTopSnackBar("الرجاء إدخال عنوان الكتاب واسم المؤلف");
                          return;
                        }

                        if (copies.isEmpty || int.tryParse(copies) == null || int.parse(copies) < 0) {
                          showTopSnackBar("الرجاء إدخال عدد صحيح موجب للنسخ");
                          return;
                        }

                        if (category.isEmpty) {
                          _categoryController.text = "عام";
                        }

                        addBook();
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(
                    double.infinity,
                    isPortrait ? screenHeight * 0.065 : screenHeight * 0.09,
                  ),
                  backgroundColor: Color(0xFF139799),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: Color(0xFF139799).withOpacity(0.3),
                ),
                child: isLoading
                    ? SizedBox(
                        height: screenHeight * 0.03,
                        width: screenHeight * 0.03,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        "إضافة الكتاب",
                        style: TextStyle(
                          fontFamily: 'Zain',
                          fontSize: screenWidth * 0.04 * textScaleFactor,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
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
}