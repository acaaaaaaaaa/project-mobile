import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
