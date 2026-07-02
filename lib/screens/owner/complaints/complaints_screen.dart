import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/complaint.dart';
import '../../../models/staff.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/status_chip.dart';

/// Owner complaints board. Lists every complaint, lets the owner assign it to a
/// staff member and move it through its status lifecycle.
class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  bool _openOnly = true;

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Unresolved only'),
                  selected: _openOnly,
                  onSelected: (v) => setState(() => _openOnly = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: fs.complaints.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var complaints = snap.data!.docs
                    .map((d) => Complaint.fromMap(d.id, d.data()))
                    .toList();
                if (_openOnly) {
                  complaints =
                      complaints.where((c) => !c.isResolved).toList();
                }
                complaints.sort((a, b) => (b.createdAt ?? DateTime(0))
                    .compareTo(a.createdAt ?? DateTime(0)));
                if (complaints.isEmpty) {
                  return const Center(child: Text('No complaints to show.'));
                }
                return ListView.separated(
                  itemCount: complaints.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = complaints[i];
                    return ListTile(
                      leading: const Icon(Icons.report_problem_outlined),
                      title: Text('${c.categoryLabel} · ${c.raisedByName}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.description),
                          if (c.assignedStaffName != null)
                            Text('Assigned to ${c.assignedStaffName}',
                                style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      isThreeLine: c.assignedStaffName != null,
                      trailing: StatusChip(status: c.status),
                      onTap: () => _manage(fs, c),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _manage(FirestoreService fs, Complaint c) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _ManageSheet(complaint: c),
    );
  }
}

class _ManageSheet extends StatelessWidget {
  final Complaint complaint;
  const _ManageSheet({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(complaint.categoryLabel,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(complaint.description),
          const Divider(height: 24),
          Text('Assign to staff',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: fs.staff.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const LinearProgressIndicator();
              final staff = snap.data!.docs
                  .map((d) => Staff.fromMap(d.id, d.data()))
                  .toList();
              if (staff.isEmpty) {
                return const Text('No staff yet. Add staff first.');
              }
              return Wrap(
                spacing: 8,
                children: staff.map((s) {
                  final selected = complaint.assignedStaffId == s.id;
                  return ChoiceChip(
                    label: Text(s.name),
                    selected: selected,
                    onSelected: (_) {
                      fs.complaints.doc(complaint.id).update({
                        'assignedStaffId': s.id,
                        'assignedStaffName': s.name,
                        'status': 'assigned',
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              );
            },
          ),
          const Divider(height: 24),
          Text('Set status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final s in ['open', 'assigned', 'in_progress', 'resolved'])
                ActionChip(
                  label: Text(s.replaceAll('_', ' ')),
                  onPressed: () {
                    fs.complaints.doc(complaint.id).update({
                      'status': s,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
