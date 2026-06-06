/// Mirror of a `rooms/{roomId}` document. The [roomCode] is the human-facing
/// unique id (e.g. "A-101"). [status] is derived from bed occupancy.
class Room {
  final String id;
  final String blockId;
  final String floorId;
  final String roomCode;
  final int sharing; // beds in the room (1, 2, 3, ...)
  final bool ac;
  final String washroom; // "attached" | "common"
  final num rentAmount;
  final num depositAmount;
  final String status; // "vacant" | "occupied"
  final List<String> amenities;

  Room({
    required this.id,
    required this.blockId,
    required this.floorId,
    required this.roomCode,
    required this.sharing,
    required this.ac,
    required this.washroom,
    required this.rentAmount,
    required this.depositAmount,
    this.status = 'vacant',
    this.amenities = const [],
  });

  factory Room.fromMap(String id, Map<String, dynamic> map) {
    return Room(
      id: id,
      blockId: map['blockId'] as String? ?? '',
      floorId: map['floorId'] as String? ?? '',
      roomCode: map['roomCode'] as String? ?? '',
      sharing: (map['sharing'] as num?)?.toInt() ?? 1,
      ac: map['ac'] as bool? ?? false,
      washroom: map['washroom'] as String? ?? 'common',
      rentAmount: (map['rentAmount'] as num?) ?? 0,
      depositAmount: (map['depositAmount'] as num?) ?? 0,
      status: map['status'] as String? ?? 'vacant',
      amenities: (map['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'blockId': blockId,
        'floorId': floorId,
        'roomCode': roomCode,
        'sharing': sharing,
        'ac': ac,
        'washroom': washroom,
        'rentAmount': rentAmount,
        'depositAmount': depositAmount,
        'status': status,
        'amenities': amenities,
      };

  bool get isVacant => status == 'vacant';
}
