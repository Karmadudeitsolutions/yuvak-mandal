import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/contribution.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../../services/data_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/supabase_data_service.dart';

class ContributionsScreen extends StatefulWidget {
  @override
  _ContributionsScreenState createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen> {
  List<Contribution> contributions = [];
  List<Group> groups = [];
  Group? selectedGroup;
  User? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    // Load current user
    currentUser = await SupabaseAuthService.getCurrentUser() ?? await DataService.getCurrentUser();

    // Load groups from Supabase membership; fallback to local
    try {
      if (currentUser != null) {
        groups = await SupabaseDataService.getUserGroups(currentUser!.id);
      }
      if (groups.isEmpty) {
        // Fallback to local groups (legacy) filtered by member list
        final localGroups = await DataService.getGroups();
        groups = localGroups.where((g) => g.members.any((m) => m.id == currentUser?.id)).toList();
      }
    } catch (_) {
      final localGroups = await DataService.getGroups();
      groups = localGroups.where((g) => g.members.any((m) => m.id == currentUser?.id)).toList();
    }

    // Load contributions (still local for now)
    contributions = await DataService.getContributions();

    if (groups.isNotEmpty) {
      selectedGroup = groups.first;
    }

    setState(() {
      isLoading = false;
    });
  }

  List<Contribution> get filteredContributions {
    if (selectedGroup == null) return [];
    return contributions
        .where((c) => c.groupId == selectedGroup!.id && c.userId == currentUser?.id)
        .toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
  }

  Future<void> _markAsPaid(Contribution contribution) async {
    final updatedContribution = Contribution(
      id: contribution.id,
      groupId: contribution.groupId,
      userId: contribution.userId,
      amount: contribution.amount,
      dueDate: contribution.dueDate,
      paidDate: DateTime.now(),
      status: 'Paid',
      period: contribution.period,
    );

    final allContributions = await DataService.getContributions();
    final index = allContributions.indexWhere((c) => c.id == contribution.id);
    if (index != -1) {
      allContributions[index] = updatedContribution;
      await DataService.saveContributions(allContributions);
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment marked as completed!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF0A0E27),
        appBar: AppBar(
          backgroundColor: Color(0xFF1E2746),
          elevation: 0,
          title: Text('Contributions', style: TextStyle(color: Colors.white)),
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
          'Contributions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: groups.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Group Selector
                if (groups.length > 1) _buildGroupSelector(),
                
                // Summary Card
                _buildSummaryCard(),
                
                // Contributions List
                Expanded(
                  child: _buildContributionsList(),
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
          Icon(Icons.payment_outlined, color: Colors.grey[400], size: 64),
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
            'Join a group to start making contributions',
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

  Widget _buildSummaryCard() {
    if (selectedGroup == null) return SizedBox.shrink();

    final paidContributions = filteredContributions.where((c) => c.status == 'Paid').length;
    final pendingContributions = filteredContributions.where((c) => c.status == 'Pending').length;
    final totalPaid = filteredContributions
        .where((c) => c.status == 'Paid')
        .fold(0.0, (sum, c) => sum + c.amount);

    return Container(
      margin: EdgeInsets.all(16),
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
              Icon(Icons.payment, color: Colors.white, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedGroup!.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Monthly: ₹${selectedGroup!.monthlyContribution.toStringAsFixed(0)}',
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
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Paid',
                  '$paidContributions',
                  Color(0xFF4CAF50),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Pending',
                  '$pendingContributions',
                  Color(0xFFFF9800),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Total Paid',
                  '₹${totalPaid.toStringAsFixed(0)}',
                  Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionsList() {
    if (selectedGroup == null) return SizedBox.shrink();

    final contributions = filteredContributions;

    if (contributions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, color: Colors.grey[400], size: 64),
            SizedBox(height: 16),
            Text(
              'No Contributions Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your contribution history will appear here',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: contributions.length,
      itemBuilder: (context, index) {
        final contribution = contributions[index];
        return _buildContributionCard(contribution);
      },
    );
  }

  Widget _buildContributionCard(Contribution contribution) {
    final isOverdue = contribution.status == 'Pending' && 
                     contribution.dueDate.isBefore(DateTime.now());
    final statusColor = contribution.status == 'Paid' 
        ? Color(0xFF4CAF50)
        : isOverdue 
            ? Color(0xFFE91E63)
            : Color(0xFFFF9800);

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
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                contribution.status == 'Paid' 
                    ? Icons.check_circle
                    : isOverdue
                        ? Icons.warning
                        : Icons.schedule,
                color: statusColor,
              ),
            ),
            title: Text(
              contribution.period,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  'Amount: ₹${contribution.amount.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                SizedBox(height: 4),
                Text(
                  'Due: ${DateFormat('MMM dd, yyyy').format(contribution.dueDate)}',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                if (contribution.paidDate != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'Paid: ${DateFormat('MMM dd, yyyy').format(contribution.paidDate!)}',
                    style: TextStyle(color: Color(0xFF4CAF50)),
                  ),
                ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOverdue ? 'Overdue' : contribution.status,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (contribution.status == 'Pending')
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _markAsPaid(contribution),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Mark as Paid',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}