import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/loan_request.dart';
import '../../models/group.dart';
import '../../models/repayment.dart';
import '../../services/data_service.dart';

class ManageLoansScreen extends StatefulWidget {
  @override
  _ManageLoansScreenState createState() => _ManageLoansScreenState();
}

class _ManageLoansScreenState extends State<ManageLoansScreen> {
  List<LoanRequest> loanRequests = [];
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

    loanRequests = await DataService.getLoanRequests();
    groups = await DataService.getGroups();
    
    if (groups.isNotEmpty) {
      selectedGroup = groups.first;
    }

    setState(() {
      isLoading = false;
    });
  }

  List<LoanRequest> get filteredLoanRequests {
    var filtered = loanRequests;
    
    if (selectedGroup != null) {
      filtered = filtered.where((l) => l.groupId == selectedGroup!.id).toList();
    }
    
    if (filterStatus != 'All') {
      filtered = filtered.where((l) => l.status == filterStatus).toList();
    }
    
    return filtered..sort((a, b) => b.requestDate.compareTo(a.requestDate));
  }

  Future<void> _approveLoan(LoanRequest loanRequest) async {
    final updatedLoanRequest = LoanRequest(
      id: loanRequest.id,
      groupId: loanRequest.groupId,
      requesterId: loanRequest.requesterId,
      amount: loanRequest.amount,
      purpose: loanRequest.purpose,
      durationMonths: loanRequest.durationMonths,
      interestRate: loanRequest.interestRate,
      status: 'Approved',
      requestDate: loanRequest.requestDate,
      approvedDate: DateTime.now(),
    );

    final allLoanRequests = await DataService.getLoanRequests();
    final index = allLoanRequests.indexWhere((l) => l.id == loanRequest.id);
    if (index != -1) {
      allLoanRequests[index] = updatedLoanRequest;
      await DataService.saveLoanRequests(allLoanRequests);
      
      // Create repayment schedule
      await _createRepaymentSchedule(updatedLoanRequest);
      
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loan approved successfully!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  Future<void> _createRepaymentSchedule(LoanRequest loanRequest) async {
    final monthlyAmount = (loanRequest.amount * (1 + loanRequest.interestRate / 100)) / loanRequest.durationMonths;
    final repayments = <Repayment>[];
    
    for (int i = 1; i <= loanRequest.durationMonths; i++) {
      final dueDate = DateTime.now().add(Duration(days: 30 * i));
      
      repayments.add(Repayment(
        id: '${loanRequest.id}_repay_$i',
        loanId: loanRequest.id,
        userId: loanRequest.requesterId,
        amount: monthlyAmount,
        dueDate: dueDate,
        status: 'Pending',
        installmentNumber: i,
        totalInstallments: loanRequest.durationMonths,
      ));
    }
    
    final existingRepayments = await DataService.getRepayments();
    existingRepayments.addAll(repayments);
    await DataService.saveRepayments(existingRepayments);
  }

  Future<void> _rejectLoan(LoanRequest loanRequest) async {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E2746),
        title: Text('Reject Loan Request', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for rejection:',
              style: TextStyle(color: Colors.grey[400]),
            ),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter rejection reason...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6C63FF)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedLoanRequest = LoanRequest(
                id: loanRequest.id,
                groupId: loanRequest.groupId,
                requesterId: loanRequest.requesterId,
                amount: loanRequest.amount,
                purpose: loanRequest.purpose,
                durationMonths: loanRequest.durationMonths,
                interestRate: loanRequest.interestRate,
                status: 'Rejected',
                requestDate: loanRequest.requestDate,
                rejectionReason: reasonController.text,
              );

              final allLoanRequests = await DataService.getLoanRequests();
              final index = allLoanRequests.indexWhere((l) => l.id == loanRequest.id);
              if (index != -1) {
                allLoanRequests[index] = updatedLoanRequest;
                await DataService.saveLoanRequests(allLoanRequests);
                _loadData();
              }
              
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Loan request rejected'),
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
          title: Text('Manage Loans', style: TextStyle(color: Colors.white)),
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
          'Manage Loans',
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
              color: Color(0xFFFF9800),
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
                          children: ['All', 'Pending', 'Approved', 'Rejected'].map((status) {
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
                colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
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
                    '${filteredLoanRequests.length}',
                    Icons.request_quote,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Pending',
                    '${filteredLoanRequests.where((l) => l.status == 'Pending').length}',
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Amount',
                    '₹${filteredLoanRequests.fold(0.0, (sum, l) => sum + l.amount).toStringAsFixed(0)}',
                    Icons.currency_rupee,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          
          // Loan Requests List
          Expanded(
            child: filteredLoanRequests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredLoanRequests.length,
                    itemBuilder: (context, index) {
                      final loanRequest = filteredLoanRequests[index];
                      return _buildLoanCard(loanRequest);
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
            fontSize: 16,
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
          Icon(Icons.request_quote_outlined, color: Colors.grey[400], size: 64),
          SizedBox(height: 16),
          Text(
            'No Loan Requests',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No loan requests match the current filter',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(LoanRequest loanRequest) {
    final statusColor = loanRequest.status == 'Approved' 
        ? Color(0xFF4CAF50)
        : loanRequest.status == 'Rejected'
            ? Color(0xFFE91E63)
            : Color(0xFFFF9800);

    // Get member name (mock data)
    final memberName = 'Member ${loanRequest.requesterId.substring(loanRequest.requesterId.length - 1)}';

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
                        loanRequest.status == 'Approved' 
                            ? Icons.check_circle
                            : loanRequest.status == 'Rejected'
                                ? Icons.cancel
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
                            loanRequest.purpose,
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
                          '₹${loanRequest.amount.toStringAsFixed(0)}',
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
                            loanRequest.status,
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
                    _buildInfoChip('${loanRequest.durationMonths} months', Icons.schedule),
                    SizedBox(width: 12),
                    _buildInfoChip('${loanRequest.interestRate}% interest', Icons.percent),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[400], size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Requested: ${DateFormat('MMM dd, yyyy').format(loanRequest.requestDate)}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    if (loanRequest.approvedDate != null) ...[
                      SizedBox(width: 16),
                      Icon(Icons.check, color: Color(0xFF4CAF50), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Approved: ${DateFormat('MMM dd, yyyy').format(loanRequest.approvedDate!)}',
                        style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
                      ),
                    ],
                  ],
                ),
                if (loanRequest.rejectionReason != null) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFE91E63).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Color(0xFFE91E63), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rejection Reason: ${loanRequest.rejectionReason}',
                            style: TextStyle(color: Color(0xFFE91E63), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (loanRequest.status == 'Pending')
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
                      onPressed: () => _approveLoan(loanRequest),
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
                      onPressed: () => _rejectLoan(loanRequest),
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

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFF0A0E27),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[400], size: 12),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
        ],
      ),
    );
  }
}