import 'dart:developer';

import 'package:chitchat/Data/Repository/template/RepoTemplate.dart';
import 'package:chitchat/Data/Repository/template/service_locator.dart';
import 'package:chitchat/router/app_router.dart';
import 'package:chitchat/screen/PhoneNumberScreen.dart';
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
      final userCredential = await auth.createUserWithEmailAndPassword(
          email: email, password: password);
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
          phoneNumber.replaceAll(RegExp(r'\s+'), "").trim();
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
      if (googleUser == null) throw 'Google Sign-In canceled by user';

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw 'Failed to sign in with Google';

      UserModel? userModel = await getUserData(user.uid);
      if (userModel == null) {
        userModel = UserModel(
          uid: user.uid,
          username: user.displayName ?? "New User",
          email: user.email ?? "Unknown",
          phoneNumber: "",
        );
        await saveUserData(userModel);
      }

      if (userModel.phoneNumber.isEmpty) {
        log("Phone number missing. Navigating to phoneNumberScreen...");
        final String? newPhoneNumber = await getit<AppRouter>().push<String>(
          phoneNumberScreen(userModel: userModel),
        );

        if (newPhoneNumber == null || newPhoneNumber.isEmpty) {
          throw 'Phone number is required!';
        }

        userModel = userModel.copyWith(phoneNumber: newPhoneNumber.trim());
        await saveUserData(userModel);
      }

      return userModel;
    } catch (e) {
      log('Google Sign-In Error: ${e.toString()}');
      rethrow;
    }
  }
  Future<void> saveUserData(UserModel user) async {
    try {
      await firestore.collection("users").doc(user.uid).set(user.toMap());
      log('User data saved successfully for UID: ${user.uid}');
    } catch (e) {
      log('Error saving user data for UID: ${user.uid} - ${e.toString()}');
      throw FirebaseAuthException(
          code: 'save-user-data-failed', message: 'Failed to save user data');
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await firestore.collection("users").doc(uid).get();
      if (!doc.exists) {
        log("User document not found for UID: $uid");
        return null;
      }
      final data = doc.data();
      if (data == null) {
        return null;
      }
      return UserModel.fromFirestore(doc);
    } catch (e) {
      log('Error fetching user data: ${e.toString()}');
      return null;
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
        throw FirebaseAuthException(
            code: 'user-not-found', message: 'User not found');
      }

      log('User UID: ${userCredential.user!.uid}');

      final userData = await getUserData(userCredential.user!.uid);
      return userData;
    } catch (e) {
      log('Signin Error: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> updatePhoneNumber(String uid, String phoneNumber) async {
    try {
      await firestore
          .collection("users")
          .doc(uid)
          .update({"phoneNumber": phoneNumber});
    } catch (e) {
      throw FirebaseAuthException(
          code: 'update-phone-failed',
          message: 'Failed to update phone number');
    }
  }

  Future<void> signout() async {
    await auth.signOut();
    await _googleSignIn.signOut();
  }
}
