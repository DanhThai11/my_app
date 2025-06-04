import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Thêm import cho Firestore
// import 'package:my_app/database/database_helper.dart'; // Không cần nữa

class HistoryDetailScreen extends StatefulWidget {
final String historyId; // ID của đơn hàng từ Firestore (document ID)

HistoryDetailScreen({required this.historyId});

@override
_HistoryDetailScreenState createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
// Sử dụng FutureBuilder để xử lý trạng thái bất đồng bộ
late Future<DocumentSnapshot<Map<String, dynamic>>> _orderDetailFuture;

@override
void initState() {
super.initState();
_orderDetailFuture = _fetchOrderDetail();
}

Future<DocumentSnapshot<Map<String, dynamic>>> _fetchOrderDetail() async {
try {
final orderDoc = await FirebaseFirestore.instance
    .collection('orders')
    .doc(widget.historyId) // Lấy document bằng ID đã truyền vào
    .get();
if (!orderDoc.exists) {
throw Exception('Không tìm thấy đơn hàng với ID: ${widget.historyId}');
}
return orderDoc as DocumentSnapshot<Map<String, dynamic>>;
} catch (e) {
print('Lỗi khi tải chi tiết đơn hàng: $e');
throw Exception('Không thể tải chi tiết đơn hàng: $e');
}
}

String _formatPrice(dynamic price) {
if (price == null) return 'N/A';
return (price as num).toStringAsFixed(0); // Bỏ phần thập phân
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text('Chi tiết đơn hàng'),
),
body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
future: _orderDetailFuture,
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return Center(child: CircularProgressIndicator());
} else if (snapshot.hasError) {
print('FutureBuilder Error (HistoryDetailScreen): ${snapshot.error}');
return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
} else if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
return Center(child: Text('Không tìm thấy thông tin chi tiết cho đơn hàng này.'));
}

// Lấy dữ liệu đơn hàng từ DocumentSnapshot
final orderData = snapshot.data!.data();
if (orderData == null) {
return Center(child: Text('Dữ liệu đơn hàng không hợp lệ.'));
}

final List<dynamic> items = orderData['items'] as List<dynamic>? ?? [];

return SingleChildScrollView( // Cho phép cuộn nếu nội dung dài
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Mã đơn hàng: ${snapshot.data!.id}', // Hiển thị ID của document
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
SizedBox(height: 8),
Text(
'Ngày đặt: ${_formatTimestamp(orderData['orderDate'] as Timestamp?)}',
style: TextStyle(fontSize: 16),
),
SizedBox(height: 8),
Text(
'Tổng tiền: ${_formatPrice(orderData['totalAmount'])} VND',
style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
SizedBox(height: 8),
Text(
'Trạng thái: ${orderData['status'] ?? 'N/A'}',
style: TextStyle(fontSize: 16),
),
SizedBox(height: 8),
Text(
'Phương thức thanh toán: ${orderData['paymentMethod'] ?? 'N/A'}',
style: TextStyle(fontSize: 16),
),
if (orderData['userName'] != null) ...[
SizedBox(height: 8),
Text(
'Khách hàng: ${orderData['userName']}',
style: TextStyle(fontSize: 16),
),
],
if (orderData['userEmail'] != null) ...[
SizedBox(height: 8),
Text(
'Email: ${orderData['userEmail']}',
style: TextStyle(fontSize: 16),
),
],
// Thêm các thông tin khác nếu có, ví dụ địa chỉ giao hàng
// if (orderData['shippingAddress'] != null) ...[
//   SizedBox(height: 8),
//   Text(
//     'Địa chỉ giao hàng: ${orderData['shippingAddress']}',
//     style: TextStyle(fontSize: 16),
//   ),
// ],
SizedBox(height: 20),
Text(
'Các sản phẩm:',
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
if (items.isEmpty)
Padding(
padding: const EdgeInsets.symmetric(vertical: 8.0),
child: Text('Không có sản phẩm nào trong đơn hàng này.'),
)
else
ListView.builder(
shrinkWrap: true, // Quan trọng khi ListView trong Column/SingleChildScrollView
physics: NeverScrollableScrollPhysics(), // Không cho ListView này cuộn riêng
itemCount: items.length,
itemBuilder: (context, index) {
final item = items[index] as Map<String, dynamic>;
return Card(
margin: EdgeInsets.symmetric(vertical: 8.0),
child: ListTile(
leading: item['imageurl'] != null && (item['imageurl'] as String).isNotEmpty
? Image.network(
item['imageurl'] as String,
width: 60,
height: 60,
fit: BoxFit.cover,
errorBuilder: (context, error, stackTrace) =>
Icon(Icons.broken_image, size: 60),
)
    : Icon(Icons.image_not_supported, size: 60),
title: Text(
item['name'] as String? ?? 'Sản phẩm không tên',
style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
),
subtitle: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Giá: ${_formatPrice(item['price'])} VND / sản phẩm'),
Text('Số lượng: ${item['quantity'] ?? 1}'),
Text('Thành tiền: ${_formatPrice((item['price'] as num? ?? 0) * (item['quantity'] as num? ?? 1))} VND'),
],
),
),
);
},
),
],
),
);
},
),
);
}

// Helper function để format Timestamp (tương tự như trong HistoryScreen)
String _formatTimestamp(Timestamp? timestamp) {
if (timestamp == null) {
return 'N/A';
}
// Bạn cần import package intl và sử dụng nó ở đây nếu muốn format phức tạp
// Hoặc format đơn giản:
final dateTime = timestamp.toDate();
return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
// Ví dụ sử dụng intl:
// return intl.DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
// Nhớ import 'package:intl/intl.dart' as intl;
}
}
