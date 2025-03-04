import 'package:chitchat/Data/Repository/authRepository.dart';
import 'package:chitchat/Logic/cubitAuth.dart';
import 'package:chitchat/router/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

final getit = GetIt.instance;
Future<void> setupServiceLocator() async{
  getit.registerLazySingleton<FirebaseFirestore>(
          () => FirebaseFirestore.instance);
  getit.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getit.registerLazySingleton(()=>AppRouter());
  getit.registerLazySingleton(()=>AuthRepository());
  getit.registerLazySingleton(
        () => cubitAuth(
      authRepository: AuthRepository(),
    ),
  );
}