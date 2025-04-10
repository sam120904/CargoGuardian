import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import '../dashboard/dashboard_page.dart';

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
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading your account...")
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