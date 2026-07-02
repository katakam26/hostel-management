import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/expense.dart';
import '../../../models/payment.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../utils/dates.dart';

/// Owner home. Live headcount/occupancy counts plus this month's finances
/// (revenue from paid bills, expenses, and profit) with an expense editor.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final name = context.read<AuthService>().currentUser?.name ?? 'Owner';
    final month = Dates.thisMonth();

    return ListView(
      children: [
        Text('Welcome, $name',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Here\'s how your hostel looks today.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _CountCard(
              label: 'Active tenants',
              icon: Icons.people,
              color: Colors.indigo,
              query: fs.tenants.where('status', isEqualTo: 'active'),
            ),
            _CountCard(
              label: 'Total rooms',
              icon: Icons.meeting_room,
              color: Colors.teal,
              query: fs.rooms,
            ),
            _CountCard(
              label: 'Vacant rooms',
              icon: Icons.event_available,
              color: Colors.green,
              query: fs.rooms.where('status', isEqualTo: 'vacant'),
            ),
            _CountCard(
              label: 'Free beds',
              icon: Icons.single_bed,
              color: Colors.orange,
              query: fs.beds.where('occupiedByTenantId', isNull: true),
            ),
            _CountCard(
              label: 'Staff',
              icon: Icons.badge,
              color: Colors.blueGrey,
              query: fs.staff,
            ),
            _CountCard(
              label: 'Open complaints',
              icon: Icons.report_problem,
              color: Colors.redAccent,
              query: fs.complaints.where('status', isEqualTo: 'open'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _MoveOutRequests(),
        Text('This month · ${Dates.prettyMonth(month)}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _FinanceCard(month: month),
        const SizedBox(height: 12),
        _ExpensesSection(month: month),
      ],
    );
  }
}

/// Pending tenant move-out requests, with a one-tap check-out that frees the
/// bed and resolves the request. Hidden entirely when there are none.
class _MoveOutRequests extends StatelessWidget {
  const _MoveOutRequests();

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: fs.requests.where('status', isEqualTo: 'open').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final requests = snap.data!.docs
            .where((d) => d.data()['kind'] == 'move_out')
            .toList();
        if (requests.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Move-out requests',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...requests.map((d) {
              final r = d.data();
              return Card(
                color: Colors.orange.withValues(alpha: 0.10),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.orange),
                  title: Text(r['fromName'] as String? ?? 'Tenant'),
                  subtitle: Text(r['details'] as String? ?? ''),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: () => fs.requests
                            .doc(d.id)
                            .update({'status': 'resolved'}),
                        child: const Text('Dismiss'),
                      ),
                      FilledButton(
                        onPressed: () => _checkOut(
                            fs, d.id, r['fromId'] as String? ?? ''),
                        child: const Text('Check out'),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Future<void> _checkOut(
      FirestoreService fs, String requestId, String tenantId) async {
    if (tenantId.isEmpty) return;
    final tSnap = await fs.tenants.doc(tenantId).get();
    final batch = fs.tenants.firestore.batch();
    batch.update(fs.requests.doc(requestId), {'status': 'resolved'});
    if (tSnap.exists) {
      final data = tSnap.data()!;
      batch.update(fs.tenants.doc(tenantId), {
        'status': 'moved_out',
        'checkOutDate': FieldValue.serverTimestamp(),
      });
      final bedId = data['bedId'] as String?;
      final roomId = data['roomId'] as String?;
      if (bedId != null) {
        batch.update(fs.beds.doc(bedId), {'occupiedByTenantId': null});
      }
      if (roomId != null) {
        batch.update(fs.rooms.doc(roomId), {'status': 'vacant'});
      }
    }
    await batch.commit();
  }
}

/// Revenue (paid bills) − expenses = profit, for [month].
class _FinanceCard extends StatelessWidget {
  final String month;
  const _FinanceCard({required this.month});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: fs.payments.where('month', isEqualTo: month).snapshots(),
      builder: (context, paySnap) {
        num revenue = 0;
        if (paySnap.hasData) {
          for (final d in paySnap.data!.docs) {
            final p = Payment.fromMap(d.id, d.data());
            if (p.isPaid) revenue += p.totalAmount;
          }
        }
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: fs.expenses.where('month', isEqualTo: month).snapshots(),
          builder: (context, expSnap) {
            num expenses = 0;
            if (expSnap.hasData) {
              for (final d in expSnap.data!.docs) {
                expenses += (d.data()['amount'] as num?) ?? 0;
              }
            }
            final profit = revenue - expenses;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metric(context, 'Revenue', revenue, Colors.green),
                    _metric(context, 'Expenses', expenses, Colors.redAccent),
                    _metric(context, 'Profit', profit,
                        profit >= 0 ? Colors.indigo : Colors.red),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _metric(BuildContext context, String label, num value, Color color) {
    return Column(
      children: [
        Text('₹$value',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: color, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// List + add-form for this month's expenses.
class _ExpensesSection extends StatelessWidget {
  final String month;
  const _ExpensesSection({required this.month});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Expenses',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () => _addExpense(context, fs),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: fs.expenses.where('month', isEqualTo: month).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const LinearProgressIndicator();
                final expenses = snap.data!.docs
                    .map((d) => Expense.fromMap(d.id, d.data()))
                    .toList();
                if (expenses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No expenses recorded this month.'),
                  );
                }
                return Column(
                  children: expenses.map((e) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(e.type == 'recurring'
                          ? Icons.repeat
                          : Icons.bolt),
                      title: Text(e.category),
                      subtitle: e.note.isEmpty ? null : Text(e.note),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₹${e.amount}'),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => fs.expenses.doc(e.id).delete(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addExpense(BuildContext context, FirestoreService fs) async {
    final category = TextEditingController();
    final amount = TextEditingController();
    final note = TextEditingController();
    String type = 'recurring';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: category,
                  decoration: const InputDecoration(
                      labelText: 'Category',
                      hintText: 'e.g. Electricity, Salaries, Repairs'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Amount (₹)', prefixText: '₹ '),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: note,
                  decoration:
                      const InputDecoration(labelText: 'Note (optional)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'recurring', child: Text('Recurring')),
                    DropdownMenuItem(
                        value: 'non_recurring', child: Text('One-off')),
                  ],
                  onChanged: (v) => setLocal(() => type = v ?? 'recurring'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final amt = num.tryParse(amount.text);
    if (category.text.trim().isEmpty || amt == null) return;
    await fs.expenses.add(
      Expense(
        id: '',
        type: type,
        category: category.text.trim(),
        amount: amt,
        month: month,
        note: note.text.trim(),
      ).toMap(),
    );
  }
}

/// A metric tile that live-counts the documents returned by [query].
class _CountCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Query<Map<String, dynamic>> query;

  const _CountCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snap) {
                final count =
                    snap.hasData ? snap.data!.docs.length.toString() : '…';
                return Text(count,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold));
              },
            ),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
