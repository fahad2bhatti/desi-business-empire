import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/game_controller.dart';
import '../../app/prefs.dart';
import '../../app/theme.dart';

/// "Aur" tab: wallet, settings, tutorial replay, privacy, reset.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider).value ?? const AppPrefs();
    final session = ref.watch(gameControllerProvider).requireValue;
    final notifier = ref.read(prefsProvider.notifier);
    final starter = ref
        .read(gameControllerProvider.notifier)
        .engine
        .config
        .stages
        .first
        .id;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Aur',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Hisaab kitaab'),
            subtitle: const Text('Wallet aur aakhri len den'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/more/wallet'),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Karobar ka naam'),
            subtitle: Text(prefs.businessName ?? '-'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editName(context, ref, prefs.businessName ?? ''),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('Aawaz'),
            subtitle: const Text('Aawazein agle batch mein aayengi'),
            value: prefs.sound,
            onChanged: notifier.setSound,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Vibration'),
            subtitle: const Text('Kaam hone par halki vibration'),
            value: prefs.haptics,
            onChanged: notifier.setHaptics,
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('Tutorial dobara dekhein'),
            onTap: () async {
              await notifier.setTutorialStep(Tutorial.buyStock);
              if (context.mounted) {
                context.go('/business/$starter');
              }
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Privacy'),
            subtitle: Text(
              'Saara data sirf aap ke phone par hai. Koi account, ads ya tracking nahi.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.save_outlined),
            title: const Text('Save'),
            subtitle: Text(
              session.saveFailed
                  ? 'Save mein masla hai'
                  : 'Theek hai · revision ${session.state.revision}',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: AppColors.terra,
            ),
            title: const Text(
              'Game reset karein',
              style: TextStyle(color: AppColors.terra),
            ),
            subtitle: const Text('Saari progress mit jayegi'),
            onTap: () => _confirmReset(context, ref),
          ),
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
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game reset karein?'),
        content: const Text(
          'Paisa, karobar, staff aur upgrades sab mit jayenge. Ye wapas nahi hoga.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nahi'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.terra),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Haan, reset'),
          ),
        ],
      ),
    );
    if (!(first ?? false) || !context.mounted) {
      return;
    }
    final second = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aakhri dafa poochh rahe hain'),
        content: const Text('Pakka saari progress mitani hai?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nahi'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.terra),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mita do'),
          ),
        ],
      ),
    );
    if (second ?? false) {
      await ref.read(prefsProvider.notifier).setTutorialStep(Tutorial.buyStock);
      await ref.read(gameControllerProvider.notifier).resetGame();
    }
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
    title: const Text('Karobar ka naam'),
    content: TextField(
      controller: _controller,
      maxLength: 30,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Rehne dein'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text.trim()),
        child: const Text('Save'),
      ),
    ],
  );
}
