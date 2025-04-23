// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;

// Web-specific implementation
class PlatformImplementation {
  static void openUrlInBrowser(String url) {
    try {
      // Check if we're on iOS Safari
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      final isIOSSafari = userAgent.contains('iphone') || 
                          userAgent.contains('ipad') || 
                          userAgent.contains('ipod');
      
      if (isIOSSafari) {
        // For iOS Safari, use a direct approach
        html.window.location.href = url;
      } else {
        // Use the custom JavaScript function defined in index.html
        js.context.callMethod('openExternalUrl', [url]);
      }
    } catch (e) {
      print("Error opening URL: $e");
      // Fallback to standard window.open
      try {
        html.window.open(url, '_blank');
      } catch (e2) {
        print("Fallback error opening URL: $e2");
        // Last resort - direct navigation
        html.window.location.href = url;
      }
    }
  }
  
  // Add a method to check network connectivity on web
  static bool checkNetworkConnectivity() {
    try {
      // Convert bool? to bool with a default value of false
      return html.window.navigator.onLine ?? false;
    } catch (e) {
      print("Error checking network connectivity: $e");
      return false;
    }
  }
  
  // Add a method to log to console for debugging
  static void logToConsole(String message) {
    try {
      js.context.callMethod('console.log', [message]);
    } catch (e) {
      print("Error logging to console: $e");
    }
  }
  
  // Add a method to check if running on mobile browser
  static bool isMobileBrowser() {
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return userAgent.contains('mobile') || 
             userAgent.contains('android') || 
             userAgent.contains('iphone') || 
             userAgent.contains('ipad');
    } catch (e) {
      print("Error detecting mobile browser: $e");
      return false;
    }
  }

  static bool isIOSSafari() {
  final userAgent = html.window.navigator.userAgent.toLowerCase();
  return (userAgent.contains('iphone') ||
          userAgent.contains('ipad') ||
          userAgent.contains('ipod')) &&
      userAgent.contains('safari');
}

  
  // Add a method to get location permission status
  static bool getLocationPermission() {
    try {
      // Call the JavaScript function defined in index.html
      final result = js.context.callMethod('getLocationPermission');
      return result == true;
    } catch (e) {
      print("Error getting location permission: $e");
      return false;
    }
  }
  
  // Add a method to request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      // Call the JavaScript function defined in index.html
      js.context.callMethod('requestLocationPermission');
      
      // Wait a bit for the permission dialog to be handled
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if permission was granted
      return getLocationPermission();
    } catch (e) {
      print("Error requesting location permission: $e");
      return false;
    }
  }
  
  // Add a method to initialize a map
  static void initializeMap(String elementId, double lat, double lng, String title) {
    try {
      // Call the JavaScript function defined in index.html
      js.context.callMethod('initializeMap', [elementId, lat, lng, title]);
    } catch (e) {
      print("Error initializing map: $e");
    }
  }
}