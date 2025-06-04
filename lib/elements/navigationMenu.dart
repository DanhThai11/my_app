import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:my_app/elements/appbar.dart'; // appBar() có thể là tên class, không phải hàm để gọi như trang
import 'package:my_app/pages/home.dart'; // Giả sử HomePage là màn hình chính của bạn
import 'package:my_app/pages/login_screen.dart';
import 'package:my_app/pages/profile.dart';

class NavigationMenu extends StatelessWidget {
  NavigationMenu({super.key});

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero, // Thường nên đặt padding của ListView là zero khi dùng trong Drawer
        children: [
          UserAccountsDrawerHeader( // Sử dụng UserAccountsDrawerHeader cho phần thông tin người dùng đẹp hơn
            decoration: BoxDecoration(
              color: Color(0xff2F3194), // Hoặc màu bạn muốn cho header
            ),
            accountName: Text(
              user?.displayName ?? 'Người dùng',
              style: TextStyle(
                fontSize: 18, // Điều chỉnh kích thước font nếu cần
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            accountEmail: user?.email != null // Hiển thị email nếu có
                ? Text(
              user!.email!,
              style: TextStyle(color: Colors.white70),
            )
                : null,
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white, // Màu nền cho avatar nếu ảnh lỗi
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!) // Sử dụng ảnh đại diện từ Firebase nếu có
                  : null,
              child: user?.photoURL == null // Hiển thị chữ cái đầu nếu không có ảnh
                  ? Text(
                user?.displayName?.isNotEmpty == true ? user!.displayName![0].toUpperCase() : "U",
                style: TextStyle(fontSize: 40.0, color: Color(0xff2F3194)),
              )
                  : null,
            ),
            // Loại bỏ hình ảnh logo-profile.png nếu dùng UserAccountsDrawerHeader theo cách này
            // Nếu bạn vẫn muốn giữ layout cũ, xem phần dưới
          ),
          // Nếu bạn muốn giữ layout cũ với Image.asset và Text:
          /*
          Padding(
            padding: EdgeInsets.fromLTRB(15, 17, 15, 0), // Thêm padding phải để Expanded có không gian co giãn
            child: Row(
              children: [
                Image.asset(
                  "assets/images/logo-profile.png",
                  height: 113,
                  width: 113,
                ),
                SizedBox(width: 19), // Sử dụng SizedBox thay vì Padding chỉ có left
                Expanded( // Bọc widget chứa Text bằng Expanded
                  child: Text(
                    user?.displayName ?? 'Người dùng',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff2F3194),
                    ),
                    overflow: TextOverflow.ellipsis, // Xử lý nếu tên quá dài
                    maxLines: 2, // Cho phép hiển thị tối đa 2 dòng nếu cần
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),
          */
          ListTile(
            onTap: () {
              Navigator.pop(context); // Đóng Drawer trước khi điều hướng
              // Navigator.push(context, MaterialPageRoute(builder: (context) => appBar()));
              // Lưu ý: appBar() có vẻ là tên class widget, không phải là một trang để điều hướng đến.
              // Bạn nên điều hướng đến một Widget trang cụ thể, ví dụ: HomePage
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen())); // Ví dụ điều hướng
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
              Navigator.pop(context); // Đóng Drawer
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
            },
            leading: Icon(
              Icons.person,
              size: 27,
              color: Color(0xff2F3194),
            ),
            title: Text(
              'Cá nhân',
              style: TextStyle(color: Color(0xff2F3194), fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            onTap: () {
              Navigator.pop(context); // Đóng Drawer
              // TODO: Điều hướng đến trang Trợ giúp
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
          Divider(color: Colors.grey.shade300), // Thêm đường kẻ phân cách
          ListTile(
            onTap: () async {
              Navigator.pop(context); // Đóng Drawer trước
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                    (Route<dynamic> route) => false,
              );
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