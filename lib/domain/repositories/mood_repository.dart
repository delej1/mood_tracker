import '../models/mood_entry.dart';

/// Contract for mood persistence.

abstract class MoodRepository {
  /// Returns the most recent [limit] entries, newest first.
  /// Returns an empty list when no entries exist.
  Future<List<MoodEntry>> getEntries({int limit = 7});

  /// Persists a new [entry].
  /// Implementations should prepend and enforce a maximum stored count.
  Future<void> saveEntry(MoodEntry entry);

  /// Removes all stored entries. Useful for testing and a future "clear data" feature.
  Future<void> clearAll();
}
