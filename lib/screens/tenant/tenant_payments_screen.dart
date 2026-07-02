import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/payment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/dates.dart';

/// Tenant's rent history. Unpaid bills can be paid here (marked paid — this is
/// a demo flow; wire a real gateway like Razorpay/Stripe in place of _pay).
class TenantPaymentsScreen extends StatelessWidget {
  const TenantPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final tenantId = context.read<AuthService>().currentUser?.linkedId;
    if (tenantId == null) {
      return const Center(child: Text('Your tenant profile is not linked yet.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: fs.payments.where('tenantId', isEqualTo: tenantId).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final payments = snap.data!.docs
            .map((d) => Payment.fromMap(d.id, d.data()))
            .toList()
          ..sort((a, b) => b.month.compareTo(a.month));
        if (payments.isEmpty) {
          return const Center(
              child: Text('No bills yet. The owner will generate rent bills.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(4),
          itemCount: payments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final p = payments[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(Dates.prettyMonth(p.month),
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('₹${p.totalAmount}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rent ₹${p.baseRent}'
                      '${p.electricityBill > 0 ? " · Electricity ₹${p.electricityBill}" : ""}'
                      '${p.extraAmenityCharge > 0 ? " · Extra ₹${p.extraAmenityCharge}" : ""}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: Text(p.status),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: p.isPaid
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                        ),
                        if (!p.isPaid)
                          FilledButton.icon(
                            onPressed: () => _pay(context, fs, p),
                            icon: const Icon(Icons.payment, size: 18),
                            label: const Text('Pay now'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pay(
      BuildContext context, FirestoreService fs, Payment p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm payment'),
        content: Text(
            'Pay ₹${p.totalAmount} for ${Dates.prettyMonth(p.month)}?\n\n'
            '(Demo: this marks the bill paid. Connect a real payment gateway '
            'to charge a card.)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Pay'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await fs.payments.doc(p.id).update({
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
      'method': 'online',
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Payment successful.')));
    }
  }
}
