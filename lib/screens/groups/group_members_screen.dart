import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../../services/supabase_data_service.dart';

class GroupMembersScreen extends StatefulWidget {
  final Group group;

  const GroupMembersScreen({Key? key, required this.group}) : super(key: key);

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  bool _isLoading = true;
  List<User> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      _members = await SupabaseDataService.getGroupMembers(widget.group.id);
    } catch (e) {
      print('Error loading group members: $e');
      _members = [];
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
        title: Text(
          '${widget.group.name} Members',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMembers,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Group info header
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.group.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.group.description,
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _infoChip(
                              Icons.people,
                              '${_members.length} members',
                            ),
                            const SizedBox(width: 12),
                            _infoChip(
                              Icons.calendar_month,
                              '${widget.group.totalMonths} months',
                            ),
                            const SizedBox(width: 12),
                            _infoChip(
                              Icons.currency_rupee,
                              '₹${widget.group.totalAmount.toStringAsFixed(0)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Members list
                  Expanded(
                    child:
                        _members.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 56,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No members found',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            )
                            : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _members.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final member = _members[index];
                                final isAdmin =
                                    member.id == widget.group.adminId;

                                return _buildMemberCard(member, isAdmin);
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildMemberCard(User member, bool isAdmin) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2746),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            isAdmin
                ? Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                  width: 1,
                )
                : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header with avatar and role
            Row(
              children: [
                // Avatar with gradient background
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors:
                          isAdmin
                              ? [
                                const Color(0xFF6C63FF),
                                const Color(0xFF8B7EFF),
                              ]
                              : [Colors.green, Colors.lightGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isAdmin
                                ? const Color(0xFF6C63FF)
                                : Colors.green)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Name and role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _roleChip(isAdmin),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Contact information
            _buildContactInfo(member),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(User member) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          if (member.email.isNotEmpty)
            _buildContactRow(
              Icons.email_outlined,
              'Email',
              member.email,
              const Color(0xFF64B5F6),
            ),
          if (member.email.isNotEmpty && member.phone.isNotEmpty)
            const SizedBox(height: 12),
          if (member.phone.isNotEmpty)
            _buildContactRow(
              Icons.phone_outlined,
              'Phone',
              member.phone,
              const Color(0xFF81C784),
            ),
          if (member.email.isEmpty && member.phone.isEmpty)
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.grey[500]),
                const SizedBox(width: 12),
                Text(
                  'No contact information available',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
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
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
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
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
