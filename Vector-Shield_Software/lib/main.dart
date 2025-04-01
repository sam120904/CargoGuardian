import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'dashboard.dart';
import 'config.dart';

// Global variable to track initialization state
bool isInitialized = false;
String? initError;

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Run the app immediately, but show a loading screen
  // This prevents the blank screen issue
  runApp(const LoadingApp());

  try {
    // Initialize AppConfig first - this will try to load .env
    // but won't fail if it doesn't exist (like on Vercel)
    await AppConfig.initialize();

    // Debug: Print config values to help diagnose issues
    AppConfig.debugPrintConfig();

    // Check if Firebase is already initialized to avoid the "already exists" error
    if (Firebase.apps.isEmpty) {
      try {
        // Initialize Firebase only if it's not already initialized
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print("Firebase initialized successfully");
      } catch (e) {
        print("Error initializing Firebase: $e");
        // Continue anyway, we'll handle auth state in the app
        if (e.toString().contains('duplicate-app')) {
          print("Ignoring duplicate app error, Firebase is already initialized");
        } else {
          initError = "Firebase error: ${e.toString()}";
        }
      }
    } else {
      print("Firebase was already initialized");
    }

    isInitialized = true;
  } catch (e) {
    print("Error during initialization: $e");
    initError = e.toString();
  }

  // Now run the actual app
  runApp(const MyApp());
}

// Simple loading app to show while initializing
class LoadingApp extends StatelessWidget {
  const LoadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                "Loading application...",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home:
          !isInitialized
              ? InitErrorScreen(error: initError)
              : const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
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
      body: Center(
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
    // Fallback timer - show login page after 5 seconds if Firebase auth is stuck
    Timer(const Duration(seconds: 5), () {
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    "Checking authentication status...",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please wait...",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
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