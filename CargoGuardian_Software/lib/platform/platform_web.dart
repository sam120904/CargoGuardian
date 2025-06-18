// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:async';
import 'package:flutter/material.dart';

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
      final userAgent = html.window.navigator.userAgent.toLowerCase();
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

  // Enhanced iOS Safari detection with null safety
  static bool isIOSSafari() {
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
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

  // Console command checking for testing mode
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

  // Set up console command listener
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

        // Support for string commands
        window.testMode = function(command) {
          if (command === 'ON' || command === 'on') {
            window.TEST_ON();
          } else if (command === 'off' || command === 'OFF') {
            window.TEST_OFF();
          } else {
            console.log('❌ Invalid command. Use: testMode("ON") or testMode("OFF")');
            console.log('💡 Or use: TEST_ON() and TEST_OFF()');
          }
        };

        // Also support string commands directly
        window.addEventListener('keydown', function(e) {
          if (e.ctrlKey && e.shiftKey && e.key === 'T') {
            console.log('🚀 CargoGuardian Testing Commands:');
            console.log('📋 Function Commands:');
            console.log('   • TEST_ON()  - Enable simulation mode');
            console.log('   • TEST_OFF() - Disable simulation mode');
            console.log('📋 String Commands:');
            console.log('   • testMode("ON")  - Enable simulation mode');
            console.log('   • testMode("OFF") - Disable simulation mode');
            console.log('   • Ctrl+Shift+T - Show this help');
          }
        });

        console.log('🚀 CargoGuardian Testing Mode Available!');
        console.log('📋 Available Commands:');
        console.log('   Function Commands:');
        console.log('   • TEST_ON()  - Enable simulation mode');
        console.log('   • TEST_OFF() - Disable simulation mode');
        console.log('   String Commands:');
        console.log('   • testMode("ON")  - Enable simulation mode');
        console.log('   • testMode("OFF") - Disable simulation mode');
        console.log('   • Ctrl+Shift+T - Show this help');
        console.log('');
        console.log('💡 Default mode: REAL DATA (TEST OFF)');
      ''']);
    } catch (e) {
      print("Error setting up console listener: $e");
    }
  }

  // NEW: Register actual tile-based map view
  static void registerMapView(String viewType, double lat, double lng, VoidCallback onMapClick) {
    try {
      // Register a real tile-based map view
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        // Create main map container
        final mapContainer = html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'relative'
          ..style.overflow = 'hidden'
          ..style.backgroundColor = '#f0f8ff';

        // Create the actual map using Leaflet-style tile approach
        final mapDiv = html.DivElement()
          ..id = 'map-$viewId'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'relative'
          ..style.cursor = 'pointer';

        // Add the map initialization script
        final script = html.ScriptElement()
          ..text = '''
            (function() {
              const mapDiv = document.getElementById('map-$viewId');
              if (!mapDiv) return;
              
              // Calculate tile coordinates for the given lat/lng
              const zoom = 15;
              const lat = $lat;
              const lng = $lng;
              
              // Convert lat/lng to tile coordinates
              function deg2num(lat_deg, lon_deg, zoom) {
                const lat_rad = lat_deg * Math.PI / 180.0;
                const n = Math.pow(2.0, zoom);
                const xtile = Math.floor((lon_deg + 180.0) / 360.0 * n);
                const ytile = Math.floor((1.0 - Math.asinh(Math.tan(lat_rad)) / Math.PI) / 2.0 * n);
                return [xtile, ytile];
              }
              
              const [centerX, centerY] = deg2num(lat, lng, zoom);
              
              // Create a 3x3 grid of tiles centered on our location
              const tileSize = 256;
              const gridSize = 3;
              const startX = centerX - Math.floor(gridSize / 2);
              const startY = centerY - Math.floor(gridSize / 2);
              
              // Clear any existing content
              mapDiv.innerHTML = '';
              
              // Create tiles container
              const tilesContainer = document.createElement('div');
              tilesContainer.style.position = 'relative';
              tilesContainer.style.width = (gridSize * tileSize) + 'px';
              tilesContainer.style.height = (gridSize * tileSize) + 'px';
              tilesContainer.style.left = '50%';
              tilesContainer.style.top = '50%';
              tilesContainer.style.transform = 'translate(-50%, -50%)';
              
              // Add tiles
              for (let i = 0; i < gridSize; i++) {
                for (let j = 0; j < gridSize; j++) {
                  const tileX = startX + i;
                  const tileY = startY + j;
                  
                  const tile = document.createElement('img');
                  tile.src = `https://tile.openstreetmap.org/\${zoom}/\${tileX}/\${tileY}.png`;
                  tile.style.position = 'absolute';
                  tile.style.left = (i * tileSize) + 'px';
                  tile.style.top = (j * tileSize) + 'px';
                  tile.style.width = tileSize + 'px';
                  tile.style.height = tileSize + 'px';
                  tile.style.border = 'none';
                  tile.style.display = 'block';
                  
                  // Add loading placeholder
                  tile.style.backgroundColor = '#e0e0e0';
                  
                  // Handle tile load errors
                  tile.onerror = function() {
                    this.style.backgroundColor = '#f0f0f0';
                    this.style.display = 'flex';
                    this.style.alignItems = 'center';
                    this.style.justifyContent = 'center';
                    this.innerHTML = '<div style="color: #666; font-size: 12px;">Map tile unavailable</div>';
                  };
                  
                  tilesContainer.appendChild(tile);
                }
              }
              
              // Add location marker
              const marker = document.createElement('div');
              marker.innerHTML = '📍';
              marker.style.position = 'absolute';
              marker.style.left = '50%';
              marker.style.top = '50%';
              marker.style.transform = 'translate(-50%, -50%)';
              marker.style.fontSize = '24px';
              marker.style.zIndex = '1000';
              marker.style.filter = 'drop-shadow(2px 2px 4px rgba(0,0,0,0.5))';
              
              // Add location info overlay
              const infoOverlay = document.createElement('div');
              infoOverlay.innerHTML = `
                <div style="
                  position: absolute;
                  top: 10px;
                  left: 10px;
                  background: rgba(255, 255, 255, 0.9);
                  padding: 8px 12px;
                  border-radius: 6px;
                  font-size: 12px;
                  font-family: Arial, sans-serif;
                  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
                  z-index: 1001;
                ">
                  <strong>Delhi Central Station</strong><br>
                  📍 \${lat.toFixed(4)}, \${lng.toFixed(4)}
                </div>
              `;
              
              // Add click instruction overlay
              const clickOverlay = document.createElement('div');
              clickOverlay.innerHTML = `
                <div style="
                  position: absolute;
                  bottom: 10px;
                  right: 10px;
                  background: rgba(0, 0, 0, 0.7);
                  color: white;
                  padding: 6px 10px;
                  border-radius: 4px;
                  font-size: 11px;
                  font-family: Arial, sans-serif;
                  z-index: 1001;
                ">
                  🖱️ Click to open in Google Maps
                </div>
              `;
              
              // Assemble the map
              mapDiv.appendChild(tilesContainer);
              mapDiv.appendChild(marker);
              mapDiv.appendChild(infoOverlay);
              mapDiv.appendChild(clickOverlay);
              
              // Add click handler to the entire map
              mapDiv.addEventListener('click', function(e) {
                // Add click animation
                mapDiv.style.transform = 'scale(0.98)';
                mapDiv.style.transition = 'transform 0.1s ease';
                setTimeout(function() {
                  mapDiv.style.transform = 'scale(1.0)';
                }, 100);
              });
              
              // Add hover effect
              mapDiv.addEventListener('mouseenter', function() {
                mapDiv.style.filter = 'brightness(1.05)';
                mapDiv.style.transition = 'filter 0.2s ease';
              });
              
              mapDiv.addEventListener('mouseleave', function() {
                mapDiv.style.filter = 'brightness(1.0)';
              });
              
            })();
          ''';

        // Add click handler
        mapDiv.onClick.listen((event) {
          onMapClick();
        });

        // Assemble the container
        mapContainer.children.addAll([mapDiv, script]);

        return mapContainer;
      });
    } catch (e) {
      print("Error registering map view: $e");
    }
  }
}

class PlatformUtils {
  // Detect platform details
  static Future<PlatformInfo> detectPlatform() async {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
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
