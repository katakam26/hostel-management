import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirror of an `expenses/{expenseId}` document. Used by the Owner dashboard to
/// compute monthly profit (revenue from paid payments minus these expenses).
class Expense {
  final String id;
  final String type; // "recurring" | "non_recurring"
  final String category;
  final num amount;
  final String month; // "YYYY-MM"
  final String note;
  final DateTime? createdAt;

  Expense({
    required this.id,
    this.type = 'recurring',
    required this.category,
    required this.amount,
    required this.month,
    this.note = '',
    this.createdAt,
  });

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return Expense(
      id: id,
      type: map['type'] as String? ?? 'recurring',
      category: map['category'] as String? ?? '',
      amount: (map['amount'] as num?) ?? 0,
      month: map['month'] as String? ?? '',
      note: map['note'] as String? ?? '',
      createdAt: ts(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'category': category,
        'amount': amount,
        'month': month,
        'note': note,
        'createdAt':
            createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      };
}
