import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/complaint.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/status_chip.dart';

/// Complaints assigned to this staff member. They can advance the status as
/// they work (assigned -> in_progress -> resolved).
class StaffComplaintsScreen extends StatelessWidget {
  const StaffComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final staffId = context.read<AuthService>().currentUser?.linkedId;
    if (staffId == null) {
      return const Center(child: Text('Your staff profile is not linked yet.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          fs.complaints.where('assignedStaffId', isEqualTo: staffId).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final complaints = snap.data!.docs
            .map((d) => Complaint.fromMap(d.id, d.data()))
            .toList()
          ..sort((a, b) {
            // Unresolved first, then newest.
            if (a.isResolved != b.isResolved) return a.isResolved ? 1 : -1;
            return (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0));
          });
        if (complaints.isEmpty) {
          return const Center(child: Text('No complaints assigned to you.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(4),
          itemCount: complaints.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final c = complaints[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${c.categoryLabel} · ${c.raisedByName}',
                            style: Theme.of(context).textTheme.titleMedium),
                        StatusChip(status: c.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(c.description),
                    const SizedBox(height: 8),
                    if (!c.isResolved)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (c.status != 'in_progress')
                            TextButton(
                              onPressed: () =>
                                  _setStatus(fs, c, 'in_progress'),
                              child: const Text('Start work'),
                            ),
                          FilledButton(
                            onPressed: () => _setStatus(fs, c, 'resolved'),
                            child: const Text('Mark resolved'),
                          ),
                        ],
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

  Future<void> _setStatus(
      FirestoreService fs, Complaint c, String status) async {
    await fs.complaints.doc(c.id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
