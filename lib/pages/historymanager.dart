import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Không cần thiết nếu không lọc theo user cụ thể nữa
import 'package:intl/intl.dart'; // For date formatting
import 'package:my_app/elements/navigationMenu.dart'; // Hoặc navigationMenuAdmin nếu đây là cho admin
import 'package:my_app/pages/historydetail.dart';
import 'package:my_app/pages/historydetailmanager.dart';

class HistoryScreenManager extends StatefulWidget {
  const HistoryScreenManager({super.key});

  @override
  State<HistoryScreenManager> createState() => _HistoryScreenManagerState(); // Đổi tên State cho đúng quy ước
}

class _HistoryScreenManagerState extends State<HistoryScreenManager> { // Đổi tên State
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchAllOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchAllOrders() async {
    // Tùy chọn: Kiểm tra xem người dùng có phải là admin không trước khi fetch
    // Ví dụ:
    // final user = FirebaseAuth.instance.currentUser;
    // if (user == null ) { // Hoặc !isAdmin(user)
    //   print('User not authorized to view all orders.');
    //   return [];
    // }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
      // .where('userId', isEqualTo: user.uid) // <<--- LOẠI BỎ DÒNG NÀY
          .orderBy('orderDate', descending: true) // Vẫn sắp xếp theo ngày, mới nhất trước
          .get();

      if (snapshot.docs.isEmpty) {
        print('No orders found in the collection.');
        return [];
      }

      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Thêm ID của document vào data
        // Bạn có thể muốn thêm thông tin người dùng vào đây nếu cần hiển thị ai đã đặt hàng
        // Ví dụ: data['userEmail'] = data['userEmailFieldFromDocument']; // Giả sử bạn lưu email người dùng trong đơn hàng
        return data;
      }).toList();

      return orders;
    } catch (e) {
      print('Error fetching all orders: $e');
      throw Exception('Failed to load order history: $e');
    }
  }

  String _formatOrderDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'N/A';
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tất cả đơn hàng', // Thay đổi tiêu đề cho phù hợp
          style: TextStyle(
            fontSize: 20,
            color: Color(0xff2F3194),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      //   leading: Builder(
      //     builder: (context) => IconButton(
      //       onPressed: () {
      //         Scaffold.of(context).openDrawer();
      //       },
      //       icon: Icon(
      //         Icons.sort,
      //         color: Color(0xff2F3194),
      //       ),
      //     ),
      //   ),
      ),
      // drawer: NavigationMenu(), // Hoặc NavigationMenuAdmin() nếu đây là giao diện admin
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('FutureBuilder error: ${snapshot.error}');
            return Center(child: Text('Đã xảy ra lỗi khi tải lịch sử: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Chưa có đơn hàng nào trong hệ thống.'));
          }

          final ordersList = snapshot.data!;

          return ListView.builder(
            itemCount: ordersList.length,
            itemBuilder: (context, index) {
              final order = ordersList[index];
              final orderId = order['id'] ?? order['orderId'] ?? 'N/A';
              // Lấy thông tin người đặt hàng (nếu có và cần hiển thị)
              // final String userIdentifier = order['userEmail'] ?? order['userId'] ?? 'Unknown User';

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryDetailManagerScreen(historyId: orderId),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    leading: Icon(Icons.receipt_long, size: 30, color: Color(0xff2F3194)),
                    title: Text(
                      'Ngày đặt: ${_formatOrderDate(order['orderDate'] as Timestamp?)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        // Nếu muốn hiển thị người đặt hàng:
                        // Text(
                        //   'Người đặt: $userIdentifier',
                        //   style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                        // ),
                        // SizedBox(height: 4),
                        Text(
                          'Mã đơn hàng: $orderId',
                          style: TextStyle(fontSize: 15),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tổng tiền: ${order['totalAmount']?.toStringAsFixed(0) ?? '0'} VND',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Trạng thái: ${order['status'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 16, color: _getStatusColor(order['status'])),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }


  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'đang xử lý':
        return Colors.orange;
      case 'đã giao':
        return Colors.green;
      case 'đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}