import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../../services/data_service.dart';
import '../../services/supabase_data_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/shared_preferences_service.dart';

class JoinGroupScreen extends StatefulWidget {
  @override
  _JoinGroupScreenState createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupCodeController = TextEditingController();
  bool _isLoading = false;
  List<Group> availableGroups = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableGroups();
  }

  @override
  void dispose() {
    _groupCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableGroups() async {
    try {
      // Prefer stored user; fallback to current auth
      final storedUser = await SharedPreferencesService.getStoredUser();
      final user = storedUser ?? await SupabaseAuthService.getCurrentUser();
      if (user == null) {
        // Without a user we can still show all groups
        final allGroups = await SupabaseDataService.getGroups();
        setState(() {
          availableGroups = allGroups;
        });
        return;
      }

      // Fetch all groups and user groups from Supabase
      final allGroups = await SupabaseDataService.getGroups();
      final myGroups = await SupabaseDataService.getUserGroups(user.id);
      final myGroupIds = myGroups.map((g) => g.id).toSet();

      setState(() {
        availableGroups = allGroups.where((g) => !myGroupIds.contains(g.id)).toList();
      });
    } catch (e) {
      // Fallback: show local groups excluding any with user in members (legacy)
      final groups = await DataService.getGroups();
      final currentUser = await DataService.getCurrentUser();
      setState(() {
        availableGroups = groups.where((group) =>
          !group.members.any((member) => member.id == currentUser?.id)
        ).toList();
      });
    }
  }

  Future<void> _joinGroup(Group group) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Prefer stored user; fallback to current auth
      final storedUser = await SharedPreferencesService.getStoredUser();
      final currentUser = storedUser ?? await SupabaseAuthService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Please login or register to join a group');
      }

      // Join via Supabase group_members
      final (success, message) = await SupabaseDataService.joinGroup(
        groupId: group.id,
        userId: currentUser.id,
      );

      if (!success) {
        throw Exception(message);
      }

      // Optional: update local cache
      final allGroups = await DataService.getGroups();
      if (!allGroups.any((g) => g.id == group.id)) {
        allGroups.add(group);
        await DataService.saveGroups(allGroups);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined ${group.name}!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinByCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prefer stored user; fallback to current auth
      final storedUser = await SharedPreferencesService.getStoredUser();
      final user = storedUser ?? await SupabaseAuthService.getCurrentUser();
      if (user == null) throw Exception('Please login or register to join by code');

      final code = _groupCodeController.text.trim();
      final (success, message) = await SupabaseDataService.joinGroupByCode(
        code: code,
        userId: user.id,
      );

      if (!success) throw Exception(message);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined group successfully!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E2746),
        elevation: 0,
        title: Text(
          'Join Group',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF1E2746)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.group_add, color: Colors.white, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join Group',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Join an existing mandal group',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Join by Code Section
            Text(
              'Join by Code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF1E2746),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _groupCodeController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Group Code',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.qr_code, color: Color(0xFF6C63FF)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter group code';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _joinByCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Join by Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Available Groups Section
            Text(
              'Available Groups',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            if (availableGroups.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF1E2746),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.group_off, color: Colors.grey[400], size: 48),
                    SizedBox(height: 16),
                    Text(
                      'No available groups',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ask your group admin for an invitation code',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: availableGroups.length,
                itemBuilder: (context, index) {
                  final group = availableGroups[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E2746),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFF6C63FF),
                        child: Icon(Icons.group, color: Colors.white),
                      ),
                      title: Text(
                        group.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            group.description,
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.people, color: Colors.grey[400], size: 16),
                              SizedBox(width: 4),
                              Text(
                                '${group.members.length} members',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                              SizedBox(width: 16),
                              Icon(Icons.currency_rupee, color: Colors.grey[400], size: 16),
                              Text(
                                '${group.monthlyContribution.toStringAsFixed(0)}/month',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: _isLoading ? null : () => _joinGroup(group),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Join',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}