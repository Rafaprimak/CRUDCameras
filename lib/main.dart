import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';  
import 'services/camera_group_service.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  
  await _initializeServices();
  runApp(const MyApp());
}

Future<void> _initializeServices() async {
  try {
    final groupService = CameraGroupService();
    await groupService.initialize();
  } catch (e) {
    print('Error initializing services: $e');
  }
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: customYellow,
          primary: customYellow, 
          brightness: Brightness.light,
        ),
        fontFamily: 'Karla',
        dialogBackgroundColor: Colors.white,
        dialogTheme: const DialogTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

