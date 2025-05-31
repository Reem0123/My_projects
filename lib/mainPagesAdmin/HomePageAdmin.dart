import 'package:flutter/material.dart';
import 'package:libyyapp/mainPagesAdmin/LibraryCatalogadmin.dart';
import 'package:libyyapp/mainPagesAdmin/MyaccountAdmin.dart';
import 'package:libyyapp/mainPagesAdmin/moreAdmin.dart';
import 'package:libyyapp/mainPagesAdmin/newsAdmin.dart';
import 'package:libyyapp/mainPagesAdmin/ShowpageAdmin.dart';

class Homepageadmin extends StatefulWidget {
  const Homepageadmin({super.key});

  @override
  State<Homepageadmin> createState() => _HomepageadminState();
}

class _HomepageadminState extends State<Homepageadmin> {
   int _selectedIndex = 2; 
  final List<Widget> _pages = [
    Newsadmin(),
    LibraryCatalogadminScreen(),
    Showpageadmin(),
    Myaccountadmin(),
    MoreadminPage()
  ];



  
  final List<Map<String, dynamic>> _tabs = [
    {"icon": Icons.newspaper_outlined, "text": "الأخبار"},
    {"icon": Icons.list_alt, "text": "فهرس الكتب "},
    {"icon": Icons.home_filled, "text": "الرئيسية"},
    {"icon": Icons.person_2_rounded, "text": "حسابي"},
    {"icon": Icons.grid_view, "text": "المزيد"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        toolbarHeight: 10,
      ),
      body: _pages[_selectedIndex],
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