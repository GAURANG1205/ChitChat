import 'dart:developer';

import 'package:chitchat/Data/Repository/template/RepoTemplate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../Model/user_model.dart';

class AuthRepository extends RepoTemplate {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  Stream<User?> get authStateChanges => auth.authStateChanges();
  Future<UserModel> signUp({
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final formattedPhoneNumber =
      phoneNumber.replaceAll(RegExp(r'\s+'), "".trim());
      final emailExists = await checkEmailExists(email);
      if (emailExists) {
        throw "An account with the same email already exists";
      }
      final phoneNumberExists = await checkPhoneExists(formattedPhoneNumber);
      if (phoneNumberExists) {
        throw "An account with the same phone already exists";
      }
      if (userCredential.user == null) {
        throw "Failed to create user";
      }
      final user = UserModel(
        uid: userCredential.user!.uid,
        username: username,
        email: email,
        phoneNumber: formattedPhoneNumber,
      );
      await saveUserData(user);
      return user;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
  Future<bool> checkEmailExists(String email) async {
    try {
      final methods = await auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print("Error checking email: $e");
      return false;
    }
  }

  Future<bool> checkPhoneExists(String phoneNumber) async {
    try {
      final formattedPhoneNumber =
      phoneNumber.replaceAll(RegExp(r'\s+'), "".trim());
      final querySnapshot = await firestore
          .collection("users")
          .where("phoneNumber", isEqualTo: formattedPhoneNumber)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking email: $e");
      return false;
    }
  }
  Future<UserModel> googleSignIn() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google Sign-In canceled by user';
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw 'Failed to sign in with Google';
      }
      log("User UID: ${user.uid}");
      UserModel? userModel = await getUserData(user.uid);

      if (userModel == null) {
        log('No user data found. Creating new user...');
        userModel = UserModel(
          uid: user.uid,
          username: user.displayName ?? "New User",
          email: user.email ?? "Unknown",
          phoneNumber: user.phoneNumber ?? "Unknown",
        );

        await saveUserData(userModel);
        log('User data saved to Firestore successfully.');
      } else {
        log('User data already exists.');
      }

      return userModel;
    } catch (e) {
      log('Google Sign-In Error: ${e.toString()}');
      rethrow;  // Rethrow the error for the caller to handle
    }
  }


  Future<void> saveUserData(UserModel user) async {
    try {
      await firestore.collection("users").doc(user.uid).set(user.toMap());
      log('User data saved successfully for UID: ${user.uid}');
    } catch (e) {
      log('Error saving user data for UID: ${user.uid} - ${e.toString()}');
      throw FirebaseAuthException(code: 'save-user-data-failed', message: 'Failed to save user data');
    }
  }
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await firestore.collection("users").doc(uid).get();
      if (!doc.exists) {
        log("User document not found for UID: $uid");
        return null;
      }
      return UserModel.fromFirestore(doc);
    } catch (e) {
      log('Error fetching user data for UID: $uid - ${e.toString()}');
      rethrow;
    }
  }


  Future<UserModel?> signin({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (userCredential.user == null) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'User not found');
      }

      log('User UID: ${userCredential.user!.uid}');

      final userData = await getUserData(userCredential.user!.uid);
      return userData;
    } catch (e) {
      log('Signin Error: ${e.toString()}');
      rethrow;
    }
  }
Future<void> signout() async {
    await auth.signOut();
    await _googleSignIn.signOut();
}
  }