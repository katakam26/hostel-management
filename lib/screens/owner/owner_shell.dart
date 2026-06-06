import 'package:flutter/material.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/placeholder_page.dart';
import 'dashboard/dashboard_screen.dart';
import 'hostel_setup/hostel_setup_screen.dart';
import 'staff/staff_screen.dart';
import 'tenants/tenants_screen.dart';

/// Owner (Admin) app shell. Modules map 1:1 to the OWNER FEATURES in the spec.
/// Phase 1 modules (Dashboard, Hostel, Tenants, Staff) are live; the rest are
/// placeholders until later phases fill them in.
class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShellScaffold(
      title: 'Owner',
      items: [
        NavItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          page: DashboardScreen(),
        ),
        NavItem(
          label: 'Hostel',
          icon: Icons.apartment_outlined,
          page: HostelSetupScreen(),
        ),
        NavItem(
          label: 'Tenants',
          icon: Icons.people_outline,
          page: TenantsScreen(),
        ),
        NavItem(
          label: 'Staff',
          icon: Icons.badge_outlined,
          page: StaffScreen(),
        ),
        NavItem(
          label: 'Payments',
          icon: Icons.payments_outlined,
          page: PlaceholderPage(
              title: 'Rent & Payments', icon: Icons.payments_outlined),
        ),
        NavItem(
          label: 'Complaints',
          icon: Icons.report_problem_outlined,
          page: PlaceholderPage(
              title: 'Complaints Board', icon: Icons.report_problem_outlined),
        ),
        NavItem(
          label: 'Food',
          icon: Icons.restaurant_outlined,
          page: PlaceholderPage(
              title: 'Food & Menu', icon: Icons.restaurant_outlined),
        ),
        NavItem(
          label: 'Notices',
          icon: Icons.campaign_outlined,
          page: PlaceholderPage(
              title: 'Notices & Announcements',
              icon: Icons.campaign_outlined),
        ),
      ],
    );
  }
}
