import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../../services/data_service.dart';

class MembersScreen extends StatefulWidget {
  @override
  _MembersScreenState createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<Group> groups = [];
  Group? selectedGroup;
  bool isLoading = true;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    currentUser = await DataService.getCurrentUser();
    groups = await DataService.getGroups();
    
    // Filter groups where current user is a member
    groups = groups.where((group) => 
      group.members.any((member) => member.id == currentUser?.id)
    ).toList();

    if (groups.isNotEmpty) {
      selectedGroup = groups.first;
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF0A0E27),
        appBar: AppBar(
          backgroundColor: Color(0xFF1E2746),
          elevation: 0,
          title: Text('Members', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E2746),
        elevation: 0,
        title: Text(
          'Members',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (selectedGroup != null && selectedGroup!.adminId == currentUser?.id)
            IconButton(
              icon: Icon(Icons.person_add, color: Colors.white),
              onPressed: _showInviteDialog,
            ),
        ],
      ),
      body: groups.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Group Selector
                if (groups.length > 1) _buildGroupSelector(),
                
                // Members List
                Expanded(
                  child: selectedGroup == null
                      ? _buildEmptyState()
                      : _buildMembersList(),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, color: Colors.grey[400], size: 64),
          SizedBox(height: 16),
          Text(
            'No Groups Found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Join or create a group to see members',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1E2746),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Group>(
          value: selectedGroup,
          isExpanded: true,
          dropdownColor: Color(0xFF1E2746),
          style: TextStyle(color: Colors.white),
          icon: Icon(Icons.arrow_drop_down, color: Colors.white),
          items: groups.map((group) {
            return DropdownMenuItem<Group>(
              value: group,
              child: Text(
                group.name,
                style: TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (Group? newValue) {
            setState(() {
              selectedGroup = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Info Card
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.group, color: Colors.white, size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedGroup!.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            selectedGroup!.description,
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
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(
                      '${selectedGroup!.members.length}',
                      'Members',
                      Icons.people,
                    ),
                    SizedBox(width: 16),
                    _buildInfoChip(
                      '₹${selectedGroup!.monthlyContribution.toStringAsFixed(0)}',
                      'Monthly',
                      Icons.currency_rupee,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Members Section
          Text(
            'Members (${selectedGroup!.members.length})',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Members List
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: selectedGroup!.members.length,
            itemBuilder: (context, index) {
              final member = selectedGroup!.members[index];
              final isAdmin = member.id == selectedGroup!.adminId;
              final isCurrentUser = member.id == currentUser?.id;

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Color(0xFF1E2746),
                  borderRadius: BorderRadius.circular(12),
                  border: isCurrentUser 
                      ? Border.all(color: Color(0xFF6C63FF), width: 2)
                      : null,
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? Color(0xFFFFD700) : Color(0xFF6C63FF),
                    child: Text(
                      member.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: isAdmin ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        member.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFF6C63FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'You',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        member.email,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        member.phone,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isAdmin ? Color(0xFFFFD700) : Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isAdmin ? 'Admin' : 'Member',
                          style: TextStyle(
                            color: isAdmin ? Colors.black : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String value, String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E2746),
        title: Text(
          'Invite Members',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share this group code with others:',
              style: TextStyle(color: Colors.grey[400]),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF0A0E27),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (selectedGroup!.joinCode.isNotEmpty
                    ? selectedGroup!.joinCode
                    : selectedGroup!.id.substring(0, 4).toUpperCase()),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: Color(0xFF6C63FF)),
            ),
          ),
        ],
      ),
    );
  }
}