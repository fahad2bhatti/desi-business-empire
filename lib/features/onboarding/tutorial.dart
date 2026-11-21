import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/prefs.dart';
import '../../app/theme.dart';
import '../../core/strings.dart';
import '../../domain/economy/game_state.dart';

/// Moves the tutorial forward when the player has done what the current
/// step asks. Never goes backwards, so a returning player skips what they
/// already did.
int advanceTutorial(int step, GameState s) {
  var next = step;
  if (next == Tutorial.work && (s.taps > 0 || s.businesses.isNotEmpty)) {
    next = Tutorial.buyBusiness;
  }
  if (next == Tutorial.buyBusiness && s.businesses.isNotEmpty) {
    next = Tutorial.upgrade;
  }
  if (next == Tutorial.upgrade &&
      s.businesses.values.any((level) => level >= 2)) {
    next = Tutorial.done;
  }
  return next;
}

/// The coach card for the current step, or nothing when the tutorial is
/// finished or not started.
class TutorialCoach extends ConsumerWidget {
  const TutorialCoach({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(prefsProvider).value?.tutorialStep ?? Tutorial.done;
    final (String title, String body) = switch (step) {
      Tutorial.work => (S.tutorialStep1, S.tutorialBody1),
      Tutorial.buyBusiness => (S.tutorialStep2, S.tutorialBody2),
      Tutorial.upgrade => (S.tutorialStep3, S.tutorialBody3),
      _ => ('', ''),
    };
    if (title.isEmpty) {
      return const SizedBox.shrink();
    }
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s12,
          AppSpacing.s8,
          AppSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: p.accentInk.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: p.accentInk, size: 20),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    title,
                    style: context.text.titleSmall?.copyWith(
                      color: p.accentInk,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s8),
              child: Text(body, style: context.text.bodyMedium),
            ),
            Row(
              children: [
                if (step == Tutorial.buyBusiness)
                  TextButton(
                    onPressed: () => context.go('/businesses'),
                    child: const Text(S.openBusinesses),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => ref
                      .read(prefsProvider.notifier)
                      .setTutorialStep(Tutorial.done),
                  style: TextButton.styleFrom(foregroundColor: p.inkMuted),
                  child: const Text(S.skipTutorial),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
