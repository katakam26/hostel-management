import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/menu.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/dates.dart';

/// Tenant food & mess: today's menu plus a food rating form.
class TenantFoodScreen extends StatelessWidget {
  const TenantFoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final key = Dates.today();

    return ListView(
      padding: const EdgeInsets.all(4),
      children: [
        Text("Today's menu · ${DateFormat.yMMMMEEEEd().format(DateTime.now())}",
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: fs.menus.doc(key).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Card(
                  child: ListTile(title: Text('Loading menu…')));
            }
            final data = snap.data!.data();
            final menu =
                data == null ? Menu(id: key, date: key) : Menu.fromMap(key, data);
            if (menu.isEmpty) {
              return const Card(
                child: ListTile(
                  leading: Icon(Icons.no_meals),
                  title: Text('Menu not published yet'),
                  subtitle: Text('Check back later.'),
                ),
              );
            }
            return Column(
              children: [
                _meal(context, Icons.free_breakfast, 'Breakfast', menu.breakfast),
                _meal(context, Icons.lunch_dining, 'Lunch', menu.lunch),
                _meal(context, Icons.dinner_dining, 'Dinner', menu.dinner),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Text('Rate the food', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const _FoodRatingForm(),
      ],
    );
  }

  Widget _meal(
      BuildContext context, IconData icon, String label, String value) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value.isEmpty ? '—' : value),
      ),
    );
  }
}

class _FoodRatingForm extends StatefulWidget {
  const _FoodRatingForm();

  @override
  State<_FoodRatingForm> createState() => _FoodRatingFormState();
}

class _FoodRatingFormState extends State<_FoodRatingForm> {
  int _rating = 0;
  final _comment = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                );
              }),
            ),
            TextField(
              controller: _comment,
              decoration:
                  const InputDecoration(labelText: 'Comment (optional)'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _saving || _rating == 0 ? null : _submit,
                child: Text(_saving ? 'Sending…' : 'Submit feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final fs = context.read<FirestoreService>();
    final tenantId = context.read<AuthService>().currentUser?.linkedId;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await fs.ratings.add({
        'tenantId': tenantId,
        'target': 'food',
        'rating': _rating,
        'comment': _comment.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _comment.clear();
      setState(() => _rating = 0);
      messenger.showSnackBar(
          const SnackBar(content: Text('Thanks for your feedback!')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
