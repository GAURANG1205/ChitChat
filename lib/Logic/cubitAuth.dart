import 'dart:async';
import 'dart:developer';

import 'package:chitchat/Logic/AuthState.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Data/Repository/authRepository.dart';

class cubitAuth extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  cubitAuth({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    _init();
  }

  void _init() {
    emit(state.copyWith(status: AuthStatus.initial));

    _authStateSubscription = _authRepository.authStateChanges.listen((user) async {
      if (user != null) {
        try {
          final userData = await _authRepository.getUserData(user.uid);

          if (userData != null) {
            if (userData.phoneNumber == "Unknown" || userData.phoneNumber.isEmpty) {
              emit(state.copyWith(
                status: AuthStatus.needPhoneNumber,
                user: userData,
              ));
            } else {
              emit(state.copyWith(
                status: AuthStatus.authenticated,
                user: userData,
              ));
            }
          } else {
            emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
          }
        } catch (e) {
          emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
        }
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
      }
    });
  }
  Future<void> signIn({required String email, required String password}) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      final user = await _authRepository.signin(email: email, password: password);
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
    }
  }

  Future<void> googleSignIn() async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      final user = await _authRepository.googleSignIn();

      if (user.phoneNumber == "Unknown" || user.phoneNumber.isEmpty) {
        emit(state.copyWith(status: AuthStatus.needPhoneNumber, user: user));
      } else {
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
      }
    } catch (e) {
      log('Error during Google Sign-In in Cubit: ${e.toString()}');
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
          username: username, email: email, phoneNumber: phoneNumber, password: password);
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
    }
  }
  Future<void> updatePhoneNumber(String uid, String phoneNumber) async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      await _authRepository.updatePhoneNumber(uid, phoneNumber);
      final updatedUser = await _authRepository.getUserData(uid);
      if (updatedUser != null && (updatedUser.phoneNumber.isNotEmpty && updatedUser.phoneNumber != "Unknown")) {
        emit(state.copyWith(status: AuthStatus.authenticated, user: updatedUser));
      } else {
        emit(state.copyWith(status: AuthStatus.needPhoneNumber, user: updatedUser));
      }
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
    }
  }


  Future<void> signOut() async {
    try {
      await _authRepository.signout();
      emit(state.copyWith(status: AuthStatus.unauthenticated, user: null));
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.error, error: e.toString()));
    }
  }
  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
