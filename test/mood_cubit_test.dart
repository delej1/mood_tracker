import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mood_tracker/domain/enums/mood_type.dart';
import 'package:mood_tracker/domain/models/mood_entry.dart';
import 'package:mood_tracker/domain/repositories/mood_repository.dart';
import 'package:mood_tracker/presentation/cubit/mood_cubit.dart';
import 'package:mood_tracker/presentation/cubit/mood_state.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockMoodRepository extends Mock implements MoodRepository {}

class FakeMoodEntry extends Fake implements MoodEntry {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MoodEntry _entry({MoodType mood = MoodType.happy}) => MoodEntry(
  id: 'test-id-${mood.name}',
  mood: mood,
  timestamp: DateTime(2024, 5, 15, 10, 30),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockMoodRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeMoodEntry());
  });

  setUp(() {
    repository = MockMoodRepository();
  });

  group('MoodCubit — loadEntries', () {
    blocTest<MoodCubit, MoodState>(
      'emits loaded entries on success',
      build: () {
        when(
          () => repository.getEntries(),
        ).thenAnswer((_) async => [_entry(mood: MoodType.happy)]);
        return MoodCubit(repository: repository);
      },
      act: (cubit) => cubit.loadEntries(),
      expect: () => [
        isA<MoodState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.entries.length, 'entries.length', 1)
            .having(
              (s) => s.entries.first.mood,
              'entries[0].mood',
              MoodType.happy,
            ),
      ],
    );

    blocTest<MoodCubit, MoodState>(
      'emits error state when repository throws',
      build: () {
        when(
          () => repository.getEntries(),
        ).thenThrow(Exception('storage unavailable'));
        return MoodCubit(repository: repository);
      },
      act: (cubit) => cubit.loadEntries(),
      expect: () => [
        isA<MoodState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.error, 'error', isNotNull),
      ],
    );
  });

  group('MoodCubit — logMood', () {
    blocTest<MoodCubit, MoodState>(
      'calls saveEntry and refreshes entries list',
      build: () {
        when(
          () => repository.getEntries(),
        ).thenAnswer((_) async => <MoodEntry>[]);
        when(() => repository.saveEntry(any())).thenAnswer((_) async {});
        // Second call to getEntries after save returns the new entry.
        int callCount = 0;
        when(() => repository.getEntries()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [];
          return [_entry(mood: MoodType.neutral)];
        });
        return MoodCubit(repository: repository);
      },
      act: (cubit) async {
        await cubit.loadEntries();
        await cubit.logMood(MoodType.neutral);
      },
      expect: () => [
        // After loadEntries — empty list, not loading.
        isA<MoodState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.entries, 'entries', isEmpty),
        // After logMood — new entry present, justLogged = true.
        isA<MoodState>()
            .having((s) => s.justLogged, 'justLogged', true)
            .having((s) => s.entries.length, 'entries.length', 1),
        // After 1.5 s — justLogged resets.
        isA<MoodState>().having((s) => s.justLogged, 'justLogged', false),
      ],
    );

    test('saveEntry is called with the correct mood type', () async {
      when(() => repository.getEntries()).thenAnswer((_) async => []);
      when(() => repository.saveEntry(any())).thenAnswer((_) async {});

      final cubit = MoodCubit(repository: repository);
      await cubit.logMood(MoodType.sad);

      final captured = verify(
        () => repository.saveEntry(captureAny()),
      ).captured;
      final saved = captured.first as MoodEntry;
      expect(saved.mood, MoodType.sad);
    });
  });

  group('MoodCubit — selectEntry / clearSelection', () {
    blocTest<MoodCubit, MoodState>(
      'selectEntry sets selectedEntry and isAnimating',
      build: () {
        when(() => repository.getEntries()).thenAnswer((_) async => []);
        return MoodCubit(repository: repository);
      },
      act: (cubit) => cubit.selectEntry(_entry()),
      expect: () => [
        // First emit: selected + animating.
        isA<MoodState>()
            .having((s) => s.selectedEntry, 'selectedEntry', isNotNull)
            .having((s) => s.isAnimating, 'isAnimating', true),
        // After 800 ms delay: isAnimating resets.
        isA<MoodState>()
            .having((s) => s.isAnimating, 'isAnimating', false)
            .having((s) => s.selectedEntry, 'selectedEntry', isNotNull),
      ],
    );

    blocTest<MoodCubit, MoodState>(
      'clearSelection nulls selectedEntry',
      build: () {
        when(() => repository.getEntries()).thenAnswer((_) async => []);
        return MoodCubit(repository: repository);
      },
      seed: () => MoodState(selectedEntry: _entry(), isAnimating: true),
      act: (cubit) => cubit.clearSelection(),
      expect: () => [
        isA<MoodState>()
            .having((s) => s.selectedEntry, 'selectedEntry', isNull)
            .having((s) => s.isAnimating, 'isAnimating', false),
      ],
    );
  });

  group('MoodCubit — clearAllEntries', () {
    blocTest<MoodCubit, MoodState>(
      'clears entries and calls repository.clearAll',
      build: () {
        when(() => repository.clearAll()).thenAnswer((_) async {});
        return MoodCubit(repository: repository);
      },
      seed: () => MoodState(entries: [_entry()]),
      act: (cubit) => cubit.clearAllEntries(),
      expect: () => [
        isA<MoodState>().having((s) => s.entries, 'entries', isEmpty),
      ],
      verify: (_) => verify(() => repository.clearAll()).called(1),
    );
  });
}
