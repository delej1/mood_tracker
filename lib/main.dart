import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/repositories/local_mood_repository.dart';
import 'presentation/cubit/mood_cubit.dart';
import 'presentation/screens/mood_tracker_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoodTrackerApp());
}

class MoodTrackerApp extends StatelessWidget {
  const MoodTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MoodCubit(repository: LocalMoodRepository()),
      child: MaterialApp(
        title: 'Mood Tracker',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const MoodTrackerScreen(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF7986CB),
      scaffoldBackgroundColor: const Color(0xFFF8F7F4),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D2D2D),
        ),
        bodySmall: TextStyle(fontSize: 12, color: Color(0xFF757575)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
