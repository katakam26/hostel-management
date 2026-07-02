import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/menu.dart';
import '../../../services/firestore_service.dart';
import '../../../utils/dates.dart';

/// Owner food & mess screen: edit the daily menu (upsert keyed by date) and
/// read the food feedback tenants have left.
class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  DateTime _date = DateTime.now();
  final _breakfast = TextEditingController();
  final _lunch = TextEditingController();
  final _dinner = TextEditingController();
  String _loadedForKey = '';
  bool _saving = false;

  @override
  void dispose() {
    _breakfast.dispose();
    _lunch.dispose();
    _dinner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final key = Dates.dayKey(_date);

    return ListView(
      padding: const EdgeInsets.all(4),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Menu for ${DateFormat.yMMMMEEEEd().format(_date)}',
                        style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
                // Prefill the fields from the stored menu the first time we see
                // this date's document.
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: fs.menus.doc(key).snapshots(),
                  builder: (context, snap) {
                    if (snap.hasData && _loadedForKey != key) {
                      final data = snap.data!.data();
                      final m = data == null
                          ? Menu(id: key, date: key)
                          : Menu.fromMap(key, data);
                      _breakfast.text = m.breakfast;
                      _lunch.text = m.lunch;
                      _dinner.text = m.dinner;
                      _loadedForKey = key;
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _breakfast,
                  decoration: const InputDecoration(
                      labelText: 'Breakfast', prefixIcon: Icon(Icons.free_breakfast)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lunch,
                  decoration: const InputDecoration(
                      labelText: 'Lunch', prefixIcon: Icon(Icons.lunch_dining)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dinner,
                  decoration: const InputDecoration(
                      labelText: 'Dinner', prefixIcon: Icon(Icons.dinner_dining)),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _save(fs, key),
                  icon: const Icon(Icons.save),
                  label: Text(_saving ? 'Saving…' : 'Save menu'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Food feedback', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _FeedbackList(),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _loadedForKey = ''; // force reload for the new date
      });
    }
  }

  Future<void> _save(FirestoreService fs, String key) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await fs.menus.doc(key).set(
            Menu(
              id: key,
              date: key,
              breakfast: _breakfast.text.trim(),
              lunch: _lunch.text.trim(),
              dinner: _dinner.text.trim(),
            ).toMap(),
          );
      messenger.showSnackBar(const SnackBar(content: Text('Menu saved.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Latest food ratings tenants have submitted.
class _FeedbackList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: fs.ratings.where('target', isEqualTo: 'food').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          );
        }
        final docs = snap.data!.docs.toList()
          ..sort((a, b) {
            final ta = a.data()['createdAt'];
            final tb = b.data()['createdAt'];
            final da = ta is Timestamp ? ta.toDate() : DateTime(0);
            final db = tb is Timestamp ? tb.toDate() : DateTime(0);
            return db.compareTo(da);
          });
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('No food feedback yet.'),
          );
        }
        return Column(
          children: docs.map((d) {
            final data = d.data();
            final rating = (data['rating'] as num?)?.toInt() ?? 0;
            final comment = data['comment'] as String? ?? '';
            return Card(
              child: ListTile(
                leading: const Icon(Icons.restaurant),
                title: Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      size: 18,
                      color: Colors.amber,
                    ),
                  ),
                ),
                subtitle: comment.isEmpty ? null : Text(comment),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
