import 'package:flutter/material.dart';
import '../Library/Constant/Slideanimation.dart';
import '../utils/auth_migration.dart';
import '../screens/admin/admin_dashboard.dart';
import 'LoginScreen1.dart';

class AdminLoginScreen extends StatefulWidget {
  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminCodeController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _passwordVisible = false;

  // Admin access codes for different roles
  final Map<String, String> _adminCodes = {
    'ADMIN2024': 'Admin',
    'MANAGER2024': 'Manager',
    'LEADER2024': 'Leader',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 2000));
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate admin code
    final adminCode = _adminCodeController.text.trim();
    if (!_adminCodes.containsKey(adminCode)) {
      setState(() {
        _errorMessage = 'Invalid admin access code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First try to login with existing credentials
      final loginResult = await AuthMigration.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (loginResult.success) {
        // Check if user role matches admin code
        final userRole = loginResult.user?.role ?? 'Member';
        final expectedRole = _adminCodes[adminCode]!;

        if (userRole == expectedRole || userRole == 'Admin') {
          // Navigate to admin dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboard()),
          );
        } else {
          setState(() {
            _errorMessage = 'Your account does not have $expectedRole privileges';
          });
        }
      } else {
        // If login fails, check if we should create admin account
        if (adminCode == 'ADMIN2024') {
          await _createAdminAccount();
        } else {
          setState(() {
            _errorMessage = 'Invalid credentials. Contact admin to create your account.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createAdminAccount() async {
    try {
      final adminCode = _adminCodeController.text.trim();
      final role = _adminCodes[adminCode]!;

      final result = await AuthMigration.register(
        name: 'System $role',
        email: _emailController.text.trim(),
        phone: '1234567890', // Default phone for admin
        password: _passwordController.text,
        role: role,
      );

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$role account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Auto login after creating account
        final loginResult = await AuthMigration.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (loginResult.success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboard()),
          );
        }
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create admin account';
      });
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  String? _validateAdminCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter admin access code';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Color(0xff21254A),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 200,
              child: Stack(
                children: <Widget>[
                  SlideAnimation(
                    position: 2,
                    itemCount: 8,
                    slideDirection: SlideDirection.fromTop,
                    animationController: _animationController,
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: AssetImage("assets/Assets/login1.png"),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SlideAnimation(
                      position: 1,
                      itemCount: 8,
                      slideDirection: SlideDirection.fromLeft,
                      animationController: _animationController,
                      child: Text(
                        "Admin Access\nPortal",
                        style: TextStyle(
                          fontSize: 35,
                          fontFamily: "Popins",
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Admin Codes Information
                    SlideAnimation(
                      position: 1,
                      itemCount: 8,
                      slideDirection: SlideDirection.fromLeft,
                      animationController: _animationController,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔑 Admin Access Codes:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('• ADMIN2024 - Full Admin Access', 
                                 style: TextStyle(color: Colors.blue.shade700)),
                            Text('• MANAGER2024 - Manager Access', 
                                 style: TextStyle(color: Colors.blue.shade700)),
                            Text('• LEADER2024 - Group Leader Access', 
                                 style: TextStyle(color: Colors.blue.shade700)),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 30),
                    
                    // Error message
                    if (_errorMessage.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SlideAnimation(
                      position: 1,
                      itemCount: 8,
                      slideDirection: SlideDirection.fromLeft,
                      animationController: _animationController,
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.transparent,
                        ),
                        child: Column(
                          children: <Widget>[
                            // Admin Code field
                            Container(
                              padding: EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[100]!),
                                ),
                              ),
                              child: TextFormField(
                                controller: _adminCodeController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Admin Access Code",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.security, color: Colors.grey),
                                ),
                                validator: _validateAdminCode,
                              ),
                            ),
                            
                            // Email field
                            Container(
                              padding: EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[100]!),
                                ),
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                style: TextStyle(color: Colors.white),
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Admin Email",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.email, color: Colors.grey),
                                ),
                                validator: _validateEmail,
                              ),
                            ),
                            
                            // Password field
                            Container(
                              padding: EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[100]!),
                                ),
                              ),
                              child: TextFormField(
                                controller: _passwordController,
                                style: TextStyle(color: Colors.white),
                                obscureText: !_passwordVisible,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Password",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.lock, color: Colors.grey),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _passwordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _passwordVisible = !_passwordVisible;
                                      });
                                    },
                                  ),
                                ),
                                validator: _validatePassword,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 30.0),
                    
                    // Admin Login Button
                    SlideAnimation(
                      position: 1,
                      itemCount: 8,
                      slideDirection: SlideDirection.fromLeft,
                      animationController: _animationController,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _handleAdminLogin,
                        child: Container(
                          height: 50,
                          margin: EdgeInsets.symmetric(horizontal: 60),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: _isLoading ? Colors.grey : Colors.orange.shade600,
                          ),
                          child: Center(
                            child: _isLoading
                                ? CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : Text(
                                    "Admin Login",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      fontFamily: "Popins",
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 20.0),
                    
                    // Back to User Login
                    SlideAnimation(
                      position: 1,
                      itemCount: 8,
                      slideDirection: SlideDirection.fromLeft,
                      animationController: _animationController,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen1()),
                            );
                          },
                          child: Text(
                            "← Back to User Login",
                            style: TextStyle(
                              color: Colors.pink[200],
                              fontFamily: "Popins",
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
