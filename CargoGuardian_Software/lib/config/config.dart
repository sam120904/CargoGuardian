import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiKey => dotenv.env['API_KEY'] ?? 'AIzaSyDS3Qwxu0gTG5i0inF8V2-jdeFFhch9PSQ';
  static String get appId => dotenv.env['APP_ID'] ?? '1:123456789:web:abcdef123456';
  static String get messagingSenderId => dotenv.env['MESSAGING_SENDER_ID'] ?? '123456789';
  static String get projectId => dotenv.env['PROJECT_ID'] ?? 'cargo-guardian-project';
  static String get storageBucket => dotenv.env['STORAGE_BUCKET'] ?? 'cargo-guardian-project.appspot.com';
  
  // Blynk configuration
  static String get blynkAuthToken => dotenv.env['BLYNK_AUTH_TOKEN'] ?? 'YOUR_BLYNK_AUTH_TOKEN';
  static String get blynkServer => dotenv.env['BLYNK_SERVER'] ?? 'blynk.cloud';
  static int get blynkPort => int.tryParse(dotenv.env['BLYNK_PORT'] ?? '443') ?? 443;
  
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      print('Environment variables loaded successfully');
    } catch (e) {
      print('Error loading environment variables: $e');
      print('Using default configuration values');
    }
  }
  
  static void debugPrintConfig() {
    if (kDebugMode) {
      print('=== AppConfig Debug Info ===');
      print('Project ID: $projectId');
      print('Blynk Server: $blynkServer');
      print('Blynk Port: $blynkPort');
      print('===========================');
    }
  }
  
  // Location permission helpers for web
  static bool hasLocationPermission = false;
  
  static Future<bool> requestLocationPermission() async {
    if (kIsWeb) {
      try {
        // Use the JavaScript function defined in index.html
        // This is a placeholder - actual implementation would use js interop
        hasLocationPermission = true;
        return true;
      } catch (e) {
        print('Error requesting location permission: $e');
        return false;
      }
    }
    return false;
  }
}
