import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/prefs.dart';
import '../../app/theme.dart';
import '../../core/strings.dart';
import '../common/visuals.dart';

/// First launch: what the game is, a name for the business, then the
/// guided first sale.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, required this.onDone});

  /// Called after the name is saved.
  final VoidCallback onDone;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _name = TextEditingController(text: S.defaultEmpireName);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _error {
    final n = _name.text.trim();
    if (n.length < 2) {
      return S.nameTooShort;
    }
    if (n.length > 30) {
      return S.nameTooLong;
    }
    return null;
  }

  Future<void> _start() async {
    if (_error != null || _saving) {
      return;
    }
    setState(() => _saving = true);
    final prefs = ref.read(prefsProvider.notifier);
    await prefs.setBusinessName(_name.text.trim());
    final step = ref.read(prefsProvider).requireValue.tutorialStep;
    if (step == Tutorial.welcome) {
      await prefs.setTutorialStep(Tutorial.work);
    }
    if (!mounted) {
      return;
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24,
            AppSpacing.s32,
            AppSpacing.s24,
            AppSpacing.s24,
          ),
          children: [
            const SizedBox(height: AppSpacing.s24),
            Row(
              children: [
                for (final (id, color) in [
                  ('samosa', p.street),
                  ('taxi', p.transport),
                  ('kiryana', p.shops),
                  ('factory', p.companies),
                ]) ...[
                  SignTile(icon: iconFor(id), artId: id, dot: color, size: 56),
                  const SizedBox(width: AppSpacing.s12),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(S.welcomeTitle, style: context.text.displaySmall),
            const SizedBox(height: AppSpacing.s12),
            Text(
              S.welcomeBody,
              style: context.text.bodyLarge?.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              S.notRealMoney,
              style: context.text.bodyMedium?.copyWith(color: p.inkMuted),
            ),
            const SizedBox(height: AppSpacing.s32),
            TextField(
              controller: _name,
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: S.businessNameLabel,
                helperText: S.businessNameHelp,
                errorText: _error,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _start(),
            ),
            const SizedBox(height: AppSpacing.s16),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _error == null && !_saving ? _start : null,
              child: const Text(S.start),
            ),
          ],
        ),
      ),
    );
  }
}
