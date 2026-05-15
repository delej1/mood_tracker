import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/mood_entry.dart';
import '../../domain/repositories/mood_repository.dart';

/// [MoodRepository] backed by [SharedPreferences].
///
/// Storage format:
///   Key   → `mood_entries`
///   Value → JSON-encoded `List<Map<String, dynamic>>`

class LocalMoodRepository implements MoodRepository {
  static const _storageKey = 'mood_entries';

  /// Maximum number of entries ever written to storage.
  /// Only the 7 most recent are surfaced to the UI, but we keep 50 so a user
  /// who clears and re-adds can still see meaningful history.
  static const _maxStoredEntries = 50;

  // ---------------------------------------------------------------------------
  // MoodRepository interface
  // ---------------------------------------------------------------------------

  @override
  Future<List<MoodEntry>> getEntries({int limit = 7}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null) return [];

    final decoded = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(MoodEntry.fromJson)
        .toList();

    // Entries are stored newest-first; just clamp to the requested limit.
    return decoded.take(limit).toList();
  }

  @override
  Future<void> saveEntry(MoodEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    final existing = raw != null
        ? (jsonDecode(raw) as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map(MoodEntry.fromJson)
              .toList()
        : <MoodEntry>[];

    // Prepend newest entry and enforce the cap.
    final updated = [entry, ...existing].take(_maxStoredEntries).toList();

    await prefs.setString(
      _storageKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
