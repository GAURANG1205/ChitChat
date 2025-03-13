import 'package:chitchat/Data/Model/chatMessage_model.dart';
import 'package:chitchat/Data/Repository/template/RepoTemplate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Model/chat_model.dart';

class ChatRepository extends RepoTemplate {
  CollectionReference get _chatRooms => firestore.collection("chatRooms");

  CollectionReference getChatRoomMessages(String chatRoomId) {
    return _chatRooms.doc(chatRoomId).collection("messages");
  }

  Future<ChatRoomModel> getOrCreateChatRoom(
      String currentUserId, String otherUserId) async {
    if (currentUserId == otherUserId) {
      throw Exception("Cannot create a chat room with yourself");
    }

    final users = [currentUserId, otherUserId]..sort();
    final roomId = users.join("_");

    final roomDoc = await _chatRooms.doc(roomId).get();

    if (roomDoc.exists) {
      return ChatRoomModel.fromFirestore(roomDoc);
    }

    final currentUserData =
        (await firestore.collection("users").doc(currentUserId).get()).data()
            as Map<String, dynamic>;
    final otherUserData =
        (await firestore.collection("users").doc(otherUserId).get()).data()
            as Map<String, dynamic>;
    final participantsName = {
      currentUserId: currentUserData['username']?.toString() ?? "",
      otherUserId: otherUserData['username']?.toString() ?? "",
    };

    final newRoom = ChatRoomModel(
        id: roomId,
        participants: users,
        participantsName: participantsName,
        lastReadTime: {
          currentUserId: Timestamp.now(),
          otherUserId: Timestamp.now(),
        });

    await _chatRooms.doc(roomId).set(newRoom.toMap());
    return newRoom;
  }

  Future<void> sendMessage(
      {required String chatRoomId,
      required String senderId,
      required String receiverId,
      required String content,
      MessageType type = MessageType.text}) async {
    final batch = firestore.batch();
    final messageRef = getChatRoomMessages(chatRoomId);
    final messageDoc = messageRef.doc();
    final message = ChatMessage(
      id: messageDoc.id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: type,
      timestamp: Timestamp.now(),
      readBy: [],
    );
    batch.set(messageDoc, message.toMap());
    batch.update(_chatRooms.doc(chatRoomId), {
      "lastMessage": content,
      "lastMessageSenderId": senderId,
      "lastMessageTime": message.timestamp,
    });
    await batch.commit();
  }

  Stream<List<ChatMessage>> getMessages(String chatRoomId,
      {DocumentSnapshot? lastDocument}) {
    var query = getChatRoomMessages(chatRoomId)
        .orderBy('timestamp', descending: true)
        .limit(20);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
  }

  Future<List<ChatMessage>> getMoreMessages(String chatRoomId,
      {required DocumentSnapshot lastDocument}) async {
    final query = getChatRoomMessages(chatRoomId)
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastDocument)
        .limit(20);
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
  }

  Stream<List<ChatRoomModel>> getChatRooms(String userId) {
    return _chatRooms
        .where("participants", arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoomModel.fromFirestore(doc))
            .toList());
  }

  Stream<int> getUnReadCount(String chatRoomId, String userId) {
    return getChatRoomMessages(chatRoomId)
        .where("receiverId", isEqualTo: userId)
        .where("readBy", arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final unreadMessages = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> readBy = data["readBy"] ?? [];
        return !readBy.contains(userId);
      }).length;
      return unreadMessages;
    });
  }

  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      final batch = firestore.batch();
      final unreadMessages = await getChatRoomMessages(chatRoomId)
          .where("receiverId", isEqualTo: userId)
          .get();

      final messagesToUpdate = unreadMessages.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> readBy = data["readBy"] ?? [];
        return !readBy.contains(userId);
      }).toList();

      if (messagesToUpdate.isEmpty) return;

      for (final doc in messagesToUpdate) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
          'status': "read",
        });
      }
      await batch.commit();
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }
  Stream<Map<String, dynamic>> getUserOnlineStatus(String userId) {
    return firestore
        .collection("users")
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      return {
        'isOnline': data?['isOnline'] ?? false,
        'lastSeen': data?['lastSeen'],
      };
    });
  }
}
