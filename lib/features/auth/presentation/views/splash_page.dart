import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/shared/widgets/furpa_brand.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFF6F8FC)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const FurpaBrandLockup(scale: 1.08, showCaption: true),
              const SizedBox(height: 20),
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 14),
              Text(
                'Furpa Merkez Terminal baslatiliyor...',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
