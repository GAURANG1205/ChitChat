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
  final ContactRepository _contactRepository = ContactRepository();
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _contactRepository.contactsStream.listen((updatedContacts) {
      setState(() {
        _contacts = updatedContacts;
        _filterContacts();
      });
    });
    searchController.addListener(_filterContacts);
    _contactRepository.listenForNewRegisteredUsers();
  }

  void _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final contacts = await _contactRepository.getRegisteredContacts();
      setState(() {
        _contacts = contacts;
        _filterContacts();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterContacts() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = List.from(_contacts);
      } else {
        _filteredContacts = _contacts.where((contact) {
          final name = contact["name"].toString().toLowerCase();
          final phoneNumber = contact["phoneNumber"].toString().toLowerCase();
          return name.contains(query) || phoneNumber.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_filterContacts);
    searchController.dispose();
    _contactRepository.dispose();
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadContacts,
            tooltip: 'Refresh Contacts',
          ),
        ],
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
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    searchController.clear();
                  },
                  icon: Icon(Icons.close),
                )
                    : Icon(Icons.search),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Contacts on ChitChat",
                  style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode
                          ? Color.fromRGBO(145, 150, 154, 100)
                          : Color.fromRGBO(90, 91, 93, 100)),
                ),
                if (_filteredContacts.isNotEmpty)
                  Text(
                    "${_filteredContacts.length} contacts",
                    style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode
                            ? Color.fromRGBO(145, 150, 154, 100)
                            : Color.fromRGBO(90, 91, 93, 100)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Error: $_errorMessage"),
                  ElevatedButton(
                    onPressed: _loadContacts,
                    child: Text("Retry"),
                  ),
                ],
              ),
            )
                : _filteredContacts.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_search,
                    size: 48,
                    color: isDarkMode
                        ? Colors.white54
                        : Colors.black38,
                  ),
                  SizedBox(height: 16),
                  Text(
                    searchController.text.isEmpty
                        ? "No contacts found on ChitChat"
                        : "No matching contacts found",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundImage:
                    AssetImage("assets/icon/Unknown.jpg"),
                  ),
                  title: Text(
                    contact["name"],
                    style: TextStyle(fontSize: 16),
                  ),
                  subtitle: Text(
                    contact["phoneNumber"] ?? "",
                    style: TextStyle(fontSize: 12),
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
            ),
          )
        ],
      ),
    );
  }
}