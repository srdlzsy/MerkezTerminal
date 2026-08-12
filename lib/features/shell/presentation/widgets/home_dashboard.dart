import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.user,
    required this.menus,
    required this.onSelectMenu,
    this.offlineQueueCount = 0,
    this.offlineFailedCount = 0,
  });

  final CurrentUser user;
  final List<MenuEntry> menus;
  final ValueChanged<MenuEntry> onSelectMenu;
  final int offlineQueueCount;
  final int offlineFailedCount;

  @override
  Widget build(BuildContext context) {
    final menuGroups = _groupMenusByModule(menus);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      children: <Widget>[
        _UserSummary(
          user: user,
          offlineQueueCount: offlineQueueCount,
          offlineFailedCount: offlineFailedCount,
        ),
        const SizedBox(height: 8),
        SectionCard(
          title: 'Tum Menuler',
          subtitle: menus.isEmpty
              ? 'Kullaniciya atanmis menu bulunamadi.'
              : '${menus.length} ekran kullanima hazir',
          child: menus.isEmpty
              ? const _DashboardEmptyState()
              : Column(
                  children: <Widget>[
                    for (var index = 0; index < menuGroups.length; index += 1)
                      Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
                        child: _MenuModuleGroup(
                          group: menuGroups[index],
                          onSelectMenu: onSelectMenu,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  List<_MenuModuleGroupData> _groupMenusByModule(List<MenuEntry> menus) {
    final groups = <_MenuModuleGroupData>[];
    for (final menu in menus) {
      final existingIndex = groups.indexWhere(
        (group) => group.moduleCode == menu.moduleCode,
      );
      if (existingIndex == -1) {
        groups.add(
          _MenuModuleGroupData(
            moduleCode: menu.moduleCode,
            moduleName: menu.displayModuleName,
            menus: <MenuEntry>[menu],
          ),
        );
        continue;
      }

      groups[existingIndex].menus.add(menu);
    }

    return groups;
  }
}

class _UserSummary extends StatelessWidget {
  const _UserSummary({
    required this.user,
    required this.offlineQueueCount,
    required this.offlineFailedCount,
  });

  final CurrentUser user;
  final int offlineQueueCount;
  final int offlineFailedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;

        return Container(
          padding: EdgeInsets.all(isCompact ? 8 : 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Depo ${user.warehouseNo} - ${user.warehouseName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white.withAlpha(215),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Islem yapmak icin asagidaki menu listesinden bir ekran secin.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withAlpha(205),
                  height: 1.2,
                ),
              ),
              if (offlineQueueCount > 0) ...<Widget>[
                const SizedBox(height: 7),
                _OfflineStatusPill(
                  offlineQueueCount: offlineQueueCount,
                  offlineFailedCount: offlineFailedCount,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OfflineStatusPill extends StatelessWidget {
  const _OfflineStatusPill({
    required this.offlineQueueCount,
    required this.offlineFailedCount,
  });

  final int offlineQueueCount;
  final int offlineFailedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = offlineFailedCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withAlpha(36)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            hasError
                ? Icons.error_outline_rounded
                : Icons.cloud_upload_outlined,
            color: Colors.white,
            size: 17,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hasError
                  ? '$offlineQueueCount offline kayit, $offlineFailedCount hata'
                  : '$offlineQueueCount offline kayit senkron bekliyor',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuModuleGroupData {
  _MenuModuleGroupData({
    required this.moduleCode,
    required this.moduleName,
    required this.menus,
  });

  final String moduleCode;
  final String moduleName;
  final List<MenuEntry> menus;
}

class _MenuModuleGroup extends StatelessWidget {
  const _MenuModuleGroup({required this.group, required this.onSelectMenu});

  final _MenuModuleGroupData group;
  final ValueChanged<MenuEntry> onSelectMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _moduleColor(group.moduleCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 5),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(13),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                _moduleIcon(group.moduleCode, group.moduleName),
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  group.moduleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(200),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${group.menus.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        for (var index = 0; index < group.menus.length; index += 1)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 4),
            child: _PdaMenuTile(
              moduleColor: iconColor,
              menu: group.menus[index],
              onTap: () => onSelectMenu(group.menus[index]),
            ),
          ),
      ],
    );
  }
}

class _PdaMenuTile extends StatelessWidget {
  const _PdaMenuTile({
    required this.moduleColor,
    required this.menu,
    required this.onTap,
  });

  final Color moduleColor;
  final MenuEntry menu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 48,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(85),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: <Widget>[
                Container(
                  width: 31,
                  height: 31,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: moduleColor.withAlpha(18),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(_menuIcon(menu), size: 18, color: moduleColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    menu.displayMenuName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _moduleIcon(String moduleCode, String moduleName) {
  final key = _normalizedMenuKey('$moduleCode $moduleName');

  if (key.contains('siparis')) {
    return Icons.assignment_outlined;
  }
  if (key.contains('sevk')) {
    return Icons.local_shipping_outlined;
  }
  if (key.contains('mal kabul')) {
    return Icons.inventory_2_outlined;
  }
  if (key.contains('stok')) {
    return Icons.warehouse_outlined;
  }
  if (key.contains('iade')) {
    return Icons.assignment_return_outlined;
  }
  if (key.contains('legacy') || key.contains('arac')) {
    return Icons.qr_code_scanner_rounded;
  }
  return Icons.dashboard_customize_outlined;
}

IconData _menuIcon(MenuEntry menu) {
  final key = _normalizedMenuKey(
    '${menu.moduleCode} ${menu.menuCode} ${menu.menuName}',
  );

  if (key.contains('fiyat')) {
    return Icons.price_check_rounded;
  }
  if (key.contains('cari')) {
    return Icons.person_search_rounded;
  }
  if (key.contains('barkod') || key.contains('barcode')) {
    return Icons.qr_code_scanner_rounded;
  }
  if (key.contains('etiket') || key.contains('label')) {
    return Icons.local_offer_outlined;
  }
  if (key.contains('sayim')) {
    return Icons.fact_check_outlined;
  }
  if (key.contains('zayiat')) {
    return Icons.delete_sweep_outlined;
  }
  if (key.contains('masraf')) {
    return Icons.receipt_long_outlined;
  }
  if (key.contains('virman')) {
    return Icons.swap_horiz_rounded;
  }
  if (key.contains('iade')) {
    return Icons.keyboard_return_rounded;
  }
  if (key.contains('gelen')) {
    return Icons.call_received_rounded;
  }
  if (key.contains('giden')) {
    return Icons.call_made_rounded;
  }
  if (key.contains('sevk')) {
    return Icons.local_shipping_outlined;
  }
  if (key.contains('mal kabul')) {
    return Icons.inventory_2_outlined;
  }
  if (key.contains('fark')) {
    return Icons.difference_outlined;
  }
  if (key.contains('onerilen')) {
    return Icons.recommend_outlined;
  }
  if (key.contains('siparis')) {
    return Icons.assignment_outlined;
  }
  if (key.contains('firma')) {
    return Icons.business_outlined;
  }
  if (key.contains('depo')) {
    return Icons.warehouse_outlined;
  }
  return Icons.apps_rounded;
}

Color _moduleColor(String moduleCode) {
  final key = _normalizedMenuKey(moduleCode);

  if (key.contains('siparis')) {
    return const Color(0xFF2E6F95);
  }
  if (key.contains('sevk')) {
    return const Color(0xFF2F7D57);
  }
  if (key.contains('mal kabul')) {
    return const Color(0xFF8A5A22);
  }
  if (key.contains('stok')) {
    return const Color(0xFF6C5A9E);
  }
  if (key.contains('iade')) {
    return const Color(0xFF9A4D4A);
  }
  return const Color(0xFF58667A);
}

String _normalizedMenuKey(String value) {
  return value
      .replaceAll('-', ' ')
      .replaceAll('_', ' ')
      .replaceAllMapped(
        RegExp(r'(?<=[a-z])([A-Z])'),
        (match) => ' ${match.group(0)}',
      )
      .toLowerCase();
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        'Bu kullaniciya atanmis menu bulunamadi. Yetkiler icin sistem yoneticinizle gorusun.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
