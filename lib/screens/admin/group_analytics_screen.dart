import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/contribution.dart';
import '../../models/group.dart';
import '../../models/loan_request.dart';
import '../../services/data_service.dart';

class GroupAnalyticsScreen extends StatefulWidget {
  @override
  _GroupAnalyticsScreenState createState() => _GroupAnalyticsScreenState();
}

class _GroupAnalyticsScreenState extends State<GroupAnalyticsScreen> {
  List<Group> groups = [];
  List<Contribution> contributions = [];
  List<LoanRequest> loanRequests = [];
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

    groups = await DataService.getGroups();
    contributions = await DataService.getContributions();
    loanRequests = await DataService.getLoanRequests();

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
          title: Text('Group Analytics', style: TextStyle(color: Colors.white)),
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
          'Group Analytics',
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
              color: Color(0xFF2196F3),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Stats
            Text(
              'System Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Groups',
                    '${groups.length}',
                    Icons.group,
                    Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Members',
                    '${groups.fold(0, (sum, group) => sum + group.members.length)}',
                    Icons.people,
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
                    'Total Funds',
                    '₹${groups.fold(0.0, (sum, group) => sum + (group.monthlyContribution * group.members.length)).toStringAsFixed(0)}',
                    Icons.account_balance_wallet,
                    Color(0xFFFF9800),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Active Loans',
                    '${loanRequests.where((l) => l.status == 'Approved').length}',
                    Icons.request_quote,
                    Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),

            // Payment Status Chart
            Text(
              'Payment Status Distribution',
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
                      value: contributions.where((c) => c.status == 'Paid').length.toDouble(),
                      title: 'Paid\n${contributions.where((c) => c.status == 'Paid').length}',
                      color: Color(0xFF4CAF50),
                      radius: 80,
                      titleStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: contributions.where((c) => c.status == 'Pending').length.toDouble(),
                      title: 'Pending\n${contributions.where((c) => c.status == 'Pending').length}',
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

            // Group Performance
            Text(
              'Group Performance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _buildGroupPerformanceCard(group);
              },
            ),
            SizedBox(height: 32),

            // Loan Status Chart
            Text(
              'Loan Request Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF1E2746),
                borderRadius: BorderRadius.circular(16),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: loanRequests.length.toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const statuses = ['Pending', 'Approved', 'Rejected'];
                          if (value.toInt() < statuses.length) {
                            return Text(
                              statuses[value.toInt()],
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
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: loanRequests.where((l) => l.status == 'Pending').length.toDouble(),
                          color: Color(0xFFFF9800),
                          width: 30,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: loanRequests.where((l) => l.status == 'Approved').length.toDouble(),
                          color: Color(0xFF4CAF50),
                          width: 30,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: loanRequests.where((l) => l.status == 'Rejected').length.toDouble(),
                          color: Color(0xFFE91E63),
                          width: 30,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildGroupPerformanceCard(Group group) {
    final groupContributions = contributions.where((c) => c.groupId == group.id).toList();
    final paidContributions = groupContributions.where((c) => c.status == 'Paid').length;
    final totalContributions = groupContributions.length;
    final performancePercentage = totalContributions > 0 ? (paidContributions / totalContributions * 100) : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${group.members.length} members • ₹${group.monthlyContribution.toStringAsFixed(0)}/month',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: performancePercentage >= 80 
                      ? Color(0xFF4CAF50)
                      : performancePercentage >= 60
                          ? Color(0xFFFF9800)
                          : Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${performancePercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGroupStat('Paid', '$paidContributions', Color(0xFF4CAF50)),
              ),
              Expanded(
                child: _buildGroupStat('Pending', '${totalContributions - paidContributions}', Color(0xFFFF9800)),
              ),
              Expanded(
                child: _buildGroupStat('Total Fund', '₹${(group.monthlyContribution * group.members.length).toStringAsFixed(0)}', Color(0xFF2196F3)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}