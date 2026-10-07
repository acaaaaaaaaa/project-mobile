import 'package:flutter/material.dart';
import 'active_session_screen.dart';

/// Wrapper compatibility untuk StudyRoomScreen yang mengarahkan ke ActiveSessionScreen desain baru
class StudyRoomScreen extends StatelessWidget {
  const StudyRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ActiveSessionScreen(
      totalMinutes: 45,
      roomTitle: 'Kerkom Algoritma Lanjut',
    );
  }
}
