
import 'package:chitchat/screen/chatScreen.dart';
import 'package:chitchat/screen/loginPage.dart';
import 'package:chitchat/screen/signup.dart';
import 'package:chitchat/screen/splashScreen.dart';
import 'package:chitchat/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
void main() async {
 WidgetsFlutterBinding.ensureInitialized();
 await initializeFirebase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightThemeData(context),
        darkTheme: darkThemeData(context),
        themeMode: ThemeMode.system,
        title: 'Chit Chat',
        home: chatScreen());
  }
}

initializeFirebase() async{
  await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
       );
}
