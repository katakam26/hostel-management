import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/app_role.dart';
import '../../../models/bed.dart';
import '../../../models/room.dart';
import '../../../models/tenant.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../utils/id_gen.dart';
import '../widgets/credentials_dialog.dart';

/// Add-tenant flow: collect details, pick a free bed, then provision a login.
/// On submit we issue a Firebase Auth account (via AuthService.issueAccount),
/// create the tenant doc, occupy the bed, and update room status atomically.
class AddTenantScreen extends StatefulWidget {
  const AddTenantScreen({super.key});

  @override
  State<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _deposit = TextEditingController();

  String? _bedId;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _deposit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Add tenant')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  const InputDecoration(labelText: 'Email (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _deposit,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Deposit amount (₹)', prefixText: '₹ '),
              validator: (v) =>
                  num.tryParse(v ?? '') == null ? 'Enter a number' : null,
            ),
            const SizedBox(height: 16),
            Text('Assign bed', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _BedPicker(
              fs: fs,
              selectedBedId: _bedId,
              onChanged: (id) => setState(() => _bedId = id),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Creating…' : 'Create tenant & issue login'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bedId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please assign a bed.')));
      return;
    }
    setState(() => _saving = true);
    final fs = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Resolve the bed + room so we know the roomId and remaining vacancy.
      final bedSnap = await fs.beds.doc(_bedId).get();
      final bed = Bed.fromMap(bedSnap.id, bedSnap.data()!);
      final roomSnap = await fs.rooms.doc(bed.roomId).get();
      final room = Room.fromMap(roomSnap.id, roomSnap.data()!);

      final uniqueId = IdGen.tenantId();
      final password = IdGen.tempPassword();
      final tenantRef = fs.tenants.doc();

      // 1) Provision the login first (won't sign the owner out).
      await auth.issueAccount(
        uniqueId: uniqueId,
        password: password,
        role: AppRole.tenant,
        name: _name.text.trim(),
        linkedId: tenantRef.id,
      );

      // 2) Create tenant + occupy bed in one batch.
      final tenant = Tenant(
        id: tenantRef.id,
        uniqueId: uniqueId,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        roomId: room.id,
        bedId: bed.id,
        checkInDate: DateTime.now(),
        depositAmount: num.parse(_deposit.text),
      );
      final batch = fs.tenants.firestore.batch();
      batch.set(tenantRef, tenant.toMap());
      batch.update(fs.beds.doc(bed.id), {'occupiedByTenantId': tenantRef.id});

      // Mark the room occupied once its last free bed is taken.
      final freeBeds = await fs.beds
          .where('roomId', isEqualTo: room.id)
          .where('occupiedByTenantId', isNull: true)
          .get();
      if (freeBeds.docs.length <= 1) {
        batch.update(fs.rooms.doc(room.id), {'status': 'occupied'});
      }
      await batch.commit();

      if (!mounted) return;
      await showCredentialsDialog(
        context,
        title: 'Tenant created',
        uniqueId: uniqueId,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Dropdown of free beds, labelled with their room code.
class _BedPicker extends StatelessWidget {
  final FirestoreService fs;
  final String? selectedBedId;
  final ValueChanged<String?> onChanged;
  const _BedPicker({
    required this.fs,
    required this.selectedBedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: fs.beds.where('occupiedByTenantId', isNull: true).snapshots(),
      builder: (context, bedSnap) {
        if (!bedSnap.hasData) {
          return const LinearProgressIndicator();
        }
        final beds = bedSnap.data!.docs
            .map((d) => Bed.fromMap(d.id, d.data()))
            .toList();
        if (beds.isEmpty) {
          return const Text(
            'No free beds. Add rooms in Hostel Setup first.',
          );
        }
        // Resolve room codes for the rooms that have free beds.
        return FutureBuilder<Map<String, String>>(
          future: _roomCodes(beds.map((b) => b.roomId).toSet()),
          builder: (context, roomSnap) {
            final codes = roomSnap.data ?? const {};
            beds.sort((a, b) {
              final ca = codes[a.roomId] ?? '';
              final cb = codes[b.roomId] ?? '';
              final byRoom = ca.compareTo(cb);
              return byRoom != 0 ? byRoom : a.bedNumber.compareTo(b.bedNumber);
            });
            return DropdownButtonFormField<String>(
              initialValue: selectedBedId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Free bed',
                border: OutlineInputBorder(),
              ),
              items: beds.map((b) {
                final code = codes[b.roomId] ?? b.roomId;
                return DropdownMenuItem(
                  value: b.id,
                  child: Text('$code · Bed ${b.bedNumber}'),
                );
              }).toList(),
              onChanged: onChanged,
            );
          },
        );
      },
    );
  }

  Future<Map<String, String>> _roomCodes(Set<String> roomIds) async {
    final entries = <String, String>{};
    for (final id in roomIds) {
      final snap = await fs.rooms.doc(id).get();
      entries[id] = (snap.data()?['roomCode'] as String?) ?? id;
    }
    return entries;
  }
}
