import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Helper method to get environment variables with fallbacks
  static String _getEnv(String key, String fallback) {
    // First try dotenv
    String? value = dotenv.env[key];
    
    // If not found and in web, try to print a helpful message
    if ((value == null || value.isEmpty) && kIsWeb) {
      print('WARNING: Environment variable $key not found. Using fallback value.');
    }
    
    return value ?? fallback;
  }

  // Blynk API credentials
  static String get blynkTemplateId => _getEnv('BLYNK_TEMPLATE_ID', '');
  static String get blynkTemplateName => _getEnv('BLYNK_TEMPLATE_NAME', '');
  static String get blynkAuthToken => _getEnv('BLYNK_AUTH_TOKEN', '');
  static String get blynkBaseUrl => _getEnv('BLYNK_BASE_URL', 'https://blynk.cloud/external/api');
  
  // Firebase configuration
  static String get firebaseApiKey => _getEnv('FIREBASE_API_KEY', '');
  static String get firebaseAppId => _getEnv('FIREBASE_APP_ID', '');
  static String get firebaseProjectId => _getEnv('FIREBASE_PROJECT_ID', '');
  static String get firebaseMessagingSenderId => _getEnv('FIREBASE_MESSAGING_SENDER_ID', '');
  static String get firebaseStorageBucket => _getEnv('FIREBASE_STORAGE_BUCKET', '');
  
  // Method to check if running in production
  static bool get isProduction {
    return _getEnv('ENVIRONMENT', '') == 'production';
  }
  
  // Method to check if all required Firebase config is present
  static bool get hasRequiredFirebaseConfig {
    return firebaseApiKey.isNotEmpty && 
           firebaseAppId.isNotEmpty && 
           firebaseProjectId.isNotEmpty;
  }
  
  // Method to check if all required Blynk config is present
  static bool get hasRequiredBlynkConfig {
    return blynkTemplateId.isNotEmpty && 
           blynkAuthToken.isNotEmpty;
  }
}