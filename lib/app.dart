import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/auth_cubit.dart';
import 'features/auth/login_page.dart';
import 'features/files/my_files_page.dart';
import 'features/files/shared_with_me_page.dart';
import 'features/files/files_cubit.dart';
import 'dart:io';

class EduNotesApp extends StatelessWidget {
  const EduNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        final files = context.read<FilesCubit>();
        if (state is Authenticated) {
          files.refresh(state.user.id, state.user.email);
        } else {
          files.refresh(null, null);
        }
      },
      child: MaterialApp(
        title: 'EduNotes (Mock)',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) return const _HomeShell();
            return const LoginPage();
          },
        ),
      ),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int idx = 0;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<FilesCubit>().refresh(authState.user.id, authState.user.email);
    }
  }

  Future<void> _confirmLogout() async {
    bool isOffline = false;
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        isOffline = true;
      }
    } on SocketException catch (_) {
      isOffline = true;
    }

    if (!mounted) return;

    if (isOffline) {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Offline Warning'),
          content: const Text(
              'You are currently offline.\n\n'
                  'Any changes you made recently have not been saved to the cloud yet.\n\n'
                  'If you log out now, you will lose the changes.\n\n'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log Out Anyway'),
            ),
          ],
        ),
      );

      if (shouldLogout != true) return;
    }

    if (mounted) context.read<AuthCubit>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [MyFilesPage(), SharedWithMePage()];
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduNotes'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.folder), label: 'My files'),
          NavigationDestination(icon: Icon(Icons.folder_shared), label: 'Shared'),
        ],
      ),
    );
  }
}