import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/group.dart';
import '../../models/contribution.dart';
import '../../services/shared_preferences_service.dart';
import '../../services/supabase_data_service.dart';

class MonthlyPaymentsScreen extends StatefulWidget {
  final Group group;

  const MonthlyPaymentsScreen({Key? key, required this.group}) : super(key: key);

  @override
  _MonthlyPaymentsScreenState createState() => _MonthlyPaymentsScreenState();
}

class _MonthlyPaymentsScreenState extends State<MonthlyPaymentsScreen> {
  User? currentUser;
  List<Contribution> contributions = [];
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

    try {
      currentUser = await SharedPreferencesService.getStoredUser();
      if (currentUser != null) {
        // Get contributions for this group and user
        final allContributions = await SupabaseDataService.getContributions(groupId: widget.group.id);
        contributions = allContributions.where((c) => c.userId == currentUser!.id).toList();
      }
    } catch (e) {
      print('Error loading contributions: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getMonthlyPaymentStatus() {
    final months = <Map<String, dynamic>>[];
    final created = widget.group.createdAt;
    final totalMonths = widget.group.totalMonths; // Use group's total_months from database
    
    for (int i = 0; i < totalMonths; i++) {
      final monthDate = DateTime(created.year, created.month + i, 1);
      final monthName = '${_getMonthName(monthDate.month)} ${monthDate.year}';
      
      // Check if payment exists for this month
      final payment = contributions.firstWhere(
        (c) => c.period == monthName,
        orElse: () => Contribution(
          id: '',
          groupId: widget.group.id,
          userId: currentUser?.id ?? '',
          amount: widget.group.monthlyContribution,
          dueDate: monthDate,
          status: 'Pending',
          period: monthName,
        ),
      );
      
      final isPaid = payment.id.isNotEmpty;
      
      months.add({
        'month': monthName,
        'date': monthDate,
        'amount': widget.group.monthlyContribution,
        'status': isPaid ? 'Paid' : 'Pending',
        'paidDate': payment.paidDate,
        'contribution': payment,
        'isPaid': isPaid,
      });
    }
    return months; // Show months in ascending order (earliest first)
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<void> _makePayment(Map<String, dynamic> monthData) async {
    if (currentUser == null) return;

    // Check if already paid
    if (monthData['isPaid'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment for ${monthData['month']} is already completed!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Payment'),
          content: Text(
            'Pay ₹${monthData['amount'].toStringAsFixed(0)} for ${monthData['month']}?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Pay'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final contribution = Contribution(
          id: '',
          groupId: widget.group.id,
          userId: currentUser!.id,
          amount: monthData['amount'].toDouble(),
          dueDate: monthData['date'],
          paidDate: DateTime.now(),
          status: 'Paid',
          period: monthData['month'],
        );

        final saved = await SupabaseDataService.createContribution(contribution);
        
        if (saved != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment for ${monthData['month']} completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Refresh data
        } else {
          throw Exception('Failed to save payment');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyData = _getMonthlyPaymentStatus();
    final paidCount = monthlyData.where((m) => m['status'] == 'Paid').length;
    final totalAmount = monthlyData.fold(0.0, (sum, m) => sum + m['amount']);
    final paidAmount = monthlyData.where((m) => m['status'] == 'Paid').fold(0.0, (sum, m) => sum + m['amount']);
    final progress = monthlyData.isNotEmpty ? (paidCount / monthlyData.length) : 0.0;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Payment Timeline',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              centerTitle: false,
              titlePadding: EdgeInsets.only(left: 56, bottom: 16),
            ),
          ),

          SliverToBoxAdapter(
            child: isLoading
                ? Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading payment data...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group Overview Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF667EEA),
                                Color(0xFF764BA2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF667EEA).withOpacity(0.3),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.group,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.group.name,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${monthlyData.length} month plan',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 24),
                              
                              // Progress Section
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Payment Progress',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Container(
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: progress,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          '${(progress * 100).toInt()}% Complete',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 24),
                                  Container(
                                    width: 80,
                                    height: 80,
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          child: CircularProgressIndicator(
                                            value: progress,
                                            strokeWidth: 6,
                                            backgroundColor: Colors.white.withOpacity(0.3),
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '$paidCount',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                '/${monthlyData.length}',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.8),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
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
                              
                              SizedBox(height: 20),
                              
                              // Amount Summary
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildAmountCard(
                                      'Monthly',
                                      '₹${widget.group.monthlyContribution.toStringAsFixed(0)}',
                                      Icons.calendar_month,
                                      Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _buildAmountCard(
                                      'Paid',
                                      '₹${paidAmount.toStringAsFixed(0)}',
                                      Icons.check_circle,
                                      Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: _buildAmountCard(
                                      'Remaining',
                                      '₹${(totalAmount - paidAmount).toStringAsFixed(0)}',
                                      Icons.pending,
                                      Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 32),

                        // Section Header
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(0xFF667EEA),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Monthly Payments',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(0xFF667EEA).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$paidCount/${ monthlyData.length} paid',
                                style: TextStyle(
                                  color: Color(0xFF667EEA),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        // Monthly Payments List
                        ...monthlyData.asMap().entries.map((entry) {
                          final index = entry.key;
                          final monthData = entry.value;
                          final isPaid = monthData['status'] == 'Paid';
                          final isCurrentMonth = monthData['date'].month == DateTime.now().month && 
                                                monthData['date'].year == DateTime.now().year;
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            child: _buildPaymentCard(
                              monthData, 
                              isPaid, 
                              isCurrentMonth,
                              index + 1,
                            ),
                          );
                        }).toList(),

                        SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(String title, String amount, IconData icon, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
          SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> monthData, bool isPaid, bool isCurrentMonth, int monthNumber) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPaid 
              ? Colors.green.shade200 
              : isCurrentMonth 
                  ? Color(0xFF667EEA).withOpacity(0.3)
                  : Colors.grey.shade200,
          width: isPaid || isCurrentMonth ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPaid 
                ? Colors.green.withOpacity(0.1)
                : isCurrentMonth
                    ? Color(0xFF667EEA).withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Month Number Circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: isPaid 
                  ? LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    )
                  : isCurrentMonth
                      ? LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        )
                      : LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade400],
                        ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: isPaid
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 28,
                    )
                  : Text(
                      '$monthNumber',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          
          SizedBox(width: 16),
          
          // Month Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      monthData['month'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (isCurrentMonth && !isPaid) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Current',
                          style: TextStyle(
                            color: Color(0xFF667EEA),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '₹${monthData['amount'].toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPaid 
                        ? Colors.green.shade700
                        : Color(0xFF667EEA),
                  ),
                ),
                if (isPaid && monthData['paidDate'] != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'Paid on ${_formatDate(monthData['paidDate'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Action Button
          if (!isPaid)
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => _makePayment(monthData),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentMonth 
                      ? Color(0xFF667EEA)
                      : Colors.orange.shade500,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
                child: FittedBox(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payment, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Pay',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 16,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Paid',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
