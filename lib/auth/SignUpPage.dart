import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:libyyapp/widgets/textformfield.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
  File? _image;
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _birthPlaceController = TextEditingController();
  final TextEditingController _residenceStateController = TextEditingController();
  final TextEditingController _residenceCityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  bool isShowing = false;
  String? role;
  bool isLoading = false;
  
  final cloudinary = CloudinaryPublic(
    'dyvgalhtd', 
    'my_app_preset', 
    cache: false,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _animation = Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0)).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _birthPlaceController.dispose();
    _residenceStateController.dispose();
    _residenceCityController.dispose();
    
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, 
    );
    
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
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
        _image = File(capturedImage.path);
      });
    }
  }

  Future<String?> _uploadImageToCloudinary() async {
    if (_image == null) return null;
    
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _image!.path,
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

  Future<void> addUserDetails({
    required String uid,
    required String firstname,
    required String lastname,
    required String email,
    required String phone,
    required DateTime birthDate,
    required String birthPlace,
    required String residenceState,
    required String residenceCity,
    String? imageUrl,
    String? role,
  }) async {
    await FirebaseFirestore.instance.collection('Users').doc(uid).set({
      'first name': firstname,
      'last name': lastname,
      'email': email,
      'phone number': phone,
      'birth date': birthDate,
      'birth place': birthPlace,
      'residence State': residenceState,
      'residence city': residenceCity,
      'profile_image': imageUrl ?? '',
      'role': role ?? 'reader',
    });
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
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
  final textScaleFactor = MediaQuery.of(context).textScaleFactor;

  return Scaffold(
    body: isLoading == true 
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF139799)),
            ),
          ) 
        : Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: isPortrait ? screenHeight * 0.02 : screenHeight * 0.01,
            ),
            child: Center(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        'تسجيل حساب جديد',
                        style: TextStyle(
                          fontFamily: 'Zain',
                          fontSize: screenWidth * 0.045 * textScaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF139799),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      GestureDetector(
                        onTap: _showImageSourceOptions,
                        child: Container(
                          width: screenWidth * 0.25,
                          height: screenWidth * 0.25,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: Color(0xFF139799).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: _image != null
                              ? ClipOval(
                                  child: Image.file(
                                    _image!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt,
                                  size: screenWidth * 0.1,
                                  color: Color(0xFF139799),
                                ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Text(
                        "اختر صورة شخصية",
                        style: TextStyle(
                          fontFamily: 'Zain',
                          color: Colors.grey[700],
                          fontSize: screenWidth * 0.035 * textScaleFactor,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      CustomTextForm(
                        hinttext: "الاسم", 
                        myController: _firstnameController,
                        icon: Icons.person,
                        iconSize: screenWidth * 0.06,
                        fontSize: screenWidth * 0.04,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      CustomTextForm(
                        hinttext: "اللقب", 
                        myController: _lastnameController,
                        icon: Icons.person,
                        iconSize: screenWidth * 0.06,
                        fontSize: screenWidth * 0.04,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      CustomTextForm(
                        hinttext: 'البريد الالكتروني', 
                        myController: _emailController, 
                        icon: Icons.email,
                        iconSize: screenWidth * 0.06,
                        fontSize: screenWidth * 0.04,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      CustomTextForm(
                        hinttext: 'كلمة المرور', 
                        myController: _passwordController, 
                        icon: Icons.lock, 
                        isPassword: true,
                        iconSize: screenWidth * 0.06,
                        fontSize: screenWidth * 0.04,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      CustomTextForm(
                        hinttext: "رقم الهاتف",
                        myController: _phoneController,
                        icon: Icons.phone,
                        iconSize: screenWidth * 0.06,
                        fontSize: screenWidth * 0.04,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      CustomTextForm(
                        hinttext: "تاريخ الميلاد",
                        myController: _birthDateController,
                        icon: Icons.calendar_today,
                        isDatePicker: true,
                        iconSize: screenWidth * 0.06,
                        fontSize: screenWidth * 0.04,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      CustomTextForm(
                        hinttext: "ولاية الميلاد",
                        myController: _birthPlaceController,
                        icon: Icons.location_on,
                        iconSize: screenWidth * 0.06,
                        fontSize: screenWidth * 0.04,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      CustomTextForm(
                        hinttext: "ولاية السكن",
                        myController: _residenceStateController,
                        icon: Icons.location_city,
                        iconSize: screenWidth * 0.06,
                        fontSize: screenWidth * 0.04,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      CustomTextForm(
                        hinttext: "بلدية السكن",
                        myController: _residenceCityController,
                        icon: Icons.home,
                        iconSize: screenWidth * 0.06,
                        fontSize: screenWidth * 0.04,
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      ElevatedButton(
                        onPressed: () async {
                          String email = _emailController.text.trim();
                          String password = _passwordController.text;
                          String firstname = _firstnameController.text.trim();
                          String lastname = _lastnameController.text.trim();
                          String phoneNbr = _phoneController.text.trim();
                          String birthPlace = _birthPlaceController.text.trim();
                          String birthDate = _birthDateController.text.trim();
                          String residenceState = _residenceStateController.text.trim();
                          String residenceCity = _residenceCityController.text.trim();
                          String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'; 

                          if (email.isEmpty || 
                              password.isEmpty || 
                              firstname.isEmpty || 
                              phoneNbr.isEmpty || 
                              lastname.isEmpty || 
                              birthDate.isEmpty || 
                              birthPlace.isEmpty || 
                              residenceState.isEmpty || 
                              residenceCity.isEmpty) {
                            showTopSnackBar("الرجاء إدخال جميع الحقول");
                            return;
                          }

                          if (!RegExp(emailPattern).hasMatch(email)) {
                            showTopSnackBar("الرجاء إدخال بريد إلكتروني صالح");
                            return;
                          }
                    
                          if (!RegExp(r'^\d{10}$').hasMatch(phoneNbr)) {
                            showTopSnackBar("يجب أن يحتوي رقم الهاتف على 10 أرقام فقط");
                            return;
                          }
                      
                          try {
                            setState(() {
                              isLoading = true;
                            });
                        
                            String? imageUrl;
                            if (_image != null) {
                              imageUrl = await _uploadImageToCloudinary();
                            }
                        
                            final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );

                            final User? user = credential.user;
                            await user?.sendEmailVerification();

                            if (user != null) {
                              await addUserDetails(
                                uid: user.uid,
                                firstname: _firstnameController.text.trim(),
                                lastname: _lastnameController.text.trim(),
                                email: _emailController.text.trim(),
                                phone: _phoneController.text.trim(),
                                birthDate: DateTime.parse(_birthDateController.text.trim()),
                                birthPlace: _birthPlaceController.text.trim(),
                                residenceState: _residenceStateController.text.trim(),
                                residenceCity: _residenceCityController.text.trim(),
                                imageUrl: imageUrl, 
                                role: role,
                              );
                            }

                            setState(() {
                              isLoading = false;
                            });
                        
                            Navigator.of(context).pushReplacementNamed("Login");

                          } on FirebaseAuthException catch (e) {
                            setState(() {
                              isLoading = false;
                            });
                        
                            if (e.code == 'weak-password') {
                              showTopSnackBar("كلمة المرور ضعيفة للغاية");
                            } else if (e.code == 'email-already-in-use') {
                              showTopSnackBar("الحساب موجود بالفعل لهذا البريد الإلكتروني");
                            } else {
                              showTopSnackBar("حدث خطأ أثناء إنشاء الحساب: ${e.message}");
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                            });
                        
                            showTopSnackBar("حدث خطأ غير متوقع: ${e.toString()}");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF139799),
                          minimumSize: Size(
                            screenWidth * 0.9,
                            isPortrait ? screenHeight * 0.065 : screenHeight * 0.09,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Color(0xFF139799).withOpacity(0.3),
                        ),
                        child: Text(
                          "تسجيل",
                          style: TextStyle(
                            fontFamily: 'Zain',
                            fontSize: screenWidth * 0.04 * textScaleFactor,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                    ],
                  ),
                ),
              ),
            ),
          ),
  );
}
}