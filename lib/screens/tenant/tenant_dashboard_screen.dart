import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/payment.dart';
import '../../models/room.dart';
import '../../models/tenant.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// Tenant home: their room & bed, deposit and this month's payment status.
class TenantDashboardScreen extends StatelessWidget {
  const TenantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    final tenantId = auth.currentUser?.linkedId;

    if (tenantId == null) {
      return const Center(child: Text('Your tenant profile is not linked yet.'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: fs.tenants.doc(tenantId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.data!.exists) {
          return const Center(child: Text('Tenant profile not found.'));
        }
        final t = Tenant.fromMap(snap.data!.id, snap.data!.data()!);
        return ListView(
          padding: const EdgeInsets.all(4),
          children: [
            Text('Hi, ${t.name.split(' ').first} 👋',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _RoomCard(tenant: t),
            const SizedBox(height: 12),
            _DepositCard(tenant: t),
            const SizedBox(height: 12),
            _PaymentStatusCard(tenantId: t.id),
          ],
        );
      },
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Tenant tenant;
  const _RoomCard({required this.tenant});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    if (tenant.roomId == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.meeting_room_outlined),
          title: Text('No room assigned yet'),
        ),
      );
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: fs.rooms.doc(tenant.roomId).get(),
      builder: (context, snap) {
        final room = (snap.hasData && snap.data!.exists)
            ? Room.fromMap(snap.data!.id, snap.data!.data()!)
            : null;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.meeting_room, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text('My Room',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                _row('Room', room?.roomCode ?? '—'),
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: tenant.bedId == null
                      ? null
                      : fs.beds.doc(tenant.bedId).get(),
                  builder: (context, bedSnap) {
                    if (tenant.bedId == null) return _row('Bed', '—');
                    final n = (bedSnap.hasData && bedSnap.data!.exists)
                        ? bedSnap.data!.data()?['bedNumber']?.toString()
                        : null;
                    return _row('Bed', n == null ? '…' : 'Bed $n');
                  },
                ),
                if (room != null) ...[
                  _row('Type',
                      '${room.sharing}-sharing · ${room.ac ? "AC" : "Non-AC"}'),
                  _row('Washroom', room.washroom),
                  _row('Rent', '₹${room.rentAmount} / bed / month'),
                  if (room.amenities.isNotEmpty)
                    _row('Amenities',
                        room.amenities.map((a) => a.replaceAll('_', ' ')).join(', ')),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 100, child: Text(label)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

class _DepositCard extends StatelessWidget {
  final Tenant tenant;
  const _DepositCard({required this.tenant});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          tenant.depositPaid ? Icons.verified : Icons.pending,
          color: tenant.depositPaid ? Colors.green : Colors.orange,
        ),
        title: const Text('Security deposit'),
        subtitle: Text('₹${tenant.depositAmount}'),
        trailing: Text(
          tenant.depositPaid ? 'Paid' : 'Pending',
          style: TextStyle(
            color: tenant.depositPaid ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _PaymentStatusCard extends StatelessWidget {
  final String tenantId;
  const _PaymentStatusCard({required this.tenantId});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: fs.payments.where('tenantId', isEqualTo: tenantId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Card(
              child: ListTile(title: Text('Loading payments…')));
        }
        final payments = snap.data!.docs
            .map((d) => Payment.fromMap(d.id, d.data()))
            .where((p) => !p.isPaid)
            .toList()
          ..sort((a, b) => a.month.compareTo(b.month));
        final due = payments.fold<num>(0, (s, p) => s + p.totalAmount);
        return Card(
          color: payments.isEmpty ? null : Colors.orange.withValues(alpha: 0.12),
          child: ListTile(
            leading: Icon(
              payments.isEmpty ? Icons.check_circle : Icons.payments,
              color: payments.isEmpty ? Colors.green : Colors.orange,
            ),
            title: Text(payments.isEmpty
                ? 'All rent paid'
                : '${payments.length} pending bill(s)'),
            subtitle: Text(payments.isEmpty
                ? 'You have no dues. Thank you!'
                : 'Total due: ₹$due · oldest ${DateFormat.yMMM().format(_asDate(payments.first.month))}'),
          ),
        );
      },
    );
  }

  DateTime _asDate(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return DateTime.now();
    return DateTime(
        int.tryParse(parts[0]) ?? 2026, int.tryParse(parts[1]) ?? 1);
  }
}
