import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video }

enum MessageStatus { sent, read }

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final Timestamp timestamp;
  final List<String> readBy;
  final Timestamp? editedAt;
  final ChatMessage? repliedToMessage;
  final List<String> deletedFor;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    required this.readBy,
    this.editedAt,
    this.repliedToMessage,
    required this.deletedFor,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatMessage(
      id: doc.id,
      chatRoomId: data['chatRoomId'] as String,
      senderId: data['senderId'] as String,
      receiverId: data['receiverId'] as String,
      content: data['content'] as String,
      type: MessageType.values.firstWhere(
            (e) => e.toString() == data['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
            (e) => e.toString() == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: data['timestamp'] as Timestamp,
      readBy: List<String>.from(data['readBy'] ?? []),
      editedAt: data['editedAt'] != null ? data['editedAt'] as Timestamp : null,
      repliedToMessage: data['repliedToMessage'] != null
          ? ChatMessage(
        id: data['repliedToMessage']['id'] ?? '',
        senderId: data['repliedToMessage']['senderId'] ?? '',
        receiverId: '',
        chatRoomId: '',
        content: data['repliedToMessage']['content'] ?? '',
        timestamp: (data['repliedToMessage']['timestamp'] as Timestamp?) ??
            Timestamp.now(),
        type: MessageType.text,
        status: MessageStatus.sent,
        readBy: [],
        editedAt: null,
        deletedFor: [],
        repliedToMessage: null,
      )
          : null,
      deletedFor: List<String>.from(data['deletedFor'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "chatRoomId": chatRoomId,
      "senderId": senderId,
      "receiverId": receiverId,
      "content": content,
      "type": type.toString(),
      "status": status.toString(),
      "timestamp": timestamp,
      "readBy": readBy,
      "editedAt": editedAt,
      "repliedToMessage": repliedToMessage != null
          ? {
        'id': repliedToMessage!.id,
        'senderId': repliedToMessage!.senderId,
        'content': repliedToMessage!.content,
        'timestamp': repliedToMessage!.timestamp,
      }
          : null,
      "deletedFor": deletedFor,
    };
  }
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
        id: map['id'],
        chatRoomId: map['chatRoomId'],
        senderId: map['senderId'],
        receiverId: map['receiverId'],
        content: map['content'],
        type: MessageType.values.firstWhere((e) => e.toString() == map['type'],
            orElse: () => MessageType.text),
        status: MessageStatus.values.firstWhere(
            (e) => e.toString() == map['status'],
            orElse: () => MessageStatus.sent),
        timestamp: Timestamp.fromMillisecondsSinceEpoch(map['timestamp']),
        readBy: map['readBy'] != null ? List<String>.from(map['readBy']) : [],
        editedAt: map['editedAt'] != null
            ? Timestamp.fromMillisecondsSinceEpoch(map['editedAt'])
            : null,
        repliedToMessage: map['repliedToMessage'] != null
            ? ChatMessage.fromMap(
                Map<String, dynamic>.from(map['repliedToMessage']))
            : null,
        deletedFor: List<String>.from(map['deletedFor'] ?? []));
  }

  ChatMessage copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    Timestamp? timestamp,
    List<String>? readBy,
    Timestamp? editedAt,
    ChatMessage? repliedToMessage,
    List<String>? deletedFor,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      readBy: readBy ?? this.readBy,
      editedAt: editedAt ?? this.editedAt,
      repliedToMessage: repliedToMessage ?? this.repliedToMessage,
      deletedFor: deletedFor ?? this.deletedFor,
    );
  }
}
