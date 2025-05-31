import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libyyapp/mainPagesReader/editProfilePage.dart';

class Myaccountadmin extends StatefulWidget {
  Myaccountadmin({super.key});

  @override
  State<Myaccountadmin> createState() => _MyaccountadminState();
}

class _MyaccountadminState extends State<Myaccountadmin> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String userName = "";
  String userSurname = "";
  String userProfileImage = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('Users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            userName = userData['first name'] ?? "";
            userSurname = userData['last name'] ?? "";
            userProfileImage = userData.containsKey('profile_Image') ? userData['profile_Image'] : "";
            
            if (userProfileImage.isEmpty && userData.containsKey('profileImage')) {
              userProfileImage = userData['profileImage'];
            }
            if (userProfileImage.isEmpty && userData.containsKey('profile_image')) {
              userProfileImage = userData['profile_image'];
            }
            
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: Color(0xFF139799)))
        : SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.04),
                
                // صورة الملف الشخصي
                Container(
                  width: screenWidth * 0.25,
                  height: screenWidth * 0.25,
                  decoration: BoxDecoration(
                    color: Color(0xFF139799).withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: userProfileImage.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          userProfileImage,
                          fit: BoxFit.cover,
                          width: screenWidth * 0.25,
                          height: screenWidth * 0.25,
                          
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.person_2, 
                                size: screenWidth * 0.12, 
                                color: Color(0xFF139799)),
                            );
                          },
                         
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Color(0xFF139799),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.person_2, 
                          size: screenWidth * 0.12, 
                          color: Color(0xFF139799)),
                      ),
                ),
                
                SizedBox(height: screenHeight * 0.02),
                
                // اسم المستخدم
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Text(
                    "$userName $userSurname",
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.03),
                
                // خيارات القائمة
                _buildOption(context, Icons.person, 'بطاقة المكتبة'),
                _buildOption(context, Icons.manage_accounts, 'إدارة حسابات المستخدمين'),
                _buildOption(context, Icons.edit, 'تعديل الملف الشخصي'),
                _buildOption(context, Icons.exit_to_app, 'تسجيل خروج', isLogout: true),
                
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String title, {bool isLogout = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return InkWell(
      onTap: () async {
        if (isLogout) {
          GoogleSignIn googleSignIn = GoogleSignIn();
          googleSignIn.disconnect();
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pushNamedAndRemoveUntil('Login', (route) => false);
        } else {
          switch (title) {
            case 'بطاقة المكتبة':
              Navigator.of(context).pushNamed('LibraryCard');
              break;
            case 'تعديل الملف الشخصي':
              final currentUser = _auth.currentUser;
              if (currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      userId: currentUser.uid, 
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
                );
              }
              break;
            case 'إدارة حسابات المستخدمين':
              Navigator.of(context).pushNamed('manageUserAccounts');
              break;
            default:
              print('No route defined for $title');
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.04,
          horizontal: screenWidth * 0.05,
        ),
        margin: EdgeInsets.symmetric(
          vertical: screenWidth * 0.01,
          horizontal: screenWidth * 0.04,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.arrow_back_ios, 
              size: screenWidth * 0.04, 
              color: Color(0xFF139799),
            ), 
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Icon(
                  icon, 
                  color: Color(0xFF139799),
                  size: screenWidth * 0.05,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}