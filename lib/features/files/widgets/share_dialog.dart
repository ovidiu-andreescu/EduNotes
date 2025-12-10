import 'package:flutter/material.dart';

Future<String?> showShareDialog(BuildContext context) async {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Share by Email'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Recipient Email',
          helperText: 'Enter the exact email of the user',
          prefixIcon: Icon(Icons.email),
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
            if (v.isNotEmpty && v.contains('@')) {
              Navigator.pop(context, v);
            }
          },
          child: const Text('Share'),
        ),
      ],
    ),
  );
}