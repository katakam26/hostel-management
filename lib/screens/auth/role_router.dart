import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_role.dart';
import '../../services/auth_service.dart';
import '../owner/owner_shell.dart';
import '../staff/staff_shell.dart';
import '../tenant/tenant_shell.dart';
import 'login_screen.dart';

/// Watches the logged-in user and shows the right app for their role.
/// Not logged in -> Login. Logged in -> owner/tenant/staff shell.
class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    switch (user.role) {
      case AppRole.owner:
        return const OwnerShell();
      case AppRole.tenant:
        return const TenantShell();
      case AppRole.staff:
        return const StaffShell();
    }
  }
}
