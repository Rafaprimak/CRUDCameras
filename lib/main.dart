import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';  // Import firebase options
import 'services/camera_group_service.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with options
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
    // Keep your existing yellow but ensure consistent rendering
    final Color customYellow = const Color(0xFFffc112);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Camera Management',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: customYellow,
          primary: customYellow, // Explicitly set primary to avoid tint shifts
          brightness: Brightness.light,
        ),
        fontFamily: 'Karla',
        // Standard dialog theme
        dialogBackgroundColor: Colors.white,
        dialogTheme: const DialogTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white, // Important for Material 3
          elevation: 24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        // Alert dialog theme - using the correct property name
        // Note: DialogTheme controls both regular dialogs and alert dialogs
        // If you need specific alert dialog styling, use the proper widget properties when creating alerts
      ),
      home: const WelcomeScreen(),
    );
  }
}

