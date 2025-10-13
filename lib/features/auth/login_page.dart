import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_cubit.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: passC, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 16),
              if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: loading
                    ? null
                    : () async {
                  setState(() { loading = true; error = null; });
                  try {
                    await context.read<AuthCubit>().signIn(emailC.text.trim(), passC.text);
                  } catch (e) {
                    setState(() => error = e.toString());
                  } finally {
                    if (mounted) setState(() => loading = false);
                  }
                },
                child: Text(loading ? 'Signing in...' : 'Sign in'),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
                child: const Text('Create account'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
