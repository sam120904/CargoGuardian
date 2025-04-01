import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

// Conditionally import dart:js only for web
import 'dart:js_util' if (dart.library.html) 'dart:js_util' as js_util;

class AppConfig {
  // Static initialization flag to track if we've tried loading .env
  static bool _didTryLoadEnv = false;
  static bool _didTryLoadJsEnv = false;

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

    // For web, try to load environment variables from JavaScript
    if (kIsWeb && !_didTryLoadJsEnv) {
      try {
        _loadJsEnvironmentVariables();
      } catch (e) {
        print("Error loading JS environment variables: $e");
      } finally {
        _didTryLoadJsEnv = true;
      }
    }
  }

  // Load environment variables from JavaScript (injected by Vercel)
  static void _loadJsEnvironmentVariables() {
    if (kIsWeb) {
      try {
        // Check if window object has our environment variables
        final firebaseApiKey = _getJsEnv('FIREBASE_API_KEY');
        if (firebaseApiKey != null && firebaseApiKey.isNotEmpty) {
          print("Successfully loaded environment variables from JavaScript");
        }
      } catch (e) {
        print("Error accessing JavaScript environment variables: $e");
      }
    }
  }

  // Helper to get environment variable from JavaScript
  static String? _getJsEnv(String key) {
    if (kIsWeb) {
      try {
        // Use a safe approach to access JS variables
        return _getJsProperty(key);
      } catch (e) {
        print("Error getting $key from JS: $e");
      }
    }
    return null;
  }

  // Safe method to get JS property that works on both web and mobile
  static String? _getJsProperty(String key) {
    if (kIsWeb) {
      try {
        // This is a safe way to check if we're on web and can access JS
        return _callJsMethod('getEnvVar', [key]);
      } catch (e) {
        print("JS access error: $e");
      }
    }
    return null;
  }

  // Safe method to call JS methods that works on both web and mobile
  static dynamic _callJsMethod(String method, List<dynamic> args) {
    if (kIsWeb) {
      try {
        // Use js_util instead of dart:js directly
        return js_util.callMethod(js_util.globalThis, method, args);
      } catch (e) {
        print("JS method call error: $e");
      }
    }
    return null;
  }

  // Helper method to get environment variables with fallbacks
  static String _getEnv(String key, String fallback) {
    // First check if we're on web and can get from JavaScript
    if (kIsWeb) {
      final jsValue = _getJsEnv(key);
      if (jsValue != null && jsValue.isNotEmpty && jsValue != "%$key%") {
        return jsValue;
      }
    }

    // Then check dotenv
    final envValue = dotenv.env[key];
    if (envValue != null && envValue.isNotEmpty) {
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

  // Location permission status
  static bool get hasLocationPermission {
    if (kIsWeb) {
      try {
        final hasPermission = _callJsMethod('getLocationPermission', []);
        if (hasPermission != null) {
          return hasPermission as bool;
        }
      } catch (e) {
        print("Error checking location permission: $e");
      }
    }
    return false;
  }

  // Method to request location permission
  static Future<bool> requestLocationPermission() async {
    if (kIsWeb) {
      try {
        final completer = Completer<bool>();
        
        // Use JavaScript to request location permission
        _callJsMethod('requestLocationPermission', []);
        
        // Wait a bit for the permission dialog to be handled
        await Future.delayed(const Duration(seconds: 2));
        
        // Check if permission was granted
        final hasPermission = _callJsMethod('getLocationPermission', []);
        if (hasPermission != null && hasPermission as bool) {
          completer.complete(true);
        } else {
          completer.complete(false);
        }
        
        return completer.future;
      } catch (e) {
        print("Error requesting location permission: $e");
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

