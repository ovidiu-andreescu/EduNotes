import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'models.dart';
import 'files_repository.dart';

class FirebaseFilesRepository implements FilesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final Map<String, EntryBase> _cache = {};
  final _changes = StreamController<void>.broadcast();

  StreamSubscription? _ownSub, _sharedSub;
  String? _uid;
  String? _email;
  bool _isOfflineMode = false;
  bool _isMigrating = false;

  CollectionReference<Map<String, dynamic>> get _entries => _db.collection('entries');

  @override
  void setActiveUser(String? uid, String? email) {
    _uid = uid;
    _email = email;
    _isOfflineMode = (uid == 'offline-guest');

    _ownSub?.cancel();
    _sharedSub?.cancel();
    _cache.clear();

    if (uid == null) {
      _changes.add(null);
      return;
    }

    if (_isOfflineMode) {
      _loadLocalOfflineFile();
    } else {
      _migrateOfflineData(uid);

      _ownSub = _entries.where('ownerId', isEqualTo: uid).snapshots().listen(_applySnap);
      if (email != null) {
        _sharedSub = _entries.where('sharedWith', arrayContains: email).snapshots().listen(_applySnap);
      }

      _loadFromCache(uid, email);
    }
  }

  Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/offline_guest_data.json');
  }

  Future<void> _loadLocalOfflineFile() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);

        for (final item in jsonList) {
          final type = item['type'];
          if (type == 'note') {
            final note = TextNote.fromJson(item);
            _cache[note.id] = note;
          } else if (type == 'image') {
            final img = ImageItem.fromJson(item);
            _cache[img.id] = img;
          }
        }
      }
    } catch (e) {
      print('Error loading offline file: $e');
    } finally {
      _changes.add(null);
    }
  }

  Future<void> _saveToLocalOfflineFile() async {
    if (!_isOfflineMode) return;
    try {
      final file = await _localFile;
      final jsonList = _cache.values.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving offline file: $e');
    }
  }

  Future<void> _loadFromCache(String uid, String? email) async {
    try {
      final mySnap = await _entries
          .where('ownerId', isEqualTo: uid)
          .get(const GetOptions(source: Source.cache));

      _processSnapshotData(mySnap);

      if (email != null) {
        final sharedSnap = await _entries
            .where('sharedWith', arrayContains: email)
            .get(const GetOptions(source: Source.cache));
        _processSnapshotData(sharedSnap);
      }
    } catch (e) {
      print('Cache load error: $e');
    } finally {
      _changes.add(null);
    }
  }

  void _processSnapshotData(QuerySnapshot<Map<String, dynamic>> snap) {
    for (final doc in snap.docs) {
      final data = doc.data();
      final id = doc.id;
      final type = data['type'] as String? ?? 'note';

      final ownerId = data['ownerId'] as String;
      final title = data['title'] as String? ?? '';
      final sharedWith = List<String>.from(data['sharedWith'] ?? const []);
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      if (type == 'image') {
        _cache[id] = ImageItem(
          id: id, ownerId: ownerId, title: title, sharedWith: sharedWith,
          createdAt: createdAt, updatedAt: updatedAt,
          imagePathOrUrl: data['imageUrl'] as String? ?? '',
        );
      } else {
        _cache[id] = TextNote(
          id: id, ownerId: ownerId, title: title, sharedWith: sharedWith,
          createdAt: createdAt, updatedAt: updatedAt,
          content: data['content'] as String? ?? '',
          lockedByUserId: data['lockedByUserId'] as String?,
        );
      }
    }
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
          id: id, ownerId: ownerId, title: title, sharedWith: sharedWith,
          createdAt: createdAt, updatedAt: updatedAt,
          imagePathOrUrl: data['imageUrl'] as String? ?? '',
        );
      } else {
        _cache[id] = TextNote(
          id: id, ownerId: ownerId, title: title, sharedWith: sharedWith,
          createdAt: createdAt, updatedAt: updatedAt,
          content: data['content'] as String? ?? '',
          lockedByUserId: data['lockedByUserId'] as String?,
        );
      }
    }
    _changes.add(null);
  }

  Future<void> _migrateOfflineData(String realUserId) async {
    if (_isMigrating) return;

    final file = await _localFile;
    if (!await file.exists()) return;

    _isMigrating = true;

    try {
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);

      for (final item in jsonList) {
        final docRef = _entries.doc();
        final data = Map<String, dynamic>.from(item);
        data['ownerId'] = realUserId;
        data['createdAt'] = FieldValue.serverTimestamp();
        data['updatedAt'] = FieldValue.serverTimestamp();
        await docRef.set(data);
      }
      await file.delete();
    } catch (e) {
      print('Migration failed: $e');
    } finally {
      _isMigrating = false;
    }
  }

  Future<void> _uploadImageInBackground(String id, File file, String ownerId) async {
    if (_isOfflineMode) return;
    try {
      final ref = _storage.ref('noteImages/$id/${path.basename(file.path)}');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await _entries.doc(id).update({
        'imageUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Background upload failed (offline?): $e');
    }
  }

  @override
  Stream<void> watchAll() => _changes.stream;

  @override
  List<EntryBase> myFiles(String uid) => _cache.values.toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  List<EntryBase> sharedWithMe(String email) => _cache.values.where((e) => e.sharedWith.contains(email)).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  EntryBase getById(String id) => _cache[id]!;

  @override
  Future<TextNote> createNote({required String ownerId, required String title}) async {
    if (_isOfflineMode) {
      final note = TextNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ownerId: ownerId, title: title, sharedWith: const [],
        createdAt: DateTime.now(), updatedAt: DateTime.now(), content: '',
      );
      _cache[note.id] = note;
      _changes.add(null);
      await _saveToLocalOfflineFile();
      return note;
    }

    final ref = _entries.doc();
    final now = FieldValue.serverTimestamp();
    await ref.set({
      'type': 'note', 'ownerId': ownerId, 'title': title, 'sharedWith': <String>[],
      'content': '', 'lockedByUserId': null, 'createdAt': now, 'updatedAt': now,
    });
    return TextNote(
      id: ref.id, ownerId: ownerId, title: title, sharedWith: const [],
      createdAt: DateTime.now(), updatedAt: DateTime.now(), content: '',
    );
  }

  @override
  Future<ImageItem> createImage({
    required String ownerId,
    required String title,
    required String imagePathOrUrl,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imagePathOrUrl)}';
    final savedImage = await File(imagePathOrUrl).copy('${appDir.path}/$fileName');

    if (_isOfflineMode) {
      final item = ImageItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ownerId: ownerId, title: title, sharedWith: const [],
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        imagePathOrUrl: savedImage.path,
      );
      _cache[item.id] = item;
      _changes.add(null);
      await _saveToLocalOfflineFile();
      return item;
    }

    final ref = _entries.doc();
    final id = ref.id;
    final now = FieldValue.serverTimestamp();
    await ref.set({
      'type': 'image', 'ownerId': ownerId, 'title': title, 'sharedWith': <String>[],
      'imageUrl': savedImage.path, 'createdAt': now, 'updatedAt': now,
    });

    _uploadImageInBackground(id, savedImage, ownerId);

    return ImageItem(
      id: id, ownerId: ownerId, title: title, sharedWith: const [],
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
      imagePathOrUrl: savedImage.path,
    );
  }

  @override
  Future<void> deleteEntry(String id) async {
    if (_isOfflineMode) {
      _cache.remove(id);
      _changes.add(null);
      await _saveToLocalOfflineFile();
      return;
    }
    await _entries.doc(id).delete();
  }

  @override
  Future<void> updateNoteContent({
    required String noteId,
    required String newContent,
    required String editorUserId,
  }) async {
    if (_isOfflineMode) {
      final old = _cache[noteId];
      if (old is TextNote) {
        _cache[noteId] = old.copyWith(content: newContent, updatedAt: DateTime.now());
        _changes.add(null);
        await _saveToLocalOfflineFile();
      }
      return;
    }
    await _entries.doc(noteId).update({
      'content': newContent,
      'lockedByUserId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<bool> acquireLock({required String noteId, required String userId}) async {
    if (_isOfflineMode) return true;
    try {
      return await _db.runTransaction((tx) async {
        final ref = _entries.doc(noteId);
        final snap = await tx.get(ref);
        if (!snap.exists) return false;
        final cur = snap.data()!;
        final lockedBy = cur['lockedByUserId'] as String?;
        final updatedAt = (cur['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        final isStale = DateTime.now().difference(updatedAt).inMinutes > 10;

        if (lockedBy == null || lockedBy == userId || isStale) {
          tx.update(ref, {'lockedByUserId': userId, 'updatedAt': FieldValue.serverTimestamp()});
          return true;
        }
        return false;
      });
    } catch (e) {
      print('Offline Mode: Bypassing lock check. Error: $e');
      return true;
    }
  }

  @override
  Future<void> releaseLock({required String noteId, required String userId}) async {
    if (_isOfflineMode) return;
    await _entries.doc(noteId).update({
      'lockedByUserId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> shareWithUser({required String entryId, required String email}) async {
    if (_isOfflineMode) throw Exception("Cannot share in Guest Mode");
    await _entries.doc(entryId).update({
      'sharedWith': FieldValue.arrayUnion([email]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unshareWithUser({required String entryId, required String email}) async {
    if (_isOfflineMode) return;
    await _entries.doc(entryId).update({
      'sharedWith': FieldValue.arrayRemove([email]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}