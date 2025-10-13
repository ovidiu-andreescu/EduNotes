import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models.dart';
import '../../data/files_repository.dart';

class FilesState extends Equatable {
  final List<EntryBase> myFiles;
  final List<EntryBase> sharedWithMe;
  final bool loading;

  const FilesState({this.myFiles = const [], this.sharedWithMe = const [], this.loading = true});

  FilesState copyWith({List<EntryBase>? myFiles, List<EntryBase>? sharedWithMe, bool? loading}) => FilesState(
    myFiles: myFiles ?? this.myFiles,
    sharedWithMe: sharedWithMe ?? this.sharedWithMe,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [myFiles, sharedWithMe, loading];
}

class FilesCubit extends Cubit<FilesState> {
  final FilesRepository repo;
  StreamSubscription? _sub;
  String? _uid;

  FilesCubit(this.repo) : super(const FilesState());

  Future<void> refresh([String? userId]) async {
    if (userId != null) _uid = userId;
    repo.setActiveUser(_uid);

    _sub?.cancel();
    if (_uid == null) {
      emit(state.copyWith(myFiles: [], sharedWithMe: [], loading: false));
      return;
    }

    _sub = repo.watchAll().listen((_) {
      final my = repo.myFiles(_uid!);
      final shared = repo.sharedWithMe(_uid!);
      emit(FilesState(myFiles: my, sharedWithMe: shared, loading: false));
    });
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
