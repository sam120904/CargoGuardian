import 'dart:html' as html;

// Web-specific implementation
class PlatformImplementation {
  static void openUrlInBrowser(String url) {
    // Use dart:html to open URL in a new tab
    html.window.open(url, '_blank');
  }
}