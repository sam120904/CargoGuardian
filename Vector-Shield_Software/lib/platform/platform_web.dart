// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;

// Web-specific implementation
class PlatformImplementation {
  static void openUrlInBrowser(String url) {
    // Use dart:html to open URL in a new tab
    html.window.open(url, '_blank');
  }
  
  // Add a method to check network connectivity on web
  static bool checkNetworkConnectivity() {
    // Convert bool? to bool with a default value of false
    return html.window.navigator.onLine ?? false;
  }
  
  // Add a method to log to console for debugging
  static void logToConsole(String message) {
    js.context.callMethod('console.log', [message]);
  }
}
