import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirror of a `notices/{noticeId}` document. Posted by the Owner and shown to
/// tenants and/or staff in their notices feed. Urgent notices are highlighted.
class Notice {
  final String id;
  final String title;
  final String body;
  final String audience; // "all" | "tenants" | "staff"
  final bool urgent;
  final DateTime? createdAt;

  Notice({
    required this.id,
    required this.title,
    required this.body,
    this.audience = 'all',
    this.urgent = false,
    this.createdAt,
  });

  factory Notice.fromMap(String id, Map<String, dynamic> map) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return Notice(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      audience: map['audience'] as String? ?? 'all',
      urgent: map['urgent'] as bool? ?? false,
      createdAt: ts(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'audience': audience,
        'urgent': urgent,
        'createdAt':
            createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      };

  /// True if this notice should be shown to the given audience key
  /// ("tenants" or "staff").
  bool visibleTo(String who) => audience == 'all' || audience == who;
}
