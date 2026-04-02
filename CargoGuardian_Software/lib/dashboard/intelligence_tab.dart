import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/graph_service.dart';

/// Intelligence Tab — The Duality Dashboard
/// Left side: Efficiency metrics (cyan/blue)
/// Right side: Security metrics (red/amber)
/// Center: Network Health (Duality Score)
class IntelligenceTab extends StatefulWidget {
  const IntelligenceTab({super.key});

  @override
  State<IntelligenceTab> createState() => _IntelligenceTabState();
}

class _IntelligenceTabState extends State<IntelligenceTab>
    with TickerProviderStateMixin {
  final GraphService _graphService = GraphService();

  // Data
  Map<String, dynamic>? _networkHealth;
  List<dynamic> _bottlenecks = [];
  List<dynamic> _suspiciousRoutes = [];
  List<dynamic> _overloadRisks = [];
  List<dynamic> _stations = [];
  List<dynamic> _trains = [];

  bool _isLoading = true;
  bool _middlewareOnline = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _scoreController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic),
    );

    _loadData();

    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scoreController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final online = await _graphService.isMiddlewareOnline();
      if (!online) {
        if (mounted) {
          setState(() {
            _middlewareOnline = false;
            _isLoading = false;
            _errorMessage = 'Middleware server is offline. Start it with: uvicorn main:app --reload';
          });
        }
        return;
      }

      setState(() => _middlewareOnline = true);

      final results = await Future.wait([
        _graphService.getNetworkHealth(),
        _graphService.getBottlenecks(),
        _graphService.getSuspiciousRerouting(),
        _graphService.getOverloadRisks(),
        _graphService.getAllStations(),
        _graphService.getAllTrains(),
      ]);

      if (mounted) {
        setState(() {
          _networkHealth = results[0] as Map<String, dynamic>;
          _bottlenecks = results[1] as List;
          _suspiciousRoutes = results[2] as List;
          _overloadRisks = results[3] as List;
          _stations = results[4] as List;
          _trains = results[5] as List;
          _isLoading = false;
          _errorMessage = null;
        });
        _scoreController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading graph data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingView();
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    final healthData = _networkHealth?['data'] as Map<String, dynamic>?;
    if (healthData == null) {
      return _buildErrorView();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.cyan,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),

            // Duality Score Card
            _buildDualityScoreCard(healthData),
            const SizedBox(height: 20),

            // Split Panels: Efficiency vs Security
            _buildDualityPanels(healthData),
            const SizedBox(height: 20),

            // Network Overview
            _buildNetworkOverview(healthData),
            const SizedBox(height: 20),

            // Bottleneck Alerts
            if (_bottlenecks.isNotEmpty) ...[
              _buildSectionTitle('🚨 Bottleneck Stations', Colors.red.shade400),
              const SizedBox(height: 8),
              ..._bottlenecks.map((b) => _buildBottleneckCard(b)),
              const SizedBox(height: 20),
            ],

            // Suspicious Rerouting
            if (_suspiciousRoutes.isNotEmpty) ...[
              _buildSectionTitle('⚠️ Suspicious Rerouting', Colors.orange.shade400),
              const SizedBox(height: 8),
              ..._suspiciousRoutes.map((s) => _buildSuspiciousCard(s)),
              const SizedBox(height: 20),
            ],

            // Overload Risks
            if (_overloadRisks.isNotEmpty) ...[
              _buildSectionTitle('🔴 Overload Risks', Colors.deepOrange.shade400),
              const SizedBox(height: 8),
              ..._overloadRisks.map((r) => _buildOverloadCard(r)),
              const SizedBox(height: 20),
            ],

            // Active Trains
            _buildSectionTitle('🚆 Active Trains', Colors.blue.shade400),
            const SizedBox(height: 8),
            ..._trains.map((t) => _buildTrainCard(t)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan.shade400),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Graph Intelligence...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing network topology',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _middlewareOnline ? Icons.warning_amber : Icons.cloud_off,
              size: 64,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              _middlewareOnline ? 'Graph Data Error' : 'Middleware Offline',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Column(
                children: [
                  Text(
                    _errorMessage ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Run the middleware server:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.cyan.shade300,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SelectableText(
                      'cd middleware\npip install -r requirements.txt\nuvicorn main:app --reload',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.cyan.shade600, Colors.deepPurple.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.hub, color: Colors.white, size: 24),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Graph Intelligence',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _middlewareOnline ? Colors.greenAccent : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _middlewareOnline ? 'TigerGraph Connected' : 'Middleware Offline',
                    style: TextStyle(
                      fontSize: 13,
                      color: _middlewareOnline ? Colors.greenAccent.shade200 : Colors.red.shade300,
                    ),
                  ),
                  if (_networkHealth?['demo_mode'] == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade700.withOpacity(0.5)),
                      ),
                      child: Text(
                        'DEMO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade300,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() => _isLoading = true);
            _loadData();
          },
          icon: Icon(Icons.refresh, color: Colors.grey.shade400),
          tooltip: 'Refresh data',
        ),
      ],
    );
  }

  Widget _buildDualityScoreCard(Map<String, dynamic> health) {
    final dualityScore = (health['duality_score'] as num?)?.toDouble() ?? 0.0;
    final efficiencyScore = (health['efficiency']?['score'] as num?)?.toDouble() ?? 0.0;
    final securityScore = (health['security']?['score'] as num?)?.toDouble() ?? 0.0;

    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.cyan.shade900.withOpacity(0.4),
                Colors.deepPurple.shade900.withOpacity(0.3),
                Colors.red.shade900.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.cyan.shade700.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(-5, 0),
              ),
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(5, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'DUALITY SCORE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white54,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _scoreAnimation.value * (dualityScore / 100),
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        dualityScore > 70
                            ? Colors.greenAccent
                            : dualityScore > 40
                                ? Colors.amber
                                : Colors.redAccent,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${(dualityScore * _scoreAnimation.value).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'of 100',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniScore(
                      '⚡ Efficiency',
                      efficiencyScore,
                      Colors.cyan,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade700,
                  ),
                  Expanded(
                    child: _buildMiniScore(
                      '🛡️ Security',
                      securityScore,
                      Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniScore(String label, double score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${score.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDualityPanels(Map<String, dynamic> health) {
    final efficiency = health['efficiency'] as Map<String, dynamic>? ?? {};
    final security = health['security'] as Map<String, dynamic>? ?? {};

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Efficiency Panel
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.cyan.shade900.withOpacity(0.3),
                  Colors.blue.shade900.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyan.shade800.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.cyan.shade300, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'EFFICIENCY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.cyan.shade300,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMetric('Congestion', '${((efficiency['avg_congestion'] ?? 0) * 100).toStringAsFixed(0)}%', Colors.cyan),
                _buildMetric('Active Trains', '${efficiency['active_trains'] ?? 0}', Colors.cyan),
                _buildMetric('Delayed', '${efficiency['delayed_trains'] ?? 0}', Colors.amber),
                _buildMetric('On-Time Rate', '${efficiency['on_time_rate'] ?? 0}%', Colors.greenAccent),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Security Panel
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.shade900.withOpacity(0.3),
                  Colors.orange.shade900.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade800.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, color: Colors.red.shade300, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'SECURITY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade300,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMetric('Flagged Cargo', '${security['flagged_cargo'] ?? 0}', Colors.red),
                _buildMetric('Overloaded', '${security['overloaded_trains'] ?? 0}', Colors.orange),
                _buildMetric('Bottlenecks', '${security['bottleneck_stations'] ?? 0}', Colors.amber),
                _buildMetric('Incidents', '${security['risk_incidents'] ?? 0}', Colors.redAccent),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkOverview(Map<String, dynamic> health) {
    final network = health['network'] as Map<String, dynamic>? ?? {};
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NETWORK OVERVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildNetworkStat(Icons.location_city, '${network['total_stations'] ?? 0}', 'Stations', Colors.blue),
              _buildNetworkStat(Icons.train, '${network['total_trains'] ?? 0}', 'Trains', Colors.green),
              _buildNetworkStat(Icons.inventory_2, '${network['total_cargo'] ?? 0}', 'Cargo', Colors.purple),
              _buildNetworkStat(Icons.route, '${network['total_routes'] ?? 0}', 'Routes', Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color.withOpacity(0.8), size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }

  Widget _buildBottleneckCard(dynamic bottleneck) {
    final loadRatio = (bottleneck['load_ratio'] as num?)?.toDouble() ?? 0.0;
    final riskLevel = bottleneck['risk_level'] ?? 'MEDIUM';
    final riskColor = riskLevel == 'CRITICAL' ? Colors.red : riskLevel == 'HIGH' ? Colors.orange : Colors.amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning, color: riskColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bottleneck['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${bottleneck['city']} • ${bottleneck['connections'] ?? 0} connections',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  riskLevel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(loadRatio * 100).toStringAsFixed(0)}% loaded',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuspiciousCard(dynamic suspicious) {
    final riskLevel = suspicious['risk_level'] ?? 'MEDIUM';
    final riskColor = riskLevel == 'CRITICAL' ? Colors.red : Colors.orange;
    final deviations = suspicious['unplanned_stops'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gps_not_fixed, color: riskColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  suspicious['description'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  riskLevel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: riskColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${suspicious['origin_station']} → ${suspicious['destination_station']}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
          if (deviations.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: deviations.map<Widget>((stop) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '⚠ $stop',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade300),
                  ),
                );
              }).toList(),
            ),
          ],
          if (suspicious['reason'] != null) ...[
            const SizedBox(height: 6),
            Text(
              suspicious['reason'],
              style: TextStyle(fontSize: 12, color: Colors.orange.shade300, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverloadCard(dynamic risk) {
    final loadPct = (risk['load_percentage'] as num?)?.toDouble() ?? 0.0;
    final color = loadPct > 95 ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.train, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  risk['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                Text(
                  '${risk['current_weight']}t / ${risk['max_capacity']}t',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${loadPct.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                risk['risk_level'] ?? '',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrainCard(dynamic train) {
    final status = train['status'] ?? 'idle';
    final statusColor = status == 'en_route'
        ? Colors.greenAccent
        : status == 'loading'
            ? Colors.blue
            : status == 'delayed'
                ? Colors.red
                : Colors.grey;
    final loadPct = (train['max_capacity'] != null && train['max_capacity'] > 0)
        ? (train['current_weight'] ?? 0) / train['max_capacity']
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Icon(Icons.train, color: statusColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  train['name'] ?? train['train_id'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.toString().toUpperCase(),
                      style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                    if (train['speed'] != null && (train['speed'] as num) > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${train['speed']} km/h',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(loadPct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: loadPct > 0.9 ? Colors.red : loadPct > 0.7 ? Colors.amber : Colors.greenAccent,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: loadPct.clamp(0.0, 1.0).toDouble(),
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    loadPct > 0.9 ? Colors.red : loadPct > 0.7 ? Colors.amber : Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
