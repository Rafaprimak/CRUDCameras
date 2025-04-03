import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Camera Management',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Karla',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Karla'),
          displayMedium: TextStyle(fontFamily: 'Karla'),
          displaySmall: TextStyle(fontFamily: 'Karla'),
          headlineLarge: TextStyle(fontFamily: 'Karla'),
          headlineMedium: TextStyle(fontFamily: 'Karla'),
          headlineSmall: TextStyle(fontFamily: 'Karla'),
          titleLarge: TextStyle(fontFamily: 'Karla'),
          titleMedium: TextStyle(fontFamily: 'Karla'),
          titleSmall: TextStyle(fontFamily: 'Karla'),
          bodyLarge: TextStyle(fontFamily: 'Karla'),
          bodyMedium: TextStyle(fontFamily: 'Karla'),
          bodySmall: TextStyle(fontFamily: 'Karla'),
          labelLarge: TextStyle(fontFamily: 'Karla'),
          labelMedium: TextStyle(fontFamily: 'Karla'),
          labelSmall: TextStyle(fontFamily: 'Karla'),
        ),
        colorScheme: ColorScheme.light(
          primary: Colors.yellow,
          onPrimary: Colors.black,
          secondary: Colors.white,
          onSecondary: Colors.black,
          tertiary: Colors.black,
          onTertiary: Colors.white,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.yellow,
          foregroundColor: Colors.black,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.yellow,
          foregroundColor: Colors.black,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

