import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:my_app/pages/home.dart'; // Bạn có thể bỏ comment nếu cần chuyển hướng đến HomeScreen

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isProcessingOrder = false;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  // HÀM HIỂN THỊ POP-UP TÙY CHỈNH
  void _showCustomPopup(BuildContext context, String message, {bool isError = false}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        Future.delayed(Duration(seconds: 2), () {
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

  Future<void> _fetchCartItems() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Sử dụng context của _CartScreenState
        _showCustomPopup(context, 'Vui lòng đăng nhập để xem giỏ hàng', isError: true);
        return;
      }

      final userId = user.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('cart')
          .doc(userId)
          .collection('items')
          .get();

      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'productId': data['productId'] ?? '',
          'name': data['name'] ?? '',
          'price': (data['price'] ?? 0.0).toDouble(),
          'imageurl': data['imageurl'] ?? '',
          'quantity': data['quantity'] ?? 1,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _cartItems = items;
        });
      }
    } catch (e) {
      print('Lỗi khi tải giỏ hàng: $e');
      if (mounted) {
        _showCustomPopup(context, 'Lỗi khi tải giỏ hàng', isError: true);
      }
    }
  }

  Future<void> _removeFromCart(String docId, String productName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showCustomPopup(context, 'Vui lòng đăng nhập để thực hiện thao tác này', isError: true);
        return;
      }

      final userId = user.uid;
      await FirebaseFirestore.instance
          .collection('cart')
          .doc(userId)
          .collection('items')
          .doc(docId)
          .delete();

      if (mounted) {
        setState(() {
          _cartItems.removeWhere((item) => item['id'] == docId);
        });
        _showCustomPopup(context, 'Đã xóa "$productName" khỏi giỏ hàng');
      }
    } catch (e) {
      print('Lỗi khi xóa sản phẩm: $e');
      if (mounted) {
        _showCustomPopup(context, 'Lỗi khi xóa sản phẩm', isError: true);
      }
    }
  }

  Future<void> _updateQuantity(String docId, int newQuantity, String productName) async {
    if (newQuantity < 1) {
      _showCustomPopup(context, 'Số lượng không thể nhỏ hơn 1', isError: true);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showCustomPopup(context, 'Vui lòng đăng nhập để thực hiện thao tác này', isError: true);
        return;
      }

      final userId = user.uid;
      await FirebaseFirestore.instance
          .collection('cart')
          .doc(userId)
          .collection('items')
          .doc(docId)
          .update({'quantity': newQuantity});

      if (mounted) {
        setState(() {
          final itemIndex = _cartItems.indexWhere((item) => item['id'] == docId);
          if (itemIndex != -1) {
            _cartItems[itemIndex]['quantity'] = newQuantity;
          }
        });
        _showCustomPopup(context, 'Đã cập nhật số lượng cho "$productName"');
      }
    } catch (e) {
      print('Lỗi khi cập nhật số lượng: $e');
      if (mounted) {
        _showCustomPopup(context, 'Lỗi khi cập nhật số lượng', isError: true);
      }
    }
  }

  double _calculateTotal() {
    return _cartItems.fold(0.0, (total, item) => total + (item['price'] * item['quantity']));
  }

  Future<void> _placeOrder() async {
    if (_cartItems.isEmpty) {
      _showCustomPopup(context, 'Giỏ hàng trống, không thể đặt hàng.', isError: true);
      return;
    }

    if (mounted) {
      setState(() => _isProcessingOrder = true);
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showCustomPopup(context, 'Vui lòng đăng nhập để đặt hàng', isError: true);
        if (mounted) {
          setState(() => _isProcessingOrder = false);
        }
        return;
      }

      final userId = user.uid;
      final totalAmount = _calculateTotal();
      final orderId = FirebaseFirestore.instance.collection('orders').doc().id;

      final orderData = {
        'orderId': orderId,
        'userId': userId,
        'userName': user.displayName ?? 'N/A',
        'userEmail': user.email ?? 'N/A',
        'items': _cartItems.map((item) => {
          'productId': item['productId'],
          'name': item['name'],
          'price': item['price'],
          'imageurl': item['imageurl'],
          'quantity': item['quantity'],
        }).toList(),
        'totalAmount': totalAmount,
        'orderDate': Timestamp.now(),
        'status': 'Đang xử lý',
        'paymentMethod': 'Thanh toán khi nhận hàng',
      };

      await FirebaseFirestore.instance.collection('orders').doc(orderId).set(orderData);
      await _clearCartAfterOrder(userId);

      if (mounted) {
        // Hiển thị pop-up thành công với thời gian dài hơn một chút để người dùng đọc mã đơn hàng
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) {
            Future.delayed(Duration(seconds: 4), () { // Thời gian dài hơn
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
              // Optional: Navigate after showing success
              // if (mounted) {
              //   Navigator.pushAndRemoveUntil(
              //     context,
              //     MaterialPageRoute(builder: (context) => HomeScreen()), // Replace with your desired screen
              //     (Route<dynamic> route) => false,
              //   );
              // }
            });
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              elevation: 5,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                decoration: BoxDecoration(
                  color: Colors.green[400],
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 40),
                    SizedBox(height: 15),
                    Text(
                      'Đặt hàng thành công!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Mã đơn hàng của bạn: $orderId',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

    } catch (e) {
      print('Lỗi khi đặt hàng: $e');
      if (mounted) {
        _showCustomPopup(context, 'Đã xảy ra lỗi khi đặt hàng. Vui lòng thử lại.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingOrder = false);
      }
    }
  }

  Future<void> _clearCartAfterOrder(String userId) async {
    try {
      final cartItemsRef = FirebaseFirestore.instance
          .collection('cart')
          .doc(userId)
          .collection('items');

      final snapshot = await cartItemsRef.get();
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (DocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        setState(() {
          _cartItems = [];
        });
      }
      print('Giỏ hàng đã được xóa sau khi đặt hàng.');
    } catch (e) {
      print('Lỗi khi xóa giỏ hàng: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Giỏ hàng'),
      ),
      body: _cartItems.isEmpty && !_isProcessingOrder
          ? Center(child: Text('Giỏ hàng của bạn đang trống'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: item['imageurl'] != null && item['imageurl'].isNotEmpty
                        ? Image.network(
                      item['imageurl'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.broken_image, size: 60),
                    )
                        : Icon(Icons.image_not_supported, size: 60),
                    title: Text(item['name'] ?? 'Tên sản phẩm không xác định'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item['price']?.toStringAsFixed(0) ?? '0'} VNĐ'),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline),
                              iconSize: 20,
                              onPressed: () => _updateQuantity(
                                  item['id'], (item['quantity'] ?? 1) - 1, item['name']),
                            ),
                            Text('${item['quantity'] ?? 1}'),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline),
                              iconSize: 20,
                              onPressed: () => _updateQuantity(
                                  item['id'], (item['quantity'] ?? 1) + 1, item['name']),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () => _removeFromCart(item['id'], item['name']),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng cộng: ${_calculateTotal().toStringAsFixed(0)} VNĐ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _isProcessingOrder
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white, // Màu chữ cho button
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  onPressed: (_cartItems.isEmpty || _isProcessingOrder) ? null : _placeOrder,
                  child: Text('Đặt hàng'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}