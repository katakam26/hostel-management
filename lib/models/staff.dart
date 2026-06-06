/// Mirror of a `staff/{staffId}` document. Created by the Owner; the
/// [uniqueId] is the employee id used to log in (see AuthService).
class Staff {
  final String id;
  final String uniqueId;
  final String name;
  final String phone;
  final String? email;
  final String role; // "cleaner" | "warden" | "security" | ...
  final num salaryAmount;
  final String salaryStatus; // "paid" | "unpaid"
  final List<Map<String, dynamic>> shifts; // [{day, start, end}]

  Staff({
    required this.id,
    required this.uniqueId,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.salaryAmount = 0,
    this.salaryStatus = 'unpaid',
    this.shifts = const [],
  });

  factory Staff.fromMap(String id, Map<String, dynamic> map) {
    return Staff(
      id: id,
      uniqueId: map['uniqueId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String?,
      role: map['role'] as String? ?? 'cleaner',
      salaryAmount: (map['salaryAmount'] as num?) ?? 0,
      salaryStatus: map['salaryStatus'] as String? ?? 'unpaid',
      shifts: (map['shifts'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'uniqueId': uniqueId,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role,
        'salaryAmount': salaryAmount,
        'salaryStatus': salaryStatus,
        'shifts': shifts,
      };
}
