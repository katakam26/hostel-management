/// Mirror of a `beds/{bedId}` document. One per sleeping slot in a room.
/// [occupiedByTenantId] is null when the bed is free.
class Bed {
  final String id;
  final String roomId;
  final int bedNumber;
  final String? occupiedByTenantId;

  Bed({
    required this.id,
    required this.roomId,
    required this.bedNumber,
    this.occupiedByTenantId,
  });

  factory Bed.fromMap(String id, Map<String, dynamic> map) {
    return Bed(
      id: id,
      roomId: map['roomId'] as String? ?? '',
      bedNumber: (map['bedNumber'] as num?)?.toInt() ?? 0,
      occupiedByTenantId: map['occupiedByTenantId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'bedNumber': bedNumber,
        'occupiedByTenantId': occupiedByTenantId,
      };

  bool get isFree => occupiedByTenantId == null;
}
