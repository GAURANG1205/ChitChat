import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel{
  final String uid;
  final String username;
  final String email;
  final String phoneNumber;
  final bool isOnline;
  final Timestamp lastSeen;
  final Timestamp createdAt;
  final String? fcmToken;
  final List<String> blockedUsers;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.phoneNumber,
    this.isOnline = false,
    Timestamp? lastSeen,
    Timestamp? createdAt,
    this.fcmToken,
    this.blockedUsers = const [],
  })  : lastSeen = lastSeen ?? Timestamp.now(),
        createdAt = createdAt ?? Timestamp.now();

  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? phoneNumber,
    bool? isOnline,
    Timestamp? lastSeen,
    Timestamp? createdAt,
    String? fcmToken,
    List<String>? blockedUsers,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
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
      fcmToken: data["fcmToken"],
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
    'isOnline': isOnline,
    'lastSeen': lastSeen,
    'createdAt': createdAt,
    'blockedUsers': blockedUsers,
    'fcmToken': fcmToken,
  };
}
}