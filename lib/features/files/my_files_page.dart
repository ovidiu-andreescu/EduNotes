import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/files_repository.dart';
import '../../data/models.dart';
import '../auth/auth_cubit.dart';
import 'files_cubit.dart';
import 'note_editor_page.dart';
import 'image_view_page.dart';
import 'widgets/file_card.dart';
import 'widgets/share_dialog.dart';

class MyFilesPage extends StatelessWidget {
  const MyFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final filesRepo = context.read<FilesRepository>();
    final user = context.read<AuthCubit>().currentUser!;

    return Scaffold(
      body: BlocBuilder<FilesCubit, FilesState>(
        builder: (context, state) {
          if (state.loading) return const Center(child: CircularProgressIndicator());
          final files = state.myFiles;
          if (files.isEmpty) {
            return const Center(child: Text('No files yet. Use + to add.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: files.length,
            itemBuilder: (context, i) {
              final e = files[i];
              return FileCard(
                entry: e,
                onOpen: () {
                  if (e is TextNote) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => NoteEditorPage(noteId: e.id),
                    ));
                  } else if (e is ImageItem) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ImageViewPage(imageId: e.id),
                    ));
                  }
                },
                onShare: () async {
                  final otherId = await showShareDialog(context);
                  if (otherId != null) {
                    await filesRepo.shareWithUser(entryId: e.id, otherUserId: otherId);
                  }
                },
                onUnshare: () async {
                  for (final uid in e.sharedWith) {
                    await filesRepo.unshareWithUser(entryId: e.id, otherUserId: uid);
                  }
                },
                onDelete: () async {
                  await filesRepo.deleteEntry(e.id);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: _AddFab(filesRepo: filesRepo),
    );
  }
}

class _AddFab extends StatelessWidget {
  final FilesRepository filesRepo;
  const _AddFab({required this.filesRepo});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser!;
    return FloatingActionButton.extended(
      onPressed: () async {
        final choice = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('New note'),
                onTap: () => Navigator.pop(context, 'note'),
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Add image from gallery'),
                onTap: () => Navigator.pop(context, 'image'),
              ),
            ]),
          ),
        );
        if (choice == 'note') {
          final note = await filesRepo.createNote(ownerId: user.id, title: 'Untitled note');
          await filesRepo.acquireLock(noteId: note.id, userId: user.id);
          if (context.mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorPage(noteId: note.id)));
          }
        } else if (choice == 'image') {
          final picker = ImagePicker();
          final img = await picker.pickImage(source: ImageSource.gallery);
          if (img != null) {
            await filesRepo.createImage(
              ownerId: user.id,
              title: 'Image ${DateTime.now().toIso8601String()}',
              imagePathOrUrl: img.path,
            );
          }
        }
      },
      label: const Text('Add'),
      icon: const Icon(Icons.add),
    );
  }
}
