import 'package:equatable/equatable.dart';

import '../enums/mood_type.dart';

/// An immutable record of a single mood log event.
///
/// Stored as a JSON object in SharedPreferences:
/// ```json
/// { "id": "...", "mood": "happy", "timestamp": "2024-05-15T14:30:00.000Z" }
/// ```
class MoodEntry extends Equatable {
  const MoodEntry({
    required this.id,
    required this.mood,
    required this.timestamp,
  });

  final String id;
  final MoodType mood;
  final DateTime timestamp;

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
    'id': id,
    'mood': mood.toJson(),
    'timestamp': timestamp.toIso8601String(),
  };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
    id: json['id'] as String,
    mood: MoodType.fromJson(json['mood'] as String),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  // ---------------------------------------------------------------------------
  // Equatable
  // ---------------------------------------------------------------------------

  @override
  List<Object?> get props => [id, mood, timestamp];

  @override
  String toString() => 'MoodEntry(id: $id, mood: $mood, timestamp: $timestamp)';
}
