/// Mirror of a `floors/{floorId}` document. Belongs to a block and groups the
/// rooms on one floor.
class Floor {
  final String id;
  final String blockId;
  final int number;

  Floor({required this.id, required this.blockId, required this.number});

  factory Floor.fromMap(String id, Map<String, dynamic> map) {
    return Floor(
      id: id,
      blockId: map['blockId'] as String? ?? '',
      number: (map['number'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'blockId': blockId,
        'number': number,
      };

  String get label => number == 0 ? 'Ground floor' : 'Floor $number';
}
