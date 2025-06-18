import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

// Import platform-specific code conditionally
import '../platform/platform_imports.dart';

class TestingService {
  static final TestingService _instance = TestingService._internal();
  factory TestingService() => _instance;
  TestingService._internal();

  bool _isTestMode = false;
  Timer? _consoleListener;
  Timer? _simulationTimer;
  
  // Simulated data
  double _simulatedWeight = 35.0;
  final List<double> _simulatedHistory = [32.0, 34.0, 35.0, 36.0, 35.5, 35.0];
  bool _simulatedDeviceOnline = true;
  
  // Callbacks for when test mode changes
  final List<VoidCallback> _testModeChangeCallbacks = [];

  bool get isTestMode => _isTestMode;
  bool get simulatedDeviceOnline => _simulatedDeviceOnline;
  double get simulatedWeight => _simulatedWeight;
  List<double> get simulatedHistory => List.from(_simulatedHistory);

  void initialize() {
    if (kIsWeb) {
      _startConsoleListener();
      PlatformSpecific.setupConsoleListener();
    }
    _startSimulation();
    
    if (kDebugMode) {
      print('🚀 CargoGuardian TestingService initialized');
      print('📊 Default mode: REAL DATA (TEST OFF)');
      if (kIsWeb) {
        print('💡 Web platform detected - Console commands available:');
        print('   • Open browser console and type: TEST_ON()');
        print('   • To disable: TEST_OFF()');
        print('   • Or use Ctrl+Shift+T for help');
      } else {
        print('📱 Mobile platform detected - Console commands not available');
      }
    }
  }

  void dispose() {
    _consoleListener?.cancel();
    _simulationTimer?.cancel();
  }

  void _startConsoleListener() {
    if (!kIsWeb) return;
    
    // Set up console command listener for web
    _consoleListener = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      try {
        // Use platform-specific code to check for console commands
        PlatformSpecific.checkConsoleCommands((String command) {
          _handleConsoleCommand(command.trim().toUpperCase());
        });
      } catch (e) {
        // Silently handle errors - console listener is optional
      }
    });
  }

  void _handleConsoleCommand(String command) {
    switch (command) {
      case 'TEST ON':
        enableTestMode();
        break;
      case 'TEST OFF':
        disableTestMode();
        break;
      default:
        // Ignore unknown commands
        break;
    }
  }

  void enableTestMode() {
    if (_isTestMode) return;
    
    _isTestMode = true;
    _simulatedDeviceOnline = true;
    
    if (kDebugMode) {
      print('🧪 TEST MODE ENABLED - Now showing simulated data');
      print('📊 Simulated device is ONLINE with realistic weight data');
      print('💡 Type TEST_OFF() to return to real hardware data');
    }
    
    _notifyTestModeChange();
  }

  void disableTestMode() {
    if (!_isTestMode) return;
    
    _isTestMode = false;
    
    if (kDebugMode) {
      print('🔌 TEST MODE DISABLED - Now showing real hardware data');
      print('📡 Connecting to actual IoT device...');
    }
    
    _notifyTestModeChange();
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isTestMode) return;
      
      // Simulate realistic weight fluctuations
      final random = math.Random();
      final baseWeight = 35.0;
      final variation = (random.nextDouble() - 0.5) * 4.0; // ±2 tons variation
      _simulatedWeight = (baseWeight + variation).clamp(20.0, 60.0);
      
      // Update history by shifting data
      _simulatedHistory.removeAt(0);
      _simulatedHistory.add(_simulatedWeight);
      
      // Occasionally simulate device going offline/online in test mode
      if (random.nextDouble() < 0.05) { // 5% chance
        _simulatedDeviceOnline = !_simulatedDeviceOnline;
        if (kDebugMode) {
          print(_simulatedDeviceOnline 
            ? '🟢 Simulated device came back ONLINE' 
            : '🔴 Simulated device went OFFLINE');
        }
      }
    });
  }

  void addTestModeChangeCallback(VoidCallback callback) {
    _testModeChangeCallbacks.add(callback);
  }

  void removeTestModeChangeCallback(VoidCallback callback) {
    _testModeChangeCallbacks.remove(callback);
  }

  void _notifyTestModeChange() {
    for (final callback in _testModeChangeCallbacks) {
      callback();
    }
  }

  // Manual control methods for testing
  void setSimulatedWeight(double weight) {
    if (_isTestMode) {
      _simulatedWeight = weight.clamp(0.0, 100.0);
    }
  }

  void setSimulatedDeviceStatus(bool online) {
    if (_isTestMode) {
      _simulatedDeviceOnline = online;
      if (kDebugMode) {
        print(online 
          ? '🟢 Simulated device set to ONLINE' 
          : '🔴 Simulated device set to OFFLINE');
      }
    }
  }

  // Generate realistic simulated data
  Map<String, dynamic> getSimulatedSensorData() {
    final random = math.Random();
    return {
      'weight': _simulatedWeight,
      'temperature': 22.0 + (random.nextDouble() * 6.0), // 22-28°C
      'humidity': 45.0 + (random.nextDouble() * 20.0), // 45-65%
      'vibration': random.nextDouble() * 2.0, // 0-2 units
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
