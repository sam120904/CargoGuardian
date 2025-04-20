import 'package:flutter/foundation.dart';

// Platform-specific imports
import 'platform_web.dart' if (dart.library.io) 'platform_mobile.dart';

// This class is a facade for platform-specific implementations
class PlatformSpecific {
  // Open URL in browser - implementation differs between web and mobile
  static void openUrlInBrowser(String url) {
    PlatformImplementation.openUrlInBrowser(url);
  }
  
  // Check network connectivity - implementation differs between web and mobile
  static bool checkNetworkConnectivity() {
    return PlatformImplementation.checkNetworkConnectivity();
  }
  
  // Log to console for debugging
  static void logToConsole(String message) {
    if (kIsWeb) {
      PlatformImplementation.logToConsole(message);
    } else {
      print(message);
    }
  }
  
  // Check if running on mobile browser
  static bool isMobileBrowser() {
    if (kIsWeb) {
      return PlatformImplementation.isMobileBrowser();
    }
    return false;
  }
  
  // Get location permission status
  static bool getLocationPermission() {
    if (kIsWeb) {
      return PlatformImplementation.getLocationPermission();
    }
    return false;
  }
  
  // Request location permission
  static Future<bool> requestLocationPermission() async {
    if (kIsWeb) {
      return await PlatformImplementation.requestLocationPermission();
    }
    return false;
  }
  
  // Initialize a map
  static void initializeMap(String elementId, double lat, double lng, String title) {
    if (kIsWeb) {
      PlatformImplementation.initializeMap(elementId, lat, lng, title);
    }
  }
}