import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'dart:math';

import '../models/user.dart';
import '../models/group.dart';
import '../models/contribution.dart';
import '../models/loan_request.dart';
import '../models/repayment.dart';
import 'supabase_service.dart';

class SupabaseDataService {
  // User operations
  static Future<List<User>> getUsers() async {
    try {
      final data = await SupabaseService.select('users');
      return data.map((item) => User.fromJson(item)).whereType<User>().toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Group membership operations
  static Future<List<Group>> getUserGroups(String userId) async {
    try {
      // Primary approach: join via group_members -> groups
      final data = await SupabaseService.client
          .from('group_members')
          .select('groups(*)')
          .eq('user_id', userId);

      final List<Group> groups = [];
      for (final row in data) {
        final g = row['groups'];
        if (g != null) {
          groups.add(Group.fromJson(Map<String, dynamic>.from(g)));
        }
      }

      if (groups.isNotEmpty) return groups;

      // Fallback: fetch group_ids first, then load groups by IDs
      final memberships = await SupabaseService.client
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);
      final ids =
          memberships
              .map((m) => m['group_id'])
              .where((id) => id != null)
              .toList();
      if (ids.isEmpty) return [];

      final groupsData = await SupabaseService.client
          .from('groups')
          .select('*')
          .inFilter('id', ids);

      return List<Map<String, dynamic>>.from(
        groupsData,
      ).map((g) => Group.fromJson(g)).toList();
    } catch (e) {
      print('Error fetching user groups: $e');
      return [];
    }
  }

  static Future<(bool success, String message)> joinGroup({
    required String groupId,
    required String userId,
    String role = 'Member',
  }) async {
    try {
      await SupabaseService.client.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': role,
      });
      return (true, 'Joined group successfully');
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return (false, 'You are already a member of this group');
      }
      if (e.code == '23503') {
        return (false, 'Invalid group code');
      }
      return (false, 'Error joining group: ${e.message}');
    } catch (e) {
      return (false, 'Error joining group: $e');
    }
  }

  static Future<User?> getUserById(String id) async {
    try {
      final data = await SupabaseService.select('users', filters: {'id': id});
      if (data.isNotEmpty) {
        return User.fromJson(data.first);
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  // Group operations
  static Future<List<Group>> getGroups() async {
    try {
      final data = await SupabaseService.select('groups');
      return data.map((item) => Group.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching groups: $e');
      return [];
    }
  }

  static Future<String> _generateUniqueJoinCode() async {
    final rng = Random();
    for (int i = 0; i < 10; i++) {
      // Try up to 10 times
      final code = (rng.nextInt(9000) + 1000).toString(); // 1000-9999
      final existing = await SupabaseService.select(
        'groups',
        filters: {'join_code': code},
      );
      if (existing.isEmpty) return code;
    }
    // Fallback if many collisions
    return (Random().nextInt(9000) + 1000).toString();
  }

  static Future<Group?> createGroup(Group group) async {
    try {
      // Generate a unique 4-digit code
      final code = await _generateUniqueJoinCode();

      // Map to Supabase schema; let DB generate UUID id
      final payload = {
        'name': group.name,
        'description': group.description,
        'monthly_contribution': group.monthlyContribution,
        'admin_id': group.adminId,
        'join_code': code,
        'total_months': group.totalMonths,
        'total_amount': group.totalAmount,
      };
      final data = await SupabaseService.insert('groups', payload);
      if (data.isNotEmpty) {
        final created = Group.fromJson(data.first);

        // Ensure creator is added as Admin member
        try {
          await SupabaseService.client.from('group_members').insert({
            'group_id': created.id,
            'user_id': group.adminId,
            'role': 'Admin',
          });
        } catch (_) {}

        return created;
      }
      return null;
    } on PostgrestException catch (e) {
      print('Error creating group (DB): ${e.message}');
      return null;
    } catch (e) {
      print('Error creating group: $e');
      return null;
    }
  }

  static Future<(bool success, String message)> joinGroupByCode({
    required String code,
    required String userId,
  }) async {
    try {
      // Find group by join_code
      final groups = await SupabaseService.select(
        'groups',
        filters: {'join_code': code},
      );
      if (groups.isEmpty) {
        return (false, 'Invalid group code');
      }
      final groupId = groups.first['id'].toString();

      // Join membership
      return await joinGroup(groupId: groupId, userId: userId);
    } on PostgrestException catch (e) {
      if (e.code == '23505')
        return (false, 'You are already a member of this group');
      return (false, 'Error joining by code: ${e.message}');
    } catch (e) {
      return (false, 'Error joining by code: $e');
    }
  }

  static Future<Group?> updateGroup(Group group) async {
    try {
      final data = await SupabaseService.update(
        'groups',
        group.toJson(),
        filters: {'id': group.id},
      );
      if (data.isNotEmpty) {
        return Group.fromJson(data.first);
      }
      return null;
    } catch (e) {
      print('Error updating group: $e');
      return null;
    }
  }

  static Future<bool> deleteGroup(String groupId) async {
    try {
      await SupabaseService.delete('groups', filters: {'id': groupId});
      return true;
    } catch (e) {
      print('Error deleting group: $e');
      return false;
    }
  }

  static Future<List<User>> getGroupMembers(String groupId) async {
    try {
      // Join group_members with users to get member details
      final data = await SupabaseService.client
          .from('group_members')
          .select('users(*)')
          .eq('group_id', groupId);

      final List<User> members = [];
      for (final row in data) {
        final user = row['users'];
        if (user != null) {
          members.add(User.fromJson(Map<String, dynamic>.from(user)));
        }
      }

      if (members.isNotEmpty) return members;

      // Fallback: fetch user_ids first, then load users by IDs
      final memberships = await SupabaseService.client
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId);
      final userIds =
          memberships
              .map((m) => m['user_id'])
              .where((id) => id != null)
              .toList();
      if (userIds.isEmpty) return [];

      final usersData = await SupabaseService.client
          .from('users')
          .select('*')
          .inFilter('id', userIds);

      return List<Map<String, dynamic>>.from(
        usersData,
      ).map((u) => User.fromJson(u)).toList();
    } catch (e) {
      print('Error fetching group members: $e');
      return [];
    }
  }

  // Contribution operations
  static Future<List<Contribution>> getContributions({
    String? groupId,
    String? userId,
  }) async {
    try {
      Map<String, dynamic>? filters;
      if (groupId != null && userId != null) {
        // For complex filters in bypass mode, return empty list
        print('SupabaseDataService: Bypassing complex contribution query');
        return [];
      } else if (groupId != null) {
        filters = {'group_id': groupId};
      } else if (userId != null) {
        filters = {'user_id': userId};
      }

      final data = await SupabaseService.select(
        'contributions',
        filters: filters,
      );
      return data.map((item) => Contribution.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching contributions: $e');
      return [];
    }
  }

  static Future<Contribution?> createContribution(
    Contribution contribution,
  ) async {
    try {
      final data = await SupabaseService.insert(
        'contributions',
        contribution.toJson(),
      );
      if (data.isNotEmpty) {
        return Contribution.fromJson(data.first);
      }
      return null;
    } catch (e) {
      print('Error creating contribution: $e');
      return null;
    }
  }

  static Future<Contribution?> updateContribution(
    Contribution contribution,
  ) async {
    try {
      final data = await SupabaseService.update(
        'contributions',
        contribution.toJson(),
        filters: {'id': contribution.id},
      );
      if (data.isNotEmpty) {
        return Contribution.fromJson(data.first);
      }
      return null;
    } catch (e) {
      print('Error updating contribution: $e');
      return null;
    }
  }

  // Loan request operations
  static Future<List<LoanRequest>> getLoanRequests({
    String? groupId,
    String? userId,
    String? status,
  }) async {
    try {
      Map<String, dynamic>? filters;

      // Build filters based on parameters
      if (groupId != null || userId != null || status != null) {
        filters = {};
        if (groupId != null) filters['group_id'] = groupId;
        if (userId != null) filters['user_id'] = userId;
        if (status != null) filters['status'] = status;
      }

      final data = await SupabaseService.select(
        'loan_requests',
        filters: filters,
      );
      return data.map((item) => LoanRequest.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching loan requests: $e');
      return [];
    }
  }

  static Future<LoanRequest?> createLoanRequest(LoanRequest loanRequest) async {
    try {
      final data = await SupabaseService.insert(
        'loan_requests',
        loanRequest.toJson(),
      );
      if (data.isNotEmpty) {
        return LoanRequest.fromJson(data.first);
      }
      return null;
    } catch (e) {
      print('Error creating loan request: $e');
      return null;
    }
  }

  static Future<LoanRequest?> updateLoanRequest(LoanRequest loanRequest) async {
    try {
      final data = await SupabaseService.update(
        'loan_requests',
        loanRequest.toJson(),
        filters: {'id': loanRequest.id},
      );
      if (data.isNotEmpty) {
        return LoanRequest.fromJson(data.first);
      }
      return null;
    } catch (e) {
      print('Error updating loan request: $e');
      return null;
    }
  }

  // Repayment operations
  static Future<List<Repayment>> getRepayments({
    String? loanId,
    String? userId,
  }) async {
    try {
      Map<String, dynamic>? filters;
      if (loanId != null && userId != null) {
        // For complex filters in bypass mode, return empty list
        print('SupabaseDataService: Bypassing complex repayment query');
        return [];
      } else if (loanId != null) {
        filters = {'loan_id': loanId};
      } else if (userId != null) {
        filters = {'user_id': userId};
      }

      final data = await SupabaseService.select('repayments', filters: filters);
      return data.map((item) => Repayment.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching repayments: $e');
      return [];
    }
  }

  static Future<Repayment?> createRepayment(Repayment repayment) async {
    try {
      final data = await SupabaseService.insert(
        'repayments',
        repayment.toJson(),
      );
      if (data.isNotEmpty) {
        return Repayment.fromJson(data.first);
      }
      return null;
    } catch (e) {
      print('Error creating repayment: $e');
      return null;
    }
  }

  static Future<Repayment?> updateRepayment(Repayment repayment) async {
    try {
      final data = await SupabaseService.update(
        'repayments',
        repayment.toJson(),
        filters: {'id': repayment.id},
      );
      if (data.isNotEmpty) {
        return Repayment.fromJson(data.first);
      }
      return null;
    } catch (e) {
      print('Error updating repayment: $e');
      return null;
    }
  }

  // Analytics and reporting
  static Future<Map<String, dynamic>> getGroupStatistics(String groupId) async {
    try {
      // Get total contributions
      final contributions = await getContributions(groupId: groupId);
      final totalContributions = contributions.fold<double>(
        0.0,
        (sum, contribution) => sum + contribution.amount,
      );

      // Get active loans
      final activeLoans = await getLoanRequests(
        groupId: groupId,
        status: 'approved',
      );
      final totalActiveLoans = activeLoans.fold<double>(
        0.0,
        (sum, loan) => sum + loan.amount,
      );

      // Get total repayments - bypass mode returns empty
      final allRepayments = <Map<String, dynamic>>[];
      print('SupabaseDataService: Bypassing repayments query for statistics');

      final totalRepayments = allRepayments.fold<double>(
        0.0,
        (sum, repayment) => sum + (repayment['amount'] as num).toDouble(),
      );

      return {
        'totalContributions': totalContributions,
        'totalActiveLoans': totalActiveLoans,
        'totalRepayments': totalRepayments,
        'availableFunds':
            totalContributions + totalRepayments - totalActiveLoans,
        'memberCount': contributions.map((c) => c.userId).toSet().length,
      };
    } catch (e) {
      print('Error fetching group statistics: $e');
      return {
        'totalContributions': 0.0,
        'totalActiveLoans': 0.0,
        'totalRepayments': 0.0,
        'availableFunds': 0.0,
        'memberCount': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      // Get user contributions
      final contributions = await getContributions(userId: userId);
      final totalContributions = contributions.fold<double>(
        0.0,
        (sum, contribution) => sum + contribution.amount,
      );

      // Get user loans
      final userLoans = await getLoanRequests(userId: userId);
      final activeLoans =
          userLoans.where((loan) => loan.status == 'approved').toList();
      final totalBorrowed = activeLoans.fold<double>(
        0.0,
        (sum, loan) => sum + loan.amount,
      );

      // Get user repayments
      final repayments = await getRepayments(userId: userId);
      final totalRepaid = repayments.fold<double>(
        0.0,
        (sum, repayment) => sum + repayment.amount,
      );

      return {
        'totalContributions': totalContributions,
        'totalBorrowed': totalBorrowed,
        'totalRepaid': totalRepaid,
        'outstandingBalance': totalBorrowed - totalRepaid,
        'loanCount': activeLoans.length,
      };
    } catch (e) {
      print('Error fetching user statistics: $e');
      return {
        'totalContributions': 0.0,
        'totalBorrowed': 0.0,
        'totalRepaid': 0.0,
        'outstandingBalance': 0.0,
        'loanCount': 0,
      };
    }
  }

  // Real-time subscriptions - bypass mode
  static void subscribeToContributions(
    String groupId,
    Function(Map<String, dynamic>) callback,
  ) {
    print(
      'SupabaseDataService: Bypassing subscription to contributions for group $groupId',
    );
    // No-op in bypass mode
  }

  static void subscribeToLoanRequests(
    String groupId,
    Function(Map<String, dynamic>) callback,
  ) {
    print(
      'SupabaseDataService: Bypassing subscription to loan requests for group $groupId',
    );
    // No-op in bypass mode
  }

  static Future<void> initializeSampleData() async {}
}
