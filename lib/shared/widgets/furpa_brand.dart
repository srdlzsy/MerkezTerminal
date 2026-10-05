import 'package:flutter/material.dart';

abstract final class FurpaBrandColors {
  static const Color navy = Color(0xFF22356A);
  static const Color yellow = Color(0xFFF4CC35);
  static const Color canvas = Color(0xFFF4F6FA);
  static const Color ink = Color(0xFF17213B);
  static const Color muted = Color(0xFF5E6883);
}

abstract final class FurpaBrandAssets {
  static const String logo = 'assets/branding/furpa logo.png';
  static const String appIcon = 'assets/branding/furpa_92x92.png';
}

class FurpaStartupLockup extends StatelessWidget {
  const FurpaStartupLockup({
    super.key,
    this.markSize = 82,
    this.showProductName = true,
  });

  final double markSize;
  final bool showProductName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Furpa Merkez Terminal',
      image: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FurpaStartupMark(size: markSize),
          const SizedBox(height: 14),
          Text(
            'FURPA',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: FurpaBrandColors.navy,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          if (showProductName) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              'MERKEZ TERMINAL',
              style: theme.textTheme.labelMedium?.copyWith(
                color: FurpaBrandColors.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FurpaStartupMark extends StatelessWidget {
  const FurpaStartupMark({super.key, this.size = 82});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: const _FurpaOfficialMarkPainter()),
    );
  }
}

class _FurpaOfficialMarkPainter extends CustomPainter {
  const _FurpaOfficialMarkPainter();

  static const Color _yellow = Color(0xFFF9FC18);
  static const Color _purple = Color(0xFF210DA0);

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 108;
    final scaleY = size.height / 108;
    canvas.scale(scaleX, scaleY);

    canvas.drawCircle(const Offset(54, 54), 54, Paint()..color = _yellow);

    final letterPaint = Paint()..color = _purple;
    canvas
      ..drawRect(const Rect.fromLTWH(30, 18, 18, 72), letterPaint)
      ..drawRect(const Rect.fromLTWH(48, 18, 36, 18), letterPaint)
      ..drawRect(const Rect.fromLTWH(48, 48, 26, 16), letterPaint);
  }

  @override
  bool shouldRepaint(covariant _FurpaOfficialMarkPainter oldDelegate) => false;
}

class FurpaBrandLockup extends StatelessWidget {
  const FurpaBrandLockup({
    super.key,
    this.scale = 1,
    this.enclosed = false,
    this.showCaption = false,
  });

  final double scale;
  final bool enclosed;
  final bool showCaption;

  @override
  Widget build(BuildContext context) {
    final logoWidth = 182.0 * scale;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FurpaBrandMark(width: logoWidth),
        if (showCaption)
          Padding(
            padding: EdgeInsets.only(top: 10 * scale),
            child: Text(
              'Merkez Terminal',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: FurpaBrandColors.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
      ],
    );

    if (!enclosed) {
      return content;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: FurpaBrandColors.navy.withAlpha(18)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: FurpaBrandColors.navy.withAlpha(14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: content,
    );
  }
}

class FurpaBrandMark extends StatelessWidget {
  const FurpaBrandMark({super.key, this.width = 172});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      FurpaBrandAssets.logo,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: width * 0.28,
          alignment: Alignment.centerLeft,
          child: Text(
            'FURPA',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: FurpaBrandColors.navy,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        );
      },
    );
  }
}
