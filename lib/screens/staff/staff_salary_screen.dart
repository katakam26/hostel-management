import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/staff.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// Staff salary info: amount and this month's payment status (read-only; the
/// owner marks salary paid from the owner app).
class StaffSalaryScreen extends StatelessWidget {
  const StaffSalaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final staffId = context.read<AuthService>().currentUser?.linkedId;
    if (staffId == null) {
      return const Center(child: Text('Your staff profile is not linked yet.'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: fs.staff.doc(staffId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.data!.exists) {
          return const Center(child: Text('Staff profile not found.'));
        }
        final s = Staff.fromMap(snap.data!.id, snap.data!.data()!);
        final paid = s.salaryStatus == 'paid';
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_wallet,
                          size: 48, color: Colors.indigo),
                      const SizedBox(height: 12),
                      Text('₹${s.salaryAmount}',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const Text('per month'),
                      const SizedBox(height: 16),
                      Chip(
                        avatar: Icon(
                          paid ? Icons.check_circle : Icons.pending,
                          color: paid ? Colors.green : Colors.orange,
                        ),
                        label: Text(paid
                            ? 'Paid this month'
                            : 'Payment pending'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Role: ${s.role}',
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        );
      },
    );
  }
}
