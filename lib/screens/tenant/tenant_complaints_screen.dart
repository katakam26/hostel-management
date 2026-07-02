import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/complaint.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/status_chip.dart';

/// Tenant raises complaints and tracks their status here.
class TenantComplaintsScreen extends StatelessWidget {
  const TenantComplaintsScreen({super.key});

  static const categories = [
    'water',
    'electricity',
    'fan_ac',
    'cleaning',
    'wifi',
    'food',
    'other',
  ];

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final user = context.read<AuthService>().currentUser;
    final tenantId = user?.linkedId;
    if (tenantId == null) {
      return const Center(child: Text('Your tenant profile is not linked yet.'));
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _raise(context, fs, tenantId, user?.name ?? 'Tenant'),
        icon: const Icon(Icons.add),
        label: const Text('Raise complaint'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            fs.complaints.where('raisedById', isEqualTo: tenantId).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final complaints = snap.data!.docs
              .map((d) => Complaint.fromMap(d.id, d.data()))
              .toList()
            ..sort((a, b) => (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)));
          if (complaints.isEmpty) {
            return const Center(
                child: Text('No complaints yet. Tap "Raise complaint".'));
          }
          final df = DateFormat.yMMMd();
          return ListView.separated(
            padding: const EdgeInsets.all(4),
            itemCount: complaints.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = complaints[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.report_problem_outlined),
                  title: Text(c.categoryLabel),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.description),
                      const SizedBox(height: 4),
                      Text(
                        '${c.createdAt == null ? "" : df.format(c.createdAt!)}'
                        '${c.assignedStaffName != null ? " · ${c.assignedStaffName}" : ""}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: StatusChip(status: c.status),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _raise(BuildContext context, FirestoreService fs,
      String tenantId, String tenantName) async {
    String category = categories.first;
    final description = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Raise a complaint'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(c.replaceAll('_', ' '))))
                      .toList(),
                  onChanged: (v) => setLocal(() => category = v ?? 'other'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Describe the problem'),
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
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || description.text.trim().isEmpty) return;
    await fs.complaints.add(
      Complaint(
        id: '',
        raisedById: tenantId,
        raisedByName: tenantName,
        category: category,
        description: description.text.trim(),
      ).toMap(),
    );
  }
}
