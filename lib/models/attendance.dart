import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirror of an `attendance/{attendanceId}` document. One row per person per
/// day; staff mark check-in and later check-out from the staff app.
class Attendance {
  final String id;
  final String personType; // "staff" | "tenant"
  final String personId;
  final String date; // "YYYY-MM-DD"
  final DateTime? checkIn;
  final DateTime? checkOut;

  Attendance({
    required this.id,
    required this.personType,
    required this.personId,
    required this.date,
    this.checkIn,
    this.checkOut,
  });

  factory Attendance.fromMap(String id, Map<String, dynamic> map) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return Attendance(
      id: id,
      personType: map['personType'] as String? ?? 'staff',
      personId: map['personId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      checkIn: ts(map['checkIn']),
      checkOut: ts(map['checkOut']),
    );
  }

  Map<String, dynamic> toMap() => {
        'personType': personType,
        'personId': personId,
        'date': date,
        'checkIn': checkIn == null ? null : Timestamp.fromDate(checkIn!),
        'checkOut': checkOut == null ? null : Timestamp.fromDate(checkOut!),
      };
}
