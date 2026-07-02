import 'package:flutter/material.dart';

import '../../widgets/app_scaffold.dart';
import '../../widgets/notices_feed.dart';
import 'staff_attendance_screen.dart';
import 'staff_complaints_screen.dart';
import 'staff_salary_screen.dart';
import 'staff_shifts_screen.dart';

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
          page: StaffShiftsScreen(),
        ),
        NavItem(
          label: 'Attendance',
          icon: Icons.how_to_reg_outlined,
          page: StaffAttendanceScreen(),
        ),
        NavItem(
          label: 'Complaints',
          icon: Icons.build_outlined,
          page: StaffComplaintsScreen(),
        ),
        NavItem(
          label: 'Salary',
          icon: Icons.account_balance_wallet_outlined,
          page: StaffSalaryScreen(),
        ),
        NavItem(
          label: 'Notices',
          icon: Icons.campaign_outlined,
          page: NoticesFeed(audience: 'staff'),
        ),
      ],
    );
  }
}
