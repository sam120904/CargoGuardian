import 'package:url_launcher/url_launcher.dart';

// Mobile-specific implementation
class PlatformImplementation {
  static void openUrlInBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }

  static bool checkNetworkConnectivity() {
    // Placeholder: use `connectivity_plus` for real check
    return true;
  }

  static void logToConsole(String message) {
    print(message);
  }

  static bool isMobileBrowser() {
    // Native mobile apps are not mobile browsers
    return false;
  }

  static bool getLocationPermission() {
    // Not implemented - needs a location plugin
    return false;
  }

  static Future<bool> requestLocationPermission() async {
    // Not implemented - needs a location plugin
    return false;
  }

  static void initializeMap(String elementId, double lat, double lng, String title) {
    // Maps not supported in this way on mobile
  }

  static bool isIOSSafari() {
    // Not applicable on mobile
    return false;
  }
}
