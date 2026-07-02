import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/block.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import 'floors_screen.dart';

/// Top level of Hostel Setup: the Owner's blocks. One hostel per owner for now,
/// keyed by the owner's uid as the hostelId. Tap a block to manage its floors.
class HostelSetupScreen extends StatelessWidget {
  const HostelSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final hostelId = context.read<AuthService>().currentUser!.uid;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addBlock(context, fs, hostelId),
        icon: const Icon(Icons.add),
        label: const Text('Add block'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: fs.blocks.where('hostelId', isEqualTo: hostelId).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final blocks = snap.data!.docs
              .map((d) => Block.fromMap(d.id, d.data()))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          if (blocks.isEmpty) {
            return const _Empty(
              icon: Icons.apartment_outlined,
              message: 'No blocks yet.\nTap "Add block" to start setting up the hostel.',
            );
          }
          return ListView.separated(
            itemCount: blocks.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final block = blocks[i];
              return ListTile(
                leading: const Icon(Icons.apartment),
                title: Text(block.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'rename') _renameBlock(context, fs, block);
                        if (v == 'delete') _deleteBlock(context, fs, block);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FloorsScreen(block: block),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addBlock(
      BuildContext context, FirestoreService fs, String hostelId) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add block'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Block name',
            hintText: 'e.g. A Block',
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
    if (name == null || name.isEmpty) return;
    await fs.blocks.add(Block(id: '', hostelId: hostelId, name: name).toMap());
  }

  Future<void> _renameBlock(
      BuildContext context, FirestoreService fs, Block block) async {
    final controller = TextEditingController(text: block.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename block'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Block name'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await fs.blocks.doc(block.id).update({'name': name});
  }

  /// Delete a block — only when it has no floors, so nothing orphans below it.
  Future<void> _deleteBlock(
      BuildContext context, FirestoreService fs, Block block) async {
    final messenger = ScaffoldMessenger.of(context);
    final floors = await fs.floors.where('blockId', isEqualTo: block.id).get();
    if (floors.docs.isNotEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Delete this block\'s floors first.'),
      ));
      return;
    }
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${block.name}?'),
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
    await fs.blocks.doc(block.id).delete();
  }
}

/// Simple empty-state used across the hostel-setup screens.
class _Empty extends StatelessWidget {
  final IconData icon;
  final String message;
  const _Empty({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
