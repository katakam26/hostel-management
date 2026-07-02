import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/notice.dart';
import '../../../services/firestore_service.dart';

/// Owner notices composer + list. Notices are read by tenants/staff in their
/// own notices feed, filtered by audience.
class OwnerNoticesScreen extends StatelessWidget {
  const OwnerNoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _compose(context, fs),
        icon: const Icon(Icons.add),
        label: const Text('New notice'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: fs.notices.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notices = snap.data!.docs
              .map((d) => Notice.fromMap(d.id, d.data()))
              .toList()
            ..sort((a, b) => (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)));
          if (notices.isEmpty) {
            return const Center(
                child: Text('No notices yet. Tap "New notice".'));
          }
          final df = DateFormat.yMMMd().add_jm();
          return ListView.separated(
            itemCount: notices.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = notices[i];
              return ListTile(
                leading: Icon(
                  n.urgent ? Icons.priority_high : Icons.campaign_outlined,
                  color: n.urgent ? Colors.red : null,
                ),
                title: Text(n.title),
                subtitle: Text(
                    '${n.body}\nTo: ${n.audience}${n.createdAt == null ? "" : " · ${df.format(n.createdAt!)}"}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => fs.notices.doc(n.id).delete(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _compose(BuildContext context, FirestoreService fs) async {
    final title = TextEditingController();
    final body = TextEditingController();
    String audience = 'all';
    bool urgent = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New notice'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: body,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: audience,
                  decoration: const InputDecoration(labelText: 'Audience'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Everyone')),
                    DropdownMenuItem(
                        value: 'tenants', child: Text('Tenants only')),
                    DropdownMenuItem(value: 'staff', child: Text('Staff only')),
                  ],
                  onChanged: (v) => setLocal(() => audience = v ?? 'all'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mark urgent'),
                  value: urgent,
                  onChanged: (v) => setLocal(() => urgent = v),
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
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    await fs.notices.add(
      Notice(
        id: '',
        title: title.text.trim(),
        body: body.text.trim(),
        audience: audience,
        urgent: urgent,
      ).toMap(),
    );
  }
}
