import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/contribution.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../../services/data_service.dart';

class ManagePaymentsScreen extends StatefulWidget {
  @override
  _ManagePaymentsScreenState createState() => _ManagePaymentsScreenState();
}

class _ManagePaymentsScreenState extends State<ManagePaymentsScreen> {
  List<Contribution> contributions = [];
  List<Group> groups = [];
  Group? selectedGroup;
  bool isLoading = true;
  String filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    contributions = await DataService.getContributions();
    groups = await DataService.getGroups();
    
    if (groups.isNotEmpty) {
      selectedGroup = groups.first;
    }

    setState(() {
      isLoading = false;
    });
  }

  List<Contribution> get filteredContributions {
    var filtered = contributions;
    
    if (selectedGroup != null) {
      filtered = filtered.where((c) => c.groupId == selectedGroup!.id).toList();
    }
    
    if (filterStatus != 'All') {
      if (filterStatus == 'Overdue') {
        filtered = filtered.where((c) => 
          c.status == 'Pending' && c.dueDate.isBefore(DateTime.now())
        ).toList();
      } else {
        filtered = filtered.where((c) => c.status == filterStatus).toList();
      }
    }
    
    return filtered..sort((a, b) => b.dueDate.compareTo(a.dueDate));
  }

  Future<void> _approvePayment(Contribution contribution) async {
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
          content: Text('Payment approved successfully!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  Future<void> _rejectPayment(Contribution contribution) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E2746),
        title: Text('Reject Payment', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to reject this payment?',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment rejected'),
                  backgroundColor: Color(0xFFE91E63),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE91E63)),
            child: Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF0A0E27),
        appBar: AppBar(
          backgroundColor: Color(0xFF1E2746),
          elevation: 0,
          title: Text('Manage Payments', style: TextStyle(color: Colors.white)),
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
          'Manage Payments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'ADMIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Group Selector
                if (groups.length > 1)
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
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
                  ),
                
                // Status Filter
                Row(
                  children: [
                    Text(
                      'Filter: ',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Pending', 'Paid', 'Overdue'].map((status) {
                            return Container(
                              margin: EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  status,
                                  style: TextStyle(
                                    color: filterStatus == status ? Colors.white : Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                selected: filterStatus == status,
                                onSelected: (selected) {
                                  setState(() {
                                    filterStatus = status;
                                  });
                                },
                                selectedColor: Color(0xFF6C63FF),
                                backgroundColor: Color(0xFF1E2746),
                                checkmarkColor: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Summary Stats
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF1E2746)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total',
                    '${filteredContributions.length}',
                    Icons.receipt,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Pending',
                    '${filteredContributions.where((c) => c.status == 'Pending').length}',
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Overdue',
                    '${filteredContributions.where((c) => c.status == 'Pending' && c.dueDate.isBefore(DateTime.now())).length}',
                    Icons.warning,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Payments List
          Expanded(
            child: filteredContributions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredContributions.length,
                    itemBuilder: (context, index) {
                      final contribution = filteredContributions[index];
                      return _buildPaymentCard(contribution);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
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
            'No Payments Found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No payments match the current filter',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Contribution contribution) {
    final isOverdue = contribution.status == 'Pending' && 
                     contribution.dueDate.isBefore(DateTime.now());
    final statusColor = contribution.status == 'Paid' 
        ? Color(0xFF4CAF50)
        : isOverdue 
            ? Color(0xFFE91E63)
            : Color(0xFFFF9800);

    // Get member name (mock data)
    final memberName = 'Member ${contribution.userId.substring(contribution.userId.length - 1)}';

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
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
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
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memberName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            contribution.period,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${contribution.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOverdue ? 'Overdue' : contribution.status,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[400], size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Due: ${DateFormat('MMM dd, yyyy').format(contribution.dueDate)}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    if (contribution.paidDate != null) ...[
                      SizedBox(width: 16),
                      Icon(Icons.check, color: Color(0xFF4CAF50), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Paid: ${DateFormat('MMM dd, yyyy').format(contribution.paidDate!)}',
                        style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (contribution.status == 'Pending')
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF0A0E27),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approvePayment(contribution),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Approve',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _rejectPayment(contribution),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE91E63),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Reject',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
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