class Contribution {
  final String id;
  final String groupId;
  final String userId;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status; // 'Paid', 'Pending', 'Overdue'
  final String period; // e.g., "January 2024"

  Contribution({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.status,
    required this.period,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'group_id': groupId,
      'user_id': userId,
      'amount': amount,
      'description': period, // Use period as description
      'contribution_date': dueDate.toIso8601String().split('T')[0], // Date only
    };
    
    // Only include id if it's not empty (let database generate UUID if empty)
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }

  // For app-level JSON (keeping for compatibility)
  Map<String, dynamic> toAppJson() {
    return {
      'id': id,
      'groupId': groupId,
      'userId': userId,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'status': status,
      'period': period,
    };
  }

  factory Contribution.fromJson(Map<String, dynamic> json) {
    // Handle both database snake_case and app camelCase
    return Contribution(
      id: json['id'] ?? '',
      groupId: json['group_id'] ?? json['groupId'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      dueDate: json['contribution_date'] != null 
          ? DateTime.parse(json['contribution_date'])
          : (json['dueDate'] != null ? DateTime.parse(json['dueDate']) : DateTime.now()),
      paidDate: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : (json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null),
      status: json['status'] ?? 'Paid', // Default to Paid for database records
      period: json['description'] ?? json['period'] ?? '',
    );
  }
}