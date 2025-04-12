import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/config.dart';

class BlynkService {
  final String _baseUrl = 'https://blynk.cloud/external/api';
  
  // Get current weight from Blynk
  Future<double> getCurrentWeight() async {
    try {
      // For demo purposes, we'll simulate a random weight
      // In a real app, you would fetch this from Blynk
      if (kIsWeb) {
        // Simulate a network request
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Simulate a random weight between 30 and 60
        final random = math.Random();
        final weight = 30.0 + random.nextDouble() * 30.0;
        
        // Simulate a server error sometimes
        if (random.nextDouble() < 0.3) {
          throw Exception('Failed to connect to IoT device');
        }
        
        return weight;
      } else {
        // For Android, we'll use the Blynk API
        final token = AppConfig.blynkAuthToken;
        final url = '$_baseUrl/get?token=$token&v0';
        
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          // Parse the response
          final dynamic data = jsonDecode(response.body);
          if (data is List && data.isNotEmpty && data[0] != null) {
            return double.parse(data[0].toString());
          } else if (data is int) {
            // Handle case where response is a single integer
            return data.toDouble();
          } else {
            return 0.0;
          }
        } else {
          // If the server did not return a 200 OK response,
          // throw an exception.
          throw Exception('Failed to load weight: ${response.statusCode}, ${response.body}');
        }
      }
    } catch (e) {
      print('Error getting current weight: $e');
      throw Exception('Failed to connect to IoT device');
    }
  }
  
  // Get weight history from Blynk
  Future<List<double>> getWeightHistory() async {
    try {
      // For demo purposes, we'll simulate a random weight history
      // In a real app, you would fetch this from Blynk
      if (kIsWeb) {
        // Simulate a network request
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Check if we can connect to the IoT device first
        if (!await isIoTDeviceOnline()) {
          throw Exception('Failed to connect to IoT device');
        }
        
        // Simulate a random weight history
        final random = math.Random();
        
        // Simulate a server error sometimes
        if (random.nextDouble() < 0.3) {
          throw Exception('Reports limit reached. One device can send only 24 reports per day');
        }
        
        // Generate 6 random weights between 30 and 60
        final history = List.generate(
          6, 
          (index) => 30.0 + random.nextDouble() * 30.0
        );
        
        return history;
      } else {
        // For Android, we'll use the Blynk API
        final token = AppConfig.blynkAuthToken;
        final url = '$_baseUrl/data/get?token=$token&period=day&granularity=1&pin=v0';
        
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          // Parse the response
          final dynamic data = jsonDecode(response.body);
          
          if (data is List) {
            final history = data.map((item) {
              if (item is Map && item.containsKey('value')) {
                return double.parse(item['value'].toString());
              }
              return 0.0;
            }).toList();
            
            // Ensure we have at least 6 data points
            while (history.length < 6) {
              history.add(0.0);
            }
            
            // Take only the last 6 data points
            return history.sublist(math.max(0, history.length - 6));
          } else {
            throw Exception('No data');
          }
        } else {
          // If the server did not return a 200 OK response,
          // throw an exception.
          throw Exception('Failed to load weight history: ${response.statusCode}, ${response.body}');
        }
      }
    } catch (e) {
      print('Error getting weight history: $e');
      rethrow;
    }
  }
  
  // Set clearance status in Blynk
  Future<void> setClearance(bool isClearanceGiven) async {
    try {
      // For demo purposes, we'll simulate a network request
      // In a real app, you would send this to Blynk
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Simulate a server error sometimes
      if (math.Random().nextDouble() < 0.3) {
        throw Exception('Failed to update clearance status');
      }
      
      // In a real app, you would send this to Blynk
      // final token = AppConfig.blynkAuthToken;
      // final url = '$_baseUrl/update?token=$token&v1=${isClearanceGiven ? 1 : 0}';
      // final response = await http.get(Uri.parse(url));
      
      // if (response.statusCode != 200) {
      //   throw Exception('Failed to update clearance status: ${response.statusCode}, ${response.body}');
      // }
    } catch (e) {
      print('Error setting clearance: $e');
      throw Exception('Failed to update clearance status');
    }
  }
  
  // Send alert status to Blynk
  Future<void> sendAlert(bool sendAlertEnabled) async {
    try {
      // For demo purposes, we'll simulate a network request
      // In a real app, you would send this to Blynk
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Simulate a server error sometimes
      if (math.Random().nextDouble() < 0.3) {
        throw Exception('Failed to update alert status');
      }
      
      // In a real app, you would send this to Blynk
      // final token = AppConfig.blynkAuthToken;
      // final url = '$_baseUrl/update?token=$token&v2=${sendAlertEnabled ? 1 : 0}';
      // final response = await http.get(Uri.parse(url));
      
      // if (response.statusCode != 200) {
      //   throw Exception('Failed to update alert status: ${response.statusCode}, ${response.body}');
      // }
    } catch (e) {
      print('Error sending alert: $e');
      throw Exception('Failed to update alert status');
    }
  }
  
  // Request location permission (Android only)
  Future<bool> requestLocationPermission() async {
    try {
      // For demo purposes, we'll simulate a permission request
      // In a real app, you would use a location permission package
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Simulate permission granted
      return true;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  // Add a method to check if the IoT device is online
  Future<bool> isIoTDeviceOnline() async {
    try {
      // Try to get the current weight as a connectivity test
      await getCurrentWeight();
      return true;
    } catch (e) {
      print('IoT device is offline: $e');
      return false;
    }
  }
}
