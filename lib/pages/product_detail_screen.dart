import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product; // Nhận toàn bộ dữ liệu sản phẩm

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1; // Số lượng mặc định khi thêm vào giỏ

  String _formatPrice(dynamic price) {
    if (price == null) return 'N/A';
    return (price as num).toStringAsFixed(0); // Bỏ phần thập phân
  }

  // HÀM HIỂN THỊ POP-UP TÙY CHỈNH
  void _showCustomPopup(BuildContext context, String message, {bool isError = false}) {
    showDialog(
      context: context,
      barrierDismissible: true, // Cho phép đóng khi chạm bên ngoài
      builder: (BuildContext dialogContext) {
        // Tự động đóng sau một khoảng thời gian
        Future.delayed(Duration(seconds: 2), () {
          // Kiểm tra xem dialog còn tồn tại trước khi cố gắng đóng
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 5,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            decoration: BoxDecoration(
              color: isError ? Colors.red[400] : Colors.green[400],
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 40,
                ),
                SizedBox(height: 15),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addToCart() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showCustomPopup(
          context,
          'Vui lòng đăng nhập để thêm vào giỏ hàng',
          isError: true,
        );
        return;
      }

      final userId = user.uid;
      final productId = widget.product['id'];

      // Kiểm tra sản phẩm đã có trong giỏ hàng chưa
      final existingCartItem = await FirebaseFirestore.instance
          .collection('cart')
          .doc(userId)
          .collection('items')
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (existingCartItem.docs.isNotEmpty) {
        // Nếu đã có, cập nhật số lượng
        final docId = existingCartItem.docs.first.id;
        final currentQuantity = existingCartItem.docs.first.data()['quantity'] ?? 0;
        await FirebaseFirestore.instance
            .collection('cart')
            .doc(userId)
            .collection('items')
            .doc(docId)
            .update({'quantity': currentQuantity + _quantity});
      } else {
        // Nếu chưa có, thêm mới
        await FirebaseFirestore.instance
            .collection('cart')
            .doc(userId)
            .collection('items')
            .add({
          'productId': productId,
          'name': widget.product['name'],
          'price': widget.product['price'],
          'imageurl': widget.product['imageurl'],
          'quantity': _quantity,
        });
      }

      _showCustomPopup(
        context,
        '${widget.product['name']} đã được thêm vào giỏ hàng',
      );
      // Có thể gọi hàm cập nhật lại số lượng trên icon giỏ hàng ở HomeScreen nếu cần
      // (cần truyền callback hoặc sử dụng state management)

    } catch (e) {
      print('Lỗi thêm vào giỏ hàng từ chi tiết sản phẩm: $e');
      _showCustomPopup(
        context,
        'Lỗi khi thêm vào giỏ hàng',
        isError: true,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Chi tiết sản phẩm'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product['imageurl'] != null && (product['imageurl'] as String).isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    product['imageurl'],
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.broken_image, size: 250),
                  ),
                ),
              )
            else
              Center(
                child: Icon(Icons.image_not_supported, size: 250, color: Colors.grey),
              ),
            SizedBox(height: 20),
            Text(
              product['name'] ?? 'Tên sản phẩm không xác định',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Giá: ${_formatPrice(product['price'])} VND / KG',
              style: TextStyle(fontSize: 22, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'Số lượng còn lại: ${product['quantity'] ?? 0} KG',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            SizedBox(height: 16),
            Text(
              'Mô tả:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              product['description'] ?? 'Không có mô tả cho sản phẩm này.',
              style: TextStyle(fontSize: 18, color: Colors.black54, height: 1.5),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Số lượng:', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (_quantity > 1) {
                      setState(() {
                        _quantity--;
                      });
                    }
                  },
                ),
                Text('$_quantity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: () {
                    // Có thể kiểm tra với số lượng tồn kho widget.product['quantity']
                    // Ví dụ: if (_quantity < (widget.product['quantity'] ?? 0))
                    setState(() {
                      _quantity++;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 24),
            Center( // Đã căn giữa nút bằng Center
              child: ElevatedButton.icon(
                icon: Icon(Icons.add_shopping_cart),
                label: Text( // Label là Text đơn giản
                  'Thêm vào giỏ hàng',
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white, // Màu cho icon và text
                ),
                onPressed: _addToCart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}