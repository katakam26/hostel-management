import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/complaint.dart';
import '../../models/staff.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/status_chip.dart';

/// Staff home: assigned shift timings and the complaints assigned to them
/// (their tasks for the day).
class StaffShiftsScreen extends StatelessWidget {
  const StaffShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final staffId = context.read<AuthService>().currentUser?.linkedId;
    if (staffId == null) {
      return const Center(child: Text('Your staff profile is not linked yet.'));
    }

    return ListView(
      padding: const EdgeInsets.all(4),
      children: [
        Text('My shifts', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: fs.staff.doc(staffId).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const LinearProgressIndicator();
            if (!snap.data!.exists) {
              return const Text('Staff profile not found.');
            }
            final s = Staff.fromMap(snap.data!.id, snap.data!.data()!);
            if (s.shifts.isEmpty) {
              return const Card(
                child: ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('No shifts assigned yet'),
                  subtitle: Text('The owner will set your shift timings.'),
                ),
              );
            }
            return Column(
              children: s.shifts
                  .map((shift) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.schedule),
                          title: Text(shift['day']?.toString() ?? ''),
                          subtitle: Text(
                              '${shift['start']} – ${shift['end']}'),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
        const Divider(height: 32),
        Text('My tasks (assigned complaints)',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: fs.complaints
              .where('assignedStaffId', isEqualTo: staffId)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const LinearProgressIndicator();
            final tasks = snap.data!.docs
                .map((d) => Complaint.fromMap(d.id, d.data()))
                .where((c) => !c.isResolved)
                .toList();
            if (tasks.isEmpty) {
              return const Text('No open tasks. Nice work!');
            }
            return Column(
              children: tasks
                  .map((c) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.build_outlined),
                          title: Text(c.categoryLabel),
                          subtitle: Text(c.description),
                          trailing: StatusChip(status: c.status),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
