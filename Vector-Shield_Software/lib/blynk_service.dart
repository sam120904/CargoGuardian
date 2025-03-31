import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart'; // Import the config file for API keys

class BlynkService {
  // Get credentials from config file instead of hardcoding
  final String templateId = AppConfig.blynkTemplateId;
  final String templateName = AppConfig.blynkTemplateName;
  final String authToken = AppConfig.blynkAuthToken;
  final String baseUrl = AppConfig.blynkBaseUrl;
  
  // Get current weight data from Blynk
  Future<double> getCurrentWeight() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get?token=$authToken&v0'),
      );
      
      if (response.statusCode == 200) {
        final value = response.body.replaceAll('[', '').replaceAll(']', '');
        // Removed console log
      
        // Check if the value is empty (not if it's zero)
        if (value.isEmpty) {
          // Removed console log
          // Wait a moment and try again
          await Future.delayed(const Duration(milliseconds: 300));
          final retryResponse = await http.get(
            Uri.parse('$baseUrl/get?token=$authToken&v0'),
          );
        
          if (retryResponse.statusCode == 200) {
            final retryValue = retryResponse.body.replaceAll('[', '').replaceAll(']', '');
            if (retryValue.isNotEmpty) {
              // Accept any non-empty value, including zero
              return double.parse(retryValue);
            }
          }
        
          // Only use default if we truly can't get a value
          return 0.0; // Return actual zero instead of default
        }
      
        // Accept any value, including zero
        return double.parse(value);
      } else {
        print('Failed to load weight data: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to load weight data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting weight: $e');
      // Return zero in case of error instead of default
      return 0.0;
    }
  }
  
  // Get historical weight data
  Future<List<double>> getWeightHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/data/get?token=$authToken&period=day&granularity=1&pin=v0'),
      );
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map<double>((item) => double.parse(item[1].toString())).toList();
      } else {
        throw Exception('Failed to load weight history');
      }
    } catch (e) {
      print('Error getting weight history: $e');
      // Return zeros for default values instead of random values
      return [0, 0, 0, 0, 0, 0];
    }
  }
  
  // Send clearance status to Blynk
  Future<void> setClearance(bool isClearanceGiven) async {
    try {
      final value = isClearanceGiven ? "1" : "0";
      print('Setting clearance to: $value');
    
      final response = await http.get(
        Uri.parse('$baseUrl/update?token=$authToken&v1=$value'),
      );
    
      print('Clearance update response: ${response.statusCode}, ${response.body}');
    
      if (response.statusCode != 200) {
        throw Exception('Failed to update clearance status: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error setting clearance: $e');
      rethrow;
    }
  }
  
  // Send alert status to Blynk
  Future<void> sendAlert(bool sendAlert) async {
    try {
      final value = sendAlert ? "1" : "0";
      print('Setting alert to: $value');
    
      final response = await http.get(
        Uri.parse('$baseUrl/update?token=$authToken&v2=$value'),
      );
    
      print('Alert update response: ${response.statusCode}, ${response.body}');
    
      if (response.statusCode != 200) {
        throw Exception('Failed to update alert status: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error sending alert: $e');
      rethrow;
    }
  }
}

