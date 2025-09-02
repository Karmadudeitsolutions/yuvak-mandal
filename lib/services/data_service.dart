import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/contribution.dart';
import '../models/loan_request.dart';
import '../models/repayment.dart';

class DataService {
  static const String _currentUserKey = 'current_user';
  static const String _groupsKey = 'groups';
  static const String _contributionsKey = 'contributions';
  static const String _loanRequestsKey = 'loan_requests';
  static const String _repaymentsKey = 'repayments';

  // Current User Management
  static Future<void> saveCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  static Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Groups Management
  static Future<void> saveGroups(List<Group> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = groups.map((g) => g.toJson()).toList();
    await prefs.setString(_groupsKey, jsonEncode(groupsJson));
  }

  static Future<List<Group>> getGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getString(_groupsKey);
    if (groupsJson != null) {
      final List<dynamic> decoded = jsonDecode(groupsJson);
      return decoded.map((g) => Group.fromJson(g)).toList();
    }
    return [];
  }

  // Contributions Management
  static Future<void> saveContributions(List<Contribution> contributions) async {
    final prefs = await SharedPreferences.getInstance();
    final contributionsJson = contributions.map((c) => c.toJson()).toList();
    await prefs.setString(_contributionsKey, jsonEncode(contributionsJson));
  }

  static Future<List<Contribution>> getContributions() async {
    final prefs = await SharedPreferences.getInstance();
    final contributionsJson = prefs.getString(_contributionsKey);
    if (contributionsJson != null) {
      final List<dynamic> decoded = jsonDecode(contributionsJson);
      return decoded.map((c) => Contribution.fromJson(c)).toList();
    }
    return [];
  }

  // Loan Requests Management
  static Future<void> saveLoanRequests(List<LoanRequest> loanRequests) async {
    final prefs = await SharedPreferences.getInstance();
    final loanRequestsJson = loanRequests.map((l) => l.toJson()).toList();
    await prefs.setString(_loanRequestsKey, jsonEncode(loanRequestsJson));
  }

  static Future<List<LoanRequest>> getLoanRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final loanRequestsJson = prefs.getString(_loanRequestsKey);
    if (loanRequestsJson != null) {
      final List<dynamic> decoded = jsonDecode(loanRequestsJson);
      return decoded.map((l) => LoanRequest.fromJson(l)).toList();
    }
    return [];
  }

  // Repayments Management
  static Future<void> saveRepayments(List<Repayment> repayments) async {
    final prefs = await SharedPreferences.getInstance();
    final repaymentsJson = repayments.map((r) => r.toJson()).toList();
    await prefs.setString(_repaymentsKey, jsonEncode(repaymentsJson));
  }

  static Future<List<Repayment>> getRepayments() async {
    final prefs = await SharedPreferences.getInstance();
    final repaymentsJson = prefs.getString(_repaymentsKey);
    if (repaymentsJson != null) {
      final List<dynamic> decoded = jsonDecode(repaymentsJson);
      return decoded.map((r) => Repayment.fromJson(r)).toList();
    }
    return [];
  }

  // Initialize sample data
  static Future<void> initializeSampleData() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return;

    // Create sample group
    final sampleGroup = Group(
      id: 'group_1',
      name: 'Family Mandal',
      description: 'Monthly savings group for family',
      monthlyContribution: 5000.0,
      members: [
        currentUser,
        User(id: 'user_2', name: 'Rajesh Kumar', email: 'rajesh@email.com', phone: '9876543210'),
        User(id: 'user_3', name: 'Priya Sharma', email: 'priya@email.com', phone: '9876543211'),
        User(id: 'user_4', name: 'Amit Singh', email: 'amit@email.com', phone: '9876543212'),
      ],
      adminId: currentUser.id,
      createdAt: DateTime.now().subtract(Duration(days: 30)),
    );

    await saveGroups([sampleGroup]);

    // Create sample contributions
    final contributions = [
      Contribution(
        id: 'cont_1',
        groupId: 'group_1',
        userId: currentUser.id,
        amount: 5000.0,
        dueDate: DateTime.now().subtract(Duration(days: 5)),
        paidDate: DateTime.now().subtract(Duration(days: 3)),
        status: 'Paid',
        period: 'January 2024',
      ),
      Contribution(
        id: 'cont_2',
        groupId: 'group_1',
        userId: currentUser.id,
        amount: 5000.0,
        dueDate: DateTime.now().add(Duration(days: 25)),
        status: 'Pending',
        period: 'February 2024',
      ),
    ];

    await saveContributions(contributions);

    // Create sample loan request
    final loanRequests = [
      LoanRequest(
        id: 'loan_1',
        groupId: 'group_1',
        requesterId: currentUser.id,
        amount: 25000.0,
        purpose: 'Medical Emergency',
        durationMonths: 12,
        interestRate: 2.0,
        status: 'Approved',
        requestDate: DateTime.now().subtract(Duration(days: 10)),
        approvedDate: DateTime.now().subtract(Duration(days: 5)),
      ),
    ];

    await saveLoanRequests(loanRequests);

    // Create sample repayments
    final repayments = [
      Repayment(
        id: 'repay_1',
        loanId: 'loan_1',
        userId: currentUser.id,
        amount: 2250.0,
        dueDate: DateTime.now().add(Duration(days: 15)),
        status: 'Pending',
        installmentNumber: 1,
        totalInstallments: 12,
      ),
      Repayment(
        id: 'repay_2',
        loanId: 'loan_1',
        userId: currentUser.id,
        amount: 2250.0,
        dueDate: DateTime.now().add(Duration(days: 45)),
        status: 'Pending',
        installmentNumber: 2,
        totalInstallments: 12,
      ),
    ];

    await saveRepayments(repayments);
  }
}