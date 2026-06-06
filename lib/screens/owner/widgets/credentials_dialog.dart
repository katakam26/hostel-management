import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows the owner the freshly issued login ID + temporary password for a new
/// tenant/staff account, with copy buttons. The password is only shown here
/// (it isn't stored in plaintext), so the owner must hand it over now.
Future<void> showCredentialsDialog(
  BuildContext context, {
  required String title,
  required String uniqueId,
  required String password,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share these with the user. The password is shown only once.',
          ),
          const SizedBox(height: 16),
          _CopyRow(label: 'Login ID', value: uniqueId),
          const SizedBox(height: 8),
          _CopyRow(label: 'Password', value: password),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String value;
  const _CopyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
                fontFamily: 'monospace', fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          tooltip: 'Copy',
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label copied')),
            );
          },
        ),
      ],
    );
  }
}
