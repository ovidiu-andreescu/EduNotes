import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/auth_cubit.dart';
import 'features/auth/login_page.dart';
import 'features/files/my_files_page.dart';
import 'features/files/shared_with_me_page.dart';
import 'features/files/files_cubit.dart';

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

  @override
  Widget build(BuildContext context) {
    final pages = const [MyFilesPage(), SharedWithMePage()];
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduNotes'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => context.read<AuthCubit>().signOut(),
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