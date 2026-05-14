import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/core/config/app_config.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_blueprints.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';

class ModulePlaceholderPage extends StatelessWidget {
  const ModulePlaceholderPage({super.key, required this.menuEntry});

  final MenuEntry menuEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blueprint = MenuBlueprintRegistry.resolve(menuEntry);

    return Material(
      color: Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  theme.colorScheme.primary.withAlpha(215),
                  theme.colorScheme.secondary.withAlpha(215),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 14,
              children: <Widget>[
                Text(
                  menuEntry.displayModuleName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withAlpha(225),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  blueprint.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  blueprint.subtitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withAlpha(225),
                    height: 1.5,
                  ),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _HeaderPill(label: 'Module: ${menuEntry.moduleCode}'),
                    _HeaderPill(label: 'Menu: ${menuEntry.menuCode}'),
                    _HeaderPill(label: '${menuEntry.actions.length} action'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionCard(
            title: 'Yetki Aksiyonlari',
            subtitle:
                'Bu buton ve ekran izinleri GET /api/auth/me cevabindaki actions ile cizilmeli.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: menuEntry.actions.isEmpty
                  ? const <Widget>[Chip(label: Text('Action bulunamadi'))]
                  : menuEntry.actions
                        .map(
                          (action) => Chip(
                            avatar: const Icon(
                              Icons.verified_outlined,
                              size: 18,
                            ),
                            label: Text(action.name),
                          ),
                        )
                        .toList(growable: false),
            ),
          ),
          const SizedBox(height: 24),
          SectionCard(
            title: 'API Endpointleri',
            subtitle: 'Bu menu icin temel liste, detay ve islem url\'leri',
            child: Column(
              spacing: 14,
              children: blueprint.endpoints
                  .map((endpoint) => _EndpointTile(endpoint: endpoint))
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 24),
          SectionCard(
            title: 'UI Notlari',
            subtitle:
                'Dokumandaki davranis notlari bu ekranin is kurallarini yonlendirir.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 14,
              children: blueprint.uiNotes
                  .map((note) => _BulletText(note))
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 24),
          SectionCard(
            title: 'Entegrasyon Hatirlaticilari',
            subtitle: 'Tum moduller icin ortak teknik kurallar',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 14,
              children: <Widget>[
                _BulletText('Base URL: ${AppConfig.baseUrl}'),
                const _BulletText(
                  'Authorization basliginda Bearer token gonderilmeli.',
                ),
                const _BulletText(
                  'Hatalar application/problem+json formatinda ele alinmali.',
                ),
                const _BulletText(
                  'Tarih alanlari ISO 8601 oldugu icin request ve response parserlari ayni standardi kullanmali.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EndpointTile extends StatelessWidget {
  const _EndpointTile({required this.endpoint});

  final EndpointSpec endpoint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(96),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _methodColor(theme, endpoint.method).withAlpha(32),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  endpoint.method,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: _methodColor(theme, endpoint.method),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  endpoint.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SelectableText(
            endpoint.path,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _methodColor(ThemeData theme, String method) {
    return switch (method) {
      'GET' => theme.colorScheme.secondary,
      'POST' => theme.colorScheme.primary,
      'PUT' => const Color(0xFF2754C5),
      'DELETE' => const Color(0xFFB3261E),
      _ => theme.colorScheme.tertiary,
    };
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(38)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 8, right: 10),
          height: 7,
          width: 7,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
