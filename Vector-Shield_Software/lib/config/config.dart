import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

// Platform-specific imports
import '../platform/platform_imports.dart';

class AppConfig {
  // Static initialization flag to track if we've tried loading .env
  static bool _didTryLoadEnv = false;

  // Cache for environment variables to prevent repeated lookups
  static final Map<String, String> _envCache = {};

  // Method to initialize config - call this before accessing any values
  static Future<void> initialize() async {
    if (!_didTryLoadEnv) {
      try {
        // Try to load .env file on all platforms
        await dotenv.load(fileName: ".env").catchError((e) {
          print("Note: .env file not loaded: $e");
        });
      } catch (e) {
        print("Note: Error loading environment: $e");
        // Continue anyway, we'll use default values
      } finally {
        _didTryLoadEnv = true;
      }
    }
  }

  // Helper method to get environment variables with fallbacks
  static String _getEnv(String key, String fallback) {
    // First check cache to avoid repeated lookups
    if (_envCache.containsKey(key)) {
      final cachedValue = _envCache[key];
      if (cachedValue != null && cachedValue.isNotEmpty) {
        return cachedValue;
      }
    }

    // Then check dotenv
    final envValue = dotenv.env[key];
    if (envValue != null && envValue.isNotEmpty) {
      // Cache the value for future use
      _envCache[key] = envValue;
      return envValue;
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
      _getEnv('BLYNK_AUTH_TOKEN', '5VyqNitgoIiqWJynb38LQMgqtotgnj_M');
  static String get blynkBaseUrl =>
      _getEnv('BLYNK_BASE_URL', 'https://blynk.cloud/external/api');

  // Firebase configuration
  static String get firebaseApiKey =>
      _getEnv('FIREBASE_API_KEY', 'AIzaSyDS3Qwxu0gTG5i0inF8V2-jdeFFhch9PSQ');
  static String get firebaseAppId =>
      _getEnv('FIREBASE_APP_ID', '1:724662837533:web:b06b49441f6d55b9ba81f4');
  static String get firebaseProjectId =>
      _getEnv('FIREBASE_PROJECT_ID', 'vector-shield');
  static String get firebaseMessagingSenderId =>
      _getEnv('FIREBASE_MESSAGING_SENDER_ID', '724662837533');
  static String get firebaseStorageBucket =>
      _getEnv('FIREBASE_STORAGE_BUCKET', 'vector-shield.appspot.com');

  // Location permission status - improved platform-safe implementation
  static bool get hasLocationPermission {
    if (kIsWeb) {
      try {
        return PlatformSpecific.getLocationPermission();
      } catch (e) {
        print("Error checking location permission: $e");
        return false;
      }
    }
    return false;
  }

  // Method to request location permission - improved platform-safe implementation
  static Future<bool> requestLocationPermission() async {
    if (kIsWeb) {
      try {
        return await PlatformSpecific.requestLocationPermission();
      } catch (e) {
        print("Error requesting location permission: $e");
        return false;
      }
    }
    return false;
  }

  // Method to check if running on iOS Safari
  static bool get isIOSSafari {
    if (kIsWeb) {
      try {
        return PlatformSpecific.isIOSSafari();
      } catch (e) {
        print("Error checking if iOS Safari: $e");
        return false;
      }
    }
    return false;
  }

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

  // Method to check if running on mobile browser
  static bool get isMobileBrowser {
    if (kIsWeb) {
      try {
        return PlatformSpecific.isMobileBrowser();
      } catch (e) {
        print("Error checking if mobile browser: $e");
        return false;
      }
    }
    return false;
  }

  // Debug method to print all config values (without sensitive data)
  static void debugPrintConfig() {
    if (kDebugMode) {
      print('=== AppConfig Values ===');
      print('Environment: ${isProduction ? 'Production' : 'Development'}');
      print('Running on: ${kIsWeb ? 'Web' : 'Native'}');
      if (kIsWeb) {
        print('Browser type: ${isMobileBrowser ? 'Mobile' : 'Desktop'}');
        print('iOS Safari: ${isIOSSafari ? 'Yes' : 'No'}');
      }
      print('FIREBASE_API_KEY: ${firebaseApiKey.isEmpty ? 'MISSING' : 'SET'}');
      print('FIREBASE_APP_ID: ${firebaseAppId.isEmpty ? 'MISSING' : 'SET'}');
      print('FIREBASE_PROJECT_ID: $firebaseProjectId');
      print('BLYNK_TEMPLATE_ID: $blynkTemplateId');
      print('BLYNK_AUTH_TOKEN: ${blynkAuthToken.isEmpty ? 'MISSING' : 'SET'}');
      print('=======================');
    }
  }

}
