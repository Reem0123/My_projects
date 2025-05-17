import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
  
    Timer(Duration(seconds: 4), () {
      checkUserAndRedirect();
    });
  }
  
  
  Future<void> checkUserAndRedirect() async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser != null && currentUser.emailVerified) {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .get();
      
      if (userDoc.exists) {
        String role = userDoc['role'] ?? 'reader'; 
      
        if (role == 'admin') {
          Navigator.of(context).pushReplacementNamed("HomeAdmin");
        } else if (role == 'reader') {
          Navigator.of(context).pushReplacementNamed("Home");
        }
      }
    } catch (e) {
     
      print("خطأ في الحصول على بيانات المستخدم: $e");
    }
  } else {
    Navigator.of(context).pushReplacementNamed("Login");
  }
}
    

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/documents/animBook3.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}