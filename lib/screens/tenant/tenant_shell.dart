import 'package:flutter/material.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/notices_feed.dart';
import 'tenant_amenities_screen.dart';
import 'tenant_complaints_screen.dart';
import 'tenant_dashboard_screen.dart';
import 'tenant_food_screen.dart';
import 'tenant_payments_screen.dart';
import 'tenant_profile_screen.dart';

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
          page: TenantDashboardScreen(),
        ),
        NavItem(
          label: 'Payments',
          icon: Icons.payments_outlined,
          page: TenantPaymentsScreen(),
        ),
        NavItem(
          label: 'Food',
          icon: Icons.restaurant_outlined,
          page: TenantFoodScreen(),
        ),
        NavItem(
          label: 'Amenities',
          icon: Icons.local_laundry_service_outlined,
          page: TenantAmenitiesScreen(),
        ),
        NavItem(
          label: 'Complaints',
          icon: Icons.report_problem_outlined,
          page: TenantComplaintsScreen(),
        ),
        NavItem(
          label: 'Notices',
          icon: Icons.campaign_outlined,
          page: NoticesFeed(audience: 'tenants'),
        ),
        NavItem(
          label: 'Profile',
          icon: Icons.person_outline,
          page: TenantProfileScreen(),
        ),
      ],
    );
  }
}
