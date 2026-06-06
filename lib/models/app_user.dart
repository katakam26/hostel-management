import 'app_role.dart';

/// Mirror of a `users/{uid}` Firestore document. Created by the Owner when a
/// tenant/staff account is issued; the [uniqueId] is what the user types to
/// log in (mapped to a synthetic email by AuthService).
class AppUser {
  final String uid;
  final String uniqueId;
  final AppRole role;
  final String name;
  final String? email;

  /// Id of the linked domain document (tenants/{id} or staff/{id}).
  final String? linkedId;

  AppUser({
    required this.uid,
    required this.uniqueId,
    required this.role,
    required this.name,
    this.email,
    this.linkedId,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      uniqueId: map['uniqueId'] as String? ?? '',
      role: AppRole.fromString(map['role'] as String?),
      name: map['name'] as String? ?? '',
      email: map['email'] as String?,
      linkedId: map['linkedId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'uniqueId': uniqueId,
        'role': role.asString,
        'name': name,
        'email': email,
        'linkedId': linkedId,
      };
}
