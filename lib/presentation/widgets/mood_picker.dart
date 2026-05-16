import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/enums/mood_type.dart';
import '../cubit/mood_cubit.dart';
import '../cubit/mood_state.dart';
import 'mood_face_painter.dart';

/// Displays the three mood buttons in a horizontal row.
/// Tapping one calls [MoodCubit.logMood] and shows a selected ring.
class MoodPicker extends StatefulWidget {
  const MoodPicker({super.key});

  @override
  State<MoodPicker> createState() => _MoodPickerState();
}

class _MoodPickerState extends State<MoodPicker> {
  MoodType? _pressed; // tracks which button is in the "just tapped" state

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoodCubit, MoodState>(
      builder: (context, state) {
        return Column(
          children: [
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: MoodType.values.map((mood) {
                return _MoodButton(
                  mood: mood,
                  isPressed: _pressed == mood,
                  isLoading: state.isLoading,
                  onTap: () => _onMoodTapped(context, mood),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  void _onMoodTapped(BuildContext context, MoodType mood) {
    setState(() => _pressed = mood);
    context.read<MoodCubit>().logMood(mood);
    // Reset the pressed highlight after the feedback animation.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _pressed = null);
    });
  }
}

// ---------------------------------------------------------------------------

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.mood,
    required this.onTap,
    required this.isLoading,
    required this.isPressed,
  });

  final MoodType mood;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    const faceSize = 88.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: isLoading ? null : onTap,
            child: AnimatedScale(
              scale: isPressed ? 0.94 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: faceSize,
                height: faceSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mood.surfaceColor,
                  border: Border.all(color: mood.accentColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: mood.accentColor.withValues(alpha: 0.25),
                      blurRadius: isPressed ? 8 : 12,
                      spreadRadius: isPressed ? 1 : 2,
                    ),
                  ],
                ),
                child: Semantics(
                  label: 'Log ${mood.label} mood',
                  button: true,
                  child: CustomPaint(
                    size: const Size(faceSize, faceSize),
                    painter: MoodFacePainter(
                      mood: mood,
                      color: mood.accentColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mood.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: mood.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
