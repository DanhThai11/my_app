import 'package:flutter/material.dart';
import 'package:my_app/elements/navigationMenu.dart';
import 'package:my_app/pages/history.dart';
import 'package:my_app/pages/home.dart';
import 'package:my_app/pages/login_screen.dart';
import 'package:my_app/pages/profile.dart';

class appBar extends StatefulWidget {
  appBar({super.key});
  @override
  State<appBar> createState() => _appBarState();
}

class _appBarState extends State<appBar> {
  int _currentIndex = 0;
  final tabs = [
    HomeScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
          onTap: (index){
            setState(() {
              _currentIndex = index;
            });
          },
          currentIndex: _currentIndex ,
          items: [
        BottomNavigationBarItem(icon: Icon(Icons.home),
            label: 'Trang chủ',),
        BottomNavigationBarItem(icon: Icon(Icons.history),
          label: 'Lịch sử',),
        BottomNavigationBarItem(icon: Icon(Icons.person),
          label: 'Cá nhân',),
      ]),
      body: tabs[_currentIndex],

    );
  }
}
