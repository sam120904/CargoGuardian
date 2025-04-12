import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';

class BlynkService {
  final String _baseUrl = 'https://blynk.cloud/external/api';

  // Get current weight from Blynk
  Future<double> getCurrentWeight() async {
    try {
      final token = AppConfig.blynkAuthToken;
      final url = '$_baseUrl/get?token=$token&v0';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty && data[0] != null) {
          return double.parse(data[0].toString());
        } else if (data is int) {
          return data.toDouble();
        } else {
          throw Exception('Invalid data format received from IoT device');
        }
      } else {
        throw Exception('Failed to load weight: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error getting current weight: $e');
      throw Exception('Failed to connect to IoT device');
    }
  }

  // Get weight history from Blynk
  Future<List<double>> getWeightHistory() async {
    try {
      final token = AppConfig.blynkAuthToken;
      final url = '$_baseUrl/data/get?token=$token&period=day&granularity=1&pin=v0';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        if (data is List) {
          final history = data.map((item) {
            if (item is Map && item.containsKey('value')) {
              return double.parse(item['value'].toString());
            }
            return 0.0;
          }).toList();

          while (history.length < 6) {
            history.add(0.0);
          }

          return history.sublist(history.length - 6);
        } else {
          throw Exception('No data');
        }
      } else {
        throw Exception('Failed to load weight history: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error getting weight history: $e');
      rethrow;
    }
  }

  // Set clearance status in Blynk
  Future<void> setClearance(bool isClearanceGiven) async {
    try {
      final token = AppConfig.blynkAuthToken;
      final url = '$_baseUrl/update?token=$token&v1=${isClearanceGiven ? 1 : 0}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to update clearance status: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error setting clearance: $e');
      throw Exception('Failed to update clearance status');
    }
  }

  // Send alert status to Blynk
  Future<void> sendAlert(bool sendAlertEnabled) async {
    try {
      final token = AppConfig.blynkAuthToken;
      final url = '$_baseUrl/update?token=$token&v2=${sendAlertEnabled ? 1 : 0}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to update alert status: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error sending alert: $e');
      throw Exception('Failed to update alert status');
    }
  }

  // Request location permission (stub - real implementation needed for Android)
  Future<bool> requestLocationPermission() async {
    // In real apps, use permission_handler or similar package
    return true;
  }

  // Check if IoT device is online
  Future<bool> isIoTDeviceOnline() async {
    try {
      final token = AppConfig.blynkAuthToken;
      final url = '$_baseUrl/get?token=$token&v0';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if ((data is List && data.isNotEmpty && data[0] != null) || data is int) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('IoT device is offline: $e');
      return false;
    }
  }
}
