import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/block.dart';
import '../../../models/floor.dart';
import '../../../models/room.dart';
import '../../../services/firestore_service.dart';

/// Rooms on one floor. Adding a room also generates one `beds/{bedId}` doc per
/// sharing slot so tenant assignment has beds to attach to.
class RoomsScreen extends StatelessWidget {
  final Block block;
  final Floor floor;
  const RoomsScreen({super.key, required this.block, required this.floor});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: Text('${block.name} · ${floor.label}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addRoom(context, fs),
        icon: const Icon(Icons.add),
        label: const Text('Add room'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: fs.rooms.where('floorId', isEqualTo: floor.id).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rooms = snap.data!.docs
              .map((d) => Room.fromMap(d.id, d.data()))
              .toList()
            ..sort((a, b) => a.roomCode.compareTo(b.roomCode));
          if (rooms.isEmpty) {
            return const Center(child: Text('No rooms yet. Tap "Add room".'));
          }
          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final room = rooms[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: room.isVacant
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  child: Icon(room.ac ? Icons.ac_unit : Icons.bed_outlined),
                ),
                title: Text(room.roomCode),
                subtitle: Text(
                  '${room.sharing}-sharing · ${room.ac ? "AC" : "Non-AC"} · '
                  '${room.washroom} washroom · ₹${room.rentAmount}/bed/mo',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(room.status),
                      visualDensity: VisualDensity.compact,
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'rent') _editRent(context, fs, room);
                        if (v == 'delete') _deleteRoom(context, fs, room);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rent', child: Text('Edit rent')),
                        PopupMenuItem(
                            value: 'delete', child: Text('Delete room')),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addRoom(BuildContext context, FirestoreService fs) async {
    final result = await showModalBottomSheet<_RoomDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddRoomSheet(),
    );
    if (result == null) return;

    // Create the room, then a bed per sharing slot in one batch.
    final roomRef = fs.rooms.doc();
    final room = Room(
      id: roomRef.id,
      blockId: block.id,
      floorId: floor.id,
      roomCode: result.roomCode,
      sharing: result.sharing,
      ac: result.ac,
      washroom: result.washroom,
      rentAmount: result.rent,
      depositAmount: result.deposit,
      amenities: result.amenities,
    );
    final batch = fs.rooms.firestore.batch();
    batch.set(roomRef, room.toMap());
    for (var n = 1; n <= result.sharing; n++) {
      final bedRef = fs.beds.doc();
      batch.set(bedRef, {
        'roomId': roomRef.id,
        'bedNumber': n,
        'occupiedByTenantId': null,
      });
    }
    await batch.commit();
  }

  Future<void> _editRent(
      BuildContext context, FirestoreService fs, Room room) async {
    final rent = TextEditingController(text: room.rentAmount.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit rent · ${room.roomCode}'),
        content: TextField(
          controller: rent,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Rent per bed / month (₹)', prefixText: '₹ '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final value = num.tryParse(rent.text);
    if (value == null) return;
    await fs.rooms.doc(room.id).update({'rentAmount': value});
  }

  /// Delete a room and its beds — only when no bed is occupied, so we never
  /// orphan a tenant.
  Future<void> _deleteRoom(
      BuildContext context, FirestoreService fs, Room room) async {
    final messenger = ScaffoldMessenger.of(context);
    final beds = await fs.beds.where('roomId', isEqualTo: room.id).get();
    final occupied =
        beds.docs.any((d) => d.data()['occupiedByTenantId'] != null);
    if (occupied) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Check out its tenants before deleting this room.'),
      ));
      return;
    }
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete room ${room.roomCode}?'),
        content: const Text('This removes the room and its beds. This cannot '
            'be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final batch = fs.rooms.firestore.batch();
    for (final b in beds.docs) {
      batch.delete(fs.beds.doc(b.id));
    }
    batch.delete(fs.rooms.doc(room.id));
    await batch.commit();
  }
}

/// Plain data carried back from the add-room sheet.
class _RoomDraft {
  final String roomCode;
  final int sharing;
  final bool ac;
  final String washroom;
  final num rent;
  final num deposit;
  final List<String> amenities;
  _RoomDraft({
    required this.roomCode,
    required this.sharing,
    required this.ac,
    required this.washroom,
    required this.rent,
    required this.deposit,
    required this.amenities,
  });
}

class _AddRoomSheet extends StatefulWidget {
  const _AddRoomSheet();

  @override
  State<_AddRoomSheet> createState() => _AddRoomSheetState();
}

class _AddRoomSheetState extends State<_AddRoomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _rent = TextEditingController();
  final _deposit = TextEditingController();
  int _sharing = 1;
  bool _ac = false;
  String _washroom = 'attached';
  final _allAmenities = const ['wifi', 'washing_machine', 'geyser', 'parking'];
  final Set<String> _amenities = {};

  @override
  void dispose() {
    _code.dispose();
    _rent.dispose();
    _deposit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add room', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _code,
                decoration: const InputDecoration(
                  labelText: 'Room code (unique)',
                  hintText: 'e.g. A-101',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Sharing'),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _sharing,
                    items: [1, 2, 3, 4]
                        .map((n) => DropdownMenuItem(
                            value: n, child: Text('$n-sharing')))
                        .toList(),
                    onChanged: (v) => setState(() => _sharing = v ?? 1),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Air conditioned'),
                value: _ac,
                onChanged: (v) => setState(() => _ac = v),
              ),
              Row(
                children: [
                  const Text('Washroom'),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _washroom,
                    items: const [
                      DropdownMenuItem(
                          value: 'attached', child: Text('Attached')),
                      DropdownMenuItem(value: 'common', child: Text('Common')),
                    ],
                    onChanged: (v) =>
                        setState(() => _washroom = v ?? 'attached'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _rent,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Rent per bed / month (₹)',
                    helperText: 'Each tenant in the room is billed this amount',
                    prefixText: '₹ '),
                validator: (v) =>
                    num.tryParse(v ?? '') == null ? 'Enter a number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deposit,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Deposit (₹)', prefixText: '₹ '),
                validator: (v) =>
                    num.tryParse(v ?? '') == null ? 'Enter a number' : null,
              ),
              const SizedBox(height: 12),
              const Text('Amenities'),
              Wrap(
                spacing: 8,
                children: _allAmenities.map((a) {
                  final on = _amenities.contains(a);
                  return FilterChip(
                    label: Text(a.replaceAll('_', ' ')),
                    selected: on,
                    onSelected: (s) => setState(
                        () => s ? _amenities.add(a) : _amenities.remove(a)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Add room'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_RoomDraft(
      roomCode: _code.text.trim(),
      sharing: _sharing,
      ac: _ac,
      washroom: _washroom,
      rent: num.parse(_rent.text),
      deposit: num.parse(_deposit.text),
      amenities: _amenities.toList(),
    ));
  }
}
