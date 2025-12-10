import 'models.dart';

abstract class FilesRepository {
  /// Call when auth user changes.
  /// We need the email to listen for files shared with this user.
  void setActiveUser(String? uid, String? email);

  /// Emits whenever the underlying data for the active user changes.
  Stream<void> watchAll();

  List<EntryBase> myFiles(String uid);

  /// Returns files shared with the given [email].
  List<EntryBase> sharedWithMe(String email);

  EntryBase getById(String id);

  Future<TextNote> createNote({required String ownerId, required String title});
  Future<ImageItem> createImage({
    required String ownerId,
    required String title,
    required String imagePathOrUrl,
  });

  Future<void> deleteEntry(String id);

  Future<void> updateNoteContent({
    required String noteId,
    required String newContent,
    required String editorUserId,
  });

  Future<bool> acquireLock({required String noteId, required String userId});
  Future<void> releaseLock({required String noteId, required String userId});

  Future<void> shareWithUser({required String entryId, required String email});
  Future<void> unshareWithUser({required String entryId, required String email});
}