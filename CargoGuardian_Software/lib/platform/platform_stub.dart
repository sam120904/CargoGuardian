// Stub implementation for platforms that don't match web or mobile
import 'dart:async';
import 'package:flutter/material.dart';

// This is a fallback implementation that ensures the code compiles
// even if neither web nor mobile platforms are detected
class PlatformImplementation {
  static void openUrlInBrowser(String url) {
    print("openUrlInBrowser not implemented for this platform");
  }

  static bool checkNetworkConnectivity() {
    return false;
  }

  static void logToConsole(String message) {
    print(message);
  }

  static bool isMobileBrowser() {
    return false;
  }

  static bool getLocationPermission() {
    return false;
  }

  static Future<bool> requestLocationPermission() async {
    return false;
  }

  static void initializeMap(String elementId, double lat, double lng, String title) {
    print("initializeMap not implemented for this platform");
  }

  static bool isIOSSafari() {
    return false;
  }

  // Console command checking - stub implementation
  static void checkConsoleCommands(Function(String) onCommand) {
    // Stub implementation
  }

  // Set up console command listener - stub implementation
  static void setupConsoleListener() {
    // Stub implementation
  }

  // Register map view - stub implementation
  static void registerMapView(String viewType, double lat, double lng, VoidCallback onMapClick) {
    // Stub implementation
  }
}

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

class PlatformUtils {
  // Detect platform details - stub implementation
  static Future<PlatformInfo> detectPlatform() async {
    return PlatformInfo(
      isMobileBrowser: false,
      isIOSSafari: false,
      isStandalone: false,
      userAgent: 'unknown',
    );
  }
  
  // Set viewport height for iOS Safari - stub implementation
  static void setIOSViewportHeight() {
    // Stub implementation
  }
  
  // Setup iOS Safari events - stub implementation
  static void setupIOSSafariEvents() {
    // Stub implementation
  }
  
  // Reload page - stub implementation
  static void reloadPage() {
    // Stub implementation
  }
}
