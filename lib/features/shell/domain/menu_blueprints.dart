import 'package:furpa_merkez_terminal/features/shell/domain/menu_entry.dart';

class EndpointSpec {
  const EndpointSpec({
    required this.label,
    required this.method,
    required this.path,
  });

  final String label;
  final String method;
  final String path;
}

class MenuBlueprint {
  const MenuBlueprint({
    required this.title,
    required this.subtitle,
    required this.endpoints,
    required this.uiNotes,
  });

  final String title;
  final String subtitle;
  final List<EndpointSpec> endpoints;
  final List<String> uiNotes;
}

abstract final class MenuBlueprintRegistry {
  static MenuBlueprint resolve(MenuEntry entry) {
    final key = '${entry.moduleCode}.${entry.menuCode}';

    return _overrides[key] ?? _generic(entry);
  }

  static final Map<String, MenuBlueprint> _overrides = <String, MenuBlueprint>{
    'siparis-islemleri.verilen-firma-siparisleri': const MenuBlueprint(
      title: 'Verilen Firma Siparisleri',
      subtitle:
          'Firma siparislerinin liste, detay ve create akislarini yonetir.',
      endpoints: <EndpointSpec>[
        EndpointSpec(
          label: 'Liste',
          method: 'GET',
          path: '/api/siparis-islemleri/verilen-firma-siparisleri',
        ),
        EndpointSpec(
          label: 'Detay',
          method: 'GET',
          path:
              '/api/siparis-islemleri/verilen-firma-siparisleri/{seri}/{sira}',
        ),
        EndpointSpec(
          label: 'Olustur',
          method: 'POST',
          path: '/api/siparis-islemleri/verilen-firma-siparisleri',
        ),
      ],
      uiNotes: <String>[
        'Mal kabul icin acik siparis baglama akisi CustomerCode ve OnlyOpen=true ile calisir.',
        'Liste ekraninda musteri, adres, satir sayisi, toplam miktar ve teslim tarihi one cikarilmali.',
        'Detayda header ve items ayri bolumler halinde gosterilmeli.',
      ],
    ),
    'sevk-islemleri.giden-depolar-arasi-sevkler': const MenuBlueprint(
      title: 'Giden Depolar Arasi Sevkler',
      subtitle:
          'Giden sevklerin liste, detay, create ve e-irsaliye akislarini yonetir.',
      endpoints: <EndpointSpec>[
        EndpointSpec(
          label: 'Liste',
          method: 'GET',
          path: '/api/sevk-islemleri/depolar-arasi-sevkler/giden',
        ),
        EndpointSpec(
          label: 'Detay',
          method: 'GET',
          path: '/api/sevk-islemleri/depolar-arasi-sevkler/giden/{seri}/{sira}',
        ),
        EndpointSpec(
          label: 'Olustur',
          method: 'POST',
          path: '/api/sevk-islemleri/depolar-arasi-sevkler/giden',
        ),
        EndpointSpec(
          label: 'E-Irsaliye',
          method: 'POST',
          path:
              '/api/sevk-islemleri/depolar-arasi-sevkler/giden/{seri}/{sira}/e-irsaliye',
        ),
        EndpointSpec(
          label: 'PDF',
          method: 'GET',
          path:
              '/api/sevk-islemleri/depolar-arasi-sevkler/giden/{seri}/{sira}/e-irsaliye/pdf',
        ),
      ],
      uiNotes: <String>[
        'E-irsaliye bilgileri create ekraninda degil, detay ekranindaki modal ile alinmali.',
        'warehouseOrderNo varsa kullaniciya siparise bagli sevk oldugu gosterilebilir.',
        'Satir eslestirmesi icin movementGuid saklanmali; sadece stok kodu yeterli degil.',
      ],
    ),
    'sevk-islemleri.gelen-depolar-arasi-sevkler': const MenuBlueprint(
      title: 'Gelen Depolar Arasi Sevkler',
      subtitle:
          'Gelen sevklerin liste ve detay akislarini hedef depo perspektifinden gosterir.',
      endpoints: <EndpointSpec>[
        EndpointSpec(
          label: 'Liste',
          method: 'GET',
          path: '/api/sevk-islemleri/depolar-arasi-sevkler/gelen',
        ),
        EndpointSpec(
          label: 'Detay',
          method: 'GET',
          path: '/api/sevk-islemleri/depolar-arasi-sevkler/gelen/{seri}/{sira}',
        ),
      ],
      uiNotes: <String>[
        'Liste ekraninda kaynak depo, hedef depo, sevk durumu, plaka, sofor ve toplam miktar gosterilmeli.',
        'Detaydaki movementGuid degeri mal kabul ekranina tasinmali.',
      ],
    ),
    'sevk-islemleri.giden-firma-sevkleri': const MenuBlueprint(
      title: 'Giden Firma Sevkleri',
      subtitle:
          'Giden firma sevkleri icin liste, detay, create ve e-irsaliye akislarini toplar.',
      endpoints: <EndpointSpec>[
        EndpointSpec(
          label: 'Liste',
          method: 'GET',
          path: '/api/sevk-islemleri/firma-sevkleri/giden',
        ),
        EndpointSpec(
          label: 'Detay',
          method: 'GET',
          path: '/api/sevk-islemleri/firma-sevkleri/giden/{seri}/{sira}',
        ),
        EndpointSpec(
          label: 'Olustur',
          method: 'POST',
          path: '/api/sevk-islemleri/firma-sevkleri/giden',
        ),
        EndpointSpec(
          label: 'E-Irsaliye',
          method: 'POST',
          path:
              '/api/sevk-islemleri/firma-sevkleri/giden/{seri}/{sira}/e-irsaliye',
        ),
        EndpointSpec(
          label: 'PDF',
          method: 'GET',
          path:
              '/api/sevk-islemleri/firma-sevkleri/giden/{seri}/{sira}/e-irsaliye/pdf',
        ),
      ],
      uiNotes: <String>[
        'Plaka, sofor adi ve TCKN sadece e-irsaliye gonderim adiminda zorunlu alinmali.',
        'Satir bazinda unitPrice verilirse toplam tutar quantity * unitPrice toplamindan uretilir.',
      ],
    ),
    'sevk-islemleri.gelen-firma-sevkleri': const MenuBlueprint(
      title: 'Gelen Firma Sevkleri',
      subtitle: 'Gelen firma sevklerinin liste ve detay akislarini gosterir.',
      endpoints: <EndpointSpec>[
        EndpointSpec(
          label: 'Liste',
          method: 'GET',
          path: '/api/sevk-islemleri/firma-sevkleri/gelen',
        ),
        EndpointSpec(
          label: 'Detay',
          method: 'GET',
          path: '/api/sevk-islemleri/firma-sevkleri/gelen/{seri}/{sira}',
        ),
      ],
      uiNotes: <String>[
        'Liste ve detay modelleri firma sevkleri ortak response yapisini kullanir.',
      ],
    ),
    'mal-kabul-islemleri.depo-mal-kabulleri': const MenuBlueprint(
      title: 'Depo Mal Kabulleri',
      subtitle:
          'Bekleyen gelen sevkleri listeler ve movementGuid bazli kabul akisini yonetir.',
      endpoints: <EndpointSpec>[
        EndpointSpec(
          label: 'Liste',
          method: 'GET',
          path: '/api/mal-kabul-islemleri/depo-mal-kabulleri',
        ),
        EndpointSpec(
          label: 'Detay',
          method: 'GET',
          path: '/api/mal-kabul-islemleri/depo-mal-kabulleri/{seri}/{sira}',
        ),
        EndpointSpec(
          label: 'Kabul',
          method: 'POST',
          path:
              '/api/mal-kabul-islemleri/depo-mal-kabulleri/{seri}/{sira}/kabul',
        ),
      ],
      uiNotes: <String>[
        'Liste bekleyen gelen sevkleri gosterir; yeni bos fis acilmaz.',
        'UI her satir icin receivedQuantity alanini sevk miktariyla onceden doldurabilir.',
        'Eksik veya fazla durumda allowDiscrepancy kullanicidan acik onay alinarak gonderilmeli.',
      ],
    ),
    'stok-islemleri.sayim-sonuclari': const MenuBlueprint(
      title: 'Sayim Sonuclari',
      subtitle:
          'Belge no ve documentDate bazli detay acan stok sayim akisini yonetir.',
      endpoints: <EndpointSpec>[
        EndpointSpec(
          label: 'Liste',
          method: 'GET',
          path: '/api/stok-islemleri/sayim-sonuclari',
        ),
        EndpointSpec(
          label: 'Detay',
          method: 'GET',
          path:
              '/api/stok-islemleri/sayim-sonuclari/{documentNo}?documentDate={yyyy-mm-dd}',
        ),
        EndpointSpec(
          label: 'Olustur',
          method: 'POST',
          path: '/api/stok-islemleri/sayim-sonuclari',
        ),
      ],
      uiNotes: <String>[
        'Bu moduld e belge serisi yoktur; detay icin documentNo ile documentDate birlikte tutulmali.',
        'Satirda barcode bos gelirse backend stok kodundan barkod bulmayi dener.',
      ],
    ),
    'iade-islemleri.giden-depo-iadeleri': const MenuBlueprint(
      title: 'Giden Depo Iadeleri',
      subtitle:
          'Depolar arasi iade liste, detay, create ve e-irsaliye akislarini kaynak sube perspektifinden yonetir.',
      endpoints: <EndpointSpec>[
        EndpointSpec(
          label: 'Liste',
          method: 'GET',
          path: '/api/iade-islemleri/depo-iadeleri/giden',
        ),
        EndpointSpec(
          label: 'Detay',
          method: 'GET',
          path: '/api/iade-islemleri/depo-iadeleri/giden/{seri}/{sira}',
        ),
        EndpointSpec(
          label: 'Olustur',
          method: 'POST',
          path: '/api/iade-islemleri/depo-iadeleri/giden',
        ),
        EndpointSpec(
          label: 'E-Irsaliye',
          method: 'POST',
          path:
              '/api/iade-islemleri/depo-iadeleri/giden/{seri}/{sira}/e-irsaliye',
        ),
        EndpointSpec(
          label: 'PDF',
          method: 'GET',
          path:
              '/api/iade-islemleri/depo-iadeleri/giden/{seri}/{sira}/e-irsaliye/pdf',
        ),
      ],
      uiNotes: <String>[
        'Bu ekran depolar arasi sevkin iade varyanti gibi dusunulmeli.',
        'Create request icinde warehouseOrderLineGuid yoktur; siparis baglama yapilmaz.',
      ],
    ),
    'iade-islemleri.gelen-depo-iadeleri': const MenuBlueprint(
      title: 'Gelen Depo Iadeleri',
      subtitle:
          'Iadelerin hedef sube perspektifinden liste ve detay akislarini gosterir.',
      endpoints: <EndpointSpec>[
        EndpointSpec(
          label: 'Liste',
          method: 'GET',
          path: '/api/iade-islemleri/depo-iadeleri/gelen',
        ),
        EndpointSpec(
          label: 'Detay',
          method: 'GET',
          path: '/api/iade-islemleri/depo-iadeleri/gelen/{seri}/{sira}',
        ),
      ],
      uiNotes: <String>[
        'Kaynak ve hedef sube perspektifi ayrilmali; me.modules tarafinda iki ayri menu olarak cizilmeli.',
      ],
    ),
  };

  static MenuBlueprint _generic(MenuEntry entry) {
    final basePath = '/api/${entry.moduleCode}/${entry.menuCode}';
    final actions = entry.actions.map((item) => item.code).toSet();
    final endpoints = <EndpointSpec>[
      if (actions.contains('list') || actions.isEmpty)
        EndpointSpec(label: 'Liste', method: 'GET', path: basePath),
      if (actions.contains('detail'))
        EndpointSpec(
          label: 'Detay',
          method: 'GET',
          path: '$basePath/{seri}/{sira}',
        ),
      if (actions.contains('create'))
        EndpointSpec(label: 'Olustur', method: 'POST', path: basePath),
      if (actions.contains('update'))
        EndpointSpec(label: 'Guncelle', method: 'PUT', path: '$basePath/{id}'),
    ];

    return MenuBlueprint(
      title: entry.displayMenuName,
      subtitle:
          'Bu ekran me.modules cevabina gore dinamik cizilecek sekilde hazirlandi.',
      endpoints: endpoints,
      uiNotes: <String>[
        'Sol menu, ekran gorunurlugu ve buton yetkileri GET /api/auth/me cevabindan uretilmeli.',
        'Liste ekranlarinda StartDate ve EndDate filtreleri zorunlu kabul edilmeli.',
        'WarehouseNo verilmezse backend JWT icindeki depo bilgisini kullanabilir.',
        '401, 403, 404, 409 ve 501 cevaplari problem+json formatinda islenmeli.',
      ],
    );
  }
}
