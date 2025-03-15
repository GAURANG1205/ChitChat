import 'package:chitchat/Comman/CustomTextField.dart';
import 'package:chitchat/Data/Repository/template/service_locator.dart';
import 'package:chitchat/Logic/cubitAuth.dart';
import 'package:chitchat/screen/ContactScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' as bloc;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../Comman/chatListTile.dart';
import '../Data/Repository/ContactRepository.dart';
import '../Data/Repository/authRepository.dart';
import '../Data/Repository/chatRepository.dart';
import '../Theme/colors.dart';
import '../router/app_router.dart';
import 'Chat_MessageScreen.dart';
import 'LoginPageScreen.dart';

class chatScreen extends StatefulWidget {
  chatScreen({super.key});

  @override
  State<chatScreen> createState() {
    return _chatScreenState();
  }
}

class _chatScreenState extends State<chatScreen> {
  var _selectIndex = 0;
  final TextEditingController searchController = TextEditingController();
  late final ChatRepository _chatRepository;
  late final String _currentUserId;
  Map<String, String> _contactNameMap = {};
  bool _isLoadingContacts = true;

  Future<void> _loadContacts() async {
    final hasPermission = await ContactRepository().requestContactsPermission();
    if (!hasPermission) {
      Get.snackbar("Permission Required", "Please enable contact permissions.");
      return;
    }
    final contacts = await ContactRepository().getRegisteredContacts();
    if (mounted) {
      setState(() {
        _contactNameMap.clear();
        _contactNameMap.addAll({for (var contact in contacts) contact['id']: contact['name']});
        _isLoadingContacts = false;
      });
    }
  }
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _chatRepository = getit<ChatRepository>();
    _currentUserId = getit<AuthRepository>().auth.currentUser?.uid ?? "";
    _loadContacts();
    super.initState();
  }

  Widget build(context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chit Chat",
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: isDarkMode ? kContentColorLightTheme : kPrimaryColor,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            isDarkMode ? kContentColorDarkTheme : kContentColorLightTheme,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await context.read<cubitAuth>().signOut();
              getit<AppRouter>().pushAndRemoveUntil(loginPage());
            },
            icon: Icon(Icons.search),
          )
        ],
      ),
      body: _isLoadingContacts?Center(child: CircularProgressIndicator(),): Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CustomTextField(
              decoration: InputDecoration(
                hintText: "Search",
                hintStyle: TextStyle(
                    color: isDarkMode
                        ? Color.fromRGBO(150, 155, 159, 100)
                        : Color.fromRGBO(103, 103, 104, 100),
                    fontSize: 14),
                filled: true,
                fillColor: isDarkMode
                    ? Color.fromRGBO(141, 146, 150, 100)
                    : Color.fromRGBO(228, 228, 228, 1),
                suffixIcon:
                    IconButton(onPressed: () {}, icon: Icon(Icons.search)),
                contentPadding: EdgeInsets.only(left: 20, top: 10, bottom: 10),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(20),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              textEditingController: searchController,
            ),
            SizedBox(height: mq.height * 0.002),
            Expanded(
              child: StreamBuilder(
                  stream: _chatRepository.getChatRooms(_currentUserId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      print(snapshot.error);
                      return Center(
                        child: Text("error:${snapshot.error}"),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final chats = snapshot.data!;
                    if (chats.isEmpty) {
                      return const Center(
                        child: Text("No recent chats"),
                      );
                    }
                    return ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          final otherUserId = chat.participants
                              .firstWhere((id) => id != _currentUserId);
                          final otherUserName = _contactNameMap[otherUserId] ??
                              chat.participantsName![otherUserId] ?? "Unknown";

                          return StatefulBuilder(builder: (context, setState) {
                            return ChatListTile(
                                chat: chat,
                                currentUserId: _currentUserId,
                                contactNameMap: _contactNameMap,
                                onTap: () async {
                                  await Get.to(() => ChatMessageScreen(
                                    receiverId: otherUserId,
                                    receiverName: otherUserName,
                                  ),transition: Transition.rightToLeft);
                                  _loadContacts();
                                });
                          });
                        });
                  }),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        onPressed: () async {
          final hasPermission =
              await ContactRepository().requestContactsPermission();
          if (hasPermission) {
           await Get.to(() => const contactScreen(),
                transition: Transition.rightToLeft);
          } else {
            Get.snackbar("Permission Required",
                "Please enable contact permissions in settings.");
          }
        },
        child: const Icon(
          Icons.person_add_alt_1,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        animationDuration: Duration(seconds: 1),
        selectedIndex: _selectIndex,
        onDestinationSelected: (value) {
          setState(() {
            _selectIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.messenger_outline_outlined), label: "Chats"),
          NavigationDestination(
              icon: Icon(Icons.slow_motion_video), label: "Story"),
          NavigationDestination(icon: Icon(Icons.call), label: "Calls"),
          NavigationDestination(
            icon: CircleAvatar(
              radius: 14,
              backgroundImage: AssetImage("assets/icon/icon.png"),
              backgroundColor: Colors.transparent,
            ),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
