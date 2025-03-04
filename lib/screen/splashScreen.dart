import 'package:chitchat/Data/Repository/template/service_locator.dart';
import 'package:chitchat/router/app_router.dart';
import 'package:chitchat/screen/chatScreen.dart';
import 'package:chitchat/screen/loginPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Logic/AuthState.dart';
import '../Logic/cubitAuth.dart';

class Splashscreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<cubitAuth, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          getit<AppRouter>().pushAndRemoveUntil(chatScreen());
        } else if (state.status == AuthStatus.unauthenticated) {
          getit<AppRouter>().pushAndRemoveUntil(loginPage());
        }
      },
      child: Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // Loading until auth state is checked
        ),
      ),
    );
  }
}
