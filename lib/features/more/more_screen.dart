import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/game_controller.dart';
import '../../app/prefs.dart';
import '../../app/theme.dart';
import '../../core/strings.dart';
import '../common/widgets.dart';

/// "More" tab: accounts, settings, tutorial replay, privacy, reset.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider).value ?? const AppPrefs();
    final session = ref.watch(gameControllerProvider).requireValue;
    final notifier = ref.read(prefsProvider.notifier);
    final p = context.palette;

    Widget group(List<Widget> children) => Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, w) in children.indexed) ...[
            if (i > 0) const Divider(),
            w,
          ],
        ],
      ),
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20,
          AppSpacing.s16,
          AppSpacing.s20,
          AppSpacing.s32,
        ),
        children: [
          Text(S.moreTitle, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.s20),
          group([
            ListTile(
              leading: Icon(Icons.receipt_long_outlined, color: p.inkMuted),
              title: const Text(S.accounts),
              subtitle: const Text(S.accountsSubtitle),
              trailing: Icon(Icons.chevron_right, color: p.inkMuted),
              onTap: () => context.go('/more/wallet'),
            ),
            ListTile(
              leading: Icon(Icons.leaderboard_outlined, color: p.inkMuted),
              title: const Text(S.leaderboard),
              subtitle: const Text(S.leaderboardSubtitle),
              trailing: Icon(Icons.chevron_right, color: p.inkMuted),
              onTap: () => context.go('/more/leaderboard'),
            ),
            ListTile(
              leading: Icon(Icons.storefront_outlined, color: p.inkMuted),
              title: const Text(S.empireName),
              subtitle: Text(prefs.businessName ?? S.defaultName),
              trailing: Icon(Icons.edit_outlined, color: p.inkMuted),
              onTap: () => _editName(context, ref, prefs.businessName ?? ''),
            ),
          ]),
          const SizedBox(height: AppSpacing.s24),
          const SectionTitle(S.appearance),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text(S.themeDark),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text(S.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.phone_android),
                label: Text(S.themeSystem),
              ),
            ],
            selected: {prefs.themeMode},
            onSelectionChanged: (v) => notifier.setThemeMode(v.first),
          ),
          const SizedBox(height: AppSpacing.s24),
          group([
            SwitchListTile(
              secondary: Icon(Icons.volume_up_outlined, color: p.inkMuted),
              title: const Text(S.sound),
              subtitle: const Text(S.soundSubtitle),
              value: prefs.sound,
              onChanged: notifier.setSound,
            ),
            SwitchListTile(
              secondary: Icon(Icons.vibration, color: p.inkMuted),
              title: const Text(S.vibration),
              subtitle: const Text(S.vibrationSubtitle),
              value: prefs.haptics,
              onChanged: notifier.setHaptics,
            ),
            ListTile(
              leading: Icon(Icons.school_outlined, color: p.inkMuted),
              title: const Text(S.replayTutorial),
              onTap: () async {
                await notifier.setTutorialStep(Tutorial.work);
                if (context.mounted) {
                  context.go('/');
                }
              },
            ),
          ]),
          const SizedBox(height: AppSpacing.s24),
          group([
            ListTile(
              leading: Icon(Icons.lock_outline, color: p.inkMuted),
              title: const Text(S.privacy),
              subtitle: const Text(S.privacyBody),
            ),
            ListTile(
              leading: Icon(Icons.save_outlined, color: p.inkMuted),
              title: const Text(S.saveStatus),
              subtitle: Text(
                session.saveFailed
                    ? S.saveProblem
                    : S.saveOk(session.state.revision),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.s24),
          group([
            ListTile(
              leading: Icon(Icons.delete_outline, color: p.danger),
              title: Text(S.resetGame, style: TextStyle(color: p.danger)),
              subtitle: const Text(S.resetSubtitle),
              onTap: () => _confirmReset(context, ref),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(initial: current),
    );
    if (name != null && name.length >= 2) {
      await ref.read(prefsProvider.notifier).setBusinessName(name);
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final p = context.palette;
    Future<bool> ask(String title, String body, String action) async =>
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(S.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: p.danger,
                  foregroundColor: p.onDanger,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;

    if (!await ask(S.resetTitle, S.resetBody, S.reset) || !context.mounted) {
      return;
    }
    if (!await ask(S.resetAgainTitle, S.resetAgainBody, S.eraseEverything)) {
      return;
    }
    await ref.read(prefsProvider.notifier).setTutorialStep(Tutorial.work);
    await ref.read(gameControllerProvider.notifier).resetGame();
  }
}

/// Owns its text controller so it is disposed after the dialog closes.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(S.empireName),
    content: TextField(
      controller: _controller,
      maxLength: 30,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(S.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text.trim()),
        child: const Text(S.save),
      ),
    ],
  );
}
