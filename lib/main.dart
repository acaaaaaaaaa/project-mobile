import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'services/backend_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS', defaultValue: true);
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'demo-focusroom');
  const appId = String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '1:1234567890:android:focusroomdemo');
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'demo-api-key');
  const senderId = String.fromEnvironment('FIREBASE_SENDER_ID', defaultValue: '1234567890');
  try {
    await Firebase.initializeApp(options: const FirebaseOptions(
      apiKey: apiKey, appId: appId, messagingSenderId: senderId, projectId: projectId,
    ));
    await BackendService.instance.initialize(useEmulators: useEmulators);
  } catch (error) {
    runApp(MaterialApp(home: Scaffold(body: Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Firebase belum terhubung: $error\n\nJalankan Firebase Emulator Suite, lalu buka aplikasi kembali.'),
    )))));
    return;
  }
  runApp(const FocusRoomApp());
}

class FocusRoomApp extends StatelessWidget {
  const FocusRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusRoom - Study Group Anti-Distraction',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1), // Indigo
          secondary: Color(0xFF06B6D4), // Cyan
          surface: Color(0xFF1E293B), // Slate 800
          error: Color(0xFFEF4444), // Red
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: false,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
