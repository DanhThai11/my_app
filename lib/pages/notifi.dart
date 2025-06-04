import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl; //

// import 'package:my_app/database/database_helper.dart'; // No longer needed

class NotifiScreen extends StatefulWidget { // Renamed to follow Dart conventions (UpperCamelCase)
  const NotifiScreen({super.key});

  @override
  State<NotifiScreen> createState() => _NotifiScreenState();
}

class _NotifiScreenState extends State<NotifiScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchUserOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchUserOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in. Cannot fetch notifications.');
      return []; // Return empty list if user is not logged in
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders') // Assuming 'orders' collection stores order information
          .where('userId', isEqualTo: user.uid) // Filter by current user's ID
          .orderBy('orderDate', descending: true) // Show newest orders/notifications first
          .get();

      if (snapshot.docs.isEmpty) {
        print('No orders found for user ${user.uid} to generate notifications.');
        return [];
      }

      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add the document ID to your map
        return data;
      }).toList();
      return orders;
    } catch (e) {
      print('Error fetching orders for notifications: $e');
      throw Exception('Failed to load notifications: $e');
    }
  }

  String _formatOrderDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'N/A';
    }
    // Using intl package for date formatting (e.g., "dd/MM/yyyy HH:mm")
    return intl.DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Thông báo',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Notification FutureBuilder error: ${snapshot.error}');
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Chưa có thông báo mới.'));
          }

          final notificationsList = snapshot.data!; // These are essentially orders

          return ListView.builder(
            itemCount: notificationsList.length,
            itemBuilder: (context, index) {
              final notificationOrder = notificationsList[index];
              final orderId = notificationOrder['id'] ?? notificationOrder['orderId'] ?? 'N/A';

              // Customize the notification message based on order data
              String notificationTitle = 'Đặt hàng thành công!';
              String notificationMessage = 'Đơn hàng mã $orderId của bạn đã được đặt vào lúc ${_formatOrderDate(notificationOrder['orderDate'] as Timestamp?)}.';

              // You could further customize based on order status if needed
              // For example, if status is 'shipped', change the title.
              // if (notificationOrder['status'] == 'Đã giao') {
              //   notificationTitle = 'Đơn hàng đã được giao!';
              //   notificationMessage = 'Đơn hàng mã $orderId đã được giao thành công.';
              // }

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  leading: Icon(
                    Icons.check_circle, // Icon for successful order
                    size: 35,
                    color: Colors.green,
                  ),
                  title: Text(
                    notificationTitle,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        notificationMessage,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tổng tiền: ${notificationOrder['totalAmount']?.toStringAsFixed(0) ?? '0'} VND',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Trạng thái: ${notificationOrder['status'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  // Optional: onTap to navigate to order details
                  onTap: () {
                    // Navigate to HistoryDetailScreen or a specific order detail view
                    // Ensure HistoryDetailScreen can handle the orderId
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => HistoryDetailScreen(historyId: orderId),
                    //   ),
                    // );
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