import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/payment.dart';
import '../../../models/room.dart';
import '../../../models/tenant.dart';
import '../../../services/firestore_service.dart';
import '../../../utils/dates.dart';

/// Owner rent & payments board. Shows this month's bills, lets the owner
/// generate rent for every active tenant in one tap, add electricity/amenity
/// charges, and mark bills paid/unpaid.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  String _month = Dates.thisMonth();
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generating ? null : () => _generateRent(fs),
        icon: _generating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.receipt_long),
        label: Text(_generating ? 'Generating…' : 'Generate rent'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text('Month', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _month,
                  items: _recentMonths()
                      .map((m) => DropdownMenuItem(
                          value: m, child: Text(Dates.prettyMonth(m))))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _month = v ?? Dates.thisMonth()),
                ),
              ],
            ),
          ),
          _MonthSummary(month: _month),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: fs.payments.where('month', isEqualTo: _month).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final payments = snap.data!.docs
                    .map((d) => Payment.fromMap(d.id, d.data()))
                    .toList()
                  ..sort((a, b) => a.tenantName
                      .toLowerCase()
                      .compareTo(b.tenantName.toLowerCase()));
                if (payments.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No bills for this month yet.\n'
                        'Tap "Generate rent" to bill all active tenants.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: payments.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = payments[i];
                    return ListTile(
                      leading: Icon(
                        p.isPaid
                            ? Icons.check_circle
                            : Icons.pending_actions,
                        color: p.isPaid ? Colors.green : Colors.orange,
                      ),
                      title: Text(p.tenantName),
                      subtitle: Text(
                        'Rent ₹${p.baseRent}'
                        '${p.electricityBill > 0 ? " · Elec ₹${p.electricityBill}" : ""}'
                        '${p.extraAmenityCharge > 0 ? " · Extra ₹${p.extraAmenityCharge}" : ""}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${p.totalAmount}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(p.status,
                              style: TextStyle(
                                  color: p.isPaid
                                      ? Colors.green
                                      : Colors.orange)),
                        ],
                      ),
                      onTap: () => _editBill(fs, p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _recentMonths() {
    final now = DateTime.now();
    return List.generate(
        6, (i) => Dates.monthKey(DateTime(now.year, now.month - i)));
  }

  /// Create a rent bill for every active tenant that doesn't already have one
  /// this month, using their room's rent amount.
  Future<void> _generateRent(FirestoreService fs) async {
    setState(() => _generating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final tenantSnap =
          await fs.tenants.where('status', isEqualTo: 'active').get();
      final existing =
          await fs.payments.where('month', isEqualTo: _month).get();
      final billedTenantIds = existing.docs
          .map((d) => d.data()['tenantId'] as String?)
          .whereType<String>()
          .toSet();

      var created = 0;
      final batch = fs.payments.firestore.batch();
      for (final doc in tenantSnap.docs) {
        final tenant = Tenant.fromMap(doc.id, doc.data());
        if (billedTenantIds.contains(tenant.id)) continue;
        num rent = 0;
        if (tenant.roomId != null) {
          final roomSnap = await fs.rooms.doc(tenant.roomId).get();
          if (roomSnap.exists) {
            rent = Room.fromMap(roomSnap.id, roomSnap.data()!).rentAmount;
          }
        }
        final ref = fs.payments.doc();
        batch.set(
          ref,
          Payment(
            id: ref.id,
            tenantId: tenant.id,
            tenantName: tenant.name,
            month: _month,
            baseRent: rent,
          ).toMap(),
        );
        created++;
      }
      if (created > 0) await batch.commit();
      messenger.showSnackBar(SnackBar(
        content: Text(created == 0
            ? 'All active tenants already billed for this month.'
            : 'Generated $created rent bill(s).'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _editBill(FirestoreService fs, Payment p) async {
    final elec = TextEditingController(text: p.electricityBill.toString());
    final extra = TextEditingController(text: p.extraAmenityCharge.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p.tenantName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Base rent: ₹${p.baseRent}'),
            const SizedBox(height: 12),
            TextField(
              controller: elec,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Electricity bill (₹)', prefixText: '₹ '),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: extra,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Extra amenity charge (₹)', prefixText: '₹ '),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final e = num.tryParse(elec.text) ?? 0;
    final x = num.tryParse(extra.text) ?? 0;
    await fs.payments.doc(p.id).update({
      'electricityBill': e,
      'extraAmenityCharge': x,
      'totalAmount': p.baseRent + e + x,
    });
    if (!mounted) return;
    // Offer to toggle paid state right after editing.
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(p.isPaid ? 'Bill updated.' : 'Bill updated.'),
      action: SnackBarAction(
        label: p.isPaid ? 'Mark unpaid' : 'Mark paid',
        onPressed: () => _togglePaid(fs, p),
      ),
    ));
  }

  Future<void> _togglePaid(FirestoreService fs, Payment p) async {
    await fs.payments.doc(p.id).update({
      'status': p.isPaid ? 'unpaid' : 'paid',
      'paidAt': p.isPaid ? null : FieldValue.serverTimestamp(),
      'method': p.isPaid ? null : 'cash',
    });
  }
}

/// Revenue/collected/pending summary for the selected month.
class _MonthSummary extends StatelessWidget {
  final String month;
  const _MonthSummary({required this.month});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: fs.payments.where('month', isEqualTo: month).snapshots(),
      builder: (context, snap) {
        num billed = 0, collected = 0;
        if (snap.hasData) {
          for (final d in snap.data!.docs) {
            final p = Payment.fromMap(d.id, d.data());
            billed += p.totalAmount;
            if (p.isPaid) collected += p.totalAmount;
          }
        }
        final pending = billed - collected;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat(context, 'Billed', billed, Colors.indigo),
              _stat(context, 'Collected', collected, Colors.green),
              _stat(context, 'Pending', pending, Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(BuildContext context, String label, num value, Color color) {
    return Column(
      children: [
        Text('₹$value',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: color, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
