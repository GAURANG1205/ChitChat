import 'package:chitchat/Comman/CustomTextField.dart';
import 'package:chitchat/Comman/ScaffoldMessage.dart';
import 'package:chitchat/Data/Repository/authRepository.dart';
import 'package:chitchat/Data/Repository/template/service_locator.dart';
import 'package:chitchat/Logic/AuthState.dart';
import 'package:chitchat/Logic/cubitAuth.dart';
import 'package:chitchat/Theme/colors.dart';
import 'package:chitchat/screen/loginPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../router/app_router.dart';
import 'chatScreen.dart';

class signUp extends StatefulWidget {
  const signUp({super.key});

  @override
  State<signUp> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<signUp> {
  var showPassword = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _userNameFocus = FocusNode();
  final _phoneNumberFocus = FocusNode();
  final _formkey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _emailFocus.dispose();
    _phoneNumberFocus.dispose();
    _passwordFocus.dispose();
    _userNameFocus.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your username";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address (e.g., example@email.com)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number (e.g., +1234567890)';
    }
    return null;
  }

  Future<void> handleSignUp() async {
    FocusScope.of(context).unfocus();
    if (_formkey.currentState?.validate() ?? false) {
      try {
        await getit<cubitAuth>().signUp(
            username: userNameController.text,
            email: emailController.text,
            phoneNumber: phoneNumberController.text,
            password: passwordController.text);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } else {
      print("Form Validation Failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<cubitAuth, AuthState>(
      bloc: getit<cubitAuth>(),
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          getit<AppRouter>().pushAndRemoveUntil(chatScreen());
        } else if (state.status == AuthStatus.error && state.error != null) {
          ScaffoldMessage.showSnackBar(context, message: state.error!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              Container(
                width: mq.width,
                height: mq.height,
                color: !isDarkMode ? kPrimaryColor : kContentColorDarkTheme,
                child: Padding(
                  padding: EdgeInsets.only(top: mq.height * 0.06, left: 20),
                  child: Text(
                    'Sign Up\nCreate Your Account',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: kContentColorLightTheme,
                          fontWeight: FontWeight.bold,
                          fontSize: mq.width * 0.08,
                        ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                    top: mq.height * 0.18 < 0 ? 0 : mq.height * 0.18),
                child: Container(
                  width: mq.width,
                  height: mq.height * 0.8 < 0 ? 0 : mq.height * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color:
                        isDarkMode ? Colors.black45 : kContentColorLightTheme,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(top: 30, left: 16, right: 16),
                      child: Form(
                        key: _formkey,
                        child: Column(
                          children: [
                            CustomTextField(
                              textEditingController: userNameController,
                              validator: _validateUsername,
                              focusNode: _userNameFocus,
                              decoration: InputDecoration(
                                labelText: "Username",
                                suffixIcon: Icon(Icons.person_outline_rounded,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ),
                            SizedBox(height: 30), // Add spacing
                            CustomTextField(
                              textEditingController: emailController,
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              focusNode: _emailFocus,
                              decoration: InputDecoration(
                                labelText: "Email",
                                suffixIcon: Icon(Icons.email_outlined,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ),
                            const SizedBox(
                              height: 30,
                            ),
                            CustomTextField(
                              textEditingController: passwordController,
                              validator: _validatePassword,
                              obscureText: showPassword,
                              focusNode: _passwordFocus,
                              decoration: InputDecoration(
                                labelText: "Password",
                                suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        showPassword = !showPassword;
                                      });
                                    },
                                    icon: Icon(
                                      !showPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    )),
                              ),
                            ),
                            const SizedBox(height: 30),
                            CustomTextField(
                              textEditingController: phoneNumberController,
                              validator: _validatePhone,
                              keyboardType: TextInputType.phone,
                              focusNode: _phoneNumberFocus,
                              decoration: InputDecoration(
                                  labelText: "Phone Number",
                                  suffixIcon: Icon(
                                    Icons.phone,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  )),
                            ),
                            SizedBox(height: 24), // Add spacing
                            ElevatedButton(
                              onPressed: handleSignUp,
                              // Implement login action
                              child: state.status == AuthStatus.loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Center(
                                      child: Text(
                                      'Sign Up',
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
                            SizedBox(
                              height: mq.height * 0.03,
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                  color: isDarkMode
                                      ? kContentColorLightTheme
                                      : kPrimaryColor,
                                )),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  child: Text('Or SignUp with'),
                                ),
                                Expanded(
                                    child: Divider(
                                  color: isDarkMode
                                      ? kContentColorLightTheme
                                      : kPrimaryColor,
                                ))
                              ],
                            ),
                            SizedBox(
                              height:
                                  mq.height * 0.008 < 0 ? 0 : mq.height * 0.008,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                InkWell(
                                  splashColor:
                                      isDarkMode ? Colors.white : Colors.grey,
                                  onTap: () {},
                                  child: Image(
                                      width: 25,
                                      image: AssetImage(
                                        'assets/icon/google.png',
                                      )),
                                ),
                                InkWell(
                                  child: CircleAvatar(
                                      child: Image(
                                          width: 30,
                                          image: AssetImage(
                                            'assets/icon/facebook.png',
                                          )),
                                      backgroundColor: Colors.transparent),
                                )
                              ],
                            ),
                            SizedBox(
                              height: mq.height * 0.1 < 0 ? 0 : mq.height * 0.1,
                            ),
                            Align(
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text("Already Have A Account?"),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        "Login In",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                                color: kPrimaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                      ),
                                    )
                                  ]),
                              alignment: Alignment.bottomRight,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
