import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/notice.dart';
import '../services/firestore_service.dart';

/// Read-only notices feed shared by the Tenant and Staff apps. Pass the
/// [audience] key ("tenants" or "staff") so each role only sees notices meant
/// for them (plus "all" notices).
class NoticesFeed extends StatelessWidget {
  final String audience;
  const NoticesFeed({super.key, required this.audience});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: fs.notices.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final notices = snap.data!.docs
            .map((d) => Notice.fromMap(d.id, d.data()))
            .where((n) => n.visibleTo(audience))
            .toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0)));
        if (notices.isEmpty) {
          return const Center(child: Text('No notices yet.'));
        }
        final df = DateFormat.yMMMd().add_jm();
        return ListView.separated(
          padding: const EdgeInsets.all(4),
          itemCount: notices.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final n = notices[i];
            return Card(
              color: n.urgent
                  ? Theme.of(context).colorScheme.errorContainer
                  : null,
              child: ListTile(
                leading: Icon(
                  n.urgent ? Icons.priority_high : Icons.campaign_outlined,
                  color: n.urgent
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
                title: Text(n.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(n.body),
                    const SizedBox(height: 6),
                    Text(
                      n.createdAt == null ? '' : df.format(n.createdAt!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
