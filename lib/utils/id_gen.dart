import 'dart:math';

/// Helpers for the owner-issued login IDs and temporary passwords described in
/// DESIGN.md (e.g. `TEN-1027`, `STF-4012`).
class IdGen {
  IdGen._();

  static final Random _rng = Random.secure();

  /// A tenant login id, e.g. `TEN-4821`.
  static String tenantId() => 'TEN-${_digits(4)}';

  /// A staff/employee login id, e.g. `STF-9043`.
  static String staffId() => 'STF-${_digits(4)}';

  /// A readable temporary password the owner hands to the new user.
  static String tempPassword() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    return List.generate(8, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  static String _digits(int n) =>
      List.generate(n, (_) => _rng.nextInt(10)).join();
}
