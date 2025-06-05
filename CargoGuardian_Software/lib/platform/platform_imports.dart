import 'package:flutter/foundation.dart';

// Import the appropriate platform implementation
import 'platform_stub.dart'
    if (dart.library.html) 'platform_web.dart'
    if (dart.library.io) 'platform_mobile.dart';

// Re-export PlatformUtils from the appropriate implementation
export 'platform_stub.dart'
    if (dart.library.html) 'platform_web.dart'
    if (dart.library.io) 'platform_mobile.dart';

class PlatformSpecific {
  static void openUrlInBrowser(String url) {
    try {
      PlatformImplementation.openUrlInBrowser(url);
    } catch (e) {
      print("Error opening URL in browser: $e");
    }
  }

  static bool checkNetworkConnectivity() {
    try {
      return PlatformImplementation.checkNetworkConnectivity();
    } catch (e) {
      print("Error checking network connectivity: $e");
      return false;
    }
  }

  static void logToConsole(String message) {
    try {
      if (kIsWeb) {
        PlatformImplementation.logToConsole(message);
      } else {
        if (kDebugMode) {
          print(message);
        }
      }
    } catch (e) {
      print("Error logging to console: $e");
    }
  }

  static bool isMobileBrowser() {
    try {
      if (kIsWeb) {
        return PlatformImplementation.isMobileBrowser();
      }
      return false;
    } catch (e) {
      print("Error detecting mobile browser: $e");
      return false;
    }
  }

  static bool getLocationPermission() {
    try {
      if (kIsWeb) {
        return PlatformImplementation.getLocationPermission();
      }
      return false;
    } catch (e) {
      print("Error getting location permission: $e");
      return false;
    }
  }

  static Future<bool> requestLocationPermission() async {
    try {
      if (kIsWeb) {
        return await PlatformImplementation.requestLocationPermission();
      }
      return false;
    } catch (e) {
      print("Error requesting location permission: $e");
      return false;
    }
  }

  static void initializeMap(String elementId, double lat, double lng, String title) {
    try {
      if (kIsWeb) {
        PlatformImplementation.initializeMap(elementId, lat, lng, title);
      }
    } catch (e) {
      print("Error initializing map: $e");
    }
  }

  static bool isIOSSafari() {
    try {
      if (kIsWeb) {
        return PlatformImplementation.isIOSSafari();
      }
      return false;
    } catch (e) {
      print("Error detecting iOS Safari: $e");
      return false;
    }
  }
}

// This class is just for documentation purposes
class PlatformInfo {
  final bool isMobileBrowser;
  final bool isIOSSafari;
  final bool isStandalone;
  final String userAgent;

  PlatformInfo({
    required this.isMobileBrowser,
    required this.isIOSSafari,
    required this.isStandalone,
    required this.userAgent,
  });
}
