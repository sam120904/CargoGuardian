import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Static initialization flag to track if we've tried loading .env
  static bool _didTryLoadEnv = false;
  
  // Method to initialize config - call this before accessing any values
  static Future<void> initialize() async {
    if (!_didTryLoadEnv) {
      try {
        // Try to load .env file, but don't throw if it fails
        await dotenv.load(fileName: ".env").catchError((e) {
          print("Note: .env file not loaded: $e");
          // This is expected in Vercel, so we continue
        });
      } catch (e) {
        print("Note: Error loading environment: $e");
        // Continue anyway, we'll use environment variables from the platform
      } finally {
        _didTryLoadEnv = true;
      }
    }
  }

  // Helper method to get environment variables with fallbacks
  static String _getEnv(String key, String fallback) {
    // First try dotenv (for local development)
    String? value = dotenv.env[key];
    
    // If not found and in web, try to get from platform environment
    // (this is how Vercel provides environment variables)
    if ((value == null || value.isEmpty) && kIsWeb) {
      // For web in production, we'll use the values from platform environment
      // or the fallback values if not available
      
      // Note: In a real Vercel deployment, environment variables are injected
      // into the JavaScript environment and can be accessed via dotenv
      // even though we didn't load a .env file
      
      if (dotenv.env[key] != null && dotenv.env[key]!.isNotEmpty) {
        return dotenv.env[key]!;
      }
      
      if (kDebugMode) {
        print('Using fallback for $key in web environment');
      }
    }
    
    // Return the value if found, otherwise use fallback
    return value ?? fallback;
  }

  // Blynk API credentials
  static String get blynkTemplateId => _getEnv('BLYNK_TEMPLATE_ID', 'TMPL3DNFQ3rfM');
  static String get blynkTemplateName => _getEnv('BLYNK_TEMPLATE_NAME', 'final');
  static String get blynkAuthToken => _getEnv('BLYNK_AUTH_TOKEN', ''); // Add your default here
  static String get blynkBaseUrl => _getEnv('BLYNK_BASE_URL', 'https://blynk.cloud/external/api');
  
  // Firebase configuration
  static String get firebaseApiKey => _getEnv('FIREBASE_API_KEY', ''); // Add your default here
  static String get firebaseAppId => _getEnv('FIREBASE_APP_ID', ''); // Add your default here
  static String get firebaseProjectId => _getEnv('FIREBASE_PROJECT_ID', 'vector-shield');
  static String get firebaseMessagingSenderId => _getEnv('FIREBASE_MESSAGING_SENDER_ID', '724662837533');
  static String get firebaseStorageBucket => _getEnv('FIREBASE_STORAGE_BUCKET', 'vector-shield.appspot.com');
  
  // Method to check if running in production
  static bool get isProduction {
    return kIsWeb && !kDebugMode;
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
  
  // Debug method to print all config values (without sensitive data)
  static void debugPrintConfig() {
    if (kDebugMode) {
      print('=== AppConfig Values ===');
      print('Environment: ${isProduction ? 'Production' : 'Development'}');
      print('FIREBASE_API_KEY: ${firebaseApiKey.isEmpty ? 'MISSING' : 'SET'}');
      print('FIREBASE_APP_ID: ${firebaseAppId.isEmpty ? 'MISSING' : 'SET'}');
      print('FIREBASE_PROJECT_ID: $firebaseProjectId');
      print('BLYNK_TEMPLATE_ID: $blynkTemplateId');
      print('BLYNK_AUTH_TOKEN: ${blynkAuthToken.isEmpty ? 'MISSING' : 'SET'}');
      print('=======================');
    }
  }
}

