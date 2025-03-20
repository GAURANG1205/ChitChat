
import 'package:chitchat/router/app_router.dart';
import 'package:chitchat/screen/ChatScreen.dart';
import 'package:chitchat/screen/LoginPageScreen.dart';
import 'package:chitchat/screen/SignUpScreen.dart';
import 'package:chitchat/screen/AuthIntialization.dart';
import 'package:chitchat/Theme/theme.dart';
import 'package:chitchat/Data/Repository/template/service_locator.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
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
    child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: getit<AppRouter>().navigatorKey,
        theme: lightThemeData(context),
        darkTheme: darkThemeData(context),
        themeMode: ThemeMode.system,
        title: 'Chit Chat',
        home: AuthIntialization()));
  }
}

