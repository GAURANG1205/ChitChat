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
      _getUserMessge(chatRoom.id);
      BlocOtherUser(receiverId);
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

  void _getUserMessge(String chatRoomId) {
    _chatMessageSubscription?.cancel();
    _chatMessageSubscription =
        _chatRepository.getMessages(chatRoomId).listen((messages) {
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
  Future<void> leaveChat() async {
    _isInChat = false;
  }
}