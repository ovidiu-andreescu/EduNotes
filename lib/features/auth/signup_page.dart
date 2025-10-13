import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_cubit.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final pass2C = TextEditingController();
  String? error;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: passC, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 12),
              TextField(controller: pass2C, decoration: const InputDecoration(labelText: 'Retype password'), obscureText: true),
              const SizedBox(height: 16),
              if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: loading
                    ? null
                    : () async {
                  if (passC.text != pass2C.text) {
                    setState(() => error = 'Passwords do not match');
                    return;
                  }
                  setState(() { loading = true; error = null; });
                  try {
                    await context.read<AuthCubit>().signUp(emailC.text, passC.text);
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    setState(() => error = e.toString());
                  } finally {
                    if (mounted) setState(() => loading = false);
                  }
                },
                child: Text(loading ? 'Creating...' : 'Create'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
