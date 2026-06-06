import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';

/// Owner home with live counts. Revenue/expense/profit metrics arrive in
/// Phase 2 (payments); for now this surfaces occupancy and headcount.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final name = context.read<AuthService>().currentUser?.name ?? 'Owner';

    return ListView(
      children: [
        Text('Welcome, $name',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Here\'s how your hostel looks today.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount:
              MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _CountCard(
              label: 'Active tenants',
              icon: Icons.people,
              color: Colors.indigo,
              query: fs.tenants.where('status', isEqualTo: 'active'),
            ),
            _CountCard(
              label: 'Total rooms',
              icon: Icons.meeting_room,
              color: Colors.teal,
              query: fs.rooms,
            ),
            _CountCard(
              label: 'Vacant rooms',
              icon: Icons.event_available,
              color: Colors.green,
              query: fs.rooms.where('status', isEqualTo: 'vacant'),
            ),
            _CountCard(
              label: 'Free beds',
              icon: Icons.single_bed,
              color: Colors.orange,
              query: fs.beds.where('occupiedByTenantId', isNull: true),
            ),
            _CountCard(
              label: 'Staff',
              icon: Icons.badge,
              color: Colors.blueGrey,
              query: fs.staff,
            ),
            _CountCard(
              label: 'Open complaints',
              icon: Icons.report_problem,
              color: Colors.redAccent,
              query: fs.complaints.where('status', isEqualTo: 'open'),
            ),
          ],
        ),
      ],
    );
  }
}

/// A metric tile that live-counts the documents returned by [query].
class _CountCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Query<Map<String, dynamic>> query;

  const _CountCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snap) {
                final count =
                    snap.hasData ? snap.data!.docs.length.toString() : '…';
                return Text(count,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold));
              },
            ),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
