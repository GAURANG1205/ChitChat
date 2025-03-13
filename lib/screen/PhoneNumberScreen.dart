import 'package:chitchat/Comman/CustomTextField.dart';
import 'package:chitchat/Data/Repository/template/service_locator.dart';
import 'package:chitchat/Logic/cubitAuth.dart';
import 'package:flutter/material.dart';
import '../Data/Model/user_model.dart';
import '../Theme/colors.dart';

class phoneNumberScreen extends StatefulWidget {
  final UserModel userModel;

  phoneNumberScreen({required this.userModel});
  @override
  _phoneNumberScreenState createState() => _phoneNumberScreenState();
}

class _phoneNumberScreenState extends State<phoneNumberScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _phoneNumberFocus = FocusNode();
  final _formkey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneNumberFocus.dispose();
    super.dispose();
  }
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number (e.g., +1234567890)';
    }
    return null;
  }

  Future<void> _savePhoneNumber() async {
    FocusScope.of(context).unfocus();
    if(_formkey.currentState?.validate() ?? false) {
      String phoneNumber = _phoneController.text.trim();
      if (phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter a phone number")),
        );
        return;
      }
      try {
        await getit<cubitAuth>().updatePhoneNumber(
            widget.userModel.uid, phoneNumber);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Phone number updated successfully!")),
        );
        Navigator.pop(context,phoneNumber);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating phone number: $e")),
        );
      }
    }
    else{
      return;
    }
  }
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text("Enter Phone Number")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formkey,
              child: CustomTextField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                focusNode:_phoneNumberFocus,
                validator: _validatePhone,
                textEditingController: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePhoneNumber,
              child: Center(
                  child: Text(
                    'Login',
                    style: Theme.of(context)
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
          ],
        ),
      ),
    );
  }
}
