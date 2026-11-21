import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../data/local/save_repository.dart';

/// Shown when the game cannot load. A broken save is never wiped without
/// the player confirming.
class LoadErrorScreen extends ConsumerWidget {
  const LoadErrorScreen({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final corrupt = error is SaveCorruptException;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                corrupt ? 'Save parhi nahi ja saki' : 'Game load nahi hua',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                corrupt
                    ? 'Aap ki save aur dono backups kharab hain. Naya game shuru karne se purani progress khatam ho jayegi.'
                    : '$error',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              if (corrupt)
                FilledButton(
                  onPressed: () => _confirmReset(context, ref),
                  child: const Text('Naya game shuru karein'),
                )
              else
                FilledButton(
                  onPressed: () => ref.invalidate(gameControllerProvider),
                  child: const Text('Dobara koshish'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pakka?'),
        content: const Text('Saari progress mit jayegi. Ye wapas nahi hoga.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nahi')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Haan, naya game'),
          ),
        ],
      ),
    );
    if (ok ?? false) await ref.read(gameControllerProvider.notifier).resetGame();
  }
}
