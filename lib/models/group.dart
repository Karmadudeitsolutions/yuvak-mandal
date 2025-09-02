import 'user.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final double monthlyContribution; // Not stored in DB
  final int totalMonths; // Stored in DB as total_months
  final double totalAmount; // Stored in DB as total_amount
  final List<User> members; // Supabase uses group_members table
  final String adminId; // Maps to created_by in Supabase
  final DateTime createdAt; // Maps to created_at in Supabase
  final String joinCode; // Maps to join_code in Supabase

  Group({
    required this.id,
    required this.name,
    required this.description,
    this.monthlyContribution = 0.0,
    this.totalMonths = 0,
    this.totalAmount = 0.0,
    this.members = const [],
    required this.adminId,
    required this.createdAt,
    this.joinCode = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'monthlyContribution': monthlyContribution,
      'totalMonths': totalMonths,
      'totalAmount': totalAmount,
      'members': members.map((m) => m.toJson()).toList(),
      'adminId': adminId,
      'createdAt': createdAt.toIso8601String(),
      'joinCode': joinCode,
    };
  }

  // Robust parser supporting both app-local and Supabase snake_case fields
  factory Group.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
      return 0;
    }

    final monthly = json.containsKey('monthlyContribution')
        ? toDouble(json['monthlyContribution'])
        : toDouble(json['monthly_contribution']);

    final totalMonths = json.containsKey('totalMonths')
        ? toInt(json['totalMonths'])
        : toInt(json['total_months']);

    final totalAmount = json.containsKey('totalAmount')
        ? toDouble(json['totalAmount'])
        : toDouble(json['total_amount']);

    final membersList = json['members'];

    return Group(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: (json['description'] ?? '').toString(),
      monthlyContribution: monthly,
      totalMonths: totalMonths,
      totalAmount: totalAmount,
      members: membersList is List
          ? membersList.map((m) => User.fromJson(m as Map<String, dynamic>)).toList()
          : <User>[],
      adminId: (json['adminId'] ?? json['admin_id'] ?? json['created_by'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
      joinCode: (json['joinCode'] ?? json['join_code'] ?? '').toString(),
    );
  }
}