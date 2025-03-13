import 'dart:async';
import 'dart:developer';

import 'package:chitchat/Logic/chat/chat_state.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Data/Repository/chatRepository.dart';

class ChatCubit extends Cubit<ChatState>{
  final ChatRepository _chatRepository;
  final String currentUserId;
  bool _isInChat = false;
 StreamSubscription? _chatMessageSubscription;
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
      _getUserMessge(chatRoom.id);
    } catch (e) {
      emit(state.copyWith(
          status: ChatStatus.error, error: "Failed to create chat room $e"));
    }
  }
  Future<void> sendMessage(
      {required String content, required String receiverId}) async {
    if (state.chatRoomId == null) return;
    try {
      await _chatRepository.sendMessage(
        chatRoomId: state.chatRoomId!,
        senderId: currentUserId,
        receiverId: receiverId,
        content: content,
      );
    } catch (e) {
      log(e.toString());
      emit(state.copyWith(error: "Failed to send message"));
    }
  }
  void onChatScreenOpened() {
    if (state.chatRoomId != null) {
      _markMessagesAsRead(state.chatRoomId!);  // Mark messages as read
    }
  }
  void _getUserMessge(String chatRoomId) {
    _chatMessageSubscription?.cancel();
    _chatMessageSubscription =
        _chatRepository.getMessages(chatRoomId).listen((messages) {
          if (_isInChat && messages.isNotEmpty) {
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
    if (!_isInChat) return;
    try {
      await _chatRepository.markMessagesAsRead(chatRoomId, currentUserId);
    } catch (e) {
      print("error marking messages as read $e");
    }
  }

  Future<void> leaveChat() async {
    _isInChat = false;
    _chatMessageSubscription?.cancel();
  }
}
