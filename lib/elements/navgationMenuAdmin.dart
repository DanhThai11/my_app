import 'package:flutter/material.dart';
import 'package:my_app/elements/appbar.dart';
import 'package:my_app/pages/StaticScreen.dart';
import 'package:my_app/pages/admin.dart';
import 'package:my_app/pages/history.dart';
import 'package:my_app/pages/home.dart';
import 'package:my_app/pages/login_screen.dart';
import 'package:my_app/pages/productmanager.dart';
import 'package:my_app/pages/profile.dart';
import 'package:my_app/pages/userScreen.dart';

class navigationMenuAdmin extends StatelessWidget {
  navigationMenuAdmin({super.key});
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 15,top: 17),
            child: Row(
              children: [
                Image.asset("assets/images/th.png",
                  height: 113,width: 113,),
                const Padding(
                    padding: EdgeInsets.only(left: 19),
                    child: Text('ADMIN',style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff2F3194),
                    ),))
              ],
            ),
          ),
          SizedBox(height: 14,),
          ListTile(
            onTap: () {
              // Navigator.push(context, MaterialPageRoute(builder: (context) => adminScreen()));
            },
            leading: Icon(
              Icons.home,
              size: 27,
              color: Color(0xff2F3194),
            ),
            title: Text(
              'Trang chủ',
              style: TextStyle(color: Color(0xff2F3194), fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),

          ListTile(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsScreen()));
            },
            leading: Icon(
              Icons.analytics,
              size: 27,
              color: Color(0xff2F3194),
            ),
            title: Text(
              'Thống kê',
              style: TextStyle(color: Color(0xff2F3194), fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => UserListScreen()));
            },
            leading: Icon(
              Icons.person,
              size: 27,
              color: Color(0xff2F3194),
            ),
            title: Text(
              'Tài khoản',
              style: TextStyle(color: Color(0xff2F3194), fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),

          ListTile(
            onTap: () {

            },
            leading: Icon(
              Icons.help,
              size: 27,
              color: Color(0xff2F3194),
            ),
            title: Text(
              'Trợ giúp',
              style: TextStyle(color: Color(0xff2F3194), fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),

          ListTile(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (Route<dynamic> route) => false);
            },
            leading: Icon(
              Icons.exit_to_app,
              size: 27,
              color: Color(0xff2F3194),
            ),
            title: Text(
              'Đăng xuất',
              style: TextStyle(color: Color(0xff2F3194), fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
