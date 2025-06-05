import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';

class BlynkService {
  static const String _baseUrl = 'https://blynk.cloud/external/api';

  String get _authToken => AppConfig.blynkAuthToken;

  // Check if IoT device is online
  Future<bool> isIoTDeviceOnline() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/isHardwareConnected?token=$_authToken'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return response.body.toLowerCase() == 'true';
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
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/get?token=$_authToken&v1'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return double.parse(data[0].toString());
        } else if (data is int) {
          return data.toDouble();
        } else {
          throw Exception('Invalid weight data format');
        }
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
    try {
      final value = clearance ? 1 : 0;
      final response = await http.get(
        Uri.parse('$_baseUrl/update?token=$_authToken&v2=$value'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('Clearance ${clearance ? 'given' : 'revoked'} successfully');
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
    try {
      final value = enable ? 1 : 0;
      final response = await http.get(
        Uri.parse('$_baseUrl/update?token=$_authToken&v3=$value'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('Alert ${enable ? 'enabled' : 'disabled'} successfully');
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
