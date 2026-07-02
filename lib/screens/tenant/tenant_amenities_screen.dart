import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/room.dart';
import '../../models/tenant.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/dates.dart';

/// Tenant amenities: shows the room's amenities and lets the tenant book a
/// washing-machine slot. Bookings for today are listed so slots aren't doubled.
class TenantAmenitiesScreen extends StatelessWidget {
  const TenantAmenitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final user = context.read<AuthService>().currentUser;
    final tenantId = user?.linkedId;
    if (tenantId == null) {
      return const Center(child: Text('Your tenant profile is not linked yet.'));
    }

    return ListView(
      padding: const EdgeInsets.all(4),
      children: [
        Text('My amenities', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: fs.tenants.doc(tenantId).get(),
          builder: (context, tSnap) {
            if (!tSnap.hasData) return const LinearProgressIndicator();
            final t = Tenant.fromMap(tSnap.data!.id, tSnap.data!.data() ?? {});
            if (t.roomId == null) {
              return const Card(
                  child: ListTile(title: Text('No room assigned yet.')));
            }
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: fs.rooms.doc(t.roomId).get(),
              builder: (context, rSnap) {
                if (!rSnap.hasData) return const LinearProgressIndicator();
                final room =
                    Room.fromMap(rSnap.data!.id, rSnap.data!.data() ?? {});
                final amenities = <String>{'wifi', ...room.amenities};
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: amenities
                      .map((a) => Chip(
                            avatar: Icon(_iconFor(a), size: 18),
                            label: Text(a.replaceAll('_', ' ')),
                          ))
                      .toList(),
                );
              },
            );
          },
        ),
        const Divider(height: 32),
        Text('Book washing machine',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _BookingForm(tenantId: tenantId, tenantName: user?.name ?? 'Tenant'),
        const SizedBox(height: 16),
        Text("Today's bookings",
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _TodaysBookings(),
      ],
    );
  }

  IconData _iconFor(String a) {
    switch (a) {
      case 'wifi':
        return Icons.wifi;
      case 'washing_machine':
        return Icons.local_laundry_service;
      case 'geyser':
        return Icons.hot_tub;
      case 'parking':
        return Icons.local_parking;
      default:
        return Icons.check;
    }
  }
}

class _BookingForm extends StatefulWidget {
  final String tenantId;
  final String tenantName;
  const _BookingForm({required this.tenantId, required this.tenantName});

  @override
  State<_BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<_BookingForm> {
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text('Slot: ${_start.format(context)} '
                  '– ${_endLabel(context)}'),
            ),
            TextButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule),
              label: const Text('Change'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _saving ? null : _book,
              child: Text(_saving ? '…' : 'Book'),
            ),
          ],
        ),
      ),
    );
  }

  String _endLabel(BuildContext context) {
    final endHour = (_start.hour + 1) % 24;
    return TimeOfDay(hour: endHour, minute: _start.minute).format(context);
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _start);
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _book() async {
    setState(() => _saving = true);
    final fs = context.read<FirestoreService>();
    final messenger = ScaffoldMessenger.of(context);
    final startStr =
        '${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}';
    final endHour = (_start.hour + 1) % 24;
    final endStr =
        '${endHour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}';
    try {
      await fs.amenityBookings.add({
        'amenity': 'washing_machine',
        'tenantId': widget.tenantId,
        'tenantName': widget.tenantName,
        'date': Dates.today(),
        'slotStart': startStr,
        'slotEnd': endStr,
        'createdAt': FieldValue.serverTimestamp(),
      });
      messenger.showSnackBar(
          SnackBar(content: Text('Booked $startStr–$endStr.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _TodaysBookings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: fs.amenityBookings
          .where('date', isEqualTo: Dates.today())
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const LinearProgressIndicator();
        final docs = snap.data!.docs.toList()
          ..sort((a, b) => (a.data()['slotStart'] as String? ?? '')
              .compareTo(b.data()['slotStart'] as String? ?? ''));
        if (docs.isEmpty) {
          return const Text('No bookings today. Be the first!');
        }
        return Column(
          children: docs.map((d) {
            final m = d.data();
            return ListTile(
              dense: true,
              leading: const Icon(Icons.local_laundry_service),
              title: Text('${m['slotStart']} – ${m['slotEnd']}'),
              subtitle: Text(m['tenantName'] as String? ?? ''),
            );
          }).toList(),
        );
      },
    );
  }
}
