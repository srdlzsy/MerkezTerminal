import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/shared/widgets/furpa_brand.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFF8FAFF)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const FurpaStartupLockup(markSize: 88),
              const SizedBox(height: 24),
              SizedBox(
                width: 112,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                  color: theme.colorScheme.primary,
                  backgroundColor: const Color(0xFFDDE2EE),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Uygulama hazirlaniyor...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: FurpaBrandColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
