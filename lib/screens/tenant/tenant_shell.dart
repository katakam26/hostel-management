import 'package:flutter/material.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/placeholder_page.dart';

/// Tenant self-service app shell. Modules map to the TENANT FEATURES in the spec.
class TenantShell extends StatelessWidget {
  const TenantShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShellScaffold(
      title: 'Tenant',
      items: [
        NavItem(
          label: 'Home',
          icon: Icons.home_outlined,
          page: PlaceholderPage(
              title: 'Dashboard (room, bed, payment status)',
              icon: Icons.home_outlined),
        ),
        NavItem(
          label: 'Payments',
          icon: Icons.payments_outlined,
          page: PlaceholderPage(
              title: 'Pay Rent & History', icon: Icons.payments_outlined),
        ),
        NavItem(
          label: 'Food',
          icon: Icons.restaurant_outlined,
          page: PlaceholderPage(
              title: 'Food Menu & Feedback', icon: Icons.restaurant_outlined),
        ),
        NavItem(
          label: 'Amenities',
          icon: Icons.local_laundry_service_outlined,
          page: PlaceholderPage(
              title: 'Amenities & Washing-Machine Booking',
              icon: Icons.local_laundry_service_outlined),
        ),
        NavItem(
          label: 'Complaints',
          icon: Icons.report_problem_outlined,
          page: PlaceholderPage(
              title: 'Raise & Track Complaints',
              icon: Icons.report_problem_outlined),
        ),
        NavItem(
          label: 'Profile',
          icon: Icons.person_outline,
          page: PlaceholderPage(
              title: 'Profile, Documents & Move-out',
              icon: Icons.person_outline),
        ),
      ],
    );
  }
}
