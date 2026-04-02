import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/graph_service.dart';

/// Interactive network topology visualization.
/// Shows stations as nodes and routes as edges.
/// Color-coded by load/congestion/risk.
class NetworkView extends StatefulWidget {
  const NetworkView({super.key});

  @override
  State<NetworkView> createState() => _NetworkViewState();
}

class _NetworkViewState extends State<NetworkView>
    with SingleTickerProviderStateMixin {
  final GraphService _graphService = GraphService();

  List<dynamic> _stations = [];
  List<dynamic> _connections = [];
  bool _isLoading = true;
  String? _selectedStation;
  Map<String, dynamic>? _selectedStationData;

  late AnimationController _animController;
  late Animation<double> _animation;

  // Map viewport
  Offset _offset = Offset.zero;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _graphService.getAllStations(),
        _graphService.getRouteConnections(),
      ]);

      if (mounted) {
        setState(() {
          _stations = results[0];
          _connections = results[1];
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Building network topology...',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade800),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.share, color: Colors.cyan.shade400, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Network Topology',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // Legend
              _buildLegendDot(Colors.greenAccent, 'Low Risk'),
              const SizedBox(width: 8),
              _buildLegendDot(Colors.amber, 'Medium'),
              const SizedBox(width: 8),
              _buildLegendDot(Colors.redAccent, 'High Risk'),
            ],
          ),
        ),

        // Network canvas
        Expanded(
          child: GestureDetector(
            onScaleStart: (details) {},
            onScaleUpdate: (details) {
              setState(() {
                _scale = (_scale * details.scale).clamp(0.5, 3.0);
                _offset += details.focalPointDelta;
              });
            },
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return ClipRect(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _NetworkPainter(
                      stations: _stations,
                      connections: _connections,
                      progress: _animation.value,
                      selectedStation: _selectedStation,
                      offset: _offset,
                      scale: _scale,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Selected station details
        if (_selectedStationData != null) _buildStationDetail(),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildStationDetail() {
    final data = _selectedStationData!;
    final loadRatio = (data['current_load'] ?? 0) / (data['capacity'] ?? 1);
    final color = loadRatio > 0.8 ? Colors.red : loadRatio > 0.6 ? Colors.amber : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_city, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${data['city']}, ${data['state']} • ${data['station_type']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(loadRatio * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                '${data['current_load']}/${data['capacity']}t',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the network graph visualization.
class _NetworkPainter extends CustomPainter {
  final List<dynamic> stations;
  final List<dynamic> connections;
  final double progress;
  final String? selectedStation;
  final Offset offset;
  final double scale;

  _NetworkPainter({
    required this.stations,
    required this.connections,
    required this.progress,
    this.selectedStation,
    required this.offset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stations.isEmpty) return;

    // Calculate normalized positions from lat/lng
    double minLat = double.infinity, maxLat = -double.infinity;
    double minLng = double.infinity, maxLng = -double.infinity;

    for (final s in stations) {
      final lat = (s['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (s['longitude'] as num?)?.toDouble() ?? 0;
      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLng = math.min(minLng, lng);
      maxLng = math.max(maxLng, lng);
    }

    final padding = 60.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    Offset getPos(dynamic station) {
      final lat = (station['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (station['longitude'] as num?)?.toDouble() ?? 0;
      // Map lat/lng to canvas coordinates
      // Latitude inverted because canvas Y increases downward
      final x = padding + ((lng - minLng) / (maxLng - minLng + 0.001)) * drawWidth;
      final y = padding + ((maxLat - lat) / (maxLat - minLat + 0.001)) * drawHeight;
      return Offset(x * scale + offset.dx, y * scale + offset.dy);
    }

    // Build station position map
    final Map<String, Offset> positions = {};
    for (final s in stations) {
      final id = s['station_id'] ?? '';
      positions[id] = getPos(s);
    }

    // Draw edges first
    for (int i = 0; i < connections.length; i++) {
      final conn = connections[i];
      final fromId = conn['from'] ?? '';
      final toId = conn['to'] ?? '';
      final fromPos = positions[fromId];
      final toPos = positions[toId];

      if (fromPos == null || toPos == null) continue;

      final congestion = (conn['congestion_level'] as num?)?.toDouble() ?? 0;
      final edgeColor = congestion > 0.6
          ? Colors.red.withOpacity(progress * 0.6)
          : congestion > 0.3
              ? Colors.amber.withOpacity(progress * 0.6)
              : Colors.cyan.withOpacity(progress * 0.4);

      final paint = Paint()
        ..color = edgeColor
        ..strokeWidth = 1.5 * scale
        ..style = PaintingStyle.stroke;

      // Animated edge drawing
      final animatedEnd = Offset.lerp(fromPos, toPos, progress)!;
      canvas.drawLine(fromPos, animatedEnd, paint);
    }

    // Draw nodes
    for (final s in stations) {
      final id = s['station_id'] ?? '';
      final pos = positions[id];
      if (pos == null) continue;

      final loadRatio = (s['current_load'] ?? 0) / (s['capacity'] ?? 1);
      final riskScore = (s['risk_score'] as num?)?.toDouble() ?? 0;

      final nodeColor = riskScore > 0.25
          ? Colors.redAccent
          : loadRatio > 0.7
              ? Colors.amber
              : Colors.greenAccent;

      // Outer glow
      final glowPaint = Paint()
        ..color = nodeColor.withOpacity(progress * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(pos, 16 * scale * progress, glowPaint);

      // Node circle
      final nodePaint = Paint()
        ..color = nodeColor.withOpacity(progress * 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 8 * scale * progress, nodePaint);

      // Border
      final borderPaint = Paint()
        ..color = nodeColor.withOpacity(progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(pos, 8 * scale * progress, borderPaint);

      // Label
      if (progress > 0.5) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: s['name'] ?? id,
            style: TextStyle(
              color: Colors.white.withOpacity((progress - 0.5) * 2),
              fontSize: 10 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(pos.dx - textPainter.width / 2, pos.dy + 12 * scale),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.offset != offset ||
        oldDelegate.scale != scale ||
        oldDelegate.selectedStation != selectedStation;
  }
}
