import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/contribution.dart';
import '../../models/group.dart';
import '../../models/loan_request.dart';
import '../../models/repayment.dart';
import '../../models/user.dart';
import '../../services/data_service.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Contribution> contributions = [];
  List<Group> groups = [];
  List<LoanRequest> loanRequests = [];
  List<Repayment> repayments = [];
  Group? selectedGroup;
  User? currentUser;
  bool isLoading = true;
  int selectedTabIndex = 0;

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
    contributions = await DataService.getContributions();
    groups = await DataService.getGroups();
    loanRequests = await DataService.getLoanRequests();
    repayments = await DataService.getRepayments();
    
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
          title: Text('Reports', style: TextStyle(color: Colors.white)),
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
          'Reports',
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
                
                // Tab Bar
                _buildTabBar(),
                
                // Content
                Expanded(
                  child: _buildTabContent(),
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
          Icon(Icons.analytics_outlined, color: Colors.grey[400], size: 64),
          SizedBox(height: 16),
          Text(
            'No Data Available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Join a group to view reports',
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

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1E2746),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTabIndex = 0),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedTabIndex == 0 ? Color(0xFF6C63FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Overview',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: selectedTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTabIndex = 1),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedTabIndex == 1 ? Color(0xFF6C63FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Charts',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: selectedTabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTabIndex = 2),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedTabIndex == 2 ? Color(0xFF6C63FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Summary',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: selectedTabIndex == 2 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildChartsTab();
      case 2:
        return _buildSummaryTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    if (selectedGroup == null) return SizedBox.shrink();

    final groupContributions = contributions.where((c) => c.groupId == selectedGroup!.id).toList();
    final groupLoanRequests = loanRequests.where((l) => l.groupId == selectedGroup!.id).toList();
    final myContributions = groupContributions.where((c) => c.userId == currentUser?.id).toList();
    final myLoanRequests = groupLoanRequests.where((l) => l.requesterId == currentUser?.id).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Overview Card
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
                Text(
                  selectedGroup!.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Group Overview',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildOverviewItem(
                        'Members',
                        '${selectedGroup!.members.length}',
                        Icons.people,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildOverviewItem(
                        'Monthly',
                        '₹${selectedGroup!.monthlyContribution.toStringAsFixed(0)}',
                        Icons.currency_rupee,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // My Statistics
          Text(
            'My Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Contributions',
                  '${myContributions.length}',
                  Icons.payment,
                  Color(0xFF4CAF50),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Loan Requests',
                  '${myLoanRequests.length}',
                  Icons.request_quote,
                  Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Paid',
                  '₹${myContributions.where((c) => c.status == 'Paid').fold(0.0, (sum, c) => sum + c.amount).toStringAsFixed(0)}',
                  Icons.check_circle,
                  Color(0xFF4CAF50),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  '₹${myContributions.where((c) => c.status == 'Pending').fold(0.0, (sum, c) => sum + c.amount).toStringAsFixed(0)}',
                  Icons.schedule,
                  Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    if (selectedGroup == null) return SizedBox.shrink();

    final groupContributions = contributions.where((c) => c.groupId == selectedGroup!.id).toList();
    final paidCount = groupContributions.where((c) => c.status == 'Paid').length;
    final pendingCount = groupContributions.where((c) => c.status == 'Pending').length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contribution Status Pie Chart
          Text(
            'Contribution Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 250,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1E2746),
              borderRadius: BorderRadius.circular(16),
            ),
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: paidCount.toDouble(),
                    title: 'Paid\n$paidCount',
                    color: Color(0xFF4CAF50),
                    radius: 80,
                    titleStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: pendingCount.toDouble(),
                    title: 'Pending\n$pendingCount',
                    color: Color(0xFFFF9800),
                    radius: 80,
                    titleStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          SizedBox(height: 32),

          // Monthly Contributions Bar Chart
          Text(
            'Monthly Trend',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 250,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1E2746),
              borderRadius: BorderRadius.circular(16),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: selectedGroup!.monthlyContribution * selectedGroup!.members.length,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                        if (value.toInt() < months.length) {
                          return Text(
                            months[value.toInt()],
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(6, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (selectedGroup!.monthlyContribution * selectedGroup!.members.length) * 
                             (0.6 + (index * 0.1)), // Mock data
                        color: Color(0xFF6C63FF),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    if (selectedGroup == null) return SizedBox.shrink();

    final groupContributions = contributions.where((c) => c.groupId == selectedGroup!.id).toList();
    final groupLoanRequests = loanRequests.where((l) => l.groupId == selectedGroup!.id).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Table
          Text(
            'Financial Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF1E2746),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Total Members', '${selectedGroup!.members.length}', true),
                _buildSummaryRow('Monthly Contribution', '₹${selectedGroup!.monthlyContribution.toStringAsFixed(0)}', false),
                _buildSummaryRow('Total Monthly Collection', '₹${(selectedGroup!.monthlyContribution * selectedGroup!.members.length).toStringAsFixed(0)}', false),
                _buildSummaryRow('Total Contributions', '${groupContributions.length}', false),
                _buildSummaryRow('Paid Contributions', '${groupContributions.where((c) => c.status == 'Paid').length}', false),
                _buildSummaryRow('Pending Contributions', '${groupContributions.where((c) => c.status == 'Pending').length}', false),
                _buildSummaryRow('Total Loan Requests', '${groupLoanRequests.length}', false),
                _buildSummaryRow('Approved Loans', '${groupLoanRequests.where((l) => l.status == 'Approved').length}', false),
                _buildSummaryRow('Group Created', DateFormat('MMM dd, yyyy').format(selectedGroup!.createdAt), false),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Recent Activity
          Text(
            'Recent Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1E2746),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildActivityItem(
                  Icons.group_add,
                  'Group Created',
                  DateFormat('MMM dd, yyyy').format(selectedGroup!.createdAt),
                  Color(0xFF4CAF50),
                ),
                if (groupContributions.isNotEmpty)
                  _buildActivityItem(
                    Icons.payment,
                    'Latest Contribution',
                    groupContributions.last.period,
                    Color(0xFF2196F3),
                  ),
                if (groupLoanRequests.isNotEmpty)
                  _buildActivityItem(
                    Icons.request_quote,
                    'Latest Loan Request',
                    '₹${groupLoanRequests.last.amount.toStringAsFixed(0)}',
                    Color(0xFFFF9800),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(height: 8),
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
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              Spacer(),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isHeader) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[700]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHeader ? Colors.white : Colors.grey[400],
              fontSize: isHeader ? 16 : 14,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isHeader ? 16 : 14,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
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