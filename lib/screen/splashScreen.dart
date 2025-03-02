import 'package:chitchat/Theme/colors.dart';
import 'package:chitchat/screen/chatScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class splashScreen extends StatefulWidget {
  @override
  State<splashScreen> createState() {
    return splashScreenState();
  }
}

class splashScreenState extends State<splashScreen> {
  @override
  void initState(){
    super.initState();
     Future.delayed(const Duration(seconds: 1), () {
         Navigator.pushReplacement(
             context, MaterialPageRoute(builder: (context) => chatScreen()));
    });
  }
@override
  Widget build(context) {
    var size = MediaQuery.of(context).size;
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
            color:
                isDarkMode ? kContentColorDarkTheme : kContentColorLightTheme),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Image(
                  width: size.height * 0.4,
                  image: isDarkMode
                      ? AssetImage('assets/icon/splashDark.png')
                      : AssetImage('assets/icon/splashLight.png')),
              Text(
                "Chit Chat",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: isDarkMode
                        ? kContentColorLightTheme
                        : kPrimaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: size.width * 0.11),
              )
            ],
          ),
        ),
      ),
    );
  }
}
