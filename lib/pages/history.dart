import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
// import 'package:my_app/database/database_helper.dart'; // No longer needed for history
import 'package:my_app/elements/navigationMenu.dart';
import 'package:my_app/pages/historydetail.dart'; // Assuming you still want to navigate here

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // bool _isLoading = true; // FutureBuilder will handle loading state
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchUserOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchUserOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Not logged in, return empty list or throw error
      print('User not logged in. Cannot fetch history.');
      return [];
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid) // Filter by current user's ID
          .orderBy('orderDate', descending: true) // Show newest orders first
          .get();

      if (snapshot.docs.isEmpty) {
        print('No orders found for user ${user.uid}');
        return [];
      }

      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        // Add the document ID to your map if you need it for navigation or other operations
        data['id'] = doc.id;
        return data;
      }).toList();

      // print('Fetched orders: $orders');
      return orders;
    } catch (e) {
      print('Error fetching orders: $e');
      // Propagate the error to be handled by FutureBuilder
      throw Exception('Failed to load order history: $e');
    }
  }

  String _formatOrderDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'N/A';
    }
    // Using intl package for date formatting
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lịch sử đơn hàng', // Changed title
          style: TextStyle(
            fontSize: 20,
            color: Color(0xff2F3194),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: Icon(
              Icons.sort,
              color: Color(0xff2F3194),
            ),
          ),
        ),
      ),
      drawer: NavigationMenu(), // Corrected from navigationMenu() to NavigationMenu()
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('FutureBuilder error: ${snapshot.error}');
            return Center(child: Text('Đã xảy ra lỗi khi tải lịch sử: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Chưa có đơn hàng nào.'));
          }

          final ordersList = snapshot.data!;

          return ListView.builder(
            itemCount: ordersList.length,
            itemBuilder: (context, index) {
              final order = ordersList[index];
              final orderId = order['id'] ?? order['orderId'] ?? 'N/A'; // Use document ID or orderId field

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryDetailScreen(historyId: orderId),
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    leading: Icon(Icons.receipt_long, size: 30, color: Color(0xff2F3194)), // Changed icon
                    title: Text(
                      // 'Mã đơn: ${orderId}', // Display Order ID
                      'Ngày đặt: ${_formatOrderDate(order['orderDate'] as Timestamp?)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
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
                        // You can add more details here if needed, e.g., number of items
                        // Text(
                        //   'Số lượng mặt hàng: ${(order['items'] as List?)?.length ?? 0}',
                        //   style: TextStyle(fontSize: 16),
                        // ),
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

  // Helper function to determine status color (optional)
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'đang xử lý':
        return Colors.orange;
      case 'đã giao': // Example
        return Colors.green;
      case 'đã hủy': // Example
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}