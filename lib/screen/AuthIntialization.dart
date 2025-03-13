import 'package:chitchat/Data/Repository/template/service_locator.dart';
import 'package:chitchat/router/app_router.dart';
import 'package:chitchat/screen/HomeScreen.dart';
import 'package:chitchat/screen/LoginPageScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../Logic/AuthState.dart';
import '../Logic/cubitAuth.dart';

class AuthIntialization extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<cubitAuth, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          FlutterNativeSplash.remove();
          getit<AppRouter>().pushAndRemoveUntil(chatScreen());
        } else if (state.status == AuthStatus.unauthenticated) {
          FlutterNativeSplash.remove();
          getit<AppRouter>().pushAndRemoveUntil(loginPage());
        }
      },
      child: BlocBuilder<cubitAuth, AuthState>(
        builder: (context, state) {
          if (state.status == AuthStatus.loading) {
            return Container(); // Keep splash visible
          }

          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
