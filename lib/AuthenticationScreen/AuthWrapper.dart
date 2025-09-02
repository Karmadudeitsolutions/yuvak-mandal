import 'package:flutter/material.dart';
import '../utils/auth_migration.dart';
import '../screens/home/home_screen.dart';
import '../AuthenticationScreen/LoginScreen1.dart';
import '../debug/debug_screen.dart';

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await AuthMigration.isLoggedIn();
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xff21254A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink[200]!),
              ),
              SizedBox(height: 20),
              Text(
                'Yuvak Mandal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: "Popins",
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Loan Management System',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[300],
                  fontFamily: "Popins",
                ),
              ),
            ],
          ),
        ),
        // Debug button - only visible in debug mode
        floatingActionButton: _buildDebugButton(context),
      );
    }

    final mainScreen = _isLoggedIn ? HomeScreen() : LoginScreen1();
    
    // Wrap the main screen with debug button
    return Scaffold(
      body: mainScreen,
      floatingActionButton: _buildDebugButton(context),
    );
  }
  
  Widget? _buildDebugButton(BuildContext context) {
    // Only show debug button in debug mode
    bool inDebugMode = false;
    assert(inDebugMode = true); // This will only execute in debug mode
    
    if (!inDebugMode) return null;
    
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.red,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DebugScreen()),
        );
      },
      child: const Icon(Icons.bug_report, color: Colors.white),
    );
  }
}
