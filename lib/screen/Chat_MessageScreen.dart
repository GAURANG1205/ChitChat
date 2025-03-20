import 'dart:developer';

import 'package:chitchat/Data/Model/chatMessage_model.dart';
import 'package:chitchat/Logic/chat/chatCubit.dart';
import 'package:chitchat/Logic/chat/chat_state.dart';
import 'package:chitchat/Theme/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../Data/Repository/template/service_locator.dart';

class ChatMessageScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? photoUrl;

  const ChatMessageScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.photoUrl,
  });

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final messageTextController = TextEditingController();
  late final ChatCubit _chatCubit;
  final _scrollController = ScrollController();
  List<ChatMessage> _previousMessages = [];
  bool _showEmoji = false;
  Set<String> selectedMessages = {};
  String? highlightedMessageId;
  @override
  void initState() {
    _chatCubit = getit<ChatCubit>();
    _chatCubit.enterChat(widget.receiverId);
    _chatCubit.onChatScreenOpened();
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  Future<void> _handleSendMessage() async {
    final messageText = messageTextController.text.trim();
    if (messageText.isNotEmpty) {
      log("Reply message before sending: ${_chatCubit.state.replyMessage?.content}");
      await _chatCubit.sendMessage(
          content: messageText, receiverId: widget.receiverId);
      _chatCubit.clearReplyMessage();
      messageTextController.clear();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _chatCubit.loadMoreMessages();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _hasNewMessages(List<ChatMessage> messages) {
    if (messages.length != _previousMessages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      _previousMessages = messages;
    }
  }

  void _toggleSelection(String messageId) {
    setState(() {
      if (selectedMessages.contains(messageId)) {
        selectedMessages.remove(messageId);
      } else {
        selectedMessages.add(messageId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      selectedMessages.clear();
    });
  }
  void _scrollToMessage(String messageId) {
    int index = _chatCubit.state.messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      setState(() {
        highlightedMessageId = messageId;
      });
      _scrollController.animateTo(
        index * 100.0,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          highlightedMessageId = null;
        });
      });
    }
  }

  void _deleteSelectedMessages() async {
    if (selectedMessages.isEmpty) return;

    print("Selected messages: ${selectedMessages.length}");
    List<ChatMessage> selectedMessageObjects = [];
    for (String messageId in selectedMessages) {
      final message = _chatCubit.state.messages.firstWhere(
        (msg) => msg.id == messageId,
        orElse: () => ChatMessage(
            id: '',
            content: '',
            senderId: '',
            receiverId: '',
            timestamp: Timestamp.now(),
            status: MessageStatus.sent,
            deletedFor: [],
            chatRoomId: '',
            readBy: []),
      );

      if (message.id.isNotEmpty) {
        selectedMessageObjects.add(message);
      }
    }
    print("Found ${selectedMessageObjects.length} message objects");
    int otherUserMessageCount = 0;
    int myMessageCount = 0;

    for (ChatMessage message in selectedMessageObjects) {
      print(
          "Message ID: ${message.id}, Sender: ${message.senderId}, Current User: ${_chatCubit.currentUserId}");

      if (message.senderId == _chatCubit.currentUserId) {
        myMessageCount++;
      } else {
        otherUserMessageCount++;
      }
    }
    print(
        "My messages: $myMessageCount, Other user messages: $otherUserMessageCount");
    String dialogTitle = "Delete Message?";
    List<Widget> actions = [];
    if (otherUserMessageCount == 0) {
      actions.add(TextButton(
        onPressed: () => Navigator.pop(context, "deleteForEveryone"),
        child: const Text("Delete for Everyone"),
      ));
    }
    actions.add(TextButton(
      onPressed: () => Navigator.pop(context, "deleteForMe"),
      child: const Text("Delete for Me"),
    ));

    actions.add(TextButton(
      onPressed: () => Navigator.pop(context, null),
      child: const Text("Cancel"),
    ));
    final String? selectedOption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: otherUserMessageCount > 0
            ? Text("Some selected messages can only be deleted for you.")
            : null,
        actions: actions,
      ),
    );

    print("Selected option: $selectedOption");
    if (selectedOption == null) return;
    for (String messageId in selectedMessages) {
      final message = _chatCubit.state.messages.firstWhere(
        (msg) => msg.id == messageId,
        orElse: () => ChatMessage(
            id: '',
            content: '',
            senderId: '',
            receiverId: '',
            timestamp: Timestamp.now(),
            status: MessageStatus.sent,
            deletedFor: [],
            chatRoomId: '',
            readBy: []),
      );
      if (selectedOption == "deleteForMe") {
        print("Deleting message $messageId for me");
        await _chatCubit.deleteMessage(messageId, false);
      } else if (selectedOption == "deleteForEveryone" &&
          message.senderId == _chatCubit.currentUserId) {
        print("Deleting message $messageId for everyone");
        await _chatCubit.deleteMessage(messageId, true);
      }
    }
    setState(() {
      selectedMessages.clear();
    });
  }

  @override
  void dispose() {
    super.dispose();
    messageTextController.dispose();
    _scrollController.dispose();
    _chatCubit.leaveChat();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
        appBar: selectedMessages.isNotEmpty
            ? AppBar(
                leading: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: _clearSelection,
                ),
                title: Text("${selectedMessages.length} Selected"),
                actions: [
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: _deleteSelectedMessages,
                  ),
                ],
              )
            : AppBar(
                titleSpacing: 0,
                title: Flex(
                  mainAxisSize: MainAxisSize.min,
                  direction: Axis.horizontal,
                  children: [
                    Flexible(
                      flex: 1,
                      child: CircleAvatar(
                        radius: mq.width*0.04,
                        backgroundImage:  widget.photoUrl!.isNotEmpty
                            ? NetworkImage(widget.photoUrl!)
                            : const AssetImage("assets/icon/Unknown.jpg") as ImageProvider,
                      ),
                    ),
                    SizedBox(width: mq.width * 0.0158),
                    Flexible(
                      flex: 1,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.receiverName,
                              style: TextStyle(
                                fontSize: mq.width * 0.0455,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ]),
                    )
                  ],
                ),
                actions: [
                  IconButton(
                      onPressed: () {}, icon: Icon(Icons.videocam_outlined)),
                  IconButton(onPressed: () {}, icon: Icon(Icons.call_outlined)),
                  BlocBuilder<ChatCubit, ChatState>(
                      bloc: _chatCubit,
                      builder: (context, state) {
                        if (state.isUserBlocked) {
                          return TextButton.icon(
                            onPressed: () =>
                                _chatCubit.unBlockUser(widget.receiverId),
                            label: const Text(
                              "Unblock",
                            ),
                            icon: const Icon(Icons.block),
                          );
                        }
                        return PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            if (value == "block") {
                              final bool? confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                      "Are you sure you want to block ${widget.receiverName}"),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          "Block",
                                          style: TextStyle(color: Colors.red),
                                        ))
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _chatCubit.blockUser(widget.receiverId);
                              }
                            }
                          },
                          itemBuilder: (context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem(
                              value: 'block',
                              child: Text("Block User"),
                            )
                          ],
                        );
                      })
                ],
              ),
        body: SafeArea(
          child: BlocConsumer<ChatCubit, ChatState>(
            listener: (context, state) {
              _hasNewMessages(state.messages);
            },
            bloc: _chatCubit,
            builder: (context, state) {
              if (state.status == ChatStatus.loading) {
                return Center(child: CircularProgressIndicator());
              }
              if (state.status == ChatStatus.error) {
                return Center(
                  child: Text(state.error ?? "Something Went Wrong"),
                );
              }

              return Column(
                children: [
                  if (state.amIBlocked)
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.red.withOpacity(0.1),
                      child: Text(
                        "You have been blocked by ${widget.receiverName}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final messsage = state.messages[index];
                          final bool isMe =
                              messsage.senderId == _chatCubit.currentUserId;
                          if (messsage.deletedFor
                                  .contains(_chatCubit.currentUserId) ==
                              true) {
                            return const SizedBox.shrink();
                          }
                          return GestureDetector(
                            onHorizontalDragEnd: (details) {
                              if (details.primaryVelocity != null &&
                                  details.primaryVelocity! > 500) {
                                print(
                                    "Swipe detected! Replying to: ${messsage.content}");
                                _chatCubit.setReplyMessage(messsage);
                              }
                            },
                            child: MessageBubble(
                                Message: messsage,
                                isMe: isMe,
                                isSelected:
                                    selectedMessages.contains(messsage.id),
                                onLongPress: () =>
                                    _toggleSelection(messsage.id),
                                isHighlighted: highlightedMessageId == messsage.id,
                                onTap: () {
                                  if (selectedMessages.isNotEmpty) {
                                    _toggleSelection(messsage.id);
                                  }
                                },
                              onReplyTap: () => _scrollToMessage(messsage.id)),
                          );
                        }),
                  ),
                  if (!state.amIBlocked && !state.isUserBlocked)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12, top: 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Color(0xFF32373D) : Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (state.replyMessage != null)
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? Color(0xFF282D32) : Colors.grey[200],
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(30),
                                              topRight: Radius.circular(30),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Replying to:",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.blueGrey,
                                                      ),
                                                    ),
                                                    Text(
                                                      state.replyMessage!.content,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontStyle: FontStyle.italic,
                                                        color: isDarkMode ? Colors.white70 : Colors.black87,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  _chatCubit.clearReplyMessage();
                                                  setState(() {});
                                                },
                                                child: Icon(Icons.close, color: Colors.blueGrey, size: 20),
                                              ),
                                            ],
                                          ),
                                        ),

                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _showEmoji = !_showEmoji;
                                                if (_showEmoji) {
                                                  FocusScope.of(context).unfocus(); // Close keyboard first
                                                }
                                              });
                                            },
                                            icon: Icon(Icons.emoji_emotions_outlined, color: isDarkMode ? Colors.white : Colors.black),
                                          ),
                                          Expanded(
                                            child: TextField(
                                              onTap: () {
                                                if (_showEmoji) {
                                                  setState(() {
                                                    _showEmoji = false;
                                                  });
                                                }
                                              },
                                              keyboardType: TextInputType.multiline,
                                              controller: messageTextController,
                                              minLines: 1,
                                              maxLines: 5,
                                              decoration: InputDecoration(
                                                contentPadding: EdgeInsets.symmetric(vertical: 15),
                                                hintText: "Message",
                                                hintStyle: TextStyle(
                                                  color: isDarkMode ? Color(0xFFB0B3B8) : Color(0xFF606770),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                filled: true,
                                                fillColor: isDarkMode ? Color(0xFF32373D) : Colors.white,
                                                border: OutlineInputBorder(
                                                  borderSide: BorderSide.none,
                                                  borderRadius: BorderRadius.circular(50),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide.none,
                                                  borderRadius: BorderRadius.circular(50),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _handleSendMessage,
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(12),
                                  backgroundColor: isDarkMode ? kPrimaryColor.withOpacity(0.6) : kPrimaryColor.withOpacity(0.9),
                                ),
                                child: Icon(Icons.send, color: isDarkMode ? Colors.black : Colors.white),
                              ),
                            ],
                          ),
                          Visibility(
                            visible: _showEmoji,
                            child: SizedBox(
                              height: 250,
                              child: EmojiPicker(
                                textEditingController: messageTextController,
                                onEmojiSelected: (category, emoji) {
                                  messageTextController.text += emoji.emoji;
                                },
                                config: Config(
                                  height: 250,
                                  emojiViewConfig: EmojiViewConfig(
                                    columns: 8,
                                    emojiSizeMax: 40.0,
                                    backgroundColor: isDarkMode ? Color(0xFF202020) : Colors.white,
                                  ),
                                  bottomActionBarConfig: BottomActionBarConfig(
                                    enabled: true,
                                    backgroundColor: isDarkMode ? kPrimaryColor.withOpacity(0.5) : kPrimaryColor,
                                    buttonColor: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ));
  }
}

class MessageBubble extends StatefulWidget {
  final ChatMessage Message;
  final bool isMe;
  final bool isSelected;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final bool isHighlighted;
  final VoidCallback onReplyTap;
  const MessageBubble({
    super.key,
    required this.Message,
    required this.isMe,
    required this.isSelected,
    required this.onLongPress,
    required this.onTap,
    required this.isHighlighted,
    required this.onReplyTap
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery
        .of(context)
        .size;
    final isDarkMode = Theme
        .of(context)
        .brightness == Brightness.dark;
    return GestureDetector(
      onLongPress: widget.onLongPress,
      onTap: widget.onTap,
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: widget.isMe ? 64 : 8,
            right: widget.isMe ? 8 : 64,
            bottom: 4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.blue.withOpacity(0.3)
                : widget.isMe
                ? (isDarkMode
                ? kPrimaryColor.withOpacity(0.2)
                : kPrimaryColor.withOpacity(0.6))
                : (isDarkMode
                ? Colors.grey[800]
                : Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: widget.isMe ? Radius.circular(16) : Radius.zero,
              bottomRight: widget.isMe ? Radius.zero : Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (widget.Message.repliedToMessage != null)
                _buildRepliedMessage(context),
              Text(
                widget.Message.content,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('h:mm a')
                        .format(widget.Message.timestamp.toDate()),
                    style: TextStyle(
                        color: Colors.blueGrey, fontSize: mq.width * 0.02),
                  ),
                  SizedBox(width: mq.width * 0.02),
                  if (widget.isMe)
                    Icon(
                      Icons.done_all,
                      size: mq.width * 0.04,
                      color: widget.Message.status == MessageStatus.read
                          ? Colors.blue
                          : (isDarkMode ? Colors.grey : Colors.white),
                    )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildRepliedMessage(BuildContext context) {
    return InkWell(
      onTap:widget.onReplyTap,
      child: Container(
        padding: EdgeInsets.all(8),
        margin: EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
            bottomLeft: widget.isMe?Radius.circular(8):Radius.zero,
            bottomRight: widget.isMe?Radius.zero:Radius.circular(8),
          ),
          border: Border(
            left: BorderSide(
              color: kPrimaryColor,
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.Message.repliedToMessage?.content ?? "Error loading reply",
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
