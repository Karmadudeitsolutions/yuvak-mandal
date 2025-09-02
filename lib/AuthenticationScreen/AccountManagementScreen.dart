import 'package:flutter/material.dart';
import '../utils/auth_migration.dart';
import '../models/user.dart';
import '../AuthenticationScreen/LoginScreen1.dart';

class AccountManagementScreen extends StatefulWidget {
  @override
  _AccountManagementScreenState createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  User? _currentUser;
  bool _isLoading = false;

  // Edit Profile Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Change Password Controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Delete Account Controller
  final _deletePasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _deletePasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await AuthMigration.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          _phoneController.text = user.phone;
        });
      }
    } catch (e) {
      _showMessage('Failed to load user information', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      _showMessage('Please fill in all fields', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthMigration.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (result.success) {
        setState(() {
          _currentUser = result.user;
        });
        _showMessage('Profile updated successfully!');
      } else {
        _showMessage(result.message, isError: true);
      }
    } catch (e) {
      _showMessage('Failed to update profile', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showMessage('Please fill in all password fields', isError: true);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage('New passwords do not match', isError: true);
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showMessage('New password must be at least 6 characters', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthMigration.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (result.success) {
        _showMessage('Password changed successfully!');
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        _showMessage(result.message, isError: true);
      }
    } catch (e) {
      _showMessage('Failed to change password', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    if (_deletePasswordController.text.isEmpty) {
      _showMessage('Please enter your password to confirm deletion', isError: true);
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthMigration.deleteAccount(
        password: _deletePasswordController.text,
      );

      if (result.success) {
        _showMessage('Account deleted successfully');
        // Navigate to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen1()),
          (Route<dynamic> route) => false,
        );
      } else {
        _showMessage(result.message, isError: true);
      }
    } catch (e) {
      _showMessage('Failed to delete account', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthMigration.logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen1()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff21254A),
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Color(0xff21254A),
          foregroundColor: textColor ?? Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(text, style: TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Account Management'),
          backgroundColor: Color(0xff21254A),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Account Management'),
        backgroundColor: Color(0xff21254A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Info Section
            _buildSection(
              'User Information',
              [
                if (_currentUser != null) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xff21254A),
                      child: Text(
                        _currentUser!.name[0].toUpperCase(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(_currentUser!.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${_currentUser!.email}'),
                        Text('Role: ${_currentUser!.role}'),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Edit Profile Section
            _buildSection(
              'Edit Profile',
              [
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                ),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                ),
                _buildButton(
                  text: 'Update Profile',
                  onPressed: _updateProfile,
                ),
              ],
            ),

            // Change Password Section
            _buildSection(
              'Change Password',
              [
                _buildTextField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  obscureText: true,
                ),
                _buildTextField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  obscureText: true,
                ),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New Password',
                  obscureText: true,
                ),
                _buildButton(
                  text: 'Change Password',
                  onPressed: _changePassword,
                ),
              ],
            ),

            // Danger Zone
            _buildSection(
              'Danger Zone',
              [
                Text(
                  'Warning: This action cannot be undone.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                _buildTextField(
                  controller: _deletePasswordController,
                  label: 'Enter Password to Confirm',
                  obscureText: true,
                ),
                _buildButton(
                  text: 'Delete Account',
                  onPressed: _deleteAccount,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                ),
              ],
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
