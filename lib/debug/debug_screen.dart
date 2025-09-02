import 'package:flutter/material.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _debugOutput = '';
  bool _isLoading = false;

  void _addDebugOutput(String message) {
    setState(() {
      _debugOutput += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    _addDebugOutput('🧪 Testing Supabase connection...');
    
    try {
      final isConnected = await SupabaseAuthService.testConnection();
      if (isConnected) {
        _addDebugOutput('✅ Connection successful!');
      } else {
        _addDebugOutput('❌ Connection failed!');
      }
    } catch (e) {
      _addDebugOutput('❌ Connection error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testRegistration() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      _addDebugOutput('❌ Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _addDebugOutput('🚀 Testing user registration...');
    
    try {
      final result = await SupabaseAuthService.register(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
      );

      if (result.success) {
        _addDebugOutput('✅ Registration successful!');
        _addDebugOutput('👤 User: ${result.user?.name}');
        _addDebugOutput('📧 Email: ${result.user?.email}');
        _addDebugOutput('🎭 Role: ${result.user?.role}');
      } else {
        _addDebugOutput('❌ Registration failed: ${result.message}');
      }
    } catch (e) {
      _addDebugOutput('❌ Registration error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _addDebugOutput('❌ Please fill in email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _addDebugOutput('🔑 Testing user login...');
    
    try {
      final result = await SupabaseAuthService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (result.success) {
        _addDebugOutput('✅ Login successful!');
        _addDebugOutput('👤 User: ${result.user?.name}');
        _addDebugOutput('📧 Email: ${result.user?.email}');
        _addDebugOutput('🎭 Role: ${result.user?.role}');
      } else {
        _addDebugOutput('❌ Login failed: ${result.message}');
      }
    } catch (e) {
      _addDebugOutput('❌ Login error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getCurrentUser() async {
    setState(() {
      _isLoading = true;
    });

    _addDebugOutput('👤 Getting current user...');
    
    try {
      final user = await SupabaseAuthService.getCurrentUser();
      
      if (user != null) {
        _addDebugOutput('✅ Current user found!');
        _addDebugOutput('👤 Name: ${user.name}');
        _addDebugOutput('📧 Email: ${user.email}');
        _addDebugOutput('📱 Phone: ${user.phone}');
        _addDebugOutput('🎭 Role: ${user.role}');
      } else {
        _addDebugOutput('❌ No current user found');
      }
    } catch (e) {
      _addDebugOutput('❌ Get current user error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getAllUsers() async {
    setState(() {
      _isLoading = true;
    });

    _addDebugOutput('👥 Getting all users...');
    
    try {
      final users = await SupabaseAuthService.getAllUsers();
      
      _addDebugOutput('✅ Found ${users.length} users:');
      for (final user in users) {
        _addDebugOutput('  • ${user.name} (${user.email}) - ${user.role}');
      }
    } catch (e) {
      _addDebugOutput('❌ Get all users error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Debug'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input fields
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testConnection,
                  child: const Text('Test Connection'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testRegistration,
                  child: const Text('Test Register'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testLogin,
                  child: const Text('Test Login'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _getCurrentUser,
                  child: const Text('Get Current User'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _getAllUsers,
                  child: const Text('Get All Users'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _debugOutput = '';
                    });
                  },
                  child: const Text('Clear Log'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Debug output
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black87,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugOutput.isEmpty ? 'Debug output will appear here...' : _debugOutput,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}