import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/shared_preferences_service.dart';
import '../../services/supabase_data_service.dart';
import 'group_members_screen.dart';

class MyGroupsScreen extends StatefulWidget {
  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  bool _isLoading = true;
  User? _currentUser;
  List<Group> _groups = [];
  int _selectedTabIndex = 0; // 0 for Created, 1 for Joined

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final spUser = await SharedPreferencesService.getStoredUser();
      _currentUser = spUser ?? await SupabaseAuthService.getCurrentUser();
      if (_currentUser != null) {
        _groups = await SupabaseDataService.getUserGroups(_currentUser!.id);
      } else {
        _groups = [];
      }
    } catch (e) {
      _groups = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Group> get _filteredGroups {
    if (_currentUser == null) return [];

    if (_selectedTabIndex == 0) {
      // Created groups - where user is admin
      return _groups
          .where((group) => group.adminId == _currentUser!.id)
          .toList();
    } else {
      // Joined groups - where user is member (not admin)
      return _groups
          .where((group) => group.adminId != _currentUser!.id)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2746),
        elevation: 0,
        title: const Text(
          'My Groups',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Tab selector
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2746),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTabIndex = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    _selectedTabIndex == 0
                                        ? const Color(0xFF6C63FF)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Created',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      _selectedTabIndex == 0
                                          ? Colors.white
                                          : Colors.white70,
                                  fontWeight:
                                      _selectedTabIndex == 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTabIndex = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    _selectedTabIndex == 1
                                        ? const Color(0xFF6C63FF)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Joined',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      _selectedTabIndex == 1
                                          ? Colors.white
                                          : Colors.white70,
                                  fontWeight:
                                      _selectedTabIndex == 1
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child:
                        _filteredGroups.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.group_off,
                                    size: 56,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedTabIndex == 0
                                        ? "You haven't created any groups yet"
                                        : "You haven't joined any groups yet",
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _selectedTabIndex == 0
                                        ? 'Create your first group'
                                        : 'Join a group using a code',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _filteredGroups.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final g = _filteredGroups[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E2746),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    title: Text(
                                      g.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        if (g.description.isNotEmpty)
                                          Text(
                                            g.description,
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _chip(
                                              Icons.calendar_month,
                                              '${g.totalMonths} months',
                                            ),
                                            _chip(
                                              Icons.summarize,
                                              '₹${g.totalAmount.toStringAsFixed(0)} total',
                                            ),
                                            _roleChip(
                                              g.adminId == _currentUser?.id,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white54,
                                      size: 16,
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  GroupMembersScreen(group: g),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _roleChip(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            isAdmin
                ? const Color(0xFF6C63FF).withOpacity(0.15)
                : Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isAdmin
                  ? const Color(0xFF6C63FF).withOpacity(0.5)
                  : Colors.green.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person,
            size: 16,
            color: isAdmin ? const Color(0xFF6C63FF) : Colors.green,
          ),
          const SizedBox(width: 6),
          Text(
            isAdmin ? 'Admin' : 'Member',
            style: TextStyle(
              color: isAdmin ? const Color(0xFF6C63FF) : Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
