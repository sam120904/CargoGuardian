import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/graph_service.dart';

/// Route Optimizer Tab — Find fastest paths between stations.
/// Efficiency side of Duality with animated path visualization.
class RouteOptimizerTab extends StatefulWidget {
  const RouteOptimizerTab({super.key});

  @override
  State<RouteOptimizerTab> createState() => _RouteOptimizerTabState();
}

class _RouteOptimizerTabState extends State<RouteOptimizerTab>
    with SingleTickerProviderStateMixin {
  final GraphService _graphService = GraphService();

  List<dynamic> _stations = [];
  String? _fromStation;
  String? _toStation;
  Map<String, dynamic>? _routeResult;
  bool _isLoading = false;
  bool _isLoadingStations = true;
  String? _error;

  late AnimationController _pathAnimController;
  late Animation<double> _pathAnimation;

  @override
  void initState() {
    super.initState();
    _pathAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pathAnimController, curve: Curves.easeInOut),
    );
    _loadStations();
  }

  @override
  void dispose() {
    _pathAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadStations() async {
    try {
      final stations = await _graphService.getAllStations();
      if (mounted) {
        setState(() {
          _stations = stations;
          _isLoadingStations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStations = false;
          _error = 'Could not load stations. Is the middleware running?';
        });
      }
    }
  }

  Future<void> _findRoute() async {
    if (_fromStation == null || _toStation == null) return;
    if (_fromStation == _toStation) {
      setState(() => _error = 'Origin and destination must be different');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _routeResult = null;
    });

    try {
      final result = await _graphService.getShortestRoute(_fromStation!, _toStation!);
      if (mounted) {
        setState(() {
          _routeResult = result;
          _isLoading = false;
        });
        _pathAnimController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error finding route: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStations) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan.shade400),
            ),
            SizedBox(height: 16),
            Text(
              'Loading station network...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          SizedBox(height: 20),

          // Station Selection
          _buildStationSelector(),
          SizedBox(height: 16),

          // Find Route Button
          _buildFindButton(),
          SizedBox(height: 20),

          // Error
          if (_error != null) _buildError(),

          // Result
          if (_routeResult != null) ...[
            _buildRouteResult(),
            SizedBox(height: 20),
            _buildRouteVisualization(),
            SizedBox(height: 20),
            _buildSegmentDetails(),
          ],

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.cyan.shade600, Colors.teal.shade600],
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
          child: Icon(Icons.route, color: Colors.white, size: 24),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route Optimizer',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                'Graph-powered shortest path analysis',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStationSelector() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // From Station
          _buildDropdown(
            label: 'Origin Station',
            icon: Icons.trip_origin,
            color: Colors.greenAccent,
            value: _fromStation,
            onChanged: (v) => setState(() => _fromStation = v),
          ),
          SizedBox(height: 16),

          // Swap button
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  final temp = _fromStation;
                  _fromStation = _toStation;
                  _toStation = temp;
                });
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.swap_vert, color: Colors.cyan.shade700, size: 20),
              ),
            ),
          ),
          SizedBox(height: 16),

          // To Station
          _buildDropdown(
            label: 'Destination Station',
            icon: Icons.location_on,
            color: Colors.redAccent,
            value: _toStation,
            onChanged: (v) => setState(() => _toStation = v),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required Color color,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            dropdownColor: Colors.white,
            style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
            hint: Text(
              'Select station',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            items: _stations.map<DropdownMenuItem<String>>((station) {
              return DropdownMenuItem<String>(
                value: station['station_id'],
                child: Text(
                  '${station['name']} (${station['station_id']})',
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildFindButton() {
    final canFind = _fromStation != null && _toStation != null && !_isLoading;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canFind ? _findRoute : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan.shade700,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade800,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canFind ? 4 : 0,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Running Dijkstra\'s Algorithm...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt),
                  SizedBox(width: 8),
                  Text(
                    'Find Fastest Route',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade700.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteResult() {
    final data = _routeResult?['data'] as Map<String, dynamic>? ?? {};
    final totalHours = (data['total_hours'] as num?)?.toDouble() ?? 0;
    final totalKm = (data['total_km'] as num?)?.toDouble() ?? 0;
    final stops = (data['stops'] as num?)?.toInt() ?? 0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'OPTIMAL ROUTE FOUND',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 3,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildRouteStat(Icons.timer, '${totalHours.toStringAsFixed(1)}h', 'Travel Time'),
              Container(width: 1, height: 40, color: Colors.grey.shade700),
              _buildRouteStat(Icons.straighten, '${totalKm.toStringAsFixed(0)} km', 'Distance'),
              Container(width: 1, height: 40, color: Colors.grey.shade700),
              _buildRouteStat(Icons.location_city, '$stops', 'Stops'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.cyan.shade700, size: 22),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteVisualization() {
    final data = _routeResult?['data'] as Map<String, dynamic>? ?? {};
    final path = data['path'] as List? ?? [];

    if (path.isEmpty) return SizedBox();

    return AnimatedBuilder(
      animation: _pathAnimation,
      builder: (context, child) {
        final visibleCount = (_pathAnimation.value * path.length).ceil().clamp(0, path.length);

        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ROUTE VISUALIZATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 16),
              ...List.generate(path.length, (i) {
                final isVisible = i < visibleCount;
                final isFirst = i == 0;
                final isLast = i == path.length - 1;
                final station = path[i];

                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isVisible ? 1.0 : 0.2,
                  child: Row(
                    children: [
                      // Timeline indicator
                      SizedBox(
                        width: 40,
                        child: Column(
                          children: [
                            if (!isFirst)
                              Container(
                                width: 2,
                                height: 16,
                                color: isVisible ? Colors.cyan.shade400 : Colors.grey.shade700,
                              ),
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: isFirst
                                    ? Colors.greenAccent
                                    : isLast
                                        ? Colors.redAccent
                                        : (isVisible ? Colors.cyan : Colors.grey.shade700),
                                shape: BoxShape.circle,
                                boxShadow: isVisible
                                    ? [
                                        BoxShadow(
                                          color: (isFirst ? Colors.greenAccent : isLast ? Colors.redAccent : Colors.cyan).withOpacity(0.4),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : [],
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 16,
                                color: (isVisible && i + 1 < visibleCount)
                                    ? Colors.cyan.shade400
                                    : Colors.grey.shade700,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isVisible
                                ? (isFirst
                                    ? Colors.greenAccent.withOpacity(0.08)
                                    : isLast
                                        ? Colors.redAccent.withOpacity(0.08)
                                        : Colors.cyan.withOpacity(0.05))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                station['name'] ?? station['station_id'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isFirst || isLast ? FontWeight.bold : FontWeight.normal,
                                  color: isVisible ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                              if (station['city'] != null && station['city'] != '') ...[
                                SizedBox(width: 8),
                                Text(
                                  station['city'],
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegmentDetails() {
    final data = _routeResult?['data'] as Map<String, dynamic>? ?? {};
    final segments = data['segments'] as List? ?? [];

    if (segments.isEmpty) return SizedBox();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            'SEGMENT DETAILS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 12),
          ...segments.map<Widget>((seg) {
            final congestion = (seg['congestion'] as num?)?.toDouble() ?? 0;
            final congestionColor = congestion > 0.6
                ? Colors.red
                : congestion > 0.3
                    ? Colors.amber
                    : Colors.greenAccent;
            final condition = seg['condition'] ?? 'unknown';
            final conditionColor = condition == 'good'
                ? Colors.greenAccent
                : condition == 'fair'
                    ? Colors.amber
                    : Colors.red;

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${seg['from']} → ${seg['to']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSegmentChip(Icons.straighten, '${seg['distance_km']} km', Colors.cyan),
                      SizedBox(width: 8),
                      _buildSegmentChip(Icons.timer, '${seg['travel_hours']}h', Colors.teal),
                      SizedBox(width: 8),
                      _buildSegmentChip(Icons.traffic, '${(congestion * 100).toStringAsFixed(0)}%', congestionColor),
                      SizedBox(width: 8),
                      _buildSegmentChip(Icons.construction, condition, conditionColor),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSegmentChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
