import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/enums/mood_type.dart';
import '../../domain/models/mood_entry.dart';
import '../cubit/mood_cubit.dart';
import '../cubit/mood_state.dart';
import '../widgets/mood_face_painter.dart';
import '../widgets/mood_picker.dart';
import '../widgets/timeline_card.dart';

/// The single screen of the mood tracker app.

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen>
    with SingleTickerProviderStateMixin {
  static const _contentMaxWidth = 820.0;
  static const _bannerSlotHeight = 44.0;

  // --------------------------------------------------------------------------
  // Animation
  // --------------------------------------------------------------------------

  /// Drives the face pulse when a timeline entry is tapped.
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  late final Animation<double> _pulseAnim = Tween<double>(
    begin: 1.0,
    end: 1.10,
  ).chain(CurveTween(curve: Curves.easeInOut)).animate(_pulseController);

  bool _isDetailSheetOpen = false;

  // --------------------------------------------------------------------------
  // Lifecycle
  // --------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // Load persisted entries once the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoodCubit>().loadEntries();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MoodCubit, MoodState>(
      listenWhen: (previous, current) =>
          previous.selectedEntry?.id != current.selectedEntry?.id &&
          current.selectedEntry != null,
      // ── Listener — one-shot side effects ──────────────────────────────────
      listener: (context, state) async {
        final entry = state.selectedEntry;
        final moodCubit = context.read<MoodCubit>();
        if (entry == null) return;

        await _pulseController.forward(from: 0);
        await _pulseController.reverse();

        if (!mounted) return;
        final selectedId = moodCubit.state.selectedEntry?.id;
        if (selectedId != entry.id) return;

        _showEntrySheet(entry, moodCubit);
      },
      // ── Builder — declarative UI ───────────────────────────────────────────
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F7F4),
          appBar: _buildAppBar(context),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, state),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // AppBar
  // --------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Mood Tracker',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: 0.3,
          color: Color(0xFF2D2D2D),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Color(0xFFBDBDBD)),
          tooltip: 'Clear all entries',
          onPressed: () => _confirmClear(context),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Body
  // --------------------------------------------------------------------------

  Widget _buildBody(BuildContext context, MoodState state) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MoodPicker(),
                      const SizedBox(height: 28),

                      // Reserve vertical space so the success banner does not
                      // visibly push the timeline up and down.
                      SizedBox(
                        height: _bannerSlotHeight,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: state.justLogged
                                ? _LoggedBanner(key: const ValueKey('logged'))
                                : const SizedBox.shrink(key: ValueKey('empty')),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),
                      _buildTimeline(context, state),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Timeline
  // --------------------------------------------------------------------------

  Widget _buildTimeline(BuildContext context, MoodState state) {
    if (state.entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Text(
          'Your mood history will appear here.\nTap a face above to log your first entry.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade500,
            height: 1.6,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Recent entries',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: state.entries.length,
            itemBuilder: (context, index) {
              final entry = state.entries[index];
              return TimelineCard(
                entry: entry,
                isSelected: state.selectedEntry?.id == entry.id,
                pulseAnimation:
                    state.selectedEntry?.id == entry.id && state.isAnimating
                    ? _pulseAnim
                    : null,
                onTap: () => context.read<MoodCubit>().selectEntry(entry),
              );
            },
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Entry bottom sheet
  // --------------------------------------------------------------------------

  void _showEntrySheet(MoodEntry entry, MoodCubit moodCubit) {
    if (_isDetailSheetOpen) return;

    _isDetailSheetOpen = true;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntryDetailSheet(entry: entry),
    ).then((_) {
      _isDetailSheetOpen = false;
      // Clear selection when the sheet is dismissed.
      if (mounted) moodCubit.clearSelection();
    });
  }

  // --------------------------------------------------------------------------
  // Clear confirmation
  // --------------------------------------------------------------------------

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all entries?'),
        content: const Text(
          'This will permanently delete all your mood history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MoodCubit>().clearAllEntries();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Subwidgets
// ============================================================================

/// Green "Mood logged ✓" confirmation banner.
class _LoggedBanner extends StatelessWidget {
  const _LoggedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF66BB6A), size: 16),
          SizedBox(width: 6),
          Text(
            'Mood logged',
            style: TextStyle(
              color: Color(0xFF388E3C),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Bottom sheet shown when the user taps a timeline entry.
class _EntryDetailSheet extends StatelessWidget {
  const _EntryDetailSheet({required this.entry});

  final MoodEntry entry;

  @override
  Widget build(BuildContext context) {
    final mood = entry.mood;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: mood.accentColor.withValues(alpha: 0.20),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle.
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mood.surfaceColor,
                border: Border.all(
                  color: mood.accentColor.withValues(alpha: 0.18),
                  width: 2,
                ),
              ),
              child: CustomPaint(
                size: const Size(132, 132),
                painter: MoodFacePainter(
                  mood: mood,
                  color: mood.accentColor,
                  strokeWidth: 4.0,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              mood.label,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: mood.accentColor,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: mood.surfaceColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _formatDateTime(entry.timestamp),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'This check-in is part of your latest 7 mood entries.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final date = '${_monthName(dt.month)} ${dt.day}, ${dt.year}';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$date at $hour:$minute $period';
  }

  String _monthName(int m) => const [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][m];
}
