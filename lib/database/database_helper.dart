// import 'dart:async';
// import 'dart:ffi';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
//
// class DatabaseHelper {
//   static final DatabaseHelper _instance = DatabaseHelper._internal();
//   static Database? _database;
//
//   factory DatabaseHelper() {
//     return _instance;
//   }
//
//   DatabaseHelper._internal();
//
//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDatabase();
//     return _database!;
//   }
//
//   Future<Database> _initDatabase() async {
//     String path = join(await getDatabasesPath(), 'app_database.db');
//     return await openDatabase(
//       path,
//       version: 4,
//       onCreate: _onCreate,
//     );
//   }
//
//   Future<void> _onCreate(Database db, int version) async {
//     //bảng users
//     await db.execute('''
//       CREATE TABLE users (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         username TEXT NOT NULL UNIQUE,
//         password TEXT NOT NULL,
//         name TEXT,
//         email TEXT,
//         phone TEXT
//       )
//     ''');
//
//     //bảng products
//     await db.execute('''
//       CREATE TABLE products (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         name TEXT NOT NULL,
//         price REAL NOT NULL,
//         quantity INTEGER NOT NULL,
//         description TEXT,
//         image TEXT
//       )
//     ''');
//
//     //bảng out_of_stock_products(sản phẩm hết hàng)
//     await db.execute('''
//       CREATE TABLE out_of_stock_products (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         productId INTEGER,
//         name TEXT ,
//         price REAL ,
//         quantity INTEGER ,
//         description TEXT,
//         image TEXT,
//         FOREIGN KEY(productId) REFERENCES products(id)
//       )
//     ''');
//
//     //bảng cart
//     await db.execute('''
//       CREATE TABLE cart (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         productId INTEGER,
//         name TEXT ,
//         price REAL ,
//         quantity INTEGER,
//         image TEXT,
//         FOREIGN KEY(productId) REFERENCES products(id)
//       )
//     ''');
//
//     //bảng history
//     await db.execute('''
//       CREATE TABLE history (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         orderDate TEXT,
//         totalPrice REAL,
//         status TEXT
//       )
//     ''');
//
//     await db.execute('''
//       CREATE TABLE history_detail (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         cartId INTEGER,
//         historyId INTEGER,
//         name TEXT ,
//         price REAL ,
//         quantity INTEGER,
//         image TEXT,
//         FOREIGN KEY(cartId) REFERENCES cart(id),
//         FOREIGN KEY(historyId) REFERENCES history(id)
//       )
//     ''');
//   }
//
//   //quản lý người dùng
//   Future<int> registerUser(String username, String password, String name, String email, String phone) async {
//     final db = await database;
//     return await db.insert(
//       'users',
//       {
//         'username': username,
//         'password': password,
//         'name' : name,
//         'email' : email,
//         'phone' : phone
//       },
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   }
//
//   //danh sách tài khoản
//   Future<List<Map<String, dynamic>>> getAllUsers() async {
//     final db = await database;
//     return await db.query('users');
//   }
//
//   //xóa dữ liệu
//   Future<void> clearDatabase() async {
//     final db = await database;
//     await db.delete('users');
//     print("Tất cả dữ liệu đã được xóa.");
//   }
//
//   //kiểm tra username có tồn tại hay chưa
//   Future<bool> usernameExist(String username) async {
//     final db = await database;
//     final result = await db.query(
//       'users',
//       where: 'username = ?',
//       whereArgs: [username],
//     );
//     return result.isNotEmpty;
//   }
//
//   //xoá tài khoản
//   Future<int> deleteUser(int id) async {
//     final db = await database;
//     return await db.delete(
//       'users',
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//   }
//
//   //Kiểm tra tài khoản
//   Future<bool> checkLogin(String username, String password) async {
//     final db = await database;
//     final result = await db.query(
//       'users',
//       where: 'username = ? AND password = ?',
//       whereArgs: [username, password],
//     );
//     return result.isNotEmpty;
//   }
//
//   // đếm tài khoản
//   Future<int> getUserCount() async {
//     final db = await database;
//     final result = await db.rawQuery('SELECT COUNT(*) AS count FROM users');
//     final count = Sqflite.firstIntValue(result) ?? 0;
//     return count;
//   }
//   //cập nhật tài khoản
//   Future<int> updateUser(Map<String, dynamic> user) async {
//     final db = await database;
//     return await db.update(
//       'users',
//       user,
//       where: 'id = ?',
//       whereArgs: [user['id']],
//     );
//   }
//   //thêm sản phẩm
//   Future<int> insertProduct(Map<String, dynamic> product) async {
//     final db = await database;
//     return await db.insert('products', product);
//   }
//
//   // Thêm sản phẩm vào bảng out_of_stock_products
//   Future<void> addProductToout_of_stock_products(int productId) async {
//     final db = await database;
//
//     // Lấy thông tin sản phẩm từ bảng products
//     final List<Map<String, dynamic>> product = await db.query(
//       'products',
//       where: 'id = ?',
//       whereArgs: [productId],
//     );
//
//     if (product.isEmpty) {
//       print('Sản phẩm không tồn tại.');
//       return;
//     }
//
//     final productData = product.first;
//
//     // Kiểm tra xem sản phẩm đã tồn tại trong out_of_stock_products hay chưa
//     final List<Map<String, dynamic>> outOfStockProduct = await db.query(
//       'out_of_stock_products',
//       where: 'productId = ?',
//       whereArgs: [productId],
//     );
//
//     if (outOfStockProduct.isNotEmpty) {
//       print('Sản phẩm đã tồn tại trong bảng out_of_stock_products.');
//       return;
//     }
//
//     // Chuyển sản phẩm sang bảng out_of_stock_products
//     await db.insert(
//       'out_of_stock_products',
//       {
//         'productId': productData['id'],
//         'name': productData['name'],
//         'price': productData['price'],
//         'quantity': productData['quantity'],
//         'description': productData['description'],
//         'image': productData['image'],
//       },
//     );
//
//     // Cập nhật số lượng sản phẩm trong bảng products thành 0 (nếu cần)
//     await db.update(
//       'products',
//       {'quantity': 0},
//       where: 'id = ?',
//       whereArgs: [productId],
//     );
//
//     print('Sản phẩm đã được chuyển sang bảng out_of_stock_products.');
//   }
//
//   // Thêm out_of_stock_products vào bảng sản phẩm
//   Future<void> addout_of_stock_productsToProduct(int productId) async {
//     final db = await database;
//
//     // Lấy thông tin sản phẩm từ bảng products
//     final List<Map<String, dynamic>> product = await db.query(
//       'out_of_stock_products',
//       where: 'id = ?',
//       whereArgs: [productId],
//     );
//
//     if (product.isEmpty) {
//       print('Sản phẩm không tồn tại.');
//       return;
//     }
//
//     final productData = product.first;
//
//     // Kiểm tra xem sản phẩm đã tồn tại trong out_of_stock_products hay chưa
//     final List<Map<String, dynamic>> outOfStockProduct = await db.query(
//       'products',
//       where: 'productId = ?',
//       whereArgs: [productId],
//     );
//
//     if (outOfStockProduct.isNotEmpty) {
//       print('Sản phẩm đã tồn tại trong bảng out_of_stock_products.');
//       return;
//     }
//
//     // Chuyển sản phẩm sang bảng out_of_stock_products
//     await db.insert(
//       'products',
//       {
//         'productId': productData['id'],
//         'name': productData['name'],
//         'price': productData['price'],
//         'quantity': productData['quantity'],
//         'description': productData['description'],
//         'image': productData['image'],
//       },
//     );
//
//   }
//
//   //lấy sản phẩm
//   Future<List<Map<String, dynamic>>> getAllProducts() async {
//     final db = await database;
//     return await db.query('products');
//   }
//
//   //lấy sản phẩm hết hàng
//   Future<List<Map<String, dynamic>>> getAllOut_of_stock_products() async {
//     final db = await database;
//     return await db.query('out_of_stock_products');
//   }
//
//   // Thêm sản phẩm
//   Future<int> addProduct(String name, double price, int quantity,
//       String description, String image) async {
//     final db = await database;
//     try {
//       return await db.insert(
//         'products',
//         {
//           'name': name,
//           'price': price,
//           'quantity': quantity,
//           'description': description,
//           'image': image,
//         },
//         conflictAlgorithm: ConflictAlgorithm.replace,
//       );
//     } catch (e) {
//       print('Lỗi khi thêm sản phẩm: $e');
//       return -1;
//     }
//   }
//
//   // Cập nhật sản phẩm
//   Future<int> updateProduct(Map<String, dynamic> product) async {
//     final db = await database;
//     return await db.update(
//       'products',
//       product,
//       where: 'id = ?',
//       whereArgs: [product['id']],
//     );
//   }
//  //cập nhật sản phẩm hết hạn
//   Future<int> updateout_of_stockProduct(Map<String, dynamic> out_of_stockproducts) async {
//     final db = await database;
//     return await db.update(
//       'out_of_stock_products',
//       out_of_stockproducts,
//       where: 'id = ?',
//       whereArgs: [out_of_stockproducts['id']],
//     );
//   }
//
//   // Xóa sản phẩm
//   Future<int> deleteProduct(int producId) async {
//     final db = await database;
//     return await db.delete(
//       'products',
//       where: 'id = ?',
//       whereArgs: [producId],
//     );
//   }
//
//   //xóa sản phẩm hết hạn
//   Future<int> deleteout_of_stockProduct(int producId) async {
//     final db = await database;
//     return await db.delete(
//       'out_of_stock_products',
//       where: 'id = ?',
//       whereArgs: [producId],
//     );
//   }
//
//   //lấy thông tin sản phẩm theo ID
//   Future<Map<String, dynamic>> getProductById(int productId) async {
//     final db = await database;
//     final result = await db.query(
//       'products',
//       where: 'id = ?',
//       whereArgs: [productId],
//       limit: 1,
//     );
//     return result.isNotEmpty ? result.first : {};
//   }
//
//
//   Future<void> checkTables() async {
//     final db = await database;
//     final List<Map<String, dynamic>> result = await db.rawQuery(
//         "SELECT name FROM sqlite_master WHERE type='table'");
//     print("Danh sách bảng: ${result.map((e) => e['name']).toList()}");
//   }
//
//   //thêm sản phẩm vào giỏ hàng
//   Future<void> addProductToCart(int productId) async {
//     final db = await database;
//
//     //lấy thông tin sản phẩm từ bảng products
//     final List<Map<String, dynamic>> product = await db.query(
//       'products',
//       where: 'id = ?',
//       whereArgs: [productId],
//     );
//
//     if (product.isEmpty) {
//       print('Sản phẩm không tồn tại.');
//       return;
//     }
//
//     final productData = product.first;
//
//     //kiểm tra xem sản phẩm đã tồn tại trong giỏ hàng hay chưa
//     final List<Map<String, dynamic>> cart = await db.query(
//       'cart',
//       where: 'productId = ?',
//       whereArgs: [productId],
//     );
//
//     if (cart.isNotEmpty) {
//       //nếu đã tồn tại, tăng số lượng
//       final currentQuantity = cart.first['quantity'] ?? 1;
//       await db.update(
//         'cart',
//         {'quantity': currentQuantity + 1},
//         where: 'productId = ?',
//         whereArgs: [productId],
//       );
//       print('Sản phẩm đã tồn tại. Số lượng mới: ${currentQuantity + 1}');
//     } else {
//       //nếu chưa tồn tại, thêm sản phẩm mới vào giỏ hàng
//       await db.insert(
//         'cart',
//         {
//           'productId': productData['id'],
//           'name': productData['name'],
//           'price': productData['price'],
//           'quantity': 1, // Số lượng mặc định là 1
//           'image': productData['image'],
//         },
//       );
//       print('Đã thêm sản phẩm vào giỏ hàng.');
//     }
//   }
//
//   //tăng số lượng sản phẩm
//   Future<void> addQuantity(int productId) async {
//     final db = await database;
//     final List<Map<String, dynamic>> cart = await db.query(
//       'cart',
//       where: 'productId = ?',
//       whereArgs: [productId],
//     );
//     if (cart.isNotEmpty) {
//       final currentQuantity = cart.first['quantity'] ?? 1;
//       await db.update(
//         'cart',
//         {'quantity': currentQuantity + 1},
//         where: 'productId = ?',
//         whereArgs: [productId],
//       );
//       print('Số lượng sản phẩm tăng lên: ${currentQuantity + 1}');
//     } else {
//       print('Sản phẩm không tồn tại trong giỏ hàng.');
//     }
//   }
//
//   //giảm số lượng sản phẩm
//   Future<void> removeQuantity(int productId) async {
//     final db = await database;
//
//     // lấy thông tin sản phẩm trong giỏ hàng
//     final List<Map<String, dynamic>> cart = await db.query(
//       'cart',
//       where: 'productId = ?',
//       whereArgs: [productId],
//     );
//
//     if (cart.isNotEmpty) {
//       final currentQuantity = cart.first['quantity'] ?? 1;
//
//       if (currentQuantity > 1) {
//         //giảm số lượng nếu lớn hơn 1
//         await db.update(
//           'cart',
//           {'quantity': currentQuantity - 1},
//           where: 'productId = ?',
//           whereArgs: [productId],
//         );
//         print('Số lượng sản phẩm giảm xuống: ${currentQuantity - 1}');
//       } else {
//         // Xóa sản phẩm khỏi giỏ hàng nếu số lượng là 1
//         await db.delete(
//           'cart',
//           where: 'productId = ?',
//           whereArgs: [productId],
//         );
//         print('Sản phẩm đã được xóa khỏi giỏ hàng.');
//       }
//     }
//   }
//
//   //lấy sản phẩm trong cart
//   Future<List<Map<String, dynamic>>> getAllCartItems() async {
//     final db = await database;
//     return await db.query('cart');
//   }
//
//   //tính giá trị sản phẩm
//   Future<double> totalPrice() async {
//     final db = await database;
//
//     final List<Map<String, dynamic>> cart = await db.query('cart');
//
//     double totalPrice = cart.fold(0, (sum, item) {
//       final price = item['price'] as double;
//       final quantity = item['quantity'] as int;
//       return sum + (price * quantity);
//     });
//
//     print('Tổng giá trị giỏ hàng: $totalPrice');
//     return totalPrice;
//   }
//
//
//   Future<void> updateCartItemQuantity(int productId, int newQuantity) async {
//     final db = await database;
//     if (newQuantity > 0) {
//       //cập nhật số lượng
//       await db.update(
//         'cart',
//         {'quantity': newQuantity},
//         where: 'productId = ?',
//         whereArgs: [productId],
//       );
//       print('Đã cập nhật số lượng sản phẩm trong giỏ hàng.');
//     } else {
//       // Xóa sản phẩm nếu số lượng <= 0
//       await deleteCartItem(productId);
//     }
//   }
//
//   //xóa sản phẩm khỏi giỏ hàng
//   Future<void> deleteCartItem(int productId) async {
//     final db = await database;
//     await db.delete(
//       'cart',
//       where: 'productId = ?',
//       whereArgs: [productId],
//     );
//     print('Đã xóa sản phẩm khỏi giỏ hàng.');
//   }
//
//   Future<void> resetDatabase() async {
//     String path = join(await getDatabasesPath(), 'app_database.db');
//     await deleteDatabase(path);
//     _database = null;
//     await database;
//     print("đã xóa");
//   }
//
// //lấy số lượng sản phẩm trong sản phẩm
//   Future<int> getProductCount() async {
//     final db = await database;
//
//     // Sử dụng COUNT(*) để đếm số dòng trong bảng products
//     final result = await db.rawQuery('SELECT COUNT(*) AS count FROM products');
//
//     //lấy số lượng từ kết quả truy vấn
//     final count = Sqflite.firstIntValue(result) ?? 0;
//
//     print('Số lượng item trong bảng products: $count');
//     return count;
//   }
//
//   //lấy số lượng sản phẩm trong giỏ hàng
//   Future<int> getCartCount() async {
//     final db = await database;
//
//     // Sử dụng COUNT(*) để đếm số dòng trong bảng products
//     final result = await db.rawQuery('SELECT COUNT(*) AS count FROM cart');
//
//     // Lấy số lượng từ kết quả truy vấn
//     final count = Sqflite.firstIntValue(result) ?? 0;
//
//     print('Số lượng item trong bảng products: $count');
//     return count;
//   }
//
//   Future<void> addCartToHistory(String status) async {
//     final db = await database;
//
//     //lấy tất cả sản phẩm trong giỏ hàng
//     final List<Map<String, dynamic>> cartItems = await db.query('cart');
//
//     if (cartItems.isEmpty) {
//       print('Giỏ hàng trống. Không có gì để thêm vào lịch sử.');
//       return;
//     }
//
//     //kiểm tra số lượng sản phẩm trong kho trước khi thêm vào lịch sử
//     for (var item in cartItems) {
//       int productId = item['productId'] as int;
//       int cartQuantity = item['quantity'] as int;
//
//       //lấy thông tin sản phẩm từ bảng products
//       final List<Map<String, dynamic>> product = await db.query(
//         'products',
//         where: 'id = ?',
//         whereArgs: [productId],
//       );
//
//       if (product.isEmpty) {
//         print('Sản phẩm với ID $productId không tồn tại.');
//         return;
//       }
//
//       // int currentQuantity = product.first['quantity'] as int;
//       //
//       // if (cartQuantity > currentQuantity) {
//       //   // Nếu số lượng mua vượt quá số lượng tồn kho
//       //   print(
//       //       'Số lượng sản phẩm "${product.first['name']}" không đủ. Chỉ còn lại $currentQuantity sản phẩm trong kho.');
//       //   return; // Dừng quá trình nếu phát hiện lỗi
//       // }
//     }
//
//     //tính tổng giá trị giỏ hàng
//     double totalPrice = cartItems.fold(0, (sum, item) {
//       final price = item['price'] as double;
//       final quantity = item['quantity'] as int;
//       return sum + (price * quantity);
//     });
//
//     //thêm đơn hàng mới vào bảng history
//     int historyId = await db.insert('history', {
//       'orderDate': DateTime.now().toIso8601String(),
//       'totalPrice': totalPrice,
//       'status': status,
//     });
//
//     //thêm các sản phẩm vào bảng history_detail và trừ số lượng sản phẩm trong kho
//     for (var item in cartItems) {
//       int productId = item['productId'] as int;
//       int cartQuantity = item['quantity'] as int;
//
//       //thêm sản phẩm vào bảng history_detail
//       await db.insert('history_detail', {
//         'historyId': historyId,
//         'cartId': item['id'],
//         'name': item['name'],
//         'price': item['price'],
//         'quantity': cartQuantity,
//         'image': item['image'],
//       });
//
//       //trừ số lượng sản phẩm trong kho
//       final List<Map<String, dynamic>> product = await db.query(
//         'products',
//         where: 'id = ?',
//         whereArgs: [productId],
//       );
//
//       if (product.isNotEmpty) {
//         int currentQuantity = product.first['quantity'] as int;
//         int updatedQuantity = currentQuantity - cartQuantity;
//
//         await db.update(
//           'products',
//           {'quantity': updatedQuantity},
//           where: 'id = ?',
//           whereArgs: [productId],
//         );
//       }
//     }
//
//     // Xóa toàn bộ giỏ hàng
//     await db.delete('cart');
//
//     print('Đã chuyển giỏ hàng vào lịch sử và cập nhật số lượng sản phẩm.');
//   }
//
//
//
//
//   Future<List<Map<String, dynamic>>> getAllHistory() async {
//     final db = await database;
//     return await db.query('history'); // Bảng 'history' chứa lịch sử
//   }
//
//   Future<List<Map<String, dynamic>>> getHistoryDetails(int historyId) async {
//     final db = await database;
//     return await db.query(
//       'history_detail',
//       where: 'historyId = ?',
//       whereArgs: [historyId],
//     );
//   }
//
//   Future<int> getHistoryCount() async {
//     final db = await database;
//
//     //sử dụng COUNT(*) để đếm số dòng trong bảng products
//     final result = await db.rawQuery('SELECT COUNT(*) AS count FROM history');
//
//     //lấy số lượng từ kết quả truy vấn
//     final count = Sqflite.firstIntValue(result) ?? 0;
//
//     print('Số lượng item trong bảng history: $count');
//     return count;
//   }
//
//   Future<int> getproductCount() async {
//     final db = await database;
//
//     //sử dụng COUNT(*) để đếm số dòng trong bảng products
//     final result = await db.rawQuery('SELECT COUNT(*) AS count FROM out_of_stock_products');
//
//     //lấy số lượng từ kết quả truy vấn
//     final count = Sqflite.firstIntValue(result) ?? 0;
//
//     return count;
//   }
//
//   Future<void> deleteOrder(int id) async {
//     final db = await database;
//     await db.delete(
//        'history',
//         where: 'id = ?',
//         whereArgs: [id]);
//   }
//
// }
