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
        12,
        12,
        12,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      children: <Widget>[
        _UserSummary(
          user: user,
          offlineQueueCount: offlineQueueCount,
          offlineFailedCount: offlineFailedCount,
        ),
        const SizedBox(height: 10),
        SectionCard(
          title: 'Tum Menuler',
          subtitle: menus.isEmpty
              ? 'Kullaniciya atanmis menu bulunamadi.'
              : '${menus.length} ekran kullanima hazir.',
          child: menus.isEmpty
              ? const _DashboardEmptyState()
              : Column(
                  children: <Widget>[
                    for (var index = 0; index < menuGroups.length; index += 1)
                      Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(24),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Depo ${user.warehouseNo} - ${user.warehouseName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(210),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Islem yapmak icin asagidaki menu listesinden bir ekran secin.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withAlpha(205),
              height: 1.3,
            ),
          ),
          if (offlineQueueCount > 0) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withAlpha(38)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    offlineFailedCount > 0
                        ? Icons.error_outline_rounded
                        : Icons.cloud_upload_outlined,
                    color: Colors.white,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      offlineFailedCount > 0
                          ? '$offlineQueueCount offline kayit var, $offlineFailedCount hata bekliyor.'
                          : '$offlineQueueCount offline kayit senkron bekliyor.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 6),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  group.moduleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF5C6B80),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${group.menus.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        for (var index = 0; index < group.menus.length; index += 1)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 6),
            child: _PdaMenuTile(
              menu: group.menus[index],
              onTap: () => onSelectMenu(group.menus[index]),
            ),
          ),
      ],
    );
  }
}

class _PdaMenuTile extends StatelessWidget {
  const _PdaMenuTile({required this.menu, required this.onTap});

  final MenuEntry menu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 58,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(85),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.apps_rounded,
                    size: 19,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
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
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
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
