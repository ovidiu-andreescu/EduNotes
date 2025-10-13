import 'package:flutter/material.dart';

Future<String?> showShareDialog(BuildContext context) async {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Share with (recipient UID)'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Recipient UID',
          helperText: 'Temporary: paste the other user\'s Firebase UID',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final v = controller.text.trim();
            Navigator.pop(context, v.isEmpty ? null : v);
          },
          child: const Text('Share'),
        ),
      ],
    ),
  );
}
