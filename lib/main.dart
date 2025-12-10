import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'firebase_options.dart';

import 'features/auth/auth_cubit.dart';
import 'features/files/files_cubit.dart';

import 'data/files_repository.dart';
import 'data/firebase_files_repo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final FilesRepository filesRepo = FirebaseFilesRepository();

  runApp(
    RepositoryProvider<FilesRepository>.value(
      value: filesRepo,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit()),
          BlocProvider(create: (_) => FilesCubit(filesRepo)),
        ],
        child: const EduNotesApp(),
      ),
    ),
  );
}
