import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/attendance.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/dates.dart';

/// Staff attendance: mark today's check-in / check-out and see past history.
/// Today's row is keyed by `{staffId}_{date}` so a person has one row per day.
class StaffAttendanceScreen extends StatelessWidget {
  const StaffAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final staffId = context.read<AuthService>().currentUser?.linkedId;
    if (staffId == null) {
      return const Center(child: Text('Your staff profile is not linked yet.'));
    }
    final todayDocId = '${staffId}_${Dates.today()}';

    return ListView(
      padding: const EdgeInsets.all(4),
      children: [
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: fs.attendance.doc(todayDocId).snapshots(),
          builder: (context, snap) {
            final today = (snap.hasData && snap.data!.exists)
                ? Attendance.fromMap(snap.data!.id, snap.data!.data()!)
                : null;
            final tf = DateFormat.jm();
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today · ${DateFormat.yMMMMd().format(DateTime.now())}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(today?.checkIn == null
                              ? 'Not checked in'
                              : 'In: ${tf.format(today!.checkIn!)}'),
                        ),
                        Expanded(
                          child: Text(today?.checkOut == null
                              ? 'Not checked out'
                              : 'Out: ${tf.format(today!.checkOut!)}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: today?.checkIn != null
                              ? null
                              : () => _checkIn(fs, todayDocId, staffId),
                          icon: const Icon(Icons.login),
                          label: const Text('Check in'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: (today?.checkIn == null ||
                                  today?.checkOut != null)
                              ? null
                              : () => _checkOut(fs, todayDocId),
                          icon: const Icon(Icons.logout),
                          label: const Text('Check out'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text('History', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: fs.attendance
              .where('personId', isEqualTo: staffId)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const LinearProgressIndicator();
            final rows = snap.data!.docs
                .map((d) => Attendance.fromMap(d.id, d.data()))
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            if (rows.isEmpty) return const Text('No attendance history yet.');
            final tf = DateFormat.jm();
            return Column(
              children: rows.map((a) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.event_available),
                  title: Text(a.date),
                  subtitle: Text(
                    '${a.checkIn == null ? "—" : tf.format(a.checkIn!)} '
                    'to ${a.checkOut == null ? "—" : tf.format(a.checkOut!)}',
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _checkIn(
      FirestoreService fs, String docId, String staffId) async {
    await fs.attendance.doc(docId).set({
      'personType': 'staff',
      'personId': staffId,
      'date': Dates.today(),
      'checkIn': FieldValue.serverTimestamp(),
      'checkOut': null,
    });
  }

  Future<void> _checkOut(FirestoreService fs, String docId) async {
    await fs.attendance
        .doc(docId)
        .update({'checkOut': FieldValue.serverTimestamp()});
  }
}
