
import 'package:chitchat/router/app_router.dart';
import 'package:chitchat/screen/chatScreen.dart';
import 'package:chitchat/screen/loginPage.dart';
import 'package:chitchat/screen/signup.dart';
import 'package:chitchat/screen/AuthIntialization.dart';
import 'package:chitchat/Theme/theme.dart';
import 'package:chitchat/Data/Repository/template/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'Logic/cubitAuth.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
void main() async {
  final WidgetsBinding widgetsBinding = await WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await setupServiceLocator();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
        BlocProvider<cubitAuth>(
        create: (context) => getit<cubitAuth>(),
    ),
    ],
    child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: getit<AppRouter>().navigatorKey,
        theme: lightThemeData(context),
        darkTheme: darkThemeData(context),
        themeMode: ThemeMode.system,
        title: 'Chit Chat',
        home: Authintialization()));
  }
}

