import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models.dart';
import 'files_cubit.dart';
import 'image_view_page.dart';
import 'note_editor_page.dart';
import 'widgets/file_card.dart';

class SharedWithMePage extends StatelessWidget {
  const SharedWithMePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilesCubit, FilesState>(
      builder: (context, state) {
        if (state.loading) return const Center(child: CircularProgressIndicator());
        final files = state.sharedWithMe;
        if (files.isEmpty) return const Center(child: Text('Nothing shared with you yet.'));
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: files.length,
          itemBuilder: (context, i) {
            final e = files[i];
            return FileCard(
              entry: e,
              onOpen: () {
                if (e is TextNote) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorPage(noteId: e.id)));
                } else if (e is ImageItem) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewPage(imageId: e.id)));
                }
              },
              onShare: null,
              onUnshare: null,
              onDelete: null,
            );
          },
        );
      },
    );
  }
}
