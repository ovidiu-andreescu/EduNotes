import 'models.dart';

abstract class FilesRepository {
  /// Call when auth user changes.
  void setActiveUser(String? uid);

  /// Emits whenever the underlying data for the active user changes.
  Stream<void> watchAll();

  List<EntryBase> myFiles(String uid);
  List<EntryBase> sharedWithMe(String uid);

  EntryBase getById(String id);

  Future<TextNote> createNote({required String ownerId, required String title});
  Future<ImageItem> createImage({
    required String ownerId,
    required String title,
    required String imagePathOrUrl, // local path; repo uploads to Storage
  });

  Future<void> deleteEntry(String id);

  Future<void> updateNoteContent({
    required String noteId,
    required String newContent,
    required String editorUserId,
  });

  Future<bool> acquireLock({required String noteId, required String userId});
  Future<void> releaseLock({required String noteId, required String userId});

  Future<void> shareWithUser({required String entryId, required String otherUserId});
  Future<void> unshareWithUser({required String entryId, required String otherUserId});
}
