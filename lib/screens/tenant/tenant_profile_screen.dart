import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/tenant.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// Tenant profile: personal details, documents, a move-out request, and a
/// service rating. Move-out requests land in `requests` for the owner to see.
class TenantProfileScreen extends StatelessWidget {
  const TenantProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final user = context.read<AuthService>().currentUser;
    final tenantId = user?.linkedId;
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
          return const Center(child: Text('Profile not found.'));
        }
        final t = Tenant.fromMap(snap.data!.id, snap.data!.data()!);
        final df = DateFormat.yMMMd();
        return ListView(
          padding: const EdgeInsets.all(4),
          children: [
            Center(
              child: CircleAvatar(
                radius: 36,
                child: Text(t.name.isEmpty ? '?' : t.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
                child: Text(t.name,
                    style: Theme.of(context).textTheme.titleLarge)),
            Center(child: Text(t.uniqueId)),
            const Divider(height: 32),
            _row('Phone', t.phone),
            _row('Email', t.email ?? '—'),
            _row('Check-in',
                t.checkInDate == null ? '—' : df.format(t.checkInDate!)),
            _row('Status', t.isActive ? 'Active' : 'Moved out'),
            const Divider(height: 32),
            Text('Documents', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (t.documents.isEmpty)
              const Text('No documents uploaded. Ask the owner to add yours.')
            else
              ...t.documents.map((d) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(d['type']?.toString() ?? 'Document'),
                  )),
            const Divider(height: 32),
            const _ServiceRating(),
            const SizedBox(height: 12),
            if (t.isActive)
              OutlinedButton.icon(
                onPressed: () =>
                    _requestMoveOut(context, fs, t, user?.name ?? 'Tenant'),
                icon: const Icon(Icons.logout),
                label: const Text('Request move-out'),
              ),
          ],
        );
      },
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 100, child: Text(label)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Future<void> _requestMoveOut(BuildContext context, FirestoreService fs,
      Tenant t, String name) async {
    DateTime moveDate = DateTime.now().add(const Duration(days: 30));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Request move-out'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose your intended move-out date. The owner will '
                  'review and confirm.'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat.yMMMd().format(moveDate)),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: moveDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setLocal(() => moveDate = picked);
                    },
                    child: const Text('Pick date'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await fs.requests.add({
      'fromType': 'tenant',
      'fromId': t.id,
      'fromName': name,
      'kind': 'move_out',
      'details': 'Requested move-out on ${DateFormat.yMMMd().format(moveDate)}',
      'moveOutDate': Timestamp.fromDate(moveDate),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Move-out request submitted.')));
    }
  }
}

class _ServiceRating extends StatefulWidget {
  const _ServiceRating();

  @override
  State<_ServiceRating> createState() => _ServiceRatingState();
}

class _ServiceRatingState extends State<_ServiceRating> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rate hostel service',
            style: Theme.of(context).textTheme.titleMedium),
        Row(
          children: List.generate(5, (i) {
            return IconButton(
              icon: Icon(i < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber),
              onPressed: () async {
                setState(() => _rating = i + 1);
                final fs = context.read<FirestoreService>();
                final tenantId =
                    context.read<AuthService>().currentUser?.linkedId;
                await fs.ratings.add({
                  'tenantId': tenantId,
                  'target': 'service',
                  'rating': i + 1,
                  'comment': '',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thanks for rating!')));
                }
              },
            );
          }),
        ),
      ],
    );
  }
}
