// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;
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

// Enhanced platform detection
bool _isMobileBrowser = false;
bool _isIOSSafari = false;
bool _isStandalone = false;

// Helper function to safely check for standalone mode
bool _checkStandaloneMode() {
  if (!kIsWeb) return false;
  
  try {
    // Use JavaScript interop to safely check for standalone mode
    if (js.context.hasProperty('navigator')) {
      final navigator = js.context['navigator'];
      if (navigator != null && navigator.hasProperty('standalone')) {
        return navigator['standalone'] == true;
      }
    }
    
    // Alternative method using media query
    final mediaQuery = html.window.matchMedia('(display-mode: standalone)');
    return mediaQuery.matches;
  } catch (e) {
    print("Error checking standalone mode: $e");
    return false;
  }
}

// Helper function to detect iOS Safari
bool _detectIOSSafari() {
  if (!kIsWeb) return false;
  
  try {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    final platform = html.window.navigator.platform?.toLowerCase() ?? '';
    
    // Check for iOS devices
    final isIOS = userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod') ||
        platform.contains('iphone') ||
        platform.contains('ipad') ||
        platform.contains('ipod');
    
    // Check for Safari browser (not Chrome or other browsers on iOS)
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

void main() async {
  // Enhanced error handling with zone
  runZonedGuarded(
    () async {
      // Ensure Flutter is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Enhanced platform detection for web
      if (kIsWeb) {
        try {
          final userAgent = html.window.navigator.userAgent.toLowerCase();
          
          _isMobileBrowser = userAgent.contains('mobile') ||
              userAgent.contains('android') ||
              userAgent.contains('iphone') ||
              userAgent.contains('ipad');

          _isIOSSafari = _detectIOSSafari();
          _isStandalone = _checkStandaloneMode();

          print("Enhanced platform detection: "
              "Mobile: $_isMobileBrowser, "
              "iOS Safari: $_isIOSSafari, "
              "Standalone: $_isStandalone, "
              "UserAgent: $userAgent");

          // Enhanced delay for iOS Safari
          if (_isIOSSafari) {
            final delay = _isStandalone ? 2000 : 3000;
            print("Adding ${delay}ms delay for iOS Safari");
            await Future.delayed(Duration(milliseconds: delay));
          } else if (_isMobileBrowser) {
            await Future.delayed(const Duration(milliseconds: 1000));
          }
        } catch (e) {
          print("Error during enhanced web platform detection: $e");
        }
      }

      // Initialize AppConfig with error handling
      try {
        await AppConfig.initialize();
        AppConfig.debugPrintConfig();
      } catch (e) {
        print("Error initializing AppConfig: $e");
      }

      // Enhanced Firebase initialization
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          print("Firebase initialized successfully");
          
          // Additional delay after Firebase initialization for iOS Safari
          if (_isIOSSafari) {
            await Future.delayed(const Duration(milliseconds: 1000));
          }
        } catch (e) {
          print("Error initializing Firebase: $e");
          if (!e.toString().contains('duplicate-app')) {
            // Only throw if it's not a duplicate app error
            rethrow;
          }
        }
      } else {
        print("Firebase was already initialized");
      }

      // Run the app
      runApp(const MyApp());
    },
    (error, stackTrace) {
      // Enhanced error logging
      print('Unhandled error in main: $error');
      print('Stack trace: $stackTrace');
      
      // Try to run a minimal app even if there are errors
      try {
        runApp(MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Application Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${error.toString()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (kIsWeb) {
                        html.window.location.reload();
                      }
                    },
                    child: const Text('Reload App'),
                  ),
                ],
              ),
            ),
          ),
        ));
      } catch (e) {
        print('Failed to run minimal error app: $e');
      }
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  String? _initError;
  Timer? _initTimer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _initTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Enhanced initialization delay based on platform
      int delay = 500; // Default delay
      
      if (kIsWeb) {
        if (_isIOSSafari) {
          delay = _isStandalone ? 3500 : 4500; // Longer delay for iOS Safari
        } else if (_isMobileBrowser) {
          delay = 2000; // Medium delay for other mobile browsers
        }
      }
      
      print("App initialization delay: ${delay}ms");
      await Future.delayed(Duration(milliseconds: delay));

      // Additional iOS Safari specific initialization
      if (_isIOSSafari && kIsWeb) {
        try {
          // Set viewport height for iOS Safari using JavaScript interop
          _setIOSViewportHeight();
          
          // Handle orientation changes
          html.window.addEventListener('orientationchange', (event) {
            Timer(const Duration(milliseconds: 500), () {
              _setIOSViewportHeight();
            });
          });
          
          // Handle resize events
          html.window.addEventListener('resize', (event) {
            Timer(const Duration(milliseconds: 100), () {
              _setIOSViewportHeight();
            });
          });
        } catch (e) {
          print("Error setting up iOS Safari specific features: $e");
        }
      }

      // Mark initialization as complete
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print("Error during app initialization: $e");
      if (mounted) {
        setState(() {
          _initError = e.toString();
          _isInitialized = true;
        });
      }
    }
  }

  void _setIOSViewportHeight() {
    try {
      final vh = html.window.innerHeight! * 0.01;
      html.document.documentElement?.style.setProperty('--vh', '${vh}px');
    } catch (e) {
      print("Error setting viewport height: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CargoGuardian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Enhanced theme for better iOS Safari compatibility
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
            // Enhanced button styling for iOS Safari
            elevation: _isIOSSafari ? 2 : 4,
          ),
        ),
      ),
      home: !_isInitialized
          ? const EnhancedAppLoadingScreen()
          : (_initError != null
              ? EnhancedInitErrorScreen(error: _initError)
              : const EnhancedAuthWrapper()),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}

// Enhanced loading screen with iOS Safari optimizations
class EnhancedAppLoadingScreen extends StatefulWidget {
  const EnhancedAppLoadingScreen({super.key});

  @override
  State<EnhancedAppLoadingScreen> createState() => _EnhancedAppLoadingScreenState();
}

class _EnhancedAppLoadingScreenState extends State<EnhancedAppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _loadingTextTimer;
  int _loadingStep = 0;
  
  final List<String> _loadingMessages = [
    "Initializing CargoGuardian...",
    "Loading security protocols...",
    "Connecting to IoT sensors...",
    "Preparing dashboard...",
    "Almost ready..."
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: _isIOSSafari ? 2000 : 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    // Start loading text animation
    _startLoadingTextAnimation();
  }

  void _startLoadingTextAnimation() {
    _loadingTextTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted && _loadingStep < _loadingMessages.length - 1) {
        setState(() {
          _loadingStep++;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loadingTextTimer?.cancel();
    super.dispose();
  }

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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
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
                    textAlign: TextAlign.center,
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _loadingMessages[_loadingStep],
                      key: ValueKey(_loadingStep),
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_isIOSSafari) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Optimizing for iOS Safari...",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced error screen with better iOS Safari support
class EnhancedInitErrorScreen extends StatelessWidget {
  final String? error;

  const EnhancedInitErrorScreen({super.key, this.error});

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
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 60),
                  const SizedBox(height: 20),
                  Text(
                    "Application Error",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    error ?? "Failed to initialize the application.",
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  if (_isIOSSafari) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700),
                          const SizedBox(height: 8),
                          Text(
                            "iOS Safari Detected",
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Try refreshing the page, clearing browser cache, or opening in a different browser if issues persist.",
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (kIsWeb) {
                            html.window.location.reload();
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          }
                        },
                        child: const Text("Reload App"),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text("Continue Anyway"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced AuthWrapper with better iOS Safari compatibility
class EnhancedAuthWrapper extends StatefulWidget {
  const EnhancedAuthWrapper({super.key});

  @override
  State<EnhancedAuthWrapper> createState() => _EnhancedAuthWrapperState();
}

class _EnhancedAuthWrapperState extends State<EnhancedAuthWrapper> {
  bool _timeoutReached = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Enhanced timeout for iOS Safari
    final timeoutDuration = _isIOSSafari ? 8 : 5; // Longer timeout for iOS Safari
    print("Setting auth timeout to ${timeoutDuration} seconds");
    
    _timeoutTimer = Timer(Duration(seconds: timeoutDuration), () {
      if (mounted) {
        print("Auth timeout reached after ${timeoutDuration} seconds");
        setState(() {
          _timeoutReached = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Enhanced timeout handling
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
              child: SafeArea(
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
                        "Checking authentication...",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (_isIOSSafari) ...[
                        const SizedBox(height: 8),
                        Text(
                          "iOS Safari may take longer to load",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          print("Auth stream error: ${snapshot.error}");
          return const LoginPage();
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
