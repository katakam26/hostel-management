/// The three roles in the hostel system. Stored on each user document and
/// used by the role router to decide which app shell to show after login.
enum AppRole {
  owner,
  tenant,
  staff;

  /// Parse a role string coming from Firestore. Defaults to [tenant] if the
  /// value is missing or unrecognised (least-privilege fallback).
  static AppRole fromString(String? value) {
    switch (value) {
      case 'owner':
        return AppRole.owner;
      case 'staff':
        return AppRole.staff;
      case 'tenant':
      default:
        return AppRole.tenant;
    }
  }

  String get asString => name;

  String get label {
    switch (this) {
      case AppRole.owner:
        return 'Owner';
      case AppRole.tenant:
        return 'Tenant';
      case AppRole.staff:
        return 'Staff';
    }
  }
}
