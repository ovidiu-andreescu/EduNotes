import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'models.dart';
import 'files_repository.dart';

class FirebaseFilesRepository implements FilesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final Map<String, EntryBase> _cache = {};
  final _changes = StreamController<void>.broadcast();

  StreamSubscription? _ownSub, _sharedSub;
  String? _uid;

  CollectionReference<Map<String, dynamic>> get _entries => _db.collection('entries');

  @override
  void setActiveUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;

    _ownSub?.cancel();
    _sharedSub?.cancel();
    _cache.clear();

    if (uid == null) {
      _changes.add(null);
      return;
    }

    _ownSub = _entries.where('ownerId', isEqualTo: uid).snapshots().listen(_applySnap);
    _sharedSub = _entries.where('sharedWith', arrayContains: uid).snapshots().listen(_applySnap);
  }

  void _applySnap(QuerySnapshot<Map<String, dynamic>> snap) {
    for (final c in snap.docChanges) {
      final id = c.doc.id;
      if (c.type == DocumentChangeType.removed) {
        _cache.remove(id);
        continue;
      }
      final data = c.doc.data();
      if (data == null) continue;

      final type = data['type'] as String? ?? 'note';
      final ownerId = data['ownerId'] as String;
      final title = data['title'] as String? ?? '';
      final sharedWith = List<String>.from(data['sharedWith'] ?? const []);
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      if (type == 'image') {
        _cache[id] = ImageItem(
          id: id,
          ownerId: ownerId,
          title: title,
          sharedWith: sharedWith,
          createdAt: createdAt,
          updatedAt: updatedAt,
          imagePathOrUrl: data['imageUrl'] as String? ?? '',
        );
      } else {
        _cache[id] = TextNote(
          id: id,
          ownerId: ownerId,
          title: title,
          sharedWith: sharedWith,
          createdAt: createdAt,
          updatedAt: updatedAt,
          content: data['content'] as String? ?? '',
          lockedByUserId: data['lockedByUserId'] as String?,
        );
      }
    }
    _changes.add(null);
  }

  @override
  Stream<void> watchAll() => _changes.stream;

  @override
  List<EntryBase> myFiles(String uid) =>
      _cache.values.where((e) => e.ownerId == uid).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  List<EntryBase> sharedWithMe(String uid) =>
      _cache.values.where((e) => e.sharedWith.contains(uid) && e.ownerId != uid).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  EntryBase getById(String id) => _cache[id]!;

  @override
  Future<TextNote> createNote({required String ownerId, required String title}) async {
    final ref = _entries.doc();
    final now = FieldValue.serverTimestamp();
    await ref.set({
      'type': 'note',
      'ownerId': ownerId,
      'title': title,
      'sharedWith': <String>[],
      'content': '',
      'lockedByUserId': null,
      'createdAt': now,
      'updatedAt': now,
    });
    return TextNote(
      id: ref.id,
      ownerId: ownerId,
      title: title,
      sharedWith: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      content: '',
    );
  }

  @override
  Future<ImageItem> createImage({
    required String ownerId,
    required String title,
    required String imagePathOrUrl,
  }) async {
    final file = File(imagePathOrUrl);
    final id = _entries.doc().id;
    final upload = await _storage.ref('noteImages/$id/${file.uri.pathSegments.last}').putFile(file);
    final url = await upload.ref.getDownloadURL();
    final now = FieldValue.serverTimestamp();
    await _entries.doc(id).set({
      'type': 'image',
      'ownerId': ownerId,
      'title': title,
      'sharedWith': <String>[],
      'imageUrl': url,
      'createdAt': now,
      'updatedAt': now,
    });
    return ImageItem(
      id: id,
      ownerId: ownerId,
      title: title,
      sharedWith: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      imagePathOrUrl: url,
    );
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _entries.doc(id).delete();
  }

  @override
  Future<void> updateNoteContent({
    required String noteId,
    required String newContent,
    required String editorUserId,
  }) async {
    await _entries.doc(noteId).update({
      'content': newContent,
      'lockedByUserId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<bool> acquireLock({required String noteId, required String userId}) async {
    return _db.runTransaction((tx) async {
      final ref = _entries.doc(noteId);
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final cur = snap.data()!;
      final lockedBy = cur['lockedByUserId'] as String?;
      if (lockedBy == null || lockedBy == userId) {
        tx.update(ref, {'lockedByUserId': userId, 'updatedAt': FieldValue.serverTimestamp()});
        return true;
      }
      return false;
    });
  }

  @override
  Future<void> releaseLock({required String noteId, required String userId}) async {
    await _entries.doc(noteId).update({
      'lockedByUserId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> shareWithUser({required String entryId, required String otherUserId}) async {
    await _entries.doc(entryId).update({
      'sharedWith': FieldValue.arrayUnion([otherUserId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unshareWithUser({required String entryId, required String otherUserId}) async {
    await _entries.doc(entryId).update({
      'sharedWith': FieldValue.arrayRemove([otherUserId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
