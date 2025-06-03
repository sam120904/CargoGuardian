// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'config/config.dart';

import 'auth/login_page.dart';
import 'auth/signup_page.dart';

import 'dashboard/dashboard_page.dart';

// Platform detection needs to be at the top level
bool _isMobileBrowser = false;

void main() async {
  // Wrap the app in a zone to catch all unhandled errors
  runZonedGuarded(
    () async {
      // Ensure Flutter is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize AppConfig first
      await AppConfig.initialize();

      // Platform detection for web
      if (kIsWeb) {
        try {
          final userAgent = html.window.navigator.userAgent.toLowerCase();
          _isMobileBrowser =
              userAgent.contains('mobile') ||
              userAgent.contains('android') ||
              userAgent.contains('iphone') ||
              userAgent.contains('ipad');

          print(
            "Running on ${_isMobileBrowser ? 'mobile' : 'desktop'} browser",
          );

          // Add delay for mobile browsers before Firebase init
          if (_isMobileBrowser) {
            await Future.delayed(const Duration(milliseconds: 800));
          }
        } catch (e) {
          print("Error during web platform detection: $e");
        }
      }

      // Debug: Print config values
      AppConfig.debugPrintConfig();

      // Initialize Firebase with error handling
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          print("Firebase initialized successfully");
        } catch (e) {
          print("Error initializing Firebase: $e");
          if (e.toString().contains('duplicate-app')) {
            print(
              "Ignoring duplicate app error, Firebase is already initialized",
            );
          }
        }
      } else {
        print("Firebase was already initialized");
      }

      // Run the app
      runApp(const MyApp());
    },
    (error, stackTrace) {
      // Log any unhandled errors
      print('Unhandled error: $error');
      print('Stack trace: $stackTrace');
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // App initialization state
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // Initialize the app

  Future<void> _initializeApp() async {
    try {
      // Add a small delay to ensure everything is loaded
      // Increase delay for mobile browsers, especially iOS Safari
      if (kIsWeb) {
        // Check if we're on iOS Safari
        final userAgent = html.window.navigator.userAgent.toLowerCase();
        final isIOSSafari =
            userAgent.contains('iphone') ||
            userAgent.contains('ipad') ||
            userAgent.contains('ipod');

        if (isIOSSafari) {
          // iOS Safari needs more time
          await Future.delayed(const Duration(milliseconds: 2500));
        } else if (_isMobileBrowser) {
          // Other mobile browsers
          await Future.delayed(const Duration(milliseconds: 1500));
        } else {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Mark initialization as complete
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print("Error during initialization: $e");
      if (mounted) {
        setState(() {
          _initError = e.toString();
          _isInitialized =
              true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CargoGuardian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home:
          !_isInitialized
              ? const AppLoadingScreen()
              : (_initError != null
                  ? InitErrorScreen(error: _initError)
                  : const AuthWrapper()),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}

// Improved loading screen with better mobile compatibility
class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.indigo.shade50],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shield,
                  size: 48,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "CargoGuardian",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Train Cargo Monitoring System",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Initializing...",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Screen to show initialization errors
class InitErrorScreen extends StatelessWidget {
  final String? error;

  const InitErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.indigo.shade50],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 60),
                const SizedBox(height: 20),
                Text(
                  "Application Initialization Error",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  error ??
                      "Failed to initialize the application. Please check your configuration.",
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Try to navigate to login page anyway
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text("Try to continue anyway"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Improved AuthWrapper with better mobile compatibility
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _timeoutReached = false;

  @override
  void initState() {
    super.initState();
    // Fallback timer - show login page after 3 seconds if Firebase auth is stuck
    // Reduced from 5 to 3 seconds for better user experience
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _timeoutReached = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If timeout reached and still waiting, show login page
        if ((snapshot.connectionState == ConnectionState.waiting) &&
            _timeoutReached) {
          print("Auth timeout reached, showing login page");
          return const LoginPage();
        }

        // Show loading indicator while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_timeoutReached) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade50, Colors.indigo.shade50],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Checking authentication status...",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Check if user is logged in
        if (snapshot.hasData) {
          print("User is logged in: ${snapshot.data?.uid}");
          return const DashboardPage();
        }

        // User is not logged in
        print("User is not logged in, showing login page");
        return const LoginPage();
      },
    );
  }
}
