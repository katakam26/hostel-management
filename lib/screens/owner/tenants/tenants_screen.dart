import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/tenant.dart';
import '../../../services/firestore_service.dart';
import 'add_tenant_screen.dart';
import 'tenant_detail_screen.dart';

/// Owner's tenant list with a search-free, status-grouped view. Tap a tenant
/// for details; the FAB opens the add-tenant flow.
class TenantsScreen extends StatelessWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddTenantScreen()),
        ),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add tenant'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: fs.tenants.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tenants = snap.data!.docs
              .map((d) => Tenant.fromMap(d.id, d.data()))
              .toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          if (tenants.isEmpty) {
            return const Center(
              child: Text('No tenants yet. Tap "Add tenant".'),
            );
          }
          return ListView.separated(
            itemCount: tenants.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = tenants[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(t.name.isEmpty ? '?' : t.name[0].toUpperCase()),
                ),
                title: Text(t.name),
                subtitle: Text('${t.uniqueId} · ${t.phone}'),
                trailing: Chip(
                  label: Text(t.isActive ? 'active' : 'moved out'),
                  visualDensity: VisualDensity.compact,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TenantDetailScreen(tenantId: t.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
