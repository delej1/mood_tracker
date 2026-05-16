import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/enums/mood_type.dart';
import '../../domain/models/mood_entry.dart';
import 'mood_face_painter.dart';

/// A single card in the horizontal timeline.
///
/// Shows:
///   • The date ("May 15") at the top
///   • A [CustomPaint] face in the centre
///   • The mood label below
///   • A coloured bottom accent bar
///
/// Tapping calls [onTap] which triggers [MoodCubit.selectEntry].
class TimelineCard extends StatelessWidget {
  const TimelineCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.isSelected = false,
    this.pulseAnimation,
  });

  final MoodEntry entry;
  final VoidCallback onTap;
  final bool isSelected;
  final Animation<double>? pulseAnimation;

  static const _cardWidth = 96.0;
  static const _faceSize = 52.0;
  static final _dateFormatter = DateFormat('MMM d');
  static final _timeFormatter = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final mood = entry.mood;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: _cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? mood.accentColor.withValues(alpha: 0.15)
              : mood.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: mood.accentColor.withValues(alpha: isSelected ? 0.9 : 0.35),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: mood.accentColor.withValues(
                alpha: isSelected ? 0.30 : 0.12,
              ),
              blurRadius: isSelected ? 14 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Date header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Column(
                  children: [
                    Text(
                      _dateFormatter.format(entry.timestamp),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: mood.accentColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      _timeFormatter.format(entry.timestamp),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: mood.accentColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Face ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Semantics(
                  label: mood.semanticLabel,
                  child: pulseAnimation == null
                      ? _buildFace(mood, 1.0)
                      : AnimatedBuilder(
                          animation: pulseAnimation!,
                          builder: (context, child) =>
                              _buildFace(mood, pulseAnimation!.value),
                        ),
                ),
              ),

              // ── Mood label ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  mood.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: mood.accentColor,
                  ),
                ),
              ),

              // ── Accent bar ───────────────────────────────────────────────
              Container(height: 4, color: mood.accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFace(MoodType mood, double pulseScale) {
    return CustomPaint(
      size: const Size(_faceSize, _faceSize),
      painter: MoodFacePainter(
        mood: mood,
        color: mood.accentColor,
        pulseScale: pulseScale,
        strokeWidth: 2.0,
      ),
    );
  }
}
