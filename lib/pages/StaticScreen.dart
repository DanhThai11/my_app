import 'dart:async'; // Cần thiết cho StreamController nếu bạn muốn quản lý stream phức tạp hơn, nhưng ở đây dùng trực tiếp map là đủ
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// --- MODELS (Giữ nguyên) ---
class ChartData {
  final DateTime date;
  final double totalRevenue;
  final int orderCount;

  ChartData({required this.date, required this.totalRevenue, required this.orderCount});
}

class ProductSalesData {
  final String productName;
  final int totalQuantitySold;

  ProductSalesData({required this.productName, required this.totalQuantitySold});
}

class FullStatisticsData {
  final List<ChartData> orderChartData;
  final List<ProductSalesData> topSellingProducts;

  FullStatisticsData({required this.orderChartData, required this.topSellingProducts});
}

class StatisticsScreen extends StatefulWidget {
  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Khởi tạo _statisticsStream với một Stream rỗng ban đầu
  // Điều này đảm bảo nó luôn được khởi tạo trước khi build() được gọi
  late Stream<FullStatisticsData> _statisticsStream = Stream.value(
      FullStatisticsData(orderChartData: [], topSellingProducts: [])
  ); // Hoặc bạn có thể dùng Stream.empty() nếu bạn muốn xử lý ConnectionState.none
  // trong StreamBuilder một cách khác. Stream.value() sẽ làm cho nó có dữ liệu
  // ngay lập tức (dữ liệu rỗng) và ConnectionState.active

  String _selectedPeriod = 'last7days';
  StreamSubscription? _statisticsSubscription;

  @override
  void initState() {
    super.initState();
    // Bây giờ _statisticsStream đã được khởi tạo, chúng ta chỉ cần
    // cập nhật nó với stream dữ liệu thực tế.
    _subscribeToStatistics(_selectedPeriod);
  }

  void _subscribeToStatistics(String period) {
    _statisticsSubscription?.cancel();

    // Gán stream mới cho _statisticsStream
    // setState không cần thiết ở đây vì StreamBuilder sẽ tự động
    // lắng nghe sự thay đổi của stream này.
    _statisticsStream = _streamFullStatisticsData(period);

    // Nếu bạn muốn StreamBuilder rebuild khi _statisticsStream được gán lại,
    // và không chỉ khi stream phát ra dữ liệu mới, bạn cần gọi setState.
    // Tuy nhiên, việc gán trực tiếp thường là đủ vì StreamBuilder
    // sẽ nhận stream mới và bắt đầu lắng nghe nó.
    // Nếu bạn gặp vấn đề UI không cập nhật khi đổi period, hãy thêm setState ở đây:
    setState(() {
      _statisticsStream = _streamFullStatisticsData(period);
    });

    _statisticsSubscription = _statisticsStream.listen(
            (data) {
          // print("Dữ liệu stream mới nhận được trong state: ${data.orderChartData.length}");
        },
        onError: (error, stackTrace) {
          print("Lỗi từ stream trong state: $error");
        }
    );
  }


  Stream<FullStatisticsData> _streamFullStatisticsData(String period) {
    DateTime endDate = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'last30days':
        startDate = endDate.subtract(Duration(days: 30));
        break;
      case 'thisMonth':
        startDate = DateTime(endDate.year, endDate.month, 1);
        break;
      case 'last7days':
      default:
        startDate = endDate.subtract(Duration(days: 7));
    }

    print("Subscribing to data from $startDate to $endDate for period: $period");

    // QUAN TRỌNG: Điều chỉnh bộ lọc trạng thái cho phù hợp với logic của bạn
    // Ví dụ: chỉ tính 'Đã giao' cho sản phẩm bán chạy, hoặc 'Đã giao' và 'Đang xử lý' cho doanh thu
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    // .where('status', whereIn: ['Đã giao', 'Đang xử lý']); // Thêm lại nếu bạn cần lọc theo status

    return query.snapshots().map((querySnapshot) {
      print("Stream received ${querySnapshot.docs.length} documents for period: $period");






      // --- 1. Xử lý dữ liệu cho biểu đồ doanh thu & số lượng đơn hàng ---
      Map<DateTime, ChartData> aggregatedOrderData = {};
      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?; // Ép kiểu an toàn
          if (data == null) continue;

          final orderDateTimestamp = data['orderDate'] as Timestamp?;
          final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;

          if (orderDateTimestamp != null) {
            DateTime dateOnly = DateTime(
              orderDateTimestamp.toDate().year,
              orderDateTimestamp.toDate().month,
              orderDateTimestamp.toDate().day,
            );
            if (aggregatedOrderData.containsKey(dateOnly)) {
              aggregatedOrderData[dateOnly] = ChartData(
                date: dateOnly,
                totalRevenue: aggregatedOrderData[dateOnly]!.totalRevenue + totalAmount,
                orderCount: aggregatedOrderData[dateOnly]!.orderCount + 1,
              );
            } else {
              aggregatedOrderData[dateOnly] = ChartData(
                date: dateOnly,
                totalRevenue: totalAmount,
                orderCount: 1,
              );
            }
          }
        }
      }
      List<ChartData> finalOrderChartData = [];
      DateTime currentChartDateLoop = DateTime(startDate.year, startDate.month, startDate.day);
      DateTime endChartDateLoop = DateTime(endDate.year, endDate.month, endDate.day);

      while (!currentChartDateLoop.isAfter(endChartDateLoop)) {
        DateTime currentDayOnly = DateTime(currentChartDateLoop.year, currentChartDateLoop.month, currentChartDateLoop.day);
        if (aggregatedOrderData.containsKey(currentDayOnly)) {
          finalOrderChartData.add(aggregatedOrderData[currentDayOnly]!);
        } else {
          finalOrderChartData.add(ChartData(date: currentDayOnly, totalRevenue: 0, orderCount: 0));
        }
        currentChartDateLoop = currentChartDateLoop.add(Duration(days: 1));
        if (finalOrderChartData.length > 90) break; // Giới hạn an toàn
      }
      finalOrderChartData.sort((a, b) => a.date.compareTo(b.date));

      // --- 2. Xử lý dữ liệu cho sản phẩm bán chạy nhất ---
      Map<String, int> productQuantities = {};
      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          final List<dynamic>? items = data['items'] as List<dynamic>?;
          if (items != null) {
            for (var item in items) {
              if (item is Map<String, dynamic>) {
                final String? productName = item['name'] as String?;
                final int? quantity = (item['quantity'] as num?)?.toInt();

                if (productName != null && quantity != null && quantity > 0) {
                  productQuantities[productName] = (productQuantities[productName] ?? 0) + quantity;
                }
              }
            }
          }
        }
      }

      List<ProductSalesData> sortedProducts = productQuantities.entries
          .map((entry) => ProductSalesData(productName: entry.key, totalQuantitySold: entry.value))
          .toList();
      sortedProducts.sort((a, b) => b.totalQuantitySold.compareTo(a.totalQuantitySold));
      List<ProductSalesData> topSellingProducts = sortedProducts.take(5).toList();

      // print("Processed Order Chart Data Points (Stream): ${finalOrderChartData.length}");
      // print("Top Selling Products (Stream): ${topSellingProducts.map((p) => '${p.productName}: ${p.totalQuantitySold}').toList()}");

      return FullStatisticsData(
        orderChartData: finalOrderChartData,
        topSellingProducts: topSellingProducts,
      );
    }).handleError((error, stackTrace) {
      // Xử lý lỗi từ stream một cách tập trung nếu cần
      print('Lỗi trong stream _streamFullStatisticsData: $error');
      print('Stack trace: $stackTrace');
      // Có thể throw lại lỗi hoặc trả về một FullStatisticsData rỗng/đặc biệt để báo lỗi
      // return FullStatisticsData(orderChartData: [], topSellingProducts: []); // Ví dụ
      throw Exception('Không thể tải dữ liệu thống kê từ stream: $error');
    });
  }

  void _onPeriodChange(String? newPeriod) {
    if (newPeriod != null && newPeriod != _selectedPeriod) {
      setState(() {
        _selectedPeriod = newPeriod;
        // Gọi lại hàm để subscribe với period mới
        _subscribeToStatistics(_selectedPeriod);
      });
    }
  }

  @override
  void dispose() {
    _statisticsSubscription?.cancel(); // Quan trọng: Hủy lắng nghe để tránh memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thống kê (Trực tiếp)'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<String>(
                value: _selectedPeriod,
                decoration: InputDecoration(
                  labelText: 'Chọn khoảng thời gian',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  DropdownMenuItem(value: 'last7days', child: Text('7 ngày qua')),
                  DropdownMenuItem(value: 'last30days', child: Text('30 ngày qua')),
                  DropdownMenuItem(value: 'thisMonth', child: Text('Tháng này')),
                ],
                onChanged: _onPeriodChange,
              ),
            ),
            SizedBox(height: 20),

            // Sử dụng StreamBuilder
            StreamBuilder<FullStatisticsData>(
              stream: _statisticsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  // Hiển thị loading chỉ khi đang chờ và chưa có dữ liệu nào (lần đầu tải)
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  print('Lỗi StreamBuilder (StatisticsScreen): ${snapshot.error}');
                  return Center(
                      child: Text(
                        'Đã xảy ra lỗi: ${snapshot.error?.toString()}.\nVui lòng kiểm tra console.',
                        textAlign: TextAlign.center,
                      ));
                } else if (!snapshot.hasData || (snapshot.data!.orderChartData.isEmpty && snapshot.data!.topSellingProducts.isEmpty)) {
                  // Nếu stream đã active nhưng không có dữ liệu (có thể do không có đơn hàng nào khớp)
                  // hoặc có dữ liệu nhưng cả 2 list đều rỗng
                  return Center(child: Text('Không có dữ liệu thống kê cho khoảng thời gian này.'));
                }

                // Nếu có dữ liệu (kể cả khi đang connectionState.waiting nhưng đã có dữ liệu cũ)
                // StreamBuilder sẽ tự rebuild khi có dữ liệu mới từ stream
                final FullStatisticsData statsData = snapshot.data!;
                final List<ChartData> orderData = statsData.orderChartData;
                final List<ProductSalesData> topProductsData = statsData.topSellingProducts;

                // Hiển thị loading indicator nhỏ ở góc nếu đang cập nhật ngầm
                Widget updatingIndicator = Container();
                if (snapshot.connectionState == ConnectionState.waiting && snapshot.hasData) {
                  updatingIndicator = Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0))
                      )
                  );
                }


                return Stack( // Sử dụng Stack để có thể overlay loading indicator
                  children: [
                    Column(
                      children: [
                        if (orderData.isNotEmpty || topProductsData.isNotEmpty) ...[ // Chỉ hiển thị nếu có ít nhất 1 loại dữ liệu
                          if (orderData.isNotEmpty) ...[
                            _buildSectionTitle('Doanh thu (${_getPeriodText()})'),
                            Container(
                              height: 300,
                              child: LineChart(_buildRevenueChart(orderData)),
                            ),
                            SizedBox(height: 30),
                            _buildSectionTitle('Số lượng đơn hàng (${_getPeriodText()})'),
                            Container(
                              height: 300,
                              child: LineChart(_buildOrderCountChart(orderData)),
                            ),
                            SizedBox(height: 30),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20.0),
                              child: Text('Không có dữ liệu đơn hàng cho khoảng thời gian này.', textAlign: TextAlign.center),
                            )
                          ],

                          if (topProductsData.isNotEmpty) ...[
                            _buildSectionTitle('Top 5 Sản phẩm bán chạy (${_getPeriodText()})'),
                            Container(
                              height: 350,
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: BarChart(_buildTopSellingProductsChart(topProductsData)),
                            ),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20.0),
                              child: Text('Không có dữ liệu sản phẩm bán chạy cho khoảng thời gian này.', textAlign: TextAlign.center),
                            )
                          ],
                        ] else if (snapshot.connectionState != ConnectionState.waiting) ... [
                          // Trường hợp này đã được xử lý bởi điều kiện !snapshot.hasData ở trên,
                          // nhưng thêm để rõ ràng nếu logic thay đổi
                          Center(child: Text('Không có dữ liệu thống kê nào để hiển thị.'))
                        ],
                      ],
                    ),
                    updatingIndicator,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- CÁC HÀM BUILD UI VÀ HELPER (Giữ nguyên) ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
    );
  }

  String _getPeriodText() {
    switch (_selectedPeriod) {
      case 'last7days': return '7 Ngày Qua';
      case 'last30days': return '30 Ngày Qua';
      case 'thisMonth': return 'Tháng Này';
      default: return '';
    }
  }

  LineChartData _buildRevenueChart(List<ChartData> data) {
    List<FlSpot> spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalRevenue);
    }).toList();

    double maxYValue = 0;
    if (data.isNotEmpty) {
      maxYValue = data.map((d) => d.totalRevenue).reduce((a, b) => a > b ? a : b);
    }
    double maxY = maxYValue * 1.2;
    if (maxY == 0) maxY = 100000;

    return LineChartData(
      // ... (Phần còn lại của _buildRevenueChart giữ nguyên như trước)
      maxY: maxY,
      minY: 0,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xffe7e8ec), strokeWidth: 1),
        getDrawingVerticalLine: (value) => FlLine(color: const Color(0xffe7e8ec), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: data.length > 7 ? (data.length / 7).ceilToDouble() : 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index >= 0 && index < data.length) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8.0,
                  child: Text(DateFormat('dd/MM').format(data[index].date), style: TextStyle(fontSize: 10, color: Colors.blueGrey[600])),
                );
              }
              return Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 55,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value == 0 || value == maxY || (maxY > 0 && value % (maxY / 5).floor() == 0)) {
                return Text(
                  NumberFormat.compactSimpleCurrency(locale: 'vi_VN', decimalDigits: 0).format(value),
                  style: TextStyle(fontSize: 9, color: Colors.blueGrey[600]),
                  textAlign: TextAlign.left,
                );
              }
              return Text('');
            },
            interval: (maxY / 5).floorToDouble() > 0 ? (maxY / 5).floorToDouble() : maxY / 2,
          ),
        ),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xffe7e8ec), width: 1)),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blueAccent,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: spots.length <= 15),
          belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.2)),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              if (flSpot.spotIndex >= 0 && flSpot.spotIndex < data.length) {
                final chartPoint = data[flSpot.spotIndex];
                return LineTooltipItem(
                  '${DateFormat('dd/MM/yyyy').format(chartPoint.date)}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: <TextSpan>[
                    TextSpan(
                      text: NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(chartPoint.totalRevenue),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ],
                );
              }
              return null;
            }).toList();
          },
        ),
      ),
    );
  }

  LineChartData _buildOrderCountChart(List<ChartData> data) {
    List<FlSpot> spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.orderCount.toDouble());
    }).toList();

    double maxYValue = 0;
    if (data.isNotEmpty) {
      maxYValue = data.map((d) => d.orderCount).reduce((a, b) => a > b ? a : b).toDouble();
    }
    double maxY = maxYValue * 1.2;
    if (maxY == 0) maxY = 10;

    return LineChartData(
      // ... (Phần còn lại của _buildOrderCountChart giữ nguyên như trước)
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: data.length > 7 ? (data.length / 7).ceilToDouble() : 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0,
                    child: Text(DateFormat('dd/MM').format(data[index].date), style: TextStyle(fontSize: 10, color: Colors.blueGrey[600])),
                  );
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (maxY / 5).ceilToDouble() > 0 ? (maxY / 5).ceilToDouble() : 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() == 0 || value.toInt() == maxY.toInt() || (maxY > 0 && value.toInt() % (maxY / 5).ceil() == 0) ) {
                    return Text(value.toInt().toString(), style: TextStyle(fontSize: 10, color: Colors.blueGrey[600]), textAlign: TextAlign.left);
                  }
                  return Text('');
                }
            ),
          ),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.greenAccent.shade700,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: spots.length <= 15),
            belowBarData: BarAreaData(show: true, color: Colors.greenAccent.withOpacity(0.2)),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                if (flSpot.spotIndex >= 0 && flSpot.spotIndex < data.length) {
                  final chartPoint = data[flSpot.spotIndex];
                  return LineTooltipItem(
                    '${DateFormat('dd/MM/yyyy').format(chartPoint.date)}\n',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    children: <TextSpan>[
                      TextSpan(
                        text: '${chartPoint.orderCount} đơn',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ],
                  );
                }
                return null;
              }).toList();
            },
          ),
        )
    );
  }

  BarChartData _buildTopSellingProductsChart(List<ProductSalesData> productData) {
    if (productData.isEmpty) {
      return BarChartData(barGroups: []);
    }

    double maxYValue = 0;
    if (productData.isNotEmpty) {
      maxYValue = productData.map((d) => d.totalQuantitySold).reduce((a, b) => a > b ? a : b).toDouble();
    }
    double maxY = maxYValue * 1.2;
    if (maxY == 0) maxY = 10;

    return BarChartData(
      // ... (Phần còn lại của _buildTopSellingProductsChart giữ nguyên như trước)
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      minY: 0,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            if (groupIndex >= 0 && groupIndex < productData.length) {
              final product = productData[groupIndex];
              return BarTooltipItem(
                '${product.productName}\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14,),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Đã bán: ${product.totalQuantitySold}',
                    style: const TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.w500,),
                  ),
                ],
              );
            }
            return null;
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index >= 0 && index < productData.length) {
                String name = productData[index].productName;
                if (name.length > 15) { name = '${name.substring(0, 12)}...';}
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 6.0,
                  angle: productData.length > 3 ? -0.5 : 0,
                  child: Text(name, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 10)),
                );
              }
              return Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (maxY / 5).ceilToDouble() > 0 ? (maxY / 5).ceilToDouble() : 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value.toInt() == 0 || value.toInt() == maxY.toInt() || (maxY > 0 && value.toInt() % (maxY / 5).ceil() == 0) ) {
                return Text(value.toInt().toString(), style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 10));
              }
              return Text('');
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: productData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: data.totalQuantitySold.toDouble(),
              color: Colors.teal,
              width: productData.length > 5 ? 12 : 18,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        );
      }).toList(),
      gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.8)
      ),
    );
  }
}