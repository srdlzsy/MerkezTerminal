import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furpa_merkez_terminal/features/auth/data/models/auth_models.dart';
import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';
import 'package:furpa_merkez_terminal/features/shell/presentation/widgets/home_dashboard.dart';
import 'package:furpa_merkez_terminal/shared/product_entry/product_entry_widgets.dart';
import 'package:furpa_merkez_terminal/shared/widgets/terminal_ui_parts.dart';

class _FleetDeviceProfile {
  const _FleetDeviceProfile({
    required this.name,
    required this.size,
    required this.devicePixelRatio,
    this.keyboardInset = 0,
    this.textScale = 1.0,
  });

  final String name;
  final Size size;
  final double devicePixelRatio;
  final double keyboardInset;
  final double textScale;
}

const List<_FleetDeviceProfile> _fleetProfiles = <_FleetDeviceProfile>[
  _FleetDeviceProfile(
    name: 'Zebra TC20 (480x800 @ 240dpi = 320x533 dp)',
    size: Size(320, 533),
    devicePixelRatio: 1.5,
  ),
  _FleetDeviceProfile(
    name: 'Zebra TC20 + Soft Keyboard (320x533 dp, inset 220)',
    size: Size(320, 533),
    devicePixelRatio: 1.5,
    keyboardInset: 220,
  ),
  _FleetDeviceProfile(
    name: 'Compact 3.5" / EDA51 Buyuk Ekran (305x480 dp, 1.2x)',
    size: Size(305, 480),
    devicePixelRatio: 2.0,
    textScale: 1.2,
  ),
  _FleetDeviceProfile(
    name: 'Honeywell EDA51 Portrait (720x1280 @ 320dpi = 360x640 dp)',
    size: Size(360, 640),
    devicePixelRatio: 2.0,
  ),
  _FleetDeviceProfile(
    name: 'Honeywell EDA51 Landscape (640x336 dp)',
    size: Size(640, 336),
    devicePixelRatio: 2.0,
  ),
  _FleetDeviceProfile(
    name: 'alps Z1 Portrait (720x1440 @ 320dpi = 360x720 dp)',
    size: Size(360, 720),
    devicePixelRatio: 2.0,
  ),
  _FleetDeviceProfile(
    name: 'Redmi Note 14 / Galaxy A56 Phone (392x872 dp, SafeArea notch+bar)',
    size: Size(392, 872),
    devicePixelRatio: 2.75,
  ),
];

void main() {
  const testWidths = <double>[240, 280, 320, 360, 400];

  group('PDA Responsive Matrix (240-400 dp + 1.3x text scale)', () {
    testWidgets(
      'dual quantity V2 card never truncates barcode, koli, or price across all widths',
      (tester) async {
        for (final width in testWidths) {
          for (final textScale in <double>[1.0, 1.3]) {
            final dispatchController = TextEditingController(text: '12');
            final acceptedController = TextEditingController(text: '12');
            addTearDown(dispatchController.dispose);
            addTearDown(acceptedController.dispose);

            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 640),
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        width: width - 16,
                        child: TerminalDualQuantityProductLineCard(
                          lineNo: 1,
                          stockCode: '019012',
                          stockName: 'COCA COLA 1LT',
                          unitLabel: 'ADET',
                          packageLabel: '12',
                          barcode: '5000112665116',
                          priceLabel: 'Net 61,46 TL | Brut 78,99 TL',
                          onDelete: () {},
                          primaryQuantity: TerminalQuantityStepper(
                            controller: dispatchController,
                            label: 'Irs. Miktar*',
                            dense: true,
                          ),
                          secondaryQuantity: TerminalQuantityStepper(
                            controller: acceptedController,
                            label: 'Fiili Miktar*',
                            dense: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(
              tester.takeException(),
              isNull,
              reason: 'Overflow at width=$width textScale=$textScale',
            );

            final barcodeText = tester.widget<Text>(find.text('5000112665116'));
            final packageText = tester.widget<Text>(
              find.text('Koli ici 12 ADET'),
            );
            final priceText = tester.widget<Text>(
              find.text('Net 61,46 TL | Brut 78,99 TL'),
            );

            expect(barcodeText.overflow, isNot(TextOverflow.ellipsis));
            expect(packageText.overflow, isNot(TextOverflow.ellipsis));
            expect(priceText.overflow, isNot(TextOverflow.ellipsis));
          }
        }
      },
    );

    testWidgets(
      'TerminalListHeaderCard hides filler subtitle on compact PDA widths and shows on wide',
      (tester) async {
        const subtitle =
            'Etiket belgelerini listeleyin, detaylari acin ve yeni belge olusturun.';

        for (final width in <double>[240, 320, 360, 400]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: width,
                  child: TerminalListHeaderCard(
                    title: 'Etiket Belgeleri',
                    subtitle: subtitle,
                    filters: const <Widget>[
                      ChoiceChip(label: Text('Son Belgeler'), selected: true),
                      ChoiceChip(label: Text('Tum Gecmis'), selected: false),
                    ],
                    actions: <Widget>[
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Yenile'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'Header overflow at width=$width',
          );
          expect(find.text(subtitle), findsNothing);
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 500,
                child: TerminalListHeaderCard(
                  title: 'Etiket Belgeleri',
                  subtitle: subtitle,
                  filters: const <Widget>[],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(subtitle), findsOneWidget);
      },
    );

    testWidgets(
      'list record cards align badge + chevron horizontally and keep date/time readable without ellipsis across all widths',
      (tester) async {
        for (final width in testWidths) {
          for (final textScale in <double>[1.0, 1.3]) {
            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 640),
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        width: width - 16,
                        child: TerminalPdaRecordCard(
                          onTap: () {},
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              TerminalPdaCardHeader(
                                title: 'F56.90769',
                                subtitle: 'MANAV DEPO -> KAPLIKAYA',
                                trailing: TerminalPdaCardTrailing(
                                  badges: <Widget>[
                                    TerminalBadge(label: 'Ulasti'),
                                  ],
                                ),
                              ),
                              SizedBox(height: 6),
                              TerminalPdaInfoGrid(
                                compact: true,
                                items: <TerminalPdaInfo>[
                                  TerminalPdaInfo(
                                    label: 'Olusturma',
                                    value: '25.11.2026 13:19',
                                  ),
                                  TerminalPdaInfo(
                                    label: 'Miktar',
                                    value: '172,93',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(
              tester.takeException(),
              isNull,
              reason: 'Record card overflow at width=$width scale=$textScale',
            );

            final badgeCenterY = tester.getCenter(find.text('Ulasti')).dy;
            final chevronCenterY = tester
                .getCenter(find.byIcon(Icons.chevron_right_rounded))
                .dy;
            expect(
              (badgeCenterY - chevronCenterY).abs(),
              lessThanOrEqualTo(4),
              reason: 'Badge and chevron should sit inline at width=$width',
            );

            expect(find.text('25.11.2026 13:19'), findsOneWidget);
            expect(find.text('172,93'), findsOneWidget);
          }
        }
      },
    );

    testWidgets(
      'TerminalDetailLineCard shows full price/barcode, uses 1-based lines, and hides raw UUID notes across all widths',
      (tester) async {
        expect(terminalDisplayLineNo(0, 0, zeroBasedList: true), 1);
        expect(terminalDisplayLineNo(1, 1, zeroBasedList: true), 2);
        expect(terminalDisplayLineNo(0, 2), 3);
        expect(
          terminalDisplayableNote('a561f7a8-8f60-4db1-99bc-cecd04a4770a'),
          isNull,
        );
        expect(terminalDisplayableNote('Kirik koli'), 'Kirik koli');

        for (final width in testWidths) {
          for (final textScale in <double>[1.0, 1.3]) {
            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 640),
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: <Widget>[
                          TerminalDetailLineCard(
                            lineNo: terminalDisplayLineNo(
                              0,
                              0,
                              zeroBasedList: true,
                            ),
                            stockName: 'ARMUT DEVECI PAKET',
                            stockCode: '049322',
                            barcode: '5449000134585',
                            quantityLabel: '8 ADET',
                            priceFacts: const <String>[
                              'Fiyat 34,50 TL',
                              'Tutar 276,00 TL',
                            ],
                            note: 'a561f7a8-8f60-4db1-99bc-cecd04a4770a',
                          ),
                          const SizedBox(height: 6),
                          const TerminalDetailLineCard(
                            lineNo: 2,
                            stockName: 'DLS.COCA COLA 200ML*6 LI ZERO SUGAR',
                            stockCode: '000111',
                            quantityLabel: '4 ADET',
                            note: 'Ozel raf etiketi basilsin',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(
              tester.takeException(),
              isNull,
              reason: 'Detail line overflow at width=$width scale=$textScale',
            );
            expect(find.text('01'), findsOneWidget);
            expect(find.text('8 ADET'), findsOneWidget);
            expect(find.text('049322'), findsOneWidget);
            expect(find.text('5449000134585'), findsOneWidget);
            expect(find.text('Fiyat 34,50 TL'), findsOneWidget);
            expect(find.text('Tutar 276,00 TL'), findsOneWidget);
            expect(
              find.text('a561f7a8-8f60-4db1-99bc-cecd04a4770a'),
              findsNothing,
            );
            expect(find.text('Ozel raf etiketi basilsin'), findsOneWidget);

            final priceWidget = tester.widget<Text>(
              find.text('Fiyat 34,50 TL'),
            );
            expect(priceWidget.overflow, isNot(TextOverflow.ellipsis));
          }
        }
      },
    );

    testWidgets(
      'TerminalEDespatchActionStrip stays compact without developer jargon across all widths',
      (tester) async {
        for (final width in testWidths) {
          for (final textScale in <double>[1.0, 1.3]) {
            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 640),
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(8),
                      child: TerminalEDespatchActionStrip(
                        canSendEDespatch: true,
                        canViewEDespatchPdf: true,
                        isSendingEDespatch: false,
                        isLoadingPdf: false,
                        onSendEDespatch: () {},
                        onShowPdf: () {},
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(
              tester.takeException(),
              isNull,
              reason: 'E-Despatch strip overflow at width=$width',
            );
            expect(find.textContaining('create ekraninda'), findsNothing);
            expect(find.text('E-Irsaliyeye Cevir'), findsOneWidget);
            expect(find.text('PDF Goster'), findsOneWidget);
          }
        }

        // PDF-only mode on 320 dp should be super compact (no send hint).
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 304,
                  child: KeyedSubtree(
                    key: key,
                    child: TerminalEDespatchActionStrip(
                      canSendEDespatch: false,
                      canViewEDespatchPdf: true,
                      isSendingEDespatch: false,
                      isLoadingPdf: false,
                      onSendEDespatch: () {},
                      onShowPdf: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.getSize(find.byKey(key)).height, lessThanOrEqualTo(92));
      },
    );

    testWidgets(
      'TerminalResponsiveLookupRow with compact ProductLookupField never overflows across 240-400 dp',
      (tester) async {
        for (final width in testWidths) {
          final controller = TextEditingController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: width - 16,
                    child: TerminalResponsiveLookupRow(
                      field: ProductLookupField(
                        controller: controller,
                        onSubmit: () {},
                      ),
                      action: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Urun'),
                      ),
                      trailingAction: IconButton.filledTonal(
                        onPressed: () {},
                        tooltip: 'Kamera ile oku',
                        icon: const Icon(Icons.photo_camera_back_rounded),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'Lookup row overflow at width=$width',
          );
          expect(find.text('Barkod / stok / urun'), findsOneWidget);
        }
      },
    );
  });

  group('Real Production Fleet Profiles (Zebra TC20, EDA51, alps Z1, 3.5")', () {
    testWidgets(
      'HomeDashboard renders cleanly across all fleet device profiles',
      (tester) async {
        const action = PermissionAction(
          code: 'list',
          name: 'Listele',
          permissionCode: 'kabul-islemleri.firma-mal-kabul.list',
        );
        const modules = <PermissionModule>[
          PermissionModule(
            code: 'kabul-islemleri',
            name: 'KabulIslemleri',
            menus: <PermissionMenu>[
              PermissionMenu(
                code: 'firma-mal-kabul',
                name: 'FirmaMalKabul',
                actions: <PermissionAction>[action],
              ),
              PermissionMenu(
                code: 'depo-mal-kabul',
                name: 'DepoMalKabul',
                actions: <PermissionAction>[action],
              ),
            ],
          ),
          PermissionModule(
            code: 'sevk-islemleri',
            name: 'SevkIslemleri',
            menus: <PermissionMenu>[
              PermissionMenu(
                code: 'giden-depo-sevkleri',
                name: 'GidenDepoSevkleri',
                actions: <PermissionAction>[action],
              ),
            ],
          ),
        ];
        const user = CurrentUser(
          id: '105',
          username: '105.sube',
          email: '105@furpa.local',
          firstName: 'MILLET 1',
          lastName: 'Sube',
          warehouseNo: '105',
          warehouseName: 'MILLET 1 SUBE',
          isActive: true,
          roles: <String>[],
          permissions: <String>[],
          modules: modules,
        );
        final menus = modules
            .expand(
              (m) => m.menus.map((menu) => MenuEntry.fromPermissionMenu(m, menu)),
            )
            .toList(growable: false);

        for (final profile in _fleetProfiles) {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: profile.size,
                  devicePixelRatio: profile.devicePixelRatio,
                  padding: const EdgeInsets.only(top: 24),
                  viewInsets: EdgeInsets.only(bottom: profile.keyboardInset),
                  textScaler: TextScaler.linear(profile.textScale),
                ),
                child: Scaffold(
                  body: SafeArea(
                    child: HomeDashboard(
                      user: user,
                      menus: menus,
                      installedVersionLabel: '1.1.110 (4110)',
                      onSelectMenu: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'HomeDashboard overflow on ${profile.name}',
          );
          expect(find.text('Tum Menuler'), findsOneWidget);
        }
      },
    );

    testWidgets(
      'Create dock + V2 product card + dual card stay usable with keyboard across all fleet profiles',
      (tester) async {
        for (final profile in _fleetProfiles) {
          final lookupController = TextEditingController();
          final qtyController = TextEditingController(text: '12');
          final dispatchController = TextEditingController(text: '12');
          final acceptedController = TextEditingController(text: '12');
          addTearDown(lookupController.dispose);
          addTearDown(qtyController.dispose);
          addTearDown(dispatchController.dispose);
          addTearDown(acceptedController.dispose);

          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: profile.size,
                  devicePixelRatio: profile.devicePixelRatio,
                  padding: const EdgeInsets.only(top: 24),
                  viewInsets: EdgeInsets.only(bottom: profile.keyboardInset),
                  textScaler: TextScaler.linear(profile.textScale),
                ),
                child: Scaffold(
                  appBar: AppBar(title: const Text('Yeni Firma Mal Kabul')),
                  body: SafeArea(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        8,
                        8,
                        8,
                        8 + profile.keyboardInset,
                      ),
                      children: <Widget>[
                        TerminalPdaLineCard(
                          title: 'Giris satiri',
                          child: TerminalResponsiveLookupRow(
                            field: ProductLookupField(
                              controller: lookupController,
                              onSubmit: () {},
                            ),
                            action: FilledButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.search_rounded),
                              label: const Text('Urun'),
                            ),
                            trailingAction: IconButton.filledTonal(
                              onPressed: () {},
                              tooltip: 'Kamera ile oku',
                              icon: const Icon(Icons.photo_camera_back_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TerminalCompactProductLineCard(
                          lineNo: 1,
                          stockCode: '044224',
                          stockName: 'TORKU TOZ SEKER 2KG*10',
                          quantityController: qtyController,
                          unitLabel: 'ADET',
                          packageLabel: '10',
                          barcode: '8690120010120',
                          onDelete: () {},
                        ),
                        TerminalDualQuantityProductLineCard(
                          lineNo: 2,
                          stockCode: '019012',
                          stockName: 'COCA COLA 1LT',
                          unitLabel: 'ADET',
                          packageLabel: '12',
                          barcode: '5000112665116',
                          priceLabel: 'Net 61,46 TL | Brut 78,99 TL',
                          onDelete: () {},
                          primaryQuantity: TerminalQuantityStepper(
                            controller: dispatchController,
                            label: 'Irs. Miktar*',
                            dense: true,
                          ),
                          secondaryQuantity: TerminalQuantityStepper(
                            controller: acceptedController,
                            label: 'Fiili Miktar*',
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'Create screen overflow on ${profile.name}',
          );
          expect(find.text('Barkod / stok / urun'), findsOneWidget);
        }
      },
    );

    testWidgets(
      'List and Detail pages render without overflow or truncation across all fleet profiles',
      (tester) async {
        for (final profile in _fleetProfiles) {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: profile.size,
                  devicePixelRatio: profile.devicePixelRatio,
                  padding: const EdgeInsets.only(top: 24),
                  viewInsets: EdgeInsets.only(bottom: profile.keyboardInset),
                  textScaler: TextScaler.linear(profile.textScale),
                ),
                child: Scaffold(
                  appBar: AppBar(title: const Text('F56.90769')),
                  body: SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: <Widget>[
                        TerminalListHeaderCard(
                          title: 'Giden Depo Sevkleri',
                          subtitle:
                              'Depolar arasi sevkleri listeler ve detay acar.',
                          filters: <Widget>[
                            TerminalFilterButton(
                              label: 'Baslangic',
                              value: '25.11.2026',
                              onPressed: () {},
                            ),
                            TerminalFilterButton(
                              label: 'Bitis',
                              value: '25.11.2026',
                              onPressed: () {},
                            ),
                          ],
                          actions: <Widget>[
                            FilledButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.search_rounded),
                              label: const Text('Listele'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () {},
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Yeni Sevk'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TerminalPdaRecordCard(
                          onTap: () {},
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              TerminalPdaCardHeader(
                                title: 'F56.90769',
                                subtitle: 'MANAV DEPO -> KAPLIKAYA',
                                trailing: TerminalPdaCardTrailing(
                                  badges: <Widget>[
                                    TerminalBadge(label: 'Ulasti'),
                                  ],
                                ),
                              ),
                              SizedBox(height: 6),
                              TerminalPdaInfoGrid(
                                compact: true,
                                items: <TerminalPdaInfo>[
                                  TerminalPdaInfo(
                                    label: 'Tarih',
                                    value: '25.11.2026',
                                  ),
                                  TerminalPdaInfo(
                                    label: 'Miktar',
                                    value: '172,93',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TerminalEDespatchActionStrip(
                          canSendEDespatch: true,
                          canViewEDespatchPdf: true,
                          isSendingEDespatch: false,
                          isLoadingPdf: false,
                          onSendEDespatch: () {},
                          onShowPdf: () {},
                        ),
                        const SizedBox(height: 6),
                        const TerminalDetailLineCard(
                          lineNo: 1,
                          stockName: 'ARMUT DEVECI PAKET',
                          stockCode: '049322',
                          quantityLabel: '8 ADET',
                          priceFacts: <String>[
                            'Fiyat 34,50 TL',
                            'Tutar 276,00 TL',
                          ],
                          note: 'a561f7a8-8f60-4db1-99bc-cecd04a4770a',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'List/Detail overflow on ${profile.name}',
          );
          expect(
            find.text('a561f7a8-8f60-4db1-99bc-cecd04a4770a'),
            findsNothing,
          );
        }
      },
    );

    testWidgets(
      'List header action buttons share uniform 40 dp height on Zebra TC20 (320 dp) and EDA51 (360 dp)',
      (tester) async {
        for (final width in <double>[320, 360]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: width - 16,
                    child: TerminalListHeaderCard(
                      title: 'Firma Mal Kabulleri',
                      filters: const <Widget>[],
                      actions: <Widget>[
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('Listele'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('Temizle'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_task_rounded),
                          label: const Text('Yeni Mal Kabul'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.cloud_off_rounded),
                          label: const Text('Offline Taslaklar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final listeleRect = tester.getRect(find.byTooltip('Listele'));
          final temizleRect = tester.getRect(find.byTooltip('Temizle'));
          final yeniRect = tester.getRect(
            find.ancestor(
              of: find.text('Yeni'),
              matching: find.byWidgetPredicate((w) => w is FilledButton),
            ),
          );
          final offlineRect = tester.getRect(
            find.byTooltip('Offline Taslaklar'),
          );

          expect(listeleRect.height, closeTo(40, 2));
          expect(temizleRect.height, closeTo(40, 2));
          expect(yeniRect.height, closeTo(40, 2));
          expect(offlineRect.height, closeTo(40, 2));
          expect((listeleRect.center.dy - yeniRect.center.dy).abs(), lessThan(2));
          expect((offlineRect.center.dy - yeniRect.center.dy).abs(), lessThan(2));
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Shared lookup row keeps field, Urun button, and camera button uniform height even inside 48 dp create theme',
      (tester) async {
        for (final width in <double>[320, 360]) {
          final controller = TextEditingController();
          addTearDown(controller.dispose);

          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                ),
              ),
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    width: width - 16,
                    child: TerminalResponsiveLookupRow(
                      field: ProductLookupField(
                        controller: controller,
                        onSubmit: () {},
                      ),
                      action: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Urun'),
                      ),
                      trailingAction: IconButton.filledTonal(
                        onPressed: () {},
                        tooltip: 'Kamera ile oku',
                        icon: const Icon(Icons.photo_camera_back_rounded),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final fieldRect = tester.getRect(find.byType(TextFormField));
          final urunRect = tester.getRect(
            find.ancestor(
              of: find.text('Urun'),
              matching: find.byWidgetPredicate((w) => w is FilledButton),
            ),
          );
          final okuRect = tester.getRect(find.byTooltip('Kamera ile oku'));

          expect((fieldRect.height - urunRect.height).abs(), lessThanOrEqualTo(3));
          expect((urunRect.height - okuRect.height).abs(), lessThanOrEqualTo(2));
          expect((fieldRect.center.dy - urunRect.center.dy).abs(), lessThanOrEqualTo(2));
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Phone SafeArea (notch + gesture bar) keeps create header and bottom buttons clear of system insets',
      (tester) async {
        final qtyController = TextEditingController();
        addTearDown(qtyController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(392, 872),
                devicePixelRatio: 2.75,
                padding: EdgeInsets.only(top: 44, bottom: 34),
              ),
              child: Scaffold(
                body: SafeArea(
                  top: true,
                  bottom: true,
                  child: Column(
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Yeni Depo Sevki'),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(8),
                          children: <Widget>[
                            TerminalCompactProductLineCard(
                              lineNo: 1,
                              stockCode: '045905',
                              stockName: 'MNV ANANAS ADET',
                              quantityController: qtyController,
                              unitLabel: 'ADET',
                              allowEmptyQuantity: true,
                              onDelete: () {},
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: TerminalFormActionRow(
                          cancel: OutlinedButton(
                            onPressed: () {},
                            child: const Text('Vazgec'),
                          ),
                          submit: FilledButton(
                            onPressed: () {},
                            child: const Text('Kaydet'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.getTopLeft(find.text('Yeni Depo Sevki')).dy,
          greaterThanOrEqualTo(44),
        );
        expect(
          tester.getBottomRight(find.widgetWithText(FilledButton, 'Kaydet')).dy,
          lessThanOrEqualTo(872 - 34),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
