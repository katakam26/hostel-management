import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/app_role.dart';
import '../../../models/staff.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../utils/id_gen.dart';
import '../widgets/credentials_dialog.dart';

/// Add-staff flow: collect details, then provision an employee login the same
/// way as tenants (AuthService.issueAccount on a secondary app).
class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _salary = TextEditingController();
  String _role = 'cleaner';
  bool _saving = false;

  static const _roles = ['cleaner', 'warden', 'security'];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _salary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add staff')),
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
              decoration: const InputDecoration(labelText: 'Email (optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: _roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _role = v ?? 'cleaner'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _salary,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Monthly salary (₹)', prefixText: '₹ '),
              validator: (v) =>
                  num.tryParse(v ?? '') == null ? 'Enter a number' : null,
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
              label: Text(_saving ? 'Creating…' : 'Create staff & issue login'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final fs = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final uniqueId = IdGen.staffId();
      final password = IdGen.tempPassword();
      final staffRef = fs.staff.doc();

      await auth.issueAccount(
        uniqueId: uniqueId,
        password: password,
        role: AppRole.staff,
        name: _name.text.trim(),
        linkedId: staffRef.id,
      );

      final staff = Staff(
        id: staffRef.id,
        uniqueId: uniqueId,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        role: _role,
        salaryAmount: num.parse(_salary.text),
      );
      await staffRef.set(staff.toMap());

      if (!mounted) return;
      await showCredentialsDialog(
        context,
        title: 'Staff created',
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
