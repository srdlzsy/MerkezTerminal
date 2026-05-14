import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';
import 'package:furpa_merkez_terminal/shared/widgets/furpa_brand.dart';

class ModuleNavigationPanel extends StatelessWidget {
  const ModuleNavigationPanel({
    super.key,
    required this.user,
    required this.modules,
    required this.selectedMenu,
    required this.onSelectMenu,
    required this.onHomeTap,
    required this.onSignOut,
    this.isExpanded = true,
    this.onToggleExpanded,
  });

  final CurrentUser user;
  final List<PermissionModule> modules;
  final MenuEntry? selectedMenu;
  final ValueChanged<MenuEntry> onSelectMenu;
  final VoidCallback onHomeTap;
  final VoidCallback onSignOut;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child:
            isExpanded
                ? _ExpandedNavigation(
                  user: user,
                  modules: modules,
                  selectedMenu: selectedMenu,
                  onSelectMenu: onSelectMenu,
                  onHomeTap: onHomeTap,
                  onSignOut: onSignOut,
                  onToggleExpanded: onToggleExpanded,
                )
                : _CompactNavigation(
                  onHomeTap: onHomeTap,
                  onSignOut: onSignOut,
                  onToggleExpanded: onToggleExpanded,
                ),
      ),
    );
  }
}

class _ExpandedNavigation extends StatelessWidget {
  const _ExpandedNavigation({
    required this.user,
    required this.modules,
    required this.selectedMenu,
    required this.onSelectMenu,
    required this.onHomeTap,
    required this.onSignOut,
    required this.onToggleExpanded,
  });

  final CurrentUser user;
  final List<PermissionModule> modules;
  final MenuEntry? selectedMenu;
  final ValueChanged<MenuEntry> onSelectMenu;
  final VoidCallback onHomeTap;
  final VoidCallback onSignOut;
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFF),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withAlpha(70),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: onHomeTap,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: FurpaBrandLockup(scale: 0.72),
                      ),
                    ),
                  ),
                  if (onToggleExpanded != null)
                    IconButton(
                      onPressed: onToggleExpanded,
                      tooltip: 'Menuyu daralt',
                      icon: const Icon(Icons.menu_open_rounded),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                user.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Depo ${user.warehouseNo} - ${user.warehouseName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5C6B80),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            children: <Widget>[
              _UtilityTile(
                icon: Icons.home_rounded,
                label: 'Anasayfa',
                isSelected: selectedMenu == null,
                onTap: onHomeTap,
              ),
              ...modules.map(
                (module) => _ModuleSection(
                  module: module,
                  selectedMenu: selectedMenu,
                  onSelectMenu: onSelectMenu,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cikis yap'),
          ),
        ),
      ],
    );
  }
}

class _CompactNavigation extends StatelessWidget {
  const _CompactNavigation({
    required this.onHomeTap,
    required this.onSignOut,
    required this.onToggleExpanded,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onSignOut;
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 10),
        Tooltip(
          message: 'Anasayfa',
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onHomeTap,
            child: Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FD),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const FittedBox(
                fit: BoxFit.contain,
                child: FurpaBrandMark(width: 46),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _CompactIconButton(
          icon: Icons.home_rounded,
          tooltip: 'Anasayfa',
          onTap: onHomeTap,
        ),
        if (onToggleExpanded != null) ...<Widget>[
          const SizedBox(height: 8),
          _CompactIconButton(
            icon: Icons.menu_open_rounded,
            tooltip: 'Menuyu ac',
            onTap: onToggleExpanded!,
          ),
        ],
        const Spacer(),
        _CompactIconButton(
          icon: Icons.logout_rounded,
          tooltip: 'Cikis yap',
          onTap: onSignOut,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
  }
}

class _UtilityTile extends StatelessWidget {
  const _UtilityTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Material(
        color:
            isSelected
                ? Theme.of(context).colorScheme.primary.withAlpha(24)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          minVerticalPadding: 0,
          leading: Icon(icon, size: 20),
          title: Text(label),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _ModuleSection extends StatelessWidget {
  const _ModuleSection({
    required this.module,
    required this.selectedMenu,
    required this.onSelectMenu,
  });

  final PermissionModule module;
  final MenuEntry? selectedMenu;
  final ValueChanged<MenuEntry> onSelectMenu;

  @override
  Widget build(BuildContext context) {
    final hasSelectedChild = module.menus.any(
      (menu) =>
          selectedMenu?.id == MenuEntry.fromPermissionMenu(module, menu).id,
    );

    return ExpansionTile(
      initiallyExpanded: hasSelectedChild,
      tilePadding: const EdgeInsets.symmetric(horizontal: 6),
      childrenPadding: const EdgeInsets.only(bottom: 2),
      title: Text(
        prettifyIdentifier(module.name, fallback: module.code),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      children:
          module.menus
              .map(
                (menu) => _MenuTile(
                  entry: MenuEntry.fromPermissionMenu(module, menu),
                  selectedMenu: selectedMenu,
                  onTap: onSelectMenu,
                ),
              )
              .toList(growable: false),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.entry,
    required this.selectedMenu,
    required this.onTap,
  });

  final MenuEntry entry;
  final MenuEntry? selectedMenu;
  final ValueChanged<MenuEntry> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedMenu?.id == entry.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Material(
        color:
            isSelected
                ? Theme.of(context).colorScheme.primary.withAlpha(24)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          minVerticalPadding: 0,
          title: Text(
            entry.displayMenuName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => onTap(entry),
        ),
      ),
    );
  }
}
