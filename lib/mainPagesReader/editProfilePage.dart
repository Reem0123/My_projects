import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:libyyapp/widgets/textformfield.dart';

class EditProfilePage extends StatefulWidget {
  final String userId;

  const EditProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> with SingleTickerProviderStateMixin {
  bool isShowing = false;
  bool isLoading = true; 
  File? _selectedImage;
  String? _currentImageUrl;
  Map<String, dynamic> userData = {};
  Timer? _snackBarTimer;

  late Animation<Offset> _animation;
  late AnimationController _animationController;
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;
  late TextEditingController _birthPlaceController;
  late TextEditingController _residenceStateController;
  late TextEditingController _residenceCityController;
  OverlayEntry? _overlayEntry;
  
  final cloudinary = CloudinaryPublic(
    'dyvgalhtd',
    'my_app_preset',
    cache: false,
  );

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    _overlayEntry?.remove();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _birthPlaceController.dispose();
    _residenceStateController.dispose();
    _residenceCityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    _firstnameController = TextEditingController();
    _lastnameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _birthDateController = TextEditingController();
    _birthPlaceController = TextEditingController();
    _residenceStateController = TextEditingController();
    _residenceCityController = TextEditingController();
    
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _animation = Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0)).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
      
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        
        setState(() {
          userData = data;
          
          _firstnameController.text = data['first name'] ?? '';
          _lastnameController.text = data['last name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone number'] ?? '';
          
          if (data['birth date'] != null) {
            if (data['birth date'] is Timestamp) {
              _birthDateController.text = (data['birth date'] as Timestamp)
                  .toDate()
                  .toString()
                  .split(' ')[0];
            } else {
              _birthDateController.text = data['birth date'].toString();
            }
          }
          
          _birthPlaceController.text = data['birth place'] ?? '';
          _residenceStateController.text = data['residence State'] ?? '';
          _residenceCityController.text = data['residence city'] ?? '';
          
          _currentImageUrl = data.containsKey('profile_image') 
              ? data['profile_image'] 
              : '';
              
          if (_currentImageUrl == null || _currentImageUrl!.isEmpty) {
            if (data.containsKey('profile_Image')) {
              _currentImageUrl = data['profile_Image'];
            } else if (data.containsKey('profileImage')) {
              _currentImageUrl = data['profileImage'];
            }
          }
          
          isLoading = false;
        });
      } else {
        print("وثيقة المستخدم غير موجودة");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("خطأ في تحميل بيانات المستخدم: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void showTopSnackBar(String message) {
    if (isShowing) {
      if (mounted) {
        _animationController.forward(from: 0);
      }
      return;
    }

    isShowing = true;
    _overlayEntry = _createOverlayEntry(message);
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();

    _snackBarTimer?.cancel();
    _snackBarTimer = Timer(Duration(seconds: 2), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          _overlayEntry?.remove();
          isShowing = false;
        });
      } else {
        _overlayEntry?.remove();
        isShowing = false;
      }
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


void _removeImage() {
  setState(() {
    _selectedImage = null;
    _currentImageUrl = null;
  });
}

  Future<String?> _uploadImageToCloudinary() async {
    if (_selectedImage == null) return _currentImageUrl; 
    
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _selectedImage!.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'profile_images', 
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      throw e;
    }
  }

  Future<void> updateProfile() async {
  setState(() {
    isLoading = true;
  });
  
  try {
    User? currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      throw Exception("لم يتم العثور على المستخدم الحالي");
    }
    
    String? imageUrl = _currentImageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImageToCloudinary();
    }
    // إذا كانت الصورة قد أزيلت
    else if (_currentImageUrl == null && userData['profile_image'] != null) {
      imageUrl = ''; // إعداد قيمة فارغة لإزالة الصورة
    }
    
    DateTime birthDate;
    try {
      birthDate = DateTime.parse(_birthDateController.text);
    } catch (e) {
      showTopSnackBar("صيغة التاريخ غير صحيحة. الرجاء استخدام صيغة YYYY-MM-DD");
      setState(() {
        isLoading = false;
      });
      return;
    }
    
    // تحضير بيانات التحديث
    Map<String, dynamic> updateData = {
      'first name': _firstnameController.text.trim(),
      'last name': _lastnameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone number': _phoneController.text.trim(),
      'birth date': birthDate,
      'birth place': _birthPlaceController.text.trim(),
      'residence State': _residenceStateController.text.trim(),
      'residence city': _residenceCityController.text.trim(),
    };
    
    // إضافة صورة الملف الشخصي فقط إذا كانت متوفرة
    if (imageUrl != null) {
      updateData['profile_image'] = imageUrl;
    } else {
      updateData['profile_image'] = ''; // أو يمكن استخدام null إذا كنت تفضل ذلك
    }
    
    // تنفيذ التحديث في Firestore
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .update(updateData);
    
    // تحديث البريد الإلكتروني في Firebase Auth إذا تغير
    if (currentUser.email != _emailController.text.trim()) {
      await currentUser.updateEmail(_emailController.text.trim());
    }
    
    setState(() {
      isLoading = false;
    });
    
    // إظهار رسالة نجاح وإغلاق الصفحة
    showTopSnackBar("تم تحديث الملف الشخصي بنجاح");
    Navigator.of(context).pop(true);
    
  } catch (error) {
    setState(() {
      isLoading = false;
    });
    
    String errorMessage = "حدث خطأ أثناء تحديث الملف الشخصي";
    
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'requires-recent-login':
          errorMessage = "يتطلب هذا الإجراء تسجيل الدخول حديثاً. الرجاء تسجيل الخروج ثم الدخول مرة أخرى";
          break;
        case 'email-already-in-use':
          errorMessage = "البريد الإلكتروني مستخدم بالفعل من قبل حساب آخر";
          break;
        case 'invalid-email':
          errorMessage = "البريد الإلكتروني غير صالح";
          break;
        default:
          errorMessage = "خطأ في المصادقة: ${error.message}";
      }
    } else if (error is FirebaseException) {
      errorMessage = "خطأ في قاعدة البيانات: ${error.message}";
    }
    
    showTopSnackBar(errorMessage);
    print('Error updating profile: ${error.toString()}');
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
        title: Text("تعديل الملف الشخصي",
          style: TextStyle(color: Color(0xFF139799), fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Color(0xFF139799)),
      ),
      body: isLoading 
          ? Center(child: CircularProgressIndicator(color: Color(0xFF139799)))
          : SingleChildScrollView(
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
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),)
                              ],
                            ),
                            child: _selectedImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      _selectedImage!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                                    ? ClipOval(
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
                                            child: Icon(Icons.person, color: Color(0xFF139799), size: 60),
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Color(0xFF139799),
                                      ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: Text("تغيير الصورة الشخصية", 
                          style: TextStyle(fontFamily: 'Zain', color: Colors.grey[700])),
                      ),
                      SizedBox(height: 25),
                      
                      CustomTextForm(hinttext: "الاسم", myController: _firstnameController, icon: Icons.person),
                      SizedBox(height: 20),
                      CustomTextForm(hinttext: "اللقب", myController: _lastnameController, icon: Icons.person),
                      SizedBox(height: 20),
                      CustomTextForm(hinttext: "البريد الالكتروني", myController: _emailController, icon: Icons.email),
                      SizedBox(height: 20),
                      CustomTextForm(hinttext: "رقم الهاتف", myController: _phoneController, icon: Icons.phone),
                      SizedBox(height: 20),
                      CustomTextForm(
                        hinttext: "تاريخ الميلاد",
                        myController: _birthDateController,
                        icon: Icons.calendar_today,
                        isDatePicker: true,
                      ),
                      SizedBox(height: 20),
                      CustomTextForm(
                        hinttext: "ولاية الميلاد",
                        myController: _birthPlaceController,
                        icon: Icons.location_on,
                      ),
                      SizedBox(height: 20),
                      CustomTextForm(
                        hinttext: "ولاية السكن",
                        myController: _residenceStateController,
                        icon: Icons.location_city,
                      ),
                      SizedBox(height: 20),
                      CustomTextForm(
                        hinttext: "بلدية السكن",
                        myController: _residenceCityController,
                        icon: Icons.home,
                      ),
                      SizedBox(height: 30),
                     
                      ElevatedButton(
                        onPressed: isLoading
                          ? null 
                          : () {
                            String firstname = _firstnameController.text.trim();
                            String lastname = _lastnameController.text.trim();
                            String email = _emailController.text.trim();
                            String phone = _phoneController.text.trim();
                            String birthDate = _birthDateController.text.trim();
                            String birthPlace = _birthPlaceController.text.trim();
                            String residenceState = _residenceStateController.text.trim();
                            String residenceCity = _residenceCityController.text.trim();
                            String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                              
                            if (firstname.isEmpty || lastname.isEmpty || email.isEmpty || phone.isEmpty) {
                              showTopSnackBar("يجب إدخال الاسم واللقب والبريد الإلكتروني ورقم الهاتف");
                              return;
                            }
                            
                            if (!RegExp(emailPattern).hasMatch(email)) {
                              showTopSnackBar("الرجاء إدخال بريد إلكتروني صالح");
                              return;
                            }
                            
                            if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
                              showTopSnackBar("يجب أن يحتوي رقم الهاتف على 10 أرقام فقط");
                              return;
                            }
                            
                            if (birthDate.isEmpty) {
                              showTopSnackBar("الرجاء إدخال تاريخ الميلاد");
                              return;
                            }
                            
                            if (birthPlace.isEmpty || residenceState.isEmpty || residenceCity.isEmpty) {
                              showTopSnackBar("الرجاء إدخال مكان الميلاد ومكان الإقامة");
                              return;
                            }
                            
                            updateProfile();
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
                  color: Color(0xFF139799),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // زر الكاميرا
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
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
                        Text("الكاميرا", 
                            style: TextStyle(
                              fontFamily: 'Zain',
                              color: Color(0xFF139799))),
                      ],
                    ),
                  ),
                  
                  // زر المعرض
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
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
                        Text("المعرض", 
                            style: TextStyle(
                              fontFamily: 'Zain',
                              color: Color(0xFF139799))),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              
              // خيار إزالة الصورة (بنفس التصميم)
              if (_currentImageUrl != null || _selectedImage != null)
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFF139799).withOpacity(0.1),
                        child: Icon(
                          Icons.delete,
                          size: 30,
                          color: Color(0xFF139799),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text("إزالة الصورة", 
                          style: TextStyle(
                            fontFamily: 'Zain',
                            color: Color(0xFF139799))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
}