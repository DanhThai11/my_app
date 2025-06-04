import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/pages/admin.dart';
// import 'package:my_app/pages/admin.dart'; // Bỏ comment nếu bạn có file AdminScreen và cần import

// Enum cho các tùy chọn sắp xếp
enum SortOption {
  none,
  priceLowToHigh,
  priceHighToLow,
  nameAZ,
  nameZA,
}

class ProductManagementScreen extends StatefulWidget {
  @override
  _ProductManagementScreenState createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  String _searchText = '';
  SortOption _currentSortOption = SortOption.none; // Lựa chọn sắp xếp hiện tại

  // Controller cho TextField tìm kiếm trong dialog
  final TextEditingController _searchDialogController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    // Đồng bộ _searchText với controller khi initState
    _searchDialogController.text = _searchText;
  }

  @override
  void dispose() {
    _searchDialogController.dispose(); // Hủy controller
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      QuerySnapshot snapshot;
      // Ví dụ: sắp xếp mặc định theo tên A-Z từ Firestore
      // snapshot = await FirebaseFirestore.instance.collection('products').orderBy('name').get();
      snapshot = await FirebaseFirestore.instance.collection('products').get();


      final productsData = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'price': data['price'] ?? 0,
          'description': data['description'] ?? '',
          'imageurl': data['imageurl'] ?? '',
          'quantity': data['quantity'] ?? 0,
          'createdAt': data['createdAt'] // Đảm bảo trường này tồn tại nếu bạn muốn sắp xếp theo nó
        };
      }).toList();

      if (mounted) {
        setState(() {
          _products = productsData;
          _applyCurrentFiltersAndSort(); // Áp dụng bộ lọc và sắp xếp sau khi fetch
        });
      }
    } catch (e) {
      print('Lỗi khi tải sản phẩm từ Firestore: $e');
      if (mounted) {
        _showCustomPopup(context, 'Lỗi tải sản phẩm.', isError: true);
      }
    }
  }

  void _applyCurrentFiltersAndSort() {
    List<Map<String, dynamic>> tempList = _products.where((product) {
      final nameMatches =
      product['name'].toLowerCase().contains(_searchText.toLowerCase());
      // Thêm các điều kiện lọc khác ở đây nếu cần
      return nameMatches;
    }).toList();

    // Áp dụng sắp xếp
    switch (_currentSortOption) {
      case SortOption.priceLowToHigh:
        tempList.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
        break;
      case SortOption.priceHighToLow:
        tempList.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
        break;
      case SortOption.nameAZ:
        tempList.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
        break;
      case SortOption.nameZA:
        tempList.sort((a, b) => (b['name'] as String).toLowerCase().compareTo((a['name'] as String).toLowerCase()));
        break;
      case SortOption.none:
      // Sắp xếp mặc định (ví dụ: theo thời gian tạo nếu trường 'createdAt' tồn tại và là Timestamp)
      // if (tempList.isNotEmpty && tempList.first['createdAt'] is Timestamp) {
      //   tempList.sort((a, b) => (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp)); // Mới nhất lên đầu
      // }
        break;
    }

    if (mounted) {
      setState(() {
        _filteredProducts = tempList;
      });
    }
  }

  void _showFilterDialog() {
    // Gán giá trị hiện tại của _searchText cho controller của dialog
    _searchDialogController.text = _searchText;
    SortOption tempSortOption = _currentSortOption; // Biến tạm cho lựa chọn trong dialog

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( // Để cập nhật UI của dialog
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Bộ lọc và Sắp xếp'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: _searchDialogController,
                      decoration: InputDecoration(
                        labelText: 'Tìm kiếm theo tên',
                        suffixIcon: _searchDialogController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setStateDialog(() { // Cập nhật UI dialog
                              _searchDialogController.clear();
                            });
                          },
                        )
                            : null,
                      ),
                      onChanged: (value){
                        // Cập nhật live search text cho dialog nếu muốn, hoặc chỉ khi nhấn áp dụng
                        setStateDialog(() {}); // Để suffixIcon cập nhật
                      },
                    ),
                    SizedBox(height: 20),
                    Text('Sắp xếp theo:', style: TextStyle(fontWeight: FontWeight.bold)),
                    RadioListTile<SortOption>(
                      title: const Text('Mặc định'),
                      value: SortOption.none,
                      groupValue: tempSortOption,
                      onChanged: (SortOption? value) {
                        if (value != null) {
                          setStateDialog(() {
                            tempSortOption = value;
                          });
                        }
                      },
                    ),
                    RadioListTile<SortOption>(
                      title: const Text('Giá: Thấp đến Cao'),
                      value: SortOption.priceLowToHigh,
                      groupValue: tempSortOption,
                      onChanged: (SortOption? value) {
                        if (value != null) {
                          setStateDialog(() {
                            tempSortOption = value;
                          });
                        }
                      },
                    ),
                    RadioListTile<SortOption>(
                      title: const Text('Giá: Cao đến Thấp'),
                      value: SortOption.priceHighToLow,
                      groupValue: tempSortOption,
                      onChanged: (SortOption? value) {
                        if (value != null) {
                          setStateDialog(() {
                            tempSortOption = value;
                          });
                        }
                      },
                    ),
                    RadioListTile<SortOption>(
                      title: const Text('Tên: A-Z'),
                      value: SortOption.nameAZ,
                      groupValue: tempSortOption,
                      onChanged: (SortOption? value) {
                        if (value != null) {
                          setStateDialog(() {
                            tempSortOption = value;
                          });
                        }
                      },
                    ),
                    RadioListTile<SortOption>(
                      title: const Text('Tên: Z-A'),
                      value: SortOption.nameZA,
                      groupValue: tempSortOption,
                      onChanged: (SortOption? value) {
                        if (value != null) {
                          setStateDialog(() {
                            tempSortOption = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Đặt lại'),
                  onPressed: () {
                    setStateDialog(() { // Cập nhật UI dialog
                      _searchDialogController.clear();
                      tempSortOption = SortOption.none;
                    });
                  },
                ),
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Không áp dụng thay đổi
                  },
                ),
                TextButton(
                  child: Text('Áp dụng'),
                  onPressed: () {
                    setState(() { // Cập nhật state chính của màn hình
                      _searchText = _searchDialogController.text;
                      _currentSortOption = tempSortOption;
                    });
                    _applyCurrentFiltersAndSort(); // Áp dụng bộ lọc và sắp xếp
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddProductDialog() {
    final _nameController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _imageUrlController = TextEditingController();
    final _priceController = TextEditingController();
    final _quantityController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thêm sản phẩm mới'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Tên sản phẩm'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên sản phẩm';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Mô tả'),
                  ),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(labelText: 'URL Hình ảnh'),
                  ),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(labelText: 'Giá'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập giá sản phẩm';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Giá không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(labelText: 'Số lượng'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số lượng';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Số lượng không hợp lệ';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Thêm'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final String name = _nameController.text;
                  final String description = _descriptionController.text;
                  final String imageUrl = _imageUrlController.text;
                  final double? price = double.tryParse(_priceController.text);
                  final int? quantity = int.tryParse(_quantityController.text);

                  if (price == null || quantity == null) {
                    _showCustomPopup(context, 'Giá hoặc số lượng không hợp lệ.', isError: true);
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance.collection('products').add({
                      'name': name,
                      'description': description,
                      'imageurl': imageUrl,
                      'price': price,
                      'quantity': quantity,
                      'createdAt': FieldValue.serverTimestamp(), // Quan trọng cho sắp xếp mặc định
                    });

                    Navigator.of(context).pop();
                    _showCustomPopup(context, 'Thêm sản phẩm thành công!');
                    _fetchProducts(); // Tải lại và áp dụng bộ lọc/sắp xếp
                  } catch (e) {
                    print('Lỗi khi thêm sản phẩm: $e');
                    Navigator.of(context).pop();
                    _showCustomPopup(context, 'Lỗi khi thêm sản phẩm.', isError: true);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(Map<String, dynamic> productData) {
    final String productId = productData['id'];

    final _nameController = TextEditingController(text: productData['name'] ?? '');
    final _descriptionController = TextEditingController(text: productData['description'] ?? '');
    final _imageUrlController = TextEditingController(text: productData['imageurl'] ?? '');
    final _priceController = TextEditingController(text: (productData['price'] as num?)?.toString() ?? '');
    final _quantityController = TextEditingController(text: (productData['quantity'] as num?)?.toString() ?? '');
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chỉnh sửa sản phẩm'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Tên sản phẩm'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên sản phẩm';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Mô tả'),
                  ),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(labelText: 'URL Hình ảnh'),
                  ),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(labelText: 'Giá'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập giá sản phẩm';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Giá không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(labelText: 'Số lượng'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số lượng';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Số lượng không hợp lệ';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Lưu thay đổi'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final String name = _nameController.text;
                  final String description = _descriptionController.text;
                  final String imageUrl = _imageUrlController.text;
                  final double? price = double.tryParse(_priceController.text);
                  final int? quantity = int.tryParse(_quantityController.text);

                  if (price == null || quantity == null) {
                    _showCustomPopup(context, 'Giá hoặc số lượng không hợp lệ.', isError: true);
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('products')
                        .doc(productId)
                        .update({
                      'name': name,
                      'description': description,
                      'imageurl': imageUrl,
                      'price': price,
                      'quantity': quantity,
                      // 'updatedAt': FieldValue.serverTimestamp(), // Optional
                    });

                    Navigator.of(context).pop();
                    _showCustomPopup(context, 'Cập nhật sản phẩm thành công!');
                    _fetchProducts(); // Tải lại danh sách
                  } catch (e) {
                    print('Lỗi khi cập nhật sản phẩm: $e');
                    Navigator.of(context).pop();
                    _showCustomPopup(context, 'Lỗi khi cập nhật sản phẩm.', isError: true);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(String productId, String productName) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa sản phẩm "$productName"? Thao tác này không thể hoàn tác.'),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == null || !confirmDelete) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      _showCustomPopup(context, 'Xóa sản phẩm "$productName" thành công!');
      _fetchProducts(); // Tải lại danh sách
    } catch (e) {
      print('Lỗi khi xóa sản phẩm: $e');
      _showCustomPopup(context, 'Lỗi khi xóa sản phẩm.', isError: true);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Quản lý sản phẩm',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Nếu bạn muốn thay thế màn hình admin:
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminScreen()));
            // Nếu chỉ muốn quay lại màn hình trước đó:
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.black),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.black),
            onPressed: _showAddProductDialog,
          ),
        ],
      ),
      body: Container(
        color: Color(0xFFF5E6FF), // Màu nền tùy chỉnh
        child: _products.isEmpty && _searchText.isEmpty && _currentSortOption == SortOption.none
            ? Center(child: CircularProgressIndicator()) // Loading ban đầu
            : _filteredProducts.isEmpty && (_searchText.isNotEmpty || _currentSortOption != SortOption.none)
            ? Center( // Không có kết quả sau khi lọc/sắp xếp
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Không tìm thấy sản phẩm nào khớp với bộ lọc của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        )
            : _filteredProducts.isEmpty && _products.isEmpty // Trường hợp DB rỗng hoàn toàn
            ? Center(
          child: Text(
            'Chưa có sản phẩm nào.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        )
            : ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: _filteredProducts.length,
          itemBuilder: (context, index) {
            final productData = _filteredProducts[index];
            final String productId = productData['id'] ?? '';
            final String productName = productData['name'] ?? 'Sản phẩm không tên';

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    productData['imageurl'] != null &&
                        (productData['imageurl'] as String).isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        productData['imageurl'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.broken_image, size: 60, color: Colors.grey),
                      ),
                    )
                        : Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ID: ${productId}',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Giá: ${(productData['price'] as num?)?.toStringAsFixed(0) ?? '0'}đ',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Số lượng: ${productData['quantity'] ?? 0}',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Mô tả: ${productData['description'] ?? ''}',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Các nút hành động (Edit, Delete)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: Colors.blue[700]),
                          iconSize: 22, // Kích thước icon
                          padding: EdgeInsets.all(6.0), // Padding xung quanh icon
                          constraints: BoxConstraints(), // Bỏ qua constraints mặc định để icon nhỏ hơn
                          tooltip: 'Chỉnh sửa sản phẩm',
                          onPressed: () {
                            if (productId.isNotEmpty) {
                              _showEditProductDialog(productData);
                            } else {
                              _showCustomPopup(context, 'Không thể sửa, thiếu ID sản phẩm.', isError: true);
                            }
                          },
                        ),
                        SizedBox(height: 4), // Khoảng cách giữa 2 nút
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                          iconSize: 22,
                          padding: EdgeInsets.all(6.0),
                          constraints: BoxConstraints(),
                          tooltip: 'Xóa sản phẩm',
                          onPressed: () {
                            if (productId.isNotEmpty) {
                              _deleteProduct(productId, productName);
                            } else {
                              _showCustomPopup(context, 'Không thể xóa, thiếu ID sản phẩm.', isError: true);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}