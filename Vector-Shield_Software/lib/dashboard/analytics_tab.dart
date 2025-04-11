import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dashboard_page.dart';
import 'connection_indicator.dart';

class AnalyticsTab extends StatelessWidget {
  final Size screenSize;
  final DashboardData data;
  final DashboardCallbacks callbacks;
  
  const AnalyticsTab({
    super.key,
    required this.screenSize,
    required this.data,
    required this.callbacks,
  });
  
  @override
  Widget build(BuildContext context) {
    // Calculate responsive grid columns based on screen width
    int crossAxisCount = screenSize.width < 600 ? 2 : 4;
    
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Error message if any
              if (data.errorMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data.errorMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Weight History Graph - Now with real-time data
              _buildWeightHistoryCard(context),
              
              const SizedBox(height: 16),
              
              // Analytics Cards - Now 4 cards in one row on wide screens, 2 on mobile
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                children: [
                  _buildAnalyticsCard(
                    'Avg. Weight',
                    '${(data.weightHistory.isEmpty ? 0 : data.weightHistory.reduce((a, b) => a + b) / data.weightHistory.length).toStringAsFixed(1)} tons',
                    Icons.scale,
                    Colors.purple,
                    '+${(data.currentWeight - (data.weightHistory.isNotEmpty ? data.weightHistory.first : data.currentWeight)).toStringAsFixed(1)} from start',
                    data.connectionStatus == ConnectionStatus.disconnected,
                  ),
                  _buildAnalyticsCard(
                    'Alerts',
                    data.hasAlert ? "1" : "0",
                    Icons.warning_amber,
                    Colors.orange,
                    data.hasAlert ? '1 active' : 'No active alerts',
                    data.connectionStatus == ConnectionStatus.disconnected,
                  ),
                  _buildAnalyticsCard(
                    'Efficiency',
                    data.connectionStatus == ConnectionStatus.disconnected
                      ? '0%'
                      : '${((data.currentWeight / data.maxWeightLimit) * 100).toStringAsFixed(0)}%',
                    Icons.speed,
                    Colors.green,
                    'Load efficiency',
                    data.connectionStatus == ConnectionStatus.disconnected,
                  ),
                  _buildAnalyticsCard(
                    'Distance',
                    '1,245 km',
                    Icons.route,
                    Colors.blue,
                    'This month',
                    data.connectionStatus == ConnectionStatus.disconnected,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWeightHistoryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.show_chart,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Weight History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                icon: Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
                label: Text(
                  'Last 24 hours',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                ),
                onPressed: () {
                  // Show time range selector
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: data.isLoadingHistory
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue.shade700,
                    ),
                  )
                : data.connectionStatus == ConnectionStatus.disconnected
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sensors_off,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'IoT device is offline',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Weight history data unavailable',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 10,
                          verticalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                String text = '';
                                switch (value.toInt()) {
                                  case 0:
                                    text = '6h ago';
                                    break;
                                  case 1:
                                    text = '5h ago';
                                    break;
                                  case 2:
                                    text = '4h ago';
                                    break;
                                  case 3:
                                    text = '3h ago';
                                    break;
                                  case 4:
                                    text = '2h ago';
                                    break;
                                  case 5:
                                    text = '1h ago';
                                    break;
                                }
                                
                                return Text(
                                  text,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 10,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                );
                              },
                              reservedSize: 36,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        minX: 0,
                        maxX: 5,
                        minY: 0,
                        maxY: 60,
                        lineBarsData: [
                          LineChartBarData(
                            spots: data.weightData,
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade700,
                              ],
                            ),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: Colors.blue.shade700,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade200.withOpacity(0.3),
                                  Colors.blue.shade700.withOpacity(0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          // Add threshold lines
                          LineChartBarData(
                            spots: [
                              FlSpot(0, data.maxWeightLimit),
                              FlSpot(5, data.maxWeightLimit),
                            ],
                            isCurved: false,
                            color: Colors.red.shade300,
                            barWidth: 1.5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            dashArray: [5, 5],
                          ),
                          LineChartBarData(
                            spots: [
                              FlSpot(0, data.minWeightLimit),
                              FlSpot(5, data.minWeightLimit),
                            ],
                            isCurved: false,
                            color: Colors.amber.shade300,
                            barWidth: 1.5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            dashArray: [5, 5],
                          ),
                        ],
                      ),
                    ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.blue.shade500,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Weight',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 10,
                height: 2.5,
                decoration: BoxDecoration(
                  color: Colors.red.shade300,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Max',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 10,
                height: 2.5,
                decoration: BoxDecoration(
                  color: Colors.amber.shade300,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Min',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    MaterialColor color,
    String subtitle,
    bool isOffline,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isOffline ? Colors.grey.shade500 : color.shade700,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: isOffline ? Colors.grey.shade500 : color.shade700,
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOffline ? Colors.grey.shade100 : color.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isOffline ? 'Unavailable' : subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isOffline ? Colors.grey.shade500 : color.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
