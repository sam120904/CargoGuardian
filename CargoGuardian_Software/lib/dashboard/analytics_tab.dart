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
              
              // Weight Trend Chart
              Container(
                height: 300,
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
                          Icons.trending_up,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Weight Trend Analysis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const Spacer(),
                        if (data.isLoadingHistory)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue.shade700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: data.connectionStatus == ConnectionStatus.disconnected
                        ? _buildOfflineChart()
                        : data.isLoadingHistory
                          ? _buildLoadingChart()
                          : _buildWeightChart(),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Statistics Cards
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenSize.width < 600 ? 2 : 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                children: [
                  _buildStatCard(
                    'Average Weight',
                    data.connectionStatus == ConnectionStatus.disconnected 
                      ? '0.0 tons' 
                      : '${_calculateAverage().toStringAsFixed(1)} tons',
                    Icons.analytics,
                    Colors.blue,
                    data.connectionStatus == ConnectionStatus.disconnected,
                  ),
                  _buildStatCard(
                    'Peak Weight',
                    data.connectionStatus == ConnectionStatus.disconnected 
                      ? '0.0 tons' 
                      : '${_calculatePeak().toStringAsFixed(1)} tons',
                    Icons.trending_up,
                    Colors.green,
                    data.connectionStatus == ConnectionStatus.disconnected,
                  ),
                  _buildStatCard(
                    'Min Weight',
                    data.connectionStatus == ConnectionStatus.disconnected 
                      ? '0.0 tons' 
                      : '${_calculateMin().toStringAsFixed(1)} tons',
                    Icons.trending_down,
                    Colors.orange,
                    data.connectionStatus == ConnectionStatus.disconnected,
                  ),
                  _buildStatCard(
                    'Variance',
                    data.connectionStatus == ConnectionStatus.disconnected 
                      ? '0.0%' 
                      : '${_calculateVariance().toStringAsFixed(1)}%',
                    Icons.show_chart,
                    Colors.purple,
                    data.connectionStatus == ConnectionStatus.disconnected,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Performance Metrics
              Container(
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
                          Icons.assessment,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Performance Metrics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            'Load Efficiency',
                            data.connectionStatus == ConnectionStatus.disconnected 
                              ? '0%' 
                              : '${_calculateLoadEfficiency().toStringAsFixed(1)}%',
                            data.connectionStatus == ConnectionStatus.disconnected 
                              ? Colors.grey 
                              : _calculateLoadEfficiency() > 80 
                                ? Colors.green 
                                : _calculateLoadEfficiency() > 60 
                                  ? Colors.orange 
                                  : Colors.red,
                            data.connectionStatus == ConnectionStatus.disconnected,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricItem(
                            'Weight Stability',
                            data.connectionStatus == ConnectionStatus.disconnected 
                              ? 'N/A' 
                              : _calculateStability(),
                            data.connectionStatus == ConnectionStatus.disconnected 
                              ? Colors.grey 
                              : _calculateVariance() < 5 
                                ? Colors.green 
                                : _calculateVariance() < 15 
                                  ? Colors.orange 
                                  : Colors.red,
                            data.connectionStatus == ConnectionStatus.disconnected,
                          ),
                        ),
                        Expanded(
                          child: _buildMetricItem(
                            'Compliance',
                            data.connectionStatus == ConnectionStatus.disconnected 
                              ? 'N/A' 
                              : data.isOverweight || data.isUnderweight 
                                ? 'Non-Compliant' 
                                : 'Compliant',
                            data.connectionStatus == ConnectionStatus.disconnected 
                              ? Colors.grey 
                              : data.isOverweight || data.isUnderweight 
                                ? Colors.red 
                                : Colors.green,
                            data.connectionStatus == ConnectionStatus.disconnected,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOfflineChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sensors_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'IoT device is offline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Weight data unavailable',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading weight data...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeightChart() {
    if (data.weightData.isEmpty) {
      return Center(
        child: Text(
          'No weight data available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 10,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                );
                return Text('${value.toInt()}', style: style);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                );
                return Text('${value.toInt()}', style: style);
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: 80,
        lineBarsData: [
          LineChartBarData(
            spots: data.weightData,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade600,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue.shade700,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade100.withOpacity(0.3),
                  Colors.blue.shade50.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Add limit lines
          LineChartBarData(
            spots: [
              FlSpot(0, data.maxWeightLimit),
              FlSpot(5, data.maxWeightLimit),
            ],
            isCurved: false,
            color: Colors.red.shade400,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
          LineChartBarData(
            spots: [
              FlSpot(0, data.minWeightLimit),
              FlSpot(5, data.minWeightLimit),
            ],
            isCurved: false,
            color: Colors.orange.shade400,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, MaterialColor color, bool isOffline) {
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isOffline ? Colors.grey.shade500 : color.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricItem(String title, String value, MaterialColor color, bool isOffline) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isOffline ? Colors.grey.shade100 : color.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isOffline ? Colors.grey.shade300 : color.shade200,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isOffline ? Colors.grey.shade500 : color.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
  
  double _calculateAverage() {
    if (data.weightHistory.isEmpty) return 0.0;
    final sum = data.weightHistory.reduce((a, b) => a + b);
    return sum / data.weightHistory.length;
  }
  
  double _calculatePeak() {
    if (data.weightHistory.isEmpty) return 0.0;
    return data.weightHistory.reduce((a, b) => a > b ? a : b);
  }
  
  double _calculateMin() {
    if (data.weightHistory.isEmpty) return 0.0;
    return data.weightHistory.reduce((a, b) => a < b ? a : b);
  }
  
  double _calculateVariance() {
    if (data.weightHistory.isEmpty) return 0.0;
    final average = _calculateAverage();
    final variance = data.weightHistory
        .map((weight) => (weight - average) * (weight - average))
        .reduce((a, b) => a + b) / data.weightHistory.length;
    return (variance / average) * 100; // Return as percentage
  }
  
  double _calculateLoadEfficiency() {
    if (data.currentWeight == 0) return 0.0;
    final optimalWeight = (data.minWeightLimit + data.maxWeightLimit) / 2;
    final efficiency = (data.currentWeight / optimalWeight) * 100;
    return efficiency.clamp(0.0, 100.0);
  }
  
  String _calculateStability() {
    final variance = _calculateVariance();
    if (variance < 5) return 'Stable';
    if (variance < 15) return 'Moderate';
    return 'Unstable';
  }
}
