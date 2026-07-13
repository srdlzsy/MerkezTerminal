import 'package:flutter/services.dart';

abstract final class TerminalFeedback {
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await SystemSound.play(SystemSoundType.click);
  }

  static Future<void> warning() async {
    await HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.click);
  }

  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await SystemSound.play(SystemSoundType.alert);
  }
}
