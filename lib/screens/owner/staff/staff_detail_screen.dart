import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/staff.dart';
import '../../../services/firestore_service.dart';

/// Staff profile with salary status toggle and a simple shift editor.
class StaffDetailScreen extends StatelessWidget {
  final String staffId;
  const StaffDetailScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: fs.staff.doc(staffId).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.data!.exists) {
            return const Center(child: Text('Staff not found.'));
          }
          final s = Staff.fromMap(snap.data!.id, snap.data!.data()!);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 36,
                  child: Text(
                    s.name.isEmpty ? '?' : s.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(s.name,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              Center(child: Text('${s.uniqueId} · ${s.role}')),
              const SizedBox(height: 16),
              _row('Phone', s.phone),
              _row('Email', s.email ?? '—'),
              _row('Salary', '₹${s.salaryAmount} / month'),
              const Divider(height: 32),
              SwitchListTile(
                title: const Text('Salary paid this month'),
                value: s.salaryStatus == 'paid',
                onChanged: (v) => fs.staff
                    .doc(s.id)
                    .update({'salaryStatus': v ? 'paid' : 'unpaid'}),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Shifts',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: () => _addShift(context, fs, s),
                    icon: const Icon(Icons.add),
                    label: const Text('Add shift'),
                  ),
                ],
              ),
              if (s.shifts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No shifts assigned.'),
                ),
              for (final shift in s.shifts)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.schedule),
                  title: Text(
                    '${shift['day']}  ·  ${shift['start']} – ${shift['end']}',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text(label)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Future<void> _addShift(
      BuildContext context, FirestoreService fs, Staff s) async {
    String day = 'Mon';
    final start = TextEditingController(text: '09:00');
    final end = TextEditingController(text: '17:00');
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add shift'),
        content: StatefulBuilder(
          builder: (ctx, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: day,
                decoration: const InputDecoration(labelText: 'Day'),
                items: days
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setLocal(() => day = v ?? 'Mon'),
              ),
              TextField(
                controller: start,
                decoration: const InputDecoration(labelText: 'Start (HH:mm)'),
              ),
              TextField(
                controller: end,
                decoration: const InputDecoration(labelText: 'End (HH:mm)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await fs.staff.doc(s.id).update({
      'shifts': FieldValue.arrayUnion([
        {'day': day, 'start': start.text.trim(), 'end': end.text.trim()},
      ]),
    });
  }
}
