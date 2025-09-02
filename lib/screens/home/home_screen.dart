import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/group.dart';
import '../../models/contribution.dart';
import '../../models/loan_request.dart';
import '../../services/data_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/shared_preferences_service.dart';
import '../../services/supabase_data_service.dart';
import '../groups/create_group_screen.dart';
import '../groups/join_group_screen.dart';
import '../groups/my_groups_screen.dart';
import '../groups/members_screen.dart';
import '../contributions/contributions_screen.dart';
import '../loans/loan_requests_screen.dart';
import '../repayments/repayments_screen.dart';
import '../reports/reports_screen.dart';
import '../../AuthenticationScreen/LoginScreen1.dart';
import '../admin/admin_dashboard.dart';
import '../profile/profile_screen.dart';
import '../dues/dues_screen.dart';
import '../dues/monthly_payments_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? currentUser;
  List<Group> groups = [];
  List<Contribution> contributions = [];
  List<Contribution> myContributions = [];
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

    // Prefer user from SupabaseAuthService/SharedPreferences
    final spUser = await SharedPreferencesService.getStoredUser();
    currentUser = spUser ?? await SupabaseAuthService.getCurrentUser();

    // Fetch user's groups from Supabase; fallback to local
    try {
      if (currentUser != null) {
        groups = await SupabaseDataService.getUserGroups(currentUser!.id);
        // Get user's contributions
        final allContributions = await SupabaseDataService.getContributions();
        myContributions = allContributions.where((c) => c.userId == currentUser!.id).toList();
      } else {
        groups = [];
        myContributions = [];
      }
      // TODO: Replace with SupabaseDataService when contributions/loans are wired fully
      contributions = await DataService.getContributions();
      loanRequests = await DataService.getLoanRequests();
    } catch (e) {
      // Fallback to local groups (legacy)
      groups = await DataService.getGroups();
      contributions = await DataService.getContributions();
      loanRequests = await DataService.getLoanRequests();
      myContributions = [];
    }

    setState(() {
      isLoading = false;
    });
  }

  double get totalGroupBalance {
    return groups.fold(0.0, (sum, group) => sum + group.totalAmount);
  }

  int get totalMonthsFromGroups {
    return groups.fold(0, (sum, group) => sum + group.totalMonths);
  }

  int get completedPayments {
    return myContributions.length;
  }

  double get totalPaidAmount {
    return myContributions.fold(0.0, (sum, contribution) => sum + contribution.amount);
  }

  double get totalPendingAmount {
    double totalRequired = 0.0;
    for (final group in groups) {
      // Calculate total required for this group (monthly contribution * total months)
      totalRequired += group.monthlyContribution * group.totalMonths;
    }
    return totalRequired - totalPaidAmount;
  }

  double get totalPayableAmount {
    return groups.fold(0.0, (sum, group) => sum + (group.monthlyContribution * group.totalMonths));
  }

  double get paymentProgress {
    if (totalPayableAmount == 0) return 0.0;
    return (totalPaidAmount / totalPayableAmount).clamp(0.0, 1.0);
  }

  int get pendingLoanRequests {
    return loanRequests.where((l) => l.status == 'Pending').length;
  }

  bool get isAdmin {
    return currentUser?.role == 'Admin' || currentUser?.role == 'Manager';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading Dashboard...',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Yuvak Mandal',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminDashboard()),
                );
              },
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              } else if (value == 'logout') {
                await SupabaseAuthService.logout();
                await SharedPreferencesService.clearLoginData();
                await DataService.clearCurrentUser();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen1()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                currentUser?.name ?? 'User',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isAdmin)
                                Container(
                                  margin: EdgeInsets.only(top: 8),
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (currentUser?.role ?? 'USER').toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),

              // Financial Overview Cards
              Text(
                'Financial Overview',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              
              // Main Balance Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.green, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Total Group Balance',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '₹${totalGroupBalance.toStringAsFixed(0)}',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Circular Payment Progress Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Payment Overview',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Circular Progress Indicator
                    Container(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background Circle
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          
                          // Progress Indicator
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: paymentProgress,
                              strokeWidth: 12,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                paymentProgress > 0.8 
                                    ? Colors.green
                                    : paymentProgress > 0.5 
                                        ? Colors.orange 
                                        : Colors.blue,
                              ),
                            ),
                          ),
                          
                          // Center Content
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'OUTSTANDING',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '₹${totalPendingAmount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '₹${(totalPendingAmount * 0.02).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                Text(
                                  'INTEREST',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Progress Percentage
                          Positioned(
                            top: 20,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${(paymentProgress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Payment Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Paid',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '₹${totalPaidAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        Column(
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '₹${totalPayableAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Pay Button
                    if (totalPendingAmount > 0)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _handlePaymentNavigation();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Pay ₹${totalPendingAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'All Payments Complete!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: 12),
              
              // View Breakdown Button
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    _showPaymentBreakdown(context);
                  },
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.blue.shade600,
                    size: 18,
                  ),
                  label: Text(
                    'View breakdown',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DuesScreen(
                              userGroups: groups,
                              onPaymentSuccess: _loadData,
                            ),
                          ),
                        );
                      },
                      child: _buildStatCard(
                        'Total Months',
                        '${totalMonthsFromGroups}',
                        Icons.payment,
                        Colors.orange,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Active Groups',
                      '${groups.length}',
                      Icons.group,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Completed Payments Section
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Completed Payments',
                      '${completedPayments}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Paid',
                      '₹${totalPaidAmount.toStringAsFixed(0)}',
                      Icons.payments,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              
              if (isAdmin) ...[
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Pending Approvals',
                        '$pendingLoanRequests',
                        Icons.pending_actions,
                        Colors.red,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Total Members',
                        '${groups.fold(0, (sum, group) => sum + group.members.length)}',
                        Icons.people,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
              
              SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              
              // Action Buttons Grid
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2, // more vertical space to avoid overflow on small screens
                children: [
                  _buildQuickActionButton(
                    'Create Group',
                    Icons.add_circle_outline,
                    Colors.green,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateGroupScreen())),
                  ),
                  _buildQuickActionButton(
                    'Join Group',
                    Icons.group_add,
                    Colors.blue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => JoinGroupScreen())),
                  ),
                  _buildQuickActionButton(
                    'My Groups',
                    Icons.groups_2,
                    Colors.indigo,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyGroupsScreen())),
                  ),
                  _buildQuickActionButton(
                    'Members',
                    Icons.people_outline,
                    Colors.orange,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => MembersScreen())),
                  ),
                  _buildQuickActionButton(
                    'Contributions',
                    Icons.payment,
                    Colors.purple,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => ContributionsScreen())),
                  ),
                  _buildQuickActionButton(
                    'Loan Requests',
                    Icons.request_quote,
                    Colors.pink,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoanRequestsScreen())),
                  ),
                  _buildQuickActionButton(
                    'Repayments',
                    Icons.schedule_send,
                    Colors.cyan,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => RepaymentsScreen())),
                  ),
                  _buildQuickActionButton(
                    'Reports',
                    Icons.analytics_outlined,
                    Colors.brown,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportsScreen())),
                  ),
                ],
              ),
              
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, MaterialColor color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color.shade800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), // slightly smaller padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44, // smaller icon container
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePaymentNavigation() {
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No groups found. Please join a group first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // If only one group, navigate directly to monthly payments
    if (groups.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MonthlyPaymentsScreen(group: groups.first),
        ),
      );
      return;
    }

    // Multiple groups - show selection dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Group',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose a group to make payment:',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                SizedBox(height: 16),
                ...groups.map((group) {
                  // Calculate pending amount for this group
                  final groupTotal = group.monthlyContribution * group.totalMonths;
                  final groupPaid = myContributions
                      .where((c) => c.groupId == group.id)
                      .fold(0.0, (sum, c) => sum + c.amount);
                  final groupPending = groupTotal - groupPaid;

                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.group,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        group.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            'Monthly: ₹${group.monthlyContribution.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          if (groupPending > 0)
                            Text(
                              'Pending: ₹${groupPending.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else
                            Text(
                              'All payments complete',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MonthlyPaymentsScreen(group: group),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentBreakdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            
            Text(
              'Payment Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            
            // Breakdown by groups
            ...groups.map((group) {
              final groupTotal = group.monthlyContribution * group.totalMonths;
              final groupPaid = myContributions
                  .where((c) => c.groupId == group.id)
                  .fold(0.0, (sum, c) => sum + c.amount);
              final groupPending = groupTotal - groupPaid;
              
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paid',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '₹${groupPaid.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '₹${groupPending.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '₹${groupTotal.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            
            SizedBox(height: 20),
            
            // Total Summary
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Outstanding',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  Text(
                    '₹${totalPendingAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}