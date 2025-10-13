import 'package:equatable/equatable.dart';

enum EntryType { note, image }

class UserModel extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String password;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.password,
  });

  @override
  List<Object?> get props => [id, email, displayName];
}

abstract class EntryBase extends Equatable {
  final String id;
  final EntryType type;
  final String ownerId;
  final String title;
  final List<String> sharedWith;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EntryBase({
    required this.id,
    required this.type,
    required this.ownerId,
    required this.title,
    required this.sharedWith,
    required this.createdAt,
    required this.updatedAt,
  });

  EntryBase copyBase({
    String? title,
    List<String>? sharedWith,
    DateTime? updatedAt,
  });

  @override
  List<Object?> get props => [id, type, ownerId, title, sharedWith, createdAt, updatedAt];
}

class TextNote extends EntryBase {
  final String content;
  final String? lockedByUserId;

  const TextNote({
    required super.id,
    required super.ownerId,
    required super.title,
    required super.sharedWith,
    required super.createdAt,
    required super.updatedAt,
    required this.content,
    this.lockedByUserId,
  }) : super(type: EntryType.note);

  TextNote copyWith({
    String? title,
    String? content,
    List<String>? sharedWith,
    DateTime? updatedAt,
    String? lockedByUserId, // use explicit value to set/unset
  }) {
    return TextNote(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      sharedWith: sharedWith ?? this.sharedWith,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      content: content ?? this.content,
      lockedByUserId: lockedByUserId,
    );
  }

  @override
  EntryBase copyBase({String? title, List<String>? sharedWith, DateTime? updatedAt}) =>
      copyWith(title: title, sharedWith: sharedWith, updatedAt: updatedAt, lockedByUserId: lockedByUserId);
}

class ImageItem extends EntryBase {
  final String imagePathOrUrl;

  const ImageItem({
    required super.id,
    required super.ownerId,
    required super.title,
    required super.sharedWith,
    required super.createdAt,
    required super.updatedAt,
    required this.imagePathOrUrl,
  }) : super(type: EntryType.image);

  ImageItem copyWith({
    String? title,
    List<String>? sharedWith,
    DateTime? updatedAt,
    String? imagePathOrUrl,
  }) {
    return ImageItem(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      sharedWith: sharedWith ?? this.sharedWith,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imagePathOrUrl: imagePathOrUrl ?? this.imagePathOrUrl,
    );
  }

  @override
  EntryBase copyBase({String? title, List<String>? sharedWith, DateTime? updatedAt}) =>
      copyWith(title: title, sharedWith: sharedWith, updatedAt: updatedAt);
}
