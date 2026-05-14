import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';
import 'package:furpa_merkez_terminal/shared/widgets/furpa_brand.dart';
import 'package:furpa_merkez_terminal/shared/widgets/section_card.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.user,
    required this.menus,
    required this.onSelectMenu,
  });

  final CurrentUser user;
  final List<MenuEntry> menus;
  final ValueChanged<MenuEntry> onSelectMenu;

  @override
  Widget build(BuildContext context) {
    final quickMenus = menus.take(8).toList(growable: false);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF183259), Color(0xFF2F5B8D)],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const FurpaBrandLockup(
                scale: 0.7,
                enclosed: true,
                showCaption: true,
              ),
              const SizedBox(height: 18),
              Text(
                user.fullName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Depo ${user.warehouseNo} - ${user.warehouseName}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withAlpha(220),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Uygulama ana sayfasi acildi. Soldaki menuden modullere gecebilir ya da asagidaki hizli kartlarla devam edebilirsin.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withAlpha(220),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Hizli Erisim',
          subtitle:
              quickMenus.isEmpty
                  ? 'Kullaniciya atanmis gorunur menu bulunamadi.'
                  : 'Sik kullanilan ekranlara tek dokunusla gec.',
          child:
              quickMenus.isEmpty
                  ? const _DashboardEmptyState()
                  : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        quickMenus
                            .map(
                              (menu) => _QuickMenuTile(
                                menu: menu,
                                onTap: () => onSelectMenu(menu),
                              ),
                            )
                            .toList(growable: false),
                  ),
        ),
      ],
    );
  }
}

class _QuickMenuTile extends StatelessWidget {
  const _QuickMenuTile({required this.menu, required this.onTap});

  final MenuEntry menu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width >= 840 ? 280.0 : double.infinity;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withAlpha(90),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              menu.displayModuleName,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF5C6B80),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              menu.displayMenuName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF17213B),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${menu.actions.length} yetki aksiyonu',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF5C6B80),
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        'Menu donmuyor gibi gorunuyor. /api/auth/me icindeki modules cevabi kontrol edilmeli.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
