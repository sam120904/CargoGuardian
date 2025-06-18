import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/config.dart';
import 'testing_service.dart';

class BlynkService {
  static const String _baseUrl = 'https://blynk.cloud/external/api';
  final TestingService _testingService = TestingService();

  String get _authToken => AppConfig.blynkAuthToken;

  // Check if IoT device is online
  Future<bool> isIoTDeviceOnline() async {
    // If in test mode, return simulated status
    if (_testingService.isTestMode) {
      if (kDebugMode) {
        print('🧪 [TEST MODE] Simulated device status: ${_testingService.simulatedDeviceOnline ? "ONLINE" : "OFFLINE"}');
      }
      return _testingService.simulatedDeviceOnline;
    }

    // Real device check
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/isHardwareConnected?token=$_authToken'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final isOnline = response.body.toLowerCase() == 'true';
        if (kDebugMode) {
          print('🔌 [REAL MODE] Device status: ${isOnline ? "ONLINE" : "OFFLINE"}');
        }
        return isOnline;
      } else {
        print('Error checking device status: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error checking device status: $e');
      return false;
    }
  }

  // Get current weight from virtual pin V1
  Future<double> getCurrentWeight() async {
    // If in test mode, return simulated weight
    if (_testingService.isTestMode) {
      final weight = _testingService.simulatedWeight;
      if (kDebugMode) {
        print('🧪 [TEST MODE] Simulated weight: ${weight.toStringAsFixed(1)} tons');
      }
      return weight;
    }

    // Real device data
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/get?token=$_authToken&v1'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double weight;
        if (data is List && data.isNotEmpty) {
          weight = double.parse(data[0].toString());
        } else if (data is int) {
          weight = data.toDouble();
        } else {
          throw Exception('Invalid weight data format');
        }
        if (kDebugMode) {
          print('🔌 [REAL MODE] Actual weight: ${weight.toStringAsFixed(1)} tons');
        }
        return weight;
      } else {
        throw Exception('Failed to fetch weight: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching current weight: $e');
      throw Exception('Failed to fetch weight data: ${e.toString()}');
    }
  }

  // Get weight history from virtual pin V1
  Future<List<double>> getWeightHistory() async {
    // If in test mode, return simulated history
    if (_testingService.isTestMode) {
      final history = _testingService.simulatedHistory;
      if (kDebugMode) {
        print('🧪 [TEST MODE] Simulated history: ${history.map((w) => w.toStringAsFixed(1)).join(', ')} tons');
      }
      return history;
    }

    // Real device history
    try {
      // Using Blynk's export data API to get historical data
      final response = await http.get(
        Uri.parse('$_baseUrl/data/get?token=$_authToken&period=day&granularityType=minute&pin=v1&output=json'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<double> history = [];
        
        // Extract the last 6 data points or fewer if not available
        final int count = data.length > 6 ? 6 : data.length;
        for (int i = data.length - count; i < data.length; i++) {
          if (data[i] != null && data[i]['value'] != null) {
            history.add(double.parse(data[i]['value'].toString()));
          }
        }
        
        // Ensure we have at least 6 data points
        while (history.length < 6) {
          history.add(0.0);
        }
        
        if (kDebugMode) {
          print('🔌 [REAL MODE] Actual history: ${history.map((w) => w.toStringAsFixed(1)).join(', ')} tons');
        }
        return history;
      } else if (response.statusCode == 429) {
        throw Exception('Reports limit reached. One device can send only 24 reports per day');
      } else {
        throw Exception('Failed to fetch history: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching weight history: $e');
      if (e.toString().contains('Reports limit reached')) {
        rethrow;
      }
      throw Exception('Failed to fetch weight history: ${e.toString()}');
    }
  }

  // Set clearance status to virtual pin V2
  Future<void> setClearance(bool clearance) async {
    // If in test mode, simulate the action
    if (_testingService.isTestMode) {
      if (kDebugMode) {
        print('🧪 [TEST MODE] Simulated clearance ${clearance ? 'GIVEN' : 'REVOKED'}');
      }
      // Simulate a small delay
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    // Real device action
    try {
      final value = clearance ? 1 : 0;
      final response = await http.get(
        Uri.parse('$_baseUrl/update?token=$_authToken&v2=$value'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('🔌 [REAL MODE] Clearance ${clearance ? 'given' : 'revoked'} successfully');
        }
      } else {
        throw Exception('Failed to update clearance: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error setting clearance: $e');
      throw Exception('Failed to update clearance: ${e.toString()}');
    }
  }

  // Send alert to virtual pin V3
  Future<void> sendAlert(bool enable) async {
    // If in test mode, simulate the action
    if (_testingService.isTestMode) {
      if (kDebugMode) {
        print('🧪 [TEST MODE] Simulated alert ${enable ? 'ENABLED' : 'DISABLED'}');
      }
      // Simulate a small delay
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    // Real device action
    try {
      final value = enable ? 1 : 0;
      final response = await http.get(
        Uri.parse('$_baseUrl/update?token=$_authToken&v3=$value'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('🔌 [REAL MODE] Alert ${enable ? 'enabled' : 'disabled'} successfully');
        }
      } else {
        throw Exception('Failed to update alert status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending alert: $e');
      throw Exception('Failed to update alert status: ${e.toString()}');
    }
  }

  // Request location permission (for mobile)
  Future<bool> requestLocationPermission() async {
    try {
      // This would use permission_handler package in a real implementation
      // For now, simulate permission grant
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }
}
