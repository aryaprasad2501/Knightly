import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// The few interface sounds Knightly makes. Each theme has its own set
/// (`assets/sounds/dk|sc/<name>.ogg`, Kenney "Interface Sounds", CC0).
enum KSound { tab, tap, confirm, toggle }

/// Plays interface sounds. Quiet, short and off unless the app switches it
/// on ([configure]); widget code just calls [play]. Failures (no audio
/// device, tests) are ignored: a missing click never breaks anything.
abstract final class KSounds {
  static bool _enabled = false;
  static String _set = 'dk';
  static final Map<String, AudioPlayer> _players = {};

  /// Called by the app whenever the setting or the theme changes.
  static void configure({required bool enabled, required bool tactical}) {
    _enabled = enabled;
    final set = tactical ? 'dk' : 'sc';
    if (set != _set) {
      _set = set;
      _disposeAll();
    }
  }

  static void play(KSound sound) {
    if (!_enabled) return;
    final key = '$_set/${sound.name}';
    () async {
      try {
        var player = _players[key];
        if (player == null) {
          player = AudioPlayer();
          _players[key] = player;
          await player.setAsset('assets/sounds/$key.ogg');
          await player.setVolume(0.45);
        }
        await player.seek(Duration.zero);
        await player.play();
      } on Object catch (e) {
        debugPrint('Knightly: sound $key unavailable: $e');
      }
    }();
  }

  static void _disposeAll() {
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
  }
}
