/// Mirror of a `blocks/{blockId}` document. A hostel is divided into blocks
/// (e.g. "A Block"), each block holds floors, each floor holds rooms.
class Block {
  final String id;
  final String hostelId;
  final String name;

  Block({required this.id, required this.hostelId, required this.name});

  factory Block.fromMap(String id, Map<String, dynamic> map) {
    return Block(
      id: id,
      hostelId: map['hostelId'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'hostelId': hostelId,
        'name': name,
      };
}
