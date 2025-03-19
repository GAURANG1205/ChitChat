import 'package:chitchat/Data/Model/chatMessage_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ChatStatus {
  inital,
  loading,
  loaded,
  error,
}

class ChatState extends Equatable {
  final ChatStatus status;
  final String? error;
  final String? receiverId;
  final String? chatRoomId;
  final List<ChatMessage> messages;
  final Timestamp? receiverLastSeen;
  final bool hasMoreMessages;
  final bool isLoadingMore;
  final bool isUserBlocked;
  final bool amIBlocked;
  final ChatMessage? replyMessage;
  const ChatState({
    this.status = ChatStatus.inital,
    this.error,
    this.receiverId,
    this.chatRoomId,
    this.messages = const [],
    this.receiverLastSeen,
    this.hasMoreMessages = true,
    this.isLoadingMore = false,
    this.isUserBlocked = false,
    this.amIBlocked = false,
    this.replyMessage
  });

  ChatState copyWith({
    ChatStatus? status,
    String? error,
    String? receiverId,
    String? chatRoomId,
    List<ChatMessage>? messages,
    Timestamp? receiverLastSeen,
    bool? hasMoreMessages,
    bool? isLoadingMore,
    bool? isUserBlocked,
    bool? amIBlocked,
    ChatMessage? replyMessage,
    bool clearReplyMessage = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      error: error ?? this.error,
      receiverId: receiverId ?? this.receiverId,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      messages: messages ?? this.messages,
      receiverLastSeen: receiverLastSeen ?? this.receiverLastSeen,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isUserBlocked: isUserBlocked ?? this.isUserBlocked,
      amIBlocked: amIBlocked ?? this.amIBlocked,
      replyMessage: clearReplyMessage ? null : replyMessage ?? this.replyMessage,
    );
  }


  @override
  List<Object?> get props {
    return [
      status,
      error,
      receiverId,
      chatRoomId,
      messages,
      receiverLastSeen,
      hasMoreMessages,
      isLoadingMore,
      isUserBlocked,
      amIBlocked,
      replyMessage,
    ];
  }
}