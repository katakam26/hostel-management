import 'package:flutter/material.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/placeholder_page.dart';

/// Staff app shell. Modules map to the STAFF FEATURES in the spec.
class StaffShell extends StatelessWidget {
  const StaffShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShellScaffold(
      title: 'Staff',
      items: [
        NavItem(
          label: 'Shifts',
          icon: Icons.schedule_outlined,
          page: PlaceholderPage(
              title: 'Shifts & Assigned Tasks',
              icon: Icons.schedule_outlined),
        ),
        NavItem(
          label: 'Attendance',
          icon: Icons.how_to_reg_outlined,
          page: PlaceholderPage(
              title: 'Attendance Check-in/out',
              icon: Icons.how_to_reg_outlined),
        ),
        NavItem(
          label: 'Complaints',
          icon: Icons.build_outlined,
          page: PlaceholderPage(
              title: 'Assigned Complaints', icon: Icons.build_outlined),
        ),
        NavItem(
          label: 'Salary',
          icon: Icons.account_balance_wallet_outlined,
          page: PlaceholderPage(
              title: 'Salary & Payment Info',
              icon: Icons.account_balance_wallet_outlined),
        ),
        NavItem(
          label: 'Notices',
          icon: Icons.campaign_outlined,
          page: PlaceholderPage(
              title: 'Notices & Instructions',
              icon: Icons.campaign_outlined),
        ),
      ],
    );
  }
}
