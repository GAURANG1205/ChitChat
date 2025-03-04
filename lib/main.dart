
import 'package:chitchat/router/app_router.dart';
import 'package:chitchat/screen/chatScreen.dart';
import 'package:chitchat/screen/loginPage.dart';
import 'package:chitchat/screen/signup.dart';
import 'package:chitchat/screen/splashScreen.dart';
import 'package:chitchat/Theme/theme.dart';
import 'package:chitchat/Data/Repository/template/service_locator.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
void main() async {
 WidgetsFlutterBinding.ensureInitialized();
 await setupServiceLocator();
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
        navigatorKey: getit<AppRouter>().navigatorKey,
        theme: lightThemeData(context),
        darkTheme: darkThemeData(context),
        themeMode: ThemeMode.system,
        title: 'Chit Chat',
        home: loginPage());
  }
}

initializeFirebase() async{
  await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
       );
}
