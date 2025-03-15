import 'dart:ui';

import 'package:chitchat/Theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Data/Model/chat_model.dart';
import '../Data/Repository/chatRepository.dart';
import '../Data/Repository/template/service_locator.dart';

class ChatListTile extends StatelessWidget {
  final ChatRoomModel chat;
  final String currentUserId;
  final VoidCallback onTap;
  final Map<String, String> contactNameMap;

  const ChatListTile(
      {super.key,
      required this.chat,
      required this.currentUserId,
      required this.onTap,
      required this.contactNameMap});

  String _getOtherUsername() {
    final otherUserId = chat.participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) return "Unknown User";
    return contactNameMap[otherUserId]??chat.participantsName![otherUserId]??
        "Unknown User";
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        leading: CircleAvatar(
          backgroundImage: AssetImage("assets/icon/Unknown.jpg") as ImageProvider,
        ),
        title: Text(
          _getOtherUsername(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: [
            Expanded(
                child: Text(
              chat.lastMessage ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            )),
          ],
        ),
        trailing: StreamBuilder<int>(
          stream:
              getit<ChatRepository>().getUnReadCount(chat.id, currentUserId),
          builder: (context, snapshot) {
            print("Unread messages count: ${snapshot.data}");
            final unreadCount = snapshot.data ?? 0;
            if (unreadCount == 0) return const SizedBox();
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                snapshot.data.toString(),
                style:  TextStyle(color: isDarkMode?Colors.white:Colors.white),
              ),
            );
          },
        ));
  }
}
