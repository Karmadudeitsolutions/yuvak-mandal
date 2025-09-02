import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/shared_preferences_service.dart';
import '../../services/supabase_data_service.dart';

class MyGroupsScreen extends StatefulWidget {
  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  bool _isLoading = true;
  User? _currentUser;
  List<Group> _groups = [];

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2746),
        elevation: 0,
        title: const Text('My Groups', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_off, size: 56, color: Colors.grey[500]),
                      const SizedBox(height: 12),
                      Text(
                        "You haven't joined any groups yet",
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Join a group using a code or create one',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final g = _groups[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2746),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Text(g.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            if (g.description.isNotEmpty)
                              Text(g.description, style: TextStyle(color: Colors.grey[400])),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              children: [
                                _chip(Icons.calendar_month, '${g.totalMonths} months'),
                                _chip(Icons.summarize, '₹${g.totalAmount.toStringAsFixed(0)} total'),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                        onTap: () {
                          // TODO: Navigate to group details/members if needed
                        },
                      ),
                    );
                  },
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
}