import 'package:chitchat/Data/Model/chatMessage_model.dart';
import 'package:chitchat/Data/Repository/template/RepoTemplate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Model/chat_model.dart';
import '../Model/user_model.dart';

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
      final data = roomDoc.data();
      if (data == null) {
        throw Exception("Chat room data is null in Firestore.");
      }
      return ChatRoomModel.fromFirestore(roomDoc);
    }
    final currentUserData =
        await firestore.collection("users").doc(currentUserId).get();
    final otherUserData =
        await firestore.collection("users").doc(otherUserId).get();
    if (!currentUserData.exists || !otherUserData.exists) {
      throw Exception("User data not found in Firestore.");
    }
    final currentUserMap = currentUserData.data();
    final otherUserMap = otherUserData.data();
    if (currentUserMap == null || otherUserMap == null) {
      throw Exception("User document data is null.");
    }
    final participantsName = {
      currentUserId: currentUserMap['username']?.toString() ?? "",
      otherUserId: otherUserMap['username']?.toString() ?? "",
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

  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    ChatMessage? repliedToMessage,
  }) async {
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
      deletedFor: [],
      repliedToMessage: repliedToMessage,
    );

    batch.set(messageDoc, message.toMap());

    batch.update(_chatRooms.doc(chatRoomId), {
      "lastMessage": content,
      "lastMessageSenderId": senderId,
      "lastMessageTime": message.timestamp,
    });

    await batch.commit();
  }
  Stream<List<ChatMessage>> getMessages(
      String chatRoomId,
      String currentUserId, {
        DocumentSnapshot? lastDocument,
      }) {
    var query = getChatRoomMessages(chatRoomId)
        .orderBy('timestamp', descending: true)
        .limit(20);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .where((message) => !message.deletedFor.contains(currentUserId))
          .toList();
    });
  }



  Future<List<ChatMessage>> getMoreMessages(String chatRoomId,
      {required DocumentSnapshot lastDocument}) async {
    final query = getChatRoomMessages(chatRoomId)
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastDocument)
        .limit(20);
    print("comingg");
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
        .where('status', isEqualTo: MessageStatus.sent.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      final batch = firestore.batch();
      final unreadMessages = await getChatRoomMessages(chatRoomId)
          .where(
            "receiverId",
            isEqualTo: userId,
          )
          .where('status', isEqualTo: MessageStatus.sent.toString())
          .get();
      print("found ${unreadMessages.docs.length} unread messages");

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
          'status': MessageStatus.read.toString(),
        });
        print("Marked messaegs as read for user $userId");
      }
      await batch.commit();
    } catch (e) {}
  }

  Future<DocumentSnapshot> getChatRoomDocument(String chatRoomId) {
    return _chatRooms.doc(chatRoomId).get();
  }

  Future<void> blockUser(String currentUserId, String blockedUserId) async {
    final userRef = firestore.collection("users").doc(currentUserId);
    await userRef.update({
      'blockedUsers': FieldValue.arrayUnion([blockedUserId])
    });
  }

  Future<void> unBlockUser(String currentUserId, String blockedUserId) async {
    final userRef = firestore.collection("users").doc(currentUserId);
    await userRef.update({
      'blockedUsers': FieldValue.arrayRemove([blockedUserId])
    });
  }

  Stream<bool> isUserBlocked(String currentUserId, String otherUserId) {
    return firestore
        .collection("users")
        .doc(currentUserId)
        .snapshots()
        .map((doc) {
      final userData = UserModel.fromFirestore(doc);
      return userData.blockedUsers.contains(otherUserId);
    });
  }

  Stream<bool> amIBlocked(String currentUserId, String otherUserId) {
    return firestore
        .collection("users")
        .doc(otherUserId)
        .snapshots()
        .map((doc) {
      final userData = UserModel.fromFirestore(doc);
      return userData.blockedUsers.contains(currentUserId);
    });
  }
  Future<void> deleteMessageForUser(String chatRoomId, String messageId, String userId) async {
    final messageRef = getChatRoomMessages(chatRoomId).doc(messageId);

    await messageRef.update({
      "deletedFor": FieldValue.arrayUnion([userId])
    });
  }

}
