import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:libyyapp/widgets/textformfield.dart';

class EditNewsPage extends StatefulWidget {
  final String docId;
  final String initialTitle;
  final String initialContent;
  final String initialImageUrl;

  const EditNewsPage({
    required this.docId,
    required this.initialTitle,
    required this.initialContent,
    required this.initialImageUrl,
    Key? key,
  }) : super(key: key);

  @override
  _EditNewsPageState createState() => _EditNewsPageState();
}

class _EditNewsPageState extends State<EditNewsPage> with SingleTickerProviderStateMixin {
  bool isShowing = false;
  bool isLoading = false;
  File? _selectedImage;
  String? _currentImageUrl;
  
  late Animation<Offset> _animation;
  late AnimationController _animationController;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  OverlayEntry? _overlayEntry;
  
  final cloudinary = CloudinaryPublic(
    'dyvgalhtd',
    'my_app_preset',
    cache: false,
  );

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _currentImageUrl = widget.initialImageUrl;
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateNews() async {
    setState(() => isLoading = true);
    
    try {
      String? imageUrl = _currentImageUrl;
      
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToCloudinary();
      }
      
      await FirebaseFirestore.instance.collection('News').doc(widget.docId).update({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print("secces update");
      Navigator.pop(context);
    } catch (e) {
      
      print('Error updating news: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
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
      print('Error uploading image: $e');
      throw e;
    }
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
        title: Text("تعديل الخبر",
          style: TextStyle(
            color: Color(0xFF139799),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Zain',
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Color(0xFF139799)),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updateNews,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Container(
                    width: 200,
                    height: 200,
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
                                    "تغيير صورة الخبر",
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
              
              
              CustomTextForm(
                hinttext: "عنوان الخبر",
                myController: _titleController,
                icon: Icons.title,
              ),
              SizedBox(height: 20),
              
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "محتوى الخبر",
                  hintStyle: TextStyle(fontFamily: 'Zain'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF139799)),
                  ),
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
                        _updateNews();
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Color(0xFF139799),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "حفظ التعديلات",
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