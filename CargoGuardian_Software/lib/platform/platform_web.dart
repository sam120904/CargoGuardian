// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:async';

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

// Web-specific implementation with enhanced null safety and testing support
class PlatformImplementation {
  static void openUrlInBrowser(String url) {
    try {
      // Safe user agent check with null safety
      final userAgent = html.window.navigator.userAgent?.toLowerCase() ?? '';
      final isIOSSafari = userAgent.contains('iphone') || 
                          userAgent.contains('ipad') || 
                          userAgent.contains('ipod');
      
      if (isIOSSafari) {
        // For iOS Safari, use a direct approach
        html.window.location.href = url;
      } else {
        // Use the custom JavaScript function defined in index.html
        if (js.context.hasProperty('openExternalUrl')) {
          js.context.callMethod('openExternalUrl', [url]);
        } else {
          // Fallback if function doesn't exist
          html.window.open(url, '_blank');
        }
      }
    } catch (e) {
      print("Error opening URL: $e");
      // Fallback to standard window.open
      try {
        html.window.open(url, '_blank');
      } catch (e2) {
        print("Fallback error opening URL: $e2");
        // Last resort - direct navigation
        try {
          html.window.location.href = url;
        } catch (e3) {
          print("Final fallback error: $e3");
        }
      }
    }
  }
  
  // Enhanced network connectivity check with null safety
  static bool checkNetworkConnectivity() {
    try {
      // Safe null check for navigator.onLine
      final navigator = html.window.navigator;
      if (navigator.onLine != null) {
        return navigator.onLine!;
      }
      return false;
    } catch (e) {
      print("Error checking network connectivity: $e");
      return false;
    }
  }
  
  // Safe console logging
  static void logToConsole(String message) {
    try {
      if (js.context.hasProperty('console')) {
        js.context.callMethod('console.log', [message]);
      }
    } catch (e) {
      print("Error logging to console: $e");
    }
  }
  
  // Enhanced mobile browser detection with null safety
  static bool isMobileBrowser() {
    try {
      final userAgent = html.window.navigator.userAgent?.toLowerCase() ?? '';
      return userAgent.contains('mobile') || 
             userAgent.contains('android') || 
             userAgent.contains('iphone') || 
             userAgent.contains('ipad');
    } catch (e) {
      print("Error detecting mobile browser: $e");
      return false;
    }
  }

  // Enhanced iOS Safari detection with null safety
  static bool isIOSSafari() {
    try {
      final userAgent = html.window.navigator.userAgent?.toLowerCase() ?? '';
      final platform = html.window.navigator.platform?.toLowerCase() ?? '';
      
      final isIOS = userAgent.contains('iphone') ||
                    userAgent.contains('ipad') ||
                    userAgent.contains('ipod') ||
                    platform.contains('iphone') ||
                    platform.contains('ipad') ||
                    platform.contains('ipod');
      
      final isSafari = userAgent.contains('safari') && 
                       !userAgent.contains('chrome') && 
                       !userAgent.contains('crios') &&
                       !userAgent.contains('fxios');
      
      return isIOS && isSafari;
    } catch (e) {
      print("Error detecting iOS Safari: $e");
      return false;
    }
  }
  
  // Safe location permission check
  static bool getLocationPermission() {
    try {
      // Call the JavaScript function defined in index.html
      if (js.context.hasProperty('getLocationPermission')) {
        final result = js.context.callMethod('getLocationPermission');
        return result == true;
      }
      return false;
    } catch (e) {
      print("Error getting location permission: $e");
      return false;
    }
  }
  
  // Safe location permission request
  static Future<bool> requestLocationPermission() async {
    try {
      // Call the JavaScript function defined in index.html
      if (js.context.hasProperty('requestLocationPermission')) {
        js.context.callMethod('requestLocationPermission');
        
        // Wait a bit for the permission dialog to be handled
        await Future.delayed(const Duration(seconds: 2));
        
        // Check if permission was granted
        return getLocationPermission();
      }
      return false;
    } catch (e) {
      print("Error requesting location permission: $e");
      return false;
    }
  }
  
  // Safe map initialization
  static void initializeMap(String elementId, double lat, double lng, String title) {
    try {
      // Call the JavaScript function defined in index.html
      if (js.context.hasProperty('initializeMap')) {
        js.context.callMethod('initializeMap', [elementId, lat, lng, title]);
      } else {
        print("initializeMap function not available");
      }
    } catch (e) {
      print("Error initializing map: $e");
    }
  }

  // NEW: Console command checking for testing mode
  static void checkConsoleCommands(Function(String) onCommand) {
    try {
      // Check if there are any console commands stored
      final command = html.window.localStorage['console_command'];
      if (command != null && command.isNotEmpty) {
        onCommand(command);
        // Clear the command after processing
        html.window.localStorage.remove('console_command');
      }
    } catch (e) {
      // Silently handle errors - console listener is optional
    }
  }

  // NEW: Set up console command listener
  static void setupConsoleListener() {
    try {
      // Add JavaScript function to handle console commands
      js.context['setTestMode'] = (String mode) {
        html.window.localStorage['console_command'] = mode;
      };
      
      // Add console functions for easy access
      js.context.callMethod('eval', ['''
        // CargoGuardian Testing Commands
        window.TEST_ON = function() {
          window.setTestMode('TEST ON');
          console.log('🧪 TEST MODE ENABLED - Switching to simulated data');
          console.log('📊 Simulated device is now ONLINE with realistic weight data');
          console.log('💡 Type TEST_OFF() to return to real hardware data');
        };
        
        window.TEST_OFF = function() {
          window.setTestMode('TEST OFF');
          console.log('🔌 TEST MODE DISABLED - Switching to real hardware data');
          console.log('📡 Connecting to actual IoT device...');
        };
        
        // Also support string commands
        window.addEventListener('keydown', function(e) {
          if (e.ctrlKey && e.shiftKey && e.key === 'T') {
            console.log('CargoGuardian Testing Commands:');
            console.log('- Type TEST_ON() to enable simulation mode');
            console.log('- Type TEST_OFF() to disable simulation mode');
            console.log('- Or use Ctrl+Shift+T to see this help');
          }
        });
        
        console.log('🚀 CargoGuardian Testing Mode Available!');
        console.log('📋 Available Commands:');
        console.log('   • TEST_ON()  - Enable simulation mode');
        console.log('   • TEST_OFF() - Disable simulation mode');
        console.log('   • Ctrl+Shift+T - Show this help');
        console.log('');
        console.log('💡 Default mode: REAL DATA (TEST OFF)');
      ''']);
    } catch (e) {
      print("Error setting up console listener: $e");
    }
  }
}

class PlatformUtils {
  // Detect platform details
  static Future<PlatformInfo> detectPlatform() async {
    final userAgent = html.window.navigator.userAgent?.toLowerCase() ?? '';
    final platform = html.window.navigator.platform?.toLowerCase() ?? '';
    
    // Check for mobile browser
    final isMobileBrowser = userAgent.contains('mobile') ||
        userAgent.contains('android') ||
        userAgent.contains('iphone') ||
        userAgent.contains('ipad');
    
    // Check for iOS Safari
    final isIOS = userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod') ||
        platform.contains('iphone') ||
        platform.contains('ipad') ||
        platform.contains('ipod');
    
    final isSafari = userAgent.contains('safari') && 
        !userAgent.contains('chrome') && 
        !userAgent.contains('crios') &&
        !userAgent.contains('fxios');
    
    final isIOSSafari = isIOS && isSafari;
    
    // Check for standalone mode
    bool isStandalone = false;
    
    try {
      // Method 1: Use JavaScript interop safely
      if (js.context.hasProperty('navigator')) {
        final navigator = js.context['navigator'];
        if (navigator != null && navigator.hasProperty('standalone')) {
          final standaloneValue = navigator['standalone'];
          if (standaloneValue != null) {
            isStandalone = standaloneValue == true;
          }
        }
      }
      
      // Method 2: Use media query with null safety
      try {
        final mediaQuery = html.window.matchMedia('(display-mode: standalone)');
        if (mediaQuery.matches) {
          isStandalone = true;
        }
      } catch (e) {
        print("Media query check failed: $e");
      }
    } catch (e) {
      print("Error checking standalone mode: $e");
    }
    
    return PlatformInfo(
      isMobileBrowser: isMobileBrowser,
      isIOSSafari: isIOSSafari,
      isStandalone: isStandalone,
      userAgent: userAgent,
    );
  }
  
  // Set viewport height for iOS Safari
  static void setIOSViewportHeight() {
    try {
      final innerHeight = html.window.innerHeight;
      if (innerHeight != null) {
        final vh = innerHeight * 0.01;
        html.document.documentElement?.style.setProperty('--vh', '${vh}px');
      }
    } catch (e) {
      print("Error setting viewport height: $e");
    }
  }
  
  // Setup iOS Safari events
  static void setupIOSSafariEvents() {
    try {
      // Handle orientation changes with null safety
      html.window.addEventListener('orientationchange', (event) {
        Timer(const Duration(milliseconds: 500), () {
          setIOSViewportHeight();
        });
      });
      
      // Handle resize events with null safety
      html.window.addEventListener('resize', (event) {
        Timer(const Duration(milliseconds: 100), () {
          setIOSViewportHeight();
        });
      });
    } catch (e) {
      print("Error setting up iOS Safari events: $e");
    }
  }
  
  // Reload page
  static void reloadPage() {
    try {
      html.window.location.reload();
    } catch (e) {
      print("Error reloading page: $e");
    }
  }
}
