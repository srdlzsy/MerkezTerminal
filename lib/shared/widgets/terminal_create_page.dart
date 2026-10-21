import 'package:flutter/material.dart';

typedef TerminalCreateSubmitHandler<TResult> =
    Future<bool> Function(TResult result);

abstract final class TerminalCreateSubmitScope {
  static Future<bool> submit<TResult>(
    BuildContext context,
    TResult result,
  ) async {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_TerminalCreateSubmitInherited>();
    if (scope == null) {
      Navigator.of(context).pop(result);
      return true;
    }
    return scope.submit(result);
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

  Future<bool> _submit(Object? value) async {
    final submit = widget.onSubmit;
    if (value is! TResult) {
      return false;
    }
    if (submit == null) {
      Navigator.of(context).pop(value);
      return true;
    }
    if (_isSubmitting) return false;

    setState(() => _isSubmitting = true);
    try {
      final completed = await submit(value);
      if (!mounted) return completed;
      if (completed) {
        Navigator.of(context).pop();
        return true;
      }
      setState(() => _isSubmitting = false);
      return false;
    } catch (error, stackTrace) {
      if (!mounted) return false;
      debugPrint('Create page submit failed unexpectedly: $error');
      debugPrintStack(stackTrace: stackTrace);
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Islem sonucu ekranda tamamlanamadi. Ayni kaydi yeniden '
            'gondermeden once listeyi yenileyin.',
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
                    child: const Row(
                      children: <Widget>[
                        SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Kayit yapiliyor. Sonuc kesinlesene kadar bu ekran acik kalacak.',
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

class _TerminalCreateSubmitInherited extends InheritedWidget {
  const _TerminalCreateSubmitInherited({
    required this.submit,
    required super.child,
  });

  final Future<bool> Function(Object? value) submit;

  @override
  bool updateShouldNotify(_TerminalCreateSubmitInherited oldWidget) => false;
}
