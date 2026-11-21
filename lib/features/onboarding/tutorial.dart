import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/prefs.dart';
import '../../app/theme.dart';
import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_state.dart';

/// Moves the tutorial forward when the player has done what the current
/// step asks. Never goes backwards, so a returning player skips what they
/// already did.
int advanceTutorial(int step, GameState s, String starterId) {
  final st = s.stages[starterId];
  if (st == null) {
    return step;
  }
  final lines = st.lines.values;
  final cookedOrSold =
      st.sold > 0 || lines.any((l) => l.isCooking || l.ready > 0);
  var next = step;
  if (next == Tutorial.buyStock &&
      (cookedOrSold || lines.any((l) => l.stock > 0))) {
    next = Tutorial.cook;
  }
  if (next == Tutorial.cook && cookedOrSold) {
    next = Tutorial.sell;
  }
  if (next == Tutorial.sell && st.sold > 0) {
    next = Tutorial.hireHelper;
  }
  if (next == Tutorial.hireHelper && st.staffCount(StaffRole.helper) > 0) {
    next = Tutorial.done;
  }
  return next;
}

/// The coach card for the current step, or nothing when the tutorial is
/// finished or not started.
class TutorialCoach extends ConsumerWidget {
  const TutorialCoach({super.key, required this.starterId});

  final String starterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(prefsProvider).value?.tutorialStep ?? Tutorial.done;
    final (String title, String body) = switch (step) {
      Tutorial.buyStock => (
        'Qadam 1/4: Saman lo',
        'Samosay banane ke liye saman chahiye. Samosa card par "Saman +10" dabayein.',
      ),
      Tutorial.cook => (
        'Qadam 2/4: Samosay banao',
        '"Banao" dabayein. Kadhai 30 sec mein samosay tayyar karegi.',
      ),
      Tutorial.sell => (
        'Qadam 3/4: Pehli bikri',
        'Samosay tayyar hon aur customer intezaar mein ho to "Becho" dabayein. Har samosa Rs 30 ka.',
      ),
      Tutorial.hireHelper => (
        'Qadam 4/4: Pehla Helper',
        'Staff mein Helper (Chhotu) rakhein. Wo customers khud serve karega.',
      ),
      _ => ('', ''),
    };
    if (title.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.amber, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            children: [
              if (step == Tutorial.hireHelper)
                FilledButton(
                  onPressed: () => context.go('/business/$starterId/staff'),
                  child: const Text('Staff kholo'),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => ref
                    .read(prefsProvider.notifier)
                    .setTutorialStep(Tutorial.done),
                child: const Text('Tutorial chhor dein'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
