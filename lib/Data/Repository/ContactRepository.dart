import 'dart:async';
import 'dart:developer';
import 'package:chitchat/Data/Repository/template/RepoTemplate.dart';
import 'package:chitchat/localDb/ContactLocal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/foundation.dart';

import '../Model/user_model.dart';

class ContactRepository extends RepoTemplate {
  String get currentUserId => auth.currentUser?.uid ?? '';
  final Contactlocal _localDb = Contactlocal();
  StreamSubscription? _firestoreSubscription;

  final StreamController<List<Map<String, dynamic>>> _contactsStreamController =
  StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get contactsStream => _contactsStreamController.stream;
  Future<bool> requestContactsPermission() async {
    return await FlutterContacts.requestPermission();
  }

  String normalizePhoneNumber(String number) {
    String cleanNumber = number.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.startsWith('91') && cleanNumber.length > 10) {
      cleanNumber = cleanNumber.substring(2);
    }
    return cleanNumber;
  }

  void listenForNewRegisteredUsers() {
    _firestoreSubscription=firestore.collection("users").snapshots().listen((snapshot) async {
      await refreshContacts();
    });
  }

  Future<void> refreshContacts() async {
    try {
      final cachedContacts = await _localDb.getCachedContacts();
      final cachedPhoneNumbers = cachedContacts.map((c) => c['phoneNumber'] as String).toSet();
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      final phoneNumbers = _normalizeContacts(contacts);
      if (phoneNumbers.every((contact) => cachedPhoneNumbers.contains(contact['phoneNumber']))) {
        return;
      }
      final usersSnapshot = await firestore.collection("users").get();
      for (var doc in usersSnapshot.docs) {
        log('Firestore user data: ${doc.data()}');
      }
      final registeredUsers = usersSnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      final registeredUsersMap = {
        for (var user in registeredUsers) normalizePhoneNumber(user.phoneNumber): user
      };

      final matchedContacts = <Map<String, dynamic>>[];
      final newlyMatchedContacts = <Map<String, dynamic>>[];

      for (var contact in phoneNumbers) {
        String phoneNumber = contact["phoneNumber"];
        if (registeredUsersMap.containsKey(phoneNumber)) {
          final registeredUser = registeredUsersMap[phoneNumber];
          if (registeredUser!.uid == currentUserId ) {
            continue;
          }
          final contactData = {
            'id': registeredUser.uid,
            'name': registeredUser.username.isNotEmpty?registeredUser.username:contact['name'],
            'phoneNumber': phoneNumber,
          };

          matchedContacts.add(contactData);
          if (!cachedPhoneNumbers.contains(phoneNumber)) {
            newlyMatchedContacts.add(contactData);
          }
        }
      }

      if (matchedContacts.isNotEmpty) {
        await _localDb.saveContacts(matchedContacts);
        _contactsStreamController.add(matchedContacts);
        if (newlyMatchedContacts.isNotEmpty) {
          log('New registered contacts found: ${newlyMatchedContacts.length}');
        }
      }
    } catch (e) {
      log('Error refreshing contacts: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRegisteredContacts() async {
    final cachedContacts = await _localDb.getCachedContacts();
    final filteredContacts = cachedContacts.where((contact) => contact['id'] != currentUserId).toList();
    if (filteredContacts.isNotEmpty) {
      refreshContacts();
      return filteredContacts;
    }

    try {
      await refreshContacts();
      final updatedContacts = await _localDb.getCachedContacts();
      return updatedContacts.where((contact) => contact['id'] != currentUserId).toList();
    } catch (e) {
      log('Error getting registered contacts: $e');
      return [];
    }
  }


  List<Map<String, dynamic>> _normalizeContacts(List<Contact> contacts) {
    Set<String> uniqueNumbers = {};
    List<Map<String, dynamic>> normalizedContacts = [];

    for (var contact in contacts) {
      for (var phone in contact.phones) {
        String normalizedPhone = normalizePhoneNumber(phone.number);
        if (normalizedPhone.isEmpty || uniqueNumbers.contains(normalizedPhone)) {
          continue;
        }
        uniqueNumbers.add(normalizedPhone);
        normalizedContacts.add({
          'name': contact.displayName,
          'phoneNumber': normalizedPhone,
        });
      }
    }
    return normalizedContacts;
  }
  Future<String?> getUserProfileImage(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['profileImage'] as String?;
      }
    } catch (e) {
      print("Error fetching profile image: $e");
    }
    return null;
  }
  void dispose() {
    _contactsStreamController.close();
    _firestoreSubscription?.cancel();
  }
}