import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;

import '../../data/models.dart';

sealed class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class Unauthenticated extends AuthState {}

class Authenticated extends AuthState {
  final UserModel user;
  Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthCubit extends Cubit<AuthState> {
  final fa.FirebaseAuth _auth = fa.FirebaseAuth.instance;

  AuthCubit() : super(Unauthenticated()) {
    final u = _auth.currentUser;
    if (u != null) {
      emit(Authenticated(_toUserModel(u)));
    }
    _auth.authStateChanges().listen((u) {
      if (u == null) {
        emit(Unauthenticated());
      } else {
        emit(Authenticated(_toUserModel(u)));
      }
    });
  }

  UserModel _toUserModel(fa.User u) => UserModel(
    id: u.uid,
    email: u.email ?? '',
    displayName: u.displayName ?? (u.email?.split('@').first ?? 'user'),
    password: '',
  );

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signInAnonymously() async {
    const offlineUser = UserModel(
      id: 'offline-guest',
      email: 'guest@offline',
      displayName: 'Guest (Local)',
      password: '',
    );
    emit(Authenticated(offlineUser));
  }

  Future<void> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null && (cred.user!.displayName == null || cred.user!.displayName!.isEmpty)) {
      await cred.user!.updateDisplayName(email.split('@').first);
    }
  }

  void signOut() => _auth.signOut();

  UserModel? get currentUser => switch (state) {
    Authenticated s => s.user,
    _ => null,
  };
}