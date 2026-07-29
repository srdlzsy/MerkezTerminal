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
    'siparis-islemleri.onerilen-firma-siparisleri': const MenuBlueprint(
      title: 'Onerilen Firma Siparisleri',
      subtitle:
          'Tedarikciye gore onerilen firma siparislerini hesaplar ve siparise cevirir.',
      endpoints: <EndpointSpec>[
        EndpointSpec(
          label: 'Liste',
          method: 'GET',
          path: '/api/siparis-islemleri/onerilen-firma-siparisleri',
        ),
        EndpointSpec(
          label: 'Siparise Cevir',
          method: 'POST',
          path:
              '/api/siparis-islemleri/onerilen-firma-siparisleri/convert-to-order',
        ),
      ],
      uiNotes: <String>[
        'Kullanici once firma/tedarikci secer ve onerileri listeler.',
        'Satirlar secildikten sonra miktar degistirilip verilen firma siparisine cevrilir.',
      ],
    ),
    'siparis-islemleri.onerilen-depo-siparisleri': const MenuBlueprint(
      title: 'Onerilen Depo Siparisleri',
      subtitle:
          'Kaynak depodaki stok durumuna gore onerilen depo siparislerini yonetir.',
      endpoints: <EndpointSpec>[
        EndpointSpec(
          label: 'Liste',
          method: 'GET',
          path: '/api/siparis-islemleri/onerilen-depo-siparisleri',
        ),
        EndpointSpec(
          label: 'Siparise Cevir',
          method: 'POST',
          path:
              '/api/siparis-islemleri/onerilen-depo-siparisleri/convert-to-order',
        ),
      ],
      uiNotes: <String>[
        'Kullanici once kaynak depo secer ve onerileri listeler.',
        'Satirlar secildikten sonra miktar degistirilip verilen depo siparisine cevrilir.',
      ],
    ),
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
        'Satir eslestirmesi sistem tarafinda korunur; kullaniciya stok ve miktar bilgisi yeterlidir.',
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
        'Detaydaki satir eslestirmesi mal kabul ekranina sistem tarafindan tasinmali.',
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
          'Bekleyen gelen sevk ve iadeleri listeler, satir bazli kabul akisini yonetir.',
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
        'Liste bekleyen gelen sevkleri ve gelen depo iadelerini gosterir; yeni bos fis acilmaz.',
        'isReturn=false normal gelen depo sevkini, isReturn=true gelen depo iadesini ifade eder.',
        'UI her satir icin sayilan miktari sevk miktariyla onceden doldurabilir.',
        'Eksik veya fazla durumda kullanicidan acik fark onayi alinmali.',
      ],
    ),
    'mal-kabul-islemleri.mal-kabul-farklari': const MenuBlueprint(
      title: 'Mal Kabul Farklari',
      subtitle:
          'Kabul edilmis depo sevki veya depo iadesi satirlarindaki eksik/fazla farklarini listeler.',
      endpoints: <EndpointSpec>[
        EndpointSpec(
          label: 'Liste',
          method: 'GET',
          path: '/api/mal-kabul-islemleri/mal-kabul-farklari',
        ),
        EndpointSpec(
          label: 'Kabul Ettigim',
          method: 'GET',
          path: '/api/mal-kabul-islemleri/mal-kabul-farklari/accepted',
        ),
        EndpointSpec(
          label: 'Olusturdugum',
          method: 'GET',
          path: '/api/mal-kabul-islemleri/mal-kabul-farklari/created',
        ),
      ],
      uiNotes: <String>[
        'StartDate ve EndDate zorunludur; WarehouseNo verilmezse backend JWT deposunu kullanir.',
        'scope=accepted kullanicinin deposunun kabul ettigi evraklari, scope=created kendi olusturdugu/gonderdigi evraklari listeler.',
        'Normal sevk ve depo iadesi ayni listede gelir; isReturn alanina gore rozet basilabilir.',
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
        'Bu iade akisinda siparis baglantisi kullanilmaz.',
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
