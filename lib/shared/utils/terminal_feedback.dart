import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TerminalFeedbackTone { info, success, warning, error }

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

  static void showMessage(
    BuildContext context,
    String message, {
    TerminalFeedbackTone tone = TerminalFeedbackTone.info,
  }) {
    final normalized = message.trim();
    if (normalized.isEmpty) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final colors = switch (tone) {
      TerminalFeedbackTone.info => const (
        background: Color(0xFF244A78),
        foreground: Colors.white,
        icon: Icons.info_outline_rounded,
      ),
      TerminalFeedbackTone.success => const (
        background: Color(0xFF1B6B3A),
        foreground: Colors.white,
        icon: Icons.check_circle_outline_rounded,
      ),
      TerminalFeedbackTone.warning => const (
        background: Color(0xFF8A5A00),
        foreground: Colors.white,
        icon: Icons.warning_amber_rounded,
      ),
      TerminalFeedbackTone.error => const (
        background: Color(0xFF9B1C1C),
        foreground: Colors.white,
        icon: Icons.error_outline_rounded,
      ),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          backgroundColor: colors.background,
          duration: Duration(
            milliseconds: tone == TerminalFeedbackTone.success ? 1200 : 2200,
          ),
          content: Row(
            children: <Widget>[
              Icon(colors.icon, color: colors.foreground, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  normalized,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
