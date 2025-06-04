import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:my_app/database/database_helper.dart'; // Không cần nữa
// import 'package:intl/intl.dart'; // Nếu bạn muốn format ngày giờ phức tạp hơn

class HistoryDetailManagerScreen extends StatefulWidget {
  final String historyId; // ID của đơn hàng từ Firestore (document ID)

  HistoryDetailManagerScreen({required this.historyId});

  @override
  _HistoryDetailScreenState createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailManagerScreen> {
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
          .doc(widget.historyId)
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
    return (price as num).toStringAsFixed(0);
  }

  Future<void> _deleteOrder(BuildContext context, String orderId) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa đơn hàng này không? Thao tác này không thể hoàn tác.'),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa đơn hàng thành công!'), backgroundColor: Colors.green),
        );
        // Kiểm tra xem Navigator có thể pop không trước khi gọi
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // Quay lại màn hình trước đó
        }
      } catch (e) {
        print('Lỗi khi xóa đơn hàng: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa đơn hàng: $e'), backgroundColor: Colors.red),
        );
      }
    }
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

          final orderData = snapshot.data!.data();
          if (orderData == null) {
            return Center(child: Text('Dữ liệu đơn hàng không hợp lệ.'));
          }

          final List<dynamic> items = orderData['items'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã đơn hàng: ${snapshot.data!.id}',
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
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
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
                SizedBox(height: 30), // Khoảng cách trước nút xóa
                Center( // Đặt nút xóa ở giữa hoặc tùy chỉnh vị trí
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.delete_forever, color: Colors.white),
                    label: Text('Xóa đơn hàng', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      _deleteOrder(context, widget.historyId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, // Màu nền của nút
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20), // Khoảng cách sau nút xóa
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'N/A';
    }
    final dateTime = timestamp.toDate();
    // Bạn có thể dùng package intl để format đẹp hơn nếu muốn
    // return intl.DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}