import 'package:flutter/foundation.dart';

// Conditional import: web vs mobile
import 'platform_web.dart' if (dart.library.io) 'platform_mobile.dart';

class PlatformSpecific {
  static void openUrlInBrowser(String url) {
    PlatformImplementation.openUrlInBrowser(url);
  }

  static bool checkNetworkConnectivity() {
    return PlatformImplementation.checkNetworkConnectivity();
  }

  static void logToConsole(String message) {
    if (kIsWeb) {
      PlatformImplementation.logToConsole(message);
    } else {
      print(message);
    }
  }

  static bool isMobileBrowser() {
    if (kIsWeb) {
      return PlatformImplementation.isMobileBrowser();
    }
    return false;
  }

  static bool getLocationPermission() {
    if (kIsWeb) {
      return PlatformImplementation.getLocationPermission();
    }
    return false;
  }

  static Future<bool> requestLocationPermission() async {
    if (kIsWeb) {
      return await PlatformImplementation.requestLocationPermission();
    }
    return false;
  }

  static void initializeMap(String elementId, double lat, double lng, String title) {
    if (kIsWeb) {
      PlatformImplementation.initializeMap(elementId, lat, lng, title);
    }
  }

  static bool isIOSSafari() {
    if (kIsWeb) {
      return PlatformImplementation.isIOSSafari();
    }
    return false;
  }
}
