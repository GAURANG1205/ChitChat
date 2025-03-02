import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Theme/colors.dart';

class chatScreen extends StatefulWidget {
  chatScreen({super.key});

  @override
  State<chatScreen> createState() {
    return _chatScreenState();
  }
}

class _chatScreenState extends State<chatScreen> {
  var _selectIndex = 1;

  Widget build(context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
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
            onPressed: () {},
            icon: Icon(Icons.search),
          )
        ],
      ),
      body: Center(child: Text('Hello')),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        onPressed: () {},
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
