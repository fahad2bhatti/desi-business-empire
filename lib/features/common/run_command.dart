import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/prefs.dart';
import '../../core/failure_text.dart';
import '../../core/strings.dart';
import '../../domain/economy/command_result.dart';
import '../../domain/economy/game_state.dart';

/// Runs one engine command and tells the player why it was refused.
/// Returns true when it succeeded.
Future<bool> runCommand(
  BuildContext context,
  WidgetRef ref,
  CommandResult Function(GameState s, DateTime now) command, {
  String? successText,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
  try {
    final failure = await ref
        .read(gameControllerProvider.notifier)
        .run(command);
    if (failure != null) {
      say(failureText(failure));
      return false;
    }
    if (ref.read(prefsProvider).value?.haptics ?? false) {
      HapticFeedback.selectionClick();
    }
    if (successText != null) {
      say(successText);
    }
    return true;
  } catch (_) {
    say(S.saveFailedToast);
    return false;
  }
}
