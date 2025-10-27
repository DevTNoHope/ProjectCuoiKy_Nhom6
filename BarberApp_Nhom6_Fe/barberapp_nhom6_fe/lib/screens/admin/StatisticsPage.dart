import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/statistics_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final _svc = StatisticsService();

  List<Map<String, dynamic>> bookingsByMonth = [];
  List<Map<String, dynamic>> topServices = [];
  int totalStylists = 0;
  int totalShops = 0;
  int totalBookings = 0;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final summary = await _svc.getSummary();
      final monthly = await _svc.getBookingsByMonth();
      final top = await _svc.getTopServices();

      setState(() {
        totalStylists = summary['stylists'] ?? 0;
        totalShops = summary['shops'] ?? 0;
        totalBookings = summary['bookings'] ?? 0;
        bookingsByMonth = monthly;
        topServices = top;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text('Lỗi: $error'));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('📊 Thống kê hệ thống'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tổng quan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoCard("Thợ", totalStylists.toString(),
                    Icons.person, Colors.blue),
                _buildInfoCard("Chi nhánh", totalShops.toString(),
                    Icons.store, Colors.teal),
                _buildInfoCard("Booking", totalBookings.toString(),
                    Icons.calendar_month, Colors.orange),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              "📆 Số lượng lịch đặt theo tháng",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // Biểu đồ cột: Booking theo tháng
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= bookingsByMonth.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              bookingsByMonth[index]['month'].toString(),
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: bookingsByMonth
                      .asMap()
                      .entries
                      .map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY:
                        (e.value['count'] ?? 0).toDouble(),
                        color: Colors.teal,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      )
                    ],
                  ))
                      .toList(),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              "💅 Dịch vụ được sử dụng nhiều nhất",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // Biểu đồ tròn
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sections: topServices.isEmpty
                      ? []
                      : topServices
                      .map((s) => PieChartSectionData(
                    title: s['service_name'] ?? '',
                    value: (s['count'] ?? 0).toDouble(),
                    color: Colors.primaries[
                    topServices.indexOf(s) %
                        Colors.primaries.length],
                    radius: 70,
                    titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(14),
        width: 110,
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: color),
            ),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
