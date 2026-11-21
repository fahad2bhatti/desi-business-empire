import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/prefs_repository.dart';
import 'game_controller.dart';

/// Tutorial steps, in order. Stored as an int so it survives restarts.
abstract final class Tutorial {
  static const welcome = 0;
  static const work = 1;
  static const buyBusiness = 2;
  static const upgrade = 3;
  static const done = 5;
}

class AppPrefs {
  const AppPrefs({
    this.businessName,
    this.tutorialStep = Tutorial.welcome,
    this.sound = true,
    this.haptics = true,
  });

  /// Chosen by the player on the welcome screen; `null` until then.
  final String? businessName;
  final int tutorialStep;
  final bool sound;
  final bool haptics;

  AppPrefs copyWith({
    String? businessName,
    int? tutorialStep,
    bool? sound,
    bool? haptics,
  }) => AppPrefs(
    businessName: businessName ?? this.businessName,
    tutorialStep: tutorialStep ?? this.tutorialStep,
    sound: sound ?? this.sound,
    haptics: haptics ?? this.haptics,
  );
}

final prefsRepositoryProvider = Provider<PrefsRepository>(
  (ref) => PrefsRepository(ref.watch(databaseProvider)),
);

final prefsProvider = AsyncNotifierProvider<PrefsController, AppPrefs>(
  PrefsController.new,
);

class PrefsController extends AsyncNotifier<AppPrefs> {
  static const _name = 'businessName';
  static const _tutorial = 'tutorialStep';
  static const _sound = 'sound';
  static const _haptics = 'haptics';

  @override
  Future<AppPrefs> build() async {
    final m = await ref.watch(prefsRepositoryProvider).loadAll();
    return AppPrefs(
      businessName: m[_name],
      tutorialStep: int.tryParse(m[_tutorial] ?? '') ?? Tutorial.welcome,
      sound: m[_sound] != 'false',
      haptics: m[_haptics] != 'false',
    );
  }

  Future<void> _save(String key, String value, AppPrefs next) async {
    await ref.read(prefsRepositoryProvider).set(key, value);
    state = AsyncData(next);
  }

  Future<void> setBusinessName(String name) =>
      _save(_name, name, state.requireValue.copyWith(businessName: name));

  Future<void> setTutorialStep(int step) => _save(
    _tutorial,
    '$step',
    state.requireValue.copyWith(tutorialStep: step),
  );

  Future<void> setSound(bool on) =>
      _save(_sound, '$on', state.requireValue.copyWith(sound: on));

  Future<void> setHaptics(bool on) =>
      _save(_haptics, '$on', state.requireValue.copyWith(haptics: on));
}
