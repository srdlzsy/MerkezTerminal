import 'dart:async';

import 'package:flutter/material.dart';

typedef TerminalCreateSubmitHandler<TResult> =
    Future<bool> Function(TResult result);

abstract final class TerminalCreateSubmitScope {
  static Future<bool> submit<TResult>(
    BuildContext context,
    TResult result, {
    Future<void> Function()? prepare,
  }) async {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_TerminalCreateSubmitInherited>();
    if (scope == null) {
      await prepare?.call();
      if (!context.mounted) return false;
      Navigator.of(context).pop(result);
      return true;
    }
    return scope.submit(result, prepare);
  }
}

Future<TResult?> openTerminalCreatePage<TResult>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  TerminalCreateSubmitHandler<TResult>? onSubmit,
}) {
  return Navigator.of(context).push<TResult>(
    MaterialPageRoute<TResult>(
      fullscreenDialog: true,
      settings: RouteSettings(name: title),
      builder: (context) =>
          _TerminalCreatePage<TResult>(builder: builder, onSubmit: onSubmit),
    ),
  );
}

class _TerminalCreatePage<TResult> extends StatefulWidget {
  const _TerminalCreatePage({required this.builder, required this.onSubmit});

  final WidgetBuilder builder;
  final TerminalCreateSubmitHandler<TResult>? onSubmit;

  @override
  State<_TerminalCreatePage<TResult>> createState() =>
      _TerminalCreatePageState<TResult>();
}

class _TerminalCreatePageState<TResult>
    extends State<_TerminalCreatePage<TResult>> {
  bool _isSubmitting = false;
  _TerminalCreateSubmitPhase _submitPhase =
      _TerminalCreateSubmitPhase.preparing;
  Timer? _phaseTimer;

  @override
  void dispose() {
    _phaseTimer?.cancel();
    super.dispose();
  }

  Future<bool> _submit(Object? value, Future<void> Function()? prepare) async {
    final submit = widget.onSubmit;
    if (value is! TResult) {
      return false;
    }
    if (submit == null) {
      Navigator.of(context).pop(value);
      return true;
    }
    if (_isSubmitting) return false;

    _phaseTimer?.cancel();
    setState(() {
      _isSubmitting = true;
      _submitPhase = _TerminalCreateSubmitPhase.preparing;
    });
    try {
      await prepare?.call();
      if (!mounted) return false;
      setState(() => _submitPhase = _TerminalCreateSubmitPhase.sending);
      _phaseTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted || !_isSubmitting) return;
        setState(() => _submitPhase = _TerminalCreateSubmitPhase.checking);
      });
      final completed = await submit(value);
      if (!mounted) return completed;
      _phaseTimer?.cancel();
      if (completed) {
        Navigator.of(context).pop();
        return true;
      }
      setState(() => _isSubmitting = false);
      return false;
    } catch (error, stackTrace) {
      if (!mounted) return false;
      _phaseTimer?.cancel();
      debugPrint('Create page submit failed unexpectedly: $error');
      debugPrintStack(stackTrace: stackTrace);
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kayit tamamlanamadi. Bilgiler ekranda korunuyor. '
            'Baglantiyi kontrol edip Kaydet dugmesine yeniden basin.',
          ),
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope<TResult>(
      canPop: !_isSubmitting,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        body: Theme(
          data: theme.copyWith(
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              filled: true,
              fillColor: theme.colorScheme.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(120),
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          child: Stack(
            children: <Widget>[
              _TerminalCreateSubmitInherited(
                submit: _submit,
                child: IgnorePointer(
                  ignoring: _isSubmitting,
                  child: SafeArea(
                    top: true,
                    bottom: true,
                    child: Builder(builder: widget.builder),
                  ),
                ),
              ),
              if (_isSubmitting) ...<Widget>[
                const ModalBarrier(dismissible: false, color: Colors.black38),
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 310),
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(blurRadius: 18, color: Color(0x33000000)),
                      ],
                    ),
                    child: Row(
                      children: <Widget>[
                        const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _submitPhase.message,
                            key: const ValueKey<String>(
                              'terminal-create-submit-status',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _TerminalCreateSubmitPhase { preparing, sending, checking }

extension on _TerminalCreateSubmitPhase {
  String get message => switch (this) {
    _TerminalCreateSubmitPhase.preparing => 'Bilgiler hazirlaniyor...',
    _TerminalCreateSubmitPhase.sending => 'Sunucuya gonderiliyor...',
    _TerminalCreateSubmitPhase.checking =>
      'Mikro sonucu kontrol ediliyor. Bu ekran acik kalacak.',
  };
}

class _TerminalCreateSubmitInherited extends InheritedWidget {
  const _TerminalCreateSubmitInherited({
    required this.submit,
    required super.child,
  });

  final Future<bool> Function(Object? value, Future<void> Function()? prepare)
  submit;

  @override
  bool updateShouldNotify(_TerminalCreateSubmitInherited oldWidget) => false;
}
