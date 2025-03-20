import 'dart:io';
import 'package:chitchat/Comman/ScaffoldMessage.dart';
import 'package:chitchat/screen/LoginPageScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chitchat/Data/Repository/CludinaryService.dart';

import '../Data/Repository/template/service_locator.dart';
import '../Logic/cubitAuth.dart';
import '../Theme/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  String? _profileImageUrl;
  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<Map<String, dynamic>?> _loadUserProfile() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc =
      await FirebaseFirestore.instance.collection("users").doc(uid).get();
      return userDoc.data();
    } catch (e) {
      print("Error loading profile: $e");
      return null;
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    bool hasPermission = await _requestPermission(source);
    if (!hasPermission) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;
      Navigator.pop(context);
      File selectedImage = File(pickedFile.path);
      if (!await selectedImage.exists()) return;

      setState(() {
        _image = selectedImage;
        _isUploading = true;
      });

      String? imageUrl = await _cloudinaryService.uploadImage(_image!);
      if (imageUrl != null) {
        await _updateUserProfile(imageUrl);
      }
    } catch (e) {
      print("Error selecting/uploading image: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<bool> _requestPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      return await Permission.camera.request().isGranted;
    } else {
      return await Permission.photos.request().isGranted ||
          await Permission.storage.request().isGranted;
    }
  }

  Future<void> _updateUserProfile(String? imageUrl) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      Map<String, dynamic> updates = {};
      if (imageUrl != null) updates["profileImage"] = imageUrl;
      if (_nameController.text.isNotEmpty)
        updates["username"] = _nameController.text;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update(updates);
      setState(() => _profileImageUrl = imageUrl);
      ScaffoldMessage.showSnackBar(context, message: "Profile Updated");
    } catch (e) {
      print("Error updating profile: $e");
    }
  }

  void _logout() async {
    await getit<cubitAuth>().signOut();
    Get.offAll(() => loginPage());
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Photo"),
              onTap: () => _pickAndUploadImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () => _pickAndUploadImage(ImageSource.gallery),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness==Brightness.dark;
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future:  _loadUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text("Failed to load profile"));
          }

          final userData = snapshot.data!;
          _profileImageUrl = userData["profileImage"];
          _nameController.text = userData['username'] ?? '';
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _profileImageUrl?.isNotEmpty == true
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage("assets/icon/Unknown.jpg")
                        as ImageProvider,
                      ),
                      if (_isUploading)
                        const Positioned.fill(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImagePickerOptions,
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.camera_alt, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _updateUserProfile(_profileImageUrl),
                  child: Center(
                      child: Text(
                        'Update',
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(
                          color: isDarkMode
                              ? kContentColorDarkTheme
                              : kContentColorLightTheme,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _logout,
                  child: const Text(
                      "Logout", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }),
    );
  }
}
