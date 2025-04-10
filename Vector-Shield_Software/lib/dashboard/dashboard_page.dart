import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../services/auth_service.dart';
import '../services/blynk_service.dart';
import '../config/config.dart';

// Dashboard tabs and widgets
import 'overview_tab.dart';
import 'analytics_tab.dart';
import 'location_tab.dart';
import 'connection_indicator.dart';


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
  
  // Weight data
  double _currentWeight = 0.0;
  double _minWeightLimit = 20.0;
  double _maxWeightLimit = 50.0;
  bool _isOverweight = false;
  bool _isUnderweight = false;
  bool _isClearanceGiven = false;
  bool _sendAlertEnabled = false;
  
  // Data loading states
  bool _isLoadingWeight = true;
  bool _isLoadingHistory = true;
  
  // Timer for periodic updates
  Timer? _updateTimer;
  
  // Location permission state
  bool _hasLocationPermission = false;
  bool _isRequestingPermission = false;
  
  // Alert data
  bool _hasAlert = false;
  String _alertMessage = '';
  
  // Tab selection
  int _selectedTabIndex = 0;
  
  // Flag to prevent alert on initial load
  bool _isInitialLoad = true;

  // IoT connection status
  ConnectionStatus _connectionStatus = ConnectionStatus.checking;
  Timer? _connectionBlinkTimer;
  bool _blinkState = false;
  
  // Weight history data for graph
  List<double> _weightHistory = List.filled(6, 0.0);
  
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
    
    // Check location permission
    _checkLocationPermission();
    
    // Fetch initial data
    _fetchInitialData();
    
    // Start periodic updates
    _startPeriodicUpdates();

    // Start connection indicator blinking
    _startConnectionBlinking();
  }

  // Start the connection indicator blinking
  void _startConnectionBlinking() {
    // Start with checking status
    setState(() {
      _connectionStatus = ConnectionStatus.checking;
    });

    // Create a timer that toggles the blink state every 500ms
    _connectionBlinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _blinkState = !_blinkState;
      });
    });

    // After 2 seconds, move to connecting status
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _connectionStatus = ConnectionStatus.connecting;
        });
        
        // After 3 more seconds, check if we have weight data to determine connection
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              if (_isLoadingWeight) {
                // Still loading, connection failed
                _connectionStatus = ConnectionStatus.disconnected;
              } else {
                // Data loaded, connection successful
                _connectionStatus = ConnectionStatus.connected;
                
                // Stop blinking for connected state
                _connectionBlinkTimer?.cancel();
                _blinkState = false;
              }
            });
          }
        });
      }
    });
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
      // For Android, we'll use the permission status from the location package
      // This is handled by the GoogleMap widget automatically
      setState(() {
        _hasLocationPermission = true; // Assume true for now, will be checked by GoogleMap
      });
    }
  }
  
  // Fetch initial data from Blynk
  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoadingWeight = true;
      _isLoadingHistory = true;
    });
    
    try {
      // Get current weight
      final weight = await _blynkService.getCurrentWeight();
      if (mounted) {
        setState(() {
          _currentWeight = weight;
          _isLoadingWeight = false;
          _checkWeightStatus();
          
          // Update connection status based on successful data fetch
          _connectionStatus = ConnectionStatus.connected;
          _connectionBlinkTimer?.cancel();
          _blinkState = false;
        });
      }
      
      // Get weight history
      try {
        final history = await _blynkService.getWeightHistory();
        if (history.isNotEmpty && mounted) {
          setState(() {
            _weightHistory = history.take(6).toList();
            while (_weightHistory.length < 6) {
              _weightHistory.add(0.0);
            }
            _isLoadingHistory = false;
            _isInitialLoad = false;
          });
        } else if (mounted) {
          setState(() {
            _isLoadingHistory = false;
            _isInitialLoad = false;
          });
        }
      } catch (e) {
        print('Failed to load weight history: $e');
        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
            _isInitialLoad = false;
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
          
          // Update connection status based on failed data fetch
          _connectionStatus = ConnectionStatus.disconnected;
        });
      }
    }
  }
  
  // Start periodic updates
  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        // Get current weight
        final weight = await _blynkService.getCurrentWeight();
        if (mounted) {
          setState(() {
            _currentWeight = weight;
            
            // Update weight history by shifting data points
            if (_weightHistory.isNotEmpty) {
              final newData = <double>[];
              for (int i = 1; i < _weightHistory.length; i++) {
                newData.add(_weightHistory[i]);
              }
              newData.add(weight);
              _weightHistory = newData;
            }
            
            _checkWeightStatus();
            
            // Update connection status on successful data fetch
            if (_connectionStatus != ConnectionStatus.connected) {
              _connectionStatus = ConnectionStatus.connected;
              _connectionBlinkTimer?.cancel();
              _blinkState = false;
            }
          });
        }
      } catch (e) {
        print('Error updating weight: $e');
        if (mounted) {
          setState(() {
            // Update connection status on failed data fetch
            _connectionStatus = ConnectionStatus.disconnected;
            if (_connectionBlinkTimer == null || !_connectionBlinkTimer!.isActive) {
              _startConnectionBlinking();
            }
          });
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
      if (!_hasAlert && !_isInitialLoad && _weightHistory.length > 1) {
        final weightChange = _weightHistory.last - _weightHistory[_weightHistory.length - 2];
        if (weightChange.abs() > 2.0) {
          _hasAlert = true;
          _alertMessage = 'Weight change detected: ${weightChange.toStringAsFixed(1)} tons. Possible cargo shift alert!';
        }
      }
    });
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
              const Text('Cannot give clearance when weight is out of range'),
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
                Text(_isClearanceGiven 
                  ? 'Clearance given to train' 
                  : 'Clearance revoked from train'
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text('Failed to update clearance status: ${error.toString()}'),
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
                Text(_sendAlertEnabled 
                  ? 'Alerts enabled and sent to monitoring system' 
                  : 'Alerts disabled'
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text('Failed to update alert status: ${error.toString()}'),
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
    
    bool hasPermission = await AppConfig.requestLocationPermission();
    
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

  @override
  void dispose() {
    _animationController.dispose();
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
                          child: _buildTabContent(screenSize),
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
                Row(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vector Shield',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        Text(
                          'Train Monitoring Dashboard',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    // Add connection indicator
                    const SizedBox(width: 16),
                    ConnectionIndicator(
                      status: _connectionStatus,
                      blinking: _blinkState,
                    ),
                  ],
                ),
                Row(
                  children: [
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
  
  Widget _buildTabContent(Size screenSize) {
    // Create a DashboardData object to pass to tab widgets
    final dashboardData = DashboardData(
      currentWeight: _currentWeight,
      minWeightLimit: _minWeightLimit,
      maxWeightLimit: _maxWeightLimit,
      isOverweight: _isOverweight,
      isUnderweight: _isUnderweight,
      isClearanceGiven: _isClearanceGiven,
      sendAlertEnabled: _sendAlertEnabled,
      isLoadingWeight: _isLoadingWeight,
      isLoadingHistory: _isLoadingHistory,
      hasAlert: _hasAlert,
      alertMessage: _alertMessage,
      weightHistory: _weightHistory,
      selectedTrain: _selectedTrain,
      hasLocationPermission: _hasLocationPermission,
      isRequestingPermission: _isRequestingPermission,
      connectionStatus: _connectionStatus,
      blinkState: _blinkState,
    );
    
    // Create callback functions to pass to tab widgets
    final callbacks = DashboardCallbacks(
      toggleClearance: _toggleClearance,
      toggleSendAlert: _toggleSendAlert,
      requestLocationPermission: _requestLocationPermission,
      dismissAlert: _dismissAlert,
      fetchInitialData: _fetchInitialData,
    );
    
    switch (_selectedTabIndex) {
      case 0:
        return OverviewTab(
          screenSize: screenSize,
          data: dashboardData,
          callbacks: callbacks,
        );
      case 1:
        return AnalyticsTab(
          screenSize: screenSize,
          data: dashboardData,
          callbacks: callbacks,
        );
      case 2:
        return LocationTab(
          screenSize: screenSize,
          data: dashboardData,
          callbacks: callbacks,
        );
      default:
        return OverviewTab(
          screenSize: screenSize,
          data: dashboardData,
          callbacks: callbacks,
        );
    }
  }
}

// Data class to pass to tab widgets
class DashboardData {
  final double currentWeight;
  final double minWeightLimit;
  final double maxWeightLimit;
  final bool isOverweight;
  final bool isUnderweight;
  final bool isClearanceGiven;
  final bool sendAlertEnabled;
  final bool isLoadingWeight;
  final bool isLoadingHistory;
  final bool hasAlert;
  final String alertMessage;
  final List<double> weightHistory;
  final String selectedTrain;
  final bool hasLocationPermission;
  final bool isRequestingPermission;
  final ConnectionStatus connectionStatus;
  final bool blinkState;
  
  DashboardData({
    required this.currentWeight,
    required this.minWeightLimit,
    required this.maxWeightLimit,
    required this.isOverweight,
    required this.isUnderweight,
    required this.isClearanceGiven,
    required this.sendAlertEnabled,
    required this.isLoadingWeight,
    required this.isLoadingHistory,
    required this.hasAlert,
    required this.alertMessage,
    required this.weightHistory,
    required this.selectedTrain,
    required this.hasLocationPermission,
    required this.isRequestingPermission,
    required this.connectionStatus,
    required this.blinkState,
  });
}

// Callback functions to pass to tab widgets
class DashboardCallbacks {
  final VoidCallback toggleClearance;
  final VoidCallback toggleSendAlert;
  final VoidCallback requestLocationPermission;
  final VoidCallback dismissAlert;
  final Future<void> Function() fetchInitialData;
  
  DashboardCallbacks({
    required this.toggleClearance,
    required this.toggleSendAlert,
    required this.requestLocationPermission,
    required this.dismissAlert,
    required this.fetchInitialData,
  });
}