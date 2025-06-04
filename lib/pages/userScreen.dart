import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:my_app/pages/register.dart'; // Có thể không cần nếu "thêm user" là qua màn hình đăng ký chung
// import 'package:my_app/pages/userDetailManager.dart'; // Nếu bạn muốn có màn hình chi tiết/sửa người dùng cho admin

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  // Biến state để trigger FutureBuilder fetch lại dữ liệu sau khi xóa
  // Một cách đơn giản là thay đổi key của FutureBuilder hoặc gán lại future
  // Ở đây, chúng ta sẽ gọi setState để rebuild, và FutureBuilder sẽ tự chạy lại future của nó
  // nếu future được tạo trong hàm build hoặc là một biến instance được gán lại.
  // Để đơn giản, ta sẽ tạo future trực tiếp trong FutureBuilder.

  Future<void> _deleteUser(BuildContext context, String userId, String userEmail) async {
    // Lưu ý quan trọng về việc xóa người dùng khỏi Firebase Auth:
    // API client-side của Firebase Auth chỉ cho phép người dùng đang đăng nhập xóa chính tài khoản của họ.
    // Để admin xóa tài khoản Auth của người dùng khác, bạn cần sử dụng Firebase Admin SDK
    // trên một môi trường server (ví dụ: Cloud Functions).

    // Hành động này sẽ chỉ xóa document người dùng khỏi Firestore.
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text(
              'Bạn có chắc chắn muốn xóa người dùng "$userEmail" khỏi danh sách Firestore?\n\n'
                  'LƯU Ý: Thao tác này KHÔNG xóa tài khoản khỏi Firebase Authentication. '
                  'Để xóa hoàn toàn, cần thực hiện từ Firebase Console hoặc sử dụng Admin SDK.'),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: Text('Xóa khỏi Firestore', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Đã xóa người dùng "$userEmail" khỏi danh sách Firestore.'),
              backgroundColor: Colors.green),
        );
        // Gọi setState để widget rebuild và FutureBuilder fetch lại dữ liệu
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi khi xóa người dùng khỏi Firestore: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách Người dùng'),
        // Cân nhắc có nên "thêm" user từ màn hình admin hay không.
        // Thông thường, người dùng sẽ tự đăng ký qua RegisterScreen.
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.person_add_alt_1),
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(builder: (context) => RegisterScreen()),
        //       ).then((_) {
        //         // Sau khi quay lại từ màn hình đăng ký, refresh danh sách
        //         if (mounted) {
        //           setState(() {});
        //         }
        //       });
        //     },
        //   ),
        // ],
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // Tạo future trực tiếp ở đây để nó chạy lại khi setState được gọi
        future: FirebaseFirestore.instance
            .collection('users')
        // Bạn có thể thêm .orderBy() nếu muốn, ví dụ theo 'username' hoặc 'email'
        // .orderBy('username', descending: false)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Lỗi FutureBuilder (UserListScreen): ${snapshot.error}');
            return Center(child: Text('Đã xảy ra lỗi khi tải danh sách người dùng.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Không có người dùng nào trong hệ thống.'));
          }

          final usersDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: usersDocs.length,
            itemBuilder: (context, index) {
              final userDoc = usersDocs[index];
              final userData = userDoc.data();
              final String userId = userDoc.id; // Đây chính là UID từ Firebase Auth

              // Lấy các trường dữ liệu, cung cấp giá trị mặc định nếu null
              final String username = userData['username'] ?? 'N/A';
              final String email = userData['email'] ?? 'N/A';
              final String phone = userData['phone'] ?? 'Chưa có';
              final String address = userData['address'] ?? 'Chưa có';
              // final String photoURL = userData['photoURL'] ?? ''; // Bạn chưa lưu photoURL khi đăng ký

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                elevation: 3,
                child: ListTile(
                  // leading: photoURL.isNotEmpty // Nếu bạn có photoURL
                  //     ? CircleAvatar(backgroundImage: NetworkImage(photoURL))
                  //     : CircleAvatar(child: Icon(Icons.person)),
                  leading: CircleAvatar(
                    child: Icon(Icons.person_outline, color: Colors.white),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  title: Text(username, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text('Email: $email', style: TextStyle(fontSize: 14)),
                      Text('SĐT: $phone', style: TextStyle(fontSize: 14)),
                      Text('Địa chỉ: $address', style: TextStyle(fontSize: 14)),
                      Text('UID: $userId', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                    tooltip: 'Xóa khỏi Firestore',
                    onPressed: () => _deleteUser(context, userId, email),
                  ),
                  onTap: () {
                    // TODO: Điều hướng đến màn hình chi tiết/sửa người dùng nếu cần
                    // Ví dụ:
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => UserDetailManagerScreen(userId: userId),
                    //   ),
                    // );
                    print('Xem chi tiết người dùng (Firestore): $userId');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}