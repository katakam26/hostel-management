import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/staff.dart';
import '../../../services/firestore_service.dart';
import 'add_staff_screen.dart';
import 'staff_detail_screen.dart';

/// Owner's staff directory with a role filter. Tap a member for details; the
/// FAB opens the add-staff flow.
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  String _roleFilter = 'all';
  static const _roles = ['all', 'cleaner', 'warden', 'security'];

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddStaffScreen()),
        ),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add staff'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: _roles.map((r) {
                return ChoiceChip(
                  label: Text(r == 'all' ? 'All' : r),
                  selected: _roleFilter == r,
                  onSelected: (_) => setState(() => _roleFilter = r),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: fs.staff.snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var staff = snap.data!.docs
                    .map((d) => Staff.fromMap(d.id, d.data()))
                    .toList();
                if (_roleFilter != 'all') {
                  staff = staff.where((s) => s.role == _roleFilter).toList();
                }
                staff.sort((a, b) =>
                    a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                if (staff.isEmpty) {
                  return const Center(child: Text('No staff to show.'));
                }
                return ListView.separated(
                  itemCount: staff.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = staff[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                            s.name.isEmpty ? '?' : s.name[0].toUpperCase()),
                      ),
                      title: Text(s.name),
                      subtitle: Text('${s.uniqueId} · ${s.role}'),
                      trailing: Chip(
                        label: Text(s.salaryStatus),
                        visualDensity: VisualDensity.compact,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StaffDetailScreen(staffId: s.id),
                        ),
                      ),
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
}
