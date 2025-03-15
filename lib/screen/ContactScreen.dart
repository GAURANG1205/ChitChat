import 'package:chitchat/Data/Repository/ContactRepository.dart';
import 'package:chitchat/Data/Repository/template/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../Comman/CustomTextField.dart';
import '../Theme/colors.dart';
import '../router/app_router.dart';
import 'Chat_MessageScreen.dart';

class contactScreen extends StatefulWidget {
  const contactScreen({super.key});

  @override
  State<contactScreen> createState() => contactScreenState();
}

class contactScreenState extends State<contactScreen> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          "Select Contact",
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: isDarkMode ? kContentColorLightTheme : kPrimaryColor,
                fontSize: mq.width * 0.0485,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: CustomTextField(
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
          ),
          const SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "Contacts on ChitChat",
              style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? Color.fromRGBO(145, 150, 154, 100)
                      : Color.fromRGBO(90, 91, 93, 100)),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: ContactRepository().getRegisteredContacts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }
                final contacts = snapshot.data??[];
                if (contacts.isEmpty) {
                  return const Center(child: Text("No contacts found"));
                }
                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading:  CircleAvatar(
                        backgroundImage: AssetImage("assets/icon/Unknown.jpg"),
                      ),
                      title: Text(
                        contact["name"],
                        style: TextStyle(
                            fontSize: 16),
                      ),
                      onTap: () {
                        Get.off(
                            () => ChatMessageScreen(
                                  receiverId: contact['id'],
                                  receiverName: contact['name'],
                                ),
                            transition: Transition.rightToLeft);
                      },
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
