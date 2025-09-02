class Repayment {
  final String id;
  final String loanId;
  final String userId;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status; // 'Pending', 'Paid', 'Overdue'
  final int installmentNumber;
  final int totalInstallments;

  Repayment({
    required this.id,
    required this.loanId,
    required this.userId,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.status,
    required this.installmentNumber,
    required this.totalInstallments,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loanId': loanId,
      'userId': userId,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'status': status,
      'installmentNumber': installmentNumber,
      'totalInstallments': totalInstallments,
    };
  }

  factory Repayment.fromJson(Map<String, dynamic> json) {
    return Repayment(
      id: json['id'],
      loanId: json['loanId'],
      userId: json['userId'],
      amount: json['amount'].toDouble(),
      dueDate: DateTime.parse(json['dueDate']),
      paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
      status: json['status'],
      installmentNumber: json['installmentNumber'],
      totalInstallments: json['totalInstallments'],
    );
  }
}