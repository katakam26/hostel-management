import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirror of a `menus/{menuId}` document. One mess menu per day; the document
/// id is the date string "YYYY-MM-DD" so the Owner can upsert a day's menu.
class Menu {
  final String id; // date string "YYYY-MM-DD"
  final String date;
  final String breakfast;
  final String lunch;
  final String dinner;

  Menu({
    required this.id,
    required this.date,
    this.breakfast = '',
    this.lunch = '',
    this.dinner = '',
  });

  factory Menu.fromMap(String id, Map<String, dynamic> map) {
    return Menu(
      id: id,
      date: map['date'] as String? ?? id,
      breakfast: map['breakfast'] as String? ?? '',
      lunch: map['lunch'] as String? ?? '',
      dinner: map['dinner'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date,
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  bool get isEmpty =>
      breakfast.isEmpty && lunch.isEmpty && dinner.isEmpty;
}
