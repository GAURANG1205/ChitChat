import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel{
  final String uid;
  final String username;
  final String email;
  final String phoneNumber;
  final Timestamp createdAt;
  final List<String> blockedUsers;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.phoneNumber,
    Timestamp? lastSeen,
    Timestamp? createdAt,
    this.blockedUsers = const [],
  })  :createdAt = createdAt ?? Timestamp.now();

  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? phoneNumber,
    Timestamp? lastSeen,
    Timestamp? createdAt,
    List<String>? blockedUsers,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      username: data["username"] ?? "",
      email: data["email"] ?? "",
      phoneNumber: data["phoneNumber"] ?? "",
      lastSeen: data["lastSeen"] ?? Timestamp.now(),
      createdAt: data["createdAt"] ?? Timestamp.now(),
      blockedUsers: List<String>.from(data["blockedUsers"]),
    );
  }
Map<String, dynamic> toMap() {
  return {
    'username': username,
    'email': email,
    'phoneNumber': phoneNumber,
    'createdAt': createdAt,
    'blockedUsers': blockedUsers,
  };
}
}