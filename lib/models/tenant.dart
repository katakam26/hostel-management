import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirror of a `tenants/{tenantId}` document. Created by the Owner; the
/// [uniqueId] doubles as the tenant's login id (see AuthService).
class Tenant {
  final String id;
  final String uniqueId;
  final String name;
  final String phone;
  final String? email;
  final String? photoUrl;
  final String? roomId;
  final String? bedId;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final bool depositPaid;
  final num depositAmount;
  final List<Map<String, dynamic>> documents; // [{type, url}]
  final String status; // "active" | "moved_out"

  Tenant({
    required this.id,
    required this.uniqueId,
    required this.name,
    required this.phone,
    this.email,
    this.photoUrl,
    this.roomId,
    this.bedId,
    this.checkInDate,
    this.checkOutDate,
    this.depositPaid = false,
    this.depositAmount = 0,
    this.documents = const [],
    this.status = 'active',
  });

  factory Tenant.fromMap(String id, Map<String, dynamic> map) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return Tenant(
      id: id,
      uniqueId: map['uniqueId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String?,
      photoUrl: map['photoUrl'] as String?,
      roomId: map['roomId'] as String?,
      bedId: map['bedId'] as String?,
      checkInDate: ts(map['checkInDate']),
      checkOutDate: ts(map['checkOutDate']),
      depositPaid: map['depositPaid'] as bool? ?? false,
      depositAmount: (map['depositAmount'] as num?) ?? 0,
      documents: (map['documents'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      status: map['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() => {
        'uniqueId': uniqueId,
        'name': name,
        'phone': phone,
        'email': email,
        'photoUrl': photoUrl,
        'roomId': roomId,
        'bedId': bedId,
        'checkInDate':
            checkInDate == null ? null : Timestamp.fromDate(checkInDate!),
        'checkOutDate':
            checkOutDate == null ? null : Timestamp.fromDate(checkOutDate!),
        'depositPaid': depositPaid,
        'depositAmount': depositAmount,
        'documents': documents,
        'status': status,
      };

  bool get isActive => status == 'active';
}
