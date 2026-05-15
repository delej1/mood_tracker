import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums/mood_type.dart';
import '../../domain/models/mood_entry.dart';
import '../../domain/repositories/mood_repository.dart';
import 'mood_state.dart';

/// Manages all mood-tracking business logic.

class MoodCubit extends Cubit<MoodState> {
  MoodCubit({required MoodRepository repository})
    : _repository = repository,
      super(const MoodState(isLoading: true));

  final MoodRepository _repository;
  final _uuid = const Uuid();

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Fetches the stored entries from the repository.
  /// Called once from the widget's [initState].
  Future<void> loadEntries() async {
    try {
      final entries = await _repository.getEntries();
      emit(state.copyWith(entries: entries, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: () => 'Could not load entries: $e',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Logging a mood
  // ---------------------------------------------------------------------------

  /// Creates a new [MoodEntry] for [mood], persists it, and refreshes the list.
  Future<void> logMood(MoodType mood) async {
    final entry = MoodEntry(
      id: _uuid.v4(),
      mood: mood,
      timestamp: DateTime.now(),
    );

    try {
      await _repository.saveEntry(entry);
      final updated = await _repository.getEntries();

      // Emit with justLogged = true to trigger the confirmation banner.
      emit(
        state.copyWith(entries: updated, justLogged: true, error: () => null),
      );

      // After 1.5 s, clear the confirmation banner.
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!isClosed) emit(state.copyWith(justLogged: false));
    } catch (e) {
      emit(state.copyWith(error: () => 'Could not save mood: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // Timeline entry selection
  // ---------------------------------------------------------------------------

  /// Marks [entry] as selected and triggers the pulse animation sequence.
  Future<void> selectEntry(MoodEntry entry) async {
    // Set selected + start animation flag.
    emit(state.copyWith(selectedEntry: () => entry, isAnimating: true));

    // The AnimationController in the widget watches isAnimating.
    // After the animation duration we reset, giving the widget time to
    // play the full forward + reverse pulse (~600 ms total).
    await Future.delayed(const Duration(milliseconds: 800));
    if (!isClosed) {
      emit(state.copyWith(isAnimating: false));
    }
  }

  /// Clears the selected entry (dismissing any overlay/modal).
  void clearSelection() {
    emit(state.copyWith(selectedEntry: () => null, isAnimating: false));
  }

  // ---------------------------------------------------------------------------
  // Utility
  // ---------------------------------------------------------------------------

  Future<void> clearAllEntries() async {
    await _repository.clearAll();
    emit(state.copyWith(entries: [], selectedEntry: () => null));
  }
}
