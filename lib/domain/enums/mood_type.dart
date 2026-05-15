import 'package:flutter/material.dart';

/// The three supported mood expressions.

enum MoodType {
  happy,
  neutral,
  sad;

  /// Serialise to a plain string for JSON storage.
  String toJson() => name;

  /// De-serialise from the stored string.
  static MoodType fromJson(String value) =>
      MoodType.values.firstWhere((e) => e.name == value);
}

extension MoodTypeX on MoodType {
  String get label => switch (this) {
    MoodType.happy => 'Happy',
    MoodType.neutral => 'Neutral',
    MoodType.sad => 'Sad',
  };

  /// The accent colour used for the timeline card border and background tint.
  Color get accentColor => switch (this) {
    MoodType.happy => const Color(0xFFFFC107), // warm amber
    MoodType.neutral => const Color(0xFF90A4AE), // cool blue-grey
    MoodType.sad => const Color(0xFF7986CB), // soft indigo
  };

  /// A very light tint of the accent used for card backgrounds.
  Color get surfaceColor => switch (this) {
    MoodType.happy => const Color(0xFFFFF8E1),
    MoodType.neutral => const Color(0xFFECEFF1),
    MoodType.sad => const Color(0xFFE8EAF6),
  };

  /// The emoji used only for accessibility labels.
  String get semanticLabel => switch (this) {
    MoodType.happy => 'Happy face',
    MoodType.neutral => 'Neutral face',
    MoodType.sad => 'Sad face',
  };
}
