import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:libyyapp/widgets/textformfield.dart';

class EditBookForm extends StatefulWidget {
  final QueryDocumentSnapshot bookData;

  const EditBookForm({Key? key, required this.bookData}) : super(key: key);

  @override
  State<EditBookForm> createState() => _EditBookFormState();
}

class _EditBookFormState extends State<EditBookForm> with SingleTickerProviderStateMixin {
  bool isShowing = false;
  bool isLoading = false;
  File? _selectedImage;
  String? _currentImageUrl;
  
  late Animation<Offset> _animation;
  late AnimationController _animationController;
  late TextEditingController _titleController;
  late TextEditingController _autherController;
  late TextEditingController _categoryController;
  late TextEditingController _copiesController;
  late TextEditingController _descriptionController;
  OverlayEntry? _overlayEntry;
  
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
    
    final String title = widget.bookData['BookTitle'] ?? 'بدون عنوان';
    final String author = widget.bookData['Auther'] ?? 'بدون مؤلف';
    final String category = widget.bookData['Category'] ?? 'عام';
    final String description = widget.bookData.data() != null && 
                (widget.bookData.data() as Map<String, dynamic>).containsKey('description') 
                ? widget.bookData['description'] 
                : '';
    final int copies = widget.bookData.data() != null && 
                (widget.bookData.data() as Map<String, dynamic>).containsKey('copies') 
                ? widget.bookData['copies'] 
                : 1;
    
    _currentImageUrl = widget.bookData.data() != null && 
                (widget.bookData.data() as Map<String, dynamic>).containsKey('ImageUrl') 
                ? widget.bookData['ImageUrl'] 
                : '';
    
    
    _titleController = TextEditingController(text: title);
    _autherController = TextEditingController(text: author);
    _categoryController = TextEditingController(text: category);
    _copiesController = TextEditingController(text: copies.toString());
    _descriptionController = TextEditingController(text: description);
    

    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _animation = Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0)).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),);
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
    if (_selectedImage == null) return _currentImageUrl;
    
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _selectedImage!.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'book_covers',
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      throw e;
    }
  }

  Future<void> updateBook() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      String? imageUrl = _currentImageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToCloudinary();
      }
      
      int copies = int.tryParse(_copiesController.text.trim()) ?? 1;
      String status = copies > 0 ? 'متاح' : 'مستعار';
      
      await FirebaseFirestore.instance.collection('Books').doc(widget.bookData.id).update({
        'BookTitle': _titleController.text.trim(),
        'Auther': _autherController.text.trim(),
        'Category': _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'ImageUrl': imageUrl ?? '',
        'copies': copies,
        'availableCopies': copies, // يمكنك تعديل هذا حسب احتياجاتك
        'status': status,
      });
      
      Navigator.of(context).pushReplacementNamed("HomeAdmin");
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      showTopSnackBar("حدث خطأ أثناء تحديث الكتاب: ${error.toString()}");
      print('Error updating book: ${error.toString()}');
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
    return Scaffold(
      appBar: AppBar(
        title: Text("تعديل معلومات الكتاب",
          style: TextStyle(color: Color(0xFF139799), fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Color(0xFF139799)),
      ),
      body: SingleChildScrollView(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Center(
                  child: GestureDetector(
                    onTap: () {
                      _showImageSourceOptions();
                    },
                    child: Container(
                      width: 200,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          )
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
                          : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: _currentImageUrl!,
                                    width: double.infinity,
                                    height: double.infinity,
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
                                            "خطأ في تحميل الصورة",
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
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 60,
                                      color: Color(0xFF139799),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      "إضافة صورة الكتاب",
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
                ),
                SizedBox(height: 25),
                
               
                CustomTextForm(hinttext: "عنوان الكتاب", myController: _titleController, icon: Icons.title_rounded),
                SizedBox(height: 20),
                CustomTextForm(hinttext: "اسم المؤلف", myController: _autherController, icon: Icons.person),
                SizedBox(height: 20),
                CustomTextForm(hinttext: "تصنيف الكتاب", myController: _categoryController, icon: Icons.category),
                SizedBox(height: 20),
                CustomTextForm(
                  hinttext: "عدد النسخ", 
                  myController: _copiesController, 
                  icon: Icons.copy,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 20),
                
               
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "وصف الكتاب",
                    hintStyle: TextStyle(fontFamily: 'Zain'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF139799)),
                    ),
                    prefixIcon: Icon(Icons.description, color: Color(0xFF139799)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 25),
                
               
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
                      
                      updateBook();
                    },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Color(0xFF139799),
                  ),
                  child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("حفظ التعديلات", style: TextStyle(fontFamily: 'Zain', fontSize: 18, color: Colors.white)),
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