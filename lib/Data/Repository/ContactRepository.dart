import 'dart:async';
import 'dart:developer';
import 'package:chitchat/Data/Repository/template/RepoTemplate.dart';
import 'package:chitchat/localDb/ContactLocal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/foundation.dart';

import '../Model/user_model.dart';

class ContactRepository extends RepoTemplate {
  String get currentUserId => auth.currentUser?.uid ?? '';
  final Contactlocal _localDb = Contactlocal();

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
    firestore.collection("users").snapshots().listen((snapshot) async {
      await refreshContacts();
    });
  }

  Future<void> refreshContacts() async {
    try {
      final cachedContacts = await _localDb.getCachedContacts();
      final cachedPhoneNumbers = cachedContacts.map((contact) => contact['phoneNumber'] as String).toSet();

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      final List<Map<String, dynamic>> phoneNumbers =
      await compute(_normalizeContacts, contacts);

      final usersSnapshot = await firestore.collection("users").get();
      final registeredUsers = usersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      final Map<String, UserModel> registeredUsersMap = {
        for (var user in registeredUsers)
          normalizePhoneNumber(user.phoneNumber): user
      };

      final matchedContacts = <Map<String, dynamic>>[];
      final newlyMatchedContacts = <Map<String, dynamic>>[];

      for (var contact in phoneNumbers) {
        String phoneNumber = contact["phoneNumber"];
        if (registeredUsersMap.containsKey(phoneNumber)) {
          final registeredUser = registeredUsersMap[phoneNumber];
          if (registeredUser!.uid == currentUserId) {
            continue;
          }
          final contactData = {
            'id': registeredUser.uid,
            'name': contact['name'],
            'phoneNumber': phoneNumber,
            'photo': contact['photo'],
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

    if (cachedContacts.isNotEmpty) {
      refreshContacts();
      return cachedContacts;
    }
    try {
      await refreshContacts();
      return await _localDb.getCachedContacts();
    } catch (e) {
      log('Error getting registered contacts: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _normalizeContacts(List<Contact> contacts) {
    Set<String> uniqueNumbers = {};

    return contacts
        .where((contact) => contact.phones.isNotEmpty)
        .map((contact) {
      String normalizedPhone = normalizePhoneNumber(contact.phones.first.number);
      if (uniqueNumbers.contains(normalizedPhone)) {
        return null;
      }
      uniqueNumbers.add(normalizedPhone);
      return {
        'name': contact.displayName,
        'phoneNumber': normalizedPhone,
        'photo': contact.photo,
      };
    })
        .where((contact) => contact != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  void dispose() {
    _contactsStreamController.close();
  }
}