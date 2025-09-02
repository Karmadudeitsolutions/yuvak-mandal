import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/loan_request.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../../services/data_service.dart';

class LoanRequestsScreen extends StatefulWidget {
  @override
  _LoanRequestsScreenState createState() => _LoanRequestsScreenState();
}

class _LoanRequestsScreenState extends State<LoanRequestsScreen> {
  List<LoanRequest> loanRequests = [];
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
    loanRequests = await DataService.getLoanRequests();
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

  List<LoanRequest> get filteredLoanRequests {
    if (selectedGroup == null) return [];
    return loanRequests
        .where((l) => l.groupId == selectedGroup!.id)
        .toList()
      ..sort((a, b) => b.requestDate.compareTo(a.requestDate));
  }

  Future<void> _showCreateLoanDialog() async {
    showDialog(
      context: context,
      builder: (context) => _LoanRequestDialog(
        onSubmit: _createLoanRequest,
      ),
    );
  }

  Future<void> _createLoanRequest(double amount, String purpose, int duration, double interest) async {
    if (selectedGroup == null || currentUser == null) return;

    final newLoanRequest = LoanRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      groupId: selectedGroup!.id,
      requesterId: currentUser!.id,
      amount: amount,
      purpose: purpose,
      durationMonths: duration,
      interestRate: interest,
      status: 'Pending',
      requestDate: DateTime.now(),
    );

    final allLoanRequests = await DataService.getLoanRequests();
    allLoanRequests.add(newLoanRequest);
    await DataService.saveLoanRequests(allLoanRequests);
    
    _loadData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loan request submitted successfully!'),
        backgroundColor: Color(0xFF4CAF50),
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
          title: Text('Loan Requests', style: TextStyle(color: Colors.white)),
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
          'Loan Requests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: selectedGroup != null ? _showCreateLoanDialog : null,
          ),
        ],
      ),
      body: groups.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Group Selector
                if (groups.length > 1) _buildGroupSelector(),
                
                // Summary Card
                _buildSummaryCard(),
                
                // Loan Requests List
                Expanded(
                  child: _buildLoanRequestsList(),
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
          Icon(Icons.request_quote_outlined, color: Colors.grey[400], size: 64),
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
            'Join a group to request loans',
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

    final requests = filteredLoanRequests;
    final pendingRequests = requests.where((r) => r.status == 'Pending').length;
    final approvedRequests = requests.where((r) => r.status == 'Approved').length;
    final totalRequested = requests
        .where((r) => r.requesterId == currentUser?.id)
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
              Icon(Icons.request_quote, color: Colors.white, size: 32),
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
                      'Loan Requests Overview',
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
                  'Pending',
                  '$pendingRequests',
                  Color(0xFFFF9800),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Approved',
                  '$approvedRequests',
                  Color(0xFF4CAF50),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'My Total',
                  '₹${totalRequested.toStringAsFixed(0)}',
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

  Widget _buildLoanRequestsList() {
    if (selectedGroup == null) return SizedBox.shrink();

    final requests = filteredLoanRequests;

    if (requests.isEmpty) {
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
              'Tap + to create your first loan request',
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
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildLoanRequestCard(request);
      },
    );
  }

  Widget _buildLoanRequestCard(LoanRequest request) {
    final statusColor = request.status == 'Approved' 
        ? Color(0xFF4CAF50)
        : request.status == 'Rejected'
            ? Color(0xFFE91E63)
            : Color(0xFFFF9800);

    final isMyRequest = request.requesterId == currentUser?.id;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1E2746),
        borderRadius: BorderRadius.circular(12),
        border: isMyRequest 
            ? Border.all(color: Color(0xFF6C63FF), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
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
                    request.status == 'Approved' 
                        ? Icons.check_circle
                        : request.status == 'Rejected'
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
                        '₹${request.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.purpose,
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
                    request.status,
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
                _buildInfoItem('Duration', '${request.durationMonths} months'),
                SizedBox(width: 24),
                _buildInfoItem('Interest', '${request.interestRate}%'),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem('Requested', DateFormat('MMM dd, yyyy').format(request.requestDate)),
                if (request.approvedDate != null) ...[
                  SizedBox(width: 24),
                  _buildInfoItem('Approved', DateFormat('MMM dd, yyyy').format(request.approvedDate!)),
                ],
              ],
            ),
            if (isMyRequest) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Your Request',
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

class _LoanRequestDialog extends StatefulWidget {
  final Function(double, String, int, double) onSubmit;

  const _LoanRequestDialog({required this.onSubmit});

  @override
  _LoanRequestDialogState createState() => _LoanRequestDialogState();
}

class _LoanRequestDialogState extends State<_LoanRequestDialog> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final purposeController = TextEditingController();
  final durationController = TextEditingController();
  final interestController = TextEditingController(text: '2.0');

  double _loanAmount = 0.0;
  int _duration = 0;
  double _interestRate = 2.0;
  double _totalPayable = 0.0;
  double _totalInterest = 0.0;
  double _monthlyPayment = 0.0;

  @override
  void initState() {
    super.initState();
    amountController.addListener(_calculateLoan);
    durationController.addListener(_calculateLoan);
    interestController.addListener(_calculateLoan);
  }

  @override
  void dispose() {
    amountController.dispose();
    purposeController.dispose();
    durationController.dispose();
    interestController.dispose();
    super.dispose();
  }

  void _calculateLoan() {
    setState(() {
      _loanAmount = double.tryParse(amountController.text) ?? 0.0;
      _duration = int.tryParse(durationController.text) ?? 0;
      _interestRate = double.tryParse(interestController.text) ?? 0.0;

      if (_loanAmount > 0 && _duration > 0 && _interestRate >= 0) {
        // Simple interest calculation: Total = Principal + (Principal * Rate * Time / 100)
        _totalInterest = (_loanAmount * _interestRate * _duration) / 100;
        _totalPayable = _loanAmount + _totalInterest;
        _monthlyPayment = _duration > 0 ? _totalPayable / _duration : 0.0;
      } else {
        _totalPayable = 0.0;
        _totalInterest = 0.0;
        _monthlyPayment = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF1E2746),
      title: Text(
        'Request Loan',
        style: TextStyle(color: Colors.white),
      ),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6C63FF)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter valid amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: purposeController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Purpose',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6C63FF)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter purpose';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Duration (months)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6C63FF)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter valid duration';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: interestController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Interest Rate (%)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6C63FF)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter interest rate';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter valid interest rate';
                  }
                  return null;
                },
              ),
              
              // Loan Calculation Display
              if (_loanAmount > 0 && _duration > 0) ...[
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C63FF).withOpacity(0.1), Color(0xFF1E2746)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calculate, color: Color(0xFF6C63FF), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Loan Calculation',
                            style: TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildCalculationRow('Loan Amount', '₹${_loanAmount.toStringAsFixed(0)}'),
                      SizedBox(height: 8),
                      _buildCalculationRow('Interest ($_interestRate% for $_duration months)', '₹${_totalInterest.toStringAsFixed(0)}'),
                      SizedBox(height: 8),
                      Divider(color: Colors.grey[600]),
                      SizedBox(height: 8),
                      _buildCalculationRow('Total Payable Amount', '₹${_totalPayable.toStringAsFixed(0)}', isTotal: true),
                      SizedBox(height: 8),
                      _buildCalculationRow('Monthly Payment', '₹${_monthlyPayment.toStringAsFixed(0)}', isHighlight: true),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              await widget.onSubmit(
                double.parse(amountController.text),
                purposeController.text,
                int.parse(durationController.text),
                double.parse(interestController.text),
              );
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6C63FF),
          ),
          child: Text(
            'Submit',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationRow(String label, String value, {bool isTotal = false, bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.grey[300],
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? Color(0xFF6C63FF) : (isTotal ? Colors.white : Colors.grey[300]),
            fontSize: isTotal || isHighlight ? 14 : 13,
            fontWeight: isTotal || isHighlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}