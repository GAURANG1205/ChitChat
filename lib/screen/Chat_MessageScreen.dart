import 'dart:typed_data';

import 'package:chitchat/Comman/CustomTextField.dart';
import 'package:chitchat/Data/Model/chatMessage_model.dart';
import 'package:chitchat/Logic/chat/chatCubit.dart';
import 'package:chitchat/Logic/chat/chat_state.dart';
import 'package:chitchat/Theme/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../Data/Repository/template/service_locator.dart';

class ChatMessageScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatMessageScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final messageTextController = TextEditingController();
  late final ChatCubit _chatCubit;

  @override
  void initState() {
    _chatCubit = getit<ChatCubit>();
    _chatCubit.enterChat(widget.receiverId);
    _chatCubit.onChatScreenOpened();
    super.initState();
  }

  Future<void> _handleSendMessage() async {
    final messageText = messageTextController.text.trim();
    messageTextController.clear();
    if (messageText.isNotEmpty) {
      await _chatCubit.sendMessage(
          content: messageText, receiverId: widget.receiverId);
    }
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    messageTextController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: mq.width * 0.045,
                backgroundImage: AssetImage("assets/icon/Unknown.jpg"),
              ),
              SizedBox(width: mq.width * 0.0158),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  widget.receiverName,
                  style: TextStyle(
                    fontSize: mq.width * 0.0455,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "Online",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: mq.width * 0.03,
                  ),
                ),
              ])
            ],
          ),
          actions: [
            IconButton(onPressed: () {}, icon: Icon(Icons.videocam_outlined)),
            IconButton(onPressed: () {}, icon: Icon(Icons.call_outlined)),
            IconButton(onPressed: () {}, icon: Icon(Icons.more_vert_outlined)),
          ],
        ),
        body: BlocBuilder<ChatCubit, ChatState>(
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
                Expanded(
                  child: ListView.builder(
                      reverse: true,
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final messsage = state.messages[index];
                        final bool isMe =
                            messsage.senderId == _chatCubit.currentUserId;

                        return MessageBubble(Message: messsage, isMe: isMe);
                      }),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 12, top: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                                keyboardType: TextInputType.multiline,
                                controller: messageTextController,
                                minLines: 1,
                                maxLines: 5,
                                decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                    prefixIcon: IconButton(
                                        onPressed: () {},
                                        icon: Icon(
                                            Icons.emoji_emotions_outlined,
                                            color: isDarkMode
                                                ? Color.fromRGBO(
                                                    201, 201, 201, 1)
                                                : Color.fromRGBO(
                                                    107, 123, 129, 1))),
                                    hintText: "Type a Message",
                                    hintStyle: TextStyle(
                                        color: isDarkMode
                                            ? Color.fromRGBO(204, 204, 206, 1)
                                            : Color.fromRGBO(107, 123, 129, 1),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                    filled: true,
                                    fillColor:
                                        Color.fromRGBO(133, 143, 154, 100),
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.circular(50)),
                                    focusedBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(50)))),
                          ),
                          ElevatedButton(
                            onPressed: _handleSendMessage,
                            style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(12),
                              backgroundColor: isDarkMode
                                  ? kPrimaryColor.withOpacity(0.6)
                                  : kPrimaryColor.withOpacity(0.9),
                            ),
                            child: Icon(Icons.send,
                                color:
                                    isDarkMode ? Colors.black : Colors.white),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            );
          },
        ));
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage Message;
  final bool isMe;

  const MessageBubble({super.key, required this.Message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 64 : 8,
          right: isMe ? 8 : 64,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe
              ? (isDarkMode
                  ? kPrimaryColor.withOpacity(0.2)
                  : kPrimaryColor.withOpacity(0.6))
              : (isDarkMode ? Colors.grey[800] : Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: isMe ? Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment:isMe?
          CrossAxisAlignment.end:CrossAxisAlignment.start,
          children: [
            Text(
              Message.content,
              style: TextStyle(
                color: isDarkMode
                    ?  Colors.white
                    :   Colors.black,
                fontSize: 16,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(Message.timestamp.toDate()),
                  style: TextStyle(
                      color: Colors.blueGrey, fontSize: mq.width * 0.02),
                ),
                 SizedBox(width: mq.width*0.02),
                if (isMe)
                  Icon(
                    Icons.done_all,
                    size: mq.width*0.04,
                    color: Message.status == MessageStatus.read
                        ? Colors.blue
                        : (isDarkMode?Colors.grey:Colors.white),
                  )
              ],
            )
          ],
        ),
      ),
    );
  }
}
