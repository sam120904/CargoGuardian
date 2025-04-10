import 'package:flutter/foundation.dart';

// Platform-specific imports
import 'platform_web.dart' if (dart.library.io) 'platform_mobile.dart';

// This class is a facade for platform-specific implementations
class PlatformSpecific {
  // Open URL in browser - implementation differs between web and mobile
  static void openUrlInBrowser(String url) {
    if (kIsWeb) {
      // Call the web implementation
      PlatformImplementation.openUrlInBrowser(url);
    } else {
      // For mobile, we'll use url_launcher directly in the calling code
      // This is just a placeholder to maintain the API
      print('Using url_launcher for mobile');
    }
  }
}
