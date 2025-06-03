import 'package:flutter/foundation.dart';

class AppConfig {
  // Enhanced null safety for configuration
  static String? _apiKey;
  static String? _authDomain;
  static String? _projectId;
  static String? _storageBucket;
  static String? _messagingSenderId;
  static String? _appId;
  static String? _blynkToken;
  static String? _googleMapsApiKey;

  // Add this for location permission state
  static bool _hasLocationPermission = false;

  // Getters with null safety and fallbacks
  static String get apiKey => _apiKey ?? '';
  static String get authDomain => _authDomain ?? '';
  static String get projectId => _projectId ?? '';
  static String get storageBucket => _storageBucket ?? '';
  static String get messagingSenderId => _messagingSenderId ?? '';
  static String get appId => _appId ?? '';
  static String get blynkToken => _blynkToken ?? '';
  static String get googleMapsApiKey => _googleMapsApiKey ?? '';

  static bool get hasLocationPermission => _hasLocationPermission;

  static set hasLocationPermission(bool value) {
    _hasLocationPermission = value;
  }

  static Future<bool> requestLocationPermission() async {
    // Simulate requesting permission (for web)
    await Future.delayed(const Duration(milliseconds: 500));
    _hasLocationPermission = true;
    return true;
  }

  static Future<void> initialize() async {
    try {
      // Enhanced initialization with null safety
      if (kIsWeb) {
        // Web-specific configuration with fallbacks
        _initializeWebConfig();
      } else {
        // Mobile-specific configuration
        _initializeMobileConfig();
      }

      print("AppConfig initialized successfully");
    } catch (e) {
      print("Error initializing AppConfig: $e");
      // Set default values if initialization fails
      _setDefaultValues();
    }
  }

  static void _initializeWebConfig() {
    try {
      // Web configuration with null safety
      _apiKey = const String.fromEnvironment(
        'FIREBASE_API_KEY',
        defaultValue: 'AIzaSyDS3Qwxu0gTG5i0inF8V2-jdeFFhch9PSQ',
      );
      _authDomain = const String.fromEnvironment(
        'FIREBASE_AUTH_DOMAIN',
        defaultValue: 'cargoguardian-iot.firebaseapp.com',
      );
      _projectId = const String.fromEnvironment(
        'FIREBASE_PROJECT_ID',
        defaultValue: 'cargoguardian-iot',
      );
      _storageBucket = const String.fromEnvironment(
        'FIREBASE_STORAGE_BUCKET',
        defaultValue: 'cargoguardian-iot.appspot.com',
      );
      _messagingSenderId = const String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
        defaultValue: '123456789',
      );
      _appId = const String.fromEnvironment(
        'FIREBASE_APP_ID',
        defaultValue: '1:123456789:web:abcdef',
      );
      _blynkToken = const String.fromEnvironment(
        'BLYNK_TOKEN',
        defaultValue: 'your-blynk-token',
      );
      _googleMapsApiKey = const String.fromEnvironment(
        'GOOGLE_MAPS_API_KEY',
        defaultValue: 'AIzaSyDS3Qwxu0gTG5i0inF8V2-jdeFFhch9PSQ',
      );
    } catch (e) {
      print("Error in web config initialization: $e");
      _setDefaultValues();
    }
  }

  static void _initializeMobileConfig() {
    try {
      // Mobile configuration with null safety
      _apiKey = const String.fromEnvironment(
        'FIREBASE_API_KEY',
        defaultValue: 'AIzaSyDS3Qwxu0gTG5i0inF8V2-jdeFFhch9PSQ',
      );
      _authDomain = const String.fromEnvironment(
        'FIREBASE_AUTH_DOMAIN',
        defaultValue: 'cargoguardian-iot.firebaseapp.com',
      );
      _projectId = const String.fromEnvironment(
        'FIREBASE_PROJECT_ID',
        defaultValue: 'cargoguardian-iot',
      );
      _storageBucket = const String.fromEnvironment(
        'FIREBASE_STORAGE_BUCKET',
        defaultValue: 'cargoguardian-iot.appspot.com',
      );
      _messagingSenderId = const String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
        defaultValue: '123456789',
      );
      _appId = const String.fromEnvironment(
        'FIREBASE_APP_ID',
        defaultValue: '1:123456789:android:abcdef',
      );
      _blynkToken = const String.fromEnvironment(
        'BLYNK_TOKEN',
        defaultValue: 'your-blynk-token',
      );
      _googleMapsApiKey = const String.fromEnvironment(
        'GOOGLE_MAPS_API_KEY',
        defaultValue: 'AIzaSyDS3Qwxu0gTG5i0inF8V2-jdeFFhch9PSQ',
      );
    } catch (e) {
      print("Error in mobile config initialization: $e");
      _setDefaultValues();
    }
  }

  static void _setDefaultValues() {
    // Fallback default values
    _apiKey ??= 'AIzaSyDS3Qwxu0gTG5i0inF8V2-jdeFFhch9PSQ';
    _authDomain ??= 'cargoguardian-iot.firebaseapp.com';
    _projectId ??= 'cargoguardian-iot';
    _storageBucket ??= 'cargoguardian-iot.appspot.com';
    _messagingSenderId ??= '123456789';
    _appId ??= kIsWeb ? '1:123456789:web:abcdef' : '1:123456789:android:abcdef';
    _blynkToken ??= 'your-blynk-token';
    _googleMapsApiKey ??= 'AIzaSyDS3Qwxu0gTG5i0inF8V2-jdeFFhch9PSQ';
  }

  static void debugPrintConfig() {
    if (kDebugMode) {
      try {
        print("=== AppConfig Debug Info ===");
        print("API Key: ${_apiKey?.isNotEmpty == true ? 'Set' : 'Not set'}");
        print("Auth Domain: ${_authDomain ?? 'Not set'}");
        print("Project ID: ${_projectId ?? 'Not set'}");
        print("Storage Bucket: ${_storageBucket ?? 'Not set'}");
        print("Messaging Sender ID: ${_messagingSenderId ?? 'Not set'}");
        print("App ID: ${_appId ?? 'Not set'}");
        print(
          "Blynk Token: ${_blynkToken?.isNotEmpty == true ? 'Set' : 'Not set'}",
        );
        print(
          "Google Maps API Key: ${_googleMapsApiKey?.isNotEmpty == true ? 'Set' : 'Not set'}",
        );
        print("Platform: ${kIsWeb ? 'Web' : 'Mobile'}");
        print("=== End Config Debug ===");
      } catch (e) {
        print("Error printing debug config: $e");
      }
    }
  }

  // Validation methods with null safety
  static bool get isConfigValid {
    try {
      return _apiKey?.isNotEmpty == true &&
          _authDomain?.isNotEmpty == true &&
          _projectId?.isNotEmpty == true &&
          _appId?.isNotEmpty == true;
    } catch (e) {
      print("Error validating config: $e");
      return false;
    }
  }

  static List<String> get missingConfigs {
    final missing = <String>[];
    try {
      if (_apiKey?.isEmpty != false) missing.add('API Key');
      if (_authDomain?.isEmpty != false) missing.add('Auth Domain');
      if (_projectId?.isEmpty != false) missing.add('Project ID');
      if (_appId?.isEmpty != false) missing.add('App ID');
    } catch (e) {
      print("Error checking missing configs: $e");
      missing.add('Error checking configuration');
    }
    return missing;
  }
}
