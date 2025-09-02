import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/repayment.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../../services/data_service.dart';

class RepaymentsScreen extends StatefulWidget {
  @override
  _RepaymentsScreenState createState() => _RepaymentsScreenState();
}

class _RepaymentsScreenState extends State<RepaymentsScreen> {
  List<Repayment> repayments = [];
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

    currentUser = await DataService.getCurrentUser();
    repayments = await DataService.getRepayments();
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

  List<Repayment> get filteredRepayments {
    if (currentUser == null) return [];
    return repayments
        .where((r) => r.userId == currentUser!.id)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Future<void> _markAsPaid(Repayment repayment) async {
    final updatedRepayment = Repayment(
      id: repayment.id,
      loanId: repayment.loanId,
      userId: repayment.userId,
      amount: repayment.amount,
      dueDate: repayment.dueDate,
      paidDate: DateTime.now(),
      status: 'Paid',
      installmentNumber: repayment.installmentNumber,
      totalInstallments: repayment.totalInstallments,
    );

    final allRepayments = await DataService.getRepayments();
    final index = allRepayments.indexWhere((r) => r.id == repayment.id);
    if (index != -1) {
      allRepayments[index] = updatedRepayment;
      await DataService.saveRepayments(allRepayments);
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Repayment marked as completed!'),
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
          title: Text('Repayments', style: TextStyle(color: Colors.white)),
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
          'Repayments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Summary Card
          _buildSummaryCard(),
          
          // Repayments List
          Expanded(
            child: _buildRepaymentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final allRepayments = filteredRepayments;
    final paidRepayments = allRepayments.where((r) => r.status == 'Paid').length;
    final pendingRepayments = allRepayments.where((r) => r.status == 'Pending').length;
    final overdueRepayments = allRepayments.where((r) => 
      r.status == 'Pending' && r.dueDate.isBefore(DateTime.now())
    ).length;
    final totalPaid = allRepayments
        .where((r) => r.status == 'Paid')
        .fold(0.0, (sum, r) => sum + r.amount);
    final totalPending = allRepayments
        .where((r) => r.status == 'Pending')
        .fold(0.0, (sum, r) => sum + r.amount);

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
              Icon(Icons.schedule_send, color: Colors.white, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMI Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Your loan repayment schedule',
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
                  '$paidRepayments',
                  Color(0xFF4CAF50),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Pending',
                  '$pendingRepayments',
                  Color(0xFFFF9800),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Overdue',
                  '$overdueRepayments',
                  Color(0xFFE91E63),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAmountItem(
                  'Total Paid',
                  '₹${totalPaid.toStringAsFixed(0)}',
                  Color(0xFF4CAF50),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildAmountItem(
                  'Remaining',
                  '₹${totalPending.toStringAsFixed(0)}',
                  Color(0xFFFF9800),
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

  Widget _buildAmountItem(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentsList() {
    final repaymentsList = filteredRepayments;

    if (repaymentsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule_send_outlined, color: Colors.grey[400], size: 64),
            SizedBox(height: 16),
            Text(
              'No Repayments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your loan repayments will appear here',
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
      itemCount: repaymentsList.length,
      itemBuilder: (context, index) {
        final repayment = repaymentsList[index];
        return _buildRepaymentCard(repayment);
      },
    );
  }

  Widget _buildRepaymentCard(Repayment repayment) {
    final isOverdue = repayment.status == 'Pending' && 
                     repayment.dueDate.isBefore(DateTime.now());
    final statusColor = repayment.status == 'Paid' 
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
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        repayment.status == 'Paid' 
                            ? Icons.check_circle
                            : isOverdue
                                ? Icons.warning
                                : Icons.schedule,
                        color: statusColor,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMI ${repayment.installmentNumber}/${repayment.totalInstallments}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '₹${repayment.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOverdue ? 'Overdue' : repayment.status,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Due Date',
                        DateFormat('MMM dd, yyyy').format(repayment.dueDate),
                      ),
                    ),
                    if (repayment.paidDate != null)
                      Expanded(
                        child: _buildInfoItem(
                          'Paid Date',
                          DateFormat('MMM dd, yyyy').format(repayment.paidDate!),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12),
                // Progress Bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: repayment.installmentNumber / repayment.totalInstallments,
                    child: Container(
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Progress: ${repayment.installmentNumber}/${repayment.totalInstallments} installments',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (repayment.status == 'Pending')
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _markAsPaid(repayment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Mark as Paid',
                            style: TextStyle(color: Colors.white),
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

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}