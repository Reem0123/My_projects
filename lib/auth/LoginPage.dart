import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:libyyapp/widgets/textformfield.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  bool isShowing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                style: TextStyle(
                  fontFamily: 'Zain',
                  fontSize: MediaQuery.of(context).size.width * 0.04, 
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> saveFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (token != null && userId != null) {
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'fcmToken': token,
      });
      print(' ====the user token is saved : $token');
    } else {
      print('can not save token :userId or token not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: isPortrait ? screenHeight * 0.02 : screenHeight * 0.01,
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: screenHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "تسجيل الدخول إلى حساب المكتبة",
                          style: TextStyle(
                            fontFamily: 'Zain',
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: screenHeight * 0.03), 

                        CustomTextForm(
                          hinttext: 'البريد الالكتروني',
                          myController: _emailController,
                          icon: Icons.email,
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        CustomTextForm(
                          hinttext: 'كلمة المرور',
                          myController: _passwordController,
                          icon: Icons.lock,
                          isPassword: true,
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        ElevatedButton(
                          onPressed: () async {
                            String email = _emailController.text.trim();
                            String password = _passwordController.text;
                            String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';

                            if (email.isEmpty || password.isEmpty) {
                              showTopSnackBar("الرجاء إدخال جميع الحقول");
                              return;
                            }

                            if (!RegExp(emailPattern).hasMatch(email)) {
                              showTopSnackBar("الرجاء إدخال بريد إلكتروني صالح");
                              return;
                            }
                            if (password.length < 6) {
                              showTopSnackBar("يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل");
                              return;
                            }

                            try {
                              isLoading = true;
                              setState(() {});
                              final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                                email: _emailController.text,
                                password: _passwordController.text,
                              );

                              if (credential.user!.emailVerified) {
                                DocumentSnapshot userDoc = await FirebaseFirestore.instance
                                    .collection('Users')
                                    .doc(credential.user!.uid)
                                    .get();
                                isLoading = false;
                                setState(() {});

                                if (!userDoc.exists) {
                                  isLoading = false;
                                  setState(() {});
                                  showTopSnackBar(" حدث خطأ: لم يتم العثور على بيانات المستخدم.");
                                  return;
                                }

                                await saveFCMToken();
                                isLoading = false;
                                setState(() {});

                                String role = userDoc['role'];

                                if (role == "admin") {
                                  Navigator.of(context).pushReplacementNamed("HomeAdmin");
                                } else {
                                  Navigator.of(context).pushReplacementNamed("Home");
                                }
                              } else {
                                isLoading = false;
                                setState(() {});
                                showTopSnackBar(
                                    "تم إرسال رابط التحقق إلى بريدك الإلكتروني. يرجى التحقق منه وتأكيد حسابك");
                              }
                            } on FirebaseAuthException catch (e) {
                              isLoading = false;
                              setState(() {});
                              if (e.code == 'user-not-found') {
                                showTopSnackBar("لم يتم العثور على مستخدم لهذا البريد الإلكتروني");
                              } else if (e.code == 'wrong-password') {
                                showTopSnackBar("تم إدخال كلمة مرور خاطئة لهذا المستخدم");
                              } else if (e.code == 'invalid-credential') {
                                showTopSnackBar("البريد الإلكتروني أو كلمة المرور غير صحيحة");
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(
                              screenWidth * 0.9, 
                              screenHeight * 0.07, 
                            ),
                            backgroundColor: Color(0xFF139799),
                          ),
                          child: Text(
                            "تسجيل الدخول",
                            style: TextStyle(
                              fontFamily: 'Zain',
                              fontSize: screenWidth * 0.04, 
                              color: Colors.white,
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.01),

                        TextButton(
                          onPressed: () async {
                            if (_emailController.text == "") {
                              showTopSnackBar("الرجاء كتابة البريد الالكتروني أولا");
                              return;
                            }
                            try {
                              await FirebaseAuth.instance.sendPasswordResetEmail(
                                email: _emailController.text,
                              );
                              showTopSnackBar("تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.");
                            } catch (e) {
                              if (e is FirebaseAuthException) {
                                switch (e.code) {
                                  case "invalid-email":
                                    showTopSnackBar("البريد الإلكتروني غير صالح، الرجاء إدخال بريد صحيح");
                                    break;
                                  case "user-disabled":
                                    showTopSnackBar("تم تعطيل هذا الحساب من قبل المسؤول");
                                    break;
                                  case "too-many-requests":
                                    showTopSnackBar("لقد قمت بمحاولات كثيرة، الرجاء المحاولة لاحقًا");
                                    break;
                                  case "network-request-failed":
                                    showTopSnackBar("تحقق من اتصالك بالإنترنت ثم حاول مرة أخرى");
                                    break;
                                  default:
                                    showTopSnackBar("حدث خطأ غير متوقع، حاول مرة أخرى لاحقًا");
                                }
                              } else {
                                showTopSnackBar("حدث خطأ غير متوقع، حاول مرة أخرى.");
                              }
                            }
                          },
                          child: Text(
                            "نسيت كلمة المرور؟",
                            style: TextStyle(
                              fontFamily: 'Zain',
                              color: Color(0xFF139799),
                              fontSize: screenWidth * 0.035, 
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        Text(
                          "هل أنت مستخدم جديد لمكتبة بركات سليمان؟",
                          style: TextStyle(
                            fontFamily: 'Zain',
                            fontSize: screenWidth * 0.035, 
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed("signUp");
                          },
                          child: Text(
                            "أنشئ حساب جديد",
                            style: TextStyle(
                              fontFamily: 'Zain',
                              color: Color(0xFF139799),
                              fontSize: screenWidth * 0.035, 
                            ),
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            bool guestPressed = true;
                            Navigator.of(context).pushNamed("Home", arguments: guestPressed);
                          },
                          child: Text(
                            "أكمل كضيف",
                            style: TextStyle(
                              fontFamily: 'Zain',
                              color: Color(0xFF139799),
                              fontSize: screenWidth * 0.035, 
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}