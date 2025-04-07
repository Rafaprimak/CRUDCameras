import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final Color customYellow = const Color(0xFFffc112);
    
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
          primary: customYellow,
          onPrimary: Colors.black,
          secondary: Colors.white,
          onSecondary: Colors.black,
          tertiary: Colors.black,
          onTertiary: Colors.white,
          surface: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: customYellow,
          foregroundColor: Colors.black,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: customYellow,
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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: customYellow, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          prefixIconColor: Colors.grey[600],
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

