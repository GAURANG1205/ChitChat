import 'dart:async';

import 'package:chitchat/Logic/AuthState.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Data/Repository/authRepository.dart';
import '../Data/Repository/template/service_locator.dart';

class cubitAuth extends Cubit<AuthState>{
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  cubitAuth({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const AuthState()) {
    _init();
  }

  void _init() {
    emit(state.copyWith(status: AuthStatus.initial));

    _authStateSubscription =
        _authRepository.authStateChanges.listen((user) async {
          if (user != null) {
            try {
              final userData = await _authRepository.getUserData(user.uid);
              emit(state.copyWith(
                status: AuthStatus.authenticated,
                user: userData,
              ));
            } catch (e) {
              emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
            }
          } else {
            emit(state.copyWith(
              status: AuthStatus.unauthenticated,
              user: null,
            ));
          }
        });
  }
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));

      final user = await _authRepository.signin(
        email: email,
        password: password,
      );

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
    }
  }

  Future<void> signUp({
    required String email,
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));

      final user = await _authRepository.signUp(
          username: username,
          email: email,
          phoneNumber: phoneNumber,
          password: password);

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signout();
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
    }
  }
}

