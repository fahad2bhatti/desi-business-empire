import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/strings.dart';
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
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                corrupt ? S.corruptTitle : S.loadFailedTitle,
                style: context.text.titleLarge,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                corrupt ? S.corruptBody : '$error',
                style: context.text.bodyMedium?.copyWith(
                  color: context.palette.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              FilledButton(
                onPressed: corrupt
                    ? () => _confirmReset(context, ref)
                    : () => ref.invalidate(gameControllerProvider),
                child: Text(corrupt ? S.startNewGame : S.tryAgain),
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
        title: const Text(S.sureTitle),
        content: const Text(S.sureBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(S.keepIt),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(S.eraseAndStart),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(gameControllerProvider.notifier).resetGame();
    }
  }
}
