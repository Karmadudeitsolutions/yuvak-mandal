import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';
import '../screens/home/home_screen.dart';
import '../AuthenticationScreen/LoginScreen1.dart';
import '../test_supabase_connection.dart';

class SupabaseAuthWrapper extends StatefulWidget {
  @override
  _SupabaseAuthWrapperState createState() => _SupabaseAuthWrapperState();
}

class _SupabaseAuthWrapperState extends State<SupabaseAuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _loadingMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      setState(() {
        _loadingMessage = 'Checking authentication...';
      });

      // In bypass mode, we don't need to listen to auth state changes
      // Just set the initial state

      // Check initial auth state
      final isLoggedIn = SupabaseAuthService.isLoggedIn;
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
        _loadingMessage = 'Authentication error: ${e.toString()}';
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
              SizedBox(height: 20),
              Text(
                _loadingMessage,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  fontFamily: "Popins",
                ),
              ),
              SizedBox(height: 20),
              // Add test connection button during development
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SupabaseTestScreen(),
                    ),
                  );
                },
                child: Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[200],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isLoggedIn ? HomeScreen() : LoginScreen1();
  }
}