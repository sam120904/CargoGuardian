import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/auth_service.dart';
import '../services/blynk_service.dart';
import '../config/config.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

// Conditionally import dart:html only for web
import '../platform/platform_imports.dart';
import 'connection_indicator.dart';
import 'overview_tab.dart';
import 'analytics_tab.dart';
import 'location_tab.dart';

// Data class to pass to tab components
class DashboardData {
  final String selectedTrain;
  final List<String> trainOptions;
  final double currentWeight;
  final double minWeightLimit;
  final double maxWeightLimit;
  final bool isOverweight;
  final bool isUnderweight;
  final bool isClearanceGiven;
  final bool sendAlertEnabled;
  final bool isLoadingWeight;
  final bool isLoadingHistory;
  final bool hasLocationPermission;
  final bool isRequestingPermission;
  final String? webMapElementId;
  final List<FlSpot> weightData;
  final List<double> weightHistory;
  final bool hasAlert;
  final String alertMessage;
  final ConnectionStatus connectionStatus;
  final bool isBlinking;
  final String errorMessage;

  DashboardData({
    required this.selectedTrain,
    required this.trainOptions,
    required this.currentWeight,
    required this.minWeightLimit,
    required this.maxWeightLimit,
    required this.isOverweight,
    required this.isUnderweight,
    required this.isClearanceGiven,
    required this.sendAlertEnabled,
    required this.isLoadingWeight,
    required this.isLoadingHistory,
    required this.hasLocationPermission,
    required this.isRequestingPermission,
    this.webMapElementId,
    required this.weightData,
    required this.weightHistory,
    required this.hasAlert,
    required this.alertMessage,
    required this.connectionStatus,
    required this.isBlinking,
    required this.errorMessage,
  });
}

// Callbacks class to pass to tab components
class DashboardCallbacks {
  final VoidCallback toggleClearance;
  final VoidCallback toggleSendAlert;
  final VoidCallback dismissAlert;
  final VoidCallback requestLocationPermission;
  final VoidCallback fetchInitialData;
  final Function(String) openUrl;
  final Function(double) updateMinWeightLimit;
  final Function(double) updateMaxWeightLimit;

  DashboardCallbacks({
    required this.toggleClearance,
    required this.toggleSendAlert,
    required this.dismissAlert,
    required this.requestLocationPermission,
    required this.fetchInitialData,
    required this.openUrl,
    required this.updateMinWeightLimit,
    required this.updateMaxWeightLimit,
  });
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _blynkService = BlynkService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoggingOut = false;
  
  // Selected train data
  String _selectedTrain = 'Train A-123';
  final List<String> _trainOptions = ['Train A-123', 'Train B-456', 'Train C-789', 'Train D-012'];
  
  // Weight data - FIXED: Initialize with null/checking state
  double _currentWeight = 0.0;
  double _minWeightLimit = 20.0;
  double _maxWeightLimit = 50.0;
  bool _isOverweight = false;
  bool _isUnderweight = false;
  bool _isClearanceGiven = false;
  bool _sendAlertEnabled = false;
  
  // Data loading states - FIXED: Start with checking state
  bool _isLoadingWeight = false; // Changed from true to false
  bool _isLoadingHistory = false; // Changed from true to false
  
  // Timer for periodic updates
  Timer? _updateTimer;
  Timer? _connectionBlinkTimer;
  
  // Map controller
  GoogleMapController? _mapController;
  
  // Location permission state
  bool _hasLocationPermission = false;
  bool _isRequestingPermission = false;
  
  // Web map element ID
  String? _webMapElementId;
  
  // Weight history data for graph
  List<FlSpot> _weightData = [];
  List<double> _weightHistory = [];
  
  // Alert data
  bool _hasAlert = false;
  String _alertMessage = '';
  
  // Tab selection
  int _selectedTabIndex = 0;
  
  // Flag to prevent alert on initial load
  bool _isInitialLoad = true;
  
  // Connection status - FIXED: Start with checking state
  ConnectionStatus _connectionStatus = ConnectionStatus.checking;
  bool _isBlinking = false;
  String _errorMessage = '';
  
  // Refresh connection check in progress
  bool _isRefreshingConnection = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    
    // Generate a unique ID for the web map element
    if (kIsWeb) {
      _webMapElementId = 'google-map-${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Initialize weight data with zeros
    _initializeWeightData();
    
    // Check location permission
    _checkLocationPermission();
    
    // FIXED: Set initial state properly
    setState(() {
      _connectionStatus = ConnectionStatus.checking;
      _currentWeight = 0.0; // Start with zero weight
      _isLoadingWeight = false; // Don't show loading initially
      _isLoadingHistory = false; // Don't show loading initially
    });
    
    // Start connection status blinking
    _startConnectionBlinking();
    
    // FIXED: Check connection status first, then fetch data
    _checkConnectionStatus().then((_) {
      if (_connectionStatus == ConnectionStatus.connected) {
        _fetchInitialData();
      }
    });
  }
  
  void _initializeWeightData() {
    // Initialize weight data with zeros
    _weightData = List.generate(6, (index) => FlSpot(index.toDouble(), 0.0));
    _weightHistory = List.generate(6, (index) => 0.0);
  }
  
  // Check location permission
  Future<void> _checkLocationPermission() async {
    if (kIsWeb) {
      // First check if we already have permission from earlier
      bool hasPermission = AppConfig.hasLocationPermission;
      
      if (!hasPermission) {
        // If not, request permission
        setState(() {
          _isRequestingPermission = true;
        });
        
        hasPermission = await AppConfig.requestLocationPermission();
        
        setState(() {
          _hasLocationPermission = hasPermission;
          _isRequestingPermission = false;
        });
        
        // Show appropriate message
        if (hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Location permission granted'),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Location permission denied. Some features may not work.'),
                backgroundColor: Colors.orange.shade600,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        setState(() {
          _hasLocationPermission = true;
        });
      }
    } else {
      // For Android, we'll request permission when the location tab is selected
      // This is handled by the GoogleMap widget automatically
      setState(() {
        _hasLocationPermission = false; // Will be requested when needed
      });
    }
  }
  
  // FIXED: Fetch initial data from Blynk with proper state management
  Future<void> _fetchInitialData() async {
    if (_isRefreshingConnection) return;
    
    setState(() {
      _isLoadingWeight = true;
      _isLoadingHistory = true;
      _isRefreshingConnection = true;
    });
    
    try {
      // Get current weight
      final weight = await _blynkService.getCurrentWeight();
      if (mounted) {
        setState(() {
          _currentWeight = weight;
          _isLoadingWeight = false;
          _checkWeightStatus();
          _connectionStatus = ConnectionStatus.connected;
          _errorMessage = '';
        });
      }
      
      // Get weight history
      try {
        final history = await _blynkService.getWeightHistory();
        if (history.isNotEmpty && mounted) {
          // Convert history to FlSpot list for the chart
          final spots = <FlSpot>[];
          for (int i = 0; i < history.length && i < 6; i++) {
            spots.add(FlSpot(i.toDouble(), history[i]));
          }
          
          setState(() {
            _weightData = spots;
            _weightHistory = history;
            _isLoadingHistory = false;
            _isInitialLoad = false;
            _isRefreshingConnection = false;
          });
        } else if (mounted) {
          setState(() {
            _isLoadingHistory = false;
            _isInitialLoad = false;
            _isRefreshingConnection = false;
          });
        }
      } catch (historyError) {
        print('Error fetching weight history: $historyError');
        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
            _isInitialLoad = false;
            _isRefreshingConnection = false;
            
            // Check if it's a reports limit error
            if (historyError.toString().contains('Reports limit reached')) {
              _errorMessage = 'Reports limit reached. One device can send only 24 reports per day';
            } else if (historyError.toString().contains('No data')) {
              _errorMessage = 'No weight history data available';
            } else {
              _errorMessage = 'Failed to load weight history';
              _connectionStatus = ConnectionStatus.disconnected;
              _currentWeight = 0.0;
              _checkWeightStatus();
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching initial data: $e');
      if (mounted) {
        setState(() {
          _isLoadingWeight = false;
          _isLoadingHistory = false;
          _isInitialLoad = false;
          _connectionStatus = ConnectionStatus.disconnected;
          _errorMessage = 'Failed to connect to IoT device';
          
          // Reset weight to zero when IoT is offline
          _currentWeight = 0.0;
          _checkWeightStatus();
          _isRefreshingConnection = false;
        });
      }
    }
  }
  
  // Start connection status blinking
  void _startConnectionBlinking() {
    _connectionBlinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          // Only blink if not connected
          if (_connectionStatus != ConnectionStatus.connected) {
            _isBlinking = !_isBlinking;
          } else {
            _isBlinking = false;
          }
        });
      }
    });
  }
  
  // FIXED: Check connection status with proper state management
  Future<void> _checkConnectionStatus() async {
    if (_isRefreshingConnection) return;
    
    setState(() {
      _isRefreshingConnection = true;
      _connectionStatus = ConnectionStatus.checking;
      _updateTimer?.cancel(); // Cancel any ongoing updates
    });
    
    // Perform quick check
    bool isOnline = false;
    try {
      isOnline = await _blynkService.isIoTDeviceOnline();
    } catch (e) {
      print('Error checking connection status: $e');
      isOnline = false;
    }
    
    if (mounted) {
      setState(() {
        if (isOnline) {
          _connectionStatus = ConnectionStatus.connected;
          _errorMessage = '';
          // Start periodic updates if we're connected
          _startPeriodicUpdates();
        } else {
          _connectionStatus = ConnectionStatus.disconnected;
          _errorMessage = 'IoT device is offline';
          _currentWeight = 0.0;
          _checkWeightStatus();
        }
        _isRefreshingConnection = false;
      });
    }
    
    return;
  }
  
  // Start periodic updates
  void _startPeriodicUpdates() {
    // Cancel existing timer if any
    _updateTimer?.cancel();
    
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // Don't update if we're disconnected or refreshing
      if (_connectionStatus == ConnectionStatus.disconnected || _isRefreshingConnection) {
        return;
      }
      
      try {
        // Get current weight
        final weight = await _blynkService.getCurrentWeight();
        if (mounted) {
          setState(() {
            _currentWeight = weight;
            
            // Update weight history by shifting data points
            if (_weightData.isNotEmpty) {
              final newData = <FlSpot>[];
              final newHistory = <double>[];
              
              for (int i = 1; i < _weightData.length; i++) {
                newData.add(FlSpot(i - 1.0, _weightData[i].y));
                newHistory.add(_weightHistory[i]);
              }
              newData.add(FlSpot(_weightData.length - 1.0, weight));
              newHistory.add(weight);
              
              _weightData = newData;
              _weightHistory = newHistory;
            }
            
            _checkWeightStatus();
          });
        }
      } catch (e) {
        print('Error updating weight: $e');
        if (mounted) {
          // If we get an error, check connection status
          _checkConnectionStatus();
        }
      }
    });
  }
  
  void _checkWeightStatus() {
    setState(() {
      bool wasOverweight = _isOverweight;
      bool wasUnderweight = _isUnderweight;
      
      _isOverweight = _currentWeight > _maxWeightLimit;
      _isUnderweight = _currentWeight < _minWeightLimit;
      
      // If weight was abnormal but is now normal, clear any existing alerts
      if ((wasOverweight || wasUnderweight) && !_isOverweight && !_isUnderweight) {
        _hasAlert = false;
        _alertMessage = '';
      }
      
      // Generate random alert for demo if weight changes significantly
      // Skip alert generation during initial load
      if (!_hasAlert && !_isInitialLoad && math.Random().nextDouble() < 0.2) {
        final weightChange = (_weightData.isNotEmpty && _weightData.length > 1) 
            ? _weightData.last.y - _weightData[_weightData.length - 2].y 
            : 0.0;
            
        if (weightChange.abs() > 2.0) {
          _hasAlert = true;
          _alertMessage = 'Weight change detected: ${weightChange.toStringAsFixed(1)} tons. Possible cargo shift alert!';
        }
      }
    });
  }
  
  // Refresh data and check connection
  Future<void> _refreshData() async {
    // First check connection status
    await _checkConnectionStatus();
    
    // If connected, fetch data
    if (_connectionStatus == ConnectionStatus.connected) {
      await _fetchInitialData();
    }
    
    // Show appropriate message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_connectionStatus == ConnectionStatus.connected 
            ? 'Data refreshed' 
            : 'Failed to connect to IoT device'),
          backgroundColor: _connectionStatus == ConnectionStatus.connected 
            ? Colors.blue.shade600 
            : Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _toggleClearance() {
    // Don't allow clearance to be given if weight is out of range
    if (_isOverweight || _isUnderweight) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Cannot give clearance when weight is out of range'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Updating clearance status...'),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
    
    setState(() {
      _isClearanceGiven = !_isClearanceGiven;
    });
    
    // Send clearance status to Blynk
    _blynkService.setClearance(_isClearanceGiven).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _isClearanceGiven ? Icons.check_circle : Icons.cancel, 
                  color: Colors.white
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_isClearanceGiven 
                    ? 'Clearance given to train' 
                    : 'Clearance revoked from train'
                  ),
                ),
              ],
            ),
            backgroundColor: _isClearanceGiven 
              ? Colors.green.shade600 
              : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }).catchError((error) {
      print('Error updating clearance: $error');
      if (mounted) {
        setState(() {
          // Revert state if there was an error
          _isClearanceGiven = !_isClearanceGiven;
        });
        
        // Check connection status
        _checkConnectionStatus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to update clearance status: ${error.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }
  
  void _toggleSendAlert() {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Updating alert status...'),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
    
    setState(() {
      _sendAlertEnabled = !_sendAlertEnabled;
    });
    
    // Send alert status to Blynk
    _blynkService.sendAlert(_sendAlertEnabled).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_sendAlertEnabled 
                    ? 'Alerts enabled and sent to monitoring system' 
                    : 'Alerts disabled'
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }).catchError((error) {
      print('Error updating alert status: $error');
      if (mounted) {
        setState(() {
          // Revert state if there was an error
          _sendAlertEnabled = !_sendAlertEnabled;
        });
        
        // Check connection status
        _checkConnectionStatus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to update alert status: ${error.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }
  
  void _dismissAlert() {
    setState(() {
      _hasAlert = false;
      _alertMessage = '';
    });
  }
  
  // Request location permission
  Future<void> _requestLocationPermission() async {
    setState(() {
      _isRequestingPermission = true;
    });
    
    bool hasPermission;
    
    if (kIsWeb) {
      hasPermission = await AppConfig.requestLocationPermission();
    } else {
      // For Android, we'll use the permission status from the location package
      // This is handled by the GoogleMap widget automatically
      // But we need to request it explicitly first
      hasPermission = await _blynkService.requestLocationPermission();
    }
    
    setState(() {
      _hasLocationPermission = hasPermission;
      _isRequestingPermission = false;
    });
    
    if (hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location permission granted'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Initialize the map if we're on web
      if (kIsWeb && _webMapElementId != null) {
        _initializeWebMap();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location permission denied'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  // Initialize the web map using JavaScript
  void _initializeWebMap() {
    if (kIsWeb && _webMapElementId != null && _hasLocationPermission) {
      // Use a small delay to ensure the DOM element is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          // For web, we'll use a different approach without js_util
          // This will be handled by the JavaScript in index.html
          print('Web map initialization requested for element: $_webMapElementId');
        } catch (e) {
          print('Error initializing web map: $e');
        }
      });
    }
  }
  
  // Platform-safe method to open URLs
  Future<void> _openUrl(String url) async {
    if (kIsWeb) {
      // For web, use the JavaScript bridge
      PlatformSpecific.openUrlInBrowser(url);
    } else {
      // For Android, use url_launcher
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open map: $url'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
  
  void _updateMinWeightLimit(double value) {
    setState(() {
      _minWeightLimit = value;
      _checkWeightStatus();
    });
  }
  
  void _updateMaxWeightLimit(double value) {
    setState(() {
      _maxWeightLimit = value;
      _checkWeightStatus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController?.dispose();
    _updateTimer?.cancel(); // Cancel the timer when disposing
    _connectionBlinkTimer?.cancel(); // Cancel the connection blink timer
    super.dispose();
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoggingOut = true;
    });
    
    try {
      await _authService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Logged out successfully'),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navigate to login page after logout
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Error logging out'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenSize = MediaQuery.of(context).size;
    
    // Create data object to pass to tab components
    final data = DashboardData(
      selectedTrain: _selectedTrain,
      trainOptions: _trainOptions,
      currentWeight: _currentWeight,
      minWeightLimit: _minWeightLimit,
      maxWeightLimit: _maxWeightLimit,
      isOverweight: _isOverweight,
      isUnderweight: _isUnderweight,
      isClearanceGiven: _isClearanceGiven,
      sendAlertEnabled: _sendAlertEnabled,
      isLoadingWeight: _isLoadingWeight,
      isLoadingHistory: _isLoadingHistory,
      hasLocationPermission: _hasLocationPermission,
      isRequestingPermission: _isRequestingPermission,
      webMapElementId: _webMapElementId,
      weightData: _weightData,
      weightHistory: _weightHistory.isEmpty ? List.filled(6, 0.0) : _weightHistory,
      hasAlert: _hasAlert,
      alertMessage: _alertMessage,
      connectionStatus: _connectionStatus,
      isBlinking: _isBlinking,
      errorMessage: _errorMessage,
    );
    
    // Create callbacks object to pass to tab components
    final callbacks = DashboardCallbacks(
      toggleClearance: _toggleClearance,
      toggleSendAlert: _toggleSendAlert,
      dismissAlert: _dismissAlert,
      requestLocationPermission: _requestLocationPermission,
      fetchInitialData: _refreshData,
      openUrl: _openUrl,
      updateMinWeightLimit: _updateMinWeightLimit,
      updateMaxWeightLimit: _updateMaxWeightLimit,
    );
    
    return Scaffold(
      body: Column(
        children: [
          // App Bar - Only the navbar is fixed at the top
          _buildAppBar(user),
          
          // Main Content - Scrollable content below navbar
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade50,
                      Colors.teal.shade50,
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false, // Don't add safe area padding at the top since we have the navbar
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Train Selector and Alert Banner
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Column(
                                children: [
                                  _buildTrainSelector(),
                                  if (_hasAlert) 
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: _buildAlertBanner(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Tab Bar
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildTabBar(),
                            ),
                          ),
                        ),
                        
                        // Tab Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildTabContent(screenSize, data, callbacks),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppBar(User? user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shield,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CargoGuardian',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Train Monitoring Dashboard',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Connection status indicator
                    ConnectionIndicator(
                      status: _connectionStatus,
                      blinking: _isBlinking,
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isLoggingOut
                      ? SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue.shade700,
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.logout_rounded,
                            color: Colors.blue.shade700,
                            size: 28,
                          ),
                          onPressed: _signOut,
                          tooltip: 'Logout',
                        ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTrainSelector() {
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
      child: Row(
        children: [
          Icon(
            Icons.train,
            color: Colors.blue.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Train',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedTrain,
                  isExpanded: true,
                  underline: Container(),
                  icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700, size: 26),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTrain = newValue;
                      });
                    }
                  },
                  items: _trainOptions.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isOverweight 
                ? Colors.red.shade100 
                : _isUnderweight 
                  ? Colors.amber.shade100 
                  : Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isOverweight 
                    ? Icons.error 
                    : _isUnderweight 
                      ? Icons.warning 
                      : Icons.check_circle,
                  size: 16,
                  color: _isOverweight 
                    ? Colors.red.shade700 
                    : _isUnderweight 
                      ? Colors.amber.shade700 
                      : Colors.green.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  _isOverweight 
                    ? 'Overload' 
                    : _isUnderweight 
                      ? 'Underload' 
                      : 'Normal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isOverweight 
                      ? Colors.red.shade700 
                      : _isUnderweight 
                        ? Colors.amber.shade700 
                        : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade700,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALERT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                Text(
                  _alertMessage,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.red.shade700,
              size: 18,
            ),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            onPressed: _dismissAlert,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton(0, 'Overview', Icons.dashboard_outlined),
          _buildTabButton(1, 'Analytics', Icons.analytics_outlined),
          _buildTabButton(2, 'Location', Icons.location_on_outlined),
        ],
      ),
    );
  }
  
  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
            
            // If selecting location tab, check permission
            if (index == 2 && !_hasLocationPermission && !_isRequestingPermission) {
              _requestLocationPermission();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabContent(Size screenSize, DashboardData data, DashboardCallbacks callbacks) {
    switch (_selectedTabIndex) {
      case 0:
        return OverviewTab(
          screenSize: screenSize,
          data: data,
          callbacks: callbacks,
        );
      case 1:
        return AnalyticsTab(
          screenSize: screenSize,
          data: data,
          callbacks: callbacks,
        );
      case 2:
        return LocationTab(
          screenSize: screenSize,
          data: data,
          callbacks: callbacks,
        );
      default:
        return OverviewTab(
          screenSize: screenSize,
          data: data,
          callbacks: callbacks,
        );
    }
  }
}
