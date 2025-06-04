import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/elements/navigationMenu.dart';
import 'package:my_app/pages/cart.dart';
import 'package:my_app/pages/notifi.dart';
import 'package:my_app/pages/product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  TextEditingController _searchController = TextEditingController();
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchCartItemCount();
  }

  Future<void> _fetchProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('products').get();
      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'price': data['price'] ?? 0,
          'description': data['description'] ?? '',
          'imageurl': data['imageurl'] ?? '',
          'quantity': data['quantity'] ?? 0,
        };
      }).toList();

      if (mounted) { // Kiểm tra widget còn trong tree không
        setState(() {
          _products = products;
          _filteredProducts = products;
        });
      }
    } catch (e) {
      print('Lỗi khi tải sản phẩm từ Firestore: $e');
      if (mounted) {
        _showCustomPopup(context, 'Lỗi tải sản phẩm.', isError: true);
      }
    }
  }

  Future<void> _fetchCartItemCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;
        final snapshot = await FirebaseFirestore.instance
            .collection('cart')
            .doc(userId)
            .collection('items')
            .get();

        int totalQuantity = 0;
        for (var doc in snapshot.docs) {
          final quantity = doc.data()['quantity'];
          if (quantity is num) {
            totalQuantity += quantity.toInt();
          }
        }
        if (mounted) {
          setState(() {
            _cartItemCount = totalQuantity;
          });
        }
      }
    } catch (e) {
      print('Lỗi khi lấy số lượng giỏ hàng: $e');
      // Không nên hiển thị popup lỗi ở đây vì nó có thể chạy ngầm
    }
  }

  void _searchProduct(String query) {
    setState(() {
      _filteredProducts = _products.where((product) {
        final name = product['name'].toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
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

  Future<void> _addToCartQuick(Map<String, dynamic> product) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showCustomPopup(
          context,
          'Vui lòng đăng nhập trước khi thêm vào giỏ hàng',
          isError: true,
        );
        return;
      }

      final userId = user.uid;

      final existing = await FirebaseFirestore.instance
          .collection('cart')
          .doc(userId)
          .collection('items')
          .where('productId', isEqualTo: product['id'])
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        final docId = existing.docs.first.id;
        final currentQuantity = existing.docs.first.data()['quantity'] ?? 1;

        await FirebaseFirestore.instance
            .collection('cart')
            .doc(userId)
            .collection('items')
            .doc(docId)
            .update({'quantity': currentQuantity + 1});
      } else {
        await FirebaseFirestore.instance
            .collection('cart')
            .doc(userId)
            .collection('items')
            .add({
          'productId': product['id'],
          'name': product['name'],
          'price': product['price'],
          'imageurl': product['imageurl'],
          'quantity': 1,
        });
      }
      _showCustomPopup(
        context,
        '${product['name']} đã được thêm vào giỏ hàng.',
      );
      _fetchCartItemCount();
    } catch (e) {
      print('Lỗi thêm vào giỏ hàng: $e');
      _showCustomPopup(
        context,
        'Lỗi khi thêm vào giỏ hàng.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Trang chủ',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(),
                ),
              ).then((_) {
                _fetchProducts(); // Làm mới sản phẩm có thể không cần thiết nếu không có gì thay đổi
                _fetchCartItemCount();
              });
            },
            icon: Stack(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: Color(0xff2F3194),
                ),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _cartItemCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotifiScreen(),
                ),
              ).then((_) {
                _fetchCartItemCount();
              });
            },
            icon: Icon(
              Icons.notifications,
              color: Color(0xff2F3194),
            ),
          ),
        ],
      ),
      drawer: NavigationMenu(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                prefixIcon: Icon(Icons.search, color: Colors.grey),
              ),
              onChanged: _searchProduct,
            ),
          ),
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                child: _products.isEmpty && _searchController.text.isEmpty
                    ? CircularProgressIndicator()
                    : Text(_products.isEmpty && _searchController.text.isEmpty
                    ? 'Đang tải sản phẩm...'
                    : 'Không tìm thấy sản phẩm nào.')
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) { // context này có thể dùng cho _showCustomPopup
                final product = _filteredProducts[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(product: product),
                        ),
                      ).then((value) {
                        _fetchCartItemCount();
                      });
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          product['imageurl'] != null && (product['imageurl'] as String).isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              product['imageurl'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.broken_image, size: 80, color: Colors.grey),
                            ),
                          )
                              : Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Giá: ${(product['price'] as num?)?.toStringAsFixed(0) ?? '0'} VND / KG',
                                  style: TextStyle(fontSize: 15, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Còn lại: ${product['quantity'] ?? 0} KG',
                                  style: TextStyle(fontSize: 14, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _addToCartQuick(product), // context ở đây là context của builder
                            icon: Icon(Icons.add_shopping_cart, color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}