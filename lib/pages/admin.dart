import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Đảm bảo các import này là chính xác và các file tồn tại
import 'package:my_app/elements/navgationMenuAdmin.dart'; // Sửa nếu tên file khác
import 'package:my_app/pages/productmanager.dart';
import 'package:my_app/pages/historymanager.dart';
import 'package:my_app/pages/userScreen.dart';
import 'package:my_app/pages/StaticScreen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- LOGIC: SỬ DỤNG STREAM ĐỂ CẬP NHẬT THỜI GIAN THỰC ---
  Stream<int> _getCountStream(String collectionName) {
    try {
      return _firestore.collection(collectionName).snapshots().map((snapshot) {
        return snapshot.docs.length;
      });
    } catch (e) {
      print("Error creating count stream for $collectionName: $e");
      return Stream.value(0);
    }
  }

  Stream<int> _getOutOfStockProductCountStream() {
    try {
      return _firestore
          .collection('products')
          .where('quantity', isLessThanOrEqualTo: 0)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.length;
      });
    } catch (e) {
      print("Error creating out of stock product count stream: $e");
      return Stream.value(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- UI: Giữ nguyên như ban đầu ---
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin',
          style: TextStyle(
            fontSize: 22,
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
        actions: [
          IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.center,
            icon: Icon(Icons.notifications_outlined, color: Color(0xff2F3194), size: 25),
            onPressed: () {
              // TODO: Xử lý sự kiện nhấn vào icon thông báo
            },
          ),
        ],
      ),
      drawer: navigationMenuAdmin(), // Đảm bảo tên này đúng
      body: Padding(
        padding: const EdgeInsets.only(top: 20, left: 21, right: 21),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProductManagementScreen()),
                        );
                      },
                      child: DashboardCard( // Sử dụng DashboardCard đã được cập nhật logic
                        color: Colors.amberAccent.shade700, // Giữ màu cũ nếu muốn
                        label: 'Sản phẩm',
                        // iconData: Icons.inventory_2, // Thêm lại nếu UI ban đầu có
                        countStream: _getCountStream('products'), // TRUYỀN STREAM
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HistoryScreenManager()),
                        );
                      },
                      child: DashboardCard(
                        color: Colors.redAccent.shade700, // Giữ màu cũ nếu muốn
                        label: 'Đơn hàng',
                        // iconData: Icons.receipt_long, // Thêm lại nếu UI ban đầu có
                        countStream: _getCountStream('orders'), // TRUYỀN STREAM
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => UserListScreen()),
                        );
                      },
                      child: DashboardCard(
                        color: Colors.green.shade700, // Giữ màu cũ nếu muốn
                        label: 'Tài khoản',
                        // iconData: Icons.people, // Thêm lại nếu UI ban đầu có
                        countStream: _getCountStream('users'), // TRUYỀN STREAM
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StatisticsScreen()),
                        );
                      },
                      child: DashboardCard(
                        color: Colors.blueAccent.shade700, // Giữ màu cũ nếu muốn
                        label: 'Thống kê SP',
                        // iconData: Icons.warning_amber_rounded, // Thêm lại nếu UI ban đầu có
                        countStream: _getOutOfStockProductCountStream(), // TRUYỀN STREAM
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xff2F3194),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

// Widget tái sử dụng cho các thẻ trên dashboard
// --- UI: Giữ nguyên giao diện của DashboardCard gốc (trừ việc nhận Stream thay vì Future) ---
// --- LOGIC: Sử dụng StreamBuilder bên trong ---
class DashboardCard extends StatelessWidget {
  final Color color;
  final String label;
  // final IconData iconData; // Bỏ đi nếu UI gốc không có, hoặc thêm lại nếu có
  final Stream<int> countStream; // THAY ĐỔI: Từ Future<int> sang Stream<int>

  const DashboardCard({
    Key? key,
    required this.color,
    required this.label,
    // required this.iconData, // Bỏ đi hoặc thêm lại tùy theo UI gốc
    required this.countStream, // THAY ĐỔI
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy lại cấu trúc UI gốc của DashboardCard của bạn ở đây
    // Ví dụ, nếu UI gốc của bạn đơn giản hơn:
    return Container(
      decoration: BoxDecoration( // Giữ lại decoration gốc
        color: color, // Hoặc color.withOpacity nếu gốc là vậy
        borderRadius: BorderRadius.circular(12), // Hoặc 15
        // boxShadow: [ ... ], // Giữ lại boxShadow gốc
      ),
      height: 160, // Giữ lại height gốc
      padding: const EdgeInsets.all(16.0), // Giữ lại padding gốc, hoặc 12.0
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Giữ lại alignment gốc
        crossAxisAlignment: CrossAxisAlignment.center, // Giữ lại alignment gốc
        children: [
          // Nếu có Icon ở UI gốc, thêm lại ở đây
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text(
          //       label,
          //       // style gốc
          //     ),
          //     Icon(iconData, /* style gốc */),
          //   ],
          // ),
          Text( // Giữ lại Text style gốc cho label
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white), // Style gốc
          ),
          SizedBox(height: 8), // Giữ lại SizedBox gốc
          StreamBuilder<int>( // THAY ĐỔI: Sử dụng StreamBuilder
            stream: countStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Giữ lại widget loading gốc, ví dụ:
                return Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)));
              }
              if (snapshot.hasError) {
                print("Error in StreamBuilder for $label: ${snapshot.error}");
                // Giữ lại widget lỗi gốc
                return Text(
                  'Lỗi',
                  textAlign: TextAlign.center, // Hoặc TextAlign.right nếu gốc là vậy
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent), // Style gốc
                );
              }
              final count = snapshot.data ?? 0;
              // Giữ lại widget hiển thị số đếm gốc
              return Align( // Hoặc không Align nếu gốc không có
                alignment: Alignment.center, // Hoặc Alignment.bottomRight nếu gốc là vậy
                child: Text(
                  '$count',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white), // Style gốc
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}