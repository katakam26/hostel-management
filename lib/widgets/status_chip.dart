import 'package:flutter/material.dart';

/// A small coloured chip for a complaint/request status. Keeps the same colour
/// mapping everywhere the status is shown (owner, tenant, staff).
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    return Chip(
      label: Text(status.replaceAll('_', ' ')),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }

  Color _colorFor(String status) {
    switch (status) {
      case 'resolved':
      case 'paid':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'assigned':
        return Colors.deepPurple;
      case 'open':
      case 'unpaid':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
