import 'dart:async';
import 'dart:developer';
import 'package:chitchat/Data/Repository/template/RepoTemplate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/foundation.dart'; // For compute()

import '../Model/user_model.dart';

class ContactRepository extends RepoTemplate {
  String get currentUserId => auth.currentUser?.uid ?? '';

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

  Future<List<Map<String, dynamic>>> getRegisteredContacts() async {
    try {
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
      for (var contact in phoneNumbers) {
        String phoneNumber = contact["phoneNumber"];
        if (registeredUsersMap.containsKey(phoneNumber) &&
            registeredUsersMap[phoneNumber]!.uid != currentUserId) {
          final registeredUser = registeredUsersMap[phoneNumber];
          matchedContacts.add({
            'id': registeredUser!.uid,
            'name': contact['name'],
            'phoneNumber': phoneNumber,
            'photo': contact['photo'],
          });
        }
      }

      return matchedContacts;
    } catch (e) {
      log("Error getting registered users: $e");
      return [];
    }
  }

  List<Map<String, dynamic>> _normalizeContacts(List<Contact> contacts) {
    return contacts
        .where((contact) => contact.phones.isNotEmpty)
        .map((contact) {
      String normalizedPhone =
          normalizePhoneNumber(contact.phones.first.number);
      return {
        'name': contact.displayName,
        'phoneNumber': normalizedPhone,
        'photo': contact.photo,
      };
    }).toList();
  }
}
