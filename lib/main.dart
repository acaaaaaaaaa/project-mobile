import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    // Inisialisasi Firebase dengan kredensial dari google-services.json & Realtime Database URL
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBxC0rck6OtS9zW6k4YZbuzu5c_lovATUI',
        appId: '1:834453228503:android:0410d8cc2ef8bdbfa91992',
        messagingSenderId: '834453228503',
        projectId: 'kerkom-project',
        databaseURL: 'https://kerkom-project-default-rtdb.asia-southeast1.firebasedatabase.app/',
      ),
    );

    // Hubungkan instance Firebase Realtime Database asia-southeast1
    await FirebaseRealtimeService.instance.initialize();
  } catch (error) {
    debugPrint('Inisialisasi Firebase Realtime Database info: $error');
  }

  runApp(const FocusRoomApp());
}

class FocusRoomApp extends StatelessWidget {
  const FocusRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyPact - Focus & Study Group Anti-Distraction',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
