import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Static initialization flag to track if we've tried loading .env
  static bool _didTryLoadEnv = false;

  // Method to initialize config - call this before accessing any values
  static Future<void> initialize() async {
    if (!_didTryLoadEnv) {
      try {
        // Only try to load .env file when running locally (not on Vercel)
        if (!kIsWeb || kDebugMode) {
          await dotenv.load(fileName: ".env").catchError((e) {
            print("Note: .env file not loaded: $e");
          });
        }
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
    // First check if we're on web in production (Vercel)
    if (kIsWeb && !kDebugMode) {
      // In production web (Vercel), environment variables are injected
      // into the JavaScript environment and can be accessed via dotenv
      // even though we didn't explicitly load a .env file
      final value = dotenv.env[key];
      if (value != null && value.isNotEmpty) {
        return value;
      }
    } else {
      // For local development, we loaded the .env file
      final value = dotenv.env[key];
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    // Return fallback if no value found
    return fallback;
  }

  // Blynk API credentials
  static String get blynkTemplateId =>
      _getEnv('BLYNK_TEMPLATE_ID', 'TMPL3DNFQ3rfM');
  static String get blynkTemplateName =>
      _getEnv('BLYNK_TEMPLATE_NAME', 'final');
  static String get blynkAuthToken =>
      _getEnv('BLYNK_AUTH_TOKEN', ''); // Add your default here
  static String get blynkBaseUrl =>
      _getEnv('BLYNK_BASE_URL', 'https://blynk.cloud/external/api');

  // Firebase configuration
  static String get firebaseApiKey =>
      _getEnv('FIREBASE_API_KEY', ''); // Add your default here
  static String get firebaseAppId =>
      _getEnv('FIREBASE_APP_ID', ''); // Add your default here
  static String get firebaseProjectId =>
      _getEnv('FIREBASE_PROJECT_ID', 'vector-shield');
  static String get firebaseMessagingSenderId =>
      _getEnv('FIREBASE_MESSAGING_SENDER_ID', '724662837533');
  static String get firebaseStorageBucket =>
      _getEnv('FIREBASE_STORAGE_BUCKET', 'vector-shield.appspot.com');

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
    return blynkTemplateId.isNotEmpty && blynkAuthToken.isNotEmpty;
  }

  // Debug method to print all config values (without sensitive data)
  static void debugPrintConfig() {
    if (kDebugMode) {
      print('=== AppConfig Values ===');
      print('Environment: ${isProduction ? 'Production' : 'Development'}');
      print('Running on: ${kIsWeb ? 'Web' : 'Native'}');
      print('FIREBASE_API_KEY: ${firebaseApiKey.isEmpty ? 'MISSING' : 'SET'}');
      print('FIREBASE_APP_ID: ${firebaseAppId.isEmpty ? 'MISSING' : 'SET'}');
      print('FIREBASE_PROJECT_ID: $firebaseProjectId');
      print('BLYNK_TEMPLATE_ID: $blynkTemplateId');
      print('BLYNK_AUTH_TOKEN: ${blynkAuthToken.isEmpty ? 'MISSING' : 'SET'}');
      print('=======================');
    }
  }
}
