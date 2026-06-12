import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';

class ModulePlaceholderPage extends StatelessWidget {
  const ModulePlaceholderPage({super.key, required this.menuEntry});

  final MenuEntry menuEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withAlpha(88),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  menuEntry.displayModuleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  menuEntry.displayMenuName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bu ekran terminal uygulamasinda henuz hazir degil.',
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Ekran Durumu',
            subtitle: 'Menu gorunur, ancak ekran baglantisi tamamlanmadi.',
            child: Text(
              'Isleme devam etmek icin soldaki menuden baska bir ekran secin. '
              'Bu ekrana ihtiyaciniz varsa sistem yoneticinize bildirin.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Yetkiler',
            subtitle: 'Bu menu icin tanimli kullanici yetkileri.',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: menuEntry.actions.isEmpty
                  ? const <Widget>[Chip(label: Text('Yetki bulunamadi'))]
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
        ],
      ),
    );
  }
}
