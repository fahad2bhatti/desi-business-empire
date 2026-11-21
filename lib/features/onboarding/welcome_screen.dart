import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/prefs.dart';
import '../../app/theme.dart';

/// First launch: the fictional world, a name for the business, then the
/// guided first sale.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, required this.onDone});

  /// Called after the name is saved.
  final VoidCallback onDone;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _name = TextEditingController(text: 'Chaudhry Samosa Corner');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _error {
    final n = _name.text.trim();
    if (n.length < 2) {
      return 'Kam az kam 2 harf likhein';
    }
    if (n.length > 30) {
      return 'Zyada se zyada 30 harf';
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
      await prefs.setTutorialStep(Tutorial.buyStock);
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.amberLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.storefront,
                  size: 64,
                  color: AppColors.amberInk,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Desi Business Empire',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ek chhote se samosa stall se shuru karein. Saman lo, samosay banao, becho, '
              'aur staff rakh kar apna karobar barhao: takeaway, restaurant, aur ek din shaadi hall.',
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'Game ka paisa (virtual PKR) asli nahi. Na nikala ja sakta hai, na becha.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Aap ke karobar ka naam',
                helperText: 'Koi bhi naam rakhein. Baad mein Settings se badal sakte hain.',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _start(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _error == null && !_saving ? _start : null,
              child: const Text('Shuru karein'),
            ),
          ],
        ),
      ),
    );
  }
}
