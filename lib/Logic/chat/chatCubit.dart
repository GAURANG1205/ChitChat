import 'dart:async';
import 'dart:developer';

import 'package:chitchat/Data/Model/chatMessage_model.dart';
import 'package:chitchat/Logic/chat/chat_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Data/Repository/chatRepository.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  final String currentUserId;
  bool _isInChat = false;
  StreamSubscription? _chatMessageSubscription;
  StreamSubscription? _blockStatusSubscription;
  StreamSubscription? _amIBlockStatusSubscription;

  ChatCubit({
    required ChatRepository chatRepository,
    required this.currentUserId,
  })  : _chatRepository = chatRepository,
        super(const ChatState());

  void enterChat(String receiverId) async {
    _isInChat = true;
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final chatRoom =
          await _chatRepository.getOrCreateChatRoom(currentUserId, receiverId);
      emit(state.copyWith(
        chatRoomId: chatRoom.id,
        receiverId: receiverId,
        status: ChatStatus.loaded,
      ));
      _getUserMessge(chatRoom.id, currentUserId);
      BlocOtherUser(receiverId);
    } catch (e) {
      emit(state.copyWith(
          status: ChatStatus.error, error: "Failed to create chat room $e"));
    }
  }

  Future<void> sendMessage({required String content, required String receiverId}) async {
    if (state.chatRoomId == null) return;
    try {
      await _chatRepository.sendMessage(
        chatRoomId: state.chatRoomId!,
        senderId: currentUserId,
        receiverId: receiverId,
        content: content,
        repliedToMessage: state.replyMessage,
      );
      print("Message sent, clearing reply state");
      emit(state.copyWith(clearReplyMessage: true));
      print("State after sending: ${state.replyMessage}");
    } catch (e) {
      log(e.toString());
      emit(state.copyWith(error: "Failed to send message"));
    }
  }


  void onChatScreenOpened() {
    if (state.chatRoomId != null) {
      _markMessagesAsRead(state.chatRoomId!);
    }
  }

  Future<void> loadMoreMessages() async {
    if (state.status != ChatStatus.loaded ||
        state.messages.isEmpty ||
        !state.hasMoreMessages ||
        state.isLoadingMore) return;

    try {
      emit(state.copyWith(isLoadingMore: true));

      final lastMessage = state.messages.last;
      final lastDoc = await _chatRepository
          .getChatRoomMessages(state.chatRoomId!)
          .doc(lastMessage.id)
          .get();

      final moreMessages = await _chatRepository
          .getMoreMessages(state.chatRoomId!, lastDocument: lastDoc);

      if (moreMessages.isEmpty) {
        emit(state.copyWith(hasMoreMessages: false, isLoadingMore: false));
        return;
      }

      emit(
        state.copyWith(
            messages: [...state.messages, ...moreMessages],
            hasMoreMessages: moreMessages.length >= 20,
            isLoadingMore: false),
      );
    } catch (e) {
      emit(state.copyWith(
          error: "Failed to laod more messages", isLoadingMore: false));
    }
  }

  void _getUserMessge(String chatRoomId, String currentUserId) {
    _chatMessageSubscription?.cancel();
    _chatMessageSubscription = _chatRepository
        .getMessages(chatRoomId, currentUserId)
        .listen((messages) {
      if (_isInChat) {
        _markMessagesAsRead(chatRoomId);
      }
      emit(
        state.copyWith(
          messages: messages,
          error: null,
        ),
      );
    }, onError: (error) {
      emit(
        state.copyWith(
            error: "Failed to load messages", status: ChatStatus.error),
      );
    });
  }

  Future<void> _markMessagesAsRead(String chatRoomId) async {
    try {
      await _chatRepository.markMessagesAsRead(chatRoomId, currentUserId);
    } catch (e) {
      print("error marking messages as read $e");
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _chatRepository.blockUser(currentUserId, userId);
    } catch (e) {
      emit(
        state.copyWith(error: 'failed to block user $e'),
      );
    }
  }

  Future<void> unBlockUser(String userId) async {
    try {
      await _chatRepository.unBlockUser(currentUserId, userId);
    } catch (e) {
      emit(
        state.copyWith(error: 'failed to unblock user $e'),
      );
    }
  }

  void BlocOtherUser(String otherUserId) {
    _blockStatusSubscription?.cancel();
    _blockStatusSubscription = _chatRepository
        .isUserBlocked(currentUserId, otherUserId)
        .listen((isBlocked) {
      emit(
        state.copyWith(isUserBlocked: isBlocked),
      );

      _amIBlockStatusSubscription?.cancel();
      _blockStatusSubscription = _chatRepository
          .amIBlocked(currentUserId, otherUserId)
          .listen((isBlocked) {
        emit(
          state.copyWith(amIBlocked: isBlocked),
        );
      });
    }, onError: (error) {
      print("error getting online status");
    });
  }

  Future<void> editMessage(
      {required String messageId, required String newContent}) async {
    try {
      final messageRef = FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(state.chatRoomId)
          .collection('messages')
          .doc(messageId);
      final docSnapshot = await messageRef.get();
      if (!docSnapshot.exists) {
        print("Message does not exist.");
        return;
      }
      final messageData = docSnapshot.data();
      if (messageData?['senderId'] != FirebaseAuth.instance.currentUser?.uid) {
        print("Unauthorized update attempt.");
        return;
      }
      await messageRef.update({'content': newContent});
    } catch (e) {
      print("Error updating message: $e");
    }
  }

  Future<void> deleteMessage(String messageId, bool forEveryone) async {
    try {
      DocumentReference messageRef = FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(state.chatRoomId)
          .collection('messages')
          .doc(messageId);
      if (forEveryone) {
        await messageRef.delete();
      } else {
        await messageRef.update({
          'deletedFor': FieldValue.arrayUnion([currentUserId])
        });
      }
    } catch (e) {
      print("Error deleting message: $e");
    }
  }
  void setReplyMessage(ChatMessage? message) {
    emit(state.copyWith(replyMessage: message));
  }

  void clearReplyMessage() {
    print("Clearing reply state...");
    emit(state.copyWith(clearReplyMessage: true));
    print("Updated state: ${state.replyMessage}");
  }


  Future<void> leaveChat() async {
    _isInChat = false;
    _chatMessageSubscription?.cancel();
    _blockStatusSubscription?.cancel();
    _amIBlockStatusSubscription?.cancel();
  }
}
