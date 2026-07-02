import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/block.dart';
import '../../../models/floor.dart';
import '../../../services/firestore_service.dart';
import 'rooms_screen.dart';

/// Floors inside one block. Tap a floor to manage its rooms.
class FloorsScreen extends StatelessWidget {
  final Block block;
  const FloorsScreen({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: Text(block.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addFloor(context, fs),
        icon: const Icon(Icons.add),
        label: const Text('Add floor'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: fs.floors.where('blockId', isEqualTo: block.id).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final floors = snap.data!.docs
              .map((d) => Floor.fromMap(d.id, d.data()))
              .toList()
            ..sort((a, b) => a.number.compareTo(b.number));
          if (floors.isEmpty) {
            return const Center(
              child: Text('No floors yet. Tap "Add floor".'),
            );
          }
          return ListView.separated(
            itemCount: floors.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final floor = floors[i];
              return ListTile(
                leading: const Icon(Icons.layers_outlined),
                title: Text(floor.label),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Delete floor',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteFloor(context, fs, floor),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RoomsScreen(block: block, floor: floor),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addFloor(BuildContext context, FirestoreService fs) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add floor'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Floor number',
            hintText: '0 = ground, 1, 2 ...',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final number = int.tryParse(value ?? '');
    if (number == null) return;
    await fs.floors
        .add(Floor(id: '', blockId: block.id, number: number).toMap());
  }

  /// Delete a floor — only when it has no rooms, so rooms/beds never orphan.
  Future<void> _deleteFloor(
      BuildContext context, FirestoreService fs, Floor floor) async {
    final messenger = ScaffoldMessenger.of(context);
    final rooms = await fs.rooms.where('floorId', isEqualTo: floor.id).get();
    if (rooms.docs.isNotEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Delete this floor\'s rooms first.'),
      ));
      return;
    }
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${floor.label}?'),
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
    await fs.floors.doc(floor.id).delete();
  }
}
