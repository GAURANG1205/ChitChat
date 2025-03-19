import 'colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightThemeData(BuildContext context) {
  return ThemeData.light().copyWith(
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: appBarTheme,
      iconTheme: const IconThemeData(color: kContentColorLightTheme),
      textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
          .apply(bodyColor: kContentColorDarkTheme),
      colorScheme: const ColorScheme.light(
        primary: kPrimaryColor,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: kContentColorLightTheme,
        indicatorColor: kPrimaryColor.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: kContentColorDarkTheme.withOpacity(0.7),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            );
          }
          return TextStyle(
            color: kContentColorDarkTheme.withOpacity(0.32),
            fontSize: 14,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (Set<WidgetState> states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? kPrimaryColor
                : kContentColorDarkTheme.withOpacity(0.32),
          );
        }),
      ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kContentColorDarkTheme,
        elevation:0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      )
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color:kContentColorDarkTheme)
      ),filled: true,
      fillColor: Colors.white,
  border: OutlineInputBorder(
  borderRadius: BorderRadius.circular(10),
  borderSide: BorderSide.none,
    )
  ));
}

ThemeData darkThemeData(BuildContext context) {
  return ThemeData.dark().copyWith(
    brightness: Brightness.dark,
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: kContentColorDarkTheme,
    appBarTheme: appBarTheme.copyWith(backgroundColor: kContentColorDarkTheme),
    iconTheme: const IconThemeData(color: kContentColorDarkTheme),
    textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
        .apply(bodyColor: kContentColorLightTheme),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: kPrimaryColor,
    ),
    navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: kContentColorDarkTheme,
        indicatorColor: kPrimaryColor.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: kContentColorLightTheme.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            );
          }
          return TextStyle(
            color: kContentColorLightTheme.withOpacity(0.32),

            fontSize: 14,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (Set<WidgetState> states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? kPrimaryColor
                : kContentColorLightTheme
                    .withOpacity(0.32),
          );
        })),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kContentColorLightTheme,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      )
    ),
      inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color:kContentColorLightTheme)
          ),filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          )
      )
  );
}

const appBarTheme = AppBarTheme(centerTitle: false, elevation: 0);
