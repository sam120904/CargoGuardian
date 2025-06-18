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
      // FIXED: Always open in new tab without affecting current page
      html.window.open(url, '_blank', 'noopener,noreferrer');
    } catch (e) {
      print("Error opening URL: $e");
      // Fallback - but still try to open in new tab
      try {
        html.window.open(url, '_blank');
      } catch (e2) {
        print("Fallback error opening URL: $e2");
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

  // FIXED: Full coverage map with proper click handling
  static void registerMapView(String viewType, double lat, double lng, VoidCallback onMapClick) {
    try {
      // Register a full-coverage tile-based map view
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        // Create main map container that fills the entire space
        final mapContainer = html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'relative'
          ..style.overflow = 'hidden'
          ..style.backgroundColor = '#f0f8ff';

        // Create the actual map div that fills the container
        final mapDiv = html.DivElement()
          ..id = 'map-$viewId'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'absolute'
          ..style.top = '0'
          ..style.left = '0'
          ..style.cursor = 'pointer'
          ..style.overflow = 'hidden';

        // Add the map initialization script with full coverage
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
              
              // FIXED: Create larger grid to ensure full coverage
              const tileSize = 256;
              const gridSizeX = 6; // Increased from 3 to 6
              const gridSizeY = 4; // Increased from 3 to 4
              const startX = centerX - Math.floor(gridSizeX / 2);
              const startY = centerY - Math.floor(gridSizeY / 2);
              
              // Clear any existing content
              mapDiv.innerHTML = '';
              
              // FIXED: Create tiles container that fills the entire space
              const tilesContainer = document.createElement('div');
              tilesContainer.style.position = 'absolute';
              tilesContainer.style.width = (gridSizeX * tileSize) + 'px';
              tilesContainer.style.height = (gridSizeY * tileSize) + 'px';
              tilesContainer.style.left = '50%';
              tilesContainer.style.top = '50%';
              tilesContainer.style.transform = 'translate(-50%, -50%)';
              tilesContainer.style.minWidth = '100%';
              tilesContainer.style.minHeight = '100%';
              
              // Add tiles to cover the entire area
              for (let i = 0; i < gridSizeX; i++) {
                for (let j = 0; j < gridSizeY; j++) {
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
                  tile.style.userSelect = 'none';
                  tile.style.pointerEvents = 'none'; // Prevent individual tile clicks
                  
                  // Add loading placeholder
                  tile.style.backgroundColor = '#e8f4f8';
                  
                  // Handle tile load errors
                  tile.onerror = function() {
                    this.style.backgroundColor = '#f0f0f0';
                    this.style.display = 'flex';
                    this.style.alignItems = 'center';
                    this.style.justifyContent = 'center';
                    this.innerHTML = '<div style="color: #666; font-size: 10px; text-align: center;">Tile<br>Loading...</div>';
                  };
                  
                  tilesContainer.appendChild(tile);
                }
              }
              
              // Add location marker (centered)
              const marker = document.createElement('div');
              marker.innerHTML = '📍';
              marker.style.position = 'absolute';
              marker.style.left = '50%';
              marker.style.top = '50%';
              marker.style.transform = 'translate(-50%, -50%)';
              marker.style.fontSize = '28px';
              marker.style.zIndex = '1000';
              marker.style.filter = 'drop-shadow(2px 2px 4px rgba(0,0,0,0.7))';
              marker.style.pointerEvents = 'none'; // Don't interfere with clicks
              
              // Add location info overlay
              const infoOverlay = document.createElement('div');
              infoOverlay.innerHTML = `
                <div style="
                  position: absolute;
                  top: 12px;
                  left: 12px;
                  background: rgba(255, 255, 255, 0.95);
                  padding: 10px 14px;
                  border-radius: 8px;
                  font-size: 13px;
                  font-family: Arial, sans-serif;
                  box-shadow: 0 3px 6px rgba(0,0,0,0.2);
                  z-index: 1001;
                  border: 1px solid rgba(0,0,0,0.1);
                  pointer-events: none;
                ">
                  <strong style="color: #2c3e50;">Delhi Central Station</strong><br>
                  <span style="color: #7f8c8d;">📍 \${lat.toFixed(4)}, \${lng.toFixed(4)}</span>
                </div>
              `;
              
              // Add click instruction overlay
              const clickOverlay = document.createElement('div');
              clickOverlay.innerHTML = `
                <div style="
                  position: absolute;
                  bottom: 12px;
                  right: 12px;
                  background: rgba(0, 0, 0, 0.8);
                  color: white;
                  padding: 8px 12px;
                  border-radius: 6px;
                  font-size: 12px;
                  font-family: Arial, sans-serif;
                  z-index: 1001;
                  border: 1px solid rgba(255,255,255,0.2);
                  pointer-events: none;
                ">
                  🖱️ Click to open in Google Maps
                </div>
              `;
              
              // Assemble the map
              mapDiv.appendChild(tilesContainer);
              mapDiv.appendChild(marker);
              mapDiv.appendChild(infoOverlay);
              mapDiv.appendChild(clickOverlay);
              
              // FIXED: Add click handler that prevents navigation
              mapDiv.addEventListener('click', function(e) {
                e.preventDefault(); // Prevent default navigation
                e.stopPropagation(); // Stop event bubbling
                
                // Add click animation
                mapDiv.style.transform = 'scale(0.98)';
                mapDiv.style.transition = 'transform 0.1s ease';
                setTimeout(function() {
                  mapDiv.style.transform = 'scale(1.0)';
                }, 100);
                
                // Don't navigate - let Flutter handle the callback
                return false;
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

        // FIXED: Add click handler that only opens new tab
        mapDiv.onClick.listen((event) {
          event.preventDefault();
          event.stopPropagation();
          onMapClick(); // This will call the Flutter callback which opens new tab
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
