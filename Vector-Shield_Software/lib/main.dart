import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'dashboard.dart';
import 'config.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app with a single loading screen
  runApp(const MyApp());
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
      // Initialize AppConfig first
      await AppConfig.initialize();
      
      // Debug: Print config values
      AppConfig.debugPrintConfig();
      
      // Initialize Firebase
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          print("Firebase initialized successfully");
        } catch (e) {
          print("Error initializing Firebase: $e");
          if (e.toString().contains('duplicate-app')) {
            print("Ignoring duplicate app error, Firebase is already initialized");
          } else {
            _initError = "Firebase error: ${e.toString()}";
          }
        }
      } else {
        print("Firebase was already initialized");
      }
      
      // Add a small delay to ensure everything is loaded
      await Future.delayed(const Duration(milliseconds: 500));
      
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
          _isInitialized = true; // Still mark as initialized to show error screen
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vector Shield',
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
      home: !_isInitialized 
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

// Single loading screen for the app
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
                "Vector Shield",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Train Cargo Monitoring System",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Initializing...",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
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
                      MaterialPageRoute(builder: (context) => const LoginPage()),
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

// Separate widget to handle authentication state with timeout
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
        if ((snapshot.connectionState == ConnectionState.waiting) && _timeoutReached) {
          print("Auth timeout reached, showing login page");
          return const LoginPage();
        }
        
        // Show loading indicator while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting && !_timeoutReached) {
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
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