import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/group.dart';
import '../../models/contribution.dart';
import '../../models/loan_request.dart';
import '../../services/data_service.dart';
import 'manage_payments_screen.dart';
import 'manage_loans_screen.dart';
import 'group_analytics_screen.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  User? currentUser;
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

    currentUser = await DataService.getCurrentUser();
    groups = await DataService.getGroups();
    contributions = await DataService.getContributions();
    loanRequests = await DataService.getLoanRequests();

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    if (isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
              ),
              SizedBox(height: 16),
              Text(
                'Loading Admin Dashboard...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header Row
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: colorScheme.onPrimary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Admin Dashboard',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.onPrimary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ADMIN ACCESS',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Welcome Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.onPrimary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.dashboard_rounded,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'System Control Center',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Monitor and manage all operations',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimary.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: colorScheme.primary,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics Overview
                      Text(
                        'System Overview',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Responsive Stats Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = isTablet ? 4 : 2;
                          double childAspectRatio = isTablet ? 1.2 : 1.1;
                          
                          return GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: childAspectRatio,
                            children: [
                              _buildModernStatCard(
                                'Total Groups',
                                '${groups.length}',
                                Icons.groups_rounded,
                                Colors.blue,
                                theme,
                              ),
                              _buildModernStatCard(
                                'Pending Loans',
                                '${loanRequests.where((l) => l.status == 'Pending').length}',
                                Icons.pending_actions_rounded,
                                Colors.orange,
                                theme,
                              ),
                              _buildModernStatCard(
                                'Total Members',
                                '${groups.fold(0, (sum, group) => sum + group.members.length)}',
                                Icons.people_rounded,
                                Colors.green,
                                theme,
                              ),
                              _buildModernStatCard(
                                'Overdue Items',
                                '${contributions.where((c) => c.status == 'Pending' && c.dueDate.isBefore(DateTime.now())).length}',
                                Icons.warning_rounded,
                                Colors.red,
                                theme,
                              ),
                            ],
                          );
                        },
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Quick Actions
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Action Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernActionCard(
                                      'Manage Payments',
                                      'Review and process payments',
                                      Icons.payment_rounded,
                                      Colors.green,
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ManagePaymentsScreen(),
                                        ),
                                      ),
                                      theme,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernActionCard(
                                      'Manage Loans',
                                      'Handle loan requests',
                                      Icons.account_balance_rounded,
                                      Colors.blue,
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ManageLoansScreen(),
                                        ),
                                      ),
                                      theme,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernActionCard(
                                      'Analytics',
                                      'View detailed reports',
                                      Icons.analytics_rounded,
                                      Colors.purple,
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GroupAnalyticsScreen(),
                                        ),
                                      ),
                                      theme,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernActionCard(
                                      'Settings',
                                      'System configuration',
                                      Icons.settings_rounded,
                                      Colors.grey,
                                      () {
                                        // TODO: Navigate to settings
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Settings coming soon'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      theme,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernActionCard(
                                      'Group Overview',
                                      'View all groups details',
                                      Icons.groups_rounded,
                                      Colors.orange,
                                      () => _showGroupOverview(),
                                      theme,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: _buildModernActionCard(
                                      'User Management',
                                      'Manage user accounts',
                                      Icons.people_rounded,
                                      Colors.teal,
                                      () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('User Management coming soon'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      theme,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Recent Activity Section
                      Text(
                        'Recent Activity',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Activity List
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildActivityItem(
                              'New loan request submitted',
                              'John Doe requested ₹50,000',
                              Icons.request_quote_rounded,
                              Colors.orange,
                              '2 hours ago',
                              theme,
                            ),
                            Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
                            _buildActivityItem(
                              'Payment approved',
                              'Monthly contribution processed',
                              Icons.check_circle_rounded,
                              Colors.green,
                              '4 hours ago',
                              theme,
                            ),
                            Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
                            _buildActivityItem(
                              'New member joined',
                              'Sarah joined Group Alpha',
                              Icons.person_add_rounded,
                              Colors.blue,
                              '1 day ago',
                              theme,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show Group Overview Dialog
  void _showGroupOverview() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.groups_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Group Overview',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                
                // Groups List
                Expanded(
                  child: FutureBuilder<List<Group>>(
                    future: _loadAllGroups(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: Colors.red,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Error loading groups',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: 8),
                              Text(
                                snapshot.error.toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final groups = snapshot.data ?? [];
                      
                      if (groups.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group_off_rounded,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No groups found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          return _buildGroupCard(group, context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Load all groups (mock data for now)
  Future<List<Group>> _loadAllGroups() async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500));
    
    // Mock users
    final mockUsers1 = [
      User(id: 'user1', name: 'John Doe', email: 'john@email.com', phone: '9876543210'),
      User(id: 'user2', name: 'Jane Smith', email: 'jane@email.com', phone: '9876543211'),
      User(id: 'user3', name: 'Bob Wilson', email: 'bob@email.com', phone: '9876543212'),
      User(id: 'user4', name: 'Alice Brown', email: 'alice@email.com', phone: '9876543213'),
      User(id: 'user5', name: 'Charlie Davis', email: 'charlie@email.com', phone: '9876543214'),
    ];
    
    final mockUsers2 = [
      User(id: 'user6', name: 'David Miller', email: 'david@email.com', phone: '9876543215'),
      User(id: 'user7', name: 'Eva Garcia', email: 'eva@email.com', phone: '9876543216'),
      User(id: 'user8', name: 'Frank Johnson', email: 'frank@email.com', phone: '9876543217'),
    ];
    
    final mockUsers3 = [
      User(id: 'user9', name: 'Grace Lee', email: 'grace@email.com', phone: '9876543218'),
      User(id: 'user10', name: 'Henry Taylor', email: 'henry@email.com', phone: '9876543219'),
      User(id: 'user11', name: 'Ivy Anderson', email: 'ivy@email.com', phone: '9876543220'),
      User(id: 'user12', name: 'Jack Thomas', email: 'jack@email.com', phone: '9876543221'),
      User(id: 'user13', name: 'Kate White', email: 'kate@email.com', phone: '9876543222'),
      User(id: 'user14', name: 'Leo Martin', email: 'leo@email.com', phone: '9876543223'),
      User(id: 'user15', name: 'Mia Clark', email: 'mia@email.com', phone: '9876543224'),
    ];
    
    final mockUsers4 = [
      User(id: 'user16', name: 'Noah Lewis', email: 'noah@email.com', phone: '9876543225'),
      User(id: 'user17', name: 'Olivia Walker', email: 'olivia@email.com', phone: '9876543226'),
    ];
    
    // Mock data - replace with actual API call
    return [
      Group(
        id: '1',
        name: 'Family Mandal',
        description: 'Family savings group',
        adminId: 'admin1',
        members: mockUsers1,
        monthlyContribution: 5000.0,
        createdAt: DateTime.now().subtract(Duration(days: 180)),
      ),
      Group(
        id: '2',
        name: 'Friends Circle',
        description: 'College friends group',
        adminId: 'admin1',
        members: mockUsers2,
        monthlyContribution: 3000.0,
        createdAt: DateTime.now().subtract(Duration(days: 90)),
      ),
      Group(
        id: '3',
        name: 'Office Colleagues',
        description: 'Workplace savings',
        adminId: 'admin1',
        members: mockUsers3,
        monthlyContribution: 7500.0,
        createdAt: DateTime.now().subtract(Duration(days: 240)),
      ),
      Group(
        id: '4',
        name: 'Neighborhood Group',
        description: 'Local community savings',
        adminId: 'admin1',
        members: mockUsers4,
        monthlyContribution: 2000.0,
        createdAt: DateTime.now().subtract(Duration(days: 30)),
      ),
    ];
  }

  // Build Group Card
  Widget _buildGroupCard(Group group, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue,
                        Colors.blue.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.group_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        group.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Group Stats
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Members',
                          '${group.members.length}',
                          Icons.people_rounded,
                          Colors.blue,
                          theme,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Monthly',
                          '₹${group.monthlyContribution.toStringAsFixed(0)}',
                          Icons.calendar_month_rounded,
                          Colors.orange,
                          theme,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.withOpacity(0.1), Colors.teal.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Amount',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '₹${_calculateTotalAmount(group).toStringAsFixed(0)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            // Created Date
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                SizedBox(width: 4),
                Text(
                  'Created: ${_formatDate(group.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build Stat Item
  Widget _buildStatItem(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // Calculate Total Amount (estimated based on months since creation)
  double _calculateTotalAmount(Group group) {
    final monthsSinceCreation = DateTime.now().difference(group.createdAt).inDays ~/ 30;
    final estimatedMonths = monthsSinceCreation > 0 ? monthsSinceCreation : 1;
    return group.monthlyContribution * group.members.length * estimatedMonths;
  }

  // Format Date
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Modern Statistics Card
  Widget _buildModernStatCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Modern Action Card
  Widget _buildModernActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Activity Item
  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color, String time, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}