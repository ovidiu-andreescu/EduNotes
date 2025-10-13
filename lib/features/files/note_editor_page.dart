import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/files_repository.dart';
import '../../data/models.dart';
import '../auth/auth_cubit.dart';

class NoteEditorPage extends StatefulWidget {
  final String noteId;
  const NoteEditorPage({super.key, required this.noteId});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final _controller = TextEditingController();
  bool editing = false;
  String? error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FilesRepository>();
    final user = context.read<AuthCubit>().currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        actions: [
          if (!editing)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final note = _maybeGetNote(repo);
                if (note == null) return; // not loaded yet
                if (note.lockedByUserId != null && note.lockedByUserId != user.id) {
                  setState(() => error = 'Note is locked by another user.');
                  return;
                }
                final ok = await repo.acquireLock(noteId: widget.noteId, userId: user.id);
                if (ok) {
                  setState(() {
                    error = null;
                    editing = true;
                    _controller.text = note.content; // seed editor with latest
                  });
                } else {
                  setState(() => error = 'Note is locked by another user.');
                }
              },
            ),
          if (editing)
            IconButton(
              tooltip: 'Save',
              icon: const Icon(Icons.save),
              onPressed: () async {
                try {
                  await repo.updateNoteContent(
                    noteId: widget.noteId,
                    newContent: _controller.text,
                    editorUserId: user.id,
                  );
                  await repo.releaseLock(noteId: widget.noteId, userId: user.id);
                  setState(() {
                    editing = false;
                    error = null;
                  });
                } catch (e) {
                  setState(() => error = e.toString());
                }
              },
            ),
          if (editing)
            IconButton(
              tooltip: 'Cancel',
              icon: const Icon(Icons.close),
              onPressed: () async {
                await repo.releaseLock(noteId: widget.noteId, userId: user.id);
                setState(() {
                  editing = false;
                  error = null;
                });
              },
            ),
        ],
      ),
      body: StreamBuilder<void>(
        // Rebuild view when files change (Firestore snapshots or mock)
        stream: context.read<FilesRepository>().watchAll(),
        builder: (context, _) {
          final note = _maybeGetNote(repo);
          if (note == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final lockedByOther =
              note.lockedByUserId != null && note.lockedByUserId != user.id;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error != null) _Banner(error!, color: Colors.red),
                if (lockedByOther) const _Banner('Read-only. Locked by another user.'),
                const SizedBox(height: 8),
                Expanded(
                  child: editing
                      ? TextField(
                    controller: _controller,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Write notes...',
                    ),
                  )
                      : SingleChildScrollView(
                    child: Text(
                      note.content.isEmpty ? '(empty)' : note.content,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  TextNote? _maybeGetNote(FilesRepository repo) {
    try {
      final e = repo.getById(widget.noteId);
      return (e is TextNote) ? e : null;
    } catch (_) {
      // Not in cache yet (e.g., just created; waiting for Firestore snapshot)
      return null;
    }
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final Color? color;
  const _Banner(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: (color ?? Colors.amber).withOpacity(.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color ?? Colors.amber),
      ),
      child: Text(text),
    );
  }
}
