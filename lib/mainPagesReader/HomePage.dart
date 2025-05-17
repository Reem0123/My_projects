import 'package:flutter/material.dart';
import 'package:libyyapp/auth/LoginPage.dart';
import 'package:libyyapp/mainPagesReader/more.dart';
import 'package:libyyapp/mainPagesReader/myAccount.dart';
import 'package:libyyapp/mainPagesReader/news.dart';
import 'package:libyyapp/mainPagesReader/search.dart';
import 'package:libyyapp/mainPagesReader/showpage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2; 
   bool isGuest = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
   
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) {
      isGuest = args as bool; 
    }
  }

  final List<Widget> _pages = [
    NewsUser(),
    SearchScreen(),
    Showpage(),
    Myaccount(),
    MorePage(),
    LoginPage()
  ];



  
  final List<Map<String, dynamic>> _tabs = [
    {"icon": Icons.newspaper_outlined, "text": "الأخبار"},
    {"icon": Icons.search_sharp, "text": "ابحث"},
    {"icon": Icons.home_filled, "text": "الرئيسية"},
    {"icon": Icons.person_2_rounded, "text": "حسابي"},
    {"icon": Icons.grid_view, "text": "المزيد"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      
      body: isGuest && _selectedIndex==3 ? LoginPage() : _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (index) {
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _tabs[index]["icon"],
                      color: _selectedIndex == index ? Color(0xFF139799) : Colors.grey,
                      size: 24,
                    ),
                    SizedBox(height: 4),
                    Text(
                      _tabs[index]["text"],
                      style: TextStyle(
                        color: _selectedIndex == index ? Color(0xFF139799) : Colors.grey,
                        fontSize: 12,
                        fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
