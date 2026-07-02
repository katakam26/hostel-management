import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirror of a `complaints/{complaintId}` document. Raised by a tenant, seen by
/// the Owner (who assigns it to staff), and worked on by the assigned staff.
class Complaint {
  final String id;
  final String raisedByType; // "tenant"
  final String raisedById; // tenantId
  final String raisedByName;
  final String category; // water|electricity|fan_ac|cleaning|wifi|food|other
  final String description;
  final String status; // "open" | "assigned" | "in_progress" | "resolved"
  final String? assignedStaffId;
  final String? assignedStaffName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Complaint({
    required this.id,
    this.raisedByType = 'tenant',
    required this.raisedById,
    required this.raisedByName,
    required this.category,
    required this.description,
    this.status = 'open',
    this.assignedStaffId,
    this.assignedStaffName,
    this.createdAt,
    this.updatedAt,
  });

  factory Complaint.fromMap(String id, Map<String, dynamic> map) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return Complaint(
      id: id,
      raisedByType: map['raisedByType'] as String? ?? 'tenant',
      raisedById: map['raisedById'] as String? ?? '',
      raisedByName: map['raisedByName'] as String? ?? '',
      category: map['category'] as String? ?? 'other',
      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? 'open',
      assignedStaffId: map['assignedStaffId'] as String?,
      assignedStaffName: map['assignedStaffName'] as String?,
      createdAt: ts(map['createdAt']),
      updatedAt: ts(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'raisedByType': raisedByType,
        'raisedById': raisedById,
        'raisedByName': raisedByName,
        'category': category,
        'description': description,
        'status': status,
        'assignedStaffId': assignedStaffId,
        'assignedStaffName': assignedStaffName,
        'createdAt':
            createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  bool get isResolved => status == 'resolved';

  /// Human-friendly category label (e.g. "fan_ac" -> "Fan / AC").
  String get categoryLabel {
    switch (category) {
      case 'fan_ac':
        return 'Fan / AC';
      default:
        return category.isEmpty
            ? 'Other'
            : category[0].toUpperCase() + category.substring(1);
    }
  }
}
