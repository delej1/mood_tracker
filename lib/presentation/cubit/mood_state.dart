import 'package:equatable/equatable.dart';

import '../../domain/models/mood_entry.dart';

/// Represents every possible UI condition for the mood tracker screen.

class MoodState extends Equatable {
  const MoodState({
    this.entries = const [],
    this.selectedEntry,
    this.isAnimating = false,
    this.isLoading = false,
    this.justLogged = false,
    this.error,
  });

  /// The last 7 mood entries, newest first.
  final List<MoodEntry> entries;

  /// The timeline entry the user has tapped, or null when nothing is selected.
  final MoodEntry? selectedEntry;

  /// True for the duration of the face pulse animation on a selected entry.
  final bool isAnimating;

  /// True while the initial load from storage is in progress.
  final bool isLoading;

  /// True for a brief period after a new entry is logged — drives the
  /// "Mood logged ✓" confirmation message.
  final bool justLogged;

  /// Non-null when the last operation threw an error.
  final String? error;

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  MoodState copyWith({
    List<MoodEntry>? entries,
    MoodEntry? Function()? selectedEntry,
    bool? isAnimating,
    bool? isLoading,
    bool? justLogged,
    String? Function()? error,
  }) => MoodState(
    entries: entries ?? this.entries,
    // Using a function wrapper lets callers explicitly pass null to clear
    // the selected entry (selectedEntry: () => null).
    selectedEntry: selectedEntry != null ? selectedEntry() : this.selectedEntry,
    isAnimating: isAnimating ?? this.isAnimating,
    isLoading: isLoading ?? this.isLoading,
    justLogged: justLogged ?? this.justLogged,
    error: error != null ? error() : this.error,
  );

  // ---------------------------------------------------------------------------
  // Equatable
  // ---------------------------------------------------------------------------

  @override
  List<Object?> get props => [
    entries,
    selectedEntry,
    isAnimating,
    isLoading,
    justLogged,
    error,
  ];
}
