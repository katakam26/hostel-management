import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirror of a `payments/{paymentId}` document. A monthly rent bill for a
/// tenant, optionally including electricity and extra-amenity charges. The
/// Owner generates bills; the tenant pays (marks paid) from the tenant app.
class Payment {
  final String id;
  final String tenantId;
  final String tenantName;
  final String month; // "YYYY-MM"
  final String type; // "rent" | "deposit" | "electricity" | "amenity"
  final num baseRent;
  final num electricityBill;
  final num extraAmenityCharge;
  final num totalAmount;
  final String status; // "paid" | "unpaid"
  final DateTime? createdAt;
  final DateTime? paidAt;
  final String? method;

  Payment({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.month,
    this.type = 'rent',
    this.baseRent = 0,
    this.electricityBill = 0,
    this.extraAmenityCharge = 0,
    num? totalAmount,
    this.status = 'unpaid',
    this.createdAt,
    this.paidAt,
    this.method,
  }) : totalAmount =
            totalAmount ?? (baseRent + electricityBill + extraAmenityCharge);

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return Payment(
      id: id,
      tenantId: map['tenantId'] as String? ?? '',
      tenantName: map['tenantName'] as String? ?? '',
      month: map['month'] as String? ?? '',
      type: map['type'] as String? ?? 'rent',
      baseRent: (map['baseRent'] as num?) ?? 0,
      electricityBill: (map['electricityBill'] as num?) ?? 0,
      extraAmenityCharge: (map['extraAmenityCharge'] as num?) ?? 0,
      totalAmount: (map['totalAmount'] as num?) ?? 0,
      status: map['status'] as String? ?? 'unpaid',
      createdAt: ts(map['createdAt']),
      paidAt: ts(map['paidAt']),
      method: map['method'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'tenantId': tenantId,
        'tenantName': tenantName,
        'month': month,
        'type': type,
        'baseRent': baseRent,
        'electricityBill': electricityBill,
        'extraAmenityCharge': extraAmenityCharge,
        'totalAmount': totalAmount,
        'status': status,
        'createdAt':
            createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
        'paidAt': paidAt == null ? null : Timestamp.fromDate(paidAt!),
        'method': method,
      };

  bool get isPaid => status == 'paid';
}
