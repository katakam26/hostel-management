import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/tenant.dart';
import '../../../services/firestore_service.dart';

/// Read-only tenant profile with two owner actions: toggle deposit paid and
/// check the tenant out (frees the bed and re-opens the room).
class TenantDetailScreen extends StatelessWidget {
  final String tenantId;
  const TenantDetailScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Tenant')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: fs.tenants.doc(tenantId).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.data!.exists) {
            return const Center(child: Text('Tenant not found.'));
          }
          final t = Tenant.fromMap(snap.data!.id, snap.data!.data()!);
          final df = DateFormat.yMMMd();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 36,
                  child: Text(
                    t.name.isEmpty ? '?' : t.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(t.name,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              Center(child: Text(t.uniqueId)),
              const SizedBox(height: 16),
              _row('Phone', t.phone),
              _row('Email', t.email ?? '—'),
              _row('Status', t.isActive ? 'Active' : 'Moved out'),
              _row(
                'Check-in',
                t.checkInDate == null ? '—' : df.format(t.checkInDate!),
              ),
              if (t.checkOutDate != null)
                _row('Check-out', df.format(t.checkOutDate!)),
              _row('Deposit', '₹${t.depositAmount}'),
              const Divider(height: 32),
              SwitchListTile(
                title: const Text('Deposit paid'),
                value: t.depositPaid,
                onChanged: (v) =>
                    fs.tenants.doc(t.id).update({'depositPaid': v}),
              ),
              const SizedBox(height: 12),
              if (t.isActive)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _checkOut(context, fs, t),
                  icon: const Icon(Icons.logout),
                  label: const Text('Check out tenant'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 110, child: Text(label)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Future<void> _checkOut(
      BuildContext context, FirestoreService fs, Tenant t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Check out tenant?'),
        content: Text(
            'This frees ${t.name}\'s bed and re-opens the room for new tenants.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Check out'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final batch = fs.tenants.firestore.batch();
    batch.update(fs.tenants.doc(t.id), {
      'status': 'moved_out',
      'checkOutDate': Timestamp.fromDate(DateTime.now()),
    });
    if (t.bedId != null) {
      batch.update(fs.beds.doc(t.bedId), {'occupiedByTenantId': null});
    }
    if (t.roomId != null) {
      batch.update(fs.rooms.doc(t.roomId), {'status': 'vacant'});
    }
    await batch.commit();
  }
}
