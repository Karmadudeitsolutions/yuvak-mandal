class LoanRequest {
  final String id;
  final String groupId;
  final String requesterId;
  final double amount;
  final String purpose;
  final int durationMonths;
  final double interestRate;
  final String status; // 'Pending', 'Approved', 'Rejected', 'Active', 'Completed'
  final DateTime requestDate;
  final DateTime? approvedDate;
  final String? rejectionReason;

  LoanRequest({
    required this.id,
    required this.groupId,
    required this.requesterId,
    required this.amount,
    required this.purpose,
    required this.durationMonths,
    required this.interestRate,
    required this.status,
    required this.requestDate,
    this.approvedDate,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'requesterId': requesterId,
      'amount': amount,
      'purpose': purpose,
      'durationMonths': durationMonths,
      'interestRate': interestRate,
      'status': status,
      'requestDate': requestDate.toIso8601String(),
      'approvedDate': approvedDate?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  factory LoanRequest.fromJson(Map<String, dynamic> json) {
    return LoanRequest(
      id: json['id'],
      groupId: json['groupId'],
      requesterId: json['requesterId'],
      amount: json['amount'].toDouble(),
      purpose: json['purpose'],
      durationMonths: json['durationMonths'],
      interestRate: json['interestRate'].toDouble(),
      status: json['status'],
      requestDate: DateTime.parse(json['requestDate']),
      approvedDate: json['approvedDate'] != null ? DateTime.parse(json['approvedDate']) : null,
      rejectionReason: json['rejectionReason'],
    );
  }
}