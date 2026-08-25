# FurpaMerkezApi UI API Dokumani

Bu dokuman, mevcut backend durumuna gore frontend/UI tasarimi ve entegrasyonu icin hazirlanmistir.

## Genel Bilgiler

- API JSON dondurur.
- JSON alanlari `camelCase` gelir.
- Tarihler `ISO 8601` formatindadir.
- Yetki sistemi `module > menu > action` mantigindadir.
- UI menu agaci ve buton gorunurlugu `me` cevabindan uretilmelidir.
- Menu/route gorunurlugu icin aksiyon endpoint yetkileri kullanilmamalidir. Normal ekranlar `{module}.{menu}.page`, tanim/yonetim ekranlari `{module}.{menu}.manage` yetkisine bakmalidir.
- `list`, `detail`, `create`, `update`, `delete`, `archive`, `transfer` gibi yetkiler API endpoint ve buton/aksiyon kontroludur; tek basina sol menu veya route acma sebebi olmamalidir.
- Depo yetkisi backend tarafinda merkezi ve permission bazli uygulanir. Kullanici sadece JWT icindeki kendi deposunda islem yapar; baska depo veya tum depo kapsami icin ilgili menuye ait `{module}.{menu}.all-warehouses` yetkisi gerekir.
- `Admin`/`Administrator` rolu backend tarafinda tam yetkili kabul edilir. UI tarafinda yine role name'e gore ekran acilmamalidir; menu, route, buton ve depo secici kararlari `login.user.permissions` veya `GET /api/auth/me` cevabindaki `permissions` listesine gore verilmelidir.
- UI depo secici/filtresi gosterecegi zaman role bakmamalidir. Secili ekrandaki permission setinde ilgili `*.all-warehouses` kodu varsa depo secici acilir; yoksa depo alani gizlenir veya kilitlenir.
- Liste/rapor endpointlerinde `*.all-warehouses` yetkisi olan kullanici `WarehouseNo`/`warehouseNo` alanini bos veya `null` gonderirse endpoint destekliyorsa tum depolar doner; belirli depo icin depo no gonderilir. Tek depo gerektiren create/update/detail islemlerinde `null` tum depo anlamina gelmez; backend token deposunu varsayar veya ilgili islem icin secili depo bekler.
- Tum depolari listeleyen kullanici detay ekranina gecis icin UI, secilen satirdaki depo bilgisini kullanmalidir. Detay endpointine mumkunse satirda gelen `warehouseNo`, `sourceWarehouseNo`, `targetWarehouseNo`, `branchNo` veya ilgili islem deposu query/body alanina yazilmalidir.
- Kasa Sayimlari ozelinde UI `warehouseNo` bos gonderirse backend sadece kullanicida ilgili `kasa-islemleri.kasa-sayimlari.all-warehouses` yetkisi varsa `documentSerie` icinden subeyi cozer; ornek `F116.54` -> `116`. Bu yetki yoksa eski davranis korunur ve oturumdaki kullanici deposu kullanilir.
- Kasa Sayimlari ozelinde kullanicida ilgili `kasa-islemleri.kasa-sayimlari.all-warehouses` yetkisi varsa ve `documentSerie` sube bilgisi iceriyorsa backend hedef subeyi seriden alir; ornek `F116.57?warehouseNo=1` isteginde hedef belge subesi `116` kabul edilir. Bu senaryoda `warehouseNo` UI/oturum deposu gibi gelse bile hedef belge subesi olarak yorumlanmaz.
- Icmal Kaydi Girisi create ozelinde `kasa-islemleri.icmal-kaydi-girisi.all-warehouses` yetkisi olan kullanici hedef subeyi secmeli ve body'de `warehouseNo` gondermelidir; bos gonderirse API `400 Bad Request` doner.
- Ilgili `*.all-warehouses` yetkisi olmayan kullanici farkli `WarehouseNo`, `BranchNo` veya islem deposu gonderirse API `403 Forbidden` doner.
- Tarih aralikli liste endpointlerinde `StartDate` ve `EndDate` zorunludur; depo yetkisi yoksa `WarehouseNo` verilmez ve backend JWT icindeki depoyu kullanir.
- Development CORS originleri su an `http://localhost:5176`, `http://localhost:5173` ve `http://localhost:4200` icin aciktir.

Timeout ve tekrar deneme notu:

- API tarafinda SQL command timeout degerleri `DatabaseCommandTimeouts` konfigurasyonundan okunur; varsayilan appsettings degeri `300` saniyedir.
- `MikroReadSeconds` liste/detay/rapor okumalari, `MikroWriteSeconds` create/update/delete yazma islemleri icin kullanilir. `AuthSeconds`, `FurpaSeconds`, `AxataSeconds`, `PuanSeconds` ve `ShopigoCiroSeconds` ilgili DB context'leri icindir.
- Raw SQL ile yazilmis liste/arama/rapor komutlari da genel olarak `300` saniye bekleyecek sekilde ayarlanmistir.
- `MikroApi:TimeoutSeconds` varsayilan appsettings'te `300` saniyedir. Yazma rotasi `MikroApi` ise UI bu sureyi de dikkate almalidir.
- Terminal, mobil ve web istemcileri liste ve create isteklerinde HTTP client timeout degerini en az `300` saniye yapmalidir. Subede internet zayifsa API islemi devam ederken istemci 30-60 saniyede vazgecerse kullanici timeout gorur ve kontrolsuz tekrar basabilir.
- POST/create timeout gorurse UI hemen yeni istek kimligi veya farkli body uretmemeli; mumkunse ayni payload ile guvenli retry yapmali veya liste/detay yenileyerek evrakin olusup olusmadigini kontrol etmelidir.

Route parametre notu:

- Controller route template'lerinde belge anahtarlari genel olarak `{documentSerie}/{documentOrderNo}` seklindedir.
- Dokumanin eski akis semalarinda gecen `{seri}/{sira}` ifadesi ayni path degerlerinin kisa yazimidir; UI yeni kodda controller'daki canonical adlari `documentSerie` ve `documentOrderNo` olarak kullanmalidir.
- `{id:guid}`, `{documentOrderNo:int}` gibi ASP.NET route constraint'leri dokuman orneklerinde genelde `{id}`, `{documentOrderNo}` olarak sade yazilir; path formatini degistirmez.

Controller'da acik olan pratik alias/canonical route'lar:

- `GET /api/arama-islemleri/barkodlar/{barcode}/cozumle`
- `GET /api/arama-islemleri/urunler/{stockCode}/cari-onerileri`
- `GET /api/arama-islemleri/urunler/{stockCode}/son-kunye`
- `GET /api/siparis-islemleri/alinan-depo-siparisleri/{documentSerie}/{documentOrderNo}`
- `GET /api/siparis-islemleri/alinan-depo-siparisleri/key/{documentKey}`
- `GET /api/siparis-islemleri/alinan-firma-siparisleri/{documentSerie}/{documentOrderNo}`
- `GET /api/siparis-islemleri/alinan-firma-siparisleri/key/{documentKey}`
- `GET /api/siparis-islemleri/verilen-depo-siparisleri/{documentSerie}/{documentOrderNo}`
- `GET /api/siparis-islemleri/verilen-depo-siparisleri/key/{documentKey}`
- `GET /api/siparis-islemleri/verilen-firma-siparisleri/{documentSerie}/{documentOrderNo}`
- `GET /api/siparis-islemleri/verilen-firma-siparisleri/key/{documentKey}`
- `GET /api/sevk-islemleri/depolar-arasi-sevkler/{documentSerie}/{documentOrderNo}`, `POST /api/sevk-islemleri/depolar-arasi-sevkler/{documentSerie}/{documentOrderNo}/e-irsaliye` ve `GET /api/sevk-islemleri/depolar-arasi-sevkler/{documentSerie}/{documentOrderNo}/e-irsaliye/pdf`, `giden` alias'i ile ayni outgoing akisi calistirir.
- `GET /api/sevk-islemleri/depolar-arasi-sevkler/giden/{documentSerie}/{documentOrderNo}`, `POST /api/sevk-islemleri/depolar-arasi-sevkler/giden/{documentSerie}/{documentOrderNo}/e-irsaliye` ve `GET /api/sevk-islemleri/depolar-arasi-sevkler/giden/{documentSerie}/{documentOrderNo}/e-irsaliye/pdf`
- `GET /api/sevk-islemleri/depolar-arasi-sevkler/gelen/{documentSerie}/{documentOrderNo}`
- `GET /api/sevk-islemleri/firma-sevkleri/{documentSerie}/{documentOrderNo}`, `POST /api/sevk-islemleri/firma-sevkleri/{documentSerie}/{documentOrderNo}/e-irsaliye` ve `GET /api/sevk-islemleri/firma-sevkleri/{documentSerie}/{documentOrderNo}/e-irsaliye/pdf`, `giden` alias'i ile ayni outgoing akisi calistirir.
- `GET /api/sevk-islemleri/firma-sevkleri/giden/{documentSerie}/{documentOrderNo}`, `POST /api/sevk-islemleri/firma-sevkleri/giden/{documentSerie}/{documentOrderNo}/e-irsaliye` ve `GET /api/sevk-islemleri/firma-sevkleri/giden/{documentSerie}/{documentOrderNo}/e-irsaliye/pdf`
- `GET /api/sevk-islemleri/firma-sevkleri/gelen/{documentSerie}/{documentOrderNo}`
- `GET /api/iade-islemleri/depo-iadeleri/{documentSerie}/{documentOrderNo}`, `POST /api/iade-islemleri/depo-iadeleri/{documentSerie}/{documentOrderNo}/e-irsaliye` ve `GET /api/iade-islemleri/depo-iadeleri/{documentSerie}/{documentOrderNo}/e-irsaliye/pdf`, `giden` alias'i ile ayni outgoing akisi calistirir.
- `GET /api/iade-islemleri/depo-iadeleri/giden/{documentSerie}/{documentOrderNo}`, `POST /api/iade-islemleri/depo-iadeleri/giden/{documentSerie}/{documentOrderNo}/e-irsaliye` ve `GET /api/iade-islemleri/depo-iadeleri/giden/{documentSerie}/{documentOrderNo}/e-irsaliye/pdf`
- `GET /api/iade-islemleri/depo-iadeleri/gelen/{documentSerie}/{documentOrderNo}`
- `GET /api/iade-islemleri/firma-iadeleri/{documentSerie}/{documentOrderNo}`, `POST /api/iade-islemleri/firma-iadeleri/{documentSerie}/{documentOrderNo}/e-irsaliye` ve `GET /api/iade-islemleri/firma-iadeleri/{documentSerie}/{documentOrderNo}/e-irsaliye/pdf`
- `GET /api/mal-kabul-islemleri/depo-mal-kabulleri/{documentSerie}/{documentOrderNo}` ve `POST /api/mal-kabul-islemleri/depo-mal-kabulleri/{documentSerie}/{documentOrderNo}/kabul`
- `GET /api/mal-kabul-islemleri/mal-kabuller/depo-sevkleri/{documentSerie}/{documentOrderNo}` ve `POST /api/mal-kabul-islemleri/mal-kabuller/depo-sevkleri/{documentSerie}/{documentOrderNo}/kabul`, depo mal kabul detay/kabul endpointinin eski menu uyum alias'idir.
- `GET /api/mal-kabul-islemleri/firma-mal-kabulleri/{documentSerie}/{documentOrderNo}`
- `GET /api/mal-kabul-islemleri/firma-mal-kabulleri/resmi-belge/ettn/{ettn}` ve geriye uyumlu `GET /api/mal-kabul-islemleri/firma-mal-kabulleri/e-irsaliye/ettn/{ettn}`
- `GET /api/stok-islemleri/zayiat-fisleri/{documentSerie}/{documentOrderNo}`
- `GET /api/stok-islemleri/masraf-fisleri/{documentSerie}/{documentOrderNo}`
- `GET /api/stok-islemleri/virmanlar/{documentSerie}/{documentOrderNo}`
- `GET /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}`, `GET /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/detaylar`, `GET /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/banknot-hareketleri`, `GET /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/hediye-ceki-hareketleri`
- `PUT /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/detaylar`, `PUT /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/banknot-hareketleri`, `PUT /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/hediye-ceki-hareketleri` ve `DELETE /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}`

### Tum Depo Yetki Modeli

- Depo kapsamli menu/action setlerinde `all-warehouses` aksiyonu bulunur. Kod formati `{module}.{menu}.all-warehouses` seklindedir.
- UI depo secici gostermek icin role degil, aktif kullanicinin `permissions` listesindeki ilgili `all-warehouses` koduna bakmalidir.
- Ornek: stok raporlari icin tum sube yetkisi `rapor-islemleri.stok-raporlari.all-warehouses`; belge akis icin `operasyon-islemleri.belge-akis-takibi.all-warehouses`; kasa sayimi goruntuleme icin `kasa-islemleri.kasa-sayimlari.all-warehouses`; icmal girisi icin `kasa-islemleri.icmal-kaydi-girisi.all-warehouses`; POS muhasebe aktarimi icin `entegrasyon-islemleri.pos-muhasebe-aktarimi.all-warehouses`.
- Admin rolu migration/seed ile bu yetkilerin tamamini alir. Admin olmayan role modul bazli tum depo verilecekse ilgili menu icin `page` veya `manage`, gerekli `list/detail/create/update/delete` aksiyonlari ve `all-warehouses` birlikte atanir.
- Backend policy'deki aksiyon kodundan tum depo kodunu turetir: `rapor-islemleri.stok-raporlari.list` isteginde depo secimi icin `rapor-islemleri.stok-raporlari.all-warehouses` aranir.
- Bu yetkileri Auth DB'ye ekleyen migration: `20260727150749_AddAllWarehouseScopePermissions`.

### Tum Modul Yetki Matrisi

Bu tablo UI icin ana permission referansidir. Kaynak kod tarafi `PermissionCatalog` uzerinden uretilir. UI menuyu ve route guard'i sadece `Menu/route yetkisi` kolonuyla acmalidir. `Endpoint/buton yetkileri` kolonundaki izinler liste, detay, kaydetme, silme, arsivleme, aktarma gibi islem butonlari ve API cagri yetkileri icindir. `Depo kapsami` kolonundaki kod varsa ilgili ekranda baska depo/tum depo secimi bu yetkiye gore acilir.

| Modul | Menu/Ekran | Menu/route yetkisi | Endpoint/buton yetkileri | Depo kapsami |
|---|---|---|---|---|
| `kullanici-islemleri` | `roller` | `kullanici-islemleri.roller.manage` | - | `-` |
| `kullanici-islemleri` | `yetkiler` | `kullanici-islemleri.yetkiler.manage` | - | `-` |
| `kullanici-islemleri` | `kullanicilar` | `kullanici-islemleri.kullanicilar.manage` | - | `-` |
| `home` | `depo-oncelikleri` | `home.depo-oncelikleri.page` | - | `home.depo-oncelikleri.all-warehouses` |
| `arama-islemleri` | `fiyat-gor` | `arama-islemleri.fiyat-gor.page` | `arama-islemleri.fiyat-gor.list` | `arama-islemleri.fiyat-gor.all-warehouses` |
| `arama-islemleri` | `cari-bul` | `arama-islemleri.cari-bul.page` | `arama-islemleri.cari-bul.list` | `arama-islemleri.cari-bul.all-warehouses` |
| `green-grocer` (`Manav`) | `reports` (`ManavRaporlari`) | `green-grocer.reports.page` | `green-grocer.reports.list`<br>`green-grocer.reports.detail`<br>`green-grocer.reports.update` | `green-grocer.reports.all-warehouses` |
| `green-grocer` (`Manav`) | `product-case-profiles` (`ManavKasaProfilleri`) | `green-grocer.product-case-profiles.manage` | `green-grocer.product-case-profiles.list`<br>`green-grocer.product-case-profiles.detail`<br>`green-grocer.product-case-profiles.create`<br>`green-grocer.product-case-profiles.update`<br>`green-grocer.product-case-profiles.delete` | `green-grocer.product-case-profiles.all-warehouses` |
| `green-grocer` (`Manav`) | `operations` (`ManavOperasyonPaneli`) | `green-grocer.operations.page` | `green-grocer.operations.list`<br>`green-grocer.operations.create` | `green-grocer.operations.all-warehouses` |
| `ortak-islemler` | `sikayet-oneri` | `ortak-islemler.sikayet-oneri.page` | `ortak-islemler.sikayet-oneri.list`<br>`ortak-islemler.sikayet-oneri.detail`<br>`ortak-islemler.sikayet-oneri.update`<br>`ortak-islemler.sikayet-oneri.list-all` | `-` |
| `ortak-islemler` | `duyurular` | `ortak-islemler.duyurular.page` | `ortak-islemler.duyurular.list`<br>`ortak-islemler.duyurular.detail`<br>`ortak-islemler.duyurular.create`<br>`ortak-islemler.duyurular.update`<br>`ortak-islemler.duyurular.archive` | `ortak-islemler.duyurular.all-warehouses` |
| `ayar-islemleri` | `cihazlar` | `ayar-islemleri.cihazlar.manage` | `ayar-islemleri.cihazlar.list`<br>`ayar-islemleri.cihazlar.detail`<br>`ayar-islemleri.cihazlar.create`<br>`ayar-islemleri.cihazlar.update` | `ayar-islemleri.cihazlar.all-warehouses` |
| `ayar-islemleri` | `sube-ayarlari` | `ayar-islemleri.sube-ayarlari.manage` | `ayar-islemleri.sube-ayarlari.list`<br>`ayar-islemleri.sube-ayarlari.detail`<br>`ayar-islemleri.sube-ayarlari.create`<br>`ayar-islemleri.sube-ayarlari.update` | `ayar-islemleri.sube-ayarlari.all-warehouses` |
| `ayar-islemleri` | `kasa-pos-terminalleri` | `ayar-islemleri.kasa-pos-terminalleri.manage` | `ayar-islemleri.kasa-pos-terminalleri.list`<br>`ayar-islemleri.kasa-pos-terminalleri.detail`<br>`ayar-islemleri.kasa-pos-terminalleri.create`<br>`ayar-islemleri.kasa-pos-terminalleri.update` | `ayar-islemleri.kasa-pos-terminalleri.all-warehouses` |
| `ayar-islemleri` | `kasiyerler` | `ayar-islemleri.kasiyerler.manage` | `ayar-islemleri.kasiyerler.list`<br>`ayar-islemleri.kasiyerler.detail`<br>`ayar-islemleri.kasiyerler.create`<br>`ayar-islemleri.kasiyerler.update` | `ayar-islemleri.kasiyerler.all-warehouses` |
| `ayar-islemleri` | `soforler` | `ayar-islemleri.soforler.manage` | `ayar-islemleri.soforler.list`<br>`ayar-islemleri.soforler.detail`<br>`ayar-islemleri.soforler.create`<br>`ayar-islemleri.soforler.update`<br>`ayar-islemleri.soforler.delete` | `ayar-islemleri.soforler.all-warehouses` |
| `ayar-islemleri` | `b2b-ayarlari` | `ayar-islemleri.b2b-ayarlari.manage` | `ayar-islemleri.b2b-ayarlari.list`<br>`ayar-islemleri.b2b-ayarlari.detail`<br>`ayar-islemleri.b2b-ayarlari.create`<br>`ayar-islemleri.b2b-ayarlari.update`<br>`ayar-islemleri.b2b-ayarlari.delete` | `ayar-islemleri.b2b-ayarlari.all-warehouses` |
| `siparis-islemleri` | `alinan-depo-siparisleri` | `siparis-islemleri.alinan-depo-siparisleri.page` | `siparis-islemleri.alinan-depo-siparisleri.list`<br>`siparis-islemleri.alinan-depo-siparisleri.detail`<br>`siparis-islemleri.alinan-depo-siparisleri.create`<br>`siparis-islemleri.alinan-depo-siparisleri.update` | `siparis-islemleri.alinan-depo-siparisleri.all-warehouses` |
| `siparis-islemleri` | `verilen-depo-siparisleri` | `siparis-islemleri.verilen-depo-siparisleri.page` | `siparis-islemleri.verilen-depo-siparisleri.list`<br>`siparis-islemleri.verilen-depo-siparisleri.detail`<br>`siparis-islemleri.verilen-depo-siparisleri.create`<br>`siparis-islemleri.verilen-depo-siparisleri.update` | `siparis-islemleri.verilen-depo-siparisleri.all-warehouses` |
| `siparis-islemleri` | `alinan-firma-siparisleri` | `siparis-islemleri.alinan-firma-siparisleri.page` | `siparis-islemleri.alinan-firma-siparisleri.list`<br>`siparis-islemleri.alinan-firma-siparisleri.detail`<br>`siparis-islemleri.alinan-firma-siparisleri.create`<br>`siparis-islemleri.alinan-firma-siparisleri.update` | `siparis-islemleri.alinan-firma-siparisleri.all-warehouses` |
| `siparis-islemleri` | `verilen-firma-siparisleri` | `siparis-islemleri.verilen-firma-siparisleri.page` | `siparis-islemleri.verilen-firma-siparisleri.list`<br>`siparis-islemleri.verilen-firma-siparisleri.detail`<br>`siparis-islemleri.verilen-firma-siparisleri.create`<br>`siparis-islemleri.verilen-firma-siparisleri.update` | `siparis-islemleri.verilen-firma-siparisleri.all-warehouses` |
| `siparis-islemleri` | `onerilen-depo-siparisleri` | `siparis-islemleri.onerilen-depo-siparisleri.page` | `siparis-islemleri.onerilen-depo-siparisleri.list`<br>`siparis-islemleri.onerilen-depo-siparisleri.create` | `siparis-islemleri.onerilen-depo-siparisleri.all-warehouses` |
| `siparis-islemleri` | `onerilen-firma-siparisleri` | `siparis-islemleri.onerilen-firma-siparisleri.page` | `siparis-islemleri.onerilen-firma-siparisleri.list`<br>`siparis-islemleri.onerilen-firma-siparisleri.create` | `siparis-islemleri.onerilen-firma-siparisleri.all-warehouses` |
| `sevk-islemleri` | `giden-depolar-arasi-sevkler` | `sevk-islemleri.giden-depolar-arasi-sevkler.page` | `sevk-islemleri.giden-depolar-arasi-sevkler.list`<br>`sevk-islemleri.giden-depolar-arasi-sevkler.detail`<br>`sevk-islemleri.giden-depolar-arasi-sevkler.create`<br>`sevk-islemleri.giden-depolar-arasi-sevkler.update` | `sevk-islemleri.giden-depolar-arasi-sevkler.all-warehouses` |
| `sevk-islemleri` | `gelen-depolar-arasi-sevkler` | `sevk-islemleri.gelen-depolar-arasi-sevkler.page` | `sevk-islemleri.gelen-depolar-arasi-sevkler.list`<br>`sevk-islemleri.gelen-depolar-arasi-sevkler.detail`<br>`sevk-islemleri.gelen-depolar-arasi-sevkler.create`<br>`sevk-islemleri.gelen-depolar-arasi-sevkler.update` | `sevk-islemleri.gelen-depolar-arasi-sevkler.all-warehouses` |
| `sevk-islemleri` | `giden-firma-sevkleri` | `sevk-islemleri.giden-firma-sevkleri.page` | `sevk-islemleri.giden-firma-sevkleri.list`<br>`sevk-islemleri.giden-firma-sevkleri.detail`<br>`sevk-islemleri.giden-firma-sevkleri.create`<br>`sevk-islemleri.giden-firma-sevkleri.update` | `sevk-islemleri.giden-firma-sevkleri.all-warehouses` |
| `sevk-islemleri` | `gelen-firma-sevkleri` | `sevk-islemleri.gelen-firma-sevkleri.page` | `sevk-islemleri.gelen-firma-sevkleri.list`<br>`sevk-islemleri.gelen-firma-sevkleri.detail`<br>`sevk-islemleri.gelen-firma-sevkleri.create`<br>`sevk-islemleri.gelen-firma-sevkleri.update` | `sevk-islemleri.gelen-firma-sevkleri.all-warehouses` |
| `iade-islemleri` | `giden-depo-iadeleri` | `iade-islemleri.giden-depo-iadeleri.page` | `iade-islemleri.giden-depo-iadeleri.list`<br>`iade-islemleri.giden-depo-iadeleri.detail`<br>`iade-islemleri.giden-depo-iadeleri.create`<br>`iade-islemleri.giden-depo-iadeleri.update` | `iade-islemleri.giden-depo-iadeleri.all-warehouses` |
| `iade-islemleri` | `gelen-depo-iadeleri` | `iade-islemleri.gelen-depo-iadeleri.page` | `iade-islemleri.gelen-depo-iadeleri.list`<br>`iade-islemleri.gelen-depo-iadeleri.detail` | `iade-islemleri.gelen-depo-iadeleri.all-warehouses` |
| `iade-islemleri` | `firma-iadeleri` | `iade-islemleri.firma-iadeleri.page` | `iade-islemleri.firma-iadeleri.list`<br>`iade-islemleri.firma-iadeleri.detail`<br>`iade-islemleri.firma-iadeleri.create`<br>`iade-islemleri.firma-iadeleri.update` | `iade-islemleri.firma-iadeleri.all-warehouses` |
| `mal-kabul-islemleri` | `depo-mal-kabulleri` | `mal-kabul-islemleri.depo-mal-kabulleri.page` | `mal-kabul-islemleri.depo-mal-kabulleri.list`<br>`mal-kabul-islemleri.depo-mal-kabulleri.detail`<br>`mal-kabul-islemleri.depo-mal-kabulleri.create`<br>`mal-kabul-islemleri.depo-mal-kabulleri.update` | `mal-kabul-islemleri.depo-mal-kabulleri.all-warehouses` |
| `mal-kabul-islemleri` | `mal-kabul-farklari` | `mal-kabul-islemleri.mal-kabul-farklari.page` | `mal-kabul-islemleri.mal-kabul-farklari.list` | `mal-kabul-islemleri.mal-kabul-farklari.all-warehouses` |
| `mal-kabul-islemleri` | `firma-mal-kabulleri` | `mal-kabul-islemleri.firma-mal-kabulleri.page` | `mal-kabul-islemleri.firma-mal-kabulleri.list`<br>`mal-kabul-islemleri.firma-mal-kabulleri.detail`<br>`mal-kabul-islemleri.firma-mal-kabulleri.create`<br>`mal-kabul-islemleri.firma-mal-kabulleri.update` | `mal-kabul-islemleri.firma-mal-kabulleri.all-warehouses` |
| `stok-islemleri` | `zayiat-fisleri` | `stok-islemleri.zayiat-fisleri.page` | `stok-islemleri.zayiat-fisleri.list`<br>`stok-islemleri.zayiat-fisleri.detail`<br>`stok-islemleri.zayiat-fisleri.create`<br>`stok-islemleri.zayiat-fisleri.update` | `stok-islemleri.zayiat-fisleri.all-warehouses` |
| `stok-islemleri` | `masraf-fisleri` | `stok-islemleri.masraf-fisleri.page` | `stok-islemleri.masraf-fisleri.list`<br>`stok-islemleri.masraf-fisleri.detail`<br>`stok-islemleri.masraf-fisleri.create`<br>`stok-islemleri.masraf-fisleri.update` | `stok-islemleri.masraf-fisleri.all-warehouses` |
| `stok-islemleri` | `sayim-sonuclari` | `stok-islemleri.sayim-sonuclari.page` | `stok-islemleri.sayim-sonuclari.list`<br>`stok-islemleri.sayim-sonuclari.detail`<br>`stok-islemleri.sayim-sonuclari.create`<br>`stok-islemleri.sayim-sonuclari.update` | `stok-islemleri.sayim-sonuclari.all-warehouses` |
| `stok-islemleri` | `virmanlar` | `stok-islemleri.virmanlar.page` | `stok-islemleri.virmanlar.list`<br>`stok-islemleri.virmanlar.detail`<br>`stok-islemleri.virmanlar.create`<br>`stok-islemleri.virmanlar.update` | `stok-islemleri.virmanlar.all-warehouses` |
| `stok-islemleri` | `stok-anomali-merkezi` | `stok-islemleri.stok-anomali-merkezi.page` | `stok-islemleri.stok-anomali-merkezi.list`<br>`stok-islemleri.stok-anomali-merkezi.detail`<br>`stok-islemleri.stok-anomali-merkezi.update`<br>`stok-islemleri.stok-anomali-merkezi.scan` | `stok-islemleri.stok-anomali-merkezi.all-warehouses` |
| `rapor-islemleri` | `satis-analizleri` | `rapor-islemleri.satis-analizleri.page` | `rapor-islemleri.satis-analizleri.list` | `rapor-islemleri.satis-analizleri.all-warehouses` |
| `rapor-islemleri` | `stok-raporlari` | `rapor-islemleri.stok-raporlari.page` | `rapor-islemleri.stok-raporlari.list` | `rapor-islemleri.stok-raporlari.all-warehouses` |
| `rapor-islemleri` | `promosyon-raporlari` | `rapor-islemleri.promosyon-raporlari.page` | `rapor-islemleri.promosyon-raporlari.list` | `rapor-islemleri.promosyon-raporlari.all-warehouses` |
| `rapor-islemleri` | `tedarikci-performans-karnesi` | `rapor-islemleri.tedarikci-performans-karnesi.page` | `rapor-islemleri.tedarikci-performans-karnesi.list`<br>`rapor-islemleri.tedarikci-performans-karnesi.detail` | `rapor-islemleri.tedarikci-performans-karnesi.all-warehouses` |
| `operasyon-islemleri` | `operations` (`Operasyonlar`) | `operasyon-islemleri.operations.page` | `operasyon-islemleri.operations.list`<br>`operasyon-islemleri.operations.detail`<br>`operasyon-islemleri.operations.create`<br>`operasyon-islemleri.operations.update` | `operasyon-islemleri.operations.all-warehouses` |
| `operasyon-islemleri` | `belge-akis-takibi` | `operasyon-islemleri.belge-akis-takibi.page` | `operasyon-islemleri.belge-akis-takibi.list`<br>`operasyon-islemleri.belge-akis-takibi.detail` | `operasyon-islemleri.belge-akis-takibi.all-warehouses` |
| `operasyon-islemleri` | `depo-operasyon-paneli` | `operasyon-islemleri.depo-operasyon-paneli.page` | `operasyon-islemleri.depo-operasyon-paneli.list` | `operasyon-islemleri.depo-operasyon-paneli.all-warehouses` |
| `operasyon-islemleri` | `urun-dagilimlari` | `operasyon-islemleri.urun-dagilimlari.page` | `operasyon-islemleri.urun-dagilimlari.list`<br>`operasyon-islemleri.urun-dagilimlari.detail`<br>`operasyon-islemleri.urun-dagilimlari.create`<br>`operasyon-islemleri.urun-dagilimlari.update`<br>`operasyon-islemleri.urun-dagilimlari.delete` | `operasyon-islemleri.urun-dagilimlari.all-warehouses` |
| `duzeltme-islemleri` | `mikro-evrak-duzenleme` | `duzeltme-islemleri.mikro-evrak-duzenleme.page` | `duzeltme-islemleri.mikro-evrak-duzenleme.list`<br>`duzeltme-islemleri.mikro-evrak-duzenleme.detail`<br>`duzeltme-islemleri.mikro-evrak-duzenleme.update`<br>`duzeltme-islemleri.mikro-evrak-duzenleme.delete` | `duzeltme-islemleri.mikro-evrak-duzenleme.all-warehouses` |
| `entegrasyon-islemleri` | `axata-senkronizasyonu` | `entegrasyon-islemleri.axata-senkronizasyonu.page` | `entegrasyon-islemleri.axata-senkronizasyonu.list`<br>`entegrasyon-islemleri.axata-senkronizasyonu.detail`<br>`entegrasyon-islemleri.axata-senkronizasyonu.create`<br>`entegrasyon-islemleri.axata-senkronizasyonu.update` | `entegrasyon-islemleri.axata-senkronizasyonu.all-warehouses` |
| `entegrasyon-islemleri` | `pos-muhasebe-aktarimi` | `entegrasyon-islemleri.pos-muhasebe-aktarimi.page` | `entegrasyon-islemleri.pos-muhasebe-aktarimi.list`<br>`entegrasyon-islemleri.pos-muhasebe-aktarimi.detail`<br>`entegrasyon-islemleri.pos-muhasebe-aktarimi.create`<br>`entegrasyon-islemleri.pos-muhasebe-aktarimi.update` | `entegrasyon-islemleri.pos-muhasebe-aktarimi.all-warehouses` |
| `entegrasyon-islemleri` | `uyumsoft-e-fatura` | `entegrasyon-islemleri.uyumsoft-e-fatura.page` | `entegrasyon-islemleri.uyumsoft-e-fatura.list`<br>`entegrasyon-islemleri.uyumsoft-e-fatura.detail`<br>`entegrasyon-islemleri.uyumsoft-e-fatura.create`<br>`entegrasyon-islemleri.uyumsoft-e-fatura.update` | `entegrasyon-islemleri.uyumsoft-e-fatura.all-warehouses` |
| `entegrasyon-islemleri` | `uyumsoft-e-irsaliye` | `entegrasyon-islemleri.uyumsoft-e-irsaliye.page` | `entegrasyon-islemleri.uyumsoft-e-irsaliye.list`<br>`entegrasyon-islemleri.uyumsoft-e-irsaliye.detail`<br>`entegrasyon-islemleri.uyumsoft-e-irsaliye.create`<br>`entegrasyon-islemleri.uyumsoft-e-irsaliye.update` | `entegrasyon-islemleri.uyumsoft-e-irsaliye.all-warehouses` |
| `fatura-islemleri` | `fatura-goruntuleme` | `fatura-islemleri.fatura-goruntuleme.page` | `fatura-islemleri.fatura-goruntuleme.list`<br>`fatura-islemleri.fatura-goruntuleme.detail`<br>`fatura-islemleri.fatura-goruntuleme.update` | `fatura-islemleri.fatura-goruntuleme.all-warehouses` |
| `fatura-islemleri` | `fatura-gonderimi` | `fatura-islemleri.fatura-gonderimi.page` | `fatura-islemleri.fatura-gonderimi.list`<br>`fatura-islemleri.fatura-gonderimi.detail`<br>`fatura-islemleri.fatura-gonderimi.create` | `fatura-islemleri.fatura-gonderimi.all-warehouses` |
| `kasa-islemleri` | `kasa-sayimlari` | `kasa-islemleri.kasa-sayimlari.page` | `kasa-islemleri.kasa-sayimlari.list`<br>`kasa-islemleri.kasa-sayimlari.detail`<br>`kasa-islemleri.kasa-sayimlari.update`<br>`kasa-islemleri.kasa-sayimlari.delete` | `kasa-islemleri.kasa-sayimlari.all-warehouses` |
| `kasa-islemleri` | `icmal-kaydi-girisi` | `kasa-islemleri.icmal-kaydi-girisi.page` | `kasa-islemleri.icmal-kaydi-girisi.list`<br>`kasa-islemleri.icmal-kaydi-girisi.create` | `kasa-islemleri.icmal-kaydi-girisi.all-warehouses` |
| `kasa-islemleri` | `kasa-cirolari` | `kasa-islemleri.kasa-cirolari.page` | `kasa-islemleri.kasa-cirolari.list`<br>`kasa-islemleri.kasa-cirolari.detail` | `kasa-islemleri.kasa-cirolari.all-warehouses` |
| `kasa-islemleri` | `yeni-kasa-analizleri` | `kasa-islemleri.yeni-kasa-analizleri.page` | `kasa-islemleri.yeni-kasa-analizleri.list` | `kasa-islemleri.yeni-kasa-analizleri.all-warehouses` |
| `kasa-islemleri` | `kasa-ciro-aktarimi` | `kasa-islemleri.kasa-ciro-aktarimi.page` | `kasa-islemleri.kasa-ciro-aktarimi.list`<br>`kasa-islemleri.kasa-ciro-aktarimi.detail`<br>`kasa-islemleri.kasa-ciro-aktarimi.create` | `kasa-islemleri.kasa-ciro-aktarimi.all-warehouses` |
| `kasa-islemleri` | `kasa-hareket-aktarimi` | `kasa-islemleri.kasa-hareket-aktarimi.page` | `kasa-islemleri.kasa-hareket-aktarimi.list`<br>`kasa-islemleri.kasa-hareket-aktarimi.detail`<br>`kasa-islemleri.kasa-hareket-aktarimi.create`<br>`kasa-islemleri.kasa-hareket-aktarimi.update` | `kasa-islemleri.kasa-hareket-aktarimi.all-warehouses` |
| `kasa-islemleri` | `etiket-belgeleri` | `kasa-islemleri.etiket-belgeleri.page` | `kasa-islemleri.etiket-belgeleri.list`<br>`kasa-islemleri.etiket-belgeleri.detail`<br>`kasa-islemleri.etiket-belgeleri.create`<br>`kasa-islemleri.etiket-belgeleri.update` | `kasa-islemleri.etiket-belgeleri.all-warehouses` |
| `kasa-islemleri` | `manav-mal-kabul-etiket` (`ManavMalKabulVeEtiket`) | `kasa-islemleri.manav-mal-kabul-etiket.page` | `kasa-islemleri.manav-mal-kabul-etiket.list`<br>`kasa-islemleri.manav-mal-kabul-etiket.detail`<br>`kasa-islemleri.manav-mal-kabul-etiket.create`<br>`kasa-islemleri.manav-mal-kabul-etiket.update`<br>`kasa-islemleri.manav-mal-kabul-etiket.delete`<br>`kasa-islemleri.manav-mal-kabul-etiket.transfer` | `kasa-islemleri.manav-mal-kabul-etiket.all-warehouses` |
| `kasa-islemleri` | `kunye-etiket-yazdirma` | `kasa-islemleri.kunye-etiket-yazdirma.page` | `kasa-islemleri.kunye-etiket-yazdirma.list`<br>`kasa-islemleri.kunye-etiket-yazdirma.detail`<br>`kasa-islemleri.kunye-etiket-yazdirma.create`<br>`kasa-islemleri.kunye-etiket-yazdirma.update` | `kasa-islemleri.kunye-etiket-yazdirma.all-warehouses` |
| `kasa-islemleri` | `manav-kunye-etiket-yazdirma` | `kasa-islemleri.manav-kunye-etiket-yazdirma.page` | `kasa-islemleri.manav-kunye-etiket-yazdirma.list` | `kasa-islemleri.manav-kunye-etiket-yazdirma.all-warehouses` |
| `kasa-islemleri` | `birlik-kart-sorgulama` | `kasa-islemleri.birlik-kart-sorgulama.page` | `kasa-islemleri.birlik-kart-sorgulama.list`<br>`kasa-islemleri.birlik-kart-sorgulama.detail`<br>`kasa-islemleri.birlik-kart-sorgulama.update` | `-` |
| `kasa-islemleri` | `banknot-takipleri` | `kasa-islemleri.banknot-takipleri.page` | `kasa-islemleri.banknot-takipleri.list`<br>`kasa-islemleri.banknot-takipleri.detail`<br>`kasa-islemleri.banknot-takipleri.create` | `kasa-islemleri.banknot-takipleri.all-warehouses` |

## AnaSayfa / Depo Oncelikleri

Bu endpoint home acilisinda eski hizli erisim menusu yerine "bugun neye bakmaliyim?" paneli icin eklendi. Amac, giris yapan depo kullanicisinin kendi deposundaki acil operasyon konularini tek kartta gormesidir.

Kaynaklar:

- `document_flows`: bugunku sevk, bugunku iade, bugunku depo kabul, bekleyen depo kabul ve basarisiz e-irsaliye sayilari
- `stock_anomalies`: acik veya kabul edilmis stok anomalileri
- `feedback_items`: giris yapan kullanicinin kapanmamis sikayet/onerileri

Kapsam:

- Sadece login olmak yeterlidir.
- `home.depo-oncelikleri.all-warehouses` yetkisi olmayan kullanici `warehouseNo` gondermez; backend JWT icindeki depoyu uygular.
- Bu yetki yokken baska depo icin `warehouseNo` gonderilirse `403 Forbidden` doner.
- `home.depo-oncelikleri.all-warehouses` yetkisi olan kullanici `warehouseNo` gondererek depo secebilir.
- Bu yetkiye sahip kullanici `warehouseNo` gondermezse tum depolar ozetlenir ve `warehouseNo: null` doner.
- Endpoint sadece mevcut izleme tablolarindan okur; pahali tarama/senkronizasyon tetiklemez.

Endpoint ozeti:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `GET /api/home/depo-oncelikleri` | query | `HomeWarehousePrioritiesHttpRequest` | `HomeWarehousePrioritiesDto` | login |

Query:

```text
date         opsiyonel; yyyy-MM-dd, bos ise bugun
warehouseNo  opsiyonel; sadece `home.depo-oncelikleri.all-warehouses` yetkisi olan kullanicida tum depo/depoya gore filtreleme anlamlidir
```

Ornek:

`GET /api/home/depo-oncelikleri?date=2026-07-24&warehouseNo=110`

Response:

```json
{
  "date": "2026-07-24",
  "generatedAtUtc": "2026-07-24T09:10:00Z",
  "warehouseNo": 110,
  "warehouseName": "KESTEL 1",
  "overallStatus": "critical",
  "headline": "Bugun 3 oncelikli konu var",
  "metrics": [
    {
      "code": "failedEDespatch",
      "label": "E-Irsaliye Hatasi",
      "value": 2,
      "severity": "critical",
      "route": "/operasyon-islemleri/belge-akis-takibi?status=Failed&warehouseNo=110"
    },
    {
      "code": "pendingReceiving",
      "label": "Bekleyen Kabul",
      "value": 7,
      "severity": "warning",
      "route": "/operasyon-islemleri/belge-akis-takibi?warehouseNo=110"
    },
    {
      "code": "openStockAnomaly",
      "label": "Acik Stok Anomalisi",
      "value": 4,
      "severity": "warning",
      "route": "/stok-islemleri/stok-anomali-merkezi?status=Open&warehouseNo=110"
    },
    {
      "code": "myOpenFeedback",
      "label": "Acik Talebim",
      "value": 1,
      "severity": "info",
      "route": "/home/sikayet-oneri/benim"
    }
  ],
  "priorities": [
    {
      "code": "failedEDespatch",
      "severity": "critical",
      "title": "E-irsaliye gonderimi basarisiz",
      "description": "2 belge tekrar kontrol bekliyor.",
      "count": 2,
      "route": "/operasyon-islemleri/belge-akis-takibi?status=Failed&warehouseNo=110"
    },
    {
      "code": "pendingReceiving",
      "severity": "warning",
      "title": "Depo kabul bekliyor",
      "description": "7 depo hareketi henuz kabul edilmemis.",
      "count": 7,
      "route": "/operasyon-islemleri/belge-akis-takibi?warehouseNo=110"
    }
  ],
  "quickActions": [
    {
      "code": "documentFlow",
      "label": "Belge Akisina Git",
      "route": "/operasyon-islemleri/belge-akis-takibi?warehouseNo=110",
      "permissionCode": "operasyon-islemleri.belge-akis-takibi.list"
    },
    {
      "code": "feedback",
      "label": "Sikayet/Oneri Gonder",
      "route": "/home/sikayet-oneri",
      "permissionCode": null
    }
  ]
}
```

Alan notlari:

- `overallStatus` ve `metrics[].severity`: `critical`, `warning`, `info`, `healthy`
- `metrics`: sayisal ozet kartlari icindir; sifir degerler de doner.
- `priorities`: sadece aksiyon gerektiren konulari doner; kritik maddeler once gelir.
- `quickActions`: home butonlari icindir. `permissionCode` doluysa UI bu butonu `me.permissions` icinde ilgili kod varsa gostermelidir; `null` ise login olan herkes gorebilir.

UI onerisi:

- Home ilk ekranda ustte `headline` ve depo adini goster.
- Altinda 4-6 kompakt metrik karti kullan; eski sabit hizli erisim menusu yerine bu kartlardan gelen `route` ile yonlendir.
- `priorities` listesini "once bunu yap" sirasi gibi kullan; `critical` maddeleri daha belirgin renkle ayir.
- `priorities` bos ise pozitif bos durum goster: `headline` zaten "Bugun acil oncelik yok" doner.
- `home.depo-oncelikleri.all-warehouses` yetkisi olan kullanicida depo filtresi eklenebilir; diger kullanicida depo secici gosterilmemelidir.

## AnaSayfa / Ortak Sikayet Oneri

Bu modul home sayfasinda kucuk bir "Sikayet / Oneri" kutusu acmak ve yonetim tarafinda gelen kayitlari permission'a gore izlemek icin eklendi.

Veri Auth DB tarafinda tutulur:

- MSSQL tablo: `feedback_items`
- Migration: `20260609134038_AddFeedbackItems`
- Kullanici iliskileri: `created_by_user_id`, `read_by_user_id`, `status_changed_by_user_id` alanlari `app_users.id` alanina baglidir
- Permission katalogunda `OrtakIslemler > SikayetOneri` menusu altinda liste/detay/guncelle/tumunu listele yetkileri vardir

Temel kural:

- Home endpointleri icin sadece login olmak yeterlidir.
- Kullanici kendi sikayet/onerisini olusturur, kendi gecmisini, detayini ve durumunu gorur.
- Yonetim liste endpointi `ortak-islemler.sikayet-oneri.list` ister.
- Yonetim detay endpointi `ortak-islemler.sikayet-oneri.detail` ister.
- Okundu isaretleme, cevap/admin notu yazma ve durum degistirme `ortak-islemler.sikayet-oneri.update` ister.
- `ortak-islemler.sikayet-oneri.list-all` olmayan kullanici yonetim endpointlerinde sadece kendi actigi kayitlari gorur ve kendi kapsami disindaki kayitlarda aksiyon alamaz.
- `ortak-islemler.sikayet-oneri.list-all` olan kullanici tum kayitlari gorur, isterse `warehouseNo` ile depo filtreler.

Yetki kodlari:

- `ortak-islemler.sikayet-oneri.list`
- `ortak-islemler.sikayet-oneri.detail`
- `ortak-islemler.sikayet-oneri.update`
- `ortak-islemler.sikayet-oneri.list-all`

Not: Bu modul artik role name ile karar vermez. UI `me.permissions` listesindeki kodlara gore menu, kolon ve aksiyon butonlarini acmalidir. Eski `Admin` / `Administrator` kontrolu kullanilmamalidir.

Deger kataloglari:

```text
type:
  Complaint   Sikayet
  Suggestion  Oneri

priority:
  Low     Dusuk
  Normal  Normal
  High    Yuksek

status:
  New         Yeni
  Read        Okundu
  InProgress  Islemde
  Resolved    Cozuldu
  Closed      Kapali
  Rejected    Reddedildi
```

Request tarafinda backend su alias'lari da kabul eder:

- type: `sikayet`, `oneri`
- priority: `dusuk`, `normal`, `yuksek`
- status: `yeni`, `okundu`, `islemde`, `cozuldu`, `kapali`, `reddedildi`

UI icin onerilen kullanim:

- Home kutusunda once `GET /api/home/sikayet-oneri/ozet` cagrilir.
- Kutuda acik kayit sayisi, cozulen/kapali kayit sayisi ve son kaydin durumu gosterilir.
- "Sikayet / Oneri Gonder" butonu modal acar.
- Modalda `type`, `title`, `message`, `priority` alanlari bulunur.
- Kullanici bilgisi, depo no ve depo adi body'den alinmaz; JWT claim'lerinden backend tarafinda doldurulur.
- Ayni create formu home disinda kullanicinin kendi sayfasinda da acilabilir; UI `POST /api/home/sikayet-oneri`, `POST /api/ortak-islemler/sikayet-oneri` veya `POST /api/yonetim/sikayet-oneri` route'larindan birini kullanabilir.
- "Gecmisim" veya detay paneli icin `GET /api/home/sikayet-oneri/benim` kullanilir.
- Yonetim ekrani menu olarak `OrtakIslemler > SikayetOneri` altinda acilabilir; `list` yetkisi yoksa ekran hic acilmamalidir.
- `list-all` yetkisi yoksa yonetim ekrani sadece kullanicinin kendi actigi kayitlari liste/detay olarak gosterir.
- Yonetim gridinde tip, durum, oncelik, depo, olusturan kullanici, tarih ve admin notu kolonlari yeterlidir.
- Durum degisiminde `PATCH /durum`, sadece okunduya alma icin `PATCH /okundu` kullanilmalidir; bu aksiyonlar UI'da sadece `ortak-islemler.sikayet-oneri.update` yetkisi varsa acilmalidir.

Endpoint ozeti:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `POST /api/home/sikayet-oneri` | body | `CreateFeedbackItemHttpRequest` | `FeedbackItemDto` | login |
| `POST /api/ortak-islemler/sikayet-oneri` | body | `CreateFeedbackItemHttpRequest` | `FeedbackItemDto` | login |
| `POST /api/yonetim/sikayet-oneri` | body | `CreateFeedbackItemHttpRequest` | `FeedbackItemDto` | login |
| `GET /api/home/sikayet-oneri/benim` | - | - | `FeedbackItemDto[]` | login |
| `GET /api/ortak-islemler/sikayet-oneri/benim` | - | - | `FeedbackItemDto[]` | login |
| `GET /api/yonetim/sikayet-oneri/benim` | - | - | `FeedbackItemDto[]` | login |
| `GET /api/home/sikayet-oneri/ozet` | - | - | `FeedbackSummaryDto` | login |
| `GET /api/ortak-islemler/sikayet-oneri/ozet` | - | - | `FeedbackSummaryDto` | login |
| `GET /api/yonetim/sikayet-oneri/ozet` | - | - | `FeedbackSummaryDto` | login |
| `GET /api/yonetim/sikayet-oneri` | query | `FeedbackManagementListHttpRequest` | `FeedbackItemDto[]` | `ortak-islemler.sikayet-oneri.list`; tum kapsam icin `list-all` |
| `GET /api/yonetim/sikayet-oneri/{id}` | path | `id: guid` | `FeedbackItemDto` | `ortak-islemler.sikayet-oneri.detail`; tum kapsam icin `list-all` |
| `PATCH /api/yonetim/sikayet-oneri/{id}/okundu` | path | `id: guid` | `FeedbackItemDto` | `ortak-islemler.sikayet-oneri.update`; tum kapsam icin `list-all` |
| `PATCH /api/yonetim/sikayet-oneri/{id}/durum` | body | `ChangeFeedbackStatusHttpRequest` | `FeedbackItemDto` | `ortak-islemler.sikayet-oneri.update`; tum kapsam icin `list-all` |

Yonetim endpointleri icin alias route:

```text
/api/ortak-islemler/sikayet-oneri
/api/ortak-islemler/sikayet-oneri/{id}
/api/ortak-islemler/sikayet-oneri/{id}/okundu
/api/ortak-islemler/sikayet-oneri/{id}/durum
```

Home/kullanici endpointleri icin `home`, `ortak-islemler` ve `yonetim` route kokleri controller'da aciktir. UI sade kullanim icin home kutusunda `/api/home/sikayet-oneri/*`, ortak menu ekraninda `/api/ortak-islemler/sikayet-oneri/*` yolunu tercih edebilir.

### Sikayet Oneri Olustur

`POST /api/home/sikayet-oneri`

Body:

```json
{
  "type": "Complaint",
  "title": "Kasada bekleme",
  "message": "Aksam saatlerinde kasa kuyrugu cok uzuyor.",
  "priority": "Normal"
}
```

Validasyon:

```text
type      zorunlu, max 30; Complaint/Suggestion veya sikayet/oneri
title     zorunlu, max 120
message   zorunlu, max 2000
priority  opsiyonel, max 30; bos ise Normal
```

Response `201 Created`:

```json
{
  "id": "8a9b1d5d-f2c8-4be4-a6f4-9b6e5c08e730",
  "type": "Complaint",
  "typeName": "Sikayet",
  "title": "Kasada bekleme",
  "message": "Aksam saatlerinde kasa kuyrugu cok uzuyor.",
  "status": "New",
  "statusName": "Yeni",
  "priority": "Normal",
  "priorityName": "Normal",
  "createdByUserId": "58ac6266-8c7a-4ff5-a16e-2229ef31a111",
  "createdByUsername": "sube.kullanici",
  "createdByFullName": "Sube Kullanici",
  "warehouseNo": 110,
  "warehouseName": "KESTEL 1",
  "adminNote": null,
  "readAtUtc": null,
  "readByUserId": null,
  "statusChangedAtUtc": null,
  "statusChangedByUserId": null,
  "createdAtUtc": "2026-06-09T12:30:00Z",
  "updatedAtUtc": null,
  "closedAtUtc": null
}
```

### Benim Sikayet Onerilerim

`GET /api/home/sikayet-oneri/benim`

Kullanicinin kendi actigi son 100 kaydi doner. Liste yeni kayit once gelecek sekilde `createdAtUtc desc` siralanir.

Response:

```json
[
  {
    "id": "8a9b1d5d-f2c8-4be4-a6f4-9b6e5c08e730",
    "type": "Complaint",
    "typeName": "Sikayet",
    "title": "Kasada bekleme",
    "message": "Aksam saatlerinde kasa kuyrugu cok uzuyor.",
    "status": "InProgress",
    "statusName": "Islemde",
    "priority": "Normal",
    "priorityName": "Normal",
    "createdByUserId": "58ac6266-8c7a-4ff5-a16e-2229ef31a111",
    "createdByUsername": "sube.kullanici",
    "createdByFullName": "Sube Kullanici",
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "adminNote": "Bolge sorumlusuna iletildi.",
    "readAtUtc": "2026-06-09T12:45:00Z",
    "readByUserId": "2ffb4f7d-b63d-4b12-8d74-e2a0aee2798a",
    "statusChangedAtUtc": "2026-06-09T13:00:00Z",
    "statusChangedByUserId": "2ffb4f7d-b63d-4b12-8d74-e2a0aee2798a",
    "createdAtUtc": "2026-06-09T12:30:00Z",
    "updatedAtUtc": "2026-06-09T13:00:00Z",
    "closedAtUtc": null
  }
]
```

### Home Ozet

`GET /api/home/sikayet-oneri/ozet`

Response:

```json
{
  "myOpenCount": 2,
  "myResolvedCount": 5,
  "latestStatus": "InProgress",
  "latestCreatedAtUtc": "2026-06-09T12:30:00Z"
}
```

Not:

- `myOpenCount`: `Resolved`, `Closed`, `Rejected` disindaki kayit sayisidir.
- `myResolvedCount`: `Resolved` ve `Closed` durumundaki kayit sayisidir.
- `latestStatus` son kaydin status kodudur; kayit yoksa null gelir.

### Yonetim Liste

`GET /api/yonetim/sikayet-oneri`

Alias:

`GET /api/ortak-islemler/sikayet-oneri`

Ornek:

`GET /api/yonetim/sikayet-oneri?status=New&type=Complaint&warehouseNo=110&startDate=2026-06-01&endDate=2026-06-09&take=100`

Query:

```text
status       opsiyonel; New/Read/InProgress/Resolved/Closed/Rejected
type         opsiyonel; Complaint/Suggestion
warehouseNo  opsiyonel; sadece list-all yetkisi olan kullanicida tum depo filtreleme anlamlidir
startDate    opsiyonel; createdAtUtc baslangic tarihi
endDate      opsiyonel; createdAtUtc bitis tarihi, gun sonu dahil kabul edilir
take         opsiyonel; default 100, max 500
```

Kapsam:

- `ortak-islemler.sikayet-oneri.list-all` olan kullanici tum kayitlar uzerinden filtreleme yapar.
- `list-all` olmayan kullanici: backend otomatik olarak sadece `createdByUserId = current user` kayitlarini dondurur.
- `list-all` olmayan kullanici `warehouseNo` gonderse bile baska kullanici veya depo kaydina erisemez; depo filtresi sadece tum kapsam yetkisi olan ekranda anlamlidir.

### Yonetim Detay

`GET /api/yonetim/sikayet-oneri/{id}`

Alias:

`GET /api/ortak-islemler/sikayet-oneri/{id}`

Response `FeedbackItemDto` doner.

### Okundu Isaretle

`PATCH /api/yonetim/sikayet-oneri/{id}/okundu`

Alias:

`PATCH /api/ortak-islemler/sikayet-oneri/{id}/okundu`

Body yoktur. Kayit `New` durumundaysa status `Read` olur; daha once farkli duruma alinmissa sadece okundu bilgisi korunarak response doner.

Yetki:

- Endpoint `ortak-islemler.sikayet-oneri.update` ister.
- Baska kullanicinin kaydi icin ayrica `ortak-islemler.sikayet-oneri.list-all` gerekir.

### Durum Degistir

`PATCH /api/yonetim/sikayet-oneri/{id}/durum`

Alias:

`PATCH /api/ortak-islemler/sikayet-oneri/{id}/durum`

Body:

```json
{
  "status": "InProgress",
  "adminNote": "Bolge sorumlusuna iletildi."
}
```

Validasyon:

```text
status     zorunlu, max 30
adminNote  opsiyonel, max 1000
```

Not:

- Status `Resolved`, `Closed` veya `Rejected` olursa `closedAtUtc` dolar.
- Status tekrar final olmayan bir degere cekilirse `closedAtUtc` null olur.
- `adminNote` bos gonderilirse not temizlenir.
- Status degisimi kaydi daha once okunmadiysa `readAtUtc` ve `readByUserId` de doldurulur.
- Endpoint `ortak-islemler.sikayet-oneri.update` ister.
- Baska kullanicinin kaydi icin ayrica `ortak-islemler.sikayet-oneri.list-all` gerekir.

## AnaSayfa / Ortak Duyurular

Bu modul yetkili kullanicinin tum depolara, belirli depolara veya belirli kullanicilara duyuru yayinlamasi icin eklendi. Home tarafinda kullanici kendisine dusen aktif duyurulari gorur ve okundu isaretler; yonetim tarafinda yetkili kullanici duyuru olusturur, gunceller, arsivler ve hedef kapsamlarini izler.

Veri Auth DB tarafinda tutulur:

- MSSQL tablolar: `announcements`, `announcement_targets`, `announcement_reads`
- Migration: `20260729133811_AddAnnouncements`
- Duyuruyu olusturan kullanici bilgileri `created_by_user_id`, `created_by_username`, `created_by_full_name` alanlarinda saklanir.
- Okundu bilgisi kullanici bazli `announcement_reads` tablosunda tutulur.
- Okuyan kullanici listesi `announcement_reads` ile `app_users` iliskisinden doner; ayrica `readSummary` ile okuyan/hedef/okumayan sayilari verilir.
- Hedefler ayri satirlar olarak `announcement_targets` tablosunda tutulur; ayni duyuru birden fazla depoya veya kullaniciya hedeflenebilir.

Temel kural:

- Home endpointleri icin sadece login olmak yeterlidir.
- Kullanici yalnizca kendi kullanici id'sine, kendi deposuna veya tum depolara hedeflenmis aktif duyurulari gorur.
- Aktif duyuru `Published` durumda olmali, `startsAtUtc` gelmis olmali ve `expiresAtUtc` gecmemis olmalidir.
- Yonetim liste endpointi `ortak-islemler.duyurular.list` ister.
- Yonetim detay endpointi `ortak-islemler.duyurular.detail` ister.
- Duyuru olusturma `ortak-islemler.duyurular.create` ister.
- Duyuru guncelleme `ortak-islemler.duyurular.update` ister.
- Duyuru arsivleme `ortak-islemler.duyurular.archive` ister.
- Tum depolara duyuru, baska depoya duyuru veya baska depodaki kullaniciya duyuru icin `ortak-islemler.duyurular.all-warehouses` gerekir.
- `all-warehouses` olmayan kullanici sadece kendi deposuna veya kendi deposundaki aktif kullanicilara hedefleme yapabilir.
- `all-warehouses` olmayan kullanici yonetim ekraninda kendi olusturdugu veya kendi kapsaminda gorunen duyurulari gorur; guncelleme/arsivleme icin duyuruyu kendisinin olusturmus olmasi gerekir.
- `all-warehouses` olan kullanici tum duyurulari gorur, gunceller ve arsivler.

WarehouseAccessFilter notu:

- Request modeli hedef alanlarini `TargetWarehouseNos` olarak kullanir; bu alan global `WarehouseAccessFilter` icindeki `WarehouseNo`, `BranchNo`, `InWarehouseNo` birebir alan kontrolune takilmaz.
- Bu bilincli tercih edildi, cunku duyuruda birden fazla hedef depo olabilir.
- Depo guvenligi servis icinde `ortak-islemler.duyurular.all-warehouses` ve kullanicinin kendi `WarehouseNo` bilgisiyle tekrar dogrulanir.
- UI baska depoya hedefleme alanini sadece `all-warehouses` yetkisi varsa acmalidir.

Yetki kodlari:

- `ortak-islemler.duyurular.list`
- `ortak-islemler.duyurular.detail`
- `ortak-islemler.duyurular.create`
- `ortak-islemler.duyurular.update`
- `ortak-islemler.duyurular.archive`
- `ortak-islemler.duyurular.all-warehouses`

Deger kataloglari:

```text
priority:
  Normal     Normal
  Important  Onemli
  Urgent     Acil

status:
  Published  Yayinda
  Archived   Arsivde

targetType:
  AllWarehouses  Tum Depolar
  Warehouse      Depo
  User           Kullanici
```

Request tarafinda backend su alias'lari da kabul eder:

- priority: `normal`, `important`, `onemli`, `urgent`, `acil`
- status: `published`, `yayinda`, `archived`, `arsivde`
- targetType: `AllWarehouses`, `Warehouse`, `User`, `tumdepolar`, `depo`, `kullanici`
- `-`, `_`, bosluklar ve Turkce karakterli yazimlar normalize edilir; ornegin `all-warehouses`, `all warehouses`, `tum_depolar`, `tum depolar` ayni anlama gelir.

UI icin onerilen kullanim:

- Login sonrasi `accessToken` alindiktan ve `GET /api/auth/me` tamamlandiktan hemen sonra ana layout/header seviyesinde `GET /api/home/duyurular/ozet` cagrilmalidir.
- Duyuru gorunurlugu menuye bagli olmamalidir; kullanici `OrtakIslemler > Duyurular` ekranina girmese bile header'daki mesaj/duyuru kutusunda kendisine gelen duyuruyu gorebilmelidir.
- Header'da mesaj kutusu veya zil ikonu kullanilabilir; `unreadCount > 0` ise badge gosterilir.
- Header kutusu acildiginda `GET /api/home/duyurular?includeRead=false&take=20` cagrilip okunmamis aktif duyurular listelenmelidir.
- `Urgent` duyurular login sonrasi ilk acilista toast veya dikkat cekici header bildirimi olarak one cikarilabilir; yine de okundu islemi kullanici aksiyonuyla `PATCH /okundu` uzerinden yapilmalidir.
- Home acilisinda once `GET /api/home/duyurular/ozet` cagrilir; okunmamis sayisi header badge veya home kartinda gosterilir.
- Duyuru kutusu icin `GET /api/home/duyurular?includeRead=false&take=20` kullanilir.
- Kullanici "Tumunu goster" dediginde `includeRead=true` ile okunmus duyurular da getirilebilir.
- Duyuru satirinda oncelik rengi `priority` alanina gore belirlenmelidir: `Urgent` acil, `Important` belirgin, `Normal` standart.
- Kullanici duyuruyu actiginda veya "okundu" aksiyonuna bastiginda `PATCH /api/home/duyurular/{id}/okundu` cagrilir.
- Okundu isleminden sonra header badge icin tekrar `GET /api/home/duyurular/ozet` cagrilmalidir.
- Uzun acik kalan oturumlarda UI periyodik olarak veya uygulama tekrar odaga geldiginde `GET /api/home/duyurular/ozet` ile badge bilgisini tazeleyebilir.
- Yonetim ekrani `OrtakIslemler > Duyurular` altinda acilabilir; menu/route icin `ortak-islemler.duyurular.page`, liste API'si icin `ortak-islemler.duyurular.list` kullanilmalidir.
- Create butonu `create`, duzenle butonu `update`, arsivle butonu `archive`, depo/kullanici kapsam genisletme kontrolleri `all-warehouses` yetkisine gore acilmalidir.
- `all-warehouses` yoksa hedef tipi seciminde "Tum Depolar" pasif olmalidir; depo hedeflemede sadece kullanicinin kendi deposu secilebilir.
- Kullanici hedefleme ekraninda id elle yazdirilmaz; arama kutusu `GET /api/ortak-islemler/duyurular/hedef-kullanicilar?search=...` ile beslenir.
- Kullanici hedefleme aramasi yalnizca aktif kullanicilari dondurur; `all-warehouses` yoksa backend sonucu otomatik kendi depoyla sinirlar.
- Yonetim listesinde `readSummary` kolonlariyla okuyan/hedef/okumayan sayilari gosterilebilir; detayda `readReceipts` veya `GET /okuyanlar` ile kisi listesi acilabilir.
- Tarihler UI tarafinda kullanicinin lokal saatinde gosterilebilir ama API'ye UTC olarak gonderilmelidir.
- `expiresAtUtc` bos ise duyuru manuel arsivlenene kadar surekli yayinda kalir.

Endpoint ozeti:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `GET /api/home/duyurular` | query | `AnnouncementInboxHttpRequest` | `AnnouncementDto[]` | login |
| `GET /api/home/duyurular/ozet` | - | - | `AnnouncementSummaryDto` | login |
| `PATCH /api/home/duyurular/{id}/okundu` | path | `id: guid` | `AnnouncementDto` | login |
| `GET /api/ortak-islemler/duyurular` | query | `AnnouncementManagementListHttpRequest` | `AnnouncementDto[]` | `ortak-islemler.duyurular.list` |
| `GET /api/ortak-islemler/duyurular/hedef-kullanicilar` | query | `AnnouncementTargetUserSearchHttpRequest` | `AnnouncementTargetUserDto[]` | `ortak-islemler.duyurular.list` |
| `GET /api/ortak-islemler/duyurular/{id}` | path | `id: guid` | `AnnouncementDto` | `ortak-islemler.duyurular.detail` |
| `GET /api/ortak-islemler/duyurular/{id}/okuyanlar` | path | `id: guid` | `AnnouncementReadReceiptListDto` | `ortak-islemler.duyurular.detail` |
| `POST /api/ortak-islemler/duyurular` | body | `SaveAnnouncementHttpRequest` | `AnnouncementDto` | `ortak-islemler.duyurular.create` |
| `PUT /api/ortak-islemler/duyurular/{id}` | body | `SaveAnnouncementHttpRequest` | `AnnouncementDto` | `ortak-islemler.duyurular.update` |
| `PATCH /api/ortak-islemler/duyurular/{id}/arsivle` | path | `id: guid` | `AnnouncementDto` | `ortak-islemler.duyurular.archive` |

Yonetim endpointleri icin alias route:

```text
/api/yonetim/duyurular
/api/yonetim/duyurular/hedef-kullanicilar
/api/yonetim/duyurular/{id}
/api/yonetim/duyurular/{id}/okuyanlar
/api/yonetim/duyurular/{id}/arsivle
```

UI sade kullanim icin home kutusunda `/api/home/duyurular/*`, ortak menu ekraninda `/api/ortak-islemler/duyurular/*` yolunu tercih edebilir.

### Duyuru Inbox

`GET /api/home/duyurular`

Ornek:

`GET /api/home/duyurular?includeRead=false&take=20`

Query:

```text
includeRead  opsiyonel; default false. false ise sadece okunmamis aktif duyurular doner.
take         opsiyonel; default 100, max 500
```

Kapsam:

- Sadece `Published` durumdaki duyurular doner.
- `startsAtUtc` bos veya su andan kucuk/esit olmalidir.
- `expiresAtUtc` bos veya su andan buyuk olmalidir.
- Hedef `AllWarehouses`, kullanicinin kendi `WarehouseNo` degeri veya kendi `UserId` degeriyle eslesmelidir.
- Response once `priority desc`, sonra `publishedAtUtc desc` siralidir.

Response:

```json
[
  {
    "id": "a64af2ad-b0a2-4b62-8b21-91a63f2b0f30",
    "title": "Aksam sayim duyurusu",
    "message": "Bugun 18:00 sonrasi sayim hazirligi yapilacaktir.",
    "priority": "Important",
    "priorityName": "Onemli",
    "status": "Published",
    "statusName": "Yayinda",
    "createdByUserId": "2ffb4f7d-b63d-4b12-8d74-e2a0aee2798a",
    "createdByUsername": "merkez.admin",
    "createdByFullName": "Merkez Admin",
    "startsAtUtc": "2026-07-29T12:00:00Z",
    "expiresAtUtc": "2026-08-01T21:00:00Z",
    "publishedAtUtc": "2026-07-29T11:45:00Z",
    "archivedAtUtc": null,
    "archivedByUserId": null,
    "createdAtUtc": "2026-07-29T11:45:00Z",
    "updatedAtUtc": null,
    "readAtUtc": null,
    "targets": [
      {
        "id": "cce4c1b2-4b9c-4612-80ef-d2d3cb24b7db",
        "type": "Warehouse",
        "typeName": "Depo",
        "warehouseNo": 110,
        "warehouseName": "KESTEL 1",
        "userId": null,
        "username": null,
        "userFullName": null
      }
    ],
    "readSummary": null,
    "readReceipts": []
  }
]
```

### Duyuru Home Ozet

`GET /api/home/duyurular/ozet`

Response:

```json
{
  "activeCount": 3,
  "unreadCount": 2,
  "latestAnnouncementId": "a64af2ad-b0a2-4b62-8b21-91a63f2b0f30",
  "latestPublishedAtUtc": "2026-07-29T11:45:00Z"
}
```

Not:

- `activeCount`: kullanicinin kapsamindaki aktif duyuru sayisidir.
- `unreadCount`: aktif duyurular icinde kullanicinin henuz okundu isaretlemedigi duyuru sayisidir.
- `latestAnnouncementId` ve `latestPublishedAtUtc` aktif duyuru yoksa null gelir.

### Duyuru Okundu Isaretle

`PATCH /api/home/duyurular/{id}/okundu`

Body yoktur. Islem idempotent calisir; kullanici ayni duyuruyu daha once okuduysa mevcut `readAtUtc` korunarak response doner.

Yetki ve kapsam:

- Sadece login gerekir.
- Kullanici sadece kendi kapsaminda gorunen aktif duyuruyu okundu isaretleyebilir.
- Kapsaminda olmayan veya arsivlenmis/gecersiz tarih araligindaki duyuru icin 404 doner.

### Duyuru Yonetim Liste

`GET /api/ortak-islemler/duyurular`

Alias:

`GET /api/yonetim/duyurular`

Ornek:

`GET /api/ortak-islemler/duyurular?status=Published&targetType=Warehouse&targetWarehouseNo=110&startDate=2026-07-01&endDate=2026-07-29&includeArchived=false&take=100`

Query:

```text
status             opsiyonel; Published/Archived veya yayinda/arsivde
targetType         opsiyonel; AllWarehouses/Warehouse/User veya tumdepolar/depo/kullanici
targetWarehouseNo  opsiyonel; hedef depo filtresi
targetUserId       opsiyonel; hedef kullanici filtresi
startDate          opsiyonel; createdAtUtc baslangic tarihi
endDate            opsiyonel; createdAtUtc bitis tarihi, gun sonu dahil kabul edilir
includeArchived    opsiyonel; default false. false ise arsivli duyurular listelenmez.
take               opsiyonel; default 100, max 500
```

Kapsam:

- `all-warehouses` olan kullanici tum duyurular uzerinden filtreleme yapar.
- `all-warehouses` olmayan kullanici kendi olusturdugu veya kendisine/kendi deposuna/tum depolara hedeflenmis duyurulari gorur.
- `all-warehouses` olmayan kullanici `targetWarehouseNo` filtresinde sadece kendi deposunu gonderebilir; baska depo gonderirse 400 doner.
- Response icindeki `readSummary` doludur; liste performansi icin `readReceipts` bos dizi doner.

### Duyuru Hedef Kullanici Arama

`GET /api/ortak-islemler/duyurular/hedef-kullanicilar`

Alias:

`GET /api/yonetim/duyurular/hedef-kullanicilar`

Ornek:

`GET /api/ortak-islemler/duyurular/hedef-kullanicilar?search=serdal&warehouseNo=101&take=25`

Query:

```text
search       opsiyonel; username, ad, soyad, e-posta, depo no veya depo adinda aranir; max 100
warehouseNo  opsiyonel; sadece all-warehouses yetkisi olan kullanici baska depo gonderebilir
take         opsiyonel; default 25, max 100
```

Response:

```json
[
  {
    "id": "58ac6266-8c7a-4ff5-a16e-2229ef31a111",
    "username": "serdal.ozsoy",
    "fullName": "Serdal Ozsoy",
    "email": "serdal.ozsoy@example.local",
    "warehouseNo": 101,
    "warehouseName": "Depo 101",
    "displayName": "Serdal Ozsoy (serdal.ozsoy) / 101 - Depo 101"
  }
]
```

Not:

- Endpoint `ortak-islemler.duyurular.list` ister.
- Sadece aktif kullanicilar doner.
- `all-warehouses` olmayan kullanici icin sonuc her zaman kendi deposuyla sinirlidir.

### Duyuru Yonetim Detay

`GET /api/ortak-islemler/duyurular/{id}`

Alias:

`GET /api/yonetim/duyurular/{id}`

Response `AnnouncementDto` doner. Detay response'unda `readSummary` ve `readReceipts` doludur.

Yetki ve kapsam:

- Endpoint `ortak-islemler.duyurular.detail` ister.
- `all-warehouses` olan kullanici tum duyurulari gorur.
- `all-warehouses` olmayan kullanici kendi olusturdugu veya kendi kapsaminda gorunen duyuruyu gorur.

### Duyuru Okuyanlar

`GET /api/ortak-islemler/duyurular/{id}/okuyanlar`

Alias:

`GET /api/yonetim/duyurular/{id}/okuyanlar`

Response:

```json
{
  "announcementId": "a64af2ad-b0a2-4b62-8b21-91a63f2b0f30",
  "summary": {
    "readCount": 2,
    "targetUserCount": 3,
    "unreadCount": 1,
    "lastReadAtUtc": "2026-07-29T13:20:00Z"
  },
  "readers": [
    {
      "userId": "58ac6266-8c7a-4ff5-a16e-2229ef31a111",
      "username": "serdal.ozsoy",
      "userFullName": "Serdal Ozsoy",
      "email": "serdal.ozsoy@example.local",
      "warehouseNo": 101,
      "warehouseName": "Depo 101",
      "readAtUtc": "2026-07-29T13:20:00Z"
    }
  ]
}
```

Not:

- Endpoint `ortak-islemler.duyurular.detail` ister.
- `readers` en son okuyan en ustte olacak sekilde siralanir.
- `all-warehouses` olmayan kullanicida okuyanlar listesi kendi depo/kendi kullanici kapsamina sinirlanir.

### Duyuru Olustur

`POST /api/ortak-islemler/duyurular`

Alias:

`POST /api/yonetim/duyurular`

Depoya duyuru ornegi:

```json
{
  "title": "Aksam sayim duyurusu",
  "message": "Bugun 18:00 sonrasi sayim hazirligi yapilacaktir.",
  "priority": "Important",
  "targetType": "Warehouse",
  "targetWarehouseNos": [110, 120],
  "targetUserIds": null,
  "startsAtUtc": "2026-07-29T12:00:00Z",
  "expiresAtUtc": "2026-08-01T21:00:00Z"
}
```

Tum depolara duyuru ornegi:

```json
{
  "title": "Sistem bakimi",
  "message": "Bu gece 23:00-23:30 arasi kisa kesinti olabilir.",
  "priority": "Urgent",
  "targetType": "AllWarehouses",
  "targetWarehouseNos": null,
  "targetUserIds": null,
  "startsAtUtc": "2026-07-29T20:00:00Z",
  "expiresAtUtc": "2026-07-30T21:00:00Z"
}
```

Kullaniciya duyuru ornegi:

```json
{
  "title": "Fiyat kontrolu",
  "message": "Etiket degisimi sonrasi reyon kontrolunu tamamlayiniz.",
  "priority": "Normal",
  "targetType": "User",
  "targetWarehouseNos": null,
  "targetUserIds": [
    "58ac6266-8c7a-4ff5-a16e-2229ef31a111"
  ],
  "startsAtUtc": null,
  "expiresAtUtc": null
}
```

Validasyon:

```text
title               zorunlu, max 140
message             zorunlu, max 4000
priority            opsiyonel, max 30; bos ise Normal
targetType          zorunlu, max 30
targetWarehouseNos  targetType=Warehouse icin en az 1 pozitif depo no
targetUserIds       targetType=User icin en az 1 aktif kullanici id
startsAtUtc         opsiyonel, UTC kabul edilir
expiresAtUtc        opsiyonel, UTC kabul edilir; varsa startsAtUtc degerinden buyuk olmalidir
```

Yetki ve hedefleme:

- Endpoint `ortak-islemler.duyurular.create` ister.
- `targetType=AllWarehouses` icin `ortak-islemler.duyurular.all-warehouses` gerekir.
- `targetType=Warehouse` icin `all-warehouses` yoksa sadece kullanicinin kendi deposu gonderilebilir.
- `targetType=User` icin hedef kullanicilar aktif olmalidir; `all-warehouses` yoksa hedef kullanicilar kullanicinin kendi deposunda olmalidir.
- `targetWarehouseNos` ve `targetUserIds` icinde tekrar eden degerler backend tarafinda tekillestirilir.

### Duyuru Guncelle

`PUT /api/ortak-islemler/duyurular/{id}`

Alias:

`PUT /api/yonetim/duyurular/{id}`

Body `SaveAnnouncementHttpRequest` ile aynidir.

Not:

- Endpoint `ortak-islemler.duyurular.update` ister.
- `all-warehouses` olan kullanici tum duyurulari guncelleyebilir.
- `all-warehouses` olmayan kullanici sadece kendi olusturdugu duyuruyu guncelleyebilir.
- Arsivlenmis duyuru guncellenemez.
- Guncellemede hedefler yeniden yazilir.
- Duyurunun onceki okundu kayitlari temizlenir; cunku baslik, metin veya hedef degismis olabilir.

### Duyuru Arsivle

`PATCH /api/ortak-islemler/duyurular/{id}/arsivle`

Alias:

`PATCH /api/yonetim/duyurular/{id}/arsivle`

Body yoktur. Arsivlenen duyuru `Archived` olur, `archivedAtUtc` ve `archivedByUserId` dolar. Islem tekrar cagrilirsa duyuru zaten arsivde oldugu icin mevcut arsiv bilgisi korunarak response doner.

Yetki ve kapsam:

- Endpoint `ortak-islemler.duyurular.archive` ister.
- `all-warehouses` olan kullanici tum duyurulari arsivleyebilir.
- `all-warehouses` olmayan kullanici sadece kendi olusturdugu duyuruyu arsivleyebilir.

## Mobil Offline ve Guvenli Retry Kurallari

Bu bolum mobil uygulamanin offline iken olusturdugu fisleri internet geldiginde guvenli sekilde backend'e gondermesi icin create retry kurallarini anlatir.

Offline durum sorgusu olan pilot create akislari:

- `POST /api/mal-kabul-islemleri/firma-mal-kabulleri`
- `POST /api/stok-islemleri/sayim-sonuclari`

Guvenli retry destegi genisletilen diger kritik create akislari:

- `POST /api/sevk-islemleri/depolar-arasi-sevkler/giden`
- `POST /api/sevk-islemleri/firma-sevkleri/giden`
- `POST /api/iade-islemleri/depo-iadeleri/giden`
- `POST /api/iade-islemleri/firma-iadeleri`
- `POST /api/stok-islemleri/zayiat-fisleri`
- `POST /api/stok-islemleri/masraf-fisleri`
- `POST /api/stok-islemleri/virmanlar`

Bu endpointler legacy UI gibi normal online da kullanilabilir. Ancak mobil uygulama veya web UI timeout/tekrar basma riskine karsi guvenli calisacaksa su kurallar uygulanmalidir:

- Her yeni create denemesi icin istemci tarafinda bir `clientRequestId` uretilmelidir. Format `GUID` olmali ve ayni mantiksal fis boyunca degismemelidir.
- `clientRequestId` teknik olarak opsiyoneldir, ama offline guvenli tekrar gonderim icin pratikte zorunludur.
- Kullanici ayni fis taslagini tekrar gonderiyorsa ayni `clientRequestId` kullanilmalidir.
- Kullanici fis icerigini degistirdiyse yeni bir `clientRequestId` uretilmelidir.
- Ayni kullanici, ayni islem ve ayni `clientRequestId` kombinasyonu backend tarafinda tekil kabul edilir.
- Ayni `clientRequestId` ile ayni payload tekrar gelirse backend ayni is sonucunu donmeye calisir; boylece timeout veya kopan internet sonrasi guvenli retry yapilabilir.
- Ayni `clientRequestId` ile farkli payload gelirse endpoint `409 Conflict` doner.
- Ayni `clientRequestId` halen isleniyorsa endpoint `409 Conflict` doner.
- POST cevabi cihaza ulasmadiysa mobil uygulama once ayni `clientRequestId` ile tekrar POST denemelidir.
- Firma mal kabul ve sayim sonucunda durum hala belirsizse ilgili `offline-sync/{clientRequestId}` endpoint'i ile durum sorgulanabilir.
- Sevk, iade, zayiat, masraf ve virman create akislarinda ayri durum endpoint'i yoktur; sonuc ayni `clientRequestId` ile tekrar POST edilerek toparlanir.
- Stok hareketi yazan genisletilmis akislarda backend `clientRequestId` izini `FR` prefixli 24 karakterlik trace olarak Mikro `STOK_HAREKETLERI.sth_eticaret_kanal_kodu` alanina tasir. `MikroApi` rotasinda da ayni iz payload'a eklenir.
- `FR` prefix'i bu alan ileride dolu goruldugunde kaydin Furpa guvenli retry izinden geldigini ayirt etmek icindir.

UI davranis kurali:

- `clientRequestId` form ekraninin kimligi degildir; tek mantiksal kaydetme denemesinin kimligidir.
- UI ilk `Kaydet` aninda `clientRequestId` uretmeli, gonderilen body'nin snapshot'ini bu id ile birlikte saklamalidir.
- Request devam ederken kaydet butonu ve form alanlari kilitlenmelidir.
- Timeout, network kopmasi veya belirsiz sonuc olursa UI ayni body snapshot'i ve ayni `clientRequestId` ile `Tekrar Dene` yapmalidir.
- Kullanici belirsiz kayit modundayken formu degistirmek isterse UI bunu yeni islem kabul etmeli, eski `clientRequestId` degerini birakip sonraki kaydetmede yeni `clientRequestId` uretmelidir.
- Ayni `clientRequestId` ile farkli body gonderilip API `409 Conflict` donerse UI bunu teknik hata gibi degil, "Bu kayit denemesinin icerigi degismis; yeni islem olarak tekrar kaydedin." durumu gibi ele almalidir.
- `409 Conflict` sonrasi kullanici devam edecekse UI yeni `clientRequestId` uretmeli ve guncel body'yi yeni kaydetme denemesi olarak gondermelidir.
- En guvenli akista `Normal Edit Mode` alanlari degistirilebilir, `Pending/Retry Mode` alanlari kilitlidir; pending durumundan cikmak icin kullanici acikca `Yeni islem olarak duzenle` veya `Vazgec` aksiyonu secmelidir.

Offline durum sorgu endpointleri:

- `GET /api/mal-kabul-islemleri/firma-mal-kabulleri/offline-sync/{clientRequestId}`
- `GET /api/stok-islemleri/sayim-sonuclari/offline-sync/{clientRequestId}`

Ortak offline status response modeli:

```json
{
  "clientRequestId": "7c9b31f6-1ab4-4ed1-b02b-2a90e5e7d3fd",
  "operationCode": "stok-islemleri.sayim-sonuclari.create",
  "status": "Completed",
  "createdAtUtc": "2026-05-06T13:20:11Z",
  "completedAtUtc": "2026-05-06T13:20:13Z",
  "errorMessage": null,
  "result": {}
}
```

`status` alaninin anlamlari:

- `Processing`: istek backend tarafinda rezerve edildi, islem tamamlanmadi veya sonuc henuz toparlanamadi
- `Completed`: istek basariyla tamamlandi; `result` alaninda asil business response bulunur
- `Failed`: son deneme hata ile kapandi; `errorMessage` dolu olabilir. Ayni payload ile retry yapilabilir, ama payload degistiyse yeni `clientRequestId` kullanilmalidir

## Mobil Urun-Fiyat Katalog Sync

Mobil el terminali online iken depo bazli urun, barkod ve fiyat katalogunu indirip kendi local veritabanina kaydedebilir. Cihaz offline oldugunda barkod okutma API'ye gitmeden bu local katalog uzerinden yapilmalidir.

Endpoint:

```text
GET /api/mobile-sync/urun-fiyat-katalogu
```

Yetki:

- `Authorization: Bearer {token}` zorunludur.
- `arama-islemleri.fiyat-gor.list` permission'i gerekir.
- `warehouseNo` verilmezse JWT icindeki depo kullanilir.

Query:

```text
warehouseNo    opsiyonel; verilmezse JWT icindeki depo kullanilir
since          opsiyonel; onceki tamamlanmis syncToken, ISO 8601 tarih
cursor         opsiyonel; hasMore=true ise backend'in verdigi nextCursor
pageSize       opsiyonel; default 5000, max 10000
```

Ilk tam indirme:

```text
GET /api/mobile-sync/urun-fiyat-katalogu?warehouseNo=110&pageSize=5000
```

Devam sayfasi:

```text
GET /api/mobile-sync/urun-fiyat-katalogu?warehouseNo=110&pageSize=5000&cursor={nextCursor}
```

Degisenleri alma:

```text
GET /api/mobile-sync/urun-fiyat-katalogu?warehouseNo=110&since=2026-06-08T10:30:00
```

Response:

```json
{
  "warehouseNo": 110,
  "generatedAt": "2026-06-08T10:35:00",
  "since": "2026-06-08T10:30:00",
  "syncToken": null,
  "nextCursor": "eyJzdG9ja0NvZGUiOiIwMTU1NTAiLCJiYXJjb2RlIjoiODY5MDAwMDAwMDAwMCJ9",
  "hasMore": true,
  "pageSize": 5000,
  "items": [
    {
      "warehouseNo": 110,
      "barcode": "8690000000000",
      "lookupSource": "barcode",
      "stockCode": "015550",
      "stockName": "Stok Adi",
      "price": 125.5,
      "priceTypeCode": 1,
      "unitPointer": 1,
      "unitName": "AD",
      "unitMultiplier": 1,
      "secondaryUnitName": "KOLI",
      "secondaryUnitMultiplier": 12,
      "salesBlockCode": 0,
      "orderBlockCode": 0,
      "goodsAcceptanceBlockCode": 0,
      "isSalesBlocked": false,
      "isOrderBlocked": false,
      "isGoodsAcceptanceBlocked": false,
      "isPassive": false,
      "isDeleted": false,
      "productManagerCode": "PER001",
      "updatedAt": "2026-06-08T10:20:00"
    }
  ],
  "deletedBarcodes": []
}
```

Paging ve sync token kurali:

- `hasMore = true` ise mobil `nextCursor` ile sonraki sayfayi istemelidir.
- `cursor` icinde sync penceresi bilgisi de vardir; devam sayfalarinda `since` tekrar gonderilmek zorunda degildir.
- `syncToken` sadece `hasMore = false` oldugunda kalici olarak saklanmalidir.
- Sonraki sync'te mobil bu degeri `since` olarak gondermelidir.
- Mobil local DB kayitlarini `barcode + warehouseNo` anahtariyla upsert etmelidir.
- `deletedBarcodes` icindeki barkodlar local DB'den silinmeli veya pasif isaretlenmelidir.
- Offline okutma sirasinda bulunan fiyat son basarili sync anindaki fiyattir; UI'da "son guncelleme" bilgisi gosterilmelidir.
- Sync tekrarinda ayni barkodlar tekrar gelebilir; mobil upsert islemi idempotent olmalidir.

Mobil offline okuma akisi:

```text
Online:
1. Mobil katalog endpoint'ini cagirir.
2. hasMore=true oldukca nextCursor ile devam eder.
3. Gelen items local DB'ye yazilir.
4. hasMore=false oldugunda syncToken saklanir.

Offline:
1. Kullanici barkod okutur.
2. Mobil barcode + warehouseNo ile local DB'den urunu bulur.
3. Fiyat, stok adi, birim ve blok bilgileri local kayittan gosterilir.
```

## Mobil Cari Katalog Sync

Mobil el terminali online iken cari/firma katalogunu indirip kendi local veritabanina kaydedebilir. Cihaz offline iken mal kabul, siparis veya iade ekranlarindaki cari secimi bu local katalog uzerinden yapilabilir.

Endpoint:

```text
GET /api/mobile-sync/cari-katalogu
```

Yetki:

- `Authorization: Bearer {token}` zorunludur.
- Ek menu/action permission'i yoktur; login olan kullanici kullanabilir.

Query:

```text
since          opsiyonel; onceki tamamlanmis syncToken, ISO 8601 tarih
cursor         opsiyonel; hasMore=true ise backend'in verdigi nextCursor
pageSize       opsiyonel; default 5000, max 10000
```

Ilk tam indirme:

```text
GET /api/mobile-sync/cari-katalogu?pageSize=5000
```

Devam sayfasi:

```text
GET /api/mobile-sync/cari-katalogu?pageSize=5000&cursor={nextCursor}
```

Degisenleri alma:

```text
GET /api/mobile-sync/cari-katalogu?since=2026-06-08T10:30:00
```

Response:

```json
{
  "generatedAt": "2026-06-08T10:35:00",
  "since": "2026-06-08T10:30:00",
  "syncToken": null,
  "nextCursor": "eyJjdXN0b21lckNvZGUiOiIxMjAuMDEuMDMxMDYifQ",
  "hasMore": true,
  "pageSize": 5000,
  "items": [
    {
      "customerCode": "120.01.03106",
      "customerName": "Firma Adi",
      "customerTitle": "Ticaret Ltd.",
      "customerDisplayName": "Firma Adi Ticaret Ltd.",
      "taxNumber": "1234567890",
      "representativeCode": "PER001",
      "representativeName": "Satis Temsilcisi",
      "invoiceAddressNo": 1,
      "shippingAddressNo": 1,
      "isLocked": false,
      "isClosed": false,
      "isDeleted": false,
      "updatedAt": "2026-06-08T10:20:00"
    }
  ],
  "deletedCustomerCodes": []
}
```

Sync kurali:

- `hasMore = true` ise mobil `nextCursor` ile sonraki sayfayi istemelidir.
- `syncToken` sadece `hasMore = false` oldugunda kalici olarak saklanmalidir.
- Sonraki sync'te mobil bu degeri `since` olarak gondermelidir.
- Mobil local DB kayitlarini `customerCode` anahtariyla upsert etmelidir.
- `deletedCustomerCodes` icindeki cariler local DB'den silinmeli veya pasif isaretlenmelidir.
- Ilk tam indirme silinmis/pasif kayitlari dondurmez; `since` ile delta sync yapildiginda silinen kayitlar da bildirilir.

## Mobil Depo Katalog Sync

Mobil el terminali online iken depo katalogunu indirip kendi local veritabanina kaydedebilir. Cihaz offline iken hedef depo, kaynak depo veya karsi depo secimleri bu local katalog uzerinden yapilabilir.

Endpoint:

```text
GET /api/mobile-sync/depo-katalogu
```

Yetki:

- `Authorization: Bearer {token}` zorunludur.
- Ek menu/action permission'i yoktur; login olan kullanici kullanabilir.

Query:

```text
since          opsiyonel; onceki tamamlanmis syncToken, ISO 8601 tarih
cursor         opsiyonel; hasMore=true ise backend'in verdigi nextCursor
pageSize       opsiyonel; default 5000, max 10000
```

Ilk tam indirme:

```text
GET /api/mobile-sync/depo-katalogu?pageSize=5000
```

Devam sayfasi:

```text
GET /api/mobile-sync/depo-katalogu?pageSize=5000&cursor={nextCursor}
```

Degisenleri alma:

```text
GET /api/mobile-sync/depo-katalogu?since=2026-06-08T10:30:00
```

Response:

```json
{
  "generatedAt": "2026-06-08T10:35:00",
  "since": "2026-06-08T10:30:00",
  "syncToken": null,
  "nextCursor": "eyJ3YXJlaG91c2VObyI6MTEwfQ",
  "hasMore": true,
  "pageSize": 5000,
  "items": [
    {
      "warehouseNo": 110,
      "warehouseName": "Kestel Depo",
      "companyNo": 0,
      "branchNo": 0,
      "groupCode": "SUBE",
      "warehouseType": 0,
      "responsibilityCenterCode": "SRM001",
      "projectCode": "",
      "address": "Adres satiri",
      "district": "Kestel",
      "province": "Bursa",
      "isInventoryExcluded": false,
      "isDeleted": false,
      "updatedAt": "2026-06-08T10:20:00"
    }
  ],
  "deletedWarehouseNos": []
}
```

Sync kurali:

- `hasMore = true` ise mobil `nextCursor` ile sonraki sayfayi istemelidir.
- `syncToken` sadece `hasMore = false` oldugunda kalici olarak saklanmalidir.
- Sonraki sync'te mobil bu degeri `since` olarak gondermelidir.
- Mobil local DB kayitlarini `warehouseNo` anahtariyla upsert etmelidir.
- `deletedWarehouseNos` icindeki depolar local DB'den silinmeli veya pasif isaretlenmelidir.
- Ilk tam indirme silinmis/pasif kayitlari dondurmez; `since` ile delta sync yapildiginda silinen kayitlar da bildirilir.

## Base URL

Development:

```text
http://localhost:5228
```

Swagger:

```text
http://localhost:5228/swagger
```

Root bilgi endpoint'i:

```text
GET /
```

Response:

```json
{
  "service": "FurpaMerkezApi",
  "architecture": "Clean Architecture",
  "authDatabase": "FurpaMerkezDb",
  "businessDatabase": "MikroDB_V16_FURPA_2024",
  "swagger": "/swagger",
  "status": "Running"
}
```

## Standart Hata Formati

Hata cevaplari `application/problem+json` olarak doner.

Ornek:

```json
{
  "status": 404,
  "title": "Not Found",
  "detail": "Warehouse order detail was not found.",
  "instance": "/api/siparis-islemleri/verilen-depo-siparisleri/D110/1915"
}
```

Olasi durumlar:

- `400` validation veya hatali request
- `401` token yok/gecersiz
- `403` yetki yok
- `404` kayit bulunamadi
- `409` conflict/is kurali cakisiyor
- `501` route acik ama backend henuz implement edilmedi

## Kimlik Akisi

UI akisi:

1. `POST /api/auth/login`
2. `accessToken`, `refreshToken`, `expiresAtUtc` ve `refreshTokenExpiresAtUtc` al
3. API isteklerinde sadece `accessToken` degerini `Authorization: Bearer {token}` olarak gonder
4. `GET /api/auth/me` ile kullanici, roller, permission listesi ve module-menu-action agacini al
5. sol menu ve butonlari bu cevapla ciz
6. terminal/session depo kontrolu gerekiyorsa periyodik olarak `GET /api/auth/warehouse-context` cagir
7. access token suresi dolmadan veya 401 alindiginda `POST /api/auth/refresh` ile yeni access/refresh token al
8. kullanici cikis yaparsa `POST /api/auth/logout` ile refresh token'i iptal et

Token ve yetki notu:

- Login/register/refresh response modeli `AuthResponse` doner: `accessToken`, `expiresAtUtc`, `user`, `refreshToken`, `refreshTokenExpiresAtUtc`.
- `Authorization` header'inda sadece `accessToken` gonderilir. Tum login response'u, `user` objesi veya `permissions/modules` listesi header'a konmaz.
- `refreshToken` header'a konmaz; sadece `/api/auth/refresh` ve `/api/auth/logout` body alaninda kullanilir.
- Backend JWT'yi header limitlerine takilmamak icin kompakt tutar. Token icinde tum permission listesi garanti edilmez.
- UI, JWT decode ederek menu/buton yetkisi uretmemelidir. Full yetki listesi icin `login.user.permissions` veya `GET /api/auth/me` cevabindaki `permissions` kullanilir.
- Periyodik depo/session kontrolu icin `GET /api/auth/me` yerine `GET /api/auth/warehouse-context` kullanilmalidir. Bu endpoint permission/menu agaci dondurmez ve hafif calisir.
- `400 Bad Request - Request Too Long` gorulurse ilk kontrol `Authorization` header'idir; `Bearer eyJ...` disinda JSON/obje veya asiri uzun header gonderiliyor olabilir.
- Refresh token rotate edilir: `/refresh` basarili olunca eski refresh token iptal olur, response'taki yeni `refreshToken` saklanir.
- Kullanici yonetiminde `newPassword` ile sifre degistirilirse kullanicinin aktif refresh token'lari iptal edilir. Access token suresi dolana kadar calisabilir; yeni token almak icin tekrar login gerekir.

## Auth Endpointleri

### `POST /api/auth/login`

Amac:

- kullanici girisi

Request:

```json
{
  "usernameOrEmail": "admin",
  "password": "REPLACE_WITH_PASSWORD"
}
```

Response:

```json
{
  "accessToken": "jwt-token",
  "expiresAtUtc": "2026-04-15T12:00:00Z",
  "refreshToken": "refresh-token",
  "refreshTokenExpiresAtUtc": "2026-04-29T12:00:00Z",
  "user": {
    "id": "8c2c3d56-3f0d-4ab3-8b2d-4f2d17d6d100",
    "username": "admin",
    "email": "admin@furpamerkez.local",
    "firstName": "System",
    "lastName": "Admin",
    "warehouseNo": "110",
    "warehouseName": "KESTEL 1",
    "isActive": true,
    "roles": ["Administrator"],
    "permissions": [
      "siparis-islemleri.alinan-depo-siparisleri.list",
      "siparis-islemleri.verilen-depo-siparisleri.detail"
    ],
    "modules": [],
    "createdAtUtc": "2026-04-14T12:00:00Z",
    "updatedAtUtc": null
  }
}
```

### `POST /api/auth/refresh`

Amac:

- access token suresi dolunca tekrar kullanici sifresi istemeden yeni access token almak
- refresh token'i rotate etmek

Request:

```json
{
  "refreshToken": "refresh-token"
}
```

Response:

- `POST /api/auth/login` ile ayni `AuthResponse` modelini doner.
- Response icindeki yeni `refreshToken` saklanmali, eski refresh token kullanilmamalidir.
- Refresh token gecersiz, suresi dolmus, iptal edilmis veya kullanici pasifse `401 Unauthorized` doner.

### `POST /api/auth/logout`

Amac:

- refresh token'i iptal etmek

Request:

```json
{
  "refreshToken": "refresh-token"
}
```

Response:

- `204 No Content`
- Access token server tarafinda aninda geri cekilmez; istemci kendi access token'ini storage'dan silmelidir.

### `POST /api/auth/register`

Amac:

- yeni kullanici kaydi

Request:

```json
{
  "username": "jdoe",
  "email": "jdoe@firma.local",
  "password": "Test123!",
  "firstName": "John",
  "lastName": "Doe",
  "warehouseNo": "110",
  "warehouseName": "KESTEL 1"
}
```

Response modeli:

- `POST /api/auth/login` ile ayni `AuthResponse` modelini doner.
- Yani response alanlari `accessToken`, `expiresAtUtc`, `user`, `refreshToken` ve `refreshTokenExpiresAtUtc` alanlaridir.
- `400` validation hatasi, `409` ayni username/email zaten varsa conflict doner.

### `GET /api/auth/me`

Amac:

- login olan kullanicinin tum profil, rol, permission ve menu agacini almak

Header:

```text
Authorization: Bearer {token}
```

Response modeli:

```json
{
  "id": "guid",
  "username": "admin",
  "email": "admin@furpamerkez.local",
  "firstName": "System",
  "lastName": "Admin",
  "warehouseNo": "110",
  "warehouseName": "KESTEL 1",
  "isActive": true,
  "roles": ["Administrator"],
  "permissions": [
    "siparis-islemleri.alinan-depo-siparisleri.list",
    "siparis-islemleri.alinan-depo-siparisleri.detail"
  ],
  "modules": [
    {
      "code": "siparis-islemleri",
      "name": "SiparisIslemleri",
      "menus": [
        {
          "code": "alinan-depo-siparisleri",
          "name": "AlinanDepoSiparisleri",
          "actions": [
            {
              "code": "list",
              "name": "Listele",
              "permissionCode": "siparis-islemleri.alinan-depo-siparisleri.list",
              "description": "SiparisIslemleri > AlinanDepoSiparisleri > Listele yetkisi."
            }
          ]
        }
      ]
    }
  ],
  "createdAtUtc": "2026-04-14T12:00:00Z",
  "updatedAtUtc": null
}
```

UI kullanim notu:

- Sol menu `modules` alanindan uretilmeli
- Listele / Detay / Ekle / Guncelle butonlari `actions` uzerinden kontrol edilmeli
- Ayrica tekil kontrol gerekiyorsa `permissions` listesi de kullanilabilir

### `GET /api/auth/warehouse-context`

Amac:

- terminal/mobil oturumunda kullanicinin mevcut ag/depo baglaminin degisip degismedigini hafif sekilde kontrol etmek
- `/api/auth/me` gibi rol, permission ve menu agaci dondurmeden periyodik kontrol yapmak

Header:

```text
Authorization: Bearer {token}
```

Response:

```json
{
  "userId": "8c2c3d56-3f0d-4ab3-8b2d-4f2d17d6d100",
  "username": "160.magazaci",
  "tokenWarehouseNo": "160",
  "tokenWarehouseName": "160 SUBE",
  "currentWarehouseNo": "161",
  "currentWarehouseName": "Depo 161",
  "isTerminalUser": true,
  "requiresRelogin": true,
  "reason": "WarehouseChanged",
  "serverTimeUtc": "2026-08-25T07:25:00Z"
}
```

Alan notlari:

- `tokenWarehouseNo` / `tokenWarehouseName`: Auth DB'deki kullanici deposudur; token/session deposu gibi okunabilir.
- `currentWarehouseNo` / `currentWarehouseName`: request IP'sinin Furpa `BranchDetails.BranchIpAddress` ayarlarindan cozuldugu aktif depo baglamidir. Cozulemez veya ag birden fazla depoya denk gelirse `null` gelebilir.
- `isTerminalUser`: kullanicinin terminal roluyle acilip acilmadigini belirtir.
- `requiresRelogin`: `true` ise UI kullaniciyi oturumdan cikarmali ve tekrar login istemelidir.
- `reason`: `Ok`, `SharedNetwork`, `WarehouseChanged`, `NetworkUnknown`, `NetworkAmbiguous`, `NotTerminalUser`, `UserInactive`, `InvalidTokenWarehouse` degerlerinden biri olabilir.
- Backend sadece terminal kullanicilarda IP/depo degisimini relogin sebebi yapar. Admin/merkez gibi terminal olmayan kullanicilarda `requiresRelogin=false`, `reason=NotTerminalUser` doner.
- `Auth:TerminalLogin:SharedNetworkWarehouseGroups` icinde ayni grupta olan depolar ortak ag kabul edilir. Ornek `[50, 56]` tanimliyken 56 terminal kullanicisi 50 agindan gorunurse `requiresRelogin=false`, `reason=SharedNetwork` doner.
- `NetworkUnknown` ve `NetworkAmbiguous` durumlarinda kullanici gereksiz atilmaz; UI bu durumlari sessiz gecmelidir.

UI kullanim notu:

- Terminal/mobil uygulama aktifken 1 dakikada bir bu endpoint cagrilabilir.
- `requiresRelogin=true` veya `401 Unauthorized` gelirse UI logout yapmalidir.
- UI logout kararini `currentWarehouseNo !== tokenWarehouseNo` karsilastirmasiyla vermemelidir; 50/56 gibi ortak aglarda bu alanlar farkli olabilir ama `requiresRelogin=false` doner.
- Ag yoksa, HTTP status `0` veya network exception durumunda UI kullaniciyi atmamalidir; offline akis devam edebilir.
- Bu endpoint katalog, permission, rol veya menu verisi dondurmez; periyodik kontrol icin `/api/auth/me` yerine tercih edilmelidir.

## Yetki ve Kullanici Yonetimi

Bu ekranlar yonetim paneli UI'i icin kullanilabilir.

Not:

- Yetki, rol ve kullanici endpointlerinin `/api/kullanici-islemleri/...` alias route'lari da vardir.
- Ana route ile alias route ayni response ve yetki davranisini kullanir.

### Permission Catalog

`GET /api/permissions/catalog`

veya alias:

`GET /api/kullanici-islemleri/yetkiler/catalog`

Amac:

- sistemde tanimli tum module-menu-action agacini almak

Response:

```json
[
  {
    "code": "siparis-islemleri",
    "name": "SiparisIslemleri",
    "menus": [
      {
        "code": "alinan-depo-siparisleri",
        "name": "AlinanDepoSiparisleri",
        "actions": [
          {
            "code": "list",
            "name": "Listele",
            "permissionCode": "siparis-islemleri.alinan-depo-siparisleri.list",
            "description": "SiparisIslemleri > AlinanDepoSiparisleri > Listele yetkisi."
          }
        ]
      }
    ]
  }
]
```

### Permission List

`GET /api/permissions`

veya alias:

`GET /api/kullanici-islemleri/yetkiler`

Her permission satiri:

```json
{
  "id": "guid",
  "code": "siparis-islemleri.alinan-depo-siparisleri.list",
  "name": "AlinanDepoSiparisleri Listele",
  "description": "SiparisIslemleri > AlinanDepoSiparisleri > Listele yetkisi.",
  "moduleCode": "siparis-islemleri",
  "moduleName": "SiparisIslemleri",
  "menuCode": "alinan-depo-siparisleri",
  "menuName": "AlinanDepoSiparisleri",
  "actionCode": "list",
  "actionName": "Listele",
  "createdAtUtc": "2026-04-14T12:00:00Z",
  "updatedAtUtc": null
}
```

### Permission Create

`POST /api/permissions`

veya alias:

`POST /api/kullanici-islemleri/yetkiler`

Request:

```json
{
  "code": "siparis-islemleri.verilen-depo-siparisleri.list",
  "name": "VerilenDepoSiparisleri Listele",
  "description": "SiparisIslemleri > VerilenDepoSiparisleri > Listele yetkisi."
}
```

Response modeli:

- `Permission List` altindaki tekil `PermissionDto` modeli doner.
- `200` basarili create, `400` validation, `409` duplicate conflict doner.

### Permission Update

`PUT /api/permissions/{id}`

veya alias:

`PUT /api/kullanici-islemleri/yetkiler/{id}`

Request modeli Permission Create ile aynidir.

Response modeli:

- `Permission List` altindaki tekil `PermissionDto` modeli doner.
- `200` basarili update, `400` validation, `404` kayit bulunamadi, `409` duplicate conflict doner.

### Role List

`GET /api/roles`

veya alias:

`GET /api/kullanici-islemleri/roller`

Her role:

```json
{
  "id": "guid",
  "name": "Administrator",
  "description": "Sistem yonetici rolu",
  "isActive": true,
  "permissions": [],
  "createdAtUtc": "2026-04-14T12:00:00Z",
  "updatedAtUtc": null
}
```

### Role Create

`POST /api/roles`

veya alias:

`POST /api/kullanici-islemleri/roller`

Request:

```json
{
  "name": "SatisYoneticisi",
  "description": "Siparis ekranlarini yonetir",
  "isActive": true
}
```

Response modeli:

- `Role List` altindaki tekil `RoleDto` modeli doner.
- `200` basarili create, `400` validation, `409` duplicate conflict doner.

### Role Update

`PUT /api/roles/{id}`

veya alias:

`PUT /api/kullanici-islemleri/roller/{id}`

Request modeli Role Create ile aynidir.

Response modeli:

- `Role List` altindaki tekil `RoleDto` modeli doner.
- `200` basarili update, `400` validation, `404` kayit bulunamadi, `409` duplicate conflict doner.

### Role Permission Atama

`POST /api/roles/{id}/permissions`

veya alias:

`POST /api/kullanici-islemleri/roller/{id}/permissions`

Request:

```json
{
  "permissionIds": [
    "guid-1",
    "guid-2"
  ]
}
```

Response modeli:

- `Role List` altindaki tekil `RoleDto` modeli doner.
- `permissions` koleksiyonu yeni haliyle response icinde gelir.
- `200` basarili atama, `400` validation, `404` role veya permission kaydi bulunamadi doner.

### User List

`GET /api/users`

veya alias:

`GET /api/kullanici-islemleri/kullanicilar`

Response modeli:

- `UserDto[]` doner.
- Dizideki her item `GET /api/auth/me` icindeki user modeliyle aynidir.

### User Detail

`GET /api/users/{id}`

veya alias:

`GET /api/kullanici-islemleri/kullanicilar/{id}`

Response modeli `GET /api/auth/me` icindeki user modeliyle aynidir.

### User Update

`PUT /api/users/{id}`

veya alias:

`PUT /api/kullanici-islemleri/kullanicilar/{id}`

Request:

```json
{
  "username": "jdoe",
  "email": "jdoe@firma.local",
  "firstName": "John",
  "lastName": "Doe",
  "warehouseNo": "110",
  "warehouseName": "KESTEL 1",
  "isActive": true,
  "newPassword": null
}
```

`newPassword` opsiyoneldir. Bos/null gonderilirse mevcut sifre korunur. Dolu gonderilirse en az 6 karakter olmalidir, sifre hash'lenerek kaydedilir ve kullanicinin aktif refresh token'lari iptal edilir.

Response modeli:

- `User Detail` ile ayni `UserDto` modeli doner.
- `200` basarili update, `400` validation, `404` kayit bulunamadi, `409` duplicate conflict doner.

### User Role Atama

`POST /api/users/{id}/roles`

veya alias:

`POST /api/kullanici-islemleri/kullanicilar/{id}/roles`

Request:

```json
{
  "roleIds": [
    "guid-1",
    "guid-2"
  ]
}
```

Response modeli:

- `User Detail` ile ayni `UserDto` modeli doner.
- `roles` koleksiyonu yeni haliyle response icinde gelir.
- `200` basarili atama, `400` validation, `404` user veya role kaydi bulunamadi doner.

## Ayar Islemleri

Bu modul eski `SettingsController` islevlerini yeni API mimarisine uygun olarak ayri menu altinda toplar:

- `AyarIslemleri > Cihazlar`
- `AyarIslemleri > SubeAyarlari`
- `AyarIslemleri > KasaPosTerminalleri`
- `AyarIslemleri > Kasiyerler`
- `AyarIslemleri > Soforler`
- `AyarIslemleri > B2BAyarlari`

Veri kaynaklari:

- Furpa DB: `DeviceDetails`, `DeviceTypes`, `BranchDetails`, `CashRegistryDetails`, `Cashiers`
- FurpaB2B DB: `Bultens`, `Users`, `UserAccounts`
- Mikro write DB: `CashRegisterDetails`, `CashRegisterBranches`
- Auth DB: `despatch_drivers`

Onemli alan ayrimi:

- `cashNo`: integer sube icindeki fiziksel/operasyonel kasa no. Ornek: `130`.
- `cashRegisterNo`: geriye uyumluluk icin bazi kasa response'larinda `cashNo` ile ayni integer kasa no olarak donebilir.
- `cashFinanceNumber`: kasanin banka/POS/Z raporu tarafindaki finans/terminal grup numarasi. Ornek: `PAV210010584`.
- `terminalNo`: POS terminal grup numarasi; ayar terminal response'unda `CashRegisterDetails.CashRegisterNo` karsiligi olarak gelir. Yeni UI'da gorunen/anahtar isim icin `cashRegisterNo` alias'i da vardir.
- `branchNo`: sube/depo no

Kasa ve terminal kaynagi:

- Sube kasa listesi `GET /api/ayar-islemleri/sube-ayarlari/{branchNo}/kasalar` tarafinda Furpa `CashRegistryDetails` kaydindan kasa no'yu okur.
- Ayni response'taki `cashFinanceNumber`, once Furpa `CashRegisterDetails` icindeki `CashNo -> CashRegisterNo` eslesmesinden cozulur; Furpa'da yoksa Mikro `CashRegisterDetails` fallback olarak kullanilir.
- Kasa/POS terminal listesi `GET /api/ayar-islemleri/kasa-pos-terminalleri/kasalar/{cashNo}/terminaller` tarafinda once Furpa `CashRegisterDetails` kayitlarini dondurur. Furpa'da ilgili `cashNo` icin terminal yoksa Mikro `CashRegisterDetails` fallback olarak kullanilir.
- Icmal/kasa sayim banka odeme tipi seciminde UI `cashNo` yerine mumkunse `cashFinanceNumber` gondermelidir. Ornek: kasa `130`, finans no `PAV210010584` ise banka odeme tipi endpointi `cashRegisterNo=PAV210010584` ile cagrilir.
- `cashNo` sadece subedeki kasa numarasidir; banka/POS eslesmesinin guvenilir anahtari `cashFinanceNumber`/terminal `cashRegisterNo` degeridir.

Kasiyer listelerinde sifre donmez. Yeni kasiyer olusturma ve sifre sifirlama response'lari uretilen sifreyi tek seferlik `generatedPassword` alaninda dondurur.

UI icin tip/lookup kullanimi:

- Sube ayarlari ekrani acilirken `GET /api/ayar-islemleri/sube-ayarlari/secenekler` cagrilip `scalesTypes` ve `cashTypes` dropdown'lari doldurulabilir.
- Kasa/POS terminal ekrani acilirken `GET /api/ayar-islemleri/kasa-pos-terminalleri/secenekler` cagrilip `cashTypes` ve `terminalBanks` dropdown'lari doldurulabilir.
- Cihaz tipi dropdown'i icin mevcut `GET /api/ayar-islemleri/cihazlar/tipler` endpoint'i kullanilir.
- E-irsaliye gonderme modalinda sofor secimi icin `GET /api/ayar-islemleri/soforler?search=ali&take=20` kullanilir. Secilen kaydin `id` degeri e-irsaliye body icinde `driverId` olarak gonderilebilir; UI isterse `fullName`, `plateNumber` ve `tckn` alanlarini forma otomatik basar.
- Numeric alanlar geriye uyumluluk icin korunur; response'larda yanina `scalesTypeName`, `cashTypeName`, `cashRegisterTypeName`, `stateName` ve aciklama alanlari eklenir.
- `ScalesType` desteklenen kesin katalogdur: `0 = CAS 16`, `1 = CAS 500`.
- `CashType` katalogu UI icin anlamli adlarla doner: `0 = Standart POS Kasasi`, `1 = Ek POS Kasasi`. UI dropdown/liste etiketlerinde numeric degeri degil `name`/`cashTypeName`/`cashRegisterTypeName` alanini gostermelidir.
- Lookup endpointleri sabit kataloglari ve veritabaninda mevcut tanimsiz degerleri birlikte dondurur; tanimsiz degerlerde `isKnown=false` gelir.

Yetki kodlari:

```text
ayar-islemleri.cihazlar.list
ayar-islemleri.cihazlar.detail
ayar-islemleri.cihazlar.create
ayar-islemleri.cihazlar.update

ayar-islemleri.sube-ayarlari.list
ayar-islemleri.sube-ayarlari.detail
ayar-islemleri.sube-ayarlari.create
ayar-islemleri.sube-ayarlari.update

ayar-islemleri.kasa-pos-terminalleri.list
ayar-islemleri.kasa-pos-terminalleri.detail
ayar-islemleri.kasa-pos-terminalleri.create
ayar-islemleri.kasa-pos-terminalleri.update

ayar-islemleri.kasiyerler.list
ayar-islemleri.kasiyerler.detail
ayar-islemleri.kasiyerler.create
ayar-islemleri.kasiyerler.update

ayar-islemleri.soforler.manage
ayar-islemleri.soforler.list
ayar-islemleri.soforler.detail
ayar-islemleri.soforler.create
ayar-islemleri.soforler.update
ayar-islemleri.soforler.delete
ayar-islemleri.soforler.all-warehouses

ayar-islemleri.b2b-ayarlari.manage
ayar-islemleri.b2b-ayarlari.list
ayar-islemleri.b2b-ayarlari.detail
ayar-islemleri.b2b-ayarlari.create
ayar-islemleri.b2b-ayarlari.update
ayar-islemleri.b2b-ayarlari.delete
ayar-islemleri.b2b-ayarlari.all-warehouses
```

Not: `Soforler` ekrani tanim/yonetim ekranidir. UI menu/route acilisinda `ayar-islemleri.soforler.manage` yetkisine bakmali; liste ve butonlarda ilgili `list/detail/create/update/delete` yetkilerini kullanmalidir.

Not: `B2BAyarlari` ekrani tanim/yonetim ekranidir. UI menu/route acilisinda `ayar-islemleri.b2b-ayarlari.manage` yetkisine bakmali; bulten ve kullanici aksiyonlarinda ilgili `list/detail/create/update/delete` yetkilerini kullanmalidir. B2B kullanici sifre hash/salt alanlari API response'unda donmez ve bu ekrandan sifre degistirilmez.

Endpoint ozeti:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `GET /api/ayar-islemleri/cihazlar/tipler` | - | - | `DeviceTypeDto[]` | `cihazlar.list` |
| `GET /api/ayar-islemleri/cihazlar?branchNo=110` | query | `branchNo?: int` | `DeviceDto[]` | `cihazlar.list` |
| `GET /api/ayar-islemleri/cihazlar/durum?branchNo=110` | query | `branchNo?: int` | `DeviceStatusDto[]` | `cihazlar.list` |
| `GET /api/ayar-islemleri/cihazlar/subeler/{branchNo}/durum` | path | `branchNo: int` | `DeviceStatusDto[]` | `cihazlar.list` |
| `POST /api/ayar-islemleri/cihazlar` | body | `CreateDeviceHttpRequest` | `DeviceDto` | `cihazlar.create` |
| `DELETE /api/ayar-islemleri/cihazlar/{id}` | path | `id: int` | - | `cihazlar.update` |
| `GET /api/ayar-islemleri/sube-ayarlari/secenekler` | - | - | `BranchSettingsLookupsDto` | `sube-ayarlari.list` |
| `GET /api/ayar-islemleri/sube-ayarlari` | - | - | `BranchDetailDto[]` | `sube-ayarlari.list` |
| `GET /api/ayar-islemleri/sube-ayarlari/{branchNo}` | path | `branchNo: int` | `BranchDetailDto` | `sube-ayarlari.detail` |
| `GET /api/ayar-islemleri/sube-ayarlari/{branchNo}/kasalar` | path | `branchNo: int` | `CashRegistryDto[]` | `sube-ayarlari.detail` |
| `POST /api/ayar-islemleri/sube-ayarlari` | body | `CreateBranchSettingsHttpRequest` | `BranchDetailDto` | `sube-ayarlari.create` |
| `PUT /api/ayar-islemleri/sube-ayarlari/{branchNo}` | body + path | `UpdateBranchSettingsHttpRequest` | `BranchDetailDto` | `sube-ayarlari.update` |
| `GET /api/ayar-islemleri/kasa-pos-terminalleri/secenekler` | - | - | `CashRegisterSettingsLookupsDto` | `kasa-pos-terminalleri.list` |
| `GET /api/ayar-islemleri/kasa-pos-terminalleri/kasalar/{cashNo}/terminaller` | path | `cashNo: int` | `CashRegisterTerminalDto[]` | `kasa-pos-terminalleri.list` |
| `GET /api/ayar-islemleri/kasa-pos-terminalleri/mevcut-sube/mesaj-durumlari` | JWT | - | `CashRegisterMessageStatusDto[]` | `kasa-pos-terminalleri.list` |
| `GET /api/ayar-islemleri/kasa-pos-terminalleri/subeler/{branchNo}/mesaj-durumlari` | path | `branchNo: int` | `CashRegisterMessageStatusDto[]` | `kasa-pos-terminalleri.list` |
| `POST /api/ayar-islemleri/kasa-pos-terminalleri` | body | `CreateCashRegisterHttpRequest` | `CashRegisterResponse` | `kasa-pos-terminalleri.create` |
| `DELETE /api/ayar-islemleri/kasa-pos-terminalleri/subeler/{branchNo}/kasalar/{cashNo}` | path | `branchNo`, `cashNo` | - | `kasa-pos-terminalleri.update` |
| `DELETE /api/ayar-islemleri/kasa-pos-terminalleri/subeler/{branchNo}/terminaller/{terminalNo}` | path | `branchNo`, `terminalNo` | - | `kasa-pos-terminalleri.update` |
| `GET /api/ayar-islemleri/kasiyerler` | - | - | `CashierDto[]` | `kasiyerler.list` |
| `POST /api/ayar-islemleri/kasiyerler` | body | `CreateCashierHttpRequest` | `CashierPasswordMutationDto` | `kasiyerler.create` |
| `PUT /api/ayar-islemleri/kasiyerler/{cashierCode}` | body + path | `UpdateCashierHttpRequest` | `CashierDto` | `kasiyerler.update` |
| `POST /api/ayar-islemleri/kasiyerler/{cashierCode}/sifre-sifirla` | path | `cashierCode: int` | `CashierPasswordMutationDto` | `kasiyerler.update` |
| `GET /api/ayar-islemleri/soforler?search=&includeInactive=false&take=100` | query | `DespatchDriverListHttpRequest` | `DespatchDriverDto[]` | `soforler.list` |
| `GET /api/ayar-islemleri/soforler/{id}` | path | `id: guid` | `DespatchDriverDto` | `soforler.detail` |
| `POST /api/ayar-islemleri/soforler` | body | `SaveDespatchDriverHttpRequest` | `DespatchDriverDto` | `soforler.create` |
| `PUT /api/ayar-islemleri/soforler/{id}` | body + path | `SaveDespatchDriverHttpRequest` | `DespatchDriverDto` | `soforler.update` |
| `DELETE /api/ayar-islemleri/soforler/{id}` | path | `id: guid` | - | `soforler.delete` |
| `GET /api/ayar-islemleri/b2b-ayarlari/bultenler?search=&take=100` | query | `B2BBulletinListHttpRequest` | `B2BBulletinDto[]` | `b2b-ayarlari.list` |
| `POST /api/ayar-islemleri/b2b-ayarlari/bultenler` | body | `SaveB2BBulletinHttpRequest` | `B2BBulletinDto` | `b2b-ayarlari.create` |
| `PUT /api/ayar-islemleri/b2b-ayarlari/bultenler/{id}` | body + path | `SaveB2BBulletinHttpRequest` | `B2BBulletinDto` | `b2b-ayarlari.update` |
| `DELETE /api/ayar-islemleri/b2b-ayarlari/bultenler/{id}` | path | `id: int` | - | `b2b-ayarlari.delete` |
| `GET /api/ayar-islemleri/b2b-ayarlari/kullanicilar?search=&includeInactive=false&take=100` | query | `B2BUserListHttpRequest` | `B2BUserDto[]` | `b2b-ayarlari.list` |
| `GET /api/ayar-islemleri/b2b-ayarlari/kullanicilar/{userId}` | path | `userId: guid` | `B2BUserDetailDto` | `b2b-ayarlari.detail` |
| `PUT /api/ayar-islemleri/b2b-ayarlari/kullanicilar/{userId}` | body + path | `UpdateB2BUserHttpRequest` | `B2BUserDetailDto` | `b2b-ayarlari.update` |

### Cihazlar

`GET /api/ayar-islemleri/cihazlar/tipler`

Cihaz ekleme dropdown kaynagidir.

Response:

```json
[
  {
    "id": 1,
    "deviceName": "Terazi"
  }
]
```

`GET /api/ayar-islemleri/cihazlar?branchNo=110`

`branchNo` opsiyoneldir. Verilmezse tum cihaz kayitlari listelenir. Liste `branchNo`, cihaz tipi ve IP adresine gore siralanir.

Response:

```json
[
  {
    "id": 12,
    "branchNo": 110,
    "deviceTypeId": 1,
    "deviceTypeName": "Terazi",
    "ipAddress": "192.168.1.10",
    "description": "Manav terazisi"
  }
]
```

`POST /api/ayar-islemleri/cihazlar`

Body:

```json
{
  "branchNo": 110,
  "deviceTypeId": 1,
  "ipAddress": "192.168.1.10",
  "description": "Manav terazisi"
}
```

Validasyon:

- `branchNo` pozitif integer
- `deviceTypeId` pozitif integer ve mevcut cihaz tipi olmali
- `ipAddress` zorunlu ve IP formatinda olmali
- Ayni `branchNo + deviceTypeId + ipAddress` tekrar eklenirse `409 Conflict` doner

Response `201 Created`: `DeviceDto`

`DELETE /api/ayar-islemleri/cihazlar/{id}`

Basarili silme `204 No Content` doner. Kayit yoksa `404 Not Found` doner.

`GET /api/ayar-islemleri/cihazlar/durum?branchNo=110`

`branchNo` verilmezse JWT icindeki `warehouse_no` kullanilir. Backend her cihaz IP adresine 1000 ms timeout ile ping atar. Bir cihazdaki ping hatasi tum response'u bozmaz; ilgili satir `online=false` ve `error` ile doner.

Response:

```json
[
  {
    "branchNo": 110,
    "deviceTypeId": 1,
    "deviceTypeName": "Terazi",
    "ipAddress": "192.168.1.10",
    "description": "Manav terazisi",
    "online": true,
    "latencyMs": 12,
    "error": null
  }
]
```

### Sube Ayarlari

`GET /api/ayar-islemleri/sube-ayarlari/secenekler`

Sube ayarlari formundaki terazi tipi ve kasa tipi secimlerinin dropdown kaynagidir.

Response:

```json
{
  "scalesTypes": [
    {
      "value": 0,
      "code": "cas-16",
      "name": "CAS 16",
      "description": "Terazi.plu formatinda CAS 16 terazi dosyasi uretir.",
      "isKnown": true
    },
    {
      "value": 1,
      "code": "cas-500",
      "name": "CAS 500",
      "description": "ART_STM.txt formatinda CAS 500 terazi dosyasi uretir.",
      "isKnown": true
    }
  ],
  "cashTypes": [
    {
      "value": 0,
      "code": "standard-pos-cash-register",
      "name": "Standart POS Kasasi",
      "description": "Subenin POSKON/MESAJ dosya islemlerine dahil edilen standart satis kasasi.",
      "isKnown": true
    },
    {
      "value": 1,
      "code": "additional-pos-cash-register",
      "name": "Ek POS Kasasi",
      "description": "Subede standart kasa disinda tanimli ek POS kasasi; POSKON/MESAJ ve kasa hareket islemlerinde kasa no ile takip edilir.",
      "isKnown": true
    }
  ]
}
```

`GET /api/ayar-islemleri/sube-ayarlari`

Sube ayarlari listesidir. `branchNo asc` siralanir.

Response:

```json
[
  {
    "branchNo": 110,
    "branchIpAddress": "192.168.1.5",
    "branchScalesFolderPath": "TERAZI",
    "scalesType": 1,
    "scalesTypeName": "CAS 500",
    "scalesTypeDescription": "ART_STM.txt formatinda CAS 500 terazi dosyasi uretir.",
    "poskonFolderPath": "POSKON",
    "posGenelFolderPath": "POSGENEL"
  }
]
```

`GET /api/ayar-islemleri/sube-ayarlari/{branchNo}/kasalar`

Subeye bagli kasa tanimlarini doner.

Response:

```json
[
  {
    "detailId": 1,
    "branchNo": 110,
    "cashNo": 1,
    "cashRegisterNo": 1,
    "cashType": 1,
    "cashRegisterType": 1,
    "cashTypeName": "Ek POS Kasasi",
    "cashRegisterTypeName": "Ek POS Kasasi",
    "cashTypeDescription": "Subede standart kasa disinda tanimli ek POS kasasi; POSKON/MESAJ ve kasa hareket islemlerinde kasa no ile takip edilir.",
    "cashRegisterTypeDescription": "Subede standart kasa disinda tanimli ek POS kasasi; POSKON/MESAJ ve kasa hareket islemlerinde kasa no ile takip edilir.",
    "cashFinanceNumber": "PAV210010584"
  }
]
```

Not:

- `cashNo` / `cashRegisterNo` bu endpointte sube icindeki kasa numarasidir.
- `cashFinanceNumber` bankalar, Z raporu ve kasa sayim banka odeme tipi lookup'inda kullanilacak asil anahtardir.
- UI kasa seciminde kullaniciya `Kasa 130 - PAV210010584` gibi gosterebilir; banka odeme tiplerini getirirken `cashFinanceNumber` degerini `cashRegisterNo` query alanina yazmalidir.

`POST /api/ayar-islemleri/sube-ayarlari`

Body:

```json
{
  "branchNo": 110,
  "branchIpAddress": "192.168.1.5",
  "branchScalesFolderPath": "TERAZI",
  "scalesType": 1,
  "poskonFolderPath": "POSKON",
  "posGenelFolderPath": "POSGENEL",
  "cashRegisters": [
    {
      "cashNo": 1,
      "cashType": 1
    }
  ]
}
```

Notlar:

- Duplicate `branchNo` `409 Conflict` doner.
- `scalesType` sadece `0` veya `1` olabilir; diger degerler `400 Bad Request` doner.
- `cashRegisters` bos olabilir.
- Kasa satirlarinda duplicate `cashNo` varsa `409 Conflict` doner.

`PUT /api/ayar-islemleri/sube-ayarlari/{branchNo}`

Body `CreateBranchSettingsHttpRequest` ile ayni sube alanlarini alir; `cashRegisters` almaz.

```json
{
  "branchIpAddress": "192.168.1.5",
  "branchScalesFolderPath": "TERAZI",
  "scalesType": 1,
  "poskonFolderPath": "POSKON",
  "posGenelFolderPath": "POSGENEL"
}
```

### Kasa / POS Terminalleri

`GET /api/ayar-islemleri/kasa-pos-terminalleri/secenekler`

Kasa/POS terminal ekleme formundaki kasa tipi ve banka/odeme tipi secimlerinin dropdown kaynagidir. UI terminal bankasini serbest metin gibi yazdirmamali; `terminalBanks[].displayName` gorunen etiket, `terminalBanks[].paymentName` kayit body icindeki `bank` alanidir.

Response:

```json
{
  "cashTypes": [
    {
      "value": 0,
      "code": "standard-pos-cash-register",
      "name": "Standart POS Kasasi",
      "description": "Subenin POSKON/MESAJ dosya islemlerine dahil edilen standart satis kasasi.",
      "isKnown": true
    },
    {
      "value": 1,
      "code": "additional-pos-cash-register",
      "name": "Ek POS Kasasi",
      "description": "Subede standart kasa disinda tanimli ek POS kasasi; POSKON/MESAJ ve kasa hareket islemlerinde kasa no ile takip edilir.",
      "isKnown": true
    }
  ],
  "terminalBanks": [
    {
      "paymentName": "Akbank",
      "paymentTypeNo": 1,
      "accountCode": "POS-AKBANK",
      "displayName": "Akbank - POS-AKBANK"
    }
  ]
}
```

`POST /api/ayar-islemleri/kasa-pos-terminalleri`

Yeni kasa tanimi, Furpa tarafinda kasa kaydi ve Mikro tarafinda terminal kayitlarini olusturur.

Body:

```json
{
  "branchNo": 110,
  "cashNo": 1,
  "cashType": 1,
  "terminals": [
    {
      "terminalNo": "POS001",
      "bank": "Akbank",
      "terminalId": "T123456",
      "merchantNo": "M123456"
    }
  ]
}
```

Response `201 Created`:

```json
{
  "branchNo": 110,
  "cashNo": 1,
  "cashType": 1,
  "cashTypeName": "Ek POS Kasasi",
  "cashTypeDescription": "Subede standart kasa disinda tanimli ek POS kasasi; POSKON/MESAJ ve kasa hareket islemlerinde kasa no ile takip edilir.",
  "terminals": [
    {
      "id": 15,
      "terminalNo": "POS001",
      "cashRegisterNo": "POS001",
      "bank": "Akbank",
      "terminalId": "T123456",
      "merchantNo": "M123456",
      "cashNo": 1
    }
  ]
}
```

Notlar:

- `branchNo + cashNo` duplicate ise `409 Conflict` doner.
- Terminal no daha once Mikro `CashRegisterDetails` veya `CashRegisterBranches` icinde varsa `409 Conflict` doner.
- Silme islemleri mutlaka branch-scoped endpointlerle yapilir.

`GET /api/ayar-islemleri/kasa-pos-terminalleri/kasalar/{cashNo}/terminaller`

Kasa no'ya bagli terminal detaylarini listeler. Backend once Furpa `CashRegisterDetails` kayitlarini okur; Furpa'da ilgili kasa icin kayit yoksa Mikro `CashRegisterDetails` fallback olarak kullanilir.

Ornek:

`GET /api/ayar-islemleri/kasa-pos-terminalleri/kasalar/130/terminaller`

```json
[
  {
    "id": 3503,
    "terminalNo": "PAV210010584",
    "cashRegisterNo": "PAV210010584",
    "bank": "İş Bankası",
    "terminalId": "PAV210010584-3",
    "merchantNo": "PAV210010584-3",
    "cashNo": 130
  },
  {
    "id": 3566,
    "terminalNo": "PAV210010584",
    "cashRegisterNo": "PAV210010584",
    "bank": "TEB",
    "terminalId": "PSB25681",
    "merchantNo": "670522",
    "cashNo": 130
  }
]
```

Bu response'ta `terminalNo` ve `cashRegisterNo` ayni terminal/finans grup numarasidir. UI eski ad icin `terminalNo`, yeni net ad icin `cashRegisterNo` kullanabilir.

`DELETE /api/ayar-islemleri/kasa-pos-terminalleri/subeler/{branchNo}/kasalar/{cashNo}`

Sube kapsaminda kasa kaydini siler. Furpa `CashRegistryDetails` kaydi silinir. Mikro tarafinda ilgili terminal detaylari ve branch mappingleri de temizlenir.

`DELETE /api/ayar-islemleri/kasa-pos-terminalleri/subeler/{branchNo}/terminaller/{terminalNo}`

Tek terminal mapping ve terminal detay kaydini siler.

`GET /api/ayar-islemleri/kasa-pos-terminalleri/mevcut-sube/mesaj-durumlari`

JWT icindeki sube icin POSKON `MESAJ.xxx` dosyalarini okur.

`GET /api/ayar-islemleri/kasa-pos-terminalleri/subeler/{branchNo}/mesaj-durumlari`

Belirli sube icin POSKON `MESAJ.xxx` dosyalarini okur.

Response:

```json
[
  {
    "branchNo": 110,
    "cashNo": 1,
    "cashType": 1,
    "cashTypeName": "Ek POS Kasasi",
    "cashTypeDescription": "Subede standart kasa disinda tanimli ek POS kasasi; POSKON/MESAJ ve kasa hareket islemlerinde kasa no ile takip edilir.",
    "state": 0,
    "stateName": "1071 bulundu",
    "filePath": "\\\\192.168.1.5\\POSKON\\MESAJ.001",
    "error": null
  }
]
```

Durum hesabi:

- Dosyanin ilk satiri `1071` icerirse `state = 0`
- Diger durumlarda `state = 1`
- Dosya yoksa veya yetki/path hatasi varsa satir `state = null`, `error = hata mesaji` ile doner
- `stateName` UI icin metinsel karsiliktir; hata durumunda `null` gelir.

### Kasiyerler

`GET /api/ayar-islemleri/kasiyerler`

Kasiyerleri sifresiz listeler.

Response:

```json
[
  {
    "cashierCode": 1001,
    "cashierName": "ALI VELI",
    "cashierAuthorization": "A",
    "cashierState": true
  }
]
```

`POST /api/ayar-islemleri/kasiyerler`

Body:

```json
{
  "cashierName": "Ali Veli",
  "cashierAuthorization": "A"
}
```

Response `201 Created`:

```json
{
  "cashierCode": 1002,
  "generatedPassword": "482901",
  "cashier": {
    "cashierCode": 1002,
    "cashierName": "ALI VELI",
    "cashierAuthorization": "A",
    "cashierState": true
  }
}
```

Notlar:

- `cashierName` backend tarafinda buyuk harfe cevrilir.
- Yeni sifre 6 haneli numeric uretilir.
- `createUser` ve `updateUser` JWT icindeki `warehouse_no` degerinden set edilir.

`PUT /api/ayar-islemleri/kasiyerler/{cashierCode}`

Kasiyer bilgisini gunceller, sifreyi degistirmez.

Body:

```json
{
  "cashierName": "Ali Veli",
  "cashierAuthorization": "A",
  "cashierState": true
}
```

`POST /api/ayar-islemleri/kasiyerler/{cashierCode}/sifre-sifirla`

Kasiyere yeni 6 haneli numeric sifre uretir. Response `CashierPasswordMutationDto` modelidir.

### Soforler

Bu ekran e-irsaliye gonderirken kullanilan surucu bilgilerini Auth DB tarafinda tanimlamak icindir. UI bu ekrani sadece `ayar-islemleri.soforler.manage` yetkisi varsa menu/route olarak acmalidir. E-irsaliye modalinda otomatik doldurma icin `list` yetkisi yeterlidir.

Veri tablosu:

- Auth DB: `despatch_drivers`

Temel alanlar:

- `firstName`: ad, zorunlu, max 60
- `lastName`: soyad, zorunlu, max 60
- `fullName`: response'ta `firstName + lastName`
- `plateNumber`: plaka, zorunlu, max 20; backend buyuk harfe normalize eder
- `tckn`: 11 haneli sofor TCKN; e-irsaliye formunu otomatik doldurmak icin tam gelir
- `maskedTckn`: liste/table gorunumu icin maskeli TCKN
- `isActive`: pasif kayit e-irsaliye secim listesinde normalde gosterilmez
- `notes`: opsiyonel yonetim notu

`GET /api/ayar-islemleri/soforler?search=ali&includeInactive=false&take=20`

Yetki:

- `ayar-islemleri.soforler.list`

Query:

```text
search           opsiyonel; ad, soyad, plaka veya TCKN icinde arar
includeInactive  opsiyonel; default false
take             opsiyonel; default 100, max 500
```

Response:

```json
[
  {
    "id": "1bc27065-f775-468f-9fc9-0e1ad107d105",
    "firstName": "Ali",
    "lastName": "Veli",
    "fullName": "Ali Veli",
    "plateNumber": "16 ABC 123",
    "tckn": "11111111111",
    "maskedTckn": "111*****111",
    "isActive": true,
    "notes": null,
    "createdAtUtc": "2026-08-03T06:00:00Z",
    "updatedAtUtc": null
  }
]
```

UI notu:

- Liste/table kolonunda `maskedTckn` goster; e-irsaliye formunu doldururken `tckn` kullan.
- Arama kutusu yazildikca debounce ile bu endpoint cagrilabilir.
- E-irsaliye modalinda pasif sofor secilmemeli; bu yuzden `includeInactive=false` kullan.

`GET /api/ayar-islemleri/soforler/{id}`

Yetki:

- `ayar-islemleri.soforler.detail`

Response tek `DespatchDriverDto` doner. Kayit yoksa `404 Not Found`.

`POST /api/ayar-islemleri/soforler`

Yetki:

- `ayar-islemleri.soforler.create`

Request:

```json
{
  "firstName": "Ali",
  "lastName": "Veli",
  "plateNumber": "16 abc 123",
  "tckn": "11111111111",
  "isActive": true,
  "notes": "Ana sevk soforu"
}
```

Response:

- `201 Created`
- Body tek `DespatchDriverDto`

Kurallar:

- `tckn` tam 11 numeric karakter olmalidir; degilse `400 Bad Request`.
- Ayni aktif `plateNumber + tckn` kombinasyonu varsa `409 Conflict`.
- `plateNumber` response'ta buyuk harfli doner.

`PUT /api/ayar-islemleri/soforler/{id}`

Yetki:

- `ayar-islemleri.soforler.update`

Request modeli `POST` ile aynidir. Response tek `DespatchDriverDto` doner. Kayit yoksa `404 Not Found`.

`DELETE /api/ayar-islemleri/soforler/{id}`

Yetki:

- `ayar-islemleri.soforler.delete`

Fiziksel silme yapmaz; kaydi pasife alir. Basarili response `204 No Content`.

E-irsaliye modal entegrasyonu:

1. Modal acilirken veya arama yazildikca `GET /api/ayar-islemleri/soforler?search={text}&take=20` cagrilir.
2. Kullanici sofor secince UI `fullName`, `plateNumber`, `tckn` alanlarini forma basabilir.
3. Gonderimde body'ye sadece `driverId` gonderilebilir; backend aktif sofor kaydindan plaka/ad soyad/TCKN alanlarini doldurur.
4. Kullanici secilen sofor bilgisini formda degistirdiyse `driverId` ile birlikte manuel alanlar da gonderilebilir. Manuel dolu alanlar, secili sofor kaydinin ustune yazilir.
5. Kullanici listeden secmeden eski akisi kullanacaksa `driverId` gondermez; bu durumda `plaque`, `driverNameSurname`, `driverTckn` zorunludur.

### B2B Ayarlari

Bu ekran eski B2B sistemindeki bulten ve B2B kullanici kayitlarini yeni ayar modulu altinda yonetmek icindir.

Veri kaynagi:

- FurpaB2B DB: `Bultens`, `Users`, `UserAccounts`

Guvenlik notu:

- `Users.UserPasswordSalt` ve `Users.UserPasswordHash` API response'unda hic donmez.
- Bu ekrandan B2B kullanici sifresi olusturma veya sifre degistirme yapilmaz.
- Kullanici guncelleme sadece ad-soyad, e-posta, aktiflik, menu metni ve bitis tarihi alanlarini degistirir.

UI onerisi:

- Ekrani iki tab olarak tasarla: `Bultenler` ve `Kullanicilar`.
- Bultenler tabinda baslik/aciklama, link ve olusturma tarihi kolonlari yeterlidir.
- Kullanicilar tabinda ad-soyad, e-posta, aktif/pasif, bitis tarihi, hesap sayisi ve kategori kolonlari yeterlidir.
- Kullanici detayinda `accounts` listesi gosterilebilir; `accountId` ve `category` alanlari B2B cari/hesap baglantisini anlatir.
- Sifre alanlari UI'da hic gosterilmemeli ve body'ye yazilmamalidir.

#### B2B Bulten Liste

`GET /api/ayar-islemleri/b2b-ayarlari/bultenler?search=kampanya&take=100`

Yetki:

- `ayar-islemleri.b2b-ayarlari.list`

Query:

```text
search  opsiyonel; bulten aciklamasi veya link icinde arar
take    opsiyonel; default 100, max 500
```

Response:

```json
[
  {
    "id": 1,
    "definition": "Haftalik B2B bulteni",
    "link": "https://ornek.local/bulten.pdf",
    "createDate": "2026-08-20T09:00:00"
  }
]
```

#### B2B Bulten Olustur / Guncelle

Olustur:

`POST /api/ayar-islemleri/b2b-ayarlari/bultenler`

Guncelle:

`PUT /api/ayar-islemleri/b2b-ayarlari/bultenler/{id}`

Yetki:

- Olusturma: `ayar-islemleri.b2b-ayarlari.create`
- Guncelleme: `ayar-islemleri.b2b-ayarlari.update`

Body:

```json
{
  "definition": "Haftalik B2B bulteni",
  "link": "https://ornek.local/bulten.pdf",
  "createDate": "2026-08-20T09:00:00"
}
```

Not:

- `createDate` bos gonderilirse yeni kayitta backend su anki tarihi yazar.
- Guncellemede `createDate` bos gonderilirse mevcut tarih korunur.

#### B2B Bulten Sil

`DELETE /api/ayar-islemleri/b2b-ayarlari/bultenler/{id}`

Yetki:

- `ayar-islemleri.b2b-ayarlari.delete`

Basarili response:

```text
204 No Content
```

#### B2B Kullanici Liste

`GET /api/ayar-islemleri/b2b-ayarlari/kullanicilar?search=ali&includeInactive=false&take=100`

Yetki:

- `ayar-islemleri.b2b-ayarlari.list`

Query:

```text
search           opsiyonel; ad-soyad, e-posta veya menus alaninda arar
includeInactive  opsiyonel; default false. false ise sadece aktif kullanicilar gelir.
take             opsiyonel; default 100, max 500
```

Response:

```json
[
  {
    "userId": "58ac6266-8c7a-4ff5-a16e-2229ef31a111",
    "userFullName": "Ali Veli",
    "userMail": "ali.veli@example.local",
    "status": true,
    "createDate": "2026-08-20T09:00:00",
    "menus": "Orders,Reports",
    "userEndDate": "2026-12-31T23:59:00",
    "accountCount": 2,
    "categories": ["Bayi", "Market"]
  }
]
```

#### B2B Kullanici Detay

`GET /api/ayar-islemleri/b2b-ayarlari/kullanicilar/{userId}`

Yetki:

- `ayar-islemleri.b2b-ayarlari.detail`

Response:

```json
{
  "userId": "58ac6266-8c7a-4ff5-a16e-2229ef31a111",
  "userFullName": "Ali Veli",
  "userMail": "ali.veli@example.local",
  "status": true,
  "createDate": "2026-08-20T09:00:00",
  "menus": "Orders,Reports",
  "userEndDate": "2026-12-31T23:59:00",
  "accounts": [
    {
      "id": 1,
      "accountId": "aa59c64c-8798-49f9-b4f0-0b640d2eab7d",
      "category": "Bayi"
    }
  ]
}
```

#### B2B Kullanici Guncelle

`PUT /api/ayar-islemleri/b2b-ayarlari/kullanicilar/{userId}`

Yetki:

- `ayar-islemleri.b2b-ayarlari.update`

Body:

```json
{
  "userFullName": "Ali Veli",
  "userMail": "ali.veli@example.local",
  "status": true,
  "menus": "Orders,Reports",
  "userEndDate": "2026-12-31T23:59:00"
}
```

Not:

- `userFullName` max 70 karakterdir.
- `userMail` max 150 karakterdir ve e-posta formatinda olmalidir.
- `menus` bos gonderilebilir; bos gonderilirse DB'de null saklanir.
- Sifre hash/salt, hesap eslestirme ve cari baglantilari bu endpointle degismez.

## Manav / Manav Raporlari

Bu modul eski `Furpa.GreenGrocerWebUI` icindeki manav/yesillik raporlarini yeni API'ye tasir.

Manav siparis/sevk is kurali:

- Canli Mikro gecmisinde `56 MANAV DEPO` kaynakli manav siparisleri `DEPOLAR_ARASI_SIPARISLER` uzerinde talep/kasa niyeti gibi kullanilir; `ssip_miktar` Mikro'da stok ana birimi nedeniyle KG/ADET gorunse de sevk limiti olarak yorumlanmaz.
- Gercek sevk miktari depolar arasi sevkte `STOK_HAREKETLERI.sth_miktar` alanina yazilan KG/ADET degeridir. Bu miktar etiket/terazi barkodu okutularak olusur.
- Manav sevklerinde siparis satiri teslim kapatma akisi kullanilmaz. Canli DB pratiginde `STOK_HAREKETLERI_EK.sth_subesip_uid` linki ve `ssip_teslim_miktar` guncellemesi yoktur.
- `GreenGrocerProductCases:OrderLinkingEnabled=false` ise UI manav sevkinde `warehouseOrderLineGuid` gondermemelidir. Gonderilirse backend `sourceWarehouseNo = 56` ve `STOKLAR.sto_model_kodu in ('10','11','12','23')` olan satirlarda bu GUID'i yok sayar.
- `GreenGrocerProductCases:OrderLinkingEnabled=true` ise UI manav sevkinde gercek siparis satiri GUID'ini `warehouseOrderLineGuid` olarak gonderebilir. Bu durumda sevk satiri siparis satirina baglanir ve kalan/teslim miktari kurallari calisir.
- Manav raporlarinda siparis miktari "sube talebi/kasa niyeti", sevk miktari ise "gercek KG/ADET" olarak ayri okunmalidir.

Yetki:

- `green-grocer.reports.list`: raporlari goruntuleme
- `green-grocer.reports.update`: manav siparisi silme
- `green-grocer.product-case-profiles.manage`: kasa profil yonetim sayfasi/menu/route gorunurlugu
- `green-grocer.product-case-profiles.list`: kasa profil listeleme ve cozumleme onizleme
- `green-grocer.product-case-profiles.detail`: kasa profil detayi
- `green-grocer.product-case-profiles.create`: kasa profil olusturma
- `green-grocer.product-case-profiles.update`: kasa profil kaydetme
- `green-grocer.product-case-profiles.delete`: kasa profil pasife alma
- `green-grocer.product-case-profiles.all-warehouses`: tum depo/sube kapsaminda profil ve cozumleme goruntuleme
- `green-grocer.operations.page`: manav operasyon paneli menu/route gorunurlugu
- `green-grocer.operations.list`: manav operasyon ozetini ve MNV duzeltme onizlemesini goruntuleme
- `green-grocer.operations.create`: kontrollu MNV tartim farki/stok duzeltmesi yazma
- `green-grocer.operations.all-warehouses`: paneli veya duzeltme yazimini farkli depo kapsaminda kullanma

UI notu: `product-case-profiles` ekrani sol menude ve route guard'da sadece `manage` ile acilmalidir. `list/detail/create/update/delete` yetkileri endpoint ve buton aksiyonlari icindir; `all-warehouses` tum depo/sube kapsamidir. Sube kullanicisinda cozumleme/liste yetkisi bulunabilir ama bu durum profil yonetim ekranini acmamalidir.

`operations` ekrani sol menude ve route guard'da `green-grocer.operations.page` ile acilmalidir. Panel verisi ve MNV onizleme icin `list`, yazma/kaydet butonu icin `create`, depo secici icin `all-warehouses` kullanilir.

Tarih query alani:

- `date` onerilir.
- Geriye uyum icin `dateToGet` de kabul edilir.
- Ikisi de verilmezse backend bugunu kullanir.

Ortak query:

```text
date                 opsiyonel; rapor tarihi, verilmezse bugun
dateToGet            opsiyonel; date icin geriye uyum alias'i
warehouseNo          opsiyonel; `green-grocer.reports.all-warehouses` yoksa backend JWT deposunu uygular, yetki varsa bos birakilirsa tum subeler
typeCode             opsiyonel; 10/meyve, 11/sebze, 12/yesillik, 23/sarf/manav-sarf/ambalaj veya all/tum/tumu
search               opsiyonel; urun kodu, urun adi, sube adi veya evrak serisinde arar
includeLazyBranches  opsiyonel; default true, siparis girmeyen subeleri de dondurur
take                 opsiyonel; default 1000, max 5000
```

### Manav Kasa Profil ve Cozumleme

Bu bolum subelerin manav siparisinde kasa/koli girip Mikro tarafinda KG/ADET olarak anlamli miktar olusmasi icin tasarlanan yeni kural katmanidir.

Kaynaklar:

- Profil ve siparis snapshot kayitlari uygulama DB'sinde tutulur.
- Stok karti bilgisi Mikro `STOKLAR` tablosundan okunur.
- Kasa kg ortalamasi Furpa `Manav_Depo_Mal_Kabul_Etiket` tablosundaki gercek etiket/tartim gecmisinden hesaplanir.
- Mikro ve Furpa tablolarina yeni kural tablosu acilmaz.

Yeni tablolar:

- `green_grocer_product_case_profiles`: stok bazli kasa/koli/manuel cevrim kuralidir.
- `green_grocer_order_line_snapshots`: siparis aninda kullanilan kasa/koli girisi, ortalama/katsayi, Mikro'ya yazilan tahmini KG/ADET ve Mikro siparis satir GUID'i bilgisini sabitler.

Feature flag:

```json
{
  "GreenGrocerProductCases": {
    "Enabled": true,
    "OrderLinkingEnabled": false
  }
}
```

- Varsayilan `Enabled=true`; yeni kasa profil/cozumleme endpointleri aktif gelir.
- Ortam degiskeni ile kapatma: `GreenGrocerProductCases__Enabled=false`
- `Enabled=false` ise bu bolumdeki endpointler `409 Conflict` doner ve detay mesajinda ozelligin konfigurasyonla kapali oldugu belirtilir.
- UI kapali durumda `resolution-preview` cagirmamali, profil ekranini gizlemeli ve eski manav siparis/sevk akisini kullanmaya devam etmelidir.
- Varsayilan `OrderLinkingEnabled=false`; manav sevkte siparis GUID'i gelse bile eski davranis korunur ve GUID temizlenir.
- Siparise bagli manav sevk istenirse `GreenGrocerProductCases__OrderLinkingEnabled=true` yapilir. Bu ayar ancak `Enabled=true` iken anlamlidir.
- `OrderLinkingEnabled=true` iken `resolution-preview` response'undaki `isOrderLinkable=true` ise UI ilgili siparis satirinin `lineGuid` degerini sevk request satirinda `warehouseOrderLineGuid` olarak gonderebilir.
- Bu ayar otomatik depo siparisi uretmez; yalnizca UI'nin gonderdigi gercek siparis satiri GUID'inin korunup sevke baglanmasini saglar.
- `OrderLinkingEnabled=false` iken UI manav sevkinde siparis secme/kalan siparis kapatma akisiyle ugrasmamalidir; sadece barkod/etiket okutulan gercek KG/ADET miktariyla siparissiz sevk yapmalidir.
- `OrderLinkingEnabled=true` iken manav depo gelen siparis detayi `items[].greenGrocerCase` dolu gelen satirlari "kasa talebi + tahmini KG/ADET" olarak gosterir ve UI sevkte bu satirin `lineGuid` degerini tasiyabilir.

Cozumleme siniflari:

```text
InputMode:
- Case      kasa girisi
- Pack      koli/paket girisi
- Piece     direkt adet girisi
- KgDirect  direkt kg girisi
- Sarf      kasa/ambalaj/sarf malzemesi

ConversionMode:
- LabelAverageKgPerCase  Furpa etiket gecmisinden kg/kasa ortalamasi
- ManualKgPerCase        profil uzerindeki manuel kg/kasa
- FixedUnitsPerCase      Mikro birim2 katsayisi veya manuel adet/koli katsayisi
- DirectQuantity         girilen miktari direkt Mikro ana birimine yaz
- ManualOnly             otomatik hesaplama yok, manuel karar gerekli
- Blocked                bu urun manav kasa siparisinde engelli

Confidence:
- High
- Medium
- Low
- Blocked
```

Profil listeleme:

`GET /api/green-grocer/product-case-profiles?search=KARPUZ&includeInactive=false&take=100`

Query:

- `search`: opsiyonel, stok kodu, stok adi, model adi veya not icinde arar
- `includeInactive`: opsiyonel, default `false`
- `take`: opsiyonel, default `100`, max `500`

Response:

```json
[
  {
    "id": "ed2486c3-bd7f-4f4c-84f0-7c099cb9a6d1",
    "stockCode": "000488",
    "stockName": "MNV KARPUZ KG",
    "modelCode": "10",
    "modelName": "Meyve",
    "unit1": "KG",
    "unit2": "",
    "unit2Factor": 0,
    "isActive": true,
    "inputMode": "Case",
    "conversionMode": "ManualKgPerCase",
    "manualKgPerCase": 12.5,
    "manualUnitsPerCase": null,
    "minExpectedKgPerCase": 8,
    "maxExpectedKgPerCase": 25,
    "averageWindowDays": 30,
    "minAverageRecordCount": 5,
    "minAverageCaseCount": 20,
    "maxCoefficientOfVariation": 0.25,
    "requiresManualApproval": true,
    "allowOrderLinking": true,
    "overDeliveryTolerancePercent": 20,
    "notes": "Karpuz manuel kasa ortalamasi ile yonetilir.",
    "createdAtUtc": "2026-07-31T06:17:50Z",
    "updatedAtUtc": null
  }
]
```

Profil detayi:

`GET /api/green-grocer/product-case-profiles/{stockCode}`

Ornek:

`GET /api/green-grocer/product-case-profiles/000488`

Response tek `GreenGrocerProductCaseProfileDto` modelidir. Profil yoksa `404` doner.

Profil kaydetme:

`PUT /api/green-grocer/product-case-profiles/{stockCode}`

Body:

```json
{
  "isActive": true,
  "inputMode": "Case",
  "conversionMode": "ManualKgPerCase",
  "manualKgPerCase": 12.5,
  "manualUnitsPerCase": null,
  "minExpectedKgPerCase": 8,
  "maxExpectedKgPerCase": 25,
  "averageWindowDays": 30,
  "minAverageRecordCount": 5,
  "minAverageCaseCount": 20,
  "maxCoefficientOfVariation": 0.25,
  "requiresManualApproval": true,
  "allowOrderLinking": true,
  "overDeliveryTolerancePercent": 20,
  "notes": "Karpuz manuel kg/kasa ile hesaplanacak."
}
```

Kaydetme kurallari:

- `stockCode` Mikro `STOKLAR` icinde bulunmalidir.
- Sadece `sto_model_kodu` `10`, `11`, `12`, `23` olan urunlere profil kaydedilir.
- `ManualKgPerCase` modunda `manualKgPerCase > 0` zorunludur.
- `FixedUnitsPerCase` modunda `manualUnitsPerCase` verilmezse backend Mikro `sto_birim2_katsayi` degerini kullanabilir.
- `DELETE` fiziksel silmez; profili pasife alir.

Profil pasife alma:

`DELETE /api/green-grocer/product-case-profiles/{stockCode}`

Basarili response:

```text
204 No Content
```

Cozumleme onizleme:

`POST /api/green-grocer/product-case-profiles/resolution-preview`

Alias:

`POST /api/green-grocer/product-case-profiles/cozumleme-onizleme`

Body:

```json
{
  "stockCode": "001082",
  "inputQuantity": 3,
  "sourceWarehouseNo": 56,
  "targetWarehouseNo": 110,
  "orderDate": "2026-07-31T00:00:00"
}
```

Response:

Not: `isOrderLinkable` alani profilin `allowOrderLinking` degeri ile global
`GreenGrocerProductCases:OrderLinkingEnabled` ayarinin birlikte sonucudur. Global
ayar kapaliysa profil izin verse bile response `isOrderLinkable=false` doner.
Asagidaki ornekte `OrderLinkingEnabled=true` varsayilmistir.

```json
{
  "stockCode": "001082",
  "stockName": "MNV SEFTALI KG",
  "modelCode": "10",
  "modelName": "Meyve",
  "unit1": "KG",
  "unit2": "",
  "unit2Factor": 0,
  "inputQuantity": 3,
  "inputMode": "Case",
  "conversionMode": "LabelAverageKgPerCase",
  "microUnit": "KG",
  "estimatedQuantity": 11.25,
  "averageKgPerCase": 3.75,
  "unitsPerCase": null,
  "averageSource": "LabelHistory",
  "averageRecordCount": 47,
  "averageCaseCount": 7526,
  "coefficientOfVariation": 0.08,
  "latestLabelDate": "2026-07-30T00:00:00",
  "confidence": "High",
  "requiresManualApproval": false,
  "isOrderLinkable": true,
  "isUsable": true,
  "warnings": [],
  "errors": []
}
```

ADET/koli ornegi:

```json
{
  "stockCode": "016167",
  "inputQuantity": 3,
  "sourceWarehouseNo": 56
}
```

Response mantigi:

```json
{
  "stockCode": "016167",
  "stockName": "MNV MAYDANOZ ADET",
  "inputMode": "Pack",
  "conversionMode": "FixedUnitsPerCase",
  "microUnit": "ADET",
  "estimatedQuantity": 75,
  "unitsPerCase": 25,
  "averageSource": "StockUnitFactor",
  "confidence": "High",
  "isUsable": true,
  "warnings": [],
  "errors": []
}
```

Ortalama yoksa response hata listeleyerek doner:

```json
{
  "stockCode": "023740",
  "stockName": "MNV KIRKAGAC KAVUN KG",
  "inputMode": "Case",
  "conversionMode": "ManualOnly",
  "microUnit": "KG",
  "estimatedQuantity": 0,
  "averageSource": "None",
  "confidence": "Blocked",
  "requiresManualApproval": true,
  "isOrderLinkable": false,
  "isUsable": false,
  "warnings": [],
  "errors": [
    "Urun icin guncel kasa kg ortalamasi yok; manuel profil tanimlanmali."
  ]
}
```

UI onerisi:

- Siparis ekraninda kullanici yine kasa/koli girer.
- Barkod/stok secildikten sonra `resolution-preview` cagrilir.
- `isUsable=false` ise satir ekletilmez; `errors.first` kullaniciya gosterilir.
- `confidence=Medium` ise satir eklenebilir ama uyari gosterilir.
- `estimatedQuantity` Mikro siparis satirina yazilacak KG/ADET miktaridir.
- `inputQuantity`, `inputMode`, `averageKgPerCase` veya `unitsPerCase` UI'da "3 kasa ~= 11.25 KG" gibi gosterilir.
- Depo siparisi kaydederken `outWarehouseNo=56` ve `resolution-preview` kullanildiysa satirda `quantity = estimatedQuantity` gonderilmeli, response'taki cozumleme bilgileri de `greenGrocerCase` nesnesine aynen tasinmalidir. Backend bu bilgiyi `green_grocer_order_line_snapshots` tablosuna satir GUID'iyle yazar.
- `isOrderLinkable=true` ve `GreenGrocerProductCases:OrderLinkingEnabled=true` ise sevk ekraninda ilgili siparis satiri GUID'i `warehouseOrderLineGuid` olarak gonderilebilir.

### Manav Operasyon Paneli

Bu panel `56 MANAV DEPO` icin alis, ic tartim farki, sube kasa talepleri, gercek sevk, son sayim ve guncel stok bilgisini tek urun satirinda toplar. Amac kullanicinin "halden fatura ile gelen miktar ne, Furpa ic tartim farki ne, subeler kac kasa istemis, Mikro'ya tahmini kac KG/ADET yazilmis, gercek sevk kac KG/ADET olmus, son sayim ne diyor?" sorularini tek ekrandan cevaplamaktir.

Panel okuma agirliklidir. Yazma sadece yetkili kullanicinin onizleme sonrasi kontrollu MNV tartim farki/stok duzeltmesi olusturmasi icindir. Bu endpoint fatura, siparis, sevk veya sayim evragi olusturmaz; sadece Mikro `STOK_HAREKETLERI` uzerinde `sth_cins=10` olan ic hareket/duzeltme satiri yazar.

Root:

```text
/api/green-grocer/operations
```

Yetki:

- `green-grocer.operations.page`: menu/route
- `green-grocer.operations.list`: overview ve duzeltme onizleme
- `green-grocer.operations.create`: duzeltme yazma
- `green-grocer.operations.all-warehouses`: varsayilan 56 disinda depo secme/yazma

#### `GET /api/green-grocer/operations/overview`

Alias:

```text
GET /api/green-grocer/operations/ozet
```

Query:

```text
startDate          opsiyonel; verilmezse endDate - 7 gun
endDate            opsiyonel; verilmezse bugun
warehouseNo        opsiyonel; default 56, all-warehouses yoksa JWT deposu uygulanir
typeCode           opsiyonel; 10/meyve, 11/sebze, 12/yesillik, 23/sarf/manav-sarf/ambalaj veya all/tum/tumu
search             opsiyonel; stok kodu veya stok adinda arar
onlyWithActivity   opsiyonel; default true, aktivitesi olmayan urunleri gizler
take               opsiyonel; default 500, max 2000
```

Kaynak eslesmesi:

- `currentStockQuantity`: `dbo.fn_DepodakiMiktar(stokKodu, warehouseNo, endDate)`
- `purchaseQuantity`, `purchaseAmount`, `purchaseUnitPrice`: `STOK_HAREKETLERI` alis/fatura hareketleri; `sth_giris_depo_no=warehouseNo`, `sth_tip=0`, `sth_evraktip=3`, `sth_cins=16`
- `adjustmentInQuantity`, `adjustmentOutQuantity`, `adjustmentNetQuantity`: MNV/MERC ic tartim farki hareketleri; `sth_cins=10`, seri `MNV%` veya `MERC`
- `orderInputQuantity`: Auth DB `green_grocer_order_line_snapshots.input_quantity`; kullanicinin girdigi kasa/koli miktari
- `orderEstimatedQuantity`: snapshot uzerindeki tahmini KG/ADET
- `orderMicroQuantity`: Mikro `DEPOLAR_ARASI_SIPARISLER.ssip_miktar`; manav icin kaynak depo `ssip_cikdepo=warehouseNo`
- `shipmentQuantity`: `STOK_HAREKETLERI` gercek sevk miktari; `sth_cikis_depo_no=warehouseNo`, `sth_tip=2`, `sth_evraktip=17`, `sth_cins=6`
- `lastCountQuantity`: `SAYIM_SONUCLARI` icindeki stok bazli son sayim

Response:

```json
{
  "warehouseNo": 56,
  "warehouseName": "MANAV DEPO",
  "startDate": "2026-08-01T00:00:00",
  "endDate": "2026-08-04T00:00:00",
  "productCount": 1,
  "totalCurrentStockQuantity": 184.35,
  "totalPurchaseQuantity": 300,
  "totalPurchaseAmount": 9000,
  "totalAdjustmentInQuantity": 12.4,
  "totalAdjustmentOutQuantity": 3.1,
  "totalAdjustmentNetQuantity": 9.3,
  "totalOrderInputQuantity": 18,
  "totalOrderEstimatedQuantity": 225,
  "totalShipmentQuantity": 210.75,
  "totalLatestCountQuantity": 180,
  "statusSummaries": [
    {
      "statusCode": "balanced",
      "statusName": "Dengeli",
      "productCount": 1,
      "currentStockQuantity": 184.35,
      "purchaseQuantity": 300,
      "adjustmentNetQuantity": 9.3,
      "orderEstimatedQuantity": 225,
      "shipmentQuantity": 210.75
    }
  ],
  "items": [
    {
      "stockCode": "001082",
      "stockName": "MNV SEFTALI KG",
      "modelCode": "10",
      "modelName": "Meyve",
      "unitName": "KG",
      "currentStockQuantity": 184.35,
      "purchaseQuantity": 300,
      "purchaseAmount": 9000,
      "purchaseUnitPrice": 30,
      "purchaseDocumentCount": 2,
      "lastPurchaseDate": "2026-08-04T00:00:00",
      "lastPurchaseDocument": "FTR-123",
      "lastSupplierCode": "320.01.001",
      "lastSupplierName": "HAL TEDARIKCI",
      "adjustmentInQuantity": 12.4,
      "adjustmentOutQuantity": 3.1,
      "adjustmentNetQuantity": 9.3,
      "adjustmentDocumentCount": 2,
      "lastAdjustmentDate": "2026-08-04T00:00:00",
      "lastAdjustmentDocument": "MNVE-45",
      "lastAdjustmentSeries": "MNVE",
      "lastAdjustmentReason": "weighing-difference",
      "orderInputQuantity": 18,
      "orderEstimatedQuantity": 225,
      "orderMicroQuantity": 225,
      "orderLineCount": 8,
      "orderBranchCount": 5,
      "shipmentQuantity": 210.75,
      "shipmentDocumentCount": 3,
      "shipmentBranchCount": 3,
      "lastShipmentDate": "2026-08-04T00:00:00",
      "lastShipmentDocument": "S-456",
      "lastCountDate": "2026-08-03T00:00:00",
      "lastCountDocumentNo": 812,
      "lastCountQuantity": 180,
      "systemQuantityAtCountDate": 176.2,
      "countDifferenceAtCountDate": 3.8,
      "primaryStatusCode": "balanced",
      "primaryStatusName": "Dengeli",
      "flags": []
    }
  ]
}
```

#### `POST /api/green-grocer/operations/adjustments/preview`

Alias:

```text
POST /api/green-grocer/operations/duzeltmeler/onizleme
```

Body:

```json
{
  "warehouseNo": 56,
  "direction": "increase",
  "movementDate": "2026-08-04T00:00:00",
  "documentSerie": "MNVE",
  "reasonCode": "weighing-difference",
  "lines": [
    {
      "stockCode": "001082",
      "quantity": 12.4,
      "unitPointer": 1,
      "unitPrice": 0,
      "description": "Hal faturasi ic tartim farki"
    }
  ]
}
```

Response:

```json
{
  "warehouseNo": 56,
  "counterWarehouseNo": 1,
  "direction": "increase",
  "directionName": "Stok Artis",
  "documentSerie": "MNVE",
  "movementType": 0,
  "movementGenre": 10,
  "documentType": 12,
  "reasonCode": "weighing-difference",
  "reasonName": "Ic Tartim Farki",
  "lineCount": 1,
  "totalQuantity": 12.4,
  "totalAmount": 0
}
```

#### `POST /api/green-grocer/operations/adjustments`

Alias:

```text
POST /api/green-grocer/operations/duzeltmeler
```

Body:

```json
{
  "clientRequestId": "7af26109-960a-46e5-9b3c-9d9c6b6ff6a5",
  "warehouseNo": 56,
  "direction": "decrease",
  "movementDate": "2026-08-04T00:00:00",
  "documentDate": "2026-08-04T00:00:00",
  "documentNo": "IC-TARTIM-20260804",
  "documentSerie": "MNVF",
  "counterWarehouseNo": 1,
  "reasonCode": "weighing-difference",
  "description": "Fatura kg ile ic tartim farki",
  "creator": "MANAV",
  "acceptor": "MERKEZ",
  "lines": [
    {
      "stockCode": "001082",
      "quantity": 3.1,
      "unitPointer": 1,
      "unitPrice": 0,
      "description": "Eksik tartim"
    }
  ]
}
```

Response:

```json
{
  "clientRequestId": "7af26109-960a-46e5-9b3c-9d9c6b6ff6a5",
  "status": "created",
  "warehouseNo": 56,
  "counterWarehouseNo": 1,
  "direction": "decrease",
  "documentSerie": "MNVF",
  "documentOrderNo": 46,
  "movementDate": "2026-08-04T00:00:00",
  "documentDate": "2026-08-04T00:00:00",
  "documentNo": "IC-TARTIM-20260804",
  "reasonCode": "weighing-difference",
  "reasonName": "Ic Tartim Farki",
  "lineCount": 1,
  "totalQuantity": 3.1,
  "totalAmount": 0,
  "connectionStringName": "MikroWriteConnection",
  "movementGuids": [
    "49f26b26-9f37-4d64-98e7-1e2f7a5e2d41"
  ]
}
```

Yazma kurallari:

- UI kaydetmeden once mutlaka `adjustments/preview` cagirip kullaniciya hareket tipini, seriyi ve toplam miktari gostermelidir.
- `clientRequestId` UI kaydetme denemesi basinda uretilir ve timeout/retry durumunda degistirilmez. Yeni GUID uretilirse ayni MNV evragi tekrar yazilabilir.
- `direction=increase` stok artisi yazar; default seri `MNVE`, Mikro sablonu `sth_evraktip=12`, `sth_tip=0`, `sth_cins=10`.
- `direction=decrease` stok azalisi yazar; default seri `MNVF`, Mikro sablonu `sth_evraktip=0`, `sth_tip=1`, `sth_cins=10`.
- `MNVE`, `MNVG`, `MNVI` sadece artis icin; `MNVF` sadece azalis icin kullanilir.
- Sadece `sto_model_kodu` `10`, `11`, `12`, `23` olan manav/yesillik/sarf urunleri yazilabilir.
- Endpoint `MikroWriteConnection` ile yazar ve her satirin aciklamasina trace anahtari ekler. Timeout sonrasi ayni `clientRequestId` ile tekrar denenirse backend onceki kaydi bulup ayni cevabi toparlamaya calisir.
- Bu endpoint Mikro alis faturasi, depo siparisi, depolar arasi sevk veya sayim sonucu olusturmaz. O evraklar kendi ekranlarindan yonetilmeye devam eder.

UI onerisi:

- Panel ilk acilista `overview` ile son 7 gunu getirir.
- Satirda kullaniciya `alis`, `MNV net fark`, `sube kasa talebi`, `tahmini KG/ADET`, `gercek sevk`, `son sayim`, `guncel stok` kolonlari birlikte gosterilir.
- `green-grocer.operations.create` yoksa MNV duzeltme butonu hic gosterilmez.
- Yazma ekraninda kullanici `increase/decrease`, stok, miktar, aciklama ve gerekirse seri secer; once onizleme, sonra kaydetme yapilir.
- Kaydet butonu pending iken kilitlenir. Timeout olursa UI ayni `clientRequestId` ile tekrar dener ve basarili response geldikten sonra paneli yeniler.

Tip secenekleri:

`GET /api/green-grocer/reports/type-options`

Alias:

`GET /api/green-grocer/reports/tip-secenekleri`

Response:

```json
[
  {
    "typeCode": "10",
    "typeName": "Meyve",
    "isGreens": false
  },
  {
    "typeCode": "11",
    "typeName": "Sebze",
    "isGreens": false
  },
  {
    "typeCode": "12",
    "typeName": "Yesillik",
    "isGreens": true
  },
  {
    "typeCode": "23",
    "typeName": "Manav Sarf",
    "isGreens": false
  }
]
```

Rapor response ortak alanlari:

- Urun iceren tum rapor satirlarinda eski uyumluluk icin `productCode` ve `productName` korunur.
- `stockCode`, Mikro `STOKLAR.sto_kod` alanidir. UI'da net urun kodu kolonu icin bunu kullan.
- `stockName`, Mikro `STOKLAR.sto_isim` alanidir. UI'da tam stok adi gerekiyorsa bunu kullan.
- `productName`, kullaniciya okunakli gostermek icin kisa ad varsa `STOKLAR.sto_kisa_ismi`, yoksa `STOKLAR.sto_isim` fallback'idir.
- `product.shortName`, `STOKLAR.sto_kisa_ismi`; `product.displayName`, UI liste adi; `product.unitName`, `STOKLAR.sto_birim1_ad`.
- `product.primaryBarcode`, `BARKOD_TANIMLARI` icinden aktif/master oncelikli ilk barkoddur.
- `branch` nesnesi depo/sube bilgisinin net halidir. Eski `branchNo`, `branchName` alanlari geriye uyumluluk icin durur.
- `document` nesnesi evrak seri/sira ve ekranda gostermeye hazir `documentNo` bilgisini tasir.

Ortak product modeli:

```json
{
  "stockCode": "016201",
  "productCode": "016201",
  "stockName": "MNV ELMA STARKING KG",
  "shortName": "ELMA",
  "displayName": "ELMA",
  "productName": "ELMA",
  "modelCode": "10",
  "modelName": "Meyve",
  "unitName": "KG",
  "globalProductCode": "8690000000000",
  "primaryBarcode": "2801620100000"
}
```

### Dashboard / Ozet

`GET /api/green-grocer/reports/dashboard?date=2026-06-04`

Alias:

`GET /api/green-grocer/reports/ozet?date=2026-06-04`

Amac:

- Tek cagrida ust KPI, tip ozetleri, sube ozetleri, en yuksek miktarli urunler ve siparis girmeyen subeleri dondurur.
- Ekran acilisinda ilk cagrilacak endpoint olarak onerilir.

Response:

```json
{
  "reportDate": "2026-06-04T00:00:00",
  "warehouseNo": null,
  "branchCount": 18,
  "lazyBranchCount": 2,
  "documentCount": 18,
  "productCount": 42,
  "totalQuantity": 1250.75,
  "caseInfo": {
    "inputQuantity": 312,
    "inputMode": "Case",
    "estimatedQuantity": 1250.75,
    "microUnit": "KG",
    "averageKgPerCase": 4.01,
    "unitsPerCase": null,
    "averageSource": "Mixed",
    "confidence": "Mixed",
    "averageRecordCount": 470,
    "averageCaseCount": 75260,
    "coefficientOfVariation": 0.1
  },
  "typeSummaries": [
    {
      "typeCode": "12",
      "typeName": "Yesillik",
      "branchCount": 12,
      "documentCount": 12,
      "productCount": 8,
      "totalQuantity": 210.5,
      "caseInfo": {
        "inputQuantity": 84,
        "inputMode": "Pack",
        "estimatedQuantity": 210.5,
        "microUnit": "ADET",
        "averageKgPerCase": null,
        "unitsPerCase": 25,
        "averageSource": "StockUnitFactor",
        "confidence": "High",
        "averageRecordCount": null,
        "averageCaseCount": null,
        "coefficientOfVariation": null
      }
    }
  ],
  "branches": [
    {
      "branchNo": 110,
      "branchName": "KESTEL 1",
      "branch": {
        "warehouseNo": 110,
        "warehouseName": "KESTEL 1",
        "regionCode": "1"
      },
      "documentCount": 1,
      "productCount": 8,
      "totalQuantity": 84.25,
      "caseInfo": null
    }
  ],
  "topProducts": [
    {
      "typeCode": "10",
      "typeName": "Meyve",
      "productCode": "016201",
      "productName": "ELMA",
      "stockCode": "016201",
      "stockName": "MNV ELMA STARKING KG",
      "unitName": "KG",
      "primaryBarcode": "2801620100000",
      "globalProductCode": "8690000000000",
      "product": {
        "stockCode": "016201",
        "productCode": "016201",
        "stockName": "MNV ELMA STARKING KG",
        "shortName": "ELMA",
        "displayName": "ELMA",
        "productName": "ELMA",
        "modelCode": "10",
        "modelName": "Meyve",
        "unitName": "KG",
        "globalProductCode": "8690000000000",
        "primaryBarcode": "2801620100000"
      },
      "quantity": 42.5,
      "caseInfo": null
    }
  ],
  "lazyBranches": [
    {
      "branchNo": 120,
      "branchName": "ORNEK SUBE",
      "branch": {
        "warehouseNo": 120,
        "warehouseName": "ORNEK SUBE",
        "regionCode": "1"
      },
      "regionCode": "1"
    }
  ]
}
```

### Genel Manav Raporu

`GET /api/green-grocer/reports/summary?date=2026-06-04&typeCode=12&search=MARUL`

Alias:

`GET /api/green-grocer/reports?date=2026-06-04`

Amac:

- `DEPOLAR_ARASI_SIPARISLER` kayitlarini `STOKLAR.sto_model_kodu in ('10','11','12','23')` filtresiyle urun/tip bazinda toplar.

Response item:

```json
{
  "typeCode": "10",
  "typeName": "Meyve",
  "productCode": "016201",
  "productName": "ELMA",
  "stockCode": "016201",
  "stockName": "MNV ELMA STARKING KG",
  "unitName": "KG",
  "primaryBarcode": "2801620100000",
  "globalProductCode": "8690000000000",
  "product": {
    "stockCode": "016201",
    "productCode": "016201",
    "stockName": "MNV ELMA STARKING KG",
    "shortName": "ELMA",
    "displayName": "ELMA",
    "productName": "ELMA",
    "modelCode": "10",
    "modelName": "Meyve",
    "unitName": "KG",
    "globalProductCode": "8690000000000",
    "primaryBarcode": "2801620100000"
  },
  "quantity": 42.5,
  "caseInfo": {
    "inputQuantity": 10,
    "inputMode": "Case",
    "estimatedQuantity": 42.5,
    "microUnit": "KG",
    "averageKgPerCase": 4.25,
    "unitsPerCase": null,
    "averageSource": "LabelHistory",
    "confidence": "High",
    "averageRecordCount": 47,
    "averageCaseCount": 7526,
    "coefficientOfVariation": 0.08
  }
}
```

### Sube/Evrak Bazli Manav Raporu

`GET /api/green-grocer/reports/by-branch?date=2026-06-04&warehouseNo=110`

Alias:

`GET /api/green-grocer/reports/sube?date=2026-06-04&warehouseNo=110`

Response:

```json
{
  "items": [
    {
      "orderDate": "2026-06-04T00:00:00",
      "branchNo": 110,
      "branchName": "KESTEL 1",
      "branch": {
        "warehouseNo": 110,
        "warehouseName": "KESTEL 1",
        "regionCode": "1"
      },
      "documentSerie": "F110",
      "documentOrderNo": 1234,
      "document": {
        "documentSerie": "F110",
        "documentOrderNo": 1234,
        "documentNo": "F110/1234"
      },
      "typeCode": "10",
      "typeName": "Meyve",
      "productCode": "016201",
      "productName": "ELMA",
      "stockCode": "016201",
      "stockName": "MNV ELMA STARKING KG",
      "unitName": "KG",
      "primaryBarcode": "2801620100000",
      "globalProductCode": "8690000000000",
      "product": {
        "stockCode": "016201",
        "productCode": "016201",
        "stockName": "MNV ELMA STARKING KG",
        "shortName": "ELMA",
        "displayName": "ELMA",
        "productName": "ELMA",
        "modelCode": "10",
        "modelName": "Meyve",
        "unitName": "KG",
        "globalProductCode": "8690000000000",
        "primaryBarcode": "2801620100000"
      },
      "quantity": 12,
      "latestCreateDate": "2026-06-04T09:15:10",
      "canDelete": true,
      "caseInfo": {
        "inputQuantity": 3,
        "inputMode": "Case",
        "estimatedQuantity": 12,
        "microUnit": "KG",
        "averageKgPerCase": 4,
        "unitsPerCase": null,
        "averageSource": "LabelHistory",
        "confidence": "High",
        "averageRecordCount": 47,
        "averageCaseCount": 7526,
        "coefficientOfVariation": 0.08
      }
    }
  ],
  "lazyBranches": [
    {
      "branchNo": 120,
      "branchName": "ORNEK SUBE",
      "branch": {
        "warehouseNo": 120,
        "warehouseName": "ORNEK SUBE",
        "regionCode": "1"
      },
      "regionCode": "1"
    }
  ]
}
```

### Urun Bazli Manav Raporu

`GET /api/green-grocer/reports/by-product?date=2026-06-04`

Alias:

`GET /api/green-grocer/reports/urun?date=2026-06-04`

Amac:

- Urunleri toplam miktar ve sube/evrak kirilimiyle dondurur.
- `branches` kiriliminda `latestCreateDate` ve `canDelete` alanlari bulunur; UI sil butonunu `canDelete=true` ve kullanicida `green-grocer.reports.update` yetkisi varsa gostermelidir.
- `caseInfo` doluysa rapor satiri siparis anindaki kasa/koli snapshot'ini de icerir. `quantity` ve `caseInfo.estimatedQuantity` Mikro'ya yazilan KG/ADET toplamidir; `caseInfo.inputQuantity` subenin girdigi kasa/koli toplamidir.

Response item:

```json
{
  "typeCode": "10",
  "typeName": "Meyve",
  "productCode": "016201",
  "productName": "ELMA",
  "stockCode": "016201",
  "stockName": "MNV ELMA STARKING KG",
  "unitName": "KG",
  "primaryBarcode": "2801620100000",
  "globalProductCode": "8690000000000",
  "product": {
    "stockCode": "016201",
    "productCode": "016201",
    "stockName": "MNV ELMA STARKING KG",
    "shortName": "ELMA",
    "displayName": "ELMA",
    "productName": "ELMA",
    "modelCode": "10",
    "modelName": "Meyve",
    "unitName": "KG",
    "globalProductCode": "8690000000000",
    "primaryBarcode": "2801620100000"
  },
  "totalQuantity": 42.5,
  "caseInfo": null,
  "branches": [
    {
      "branchNo": 110,
      "branchName": "KESTEL 1",
      "branch": {
        "warehouseNo": 110,
        "warehouseName": "KESTEL 1",
        "regionCode": "1"
      },
      "documentSerie": "F110",
      "documentOrderNo": 1234,
      "document": {
        "documentSerie": "F110",
        "documentOrderNo": 1234,
        "documentNo": "F110/1234"
      },
      "quantity": 12,
      "latestCreateDate": "2026-06-04T09:15:10",
      "canDelete": true,
      "caseInfo": null
    }
  ]
}
```

### Yesillik Raporu

`GET /api/green-grocer/reports/greens?date=2026-06-04`

Alias:

`GET /api/green-grocer/reports/yesillik?date=2026-06-04`

Amac:

- Yalnizca `STOKLAR.sto_model_kodu = '12'` olan satirlari sube ve evrak bilgisiyle listeler.
- `typeCode` query verilse bile bu endpoint yesillik tipine sabitlenir.

Response item:

```json
{
  "orderDate": "2026-06-04T00:00:00",
  "branchNo": 110,
  "branchName": "KESTEL 1",
  "branch": {
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "regionCode": "1"
  },
  "documentSerie": "F110",
  "documentOrderNo": 1234,
  "document": {
    "documentSerie": "F110",
    "documentOrderNo": 1234,
    "documentNo": "F110/1234"
  },
  "rowNo": 0,
  "typeCode": "12",
  "typeName": "Yesillik",
  "productCode": "018501",
  "productName": "MARUL",
  "stockCode": "018501",
  "stockName": "MNV MARUL ADET",
  "unitName": "ADET",
  "primaryBarcode": "2801850100000",
  "globalProductCode": "",
  "product": {
    "stockCode": "018501",
    "productCode": "018501",
    "stockName": "MNV MARUL ADET",
    "shortName": "MARUL",
    "displayName": "MARUL",
    "productName": "MARUL",
    "modelCode": "12",
    "modelName": "Yesillik",
    "unitName": "ADET",
    "globalProductCode": "",
    "primaryBarcode": "2801850100000"
  },
  "quantity": 25,
  "latestCreateDate": "2026-06-04T09:15:10",
  "canDelete": true,
  "caseInfo": null
}
```

### Manav Siparisi Sil

`DELETE /api/green-grocer/orders?documentSerie=F110&documentOrderNo=1234`

Opsiyonel sube filtresi:

`DELETE /api/green-grocer/orders?documentSerie=F110&documentOrderNo=1234&warehouseNo=110`

Kural:

- Sadece son 24 saat icinde olusturulan evraklar silinebilir.
- Eski WebUI'deki `TimeSpan.Hours` davranisi yerine `TotalHours` kullanilir.
- Kayit yoksa `404`, 24 saat penceresi gecmisse `409 Conflict` doner.
- Normal kullanicida `warehouseNo` gonderilmezse backend JWT deposunu uygular; baska depo gonderirse `403` doner.
- `green-grocer.reports.all-warehouses` yetkisiyle `warehouseNo` bos birakilirsa evrak no ile eslesen tum sube satirlari silinebilir; UI'da yine secili sube ile silme onerilir.

Response:

```json
{
  "documentSerie": "F110",
  "documentOrderNo": 1234,
  "warehouseNo": 110,
  "deletedLineCount": 8,
  "latestCreateDate": "2026-06-04T09:15:10",
  "deletedAt": "2026-06-04T10:01:22"
}
```

## Ortak Arama Islemleri

Bu endpointler siparis, mal kabul, sevk, iade gibi formlarda ortak secim/arama icin kullanilir.

Not:

- Aksi belirtilmedikce endpointler `Authorization: Bearer {token}` ister.
- Genel arama endpointleri menu/action permission istemez; login olan kullanici kullanabilir.
- UI menusu olarak gorunen `FiyatGor` ve `CariBul` endpointleri kendi `list` permission'larini ister.
- `Son Kunye` endpoint'i anonim cagrilabilir; login olmadan kullanilacaksa `warehouseNo` query parametresi zorunludur.
- Mikro tarafinda sadece SELECT/read-only mantigiyla calisir.
- Urun arama `dbo.__StokveFiyatArama_Gokhan` stored procedure'u ile yapilir.
- Mobil barkod okutma senaryolarinda genel `urunler` listesi yerine once `barkodlar/{barcode}/cozumle` endpoint'i tercih edilmelidir.
- Barkod okutma, cozumleme, satira ekleme, fiyat/cari bulma ve barkod tanimlatma karar akisi icin kisa rehber: `docs/BARKOD_COZUMLEME_VE_ARAMA_REHBERI.md`.
- Mobil offline fiyat okutma icin tekil `fiyat-gor` endpointleri yerine `GET /api/mobile-sync/urun-fiyat-katalogu` ile depo bazli katalog cihaza indirilmelidir.
- Mobil offline cari ve depo secimleri icin online arama endpointleri yerine `GET /api/mobile-sync/cari-katalogu` ve `GET /api/mobile-sync/depo-katalogu` kataloglari cihaza indirilmelidir.
- Mal kabul create ekranlarinda cari secimini hizlandirmak icin `urunler/{stockCode}/cari-onerileri` endpoint'i yardimci olarak kullanilabilir.
- `warehouseNo` arama endpointlerinde her zaman islemi yapan kullanicinin/magazanin deposudur; siparis verilen kaynak depo degildir. Normal sube/terminal kullanicisinda UI bu alani bos birakmali veya token deposunu gondermelidir. Kaynak depo secildi diye `warehouseNo` kaynak depoya cevrilmemelidir.

### Urun Ara

`GET /api/arama-islemleri/urunler?warehouseNo=110&stockName=sut&take=20`

Barkod ile:

`GET /api/arama-islemleri/urunler?warehouseNo=110&barcode=8690000000000`

Stok kodu ile:

`GET /api/arama-islemleri/urunler?warehouseNo=110&stockCode=015550`

Firma/cari kodu ile:

`GET /api/arama-islemleri/urunler?warehouseNo=110&companyCode=120.01.03106&stockName=sut`

Query:

```text
warehouseNo    opsiyonel; verilmezse JWT icindeki depo kullanilir
barcode        opsiyonel; barkod ile exact arama; 27/29 ile baslayan 13 haneli terazi barkoduysa arama barkodu ilk 7 haneye normalize edilir
stockCode      opsiyonel; stok kodu ile exact arama
stockName      opsiyonel; stok adinda contains arama, en az 2 karakter
companyCode    opsiyonel; secilen firma/cari kodu filtresi
supplierCode   opsiyonel; companyCode ile ayni filtre icin geriye uyum alias'i
take           opsiyonel; default 20, max 100
```

Kural:

- `barcode`, `stockCode`, `stockName`, `companyCode` veya `supplierCode` alanlarindan en az biri verilmelidir.
- Bos arama engellenir; cunku Mikro procedure genis fiyat/stok seti dondurebilir.
- `warehouseNo`, fiyat/stok/blok bilgisinin hangi islem deposuna gore okunacagini belirler. Bu alan kaynak depo secimi icin kullanilmaz.
- Merkez depoya siparis verme ekraninda kullanici deposu `56`, kaynak depo `50` ise urun arama istegi `warehouseNo=50` ile degil, `warehouseNo=56` ile veya `warehouseNo` bos gonderilerek yapilmalidir.
- Ornek yanlis kullanim: `GET /api/arama-islemleri/urunler?warehouseNo=50&stockName=aytac`. Kullanici token deposu `56` ise ve tum depo yetkisi yoksa backend `403 Forbidden` dondurur.
- Ornek dogru kullanim: `GET /api/arama-islemleri/urunler?stockName=aytac&take=20` veya `GET /api/arama-islemleri/urunler?warehouseNo=56&stockName=aytac&take=20`.
- Barkod okutulduysa UI mumkunse degeri `barcode` alaninda gondermelidir. 27/29 terazi barkodunda backend ilk 7 haneyi arar; sonuc bulunamazsa ayni urun/PLU kismi icin `27`/`29` alternatif prefix'ini de dener. Ornek: `2700740000008` okutulursa `2700740`, sonra `2900740`, sonra orijinal barkod denenir.
- Genel arama kutusunda kullanici sadece numerik metin yazarsa ve ilk arama sonuc donmezse backend bu metni once barkod, sonra stok kodu gibi tekrar dener.
- Ornek: `stockName=2900729` gibi yanlis/genel arama seklinde gelirse backend sonuc bulamazsa `barcode=2900729` gibi tekrar deneyip `015806` stokunu dondurebilir. En temiz UI yolu yine `barcode=2900729` veya `GET /api/arama-islemleri/barkodlar/2900729/cozumle` kullanmaktir.
- UI barkodu yanlislikla `stockCode` alaninda gonderirse de backend ilk stok kodu aramasindan sonuc alamazsa ayni numerik degeri barkod gibi tekrar dener. Ornek: `stockCode=2900728&companyCode=8880325699` sonuc bulamazsa backend `barcode=2900728&companyCode=8880325699` gibi tekrar arar ve stok `015805` donebilir.
- Firma icin urun ararken UI `companyCode` gondermelidir; backend bunu Mikro procedure tarafinda `@tedarikci` filtresine baglar.
- Bu filtre Mikro'da `SATINALMA_SARTLARI.sas_cari_kod` iliskisi uzerinden calisir; yani firma ile iliskili urunler listelenir.

Response:

```json
[
  {
    "warehouseNo": 110,
    "barcode": "2700174",
    "stockCode": "015550",
    "stockName": "MNV SEFTALI KG",
    "price": 99.9,
    "priceTypeCode": 1,
    "unitName": "KG",
    "unitMultiplier": 1,
    "secondaryUnitName": "",
    "secondaryUnitMultiplier": 0,
    "salesBlockCode": 0,
    "orderBlockCode": 0,
    "goodsAcceptanceBlockCode": 0,
    "isSalesBlocked": false,
    "isOrderBlocked": false,
    "isGoodsAcceptanceBlocked": false,
    "productManagerCode": "PER001",
    "requestedBarcode": "2700174041103",
    "lookupBarcode": "2700174",
    "isVariableWeightBarcode": true,
    "embeddedQuantity": 4.11,
    "embeddedQuantityUnit": "KG",
    "isBarcodeCheckDigitValid": true
  }
]
```

UI kullanim notu:

- Mal kabulde `isGoodsAcceptanceBlocked = true` olan urunlerde uyari gosterilebilir.
- Siparis girisinde `isOrderBlocked = true` olan urunlerde uyari veya engel uygulanabilir.
- Satis/sevk formlarinda `isSalesBlocked = true` olan urunlerde uyari gosterilebilir; depolar arasi sevkte bu alan tek basina satira ekleme engeli degildir.
- Barkod okutulan satir ekleme ekranlarinda nihai karar icin once `barkodlar/{barcode}/cozumle` cagrilmalidir; `urunler` daha cok liste/arama deneyimi icindir.

### Fiyat Gor

Arama Islemleri altinda menu olarak gosterilebilecek hizli fiyat sorgu ekranidir. Ayni Mikro fiyat arama prosedurunu kullanir ve `Urun Ara` response modelini doner.

`GET /api/arama-islemleri/fiyat-gor?warehouseNo=110&barcode=8690000000000`

Stok kodu veya urun adi ile:

`GET /api/arama-islemleri/fiyat-gor?warehouseNo=110&stockCode=015550`

`GET /api/arama-islemleri/fiyat-gor?warehouseNo=110&stockName=sut&take=20`

Barkod odakli alias:

`GET /api/arama-islemleri/barkodlar/8690000000000/fiyat?warehouseNo=110&take=20`

Yetki:

- `arama-islemleri.fiyat-gor.list`

Query:

```text
warehouseNo    opsiyonel; verilmezse JWT icindeki depo kullanilir
barcode        opsiyonel; barkod ile exact arama; 27/29 ile baslayan 13 haneli terazi barkoduysa arama barkodu ilk 7 haneye normalize edilir
stockCode      opsiyonel; stok kodu ile exact arama
stockName      opsiyonel; stok adinda contains arama, en az 2 karakter
companyCode    opsiyonel; secilen firma/cari kodu filtresi
supplierCode   opsiyonel; companyCode ile ayni filtre icin geriye uyum alias'i
take           opsiyonel; default 20, max 100
```

Response:

- `ProductLookupItemDto[]`
- Alanlar `Urun Ara` response'u ile aynidir; UI fiyat icin `price`, `priceTypeCode`, `unitName`, `barcode`, `stockCode` ve `stockName` alanlarini one cikarabilir.

UI kullanim notu:

- Sol menu altinda `AramaIslemleri > FiyatGor` gibi ayri bir hizli ekran olarak sunulabilir.
- Barkod okutma ekraninda pratik yol `barkodlar/{barcode}/fiyat` alias'idir.
- Terazi barkodunda response icindeki `requestedBarcode`, `lookupBarcode`, `embeddedQuantity` ve `embeddedQuantityUnit` alanlari UI'a okutulan barkod ile arama barkodunu ayirmak icin gelir.
- El terminali offline kullanacaksa bu endpoint online anlik sorgu icin kalmali; offline veri hazirligi `Mobil Urun-Fiyat Katalog Sync` endpoint'iyle yapilmalidir.

### Urun Son Kunye

Secili stok kodu ve sube/depo icin son sevk tarihli kunye bilgisini ve Mikro satis fiyatini getirir.

`GET /api/arama-islemleri/urunler/016201/son-kunye?warehouseNo=110`

Yetki:

- Anonim cagrilabilir, token zorunlu degildir.
- Login olmadan cagrilirsa `warehouseNo` zorunludur.
- Login olan kullanici icin `warehouseNo` verilmezse JWT icindeki depo kullanilir.

Path:

```text
stockCode      zorunlu; Mikro stok kodu, ornek: 016201
```

Query:

```text
warehouseNo    anonim cagri icin zorunlu; login varsa opsiyonel
```

Response:

```json
{
  "branchNo": 110,
  "branchName": "Sube Adi",
  "productionCity": "BURSA",
  "stockCode": "016201",
  "stockName": "MNV ELMA STARKING (KIRMIZI) KG",
  "salesPrice": 99.9,
  "productionDistrict": "NILUFER",
  "productName": "ELMA",
  "goodsType": "STARKING",
  "goodsGenus": "KIRMIZI",
  "quantity": 10,
  "takenTag": "2323439260090550630",
  "buyer": "Alici",
  "productionDate": "2026-05-21T00:00:00",
  "buyingPrice": 50,
  "shippingDate": "2026-05-21T00:00:00",
  "manufacturer": "Uretici",
  "productUnit": "Kg"
}
```

Not:

- Kayit bulunamazsa response `200 OK` ile `null` doner.
- Eslesme stok adi uzerinden degil, `FaturaIslem.StokId -> MuhStok.Stokid -> MuhStok.StokKodu -> STOKLAR.sto_kod` uzerinden yapilir.
- Fiyat `fn_StokSatisFiyati(stockCode, '1', warehouseNo, '1')` fonksiyonundan gelir.
- `ShippingDate <= GETDATE()` filtresi uygulanir ve en yeni `ShippingDate` satiri doner.

### Tek Barkod Cozumle

Mobil uygulamada barkod okutunca tek cevapta urun bulundu mu, okutulan barkodun tipi, koli ici adet, terazi/KG miktari, hedef depo uygunlugu, satinalma sarti ve secili islem icin kullanilabilirlik bilgisini almak icin:

`GET /api/arama-islemleri/barkodlar/2700174041103/cozumle?warehouseNo=110&operationType=receiving&targetWarehouseNo=120&supplierCode=120.01.03106`

Query:

```text
warehouseNo    opsiyonel; verilmezse JWT icindeki depo kullanilir
operationType  opsiyonel; islem tipini verir, satira ekleme kararinda kullanilir
targetWarehouseNo opsiyonel; hedef depo/model kod uygunlugu hesaplamak icin kullanilir; shipment icin bloklayici degildir
supplierCode   opsiyonel; secili tedarikciye gore SATINALMA_SARTLARI kontrolu yapar; receiving/order icin karar motoruna dahil edilir
companyCode    opsiyonel; supplierCode ile ayni anlamda geriye uyum alias'i
isRefund       opsiyonel; false ise eski sistemdeki iade disi DLS/99 filtresi uygulanir
screenCode     opsiyonel; eski UI uyumu icin korunur, operationType bos ise ekran baglami gibi kullanilir
```

Desteklenen tipik `operationType` / `screenCode` degerleri:

- `receiving`, `firma-mal-kabulleri`, `depo-mal-kabulleri`
- `order`, `verilen-firma-siparisleri`, `verilen-depo-siparisleri`
- `shipment`, `giden-firma-sevkleri`, `giden-depolar-arasi-sevkler`
- `return`, `firma-iadeleri`, `giden-depo-iadeleri`
- `waste`, `zayiat-fisleri`, `masraf-fisleri`, `fire`
- `count`, `sayim-sonuclari`

Onemli not:

- Endpoint once 13 haneli terazi barkodunu normalize eder. `27` veya `29` ile baslayan EAN-13 barkodlarda ilk 7 hane urun barkodu kabul edilir; 8-12. haneler KG miktari olarak `embeddedQuantity` alanina yazilir.
- Ornek: `2700174041103` okutulursa `lookupBarcode = 2700174`, `embeddedQuantity = 4.11`, `embeddedQuantityUnit = KG` doner.
- Endpoint normalize edilen barkodu `BARKOD_TANIMLARI` tablosunda exact arar. Terazi barkodunda sonuc bulunamazsa ayni urun/PLU kismi icin `27`/`29` alternatif prefix'i denenir. Ornek: `2700740000008` icin `2700740`, sonra `2900740`, sonra orijinal barkod aranir.
- Barkod bulunamazsa barkodu stok kodu veya global urun numarasi gibi degerlerle eslestirmeyi dener.
- `resolutionSource` alani eslestirmenin `variable-weight`, `barcode`, `stock-code`, `gtin` veya `not-found` kaynakli oldugunu anlatir.
- `barcodeKind` alani okutulan barkodun `variable-weight`, `product`, `case`, `alternative`, `stock-code` veya `gtin` gibi pratik tipini verir.
- `caseBarcode`, `unitsPerCase` ve `matchedUnitsPerCase` alanlari koli/master barkod tespitinde kullanilir.
- `isSalesBlocked`, `isOrderBlocked`, `isGoodsAcceptanceBlocked` ve `isPassive` depo detay degerleri varsa depo ozelinden, yoksa stok kartindan hesaplanir.
- `isAllowedForTargetWarehouse` hedef depo verilirse `DEPOLAR.dep_barkod_yazici_yolu` icindeki model kod listesine gore hesaplanir.
- `operationType=shipment` icin hedef depo model kod sonucu bilgi olarak donebilir; fakat hedef depo model kodu sevkte `isUsableInOperation=false` yapmaz.
- `operationType=shipment` icin `isSalesBlocked=true` bilgi/uyari olarak doner; pasif/DLS disinda tek basina satira eklemeyi bloklamaz.
- `hasPurchaseRequirement` tedarikci/companyCode verilirse veya operasyon `receiving`/`order` ise `SATINALMA_SARTLARI` kontrol sonucudur. Bu sonuc sadece mal kabul/siparis operasyonunda satira ekleme kararina dahil edilir.
- `operationType=shipment` icin sirf `targetWarehouseNo` geldi diye satinalma sarti kontrolu calismaz ve satira ekleme bloklanmaz.
- `salesPrice` ve `priceTypeCode` secili depodaki fiyat satirindan gelir.
- `isUsableInOperation`, `operationDecision`, `warnings` ve `errors` UI'in tek karar noktasi olmalidir.

Response:

```json
{
  "isFound": true,
  "barcode": "2700174041103",
  "warehouseNo": 110,
  "screenCode": null,
  "resolutionSource": "variable-weight",
  "stockCode": "015550",
  "stockName": "MNV SEFTALI KG",
  "matchedBarcode": "2700174",
  "primaryBarcode": "2700174",
  "caseBarcode": "18690000000007",
  "unitsPerCase": 12,
  "matchedUnitPointer": 1,
  "matchedUnitName": "KG",
  "matchedUnitMultiplier": 1,
  "isBlocked": false,
  "isSalesBlocked": false,
  "isOrderBlocked": false,
  "isGoodsAcceptanceBlocked": false,
  "isUsableInScreen": true,
  "usabilityReason": "Islem tipi verilmedigi icin genel blok bilgisi donduruldu.",
  "defaultSupplierCode": "120.01.03106",
  "defaultSupplierName": "ORNEK TEDARIKCI",
  "lookupBarcode": "2700174",
  "isVariableWeightBarcode": true,
  "embeddedQuantity": 4.11,
  "embeddedQuantityUnit": "KG",
  "isBarcodeCheckDigitValid": true,
  "barcodeKind": "variable-weight",
  "isPrimaryBarcode": false,
  "isCaseBarcode": false,
  "isAlternativeBarcode": false,
  "matchedUnitsPerCase": null,
  "operationType": "receiving",
  "targetWarehouseNo": 120,
  "isAllowedForTargetWarehouse": true,
  "targetWarehouseReason": "Urun hedef deponun izinli model kodlari icinde.",
  "productModelCode": "MNV",
  "targetWarehouseModelCodes": ["MNV", "SKT"],
  "supplierCode": "120.01.03106",
  "hasPurchaseRequirement": true,
  "purchaseRequirementReason": "Secili tedarikci icin satinalma sarti bulundu.",
  "salesPrice": 99.9,
  "priceTypeCode": 1,
  "isPassive": false,
  "isUsableInOperation": true,
  "operationDecision": "Urun mal kabul isleminde kullanilabilir.",
  "warnings": [],
  "errors": []
}
```

Bulunamayan barkod davranisi:

- Endpoint `200 OK` ile doner, fakat `isFound = false` olur.
- Bu durumda UI hata modal'i yerine kullaniciya "urun bulunamadi" veya "barkod tanimsiz" gibi hizli bir mesaj gosterebilir.
- Bu endpoint Mikro `BARKOD_TANIMLARI` tablosuna yeni barkod yazmaz. Barkod tanimlatma/ekletme istenirse ayri permission, duplicate kontrolu ve audit iceren yeni bir yazma akisi tasarlanmalidir.

UI kullanim notu:

- Kamera ile tek barkod okutulan ekranlarda once bu endpoint cagrilmalidir.
- UI barkodun urun/stok/ad/tipi tahminini frontend'de yapmamalidir; okutulan degeri aynen bu endpoint'e gondermelidir.
- Satira ekleme karari icin ana alan `isUsableInOperation` olmalidir. `false` ise `operationDecision` ve `errors` kullaniciya gosterilmelidir. Sevkte `isSalesBlocked` tek basina engel gibi yorumlanmamalidir.
- Terazi barkodunda satir miktari icin `embeddedQuantity` kullanilabilir; bos ise varsayilan miktar UI tarafinda `1` kabul edilebilir.
- Koli barkodu okutulduysa `isCaseBarcode = true` ve `matchedUnitsPerCase` dolu gelir; UI koli ici adet kadar miktar onerebilir.
- `caseBarcode` doluysa koli barkodu tekrar okutma, koli bozma veya alternatif birim secimi gibi kisayollar acilabilir.

### Urunden Cari Onerileri

Secili urun icin varsayilan tedarikciyi, aktif satinalma sarti carilerini ve yakin gecmiste ayni urunle hareket gormus cari onerilerini getirmek icin:

`GET /api/arama-islemleri/urunler/015550/cari-onerileri?warehouseNo=110&take=10`

Query:

```text
warehouseNo    opsiyonel; verilmezse JWT deposu kullanilir, SATINALMA_SARTLARI.sas_depo_no icin 0 veya bu depo kabul edilir
take    opsiyonel; default 10, max 25
```

Onemli not:

- Endpoint once stok kartini bulur; bulunamazsa `isProductFound = false` ve bos liste doner.
- Oneriler uc kaynaktan uretilir:
  - `varsayilan-tedarikci`: stok kartindaki `sto_sat_cari_kod`
  - `satinalma-sarti`: `SATINALMA_SARTLARI` icindeki aktif tedarikci kayitlari
  - `stok-hareketleri`: urunun bagli oldugu yakin tarihli stok hareketleri
- Ayni cari birden fazla kaynaktan gelirse `sources` alaninda kaynaklar birlikte doner.
- Sira: once varsayilan tedarikci, sonra aktif satinalma sarti carileri, sonra stok hareket gecmisi gelir.
- Bu endpoint otomatik cari set etmek zorunda degildir; sadece UI'a "onerilen firma" bilgisini verir.

Response:

```json
{
  "isProductFound": true,
  "stockCode": "015550",
  "stockName": "Stok Adi",
  "defaultSupplierCode": "120.01.03106",
  "defaultSupplierName": "ORNEK TEDARIKCI",
  "suggestions": [
    {
      "customerCode": "120.01.03106",
      "customerName": "ORNEK TEDARIKCI",
      "taxNoOrTckn": "1234567890",
      "isDefaultSupplier": true,
      "movementCount": 8,
      "lastMovementDate": "2026-05-01T00:00:00",
      "lastDocumentNo": "ST12026000002395",
      "sources": [
        "satinalma-sarti",
        "stok-hareketleri",
        "varsayilan-tedarikci"
      ]
    }
  ]
}
```

UI kullanim notu:

- Firma mal kabul create ekraninda kullanici urun sectiginde cari bos ise bu endpoint ile `onerilen tedarikci` chip'i gosterilebilir.
- `isDefaultSupplier = true` olan ilk kayit varsayilan secim adayi gibi davranabilir ama yine de kullanicidan onay almak daha guvenlidir.

### Barkoddan Cari Bul

Arama Islemleri altinda menu olarak gosterilebilecek hizli cari/firma bulma ekranidir. Backend once barkodu stokla eslestirir, sonra stok kartindaki varsayilan tedarikciyi, aktif satinalma sarti carilerini ve yakin gecmis stok hareketlerinden cari onerilerini doner.

`GET /api/arama-islemleri/cari-bul?barcode=8690000000000&warehouseNo=110&take=10`

Barkod odakli alias:

`GET /api/arama-islemleri/barkodlar/8690000000000/cariler?warehouseNo=110&take=10`

Yetki:

- `arama-islemleri.cari-bul.list`

Query:

```text
barcode        cari-bul route'unda zorunlu; path alias'ta path parametresidir
warehouseNo    opsiyonel; verilmezse JWT icindeki depo kullanilir
take           opsiyonel; default 10, max 25
```

Response:

```json
{
  "isFound": true,
  "barcode": "8690000000000",
  "warehouseNo": 110,
  "resolutionSource": "barcode",
  "stockCode": "015550",
  "stockName": "Stok Adi",
  "matchedBarcode": "8690000000000",
  "primaryBarcode": "8690000000000",
  "caseBarcode": "18690000000007",
  "unitsPerCase": 12,
  "defaultSupplierCode": "120.01.03106",
  "defaultSupplierName": "ORNEK TEDARIKCI",
  "suggestions": [
    {
      "customerCode": "120.01.03106",
      "customerName": "ORNEK TEDARIKCI",
      "taxNoOrTckn": "1234567890",
      "isDefaultSupplier": true,
      "movementCount": 8,
      "lastMovementDate": "2026-05-01T00:00:00",
      "lastDocumentNo": "ST12026000002395",
      "sources": [
        "satinalma-sarti",
        "stok-hareketleri",
        "varsayilan-tedarikci"
      ]
    }
  ]
}
```

UI kullanim notu:

- Sol menu altinda `AramaIslemleri > CariBul` gibi ayri bir hizli ekran olarak sunulabilir.
- `isFound = false` ise barkod/stok eslesmesi yoktur; UI "urun bulunamadi" gibi kisa bir mesaj gosterebilir.
- `suggestions` bos ama `defaultSupplierCode` doluysa UI varsayilan tedarikciyi tek onerilen firma gibi gosterebilir.
- `sources` icinde `satinalma-sarti` varsa cari, urunun aktif satinalma sarti kaydindan gelmistir; mal kabul/siparis senaryolarinda diger gecmis hareket onerilerinden daha guvenilir adaydir.

### Cari Ara

`GET /api/arama-islemleri/cariler?searchText=market&take=20`

TCKN/VKN, unvan veya kodla cok sayida benzer cari donebildigi icin bu endpoint secim ekranlarinda
detayli bilgi dondurur. UI sadece `customerName` alanini gostermemeli; mumkunse
`selectionLabel` alanini veya `customerCode + customerDisplayName + taxNumber + groupCode`
kombinasyonunu kullanmalidir.

Query:

```text
searchText   zorunlu, en az 2 karakter
take         opsiyonel; default 20, max 100
```

Arama alanlari:

```text
cari_kod
cari_unvan1
cari_unvan2
cari_VergiKimlikNo
cari_vdaire_no
cari_vdaire_adi
cari_Ana_cari_kodu
cari_bolge_kodu
cari_grup_kodu
cari_sektor_kodu
cari_temsilci_kodu
cari_EMail
cari_CepTel
```

Response:

```json
[
  {
    "customerCode": "120.01.03106",
    "customerName": "ORNEK MUSTERI",
    "customerTitle": "SUBE",
    "customerDisplayName": "ORNEK MUSTERI SUBE",
    "taxNumber": "1234567890",
    "taxIdentityNo": "1234567890",
    "taxOfficeNo": "",
    "taxOfficeName": "BURSA",
    "mainCustomerCode": "",
    "regionCode": "1",
    "groupCode": "MAGAZA",
    "sectorCode": "GIDA",
    "representativeCode": "TEM001",
    "representativeName": "Ad Soyad",
    "mobilePhone": "05xxxxxxxxx",
    "email": "ornek@example.local",
    "invoiceAddressNo": 1,
    "shippingAddressNo": 1,
    "isLocked": false,
    "isClosed": false,
    "isEInvoiceCustomer": true,
    "isEDespatchCustomer": true,
    "sameTaxCustomerCount": 3,
    "selectionLabel": "120.01.03106 ORNEK MUSTERI SUBE | VKN/TCKN: 1234567890 | Grup: MAGAZA | Temsilci: Ad Soyad | Ayni vergi no: 3"
  }
]
```

UI notu:

- `sameTaxCustomerCount > 1` ise ayni vergi/TCKN numarasina bagli birden fazla cari vardir; secim satirinda mutlaka `customerCode`, `customerTitle`, `groupCode`, `representativeName` ve gerekirse adres no gosterilmelidir.
- `customerName` Mikro `cari_unvan1`, `customerTitle` Mikro `cari_unvan2` karsiligidir. Farkli cari ayrimi cogu zaman `customerTitle` uzerinden yapilir.
- `taxNumber` geriye uyumlu tek alan olarak kalir; once `taxIdentityNo`, bos ise `taxOfficeNo` degeri kullanilir.
- `selectionLabel` backend tarafinda hazirlanan pratik gorunum etiketidir; UI kendi tasarimina gore parcalari ayri kolon olarak da gosterebilir.

### Depo Ara

Tum depolari almak icin:

`GET /api/arama-islemleri/depolar?take=100`

Metin ile aramak icin:

`GET /api/arama-islemleri/depolar?searchText=kestel`

Depo no ile aramak icin:

`GET /api/arama-islemleri/depolar?warehouseNo=110`

Response:

```json
[
  {
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "companyNo": 0,
    "branchNo": 0,
    "groupCode": "",
    "warehouseType": 0,
    "responsibilityCenterCode": "",
    "projectCode": "",
    "address": "Cadde Mahalle Sokak",
    "district": "KESTEL",
    "province": "BURSA",
    "isInventoryExcluded": false
  }
]
```

## Siparis Islemleri

Bu kisim UI tarafinda su anda en gercek calisan moduldur.

### Verilen Depo Siparisleri Liste

`GET /api/siparis-islemleri/verilen-depo-siparisleri?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-10`

Yetki:

- `siparis-islemleri.verilen-depo-siparisleri.list`

Not:

- `WarehouseNo` verilmezse JWT icindeki depo bilgisi kullanilabilir

Liste satiri modeli:

```json
{
  "documentKey": "MTEwfEQxMTB8MTkxNQ",
  "documentDate": "2026-04-01T00:00:00",
  "documentSerie": "D110",
  "documentOrderNo": 1915,
  "documentNumber": "",
  "warehouseNo": 110,
  "warehouseName": "KESTEL 1",
  "relatedWarehouseNo": 50,
  "relatedWarehouseName": "MERKEZ DEPO",
  "inWarehouseNo": 110,
  "inWarehouseName": "KESTEL 1",
  "outWarehouseNo": 50,
  "outWarehouseName": "MERKEZ DEPO",
  "lineCount": 2,
  "totalQuantity": 394,
  "totalAmount": 0,
  "deliveryDate": "2026-04-01T00:00:00"
}
```

### Verilen Depo Siparisi Olustur

`POST /api/siparis-islemleri/verilen-depo-siparisleri`

Yetki:

- `siparis-islemleri.verilen-depo-siparisleri.create`

Onemli not:

- Bu endpoint su an canli `MikroConnection` yerine write icin ayrilan `testMikroConnection` uzerinden `MikroDB_V16_SOPHIGET` veritabanina yazar.
- Kod yapisi ileride canliya gecmeye hazirdir; canliya geciste `MikroWriteConnection` connection string'i eklenerek yazma hedefi degistirilebilir.
- Yazma islemi EF Core uzerinden ayri `MikroWriteDbContext` ile yapilir; okuma tarafindaki `MikroDbContext` ile karismaz.
- `documentSerie` backend tarafinda `F{islemDepoNo}` olarak uretilir.
- `documentOrderNo` ayni seri icin test DB'deki mevcut maksimum sira okunarak uretilir; ilk evrak `0`, sonraki evraklar `1, 2...` seklinde gider.
- `siparis-islemleri.verilen-depo-siparisleri.all-warehouses` yoksa `inWarehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. Bu yetki varsa baska depo adina siparis olusturulacaksa body'de opsiyonel `inWarehouseNo` gonderilebilir.
- `outWarehouseNo` siparis verilen/karsi depo numarasidir.
- Merkez depoya siparis verme senaryosunda `inWarehouseNo` islemi yapan sube/magaza, `outWarehouseNo` kaynak/merkez depodur. Normal sube kullanicisinda `inWarehouseNo` gonderilmemeli, yalniz `outWarehouseNo=50` gonderilmelidir.
- UI urun arama veya barkod cozumleme isteklerinde kaynak depo olan `50` degerini `warehouseNo` alanina basmamalidir. `warehouseNo` bos kalirsa backend JWT deposunu kullanir; kaynak depo yalniz siparis create body icindeki `outWarehouseNo` alanina yazilir.
- Manav depo siparisinde `outWarehouseNo=56` olmalidir. UI `resolution-preview` kullandiysa satirda `quantity = estimatedQuantity` gonderir; kullanicinin girdigi kasa/koli ve ortalama bilgisi opsiyonel `greenGrocerCase` nesnesinde gonderilir.
- `greenGrocerCase` gonderilirse `estimatedQuantity` ile satir `quantity` birebir eslesmelidir; eslesmezse API `400 Bad Request` doner.
- `greenGrocerCase` sadece snapshot/rapor/detay gosterimi icindir; Mikro siparis satirina yine `quantity` alani yazilir.

Request:

```json
{
  "outWarehouseNo": 50,
  "orderDate": "2026-04-17",
  "deliveryDate": "2026-04-17",
  "description": "",
  "lines": [
    {
      "stockCode": "015550",
      "quantity": 10,
      "recommendedQuantity": 0,
      "unitPrice": 0,
      "unitPointer": 1,
      "description": "",
      "packageCode": "",
      "projectCode": "",
      "responsibilityCenter": ""
    }
  ]
}
```

Manav kasa siparisi request ornegi:

```json
{
  "outWarehouseNo": 56,
  "orderDate": "2026-07-31",
  "deliveryDate": "2026-07-31",
  "description": "Manav siparisi",
  "lines": [
    {
      "stockCode": "001082",
      "quantity": 11.25,
      "recommendedQuantity": 0,
      "unitPrice": 0,
      "unitPointer": 1,
      "description": "3 kasa",
      "greenGrocerCase": {
        "inputQuantity": 3,
        "inputMode": "Case",
        "conversionMode": "LabelAverageKgPerCase",
        "microUnit": "KG",
        "estimatedQuantity": 11.25,
        "averageKgPerCase": 3.75,
        "unitsPerCase": null,
        "averageSource": "LabelHistory",
        "averageRecordCount": 47,
        "averageCaseCount": 7526,
        "coefficientOfVariation": 0.08,
        "confidence": "High"
      }
    }
  ]
}
```

Response:

```json
{
  "documentSerie": "F110",
  "documentOrderNo": 0,
  "orderDate": "2026-04-17T00:00:00",
  "deliveryDate": "2026-04-17T00:00:00",
  "inWarehouseNo": 110,
  "outWarehouseNo": 50,
  "lineCount": 1,
  "totalQuantity": 10,
  "writeConnectionName": "testMikroConnection"
}
```

### Onerilen Depo Siparisleri Liste

`GET /api/siparis-islemleri/onerilen-depo-siparisleri?SourceWarehouseNo=50`

Yetki:

- `siparis-islemleri.onerilen-depo-siparisleri.list`

Query:

```text
SourceWarehouseNo          zorunlu, urunu gonderecek kaynak depo
TargetWarehouseNo          opsiyonel, verilmezse JWT icindeki depo kullanilir
LookbackDays               opsiyonel, default 43
FallbackRecommendedDay     opsiyonel, default 7
```

Not:

- Bu endpoint read-only calisir, Mikro'ya veri yazmaz.
- Kaynak depo `DEPOLAR.dep_barkod_yazici_yolu` alanindaki model kodlariyla urun ailesini belirler.
- Acik gelen depo siparisleri, `SuggestedWarehouseOrders:OpenIncomingOrderDeduction`
  ayari acik ve kaynak depo `TrustedSourceWarehouseNos` icindeyse ihtiyactan dusulur.
- Kaynak depoda elde olmayan miktar onerilmez.
- Oneri minimum stok esigine gore tetiklenir; `needQuantity` minimum stok acigidir.
- `packageFactor` 1'den buyukse `suggestedOrderQuantity` koli katina yukari yuvarlanir.
- `maxDay` doluysa onerilen miktar maksimum stok seviyesini asmadan sinirlanir; koli kati korunur.
- Kaynak stok siniri devreye girerse son miktar yine koli kati korunarak asagi kirpilir.
- Kaynak depo model kodlari bos ise backend `400 ProblemDetails` dondurebilir.

Liste satiri modeli:

```json
{
  "stockCode": "010001",
  "stockName": "Stok Adi",
  "modelCode": "01",
  "barcode": "8690000000001",
  "targetOnHand": 2,
  "sourceOnHand": 120,
  "salesQuantity": 86,
  "openIncomingOrderQuantity": 3,
  "packageFactor": 5,
  "minDay": 7,
  "recommendedDay": 7,
  "maxDay": 0,
  "recommendedStockQuantity": 14,
  "needQuantity": 9,
  "suggestedOrderQuantity": 10
}
```

UI akisi:

- Tek sayfada kullanici once kaynak depo secer.
- Kaynak depo secimi, genel urun arama endpointindeki `warehouseNo` degerini degistirmemelidir. Kaynak depo sadece bu endpointte `SourceWarehouseNo` olarak, siparise cevirme endpointinde de `sourceWarehouseNo` olarak gonderilir.
- UI listeyi getirir ve stok kodu, stok adi, barkod, hedef stok, kaynak stok, son satis, acik siparis, ihtiyac, koli katsayisi ve onerilen siparis miktarini gosterir.
- Kullanici satirlari secer, `quantity` alanini varsayilan olarak `suggestedOrderQuantity` ile doldurur.
- Kullanici miktari degistirebilir; `recommendedQuantity` alanina orijinal `suggestedOrderQuantity` yazilmasi onerilir.

### Onerilen Depo Siparisleri / Kaynak Depo Urun Secimi

`GET /api/siparis-islemleri/onerilen-depo-siparisleri/kaynak-depo-urunleri?sourceWarehouseNo=56`

Geriye uyumlu manav alias:

`GET /api/siparis-islemleri/onerilen-depo-siparisleri/manav`

Yetki:

- `siparis-islemleri.onerilen-depo-siparisleri.list`

Amac:

- Onerilen depo siparisi ekraninda kaynak depo Manav, Sarkuteri, Unlu Mamul gibi ozel urun ailesi deposuysa klasik stok ihtiyac algoritmasi yerine kaynak deponun urun listesini getirir.
- Bu endpoint read-only calisir, Mikro'ya veri yazmaz.
- Kaynak depo urun ailesini Mikro `DEPOLAR.dep_barkod_yazici_yolu` alanindaki model kodlarindan cozer. Bu alan `10,11,12,23` gibi virgullu, `;` veya `|` ayrimli olabilir.
- Sadece bu model kodlarina uyan, aktif, siparise kapali olmayan ve secili kaynak depoda `STOK_DEPO_DETAYLARI` kaydi bulunan stoklar doner.
- Kaynak depo model kodlari bos ise backend `400 ProblemDetails` doner.
- Response satirlari siparis satirina donusturulmeye hazirdir; `quantity` ve `recommendedQuantity` bilerek `0` gelir. UI satiri ekrana miktar `0` ile koymali, kullanici miktari elle girmelidir.
- Koli/ikinci birim bilgisi icin `secondaryUnitName`, `packageFactor` ve varsa `caseBarcode` alanlari doner. Ornek `secondaryUnitName=KOLI`, `packageFactor=12` ise 1 koli 12 ana birim olarak okunur.
- Bu akista otomatik oneri miktari uretilmez; kullanici kasa/koli/adet/kg kararini ekranda verir.
- `/manav` alias'i sadece `sourceWarehouseNo=56` icin kisa yoldur. Yeni UI genel kullanimda `kaynak-depo-urunleri?sourceWarehouseNo={secilenKaynakDepo}` endpointini tercih etmelidir.

Canli DB'de model kodu tanimli kaynak depolar:

```text
50  MERKEZ DEPO             01,02,03,04,20
53  ET-SARKUTERI DEPO       15,21
55  UNLU URETIM             30,31,32,33,22
56  MANAV DEPO              10,11,12,23
58  UNLU URETIM - OZLUCE    40
```

UI karar kurali:

- Kaynak depo `53`, `55`, `56` veya `58` gibi ozel uretim/urun ailesi deposuysa klasik otomatik oneri endpointi yerine `kaynak-depo-urunleri` endpointi cagrilir.
- Kaynak depo `50 MERKEZ DEPO` ise mevcut klasik otomatik oneri endpointi normal ana akis olarak kalabilir; istenirse ayni kaynak urun secimi endpointi de model kodlari tanimli oldugu icin teknik olarak calisir.
- Kaynak depo bu tabloda yoksa klasik otomatik oneri endpointi kullanilir veya UI kaynak urun secimi aksiyonunu pasif gosterir.
- Backend tarafinda endpoint sadece bu listeye kilitli degildir; ilgili kaynak deponun `DEPOLAR.dep_barkod_yazici_yolu` model kodlari tanimliysa calisir. Bu tablo canli DB'de su an tanimli olan depolari gosterir.
- `59 UNLU URETIM - HASANAGA` ve `62 UNLU URETIM - ALEMDAR` su an canli DB'de model kodu bos oldugu icin bu endpointte aktif kaynak depo gibi kullanilmamalidir. Bu depolar icin `DEPOLAR.dep_barkod_yazici_yolu` doldurulursa endpoint calisir hale gelir.

Response:

```json
[
  {
    "sourceWarehouseNo": 56,
    "sourceWarehouseName": "MANAV DEPO",
    "stockCode": "016167",
    "stockName": "MNV MAYDANOZ ADET",
    "modelCode": "12",
    "modelName": "Yesillik",
    "unitName": "ADET",
    "secondaryUnitName": "KOLI",
    "packageFactor": 25,
    "barcode": "2900729",
    "caseBarcode": "1290072900000",
    "quantity": 0,
    "recommendedQuantity": 0,
    "unitPrice": 0,
    "unitPointer": 1
  }
]
```

UI akisi:

- Kaynak depo normal merkez/depo siparisi ise klasik `GET /api/siparis-islemleri/onerilen-depo-siparisleri?sourceWarehouseNo=...` kullanilir.
- Kaynak depo `53`, `55`, `56` veya `58` ise `GET /api/siparis-islemleri/onerilen-depo-siparisleri/kaynak-depo-urunleri?sourceWarehouseNo={sourceWarehouseNo}` cagrilir.
- Kaynak depo `59` veya `62` secilecekse once DB'de ilgili model kodlari tanimlanmalidir; aksi halde backend `400 ProblemDetails` ile "Secilen kaynak depo icin model kodlari tanimli degil." doner.
- Donen satirlar grid/form satirina `quantity=0` ile basilir.
- `packageFactor > 1` ise UI koli miktari girisine izin verebilir; ana miktar `koliAdedi * packageFactor` olarak hesaplanabilir. `caseBarcode` doluysa koli barkodu olarak gosterilebilir veya okutma eslestirmesinde kullanilabilir.
- Kullanici miktari kendisi girer; `quantity > 0` olmayan satirlar siparise cevrilmemelidir.
- Siparise cevirirken yine `POST /api/siparis-islemleri/onerilen-depo-siparisleri/convert-to-order` kullanilir.
- Request icinde secilen kaynak depo `sourceWarehouseNo` olarak gonderilir ve secilen satirlar `lines[]` altina yazilir.

### Onerilen Depo Siparislerini Siparise Cevir

`POST /api/siparis-islemleri/onerilen-depo-siparisleri/convert-to-order`

Yetki:

- `siparis-islemleri.onerilen-depo-siparisleri.create`

Not:

- Bu endpoint mevcut `Verilen Depo Siparisi Olustur` altyapisini kullanir.
- `siparis-islemleri.onerilen-depo-siparisleri.all-warehouses` yoksa `targetWarehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. Bu yetki varsa baska depo adina siparis olusturulacaksa body'de opsiyonel `targetWarehouseNo` gonderilebilir.
- `sourceWarehouseNo`, olusacak depo siparisindeki `outWarehouseNo` olarak kullanilir.
- Normal sube/terminal kullanicisinda `targetWarehouseNo` gonderilmemelidir. Merkez depo siparisi icin `sourceWarehouseNo=50` yeterlidir; hedef subeyi backend token deposundan cozer.

Request:

```json
{
  "sourceWarehouseNo": 50,
  "orderDate": "2026-07-01",
  "deliveryDate": "2026-07-01",
  "description": "Onerilen siparisten olustu",
  "lines": [
    {
      "stockCode": "010001",
      "quantity": 12,
      "recommendedQuantity": 12,
      "unitPrice": 0,
      "unitPointer": 1,
      "description": "",
      "packageCode": "",
      "projectCode": "",
      "responsibilityCenter": ""
    }
  ]
}
```

Response modeli `CreateIssuedWarehouseOrderResponse` ile aynidir.

### Alinan Depo Siparisleri Liste

`GET /api/siparis-islemleri/alinan-depo-siparisleri?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-10`

Yetki:

- `siparis-islemleri.alinan-depo-siparisleri.list`

Not:

- `WarehouseNo` verilmezse JWT icindeki depo bilgisi kullanilabilir
- Liste response modeli `Verilen Depo Siparisleri Liste` ile ayni DTO'yu kullanir

Liste satiri modeli:

```json
{
  "documentKey": "MTEwfEQxMTB8MTkxNQ",
  "documentDate": "2026-04-01T00:00:00",
  "documentSerie": "D110",
  "documentOrderNo": 1915,
  "documentNumber": "",
  "warehouseNo": 110,
  "warehouseName": "KESTEL 1",
  "relatedWarehouseNo": 50,
  "relatedWarehouseName": "MERKEZ DEPO",
  "inWarehouseNo": 110,
  "inWarehouseName": "KESTEL 1",
  "outWarehouseNo": 50,
  "outWarehouseName": "MERKEZ DEPO",
  "lineCount": 2,
  "totalQuantity": 394,
  "totalAmount": 0,
  "deliveryDate": "2026-04-01T00:00:00"
}
```

### Verilen Firma Siparisleri Liste

`GET /api/siparis-islemleri/verilen-firma-siparisleri?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-10`

Yetki:

- `siparis-islemleri.verilen-firma-siparisleri.list`

Not:

- `WarehouseNo` verilmezse JWT icindeki depo bilgisi kullanilabilir
- mevcut canli veride firma siparisleri icin `sip_tip = 1` verilen, `sip_tip = 0` alinan olarak okunuyor
- Firma mal kabulde siparis baglamak icin `CustomerCode` ve `OnlyOpen=true` query parametreleri kullanilabilir.

Mal kabul icin secili carinin acik verilen siparisleri:

`GET /api/siparis-islemleri/verilen-firma-siparisleri?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-30&CustomerCode=120.01.03106&OnlyOpen=true`

Liste satiri modeli:

```json
{
  "documentKey": "MTEwfEYxMTB8MjY0Nw",
  "documentDate": "2026-04-01T00:00:00",
  "deliveryDate": "2026-04-02T00:00:00",
  "documentSerie": "F110",
  "documentOrderNo": 2647,
  "documentNumber": "",
  "warehouseNo": 110,
  "customerCode": "120.01.03106",
  "customerName": "ORNEK MUSTERI",
  "customerTitle": "SUBE",
  "customerDisplayName": "ORNEK MUSTERI SUBE",
  "customerAddress": "DEMIRTAS OSMANGAZI BURSA",
  "description1": "",
  "description2": "",
  "deliverer": "",
  "receiver": "",
  "canBeCalled": false,
  "customerRepresentativeCode": "TEM001",
  "lineCount": 3,
  "totalQuantity": 125,
  "totalDeliveredQuantity": 40,
  "totalRemainingQuantity": 85,
  "isClosed": false,
  "totalAmount": 18450.75
}
```

### Verilen Firma Siparisi Olustur

`POST /api/siparis-islemleri/verilen-firma-siparisleri`

Yetki:

- `siparis-islemleri.verilen-firma-siparisleri.create`

Onemli not:

- Bu endpoint EF Core uzerinden ayri `MikroWriteDbContext` ile yazma yapar.
- Su an write hedefi canli `MikroConnection` degil; `MikroWriteConnection` yoksa `testMikroConnection` kullanilir.
- `SIPARISLER` tablosuna `sip_tip = 1`, `sip_cins = 0` olarak verilen firma siparisi yazar.
- `documentSerie` backend tarafinda `F{islemDepoNo}` olarak uretilir.
- `documentOrderNo` ayni seri/tip/cins icin write DB'deki maksimum sira okunarak uretilir; ilk evrak `0`, sonraki evraklar `1, 2...` seklinde gider.
- `*.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. Ilgili siparis menusunde `all-warehouses` yetkisi olan kullanici baska depo adina siparis olusturacaksa body'de opsiyonel `warehouseNo` gonderebilir.
- Cari bilgisi write DB'de `CARI_HESAPLAR` icinden okunur; `cari_odemeplan_no` -> `sip_opno`, `cari_pasaport_no == "1"` -> `sip_cagrilabilir_fl`.

Request:

```json
{
  "customerCode": "120.01.03106",
  "orderDate": "2026-04-17",
  "deliveryDate": "2026-04-18",
  "description1": "",
  "description2": "",
  "deliverer": "Teslim Eden",
  "receiver": "Teslim Alan",
  "lines": [
    {
      "stockCode": "015550",
      "quantity": 10,
      "recommendedQuantity": 0,
      "unitPrice": 0,
      "unitPointer": 1,
      "description1": "",
      "description2": "",
      "packageCode": "",
      "projectCode": "",
      "customerResponsibilityCenter": "",
      "productResponsibilityCenter": ""
    }
  ]
}
```

Response:

```json
{
  "documentSerie": "F110",
  "documentOrderNo": 0,
  "orderDate": "2026-04-17T00:00:00",
  "deliveryDate": "2026-04-18T00:00:00",
  "warehouseNo": 110,
  "customerCode": "120.01.03106",
  "lineCount": 1,
  "totalQuantity": 10,
  "totalAmount": 0,
  "writeConnectionName": "testMikroConnection"
}
```

### Onerilen Firma Siparisleri Liste

`GET /api/siparis-islemleri/onerilen-firma-siparisleri?SupplierCode=32000999`

Yetki:

- `siparis-islemleri.onerilen-firma-siparisleri.list`

Query:

```text
SupplierCode               zorunlu, secili firma/tedarikci kodu
WarehouseNo                opsiyonel, verilmezse JWT icindeki depo kullanilir
LookbackDays               opsiyonel, default 43
FallbackRecommendedDay     opsiyonel, default 7
```

Not:

- Bu endpoint read-only calisir, Mikro'ya veri yazmaz.
- Firma siparisleri firma bazli oldugu icin `SupplierCode` zorunludur; firma secilmeden liste getirilmez.
- Depo bazli tedarikci, stok karti tedarikcisi ve satinalma sartlari eslesmeleri secili firmaya gore dikkate alinir.
- Acik verilen firma siparisleri, `SuggestedCompanyOrders:OpenIssuedOrderDeduction`
  ayari acik ve tedarikci `TrustedSupplierCodes` icindeyse ihtiyactan dusulur.
- Oneri minimum stok esigine gore tetiklenir; `needQuantity` minimum stok acigidir.
- Satinalma sartinda asgari miktar varsa onerilen miktar once asgari miktara tamamlanabilir.
- `packageFactor` 1'den buyukse `suggestedOrderQuantity` koli katina yukari yuvarlanir.
- `maxDay` doluysa onerilen miktar maksimum stok seviyesini asmadan sinirlanir; koli kati korunur.

Liste satiri modeli:

```json
{
  "supplierCode": "32000999",
  "supplierName": "TEDARIKCI A.S.",
  "stockCode": "010001",
  "stockName": "Stok Adi",
  "modelCode": "01",
  "barcode": "8690000000001",
  "targetOnHand": 4,
  "salesQuantity": 86,
  "openCompanyOrderQuantity": 2,
  "packageFactor": 5,
  "minDay": 7,
  "recommendedDay": 7,
  "maxDay": 0,
  "recommendedStockQuantity": 14,
  "needQuantity": 8,
  "suggestedOrderQuantity": 25,
  "purchasePrice": 15.75,
  "minimumPurchaseQuantity": 24,
  "deliveryDay": 2
}
```

UI akisi:

- Tek sayfada kullanici firma/tedarikci secer.
- UI listeyi getirir ve firma, stok kodu, stok adi, barkod, mevcut stok, son satis, acik firma siparisi, ihtiyac, koli katsayisi, asgari alim, alis fiyati ve onerilen siparis miktarini gosterir.
- Kullanici satirlari secer, `quantity` alanini varsayilan olarak `suggestedOrderQuantity` ile doldurur.
- Kullanici miktari degistirebilir; `recommendedQuantity` alanina orijinal `suggestedOrderQuantity` yazilmasi onerilir.

### Onerilen Firma Siparislerini Siparise Cevir

`POST /api/siparis-islemleri/onerilen-firma-siparisleri/convert-to-order`

Yetki:

- `siparis-islemleri.onerilen-firma-siparisleri.create`

Not:

- Bu endpoint mevcut `Verilen Firma Siparisi Olustur` altyapisini kullanir.
- `*.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. Ilgili siparis menusunde `all-warehouses` yetkisi olan kullanici baska depo adina siparis olusturacaksa body'de opsiyonel `warehouseNo` gonderebilir.
- `supplierCode`, olusacak firma siparisindeki `customerCode` olarak kullanilir.

Request:

```json
{
  "supplierCode": "32000999",
  "orderDate": "2026-07-01",
  "deliveryDate": "2026-07-02",
  "description1": "Onerilen siparisten olustu",
  "description2": "",
  "deliverer": "",
  "receiver": "",
  "lines": [
    {
      "stockCode": "010001",
      "quantity": 24,
      "recommendedQuantity": 24,
      "unitPrice": 15.75,
      "unitPointer": 1,
      "description1": "",
      "description2": "",
      "packageCode": "",
      "projectCode": "",
      "customerResponsibilityCenter": "",
      "productResponsibilityCenter": ""
    }
  ]
}
```

Response modeli `CreateIssuedCompanyOrderResponse` ile aynidir.

### Alinan Firma Siparisleri Liste

`GET /api/siparis-islemleri/alinan-firma-siparisleri?WarehouseNo=50&StartDate=2026-04-01&EndDate=2026-04-10`

Yetki:

- `siparis-islemleri.alinan-firma-siparisleri.list`

Not:

- ayni response modeli kullanilir
- representative tam adi yerine su an sadece `customerRepresentativeCode` doner; cunku temsilci isim tablosu mevcut Mikro scaffold kapsaminda henuz yok

### Verilen Firma Siparisi Detay

Seri + sira ile:

`GET /api/siparis-islemleri/verilen-firma-siparisleri/F110/2841?warehouseNo=110`

Opsiyonel document key ile:

`GET /api/siparis-islemleri/verilen-firma-siparisleri/key/MTEwfEYxMTB8Mjg0MQ`

Yetki:

- `siparis-islemleri.verilen-firma-siparisleri.detail`

### Alinan Firma Siparisi Detay

Seri + sira ile:

`GET /api/siparis-islemleri/alinan-firma-siparisleri/A/1585?warehouseNo=50`

Opsiyonel document key ile:

`GET /api/siparis-islemleri/alinan-firma-siparisleri/key/NTB8QXwxNTg1`

Yetki:

- `siparis-islemleri.alinan-firma-siparisleri.detail`

### Firma Siparis Detay Response

```json
{
  "header": {
    "documentKey": "MTEwfEYxMTB8Mjg0MQ",
    "documentDate": "2026-04-01T00:00:00",
    "deliveryDate": "2026-04-02T00:00:00",
    "documentSerie": "F110",
    "documentOrderNo": 2841,
    "documentNumber": "",
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "customerCode": "120.01.03106",
    "customerName": "ORNEK MUSTERI",
    "customerTitle": "SUBE",
    "customerDisplayName": "ORNEK MUSTERI SUBE",
    "customerAddress": "DEMIRTAS OSMANGAZI BURSA",
    "customerRepresentativeCode": "TEM001",
    "description1": "",
    "description2": "",
    "deliverer": "",
    "receiver": "",
    "canBeCalled": false,
    "lineCount": 3,
    "totalQuantity": 125,
    "totalDeliveredQuantity": 0,
    "totalRemainingQuantity": 125,
    "totalAmount": 18450.75,
    "isClosed": false
  },
  "items": [
    {
      "lineGuid": "8d4a5a77-1b3f-4f2a-93a1-b90a1b7d3c11",
      "lineNo": 0,
      "stockCode": "015550",
      "stockName": "Stok Adi",
      "unitName": "AD",
      "unitPointer": 1,
      "quantity": 20,
      "deliveredQuantity": 0,
      "remainingQuantity": 20,
      "unitPrice": 150.5,
      "lineAmount": 3010,
      "isClosed": false,
      "description": "",
      "packageCode": "",
      "projectCode": "",
      "orderGuid": "1bb2b4fe-b722-4e67-9d4b-050b6d87e800"
    }
  ]
}
```

### Verilen Depo Siparisi Detay

Seri + sira ile:

`GET /api/siparis-islemleri/verilen-depo-siparisleri/D110/1915?warehouseNo=110`

Opsiyonel document key ile:

`GET /api/siparis-islemleri/verilen-depo-siparisleri/key/MTEwfEQxMTB8MTkxNQ`

Yetki:

- `siparis-islemleri.verilen-depo-siparisleri.detail`

### Alinan Depo Siparisi Detay

Seri + sira ile:

`GET /api/siparis-islemleri/alinan-depo-siparisleri/D110/1915?warehouseNo=110`

Opsiyonel document key ile:

`GET /api/siparis-islemleri/alinan-depo-siparisleri/key/MTEwfEQxMTB8MTkxNQ`

Yetki:

- `siparis-islemleri.alinan-depo-siparisleri.detail`

### Siparis Detay Response

```json
{
  "header": {
    "documentKey": "MTEwfEQxMTB8MTkxNQ",
    "documentDate": "2026-04-01T00:00:00",
    "deliveryDate": "2026-04-01T00:00:00",
    "documentSerie": "D110",
    "documentOrderNo": 1915,
    "documentNumber": "",
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "relatedWarehouseNo": 50,
    "relatedWarehouseName": "MERKEZ DEPO",
    "inWarehouseNo": 110,
    "inWarehouseName": "KESTEL 1",
    "outWarehouseNo": 50,
    "outWarehouseName": "MERKEZ DEPO",
    "lineCount": 2,
    "totalQuantity": 394,
    "totalDeliveredQuantity": 0,
    "totalRemainingQuantity": 394,
    "totalAmount": 0,
    "isClosed": false
  },
  "items": [
    {
      "lineNo": 0,
      "stockCode": "015550",
      "stockName": "Stok Adi",
      "unitName": "AD",
      "unitPointer": 1,
      "quantity": 384,
      "deliveredQuantity": 0,
      "remainingQuantity": 384,
      "unitPrice": 0,
      "lineAmount": 0,
      "isClosed": false,
      "description": "",
      "packageCode": "",
      "projectCode": "",
      "greenGrocerCase": null
    },
    {
      "lineGuid": "03d6df6a-b1b2-4923-b8f0-28060446e61f",
      "lineNo": 1,
      "stockCode": "001082",
      "stockName": "MNV SEFTALI KG",
      "unitName": "KG",
      "unitPointer": 1,
      "quantity": 11.25,
      "deliveredQuantity": 0,
      "remainingQuantity": 11.25,
      "unitPrice": 0,
      "lineAmount": 0,
      "isClosed": false,
      "description": "3 kasa",
      "packageCode": "",
      "projectCode": "",
      "greenGrocerCase": {
        "inputQuantity": 3,
        "inputMode": "Case",
        "conversionMode": "LabelAverageKgPerCase",
        "estimatedQuantity": 11.25,
        "microUnit": "KG",
        "averageKgPerCase": 3.75,
        "unitsPerCase": null,
        "averageSource": "LabelHistory",
        "averageRecordCount": 47,
        "averageCaseCount": 7526,
        "coefficientOfVariation": 0.08,
        "confidence": "High",
        "actualShippedQuantity": null,
        "actualShippedCaseCount": null,
        "status": "Ordered"
      }
    }
  ]
}
```

UI kullanim notlari:

- Depo siparisi liste ekraninda `documentKey`, `documentSerie`, `documentOrderNo`, `relatedWarehouseName`, `lineCount`, `totalQuantity`, `deliveryDate` yeterlidir
- Firma siparisi liste ekraninda `documentKey`, `documentSerie`, `documentOrderNo`, `customerDisplayName`, `customerAddress`, `lineCount`, `totalQuantity`, `deliveryDate` yeterlidir
- Detay ekranina gecis icin ana yol `documentSerie + documentOrderNo`
- alternatif olarak `documentKey` de saklanabilir
- detay ekraninda ust kart icin `header`, grid icin `items` kullanilmalidir
- Depo siparis detayi `items[].lineGuid` dondurur; depolar arasi sevki siparise baglamak icin bu guid `warehouseOrderLineGuid` olarak gonderilebilir
- Depolar arasi siparise bagli parcali sevk akisi icin UI, sevk satiri hazirlarken `items[].quantity` yerine `items[].remainingQuantity` alanini esas almalidir. `remainingQuantity <= 0` veya `isClosed = true` olan satirlar sevk satiri secimine tekrar getirilmemeli, sadece gecmis/bilgi olarak gosterilmelidir.
- Depo siparis detayi parcali sevk sonrasinda satir bazinda `deliveredQuantity`, `remainingQuantity` ve `isClosed` alanlarini guncel doner. UI kalan sevk ekranini acmadan once detayi yeniden okumali; kullaniciya varsayilan sevk miktari olarak kalan miktari onermelidir.
- `items[].greenGrocerCase` doluysa satir manav kasa/koli cozumleme snapshot'i ile olusmustur. UI manav depo gelen siparisinde bu satiri "3 kasa ~= 11.25 KG, ort 3.75 KG/kasa" gibi gostermelidir.
- `OrderLinkingEnabled=false` ise UI bu `lineGuid` bilgisini manav sevke tasimaz; satir sadece bilgilendirme/rapor icin kullanilir.
- `OrderLinkingEnabled=true` ise UI manav sevkte ayni satirin `lineGuid` degerini `warehouseOrderLineGuid` olarak gonderir ve gercek sevk miktarini okutulan KG/ADET olarak yollar.

## Sevk Islemleri

UI menu notu:

- `me.modules` altinda sevk menuleri giden/gelen olarak ayri gelir
- `GidenDepolarArasiSevkler` ve `GelenDepolarArasiSevkler` ayri menu gibi cizilmelidir
- `GidenFirmaSevkleri` ve `GelenFirmaSevkleri` ayri menu gibi cizilmelidir
- endpoint route'lari geriye uyum icin ayni kaldi; sadece permission/menu kodlari ayrildi

### Depolar Arasi Giden Sevkler Liste

`GET /api/sevk-islemleri/depolar-arasi-sevkler/giden?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-10`

Yetki:

- `sevk-islemleri.giden-depolar-arasi-sevkler.list`

Not:

- `WarehouseNo` verilmezse JWT icindeki depo bilgisi kullanilabilir
- tarih filtresi Mikro tarafinda `STOK_HAREKETLERI.sth_tarih` uzerinden yapilir
- sadece `sth_evraktip = 17` olan depolar arasi sevk hareketleri okunur
- giden sevklerde filtre `sth_cikis_depo_no = WarehouseNo` olarak uygulanir
- hedef depo nakliye durumuna gore `sth_giris_depo_no` veya `sth_nakliyedeposu` olarak cozulur
- performans icin liste sorgusu sadece `STOK_HAREKETLERI` belge basliklarini gruplayarak doner; depo siparisi baglantisi gibi satir bazli ek bilgiler detay endpointinden okunur
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

Geriye uyum icin su route da giden sevk listesi gibi calisir:

`GET /api/sevk-islemleri/depolar-arasi-sevkler?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-10`

### Depolar Arasi Gelen Sevkler Liste

`GET /api/sevk-islemleri/depolar-arasi-sevkler/gelen?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-10`

Yetki:

- `sevk-islemleri.gelen-depolar-arasi-sevkler.list`

Not:

- gelen sevklerde filtre `sth_nakliyedeposu = WarehouseNo OR sth_giris_depo_no = WarehouseNo` olarak uygulanir
- response modeli giden sevklerle aynidir

Liste satiri modeli:

```json
{
  "documentDate": "2026-04-01T00:00:00",
  "movementDate": "2026-04-01T00:00:00",
  "documentNo": "SVK-0001",
  "documentSerie": "F110",
  "documentOrderNo": 3694,
  "sourceWarehouseNo": 110,
  "sourceWarehouse": "KESTEL 1",
  "targetWarehouseNo": 50,
  "targetWarehouse": "MERKEZ DEPO",
  "shippingWarehouseNo": 0,
  "shippingState": 1,
  "plaque": "16 ABC 123",
  "driverNameSurname": "Ad Soyad",
  "driverTckn": "11111111111",
  "descriptionEttn": "",
  "warehouseOrderNo": "",
  "lineCount": 8,
  "totalQuantity": 250
}
```

UI kullanim notlari:

- Liste ekraninda `documentSerie`, `documentOrderNo`, `sourceWarehouse`, `targetWarehouse`, `shippingState`, `plaque`, `driverNameSurname`, `lineCount`, `totalQuantity` yeterlidir
- `shippingState = 1` ise sevk hedef depoya ulasmis kabul edilebilir; diger durumlar icin operasyonel isimlendirme UI tarafinda netlestirilebilir
- `warehouseOrderNo` liste response'unda performans nedeniyle bos gelebilir. Sevkin bagli oldugu depo siparisi gerekiyorsa detay endpointindeki `header.warehouseOrderNo`, `header.warehouseOrderNos` veya `items[].warehouseOrderNo` alanlari kullanilmalidir.
- Mal kabul satir eslestirmesi icin detay response icindeki `items[].movementGuid` kullanilmalidir; sadece stok kodu ile eslestirme ayni stoktan birden fazla satir oldugunda hatali olabilir
- Plaka, sofor adi ve sofor TCKN create ekraninda sorulmaz; kullanici bu bilgileri e-irsaliye gonderirken elle girer veya kayitli sofor listesinden secer.

### Depolar Arasi Giden Sevk Olustur

Siparissiz sevk:

`POST /api/sevk-islemleri/depolar-arasi-sevkler/giden`

Geriye uyum icin root route da ayni create gibi calisir:

`POST /api/sevk-islemleri/depolar-arasi-sevkler`

Yetki:

- `sevk-islemleri.giden-depolar-arasi-sevkler.create`

Onemli not:

- Yazma yolu `MikroWriteRouting:InterWarehouseShipment` ile secilir; mevcut config'te varsayilan deger `Database`tir.
- `Database` modunda EF Core uzerinden ayri `MikroWriteDbContext` ile yazma yapar. Write hedefi canli `MikroConnection` degil; `MikroWriteConnection` yoksa `testMikroConnection` kullanilir.
- `MikroApi` modunda `POST /Api/apiMethods/DahiliStokHareketKaydetV2` kullanilir ve olusan hareketler response/geri okuma ile mevcut response modeline cevrilir.
- `MikroApi` modunda otomatik depo siparisi gerekiyorsa once `POST /Api/apiMethods/DepolarArasiSiparisKaydetV2` ile siparis olusturulur, olusan `ssip_Guid` degerleri geri okunur ve sevk satirlarina `sth_subesip_uid` olarak eklenir. Bu yolun API-only kalmasi icin `MikroWriteRouting:IssuedWarehouseOrder` de `MikroApi` olmalidir; aksi halde backend hata dondurur.
- `STOK_HAREKETLERI` icin `sth_evraktip = 17`, `sth_tip = 2`, `sth_cins = 6` kullanilir.
- `sevk-islemleri.giden-depolar-arasi-sevkler.all-warehouses` yoksa `sourceWarehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. Bu yetki varsa baska kaynak depodan sevk olusturulacaksa body'de opsiyonel `sourceWarehouseNo` gonderilebilir.
- `targetWarehouseNo` UI'da secilen hedef depodur ve `sth_nakliyedeposu` alanina yazilir.
- `transitWarehouseNo` verilmezse `60` kullanilir ve `sth_giris_depo_no` alanina yazilir.
- `documentSerie` backend tarafinda `F{islemDepoNo}` olarak uretilir.
- `documentOrderNo` ayni seri ve `sth_evraktip = 17` icin write DB'deki maksimum sira okunarak uretilir.
- Backend ayni `documentSerie` icin sevk olusturma islemlerini SQL application lock ile siraya alir. Bu, terminalden pes pese kaydetme veya ayni anda birden fazla sevk olusturma durumunda sira numarasi/insert deadlock riskini azaltir.
- Backend son 5 dakika icinde ayni kaynak depo, hedef depo, transit depo, tarih ve birebir ayni satirlar ile olusmus bir sevk bulursa yeni evrak acmaz; mevcut evrakin `documentSerie` ve `documentOrderNo` bilgisini ayni response modeliyle dondurur. Bu alan response'ta ayrica isaretlenmez, UI ayni response'u basar.
- UI kaydet butonunu ilk tiklamadan sonra request bitene kadar disable etmeli ve timeout sonrasi ayni body tekrar gonderildiginde ayni evrak numarasinin donebilecegini kabul etmelidir. Timeout gorulse bile kullaniciya liste/detay yenileme secenegi verilmesi onerilir.
- Satirda `warehouseOrderLineGuid` verilirse depo siparis satirina baglanir. `MikroWriteRouting:InterWarehouseShipment=Database` modunda backend `STOK_HAREKETLERI_EK.sth_subesip_uid` linkini DB'de kurar; `MikroApi` modunda ayni GUID `DahiliStokHareketKaydetV2` satirina `sth_subesip_uid` olarak gonderilir ve link/teslim etkisi Mikro tarafina birakilir.
- `warehouseOrderLineGuid` verilmezse satir normalde siparissiz sevk olarak olusur; otomatik depo siparisi kurali devredeyse backend once Mikro API ile depo siparisi olusturup satiri bu yeni siparis GUID'ine baglar.
- Siparise bagli satirda stok kodu, kaynak depo, hedef depo ve kalan miktar kontrol edilir.
- Siparise bagli parcali sevkte UI satir miktarini `remainingQuantity` degerinden buyuk onermemeli ve gondermemelidir. Backend kalan miktari asan sevki reddeder; UI bunu kullanici hatasi gibi gosterip satir miktarini guncel kalan miktara cekmelidir.
- Siparise bagli sevk olusturulduktan sonra UI ilgili siparis detayini tekrar cagirip `deliveredQuantity`, `remainingQuantity` ve `isClosed` alanlarini yenilemelidir. Tum satirlarin `remainingQuantity <= 0` veya `isClosed = true` oldugu durumda siparis tekrar sevk secim listesine konmamalidir.
- Manav istisnasi: `sourceWarehouseNo = 56` ve stok model kodu `10`, `11`, `12` veya `23` ise `GreenGrocerProductCases:OrderLinkingEnabled=false` durumunda satirdaki `warehouseOrderLineGuid` yok sayilir, otomatik depo siparisi/linki uretilmez ve kalan siparis miktari kontrolu uygulanmaz. `OrderLinkingEnabled=true` ise UI'nin gonderdigi gercek siparis satiri GUID'i korunur, sevk siparise baglanir ve kalan/teslim miktari kontrolleri calisir. Bu satirlarda `quantity` gercek okutulan KG/ADET sevk miktaridir.
- Plaka, sofor adi ve TCKN bu create request'inde gonderilmez. E-irsaliye gonderiminde manuel akista bu alanlar zorunludur; kayitli sofor secilirse `driverId` yeterlidir.

Siparissiz request:

```json
{
  "clientRequestId": "2e8f99f1-8ad5-4dfb-a375-82b93f9aa101",
  "targetWarehouseNo": 50,
  "transitWarehouseNo": 60,
  "movementDate": "2026-04-17",
  "documentDate": "2026-04-17",
  "documentNo": "",
  "description": "",
  "lines": [
    {
      "stockCode": "015550",
      "quantity": 10,
      "unitPrice": 0,
      "unitPointer": 1,
      "description": "",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": ""
    }
  ]
}
```

Siparise bagli request:

```json
{
  "clientRequestId": "2e8f99f1-8ad5-4dfb-a375-82b93f9aa101",
  "targetWarehouseNo": 50,
  "transitWarehouseNo": 60,
  "movementDate": "2026-04-17",
  "documentDate": "2026-04-17",
  "lines": [
    {
      "warehouseOrderLineGuid": "8d4a5a77-1b3f-4f2a-93a1-b90a1b7d3c11",
      "stockCode": "015550",
      "quantity": 10,
      "unitPrice": 0,
      "unitPointer": 1
    }
  ]
}
```

Response:

```json
{
  "documentSerie": "F110",
  "documentOrderNo": 0,
  "movementDate": "2026-04-17T00:00:00",
  "documentDate": "2026-04-17T00:00:00",
  "documentNo": "",
  "sourceWarehouseNo": 110,
  "targetWarehouseNo": 50,
  "transitWarehouseNo": 60,
  "lineCount": 1,
  "linkedWarehouseOrderLineCount": 1,
  "totalQuantity": 10,
  "totalAmount": 0,
  "writeConnectionName": "testMikroConnection"
}
```

### Depolar Arasi Giden Sevk Detay

Seri + sira ile:

`GET /api/sevk-islemleri/depolar-arasi-sevkler/giden/F110/3694?warehouseNo=110`

Geriye uyum icin root route da giden detay gibi calisir:

`GET /api/sevk-islemleri/depolar-arasi-sevkler/F110/3694?warehouseNo=110`

Yetki:

- `sevk-islemleri.giden-depolar-arasi-sevkler.detail`

### Depolar Arasi Giden Sevk Guncelle

E-irsaliyesi henuz olusturulup gonderilmemis giden depolar arasi sevk evragini detay ekranindan gunceller.

`PUT /api/sevk-islemleri/depolar-arasi-sevkler/giden/F110/3694?warehouseNo=110`

Geriye uyum icin root route da ayni update gibi calisir:

`PUT /api/sevk-islemleri/depolar-arasi-sevkler/F110/3694?warehouseNo=110`

Yetki:

- `sevk-islemleri.giden-depolar-arasi-sevkler.update`

Onemli not:

- Bu endpoint sadece giden/kaynak depo tarafinda calisir; gelen depo mal kabul detayindan sevk evragi degistirilmez.
- `*.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kaynak depo kabul eder. Bu yetki varsa baska kaynak depo icin `warehouseNo` query parametresi gonderilebilir.
- Evrak e-irsaliye olarak gonderildiyse update reddedilir. Backend `sth_kilitli`, `sth_belge_no = FRM...` ve `sth_aciklama = UUID` izlerini kontrol eder.
- Evrak alici depo tarafindan kabul edildiyse (`sth_nakliyedurumu = 1`) update reddedilir.
- Satir aksiyonu `lines[].action` ile belirlenir: `update`, `add`, `delete`. Bos/null gonderilirse geriye uyum icin `update` kabul edilir.
- `update` ve `delete` aksiyonlarinda satir eslestirmesi zorunlu olarak `movementGuid` ile yapilir; stok kodu tek basina kullanilmaz.
- `add` aksiyonunda `movementGuid` gonderilmez; `stockCode` ve `quantity` zorunludur. `rowNo` bos birakilirsa backend mevcut evraktaki son satirdan sonra yeni satir no verir.
- `delete` aksiyonu satiri fiziksel olarak siler. Satira bagli `STOK_HAREKETLERI_EK` kaydi varsa o da silinir.
- `quantity` alani `sth_miktar` degerini degistirir. `unitPrice` gonderilip `amount` bos birakilirsa backend `sth_tutar = quantity * unitPrice` hesaplar. `amount` gonderilirse tutar aynen kullanilir.
- Siparise bagli sevkte miktar degisirse backend bagli depo siparis satirinin `ssip_teslim_miktar` alanini delta kadar gunceller; siparis miktarini asan update reddedilir. Siparise bagli satir silinirse teslim miktari silinen sevk miktari kadar geri dusurulur.

Request:

```json
{
  "movementDate": "2026-04-17",
  "documentDate": "2026-04-17",
  "targetWarehouseNo": 50,
  "transitWarehouseNo": 60,
  "description": "Sevk duzeltildi",
  "lines": [
    {
      "action": "update",
      "movementGuid": "8d4a5a77-1b3f-4f2a-93a1-b90a1b7d3c11",
      "quantity": 8,
      "unitPrice": 12.5,
      "unitPointer": 1,
      "description": "Miktar duzeltildi"
    },
    {
      "action": "add",
      "stockCode": "015550",
      "quantity": 3,
      "unitPrice": 12.5,
      "unitPointer": 1,
      "description": "Yeni satir"
    },
    {
      "action": "delete",
      "movementGuid": "03d6df6a-b1b2-4923-b8f0-28060446e61f"
    }
  ]
}
```

Response:

```json
{
  "documentSerie": "F110",
  "documentOrderNo": 3694,
  "sourceWarehouseNo": 110,
  "targetWarehouseNo": 50,
  "transitWarehouseNo": 60,
  "isReturn": false,
  "updatedLineCount": 3,
  "addedLineCount": 1,
  "deletedLineCount": 1,
  "lineCount": 2,
  "totalQuantity": 11,
  "totalAmount": 137.5,
  "updatedAt": "2026-08-13T14:30:00",
  "updateUser": 110,
  "writeConnectionName": "testMikroConnection"
}
```

### Depolar Arasi Giden Sevki E-Irsaliyeye Cevir

Detay ekranindaki mevcut evragi e-irsaliye olarak gondermek icin:

`POST /api/sevk-islemleri/depolar-arasi-sevkler/giden/F110/3694/e-irsaliye?warehouseNo=110`

Geriye uyum icin root route da ayni islem gibi calisir:

`POST /api/sevk-islemleri/depolar-arasi-sevkler/F110/3694/e-irsaliye?warehouseNo=110`

Yetki:

- `sevk-islemleri.giden-depolar-arasi-sevkler.detail`

Onemli not:

- Bu endpoint yeni evrak kesmez; mevcut sevk kaydini okuyup Uyumsoft e-irsaliye servisine yollar.
- UI tarafinda beklenen akis: kullanici once detay ekranini acar, sonra `E-Irsaliyeye Cevir` butonuna basar ve acilan formda plaka/sofor/TCKN bilgisini elle girer veya kayitli sofor listesinden secer.
- `warehouseNo` verilmezse JWT icindeki kullanici deposu kullanilir.
- Body zorunludur; seri ve sira bilgisi URL'den, tasima bilgileri body'den alinir.
- Basarili gonderimden sonra ilgili Mikro satirlari kilitlenmeye calisilir; bu yerel guncelleme basarisiz olsa bile servis gonderimi basariliysa response doner.

Request:

```json
{
  "plaque": "16 ABC 123",
  "driverNameSurname": "Ad Soyad",
  "driverTckn": "11111111111"
}
```

### Depolar Arasi Giden Sevk E-Irsaliye PDF Goster

Detay ekraninda daha once gonderilmis e-irsaliyenin PDF'ini acmak icin:

`GET /api/sevk-islemleri/depolar-arasi-sevkler/giden/F110/3694/e-irsaliye/pdf?warehouseNo=110`

Geriye uyum icin root route da ayni islem gibi calisir:

`GET /api/sevk-islemleri/depolar-arasi-sevkler/F110/3694/e-irsaliye/pdf?warehouseNo=110`

Yetki:

- `sevk-islemleri.giden-depolar-arasi-sevkler.detail`

Onemli not:

- Bu endpoint `application/pdf` binary response doner; JSON beklenmemelidir.
- Response `inline` olarak doner; UI isterse yeni sekmede, isterse iframe/pdf viewer icinde acabilir.
- Request body yoktur; seri ve sira bilgisi URL'den alinir.
- `warehouseNo` verilmezse JWT icindeki kullanici deposu kullanilir.
- Evrak henuz e-irsaliye olarak gonderilmediyse endpoint `409 Conflict` doner.

### Depolar Arasi Gelen Sevk Detay

Seri + sira ile:

`GET /api/sevk-islemleri/depolar-arasi-sevkler/gelen/F50/185640?warehouseNo=110`

Yetki:

- `sevk-islemleri.gelen-depolar-arasi-sevkler.detail`

### Depolar Arasi Sevk Detay Response

```json
{
  "header": {
    "documentDate": "2026-04-01T00:00:00",
    "movementDate": "2026-04-01T00:00:00",
    "documentNo": "SVK-0001",
    "documentSerie": "F110",
    "documentOrderNo": 3694,
    "sourceWarehouseNo": 110,
    "sourceWarehouse": "KESTEL 1",
    "targetWarehouseNo": 50,
    "targetWarehouse": "MERKEZ DEPO",
    "shippingWarehouseNo": 0,
    "shippingState": 1,
    "plaque": "16 ABC 123",
    "driverNameSurname": "Ad Soyad",
    "driverTckn": "11111111111",
    "descriptionEttn": "",
    "warehouseOrderNo": "D110.1915",
    "warehouseOrderNos": ["D110.1915"],
    "lineCount": 8,
    "totalQuantity": 250,
    "totalAmount": 12500
  },
  "items": [
    {
      "movementGuid": "8d4a5a77-1b3f-4f2a-93a1-b90a1b7d3c11",
      "lineNo": 0,
      "stockCode": "015792",
      "stockName": "Stok Adi",
      "unitName": "AD",
      "unitPointer": 1,
      "quantity": 10,
      "unitPrice": 125,
      "lineAmount": 1250,
      "description": "",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": "",
      "warehouseOrderNo": "D110.1915"
    }
  ]
}
```

### Firma Giden Sevkleri Liste

`GET /api/sevk-islemleri/firma-sevkleri/giden?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-10`

Geriye uyum icin su route da giden firma sevk listesi gibi calisir:

`GET /api/sevk-islemleri/firma-sevkleri?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-10`

Yetki:

- `sevk-islemleri.giden-firma-sevkleri.list`

Not:

- `WarehouseNo` verilmezse JWT icindeki depo bilgisi kullanilabilir
- tarih filtresi Mikro tarafinda `STOK_HAREKETLERI.sth_belge_tarih` uzerinden yapilir
- eski mantiktaki `DocumentType = 1`, `MovementType = 1`, `IsReturn = 0`, `OutputWarehouseNo = WarehouseNo` filtresinin karsiligidir
- Mikro kolon karsiliklari: `sth_evraktip = 1`, `sth_tip = 1`, `sth_normal_iade = 0`, `sth_cikis_depo_no = WarehouseNo`
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

### Firma Gelen Sevkleri Liste

`GET /api/sevk-islemleri/firma-sevkleri/gelen?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-10`

Yetki:

- `sevk-islemleri.gelen-firma-sevkleri.list`

Not:

- tarih filtresi Mikro tarafinda `STOK_HAREKETLERI.sth_create_date` uzerinden yapilir
- eski mantiktaki `DocumentType = 13`, `MovementType = 0`, `IsReturn = 0`, `InputWarehouseNo = WarehouseNo` filtresinin karsiligidir
- Mikro kolon karsiliklari: `sth_evraktip = 13`, `sth_tip = 0`, `sth_normal_iade = 0`, `sth_giris_depo_no = WarehouseNo`
- response modeli giden firma sevkleriyle aynidir
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

Firma sevkleri liste satiri modeli:

```json
{
  "documentDate": "2026-04-01T00:00:00",
  "movementCreateDate": "2026-04-01T09:15:00",
  "movementDate": "2026-04-01T00:00:00",
  "documentNo": "IRS-0001",
  "documentSerie": "F110",
  "documentOrderNo": 1250,
  "customerCode": "120.01.001",
  "customerName": "Cari Adi",
  "customerTitle": "Cari Unvani",
  "customerDisplayName": "Cari Adi Cari Unvani",
  "warehouseNo": 110,
  "warehouseName": "KESTEL 1",
  "inputWarehouseNo": 110,
  "inputWarehouseName": "KESTEL 1",
  "outputWarehouseNo": 50,
  "outputWarehouseName": "MERKEZ DEPO",
  "documentType": 13,
  "movementType": 0,
  "returnType": 0,
  "description": "",
  "lineCount": 8,
  "totalQuantity": 250,
  "totalAmount": 12500
}
```

### Firma Giden Sevk Olustur

`POST /api/sevk-islemleri/firma-sevkleri/giden`

Geriye uyum icin su route da giden firma sevk create gibi calisir:

`POST /api/sevk-islemleri/firma-sevkleri`

Yetki:

- `sevk-islemleri.giden-firma-sevkleri.create`

Onemli not:

- Yazma yolu `MikroWriteRouting:CompanyMovement` ile belirlenir; mevcut config'te varsayilan deger `Database`tir.
- `Database` modunda EF Core uzerinden ayri `MikroWriteDbContext` ile `STOK_HAREKETLERI` yazilir.
- `MikroApi` modunda `POST /Api/apiMethods/IrsaliyeKaydetV2` kullanilir ve olusan hareketler response/geri okuma ile mevcut response modeline cevrilir.
- Firma giden sevki hareketi `sth_evraktip = 1`, `sth_tip = 1`, `sth_cins = 0`, `sth_normal_iade = 0` olarak olusur.
- `*.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. Ilgili sevk menusunde `all-warehouses` yetkisi olan kullanici baska depo adina sevk olusturacaksa body'de opsiyonel `warehouseNo` gonderebilir.
- `customerCode` zorunludur ve write DB'de `CARI_HESAPLAR` icinde kontrol edilir.
- `documentSerie` backend tarafinda `F{islemDepoNo}` olarak uretilir.
- `documentOrderNo` ayni seri, evrak tipi ve iade tipi icin write DB'deki mevcut maksimum sira okunarak uretilir; ilk evrak `0`, sonraki evraklar `1, 2...` seklinde gider.
- Plaka, sofor adi ve TCKN bu create request'inde gonderilmez. E-irsaliye gonderiminde manuel akista bu alanlar zorunludur; kayitli sofor secilirse `driverId` yeterlidir.
- Satir bazinda `unitPrice` verilirse `totalAmount` `quantity * unitPrice` toplamindan olusur; verilmezse `0` olur.
- Satirda `orderLineGuid` verilirse hareket ilgili alinan firma siparis satirina baglanir. `Database` modunda `STOK_HAREKETLERI.sth_sip_uid` alanina yazilir; `MikroApi` modunda ayni GUID `IrsaliyeKaydetV2` payloadinda `sth_sip_uid` olarak gonderilir.

Request:

```json
{
  "clientRequestId": "5b0b7e62-3514-43b6-a776-220853ef2c3f",
  "customerCode": "120.01.001",
  "movementDate": "2026-04-17",
  "documentDate": "2026-04-17",
  "documentNo": "IRS-0001",
  "description": "",
  "lines": [
    {
      "stockCode": "015792",
      "quantity": 10,
      "unitPrice": 125,
      "unitPointer": 1,
      "description": "",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": "",
      "customerResponsibilityCenter": "",
      "productResponsibilityCenter": "",
      "orderLineGuid": "0f4db720-3374-4f80-ae21-6f7d2edec8b1"
    }
  ]
}
```

Response:

```json
{
  "documentSerie": "F110",
  "documentOrderNo": 0,
  "movementDate": "2026-04-17T00:00:00",
  "documentDate": "2026-04-17T00:00:00",
  "documentNo": "IRS-0001",
  "warehouseNo": 110,
  "customerCode": "120.01.001",
  "lineCount": 1,
  "totalQuantity": 10,
  "totalAmount": 1250,
  "writeConnectionName": "testMikroConnection"
}
```

### Firma Giden Sevk Detay

Seri + sira ile:

`GET /api/sevk-islemleri/firma-sevkleri/giden/PS110/422?warehouseNo=110`

Geriye uyum icin root route da giden firma sevk detayi gibi calisir:

`GET /api/sevk-islemleri/firma-sevkleri/PS110/422?warehouseNo=110`

Yetki:

- `sevk-islemleri.giden-firma-sevkleri.detail`

### Firma Giden Sevki E-Irsaliyeye Cevir

Detay ekranindaki mevcut evragi e-irsaliye olarak gondermek icin:

`POST /api/sevk-islemleri/firma-sevkleri/giden/PS110/422/e-irsaliye?warehouseNo=110`

Geriye uyum icin root route da ayni islem gibi calisir:

`POST /api/sevk-islemleri/firma-sevkleri/PS110/422/e-irsaliye?warehouseNo=110`

Yetki:

- `sevk-islemleri.giden-firma-sevkleri.detail`

Onemli not:

- Bu endpoint yeni sevk kaydi olusturmaz; secili firma sevk evragini okuyup Uyumsoft e-irsaliye servisine gonderir.
- Body zorunludur; seri ve sira bilgisi URL'den, tasima bilgileri body'den alinir.
- `warehouseNo` verilmezse JWT icindeki kullanici deposu kullanilir.
- Musteri vergi numarasi, e-irsaliye alias'i ve adres bilgileri Mikro cari kaydindan okunur.
- Plaka, sofor adi soyadi ve sofor TCKN body'deki `driverId` veya manuel alanlardan cozulur; basarili gonderimden sonra bu bilgiler ilgili Mikro hareket satirlarina yazilmaya calisilir.

Request:

```json
{
  "plaque": "16 ABC 123",
  "driverNameSurname": "Ad Soyad",
  "driverTckn": "11111111111"
}
```

### Firma Giden Sevk E-Irsaliye PDF Goster

Detay ekraninda daha once gonderilmis e-irsaliyenin PDF'ini acmak icin:

`GET /api/sevk-islemleri/firma-sevkleri/giden/PS110/422/e-irsaliye/pdf?warehouseNo=110`

Geriye uyum icin root route da ayni islem gibi calisir:

`GET /api/sevk-islemleri/firma-sevkleri/PS110/422/e-irsaliye/pdf?warehouseNo=110`

Yetki:

- `sevk-islemleri.giden-firma-sevkleri.detail`

Onemli not:

- Bu endpoint `application/pdf` binary response doner; JSON beklenmemelidir.
- Response `inline` olarak doner; UI isterse yeni sekmede, isterse iframe/pdf viewer icinde acabilir.
- Request body yoktur; seri ve sira bilgisi URL'den alinir.
- `warehouseNo` verilmezse JWT icindeki kullanici deposu kullanilir.
- Evrak henuz e-irsaliye olarak gonderilmediyse endpoint `409 Conflict` doner.

### Firma Gelen Sevk Detay

Seri + sira ile:

`GET /api/sevk-islemleri/firma-sevkleri/gelen/BG/1665?warehouseNo=110`

Yetki:

- `sevk-islemleri.gelen-firma-sevkleri.detail`

### Firma Sevk Detay Response

```json
{
  "header": {
    "documentDate": "2026-04-01T00:00:00",
    "movementCreateDate": "2026-04-01T09:15:00",
    "movementDate": "2026-04-01T00:00:00",
    "documentNo": "IRS-0001",
    "documentSerie": "F110",
    "documentOrderNo": 1250,
    "customerCode": "120.01.001",
    "customerName": "Cari Adi",
    "customerTitle": "Cari Unvani",
    "customerDisplayName": "Cari Adi Cari Unvani",
    "customerAddress": "Cadde Mahalle Sokak Ilce Il",
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "inputWarehouseNo": 110,
    "inputWarehouseName": "KESTEL 1",
    "outputWarehouseNo": 50,
    "outputWarehouseName": "MERKEZ DEPO",
    "documentType": 13,
    "movementType": 0,
    "returnType": 0,
    "description": "",
    "lineCount": 8,
    "totalQuantity": 250,
    "totalAmount": 12500
  },
  "items": [
    {
      "lineNo": 0,
      "stockCode": "015792",
      "stockName": "Stok Adi",
      "unitName": "AD",
      "unitPointer": 1,
      "quantity": 10,
      "secondaryQuantity": 0,
      "unitPrice": 125,
      "lineAmount": 1250,
      "discountAmount": 0,
      "expenseAmount": 0,
      "taxAmount": 250,
      "netWeight": 0,
      "grossWeight": 0,
      "description": "",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": "",
      "orderGuid": null
    }
  ]
}
```

## Mal Kabul Islemleri

### Depo Mal Kabulleri Liste

Bekleyen gelen depo sevklerini ve gelen depo iadelerini mal kabul ekranina kaynak olmak uzere listeler.

`GET /api/mal-kabul-islemleri/depo-mal-kabulleri?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-30`

Yetki:

- `mal-kabul-islemleri.depo-mal-kabulleri.list`

Onemli not:

- Bu endpoint sadece bekleyen mal kabul evraklarini doner.
- Filtre mantigi `sth_evraktip = 17`, `sth_normal_iade = 0 veya 1`, `sth_nakliyedeposu = WarehouseNo`, `sth_nakliyedurumu != 1` seklindedir.
- Response modeli `WarehouseShippingListItemDto` ile aynidir.
- `isReturn = false` normal gelen depo sevkini, `isReturn = true` gelen depo iadesini ifade eder.
- UI bu listeyi "evragi sec ve create'e tasin" akisi icin kullanabilir.

### Depo Mal Kabulleri Detay

Secilen bekleyen gelen sevk veya gelen depo iadesi kalemlerini mal kabul create ekranina tasimak icin kullanilir.

`GET /api/mal-kabul-islemleri/depo-mal-kabulleri/F110/3694?warehouseNo=110`

Alias:

`GET /api/mal-kabul-islemleri/mal-kabuller/depo-sevkleri/F110/3694?warehouseNo=110`

Yetki:

- `mal-kabul-islemleri.depo-mal-kabulleri.detail`

Onemli not:

- Kullanici listedeki satira tikladiginda veya ustten seri/sira girerek devam ettiginde ayni endpoint cagrilabilir.
- Sadece bekleyen evraklar doner; daha once kabul edilmis bir sevk/iade icin `404` doner.
- Response modeli `WarehouseShippingDetailDto` ile aynidir.
- `header.isReturn = false` normal gelen depo sevkini, `header.isReturn = true` gelen depo iadesini ifade eder.
- UI `items[].movementGuid` alanini kabul request'ine tasimalidir.

### Depo Mal Kabul Icin E-Irsaliye ETTN Cozumleme

Kullanici gelen irsaliyenin QR bilgisinden ETTN/UUID elde ettiyse Uyumsoft gelen kutusundan resmi ust bilgi ve kalemleri cekmek icin:

`GET /api/mal-kabul-islemleri/depo-mal-kabulleri/e-irsaliye/ettn/3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111?warehouseNo=110`

Yetki:

- `mal-kabul-islemleri.depo-mal-kabulleri.update`

Onemli not:

- Bu endpoint yeni depo mal kabul evragi olusturmaz; sadece Uyumsoft gelen e-irsaliye bilgisini okur.
- Uyumsoft tarafinda `GetInboxDespatches` operasyonu kullanilir ve ETTN exact `despatchId` olarak sorgulanir.
- `isFound = false` ise Uyumsoft'ta bu ETTN ile gelen irsaliye bulunamamistir.
- Kalemlerde ic stok eslesmesi sirasiyla `buyerItemCode`, `sellerItemCode`, `manufacturerItemCode`, `barcode`, `gtin` mantigiyla denenir.
- `isMatched = true` ve `canUseForGoodsAcceptance = true` olan satirlar UI'da yesil veya hazir eslesmis gibi gosterilebilir.
- `isGoodsAcceptanceBlocked = true` ise urun resmi irsaliyede olsa bile mal kabulde bloklu demektir.
- Depo akisi icin bu endpoint daha cok resmi belgeyi mevcut bekleyen depo sevki ile karsilastirmak ve farklari onceden gormek amaciyla dusunulmelidir.

Response:

```json
{
  "isFound": true,
  "warehouseNo": 110,
  "receivingContext": "depo-mal-kabulleri",
  "ettn": "3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111",
  "despatchNumber": "IRS2026000001234",
  "issueDate": "2026-05-06T00:00:00",
  "actualDespatchDate": "2026-05-06T00:00:00",
  "actualDespatchTime": "08:00:00",
  "plaque": "34 HTE 490_BRS",
  "driverNameSurname": "ORHAN BAYRAM",
  "driverTckn": "49216016986",
  "profileId": "TEMELIRSALIYE",
  "despatchAdviceTypeCode": "SEVK",
  "notes": [
    "Depo kabul kontrolu icin okutuldu."
  ],
  "sender": {
    "title": "MERKEZ DEPO",
    "taxNoOrTckn": "1234567890",
    "alias": "urn:mail:merkez@firma.com",
    "city": "BURSA"
  },
  "receiver": {
    "title": "KESTEL 1",
    "taxNoOrTckn": "0987654321",
    "alias": "urn:mail:kestel1@firma.com",
    "city": "BURSA"
  },
  "primaryCustomerSuggestion": null,
  "totalLineCount": 2,
  "matchedLineCount": 2,
  "unmatchedLineCount": 0,
  "suggestedCustomers": [],
  "lines": [
    {
      "lineNo": 1,
      "productName": "Stok Adi",
      "description": "Koli sevk",
      "quantity": 12,
      "unitCode": "C62",
      "buyerItemCode": "015792",
      "sellerItemCode": "015792",
      "manufacturerItemCode": null,
      "barcode": "8690000000000",
      "internalStockCode": "015792",
      "internalStockName": "Stok Adi",
      "matchReason": "buyer-item-code",
      "isMatched": true,
      "isGoodsAcceptanceBlocked": false,
      "canUseForGoodsAcceptance": true
    }
  ]
}
```

### Depo Sevki veya Iadesi Mal Kabul Et

Gelen depolar arasi sevk veya gelen depo iadesi detayinda sayim/kabul yapildiktan sonra mevcut `STOK_HAREKETLERI` satirlarini teslim alinmis duruma getirir.

`POST /api/mal-kabul-islemleri/depo-mal-kabulleri/F110/3694/kabul`

Alias:

`POST /api/mal-kabul-islemleri/mal-kabuller/depo-sevkleri/F110/3694/kabul`

Yetki:

- `mal-kabul-islemleri.depo-mal-kabulleri.update`

Onemli not:

- Bu endpoint yeni ana stok hareketi olusturmaz; gonderen deponun olusturdugu mevcut `sth_evraktip = 17`, `sth_normal_iade = 0 veya 1` satirlarini gunceller.
- `isReturn = false` normal gelen depo sevkini, `isReturn = true` gelen depo iadesini ifade eder.
- `*.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. `mal-kabul-islemleri.depo-mal-kabulleri.all-warehouses` yetkisi olan kullanici baska depo icin kabul yapacaksa body'de opsiyonel `warehouseNo` gonderebilir.
- Bekleyen kabul icin hareketlerde `sth_nakliyedeposu = kullaniciDeposu` ve `sth_nakliyedurumu != 1` olmalidir.
- Kabul icin gonderen taraf e-irsaliyesi zorunludur. Backend `sth_kilitli = true`, `sth_belge_no` degerinin `FRM` ile baslamasi ve `sth_aciklama` degerinin UUID olmasi izlerini kontrol eder; bu iz yoksa kabul islemi reddedilir. UI kabul aksiyonunu e-irsaliye gonderilmeden aktif etmemelidir.
- `sth_miktar` degistirilmez; resmi sevk/e-irsaliye miktari olarak korunur.
- UI'dan gelen sayilan miktar `sth_FormulMiktar` alanina yazilir.
- Kabulde depo swap yapilir: `sth_giris_depo_no = kullaniciDeposu`, `sth_nakliyedeposu = eski sth_giris_depo_no` ve `sth_nakliyedurumu = 1`.
- Ayni evrak ikinci kez kabul edilirse `409 Conflict` doner.
- Satir eslestirmesi `movementGuid` ile yapilmalidir; bu deger depolar arasi sevk detay response'undaki `items[].movementGuid` alanidir.
- Eksik/fazla varsa ve `allowDiscrepancy = false` ise endpoint `409 Conflict` doner.
- Eksik/fazla varsa ve `allowDiscrepancy = true` ise hareket kabul edilir, `differenceResolutionStatus = "recorded-on-formula-quantity"` doner. Canli Mikro pratigine uygun olarak fark `sth_FormulMiktar` uzerinde izlenir; otomatik iade/fire/stok duzeltme hareketi olusturulmaz.

Request:

```json
{
  "allowDiscrepancy": false,
  "lines": [
    {
      "movementGuid": "8d4a5a77-1b3f-4f2a-93a1-b90a1b7d3c11",
      "receivedQuantity": 10
    }
  ]
}
```

Response:

```json
{
  "documentSerie": "F110",
  "documentOrderNo": 3694,
  "warehouseNo": 110,
  "sourceWarehouseNo": 50,
  "transitWarehouseNo": 60,
  "shippingState": 1,
  "isReturn": false,
  "lineCount": 1,
  "totalShippedQuantity": 10,
  "totalReceivedQuantity": 8,
  "totalMissingQuantity": 2,
  "totalExcessQuantity": 0,
  "hasDiscrepancy": true,
  "differenceResolutionStatus": "recorded-on-formula-quantity",
  "writeConnectionName": "testMikroConnection",
  "lines": [
    {
      "movementGuid": "8d4a5a77-1b3f-4f2a-93a1-b90a1b7d3c11",
      "lineNo": 0,
      "stockCode": "015792",
      "shippedQuantity": 10,
      "receivedQuantity": 8,
      "differenceQuantity": -2,
      "differenceType": "missing"
    }
  ]
}
```

Eksik/fazla anlamlari:

- `differenceType = "none"`: `receivedQuantity` ile `sth_miktar` aynidir.
- `differenceType = "missing"`: sayilan miktar sevk miktarindan azdir; fark `sth_FormulMiktar` uzerinde kayit altina alinmistir.
- `differenceType = "excess"`: sayilan miktar sevk miktarindan fazladir; fark `sth_FormulMiktar` uzerinde kayit altina alinmistir.

Depo mal kabul UI akisi:

- Ekran bos fis acmaz; ana ekran bekleyen gelen depo sevklerini ve gelen depo iadelerini listeler. Liste icin tarih araligi ve depo filtresiyle `GET /api/mal-kabul-islemleri/depo-mal-kabulleri` cagrilir.
- Kullanici isterse fiziksel irsaliyenin QR bilgisinden aldigi ETTN ile `GET /api/mal-kabul-islemleri/depo-mal-kabulleri/e-irsaliye/ettn/{ettn}` cagirip resmi e-irsaliye ust bilgisi ve kalemlerini yan panelde gorebilir.
- Liste satirinda kullaniciya seri/sira, gonderen depo, hedef depo, sevk/iade tipi, sevk durumu, depo siparis no, satir sayisi ve toplam miktar gosterilir.
- Kullanici satira tikladiginda detay acilir ve `GET /api/mal-kabul-islemleri/depo-mal-kabulleri/{seri}/{sira}` cagrilir.
- ETTN sonucu ile bekleyen sevk detayi birlikte acik gosteriliyorsa UI satir bazinda miktar ve urun eslesme farklarini highlight etmelidir.
- Detayda her satir icin stok kodu, stok adi, sevk miktari, birim, parti/lot ve aciklama gosterilir. `items[].movementGuid` UI icinde saklanir; kabul request'i bu guid ile yapilir.
- UI her satirda `receivedQuantity` input'u acar ve varsayilan olarak sevk miktarini yazar. Kullanici sayim sonucuna gore bu miktari azaltabilir veya artirabilir.
- UI satir bazinda farki anlik hesaplar: sayilan miktar sevk miktarina esitse `none`, azsa `missing`, fazlaysa `excess` olarak gosterir.
- Fark yoksa `allowDiscrepancy = false` ile direkt kabul gonderilebilir.
- Fark varsa UI once uyari verir. Kullanici farkli kabul etmeyi onaylamadan `allowDiscrepancy = true` gonderilmemelidir.
- Kaydet butonu `POST /api/mal-kabul-islemleri/depo-mal-kabulleri/{seri}/{sira}/kabul` endpoint'ine gider.
- Basarili response geldikten sonra evrak bekleyen listesinden dusurulur veya detayda "Kabul edildi" durumuna alinip kullaniciya toplam sevk, toplam kabul, eksik ve fazla miktarlari gosterilir.
- `409 Conflict` gelirse UI bunu "evrak daha once kabul edilmis olabilir" veya "fark onayi gerekiyor" mesaji olarak gostermelidir.
- Bu ekran plaka, sofor ve TCKN istemez; bu bilgiler sevk/iade e-irsaliyesi gonderilirken ayrica girilir.

### Mal Kabul Farklari

Kabul edilmis depo sevki veya depo iadesi satirlarinda `sth_miktar` ile `sth_FormulMiktar` farki olan kalemleri listeler.

`GET /api/mal-kabul-islemleri/mal-kabul-farklari?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-30&scope=accepted`

Alias:

```text
GET /api/mal-kabul-islemleri/mal-kabul-farklari/accepted?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-30
GET /api/mal-kabul-islemleri/mal-kabul-farklari/created?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-30
GET /api/mal-kabul-islemleri/mal-kabul-farklari/kabul-ettigim?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-30
GET /api/mal-kabul-islemleri/mal-kabul-farklari/olusturdugum?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-30
```

Yetki:

- `mal-kabul-islemleri.mal-kabul-farklari.list`

Query:

```text
WarehouseNo  opsiyonel; verilmezse JWT icindeki depo kullanilir
StartDate    zorunlu
EndDate      zorunlu
scope        opsiyonel; accepted veya created
```

Scope anlamlari:

- `accepted`: deponun kendi mal kabul yaptigi evraklar. Filtre `sth_giris_depo_no = WarehouseNo`.
- `created`: deponun kendi olusturdugu/gonderdigi evraklar. Filtre `sth_cikis_depo_no = WarehouseNo`.

Onemli not:

- Sadece kabul edilmis satirlar doner: `sth_evraktip = 17`, `sth_nakliyedurumu = 1`.
- Normal sevk ve depo iadesi beraber gelir; `isReturn` alanina gore UI rozet basabilir.
- Fark mantigi `differenceQuantity = receivedQuantity - quantity` seklindedir.
- `differenceType = "missing"` eksik, `"excess"` fazla kabul anlamina gelir.

Response:

```json
[
  {
    "documentDate": "2026-04-10T00:00:00",
    "movementDate": "2026-04-10T00:00:00",
    "documentNo": "FRM2026600065140",
    "documentSerie": "F50",
    "documentOrderNo": 192188,
    "lineNo": 28,
    "movementGuid": "8d4a5a77-1b3f-4f2a-93a1-b90a1b7d3c11",
    "isReturn": false,
    "sourceWarehouseNo": 50,
    "sourceWarehouse": "PANAYIR PREMIUM",
    "targetWarehouseNo": 135,
    "targetWarehouse": "ALICI DEPO",
    "productCode": "019042",
    "productName": "COOK EKO BUYUK BUZDOLABI POS.30x42CM 80 YAP.*15",
    "unitName": "ADET",
    "unitPointer": 1,
    "quantity": 45,
    "receivedQuantity": 25,
    "differenceQuantity": -20,
    "differenceType": "missing",
    "description": ""
  }
]
```

### Firma Mal Kabulleri Liste

Daha once yapilmis firma mal kabul fislerini listeler.

`GET /api/mal-kabul-islemleri/firma-mal-kabulleri?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-30`

Yetki:

- `mal-kabul-islemleri.firma-mal-kabulleri.list`

Onemli not:

- Bu liste yeni create kaynagi degil, mevcut yapilmis mal kabul fislerinin gecmis listesidir.
- Firma mal kabul liste tarih filtresi `documentDate` alanina, Mikro tarafinda `STOK_HAREKETLERI.sth_belge_tarih` kolonuna uygulanir; `movementCreateDate` filtre alani degildir.
- Response modeli `CompanyMovementListItemDto` ile aynidir.
- UI ana ekranda gecmisi gosterip `Yeni Mal Kabul` aksiyonuyla create ekranina gecebilir.

### Firma Mal Kabul Detay

Yapilmis firma mal kabul fisinin header ve kalem detayini getirir.

`GET /api/mal-kabul-islemleri/firma-mal-kabulleri/ST12026/2395?warehouseNo=110`

Yetki:

- `mal-kabul-islemleri.firma-mal-kabulleri.detail`

Onemli not:

- Response modeli `CompanyMovementDetailDto` ile aynidir.
- Bu endpoint create kaynagi degil, yapilmis fis detayini gostermek icindir.

### Firma Mal Kabul Icin E-Belge ETTN/UUID Cozumleme

Kullanici tedarikci belgesinin QR bilgisinden ETTN/UUID elde ettiyse resmi ust bilgi, kalemler ve olasi cari eslesmelerini almak icin:

`GET /api/mal-kabul-islemleri/firma-mal-kabulleri/resmi-belge/ettn/3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111?warehouseNo=110&documentKind=auto`

Geriye uyumlu eski alias:

`GET /api/mal-kabul-islemleri/firma-mal-kabulleri/e-irsaliye/ettn/3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111?warehouseNo=110`

Request/query:

- `warehouseNo`: opsiyonel. `*.all-warehouses` yoksa UI gondermez; backend token deposunu kullanir.
- `documentKind`: opsiyonel. `auto`, `e-despatch` veya `e-invoice` gonderilebilir. Bos/eksik ise `auto` kabul edilir.
- `auto`: backend once Uyumsoft gelen e-irsaliye kutusunda `GetInboxDespatches` ile arar; bulunamazsa Uyumsoft gelen e-fatura tarafinda once `GetInboxInvoice`, sonra `GetInboxInvoices` ile UUID/fatura no adaylarini dener.
- Eski `/e-irsaliye/ettn/{ettn}` alias'i da artik `auto` davranir; terminal eski endpoint'i cagirmaya devam etse bile e-fatura bulunabilir.

Yetki:

- `mal-kabul-islemleri.firma-mal-kabulleri.create`

Onemli not:

- Bu endpoint create request'i yerine gecmez; sadece create ekranina on bilgi ve on dolum verir.
- `sourceDocumentKind` belge turunu soyler: `e-despatch`, `e-invoice` veya bulunamadiysa `auto`.
- `sourceDocumentLabel` UI etiketi icindir: `E-Irsaliye`, `E-Fatura` veya `E-Belge`.
- `sourceDocumentNumber` resmi belge numarasidir. Geriye uyumluluk icin `despatchNumber` alani da kaynak belge numarasini tasir; e-fatura bulundugunda burada fatura no gelir.
- E-irsaliye icin baslik bilgileri `sender`, `receiver`, `despatchNumber`, `issueDate`, `actualDespatchDate`, `actualDespatchTime`, `plaque`, `driverNameSurname`, `driverTckn`, `notes` alanlarinda toplanir.
- E-fatura icin `invoiceNumber`, `invoiceDate`, `invoiceTotal`, `taxExclusiveAmount`, `taxTotal`, `currencyCode` ve varsa `despatchReferences` ayrica dolar. `despatchAdviceTypeCode` alani geriye uyumluluk icin e-faturada `InvoiceTypeCode` degerini tasir.
- `suggestedCustomers` alani gonderici firma VKN/TCKN ve unvanina gore Mikro cari adaylari dondurur.
- `primaryCustomerSuggestion` alanini UI varsayilan cari adayi gibi kullanabilir.
- Kalemlerde stok kodlari birebir tutusmasa bile ust bilgi yine de kullanilabilir; bu yuzden `matchedLineCount = 0` olsa bile `isFound = true` create ekrani icin degerlidir.
- Ic stok eslesmesi bulunan satirlarda `internalStockCode`, `internalStockName` ve `matchReason` dolar; bulunamayan satirlar UI'da manuel eslestirme icin ayrica gosterilmelidir.
- Kalemlerde `quantitySource = despatch` ise miktar irsaliye sevk miktarindan, `quantitySource = invoice` ise fatura miktarindan gelmistir.
- E-fatura satirlarinda UBL'de varsa `unitPrice` ve `lineAmount` gelir. Bunlar on dolum/gosterim bilgisidir; kaydetmede son soz yine `POST /api/mal-kabul-islemleri/firma-mal-kabulleri` body alanlaridir.
- UI QR okutunca once bu endpoint'i cagirir. `sourceDocumentKind = e-invoice` ise ekranda "E-Fatura" etiketi, `sourceDocumentKind = e-despatch` ise "E-Irsaliye" etiketi gosterilmelidir.
- `warnings` bos degilse UI uyari bandinda gosterebilir. E-fatura bulundu ama irsaliye referansi yoksa backend bunu uyarida belirtir; bu durumda mal kabul fatura uzerinden taslaklanir, kullanici fiili kabul miktarini yine kontrol eder.

Response:

```json
{
  "isFound": true,
  "warehouseNo": 110,
  "receivingContext": "firma-mal-kabulleri",
  "ettn": "3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111",
  "sourceDocumentKind": "e-despatch",
  "sourceDocumentLabel": "E-Irsaliye",
  "sourceDocumentNumber": "IRS2026000001234",
  "despatchNumber": "IRS2026000001234",
  "issueDate": "2026-05-06T00:00:00",
  "actualDespatchDate": "2026-05-06T00:00:00",
  "actualDespatchTime": "08:00:00",
  "plaque": "34 HTE 490_BRS",
  "driverNameSurname": "ORHAN BAYRAM",
  "driverTckn": "49216016986",
  "profileId": "TEMELIRSALIYE",
  "despatchAdviceTypeCode": "SEVK",
  "invoiceNumber": null,
  "invoiceDate": null,
  "invoiceTotal": null,
  "taxExclusiveAmount": null,
  "taxTotal": null,
  "currencyCode": null,
  "despatchReferences": [],
  "warnings": [],
  "notes": [
    "Sofor bilgisi kagit irsaliyede ayrica yaziyor."
  ],
  "sender": {
    "title": "ORNEK TEDARIKCI A.S.",
    "taxNoOrTckn": "1234567890",
    "alias": "urn:mail:ornek@firma.com",
    "city": "ISTANBUL"
  },
  "receiver": {
    "title": "FURPA KESTEL 1",
    "taxNoOrTckn": "0987654321",
    "alias": "urn:mail:kestel1@furpa.com",
    "city": "BURSA"
  },
  "primaryCustomerSuggestion": {
    "customerCode": "120.01.03106",
    "customerName": "ORNEK TEDARIKCI A.S.",
    "taxNoOrTckn": "1234567890",
    "matchReason": "vkn-tckn",
    "isPrimarySuggestion": true
  },
  "totalLineCount": 2,
  "matchedLineCount": 1,
  "unmatchedLineCount": 1,
  "suggestedCustomers": [
    {
      "customerCode": "120.01.03106",
      "customerName": "ORNEK TEDARIKCI A.S.",
      "taxNoOrTckn": "1234567890",
      "matchReason": "vkn-tckn",
      "isPrimarySuggestion": true
    }
  ],
  "lines": [
    {
      "lineNo": 1,
      "productName": "Stok Adi",
      "description": "Kolili urun",
      "quantity": 12,
      "unitCode": "C62",
      "buyerItemCode": "015792",
      "sellerItemCode": "TED-015792",
      "manufacturerItemCode": null,
      "barcode": "8690000000000",
      "internalStockCode": "015792",
      "internalStockName": "Stok Adi",
      "matchReason": "buyer-item-code",
      "isMatched": true,
      "isGoodsAcceptanceBlocked": false,
      "canUseForGoodsAcceptance": true,
      "unitPrice": null,
      "lineAmount": null,
      "quantitySource": "despatch"
    },
    {
      "lineNo": 2,
      "productName": "Dis Kaynakli Urun",
      "description": "Ic stok kodu tutmuyor",
      "quantity": 5,
      "unitCode": "C62",
      "buyerItemCode": null,
      "sellerItemCode": "TED-009999",
      "manufacturerItemCode": null,
      "barcode": "9999999999999",
      "internalStockCode": null,
      "internalStockName": null,
      "matchReason": null,
      "isMatched": false,
      "isGoodsAcceptanceBlocked": false,
      "canUseForGoodsAcceptance": false,
      "unitPrice": null,
      "lineAmount": null,
      "quantitySource": "despatch"
    }
  ]
}
```

E-fatura bulunursa ayni response modeli kullanilir; farkli dolan alanlar ornegi:

```json
{
  "isFound": true,
  "sourceDocumentKind": "e-invoice",
  "sourceDocumentLabel": "E-Fatura",
  "sourceDocumentNumber": "FTR2026000000456",
  "ettn": "2f2a4fd7-7811-43f2-b5ca-3fd0e4f487a2",
  "despatchNumber": "FTR2026000000456",
  "issueDate": "2026-05-06T00:00:00",
  "actualDespatchDate": null,
  "actualDespatchTime": null,
  "profileId": "TEMELFATURA",
  "despatchAdviceTypeCode": "SATIS",
  "invoiceNumber": "FTR2026000000456",
  "invoiceDate": "2026-05-06T00:00:00",
  "invoiceTotal": 11800.0,
  "taxExclusiveAmount": 10000.0,
  "taxTotal": 1800.0,
  "currencyCode": "TRY",
  "despatchReferences": [
    "IRS2026000000123"
  ],
  "warnings": [
    "Belge e-fatura olarak bulundu.",
    "E-fatura irsaliye referansi iceriyor: IRS2026000000123"
  ],
  "lines": [
    {
      "lineNo": 1,
      "productName": "Stok Adi",
      "quantity": 10,
      "unitCode": "KGM",
      "internalStockCode": "015792",
      "internalStockName": "Stok Adi",
      "isMatched": true,
      "canUseForGoodsAcceptance": true,
      "unitPrice": 1000.0,
      "lineAmount": 10000.0,
      "quantitySource": "invoice"
    }
  ]
}
```

Bulunamadi response ornegi:

```json
{
  "isFound": false,
  "warehouseNo": 110,
  "receivingContext": "firma-mal-kabulleri",
  "ettn": "3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111",
  "sourceDocumentKind": "auto",
  "sourceDocumentLabel": "E-Belge",
  "warnings": [
    "Uyumsoft gelen e-irsaliye ve e-fatura kutusunda belge bulunamadi."
  ],
  "totalLineCount": 0,
  "matchedLineCount": 0,
  "unmatchedLineCount": 0,
  "suggestedCustomers": [],
  "lines": []
}
```

### Firma Mal Kabul Olustur

Secili cariden gelen urunler icin yeni firma mal kabul hareketi olusturur; yazma sekli `MikroWriteRouting:CompanyReceiving` ayarina gore Database veya MikroApi olur.

`POST /api/mal-kabul-islemleri/firma-mal-kabulleri`

Alias:

`POST /api/mal-kabul-islemleri/mal-kabuller/firma`

Yetki:

- `mal-kabul-islemleri.firma-mal-kabulleri.create`

Onemli not:

- Tek endpoint hem siparisli hem siparissiz mal kabul icin kullanilir.
- `*.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. `mal-kabul-islemleri.firma-mal-kabulleri.all-warehouses` yetkisi olan kullanici baska depo adina firma mal kabul olusturacaksa body'de opsiyonel `warehouseNo` gonderebilir.
- Mobil offline pilotta request'e `clientRequestId` eklenmelidir.
- Backend `sth_evraktip = 13`, `sth_tip = 0`, `sth_normal_iade = 0` olarak yeni giris hareketi olusturur.
- `movementDate` bizim mal kabul/stok hareket tarihidir; `documentDate` tedarikci fatura/irsaliye tarihidir. Firma belge tarihi hareket tarihinden eski olabilir, fakat `documentDate > movementDate` kabul edilmez.
- Mal kabul giris hareketinde `sth_miktar` irsaliye/gelen miktari olan `dispatchQuantity` ile yazilir.
- Fiili/net kabul miktari `acceptedQuantity` alanidir. UI farkli kabul durumunda `dispatchQuantity` ve `acceptedQuantity` alanlarini ayri gondermelidir.
- Eski uyumluluk icin `quantity` hala desteklenir; UI sadece `quantity` gonderirse backend bunu hem `dispatchQuantity` hem `acceptedQuantity` gibi yorumlar.
- `acceptedQuantity`, `dispatchQuantity` degerinden buyuk olamaz. `dispatchQuantity` sifirdan buyuk olmali, `acceptedQuantity` sifir olabilir.
- `autoCreateReturnForPartialAcceptance = true` varsayilandir. `acceptedQuantity < dispatchQuantity` ise backend fark kadar firma iade evragi olusturur. `Database` modunda ana mal kabul ve otomatik iade ayni DB transaction icindedir; `MikroApi` modunda ana mal kabul ve otomatik iade Mikro API create cagrilariyla sirali olusturulur.
- Otomatik firma iade hareketi `sth_evraktip = 1`, `sth_tip = 1`, `sth_normal_iade = 1` olarak olusturulur; seri `F{warehouseNo}` seklinde uretilir ve sira Mikro'daki sonraki uygun sira olur.
- Mikro net stok etkisi: `dispatchQuantity` kadar firma mal kabul girisi, fark kadar firma iade cikisi. Ornek: 10 geldi, 8 kabul edildi ise +10 mal kabul ve -2 firma iade yazilir; net stok 8 olur.
- Otomatik firma iade icin e-irsaliye gonderimi yapilmaz. Response'ta iade evrak link/status bilgisi doner; kullanici sonradan `POST /api/iade-islemleri/firma-iadeleri/{seri}/{sira}/e-irsaliye` ile gondermelidir.
- `autoCreateReturnForPartialAcceptance = false` gonderilirse fark icin iade evragi olusmaz; satir `returnStatus = IadeBekliyor` olarak doner ve UI bunu manuel cozum bekleyen fark gibi gostermelidir.
- Satirda `orderGuid` doluysa `sth_sip_uid = orderGuid` kullanilir. `Database` modunda `SIPARISLER.sip_teslim_miktar` mal kabul hareket miktari, yani `dispatchQuantity`, kadar artirilir; `MikroApi` modunda teslim etkisi Mikro API'ye birakilir ve backend siparis tablosuna ek DB update yapmaz.
- Satirda `orderGuid` bos veya `null` ise siparis GUID'i bos gider ve siparis tablosuna dokunulmaz.
- Siparis kalanindan fazla kabul varsayilan olarak engellenir. `allowOrderOverReceiving = true` gonderilirse kalan kadar siparisli, fazla kisim siparissiz hareket olarak bolunur.
- `documentNo` opsiyoneldir. E-belge/e-irsaliye no varsa tam `seri + 9 haneli sayisal sira` formatinda gonderilebilir.
- ETTN/UUID ile cozumlenen resmi belge varsa UI kaydetmede `officialDocumentKind`, `officialDocumentNo`, `officialDocumentDate` ve `officialDocumentEttn` alanlarini da gondermelidir. Backend bu bilgileri Mikro hareket satirina yazmaz; `document_flows.external_document_no` ve `document_flows.external_uuid` alanlarina iz olarak kaydeder.
- UI lookup response'unu direkt tasimak isterse `sourceDocumentKind`, `sourceDocumentNumber`, `sourceDocumentDate`, `despatchNumber`, `issueDate`, `invoiceNumber`, `invoiceDate` ve `ettn` alias alanlari da kabul edilir. `officialDocument*` alanlari doluysa onlar onceliklidir.
- `documentNo` Mikro `STOK_HAREKETLERI.sth_belge_no` alanina basilan tedarikci belge numarasidir. ETTN/UUID bu alana basilmaz; resmi belgeyi bulmak icin Belge Akis Takibi'nde `externalUuid` olarak aranir.
- UYARI: `documentNo` veya `description = "E-Irsaliye: ..."` gondermek resmi belge izini Belge Akis Takibi'ne yazdirmaz. `document_flows.external_document_no` icin mutlaka `officialDocumentNo` veya alias'i, `document_flows.external_uuid` icin mutlaka `officialDocumentEttn` veya `ettn` gonderilmelidir.
- Ornek tam `documentNo` degerleri: `ST12026000002395`, `C682026000003472`, `FRM2026600059281`, `OY32026000000162`
- Tam formatta `documentNo` gelirse `documentSerie` son 9 hane atilarak, `documentOrderNo` son 9 hane sayi olarak okunarak uretilir.
- `documentNo` bos gelirse backend cari unvanindan seri uretir ve ayni depo/seri icin siradaki `documentOrderNo` degerini verir.
- `documentNo` `ABC`, `ULK`, `FIRMA` gibi harf iceren ve tam format olmayan kisa bir deger gelirse backend bunu seri/prefix kabul eder, sadece harf-rakam karakterlerini kullanir ve siradaki sira numarasini uretir.
- `documentNo` bos veya sadece sayisal bir degerse backend seri icin cari unvanina duser.
- Response'taki `documentNo`, uretilen nihai `documentSerie + 9 haneli documentOrderNo` degeridir.
- Ayni depo icinde ayni `documentSerie + documentOrderNo` kombinasyonu tekrar kullanilamaz.
- Mobil retry icin backend `clientRequestId` izini `FR` prefixli trace olarak `sth_eticaret_kanal_kodu` alanina tasir; `MikroApi` modunda bu payload ile Mikro'ya gider, tekrar istekte sonuc bu iz uzerinden toparlanabilir.
- Ayni `clientRequestId` ile ayni payload tekrar gonderilirse backend ayni business response'u dondurmeye calisir.
- Ayni `clientRequestId` ile farkli payload gonderilirse `409 Conflict` doner.
- Ayni `clientRequestId` halen isleniyorsa `409 Conflict` doner.

Request:

```json
{
  "clientRequestId": "d8d0f3d6-5c62-4c67-b6b7-0f5d76b81b6f",
  "customerCode": "120.01.03106",
  "movementDate": "2026-04-20",
  "documentDate": "2026-04-20",
  "documentNo": "ST12026000002395",
  "officialDocumentKind": "e-despatch",
  "officialDocumentNo": "ST12026000002395",
  "officialDocumentDate": "2026-04-20",
  "officialDocumentEttn": "3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111",
  "deliverer": "Teslim Eden",
  "receiver": "Teslim Alan",
  "description": "",
  "allowOrderOverReceiving": false,
  "autoCreateReturnForPartialAcceptance": true,
  "lines": [
    {
      "stockCode": "015792",
      "dispatchQuantity": 10,
      "acceptedQuantity": 8,
      "unitPrice": 0,
      "unitPointer": 1,
      "lastConsumingDate": "2026-12-31",
      "orderGuid": "1bb2b4fe-b722-4e67-9d4b-050b6d87e800",
      "description": "",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": "",
      "customerResponsibilityCenter": "",
      "productResponsibilityCenter": ""
    },
    {
      "stockCode": "018888",
      "dispatchQuantity": 3,
      "acceptedQuantity": 3,
      "unitPrice": 0,
      "unitPointer": 1,
      "lastConsumingDate": "2026-11-30",
      "orderGuid": null
    }
  ]
}
```

Response:

```json
{
  "documentSerie": "ST12026",
  "documentOrderNo": 2395,
  "movementDate": "2026-04-20T00:00:00",
  "documentDate": "2026-04-20T00:00:00",
  "documentNo": "ST12026000002395",
  "warehouseNo": 110,
  "customerCode": "120.01.03106",
  "lineCount": 2,
  "totalReceivedQuantity": 13,
  "totalOrderLinkedQuantity": 10,
  "totalOrderlessQuantity": 3,
  "totalOrderOverReceivedQuantity": 0,
  "totalAmount": 0,
  "writeConnectionName": "testMikroConnection",
  "totalDispatchQuantity": 13,
  "totalNetAcceptedQuantity": 11,
  "totalReturnedQuantity": 2,
  "autoCreatedReturnLineCount": 1,
  "autoCreatedReturnDocumentSerie": "F110",
  "autoCreatedReturnDocumentOrderNo": 4301,
  "returnEDespatchStatus": "GonderimBekliyor",
  "lines": [
    {
      "movementGuid": "9c2d1f41-6f91-4e70-8e50-53d1e4bc88b0",
      "sourceLineNo": 0,
      "movementLineNo": 0,
      "stockCode": "015792",
      "orderGuid": "1bb2b4fe-b722-4e67-9d4b-050b6d87e800",
      "isOrderLinked": true,
      "receivingMode": "order-linked",
      "requestedQuantity": 10,
      "acceptedQuantity": 10,
      "orderLinkedQuantity": 10,
      "orderlessQuantity": 0,
      "orderRemainingBefore": 10,
      "orderRemainingAfter": 0,
      "dispatchQuantity": 10,
      "physicalAcceptedQuantity": 8,
      "returnQuantity": 2,
      "returnStatus": "IadeOlusturuldu",
      "returnMovementGuid": "1d2c3f41-6f91-4e70-8e50-53d1e4bc88b0",
      "returnDocumentSerie": "F110",
      "returnDocumentOrderNo": 4301,
      "returnEDespatchStatus": "GonderimBekliyor"
    }
  ]
}
```

Response alan notlari:

- `totalReceivedQuantity` ve `totalDispatchQuantity`: Mikro'ya yazilan firma mal kabul giris miktari toplamidir.
- `totalNetAcceptedQuantity`: fiilen kabul edilen miktar toplamidir; UI stokta kalan/net kabul icin bu alani kullanmalidir.
- `totalReturnedQuantity`: otomatik veya bekleyen firma iade fark miktari toplamidir.
- `acceptedQuantity` satir alaninin eski anlamiyla mal kabul hareket miktari oldugu unutulmamalidir; fiili kabul icin `physicalAcceptedQuantity` kullanilmalidir.
- `returnStatus`: `Yok`, `IadeOlusturuldu` veya `IadeBekliyor` olabilir.
- `returnEDespatchStatus`: `Yok` veya `GonderimBekliyor` olabilir. `GonderimBekliyor` otomatik e-irsaliye gonderildi anlamina gelmez.

Offline status endpoint:

`GET /api/mal-kabul-islemleri/firma-mal-kabulleri/offline-sync/{clientRequestId}`

Yetki:

- `mal-kabul-islemleri.firma-mal-kabulleri.create`

Onemli not:

- Bu endpoint sadece ayni kullanicinin daha once acmis oldugu offline create kaydini sorgular.
- Kayit bulunamazsa `404 Not Found` doner.
- Sonuc ilk POST cevabinda cihaza donemediyse backend kaydi `sth_eticaret_kanal_kodu` izinden tekrar toparlayabilir.
- `status = Completed` ise `result` icinde asagidaki `CreateCompanyReceivingResponse` modeli bulunur.

Ornek response:

```json
{
  "clientRequestId": "d8d0f3d6-5c62-4c67-b6b7-0f5d76b81b6f",
  "operationCode": "mal-kabul-islemleri.firma-mal-kabulleri.create",
  "status": "Completed",
  "createdAtUtc": "2026-05-06T13:40:10Z",
  "completedAtUtc": "2026-05-06T13:40:12Z",
  "errorMessage": null,
  "result": {
    "documentSerie": "ST12026",
    "documentOrderNo": 2395,
    "movementDate": "2026-04-20T00:00:00",
    "documentDate": "2026-04-20T00:00:00",
    "documentNo": "ST12026000002395",
    "warehouseNo": 110,
    "customerCode": "120.01.03106",
    "lineCount": 2,
    "totalReceivedQuantity": 9,
    "totalOrderLinkedQuantity": 6,
    "totalOrderlessQuantity": 3,
    "totalOrderOverReceivedQuantity": 0,
    "totalAmount": 0,
    "writeConnectionName": "testMikroConnection",
    "totalDispatchQuantity": 9,
    "totalNetAcceptedQuantity": 9,
    "totalReturnedQuantity": 0,
    "autoCreatedReturnLineCount": 0,
    "autoCreatedReturnDocumentSerie": null,
    "autoCreatedReturnDocumentOrderNo": null,
    "returnEDespatchStatus": "Yok",
    "lines": []
  }
}
```

Firma mal kabul UI akisi:

- Ana ekran yapilmis firma mal kabul fislerinin gecmis listesidir. Tarih araligi ve depo filtresiyle `GET /api/mal-kabul-islemleri/firma-mal-kabulleri` cagrilir.
- Liste satirinda seri/sira, cari, belge tarihi, depo, satir sayisi, toplam kabul miktari ve toplam tutar gosterilir.
- Kullanici listedeki fisi acarsa `GET /api/mal-kabul-islemleri/firma-mal-kabulleri/{seri}/{sira}` cagrilir ve ekran salt okunur detay gibi davranir.
- Yeni fis icin kullanici `Yeni Mal Kabul` aksiyonuna basar. Create ekraninda cari secimi zorunludur; cari secilmeden satir kaydetme ve `Siparis Bagla` pasif kalmalidir.
- Kullanici QR'dan ETTN/UUID okutursa UI ilk adimda `GET /api/mal-kabul-islemleri/firma-mal-kabulleri/resmi-belge/ettn/{ettn}?documentKind=auto` cagirabilir. Bu akista backend once e-irsaliye, bulunamazsa e-fatura gelen kutusunu dener.
- Bu response'tan `primaryCustomerSuggestion` varsa cari alani icin varsayilan onerilir; `despatchNumber` ve `issueDate` alanlari `documentNo` ve `documentDate` icin on dolum adayi olarak kullanilabilir.
- Kaydetmede resmi belge izinin Belge Akis Takibi'ne dusmesi icin UI lookup response'undan `sourceDocumentKind`, `sourceDocumentNumber`, `issueDate` veya `invoiceDate` ve `ettn` alanlarini create body'deki `officialDocumentKind`, `officialDocumentNo`, `officialDocumentDate`, `officialDocumentEttn` alanlarina tasimalidir.
- Backend ayrica `sourceDocumentKind`, `sourceDocumentNumber`, `sourceDocumentDate`, `despatchNumber`, `issueDate`, `invoiceNumber`, `invoiceDate` ve `ettn` alias alanlarini da kabul eder; fakat sade UI modeli icin `officialDocument*` alanlari onerilir.
- UI sadece `documentNo = ST42026000001970` ve `description = "E-Irsaliye: ST42026000001970"` gonderirse Mikro mal kabul evragi dogru olusur, fakat Belge Akis Takibi'nde `externalDocumentNo` ve `externalUuid` bos kalir. QR/ETTN ile cozumlenmis belgede lookup sonucu mutlaka `officialDocument*` alanlarina tasinmalidir.
- Kayit sonrasi `documentNo` Mikro `sth_belge_no` alaninda, resmi belge no/ETTN ise Belge Akis Takibi listesinde `externalDocumentNo` ve `externalUuid` alanlarinda aranabilir olur.
- `lines[].isMatched = true` olan satirlar tek tikla create satirina aktarilabilir; `isMatched = false` olanlar ayrica "manuel eslestir" listesine dusurulebilir.
- `DocumentNo` artik zorunlu degildir. E-belge/e-irsaliye no varsa UI tam `seri + 9 haneli sayisal sira` formatinda gonderebilir; yoksa bos gonderebilir.
- Kullanici e-belge olmayan firmalarda isterse `ABC`, `ULK`, cari unvanin ilk 2-3 harfi gibi harf iceren bir prefix girebilir. Backend bu prefix'ten seri uretip siradaki sira numarasini verir.
- UI kayit sonrasi ekranda mutlaka response'taki `documentNo`, `documentSerie` ve `documentOrderNo` alanlarini esas almalidir; bos veya prefix request'in kendisini evrak kimligi gibi saklamamalidir.
- Cari secildikten sonra kullanici manuel satir ekleyebilir. Manuel satirlarda `orderGuid = null` gonderilir.
- `Siparis Bagla` aksiyonunda UI secili carinin acik verilen firma siparislerini `GET /api/siparis-islemleri/verilen-firma-siparisleri?WarehouseNo=...&CustomerCode=...&OnlyOpen=true` ile listeler.
- Kullanici bir siparis secerse siparis detayi `GET /api/siparis-islemleri/verilen-firma-siparisleri/{seri}/{sira}?warehouseNo=...` ile acilir ve detaydaki `items[].orderGuid` mal kabul satirina tasinir.
- Siparisten veya e-belgeden gelen satirda UI resmi miktari `dispatchQuantity`, fiili sayilan miktari `acceptedQuantity` olarak tutmalidir. Normal durumda iki alan esit onerilir.
- Kullanici eksik kabul ederse UI farki anlik hesaplamalidir: `returnQuantity = dispatchQuantity - acceptedQuantity`. Bu fark backend tarafinda otomatik firma iadesine donusebilir.
- UI `acceptedQuantity > dispatchQuantity` durumuna izin vermemelidir.
- UI `autoCreateReturnForPartialAcceptance` alanini varsayilan `true` gonderebilir veya hic gondermeyebilir. Operasyon ozellikle otomatik iade istemiyorsa `false` gonderilir ve response'ta `IadeBekliyor` statusu takip edilir.
- Siparisli ve siparissiz satirlar ayni fis icinde birlikte gidebilir. UI satirda siparis bagli mi bilgisini gostermeli, ama request'te sadece `orderGuid` dolu/bos olarak gondermelidir.
- Siparis kalanindan fazla kabul varsayilan olarak engellenmelidir. Yetkili kullanici fazla kabul etmeyi secerek `allowOrderOverReceiving = true` gonderirse backend kalan kadar siparisli, fazla miktari siparissiz hareket olarak boler.
- Mobil offline akista taslak ilk olusturulurken tek bir `clientRequestId` uretilmeli ve cihazdaki local kayitla birlikte saklanmalidir.
- Kullanici ayni taslagi tekrar gonderirse ayni `clientRequestId` ile POST tekrar edilmelidir.
- POST timeout olursa UI hemen yeni GUID uretmemeli; once ayni `clientRequestId` ile retry yapmali, hala emin degilse `GET /api/mal-kabul-islemleri/firma-mal-kabulleri/offline-sync/{clientRequestId}` ile son durumu sorgulamalidir.
- `409 Conflict` ve mesaj "different request payload" anlamina geliyorsa UI bu taslagi yeni bir islem gibi ele alip yeni `clientRequestId` uretmelidir.
- `409 Conflict` ve mesaj "already being processed" anlamina geliyorsa UI kullaniciya "islem halen isleniyor" bilgisi verip status endpoint'ini poll edebilir.
- Kaydet butonu `POST /api/mal-kabul-islemleri/firma-mal-kabulleri` endpoint'ine gider.
- Basarili response sonrasi UI olusan `documentSerie` ve `documentOrderNo` ile detay ekranina gecebilir veya listeyi yenileyebilir.
- Response'ta `autoCreatedReturnLineCount > 0` ise UI olusan firma iade evragini `autoCreatedReturnDocumentSerie` + `autoCreatedReturnDocumentOrderNo` ile linklemeli ve durumunu `returnEDespatchStatus = GonderimBekliyor` olarak gostermelidir.
- Otomatik iade olustugunda UI e-irsaliye gonderimini kendiliginden tetiklememelidir. Kullanici "Firma iadesi e-irsaliye gonder" aksiyonuna bastiginda `POST /api/iade-islemleri/firma-iadeleri/{seri}/{sira}/e-irsaliye` cagrilir.
- Bu ekranda plaka, sofor ve TCKN istenmez. Firma mal kabul icin opsiyonel `deliverer` ve `receiver` alanlari teslim eden/teslim alan notu olarak kullanilabilir.

## Duzeltme Islemleri / Mikro Evrak Duzenleme

Bu modul Mikro tarafinda var olan kayitlari kontrollu sekilde duzeltmek icin eklendi. Ilk kapsam:

- `STOK_HAREKETLERI` belgeleri
- `SAYIM_SONUCLARI` sayim sonucu fisleri
- `CARI_HESAP_HAREKETLERI` belgeleri
- `STOKLAR` stok kartlari
- `STOK_DEPO_DETAYLARI` depo bazli stok karti ayarlari
- `STOK_SATIS_FIYAT_LISTELERI` depo bazli stok satis fiyatlari
- `DEPOLAR` depo kartlari
- `CARI_HESAPLAR` cari kartlari
- `SIPARISLER` firma siparis evraklari
- `DEPOLAR_ARASI_SIPARISLER` depo siparis evraklari

Menu:

- Module: `DuzeltmeIslemleri`
- Menu: `MikroEvrakDuzenleme`
- Route kok: `/api/duzeltme-islemleri/mikro-evrak-duzenleme`

Yetki kodlari:

- `duzeltme-islemleri.mikro-evrak-duzenleme.list`
- `duzeltme-islemleri.mikro-evrak-duzenleme.detail`
- `duzeltme-islemleri.mikro-evrak-duzenleme.update`
- `duzeltme-islemleri.mikro-evrak-duzenleme.delete`

Genel kurallar:

- Detay endpointleri Mikro read connection uzerinden okur; guncelleme endpointleri Mikro write connection uzerinden yazar.
- Stok ve cari hareket belgelerinde `documentSerie` ve `documentOrderNo` zorunludur.
- `documentType`, `movementType`, `movementKind`, `normalReturn` filtreleri opsiyoneldir. Seri-sira birden fazla evrak tipi/cins/iade kombinasyonuna denk gelirse backend `409 Conflict` doner; UI kullaniciya "evrak tipi/cins/iade filtresi ile daraltin" mesaji gostermelidir.
- Satir guncellemeleri `movementGuid` ile yapilir. UI detay response'undaki `lines[].movementGuid` degerini satir modelinde saklamalidir.
- Sayim sonucu fisleri `warehouseNo + documentNo + documentDate` ile bulunur. Sayim satiri guncellemeleri `countGuid` ile yapilir; UI detay response'undaki `lines[].countGuid` degerini gizli anahtar olarak saklamalidir.
- Sayim sonucunda `sym_kilitli = true` olan satir varsa update reddedilir. Sayim duzeltmede yeni fis/satir olusturma ve silme yoktur; mevcut satirlarin miktar, stok, barkod, birim ve yardimci kodlari duzeltilir.
- Firma siparislerinde `documentSerie` ve `documentOrderNo` zorunludur; `orderType` (`SIPARISLER.sip_tip`), `orderKind` (`sip_cins`), `warehouseNo` ve `customerCode` opsiyonel daraltma filtreleridir.
- Depo siparislerinde `documentSerie` ve `documentOrderNo` zorunludur; `warehouseNo`, `inWarehouseNo` ve `outWarehouseNo` opsiyonel daraltma filtreleridir.
- Siparis satir guncellemeleri `orderGuid` ile yapilir. UI detay response'undaki `lines[].orderGuid` degerini satir modelinde gizli anahtar olarak saklamalidir.
- Request body'de `null` gelen alanlar degismez. Bos string gonderilirse ilgili metin alani bosaltma istegi olarak islenir.
- Kayitlarda Mikro audit alanlari guncellenir: `lastup_user`, `lastup_date`, `degisti`.
- Bu modul yeni evrak olusturma yapmaz; sadece whitelist icindeki alanlari gunceller.
- Delete yalnizca silinmesi guvenli kayitlarda vardir: depo ozel stok ayari, depo bazli satis fiyati, stok hareket evraki, cari hareket evraki, firma siparis evraki ve depo siparis evraki.
- Stok karti, depo karti ve cari karti icin delete yoktur; UI bu ana kartlarda sil butonu gostermemelidir.
- Stok/cari hareket ve siparis evraki silmede iki mod vardir:
  - Varsayilan `soft-delete`: Mikro `iptal/hidden` bayraklariyla iptal eder.
  - `hardDelete=true`: eslesen evrak satirlarini fiziksel olarak siler. Stok hareketinde bagli `STOK_HAREKETLERI_EK` satirlari da silinir.
- UI hard delete icin ayri onay gostermelidir. Onerilen varsayilan davranis soft-delete'tir.
- Stok satis fiyati endpoint'i istisna olarak eksik `STOK_SATIS_FIYAT_LISTELERI` kaydini olusturabilir.
- Satis fiyati kaydi `stockCode + priceListNo + warehouseNo + unitPointer + paymentPlanNo` birlesimiyle bulunur. Kayit varsa guncellenir, yoksa olusturulur.
- Satis fiyati upsert islemi `STOK_FIYAT_DEGISIKLIKLERI` tablosunda sentetik fiyat degisiklik evraki olusturmaz.
- `PUT /stok-kartlari/{stockCode}` global stok kartini degistirir ve tum depolari etkileyebilir.
- Sadece belirli bir depoyu kapatmak/acmak icin `/stok-kartlari/{stockCode}/depolar/{warehouseNo}` endpoint'i kullanilmalidir.
- Depo karti ve cari karti endpointleri yeni kart olusturmaz; sadece mevcut Mikro kartini gunceller.
- Cari kartinda `parentCustomerCode`, `defaultInputWarehouseNo`, `defaultOutputWarehouseNo` gonderilirse backend ilgili cari/depo kaydinin varligini kontrol eder.
- Depo kartinda GPS alanlari icin `latitude` -90..90, `longitude` -180..180 araliginda olmalidir.
- UI alan isimlerini kendi icinde hardcoded map'lememelidir. Ekran acilisinda `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/alan-haritasi` cagrilip `displayName`, `mikroTable`, `mikroColumn`, `valueType`, `editable` alanlari kullanilmalidir.
- Alan haritasinda `editable=false` olan alanlar response/lookup bilgisidir; UI bunlari gosterir ama PUT body icinde gondermez. Ornek: stok hareketi `unitPrice` response'ta hesaplanan alandir, Mikro'da direkt `sth_b_fiyat` kolonu yoktur.

Endpoint ozeti:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/alan-haritasi` | - | - | `MikroDocumentFieldCatalogDto` | `list` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari` | query | `StockCardSearchHttpRequest` | `StockCardListItemDto[]` | `list` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}` | path | `stockCode` | `StockCardDetailDto` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}` | path + body | `StockCardPatchHttpRequest` | `StockCardUpdateResponse` | `update` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/depolar` | path + query | `warehouseNo?: int` | `StockCardWarehouseSettingsDto[]` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/depolar/{warehouseNo}` | path + body | `StockCardWarehousePatchHttpRequest` | `StockCardWarehouseUpdateResponse` | `update` |
| `DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/depolar/{warehouseNo}` | path | `stockCode`, `warehouseNo` | `MikroDocumentDeleteResponse` | `delete` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/satis-fiyatlari` | path + query | `warehouseNo?: int` | `StockSalesPriceDto[]` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/satis-fiyatlari/{warehouseNo}` | path + body | `StockSalesPriceUpsertHttpRequest` | `StockSalesPriceUpsertResponse` | `update` |
| `DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/satis-fiyatlari/{warehouseNo}` | path + query | `StockSalesPriceDeleteHttpRequest` | `MikroDocumentDeleteResponse` | `delete` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/depolar` | query | `WarehouseCardSearchHttpRequest` | `WarehouseCardListItemDto[]` | `list` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/depolar/{warehouseNo}` | path | `warehouseNo` | `WarehouseCardDetailDto` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/depolar/{warehouseNo}` | path + body | `WarehouseCardPatchHttpRequest` | `WarehouseCardUpdateResponse` | `update` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/cariler` | query | `CustomerCardSearchHttpRequest` | `CustomerCardListItemDto[]` | `list` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/cariler/{customerCode}` | path | `customerCode` | `CustomerCardDetailDto` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/cariler/{customerCode}` | path + body | `CustomerCardPatchHttpRequest` | `CustomerCardUpdateResponse` | `update` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-hareketleri` | query | `StockMovementDocumentLookupHttpRequest` | `StockMovementDocumentDto` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-hareketleri` | body | `UpdateStockMovementDocumentHttpRequest` | `StockMovementDocumentUpdateResponse` | `update` |
| `DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-hareketleri` | query | `StockMovementDocumentLookupHttpRequest` | `MikroDocumentDeleteResponse` | `delete` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/sayim-sonuclari` | query | `InventoryCountDocumentLookupHttpRequest` | `InventoryCountDocumentDto` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/sayim-sonuclari` | body | `UpdateInventoryCountDocumentHttpRequest` | `InventoryCountDocumentUpdateResponse` | `update` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/cari-hareketleri` | query | `CustomerMovementDocumentLookupHttpRequest` | `CustomerMovementDocumentDto` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/cari-hareketleri` | body | `UpdateCustomerMovementDocumentHttpRequest` | `CustomerMovementDocumentUpdateResponse` | `update` |
| `DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/cari-hareketleri` | query | `CustomerMovementDocumentLookupHttpRequest` | `MikroDocumentDeleteResponse` | `delete` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/firma-siparisleri` | query | `CompanyOrderDocumentLookupHttpRequest` | `CompanyOrderDocumentDto` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/firma-siparisleri` | body | `UpdateCompanyOrderDocumentHttpRequest` | `CompanyOrderDocumentUpdateResponse` | `update` |
| `DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/firma-siparisleri` | query | `CompanyOrderDocumentLookupHttpRequest` | `MikroDocumentDeleteResponse` | `delete` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/depo-siparisleri` | query | `WarehouseOrderDocumentLookupHttpRequest` | `WarehouseOrderDocumentDto` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/depo-siparisleri` | body | `UpdateWarehouseOrderDocumentHttpRequest` | `WarehouseOrderDocumentUpdateResponse` | `update` |
| `DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/depo-siparisleri` | query | `WarehouseOrderDocumentLookupHttpRequest` | `MikroDocumentDeleteResponse` | `delete` |

### Alan Haritasi

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/alan-haritasi`

UI bu endpoint'i form metadata kaynagi olarak kullanmalidir. Backend her duzenlenebilir bolum icin API field path, kullaniciya gosterilecek ad, Mikro tablo/kolon karsiligi ve veri tipini dondurur.

Response modeli:

```json
{
  "sections": [
    {
      "code": "stock-card",
      "title": "Stok Karti",
      "endpoint": "PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}",
      "requestModel": "StockCardPatchHttpRequest",
      "fields": [
        {
          "apiField": "name",
          "displayName": "Stok adi",
          "scope": "body",
          "valueType": "string",
          "mikroTable": "STOKLAR",
          "mikroColumn": "sto_isim",
          "editable": true,
          "description": ""
        },
        {
          "apiField": "lines[].unitPrice",
          "displayName": "Birim fiyat",
          "scope": "line",
          "valueType": "double",
          "mikroTable": "STOK_HAREKETLERI",
          "mikroColumn": "-",
          "editable": false,
          "description": "STOK_HAREKETLERI tablosunda direkt kolon yoktur; API response'ta amount / quantity olarak hesaplanir."
        }
      ]
    }
  ]
}
```

UI kullanim kurali:

- Form label'i icin `displayName` kullanilir.
- Teknik bilgi/tooltip icin `mikroTable + "." + mikroColumn` gosterilebilir.
- `apiField` request body field path'idir; UI kendi alan adi sozlugunu bunun yerine kullanmamalidir.
- `editable=false` alanlar sadece bilgi/lookup alanidir, PUT body'ye dahil edilmez.
- `special1`, `special2`, `special3` alanlari Mikro'da 4 karakterlik ozel kod alanlaridir; UI input uzunlugunu 4 ile sinirlamalidir.

Kritik alan karsiliklari:

| Bolum | API alani | UI adi | Mikro tablo/kolon | Not |
|---|---|---|---|---|
| Stok karti | `special1/2/3` | Ozel kod 1/2/3 | `STOKLAR.sto_special1/2/3` | Yeni guncellenebilir alanlar, 4 karakter |
| Depo karti | `special1/2/3` | Ozel kod 1/2/3 | `DEPOLAR.dep_special1/2/3` | Yeni guncellenebilir alanlar, 4 karakter |
| Cari karti | `special1/2/3` | Ozel kod 1/2/3 | `CARI_HESAPLAR.cari_special1/2/3` | Yeni guncellenebilir alanlar, 4 karakter |
| Stok hareket satiri | `expenseTaxPointer` | Masraf vergi pointer | `STOK_HAREKETLERI.sth_masraf_vergi_pntr` | Yeni guncellenebilir alan |
| Stok hareket satiri | `expenseTaxAmount` | Masraf vergi tutari | `STOK_HAREKETLERI.sth_masraf_vergi` | Yeni guncellenebilir alan |
| Stok hareket satiri | `special1/2/3` | Ozel kod 1/2/3 | `STOK_HAREKETLERI.sth_special1/2/3` | Yeni guncellenebilir alanlar, 4 karakter |
| Stok hareket satiri | `unitPrice` | Birim fiyat | - | Read-only; `amount / quantity` hesaplanir |
| Sayim header | `documentDate` | Sayim tarihi | `SAYIM_SONUCLARI.sym_tarihi` | Tum sayim satirlarina uygulanir |
| Sayim header | `warehouseNo` | Depo | `SAYIM_SONUCLARI.sym_depono` | Tum sayim satirlarina uygulanir |
| Sayim header | `name` | Sayim adi/notu | `SAYIM_SONUCLARI.sym_parti_kodu` | Tum sayim satirlarina uygulanir |
| Sayim satiri | `countGuid` | Sayim satir GUID | `SAYIM_SONUCLARI.sym_Guid` | Read-only; satir eslestirme anahtari |
| Sayim satiri | `quantity1..5` | Sayim miktarlari | `SAYIM_SONUCLARI.sym_miktar1..5` | En kritik duzeltme alani genelde `quantity1` |
| Sayim satiri | `stockCode`, `barcode`, `unitPointer` | Stok/barkod/birim | `sym_Stokkodu`, `sym_barkod`, `sym_birim_pntr` | Stok degisirse stok karti varligi kontrol edilir |
| Cari hareket satiri | `special1/2/3` | Ozel kod 1/2/3 | `CARI_HESAP_HAREKETLERI.cha_special1/2/3` | Yeni guncellenebilir alanlar, 4 karakter |
| Firma siparis satiri | `priceListNo` | Fiyat liste no | `SIPARISLER.sip_fiyat_liste_no` | Yeni guncellenebilir alan |
| Firma siparis satiri | `validUntil` | Gecerlilik tarihi | `SIPARISLER.sip_gecerlilik_tarihi` | Yeni guncellenebilir alan |
| Firma siparis satiri | `reservedQuantity` | Rezervasyon miktari | `SIPARISLER.sip_rezervasyon_miktari` | Yeni guncellenebilir alan |
| Firma siparis satiri | `deliveredFromReservation` | Rezerveden teslim edilen | `SIPARISLER.sip_rezerveden_teslim_edilen` | Yeni guncellenebilir alan |
| Firma siparis satiri | `special1/2/3` | Ozel kod 1/2/3 | `SIPARISLER.sip_special1/2/3` | Yeni guncellenebilir alanlar, 4 karakter |
| Depo siparis satiri | `priceListNo` | Fiyat liste no | `DEPOLAR_ARASI_SIPARISLER.ssip_fiyat_liste_no` | Yeni guncellenebilir alan |
| Depo siparis satiri | `validUntil` | Gecerlilik tarihi | `DEPOLAR_ARASI_SIPARISLER.ssip_gecerlilik_tarihi` | Yeni guncellenebilir alan |
| Depo siparis satiri | `reservedQuantity` | Rezervasyon miktari | `DEPOLAR_ARASI_SIPARISLER.ssip_rezervasyon_miktari` | Yeni guncellenebilir alan |
| Depo siparis satiri | `deliveredFromReservation` | Rezerveden teslim edilen | `DEPOLAR_ARASI_SIPARISLER.ssip_rezerveden_teslim_edilen` | Yeni guncellenebilir alan |
| Depo siparis satiri | `special1/2/3` | Ozel kod 1/2/3 | `DEPOLAR_ARASI_SIPARISLER.ssip_special1/2/3` | Yeni guncellenebilir alanlar, 4 karakter |

### Stok Karti Arama

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari?searchText=sut&take=20`

Query:

- `searchText`: opsiyonel, stok kodu/ad/kisa ad icinde arar
- `includePassive`: varsayilan `false`
- `take`: varsayilan `50`, maksimum `200`

Response item:

```json
{
  "stockCode": "015550",
  "name": "URUN ADI",
  "shortName": "URUN",
  "supplierCode": "120.01.03106",
  "unit1Name": "AD",
  "mainGroupCode": "GIDA",
  "subGroupCode": "SUT",
  "categoryCode": "",
  "isPassive": false,
  "lastUpdatedAt": "2026-06-19T14:30:00"
}
```

### Stok Karti Detay

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/015550`

Response modeli `StockCardDetailDto`:

```json
{
  "stockCode": "015550",
  "name": "URUN ADI",
  "shortName": "URUN",
  "foreignName": "",
  "supplierCode": "120.01.03106",
  "stockType": 0,
  "currencyType": 0,
  "trackingType": 0,
  "unit1Name": "AD",
  "unit2Name": "KOLI",
  "unit3Name": "",
  "unit4Name": "",
  "retailTaxPointer": 8,
  "wholesaleTaxPointer": 8,
  "categoryCode": "",
  "mainGroupCode": "GIDA",
  "subGroupCode": "SUT",
  "brandCode": "",
  "sectorCode": "",
  "rayonCode": "",
  "manufacturerCode": "",
  "responsibilityCode": "",
  "shelfCode": "",
  "salesStopped": false,
  "orderStopped": false,
  "receivingStopped": false,
  "isPassive": false,
  "discountDisabled": false,
  "createdAt": "2026-01-01T09:00:00",
  "lastUpdatedAt": "2026-06-19T14:30:00"
}
```

### Stok Karti Guncelle

`PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/015550`

Body'de sadece degistirilecek alanlar gonderilmelidir:

```json
{
  "name": "YENI URUN ADI",
  "shortName": "YENI AD",
  "supplierCode": "120.01.03106",
  "unit1Name": "AD",
  "retailTaxPointer": 8,
  "wholesaleTaxPointer": 8,
  "salesStopped": false,
  "orderStopped": false,
  "receivingStopped": false,
  "isPassive": false
}
```

Response:

```json
{
  "summary": {
    "target": "stok-kartlari",
    "updatedRowCount": 1,
    "updatedAt": "2026-06-19T15:20:00",
    "updateUser": 110
  },
  "stockCard": {
    "stockCode": "015550",
    "name": "YENI URUN ADI"
  }
}
```

### Stok Kartinin Depo Bazli Durumlari

Tum aktif depolar:

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/015550/depolar`

Yalnizca 150 numarali depo:

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/015550/depolar?warehouseNo=150`

Response:

```json
[
  {
    "stockCode": "015550",
    "warehouseNo": 150,
    "warehouseName": "ORNEK DEPO",
    "hasWarehouseDetail": true,
    "hasAnyOverride": true,
    "globalSalesStopped": false,
    "globalOrderStopped": false,
    "globalReceivingStopped": false,
    "globalIsPassive": false,
    "globalDiscountDisabled": false,
    "salesStopped": true,
    "orderStopped": false,
    "receivingStopped": false,
    "isPassive": false,
    "discountDisabled": false,
    "lastUpdatedAt": "2026-06-22T14:30:00"
  }
]
```

Alan anlamlari:

- `global*` alanlari `STOKLAR` tablosundaki tum sistemi etkileyen stok karti degerleridir.
- `salesStopped`, `orderStopped`, `receivingStopped`, `isPassive`, `discountDisabled` alanlari ilgili depoda gecerli nihai degerlerdir.
- Depo ozel alani doluysa depo degeri, bos ise global stok karti degeri kullanilir.
- `hasWarehouseDetail`, Mikro `STOK_DEPO_DETAYLARI` kaydinin varligini belirtir.
- `hasAnyOverride`, bu modulun yonettigi alanlardan en az birinde depo ozel degeri bulundugunu belirtir.

### Stok Kartini Belirli Depoda Guncelle

Ornek: `015550` urununu yalnizca 150 numarali depoda satisa kapat:

`PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/015550/depolar/150`

```json
{
  "salesStopped": true
}
```

Ayni depoda satis, siparis ve mal kabulun tamamini kapat:

```json
{
  "salesStopped": true,
  "orderStopped": true,
  "receivingStopped": true
}
```

Guncellenebilir alanlar:

- `salesStopped`: `STOK_DEPO_DETAYLARI.sdp_satisdursun`
- `orderStopped`: `STOK_DEPO_DETAYLARI.sdp_sipdursun`
- `receivingStopped`: `STOK_DEPO_DETAYLARI.sdp_malkabuldursun`
- `isPassive`: `STOK_DEPO_DETAYLARI.sdp_Pasif_fl`
- `discountDisabled`: `STOK_DEPO_DETAYLARI.sdp_IskontoYapilamaz`
- `resetToGlobal`: yonetilen depo ozel alanlarini temizler ve global stok karti degerlerine geri doner

Kurallar:

- Body'de `null` veya gonderilmeyen alan degismez.
- Depo detay kaydi yoksa ilk depo ozel guncellemede otomatik olusturulur.
- Bu islem `STOKLAR` kaydini degistirmez; diger depolar etkilenmez.
- `resetToGlobal=true` tum depo ozel blok/pasif/iskonto degerlerini temizler.
- `resetToGlobal=true` ile ayni request'te baska alanlar da gonderilirse once ayarlar sifirlanir, sonra gonderilen yeni degerler uygulanir.

Global ayarlara geri donme:

```json
{
  "resetToGlobal": true
}
```

Response:

```json
{
  "summary": {
    "target": "stok-kartlari/015550/depolar/150",
    "updatedRowCount": 1,
    "updatedAt": "2026-06-22T14:35:00",
    "updateUser": 110
  },
  "warehouseSettings": {
    "stockCode": "015550",
    "warehouseNo": 150,
    "warehouseName": "ORNEK DEPO",
    "hasWarehouseDetail": true,
    "hasAnyOverride": true,
    "globalSalesStopped": false,
    "globalOrderStopped": false,
    "globalReceivingStopped": false,
    "globalIsPassive": false,
    "globalDiscountDisabled": false,
    "salesStopped": true,
    "orderStopped": false,
    "receivingStopped": false,
    "isPassive": false,
    "discountDisabled": false,
    "lastUpdatedAt": "2026-06-22T14:35:00"
  }
}
```

### Stok Kartinin Depo Ozel Ayarini Sil

Depo ozel `STOK_DEPO_DETAYLARI` satirini kaldirir. Stok karti silinmez; urun ilgili depoda global stok karti ayarlarina geri doner.

`DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/015550/depolar/150`

Response:

```json
{
  "target": "stok-kartlari/015550/depolar/150",
  "deletedRowCount": 1,
  "deletedAt": "2026-07-02T12:46:00",
  "deleteUser": 110,
  "deletionMode": "physical-delete-override"
}
```

Depo ozel kayit zaten yoksa `deletedRowCount=0` doner. Stok veya depo bulunamazsa `404 Not Found` doner.

### Depo Karti Arama

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/depolar?searchText=kestel&take=20`

Query:

- `searchText`: opsiyonel; depo no, depo adi, grup kodu, il veya ilce icinde arar
- `includePassive`: varsayilan `false`; `true` olursa pasif/gizli depolar da gelir
- `take`: varsayilan `50`, maksimum `200`

Response item:

```json
{
  "warehouseNo": 110,
  "name": "KESTEL 1",
  "groupCode": "MAGAZA",
  "warehouseType": 0,
  "city": "BURSA",
  "district": "KESTEL",
  "isPassive": false,
  "isHidden": false,
  "lastUpdatedAt": "2026-06-26T10:20:00"
}
```

### Depo Karti Detay

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/depolar/110`

Response modeli `WarehouseCardDetailDto`:

```json
{
  "warehouseGuid": "9f3db1de-50ef-48a0-a617-7cf5634c4f3a",
  "warehouseNo": 110,
  "name": "KESTEL 1",
  "groupCode": "MAGAZA",
  "warehouseType": 0,
  "shipmentAutoPriceType": 0,
  "movementType": 0,
  "accountingCode": "",
  "responsibilityCenter": "SRM-110",
  "projectCode": "",
  "shipmentAppliedPriceNo": 1,
  "lockDate": null,
  "street": "ORNEK CADDE",
  "neighborhood": "",
  "avenue": "",
  "quarter": "",
  "apartmentNo": "",
  "apartmentUnitNo": "",
  "postalCode": "",
  "district": "KESTEL",
  "city": "BURSA",
  "country": "TURKIYE",
  "addressCode": "",
  "latitude": 40.195,
  "longitude": 29.211,
  "authorizedEmail": "depo110@furpa.com.tr",
  "phoneCountryCode": "90",
  "phoneAreaCode": "224",
  "phoneNo1": "0000000",
  "phoneNo2": "",
  "faxNo": "",
  "excludedFromInventory": false,
  "detailTrackingType": 0,
  "regionCode": "BURSA",
  "outgoingEDespatchEnabled": true,
  "incomingEDespatchEnabled": true,
  "isPassive": false,
  "isHidden": false,
  "isLocked": false,
  "createdAt": "2026-01-01T09:00:00",
  "lastUpdatedAt": "2026-06-26T10:20:00"
}
```

### Depo Karti Guncelle

`PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/depolar/110`

Body'de sadece degistirilecek alanlar gonderilmelidir:

```json
{
  "name": "KESTEL 1",
  "groupCode": "MAGAZA",
  "responsibilityCenter": "SRM-110",
  "projectCode": "",
  "city": "BURSA",
  "district": "KESTEL",
  "phoneCountryCode": "90",
  "phoneAreaCode": "224",
  "phoneNo1": "0000000",
  "authorizedEmail": "depo110@furpa.com.tr",
  "outgoingEDespatchEnabled": true,
  "incomingEDespatchEnabled": true
}
```

Guncellenebilir alanlar:

- Temel: `name`, `groupCode`, `warehouseType`, `movementType`, `shipmentAutoPriceType`, `shipmentAppliedPriceNo`
- Muhasebe/organizasyon: `accountingCode`, `responsibilityCenter`, `projectCode`, `regionCode`
- Adres: `street`, `neighborhood`, `avenue`, `quarter`, `apartmentNo`, `apartmentUnitNo`, `postalCode`, `district`, `city`, `country`, `addressCode`
- Konum/iletisim: `latitude`, `longitude`, `authorizedEmail`, `phoneCountryCode`, `phoneAreaCode`, `phoneNo1`, `phoneNo2`, `faxNo`
- Durum: `excludedFromInventory`, `detailTrackingType`, `outgoingEDespatchEnabled`, `incomingEDespatchEnabled`, `isPassive`, `isHidden`, `isLocked`, `lockDate`

Response:

```json
{
  "summary": {
    "target": "depolar/110",
    "updatedRowCount": 1,
    "updatedAt": "2026-06-26T10:30:00",
    "updateUser": 110
  },
  "warehouseCard": {
    "warehouseNo": 110,
    "name": "KESTEL 1",
    "city": "BURSA",
    "district": "KESTEL"
  }
}
```

### Cari Karti Arama

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/cariler?searchText=120.01&take=20`

Query:

- `searchText`: opsiyonel; cari kod, unvan1, unvan2 veya vergi kimlik no icinde arar
- `includePassive`: varsayilan `false`; `true` olursa iptal/gizli cariler de gelir
- `take`: varsayilan `50`, maksimum `200`

Response item:

```json
{
  "customerCode": "120.01.03106",
  "title1": "ORNEK CARI",
  "title2": "",
  "taxOffice": "NILUFER",
  "taxNo": "1234567890",
  "groupCode": "TEDARIKCI",
  "regionCode": "BURSA",
  "representativeCode": "",
  "isClosed": false,
  "isLocked": false,
  "lastUpdatedAt": "2026-06-26T10:20:00"
}
```

### Cari Karti Detay

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/cariler/120.01.03106`

Response modeli `CustomerCardDetailDto`:

```json
{
  "customerGuid": "8dc423d4-4015-4afb-aee5-909e457e2f81",
  "customerCode": "120.01.03106",
  "title1": "ORNEK CARI",
  "title2": "",
  "movementType": 0,
  "connectionType": 0,
  "purchaseStockType": 0,
  "salesStockType": 0,
  "accountingCode": "",
  "accountingCode1": "",
  "accountingCode2": "",
  "currencyType": 0,
  "currencyType1": 0,
  "currencyType2": 0,
  "taxOffice": "NILUFER",
  "taxOfficeNo": "",
  "registryNo": "",
  "taxNo": "1234567890",
  "salesPriceListNo": 1,
  "paymentType": 0,
  "paymentDay": 0,
  "paymentPlanNo": 0,
  "optionDay": 0,
  "invoiceAddressNo": 1,
  "shippingAddressNo": 1,
  "parentCustomerCode": "",
  "sectorCode": "",
  "regionCode": "BURSA",
  "groupCode": "TEDARIKCI",
  "representativeCode": "",
  "isClosed": false,
  "isLocked": false,
  "eInvoiceEnabled": true,
  "defaultEInvoiceType": 0,
  "eDespatchEnabled": true,
  "defaultEDespatchType": 0,
  "website": "",
  "email": "cari@example.com",
  "mobilePhone": "05320000000",
  "defaultInputWarehouseNo": 110,
  "defaultOutputWarehouseNo": 110,
  "kepAddress": "",
  "reconciliationEmail": "",
  "mersisNo": "",
  "taxOfficeCode": "",
  "retailCustomer": false,
  "createdAt": "2026-01-01T09:00:00",
  "lastUpdatedAt": "2026-06-26T10:20:00"
}
```

### Cari Karti Guncelle

`PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/cariler/120.01.03106`

Body'de sadece degistirilecek alanlar gonderilmelidir:

```json
{
  "title1": "ORNEK CARI",
  "taxOffice": "NILUFER",
  "taxNo": "1234567890",
  "groupCode": "TEDARIKCI",
  "regionCode": "BURSA",
  "email": "cari@example.com",
  "mobilePhone": "05320000000",
  "defaultInputWarehouseNo": 110,
  "defaultOutputWarehouseNo": 110,
  "eInvoiceEnabled": true,
  "eDespatchEnabled": true
}
```

Guncellenebilir alanlar:

- Temel: `title1`, `title2`, `movementType`, `connectionType`, `purchaseStockType`, `salesStockType`
- Muhasebe/doviz: `accountingCode`, `accountingCode1`, `accountingCode2`, `currencyType`, `currencyType1`, `currencyType2`
- Vergi: `taxOffice`, `taxOfficeNo`, `registryNo`, `taxNo`, `taxOfficeCode`
- Odeme/adres: `salesPriceListNo`, `paymentType`, `paymentDay`, `paymentPlanNo`, `optionDay`, `invoiceAddressNo`, `shippingAddressNo`
- Organizasyon: `parentCustomerCode`, `sectorCode`, `regionCode`, `groupCode`, `representativeCode`
- E-belge/iletisim: `eInvoiceEnabled`, `defaultEInvoiceType`, `eDespatchEnabled`, `defaultEDespatchType`, `website`, `email`, `mobilePhone`, `kepAddress`, `reconciliationEmail`
- Diger: `defaultInputWarehouseNo`, `defaultOutputWarehouseNo`, `mersisNo`, `retailCustomer`, `isClosed`, `isLocked`

Response:

```json
{
  "summary": {
    "target": "cariler/120.01.03106",
    "updatedRowCount": 1,
    "updatedAt": "2026-06-26T10:30:00",
    "updateUser": 110
  },
  "customerCard": {
    "customerCode": "120.01.03106",
    "title1": "ORNEK CARI",
    "taxNo": "1234567890"
  }
}
```

### Stok Satis Fiyatlarini Getir

Stok kartinin tum aktif depo fiyatlari:

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/015550/satis-fiyatlari`

Yalnizca 150 numarali depodaki fiyatlari:

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/015550/satis-fiyatlari?warehouseNo=150`

Response:

```json
[
  {
    "priceGuid": "8dc423d4-4015-4afb-aee5-909e457e2f81",
    "stockCode": "015550",
    "priceListNo": 1,
    "priceListName": "SATIS FIYATI",
    "warehouseNo": 150,
    "warehouseName": "ORNEK DEPO",
    "paymentPlanNo": 0,
    "unitPointer": 1,
    "unitName": "AD",
    "price": 109.5,
    "currencyType": 0,
    "changeReason": 4,
    "createdAt": "2026-06-25T10:20:00",
    "lastUpdatedAt": "2026-06-25T10:20:00"
  }
]
```

Aktif fiyat kaydi yoksa response bos dizi olur. Stok karti yoksa `404 Not Found` doner.

### Stok Satis Fiyati Olustur veya Guncelle

`PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/015550/satis-fiyatlari/150`

Minimum body:

```json
{
  "price": 109.5
}
```

Minimum body kullanildiginda varsayilanlar:

- `priceListNo = 1`
- `paymentPlanNo = 0`
- `unitPointer = 1`
- `currencyType = 0`
- `changeReason = 4`

Tum alanlarla ornek:

```json
{
  "priceListNo": 1,
  "paymentPlanNo": 0,
  "unitPointer": 1,
  "price": 109.5,
  "currencyType": 0,
  "changeReason": 4
}
```

Kurallar:

- Fiyat sifirdan buyuk olmalidir.
- Stok karti, depo ve aktif fiyat liste tanimi mevcut olmalidir.
- Kayit `stockCode + priceListNo + warehouseNo + unitPointer + paymentPlanNo` anahtariyla aranir.
- Kayit varsa yeni fiyat ve audit alanlari guncellenir.
- Kayit yoksa Mikro standart alanlariyla yeni `STOK_SATIS_FIYAT_LISTELERI` satiri olusturulur.
- Daha once iptal/pasif edilmis ayni anahtardaki kayit varsa aktif hale getirilerek guncellenir; ayni anahtarda ikinci kayit uretilmez.
- Upsert transaction isolation seviyesi `Serializable` oldugu icin es zamanli isteklerde mukerrer fiyat kaydi riski engellenir.

Yeni kayit response'u:

```json
{
  "summary": {
    "target": "stok-kartlari/015550/satis-fiyatlari/150",
    "updatedRowCount": 1,
    "updatedAt": "2026-06-25T10:20:00",
    "updateUser": 110
  },
  "created": true,
  "previousPrice": null,
  "salesPrice": {
    "stockCode": "015550",
    "priceListNo": 1,
    "warehouseNo": 150,
    "unitPointer": 1,
    "paymentPlanNo": 0,
    "price": 109.5,
    "currencyType": 0
  }
}
```

Mevcut kayit guncellenirse `created=false` olur ve `previousPrice` eski fiyati tasir.

### Stok Satis Fiyatini Sil

Aktif depo bazli satis fiyatini iptal eder. Fiziksel delete yapilmaz; `sfiyat_iptal`, `sfiyat_hidden`, `sfiyat_kilitli` alanlari set edilir.

`DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/015550/satis-fiyatlari/150?priceListNo=1&paymentPlanNo=0&unitPointer=1`

Query:

- `priceListNo`: varsayilan `1`
- `paymentPlanNo`: varsayilan `0`
- `unitPointer`: varsayilan `1`

Response:

```json
{
  "target": "stok-kartlari/015550/satis-fiyatlari/150",
  "deletedRowCount": 1,
  "deletedAt": "2026-07-02T12:46:00",
  "deleteUser": 110,
  "deletionMode": "soft-delete"
}
```

### Stok Hareket Evraki Getir

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-hareketleri?documentSerie=F110&documentOrderNo=12&documentType=0&movementKind=4&normalReturn=0&warehouseNo=110`

Query:

- `documentSerie`: zorunlu, Mikro `sth_evrakno_seri`
- `documentOrderNo`: zorunlu, Mikro `sth_evrakno_sira`
- `documentType`: opsiyonel, Mikro `sth_evraktip`
- `movementType`: opsiyonel, Mikro `sth_tip`
- `movementKind`: opsiyonel, Mikro `sth_cins`
- `normalReturn`: opsiyonel, Mikro `sth_normal_iade`
- `warehouseNo`: opsiyonel; `sth_giris_depo_no` veya `sth_cikis_depo_no` eslesmesi arar

Response modeli `StockMovementDocumentDto`:

```json
{
  "header": {
    "documentSerie": "F110",
    "documentOrderNo": 12,
    "documentType": 0,
    "movementTypes": [1],
    "movementKind": 4,
    "normalReturn": 0,
    "movementDate": "2026-04-21T00:00:00",
    "documentDate": "2026-04-21T00:00:00",
    "goodsAcceptanceDate": "2026-04-21T00:00:00",
    "documentNo": "",
    "customerCode": "",
    "customerTitle": "",
    "inputWarehouseNo": 0,
    "inputWarehouseName": "",
    "outputWarehouseNo": 110,
    "outputWarehouseName": "KESTEL 1",
    "shippingWarehouseNo": 60,
    "shippingWarehouseName": "NAKLIYE DEPO",
    "description": "Gun sonu zayiat",
    "movementGroupCode1": "VARDIYA-1",
    "movementGroupCode2": "SEF-01",
    "movementGroupCode3": "",
    "customerResponsibilityCenter": "",
    "stockResponsibilityCenter": "",
    "projectCode": "",
    "lineCount": 1,
    "totalQuantity": 2,
    "totalAmount": 0
  },
  "lines": [
    {
      "movementGuid": "d7f6a8ec-9c2b-4e1e-bb1c-6da6cb4a5f67",
      "rowNo": 0,
      "goodsAcceptanceDate": "2026-04-21T00:00:00",
      "stockCode": "015792",
      "stockName": "URUN ADI",
      "unitPointer": 1,
      "unitName": "AD",
      "quantity": 2,
      "secondaryQuantity": 0,
      "unitPrice": 0,
      "amount": 0,
      "description": "Gun sonu zayiat",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": "",
      "inputWarehouseNo": 0,
      "outputWarehouseNo": 110
    }
  ]
}
```

### Stok Hareket Evraki Guncelle

`PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-hareketleri`

Body:

```json
{
  "lookup": {
    "documentSerie": "F110",
    "documentOrderNo": 12,
    "documentType": 0,
    "movementKind": 4,
    "normalReturn": 0,
    "warehouseNo": 110
  },
  "header": {
    "movementDate": "2026-04-21",
    "documentDate": "2026-04-21",
    "goodsAcceptanceDate": "2026-04-21",
    "documentNo": "DUZ-001",
    "description": "Duzeltilen aciklama",
    "shippingWarehouseNo": 60,
    "movementGroupCode1": "VARDIYA-1",
    "movementGroupCode2": "SEF-01"
  },
  "lines": [
    {
      "movementGuid": "d7f6a8ec-9c2b-4e1e-bb1c-6da6cb4a5f67",
      "rowNo": 0,
      "goodsAcceptanceDate": "2026-04-21",
      "stockCode": "015792",
      "unitPointer": 1,
      "quantity": 3,
      "amount": 0,
      "description": "Satir aciklamasi",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": ""
    }
  ]
}
```

Guncellenebilir header alanlari:

- `movementDate`, `documentDate`, `goodsAcceptanceDate`, `documentNo`, `customerCode`
- `inputWarehouseNo`, `outputWarehouseNo`, `shippingWarehouseNo`
- `description`, `movementGroupCode1`, `movementGroupCode2`, `movementGroupCode3`
- `customerResponsibilityCenter`, `stockResponsibilityCenter`, `projectCode`

Guncellenebilir satir alanlari:

- `rowNo`, `goodsAcceptanceDate`, `stockCode`, `unitPointer`, `quantity`, `secondaryQuantity`, `amount`
- `discount1..discount6`, `expense1..expense4`, `taxPointer`, `taxAmount`
- `netWeight`, `grossWeight`, `description`, `partyCode`, `lotNo`, `projectCode`
- `customerResponsibilityCenter`, `stockResponsibilityCenter`, `inputWarehouseNo`, `outputWarehouseNo`

Response `StockMovementDocumentUpdateResponse` doner; `document` alaninda kaydin guncel hali bulunur.

### Stok Hareket Evraki Sil

Evrakin tum satirlarini siler veya iptal eder. Varsayilan davranis soft-delete'tir.

`DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-hareketleri?documentSerie=F110&documentOrderNo=12&documentType=0&movementKind=4&normalReturn=0&warehouseNo=110`

Hard delete:

`DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-hareketleri?documentSerie=F110&documentOrderNo=12&documentType=0&movementKind=4&normalReturn=0&warehouseNo=110&hardDelete=true`

Kurallar:

- Query alani `GET /stok-hareketleri` ile aynidir.
- `hardDelete`: opsiyonel bool. Varsayilan `false`.
- `hardDelete=false`: `sth_iptal`, `sth_hidden`, `sth_degisti`, `sth_lastup_user`, `sth_lastup_date` alanlari guncellenir.
- `hardDelete=true`: `STOK_HAREKETLERI` satirlari fiziksel silinir; bagli `STOK_HAREKETLERI_EK` satirlari da silinir.
- Filtre birden fazla evraka denk gelirse `409 Conflict` doner.
- Eslesen aktif satir yoksa `404 Not Found` doner.
- Basarili islem Belge Akis Takibi'ne `DocumentDeleted` olayi olarak yazilir. Mesaj soft modda "iptal edildi", hard modda "fiziksel olarak silindi" seklindedir.

Response:

```json
{
  "target": "stok-hareketleri/F110/12",
  "deletedRowCount": 3,
  "deletedAt": "2026-07-02T12:46:00",
  "deleteUser": 110,
  "deletionMode": "soft-delete"
}
```

Hard delete response'unda `deletionMode` alani `hard-delete` gelir.

### Sayim Sonucu Fisi Getir

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/sayim-sonuclari?warehouseNo=110&documentNo=25&documentDate=2026-04-21`

Query:

- `warehouseNo`: zorunlu, Mikro `SAYIM_SONUCLARI.sym_depono`
- `documentNo`: zorunlu, Mikro `SAYIM_SONUCLARI.sym_evrakno`
- `documentDate`: zorunlu, Mikro `SAYIM_SONUCLARI.sym_tarihi`

Response modeli `InventoryCountDocumentDto`:

```json
{
  "header": {
    "documentDate": "2026-04-21T00:00:00",
    "createdAt": "2026-04-21T10:30:00",
    "documentNo": 25,
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "name": "REYON SAYIM",
    "lineCount": 2,
    "totalQuantity": 18,
    "lastUpdatedAt": null
  },
  "lines": [
    {
      "countGuid": "d7f6a8ec-9c2b-4e1e-bb1c-6da6cb4a5f67",
      "rowNo": 0,
      "stockCode": "015792",
      "stockName": "URUN ADI",
      "barcode": "8690000000000",
      "unitPointer": 1,
      "unitName": "AD",
      "quantity1": 10,
      "quantity2": 0,
      "quantity3": 0,
      "quantity4": 0,
      "quantity5": 0,
      "rayonCode": "",
      "corridorCode": "",
      "shelfCode": "",
      "partyCode": "REYON SAYIM",
      "lotNo": 0,
      "serialNo": "",
      "special1": "",
      "special2": "",
      "special3": "",
      "lastUpdatedAt": null
    }
  ]
}
```

UI notlari:

- Satir secimi/guncellemesi kesin olarak `lines[].countGuid` ile yapilir.
- Ekranda ana sayim miktari genelde `quantity1` olarak gosterilmelidir; `quantity2..5` Mikro'nun ek miktar kolonlaridir.
- `stockCode`, `barcode`, `unitPointer`, `quantity1..5`, reyon/raf/parti/seri ve `special1..3` alanlari satir duzeltme icindir.

### Sayim Sonucu Fisi Guncelle

`PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/sayim-sonuclari`

Body:

```json
{
  "lookup": {
    "warehouseNo": 110,
    "documentNo": 25,
    "documentDate": "2026-04-21"
  },
  "header": {
    "name": "REYON SAYIM DUZELTILDI"
  },
  "lines": [
    {
      "countGuid": "d7f6a8ec-9c2b-4e1e-bb1c-6da6cb4a5f67",
      "quantity1": 12,
      "barcode": "8690000000000",
      "unitPointer": 1
    }
  ]
}
```

Kurallar:

- Endpoint yeni sayim fisi veya yeni satir olusturmaz; sadece mevcut satirlari gunceller.
- Silme endpoint'i yoktur. Yanlis satiri sifirlamak istenirse `quantity1=0` gibi miktar duzeltmesi UI kararina gore kullanilabilir.
- `header.documentDate`, `header.warehouseNo`, `header.name` gonderilirse tum sayim satirlarina uygulanir.
- Satir alanlari sadece ilgili `countGuid` satirina uygulanir.
- `stockCode` degisirse backend stok kartinin varligini kontrol eder.
- `sym_kilitli=true` olan sayim fislerinde update reddedilir.
- Request body'de `null` alanlar degismez; bos string metin alanini bosaltir.

Response `InventoryCountDocumentUpdateResponse` doner:

```json
{
  "summary": {
    "target": "sayim-sonuclari",
    "updatedRowCount": 2,
    "updatedAt": "2026-08-19T14:30:00",
    "updateUser": 110
  },
  "document": {
    "header": {
      "documentNo": 25,
      "warehouseNo": 110,
      "name": "REYON SAYIM DUZELTILDI",
      "lineCount": 2,
      "totalQuantity": 20
    },
    "lines": [
      {
        "countGuid": "d7f6a8ec-9c2b-4e1e-bb1c-6da6cb4a5f67",
        "stockCode": "015792",
        "quantity1": 12,
        "unitPointer": 1
      }
    ]
  }
}
```

### Cari Hareket Evraki Getir

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/cari-hareketleri?documentSerie=PS110&documentOrderNo=422&documentType=63&movementKind=6&normalReturn=0&customerCode=120.01.03106`

Query:

- `documentSerie`: zorunlu, Mikro `cha_evrakno_seri`
- `documentOrderNo`: zorunlu, Mikro `cha_evrakno_sira`
- `documentType`: opsiyonel, Mikro `cha_evrak_tip`
- `movementType`: opsiyonel, Mikro `cha_tip`
- `movementKind`: opsiyonel, Mikro `cha_cinsi`
- `normalReturn`: opsiyonel, Mikro `cha_normal_Iade`
- `customerCode`: opsiyonel; `cha_kod` veya `cha_ciro_cari_kodu` eslesmesi arar

Response modeli `CustomerMovementDocumentDto`:

```json
{
  "header": {
    "documentSerie": "PS110",
    "documentOrderNo": 422,
    "documentType": 63,
    "movementTypes": [0],
    "movementKind": 6,
    "normalReturn": 0,
    "movementDate": "2026-04-21T00:00:00",
    "documentDate": "2026-04-21T00:00:00",
    "documentNo": "PS1102026000000422",
    "customerCode": "120.01.03106",
    "turnoverCustomerCode": "120.01.03106",
    "customerTitle": "CARI UNVAN",
    "description": "Aciklama",
    "sellerCode": "",
    "projectCode": "",
    "responsibilityCenter": "",
    "lineCount": 1,
    "totalQuantity": 1,
    "totalAmount": 100,
    "totalSubAmount": 100
  },
  "lines": [
    {
      "movementGuid": "9f3db1de-50ef-48a0-a617-7cf5634c4f3a",
      "rowNo": 0,
      "customerCode": "120.01.03106",
      "turnoverCustomerCode": "120.01.03106",
      "customerTitle": "CARI UNVAN",
      "movementType": 0,
      "movementKind": 6,
      "normalReturn": 0,
      "quantity": 1,
      "amount": 100,
      "subAmount": 100,
      "dueDay": 0,
      "description": "Aciklama",
      "sellerCode": "",
      "projectCode": "",
      "responsibilityCenter": ""
    }
  ]
}
```

### Cari Hareket Evraki Guncelle

`PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/cari-hareketleri`

Body:

```json
{
  "lookup": {
    "documentSerie": "PS110",
    "documentOrderNo": 422,
    "documentType": 63,
    "movementKind": 6,
    "normalReturn": 0,
    "customerCode": "120.01.03106"
  },
  "header": {
    "movementDate": "2026-04-21",
    "documentDate": "2026-04-21",
    "documentNo": "PS1102026000000422",
    "description": "Duzeltilen cari aciklama",
    "customerCode": "120.01.03106",
    "turnoverCustomerCode": "120.01.03106"
  },
  "lines": [
    {
      "movementGuid": "9f3db1de-50ef-48a0-a617-7cf5634c4f3a",
      "amount": 125,
      "subAmount": 125,
      "quantity": 1,
      "description": "Satir aciklamasi"
    }
  ]
}
```

Guncellenebilir header alanlari:

- `movementDate`, `documentDate`, `documentNo`
- `customerCode`, `turnoverCustomerCode`
- `description`, `sellerCode`, `projectCode`, `responsibilityCenter`

Guncellenebilir satir alanlari:

- `rowNo`, `customerCode`, `turnoverCustomerCode`
- `quantity`, `amount`, `subAmount`, `dueDay`
- `discount1..discount6`, `expense1..expense4`, `tax1..tax5`
- `description`, `sellerCode`, `projectCode`, `responsibilityCenter`

### Cari Hareket Evraki Sil

Evrakin tum satirlarini siler veya iptal eder. Varsayilan davranis soft-delete'tir.

`DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/cari-hareketleri?documentSerie=PS110&documentOrderNo=422&documentType=63&movementKind=6&normalReturn=0&customerCode=120.01.03106`

Hard delete:

`DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/cari-hareketleri?documentSerie=PS110&documentOrderNo=422&documentType=63&movementKind=6&normalReturn=0&customerCode=120.01.03106&hardDelete=true`

Kurallar:

- Query alani `GET /cari-hareketleri` ile aynidir.
- `hardDelete`: opsiyonel bool. Varsayilan `false`.
- `hardDelete=false`: `cha_iptal`, `cha_hidden`, `cha_degisti`, `cha_lastup_user`, `cha_lastup_date` alanlari guncellenir.
- `hardDelete=true`: `CARI_HESAP_HAREKETLERI` satirlari fiziksel silinir.
- Filtre birden fazla evraka denk gelirse `409 Conflict` doner.
- Eslesen aktif satir yoksa `404 Not Found` doner.
- Basarili islem Belge Akis Takibi'ne `DocumentDeleted` olayi olarak yazilir. Mesaj soft modda "iptal edildi", hard modda "fiziksel olarak silindi" seklindedir.

Response:

```json
{
  "target": "cari-hareketleri/PS110/422",
  "deletedRowCount": 1,
  "deletedAt": "2026-07-02T12:46:00",
  "deleteUser": 110,
  "deletionMode": "soft-delete"
}
```

Hard delete response'unda `deletionMode` alani `hard-delete` gelir.

### Firma Siparis Evraki Getir

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/firma-siparisleri?documentSerie=F110&documentOrderNo=2841&orderType=1&warehouseNo=110&customerCode=120.01.03106`

Query:

- `documentSerie`: zorunlu, Mikro `SIPARISLER.sip_evrakno_seri`
- `documentOrderNo`: zorunlu, Mikro `SIPARISLER.sip_evrakno_sira`
- `orderType`: opsiyonel, Mikro `sip_tip`; mevcut siparis listelerinde `1=verilen`, `0=alinan` olarak kullanilir
- `orderKind`: opsiyonel, Mikro `sip_cins`
- `warehouseNo`: opsiyonel, Mikro `sip_depono`
- `customerCode`: opsiyonel, Mikro `sip_musteri_kod`

Response modeli `CompanyOrderDocumentDto` doner. Header; seri/sira, siparis tipi/cinsi, tarih, teslim tarihi, belge no, depo, cari, aciklama, doviz, kapanma ve toplam alanlarini icerir. Satirlar `orderGuid`, stok, birim, miktar, teslim miktari, kalan miktar, fiyat, tutar, iskonto/masraf, vergi, aciklama, paket, parti/lot, proje ve sorumluluk merkezi alanlarini icerir.

### Firma Siparis Evraki Guncelle

`PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/firma-siparisleri`

Body:

```json
{
  "lookup": {
    "documentSerie": "F110",
    "documentOrderNo": 2841,
    "orderType": 1,
    "warehouseNo": 110,
    "customerCode": "120.01.03106"
  },
  "header": {
    "orderDate": "2026-04-21",
    "deliveryDate": "2026-04-24",
    "documentDate": "2026-04-21",
    "documentNo": "DUZ-001",
    "description1": "Duzeltilen aciklama",
    "warehouseNo": 110,
    "customerCode": "120.01.03106"
  },
  "lines": [
    {
      "orderGuid": "9f3db1de-50ef-48a0-a617-7cf5634c4f3a",
      "rowNo": 0,
      "stockCode": "015792",
      "unitPointer": 1,
      "quantity": 12,
      "deliveredQuantity": 2,
      "unitPrice": 10.5,
      "amount": 126,
      "description1": "Satir aciklamasi"
    }
  ]
}
```

Guncellenebilir header alanlari:

- `orderDate`, `deliveryDate`, `documentDate`, `documentNo`
- `customerCode`, `warehouseNo`, `sellerCode`
- `description1`, `description2`, `deliveryType`, `addressNo`
- `currencyType`, `currencyRate`, `alternativeCurrencyRate`
- `canBeCalled`, `isClosed`, `closeReasonCode`
- `projectCode`, `customerResponsibilityCenter`, `stockResponsibilityCenter`

Guncellenebilir satir alanlari:

- `rowNo`, `deliveryDate`, `stockCode`, `unitPointer`
- `quantity`, `deliveredQuantity`, `unitPrice`, `amount`
- `discount1..discount6`, `expense1..expense4`, `taxPointer`, `taxAmount`
- `description1`, `description2`, `packageCode`, `partyCode`, `lotNo`
- `projectCode`, `customerResponsibilityCenter`, `stockResponsibilityCenter`
- `canBeCalled`, `isClosed`, `closeReasonCode`

Response `CompanyOrderDocumentUpdateResponse` doner; `document` alaninda kaydin guncel hali bulunur.

### Firma Siparis Evraki Sil

`DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/firma-siparisleri?documentSerie=F110&documentOrderNo=2841&orderType=1&warehouseNo=110`

Hard delete:

`DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/firma-siparisleri?documentSerie=F110&documentOrderNo=2841&orderType=1&warehouseNo=110&hardDelete=true`

Kurallar:

- Query alani `GET /firma-siparisleri` ile aynidir.
- `hardDelete=false`: `sip_iptal`, `sip_hidden`, `sip_degisti`, `sip_lastup_user`, `sip_lastup_date` alanlari guncellenir.
- `hardDelete=true`: eslesen `SIPARISLER` satirlari fiziksel silinir.
- Seri/sira birden fazla `sip_tip` veya `sip_cins` kombinasyonuna denk gelirse `409 Conflict` doner; UI `orderType` veya `orderKind` filtresi istemelidir.

### Depo Siparis Evraki Getir

`GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/depo-siparisleri?documentSerie=D110&documentOrderNo=1915&warehouseNo=110`

Query:

- `documentSerie`: zorunlu, Mikro `DEPOLAR_ARASI_SIPARISLER.ssip_evrakno_seri`
- `documentOrderNo`: zorunlu, Mikro `ssip_evrakno_sira`
- `warehouseNo`: opsiyonel; `ssip_girdepo` veya `ssip_cikdepo` eslesmesi arar
- `inWarehouseNo`: opsiyonel, Mikro `ssip_girdepo`
- `outWarehouseNo`: opsiyonel, Mikro `ssip_cikdepo`

Response modeli `WarehouseOrderDocumentDto` doner. Header; seri/sira, siparis tarihi, teslim tarihi, belge no, giris/cikis depo, aciklama, kapanma ve toplam alanlarini icerir. Satirlar `orderGuid`, stok, birim, miktar, teslim miktari, kalan miktar, fiyat, tutar, giris/cikis depo, aciklama, paket, proje ve sorumluluk merkezi alanlarini icerir.

### Depo Siparis Evraki Guncelle

`PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/depo-siparisleri`

Body:

```json
{
  "lookup": {
    "documentSerie": "D110",
    "documentOrderNo": 1915,
    "warehouseNo": 110
  },
  "header": {
    "orderDate": "2026-04-21",
    "deliveryDate": "2026-04-24",
    "documentDate": "2026-04-21",
    "documentNo": "DUZ-DEP-001",
    "inWarehouseNo": 110,
    "outWarehouseNo": 50,
    "description": "Duzeltilen depo siparisi"
  },
  "lines": [
    {
      "orderGuid": "d7f6a8ec-9c2b-4e1e-bb1c-6da6cb4a5f67",
      "rowNo": 0,
      "stockCode": "015792",
      "unitPointer": 1,
      "quantity": 24,
      "deliveredQuantity": 4,
      "unitPrice": 8.5,
      "amount": 204,
      "description": "Satir aciklamasi"
    }
  ]
}
```

Guncellenebilir header alanlari:

- `orderDate`, `deliveryDate`, `documentDate`, `documentNo`
- `inWarehouseNo`, `outWarehouseNo`, `description`
- `isClosed`, `closeReasonCode`
- `projectCode`, `responsibilityCenter`

Guncellenebilir satir alanlari:

- `rowNo`, `deliveryDate`, `stockCode`, `unitPointer`
- `quantity`, `deliveredQuantity`, `unitPrice`, `amount`
- `description`, `inWarehouseNo`, `outWarehouseNo`
- `isClosed`, `closeReasonCode`, `packageCode`, `projectCode`, `responsibilityCenter`

Response `WarehouseOrderDocumentUpdateResponse` doner; `document` alaninda kaydin guncel hali bulunur.

### Depo Siparis Evraki Sil

`DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/depo-siparisleri?documentSerie=D110&documentOrderNo=1915&warehouseNo=110`

Hard delete:

`DELETE /api/duzeltme-islemleri/mikro-evrak-duzenleme/depo-siparisleri?documentSerie=D110&documentOrderNo=1915&warehouseNo=110&hardDelete=true`

Kurallar:

- Query alani `GET /depo-siparisleri` ile aynidir.
- `hardDelete=false`: `ssip_iptal`, `ssip_hidden`, `ssip_degisti`, `ssip_lastup_user`, `ssip_lastup_date` alanlari guncellenir.
- `hardDelete=true`: eslesen `DEPOLAR_ARASI_SIPARISLER` satirlari fiziksel silinir.
- UI varsayilan olarak soft-delete kullanmali, hard delete icin ayri onay istemelidir.

UI is akisi onerisi:

1. Kullanici duzeltme tipini secer: Stok Karti, Depo Karti, Cari Karti, Stok Hareketi, Cari Hareketi, Firma Siparisi veya Depo Siparisi.
2. Kart duzeltmelerinde once arama endpoint'iyle kayit secilir, sonra detay endpoint'iyle form doldurulur.
3. Stok/cari hareketinde seri-sira girilir; evrak tipi/cins/iade alanlari varsa query'e eklenir. Siparislerde seri-sira girilir; firma siparisinde `orderType/orderKind`, depo siparisinde depo filtreleriyle daraltma yapilir.
4. Hareket detay response'u geldikten sonra UI `movementGuid`, siparis detay response'u geldikten sonra `orderGuid` alanlarini satir gridinde gizli anahtar olarak saklar.
5. Kullanici sadece degisen alanlari gonderir; degismeyen alanlar `null` veya body disinda birakilir.
6. `409 Conflict` gelirse filtreleri daraltma mesaji gosterilir.
7. Basarili `PUT` response'u guncel belge/kart halini dondurdugu icin UI gridini bu response ile yeniler.
8. Silme aksiyonunda varsayilan soft-delete kullanilmalidir. Hard delete icin ayri bir onay modalinda evrak seri/sira ve depo bilgisi tekrar gosterilip `hardDelete=true` gonderilmelidir.

## Stok Islemleri

### Zayiat Fisleri Liste

Depodan cikilan zayiat fislerinin gecmis listesini getirir.

`GET /api/stok-islemleri/zayiat-fisleri?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-30`

Yetki:

- `stok-islemleri.zayiat-fisleri.list`

Not:

- response modeli `StockReceiptListItemDto` doner
- tarih filtresi Mikro tarafinda `STOK_HAREKETLERI.sth_belge_tarih` uzerinden uygulanir
- filtre karsiligi: `sth_evraktip = 0`, `sth_tip = 1`, `sth_normal_iade = 0`, `sth_cins = 4`, `sth_cikis_depo_no = WarehouseNo`
- `creator` alani `sth_HareketGrupKodu1`, `acceptor` alani `sth_HareketGrupKodu2` kolonundan gelir
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

### Zayiat Fisi Detay

Zayiat fisinin header ve kalem detayini getirir.

`GET /api/stok-islemleri/zayiat-fisleri/F110/12?warehouseNo=110`

Yetki:

- `stok-islemleri.zayiat-fisleri.detail`

Not:

- response modeli `StockReceiptDetailDto` doner
- filtre karsiligi: `sth_evraktip = 0`, `sth_tip = 1`, `sth_normal_iade = 0`, `sth_cins = 4`, `sth_cikis_depo_no = warehouseNo`
- `header.workOrderExpenseCode` zayiat fislerinde bos gelir
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

### Zayiat Fisi Olustur

Secili kullanici deposu icin yeni zayiat fisi yazar.

`POST /api/stok-islemleri/zayiat-fisleri`

Yetki:

- `stok-islemleri.zayiat-fisleri.create`

Onemli not:

- `*.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. Ilgili stok menusunde `all-warehouses` yetkisi olan kullanici baska depo adina fis olusturacaksa body'de opsiyonel `warehouseNo` gonderebilir
- backend `STOK_HAREKETLERI` tablosuna `sth_evraktip = 0`, `sth_tip = 1`, `sth_normal_iade = 0`, `sth_cins = 4` olarak kayit yazar
- `sth_cari_kodu` bos yazilir; bu fislerde cari baglantisi yoktur
- `creator` ve `acceptor` alanlari sirasiyla `sth_HareketGrupKodu1` ve `sth_HareketGrupKodu2` kolonlarina yazilir
- `documentSerie` backend tarafinda `F{islemDepoNo}` olarak uretilir
- `documentOrderNo` ayni seri ve zayiat fis turu icin write DB'deki mevcut maksimum sira okunarak uretilir
- Satir tutari eski sistemle uyumlu olacak sekilde create aninda hesaplanir ve `STOK_HAREKETLERI.sth_tutar` alanina yazilir.
- Birim fiyat icin ilgili stogun `SATINALMA_SARTLARI` tablosundaki en guncel kaydi kullanilir: `sas_net_alis_kdvli - (sas_isk_miktar1..6 toplamı)`.
- Ilgili stok icin satin alma sarti bulunamazsa satir tutari `0` yazilir ve backend log'a uyarı duser.
- Response `totalAmount`, yazilan satirlarin `sth_tutar` toplamidir. Liste ve detay ekranlari da kayitli `sth_tutar` alanini okur; detay endpointi sonradan fiyat hesaplamaz.

Request:

```json
{
  "clientRequestId": "3e39228d-5429-4f1e-b521-60b7e82b2c25",
  "creator": "VARDIYA-1",
  "acceptor": "SEF-01",
  "movementDate": "2026-04-21",
  "documentDate": "2026-04-21",
  "documentNo": "",
  "description": "Gun sonu zayiat",
  "lines": [
    {
      "stockCode": "015792",
      "quantity": 2,
      "unitPointer": 1,
      "description": "",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": ""
    }
  ]
}
```

Response:

```json
{
  "documentSerie": "F110",
  "documentOrderNo": 12,
  "movementDate": "2026-04-21T00:00:00",
  "documentDate": "2026-04-21T00:00:00",
  "documentNo": "",
  "warehouseNo": 110,
  "creator": "VARDIYA-1",
  "acceptor": "SEF-01",
  "lineCount": 1,
  "totalQuantity": 2,
  "totalAmount": 0,
  "writeConnectionName": "testMikroConnection"
}
```

### Masraf Fisleri Liste

Depodan cikilan masraf fislerinin gecmis listesini getirir.

`GET /api/stok-islemleri/masraf-fisleri?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-30`

Yetki:

- `stok-islemleri.masraf-fisleri.list`

Not:

- response modeli `StockReceiptListItemDto` doner
- tarih filtresi Mikro tarafinda `STOK_HAREKETLERI.sth_belge_tarih` uzerinden uygulanir
- filtre karsiligi: `sth_evraktip = 0`, `sth_tip = 1`, `sth_normal_iade = 0`, `sth_cins = 5`, `sth_cikis_depo_no = WarehouseNo`
- `workOrderExpenseCode` alani Mikro'daki `sth_isemri_gider_kodu` kolonundan gelir ve bu modulde varsayilan olarak `0032` yazilir
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

### Masraf Fisi Detay

Masraf fisinin header ve kalem detayini getirir.

`GET /api/stok-islemleri/masraf-fisleri/F110/8?warehouseNo=110`

Yetki:

- `stok-islemleri.masraf-fisleri.detail`

Not:

- response modeli `StockReceiptDetailDto` doner
- filtre karsiligi: `sth_evraktip = 0`, `sth_tip = 1`, `sth_normal_iade = 0`, `sth_cins = 5`, `sth_cikis_depo_no = warehouseNo`
- `header.workOrderExpenseCode` genelde `0032` gelir
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

### Masraf Fisi Olustur

Secili kullanici deposu icin yeni masraf fisi yazar.

`POST /api/stok-islemleri/masraf-fisleri`

Yetki:

- `stok-islemleri.masraf-fisleri.create`

Onemli not:

- `*.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. Ilgili stok menusunde `all-warehouses` yetkisi olan kullanici baska depo adina fis olusturacaksa body'de opsiyonel `warehouseNo` gonderebilir
- backend `STOK_HAREKETLERI` tablosuna `sth_evraktip = 0`, `sth_tip = 1`, `sth_normal_iade = 0`, `sth_cins = 5` olarak kayit yazar
- `sth_isemri_gider_kodu` alanina sabit olarak `0032` yazilir
- `sth_cari_kodu` bos yazilir; bu fislerde cari baglantisi yoktur
- `creator` ve `acceptor` alanlari sirasiyla `sth_HareketGrupKodu1` ve `sth_HareketGrupKodu2` kolonlarina yazilir
- `documentSerie` backend tarafinda `F{islemDepoNo}` olarak uretilir
- `documentOrderNo` ayni seri ve masraf fis turu icin write DB'deki mevcut maksimum sira okunarak uretilir
- Satir tutari eski sistemle uyumlu olacak sekilde create aninda hesaplanir ve `STOK_HAREKETLERI.sth_tutar` alanina yazilir.
- Birim fiyat icin ilgili stogun `SATINALMA_SARTLARI` tablosundaki en guncel kaydi kullanilir: `sas_net_alis_kdvli - (sas_isk_miktar1..6 toplami)`.
- Ilgili stok icin satin alma sarti bulunamazsa satir tutari `0` yazilir ve backend log'a uyari duser.
- Response `totalAmount`, yazilan satirlarin `sth_tutar` toplamidir. Liste ve detay ekranlari da kayitli `sth_tutar` alanini okur; detay endpointi sonradan fiyat hesaplamaz.

Request:

```json
{
  "clientRequestId": "bc00ec38-5fbb-4669-87d5-7480f88e1987",
  "creator": "VARDIYA-2",
  "acceptor": "SEF-02",
  "movementDate": "2026-04-21",
  "documentDate": "2026-04-21",
  "documentNo": "",
  "description": "Ic tuketim masrafi",
  "lines": [
    {
      "stockCode": "018888",
      "quantity": 5,
      "unitPointer": 1,
      "description": "",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": ""
    }
  ]
}
```

Response:

```json
{
  "documentSerie": "F110",
  "documentOrderNo": 8,
  "movementDate": "2026-04-21T00:00:00",
  "documentDate": "2026-04-21T00:00:00",
  "documentNo": "",
  "warehouseNo": 110,
  "creator": "VARDIYA-2",
  "acceptor": "SEF-02",
  "lineCount": 1,
  "totalQuantity": 5,
  "totalAmount": 0,
  "writeConnectionName": "testMikroConnection"
}
```

### Stock Receipt Detay Response

Zayiat ve masraf fislerinin detay endpointleri ayni response modelini kullanir.

```json
{
  "header": {
    "documentDate": "2026-04-21T00:00:00",
    "movementCreateDate": "2026-04-21T10:15:00",
    "movementDate": "2026-04-21T00:00:00",
    "documentNo": "",
    "documentSerie": "F110",
    "documentOrderNo": 12,
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "creator": "VARDIYA-1",
    "acceptor": "SEF-01",
    "workOrderExpenseCode": "",
    "documentType": 0,
    "movementType": 1,
    "movementGenre": 4,
    "description": "Gun sonu zayiat",
    "lineCount": 1,
    "totalQuantity": 2,
    "totalAmount": 0
  },
  "items": [
    {
      "rowNo": 0,
      "stockCode": "015792",
      "stockName": "URUN ADI",
      "unitName": "ADET",
      "unitPointer": 1,
      "quantity": 2,
      "quantity2": 0,
      "unitPrice": 0,
      "lineAmount": 0,
      "description": "Gun sonu zayiat",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": ""
    }
  ]
}
```

### Sayim Sonuclari Liste

Depodaki sayim sonuclarinin gecmis listesini getirir.

`GET /api/stok-islemleri/sayim-sonuclari?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-30`

Yetki:

- `stok-islemleri.sayim-sonuclari.list`

Not:

- response modeli `InventoryCountListItemDto` doner
- tarih filtresi Mikro tarafinda `SAYIM_SONUCLARI.sym_tarihi` uzerinden uygulanir
- filtre karsiligi: `sym_depono = WarehouseNo`
- liste kayitlari `sym_evrakno + sym_tarihi` bazinda gruplanir
- `name` alani `sym_parti_kodu` kolonundan gelir
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

### Sayim Sonucu Detay

Belge numarasi ve belge tarihi ile sayim kalem detayini getirir.

`GET /api/stok-islemleri/sayim-sonuclari/25?documentDate=2026-04-21&warehouseNo=110`

Yetki:

- `stok-islemleri.sayim-sonuclari.detail`

Not:

- response modeli `InventoryCountDetailDto` doner
- filtre karsiligi: `sym_depono = warehouseNo`, `sym_evrakno = documentNo`, `sym_tarihi = documentDate`
- `items[].barcode` dogrudan `sym_barkod` kolonundan gelir
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

### Sayim Sonucu Olustur

Secili kullanici deposu icin yeni sayim sonucu yazilir.

`POST /api/stok-islemleri/sayim-sonuclari`

Yetki:

- `stok-islemleri.sayim-sonuclari.create`

Onemli not:

- `*.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. `stok-islemleri.sayim-sonuclari.all-warehouses` yetkisi olan kullanici baska depo adina sayim sonucu olusturacaksa body'de opsiyonel `warehouseNo` gonderebilir
- Mobil offline pilotta request'e `clientRequestId` eklenmelidir.
- backend `SAYIM_SONUCLARI` tablosuna yeni satirlar yazar
- `documentNo` ayni depo icin `sym_evrakno` maksimum degerinin bir fazlasi olarak uretilir
- `name` alani `sym_parti_kodu` kolonuna yazilir
- satirda `barcode` bos gelirse backend `BARKOD_TANIMLARI` tablosundan stok koduna gore barkod bulmaya calisir
- eski yapiya gore `sym_fileid = 28`, `sym_create_user = 39`, `sym_lastup_user = 39` degerleri kullanilir
- Mobil retry icin backend `clientRequestId` izini `FR` prefixli trace olarak `SAYIM_SONUCLARI.sym_serino` alanina yazar ve ayni istek tekrar geldiginde bu iz uzerinden sonucu toparlayabilir.
- Ayni `clientRequestId` ile ayni payload tekrar gonderilirse backend ayni business response'u dondurmeye calisir.
- Ayni `clientRequestId` ile farkli payload gonderilirse `409 Conflict` doner.
- Ayni `clientRequestId` halen isleniyorsa `409 Conflict` doner.

Request:

```json
{
  "clientRequestId": "7c9b31f6-1ab4-4ed1-b02b-2a90e5e7d3fd",
  "name": "Nisan 2026 Genel Sayim",
  "documentDate": "2026-04-21",
  "lines": [
    {
      "stockCode": "015792",
      "quantity": 24,
      "barcode": "8690000000012",
      "unitPointer": 1
    },
    {
      "stockCode": "018888",
      "quantity": 5,
      "unitPointer": 1
    }
  ]
}
```

Response:

```json
{
  "documentNo": 25,
  "documentDate": "2026-04-21T00:00:00",
  "warehouseNo": 110,
  "name": "Nisan 2026 Genel Sayim",
  "lineCount": 2,
  "totalQuantity": 29,
  "writeConnectionName": "testMikroConnection"
}
```

Offline status endpoint:

`GET /api/stok-islemleri/sayim-sonuclari/offline-sync/{clientRequestId}`

Yetki:

- `stok-islemleri.sayim-sonuclari.create`

Onemli not:

- Bu endpoint sadece ayni kullanicinin daha once acmis oldugu offline create kaydini sorgular.
- Kayit bulunamazsa `404 Not Found` doner.
- Sonuc ilk POST cevabinda cihaza donemediyse backend kaydi `sym_serino` izinden tekrar toparlayabilir.
- `status = Completed` ise `result` icinde asagidaki `CreateInventoryCountResponse` modeli bulunur.

Ornek response:

```json
{
  "clientRequestId": "7c9b31f6-1ab4-4ed1-b02b-2a90e5e7d3fd",
  "operationCode": "stok-islemleri.sayim-sonuclari.create",
  "status": "Completed",
  "createdAtUtc": "2026-05-06T13:20:11Z",
  "completedAtUtc": "2026-05-06T13:20:13Z",
  "errorMessage": null,
  "result": {
    "documentNo": 25,
    "documentDate": "2026-04-21T00:00:00",
    "warehouseNo": 110,
    "name": "Nisan 2026 Genel Sayim",
    "lineCount": 2,
    "totalQuantity": 29,
    "writeConnectionName": "testMikroConnection"
  }
}
```

### Sayim Sonucu Detay Response

```json
{
  "header": {
    "documentDate": "2026-04-21T00:00:00",
    "createdAt": "2026-04-21T10:15:00",
    "documentNo": 25,
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "name": "Nisan 2026 Genel Sayim",
    "lineCount": 2,
    "totalQuantity": 29
  },
  "items": [
    {
      "rowNo": 0,
      "stockCode": "015792",
      "stockName": "URUN ADI",
      "barcode": "8690000000012",
      "unitName": "ADET",
      "unitPointer": 1,
      "quantity1": 24,
      "quantity2": 0,
      "quantity3": 0,
      "quantity4": 0,
      "quantity5": 0
    }
  ]
}
```

Sayim sonucu offline UI akisi:

- Mobil uygulama local veritabaninda sayim taslagini `pending-sync` durumda tutmali ve daha ilk kayitta bir `clientRequestId` uretmelidir.
- Kullanici offline iken satir ekleme, miktar guncelleme ve taslak kaydetme tamamen cihazda yapilabilir.
- Senkron zamani geldiginde `POST /api/stok-islemleri/sayim-sonuclari` ayni `clientRequestId` ile gonderilmelidir.
- POST timeout olursa UI hemen yeni GUID uretmemeli; once ayni `clientRequestId` ile retry yapmali, sonuc yine belirsizse `GET /api/stok-islemleri/sayim-sonuclari/offline-sync/{clientRequestId}` cagirip kesin durumu gormelidir.
- `409 Conflict` ve mesaj "different request payload" anlamina geliyorsa kullanici taslagi degistirmistir; UI yeni senkron denemesi icin yeni `clientRequestId` uretmelidir.
- `409 Conflict` ve mesaj "already being processed" anlamina geliyorsa UI gecici bekleme/guncelleme durumu gostermeli ve status endpoint'ini poll etmelidir.
- `status = Completed` alindiginda local taslak artik server'da fis oldugu icin kapatilabilir; response icindeki `documentNo` ve `documentDate` ile detay ekranina gidilebilir.

### Stok Anomali Merkezi

Stok anomali merkezi, Mikro verisini tarayip supheli durumlari Auth veritabanindaki `stock_anomalies` tablosunda takip kaydi olarak saklar. Mikro'ya yazma yapmaz. `stok-islemleri.stok-anomali-merkezi.all-warehouses` yetkisi olan kullanici tum depolari gorur; diger kullanici sadece ana deposu kendi JWT deposu olan anomalileri gorur ve tarar. `relatedWarehouseNo` bilgi amaclidir; tek basina depo yetki kapsamini genisletmez.

Yakaladigi anomali tipleri:

- `NegativeStock`: depo + stok bazinda bakiye eksiye dusmus
- `DuplicateDocument`: ayni belge/stok/miktar/depo kombinasyonu tekrar etmis
- `ReceivingDifference`: depolar arasi sevkte sevk miktari ile kabul miktari farkli
- `HighQuantity`: hareket miktari son 30 gun ortalamasinin ve minimum limitin uzerinde
- `DormantStock`: depoda stok var ama uzun suredir hareket yok
- `PendingInterWarehouseTransfer`: depolar arasi sevk bekleme limitini asmis ama kabul edilmemis

Endpointler:

| Endpoint | Aciklama | Yetki |
| --- | --- | --- |
| `GET /api/stok-islemleri/stok-anomali-merkezi` | Anomali listesini getirir | `stok-islemleri.stok-anomali-merkezi.list` |
| `GET /api/stok-islemleri/stok-anomali-merkezi/satin-almacilar` | Anomalilerdeki satin almacilari ve anomali sayilarini getirir | `stok-islemleri.stok-anomali-merkezi.list` |
| `GET /api/stok-islemleri/stok-anomali-merkezi/{id}` | Anomali detayini ve olay gecmisini getirir | `stok-islemleri.stok-anomali-merkezi.detail` |
| `POST /api/stok-islemleri/stok-anomali-merkezi/tara` | Mikro verisini tarar ve anomali kayitlarini acar/gunceller | `stok-islemleri.stok-anomali-merkezi.scan` |
| `POST /api/stok-islemleri/stok-anomali-merkezi/{id}/durum` | Anomali durumunu gunceller | `stok-islemleri.stok-anomali-merkezi.update` |

Liste query:

```text
warehouseNo?: int
type?: NegativeStock | DuplicateDocument | ReceivingDifference | HighQuantity | DormantStock | PendingInterWarehouseTransfer
status?: Open | Acknowledged | Resolved | Ignored
severity?: Low | Medium | High | Critical
productManagerCode?: string; satin almacinin Mikro personel/sorumlu kodu
hasProductManager?: bool; true=atanmis, false=atanmamis urunler
startDate?: yyyy-MM-dd
endDate?: yyyy-MM-dd
search?: string
take?: 1..500, varsayilan 100
```

Liste response:

```json
{
  "totalCount": 2,
  "summary": {
    "openCount": 2,
    "acknowledgedCount": 0,
    "resolvedCount": 0,
    "ignoredCount": 0,
    "criticalCount": 1,
    "highCount": 1
  },
  "items": [
    {
      "id": "0aa4b4e1-c8bd-4b5b-9e39-5a9b51a2fba1",
      "type": "NegativeStock",
      "severity": "Critical",
      "status": "Open",
      "warehouseNo": 110,
      "relatedWarehouseNo": null,
      "warehouseName": "KESTEL 1",
      "relatedWarehouseName": null,
      "productCode": "015792",
      "productName": "URUN ADI",
      "productManagerCode": "SA001",
      "productManagerName": "AYSE YILMAZ",
      "documentSerie": null,
      "documentOrderNo": null,
      "documentNo": null,
      "quantity": -12,
      "expectedQuantity": 0,
      "actualQuantity": -12,
      "averageQuantity": null,
      "occurredAtUtc": null,
      "message": "Depo stok bakiyesi eksiye dusmus. Mevcut stok: -12.",
      "firstDetectedAtUtc": "2026-07-02T08:30:00Z",
      "lastDetectedAtUtc": "2026-07-02T08:30:00Z"
    }
  ]
}
```

Satin almacilar lookup:

`GET /api/stok-islemleri/stok-anomali-merkezi/satin-almacilar?warehouseNo=110&status=Open`

- `warehouseNo` depo yetki kapsamina tabidir; depo kullanicisi sadece ana deposu kendi deposu olan anomalileri gorur.
- `status` opsiyoneldir ve varsayilan `Open` degeridir.
- sadece secilen kapsamdaki anomalilerde bulunan satin almacilar doner.
- sorumlusu olmayan anomaliler `code=""`, `name="ATANMAMIS"`, `isAssigned=false` satirinda gruplanir.

```json
[
  {
    "code": "SA001",
    "name": "AYSE YILMAZ",
    "anomalyCount": 14,
    "isAssigned": true
  },
  {
    "code": "",
    "name": "ATANMAMIS",
    "anomalyCount": 3,
    "isAssigned": false
  }
]
```

Tarama:

`POST /api/stok-islemleri/stok-anomali-merkezi/tara`

Request:

```json
{
  "warehouseNo": 110,
  "startDate": "2026-07-01",
  "endDate": "2026-07-02",
  "dormantDays": 90,
  "pendingTransferHours": 24,
  "highQuantityLookbackDays": 30,
  "highQuantityMultiplier": 3,
  "highQuantityMinimum": 100,
  "takePerRule": 250
}
```

Not:

- `stok-islemleri.stok-anomali-merkezi.all-warehouses` yetkisi olan kullanici `warehouseNo` bos gonderirse tum depolar taranir.
- Depo kullanicisi `warehouseNo` gonderse bile backend JWT icindeki kendi deposunu kullanir; tarama sonucu baska ana depo adina anomali acmaz.
- `startDate/endDate` duplicate belge, mal kabul farki ve yuksek miktar kontrollerinde kullanilir.
- Eksi stok ve hareketsiz stok kontrolleri mevcut bakiye uzerinden calisir.
- `takePerRule`, her kuralin tek taramada en fazla kac sonuc yazacagini belirler.
- Tarama sorgulari buyuk Mikro tablolarinda calistigi icin UI ayni anda birden fazla `tara` istegi baslatmamali; buton tarama bitene kadar disabled/loading durumda kalmalidir.
- Tum depo taramasi yetkiyle mumkun olsa da yogun sistemlerde UI varsayilan olarak secili depo veya kisa tarih araligi ile taramayi tesvik etmelidir.
- Backend her kurali ayri calistirir ve sonuc kayitlarini kural bazinda sinirlar; `takePerRule` buyutuldukce Mikro sorgu suresi artabilir.
- kurallar tamamlandiktan sonra urunler Mikro'dan toplu zenginlestirilir; once `STOK_DEPO_DETAYLARI.sdp_UrunSorumlusuKodu`, bos ise `STOKLAR.sto_urun_sorkod` kullanilir ve ad/soyad `CARI_PERSONEL_TANIMLARI` tablosundan alinir.
- migration sonrasi eski anomalilerin satin almacisi ilk yeni taramada doldurulur.

Response:

```json
{
  "startedAtUtc": "2026-07-02T08:30:00Z",
  "finishedAtUtc": "2026-07-02T08:30:04Z",
  "detectedCount": 6,
  "rules": [
    { "type": "NegativeStock", "detectedCount": 1, "error": null },
    { "type": "DuplicateDocument", "detectedCount": 0, "error": null },
    { "type": "ReceivingDifference", "detectedCount": 2, "error": null },
    { "type": "HighQuantity", "detectedCount": 1, "error": null },
    { "type": "DormantStock", "detectedCount": 2, "error": null },
    { "type": "PendingInterWarehouseTransfer", "detectedCount": 0, "error": null }
  ]
}
```

Herhangi bir kural SQL timeout veya benzeri bir sebeple tamamlanamazsa endpoint komple `500` donmez; ilgili kural `rules[].error` alaninda hata mesajiyla doner, diger kurallarin yakaladigi anomaliler yine kaydedilir. UI `rules[].error` dolu olan kurallari kismi basarisiz olarak gostermeli, `detectedCount` ve hatasiz kurallardan gelen kayitlari gecersiz saymamalidir.

Durum guncelleme:

`POST /api/stok-islemleri/stok-anomali-merkezi/{id}/durum`

```json
{
  "status": "Acknowledged",
  "note": "Depo sayim sonrasi kontrol edecek."
}
```

Durumlar:

- `Open`: yeni veya tekrar yakalandi
- `Acknowledged`: kullanici gordu, inceleniyor
- `Resolved`: cozuldu
- `Ignored`: bilincli olarak yok sayildi

UI oneri:

1. Panel acilisinda once `GET /stok-anomali-merkezi?status=Open&take=100` cagir.
2. `stok-islemleri.stok-anomali-merkezi.all-warehouses` varsa depo filtresi goster; yoksa depo filtresini kilitle/gizle.
3. `satin-almacilar` lookup sonucunu filtre dropdown'unda kullan; `ATANMAMIS` seciminde listeyi `hasProductManager=false` ile cagir.
4. "Tara" aksiyonu `stok-islemleri.stok-anomali-merkezi.all-warehouses` varsa tum depolar veya secili depo icin, yoksa sadece kullanici deposu icin calissin.
5. Tarama sirasinda ikinci tarama istegini engelle, bitince `rules` sonucunu ozetle ve listeyi yenile.
6. `rules[].error` doluysa sadece ilgili kurali uyari olarak goster; diger kurallarin kaydettigi anomaliler listede kalir.
7. Satir tiklaninca detay endpoint'i ile `evidence` ve `events` gosterilsin.
8. Kullanici satiri inceledikten sonra durumunu `Acknowledged`, `Resolved` veya `Ignored` yapabilsin.

### Etiket Belgeleri Son Liste

Secili depo icin son etiket belgelerini getirir.

Root route ile `son` route'u ayni davranisi kullanir:

- `GET /api/kasa-islemleri/etiket-belgeleri?warehouseNo=110&take=10`
- `GET /api/kasa-islemleri/etiket-belgeleri/son?warehouseNo=110&take=10`

Yetki:

- `kasa-islemleri.etiket-belgeleri.list`

Not:

- `warehouseNo` verilmezse JWT icindeki kullanici deposu kullanilir
- `take` verilmezse `10` kullanilir
- `take` ust limiti `100`'dur
- response modeli `LabelDocumentListItemDto` doner
- veri Furpa veritabanindaki `LabelDocuments` kayitlarindan okunur

Response:

```json
[
  {
    "documentId": 15,
    "createDate": "2026-04-24T11:30:00",
    "warehouseNo": 110
  },
  {
    "documentId": 14,
    "createDate": "2026-04-24T10:12:00",
    "warehouseNo": 110
  }
]
```

### Etiket Belgeleri Tumu

Secili depo icin tum etiket belgelerini getirir.

`GET /api/kasa-islemleri/etiket-belgeleri/tumu?warehouseNo=110`

Yetki:

- `kasa-islemleri.etiket-belgeleri.list`

Not:

- `warehouseNo` verilmezse tum depolar degil, sadece backend'e iletilen query karsiligina gore filtre calisir
- UI tarafinda genellikle kullanicinin mevcut deposu ile cagirmak daha dogrudur
- response modeli yine `LabelDocumentListItemDto` doner

### Etiket Belgesi Detay

Secilen etiket belgesine bagli urun kartlarini getirir.

`GET /api/kasa-islemleri/etiket-belgeleri/15?warehouseNo=110`

Yetki:

- `kasa-islemleri.etiket-belgeleri.detail`

Not:

- path parametresi `documentId:int` tipindedir; seri/sira ile degil numeric belge id ile calisir
- `warehouseNo` verilmezse JWT icindeki kullanici deposu kullanilir
- response modeli `LabelDocumentProductDto` doner
- backend once Furpa tarafinda belge detaylarini okur, sonra her satiri Mikro urun karti ile zenginlestirir

Response:

```json
[
  {
    "productCode": "015550",
    "productName": "URUN ADI",
    "barcode": "8690000000012",
    "price": 125.5,
    "oldPrice": 119.9,
    "unitName": "ADET",
    "quantity": 0,
    "documentOrderNo": 0,
    "categoryCode": "GIDA"
  }
]
```

### Etiketler

Belirli bir tarih icin depo bazli tag/view kayitlarini getirir. `kasa-islemleri.etiket-belgeleri.all-warehouses` yoksa depo sorulmaz; yetki varsa query'de opsiyonel `warehouseNo` gonderilebilir.

`GET /api/kasa-islemleri/etiket-belgeleri/etiketler?dateToGet=2026-04-24&warehouseNo=110`

Yetki:

- `kasa-islemleri.etiket-belgeleri.list`

Not:

- `warehouseNo` query ile alinmaz; dogrudan JWT icindeki kullanici deposu kullanilir
- response modeli `LabelTagDto` doner
- veri Furpa tarafindaki `VwKunyeNet` view'undan okunur

Response:

```json
[
  {
    "branchNo": 110,
    "branchName": "KESTEL 1",
    "productionCity": "BURSA",
    "productionDistrict": "KESTEL",
    "productName": "DANA KIYMA",
    "goodsType": "ET",
    "goodsGenus": "BUYUKBAS",
    "quantity": 12.5,
    "takenTag": "TAG-20260424-001",
    "buyer": "FURPA",
    "productionDate": "2026-04-24T00:00:00",
    "buyingPrice": 450,
    "shippingDate": "2026-04-24T00:00:00",
    "manufacturer": "TEDARIKCI A"
  }
]
```

### Kunye Etiket Yazdirma

Belirli bir tarih icin kullanicinin deposuna ait kunye etiket kayitlarini Kasa Islemleri altindaki ayri menu route'undan getirir.

`GET /api/kasa-islemleri/kunye-etiket-yazdirma?dateToGet=2026-04-24`

Yetki:

- yok; token gerekmez, herkese aciktir

Not:

- `warehouseNo` query ile alinmaz; dogrudan JWT icindeki kullanici deposu kullanilir
- response modeli `LabelTagDto` doner
- veri Furpa tarafindaki `VwKunyeNet` view'undan okunur
- eski `stok-islemleri.kunye-etiket-yazdirma.*` permission kodlari migration ile `kasa-islemleri...` altina tasinir

Response:

```json
[
  {
    "branchNo": 110,
    "branchName": "KESTEL 1",
    "productionCity": "BURSA",
    "productionDistrict": "KESTEL",
    "productName": "DANA KIYMA",
    "goodsType": "ET",
    "goodsGenus": "BUYUKBAS",
    "quantity": 12.5,
    "takenTag": "TAG-20260424-001",
    "buyer": "FURPA",
    "productionDate": "2026-04-24T00:00:00",
    "buyingPrice": 450,
    "shippingDate": "2026-04-24T00:00:00",
    "manufacturer": "TEDARIKCI A"
  }
]
```

### Manav Kunye Etiket Yazdirma

Belirli bir depo icin manav kunye etiket kayitlarini stok kodu, stok adi, satis fiyati ve urun birimi bilgileriyle getirir. `dateToGet` verilirse secilen gun icindeki kayitlardan, verilmezse son 1 ay icindeki kayitlardan her stok icin son kunye kaydi secilir. Bu ekran Kasa Islemleri altindaki `ManavKunyeEtiketYazdirma` menusu icindir.

`GET /api/kasa-islemleri/manav-kunye-etiket-yazdirma/detayli-etiketler?warehouseNo=110&dateToGet=2026-04-24`

Varsayilan son 1 ay sorgusu:

`GET /api/kasa-islemleri/manav-kunye-etiket-yazdirma/detayli-etiketler?warehouseNo=110`

Yetki:

- yok; token gerekmez, herkese aciktir

Query:

- `warehouseNo` zorunlu, 1 veya daha buyuk depo numarasi
- `dateToGet` opsiyonel, verilirse sorgulanacak sevk tarihi

Not:

- response modeli `KunyeLabelTagDto` doner
- veri Mikro `dbo.STOKLAR`, `[KUNYENET].[dbo].[MuhStok]`, `[KUNYENET].[dbo].[FaturaIslem]` ve `[Furpa].[dbo].[VwKunyeNet]` joinlerinden okunur
- `FaturaIslem.StokId` bazinda `ROW_NUMBER() OVER (PARTITION BY StokId ORDER BY ShippingDate DESC)` kullanilarak her stok icin son kunye kaydi secilir
- sadece Mikro `STOKLAR.sto_model_kodu` degeri `10`, `11`, `12`, `23` olan stoklar doner
- `salesPrice` alani Mikro `dbo.fn_StokSatisFiyati(stockCode, '1', branchNo, '1')` fonksiyonundan gelir
- `dateToGet` verilirse tarih filtresi secilen gunun tamamini kapsar; verilmezse `ShippingDate` son 1 ay ile sinirlanir
- liste `ShippingDate desc` siralanir
- menu permission kodu `kasa-islemleri.manav-kunye-etiket-yazdirma.page`; liste aksiyonu `kasa-islemleri.manav-kunye-etiket-yazdirma.list`; endpoint anonim oldugu icin API cagrisi token istemez

Response:

```json
[
  {
    "branchNo": 110,
    "branchName": "KESTEL 1",
    "productionCity": "BURSA",
    "stockCode": "STK-001",
    "stockName": "DANA KIYMA",
    "salesPrice": 599.9,
    "productionDistrict": "KESTEL",
    "productName": "DANA KIYMA",
    "goodsType": "ET",
    "goodsGenus": "BUYUKBAS",
    "quantity": 12.5,
    "takenTag": "TAG-20260424-001",
    "buyer": "FURPA",
    "productionDate": "2026-04-24T00:00:00",
    "buyingPrice": 450,
    "shippingDate": "2026-04-24T00:00:00",
    "manufacturer": "TEDARIKCI A",
    "productUnit": "KG"
  }
]
```

### Manav Mal Kabul ve Etiket

Eski WinForms `Manav Mal Kabul ve Etiket` uygulamasindaki manav/depo mal kabul etiketi akisi icin yeni API moduludur. Bu modul, mevcut `etiket-belgeleri` modulunden farklidir; `Furpa.dbo.Manav_Depo_Mal_Kabul_Etiket` kabul kayitlarini yonetir, kasa/net kilo hesaplar, UI'nin yazdirabilecegi etiket datasini dondurur, canli Mikro manav mal kabul belgelerini okur ve etiket-Mikro farklarini gosterir.

Bu bolum UI tarafinin baska bir dokumana gitmeden kullanabilmesi icin tum endpoint, request, response, status ve yazdirma notlarini icerir.

Canli akis ayrimi:

- Bu ekranda operasyonun ana kaynagi halden gelen resmi faturadir. UI mumkun oldugunca manuel bos evrakla baslamamali; once gelen fatura listesinden ilgili hal faturasini buldurmali, sonra tartim/etiket ve Mikro mal kabul adimlarini bu faturanin ustune kurmalidir.
- Gelen hal faturasi `GET /incoming-invoices` ile Auth DB'deki Uyumsoft gelen fatura cache'inden listelenir. Kullanici faturayi secince UI `GET /incoming-invoices/{invoiceLookupId}/detail` veya dogrudan ETTN ile `GET /incoming-invoices/ettn/{ettn}` cagirip fatura kalemlerini alir.
- Etiket/tartim kaydi `Furpa.dbo.Manav_Depo_Mal_Kabul_Etiket` tablosuna yazilir; bu kayit tek basina Mikro fatura/mal kabul belgesi degildir.
- Mikro mal kabul olusturma ayrica `POST /micro/goods-receipts` ile yapilir.
- Mikro aktariminda canli formata uygun olarak `CARI_HESAP_HAREKETLERI` tarafinda fatura/cari hareket basligi acilir ve `STOK_HAREKETLERI` satirlari bu basliga `sth_fat_uid = cha_Guid` ile baglanir.
- UI fiyat ve KDV bilgisi netlesmeden Mikro aktarimi yaptirmamalidir; sadece etiket basmak istiyorsa `acceptance-records` ve `label` endpointleri yeterlidir.
- Fatura bulunamazsa UI manuel kabul acabilir ama bunu istisna akisi gibi gostermelidir; normal hal kabul akisinda kullanici gelen fatura uzerinden ilerlemelidir.

Hal faturasi odakli en saglikli senaryo:

1. Ekran acilisinda UI tarih araligini bugun veya son 7 gun olarak ayarlar.
2. Kullanici hal tedarikcisini secer veya arar; UI `GET /suppliers?query=...` ile Mikro carisini bulur.
3. UI secili tarih/tedarikci icin `GET /incoming-invoices?startDate=...&endDate=...&supplierCode=...` cagirir.
4. Kullanici listeden hal faturasini secer veya ETTN girer. UI `GET /incoming-invoices/{invoiceLookupId}/detail` ya da `GET /incoming-invoices/ettn/{ettn}` cagirir.
5. UI ust baslikta `invoiceId`, `documentId`, `supplierTitle`, `supplierTaxNo`, `issueDate`, `payableAmount`, `taxExclusiveAmount`, `taxTotal`, `documentCurrencyCode` alanlarini gosterir.
6. UI orta gridde `lines[]` kalemlerini acar. `matchedStockCode` doluysa satir otomatik Mikro stokuyla eslesmistir; bos ise kullanicidan `/stocks` ile stok secimi istenir.
7. UI fatura secilmeden Mikro aktarim butonunu acmaz. Fatura secili degilse sadece tartim/etiket taslagi yapilabilir.
8. Kullanici her urun icin fatura miktari/fiyati/KDV bilgisini kontrol eder; eslesmeyen urunlerde `GET /stocks?query=...&prefix=MNV` ile MNV stokunu secer.
9. Tartim geldikce `POST /acceptance-records/calculate` ile net kg ve kasa ortalamasi hesaplanir.
10. Onaylanan her tartim satiri `POST /acceptance-records` ile Furpa etiket kaydina yazilir. Bu satirda `documentSeries/documentNo` alanlari secili hal faturasinin gorunen belge bilgisiyle doldurulmalidir.
11. Etiket basimi `GET /acceptance-records/{id}/label` ile yapilir. Etiket basmak Mikro'ya aktarim anlamina gelmez.
12. Fatura satirlari ve tartim satirlari kontrol edildikten sonra UI `POST /micro/goods-receipts` ile Mikro alis/mal kabul belgesini olusturur.
13. Aktarimdan sonra UI `GET /micro/goods-receipts?date=...&supplierCode=...` ve `GET /micro/goods-receipts/comparison?date=...&supplierCode=...` cagirip ekrani yeniler.
14. Gun sonu kontrolunde `GET /reports/received-products?date=...` ana mutabakat raporu, `GET /reports/depot-stock?warehouseNo=56&date=...` Manav Depo stok raporu olarak kullanilir.

UI icin sade ekran kurgusu:

- Ust bant: tarih, tedarikci, gelen fatura secimi, fatura toplam tutari ve durum.
- Sol/ust liste: gelen hal faturalari. Kaynak endpoint `incoming-invoices`.
- Orta grid: fatura/kabul satirlari. Stok, fatura miktari, fiyat, KDV, tartilan net miktar, fark, etiket durumu, Mikro aktarim durumu.
- Sag panel veya modal: tartim girisi. Brut, kasa darasi, kasa sayisi, palet darasi, kasa tipi, teslim alan.
- Alt sekmeler: `Etiketler`, `Mikro Belgeleri`, `Fark Kontrolu`, `Rapor`.

UI karar kurallari:

- `CanStartAcceptance=false` gelen fatura satirinda kabul baslatma butonu pasif olmalidir; mesaj/durum kullaniciya gosterilir.
- `MatchedSupplierCode` doluysa UI tedarikciyi otomatik eslestirebilir; bos ise kullanici Mikro carisini secmelidir.
- `IsArchived=true` faturalar varsayilan listede gizlenmelidir; gerekiyorsa `includeArchived=true` ile arsivli fatura aranabilir.
- Mikro aktarimda satir `quantity`, `unitPrice`, `taxPointer/taxRatePercent` netlesmeden buton acilmamalidir.
- `acceptance-records` satiri Mikro'ya aktarildiktan sonra update/delete kapali olmalidir; backend zaten `409 Conflict` doner.
- `comparison.status = SADECE_ETIKET` ise tartim var ama Mikro aktarim yok demektir; kullaniciya "Mikro'ya aktar" aksiyonu onerilir.
- `comparison.status = SADECE_MIKRO` ise Mikro'da belge var ama Furpa etiket/tartim kaydi yok demektir; kullaniciya "etiket/tartim kaydi eksik" uyarisi verilir.
- `comparison.status = FARKLI` ise etiket net kg ile Mikro miktari farklidir; satir kirmizi/uyari olarak gosterilir.
- `comparison.status = ESLESTI` veya `YAKIN` ise satir operasyonel olarak tamamlanmis kabul edilebilir.

Mikro aktarim ne zaman kullanilir:

- `POST /micro/goods-receipts`, hal faturasinin Manav Depo'ya Mikro alis/mal kabul belgesi olarak yazilacagi son onay adimidir.
- Bu endpoint etiket basma endpointi degildir. Sadece etiket veya tartim kaydi gerekiyorsa `acceptance-records` ve `label` endpointleri kullanilir.
- Fatura kalemleri grid'e alindi, stok eslesmeleri tamamlandi, tartim/net kg kontrol edildi, fiyat ve KDV netlesti ise kullanilir.
- Fatura secilmeden normal akista Mikro aktarim acilmamalidir. Manuel belge akisi sadece fatura bulunamadigi istisna durumda kullanilmalidir.
- Bir satir sadece tartildi ama fiyat/KDV bilinmiyorsa Mikro aktarim yerine `Etiket Kaydi` durumunda bekletilmelidir.
- Bir satir Mikro'ya aktarildiktan sonra ayni satir tekrar aktarilabilir gibi gosterilmemelidir. UI `microTransferred=true`, `comparison` veya Mikro belge listesiyle bunu kontrol etmelidir.
- `comparison.status = SADECE_ETIKET` olan satirlar Mikro aktarim adayidir.
- `comparison.status = SADECE_MIKRO` olan satirlar tekrar aktarim adayi degildir; bu durumda Furpa etiket/tartim kaydi eksigi arastirilir.
- `comparison.status = FARKLI` olan satirda once miktar/fiyat/eslestirme farki cozulmeli, sonra gerekiyorsa duzeltme veya yeni aktarim karari verilmelidir.

Mikro aktarim butonu acilma kosullari:

- Tedarikci secili olmali veya fatura detayinda `matchedSupplierCode` dolu olmalidir.
- Aktarilacak en az bir satir secili olmalidir.
- Her secili satirda `stockCode` dolu olmalidir. `matchedStockCode` bos gelen fatura kalemlerinde kullanici stok secimi yapmadan aktarim acilmaz.
- Her secili satirda `quantity > 0` olmalidir. Manavda kesin miktar genelde tartim/etiket net kg toplamidir.
- Her secili satirda `unitPrice` bilinmelidir. Fiyat fatura kaleminden gelmiyorsa kullanici elle girip onaylamalidir.
- Her secili satirda `taxPointer` veya `taxRatePercent` bilinmelidir.
- Etiket kaydiyla bagli aktarim yapiliyorsa `acceptanceRecordId` dolu olmalidir.
- Request gonderilirken buton loading/disabled olmali; timeout olursa ayni belgeyi tekrar yazmadan once `GET /micro/goods-receipts` ve `comparison` yenilenmelidir.

UI hedef tasarimi:

- Bu ekran tek basina `Etiket Basim` gibi dusunulmemelidir; `Gelen Fatura -> Manav Mal Kabul -> Tartim/Etiket -> Mikro Kontrol -> Rapor` akislarini ayni modulde toparlayan operasyon ekranidir.
- Ilk ekranda tarih, tedarikci, belge/fatura bilgisi ve gunluk durum ozetleri birlikte gorunmelidir.
- Kullanici gelen fatura satirlarini gorup miktar/fiyat/KDV kontrolu yapabilmeli; tartilan urunleri ayni satirlarla eslestirebilmeli; gerekirse tartimdan yeni etiket satiri ekleyebilmelidir.
- Mikro'ya aktarim butonu sadece fiyatli/onayli satirlarda acilmalidir. Fiyat veya cari belirsizse UI Mikro aktarimi yaptirmadan once kullanicidan duzeltme istemelidir.
- Etiket basma, Mikro aktarimindan bagimsiz kalmalidir. Kullanici once etiket basabilir, sonra fiyat/kabul onayi tamamlaninca Mikro aktarimi yapabilir.
- Karsilastirma sekmesi `SADECE_ETIKET`, `SADECE_MIKRO`, `FARKLI`, `YAKIN`, `ESLESTI` durumlarini operasyonel is listesi gibi gostermelidir.
- Rapor sekmesi alinan urunler/fatura farki ve 56 Manav Depo stok durumunu gostermelidir.

Onerilen ekran bolumleri:

| Bolum | Amac | Kullanilacak endpointler |
|---|---|---|
| `Fatura/Mal Kabul` | Tedarikci, tarih, belge no, fatura kalemleri, fiyatli satirlar ve Mikro aktarim onayi | `/suppliers`, `/incoming-invoices`, `/incoming-invoices/{invoiceLookupId}/detail`, `/incoming-invoices/ettn/{ettn}`, `/stocks`, `POST /micro/goods-receipts`, `GET /micro/goods-receipts` |
| `Tartim ve Etiket` | Brut, kasa darasi, kasa sayisi, net kg, ortalama kg hesaplama ve etiket basma | `POST /acceptance-records/calculate`, `/acceptance-records`, `/labels/preview`, `/acceptance-records/{id}/label` |
| `Kontrol` | Furpa etiket kaydi ile Mikro mal kabul miktarlarini karsilastirma | `GET /micro/goods-receipts/comparison` |
| `Raporlar` | Alinan urun/fatura farki ve Manav Depo stok/fiyat gorunumu | `/reports/received-products`, `/reports/depot-stock` |

Onerilen gunluk akis:

1. UI tarih ve tedarikci secimiyle acilir.
2. UI once gelen fatura listesini getirir; kullanici faturayi secer veya ETTN ile faturayi bulur.
3. UI fatura detayindan gelen kalemleri grid'e basar; stok eslesmeyen satirlarda kullaniciya MNV stok secimi yaptirir.
4. Kullanici tartim yaptikca `calculate` ile net kg/ortalama kg hesaplanir.
5. Onaylanan tartim satiri `POST /acceptance-records` ile Furpa etiket kaydi olur.
6. Etiket icin `GET /acceptance-records/{id}/label` veya kaydetmeden once `POST /labels/preview` kullanilir.
7. Fatura kalemi, tartim net kg, fiyat ve KDV kontrolu tamamlaninca secili satirlar `POST /micro/goods-receipts` ile Mikro'ya aktarilir.
8. Basarili aktarimdan sonra UI `GET /micro/goods-receipts` ve `GET /micro/goods-receipts/comparison` ile ekrani yeniler.
9. Gun sonunda `reports/received-products` ile fatura/etiket farklari, `reports/depot-stock` ile 56 depo stok durumu kontrol edilir.

UI durum modeli onerisi:

- `Taslak`: satir UI'da hazirlaniyor, henuz Furpa etiket kaydi yok.
- `Etiket Kaydi`: `acceptance-records` satiri var, `microTransferred=false`.
- `Etiket Basildi`: UI lokal baski islemini tamamlamis; API'de ayri baski log'u yoksa bu durum UI tarafinda tutulabilir.
- `Mikro Aktarildi`: `microTransferred=true` veya Mikro belge listesinde ilgili satir gorunuyor.
- `Fark Var`: comparison status `FARKLI`, `SADECE_ETIKET` veya `SADECE_MIKRO`.
- `Tamam`: comparison status `ESLESTI` veya kabul edilebilir toleransta `YAKIN`.

Kullanici deneyimi notlari:

- Ekran pazaryeri/hal operasyonu gibi hizli veri girisine uygun olmalidir; form alanlari kisa, tablo satirlari yogun ve klavye/barkod okutmaya uygun tasarlanmalidir.
- Aynı stoktan birden fazla tartim olabilir; UI satirlari sadece stok koduyla birlestirmemeli, satir/kayit bazinda gostermelidir.
- `acceptanceRecordId` Mikro aktarim satirina tasinirse aktarimdan sonra ilgili Furpa kaydi otomatik `Mikro_Aktarildi=1` olur.
- Mikro aktarim request'i pending iken buton kilitlenmelidir. Timeout veya belirsiz durumda UI yeni seri/sira uretip tekrar basmamalidir; once Mikro belge listesi ve karsilastirma yenilenmelidir.
- UI, `documentSeries/documentOrderNo` degerlerini kullaniciya gosterebilir ama bos birakilirsa backend seri/sira uretir. Manuel seri/sira girilirse duplicate kontrolu devrededir.

Root route:

`/api/kasa-islemleri/manav-mal-kabul-etiket`

Yeni UI ve backend icin tek route budur.

Yetkiler:

- `kasa-islemleri.manav-mal-kabul-etiket.page`
- `kasa-islemleri.manav-mal-kabul-etiket.list`
- `kasa-islemleri.manav-mal-kabul-etiket.detail`
- `kasa-islemleri.manav-mal-kabul-etiket.create`
- `kasa-islemleri.manav-mal-kabul-etiket.update`
- `kasa-islemleri.manav-mal-kabul-etiket.delete`
- `kasa-islemleri.manav-mal-kabul-etiket.transfer`
- `kasa-islemleri.manav-mal-kabul-etiket.all-warehouses`

Genel HTTP notlari:

- Tum endpointler token ister.
- Yetki yoksa `403`, token yok/gecersizse `401` doner.
- Validation hatalarinda standart `ProblemDetails` ile `400` doner.
- Kayit bulunamazsa `404`, aktarilmis kayit guncelleme/silme denemesinde `409` doner.
- `DELETE` basarili olursa body donmez, `204 No Content` doner.

Endpoint ozeti:

| Method | Endpoint | Request | Response | Yetki |
|---|---|---|---|---|
| `GET` | `/suppliers` | query: `query`, `take` | `ManavMalKabulVeEtiketSupplierSuggestionDto[]` | `list` |
| `GET` | `/suppliers/by-name` | query: `name` | `ManavMalKabulVeEtiketSupplierSuggestionDto` | `list` |
| `GET` | `/stocks` | query: `query`, `prefix`, `take` | `ManavMalKabulVeEtiketStockSuggestionDto[]` | `list` |
| `GET` | `/stocks/by-name` | query: `name` | `ManavMalKabulVeEtiketStockSuggestionDto` | `list` |
| `GET` | `/stocks/{stockCode}` | path: `stockCode` | `ManavMalKabulVeEtiketStockSuggestionDto` | `list` |
| `GET` | `/incoming-invoices` | query: `startDate`, `endDate`, `supplierCode`, `searchText`, `includeArchived`, `take` | `ManavMalKabulVeEtiketIncomingInvoiceDto[]` | `list` |
| `GET` | `/incoming-invoices/{invoiceLookupId}/detail` | path: `invoiceLookupId`, query: `supplierCode` opsiyonel | `ManavMalKabulVeEtiketInvoiceDetailDto` | `detail` |
| `GET` | `/incoming-invoices/ettn/{ettn}` | path: `ettn`, query: `supplierCode` opsiyonel | `ManavMalKabulVeEtiketInvoiceDetailDto` | `detail` |
| `POST` | `/acceptance-records/calculate` | body: `ManavMalKabulVeEtiketCalculationHttpRequest` | `ManavMalKabulVeEtiketCalculationDto` | `create` |
| `GET` | `/acceptance-records` | query: `date` | `ManavMalKabulVeEtiketAcceptanceRecordDto[]` | `list` |
| `GET` | `/acceptance-records/{id}` | path: `id` | `ManavMalKabulVeEtiketAcceptanceRecordDto` | `detail` |
| `POST` | `/acceptance-records` | body: `SaveManavMalKabulVeEtiketAcceptanceRecordHttpRequest` | `ManavMalKabulVeEtiketAcceptanceRecordDto` | `create` |
| `PUT` | `/acceptance-records/{id}` | path: `id`, body: `SaveManavMalKabulVeEtiketAcceptanceRecordHttpRequest` | `ManavMalKabulVeEtiketAcceptanceRecordDto` | `update` |
| `DELETE` | `/acceptance-records/{id}` | path: `id` | `204 No Content` | `delete` |
| `GET` | `/acceptance-records/{id}/label` | path: `id` | `ManavMalKabulVeEtiketLabelDto` | `detail` |
| `POST` | `/labels/preview` | body: `SaveManavMalKabulVeEtiketAcceptanceRecordHttpRequest` | `ManavMalKabulVeEtiketLabelDto` | `create` |
| `GET` | `/reports/received-products` | query: `date` | `ManavMalKabulVeEtiketReceivedProductReportItemDto[]` | `list` |
| `GET` | `/reports/depot-stock` | query: `warehouseNo`, `date` | `ManavMalKabulVeEtiketDepotStockReportItemDto[]` | `list` |
| `GET` | `/micro/goods-receipts` | query: `date`, `supplierCode` opsiyonel | `ManavMalKabulVeEtiketMicroGoodsReceiptDocumentDto[]` | `list` |
| `GET` | `/micro/goods-receipts/comparison` | query: `date`, `supplierCode` opsiyonel | `ManavMalKabulVeEtiketGoodsReceiptComparisonItemDto[]` | `list` |
| `POST` | `/micro/goods-receipts` | body: `ManavMalKabulVeEtiketCreateMicroGoodsReceiptHttpRequest` | `ManavMalKabulVeEtiketCreateMicroGoodsReceiptResultDto` | `transfer` |

Referans arama endpointleri:

`GET /api/kasa-islemleri/manav-mal-kabul-etiket/suppliers?query=ABC&take=20`

Query:

- `query`: zorunlu, en az 2 karakter
- `take`: opsiyonel, varsayilan `20`, aralik `1-100`

Response:

```json
[
  {
    "supplierCode": "120.001",
    "supplierName": "TEDARIKCI A",
    "supplierTitle2": "LTD STI",
    "supplierTaxNo": "1234567890"
  },
  {
    "supplierCode": "120.002",
    "supplierName": "TEDARIKCI B",
    "supplierTitle2": "",
    "supplierTaxNo": "1111111111"
  }
]
```

`GET /api/kasa-islemleri/manav-mal-kabul-etiket/suppliers/by-name?name=TEDARIKCI%20A`

Query:

- `name`: zorunlu, tedarikci adi

Response:

```json
{
  "supplierCode": "120.001",
  "supplierName": "TEDARIKCI A",
  "supplierTitle2": "LTD STI",
  "supplierTaxNo": "1234567890"
}
```

`GET /api/kasa-islemleri/manav-mal-kabul-etiket/stocks?query=DOMATES&prefix=MNV&take=20`

Query:

- `query`: opsiyonel, stok adi/stok kodu/barkod aramasi
- `prefix`: opsiyonel, varsayilan `MNV`, en fazla 10 karakter
- `take`: opsiyonel, varsayilan `20`, aralik `1-100`

Response:

```json
[
  {
    "stockCode": "MNV001",
    "stockName": "MNV DOMATES",
    "barcode": "1234567",
    "unitName": "KG",
    "modelCode": "10",
    "wholesaleTaxPointer": 3
  },
  {
    "stockCode": "MNV002",
    "stockName": "MNV BIBER",
    "barcode": "7654321",
    "unitName": "KG",
    "modelCode": "11",
    "wholesaleTaxPointer": 3
  }
]
```

`GET /api/kasa-islemleri/manav-mal-kabul-etiket/stocks/by-name?name=MNV%20DOMATES`

Query:

- `name`: zorunlu, stok adi

Response:

```json
{
  "stockCode": "MNV001",
  "stockName": "MNV DOMATES",
  "barcode": "1234567",
  "unitName": "KG",
  "modelCode": "10",
  "wholesaleTaxPointer": 3
}
```

`GET /api/kasa-islemleri/manav-mal-kabul-etiket/stocks/MNV001`

Path:

- `stockCode`: zorunlu, stok kodu

Response:

```json
{
  "stockCode": "MNV001",
  "stockName": "MNV DOMATES",
  "barcode": "1234567",
  "unitName": "KG",
  "modelCode": "10",
  "wholesaleTaxPointer": 3
}
```

Referans arama notlari:

- tedarikci aramada eski uygulamadaki cari kod prefix haricleri korunur: `8888`, `1999`, `2012`, `4690`, `1998`, `2022`, `120.MY`
- stok aramada varsayilan prefix `MNV` olur
- `query` stok adi, stok kodu veya barkod icinde aranir
- `*` karakteri SQL wildcard gibi `%` davranisina cevrilir
- `suppliers/by-name`, `stocks/by-name` ve `stocks/{stockCode}` sonuc bulamazsa `404` doner

### Gelen Fatura Cache

Manav mal kabul ekrani gelen fatura listesini Auth DB'deki Uyumsoft inbox cache'inden okuyabilir.

`GET /api/kasa-islemleri/manav-mal-kabul-etiket/incoming-invoices?startDate=2026-08-13&endDate=2026-08-13&supplierCode=32000297&take=100`

Query:

```text
startDate        opsiyonel; bos ise endDate - 7 gun
endDate          opsiyonel; bos ise bugun
supplierCode     opsiyonel; verilirse Mikro cari kartinin VKN/TCKN veya unvaniyla gelen faturalar daraltilir
searchText       opsiyonel; fatura no, documentId, tedarikci unvani, VKN/TCKN, irsaliye no veya siparis belge no icinde arar
includeArchived  opsiyonel; default false
take             opsiyonel; default 100, max 500
```

Response:

```json
[
  {
    "documentId": "9f4c0c1a-...",
    "invoiceId": "GIB2026000012345",
    "supplierTitle": "HAL TEDARIKCI A",
    "supplierTaxNo": "1234567890",
    "createDate": "2026-08-13T08:10:00",
    "invoiceDate": "2026-08-13T00:00:00",
    "invoiceType": "SATIS",
    "invoiceTotal": 25004.0,
    "taxExclusiveAmount": 24753.96,
    "taxTotal": 250.04,
    "despatchId": "IRS2026000099",
    "isProcessed": false,
    "isPrinted": false,
    "isStandard": true,
    "statusCode": "ACCEPTED",
    "status": "Kabul edildi",
    "message": "",
    "documentCurrencyCode": "TRY",
    "exchangeRate": 1.0,
    "orderDocumentId": "",
    "isArchived": false,
    "invoiceTipType": "Temel Fatura",
    "invoiceTipTypeCode": 0,
    "isSeen": true,
    "lastSynchronizedAtUtc": "2026-08-13T05:15:00Z",
    "matchedSupplierCode": "32000297",
    "matchedSupplierName": "HAL TEDARIKCI A",
    "canStartAcceptance": true
  }
]
```

Not:

- Bu endpoint fatura baslik/ozet bilgisini dondurur; fatura kalemleri icin detay endpointi kullanilmalidir.
- `matchedSupplierCode` VKN/TCKN eslesmesiyle dolarsa UI tedarikci alanini otomatik onerebilir.
- `canStartAcceptance=false` ise UI yine manuel tedarikci secimine izin verebilir; fatura cache'i operasyonu bloke etmez.

### Gelen Fatura Detayi ve Kalemleri

Fatura secildikten sonra UI kalemleri almak icin bu endpointlerden birini cagirir:

```text
GET /api/kasa-islemleri/manav-mal-kabul-etiket/incoming-invoices/{invoiceLookupId}/detail?supplierCode=32000297
GET /api/kasa-islemleri/manav-mal-kabul-etiket/incoming-invoices/ettn/{ettn}?supplierCode=32000297
```

Kural:

- `invoiceLookupId` veya `ettn` Uyumsoft `invoiceId`, `documentId`, cache `serviceDocumentId` veya `localDocumentId` olabilir.
- Backend once Auth DB Uyumsoft inbox cache'inde eslesen basligi arar, sonra Uyumsoft `GetInboxInvoice` ve gerekirse `GetInboxInvoiceData` ile fatura XML'ini ceker.
- Response fatura basligi ile birlikte `lines[]` kalemlerini dondurur.
- Her kalemde backend fatura XML'indeki stok/barkod adaylarini Mikro `STOKLAR` ve `BARKOD_TANIMLARI` ile eslestirmeye calisir.
- `matchedStockCode` doluysa UI bu stokla satiri otomatik hazirlayabilir.
- `matchedStockCode` bos ise satir yine gosterilir; UI kullanicidan `/stocks` ile MNV stok secimi istemelidir.
- `canCreateAcceptance=false` satirda otomatik stok eslesmesi yoktur; Mikro aktarim veya etiket satiri olusturmadan once kullanici eslestirme yapmalidir.
- Uyumsoft UBL icinde kap/dara bilgisi standart kolon olarak degil `cbc:Note` alaninda gelebilir. Backend header notlarindan `totalCaseCount`, `totalGrossWithTareQuantity`, `totalTareQuantity`, `totalNetQuantity`; satir notundan `caseCount`, `grossWithTareQuantity`, `tareQuantity`, `netQuantity` alanlarini cozmeye calisir.
- Satir notu ornegi `84 1.432,00 126,00` ise UI bunu `84 kap`, `1432 kg darali`, `126 kg dara` olarak gosterebilir. `netQuantity` normalde fatura `quantity` degeriyle ayni net kg bilgisidir.
- Bu endpoint Mikro'ya veya Furpa etiket tablosuna yazmaz; sadece fatura kalemlerini okur ve UI'a hazirlar.

Response:

```json
{
  "invoiceLookupId": "9f4c0c1a-...",
  "invoiceId": "9f4c0c1a-...",
  "documentId": "GIB2026000012345",
  "supplierTitle": "HAL TEDARIKCI A",
  "supplierTaxNo": "1234567890",
  "issueDate": "2026-08-13T00:00:00",
  "invoiceTypeCode": "SATIS",
  "documentCurrencyCode": "TRY",
  "taxExclusiveAmount": 24753.96,
  "taxTotal": 250.04,
  "payableAmount": 25004.0,
  "totalCaseCount": 216,
  "totalGrossWithTareQuantity": 3686.0,
  "totalTareQuantity": 324.0,
  "totalNetQuantity": 3362.0,
  "despatchId": "IRS2026000099",
  "matchedSupplierCode": "32000297",
  "matchedSupplierName": "HAL TEDARIKCI A",
  "canStartAcceptance": true,
  "lines": [
    {
      "lineNo": 1,
      "lineId": "1",
      "stockCode": "015550",
      "stockName": "MNV DOMATES KG",
      "barcode": "2801555000000",
      "unitCode": "KGM",
      "note": "84 1.432,00 126,00",
      "quantity": 120.5,
      "caseCount": 84,
      "grossWithTareQuantity": 1432.0,
      "tareQuantity": 126.0,
      "netQuantity": 1306.0,
      "unitPrice": 25.0,
      "lineAmount": 3012.5,
      "taxRatePercent": 1.0,
      "taxAmount": 30.13,
      "taxPointer": 3,
      "matchedStockCode": "015550",
      "matchedStockName": "MNV DOMATES KG",
      "matchedBarcode": "2801555000000",
      "canCreateAcceptance": true,
      "warnings": []
    }
  ],
  "warnings": []
}
```

UI'da Mikro mal kabul satiri hazirlama:

- `stockCode`: `matchedStockCode` doluysa bu deger; bos ise kullanicinin sectigi MNV stok kodu
- `quantity`: fatura kalemindeki `quantity` veya tartim sonrasi onaylanan net miktar
- `unitPrice`: fatura kalemindeki `unitPrice`
- `taxPointer`: `taxPointer` doluysa bu deger
- `taxRatePercent`: `taxPointer` bos ise fatura kalemindeki `taxRatePercent`
- `taxAmount`: fatura kalemindeki `taxAmount` opsiyonel olarak tasinabilir
- `acceptanceRecordId`: satir bir Furpa tartim/etiket kaydiyla eslestirildiyse ilgili kaydin `id` degeri
- `description`: fatura kalem adi, satir no veya kullanici notu

Mikro'ya yazma yine sadece `POST /micro/goods-receipts` ile yapilir. Fatura detayi endpointini cagirmak Mikro kaydi olusturmaz.

Hesaplama:

`POST /api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records/calculate`

Request:

```json
{
  "grossWeight": 100.0,
  "caseTare": 1.2,
  "caseCount": 10,
  "palletTare": 5.0,
  "stockBarcode": "1234567"
}
```

Body:

- `grossWeight`: zorunlu, brut kilo
- `caseTare`: zorunlu, tek kasa darasi
- `caseCount`: opsiyonel, bos gelirse `1`
- `palletTare`: opsiyonel, bos gelirse `0`
- `stockBarcode`: opsiyonel, doluysa etiket barkodu hesaplanir

Response:

```json
{
  "caseTotalTare": 12.0,
  "netReceivedWeight": 83.0,
  "averageCaseWeight": 8.3,
  "labelBarcodeRaw": "123456708300",
  "labelBarcode": "1234567083001",
  "barcodeSymbology": "EAN13"
}
```

Hesap kurali:

- `caseTotalTare = caseTare * caseCount`
- `netReceivedWeight = grossWeight - caseTotalTare - palletTare`
- `averageCaseWeight = netReceivedWeight / caseCount`
- `caseCount` bos gelirse `1`, `palletTare` bos gelirse `0` kabul edilir
- `averageCaseWeight > 99` ise API hata doner
- `stockBarcode` gonderilirse API eski uygulamadaki ortalama kilo formatina gore `labelBarcodeRaw` uretir; `labelBarcode` yazdirilacak nihai barkoddur

Kabul kayitlari:

- `GET /api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records?date=2026-07-30`
- `GET /api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records/{id}`
- `POST /api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records`
- `PUT /api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records/{id}`
- `DELETE /api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records/{id}`

Liste request:

```text
date  zorunlu; yyyy-MM-dd
```

Liste response:

```json
[
  {
    "id": 15,
    "createdAt": "2026-07-30T10:20:00",
    "updatedAt": "2026-07-30T10:20:00",
    "supplierCode": "120.001",
    "supplierName": "TEDARIKCI A",
    "documentSeries": "MNV",
    "documentNo": "12345",
    "seriesAndNumber": "MNV12345",
    "stockCode": "MNV001",
    "stockName": "MNV DOMATES",
    "stockBarcode": "1234567",
    "grossWeight": 100.0,
    "caseTare": 1.2,
    "caseCount": 10,
    "caseTotalTare": 12.0,
    "palletTare": 5.0,
    "averageCaseWeight": 8.3,
    "netReceivedWeight": 83.0,
    "receivedBy": "Ali",
    "microTransferred": false,
    "status": "Bekliyor",
    "caseType": "REHINLI",
    "labelBarcodeRaw": "123456708300",
    "labelBarcode": "1234567083001",
    "barcodeSymbology": "EAN13"
  }
]
```

Tek kayit request:

```text
id  zorunlu path parametresi
```

Tek kayit response, create response ve update response ayni `ManavMalKabulVeEtiketAcceptanceRecordDto` modelini doner.

Kayit request:

```json
{
  "supplierCode": "120.001",
  "supplierName": "TEDARIKCI A",
  "documentSeries": "MNV",
  "documentNo": "12345",
  "stockCode": "MNV001",
  "stockName": "MNV DOMATES",
  "stockBarcode": "1234567",
  "grossWeight": 100.0,
  "caseTare": 1.2,
  "caseCount": 10,
  "palletTare": 5.0,
  "receivedBy": "Ali",
  "caseType": "REHINLI"
}
```

Kayit request alanlari:

- `supplierCode`: zorunlu, en fazla 25 karakter
- `supplierName`: zorunlu, en fazla 255 karakter
- `documentSeries`: opsiyonel, en fazla 25 karakter, bos gelirse `MNV`
- `documentNo`: zorunlu, en fazla 25 karakter
- `stockCode`: zorunlu, en fazla 25 karakter
- `stockName`: zorunlu, en fazla 255 karakter
- `stockBarcode`: zorunlu, en fazla 50 karakter
- `grossWeight`: zorunlu, brut kilo
- `caseTare`: zorunlu, tek kasa darasi
- `caseCount`: opsiyonel, bos gelirse `1`
- `palletTare`: opsiyonel, bos gelirse `0`
- `receivedBy`: zorunlu, en fazla 100 karakter
- `caseType`: zorunlu, en fazla 20 karakter, `REHINLI` veya `REHINSIZ`

Kayit response:

```json
{
  "id": 15,
  "createdAt": "2026-07-30T10:20:00",
  "updatedAt": "2026-07-30T10:20:00",
  "supplierCode": "120.001",
  "supplierName": "TEDARIKCI A",
  "documentSeries": "MNV",
  "documentNo": "12345",
  "seriesAndNumber": "MNV12345",
  "stockCode": "MNV001",
  "stockName": "MNV DOMATES",
  "stockBarcode": "1234567",
  "grossWeight": 100.0,
  "caseTare": 1.2,
  "caseCount": 10,
  "caseTotalTare": 12.0,
  "palletTare": 5.0,
  "averageCaseWeight": 8.3,
  "netReceivedWeight": 83.0,
  "receivedBy": "Ali",
  "microTransferred": false,
  "status": "Bekliyor",
  "caseType": "REHINLI",
  "labelBarcodeRaw": "123456708300",
  "labelBarcode": "1234567083001",
  "barcodeSymbology": "EAN13"
}
```

Create/update/delete statuslari:

- `POST /acceptance-records` basariliysa `201 Created` ve yukaridaki `ManavMalKabulVeEtiketAcceptanceRecordDto` response'unu doner
- `PUT /acceptance-records/{id}` basariliysa `200 OK` ve guncellenmis `ManavMalKabulVeEtiketAcceptanceRecordDto` response'unu doner
- `PUT /acceptance-records/{id}` icin kayit yoksa `404`, kayit Mikro'ya aktarilmissa `409` doner
- `DELETE /acceptance-records/{id}` basariliysa `204 No Content` doner
- `DELETE /acceptance-records/{id}` icin kayit yoksa `404`, kayit Mikro'ya aktarilmissa `409` doner

Kayit notlari:

- yeni kayit `Mikro_Aktarildi = 0` olarak acilir
- `documentSeries` bos gelirse `MNV` kabul edilir
- aktarilmis kayit guncellenemez ve silinemez
- `caseType` icin request tarafinda `REHINLI` ve `REHINSIZ` gonderilebilir; API response'u tablo degeriyle uyumlu normalize edilmis kasa tipini doner

Etiket datasini alma:

- kaydedilmis satir icin `GET /api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records/{id}/label`
- kaydetmeden onizleme icin `POST /api/kasa-islemleri/manav-mal-kabul-etiket/labels/preview`

Kaydedilmis etiket request:

```text
id  zorunlu path parametresi
```

Preview request:

```json
{
  "supplierCode": "120.001",
  "supplierName": "TEDARIKCI A",
  "documentSeries": "MNV",
  "documentNo": "12345",
  "stockCode": "MNV001",
  "stockName": "MNV DOMATES",
  "stockBarcode": "1234567",
  "grossWeight": 100.0,
  "caseTare": 1.2,
  "caseCount": 10,
  "palletTare": 5.0,
  "receivedBy": "Ali",
  "caseType": "REHINLI"
}
```

Label response:

```json
{
  "recordId": 15,
  "stockCode": "MNV001",
  "stockName": "MNV DOMATES",
  "stockBarcode": "1234567",
  "supplierName": "TEDARIKCI A",
  "averageCaseWeight": 8.3,
  "labelDate": "2026-07-30T10:20:00",
  "labelCount": 10,
  "labelBarcodeRaw": "123456708300",
  "labelBarcode": "1234567083001",
  "barcodeSymbology": "EAN13",
  "caseTare": 1.2,
  "caseType": "REHINLI"
}
```

UI yazdirma akisi:

1. Kullanici kayitli satirdan yazdiracaksa `GET /acceptance-records/{id}/label` cagrilir.
2. Kullanici henuz kaydetmeden etiket gormek/yazdirmak istiyorsa ayni kayit body modeliyle `POST /labels/preview` cagrilir.
3. API etiket resmi, PDF veya ZPL dondurmez; eski sistem gibi UI/terminal Windows printer driver uzerinden kendi yazici entegrasyonunu calistirir.
4. Eski rapor olcusu referans alinacaksa etiket alani yaklasik `57.9 mm x 38.9 mm`, sifir margin dusunulebilir.
5. UI etikette en az stok adi, tedarikci, tarih, ortalama kasa kilosu, kasa tipi, kasa darasi ve barkod metnini gostermelidir.
6. `labelCount` kasa sayisidir; UI bu degeri yazdirma kopya adedi olarak kullanmali veya kullaniciya adet olarak onermelidir.
7. `barcodeSymbology = EAN13` ise EAN-13, `EAN8` ise EAN-8, diger durumda Code128 renderer kullanilmalidir.
8. Normal yazdirma icin `labelBarcode` kullanilmalidir; bu alan EAN13 icin check-digit eklenmis nihai degerdir. Kullanilan renderer check digit'i kendisi hesaplamak istiyorsa `labelBarcodeRaw` verilebilir.
9. Yazdirma butonu ikinci kez tiklanmaya karsi loading/disabled durumda tutulmalidir; baski basarili olursa kayit tekrar kaydedilmez.

Eski yazdirma referansi:

- Eski sistem ZPL, ESC/POS, Bluetooth veya socket komutu uretmez.
- Kullanici standart Windows `PrintDialog` ile Windows'ta tanimli yaziciyi secer.
- Etiket DevExpress `XtraReport` olarak hazirlanir ve `ReportPrintTool.Print()` ile printer driver'a gonderilir.
- API'nin ilk surumde data-only kalmasi eski davranisa uygundur; PDF/PNG/ZPL uretimi ayrica istenirse yeni endpoint olarak tasarlanmalidir.

Eski etiket tasarim alani:

| API alani | Eski rapor kontrolu | UI kullanimi |
|---|---|---|
| `stockName` | `XrStokAdi` | ust bolumde genis urun adi |
| `stockCode` | `XrStokKodu` | barkod ustu bilgi satiri |
| `stockBarcode` | `XrBarkod` | barkod ustu urun barkodu |
| `averageCaseWeight` | `XrMiktar` | orta bolumde ortalama kasa kilosu |
| `caseTare` | `XrDara` | orta bolumde kasa darasi |
| `caseType` | `XrKasaTip` | orta/alt bolumde kasa tipi |
| `labelDate` | `XrTarih` | orta/alt bolumde tarih |
| `labelBarcode` | `xrBarCode1` | alt bolumde asil barkod |
| `supplierName` | `XrCariUnvan` | en alt bolumde tedarikci |

Raporlar:

- `GET /api/kasa-islemleri/manav-mal-kabul-etiket/reports/received-products?date=2026-07-30`
- `GET /api/kasa-islemleri/manav-mal-kabul-etiket/reports/depot-stock?warehouseNo=56&date=2026-07-30`

Alinan urunler raporu request:

```text
date  zorunlu; yyyy-MM-dd
```

Alinan urunler raporu response:

```json
[
  {
    "supplierCode": "32000297",
    "supplierName": "TEDARIKCI A",
    "stockCode": "MNV001",
    "barcode": "1234567",
    "stockName": "MNV DOMATES",
    "labelRowCount": 2,
    "documentSeries": "MNV26",
    "documentNo": "10, 11",
    "seriesAndNumber": "MNV26 - 10, 11",
    "grossWeight": 100.0,
    "caseTotalTare": 12.0,
    "palletTare": 5.0,
    "caseCount": 10,
    "netReceivedWeight": 83.0,
    "invoiceQuantity": 80.0,
    "invoiceDifference": -3.0,
    "microRowCount": 1,
    "microAmount": 2800.0,
    "microDocument": "EFT261/2014",
    "status": "FARKLI",
    "unitName": "KG"
  }
]
```

Depo stok raporu request:

```text
warehouseNo  opsiyonel; bos ise 56 kullanilir
date         opsiyonel; bos ise bugun kullanilir
```

Depo stok raporu response:

```json
[
  {
    "stockCode": "MNV001",
    "stockName": "MNV DOMATES",
    "responsible": "SATINALMA SORUMLUSU",
    "currentStock": 125.5,
    "purchasePriceWithVat": 18.75,
    "salesPrice": 24.9,
    "barcode": "1234567",
    "unitName": "KG",
    "modelCode": "10"
  }
]
```

Rapor notlari:

- depo stok raporunda `warehouseNo` verilmezse eski akisla uyumlu varsayilan depo `56` olur
- kullanici kendi deposu disinda depo isterse ilgili tum depo yetkisi gerekir
- alinan urunler raporu Furpa kabul kayitlarini canli Mikro manav mal kabul miktarlariyla karsilastirmak icindir
- `invoiceQuantity` genel stok hareketlerinden degil, canli 2026 manav formatindan okunur: `sth_tip=0`, `sth_cins=16`, `sth_evraktip=3`, `sth_normal_iade=0`, `sth_giris_depo_no=56`, `sth_cikis_depo_no=1`, `sto_isim LIKE 'MNV%'`
- `status` degeri `ESLESTI`, `YAKIN`, `FARKLI`, `SADECE_ETIKET` veya `SADECE_MIKRO` olabilir.
- Rapor liste sirasi farki buyuk satirlari once gosterecek sekildedir; UI ilk bakilacak sorunlari en ustte gosterebilir.
- Depo stok raporu barkod, birim ve model kodunu da dondurur; UI stok secimi veya etiket/kabul ekranina geciste bu alanlari kullanabilir.

Canli Mikro manav mal kabul belgeleri:

`GET /api/kasa-islemleri/manav-mal-kabul-etiket/micro/goods-receipts?date=2026-08-13`

Opsiyonel cari filtresi:

`GET /api/kasa-islemleri/manav-mal-kabul-etiket/micro/goods-receipts?date=2026-08-13&supplierCode=32000297`

Response belge bazlidir:

```json
[
  {
    "date": "2026-08-13T00:00:00",
    "documentSeries": "EFT261",
    "documentOrderNo": 2014,
    "seriesAndNumber": "EFT261/2014",
    "supplierCode": "32000297",
    "supplierName": "TEDARIKCI A",
    "createUserNo": 15,
    "lineCount": 2,
    "totalQuantity": 1427.0,
    "totalAmount": 49945.0,
    "totalTax": 0.0,
    "firstCreatedAt": "2026-08-13T11:52:56.557",
    "lastCreatedAt": "2026-08-13T11:52:56.557",
    "documentNo": "2014",
    "invoiceGuid": "0c9f474b-c9dd-4f56-91e8-1e944bb77f53",
    "offlineTraceKey": "FRMNV260813A1B2C3D4",
    "lines": [
      {
        "lineNo": 0,
        "stockCode": "001082",
        "stockName": "MNV URUN",
        "quantity": 714.0,
        "unitPrice": 35.0,
        "amount": 24990.0,
        "taxAmount": 0.0,
        "taxPointer": 0,
        "inWarehouseNo": 56,
        "outWarehouseNo": 1,
        "movementGuid": "49f26b26-9f37-4d64-98e7-1e2f7a5e2d41",
        "barcode": "2700108",
        "unitName": "KG",
        "description": "Domates"
      }
    ]
  }
]
```

Etiket - Mikro mal kabul karsilastirma:

`GET /api/kasa-islemleri/manav-mal-kabul-etiket/micro/goods-receipts/comparison?date=2026-08-13`

Response:

```json
[
  {
    "date": "2026-08-13T00:00:00",
    "supplierCode": "32000297",
    "supplierName": "TEDARIKCI A",
    "stockCode": "001082",
    "stockName": "MNV URUN",
    "labelRowCount": 1,
    "labelNetWeight": 714.4,
    "microRowCount": 2,
    "microQuantity": 1427.0,
    "difference": 712.6,
    "microAmount": 49945.0,
    "microDocument": "EFT261/2014, EFT261/2014",
    "status": "FARKLI"
  }
]
```

Karsilastirma status degerleri:

- `ESLESTI`: fark 0.01 veya altinda
- `YAKIN`: fark 2 birim veya altinda
- `FARKLI`: iki tarafta da kayit var ama fark buyuk
- `SADECE_ETIKET`: tartim/etiket var, Mikro mal kabul yok
- `SADECE_MIKRO`: Mikro mal kabul var, etiket kaydi yok

Mikro mal kabul olusturma:

`POST /api/kasa-islemleri/manav-mal-kabul-etiket/micro/goods-receipts`

Request:

```json
{
  "date": "2026-08-13",
  "supplierCode": "32000297",
  "documentSeries": "MNV26",
  "documentOrderNo": null,
  "documentNo": null,
  "mikroUserNo": 15,
  "description": "Manav mal kabul",
  "markAcceptanceRecordsTransferred": true,
  "lines": [
    {
      "acceptanceRecordId": 12345,
      "stockCode": "001082",
      "quantity": 714.4,
      "unitPrice": 35.0,
      "unitPointer": 1,
      "taxPointer": 3,
      "taxRatePercent": 1,
      "taxAmount": null,
      "description": "Domates"
    }
  ]
}
```

Bu endpoint ne yapar:

- Canli Mikro'da cari/fatura basligi acmak icin `CARI_HESAP_HAREKETLERI` kaydi olusturur.
- Her satir icin `STOK_HAREKETLERI` alis/mal kabul hareketi yazar.
- Satirlari cari basliga `sth_fat_uid = cha_Guid` ile baglar.
- `acceptanceRecordId` gonderilen Furpa etiket kayitlarini basarili yazimdan sonra `Mikro_Aktarildi=1` yapar.
- Fatura detayini okumak, etiket kaydi olusturmak veya etiket basmak bu islemi otomatik tetiklemez.

UI alan kaynagi:

| Request alani | UI'da kaynagi | Not |
|---|---|---|
| `date` | Fatura `issueDate` veya kullanicinin mal kabul tarihi | Gunluk rapor/karsilastirma bu tarihle okunur. |
| `supplierCode` | `matchedSupplierCode` veya kullanicinin sectigi Mikro cari | Bos gonderilmemeli. |
| `documentSeries` | Varsayilan `MNV`/`MNV26` veya UI belge serisi | Bos gonderilirse backend `MNV` kullanir. |
| `documentOrderNo` | Genelde `null` | Bos gonderilirse backend sonraki sirayi uretir. Manuel girilirse duplicate kontrolu calisir. |
| `documentNo` | Fatura `invoiceId`/resmi belge no veya manuel belge no | Bos ise backend sira no metnini kullanir. |
| `mikroUserNo` | UI/oturum eski Mikro kullanici no biliyorsa | Bos ise backend default `39` kullanir. |
| `description` | Ekran aciklamasi | Belge aciklamasi olarak saklanir. |
| `markAcceptanceRecordsTransferred` | Normal akista `true` | `acceptanceRecordId` gonderilen kayitlari aktarildi isaretler. |
| `lines[].acceptanceRecordId` | Furpa etiket/kabul kaydi `id` | Etiket kaydiyla bagli aktarimda doldurulur. |
| `lines[].stockCode` | `matchedStockCode` veya kullanicinin sectigi MNV stok | Zorunlu. |
| `lines[].quantity` | Tartim/etiket net kg toplamı veya onayli fatura miktari | Manavda pratikte kesin kabul miktari tartim net kg olmalidir. |
| `lines[].unitPrice` | Fatura kalemi `unitPrice` veya manuel fiyat | Fiyat bilinmeden aktarim acilmamali. |
| `lines[].unitPointer` | Stok ana birimi icin genelde `1` | Farkli birim senaryosu yoksa UI `1` gonderir. |
| `lines[].taxPointer` | Fatura/stok KDV pointer'i | Doluyken tercih edilir. |
| `lines[].taxRatePercent` | Fatura kalemi KDV yuzdesi | `taxPointer` yoksa kullanilir. |
| `lines[].taxAmount` | Fatura kalemi KDV tutari | Opsiyonel; bos ise backend oranla hesaplar. |
| `lines[].description` | Fatura kalem adi, etiket notu veya kullanici notu | Satir aciklamasi olarak gider. |

Response:

```json
{
  "date": "2026-08-13T00:00:00",
  "documentSeries": "MNV26",
  "documentOrderNo": 10,
  "seriesAndNumber": "MNV26/10",
  "supplierCode": "32000297",
  "createUserNo": 15,
  "lineCount": 1,
  "totalQuantity": 714.4,
  "totalAmount": 25004.0,
  "totalTax": 250.04,
  "updatedAcceptanceRecordCount": 1,
  "offlineTraceKey": "FRMNV260813A1B2C3D4",
  "lines": [
    {
      "lineNo": 0,
      "stockCode": "001082",
      "stockName": "MNV URUN",
      "quantity": 714.4,
      "unitPrice": 35.0,
      "amount": 25004.0,
      "taxAmount": 250.04,
      "taxPointer": 3,
      "inWarehouseNo": 56,
      "outWarehouseNo": 1
    }
  ]
}
```

Yazma kurallari:

- `lines[]` zorunludur; fiyat bilinmeden Mikro belgesi olusturulmaz.
- `documentSeries` bos gelirse `MNV`, `documentOrderNo` bos gelirse ayni seri icin sonraki sira kullanilir.
- `documentNo` bos gelirse `documentOrderNo` metni kullanilir.
- `mikroUserNo` bos gelirse backend default'u `39` kullanilir.
- `acceptanceRecordId` verilirse basarili yazmadan sonra ilgili Furpa etiket kaydi `Mikro_Aktarildi=1` olur.
- `taxAmount` verilirse aynen yazilir; yoksa `taxRatePercent` varsa hesaplanir; ikisi de yoksa `0` yazilir.
- `taxPointer` verilmezse stok kartinin `sto_toptan_vergi` degeri kullanilir.
- Mikro format canli 2026 manav formatidir: once `CARI_HESAP_HAREKETLERI` basligi acilir, sonra `STOK_HAREKETLERI` satirlari bu basliga `sth_fat_uid = cha_Guid` ile baglanir.
- Cari/fatura basligi canli alis faturasi formatina yakindir: `cha_fileid=51`, `cha_tip=1`, `cha_cinsi=35`, `cha_evrak_tip=0`, `cha_cari_cins=0`, `cha_kod=supplierCode`, `cha_ciro_cari_kodu=supplierCode`, `cha_srmrkkodu=56`, `cha_ebelge_turu=7`, `cha_fatura_belge_turu=0`.
- Stok satiri formatinda `sth_tip=0`, `sth_cins=16`, `sth_evraktip=3`, `sth_giris_depo_no=56`, `sth_cikis_depo_no=1`, `sth_fiyat_liste_no=-1` kullanilir.
- Alternatif doviz kuru Mikro `fn_KurBul(date, fn_FirmaAlternatifDovizCinsi(), 1)` fonksiyonundan okunur ve hem cari basliga hem stok satirlarina yazilir.
- `offlineTraceKey` Mikro kolon uzunluguna uygun kisa izdir; `FRMNV{yyMMdd}{hash}` formatinda uretilir ve hem cari baslikta hem stok satirlarinda saklanir.
- Ayni `date + documentSeries + documentOrderNo` icin manav mal kabul belgesi varsa API `409 Conflict` doner.

### Fiyati Degisen Etiket Urunleri

Belirli bir zaman bilgisinden sonra fiyati degisen ve etikete uygun urunleri getirir. `kasa-islemleri.etiket-belgeleri.all-warehouses` yoksa depo sorulmaz; yetki varsa query'de opsiyonel `warehouseNo` gonderilebilir.

`GET /api/kasa-islemleri/etiket-belgeleri/fiyati-degisen-urunler?dateTimeFilter=24.04.2026%2008:00:00&warehouseNo=110`

Uyumluluk icin eski route alias'i da desteklenir:

`GET /api/kasa-islemleri/etiket-belgeleri/get-by-date-for-label?dateTimeFilter=24.04.2026%2008:00:00&warehouseNo=110`

Yetki:

- `kasa-islemleri.etiket-belgeleri.list`

Not:

- `kasa-islemleri.etiket-belgeleri.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir.
- Bu yetki varsa UI belirli depo icin `warehouseNo` gonderebilir; bos gonderirse endpointin destekledigi kapsamda kullanici depo kurali uygulanir.
- `dateTimeFilter` formati `dd.MM.yyyy HH:mm:ss` olmalidir
- response modeli `LabelPriceChangedProductDto` doner
- veri Mikro tarafindaki urun, fiyat degisikligi, fiyat listesi ve barkod tablolarindan okunur
- Fiyat degisikligi filtresi eski API ile ayni mantiktadir: `STOK_FIYAT_DEGISIKLIKLERI.fid_lastup_date > dateTimeFilter`, `fid_yapildi_fl = 1`, `fid_depo_no = warehouseNo`.
- Satisi durdurulmus urunler gelmez: `STOKLAR.sto_satis_dursun = 0`.
- Response urun/stok basina tek satir dondurur. Bir urunun birden fazla barkodu varsa backend aktif barkodlar icinden once `bar_master`, sonra en yeni `bar_create_date`, sonra `bar_birimpntr` onceligiyle tek barkod secer.
- Bir urunun birim/koli/alternatif barkodlari farkli olabilir. Ornek: `046460` stok kodunda birim barkodlari ile 14 haneli koli/ikinci birim barkodu birlikte tanimlidir; bu urunde en guncel aktif barkod `08690637712128` oldugu icin etiket barkodu olarak bu donebilir.
- `barcode` UI'in varsayilan basacagi barkoddur. `barcodes` ayni urunun tum aktif barkod seceneklerini oncelik sirasiyla dondurur; UI isterse detay/dropdown olarak gosterebilir ama liste satir sayisini bu diziye gore cogaltmamalidir.
- `priceChangeDate` kullaniciya gosterilecek son fiyat degisikligi zamanidir ve `dd.MM.yyyy HH:mm` formatindadir.
- `alternativeUnitName` ve `unitPriceFactor` eski etiket mantigiyla Mikro `sto_birim4_ad` / `sto_birim4_katsayi` uzerinden hesaplanir. Ornek 1440 ml urunde fiyat `199.50`, katsayi `1.44` ise birim fiyat `138.54 TL/LITRE` olur.
- UI bu endpointi "son kontrol zamanindan sonra degisen urunler" icin kullanmali; kullanici belgeye eklemeden once gerekirse etiket belgesi detayinda urunu tekrar okutabilir.

Response:

```json
[
  {
    "productCode": "046460",
    "productName": "YUMOS EXTRA 1440ML LILYUM",
    "pluNo": 0,
    "alternativeUnitName": "LITRE",
    "barcode": "08690637712128",
    "barcodes": [
      "08690637712128",
      "8690637563348",
      "8690637712111"
    ],
    "isDomestic": 1,
    "oldPrice": 229,
    "origin": "TURKIYE",
    "price": 199.5,
    "priceChangeDate": "11.08.2026 16:27",
    "unitPriceFactor": 138.54,
    "unitName": "ADET"
  }
]
```

### Etiket Belgesi Olustur

Secili kullanici deposu icin yeni etiket belgesi olusturur.

`POST /api/kasa-islemleri/etiket-belgeleri`

Yetki:

- `kasa-islemleri.etiket-belgeleri.create`

Onemli not:

- `kasa-islemleri.etiket-belgeleri.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. Bu yetki varsa baska depo icin etiket belgesi olusturulacaksa body'de opsiyonel `warehouseNo` gonderilebilir
- en az bir satir zorunludur
- her satir yalnizca `productCode` alanini ister
- backend Furpa veritabaninda `LabelDocuments` ve `LabelDocumentDetails` tablolarina transaction ile yazar

Request:

```json
{
  "lines": [
    {
      "productCode": "015550"
    },
    {
      "productCode": "015551"
    }
  ]
}
```

Response:

```json
{
  "documentId": 16,
  "createDate": "2026-04-24T12:15:00",
  "warehouseNo": 110,
  "lineCount": 2
}
```

UI notu:

- `PUT /api/kasa-islemleri/etiket-belgeleri/{id}` route'u acik olsa da backend tarafinda su an `501 Not Implemented` doner
- detay ekraninda belge basligindan cok urun kartlari on plana cikacagi icin grid tasarimi urun odakli kurulmalidir

### Virmanlar Liste

Secili depo icin virman evraklarinin gecmis listesini getirir.

`GET /api/stok-islemleri/virmanlar?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-30`

Yetki:

- `stok-islemleri.virmanlar.list`

Not:

- response modeli `VirmanListItemDto` doner
- tarih filtresi Mikro tarafinda `STOK_HAREKETLERI.sth_belge_tarih` uzerinden uygulanir
- filtre karsiligi: `sth_evraktip = 6`, `sth_normal_iade = 0`, `sth_cins = 3`, `sth_cikis_depo_no = WarehouseNo`
- `movementTypes` alani ayni evraktaki satirlardan gelen farkli `sth_tip` degerlerini dizi olarak doner
- Canli Mikro verisinde 2026 virmanlari eski sistem mantigiyla ayni depo icinde stok donusumu gibi durur: `sth_tip = 1` cikis satiri, `sth_tip = 0` giris satiridir; `sth_giris_depo_no` ve `sth_cikis_depo_no` genelde ayni subedir.
- UI liste kartinda tek `totalQuantity` alanini "net miktar" gibi yorumlamamalidir. Virmanda bir koli urun cikis, bunun icindeki tekil urunler giris olabilir; bu yuzden cikis ve giris miktarlari farkli birim/anlam tasiyabilir.
- Liste ve detay response'unda `incomingLineCount`, `outgoingLineCount`, `incomingQuantity`, `outgoingQuantity` alanlari vardir. UI ozet icin bunlari ayri gostermelidir.
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

### Virman Detay

Virman evrakinin header ve kalem detayini getirir.

`GET /api/stok-islemleri/virmanlar/F110/15?warehouseNo=110`

Yetki:

- `stok-islemleri.virmanlar.detail`

Not:

- response modeli `VirmanDetailDto` doner
- filtre karsiligi: `sth_evraktip = 6`, `sth_normal_iade = 0`, `sth_cins = 3`, `sth_cikis_depo_no = warehouseNo`
- `items[].movementType` alani her satirin `sth_tip` degerini verir
- `items[].movementType = 1` cikis satiridir; stoktan dusen/kaynak urun gibi gosterilmelidir.
- `items[].movementType = 0` giris satiridir; stoga giren/hedef urun gibi gosterilmelidir.
- Canli ornek mantik: `6'li soda` cikis satiri, `tekil soda` giris satiri. Bu nedenle detay UI'i satirlari tek gridde renk/etiketle ayirabilir veya "Cikislar" ve "Girisler" olarak iki bolumde gosterebilir.
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

### Virman Olustur

Secili kullanici deposu icin yeni virman evragi yazar. Virman, canli eski sistemdeki gibi ayni depo icinde stok donusumu/duzeltmesi mantigiyla calisir.

`POST /api/stok-islemleri/virmanlar`

Yetki:

- `stok-islemleri.virmanlar.create`

Onemli not:

- `stok-islemleri.virmanlar.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. Bu yetki varsa baska depo adina virman olusturulacaksa body'de opsiyonel `warehouseNo` gonderilebilir
- backend `STOK_HAREKETLERI` tablosuna `sth_evraktip = 6`, `sth_normal_iade = 0`, `sth_cins = 3` olacak sekilde kayit yazar
- `movementType` alaninin karsiligi satir bazinda `sth_tip` kolonuna yazilir; `2` gonderilirse backend Mikro uyumu icin satiri `1` cikis ve `0` giris olarak iki stok hareketine acar
- eski yapiya uygun olarak `sth_giris_depo_no` ve `sth_cikis_depo_no` ayni islem deposuna yazilir
- eski yapiya uygun olarak `sth_fiyat_liste_no = -1` ve `sth_teslim_tarihi = 1900-01-01` degerleri kullanilir
- `documentSerie` backend tarafinda `F{islemDepoNo}` olarak uretilir
- `documentOrderNo` ayni seri ve virman turu icin write DB'deki mevcut maksimum sira okunarak uretilir
- Eski canli kayitlarda pratik desen: belge icinde cikis ve giris satirlari birlikte bulunur. UI kullaniciya en net akista cikis urunlerini ve giris urunlerini ayri satirlar olarak hazirlatmalidir.
- `movementType = 2` kisa yolu sadece ayni stok/miktar icin hem cikis hem giris hareketi acmak icindir. Koli bozma gibi "6'li urun cik, 6 adet tekil urun gir" senaryolarinda UI iki ayri satir gondermelidir: cikis satiri `movementType=1`, giris satiri `movementType=0`.
- `totalAmount` su an satir tutarlari `0` yazildigi icin `0` doner

Eski Angular virman karsiligi:

Eski ekranda `POST ProductMovements/AddVirman` endpointine header olmadan dogrudan `CartLine[]` gonderiliyordu. Satirin giris mi cikis mi oldugu `product.barcodeContent` alanindan anlasiliyordu. Yeni API ayni isi daha acik sekilde `lines[].movementType` ile yapar.

| Eski alan | Eski anlam | Yeni alan | Yeni anlam |
|---|---|---|---|
| `product.barcodeContent = "1"` | Stoktan cikan/parcalanan urun | `movementType = 1` | Cikis satiri, `sth_tip = 1` |
| `product.barcodeContent = "0"` | Stoga giren/olusan urun | `movementType = 0` | Giris satiri, `sth_tip = 0` |

UI akisi:

- Kullanicinin sectigi/parcaladigi kaynak urun `movementType=1` olarak gonderilir.
- Kullanicinin olusturdugu/hedef urun `movementType=0` olarak gonderilir.
- Miktarlar birbirinden bagimsiz olabilir; ornek `1 adet 6'li soda cikis`, `6 adet tekil soda giris`.
- UI liste ve detayda satirlari "Cikislar" ve "Girisler" olarak iki bolumde gosterebilir. Tek `totalQuantity` net stok etkisi gibi yorumlanmamalidir.
- Koli bozma, urun donusturme veya reyon duzeltme ekraninda en guvenli model iki acik satirdir: bir cikis, bir giris.
- `movementType=2` UI'in ana akisi olmamalidir; sadece ayni stok ve ayni miktar icin teknik kisa yol gerekiyorsa kullanilmalidir.

Request:

```json
{
  "clientRequestId": "f56fc5a6-b846-4421-a02a-b8f9f0e52d4c",
  "movementDate": "2026-04-21",
  "documentDate": "2026-04-21",
  "documentNo": "",
  "description": "Reyon duzenleme virmani",
  "lines": [
    {
      "stockCode": "015550",
      "movementType": 1,
      "quantity": 1,
      "unitPointer": 1,
      "description": "6'li soda cikis",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": ""
    },
    {
      "stockCode": "015733",
      "movementType": 0,
      "quantity": 6,
      "unitPointer": 1,
      "description": "Tekil soda giris",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": ""
    }
  ]
}
```

Response:

```json
{
  "documentSerie": "F110",
  "documentOrderNo": 15,
  "movementDate": "2026-04-21T00:00:00",
  "documentDate": "2026-04-21T00:00:00",
  "documentNo": "",
  "warehouseNo": 110,
  "movementTypes": [0, 1],
  "lineCount": 2,
  "incomingLineCount": 1,
  "outgoingLineCount": 1,
  "incomingQuantity": 6,
  "outgoingQuantity": 1,
  "totalQuantity": 7,
  "totalAmount": 0,
  "writeConnectionName": "testMikroConnection"
}
```

### Virman Detay Response

```json
{
  "header": {
    "documentDate": "2026-04-21T00:00:00",
    "movementCreateDate": "2026-04-21T10:15:00",
    "movementDate": "2026-04-21T00:00:00",
    "documentNo": "",
    "documentSerie": "F110",
    "documentOrderNo": 15,
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "documentType": 6,
    "movementGenre": 3,
    "movementTypes": [0, 1],
    "description": "Reyon duzenleme virmani",
    "lineCount": 2,
    "incomingLineCount": 1,
    "outgoingLineCount": 1,
    "incomingQuantity": 6,
    "outgoingQuantity": 1,
    "totalQuantity": 7,
    "totalAmount": 0
  },
  "items": [
    {
      "rowNo": 0,
      "stockCode": "015550",
      "stockName": "KINIK SADE SODA 200ML*6 LI",
      "unitName": "ADET",
      "unitPointer": 1,
      "movementType": 1,
      "quantity": 1,
      "quantity2": 0,
      "unitPrice": 0,
      "lineAmount": 0,
      "description": "Reyon duzenleme virmani",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": ""
    },
    {
      "rowNo": 1,
      "stockCode": "015733",
      "stockName": "KINIK SADE SODA 200ML",
      "unitName": "ADET",
      "unitPointer": 1,
      "movementType": 0,
      "quantity": 6,
      "quantity2": 0,
      "unitPrice": 0,
      "lineAmount": 0,
      "description": "Reyon duzenleme virmani",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": ""
    }
  ]
}
```

## Iade Islemleri

### Depo Iadeleri Liste

`GET /api/iade-islemleri/depo-iadeleri?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-10`

Geriye uyum icin root route giden liste gibi calisir.

Acik yon bazli route'lar:

- `GET /api/iade-islemleri/depo-iadeleri/giden?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-10`
- `GET /api/iade-islemleri/depo-iadeleri/gelen?WarehouseNo=50&StartDate=2026-04-01&EndDate=2026-04-10`

Yetki:

- giden liste icin: `iade-islemleri.giden-depo-iadeleri.list`
- gelen liste icin: `iade-islemleri.gelen-depo-iadeleri.list`

Not:

- `me.modules` tarafinda bu ekranlar iki ayri menu olarak gorunur: `GidenDepoIadeleri` ve `GelenDepoIadeleri`
- UI isimlendirme onerisi: kaynak sube icin `Giden Depo Iadeleri`, iadenin geldigi sube icin `Gelen Depo Iadeleri`
- Bir sube depo iadesi kestiginde ayni evrak diger sube tarafinda `gelen` listesinde gorulebilir
- tarih filtresi Mikro tarafinda `STOK_HAREKETLERI.sth_tarih` uzerinden yapilir
- eski depolar arasi sevk mantiginin iade varyantidir
- Mikro kolon karsiliklari: `sth_evraktip = 17`, `sth_tip = 2`, `sth_cins = 6`, `sth_normal_iade = 1`, `sth_cikis_depo_no = WarehouseNo`
- response modeli depolar arasi sevkler liste satiri modeliyle aynidir
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

### Depo Iadeleri Detay

Seri + sira ile:

`GET /api/iade-islemleri/depo-iadeleri/F110/42?warehouseNo=110`

Geriye uyum icin root route giden detay gibi calisir.

Acik yon bazli route'lar:

- `GET /api/iade-islemleri/depo-iadeleri/giden/F110/42?warehouseNo=110`
- `GET /api/iade-islemleri/depo-iadeleri/gelen/F110/42?warehouseNo=50`

Yetki:

- giden detay icin: `iade-islemleri.giden-depo-iadeleri.detail`
- gelen detay icin: `iade-islemleri.gelen-depo-iadeleri.detail`

Not:

- response modeli depolar arasi sevk detay response modeliyle aynidir
- `giden` detayda filtre `sth_evraktip = 17`, `sth_normal_iade = 1`, `sth_cikis_depo_no = warehouseNo` olarak uygulanir
- `gelen` detayda ayni evrak, hedef/transfer alanlarina gore alici sube perspektifinden okunur
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

### Depo Iadesi Guncelle

E-irsaliyesi henuz olusturulup gonderilmemis giden depo iade evragini detay ekranindan gunceller.

`PUT /api/iade-islemleri/depo-iadeleri/giden/F110/42?warehouseNo=110`

Geriye uyum icin root route da ayni update gibi calisir:

`PUT /api/iade-islemleri/depo-iadeleri/F110/42?warehouseNo=110`

Yetki:

- `iade-islemleri.giden-depo-iadeleri.update`

Onemli not:

- Bu endpoint sadece giden/kaynak depo iadesinde calisir; gelen iade/mal kabul tarafindan iade evragi degistirilmez.
- `*.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kaynak depo kabul eder. Bu yetki varsa baska kaynak depo icin `warehouseNo` query parametresi gonderilebilir.
- Evrak e-irsaliye olarak gonderildiyse update reddedilir. Backend `sth_kilitli`, `sth_belge_no = FRM...` ve `sth_aciklama = UUID` izlerini kontrol eder.
- Evrak karsi depo tarafindan kabul edildiyse (`sth_nakliyedurumu = 1`) update reddedilir.
- Satir aksiyonu `lines[].action` ile belirlenir: `update`, `add`, `delete`. Bos/null gonderilirse geriye uyum icin `update` kabul edilir.
- `update` ve `delete` aksiyonlarinda satir eslestirmesi zorunlu olarak `movementGuid` ile yapilir.
- `add` aksiyonunda `movementGuid` gonderilmez; `stockCode` ve `quantity` zorunludur. `rowNo` bos birakilirsa backend mevcut evraktaki son satirdan sonra yeni satir no verir.
- `delete` aksiyonu satiri fiziksel olarak siler. Satira bagli `STOK_HAREKETLERI_EK` kaydi varsa o da silinir.
- `quantity` alani `sth_miktar` degerini degistirir. `unitPrice` gonderilip `amount` bos birakilirsa backend `sth_tutar = quantity * unitPrice` hesaplar. `amount` gonderilirse tutar aynen kullanilir.
- Iade icin otomatik depo siparis satiri olusturulduysa backend bagli `DEPOLAR_ARASI_SIPARISLER` satirini yeni miktar, tutar, stok, depo ve aciklama bilgileriyle aynalar. Iade satiri silinirse bu satira bagli otomatik depo siparis satiri da fiziksel olarak silinir.

Request:

```json
{
  "movementDate": "2026-04-17",
  "documentDate": "2026-04-17",
  "targetWarehouseNo": 50,
  "transitWarehouseNo": 60,
  "description": "Iade duzeltildi",
  "lines": [
    {
      "action": "update",
      "movementGuid": "8d4a5a77-1b3f-4f2a-93a1-b90a1b7d3c11",
      "quantity": 8,
      "unitPrice": 12.5,
      "unitPointer": 1,
      "description": "Miktar duzeltildi"
    },
    {
      "action": "add",
      "stockCode": "015550",
      "quantity": 3,
      "unitPrice": 12.5,
      "unitPointer": 1,
      "description": "Yeni satir"
    },
    {
      "action": "delete",
      "movementGuid": "03d6df6a-b1b2-4923-b8f0-28060446e61f"
    }
  ]
}
```

Response:

```json
{
  "documentSerie": "F110",
  "documentOrderNo": 42,
  "sourceWarehouseNo": 110,
  "targetWarehouseNo": 50,
  "transitWarehouseNo": 60,
  "isReturn": true,
  "updatedLineCount": 3,
  "addedLineCount": 1,
  "deletedLineCount": 1,
  "lineCount": 2,
  "totalQuantity": 11,
  "totalAmount": 137.5,
  "updatedAt": "2026-08-13T14:30:00",
  "updateUser": 110,
  "writeConnectionName": "testMikroConnection"
}
```

### Depo Iadesini E-Irsaliyeye Cevir

Detay ekranindaki mevcut depo iade evragini e-irsaliye olarak gondermek icin:

`POST /api/iade-islemleri/depo-iadeleri/F110/42/e-irsaliye?warehouseNo=110`

Yetki:

- `iade-islemleri.giden-depo-iadeleri.detail`

Onemli not:

- Bu endpoint yeni depo iade kaydi olusturmaz; mevcut iade kaydini okuyup Uyumsoft e-irsaliye servisine yollar.
- Body zorunludur; seri ve sira bilgisi URL'den, tasima bilgileri body'den alinir.
- `warehouseNo` verilmezse JWT icindeki kullanici deposu kullanilir.
- Depo iadesi e-irsaliyesi, depolar arasi sevk ile ayni veri kaynagini kullanir ancak `sth_normal_iade = 1` filtresiyle iade hareketlerini okur.
- Basarili response dondugunde UI isterse servis dokuman numarasini ekranda bilgi olarak gosterebilir.

Request:

```json
{
  "plaque": "16 ABC 123",
  "driverNameSurname": "Ad Soyad",
  "driverTckn": "11111111111"
}
```

### Depo Iadesi E-Irsaliye PDF Goster

Detay ekraninda daha once gonderilmis e-irsaliyenin PDF'ini acmak icin:

`GET /api/iade-islemleri/depo-iadeleri/giden/F110/42/e-irsaliye/pdf?warehouseNo=110`

Geriye uyum icin root route da ayni islem gibi calisir:

`GET /api/iade-islemleri/depo-iadeleri/F110/42/e-irsaliye/pdf?warehouseNo=110`

Yetki:

- `iade-islemleri.giden-depo-iadeleri.detail`

Onemli not:

- Bu endpoint `application/pdf` binary response doner; JSON beklenmemelidir.
- Response `inline` olarak doner; UI isterse yeni sekmede, isterse iframe/pdf viewer icinde acabilir.
- Request body yoktur; seri ve sira bilgisi URL'den alinir.
- `warehouseNo` verilmezse JWT icindeki kullanici deposu kullanilir.
- Evrak henuz e-irsaliye olarak gonderilmediyse endpoint `409 Conflict` doner.

### Depo Iadeleri Olustur

`POST /api/iade-islemleri/depo-iadeleri`

Geriye uyum icin root route giden create gibi calisir.

Acik yon bazli route:

- `POST /api/iade-islemleri/depo-iadeleri/giden`

Yetki:

- `iade-islemleri.giden-depo-iadeleri.create`

Onemli not:

- Yazma yolu `MikroWriteRouting:WarehouseReturn` ile belirlenir: `Database` modunda EF Core/write DB, `MikroApi` modunda `POST /Api/apiMethods/DahiliStokHareketKaydetV2` kullanilir.
- Depo iadesi hareketi `sth_evraktip = 17`, `sth_tip = 2`, `sth_cins = 6`, `sth_normal_iade = 1` olarak olusturulur.
- `iade-islemleri.giden-depo-iadeleri.all-warehouses` yoksa `sourceWarehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. Bu yetki varsa baska kaynak depodan iade olusturulacaksa body'de opsiyonel `sourceWarehouseNo` gonderilebilir.
- `targetWarehouseNo` iadenin donecegi/hedef depodur ve `sth_nakliyedeposu` alanina yazilir.
- `transitWarehouseNo` verilmezse `60` kullanilir ve `sth_giris_depo_no` alanina yazilir.
- `documentSerie` backend tarafinda `F{islemDepoNo}` olarak uretilir.
- `documentOrderNo` ayni seri, evrak tipi ve iade tipi icin write DB'deki mevcut maksimum sira okunarak uretilir.
- Depolar arasi sevkten farki: UI request'inde `warehouseOrderLineGuid` yoktur. Otomatik depo siparisi ayari aciksa backend once depo siparisini olusturur ve satir GUID'ini iade hareketine `sth_subesip_uid` olarak baglar; ayar kapaliysa siparis baglantisi kurulmaz.
- `MikroApi` modunda otomatik depo siparisi gerekiyorsa `MikroWriteRouting:IssuedWarehouseOrder` de `MikroApi` olmalidir; aksi halde backend DB tamamlayici insert yapmadan hata dondurur.
- Plaka, sofor adi ve TCKN bu create request'inde gonderilmez. E-irsaliye gonderiminde manuel akista bu alanlar zorunludur; kayitli sofor secilirse `driverId` yeterlidir.

Request:

```json
{
  "clientRequestId": "622208d6-f427-48ef-b9fb-bd4e6e1844eb",
  "targetWarehouseNo": 50,
  "transitWarehouseNo": 60,
  "movementDate": "2026-04-17",
  "documentDate": "2026-04-17",
  "documentNo": "",
  "description": "",
  "lines": [
    {
      "stockCode": "015550",
      "quantity": 10,
      "unitPrice": 0,
      "unitPointer": 1,
      "description": "",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": ""
    }
  ]
}
```

Response:

```json
{
  "documentSerie": "F110",
  "documentOrderNo": 0,
  "movementDate": "2026-04-17T00:00:00",
  "documentDate": "2026-04-17T00:00:00",
  "documentNo": "",
  "sourceWarehouseNo": 110,
  "targetWarehouseNo": 50,
  "transitWarehouseNo": 60,
  "lineCount": 1,
  "totalQuantity": 10,
  "totalAmount": 0,
  "writeConnectionName": "testMikroConnection"
}
```

### Firma Iadeleri Liste

`GET /api/iade-islemleri/firma-iadeleri?WarehouseNo=110&StartDate=2026-04-01&EndDate=2026-04-10`

Yetki:

- `iade-islemleri.firma-iadeleri.list`

Not:

- `FirmaIadeleri` hem `me.modules` tarafinda hem backend klasor/route yapisinda `IadeIslemleri` altindadir
- tarih filtresi Mikro tarafinda `STOK_HAREKETLERI.sth_belge_tarih` uzerinden yapilir
- eski mantiktaki `DocumentType = 1`, `MovementType = 1`, `IsReturn = 1`, `OutputWarehouseNo = WarehouseNo` filtresinin karsiligidir
- Mikro kolon karsiliklari: `sth_evraktip = 1`, `sth_tip = 1`, `sth_normal_iade = 1`, `sth_cikis_depo_no = WarehouseNo`
- response modeli firma sevkleri liste satiri modeliyle aynidir
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

### Firma Iadeleri Detay

Seri + sira ile:

`GET /api/iade-islemleri/firma-iadeleri/F110/4651?warehouseNo=110`

Yetki:

- `iade-islemleri.firma-iadeleri.detail`

Not:

- response modeli firma sevk detay response modeliyle aynidir
- filtre `sth_evraktip = 1`, `sth_tip = 1`, `sth_normal_iade = 1`, `sth_cikis_depo_no = warehouseNo` olarak uygulanir
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

### Firma Iadesini E-Irsaliyeye Cevir

Detay ekranindaki mevcut iade evragini e-irsaliye olarak gondermek icin:

`POST /api/iade-islemleri/firma-iadeleri/F110/4651/e-irsaliye?warehouseNo=110`

Yetki:

- `iade-islemleri.firma-iadeleri.detail`

Onemli not:

- Bu endpoint yeni iade kaydi olusturmaz; mevcut iade kaydini okuyup Uyumsoft e-irsaliye servisine yollar.
- Body zorunludur; seri ve sira bilgisi URL'den, tasima bilgileri body'den alinir.
- `warehouseNo` verilmezse JWT icindeki kullanici deposu kullanilir.
- Firma iadesi icin UBL icerigi mevcut hareket, cari ve depo bilgilerinden backend tarafinda uretilir.
- Basarili response dondugunde UI isterse servis dokuman numarasini ekranda bilgi olarak gosterebilir.

Request:

```json
{
  "plaque": "16 ABC 123",
  "driverNameSurname": "Ad Soyad",
  "driverTckn": "11111111111"
}
```

### Firma Iadesi E-Irsaliye PDF Goster

Detay ekraninda daha once gonderilmis e-irsaliyenin PDF'ini acmak icin:

`GET /api/iade-islemleri/firma-iadeleri/F110/4651/e-irsaliye/pdf?warehouseNo=110`

Yetki:

- `iade-islemleri.firma-iadeleri.detail`

Onemli not:

- Bu endpoint `application/pdf` binary response doner; JSON beklenmemelidir.
- Response `inline` olarak doner; UI isterse yeni sekmede, isterse iframe/pdf viewer icinde acabilir.
- Request body yoktur; seri ve sira bilgisi URL'den alinir.
- `warehouseNo` verilmezse JWT icindeki kullanici deposu kullanilir.
- Evrak henuz e-irsaliye olarak gonderilmediyse endpoint `409 Conflict` doner.

### Firma Iadeleri Olustur

`POST /api/iade-islemleri/firma-iadeleri`

Yetki:

- `iade-islemleri.firma-iadeleri.create`

Onemli not:

- Bu endpoint EF Core uzerinden ayri `MikroWriteDbContext` ile yazma yapar.
- `STOK_HAREKETLERI` tablosuna `sth_evraktip = 1`, `sth_tip = 1`, `sth_normal_iade = 1` olarak firma iadesi yazar.
- `iade-islemleri.firma-iadeleri.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. Bu yetki varsa baska depo adina iade olusturulacaksa body'de opsiyonel `warehouseNo` gonderilebilir.
- `customerCode` zorunludur ve write DB'de `CARI_HESAPLAR` icinde kontrol edilir.
- `documentSerie` backend tarafinda `F{islemDepoNo}` olarak uretilir.
- `documentOrderNo` ayni seri, evrak tipi ve iade tipi icin write DB'deki mevcut maksimum sira okunarak uretilir; ilk evrak `0`, sonraki evraklar `1, 2...` seklinde gider.
- Plaka, sofor adi ve TCKN bu create request'inde gonderilmez. E-irsaliye gonderiminde manuel akista bu alanlar zorunludur; kayitli sofor secilirse `driverId` yeterlidir.
- `deliverer` teslim eden, `receiver` teslim alan bilgisidir. Opsiyoneldir; gonderilirse Mikro `STOK_HAREKETLERI.sth_HareketGrupKodu2` ve `sth_HareketGrupKodu3` alanlarina yazilir.
- Request/response modeli firma giden sevk create ile aynidir; tek fark kaydin `returnType = 1` olarak yazilmasidir.

Request:

```json
{
  "clientRequestId": "527c6a79-f98b-438d-92f7-9f1cfc16cd64",
  "customerCode": "120.01.001",
  "movementDate": "2026-04-17",
  "documentDate": "2026-04-17",
  "documentNo": "IAD-0001",
  "description": "",
  "deliverer": "Teslim Eden",
  "receiver": "Teslim Alan",
  "lines": [
    {
      "stockCode": "015792",
      "quantity": 5,
      "unitPrice": 125,
      "unitPointer": 1,
      "description": "",
      "partyCode": "",
      "lotNo": 0,
      "projectCode": "",
      "customerResponsibilityCenter": "",
      "productResponsibilityCenter": ""
    }
  ]
}
```

Response:

```json
{
  "documentSerie": "F110",
  "documentOrderNo": 0,
  "movementDate": "2026-04-17T00:00:00",
  "documentDate": "2026-04-17T00:00:00",
  "documentNo": "IAD-0001",
  "warehouseNo": 110,
  "customerCode": "120.01.001",
  "lineCount": 1,
  "totalQuantity": 5,
  "totalAmount": 625,
  "writeConnectionName": "testMikroConnection"
}
```

### E-Irsaliye Gonderme Response

Dort e-irsaliye gonderme endpointi de ayni request body modelini bekler ve ayni response modelini doner. UI bu bilgileri sevk/iade create ekraninda degil, e-irsaliye gonderme aninda almalidir.

Sofor bilgisi iki sekilde gonderilebilir:

- Elle giris: `driverId` bos gonderilir; `plaque`, `driverNameSurname` ve `driverTckn` zorunludur.
- Listeden secim: `driverId` gonderilir; backend `despatch_drivers` tablosundaki aktif soforu okuyup plaka/ad soyad/TCKN alanlarini doldurur.

`driverNameSurname` dolu gonderilirse en az iki kelime olacak sekilde `Ad Soyad` formatinda olmalidir; tek kelime gelirse API 400 doner. `driverTckn` dolu gonderilirse 11 haneli numeric olmalidir. Backend UBL uretiminde `DriverPerson` icinde sirayi `FirstName`, `FamilyName`, `NationalityID` olarak yazar; `NationalityID` soyaddan once gonderilmez.

Request - elle giris:

```json
{
  "plaque": "16 ABC 123",
  "driverNameSurname": "Ad Soyad",
  "driverTckn": "11111111111"
}
```

Request - kayitli sofor secimi:

```json
{
  "driverId": "1bc27065-f775-468f-9fc9-0e1ad107d105"
}
```

Request - kayitli sofor secilip plaka manuel duzeltilirse:

```json
{
  "driverId": "1bc27065-f775-468f-9fc9-0e1ad107d105",
  "plaque": "16 XYZ 999"
}
```

Notlar:

- `driverId` bos veya yoksa eski manuel zorunlu alan mantigi calisir.
- `driverId` doluysa kayit aktif degilse veya bulunamazsa `404 Not Found` doner.
- `driverId` ile birlikte gelen dolu manuel alanlar secili sofor kaydinin ustune yazilir; bos manuel alanlar sofor tanimindan doldurulur.
- Basarili gonderimden sonra cozulmus plaka ve TCKN Mikro hareket satirlarina metadata olarak yazilmaya calisilir.
- Response icindeki `localMikroMetadataUpdated=false` gelirse Uyumsoft gonderimi basarilidir, fakat Mikro hareket satirlari FRM/ETTN metadata'si ile isaretlenememistir. UI bu durumda tekrar e-irsaliye gondermemeli; `eDespatchDocumentNo` ve `eDespatchUuid` degerleriyle lokal Mikro belge metadata onarimi yapilmalidir.
- Ayni evrak icin belge akisinda basarili Uyumsoft gonderimi kayitliysa backend ikinci gonderimi `409 Conflict` ile engeller. Bu kural Mikro metadata isaretleme eksik kalmis olsa bile Uyumsoft'ta duplicate zarf olusmasini onlemek icindir.

Response:

```json
{
  "documentType": 1,
  "documentSerie": "F110",
  "documentOrderNo": 422,
  "eDespatchDocumentNo": "FRM2026000000422",
  "eDespatchUuid": "4d6dbec8-2eab-43cc-8f0a-cafb3f7f3a44",
  "serviceDocumentId": "123456789",
  "serviceDocumentNumber": "IRS2026000000012",
  "sentAt": "2026-04-17T14:25:00+03:00",
  "endpointUrl": "http://efatura.uyumsoft.com.tr/Services/BasicDespatchIntegration"
}
```

Alanlar:

- `documentType`: `1 = giden firma sevki`, `2 = firma iadesi`, `3 = depolar arasi giden sevk`, `4 = depo iadesi`
- `eDespatchDocumentNo`: backend tarafinda uretilen lokal e-irsaliye dokuman numarasi (`FRM` + yil + 9 haneli sira)
- `eDespatchUuid`: UBL icine yazilan benzersiz UUID
- `serviceDocumentId`: Uyumsoft tarafindan donen teknik dokuman id
- `serviceDocumentNumber`: Uyumsoft tarafindan donen dokuman/numara bilgisi
- `sentAt`: backend'in gonderim zamani
- `endpointUrl`: istegin gittigi servis adresi

### E-Irsaliye PDF Response

PDF gosterme endpointleri `GET` ile cagrilir ve body beklemez.

Ornek route'lar:

- `GET /api/sevk-islemleri/depolar-arasi-sevkler/giden/{seri}/{sira}/e-irsaliye/pdf?warehouseNo=...`
- `GET /api/sevk-islemleri/firma-sevkleri/giden/{seri}/{sira}/e-irsaliye/pdf?warehouseNo=...`
- `GET /api/iade-islemleri/depo-iadeleri/giden/{seri}/{sira}/e-irsaliye/pdf?warehouseNo=...`
- `GET /api/iade-islemleri/firma-iadeleri/{seri}/{sira}/e-irsaliye/pdf?warehouseNo=...`

Response:

- `200 OK`
- `Content-Type: application/pdf`
- `Content-Disposition: inline; filename="{eDespatchDocumentNo}.pdf"`

UI kullanim notu:

- Bu endpointler JSON donmez; response blob/binary olarak ele alinmalidir.
- Browser yeni sekmede acma, iframe icinde gosterme veya custom pdf viewer'a blob URL baglama yaklasimlari kullanilabilir.
- Evrak henuz e-irsaliye olarak gonderilmemisse `409 Conflict` doner.
- Evrak bulunamazsa `404 Not Found` doner.

## Kasa Islemleri

### Kasa Cirolari Liste

Yeni kasa sisteminden gelen ciro verilerini tarih araliginda vardiya ve kasiyer bazli ozetler.

`GET /api/kasa-islemleri/kasa-cirolari?startDate=2026-05-01&endDate=2026-05-04&warehouseNo=110`

Ek rotalar:

- `GET /api/kasa-islemleri/kasa-cirolari/yeni`
- `GET /api/kasa-islemleri/kasa-cirolari/eski`
- `GET /api/kasa-islemleri/kasa-cirolari/toplam`

Yetki:

- `kasa-islemleri.kasa-cirolari.list`

Not:

- yeni kasa rotalari ayri `ShopigoCiroConnection` kaynagini kullanir ve `SHOPIGO` veritabanindan okur
- `/api/kasa-islemleri/kasa-cirolari` ve `/yeni` yalnizca yeni kasalari doner
- `/eski` eski kasa icin `TurnoverTotals` kaynagindan gun/sube toplam satiri doner
- eski kasa liste satirinda kasa/kasiyer kirilimi olmadigi icin `shiftNo=0`, `cashierCode=""`, `cashierName=""` doner
- `/toplam` yeni kasa satirlarini ve eski kasa gun/sube toplam satirini birlikte doner
- `shiftNo` alani SHOPIGO tarafindaki `kasano` degerinden beslenir
- liste request modeli ortak `WarehouseOrderDateRangeHttpRequest` yapisindadir
- `warehouseNo` verilmezse JWT icindeki kullanici deposu kullanilir
- response modeli `CashTurnoverListItemDto` doner
- `source` alani satirin `new` veya `old` kaynagini gosterir
- `netCollectionAmount` backend tarafinda `totalCollectionAmount - totalCustomerCommission` olarak hesaplanir

Response:

```json
[
  {
    "businessDate": "2026-05-01T00:00:00",
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "shiftNo": 1,
    "cashierCode": "1001",
    "cashierName": "MEHMET YILMAZ",
    "productLineCount": 124,
    "totalSalesQuantity": 187.5,
    "totalSalesAmount": 25640.75,
    "paymentLineCount": 18,
    "totalCollectionAmount": 25640.75,
    "totalCustomerCommission": 142.3,
    "netCollectionAmount": 25498.45,
    "source": "new"
  }
]
```

### Kasa Cirolari Ozet

Tarih araligindaki eski kasa, yeni kasa veya ikisinin toplamini sube bazli ozetler.

`GET /api/kasa-islemleri/kasa-cirolari/ozet?startDate=2026-05-03&endDate=2026-05-05`

Ek rotalar:

- `GET /api/kasa-islemleri/kasa-cirolari/yeni/ozet`
- `GET /api/kasa-islemleri/kasa-cirolari/eski/ozet`
- `GET /api/kasa-islemleri/kasa-cirolari/toplam/ozet`

Yetki:

- `kasa-islemleri.kasa-cirolari.list`

Not:

- `warehouseNo` opsiyoneldir; verilirse tek sube, verilmezse tum subeler doner
- `/ozet` ve `/yeni/ozet` yalnizca yeni kasalari doner
- `/eski/ozet` yalnizca klasik Mikro `TurnoverTotals` ve `TurnoverDetails` kaynagindaki eski kasalari doner
- `/toplam/ozet` eski ve yeni kasa verilerini branch bazinda birlestirir
- response modeli `CashTurnoverOverviewDto` doner
- `subeCirolari` listesi branch bazli toplamlari icerir
- yeni kasa tarafinda `customerCount` alani yalnizca tamamlanmis (`status = 4`) `received_sales` fislerinden hesaplanir; fisler `receipt_number`, bu bos ise `uuid` bazinda ve gun/kasa kiriliminda tekillestirilir
- yeni kasa tarafinda `discountCardCustomerCount`, `furparaCardCustomerCount`, `expenseNoteTotal`, `expenseNoteCount`, `futuresSalesTotal` ve `futuresSalesCount` alanlari kaynakta dogrudan olmadigi icin `0` doner
- yeni kasa odeme kiriliminda `Nakit` nakit, yemek/gift kart tipleri `giftCardTotal`, diger tahsilat tipleri `creditTotal` tarafina yazilir
- `averageBasketAmount` backend tarafinda `overallTotal / customerCount` olarak hesaplanir

Response:

```json
{
  "dailyTotal": 398941.24,
  "dailyCashPayment": 141311.28,
  "dailyCreditCardPayment": 197504.13,
  "dailyGiftCardPayment": 59502.73,
  "dailyExpenseNoteTotal": 974.4,
  "dailyCustomerCount": 2155,
  "dailyFurparaCardCustomerCount": 0,
  "dailyDiscountCardCustomerCount": 4,
  "dailyExpenseNoteCount": 5,
  "averageBasketAmount": 185.12,
  "dailyFuturesSalesCount": 0,
  "dailyFuturesSalesTotal": 0,
  "subeCirolari": [
    {
      "region": "1",
      "branchNo": 115,
      "branchName": "DOBURCA",
      "customerCount": 17,
      "discountCardCustomerCount": 0,
      "furparaCardCustomerCount": 16,
      "lastBillTime": "08:44:15",
      "cashTotal": 1359.24,
      "creditTotal": 105,
      "giftCardTotal": 0,
      "expenseNoteTotal": 0,
      "expenseNoteCount": 0,
      "overallTotal": 2295.9,
      "futuresSalesTotal": 0,
      "futuresSalesCount": 0,
      "averageBasketAmount": 135.05
    }
  ]
}
```

### Kasa Cirolari Detay

Secili tarih, vardiya ve kasiyer icin odeme tipi ve kasa/banka kirilimini getirir.

`GET /api/kasa-islemleri/kasa-cirolari/detay?businessDate=2026-05-01&shiftNo=1&cashierCode=1001&warehouseNo=110`

Ek rotalar:

- `GET /api/kasa-islemleri/kasa-cirolari/yeni/detay`
- `GET /api/kasa-islemleri/kasa-cirolari/eski/detay`
- `GET /api/kasa-islemleri/kasa-cirolari/toplam/detay`

Yetki:

- `kasa-islemleri.kasa-cirolari.detail`

Not:

- `businessDate`, `shiftNo` ve `cashierCode` zorunludur
- `shiftNo` filtresi SHOPIGO tarafinda `kasano` kolonu ile eslestirilir
- eski kasa tarafinda kasa/kasiyer bazli detay kaynagi olmadigindan `/eski/detay` kayit bulamazsa `404 Not Found` doner
- response modeli `CashTurnoverDetailDto` doner
- ustte toplam header bilgisi, altta odeme tipi bazli kirilim listesi gelir
- `source` alani hem header hem odeme satirlarinda kaynagi gosterir
- kayit bulunamazsa `404 Not Found` doner

Response:

```json
{
  "header": {
    "businessDate": "2026-05-01T00:00:00",
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "shiftNo": 1,
    "cashierCode": "1001",
    "cashierName": "MEHMET YILMAZ",
    "productLineCount": 124,
    "totalSalesQuantity": 187.5,
    "totalSalesAmount": 25640.75,
    "paymentLineCount": 18,
    "totalCollectionAmount": 25640.75,
    "totalCustomerCommission": 142.3,
    "netCollectionAmount": 25498.45,
    "source": "new"
  },
  "payments": [
    {
      "paymentTypeNo": 1,
      "paymentTypeName": "Nakit",
      "cashBankCode": "KASA-01",
      "cashBankName": "MAGAZA KASA 1",
      "paymentLineCount": 5,
      "amount": 14320.5,
      "customerCommission": 0,
      "netAmount": 14320.5,
      "source": "new"
    },
    {
      "paymentTypeNo": 5,
      "paymentTypeName": "Akbank POS",
      "cashBankCode": "POS-AKBANK",
      "cashBankName": "AKBANK POS",
      "paymentLineCount": 7,
      "amount": 11320.25,
      "customerCommission": 142.3,
      "netAmount": 11177.95,
      "source": "new"
    }
  ]
}
```

### Yeni Kasa Analizleri

Yeni kasa sisteminden gelen gercek satis verilerini denetim, mutabakat ve operasyonel analiz amaciyla listeler. Bu modul yalnizca `ShopigoCiroConnection` kaynagini kullanir; eski kasa `TurnoverTotals`/`TurnoverDetails` verileriyle karismaz. `Kasa Cirolari` rapor ekranindan farki, ciroyu gostermenin yaninda duplicate, fis-odeme farki, satir toplami farki, bilinmeyen odeme tipi ve bos kasa/kasiyer gibi veri kalitesi sorunlarini da gorunur hale getirmesidir.

Temel route:

- `api/kasa-islemleri/yeni-kasa-analizleri`

Yetki:

- `kasa-islemleri.yeni-kasa-analizleri.list`

Ortak query:

```text
startDate       zorunlu, ISO tarih
endDate         zorunlu, ISO tarih
warehouseNo     opsiyonel; verilirse tek sube
cashRegisterNo  opsiyonel; SHOPIGO `kasano` degeri
cashierCode     opsiyonel; SHOPIGO `initiated_by` degeri
take            opsiyonel; default 500, max 2000
onlyProblematic opsiyonel; fis-mutabakat icin sadece problemli fisleri dondurur
```

Endpoint ozeti:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `GET /api/kasa-islemleri/yeni-kasa-analizleri/ciro-ozeti` | query | `YeniKasaAnalizHttpRequest` | `YeniKasaCiroOzetItemDto[]` | `list` |
| `GET /api/kasa-islemleri/yeni-kasa-analizleri/kasa-ozeti` | query | `YeniKasaAnalizHttpRequest` | `YeniKasaKasaOzetItemDto[]` | `list` |
| `GET /api/kasa-islemleri/yeni-kasa-analizleri/fis-mutabakat` | query | `YeniKasaAnalizHttpRequest` | `YeniKasaFisMutabakatItemDto[]` | `list` |
| `GET /api/kasa-islemleri/yeni-kasa-analizleri/anomaliler` | query | `YeniKasaAnalizHttpRequest` | `YeniKasaAnomalyItemDto[]` | `list` |
| `GET /api/kasa-islemleri/yeni-kasa-analizleri/odeme-tipleri` | query | `YeniKasaAnalizHttpRequest` | `YeniKasaPaymentMethodItemDto[]` | `list` |
| `GET /api/kasa-islemleri/yeni-kasa-analizleri/saglik-ozeti` | query | `YeniKasaAnalizHttpRequest` | `YeniKasaSaglikOzetItemDto[]` | `list` |
| `GET /api/kasa-islemleri/yeni-kasa-analizleri/fis-detay` | query | `YeniKasaFisDetayHttpRequest` | `YeniKasaFisDetayDto` | `list` |

#### Yeni Kasa Ciro Ozeti

Sube, kasa ve kasiyer bazinda yeni kasa ciro ozetini verir.

`GET /api/kasa-islemleri/yeni-kasa-analizleri/ciro-ozeti?startDate=2026-07-08&endDate=2026-07-08&warehouseNo=110`

Not:

- Yalniz tamamlanmis (`status = 4`) ve silinmemis `received_sales` satirlari dikkate alinir.
- Tarih filtresi `received_at` uzerinden uygulanir.
- Fis tekillestirme once `uuid`, yoksa `receipt_number`, o da yoksa satir `id` uzerinden yapilir.
- `saleTotal` satis header toplamidir.
- `productLineCount` ve `productQuantity` silinmemis/iade edilmemis `sale_items` satirlarindan gelir.
- `paymentTotal` silinmemis/iade edilmemis `payments` satirlarindan gelir.
- `difference = saleTotal - paymentTotal` olarak hesaplanir.

Response:

```json
[
  {
    "businessDate": "2026-07-08T00:00:00",
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "cashRegisterNo": "1",
    "cashierCode": "1001",
    "cashierName": "MEHMET YILMAZ",
    "saleRowCount": 245,
    "receiptCount": 242,
    "productLineCount": 1834,
    "productQuantity": 2210.5,
    "saleTotal": 185430.25,
    "paymentLineCount": 248,
    "paymentTotal": 185430.25,
    "difference": 0,
    "firstSaleAt": "2026-07-08T08:12:03",
    "lastSaleAt": "2026-07-08T22:45:10"
  }
]
```

#### Yeni Kasa Kasa Ozeti

Sube ve kasa bazinda gunluk toplam satis, odeme ve odeme kategori kirilimini verir.

`GET /api/kasa-islemleri/yeni-kasa-analizleri/kasa-ozeti?startDate=2026-07-08&endDate=2026-07-08&warehouseNo=110`

Odeme kategorileri:

- `cashTotal`: nakit odemeler
- `creditCardTotal`: kredi/banka karti odemeleri
- `giftCardTotal`: yemek karti/gift card benzeri odemeler
- `otherPaymentTotal`: odemesiz, kapali hesap veya baska kategoriye dusen odemeler
- `unknownPaymentTotal`: `payment_methods` ile eslesmeyen odemeler

Response:

```json
[
  {
    "businessDate": "2026-07-08T00:00:00",
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "cashRegisterNo": "1",
    "saleRowCount": 245,
    "receiptCount": 242,
    "saleTotal": 185430.25,
    "paymentTotal": 185430.25,
    "cashTotal": 62100,
    "creditCardTotal": 103250.25,
    "giftCardTotal": 20080,
    "otherPaymentTotal": 0,
    "unknownPaymentTotal": 0,
    "difference": 0,
    "cashierCount": 4,
    "lastSaleAt": "2026-07-08T22:45:10"
  }
]
```

#### Yeni Kasa Fis Mutabakat

Her fis icin satis header toplami, urun satir toplami ve odeme toplamini karsilastirir.

`GET /api/kasa-islemleri/yeni-kasa-analizleri/fis-mutabakat?startDate=2026-07-08&endDate=2026-07-08&warehouseNo=110&onlyProblematic=true&take=200`

Uretilen issue kodlari:

- `MissingUuid`: fis uuid alani bos
- `MissingWarehouseMapping`: sube kodu sayisal depo numarasina donusturulemedi
- `EmptyCashRegisterNo`: kasa no bos
- `MissingCashier`: kasiyer kodu bos
- `DuplicateSaleRow`: ayni satis anahtari birden fazla satirda geldi
- `MissingSaleItems`: satis toplami var fakat urun satiri yok
- `MissingPayment`: satis toplami var fakat odeme satiri yok
- `MissingPaymentAmount`: fis toplami odeme toplamindan buyuk
- `OverPaymentAmount`: odeme toplami fis toplamindan buyuk
- `SaleLineTotalMismatch`: fis toplami ile urun satirlari toplami uyusmuyor

Response:

```json
[
  {
    "businessDate": "2026-07-08T00:00:00",
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "cashRegisterNo": "1",
    "cashierCode": "1001",
    "cashierName": "MEHMET YILMAZ",
    "uuid": "3f0f6f4a-74d4-4f8f-84f1-2e8d2f2d1d11",
    "receiptNumber": "000123",
    "saleRowCount": 1,
    "productLineCount": 7,
    "paymentLineCount": 2,
    "saleTotal": 1250.75,
    "productLineTotal": 1250.75,
    "paymentTotal": 1240.75,
    "salePaymentDifference": 10,
    "saleLineDifference": 0,
    "status": "Problem",
    "issues": [
      "MissingPaymentAmount"
    ],
    "receivedAt": "2026-07-08T15:22:10"
  }
]
```

#### Yeni Kasa Anomaliler

Fis mutabakatinda bulunan sorunlari ve toplu duplicate/odeme tipi anomalilerini tek liste olarak doner.

`GET /api/kasa-islemleri/yeni-kasa-analizleri/anomaliler?startDate=2026-07-08&endDate=2026-07-08&warehouseNo=110&take=200`

Anomali tipleri:

- `DuplicateUuid`
- `DuplicateReceiptNumber`
- `UnknownPaymentMethod`
- Fis mutabakat issue kodlari (`MissingPayment`, `SaleLineTotalMismatch`, vb.)

Severity:

- `High`: tutarsal mutabakat veya kritik satis/odeme sorunu
- `Medium`: duplicate veya eksik teknik satir sorunu
- `Low`: bos teknik alanlar ve dusuk riskli veri kalitesi sorunlari

Response:

```json
[
  {
    "type": "MissingPaymentAmount",
    "severity": "High",
    "businessDate": "2026-07-08T00:00:00",
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "cashRegisterNo": "1",
    "cashierCode": "1001",
    "uuid": "3f0f6f4a-74d4-4f8f-84f1-2e8d2f2d1d11",
    "receiptNumber": "000123",
    "saleTotal": 1250.75,
    "paymentTotal": 1240.75,
    "difference": 10,
    "description": "Fis toplami odeme toplamindan buyuk."
  }
]
```

#### Yeni Kasa Odeme Tipleri

Secilen tarih araligindaki yeni kasa odeme tiplerini, `payment_methods` eslesmesini ve kategori bilgisini listeler.

`GET /api/kasa-islemleri/yeni-kasa-analizleri/odeme-tipleri?startDate=2026-07-08&endDate=2026-07-08&warehouseNo=110`

Not:

- `paymentMethodCode`, `payments.payment_method` alanidir.
- `isKnown = false` ise kod `payment_methods.id` veya `payment_methods.pavo_mediator` ile eslesmemistir.
- `category`: `Cash`, `CreditCard`, `GiftCard`, `Other`, `Unknown`

Response:

```json
[
  {
    "paymentMethodCode": "1",
    "paymentMethodName": "Nakit",
    "category": "Cash",
    "paymentMethodId": 1,
    "pavoMediator": 1,
    "pavoType": 1,
    "paymentLineCount": 820,
    "amount": 62100,
    "isKnown": true
  }
]
```

#### Yeni Kasa Saglik Ozeti

Secilen tarih araliginda sube/kasa bazinda fiÃƒâ€¦Ã…Â¸ sagligini tek bakista gosterir. Dashboard ust kartlari veya risk listesi icin kullanilir.

`GET /api/kasa-islemleri/yeni-kasa-analizleri/saglik-ozeti?startDate=2026-07-08&endDate=2026-07-08&warehouseNo=110`

Risk:

- `Healthy`: problemli fis yok
- `Warning`: teknik/veri kalitesi problemi var, kritik tutar problemi yok
- `Critical`: eksik/fazla odeme veya toplam farki var

Response:

```json
[
  {
    "businessDate": "2026-07-08T00:00:00",
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "cashRegisterNo": "1",
    "receiptCount": 242,
    "problemReceiptCount": 3,
    "criticalProblemCount": 1,
    "saleTotal": 185430.25,
    "paymentTotal": 185420.25,
    "differenceTotal": 10,
    "lastSaleAt": "2026-07-08T22:45:10",
    "riskLevel": "Critical",
    "topIssues": [
      "MissingPaymentAmount",
      "DuplicateSaleRow"
    ]
  }
]
```

#### Yeni Kasa Fis Detay

Fis mutabakat veya anomali listesinden secilen fisin detayini acar. UI icin tek response icinde fis ust bilgisi, mutabakat sonucu, ham satis satirlari, urun satirlari ve odeme satirlari doner.

UUID ile kullanim:

`GET /api/kasa-islemleri/yeni-kasa-analizleri/fis-detay?uuid=3f0f6f4a-74d4-4f8f-84f1-2e8d2f2d1d11`

UUID bos olan kayitlar icin fallback kullanim:

`GET /api/kasa-islemleri/yeni-kasa-analizleri/fis-detay?businessDate=2026-07-08&warehouseNo=110&cashRegisterNo=1&receiptNumber=000123`

Not:

- `payments[].isIncludedInTotals = false` ise satir ham odeme kaydinda vardir fakat duplicate temizleme nedeniyle mutabakat toplaminda dikkate alinmamistir.
- `reconciliationItems` ayni UUID altinda birden fazla kasa/kasiyer grubu olusursa hepsini gosterir.
- `productLines` Shopigo `sale_items` alanlariyla sinirlidir; mevcut tabloda urun adi/barkod kolonlari yoktur.

Response:

```json
{
  "uuid": "3f0f6f4a-74d4-4f8f-84f1-2e8d2f2d1d11",
  "receiptNumber": "000123",
  "businessDate": "2026-07-08T00:00:00",
  "warehouseNo": 110,
  "warehouseName": "KESTEL 1",
  "cashRegisterNo": "1",
  "cashierCode": "1001",
  "cashierName": "MEHMET YILMAZ",
  "saleTotal": 1250.75,
  "productLineTotal": 1250.75,
  "paymentTotal": 1240.75,
  "salePaymentDifference": 10,
  "saleLineDifference": 0,
  "status": "Problem",
  "issues": [
    "MissingPaymentAmount"
  ],
  "reconciliationItems": [],
  "saleRows": [
    {
      "id": 991122,
      "uuid": "3f0f6f4a-74d4-4f8f-84f1-2e8d2f2d1d11",
      "receiptNumber": "000123",
      "receivedAt": "2026-07-08T15:22:10",
      "warehouseNo": 110,
      "warehouseCode": "110",
      "cashRegisterNo": "1",
      "cashierCode": "1001",
      "saleTotal": 1250.75,
      "remainingAmount": 0,
      "marketId": "110",
      "status": "4"
    }
  ],
  "productLines": [
    {
      "id": 456,
      "saleUuid": "3f0f6f4a-74d4-4f8f-84f1-2e8d2f2d1d11",
      "quantity": 2,
      "totalPrice": 250
    }
  ],
  "payments": [
    {
      "id": 789,
      "saleUuid": "3f0f6f4a-74d4-4f8f-84f1-2e8d2f2d1d11",
      "paymentMethodCode": "1",
      "paymentMethodName": "Nakit",
      "category": "Cash",
      "paymentMethodId": 1,
      "pavoMediator": 1,
      "pavoType": 1,
      "amount": 1240.75,
      "isIncludedInTotals": true
    }
  ]
}
```

## Rapor Islemleri

### Tedarikci Performans Karnesi

Bu ekran satin alma tarafinda tedarikciyi tek kartta degerlendirmek icin eklendi. Kaynaklar ayri ekran olarak sunulmaz; UI tek `Tedarikci Performans Karnesi` ekraninda siparis, mal kabul, iade, zayiat/masraf etkisi ve fatura ozetlerini birlikte gosterir. API ayrica ekranin ust bandi icin kisa karar ozeti (`headline`), genel durum (`overallStatus`), onemli bulgular (`insights`) ve her tedarikci satiri icin okunabilir sinyaller (`signals`) doner.

Temel route:

- `api/rapor-islemleri/tedarikci-performans-karnesi`

Yetki kodlari:

- `rapor-islemleri.tedarikci-performans-karnesi.list`
- `rapor-islemleri.tedarikci-performans-karnesi.detail`
- `rapor-islemleri.tedarikci-performans-karnesi.all-warehouses`

Veri kaynaklari:

- `SIPARISLER`: verilen firma siparisleri, siparis miktari, teslim miktari, planlanan teslim tarihi
- `STOK_HAREKETLERI`: firma mal kabul, firma iade, zayiat/masraf hareketleri
- `CARI_HESAPLAR`: tedarikci kodu, unvan, VKN/TCKN
- Mal kabul fark mantigi: firma mal kabul satirlarinda `sth_miktar` ile `sth_FormulMiktar` farki varsa eksik/fazla kabul olarak okunur
- Fatura ozeti: bizim kestigimiz fatura adaylari Mikro `CARI_HESAP_HAREKETLERI`, tedarikcinin bize kestigi gelen faturalar `uyumsoft_inbox_invoices` cache uzerinden ozetlenir
- Gelen fatura toplami ile bizim kestigimiz fatura toplami dogrudan mutabakat farki olarak yorumlanmaz; bu alanlar yalnizca ayri fatura ozeti olarak verilir
- Satir bazli fiyat/fatura kontrolu ikinci fazdir; ilk fazda fatura metrikleri `summary-only` durumundadir
- Depo filtresi backend tarafinda JWT depo kapsami ile zorlanir; `rapor-islemleri.tedarikci-performans-karnesi.all-warehouses` olmayan kullanici kendi deposu disinda veri alamaz.
- `rapor-islemleri.tedarikci-performans-karnesi.all-warehouses` yetkisi olan kullanici `warehouseNo` bos birakirsa tum depolari, belirli depo gonderirse o depoyu raporlar.

Endpoint ozeti:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `GET /api/rapor-islemleri/tedarikci-performans-karnesi` | query | `SupplierPerformanceHttpRequest` | `SupplierPerformanceReportDto` | `list` |
| `GET /api/rapor-islemleri/tedarikci-performans-karnesi/{customerCode}` | path + query | `SupplierPerformanceDetailHttpRequest` | `SupplierPerformanceDetailDto` | `detail` |

Liste query:

```text
startDate     zorunlu, ISO tarih
endDate       zorunlu, ISO tarih
warehouseNo   opsiyonel; `all-warehouses` yoksa UI sormaz ve backend JWT deposunu uygular; `rapor-islemleri.tedarikci-performans-karnesi.all-warehouses` varsa bos birakilirsa tum depolar
customerCode  opsiyonel; tek tedarikciye daraltir
take          opsiyonel; default 100, max 500
```

`summary` filtreye giren tum tedarikci setini ozetler. `take` sadece `items` listesini sinirlar; toplam tedarikci sayisi ile ekrana donen satir sayisini ayirmak icin `supplierCount` ve `returnedSupplierCount` birlikte doner.

Detay query:

```text
startDate   zorunlu
endDate     zorunlu
warehouseNo opsiyonel; `all-warehouses` yoksa UI sormaz ve backend JWT deposunu uygular; `rapor-islemleri.tedarikci-performans-karnesi.all-warehouses` varsa secili depo icin gonderilebilir
eventTake   opsiyonel; default 100, max 500
```

Skor mantigi:

- Baslangic puani 100'dur.
- Gec teslim ve acik gec siparisler teslimat cezasini olusturur.
- Eksik/fazla mal kabul farki kalite cezasini olusturur.
- Firma iade miktari iade cezasini olusturur.
- Zayiat/masraf etkisi stok kartindaki varsayilan tedarikci uzerinden tedarikciye baglanir.
- Fatura ozeti skoru cezalandirmaz; gelen faturalar ve bizim kestigimiz faturalar ayri toplamlar olarak gosterilir.
- `riskLevel`: `Healthy`, `Warning`, `Critical`
- `grade`: `A`, `B`, `C`, `D`, `E`

Liste ornegi:

`GET /api/rapor-islemleri/tedarikci-performans-karnesi?startDate=2026-07-01&endDate=2026-07-03&warehouseNo=110&take=100`

Response:

```json
{
  "warehouseNo": 110,
  "startDate": "2026-07-01T00:00:00",
  "endDate": "2026-07-03T00:00:00",
  "generatedAtUtc": "2026-07-03T09:45:00Z",
  "summary": {
    "supplierCount": 2,
    "averageScore": 82.5,
    "criticalSupplierCount": 0,
    "warningSupplierCount": 1,
    "totalOrderedQuantity": 250,
    "totalReceivedQuantity": 230,
    "totalReturnedQuantity": 8,
    "totalMissingQuantity": 2,
    "totalExcessQuantity": 0,
    "totalOutageImpactQuantity": 4,
    "totalIssuedInvoiceAmount": 12500,
    "totalIncomingInvoiceAmount": 12620,
    "invoiceMetricsState": "summary-only",
    "returnedSupplierCount": 1,
    "overallStatus": "Warning",
    "headline": "2 tedarikci icinde 1 uyari seviyesinde tedarikci var; ortalama skor 82.5."
  },
  "insights": [
    {
      "code": "warning-suppliers",
      "severity": "Warning",
      "title": "Uyari seviyesinde tedarikci var",
      "description": "1 tedarikci uyari seviyesinde. Ilk kontrol: ORNEK TEDARIKCI A.S. (91.71 puan).",
      "customerCode": "120.01.03106"
    },
    {
      "code": "best-supplier",
      "severity": "Info",
      "title": "En guclu tedarikci",
      "description": "ORNEK TEDARIKCI A.S. 91.71 puan ile bu donemin en guclu karti.",
      "customerCode": "120.01.03106"
    }
  ],
  "items": [
    {
      "customerCode": "120.01.03106",
      "customerTitle": "ORNEK TEDARIKCI A.S.",
      "taxNoOrTckn": "1234567890",
      "score": 91.71,
      "grade": "A",
      "riskLevel": "Warning",
      "orders": {
        "documentCount": 4,
        "lineCount": 18,
        "orderedQuantity": 120,
        "deliveredQuantity": 112,
        "remainingQuantity": 8,
        "deliveryRate": 0.93,
        "lateDeliveredLineCount": 1,
        "openLateLineCount": 1,
        "averageLateDays": 2
      },
      "receiving": {
        "documentCount": 3,
        "lineCount": 15,
        "receivedQuantity": 112,
        "receivedAmount": 8400,
        "differenceLineCount": 1,
        "missingQuantity": 2,
        "excessQuantity": 0,
        "differenceRate": 0.02
      },
      "returns": {
        "documentCount": 1,
        "lineCount": 1,
        "returnedQuantity": 2,
        "returnedAmount": 150,
        "returnRate": 0.02
      },
      "outageImpact": {
        "documentCount": 1,
        "lineCount": 1,
        "quantity": 4,
        "amount": 0,
        "quantityRate": 0.04,
        "attribution": "stok-karti-varsayilan-tedarikci"
      },
      "invoices": {
        "issuedInvoiceCount": 1,
        "issuedInvoiceAmount": 150,
        "incomingInvoiceCount": 2,
        "incomingInvoiceAmount": 8550,
        "state": "summary-only",
        "note": "Giden fatura ve gelen fatura tutarlari ayri ozetlenir; bu iki toplam dogrudan mutabakat farki olarak yorumlanmaz. Satir bazli fiyat/fatura kontrolu ikinci fazdir."
      },
      "scoreBreakdown": {
        "deliveryPenalty": 6.5,
        "differencePenalty": 0.54,
        "returnPenalty": 0.54,
        "outagePenalty": 0.71,
        "invoicePenalty": 0,
        "totalPenalty": 8.29
      },
      "signals": [
        {
          "code": "open-late-orders",
          "severity": "Warning",
          "title": "Acik gec siparis",
          "description": "1 satir planlanan teslim tarihini gecmis ve kapanmamis."
        },
        {
          "code": "receiving-difference",
          "severity": "Warning",
          "title": "Mal kabul farki",
          "description": "2 eksik, 0 fazla kabul gorundu."
        }
      ]
    }
  ]
}
```

Detay ornegi:

`GET /api/rapor-islemleri/tedarikci-performans-karnesi/120.01.03106?startDate=2026-07-01&endDate=2026-07-03&warehouseNo=110&eventTake=100`

Response `card` alaninda liste satirindaki ayni karti, `events` alaninda bu karta kaynak olan olaylari doner.

Olay tipleri:

```text
Order
OpenLateOrder
ReceivingDifference
CompanyReturn
OutageImpact
ExpenseImpact
IssuedInvoice
IncomingInvoice
```

UI akisi:

1. Ekran acilisinda liste endpoint'i cagrilir.
2. Ustte `summary.headline`, `overallStatus`, ortalama skor, kritik/uyari sayisi, toplam siparis, kabul, iade, mal kabul farki ve fatura ozeti gosterilir.
3. `insights` alani ustte kisa bulgu listesi olarak kullanilir; kritik/uyari bulgulari once, bilgi bulgulari sonra gosterilir.
4. Gridde tedarikci, skor, risk, siparis/kabul oranlari, gec teslim, iade, mal kabul farki, zayiat etkisi ve fatura ozeti kolonlari yer alir.
5. Her satirda `signals` rozetleri/kisa uyari listesi olarak gosterilir; kullanici detaya girmeden skorun neden dustugunu gorebilir.
6. Satir secilince ayni ekranda detay paneli acilir ve detay endpoint'i cagrilir.
7. Detay panelinde `events` zaman cizelgesi olarak gosterilir; kaynak alanlari teknik kanit olarak saklanir.
8. Fatura alaninda `state = summary-only` ise UI gelen fatura ve bizim kestigimiz fatura toplamlarini ayri gostermeli; bu iki toplami "fark/uyumsuzluk" olarak vurgulamamalidir.

Yeni response alanlari:

```text
summary.overallStatus       NoData, Healthy, Warning, Critical
summary.headline            Ust bant icin kisa yorum
summary.returnedSupplierCount  take sonrasi donen kart sayisi
insights[].code             Bulgu tipi: critical-suppliers, warning-suppliers, late-orders, receiving-differences, company-returns, outage-impact, best-supplier, no-data
insights[].severity         Info, Healthy, Warning, Critical
insights[].customerCode     Bulgu belirli bir tedarikciye baglaniyorsa cari kodu
items[].signals[].code      Satir ici sinyal tipi
items[].signals[].severity  Info, Healthy, Warning, Critical
```

### Stok Raporlari

WinForms `Depo Stok Listeleme` envanterinden bu projeye read-only ve Mikro kaynaklariyla guvenle entegre edilebilen stok, hareket, satis, iade, karlilik ve sayim raporlari bu modul altinda toplandi. Bu modul yeni evrak olusturmaz, Mikro verisini degistirmez; UI tarafinda rapor/grid/ozet ekranlari icin kullanilir.

Temel route:

- `api/rapor-islemleri/stok-raporlari`

Yetki kodu:

- `rapor-islemleri.stok-raporlari.list`
- `rapor-islemleri.stok-raporlari.all-warehouses`

Veri kaynaklari:

- Mikro tablolar: `STOKLAR`, `STOK_DEPO_DETAYLARI`, `DEPOLAR`, `BARKOD_TANIMLARI`, `CARI_HESAPLAR`, `CARI_PERSONEL_TANIMLARI`, `STOK_HAREKETLERI`, `SAYIM_SONUCLARI`, `SATINALMA_SARTLARI`
- Mikro fonksiyonlari: `dbo.fn_DepodakiMiktar`, `dbo.fn_StokSatisFiyati`
- `SATINALMA_SARTLARI` yalniz tedarikci stok filtresinde yardimci eslestirme olarak okunur.
- Karlilik raporu maliyet icin `STOK_HAREKETLERI.sth_maliyet_ana` alanini kullanir; SAS fiyat/maliyet modu bu fazda yoktur.

Endpoint ozeti:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `GET /api/rapor-islemleri/stok-raporlari/son-stok` | query | `StockOnHandReportHttpRequest` | `StockOnHandReportDto` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/tedarikci-son-stok` | query | `SupplierStockOnHandHttpRequest` | `StockOnHandReportDto` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/kategori-son-stok` | query | `CategoryStockOnHandHttpRequest` | `StockOnHandReportDto` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/kategori-secenekleri` | query | `StockCategoryOptionHttpRequest` | `StockCategoryOptionDto[]` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/uretici-son-stok` | query | `ProducerStockOnHandHttpRequest` | `StockOnHandReportDto` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/envanter-degeri` | query | `StockOnHandReportHttpRequest` | `StockOnHandReportDto` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/urun-depo-durum` | query | `ProductWarehouseStockHttpRequest` | `ProductWarehouseStockDto[]` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/urun/{stockCodeOrBarcode}/depo-durum` | path + query | `ProductWarehouseStockByPathHttpRequest` | `ProductWarehouseStockDto[]` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/stok-kartlari` | query | `StockCardDetailHttpRequest` | `StockCardDetailDto[]` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/urun-ara` | query | `StockCardDetailHttpRequest` | `StockCardDetailDto[]` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/depoda-var-subede-yok` | query | `WarehouseMissingStockHttpRequest` | `WarehouseMissingStockDto[]` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/depo-sifir-stok` | query | `WarehouseZeroStockHttpRequest` | `WarehouseZeroStockDto[]` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/hareketler` | query | `StockMovementReportHttpRequest` | `StockMovementReportItemDto[]` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/giris-cikis-karsilastirma` | query | `FilteredDateRangeReportHttpRequest` | `MovementInOutComparisonDto[]` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/satislar/sube-detay` | query | `FilteredDateRangeReportHttpRequest` | `BranchSalesReportItemDto[]` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/satislar/yil-karsilastirma` | query | `FilteredDateRangeReportHttpRequest` | `YearSalesComparisonItemDto[]` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/iadeler/subeler` | query | `ReturnBranchReportHttpRequest` | `ReturnBranchReportItemDto[]` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/satislar/satmayan-urunler` | query | `NotSoldProductReportHttpRequest` | `NotSoldProductReportItemDto[]` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/karlilik` | query | `ProfitabilityReportHttpRequest` | `ProfitabilityReportItemDto[]` | `list` |
| `GET /api/rapor-islemleri/stok-raporlari/sayim-karsilastirma` | query | `CountingComparisonReportHttpRequest` | `CountingComparisonReportItemDto[]` | `list` |

Ortak query kurallari:

```text
warehouseNo   opsiyonel; `rapor-islemleri.stok-raporlari.all-warehouses` yoksa UI sormaz ve backend JWT deposunu uygular
reportDate    opsiyonel; stok anlik raporlarinda verilmezse bugun
startDate     tarih araligi raporlarinda zorunlu
endDate       tarih araligi raporlarinda zorunlu; backend gunu dahil kabul eder
take          opsiyonel; max 1000
```

Depo kapsami:

- `son-stok`, `tedarikci-son-stok`, `kategori-son-stok`, `uretici-son-stok`, `envanter-degeri`, `depoda-var-subede-yok`, `depo-sifir-stok` ve `sayim-karsilastirma` tek depo raporudur.
- `urun-depo-durum`, `stok-kartlari`, `hareketler`, `giris-cikis-karsilastirma`, satis, iade, satmayan urun ve karlilik raporlarinda `rapor-islemleri.stok-raporlari.all-warehouses` yetkisi olan kullanici `warehouseNo` bos birakirsa tum depolar okunabilir.
- `rapor-islemleri.stok-raporlari.all-warehouses` olmayan kullanicida backend token deposunu uygular; UI depo secimi gostermemelidir.
- Ornek: Asistan rolune sadece stok raporlari icin tum sube erisimi verilecekse role `rapor-islemleri.stok-raporlari.list` ve `rapor-islemleri.stok-raporlari.all-warehouses` yetkileri atanir; `Admin` rolu verilmesi gerekmez.

Filtre alanlari:

```text
filterType  stock, category, producer, supplier, product-manager, model
scope       karlilik icin producer, supplier, product-manager, category, stock
filterValue filterType/scope ile eslesen kod veya arama degeri
```

Notlar:

- `filterType` icin Turkce aliaslar da kabul edilir: `stok`, `kategori`, `uretici`, `tedarikci`, `satin-almaci`, `satinalmaci`, `model`.
- Turkce karakterli aliaslar da kabul edilir: `urun`, `ÃƒÆ’Ã‚Â¼rÃƒÆ’Ã‚Â¼n`, `ÃƒÆ’Ã‚Â¼retici`, `tedarikÃƒÆ’Ã‚Â§i`, `satÃƒâ€Ã‚Â±n-almacÃƒâ€Ã‚Â±`.
- `filterType` ve `filterValue` birlikte kullanÃƒâ€Ã‚Â±lmalÃƒâ€Ã‚Â±dÃƒâ€Ã‚Â±r; sadece biri gÃƒÆ’Ã‚Â¶nderilirse backend 400 dÃƒÆ’Ã‚Â¶ner.
- `scope` bos verilirse karlilik raporu `producer` kirilimi ile doner.
- Sayisal toplamlar backend tarafinda 2 ondaliga yuvarlanir.
- Barkod alanlari master/birim-1 barkod onceligiyle secilir.
- `OnlyWithStock=true` varsayilan davranistir; sifir stoklarin da gelmesi istenirse `false` gonderilir.
- Kategori secimi icin UI `kategori-secenekleri` endpoint'ini kullanabilir; response `categoryCode`, `categoryName`, `productCount` alanlarini doner.
- `satislar/satmayan-urunler` tum depo yetkisiyle tum depolar icin calistirilirse `warehouseName = "Tum depolar"` ve `currentStock` aktif depolarin toplam sistem miktari olarak doner.
- `karlilik` response'unda `groupName`, `supplier` ve `product-manager` icin ad/unvan; `stock` icin stok adi; `producer` ve `category` icin kod fallback'i olarak doner.

UI akisi:

1. Menu `Rapor Islemleri / Stok Raporlari` olarak acilir.
2. Ekranda tab veya sol filtreyle `Son Stok`, `Urun Depo Durum`, `Stok Kartlari`, `Hareketler`, `Satis`, `Iade`, `Karlilik`, `Sayim` gorunumleri ayrilabilir.
3. Kategori filtrelerinde dropdown `kategori-secenekleri` ile dolar; secilen `categoryCode`, `kategori-son-stok` veya genel `son-stok` filtresine yazilir.
4. `son-stok` response icindeki `totalQuantity`, `totalSalesValue`, `returnedCount` ust ozet kartlarinda; `items` gridde gosterilir.
5. `envanter-degeri` ayni response modelini kullanan deger odakli kisayoldur; UI ayni endpoint ailesini kullanip toplam satis degerini one cikarabilir.
6. `urun-depo-durum` tek urunun subeler/depolar bazinda miktar ve satis degerini gosterir; arama icin `stockCodeOrBarcode` zorunludur. Barkod okutma veya urun kartindan gecis icin `urun/{stockCodeOrBarcode}/depo-durum` path kisayolu da kullanilabilir.
7. `urun-ara`, `stok-kartlari` ile ayni response'u donen kolay okunur arama alias'idir.
8. `depoda-var-subede-yok` kaynak depoda mevcut, hedef subede olmayan urunleri listeler; kaynak depo UI tarafinda zorunlu secilmelidir.
9. `depo-sifir-stok` secili depoda sistem miktari sifir olan urunleri listeler.
10. `giris-cikis-karsilastirma`, `satislar/sube-detay`, `satislar/yil-karsilastirma`, `iadeler/subeler`, `satislar/satmayan-urunler` tarih araligi ile calisir.
11. `karlilik` raporunda UI `scope` icin segmented control veya select kullanmali; sonuc `groupCode/groupName` bazli ozetlenir.
12. `sayim-karsilastirma` sayim gunu, opsiyonel belge no ve paket kodu ile sistem miktari/sayim miktari farkini gosterir.

Ornekler:

`GET /api/rapor-islemleri/stok-raporlari/son-stok?warehouseNo=110&reportDate=2026-07-21&search=ELMA&take=100`

`GET /api/rapor-islemleri/stok-raporlari/kategori-secenekleri?search=MEYVE&take=50`

`GET /api/rapor-islemleri/stok-raporlari/urun/8690000000000/depo-durum?onlyWithStock=true`

`GET /api/rapor-islemleri/stok-raporlari/karlilik?startDate=2026-07-01&endDate=2026-07-21&scope=producer&take=250`

`GET /api/rapor-islemleri/stok-raporlari/sayim-karsilastirma?warehouseNo=110&countDate=2026-07-21&take=500`

### Promosyon Raporlari

Promosyon/bulten tarafinda rapor ihtiyaci bu modul altinda toplandi. Modul bulten tanimlarini listeler, gerceklesen POS promosyon kullanimlarini okur ve satis/marj etkisini gosterir.

Bu modul salt-okunurdur. Bulten/promosyon tanim CRUD islemleri rapor degildir; ayri admin/yonetim modulu olarak ele alinmalidir.

Temel route:

- `api/rapor-islemleri/promosyon-raporlari`

Yetki kodu:

- `rapor-islemleri.promosyon-raporlari.list`
- `rapor-islemleri.promosyon-raporlari.all-warehouses`

Veri kaynaklari:

- Mayday `PROMOSYON_TANIMLARI`: bulten/promosyon tanim listesi
- Mayday `PROMOSYON_SUBELER`: promosyonun hangi subelerde gecerli oldugu
- Furpa `PosFaturaPromosyons`: POS fislerinde gerceklesen promosyon kullanimi
- Furpa `PosFaturaSatirs`: promosyon satirinin miktar, net satis, KDV ve urun bilgisi
- Mikro `STOKLAR`: standart maliyet ile tahmini marj hesabi
- Mikro `DEPOLAR`: sube adlari

Endpoint ozeti:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `GET /api/rapor-islemleri/promosyon-raporlari/bultenler` | query | `PromotionBulletinListHttpRequest` | `PromotionBulletinListItemDto[]` | `list` |
| `GET /api/rapor-islemleri/promosyon-raporlari/bulten-secenekleri` | query | `PromotionBulletinOptionHttpRequest` | `PromotionBulletinOptionDto[]` | `list` |
| `GET /api/rapor-islemleri/promosyon-raporlari/bultenler/secenekler` | query | `PromotionBulletinOptionHttpRequest` | `PromotionBulletinOptionDto[]` | `list` |
| `GET /api/rapor-islemleri/promosyon-raporlari/performans` | query | `PromotionPerformanceHttpRequest` | `PromotionPerformanceReportDto` | `list` |
| `GET /api/rapor-islemleri/promosyon-raporlari/satis-marj-etkisi` | query | `PromotionPerformanceHttpRequest` | `PromotionPerformanceReportDto` | `list` |
| `GET /api/rapor-islemleri/promosyon-raporlari/performans/sube` | query | `PromotionPerformanceHttpRequest` | `PromotionBranchPerformanceItemDto[]` | `list` |

Bulten listesi query:

```text
warehouseNo  opsiyonel; `rapor-islemleri.promosyon-raporlari.all-warehouses` yoksa UI sormaz ve backend JWT deposunu uygular
activeOn     opsiyonel; verilmezse bugun
onlyActive   opsiyonel; default true, activeOn tarihinde aktif olan bultenleri getirir
search       opsiyonel; kod, ad veya aciklama arar
take         opsiyonel; default 100, max 1000
```

Performans query:

```text
startDate      opsiyonel; verilmezse endDate - 30 gun
endDate        opsiyonel; verilmezse bugun, backend gunu dahil kabul eder
warehouseNo    opsiyonel; `rapor-islemleri.promosyon-raporlari.all-warehouses` varsa bos birakilirsa tum subeler
promotionCode  opsiyonel; tek bulten/promosyon kodu
search         opsiyonel; kod, ad veya aciklama arar
take           opsiyonel; default 250, max 1000
```

Response notlari:

- `PromotionPerformanceReportDto` ust ozet ve promosyon bazli `items` listesini birlikte doner.
- `performans/sube` ayni hesaplari promosyon + sube kiriliminda verir.
- `netSalesAmount` POS satir net tutaridir.
- `grossSalesAmount` net tutar + KDV toplamidir.
- `discountAmount` POS promosyon satirindaki indirim/etki tutaridir.
- `estimatedCostAmount` urun miktari x Mikro `STOKLAR.sto_standartmaliyet` olarak hesaplanir.
- `marginAmount` net satis - tahmini maliyet; `marginPercent` bu tutarin net satis icindeki oranidir.
- Maliyet kartta yoksa tahmini maliyet 0 okunur; UI bu durumda marji "tahmini" olarak degerlendirmelidir.

UI akisi:

1. Menu `Rapor Islemleri / Promosyon Raporlari` olarak acilir.
2. Ilk sekmede `bultenler` endpoint'i ile aktif/pasif bulten listesi gosterilir.
3. Performans filtrelerindeki bulten/promosyon dropdown'u `bulten-secenekleri` veya canonical alias olan `bultenler/secenekler` endpoint'i ile doldurulur.
4. Bulten satiri veya dropdown secimi yapilirse `promotionCode` ile `performans` endpoint'i cagrilir.
5. Ustte kullanim adedi, fis sayisi, net/brut satis, indirim tutari ve marj kartlari gosterilir.
6. Detay gridinde promosyon bazli satirlar; sube sekmesinde `performans/sube` sonucu gosterilir.
7. Bulten tanimi olusturma/duzenleme/silme bu ekranda yapilmaz; ayri admin modulu gerekir.

Ornekler:

`GET /api/rapor-islemleri/promosyon-raporlari/bultenler?warehouseNo=110&onlyActive=true&take=100`

`GET /api/rapor-islemleri/promosyon-raporlari/bulten-secenekleri?search=12&take=50`

`GET /api/rapor-islemleri/promosyon-raporlari/bultenler/secenekler?search=12&take=50`

`GET /api/rapor-islemleri/promosyon-raporlari/performans?startDate=2026-07-01&endDate=2026-07-21&warehouseNo=110&take=250`

`GET /api/rapor-islemleri/promosyon-raporlari/performans?promotionCode=1234`

`GET /api/rapor-islemleri/promosyon-raporlari/performans/sube?startDate=2026-07-01&endDate=2026-07-21&promotionCode=1234`

### Satis Analizleri

Eski `Furpa.SalesMvcCoreUI` dashboard tarafindaki ciro disi raporlar bu API modulunde toplandi. Tum endpointler `GET` calisir, query tarafinda ortak `WarehouseOrderDateRangeHttpRequest` modelini kullanir.

Temel route:

- `api/rapor-islemleri/satis-analizleri`

Yetki kodu:

- `rapor-islemleri.satis-analizleri.list`
- `rapor-islemleri.satis-analizleri.all-warehouses`

Request query alanlari:

```text
startDate    zorunlu, ISO tarih
endDate      zorunlu, ISO tarih
warehouseNo  opsiyonel
```

Not:

- `rapor-islemleri.satis-analizleri.all-warehouses` yoksa UI `warehouseNo` sormaz; backend JWT icindeki kullanici deposunu uygular.
- `rapor-islemleri.satis-analizleri.all-warehouses` varsa `warehouseNo` verilirse tek sube filtrelenir, verilmezse tum subeler icin rapor doner.
- Tarih filtresi gun bazinda calisir; backend `endDate` degerini dahil kabul edip sorguda ertesi gunun basina kadar okur.
- Tum tutar alanlari backend tarafinda 2 ondaliga yuvarlanir.
- Indirim karti raporu kullanim adedini Mikro `TurnoverDiscountCardDetails` kaynagindan, kullanim tutarini Furpa `PosFaturas` kaynagindan eslestirir.
- MarketYo satis raporlari `STOK_HAREKETLERI` icinde `sth_evrakno_seri = 'MYO'` filtresiyle calisir.

Endpoint'ler:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `GET /api/rapor-islemleri/satis-analizleri/banka-hareketleri` | query | `WarehouseOrderDateRangeHttpRequest` | `BankMovementAnalysisItemDto[]` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/banka-hareketleri/sube` | query | `WarehouseOrderDateRangeHttpRequest` | `BranchBankMovementSummaryItemDto[]` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/banka-odeme-ozetleri/banka` | query | `WarehouseOrderDateRangeHttpRequest` | `BankPaymentSummaryReportDto` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/banka-odeme-ozetleri/merchant` | query | `WarehouseOrderDateRangeHttpRequest` | `MerchantPaymentSummaryReportDto` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/banka-odeme-ozetleri/valor` | query | `WarehouseOrderDateRangeHttpRequest` | `ValorPaymentSummaryReportDto` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/yemek-cekleri` | query | `WarehouseOrderDateRangeHttpRequest` | `FoodCheckReportDto` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/yemek-cekleri/toplamlar` | query | `WarehouseOrderDateRangeHttpRequest` | `FoodCheckTotalsDto` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/yemek-cekleri/metropol-toplam` | query | `WarehouseOrderDateRangeHttpRequest` | `SalesAnalysisAmountDto` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/yemek-cekleri/multinet-toplam` | query | `WarehouseOrderDateRangeHttpRequest` | `SalesAnalysisAmountDto` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/yemek-cekleri/setcard-toplam` | query | `WarehouseOrderDateRangeHttpRequest` | `SalesAnalysisAmountDto` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/yemek-cekleri/sodexo-kupon-toplam` | query | `WarehouseOrderDateRangeHttpRequest` | `SalesAnalysisAmountDto` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/yemek-cekleri/sodexo-pos-toplam` | query | `WarehouseOrderDateRangeHttpRequest` | `SalesAnalysisAmountDto` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/yemek-cekleri/ticket-kupon-toplam` | query | `WarehouseOrderDateRangeHttpRequest` | `SalesAnalysisAmountDto` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/yemek-cekleri/ticket-pos-toplam` | query | `WarehouseOrderDateRangeHttpRequest` | `SalesAnalysisAmountDto` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/yemek-cekleri/genel-toplam` | query | `WarehouseOrderDateRangeHttpRequest` | `SalesAnalysisAmountDto` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/marketyo-satislari` | query | `WarehouseOrderDateRangeHttpRequest` | `MyoSalesReportDto` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/marketyo-satislari/sube` | query | `WarehouseOrderDateRangeHttpRequest` | `MyoSalesByBranchItemDto[]` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/z-rapor-banka-analizi` | query | `WarehouseOrderDateRangeHttpRequest` | `ZReportBankAnalysisItemDto[]` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/indirim-kartlari` | query | `WarehouseOrderDateRangeHttpRequest` | `DiscountCardDetailItemDto[]` | `list` |
| `GET /api/rapor-islemleri/satis-analizleri/eksik-cirolar` | query | `WarehouseOrderDateRangeHttpRequest` | `MissingTurnoverBranchItemDto[]` | `list` |

#### Banka Hareketleri

`GET /api/rapor-islemleri/satis-analizleri/banka-hareketleri?startDate=2026-06-01&endDate=2026-06-10&warehouseNo=110`

Summary kayitlarindaki banka odemelerini Z no, sube, kasa, banka ve terminal bazinda listeler. `PaymentTypeID` 1..10 arasi banka odemeleri kabul edilir.

Response:

```json
[
  {
    "branchNo": 110,
    "branchName": "KESTEL 1",
    "zNo": 128,
    "date": "2026-06-10T00:00:00",
    "cashRegisterNo": "UB11001",
    "bank": "AKBANK",
    "bankAmount": 15420.75,
    "bankingNumber": 42,
    "terminalId": "TERM001"
  }
]
```

`GET /api/rapor-islemleri/satis-analizleri/banka-hareketleri/sube` ayni kaynaklari sube + banka bazinda toplar.

#### Banka Odeme Ozetleri

Uc ozet endpoint vardir:

- `/banka-odeme-ozetleri/banka`: banka adina gore toplam tutar ve slip sayisi
- `/banka-odeme-ozetleri/merchant`: banka + uye isyeri no bazinda toplam
- `/banka-odeme-ozetleri/valor`: banka + valor gunu bazinda yatacak tutar

Response ornegi:

```json
{
  "items": [
    {
      "bank": "AKBANK",
      "amount": 184250.35,
      "slipNumber": 421
    }
  ],
  "totalAmount": 184250.35,
  "totalSlipNumber": 421
}
```

Merchant response satirinda ek olarak `merchantNo`, valor response satirinda ek olarak `valorDay` alani bulunur.

#### Yemek Cekleri

`GET /api/rapor-islemleri/satis-analizleri/yemek-cekleri?startDate=2026-06-01&endDate=2026-06-10`

`Summaries` kaynaginda `PaymentTypeID` 50..60 arasi yemek ceki tutarlarini sube bazinda toplar.

Response:

```json
{
  "items": [
    {
      "branchNo": 110,
      "branchName": "KESTEL 1",
      "metropol": 1200,
      "multinet": 875.5,
      "setcard": 450,
      "sodexoKupon": 0,
      "sodexoPos": 320,
      "ticketKupon": 0,
      "ticketPos": 640,
      "total": 3485.5
    }
  ],
  "totals": {
    "metropol": 1200,
    "multinet": 875.5,
    "setcard": 450,
    "sodexoKupon": 0,
    "sodexoPos": 320,
    "ticketKupon": 0,
    "ticketPos": 640,
    "total": 3485.5
  }
}
```

Tekil toplam endpointleri `SalesAnalysisAmountDto` doner:

```json
{
  "code": "Metropol",
  "name": "Metropol",
  "amount": 1200
}
```

#### MarketYo Satislari

`GET /api/rapor-islemleri/satis-analizleri/marketyo-satislari?startDate=2026-06-01&endDate=2026-06-10`

`MYO` seri evraklarini stok hareketleri, cari hareketleri ve evrak aciklamalariyla birlestirir.

Response:

```json
{
  "items": [
    {
      "documentDate": "2026-06-10T00:00:00",
      "branchNo": 110,
      "branchName": "KESTEL 1",
      "documentSerie": "MYO",
      "documentOrderNo": 1254,
      "invoiceGuid": "25d3d19e-0e93-4e32-8a86-3e2b4f858612",
      "customerCode": "120.01.001",
      "documentNo": "MYO000001254",
      "description1": "",
      "description2": "",
      "paymentDescription": "Kapida Kredi Karti ile Odeme",
      "subTotal": 910,
      "discountTotal": 10,
      "netAmount": 900,
      "totalTax": 90,
      "amount": 990
    }
  ],
  "netAmountTotal": 900,
  "totalTaxTotal": 90,
  "amountTotal": 990,
  "doorCashTotal": 0,
  "doorCreditCardTotal": 990
}
```

`GET /api/rapor-islemleri/satis-analizleri/marketyo-satislari/sube` ayni kaynagi sube + tarih bazinda `amount` toplamiyla doner.

#### Z Rapor Banka Analizi

`GET /api/rapor-islemleri/satis-analizleri/z-rapor-banka-analizi?startDate=2026-06-01&endDate=2026-06-10`

`ZReportTotals`, `ZReportBankDetails`, `CashRegisterBranches`, `CashRegisterDetails` ve `DEPOLAR` kaynaklarini eslestirir. `cashRegisterNo` degeri `UB` ile baslayan Z rapor kasalari listelenir.

#### Indirim Kartlari

`GET /api/rapor-islemleri/satis-analizleri/indirim-kartlari?startDate=2026-06-01&endDate=2026-06-10`

Kart numarasi + sube bazinda kullanim adedi ve POS fatura toplam tutarini doner.

#### Eksik Cirolar

`GET /api/rapor-islemleri/satis-analizleri/eksik-cirolar?startDate=2026-06-01&endDate=2026-06-10`

`DEPOLAR` icinde aktif sube olup secilen tarih araliginda `TurnoverTotals` kaydi olmayan subeleri listeler.

### Kasa Ciro Aktarimi

`TransferConsole` akisindaki eski kasa ciro okuma mantigini API icine tasir. `HRddMMyy.*` dosyalarini okur, sube/kasa bazli ciro ozetlerini hesaplar ve eski ciro tablolarina add/update yapar.

Bu modul `Kasa Hareket Aktarimi` ile ayni dosya kokunu kullanabilir ama hedefi farklidir:

- `Kasa Hareket Aktarimi`: HR/IP hareket dosyalarini staging ve Mikro stok hareketi surecine alir.
- `Kasa Ciro Aktarimi`: HR dosyalarindan `TurnoverTotals`, `TurnoverDetails`, `TurnoverDiscountCardDetails` tablolarini doldurur.

Temel route:

- `api/kasa-islemleri/kasa-ciro-aktarimi`

Yetki kodlari:

- `kasa-islemleri.kasa-ciro-aktarimi.list`
- `kasa-islemleri.kasa-ciro-aktarimi.detail`
- `kasa-islemleri.kasa-ciro-aktarimi.create`

Mevcut backend durumu:

- route ailesi aktiftir
- sube lookup ve metin dosyasindan ciro import endpointleri calisir
- dosya kok yolu `KasaCiroAktarimi:MovementFilePath` konfigurasyonundan okunur; body'de `movementRootPath` verilirse o deger kullanilir
- geriye uyumluluk icin `MovementFileSetting:MovementFilePath`, `KasaHareketAktarimi:FileRootPath` ve default `\\10.0.0.55\kasa\` fallback olarak desteklenir
- `branches` verilmezse `101..300` araligindaki sube klasorleri taranir
- dosya deseni `{root}\{subeNo}\HRddMMyy.*` seklindedir
- kasa no dosya uzantisindan okunur; ornek `HR090626.001` -> `cashRegisterNo = 1`
- `FIS/FAT/IRS/GPS/BAS/TOP/TAR/SON/KRD/SDX/NAK` satir kurallari eski console davranisina gore yorumlanir
- genel toplam kosulu eski akistaki gibi `Cash + Credit + GiftCard + FuturesSales >= 0.001` degeridir; yalniz gider pusulasi olan sube/gun kaydi yazilmaz
- mevcut kayit varsa total/detail/card satirlari update edilir; eski importta olup yeni dosyada gelmeyen detail/card satirlari silinmez
- `dryRun=true` dosyalari parse eder ve insert/update adetlerini hesaplar; DB'ye yazmaz

Endpoint'ler:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `GET /api/kasa-islemleri/kasa-ciro-aktarimi/subeler` | - | - | `KasaCiroBranchDto[]` | `list` |
| `POST /api/kasa-islemleri/kasa-ciro-aktarimi/metin/aktar` | body | `KasaCiroImportHttpRequest` | `KasaCiroImportResultDto` | `create` |

Import request:

```json
{
  "startDate": "2026-06-01",
  "endDate": "2026-06-09",
  "branches": [101, 102, 110],
  "movementRootPath": "\\\\10.0.0.55\\kasa\\",
  "dryRun": false
}
```

Not:

- `startDate` ve `endDate` zorunludur.
- `branches` opsiyoneldir; bos/null gonderilirse `101..300` araligi taranir.
- `movementRootPath` normal UI'da bos birakilabilir; sadece admin/teknik override ihtiyacinda gosterilmelidir.
- Bu modul kasa filtresi almaz; secilen subelerin ilgili tarihteki tum `HRddMMyy.*` kasa dosyalarini okur.

Import response:

```json
{
  "runId": "kasa-ciro-20260601-153000",
  "status": "Completed",
  "startDate": "2026-06-01T00:00:00",
  "endDate": "2026-06-09T00:00:00",
  "processedDays": 9,
  "processedBranches": 12,
  "processedFiles": 84,
  "skippedEmptyBranches": 3,
  "insertedTotals": 10,
  "updatedTotals": 2,
  "insertedDetails": 70,
  "updatedDetails": 14,
  "insertedDiscountCards": 120,
  "updatedDiscountCards": 35,
  "warnings": [
    {
      "date": "2026-06-09T00:00:00",
      "branchNo": 110,
      "cashRegisterNo": null,
      "file": "\\\\10.0.0.55\\kasa\\110\\HR090626.*",
      "lineNo": null,
      "message": "Ciro hareket dosyasi bulunamadi."
    }
  ],
  "errors": []
}
```

UI beklentisi:

- ekran acilisinda `GET /subeler` ile sube filtresi doldurulabilir
- aktarim dialogunda tarih araligi zorunlu, sube listesi opsiyonel olmalidir
- ilk calistirma veya supheli tekrar importlarda `dryRun=true` onizleme olarak sunulmalidir
- sonuc ekraninda adetler ust kartlarda, `warnings/errors` satirlari gridde gosterilmelidir
- basarili importtan sonra eski ciro verisi `Kasa Cirolari` ekraninda `eski` veya `toplam` kaynaklariyla gorunur

### Kasa Hareket Aktarimi

Eski kasa hareket dosyalarini HR/IP formatindan staging tablolara alir, staging hareketlerini Mikro stok hareketlerine aktarir veya aktarimi geri siler.

Temel route:

- `api/kasa-islemleri/kasa-hareket-aktarimi`

Yetki kodlari:

- `kasa-islemleri.kasa-hareket-aktarimi.list`
- `kasa-islemleri.kasa-hareket-aktarimi.detail`
- `kasa-islemleri.kasa-hareket-aktarimi.create`
- `kasa-islemleri.kasa-hareket-aktarimi.update`

Mevcut backend durumu:

- route ailesi aktiftir
- sube/kasa lookup, HR hareket import, IP iptal import, zamanli import, staging silme, Mikro'ya aktar/sil/aralik aktar ve rapor endpointleri calisir
- import dosya kaynagi `KasaHareketAktarimi:FileRootPath` konfigurasyonundan okunur; default deger `\\10.0.0.55\kasa\`
- zamanli importta `Date` verilmezse `KasaHareketAktarimi:ScheduledAddDay` kullanilir; default `-1`, yani dunun dosyalarini okur
- dosya yolu `{root}\{subeNo}\HRddMMyy.*` ve `{root}\{subeNo}\IPddMMyy.*` desenindedir
- `cashRegisters` filtresi verilirse dosya adi `{prefix}{ddMMyy}.{kasaNo:000}` olarak aranir
- HR/IP satir formatinda virgullu, noktali virgul, tab ve bosluk ayraclari desteklenir; guncel kasa dosyalari genellikle `1,00006,01,FIS,...` seklinde virgullu gelir
- HR para alanlari ayiracsiz numeric gelirse kurus kabul edilir ve 100'e bolunur; ornek `003342011` -> `33420.11`. Alan `33420.11`, `33420,11` veya `730.00` gibi acik ondalik ayracla gelirse deger aynen decimal okunur.
- `skipExisting=true` iken duplicate kontrolu `Sube + KasaNo + FisNo + BelgeTuru + Tarih` alanlariyla yapilir
- `dryRun=true` import dosyalarini parse eder, barkod lookup ve hata/uyari listesi uretir, staging'e yazmaz
- barkod lookup Mikro barkod tanimlarindan urun kodu bulmaya calisir; bulunamayan barkodlar response `warnings` icinde doner
- HR import normal kasa hareketlerini, IP import iptal belgelerini staging'e alir
- HR import `FIS`, `FAT`, `IRS` ve `GPS` belge basliklarini fis olarak okur; `FAT` satirlari `documentKind = 2` / `documentKindName = Fatura` olarak staging'e kaydedilir. Bu nedenle ayni fis numarasi `FIS` ve `FAT` olarak gelirse duplicate sayilmaz, belge turu ayrimi korunur.
- Mikro aktar/sil endpointleri stored procedure calistirir; response sadece procedure adi, mesaj ve filtre bilgisini doner

Endpoint'ler:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `GET /api/kasa-islemleri/kasa-hareket-aktarimi/subeler` | - | - | `KasaHareketBranchDto[]` | `list` |
| `GET /api/kasa-islemleri/kasa-hareket-aktarimi/subeler/{branchNo}/kasalar` | path | `branchNo: int` | `KasaHareketCashRegisterDto[]` | `list` |
| `POST /api/kasa-islemleri/kasa-hareket-aktarimi/hareketler/aktar` | body | `KasaHareketImportHttpRequest` | `KasaHareketImportResultDto` | `create` |
| `POST /api/kasa-islemleri/kasa-hareket-aktarimi/iptal-belgeleri/aktar` | body | `KasaHareketImportHttpRequest` | `KasaHareketImportResultDto` | `create` |
| `POST /api/kasa-islemleri/kasa-hareket-aktarimi/zamanli-aktarim/calistir` | body | `KasaHareketScheduledImportHttpRequest` | `KasaHareketImportResultDto` | `create` |
| `DELETE /api/kasa-islemleri/kasa-hareket-aktarimi/staging` | body | `KasaHareketDeleteStagingHttpRequest` | `KasaHareketProcedureResultDto` | `update` |
| `POST /api/kasa-islemleri/kasa-hareket-aktarimi/mikro/aktar` | body | `KasaHareketMikroTransferHttpRequest` | `KasaHareketProcedureResultDto` | `create` |
| `DELETE /api/kasa-islemleri/kasa-hareket-aktarimi/mikro` | body | `KasaHareketMikroTransferHttpRequest` | `KasaHareketProcedureResultDto` | `update` |
| `POST /api/kasa-islemleri/kasa-hareket-aktarimi/mikro/aralik-aktar` | body | `KasaHareketMikroTransferRangeHttpRequest` | `KasaHareketProcedureResultDto` | `create` |
| `GET /api/kasa-islemleri/kasa-hareket-aktarimi/rapor` | query | `KasaHareketReportHttpRequest` | `KasaHareketReportRowDto[]` | `detail` |
| `GET /api/kasa-islemleri/kasa-hareket-aktarimi/rapor/ozet` | query | `KasaHareketReportHttpRequest` | `KasaHareketReportSummaryDto` | `detail` |
| `GET /api/kasa-islemleri/kasa-hareket-aktarimi/rapor/excel` | query | `KasaHareketReportHttpRequest` | `text/csv` dosya | `detail` |
| `GET /api/kasa-islemleri/kasa-hareket-aktarimi/icmal-karsilastirma` | query | `KasaHareketCashSummaryComparisonHttpRequest` | `KasaHareketCashSummaryComparisonDto` | `detail` |
| `GET /api/kasa-islemleri/kasa-hareket-aktarimi/icmal-karsilastirma/excel` | query | `KasaHareketCashSummaryComparisonHttpRequest` | `text/csv` dosya | `detail` |
| `GET /api/kasa-islemleri/kasa-hareket-aktarimi/icmal-karsilastirma/detay` | query | `KasaHareketDetailHttpRequest` | `KasaHareketDetailDto` | `detail` |

Import request:

```json
{
  "startDate": "2026-06-08",
  "endDate": "2026-06-09",
  "branches": [110, 115],
  "cashRegisters": [1, 2],
  "fileRootPath": "\\\\10.0.0.55\\kasa\\",
  "skipExisting": true,
  "dryRun": false
}
```

Import response:

```json
{
  "runId": "normal-20260608-153000",
  "importType": "normal",
  "status": "Completed",
  "processedFiles": 4,
  "processedInvoices": 128,
  "skippedExistingInvoices": 3,
  "insertedLines": 642,
  "insertedPayments": 146,
  "insertedPromotions": 12,
  "warnings": [
    {
      "branchNo": 110,
      "cashRegisterNo": 1,
      "file": "HR080626.001",
      "receiptNo": "3456",
      "lineNo": 24,
      "message": "Sistemde olmayan barkod: 8690000000000"
    }
  ],
  "errors": []
}
```

Zamanli import:

`POST /api/kasa-islemleri/kasa-hareket-aktarimi/zamanli-aktarim/calistir`

```json
{
  "date": "2026-06-09",
  "addDay": null,
  "fileRootPath": null,
  "skipExisting": true,
  "dryRun": true
}
```

Not:

- zamanli import ayni tarih icin HR ve IP importlarini birlikte calistirir
- `date` bos gonderilirse `DateTime.Today + addDay/configured ScheduledAddDay` hesaplanir
- response `importType = scheduled` olarak doner ve HR/IP sonuc adetlerini toplar

Staging silme:

`DELETE /api/kasa-islemleri/kasa-hareket-aktarimi/staging`

```json
{
  "date": "2026-06-09",
  "branchNo": 110,
  "cashRegisterNo": 1
}
```

Bu endpoint `HareketSil` procedure'unu calistirir. `branchNo` ve `cashRegisterNo` opsiyoneldir; UI'da staging temizleme aksiyonu olarak sunulmalidir, Mikro evragi silme aksiyonu gibi adlandirilmamalidir.

Mikro'ya aktar:

`POST /api/kasa-islemleri/kasa-hareket-aktarimi/mikro/aktar`

```json
{
  "date": "2026-06-09",
  "branchNo": 110
}
```

Bu endpoint `StokHareketYaz` procedure'unu calistirir. `branchNo` opsiyoneldir.

Mikro'dan sil:

`DELETE /api/kasa-islemleri/kasa-hareket-aktarimi/mikro`

```json
{
  "date": "2026-06-09",
  "branchNo": 110
}
```

Bu endpoint `StokHareketSil` procedure'unu calistirir.

Tarih araligi Mikro aktarimi:

`POST /api/kasa-islemleri/kasa-hareket-aktarimi/mikro/aralik-aktar`

```json
{
  "startDate": "2026-06-01",
  "endDate": "2026-06-09"
}
```

Bu endpoint `StokHareketYaz2` procedure'unu calistirir ve sube filtresi almaz.

Procedure response:

```json
{
  "procedure": "StokHareketYaz",
  "message": "StokHareketYaz calisti.",
  "date": "2026-06-09T00:00:00",
  "branchNo": 110,
  "cashRegisterNo": null
}
```

Rapor:

`GET /api/kasa-islemleri/kasa-hareket-aktarimi/rapor?date=2026-06-09&branchNo=110&cashRegisterNo=1`

Query:

```text
date            zorunlu; rapor tarihi
branchNo        opsiyonel; sube/depo no. all-warehouses yoksa backend JWT deposunu uygular
cashRegisterNo  opsiyonel; kasa no
```

Response:

```json
[
  {
    "date": "2026-06-09T00:00:00",
    "branchNo": 110,
    "branchName": "KESTEL 1",
    "cashRegisterNo": 1,
    "netAmount": 24500.75,
    "expense": 350.25,
    "checkAmount": 1250,
    "difference": 22900.5
  }
]
```

Alan notlari:

- `netAmount`: `PosFaturas.Toplam + PosFaturas.ToplamKdv` icinde satis/fatura kabul edilen kayit toplamidir; staging toplaminda fatura indirimi zaten uygulanmis kabul edilir.
- `expense`: `BelgeTuru = 4` icin `PosFaturas.Toplam + PosFaturas.ToplamKdv` gider pusulasi toplamidir.
- `checkAmount`: `PosFaturaOdemes` icinde `OdemeTipi = 4` cek toplamidir.
- `difference`: eski WinUI ekranindaki `Z Raporu` kolonudur; hesap `netAmount - expense - checkAmount` seklindedir.

Rapor ozet:

`GET /api/kasa-islemleri/kasa-hareket-aktarimi/rapor/ozet?date=2026-06-09&branchNo=110`

Response:

```json
{
  "date": "2026-06-09T00:00:00",
  "branchNo": 110,
  "cashRegisterNo": null,
  "rowCount": 2,
  "totalNetAmount": 45000.75,
  "totalExpense": 500.25,
  "totalCheckAmount": 2500,
  "totalDifference": 42000.5
}
```

Excel/CSV export:

`GET /api/kasa-islemleri/kasa-hareket-aktarimi/rapor/excel?date=2026-06-09&branchNo=110`

Not:

- Endpoint `text/csv; charset=utf-8` dosya doner.
- Dosya adi `kasa-hareket-rapor-yyyyMMdd.csv` formatindadir.
- CSV `;` ayraclidir ve UTF-8 BOM icerir; Excel ile direkt acilabilir.
- Gercek `.xlsx` uretilmez. UI isterse ayni `rapor` response'unu kendi grid/export mekanizmasi ile `.xlsx` olarak uretebilir.

Icmal karsilastirma:

`GET /api/kasa-islemleri/kasa-hareket-aktarimi/icmal-karsilastirma?date=2026-06-09&branchNo=110&cashRegisterNo=1&tolerance=0.01`

Amac:

- Kasa hareket aktarim raporundaki eski `Z Raporu` degeri ile Mikro `Summaries` icmal kayitlarini sube+kasa bazinda karsilastirir.
- Aktarim tarafi `PosFaturas` ve `PosFaturaOdemes` staging tablolarindan okunur.
- Icmal tarafi Mikro `Summaries` tablosundan okunur.

Query:

```text
date            zorunlu; is gunu
branchNo        opsiyonel; sube/depo no. all-warehouses yoksa backend JWT deposunu uygular
cashRegisterNo  opsiyonel; kasa no
tolerance       opsiyonel; varsayilan 0.01. Mutabik kabul edilecek parasal tolerans
```

Karsilastirma hesabi:

```text
movementZReportAmount = netAmount - expense - checkAmount
cashSummaryAmount     = Summaries icinde PaymentTypeID < 100 veya PaymentTypeID = 500 olan Amount toplami
differenceAmount      = movementZReportAmount - cashSummaryAmount
```

Not:

- `PaymentTypeID >= 100` gider/masraf gruplari karsilastirma toplaminda sayilmaz. Bu davranis `kasa-sayimlari` liste toplam mantigiyla aynidir.
- Satir anahtari `branchNo + cashRegisterNo` seklindedir.
- Sadece aktarimda veya sadece icmalde olan kasa satirlari da response'a dahil edilir.

Response:

```json
{
  "date": "2026-06-09T00:00:00",
  "branchNo": 110,
  "cashRegisterNo": 1,
  "tolerance": 0.01,
  "summary": {
    "rowCount": 1,
    "balancedCount": 0,
    "differenceCount": 1,
    "missingCashSummaryCount": 0,
    "missingMovementCount": 0,
    "totalMovementZReportAmount": 22900.5,
    "totalCashSummaryAmount": 22850.5,
    "totalDifferenceAmount": 50
  },
  "rows": [
    {
      "date": "2026-06-09T00:00:00",
      "branchNo": 110,
      "branchName": "KESTEL 1",
      "cashRegisterNo": 1,
      "movementNetAmount": 24500.75,
      "movementExpense": 350.25,
      "movementCheckAmount": 1250,
      "movementZReportAmount": 22900.5,
      "cashSummaryAmount": 22850.5,
      "cashSummaryDocumentCount": 1,
      "differenceAmount": 50,
      "status": "difference",
      "statusName": "Fark Var"
    }
  ]
}
```

`status` degerleri:

```text
balanced              tolerans icinde mutabik
difference            aktarim ve icmal var ama tutar farkli
missing-cash-summary  aktarim/staging raporu var, icmal kaydi yok
missing-movement      icmal kaydi var, aktarim/staging raporu yok
```

Icmal karsilastirma detay:

`GET /api/kasa-islemleri/kasa-hareket-aktarimi/icmal-karsilastirma/detay?date=2026-06-09&branchNo=110&cashRegisterNo=1&receiptTake=500`

Amac:

- Karsilastirma satirina tiklandiginda farkin nereden geldigini arastirmak icin detayli drill-down datasini doner.
- Backend burada Excel dosyasi uretmez; UI bu JSON response'u grid/sheet olarak kullanip kendi Excel export'unu uretebilir.
- `branchNo` ve `cashRegisterNo` zorunludur; detay endpointi tum sube/tum kasa icin calistirilmamalidir.

Query:

```text
date            zorunlu; is gunu
branchNo        zorunlu; sube/depo no
cashRegisterNo  zorunlu; kasa no
receiptTake     opsiyonel; default 500, max 5000. Fis listesinde getirilecek maksimum satir
```

Response ana bolumleri:

```text
movementReport             aktarim raporundaki sube+kasa satiri
comparison                 aktarim Z raporu ile Mikro icmal toplam farki
summary                    detay ekraninin ust KPI toplamları
cashierSummaries           aktarim fislerinden kasiyer bazli ozet
movementPaymentSummaries   aktarim fislerinin odeme tipi kirilimi
cashSummaryPayments        Mikro Summaries odeme tipi kirilimi
cashSummaryDocuments       Mikro icmal belge listesi
receipts                   Furpa PosFaturas fis listesi
canceledReceipts           Furpa PosFaturaIptals iptal fis listesi
```

Ornek response:

```json
{
  "date": "2026-06-09T00:00:00",
  "branchNo": 110,
  "branchName": "KESTEL 1",
  "cashRegisterNo": 1,
  "movementReport": {
    "date": "2026-06-09T00:00:00",
    "branchNo": 110,
    "branchName": "KESTEL 1",
    "cashRegisterNo": 1,
    "netAmount": 24500.75,
    "expense": 350.25,
    "checkAmount": 1250,
    "difference": 22900.5
  },
  "comparison": {
    "movementZReportAmount": 22900.5,
    "cashSummaryAmount": 22850.5,
    "differenceAmount": 50,
    "status": "difference",
    "statusName": "Fark Var"
  },
  "summary": {
    "receiptCount": 320,
    "returnedReceiptCount": 500,
    "canceledReceiptCount": 2,
    "movementLineCount": 1250,
    "movementPaymentCount": 340,
    "cashSummaryDocumentCount": 1,
    "cashSummaryPaymentCount": 8,
    "movementNetAmount": 24500.75,
    "movementExpense": 350.25,
    "movementCheckAmount": 1250,
    "movementZReportAmount": 22900.5,
    "cashSummaryAmount": 22850.5,
    "differenceAmount": 50,
    "minReceiptNo": 1,
    "maxReceiptNo": 330,
    "missingReceiptNos": [18, 27]
  },
  "cashierSummaries": [
    {
      "cashierCode": "1001",
      "cashierName": "MEHMET YILMAZ",
      "receiptCount": 120,
      "lineCount": 420,
      "netAmount": 9200,
      "expense": 0,
      "checkAmount": 400,
      "zReportAmount": 8800
    }
  ],
  "movementPaymentSummaries": [
    {
      "paymentType": 1,
      "paymentTypeName": "Nakit",
      "paymentCount": 80,
      "amount": 10000
    }
  ],
  "cashSummaryPayments": [
    {
      "paymentTypeId": 500,
      "paymentTypeName": "Nakit",
      "accountCode": "",
      "slipCount": 1,
      "amount": 9800,
      "isIncludedInComparison": true
    }
  ],
  "cashSummaryDocuments": [
    {
      "documentSerie": "KS110",
      "documentOrderNo": 12,
      "documentNo": "KS110/12",
      "cashNo": 1,
      "zReportNo": 125,
      "cashierNo": 1001,
      "cashierName": "MEHMET YILMAZ",
      "managerNo": 1002,
      "managerName": "AYSE DEMIR",
      "summaryDate": "2026-06-09T00:00:00",
      "totalAmount": 22850.5,
      "paymentLineCount": 8,
      "createDate": "2026-06-09T23:05:00"
    }
  ],
  "receipts": [
    {
      "invoiceGuid": "8d4a5a77-1b3f-4f2a-93a1-b90a1b7d3c11",
      "date": "2026-06-09T00:00:00",
      "time": "13:45:10",
      "branchNo": 110,
      "cashRegisterNo": 1,
      "receiptNo": 1450,
      "zNo": "125",
      "documentKind": 1,
      "documentKindName": "Fis",
      "cashierCode": "1001",
      "cashierName": "MEHMET YILMAZ",
      "cardNumber": "",
      "customerCurrentCode": "",
      "grossAmount": 120,
      "taxAmount": 20,
      "discountAmount": 0,
      "netAmount": 140,
      "expenseAmount": 0,
      "checkAmount": 0,
      "zReportAmount": 140,
      "lineCount": 3,
      "paymentCount": 1,
      "promotionCount": 0,
      "fiscalMemoryCode": "ABC123",
      "processResult": "",
      "cancelReason": 0,
      "cancelReasonName": ""
    }
  ],
  "canceledReceipts": [
    {
      "invoiceGuid": "5887c858-8083-4bf9-a9ef-0f95fbd90572",
      "date": "2026-06-09T00:00:00",
      "time": "15:12:40",
      "branchNo": 110,
      "cashRegisterNo": 1,
      "receiptNo": 18,
      "zNo": "125",
      "documentKind": 1,
      "documentKindName": "Fis",
      "cashierCode": "1001",
      "cashierName": "MEHMET YILMAZ",
      "cardNumber": "",
      "customerCurrentCode": "",
      "grossAmount": 120,
      "taxAmount": 20,
      "discountAmount": 0,
      "netAmount": 0,
      "expenseAmount": 0,
      "checkAmount": 0,
      "zReportAmount": 0,
      "lineCount": 3,
      "paymentCount": 0,
      "promotionCount": 0,
      "fiscalMemoryCode": "ABC123",
      "processResult": "",
      "cancelReason": 1,
      "cancelReasonName": "Iptal Nedeni 1"
    }
  ]
}
```

UI onerisi:

- `icmal-karsilastirma` gridinde sorunlu satira tiklaninca detay paneli veya sayfasi acilmali.
- Detay ustunde `movementZReportAmount`, `cashSummaryAmount`, `differenceAmount`, `statusName` KPI olarak gosterilmeli.
- `summary.receiptCount` toplam normal fis sayisidir; `summary.returnedReceiptCount` response'ta donen normal fis sayisidir. `receiptTake` dusukse bu iki deger farkli olabilir.
- `summary.canceledReceiptCount` iptal fis sayisidir; iptal fisler `canceledReceipts` koleksiyonunda ayrica doner ve aktarim Z raporu toplamlarini etkilemez.
- `summary.missingReceiptNos`, normal fis numara araliginda eksik gorunen fis numaralarini verir; bu liste iptal fisler veya kaynak dosyada gelmeyen fisleri arastirmak icin kullanilmalidir.
- Alt kisimda sekmeler: `Kasiyer Ozeti`, `Aktarim Odeme Kirilimi`, `Icmal Odeme Kirilimi`, `Icmal Belgeleri`, `Fisler`, `Iptal Fisler`, `Eksik Fis Numaralari`.
- Excel export UI tarafinda bu response ile uretilirse her sekme ayri sheet yapilabilir; backend CSV endpointleri sadece basit/hizli indirme icin kalabilir.
- `receiptTake=0` gonderilirse fis listesi bos gelir; sadece ozet/kirilim isteyen ekranlarda kullanilabilir.

Icmal karsilastirma Excel/CSV export:

`GET /api/kasa-islemleri/kasa-hareket-aktarimi/icmal-karsilastirma/excel?date=2026-06-09&branchNo=110`

Not:

- Endpoint `text/csv; charset=utf-8` dosya doner.
- Dosya adi `kasa-hareket-icmal-karsilastirma-yyyyMMdd.csv` formatindadir.
- CSV kolonlari: tarih, sube, kasa, aktarim net tutar, gider pusulasi, cek, aktarim Z raporu, icmal toplam, icmal belge sayisi, fark ve durum.
- UI basit indirme icin bu dosyayi kullanabilir. Daha zengin Excel icin `icmal-karsilastirma/detay` response'u uzerinden client-side `.xlsx` uretilmesi onerilir.

UI beklentisi:

- ekran tek menu olarak acilabilir; `Import`, `Rapor`, `Mikro Aktarim` sekmeleri yeterlidir
- ekran acilisinda `subeler`, sube secilince `subeler/{branchNo}/kasalar` cagrilmalidir; kasa filtresi etiketinde `cashRegisterTypeName` kullanilmalidir
- import dialogunda tarih araligi zorunlu, sube/kasa filtreleri opsiyonel olmalidir
- `dryRun` bir onizleme modu gibi sunulmalidir; sonuc adetleri ve `warnings/errors` satir bazli gosterilmelidir
- `skipExisting=true` varsayilani korunmalidir; tekrar import gereken durumlarda kullanici bilincli olarak kapatmalidir
- `staging sil`, `Mikro'ya aktar`, `Mikro'dan sil` ve `aralik aktar` aksiyonlari ayri butonlar olmalidir
- procedure response'unda adet bilgisi yoktur; UI mesaj alanini ve calistirilan filtreleri gostermelidir
- rapor sekmesinde `rapor`, ust kartlar icin `rapor/ozet`, Excel butonu icin `rapor/excel` kullanilabilir
- icmal kontrol sekmesinde `icmal-karsilastirma` response'u kullanilmali; `difference` ve `missing-*` durumlari renkli/filtrelenebilir gosterilmelidir
- icmal kontrol satirindan detay icin `icmal-karsilastirma/detay` cagrilmalidir
- zengin Excel export UI tarafinda detay response'undaki `cashierSummaries`, `movementPaymentSummaries`, `cashSummaryPayments`, `cashSummaryDocuments`, `receipts`, `canceledReceipts` ve `summary.missingReceiptNos` koleksiyonlari ayri sheet yapilarak uretilmelidir
- basit tek sheet export gerekirse `icmal-karsilastirma/excel` endpointi kullanilabilir

### Kasa Sayimlari Liste

Belirli bir gune ait kasa sayim belgelerini getirir.

`GET /api/kasa-islemleri/kasa-sayimlari?dateToGet=2026-04-24&warehouseNo=110`

Yetki:

- `kasa-islemleri.kasa-sayimlari.list`

Not:

- bu modul tarih araligi degil tek tarih ile calisir
- `warehouseNo` verilmezse JWT icindeki kullanici deposu kullanilir
- response modeli `CashSummaryListItemDto` doner
- backend belge bazli tek satir doner
- `total` alani `paymentTypeId < 100` veya `paymentTypeId = 500` olan hareketlerin toplamini verir

UI/menu ayrimi:

- `KasaSayimlari` artik okuma/goruntuleme gorevidir; sadece `list` ve `detail` yetkileri vardir.
- Yeni icmal girisi icin UI ayri gorev/menu gostermelidir: `IcmalKaydiGirisi`.
- Icmal giris ekraninin route'lari geriye uyumluluk icin halen `/api/kasa-islemleri/kasa-sayimlari` altindadir; yetki kodlari ayridir.

Response:

```json
[
  {
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "documentSerie": "KS110",
    "documentOrderNo": 12,
    "cashNo": 1,
    "zReportNo": 125,
    "cashierNo": 1001,
    "managerNo": 1002,
    "summaryDate": "2026-04-24T00:00:00",
    "total": 15340.5
  }
]
```

### Kasa Sayimlari Rapor

Belirli bir tarih icin depo bazli toplu rapor getirir.

`GET /api/kasa-islemleri/kasa-sayimlari/rapor?dateToGet=2026-04-24&warehouseNo=110`

Yetki:

- `kasa-islemleri.kasa-sayimlari.list`

Not:

- response modeli `CashSummaryReportItemDto` doner
- nakit, banka, yemek ceki, masraf pusulasi ve magaza gideri toplamlari depo bazli aggregate olarak gelir
- UI'da bu endpoint rapor/ozet ekraninda, liste endpointi ise belge listesinde kullanilmalidir

Response:

```json
[
  {
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "cashAmount": 11340.5,
    "cashAmountQuantity": 1,
    "akbank": 2500,
    "akbankQuantity": 1,
    "halkbank": 0,
    "halkbankQuantity": 0,
    "isBankasi": 0,
    "isBankasiQuantity": 0,
    "teb": 0,
    "tebQuantity": 0,
    "yapiKredi": 0,
    "yapiKrediQuantity": 0,
    "ziraatBankasi": 0,
    "ziraatBankasiQuantity": 0,
    "metropol": 0,
    "metropolQuantity": 0,
    "multinet": 0,
    "multinetQuantity": 0,
    "setcard": 0,
    "setcardQuantity": 0,
    "sodexoKupon": 0,
    "sodexoKuponQuantity": 0,
    "sodexoPos": 0,
    "sodexoPosQuantity": 0,
    "ticketKupon": 0,
    "ticketKuponQuantity": 0,
    "ticketPos": 0,
    "ticketPosQuantity": 0,
    "expenseCompass": 0,
    "expenseCompassQuantity": 0,
    "storeExpense": 0,
    "storeExpenseQuantity": 0
  }
]
```

### Kasa Sayimi Detay

Belgeye ait odeme/magaza gider satirlarini getirir.

Iki route ayni davranisi kullanir:

- `GET /api/kasa-islemleri/kasa-sayimlari/KS110/12?warehouseNo=110`
- `GET /api/kasa-islemleri/kasa-sayimlari/KS110/12/detaylar?warehouseNo=110`

Yetki:

- `kasa-islemleri.kasa-sayimlari.detail`

Not:

- response modeli `CashSummaryDetailItemDto` doner
- belge bulunmazsa `404 Not Found` doner
- odeme satirlari ve store expense satirlari ayni listede gelir
- `PaymentTypeID = 500` nakit toplam satiri bu endpointte donmez; backend bu satiri banknot hareketlerinden garanti eder
- UI kullaniciya gosterecegi odeme adini `typeName` veya `paymentName` alanindan basmalidir; `paymentTypeId`, `accountCode` veya `terminalId` uzerinden banka/yemek karti adi tahmin edilmemelidir
- `paymentTypeKey`, UI dropdown eslestirmesi icin guvenli anahtardir; format `paymentTypeNo|ACCOUNT_CODE|TERMINAL_ID` seklindedir
- `paymentTypeNo`, `paymentTypeId`, `accountCode`, `terminalId` ve `paymentTypeKey` birlikte kullanilirsa eski terminal/hesap degisimlerinde satir yanlis secenege dusmez
- `source` satirin makine dostu grubudur: `card`, `foodCheck`, `expenseVoucher`, `storeExpense`, `onlineSale`, `cash`, `other`
- `category` UI grup basligi icin kullanilabilir

Response:

```json
[
  {
    "typeName": "Akbank POS",
    "paymentName": "Akbank POS",
    "paymentTypeId": 1,
    "paymentTypeNo": 1,
    "accountCode": "POS-AKBANK",
    "terminalId": "TERM-01",
    "source": "card",
    "category": "Kredi Kartlari",
    "slipNumber": 45612,
    "amount": 2500,
    "description": "",
    "paymentTypeKey": "1|POS-AKBANK|TERM-01"
  }
]
```

### Banknot ve Hediye Ceki Hareketleri

Belgeye ait fiziksel para ve hediye ceki detaylarini getirir.

Route'lar:

- `GET /api/kasa-islemleri/kasa-sayimlari/KS110/12/banknot-hareketleri?warehouseNo=110`
- `GET /api/kasa-islemleri/kasa-sayimlari/KS110/12/hediye-ceki-hareketleri?warehouseNo=110`

Yetki:

- `kasa-islemleri.kasa-sayimlari.detail`

Response ornekleri:

```json
[
  {
    "value": 200,
    "banknoteType": 1,
    "banknoteTypeName": "200 TL",
    "quantity": 20,
    "total": 4000
  }
]
```

```json
[
  {
    "value": 100,
    "giftCheckType": 1,
    "giftCheckTypeName": "Hediye Çeki 100 TL",
    "quantity": 3,
    "total": 300
  }
]
```

Not:

- UI banknot satirinda gorunen adi `banknoteTypeName` alanindan basmalidir; `value` ve `banknoteType` ile kendisi metin uretmek zorunda degildir
- UI hediye ceki satirinda gorunen adi `giftCheckTypeName` alanindan basmalidir

### Birlik Kart Sorgulama

Birlik kart / indirim ceki bilgisini Puan DB tarafindaki `INTERBONUS_INDIRIMCEK` tablosundan `Cek_No` ile sorgular, detayini getirir ve yetkili kullanicida ayni cek kaydini gunceller.

Yetki:

- menu/route icin `kasa-islemleri.birlik-kart-sorgulama.page`
- sorgu endpoint'i icin `kasa-islemleri.birlik-kart-sorgulama.list`
- detay endpoint'i icin `kasa-islemleri.birlik-kart-sorgulama.detail`
- guncelle endpoint'i icin `kasa-islemleri.birlik-kart-sorgulama.update`

Not:

- Bu endpoint depo kapsamli degildir; `all-warehouses` yetkisi yoktur ve UI depo secici gostermemelidir.
- `PuanConnection` doluysa backend Puan DB'yi okur.
- `PuanConnection` bossa uygulama acilmaya devam eder; endpointler kontrollu olarak basarisiz sonuc ve aciklayici `message` dondurur.
- Response musteri kimlik/adres bilgisi degil, indirim ceki/puan satiri bilgisidir. `cariKod` musteri/cari kodudur; ad soyad veya unvan anlami tasimaz.
- `sorgula` request'indeki `kartNo` okutulan/girilen degerdir; backend bunu Puan DB'de `CEK_NO` alaninda arar.
- `detay` ve `guncelle` request'lerinde asil anahtar `cekNo` alanidir.
- Guncellemede `cariKod` mevcut kayittaki cari kodla ayni olmalidir. Farkli cari kodu gelirse backend kaydi guncellemez ve `isUpdated=false` doner. Bu kontrol yanlis cek/cari eslesmesini engellemek icindir.
- Auth DB migration'lari: `20260824091923_AddBirlikKartSorgulamaPermissions` page/list yetkilerini, `20260824120329_AddBirlikKartDetailUpdatePermissions` detail/update yetkilerini ekler.
- Puan DB icin migration yoktur; Puan tablolari mevcut harici veritabanidir.

Endpoint ozeti:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `POST /api/kasa-islemleri/birlik-kart-sorgulama/sorgula` | body | `BirlikKartSorgulamaRequest` | `BirlikKartSorgulamaResponse` | `kasa-islemleri.birlik-kart-sorgulama.list` |
| `POST /api/kasa-islemleri/birlik-kart-sorgulama/detay` | body | `BirlikKartDetayRequest` | `BirlikKartDetayResponse` | `kasa-islemleri.birlik-kart-sorgulama.detail` |
| `POST /api/kasa-islemleri/birlik-kart-sorgulama/guncelle` | body | `BirlikKartSorgulamaGuncelleRequest` | `BirlikKartGuncelleResponse` | `kasa-islemleri.birlik-kart-sorgulama.update` |

#### Birlik Kart Sorgula

`POST /api/kasa-islemleri/birlik-kart-sorgulama/sorgula`

Request:

```json
{
  "kartNo": "123456"
}
```

Kayit bulunursa response:

```json
{
  "isFound": true,
  "kartNo": "123456",
  "cekNo": "123456",
  "cariKod": "120.01.00001",
  "tutar": 100,
  "puan": 25,
  "baslangic": "2026-08-01T00:00:00",
  "bitis": "2026-08-31T23:59:59",
  "flag": false,
  "subeKodu": "110",
  "kasaNo": 1,
  "kartTipi": 1,
  "message": null
}
```

Kayit bulunamazsa response:

```json
{
  "isFound": false,
  "kartNo": "123456",
  "cekNo": null,
  "cariKod": null,
  "tutar": null,
  "puan": null,
  "baslangic": null,
  "bitis": null,
  "flag": null,
  "subeKodu": null,
  "kasaNo": null,
  "kartTipi": null,
  "message": "Kart veya cek kaydi bulunamadi."
}
```

#### Birlik Kart Detay

`POST /api/kasa-islemleri/birlik-kart-sorgulama/detay`

Request:

```json
{
  "cekNo": "123456"
}
```

Kayit bulunursa response:

```json
{
  "isFound": true,
  "kartNo": "123456",
  "cekNo": "123456",
  "cariKod": "120.01.00001",
  "tutar": 100,
  "puan": 25,
  "baslangic": "2026-08-01T00:00:00",
  "bitis": "2026-08-31T23:59:59",
  "flag": false,
  "subeKodu": "110",
  "kasaNo": 1,
  "kartTipi": 1,
  "message": null
}
```

Kayit bulunamazsa response:

```json
{
  "isFound": false,
  "kartNo": "123456",
  "cekNo": "123456",
  "message": "Kart veya cek kaydi bulunamadi."
}
```

#### Birlik Kart Guncelle

`POST /api/kasa-islemleri/birlik-kart-sorgulama/guncelle`

Request:

```json
{
  "cekNo": "123456",
  "cariKod": "120.01.00001",
  "tutar": 100,
  "puan": 25,
  "baslangic": "2026-08-01T00:00:00",
  "bitis": "2026-08-31T23:59:59",
  "flag": false,
  "subeKodu": "110",
  "kasaNo": 1,
  "kartTipi": 1
}
```

Validasyon ve is kurali:

```text
cekNo    zorunlu
cariKod  zorunlu; mevcut cek kaydindaki Cari_Kod ile ayni olmalidir
tutar    opsiyonel decimal
puan     opsiyonel decimal
baslangic/bitis opsiyonel tarih
flag     opsiyonel boolean
subeKodu opsiyonel metin
kasaNo   opsiyonel integer
kartTipi opsiyonel integer
```

Basarili response:

```json
{
  "isUpdated": true,
  "message": "Kart veya cek kaydi guncellendi."
}
```

Kayit yoksa veya cari kodu eslesmezse HTTP basarili donebilir ama is sonucu basarisizdir:

```json
{
  "isUpdated": false,
  "message": "Cari kodu farkli oldugu icin kart veya cek kaydi guncellenemedi."
}
```

UI kullanim notu:

- Ekranda tek ana giris olarak kart/cek no okutma alani yeterlidir.
- Kullanici sorgula dediginde body'de sadece `kartNo` gonderilir.
- Sorguda kayit bulunursa UI response'taki `cekNo` degerini detay ve guncelleme isteklerinde kullanmalidir.
- `isFound=false` ise UI teknik hata gibi degil, "kart/cek bulunamadi" sonucu gibi gostermelidir.
- `tutar`, `puan`, `baslangic`, `bitis`, `subeKodu`, `kasaNo`, `kartTipi` alanlari bilgi karti veya detay formu olarak gosterilebilir.
- Guncelle butonu sadece `kasa-islemleri.birlik-kart-sorgulama.update` yetkisi varsa acilmalidir.
- Guncelleme istegi pending iken form ve buton kilitlenmelidir; response `isUpdated=false` ise kullaniciya `message` metni gosterilmelidir.

### Banknot Takipleri

Gunluk banknot teslim/toplam kayitlarini Kasa Islemleri altindaki ayri menu route'undan getirir.

`GET /api/kasa-islemleri/banknot-takipleri?dateToGet=2026-04-24&warehouseNo=110`

Yetki:

- `kasa-islemleri.banknot-takipleri.list`

Not:

- `kasa-islemleri.banknot-takipleri.all-warehouses` yoksa UI `warehouseNo` gondermez; backend JWT icindeki kullanici deposunu uygular
- `kasa-islemleri.banknot-takipleri.all-warehouses` varsa `warehouseNo` bos/null gonderilirse tum depolar listelenir; belirli depo icin ilgili depo no gonderilir
- `warehouseNo = 1` artik tum depolar anlami tasimaz; gercekten 1 no'lu depo filtresi olarak yorumlanir
- response modeli `BanknoteTrackDto` doner ve `banknoteTrackId` alanini GUID olarak icerir
- bu route'da `differenceAmount`, eski kodla uyumlu olarak `deliveryTotalAmount - totalAmount` hesaplanir

Sayim toplami:

`GET /api/kasa-islemleri/banknot-takipleri/sayim-toplami?dateToGet=2026-04-24&warehouseNo=110`

Yetki:

- `kasa-islemleri.banknot-takipleri.list`

Not:

- Banknot teslim formunda `totalAmount` alanini backendden doldurmak icindir
- toplam, eski `GetTotalAmountForBanknoteTrack` davranisina uygun olarak `BanknoteMovements.CreateDate` gunu ve depo filtresiyle `Total` toplamidir
- `kasa-islemleri.banknot-takipleri.all-warehouses` yoksa `warehouseNo` gonderilmez; backend JWT deposunu kullanir
- all-warehouses yetkisi varsa baska depo icin `warehouseNo` gonderilebilir

Response:

```json
{
  "dateToGet": "2026-04-24T00:00:00",
  "warehouseNo": 110,
  "totalAmount": 12000
}
```

Response:

```json
[
  {
    "banknoteTrackId": "14d74fd4-1217-4056-9a0e-c45e3a25a456",
    "warehouseNo": 110,
    "warehouseName": "KESTEL 1",
    "banknoteTrackDate": "2026-04-24T00:00:00",
    "totalAmount": 12000,
    "deliveryTotalAmount": 11850,
    "differenceAmount": -150,
    "deliverer": "Teslim Eden",
    "receiver": "Teslim Alan",
    "createDate": "2026-04-24T20:10:00"
  }
]
```

Detay:

`GET /api/kasa-islemleri/banknot-takipleri/14d74fd4-1217-4056-9a0e-c45e3a25a456`

Yetki:

- `kasa-islemleri.banknot-takipleri.detail`

Olustur:

`POST /api/kasa-islemleri/banknot-takipleri`

Yetki:

- `kasa-islemleri.banknot-takipleri.create`

Onemli not:

- `kasa-islemleri.banknot-takipleri.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir. Bu yetki varsa baska depo adina banknot takip kaydi acilacaksa body'de opsiyonel `warehouseNo` gonderilebilir
- ayni depo ve ayni gun icin kayit varsa yeni insert yapmaz, `200 OK` ve `created = false` doner
- yeni kayit acilirse `201 Created` ve `created = true` doner

Request:

```json
{
  "banknoteTrackDate": "2026-04-24",
  "totalAmount": 12000,
  "deliveryTotalAmount": 11850,
  "deliverer": "Teslim Eden",
  "receiver": "Teslim Alan"
}
```

Response:

```json
{
  "banknoteTrackId": "14d74fd4-1217-4056-9a0e-c45e3a25a456",
  "banknoteTrackDate": "2026-04-24T00:00:00",
  "warehouseNo": 110,
  "created": true
}
```

### Kasa Lookup Endpointleri

Bu endpointler kasa sayim formundaki secim kutulari ve yardimci alanlar icindir. Kasa listelerinde `cashRegisterType` numeric degeri geriye uyumluluk icin korunur; UI gorunen metin olarak `cashRegisterTypeName` ve gerekirse yardim metni olarak `cashRegisterTypeDescription` kullanmalidir.

Yetki:

- tumu icin `kasa-islemleri.icmal-kaydi-girisi.list`

Route'lar:

- `GET /api/kasa-islemleri/kasa-sayimlari/kasiyerler/ikili?cashierCode=1001&managerCode=1002`
- `GET /api/kasa-islemleri/kasa-sayimlari/kasiyerler?filterString=mehmet`
- `GET /api/kasa-islemleri/kasa-sayimlari/kasalar?branchNo=110`
- `GET /api/kasa-islemleri/kasa-sayimlari/kasa-detayi?cashNo=1`
- `GET /api/kasa-islemleri/kasa-sayimlari/kasa-detayi?cashRegisterNo=CR-01`
- `GET /api/kasa-islemleri/kasa-sayimlari/banknot-tipleri`
- `GET /api/kasa-islemleri/kasa-sayimlari/hediye-ceki-tipleri`
- `GET /api/kasa-islemleri/kasa-sayimlari/odeme-tipleri/banka?cashRegisterNo=CR-01`
- `GET /api/kasa-islemleri/kasa-sayimlari/odeme-tipleri/yemek-ceki`
- `GET /api/kasa-islemleri/kasa-sayimlari/odeme-tipleri/online`
- `GET /api/kasa-islemleri/kasa-sayimlari/odeme-tipleri/masraf-pusulasi`
- `GET /api/kasa-islemleri/kasa-sayimlari/odeme-tipleri/magaza-masrafi`
- `GET /api/kasa-islemleri/kasa-sayimlari/online-kasa-detaylari`

`odeme-tipleri/banka` eski `Summaries/GetPaymentTypesByBanks` davranisi ile uyumludur. Backend `cashRegisterNo` ile `CashRegisterDetails` satirlarini bulur, bu satirlardaki `Bank` degeri ile `PaymentTypes.PaymentName` alanini eslestirir ve sadece `PaymentGenus = 1` banka odeme tiplerini dondurur. Ayni kasa numarasina bagli birden fazla banka/terminal varsa response birden fazla satir dondurur; UI bunlari tek bankaya dusurmemelidir. `terminalId` ilgili `CashRegisterDetails.TerminalId`, `accountCode` ilgili `PaymentTypes.AccountCode` degeridir. Terminal tanimlama ekranindaki banka secimi icin de `GET /api/ayar-islemleri/kasa-pos-terminalleri/secenekler` response'undaki `terminalBanks` kullanilmalidir; boylece buradaki eslestirme kayit sonrasinda dogru calisir.

UI kasa seciminde `GET /api/kasa-islemleri/kasa-sayimlari/kasalar?branchNo=...` veya ayar ekranindaki `GET /api/ayar-islemleri/sube-ayarlari/{branchNo}/kasalar` response'undan gelen `cashFinanceNumber` degeri varsa, banka odeme tipi endpointine `cashRegisterNo` olarak bu deger gonderilmelidir. Ornek: kullanici `Kasa 130` secer, satirda `cashFinanceNumber=PAV210010584` varsa cagri `GET /api/kasa-islemleri/kasa-sayimlari/odeme-tipleri/banka?cashRegisterNo=PAV210010584` olmalidir. `cashNo=130` sadece sube icindeki kasa numarasidir.

`odeme-tipleri/yemek-ceki` response'unda yemek ceki tipi adi `paymentName` alanindadir. Backend eski API ile uyumlu olarak `PaymentTypes.PaymentGenus = 2` olan yemek ceki odeme tiplerini listeler ve `accountCode` alanini `PaymentTypes.AccountCode` degeriyle doldurur. UI yemek ceki seciminde gorunen ad olarak `paymentName`, kayit payload'inda odeme tipi olarak `paymentTypeNo` kullanmalidir.

Kisa response ornekleri:

```json
[
  {
    "cashierCode": 1001,
    "cashierName": "MEHMET YILMAZ",
    "cashierPassword": "****",
    "cashierAuthorization": "KASIYER",
    "cashierState": true
  }
]
```

```json
[
  {
    "id": 3,
    "cashRegisterNo": "CR-01",
    "bank": "AKBANK",
    "terminalId": "TERM-01",
    "merchantNo": "MERCHANT-01",
    "cashNo": 1
  }
]
```

```json
[
  {
    "value": 100,
    "quantity": 0,
    "total": 0,
    "banknoteType": 2,
    "banknoteTypeName": "100 TL"
  },
  {
    "value": 200,
    "quantity": 0,
    "total": 0,
    "banknoteType": 1,
    "banknoteTypeName": "200 TL"
  }
]
```

`hediye-ceki-tipleri` response ornegi:

```json
[
  {
    "value": 25,
    "quantity": 0,
    "total": 0,
    "giftCheckType": 1,
    "giftCheckTypeName": "Hediye Çeki 25 TL"
  },
  {
    "value": 100,
    "quantity": 0,
    "total": 0,
    "giftCheckType": 2,
    "giftCheckTypeName": "Hediye Çeki 100 TL"
  }
]
```

`odeme-tipleri/banka` response ornegi:

```json
[
  {
    "paymentName": "Akbank",
    "paymentTypeId": 1,
    "paymentTypeNo": 1,
    "terminalId": "TERM-01",
    "accountCode": "108.01.001",
    "slipNumber": 0,
    "amountValue": 0,
    "paymentTypeKey": "1|108.01.001|TERM-01"
  },
  {
    "paymentName": "Halkbank",
    "paymentTypeId": 2,
    "paymentTypeNo": 2,
    "terminalId": "TERM-02",
    "accountCode": "108.01.002",
    "slipNumber": 0,
    "amountValue": 0,
    "paymentTypeKey": "2|108.01.002|TERM-02"
  }
]
```

`odeme-tipleri/yemek-ceki` response ornegi:

```json
[
  {
    "paymentName": "Sodexo POS",
    "paymentTypeId": 50,
    "paymentTypeNo": 50,
    "terminalId": "",
    "accountCode": "108.02.001",
    "slipNumber": 0,
    "amountValue": 0,
    "paymentTypeKey": "50|108.02.001|"
  },
  {
    "paymentName": "Ticket POS",
    "paymentTypeId": 52,
    "paymentTypeNo": 52,
    "terminalId": "",
    "accountCode": "108.02.002",
    "slipNumber": 0,
    "amountValue": 0,
    "paymentTypeKey": "52|108.02.002|"
  }
]
```

`odeme-tipleri/masraf-pusulasi` response ornegi:

```json
[
  {
    "paymentName": "Gider Pusulası",
    "paymentTypeId": 100,
    "paymentTypeNo": 100,
    "terminalId": "",
    "accountCode": "",
    "slipNumber": 0,
    "amountValue": 0,
    "paymentTypeKey": "100||"
  }
]
```

Not:

- `paymentName`, kullaniciya basilacak gercek addir; UI `paymentTypeNo` araligindan isim tahmin etmemelidir
- `paymentTypeKey`, dropdown secili satirini guvenli bulmak icindir; ayni odeme tipinin farkli terminal/hesap kodu varsa tek secenege dusurulmemelidir
- `odeme-tipleri/masraf-pusulasi`, Mikro tarafinda tanim yoksa bile fallback olarak `Gider Pusulası / 100` dondurur

### Z Rapor Toplami

Paylasim klasorundeki Z rapor dosyasindan `NET CIRO` degerini okumaya calisir.

`GET /api/kasa-islemleri/kasa-sayimlari/z-rapor-toplam?warehouseNo=110&zReportNo=125&cashNo=1`

Yetki:

- `kasa-islemleri.icmal-kaydi-girisi.list`

Not:

- response `double` doner
- `documentSerie` opsiyoneldir; gonderilirse `KS110`, `F110.1` ve `F110` formatlari desteklenir
- `documentSerie` bos veya parse edilemezse backend dogrudan `warehouseNo` ile sube path bilgisini cozer
- dosya bulunamazsa, config bos ise veya `NET CIRO` parse edilemezse `-1` doner
- backend sube IP ve POS klasor bilgisini `BranchDetails` kaydindan okur

### Icmal Kaydi Girisi / Olustur

Secili sube icin yeni kasa sayimi yazar.

`POST /api/kasa-islemleri/kasa-sayimlari`

Yetki:

- `kasa-islemleri.icmal-kaydi-girisi.create`

Onemli not:

- `kasa-islemleri.icmal-kaydi-girisi.all-warehouses` yoksa `warehouseNo` sorulmaz; backend JWT icindeki kullanici deposunu kullanir
- `kasa-islemleri.icmal-kaydi-girisi.all-warehouses` varsa UI sube secici gostermeli ve body'de secilen subeyi `warehouseNo` olarak gondermelidir; bos gonderilirse API `400 Bad Request` doner
- en az bir `paymentTypes`, `storeExpenses` veya `banknoteMovements` satiri zorunludur
- backend `Summaries`, `BanknoteMovements`, `GiftCheckMovements` ve `CARI_HESAP_HAREKETLERI` tarafina yazar
- `documentSerie` backend tarafinda legacy kasa icmal formatinda `F{islemDepoNo}.{cashNo}` olarak uretilir
- `documentOrderNo` ayni seri icin mevcut maksimum degerin bir fazlasi olarak uretilir
- `zReportNo` Z rapor numarasidir; `zTotalValue` Z rapor tutaridir
- `zTotalValue` eski sistemle uyumlu sekilde `Summaries` satiri olarak saklanmaz; `CARI_HESAP_HAREKETLERI` tarafinda canli/eski uyumlu `X / sira` evraklari olarak tutulur, gercek kasa sayimi belgesi `cha_aciklama = "{documentSerie}.{documentOrderNo}"` icinden izlenir
- CARI tarafinda odeme tipleri, nakit toplam, `300 = total - zTotalValue fark` ve `400 = Z Rapor Toplami` satirlari ayri hareketler olarak yazilir
- nakit toplam `paymentTypes` icinde manuel gonderilmez; backend banknot hareketlerinden `PaymentTypeID = 500`, `description = "Nakit Toplam"` satirini garanti eder
- UI yanlislikla `paymentTypes` icinde `Nakit` veya `paymentTypeNo = 500` gonderirse backend bunu ayri odeme satiri olarak yazmaz, 500 satirini banknot toplamindan uretir

Request:

```json
{
  "warehouseNo": 110,
  "cashNo": 1,
  "zReportNo": 125,
  "cashierNo": 1001,
  "managerNo": 1002,
  "zTotalValue": 6500,
  "total": 6500,
  "summaryDate": "2026-04-24",
  "giftCheckMovements": [],
  "banknoteMovements": [
    {
      "banknoteType": 1,
      "quantity": 20,
      "total": 4000,
      "value": 200
    }
  ],
  "paymentTypes": [
    {
      "paymentName": "Akbank POS",
      "paymentTypeNo": 1,
      "accountCode": "POS-AKBANK",
      "terminalId": "TERM-01",
      "slipNumber": 12,
      "amountValue": 2500
    }
  ],
  "storeExpenses": []
}
```

Response:

```json
{
  "documentSerie": "F110.1",
  "documentOrderNo": 12,
  "summaryDate": "2026-04-24T00:00:00",
  "warehouseNo": 110,
  "lineCount": 2,
  "total": 6500,
  "writeConnectionName": "MikroConnection"
}
```

### Kasa Sayimlari / Secili Kaydi Guncelleme ve Silme

Bu akis Kasa Sayimlari liste ekranindan secilen kayit icindir. Icmal Kaydi Girisi sadece yeni kayit olusturma ekranidir.

Belge uzerindeki odeme/masraf satirlari, fiziksel para detaylari ve hediye ceki detaylarini guncellemek icin ayri endpointler kullanilir.

Route'lar:

- `PUT /api/kasa-islemleri/kasa-sayimlari/F110.1/12/detaylar`
- `PUT /api/kasa-islemleri/kasa-sayimlari/F110.1/12/banknot-hareketleri`
- `PUT /api/kasa-islemleri/kasa-sayimlari/F110.1/12/hediye-ceki-hareketleri`
- `DELETE /api/kasa-islemleri/kasa-sayimlari/F110.1/12`

Legacy uyumluluk route'lari:

- `POST /api/kasa-islemleri/kasa-sayimlari/UpdateSummaryDetails`
- `POST /api/kasa-islemleri/kasa-sayimlari/UpdateBanknoteMovements`
- `POST /api/kasa-islemleri/kasa-sayimlari/UpdateGiftCheckMovements`
- `POST /api/kasa-islemleri/kasa-sayimlari/DeleteSummary`

Yetki:

- detay, banknot ve hediye ceki update icin `kasa-islemleri.kasa-sayimlari.update`
- silme icin `kasa-islemleri.kasa-sayimlari.delete`

Not:

- detay update request'inde `details` listesi zorunludur
- detay update patch degildir; UI belgede kalmasini istedigi tum odeme/masraf detay satirlarini `details` icinde gondermelidir
- banka POS, yemek ceki/karti, online odeme, masraf pusulasi ve magaza gideri satirlari ayni `details` listesinde yonetilir
- yemek ceki/karti odemeleri `GiftCheckMovements` degildir; Multinet, Metropol, Sodexo, Ticket, Setcard gibi odemeler `PUT /detaylar` icindeki `details` listesine eklenir
- detay listesinde eski satir yeni degerleriyle gelirse guncellenir; yeni satir gelirse olusur; eski satir gonderilmezse kaldirilir
- UI sadece degisen tek satiri gondermemelidir; aksi halde diger detay satirlari kaldirilmis kabul edilir
- nakit/500 satiri UI tarafindan normal detay gibi yonetilmez; backend mevcut banknot/nakit toplamindan 500 satirini yeniden uretir
- banknot update de patch degildir; `banknoteMovements` son durumda kalacak tum banknotlari icermelidir
- banknot update request'inde `banknoteMovements` bos gonderilirse mevcut banknot satirlari temizlenebilir
- banknot update sonrasi backend `PaymentTypeID = 500` nakit toplam satirini ve ilgili cari hareket toplamlarini yeni belge toplamiyla gunceller
- hediye ceki update de patch degildir; `giftCheckMovements` son durumda kalacak tum hediye ceki satirlarini icermelidir
- hediye ceki update request'inde `giftCheckMovements` bos gonderilirse mevcut hediye ceki satirlari temizlenebilir
- update sonrasi backend ilgili CARI hareketlerini canli/eski uyumlu `X + aciklama` formatinda yeniden olusturur; odeme tipleri, nakit, Z fark ve Z toplam CARI'de ayri satirlar olarak gorunur
- update belge yoksa yeni belge olusturmaz; yeni kasa sayimi/icmal kaydi icin create endpointi kullanilir
- modern `DELETE` cagrisinda sube icin query `warehouseNo` veya JWT deposu kullanilir
- legacy `POST DeleteSummary` cagrisinda `warehouseNo` yoksa backend `documentSerie` icinden subeyi cozer, ornek `F110.1` -> `110`

UI bloklarinin update karsiligi:

| UI blogu | Endpoint | Request listesi | Davranis |
| --- | --- | --- | --- |
| Nakit Hareketleri | `PUT /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/banknot-hareketleri` | `banknoteMovements` | Son banknot listesi gonderilir; yeni deger eklenir, olmayan silinir |
| Kredi Kartlari | `PUT /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/detaylar` | `details` | POS/banka satirlari son liste olarak gonderilir |
| Yemek Cekleri/Kartlari | `PUT /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/detaylar` | `details` | Multinet, Metropol, Sodexo, Ticket, Setcard gibi satirlar eklenir/guncellenir |
| Hediye Cekleri | `PUT /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/hediye-ceki-hareketleri` | `giftCheckMovements` | Fiziksel hediye ceki deger/adet listesi gonderilir |
| Online Satislar | `PUT /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/detaylar` | `details` | Kayit yokken yeni online odeme satiri eklenebilir |
| Gider Pusulalari | `PUT /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/detaylar` | `details` | Gider pusulasi fis/adet/tutar satiri eklenir/guncellenir |
| Magaza Giderleri | `PUT /api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/detaylar` | `details` | Ayni tipten birden fazla aciklamali gider satiri eklenebilir |

Detay update request:

```json
{
  "details": [
    {
      "typeName": "Akbank POS",
      "paymentTypeId": 1,
      "accountCode": "POS-AKBANK",
      "slipNumber": 12,
      "amount": 2500,
      "terminalId": "TERM-01",
      "description": ""
    },
    {
      "typeName": "Multinet",
      "paymentTypeId": 54,
      "accountCode": "K.0002",
      "slipNumber": 8,
      "amount": 1250,
      "terminalId": "",
      "description": ""
    }
  ]
}
```

Detay update response:

```json
{
  "documentSerie": "F110.1",
  "documentOrderNo": 12,
  "updatedLineCount": 2,
  "totalAmount": 6500
}
```

Banknot update request:

```json
{
  "banknoteMovements": [
    {
      "value": 200,
      "banknoteType": 1,
      "quantity": 25,
      "total": 5000
    }
  ]
}
```

Banknot update response modeli:

- `documentSerie`
- `documentOrderNo`
- `updatedLineCount`
- `totalAmount`

Hediye ceki update request:

```json
{
  "giftCheckMovements": [
    {
      "giftCheckType": 1,
      "quantity": 2,
      "total": 200,
      "value": 100
    }
  ]
}
```

Hediye ceki update response modeli:

- `documentSerie`
- `documentOrderNo`
- `updatedLineCount`
- `totalAmount`

Legacy detay update request:

```json
{
  "documentSerie": "F110.1",
  "documentOrderNo": 12,
  "summariesDetails": [
    {
      "typeName": "Akbank POS",
      "paymentTypeID": 1,
      "accountCode": "POS-AKBANK",
      "slipNumber": 12,
      "amount": 2500,
      "terminalId": "TERM-01",
      "description": ""
    }
  ]
}
```

Legacy banknot update request:

```json
{
  "documentSerie": "F110.1",
  "documentOrderNo": 12,
  "banknoteMovements": [
    {
      "value": 200,
      "banknoteTypeID": 1,
      "quantity": 25,
      "total": 5000
    }
  ]
}
```

Legacy hediye ceki update request:

```json
{
  "documentSerie": "F110.1",
  "documentOrderNo": 12,
  "giftCheckMovements": [
    {
      "giftCheckTypeID": 1,
      "quantity": 2,
      "total": 200,
      "value": 100
    }
  ]
}
```

Delete response:

```json
{
  "documentSerie": "F110.1",
  "documentOrderNo": 12,
  "deletedSummaryLineCount": 2,
  "deletedBanknoteLineCount": 1,
  "deletedGiftCheckLineCount": 0,
  "deletedCustomerMovementCount": 1
}
```

Legacy delete request:

```json
{
  "documentSerie": "F110.1",
  "documentOrderNo": 12
}
```

## Scaffold Olarak Hazir, Backend'i Henuz Implement Edilmemis Route'lar

Bu route'lar UI tasarimi icin aciktir, fakat backend cevabi su an `501 Not Implemented` doner.

Ortak scaffold request modeli:

- `fields`: `Dictionary<string, string?>`

Ortak scaffold response modeli:

- `moduleCode`
- `moduleName`
- `menuCode`
- `menuName`
- `actionCode`
- `actionName`
- `httpMethod`
- `permissionCode`
- `route`
- `resourceId`
- `isImplemented`
- `message`

`message` alani su an sabit olarak su metni doner:

```text
Bu endpoint iskelet olarak acildi. Is kurali ve Mikro veritabani entegrasyonu sonraki adimda baglanacak.
```

### Siparis Islemleri

- `POST /api/siparis-islemleri/alinan-depo-siparisleri`
- `PUT /api/siparis-islemleri/alinan-depo-siparisleri/{id}`
- `POST /api/siparis-islemleri/alinan-firma-siparisleri`
- `PUT /api/siparis-islemleri/alinan-firma-siparisleri/{id}`
- `PUT /api/siparis-islemleri/verilen-depo-siparisleri/{id}`
- `PUT /api/siparis-islemleri/verilen-firma-siparisleri/{id}`

### Sevk Islemleri

- `PUT /api/sevk-islemleri/depolar-arasi-sevkler/{id}`
- `PUT /api/sevk-islemleri/firma-sevkleri/{id}`

### Mal Kabul Islemleri

- `POST /api/mal-kabul-islemleri/depo-mal-kabulleri`
- `PUT /api/mal-kabul-islemleri/depo-mal-kabulleri/{id}`
- `PUT /api/mal-kabul-islemleri/firma-mal-kabulleri/{id}`

### Iade Islemleri

- `PUT /api/iade-islemleri/depo-iadeleri/{id}`
- `PUT /api/iade-islemleri/firma-iadeleri/{id}`

### Stok Islemleri

- `PUT /api/stok-islemleri/zayiat-fisleri/{id}`
- `PUT /api/stok-islemleri/masraf-fisleri/{id}`
- `PUT /api/stok-islemleri/sayim-sonuclari/{id}`
- `PUT /api/stok-islemleri/virmanlar/{id}`

### Kasa Islemleri

- `PUT /api/kasa-islemleri/etiket-belgeleri/{id}`

## UI Isleyis Semasi

```text
Login Ekrani
  -> POST /api/auth/login
  -> accessToken al
  -> GET /api/auth/me

Ana Layout
  -> me.modules ile sol menu ciz
  -> me.permissions ile buton yetkilerini belirle

Home / Sikayet Oneri Kutusu
  -> kutu ozet bilgisi icin GET /api/home/sikayet-oneri/ozet
  -> yeni kayit icin POST /api/home/sikayet-oneri
  -> kullanicinin gecmisi icin GET /api/home/sikayet-oneri/benim
  -> body'ye kullanici/depo bilgisi koyma; backend JWT claim'lerinden doldurur

Ortak Islemler / Sikayet Oneri Yonetimi
  -> menu/route permission'i: ortak-islemler.sikayet-oneri.page
  -> liste API permission'i: ortak-islemler.sikayet-oneri.list
  -> tum kayit kapsami icin ortak-islemler.sikayet-oneri.list-all gerekir
  -> list-all olmayan kullanici sadece kendi actigi kayitlari liste/detay olarak gorur
  -> okundu, durum veya admin notu aksiyonlari icin ortak-islemler.sikayet-oneri.update gerekir
  -> liste icin GET /api/yonetim/sikayet-oneri veya /api/ortak-islemler/sikayet-oneri
  -> satir detay icin GET /api/yonetim/sikayet-oneri/{id}
  -> okundu isareti icin PATCH /api/yonetim/sikayet-oneri/{id}/okundu
  -> durum/not guncelleme icin PATCH /api/yonetim/sikayet-oneri/{id}/durum

Home / Duyurular Kutusu
  -> login sonrasi auth/me tamamlaninca header seviyesinde GET /api/home/duyurular/ozet
  -> header mesaj kutusunda unreadCount badge goster
  -> kutu acilinca okunmamis aktif duyurular icin GET /api/home/duyurular?includeRead=false&take=20
  -> duyuru acilinca PATCH /api/home/duyurular/{id}/okundu
  -> okundu sonrasi badge icin GET /api/home/duyurular/ozet tekrar cagir
  -> baslik/metin/oncelik/tarih/hedef bilgilerini AnnouncementDto ile goster

Ortak Islemler / Duyurular Yonetimi
  -> menu/route permission'i: ortak-islemler.duyurular.page
  -> liste API permission'i: ortak-islemler.duyurular.list
  -> create butonu icin ortak-islemler.duyurular.create
  -> duzenle butonu icin ortak-islemler.duyurular.update
  -> arsivle butonu icin ortak-islemler.duyurular.archive
  -> tum depolar/baska depo/baska depo kullanicisi hedeflemek icin ortak-islemler.duyurular.all-warehouses
  -> liste icin GET /api/ortak-islemler/duyurular veya /api/yonetim/duyurular
  -> hedef kullanici secimi icin GET /api/ortak-islemler/duyurular/hedef-kullanicilar?search=...
  -> satir detay icin GET /api/ortak-islemler/duyurular/{id}
  -> okuyanlar paneli icin GET /api/ortak-islemler/duyurular/{id}/okuyanlar
  -> yeni duyuru icin POST /api/ortak-islemler/duyurular
  -> hedefleri tamamen yenileyerek guncellemek icin PUT /api/ortak-islemler/duyurular/{id}
  -> arsivlemek icin PATCH /api/ortak-islemler/duyurular/{id}/arsivle

Arama Islemleri / Fiyat Gor
  -> barkod, stok kodu veya stok adi ile GET /api/arama-islemleri/fiyat-gor
  -> barkod okutma kisayolu icin GET /api/arama-islemleri/barkodlar/{barcode}/fiyat
  -> liste satirlarini ProductLookupItemDto ile goster

Mobil Offline Fiyat Katalogu
  -> online iken GET /api/mobile-sync/urun-fiyat-katalogu ile depo bazli katalog indir
  -> hasMore=true ise nextCursor ile devam et
  -> hasMore=false olunca syncToken'i localde sakla
  -> offline barkod okutunca local DB'deki barcode + warehouseNo kaydini kullan

Arama Islemleri / Cari Bul
  -> barkod ile GET /api/arama-islemleri/cari-bul
  -> barkod okutma kisayolu icin GET /api/arama-islemleri/barkodlar/{barcode}/cariler
  -> stok karti ve onerilen cari listesini BarcodeCustomerSuggestionResponse ile goster

Siparis Islemleri / Verilen Depo Siparisleri
  -> liste filtreleri: tarih araligi, opsiyonel depo
  -> GET /api/siparis-islemleri/verilen-depo-siparisleri
  -> kullanici satira tiklar
  -> GET /api/siparis-islemleri/verilen-depo-siparisleri/{seri}/{sira}

Siparis Islemleri / Verilen Firma Siparisleri
  -> liste filtreleri: tarih araligi, opsiyonel depo
  -> GET /api/siparis-islemleri/verilen-firma-siparisleri
  -> kullanici satira tiklar
  -> GET /api/siparis-islemleri/verilen-firma-siparisleri/{seri}/{sira}

Siparis Islemleri / Onerilen Depo Siparisleri
  -> kullanici kaynak depo secer
  -> kaynak depo normal depo ise GET /api/siparis-islemleri/onerilen-depo-siparisleri?SourceWarehouseNo=...
  -> normal depo satirlarini SuggestedWarehouseOrderListItemDto ile goster
  -> kaynak depo Manav/Sarkuteri/Unlu Mamul gibi ozel depo ise GET /api/siparis-islemleri/onerilen-depo-siparisleri/kaynak-depo-urunleri?sourceWarehouseNo=...
  -> kaynak depo urunlerini SuggestedWarehouseSourceProductDto ile quantity=0 olarak goster
  -> kullanici satirlari secer ve miktarlari duzenler
  -> POST /api/siparis-islemleri/onerilen-depo-siparisleri/convert-to-order

Siparis Islemleri / Onerilen Firma Siparisleri
  -> kullanici firma/tedarikci secer
  -> GET /api/siparis-islemleri/onerilen-firma-siparisleri?SupplierCode=...
  -> liste satirlarini SuggestedCompanyOrderListItemDto ile goster
  -> kullanici satirlari secer ve miktarlari duzenler
  -> POST /api/siparis-islemleri/onerilen-firma-siparisleri/convert-to-order

Siparis Islemleri / Alinan Firma Siparisleri
  -> liste filtreleri: tarih araligi, opsiyonel depo
  -> GET /api/siparis-islemleri/alinan-firma-siparisleri
  -> kullanici satira tiklar
  -> GET /api/siparis-islemleri/alinan-firma-siparisleri/{seri}/{sira}

Siparis Detay
  -> header bilgilerini ust kartta goster
  -> items listesini grid olarak goster

Sevk Islemleri / Giden Depolar Arasi Sevkler
  -> GET /api/sevk-islemleri/depolar-arasi-sevkler/giden
  -> liste satirlarini WarehouseShippingListItemDto ile goster
  -> kullanici satira tiklar
  -> GET /api/sevk-islemleri/depolar-arasi-sevkler/giden/{seri}/{sira}
  -> kullanici 'E-Irsaliyeye Cevir' derse
  -> sofor bilgisi modalda elle alinir veya kayitli sofor secilip driverId gonderilir
  -> POST /api/sevk-islemleri/depolar-arasi-sevkler/giden/{seri}/{sira}/e-irsaliye
  -> basarili gonderimden sonra kullanici 'PDF Goster' derse
  -> GET /api/sevk-islemleri/depolar-arasi-sevkler/giden/{seri}/{sira}/e-irsaliye/pdf

Sevk Islemleri / Gelen Depolar Arasi Sevkler
  -> GET /api/sevk-islemleri/depolar-arasi-sevkler/gelen
  -> liste satirlarini WarehouseShippingListItemDto ile goster
  -> kullanici satira tiklar
  -> GET /api/sevk-islemleri/depolar-arasi-sevkler/gelen/{seri}/{sira}

Sevk Islemleri / Giden Firma Sevkleri
  -> GET /api/sevk-islemleri/firma-sevkleri/giden
  -> liste satirlarini CompanyMovementListItemDto ile goster
  -> kullanici satira tiklar
  -> GET /api/sevk-islemleri/firma-sevkleri/giden/{seri}/{sira}
  -> kullanici 'E-Irsaliyeye Cevir' derse
  -> sofor bilgisi modalda elle alinir veya kayitli sofor secilip driverId gonderilir
  -> POST /api/sevk-islemleri/firma-sevkleri/giden/{seri}/{sira}/e-irsaliye
  -> basarili gonderimden sonra kullanici 'PDF Goster' derse
  -> GET /api/sevk-islemleri/firma-sevkleri/giden/{seri}/{sira}/e-irsaliye/pdf

Sevk Islemleri / Gelen Firma Sevkleri
  -> GET /api/sevk-islemleri/firma-sevkleri/gelen
  -> liste satirlarini CompanyMovementListItemDto ile goster
  -> kullanici satira tiklar
  -> GET /api/sevk-islemleri/firma-sevkleri/gelen/{seri}/{sira}

Mal Kabul Islemleri / Depo Mal Kabulleri
  -> tarih araliginda bekleyen gelen sevkleri getir
  -> GET /api/mal-kabul-islemleri/depo-mal-kabulleri
  -> kullanici isterse QR'dan gelen ETTN ile resmi gelen e-irsaliye detayini ceker
  -> GET /api/mal-kabul-islemleri/depo-mal-kabulleri/e-irsaliye/ettn/{ettn}
  -> kullanici satira tiklar veya seri/sira girer
  -> GET /api/mal-kabul-islemleri/depo-mal-kabulleri/{seri}/{sira}
  -> kalemlerde stok kodu ile filtreleme UI tarafinda yapilir
  -> kabul kaydi icin POST /api/mal-kabul-islemleri/depo-mal-kabulleri/{seri}/{sira}/kabul

Mal Kabul Islemleri / Mal Kabul Farklari
  -> tarih araligi ve iki secimli scope ile farklari getir
  -> scope=accepted: kullanicinin deposunun kabul ettigi evraklar
  -> scope=created: kullanicinin deposunun olusturdugu/gonderdigi evraklar
  -> GET /api/mal-kabul-islemleri/mal-kabul-farklari
  -> alternatif kisayollar: /accepted, /created, /kabul-ettigim, /olusturdugum

Mal Kabul Islemleri / Firma Mal Kabulleri
  -> tarih araliginda yapilmis mal kabul fislerini getir
  -> GET /api/mal-kabul-islemleri/firma-mal-kabulleri
  -> kullanici satira tiklar
  -> GET /api/mal-kabul-islemleri/firma-mal-kabulleri/{seri}/{sira}
  -> kullanici 'Yeni Mal Kabul' derse create ekranina gecer
  -> QR'dan gelen ETTN/UUID ile e-irsaliye veya e-fatura ust bilgi ve kalemlerini cekebilir
  -> GET /api/mal-kabul-islemleri/firma-mal-kabulleri/resmi-belge/ettn/{ettn}?documentKind=auto
  -> eski alias: GET /api/mal-kabul-islemleri/firma-mal-kabulleri/e-irsaliye/ettn/{ettn}
  -> acik siparis baglamak icin GET /api/siparis-islemleri/verilen-firma-siparisleri?OnlyOpen=true&CustomerCode=...
  -> kaydetmek icin POST /api/mal-kabul-islemleri/firma-mal-kabulleri

Stok Islemleri / Zayiat Fisleri
  -> liste filtreleri: tarih araligi, opsiyonel depo
  -> GET /api/stok-islemleri/zayiat-fisleri
  -> liste satirlarini StockReceiptListItemDto ile goster
  -> kullanici satira tiklar
  -> GET /api/stok-islemleri/zayiat-fisleri/{seri}/{sira}
  -> kullanici 'Yeni Zayiat Fisi' derse create ekranina gecer
  -> creator ve acceptor alanlarini zorunlu al
  -> kaydetmek icin POST /api/stok-islemleri/zayiat-fisleri

Stok Islemleri / Masraf Fisleri
  -> liste filtreleri: tarih araligi, opsiyonel depo
  -> GET /api/stok-islemleri/masraf-fisleri
  -> liste satirlarini StockReceiptListItemDto ile goster
  -> kullanici satira tiklar
  -> GET /api/stok-islemleri/masraf-fisleri/{seri}/{sira}
  -> kullanici 'Yeni Masraf Fisi' derse create ekranina gecer
  -> creator ve acceptor alanlarini zorunlu al
  -> kaydetmek icin POST /api/stok-islemleri/masraf-fisleri

Stok Islemleri / Sayim Sonuclari
  -> liste filtreleri: tarih araligi, opsiyonel depo
  -> GET /api/stok-islemleri/sayim-sonuclari
  -> liste satirlarini InventoryCountListItemDto ile goster
  -> kullanici satira tiklar
  -> GET /api/stok-islemleri/sayim-sonuclari/{documentNo}?documentDate=...
  -> kullanici 'Yeni Sayim Sonucu' derse create ekranina gecer
  -> name alani opsiyonel, satirlar zorunlu
  -> kaydetmek icin POST /api/stok-islemleri/sayim-sonuclari

Kasa Islemleri / Etiket Belgeleri
  -> son belgeler icin GET /api/kasa-islemleri/etiket-belgeleri veya /son
  -> tum gecmis istenirse GET /api/kasa-islemleri/etiket-belgeleri/tumu
  -> liste satirlarini LabelDocumentListItemDto ile goster
  -> kullanici satira tiklar
  -> GET /api/kasa-islemleri/etiket-belgeleri/{documentId}
  -> ayni ekranda tarih bazli tag sorgusu gerekiyorsa
  -> GET /api/kasa-islemleri/etiket-belgeleri/etiketler?dateToGet=...
  -> kullanici 'Yeni Etiket Belgesi' derse create ekranina gecer
  -> her satir icin productCode zorunlu olmali
  -> kaydetmek icin POST /api/kasa-islemleri/etiket-belgeleri

Kasa Islemleri / Kunye Etiket Yazdirma
  -> tarih bazli kunye etiket kayitlari icin GET /api/kasa-islemleri/kunye-etiket-yazdirma?dateToGet=...
  -> liste satirlarini LabelTagDto ile goster

Kasa Islemleri / Manav Kunye Etiket Yazdirma
  -> depo bazli zengin response icin GET /api/kasa-islemleri/manav-kunye-etiket-yazdirma/detayli-etiketler?warehouseNo=...
  -> dateToGet opsiyoneldir; verilirse o gun icinden, verilmezse son 1 ay icinden son kunye kaydi secilir
  -> zengin liste satirlarini KunyeLabelTagDto ile goster
  -> endpoint token istemez

Kasa Islemleri / Manav Mal Kabul ve Etiket
  -> ekran acilisinda gunluk liste icin GET /api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records?date=...
  -> tedarikci secimi icin GET /api/kasa-islemleri/manav-mal-kabul-etiket/suppliers?query=...
  -> stok secimi icin GET /api/kasa-islemleri/manav-mal-kabul-etiket/stocks?query=...&prefix=MNV
  -> brut kilo, kasa darasi, kasa sayisi ve palet darasi girildikce POST /api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records/calculate
  -> kaydetmek icin POST /api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records
  -> duzenlemek icin PUT /api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records/{id}
  -> silmek icin DELETE /api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records/{id}
  -> kayitli satirdan yazdirmak icin GET /api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records/{id}/label
  -> kaydetmeden onizleme/yazdirma icin POST /api/kasa-islemleri/manav-mal-kabul-etiket/labels/preview
  -> UI labelBarcodeRaw, labelBarcode, barcodeSymbology ve labelCount alanlariyla yazici entegrasyonunu kendisi calistirir
  -> raporlar icin GET /api/kasa-islemleri/manav-mal-kabul-etiket/reports/received-products ve /reports/depot-stock
  -> Mikro mal kabul icin POST /api/kasa-islemleri/manav-mal-kabul-etiket/micro/goods-receipts kullanilir
  -> UI fiyatli/onayli satirlari gondermeden Mikro belgesi olusturulmaz

Manav / Manav Operasyon Paneli
  -> menu/route permission'i: green-grocer.operations.page
  -> panel verisi ve onizleme icin green-grocer.operations.list
  -> MNV duzeltme kaydet butonu icin green-grocer.operations.create
  -> ekran acilisinda GET /api/green-grocer/operations/overview?warehouseNo=56&startDate=...&endDate=...
  -> kullanici urun satirinda alis, MNV net fark, sube kasa talebi, tahmini KG/ADET, gercek sevk, son sayim ve guncel stok kolonlarini birlikte gorur
  -> duzeltme yazilacaksa once POST /api/green-grocer/operations/adjustments/preview
  -> onaydan sonra ayni clientRequestId ile POST /api/green-grocer/operations/adjustments
  -> timeout/retry durumunda yeni clientRequestId uretilmez; ayni istek tekrar denenir
  -> kayit sonrasi overview tekrar cagrilir

Stok Islemleri / Virmanlar
  -> liste filtreleri: tarih araligi, opsiyonel depo
  -> GET /api/stok-islemleri/virmanlar
  -> liste satirlarini VirmanListItemDto ile goster
  -> kullanici satira tiklar
  -> GET /api/stok-islemleri/virmanlar/{seri}/{sira}
  -> kullanici 'Yeni Virman' derse create ekranina gecer
  -> her satir icin movementType secimi zorunlu olmali
  -> kaydetmek icin POST /api/stok-islemleri/virmanlar

Iade Islemleri / Firma Iadeleri
  -> liste filtreleri: tarih araligi, opsiyonel depo
  -> GET /api/iade-islemleri/firma-iadeleri
  -> liste satirlarini CompanyMovementListItemDto ile goster
  -> kullanici satira tiklar
  -> GET /api/iade-islemleri/firma-iadeleri/{seri}/{sira}
  -> kullanici 'E-Irsaliyeye Cevir' derse
  -> sofor bilgisi modalda elle alinir veya kayitli sofor secilip driverId gonderilir
  -> POST /api/iade-islemleri/firma-iadeleri/{seri}/{sira}/e-irsaliye
  -> basarili gonderimden sonra kullanici 'PDF Goster' derse
  -> GET /api/iade-islemleri/firma-iadeleri/{seri}/{sira}/e-irsaliye/pdf

Iade Islemleri / Depo Iadeleri
  -> liste filtreleri: tarih araligi, opsiyonel depo
  -> kaynak sube icin GET /api/iade-islemleri/depo-iadeleri/giden
  -> alici sube icin GET /api/iade-islemleri/depo-iadeleri/gelen
  -> liste satirlarini WarehouseShippingListItemDto ile goster
  -> kullanici satira tiklar
  -> kaynak sube icin GET /api/iade-islemleri/depo-iadeleri/giden/{seri}/{sira}
  -> alici sube icin GET /api/iade-islemleri/depo-iadeleri/gelen/{seri}/{sira}
  -> kullanici 'E-Irsaliyeye Cevir' derse
  -> sofor bilgisi modalda elle alinir veya kayitli sofor secilip driverId gonderilir
  -> POST /api/iade-islemleri/depo-iadeleri/giden/{seri}/{sira}/e-irsaliye
  -> basarili gonderimden sonra kullanici 'PDF Goster' derse
  -> GET /api/iade-islemleri/depo-iadeleri/giden/{seri}/{sira}/e-irsaliye/pdf

Kasa Islemleri / Kasa Sayimlari
  -> ekran acilisinda o gunun belge listesi icin GET /api/kasa-islemleri/kasa-sayimlari?dateToGet=...
  -> ust rapor kartlari icin GET /api/kasa-islemleri/kasa-sayimlari/rapor?dateToGet=...
  -> kullanici satira tiklar
  -> GET /api/kasa-islemleri/kasa-sayimlari/{seri}/{sira}
  -> gerekiyorsa banknot ve hediye ceki detaylarini ayri sekmelerde
  -> GET /api/kasa-islemleri/kasa-sayimlari/{seri}/{sira}/banknot-hareketleri
  -> GET /api/kasa-islemleri/kasa-sayimlari/{seri}/{sira}/hediye-ceki-hareketleri
  -> kullanicida kasa-islemleri.kasa-sayimlari.update varsa 'Duzenle' aksiyonu gosterilir
  -> detay duzenleme icin PUT /api/kasa-islemleri/kasa-sayimlari/{seri}/{sira}/detaylar
  -> banknot duzenleme icin PUT /api/kasa-islemleri/kasa-sayimlari/{seri}/{sira}/banknot-hareketleri
  -> hediye ceki duzenleme icin PUT /api/kasa-islemleri/kasa-sayimlari/{seri}/{sira}/hediye-ceki-hareketleri
  -> kullanicida kasa-islemleri.kasa-sayimlari.delete varsa 'Sil' aksiyonu gosterilir
  -> silme icin DELETE /api/kasa-islemleri/kasa-sayimlari/{seri}/{sira}

Kasa Islemleri / Icmal Kaydi Girisi
  -> UI bu gorevi Kasa Sayimlari'ndan ayri menu/task olarak gostermelidir
  -> lookup alanlari icin kasiyer, kasa, odeme tipi ve banknot tipi endpointlerini paralel cagir
  -> Z rapor karsilastirmasi icin GET /api/kasa-islemleri/kasa-sayimlari/z-rapor-toplam?... 
  -> kaydetmek icin POST /api/kasa-islemleri/kasa-sayimlari

Kasa Islemleri / Banknot Takipleri
  -> fiziksel para teslim takibi icin GET /api/kasa-islemleri/banknot-takipleri?dateToGet=...
  -> detay icin GET /api/kasa-islemleri/banknot-takipleri/{banknoteTrackId}
  -> kaydetmek icin POST /api/kasa-islemleri/banknot-takipleri

Kasa Islemleri / Kasa Cirolari
  -> liste filtreleri: tarih araligi, opsiyonel depo
  -> dashboard/ozet icin GET /api/kasa-islemleri/kasa-cirolari/toplam/ozet
  -> GET /api/kasa-islemleri/kasa-cirolari
  -> liste satirlarini CashTurnoverListItemDto ile goster
  -> kullanici satira tiklar
  -> GET /api/kasa-islemleri/kasa-cirolari/detay?businessDate=...&shiftNo=...&cashierCode=...
  -> detay ekraninda header ozetini ust kartta, odeme kirilimini alttaki gridde goster

Kasa Islemleri / Kasa Ciro Aktarimi
  -> eski TransferConsole ciro aktarimi icin GET /api/kasa-islemleri/kasa-ciro-aktarimi/subeler
  -> HRddMMyy.* dosyalarindan Turnover tablolarina yazmak icin POST /api/kasa-islemleri/kasa-ciro-aktarimi/metin/aktar
  -> import oncesi dryRun=true ile dosya parse sonucu ve insert/update adetleri gosterilebilir
  -> basarili importtan sonra sonuc Kasa Cirolari ekraninda eski/toplam kaynaklariyla izlenir

Kasa Islemleri / Kasa Hareket Aktarimi
  -> ekran acilisinda sube filtresi icin GET /api/kasa-islemleri/kasa-hareket-aktarimi/subeler
  -> kullanici sube secince kasa filtresi icin GET /api/kasa-islemleri/kasa-hareket-aktarimi/subeler/{branchNo}/kasalar; kasa tipi etiketi icin cashRegisterTypeName kullanilir
  -> HR hareket dosyalarini staging'e almak icin POST /api/kasa-islemleri/kasa-hareket-aktarimi/hareketler/aktar
  -> IP iptal dosyalarini staging'e almak icin POST /api/kasa-islemleri/kasa-hareket-aktarimi/iptal-belgeleri/aktar
  -> zamanli/gunluk toplu calistirma icin POST /api/kasa-islemleri/kasa-hareket-aktarimi/zamanli-aktarim/calistir
  -> import oncesi dryRun=true ile parse/lookup sonucu gosterilebilir
  -> rapor gridini doldurmak icin GET /api/kasa-islemleri/kasa-hareket-aktarimi/rapor?date=...
  -> rapor ust kartlari icin GET /api/kasa-islemleri/kasa-hareket-aktarimi/rapor/ozet?date=...
  -> raporu Excel uyumlu CSV indirmek icin GET /api/kasa-islemleri/kasa-hareket-aktarimi/rapor/excel?date=...
  -> icmal ile aktarim Z raporu karsilastirmasi icin GET /api/kasa-islemleri/kasa-hareket-aktarimi/icmal-karsilastirma?date=...
  -> icmal karsilastirmasini Excel uyumlu CSV indirmek icin GET /api/kasa-islemleri/kasa-hareket-aktarimi/icmal-karsilastirma/excel?date=...
  -> staging temizleme icin DELETE /api/kasa-islemleri/kasa-hareket-aktarimi/staging
  -> staging hareketlerini Mikro'ya yazmak icin POST /api/kasa-islemleri/kasa-hareket-aktarimi/mikro/aktar
  -> Mikro'ya yazilmis hareketleri silmek icin DELETE /api/kasa-islemleri/kasa-hareket-aktarimi/mikro
  -> tarih araligi toplu aktarim icin POST /api/kasa-islemleri/kasa-hareket-aktarimi/mikro/aralik-aktar
```

## Fatura Islemleri

Bu bolum 2026-07-06 tarihinde kaynak kod uzerinden yeniden dogrulanmistir.

Kodla dogrulanan ana dosyalar:

- `src/FurpaMerkezApi.WebApi/Controllers/Modules/FaturaIslemleri/FaturaGoruntuleme/FaturaGoruntulemeController.cs`
- `src/FurpaMerkezApi.Infrastructure/Modules/FaturaIslemleri/FaturaGoruntuleme/InvoiceViewingService.cs`
- `src/FurpaMerkezApi.Infrastructure/Modules/FaturaIslemleri/FaturaGoruntuleme/InvoiceViewingQueryExecutor.cs`
- `src/FurpaMerkezApi.Infrastructure/Modules/FaturaIslemleri/FaturaGoruntuleme/GetInvoiceViewingDocumentUseCase.cs`
- `src/FurpaMerkezApi.Infrastructure/Modules/FaturaIslemleri/FaturaGoruntuleme/RenderInvoiceViewingDocumentUseCase.cs`
- `src/FurpaMerkezApi.Infrastructure/Modules/FaturaIslemleri/FaturaGonderimi/InvoiceSendingService.cs`
- `src/FurpaMerkezApi.Infrastructure/Services/EInvoiceDocumentRenderer.cs`
- `src/FurpaMerkezApi.WebApi/Controllers/Modules/FaturaIslemleri/FaturaGonderimi/FaturaGonderimiController.cs`
- `src/FurpaMerkezApi.WebApi/Controllers/Modules/EntegrasyonIslemleri/UyumsoftEFatura/UyumsoftEFaturaController.cs`

Bu bolumde daha once karisiklik yaratan nokta, is kurali ile mevcut HTTP endpointlerinin ayni paragrafta ic ice anlatilmasiydi. 2026-05-06 itibariyla iki akis da API tarafinda ayri ayri temsil edilmektedir:

- `fatura-gonderimi`
  - Mikro tarafinda bekleyen e-fatura / e-arsiv kayitlarini listeler
  - secilen faturadan UBL invoice uretir
  - gonderilmemis faturalarin onizlemesi icin lokal HTML render eder
  - gonderilmis faturalarin resmi PDF'ini Uyumsoft outbox servisinden alir
  - secilen belgeleri Uyumsoft `SendInvoice` ile gonderir
  - basarili cevapta donen belge numarasini Mikro `cha_belge_no`, ETTN degerini `cha_uuid` alanina yazar ve kaydi kilitler
- `fatura-goruntuleme`
  - eski `Furpa.FaturaGoruntulemeWinUI` parity'sini korur; listeyi artik Auth/PostgreSQL icindeki `uyumsoft_inbox_invoices` cache tablosundan okur
  - varsayilan belge acmada Uyumsoft `GetInboxInvoicePdf` ile PDF datasini alir
  - HTML detay/render gerektiginde Uyumsoft `GetInboxInvoice` ile XML alip `XML -> XSLT -> HTML` render eder
  - gercek print/isaretleme ayrimini koruyup `isPrinted` durumunu ayri endpoint ile gunceller

UI tarafinda karistirilmamasi gereken net kural:

- `fatura-gonderimi`, giden faturalarin ekranidir. `isSent = false` satirlar lokal HTML onizleme, `isSent = true` satirlar Uyumsoft resmi PDF kullanir.
- Gonderilmis satirin PDF lookup anahtari once Mikro `cha_uuid` (ETTN), bu alan bossa geriye uyumluluk icin `cha_Guid` degeridir.
- `fatura-goruntuleme`, gelen/inbox faturalari ve cache listesidir. Giden fatura PDF aksiyonunun ana yolu degildir.

`fatura-gonderimi` tarafinda eldeki herhangi bir XML'i manuel preview etme endpoint'i ayrica acik tutulmustur.

### UI Icin Kisa Karar Agaci

Mevcut API'yi kullanarak ilerleyecekseniz akisi su sekilde okuyun:

1. Giden faturalari listelemek icin `GET /api/fatura-islemleri/fatura-gonderimi`
2. Liste varsayilan olarak `isSent=0` ile gonderilmemisleri getirir. `isSent=1` gonderilmis giden faturalar icindir.
3. Kullanici gonderilmemis (`isSent = false`) giden fatura satirinda lokal onizleme acmak istediginde:
   - default davranis yeterliyse `GET /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}?scenario=...`
   - XSLT secimini elle kontrol etmek istiyorsaniz `POST /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/render`
   - UI response icindeki yalnizca `document.htmlContent` alanini tek bir iframe/webview icinde render eder
   - UI ayrica QR/karekod uretmez; karekodun tek kaynagi secilen XSLT'nin urettigi HTML'dir
4. Kullanici gonderilmis (`isSent = true`) giden fatura satirini actiginda `GET /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/pdf?scenario=...` cagrilir ve `application/pdf` response blob olarak gosterilir.
5. Secilen gonderilmemis faturalarin gonderime hazir olup olmadigini canli gonderim yapmadan kontrol etmek icin `POST /api/fatura-islemleri/fatura-gonderimi/validate`
6. Kontrol sonucu uygunsa secilen gonderilmemis faturalari canli Uyumsoft'a gondermek icin `POST /api/fatura-islemleri/fatura-gonderimi/send`
   - `send` endpoint'i hiz icin `/validate` kontrolunu tekrar calistirmaz; UI "Kontrol Et" butonunu ayri aksiyon olarak sunmalidir
   - backend ayni belge icin eszamanli ikinci `send` istegini Uyumsoft'a gitmeden durdurur; UI bu durumda satir bazli hata mesajini gosterip ilk istegin sonucunu beklemelidir
   - daha once Uyumsoft'a gonderilmis fakat yeniden kuyruÃƒâ€Ã…Â¸a alinmasi gereken faturalar icin ayri olarak `POST /api/fatura-islemleri/fatura-gonderimi/retry` kullanilir
7. Gelen/inbox faturalari icin secilen tarih araligini Uyumsoft'tan cache tabloya almak gerekirse `POST /api/fatura-islemleri/fatura-goruntuleme/senkronize`
8. Gelen/inbox cache listesini okumak icin `GET /api/fatura-islemleri/fatura-goruntuleme`
9. Gelen/inbox resmi PDF icin `GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}` veya `/pdf` alias'i kullanilir.
10. Gelen/inbox HTML render/onizleme gerekiyorsa:
   - default davranis yeterliyse `GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}/detail`
   - XSLT secimini elle kontrol etmek istiyorsaniz `POST /api/fatura-islemleri/fatura-goruntuleme/{documentId}/render`
11. Gelen/inbox PDF/HTML gercekten yazdirildiktan veya acikca onaylandiktan sonra `PATCH /api/fatura-islemleri/fatura-goruntuleme/{documentId}/printed`
12. UI lokal veya baska bir kaynaktan XML uretip sadece goruntusunu gormek istiyorsa `POST /api/fatura-islemleri/fatura-gonderimi/preview`

Temel route'lar:

- `api/fatura-islemleri/fatura-goruntuleme`
- `api/fatura-islemleri/fatura-gonderimi`

Yetki kodlari:

- `fatura-islemleri.fatura-goruntuleme.list`
- `fatura-islemleri.fatura-goruntuleme.detail`
- `fatura-islemleri.fatura-goruntuleme.update`
- `fatura-islemleri.fatura-gonderimi.list`
- `fatura-islemleri.fatura-gonderimi.detail`
- `fatura-islemleri.fatura-gonderimi.create`

### Fatura Goruntuleme Liste

Legacy referansi:

- bu endpoint grubu eski `Furpa.FaturaGoruntulemeWinUI` moduluyle ayni cekirdek akisi korur
- ana pencere karsiligi `Faturalar` listesidir
- backend tarafindaki ana orkestrasyon `InvoiceViewingService.cs` icinde tutulur
- veri kaynagi sadece Furpa DB'deki `EFatura` tablosudur; Mikro'dan canli belge aramaz
- varsayilan belge acma tarafinda Uyumsoft `GetInboxInvoicePdf`, HTML detay/render tarafinda Uyumsoft `GetInboxInvoice` kullanilir
- yazdirma etkisi backend'de otomatik degil, acik `PATCH /printed` komutuna ayrilmistir

Not:

- yeni davranisla birlikte `GET /api/fatura-islemleri/fatura-goruntuleme` artik yalnizca DB/cache okur
- yeni eklendi: Uyumsoft tarih araligi senkronizasyonu ayri endpoint olan `POST /api/fatura-islemleri/fatura-goruntuleme/senkronize` ile yapilir
- arama metni veya net metin arama parametresi doluysa liste tarih filtresi uygulanmaz; fatura/irsaliye/ETTN no bilinen kayit tum cache icinde aranir

Kisa ornek:

`GET /api/fatura-islemleri/fatura-goruntuleme?StartDate=2026-05-01&EndDate=2026-05-05&isProcessed=-1&isPrinted=-1&invoiceId=KEF2026&page=1&PageSize=50`

Irsaliye no ile fatura bulma:

`GET /api/fatura-islemleri/fatura-goruntuleme?StartDate=2026-07-01&EndDate=2026-07-31&despatchId=KEI2026000004237`

Geriye uyumlu ornek:

`GET /api/fatura-islemleri/fatura-goruntuleme?StartDate=2026-05-01&EndDate=2026-05-05&ProcessedState=-1&PrintedState=-1&SearchField=InvoiceId&SearchText=INV-2026&PageNumber=1&PageSize=50`

Arama metnini tarih araligiyla birlikte daraltma:

`GET /api/fatura-islemleri/fatura-goruntuleme?StartDate=2026-05-01&EndDate=2026-05-05&SearchField=InvoiceId&SearchText=INV-2026&applyDateFilterWithSearch=true`

Yetki:

- `fatura-islemleri.fatura-goruntuleme.list`

Query:

```text
StartDate       zorunlu
EndDate         zorunlu
isProcessed     opsiyonel; UI icin onerilen alias, -1=tumu, 1=true, 0=false
ProcessedState  opsiyonel; legacy alias, -1=tumu, 1=true, 0=false
isPrinted       opsiyonel; UI icin onerilen alias, -1=tumu, 1=true, 0=false
PrintedState    opsiyonel; legacy alias, -1=tumu, 1=true, 0=false
invoiceId       opsiyonel; fatura no/resmi belge no contains arama. Alias: invoiceNo
despatchId      opsiyonel; irsaliye no contains arama. Alias: despatchNo
customerTitle   opsiyonel; musteri/tedarikci unvani contains arama
customerTcknVkn opsiyonel; VKN/TCKN contains arama. Alias: tcknVkn
documentId      opsiyonel; Uyumsoft teknik UUID/ETTN contains arama. Alias: ettn
orderDocumentId opsiyonel; siparis/order referansi contains arama
status          opsiyonel; status, statusCode veya envelopeStatusCode icinde contains arama
invoiceType     opsiyonel; fatura tipi contains arama
minInvoiceTotal opsiyonel; toplam tutar alt siniri
maxInvoiceTotal opsiyonel; toplam tutar ust siniri
hasDespatchId   opsiyonel; true=irsaliyeli faturalar, false=irsaliye no bos olanlar
SearchField     opsiyonel; InvoiceDate, InvoiceId, DocumentId, CustomerTitle, CustomerTcknVkn, InvoiceTotal, DespatchId, Any, Status, InvoiceType, EnvelopeIdentifier, OrderDocumentId, Message
SearchText      opsiyonel; SearchField verilmezse genel arama olarak uygulanir
applyDateFilterWithSearch opsiyonel; default false. true ise arama/structured filtreler dolu olsa bile StartDate/EndDate de uygulanir. Alias: useDateFilterWithSearch
page            opsiyonel; UI icin onerilen alias, default 1
PageNumber      opsiyonel; default 1
PageSize        opsiyonel; geriye uyumluluk icin kabul edilir, liste sonucu artik PageSize ile kesilmez
```

UI notu:

- yeni UI gelistirmelerinde `isProcessed`, `isPrinted` ve `page` kullanilmasi tavsiye edilir
- eski istemciler icin `ProcessedState`, `PrintedState` ve `PageNumber` hala desteklenir
- ayni request'te hem yeni hem eski alias gonderilirse yeni aliaslar (`isProcessed`, `isPrinted`, `page`) oncelikli kabul edilir
- arama alani bossa listeleme `StartDate` / `EndDate` araligina gore yapilir.
- `SearchText`, `invoiceId/invoiceNo`, `despatchId/despatchNo`, `customerTitle`, `customerTcknVkn/tcknVkn`, `documentId/ettn`, `orderDocumentId`, `status` veya `invoiceType` doluysa varsayilan olarak tarih filtresi devre disi kalir; bu eski hizli belge bulma davranisidir.
- Kullanici "tarih icinde ara" isterse UI `applyDateFilterWithSearch=true` gondermelidir. Bu durumda once `StartDate` / `EndDate` araligi uygulanir, sonra arama ve diger filtreler uygulanir.
- filtreleme iki asamali dusunulmelidir:
  - backend filtreleri tarih araligindaki genis veri setini daraltir ve DB/cache uzerinden calisir
  - frontend/grid filtreleri backend'den donen aday set uzerinde anlik lokal filtreleme yapar
- kullanici elindeki irsaliye, fatura no, VKN/TCKN veya unvanla fatura bulacaksa once backend'e ilgili net query parametresi gonderilmelidir; UI ekrani bunun uzerine lokal filtre uygulayabilir

Response `InvoiceViewingListResponse`:

```json
{
  "totalCount": 245,
  "pageNumber": 1,
  "pageSize": 245,
  "items": [
    {
      "documentId": "9d6e0f84-3d3c-4c58-a1b0-4c0f8f4fd999",
      "invoiceId": "FRM2026600075612",
      "customerTitle": "ORNEK MUSTERI",
      "customerTcknVkn": "1234567890",
      "createDate": "2026-05-01T09:15:00",
      "invoiceDate": "2026-05-01T00:00:00",
      "invoiceType": "SATIS",
      "invoiceTotal": 1250.75,
      "despatchId": "",
      "isProcessed": true,
      "isPrinted": false,
      "isStandard": false,
      "statusCode": "1000",
      "status": "Onaylandi",
      "envelopeIdentifier": "urn:mail:...",
      "envelopeStatusCode": "1000",
      "message": "",
      "taxTotal": 250.15,
      "taxExclusiveAmount": 1000.60,
      "documentCurrencyCode": "TRY",
      "exchangeRate": 1,
      "orderDocumentId": "IRS202600001",
      "isArchived": false,
      "invoiceTipType": "Temel",
      "invoiceTipTypeCode": 0,
      "isSeen": true
    }
  ]
}
```

Liste davranisi:

- temel kaynak Auth/PostgreSQL icindeki `uyumsoft_inbox_invoices` tablosudur
- `GET /api/fatura-islemleri/fatura-goruntuleme` otomatik Uyumsoft cagrisi yapmaz; sadece lokal cache/DB sonucunu doner
- yeni eklendi: `POST /api/fatura-islemleri/fatura-goruntuleme/senkronize` endpoint'i secilen tarih araligini Uyumsoft `GetInboxInvoices` operasyonu ile cache tabloya upsert eder
- legacy `GetInvoicesAsync(isProcessed, isPrinted)` akisindaki gibi tarih + islenme + yazdirilma filtresi uygulanir
- arama kriteri doluysa tarih kosulu uygulanmaz; `isProcessed` ve `isPrinted` filtreleri yine uygulanmaya devam eder
- `invoiceDate` Uyumsoft full UBL icindeki `Invoice.IssueDate` (Fatura Tarihi) alanindan, `createDate` ise `InvoiceInfo.CreateDateUtc` alanindan doldurulur
- Uyumsoft kaynak sorgusu teknik olarak `ExecutionStartDate` / `ExecutionEndDate` ile calisir; bu nedenle senkronizasyon Uyumsoft'u secilen bitis tarihinden sonra da konfigurasyon kadar ileri tarar, cache'e alinacak asil is kaydi ise sonradan `invoiceDate` / Fatura Tarihi ile daraltilir
- senkron request'indeki tarih araligi Uyumsoft'tan cekilen kayitlara `invoiceDate` uzerinden tekrar uygulanir; bu nedenle DB'ye yalnizca Fatura Tarihi secilen aralikta olan belgeler yazilir
- liste tarih filtresi `invoiceDate` veya bu alan yoksa fallback olarak `createDate` alanina uygulanir
- tarih araligi gun seviyesindedir; bitis tarihi SQL tarafinda `+1 gun exclusive` mantigi ile uygulanir
- `documentId` bu listedeki Uyumsoft teknik UUID/operasyon anahtaridir; UI row key, PDF, detay, render ve printed isteklerinde bunu aynen kullanir
- `invoiceId` kullaniciya gosterilecek resmi fatura numarasidir; route parametresi olarak kullanilmaz
- `ProcessedState` ve `PrintedState` legacy WinForms'taki gibi tri-state filtre davranisi saglar
- `customerTitle` response'a buyuk harfe cevrilmis gelir
- DB tarafindaki kolon `isStandart` olsa da API response'unda alan `isStandard` olarak gelir
- `statusCode`, `status`, `envelopeStatusCode` ve durum `message` alani `includeStatuses=true` senkronizasyonunda Uyumsoft `GetInboxInvoiceStatusWithLogs` cevabindan cache'e yazilir
- `statusCode` ham Uyumsoft durum kodudur; `status` ise Uyumsoft durum enum'undan Turkce UI metnine cevrilir ve ekranda direkt gosterilebilir
- `despatchId` yalnizca Uyumsoft `GetInboxInvoices` full UBL cevabindaki `Invoice.DespatchDocumentReference[].ID` alanindan okunur; senkron sirasinda kayit basina ek `GetInboxInvoice` cagrisi yapilmaz
- `orderDocumentId` ayri siparis/order referansi alanidir; irsaliye numarasi gibi kullanilmamalidir
- `orderDocumentId`, `envelopeIdentifier`, `message`, vergi toplam/tutar, doviz, arsiv ve goruldu bilgileri Uyumsoft inbox cache tablosunda ayrica saklanir
- temel `status` mapping'leri:
  - `NotPrepared` -> `Hazirlanmadi`
  - `NotSend` -> `Gonderilmedi`
  - `Draft` -> `Taslak`
  - `Canceled` -> `Iptal Edildi`
  - `Queued` -> `Kuyrukta`
  - `Processing` -> `Isleniyor`
  - `SentToGib` -> `GIB'e Gonderildi`
  - `Approved` / `1000` -> `Onaylandi`
  - `WaitingForAprovement` / `1100` -> `Onay Bekliyor`
  - `Declined` / `1200` -> `Reddedildi`
  - `Return` / `1300` -> `Iade Edildi`
  - `EArchivedCanceled` / `1400` -> `E-Arsiv Iptal`
  - `Error` / `2000` -> `Hata`
- eski/eksik cache kayitlarinda `status` bos ise kod tabanli fallback mapping'i kullanilir:
  - `1000` -> `Onaylandi`
  - `1100` -> `Onay Bekliyor`
  - `1200` -> `Reddedildi`
  - `1300` -> `Iade Edildi`
  - `1400` -> `E-Arsiv Iptal`
  - diger -> `Bilinmiyor`
- SQL tarafinda processed + printed + net query filtreleri uygulanir; tarih filtresi yalnizca net metin arama kriteri yoksa eklenir:
  - `invoiceId` / `invoiceNo`
  - `despatchId` / `despatchNo`
  - `customerTitle`
  - `customerTcknVkn` / `tcknVkn`
  - `documentId` / `ettn`
  - `orderDocumentId`
  - `status`
  - `invoiceType`
  - `minInvoiceTotal`, `maxInvoiceTotal`
  - `hasDespatchId`
- `SearchField`/`SearchText` ikinci backend arama katmanidir; kayitlar materialize edilmeden once DB/SQL tarafinda uygulanir:
  - `InvoiceDate` -> exact date
  - `InvoiceId` -> contains, case-insensitive
  - `DocumentId` -> contains, case-insensitive
  - `CustomerTitle` -> contains, case-insensitive
  - `CustomerTcknVkn` -> contains
  - `InvoiceTotal` -> exact decimal
  - `DespatchId` -> contains, case-insensitive
  - `Status` -> `status`, `statusCode`, `envelopeStatusCode` icinde contains
  - `InvoiceType`, `EnvelopeIdentifier`, `OrderDocumentId`, `Message` -> contains
  - `Any` veya bos `SearchField` -> temel metin alanlari + tarih/toplam yakalarsa exact karsilastirma
- paging limiti kaldirilmistir; endpoint tarih/processed/printed/search sonucunun tamamini doner, response'ta `pageNumber=1` ve `pageSize=totalCount` gelir
- bu, WinUI'daki `invoiceList` / `filteredList` mantiginin API karsiligidir
- eski WinUI'daki Excel export davranisi bu endpoint grubuna server-side olarak tasinmamistir; export ihtiyaci varsa UI kendi yukledigi veriyi kullanmali veya ayrica export endpoint'i tasarlanmalidir

### Fatura Goruntuleme Manuel Senkronizasyon

Yeni eklendi:

- bu endpoint listeyi donmez; yalnizca secilen tarih araligini Uyumsoft'tan cache tabloya senkronize eder
- UI tarafinda tipik akis `POST /senkronize`, `GET /senkronize/progress` ile izleme, tamamlaninca `GET /fatura-goruntuleme` seklinde olmalidir
- `POST /senkronize` uzun HTTP istegi olarak beklemez; isi arka plana alir ve hemen `202 Accepted` doner

`POST /api/fatura-islemleri/fatura-goruntuleme/senkronize`

Yetki:

- `fatura-islemleri.fatura-goruntuleme.list`

Request body:

```json
{
  "startDate": "2026-05-01",
  "endDate": "2026-05-05",
  "includeStatuses": false
}
```

Not: `includeStatuses` gonderilmezse varsayilan `false` kabul edilir.

Response `202 Accepted`:

```json
{
  "isRunning": true,
  "status": "queued",
  "startDate": "2026-05-01T00:00:00",
  "endDate": "2026-05-05T00:00:00",
  "includeStatuses": false,
  "queryStartDate": null,
  "queryEndDate": null,
  "pageIndex": 0,
  "pageNumber": 0,
  "pageSize": 20,
  "totalCount": 0,
  "totalPage": 0,
  "fetchedCount": 0,
  "matchedCount": 0,
  "insertedCount": 0,
  "updatedCount": 0,
  "lastPageItemCount": 0,
  "lastPageMatchedCount": 0,
  "lastPageInsertedCount": 0,
  "lastPageUpdatedCount": 0,
  "progressPercent": 0,
  "startedAtUtc": "2026-07-17T12:30:00Z",
  "lastUpdatedAtUtc": "2026-07-17T12:30:00Z",
  "finishedAtUtc": null,
  "elapsedMs": 0,
  "message": "Senkronizasyon siraya alindi."
}
```

Progress endpoint:

`GET /api/fatura-islemleri/fatura-goruntuleme/senkronize/progress`

Yetki:

- `fatura-islemleri.fatura-goruntuleme.list`

Response `200 OK`:

```json
{
  "isRunning": true,
  "status": "running",
  "startDate": "2026-07-16T00:00:00",
  "endDate": "2026-07-16T00:00:00",
  "includeStatuses": false,
  "queryStartDate": "2026-07-16T00:00:00",
  "queryEndDate": "2026-07-17T00:00:00",
  "pageIndex": 18,
  "pageNumber": 19,
  "pageSize": 20,
  "totalCount": 445,
  "totalPage": 23,
  "fetchedCount": 380,
  "matchedCount": 130,
  "insertedCount": 3,
  "updatedCount": 127,
  "lastPageItemCount": 20,
  "lastPageMatchedCount": 6,
  "lastPageInsertedCount": 0,
  "lastPageUpdatedCount": 6,
  "progressPercent": 82.61,
  "startedAtUtc": "2026-07-17T08:30:00Z",
  "lastUpdatedAtUtc": "2026-07-17T08:31:15Z",
  "finishedAtUtc": null,
  "elapsedMs": 75000,
  "message": "Sayfa 19/23 islendi."
}
```

UI akis onerisi:

- `POST /senkronize` `202 Accepted` donunce ekranda loading/progress paneli acilir
- UI her 1-2 saniyede bir `GET /senkronize/progress` cagirir
- `status=queued` veya `status=running` iken `progressPercent`, `pageNumber/totalPage`, `fetchedCount`, `matchedCount`, `insertedCount`, `updatedCount` gosterilebilir
- `status=completed` veya `status=failed` oldugunda polling durdurulur
- final `sourceTotalCount/fetchedCount/matchedCount/insertedCount/updatedCount` bilgisi artik progress response'undaki `completed` durumunda okunur
- progress bilgisi API process hafizasinda tutulur; API yeniden baslarsa `idle` durumuna doner

UI hata yonetimi notu:

- Uyumsoft'a giden senkronizasyon, PDF, detail/render, gonderim/retry ve e-irsaliye PDF isteklerinde dis servis hatalari standart `ProblemDetails` olarak doner
- `502 Bad Gateway`: API Uyumsoft servisine baglanti kuramadi veya upstream HTTP istegi basarisiz oldu; UI bunu genel backend hatasi gibi degil "Uyumsoft servisine ulasilamiyor" olarak gostermelidir
- `504 Gateway Timeout`: Uyumsoft istegi zaman asimina ugradi; UI kullaniciya tekrar deneme, daha kucuk tarih araligi secme veya daha sonra deneme mesaji vermelidir
- `500 Internal Server Error`: beklenmeyen backend hatasi olarak ele alinmalidir; Uyumsoft baglanti/zaman asimi icin birincil durum artik 502/504'tur
- UI hata mesajini `ProblemDetails.detail` alanindan okumali, destek/log takibi icin `ProblemDetails.extensions.correlationId` degerini saklamali veya ekranda kopyalanabilir gostermelidir
- `GET /senkronize/progress` response'unda `status=failed` ise UI `message` alanini kullaniciya gostermeli ve polling'i durdurmalidir

Davranis:

- secilen tarih araligi UI ve DB icin Fatura Tarihi araligidir; Uyumsoft sorgusu ise `ExecutionStartDate = startDate`, `ExecutionEndDate = min(endDate + FaturaGoruntuleme:SynchronizationExecutionLookAheadDays gun sonu, API sunucusunun su anki zamani)` olarak calisir
- varsayilan ileri bakis degeri `15` gundur; maksimum `60` gunle sinirlandirilir
- bunun sebebi Uyumsoft'ta Fatura Tarihi 16.07.2026 olan kaydin, `CreateDateUtc` veya SOAP execution sayfasi 17.07.2026 icinde donebilmesidir
- Uyumsoft sayfalari `PageIndex = 0, 1, 2...` ve `PageSize = 20` ile `TotalPages` tamamlanana kadar okunur
- her Uyumsoft sayfasi alindiginda kayitlar once `invoiceDate` / Fatura Tarihi araligina gore suzulur, sonra ilgili sayfa hemen cache tabloya upsert edilir
- `includeStatuses=false` ise hizli mod kullanilir; sayfa basina ek `GetInboxInvoiceStatusWithLogs` cagrisi yapilmaz
- `includeStatuses=false` hizli modunda mevcut cache kaydindaki `statusCode`, `status`, `envelopeStatusCode`, `envelopeIdentifier` ve `message` alanlari bos veriyle ezilmez
- `includeStatuses=true` ise her 20 kayitlik sayfa icin fatura durumlari tek toplu `GetInboxInvoiceStatusWithLogs` istegiyle okunur; fatura basina ayri durum cagrisi yapilmaz
- `includeStatuses=true` iken `statusCode`, `status`, `envelopeStatusCode` ve durum mesaji bu toplu durum cevabiyla cache'e yazilir; daha once bos kaydedilmis durumlar sonraki senkronizasyonda guncellenir
- tum sayfalar eksiksiz alindiginda progress `status=completed` olur; Uyumsoft timeout olursa progress `status=failed` olur ama onceki sayfalarda Fatura Tarihi araligina uyan kayitlar cache'e yazilmis olabilir
- `includeStatuses=true` iken Uyumsoft bir faturaya ait durum bilgisini dondurmezse senkronizasyon eksik veriyi basarili saymaz ve progress `status=failed` olur
- gelen sonuc `uyumsoft_inbox_invoices` cache tablosuna upsert edilir
- `sourceTotalCount` Uyumsoft'un genisletilmis execution penceresinde bildirdigi toplam kayit, `fetchedCount` tum sayfalardan gercekten okunan kayit sayisi, `matchedCount` ise secilen Fatura Tarihi araligina uyup cache'e aday olan tekil kayit sayisidir
- Uyumsoft cagrisi basarisiz olursa progress `status=failed` olur; sessiz basarili sayilmaz
- Uyumsoft zaman asiminda progress `status=failed` olur; UI kullaniciya daha kucuk tarih araligi denemesini onermelidir
- Uyumsoft e-fatura WCF timeout degeri `EInvoice:TimeoutSeconds` konfigurasyonuyla yonetilir; varsayilan appsettings degeri `360` saniyedir
- backend her Uyumsoft sayfasi icin page index, page size, item count, total count, total page ve sure bilgisini loglar; ayrica Fatura Tarihi araligina uyan `MatchedItems` / `MatchedTotal` ve sayfa upsert sayilari loglanir
- timeout durumunda ayni tarih araligiyla tekrar `POST /senkronize` calistirilirse onceki denemede cache'e yazilmis sayfalar korunur, eksik kalan sayfalardan gelen kayitlar guncellenerek devam eder
- tekrar eden veya degisiklik icermeyen sayfalar icin koruma vardir; sonsuz donguye girmez
- sync tamamlandiktan sonra UI ayni tarih araligiyla `GET /api/fatura-islemleri/fatura-goruntuleme` cagirip DB sonucunu alabilir
- hizli liste yenileme icin UI `includeStatuses=false` kullanmali; kesin durum/log yenilemesi gereken aksiyonlarda `includeStatuses=true` tercih edilmelidir

### Fatura Goruntuleme PDF

`GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}`

Alias:

`GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}/pdf`

Yetki:

- `fatura-islemleri.fatura-goruntuleme.detail`

Response:

- `Content-Type: application/pdf`
- Backend Uyumsoft e-fatura `GetInboxInvoicePdf` operasyonunu `invoiceId = documentId` parametresiyle cagirir.
- Uyumsoft cevabindaki PDF byte dizisi normalize edilir; gecerli `%PDF` imzasi yoksa hata doner.
- JSON beklenmemelidir; UI yeni sekme, iframe veya blob URL ile dogrudan PDF gosterebilir.

UI uygulama kurali:

- `row.documentId` -> teknik UUID -> route'a gonderilir
- `row.invoiceId` -> resmi fatura numarasi -> ekranda gosterilir
- UI `row.invoiceId` degerini PDF URL'sine yazmaz
- UI fatura numarasindan teknik UUID/PDF route'u uretmeye calismaz
- `row.documentId` bos ise PDF butonu pasif olur ve veri/entegrasyon hatasi gosterilir

Bu endpoint ne icin kullanilmali:

- kullanici liste satirina tiklayip faturanin resmi PDF'ini acmak istediginde
- fatura goruntuleme ekraninda varsayilan belge acma aksiyonu icin

Frontend ornegi:

```ts
const pdfPath =
  `/api/fatura-islemleri/fatura-goruntuleme/` +
  `${encodeURIComponent(row.documentId)}/pdf`;
```

Bu endpoint ne yapmaz:

- `isPrinted` alanini kendiliginden guncellemez
- kullanicinin "yazdirildi" karari yerine gecmez

### Fatura Goruntuleme HTML Detay

`GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}/detail`

Ornek:

```http
GET /api/fatura-islemleri/fatura-goruntuleme/78644214-ce3b-4976-9fc3-d5de0d7cfe7e/detail
Authorization: Bearer {accessToken}
```

Yetki:

- `fatura-islemleri.fatura-goruntuleme.detail`

Response `InvoiceViewingDetailDto`:

- `summary`: liste satirinin ayni DTO'su
- `document`: render edilmis belge (`InvoiceRenderedDocumentDto`)

Bu endpoint ne icin kullanilmali:

- kullanici liste satirina cift tikladiginda veya "incele" dediginde
- ekstra XSLT override ihtiyaci yoksa
- default render davranisi yeterliyse

Bu endpoint ne yapmaz:

- `isPrinted` alanini kendiliginden guncellemez
- kullanicinin "yazdirildi" karari yerine gecmez
- Uyumsoft outbox belgesini acmaz; bu endpoint inbox/goruntuleme akisidir

Detay davranisi:

- public lookup key `documentId`'dir
- API once `uyumsoft_inbox_invoices` cache kaynagindan satiri bulur; satir yoksa Uyumsoft'tan tekil senkron denemesi yapar
- sonra legacy semantige uygun olarak ayni satirin `documentId` degerini Uyumsoft `GetInboxInvoice` cagrisinda lookup parametresi olarak kullanir
- bu akis eski `FaturaGoruntuleyici` formunun `documentId` bazli acilisina karsilik gelir
- UI HTML donusumunu kendi icinde yapmaz; backend'den gelen `htmlContent` dogrudan gosterilir
- backend HTML'e yeni bir QR/SVG eklemez; karekod sadece Uyumsoft belgesindeki embedded XSLT veya fallback XSLT tarafindan uretilir
- UI `document.htmlContent` alanini yalniz bir kez render eder ve ayrica QR kutuphanesi calistirmaz
- `xmlContent` debug, inceleme veya kaynak belge sekmesi icin kullanilabilir
- `summary.invoiceId` ve `document.invoiceId` kullanicinin gordugu fatura numarasidir; detay acma anahtari yine `documentId` olarak kalir
- bu endpoint legacy'deki cift-tik onizlemesine karsilik gelir; tek basina `isPrinted` update etmez
- response icindeki `document.source` bu modulde `inbox` olur; outbox/onizleme akislari `fatura-gonderimi` altinda ayridir

### Fatura Goruntuleme Render

`POST /api/fatura-islemleri/fatura-goruntuleme/{documentId}/render`

Yetki:

- `fatura-islemleri.fatura-goruntuleme.detail`

Bu endpoint ne zaman lazim:

- default `GET detail` davranisini override etmek istiyorsaniz
- embedded XSLT denenip denenmeyecegini UI tarafinda secmek istiyorsaniz
- "embedded yoksa default tasarima don" kararini acik body ile vermek istiyorsaniz

Request:

```json
{
  "profile": "Auto",
  "preferEmbeddedXslt": true,
  "fallbackToGeneral": true
}
```

Alan anlami:

- `profile`:
  - `Auto`: belge icinden profile algilanir
  - `EFatura`: e-fatura asset'ini zorlar
  - `EArsiv`: e-arsiv asset'ini zorlar
- `preferEmbeddedXslt`:
  - `null` veya bos gonderilirse backend karar verir
  - backend varsayilan kurali:
    - `isStandard = true` ise embedded aranmaz
    - `isStandard = false` ise once embedded denenir
- `fallbackToGeneral`:
  - `true` ise embedded bulunamazsa backend asset fallback'i kullanilir
  - `false` ise embedded bulunamazsa hata donmesi beklenir

Response:

- `GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}/detail` ile ayni `InvoiceViewingDetailDto`

UI notu:

- sadece belgeyi gostermek istiyorsaniz genelde `GET detail` yeterlidir
- bu endpoint daha cok "render ayarlarini elle kontrol eden gelismis UI" ihtiyaci icindir
- WinUI parity'sinde bu endpoint, `ShowInvoice(...)` tarafindaki XSLT secim davranisini backend uzerinden elle yonetebilmek icin vardir

### Fatura Goruntuleme Yazdirma ve Yazdirildi Durumu

`PATCH /api/fatura-islemleri/fatura-goruntuleme/{documentId}/printed`

Yetki:

- `fatura-islemleri.fatura-goruntuleme.update`

Request:

```json
{
  "isPrinted": true,
  "source": "preview-click"
}
```

Response `InvoiceViewingPrintedStateResponse`:

```json
{
  "summary": {
    "documentId": "DOC-001",
    "invoiceId": "INV-2026-0001",
    "customerTitle": "ORNEK MUSTERI",
    "customerTcknVkn": "1234567890",
    "createDate": "2026-05-01T09:15:00",
    "invoiceDate": "2026-05-01T00:00:00",
    "invoiceType": "SATIS",
    "invoiceTotal": 1250.75,
    "despatchId": "",
    "isProcessed": true,
    "isPrinted": true,
    "isStandard": false,
    "statusCode": "1000",
    "status": "Onaylandi"
  },
  "source": "preview-click"
}
```

Komut davranisi:

- bu endpoint legacy `statusOfPrinted` kolon tiklamasindaki kalici yan etkiyi API'ye acik komut olarak tasir
- eski WinUI akisinda belge servisden alinip goruntuleme/yazdirma tetiklenir ve yerel `EFatura.isPrinted` guncellenirdi
- yeni API tasariminda gercek print davranisi backend tarafinda simule edilmez; backend yalniz kalici `isPrinted` durumunu yazar
- satira cift tiklayip detay acmak artik kendiliginden `isPrinted` guncellemez
- UI tarafinda sadece kullanici gercekten "yazdirildi say" aksiyonunu verdiginde cagrilmalidir
- iyi UI akisi sudur:
  - once `GET /{documentId}` PDF, `GET /{documentId}/detail` HTML veya `POST render`
  - sonra PDF ya da `document.htmlContent` UI tarafinda gosterilir ve gercek print UI tarafinda tetiklenir
  - sonra kullanici acikca onaylarsa `PATCH /printed`
- response icindeki `summary` guncel DB durumunu geri doner; UI ayrica listeyi tekrar cekmeden satiri yerinde guncelleyebilir
- eski WinUI'daki gibi "yazdirilmamis" filtresinde satiri listeden dusurmek istiyorsaniz bu karar UI tarafinda verilir; backend otomatik satir silmez

### Fatura Goruntuleme Render Kurallari

- `GET /{documentId}/detail` endpoint'i `preferEmbeddedXslt` kararini kendisi verir:
  - `isStandard = true` ise legacy `Properties.Resources.general` davranisina denk olarak embedded XSLT aranmaz
  - `isStandard = false` ise once embedded XSLT denenir
- `POST render` endpoint'i ise bu karari request body'si ile override etmenize izin verir
- embedded tarama `AdditionalDocumentReference` altindaki `EmbeddedDocumentBinaryObject` dugumlerinde yapilir
- `.xslt` ve `.xsl` uzantili, veya mime icinde `xsl` gecen ekler aday kabul edilir
- embedded icerik gerekiyorsa base64 decode edilip XSLT oldugu dogrulanir
- embedded tasarim bulunursa `usedEmbeddedXslt = true` olur
- embedded tasarim bulunamazsa `Assets/Xslt/efatura.xslt` veya `Assets/Xslt/earsiv.xslt` fallback olarak kullanilir
- `profile = Auto` ise belge icinden `ProfileID` / `ScenarioId` / `DocumentTypeCode` okunarak `EFatura` veya `EArsiv` secilir
- renderer XSLT sonucuna ikinci bir QR eklemez; `fatura-goruntuleme/detail`, `fatura-goruntuleme/render`, `fatura-gonderimi/detail`, `fatura-gonderimi/render` ve XML preview ayni ortak kurala tabidir
- yani legacy'deki "custom varsa onu kullan, yoksa genel fallback" mantigi korunmustur; fark su ki fallback artik backend asset dosyalariyla uygulanir

### Fatura Goruntuleme WinUI Parity Notlari

- liste kaynagi yalnizca Uyumsoft inbox metadata'sinin yerel cache'idir; bu modulde Mikro tarafindan canli belge aramasi yapilmaz
- yeni eklendi: liste endpoint'i ile manuel Uyumsoft sync endpoint'i ayrilmistir; UI ihtiyaca gore once sync sonra liste akisini kurmalidir
- eski WinForms'taki "tum filtreli seti alip sonra arama/sayfalama yap" davranisi buyuk oranda korunmustur; sadece bu mantik artik API katmani icinde calisir
- varsayilan PDF akisi Uyumsoft `GetInboxInvoicePdf`, HTML detay/render akisi Uyumsoft `GetInboxInvoice` tarafidir; bu modulde outbox okunmaz
- eski UI'daki `invoiceDate.Value` null riski yerine API null `invoiceDate` satirlarini tarih listesine dahil etmez
- `ClientGenerator` benzeri alternatif istemci secimi artik UI sorunu degildir; backend config tabanli entegrasyon servisi kullanir
- legacy'deki hardcoded WCF credential'i yeni backend'de config tabanli hale getirilmistir; secret UI'ya sizmaz
- export davranisi UI tarafinda ayrica ele alinmalidir; mevcut API listeyi sayfalayarak doner
- eski `FaturaPdfGoruntuleyici` / `WaitForPrint` yardimci formlarinin bire bir API endpoint karsiligi yoktur; bunlar UI davranisi olarak ele alinmalidir

### Fatura Gonderimi Liste

`GET /api/fatura-islemleri/fatura-gonderimi?StartDate=2026-05-01&EndDate=2026-05-05&Scenario=EFatura&isSent=0`

Yetki:

- `fatura-islemleri.fatura-gonderimi.list`

Query:

```text
StartDate   zorunlu
EndDate     zorunlu
Scenario    opsiyonel; EFatura veya EArsiv, default EFatura
isSent      opsiyonel; UI icin onerilen alias, -1=tumu, 1=gonderilenler, 0=gonderilmeyenler
SentState   opsiyonel; legacy alias, default 0
```

Response `InvoiceSendingListResponse`:

```json
{
  "totalCount": 2,
  "items": [
    {
      "documentSerie": "FAT",
      "documentOrderNo": 12345,
      "invoiceId": "FAT2026000012345",
      "documentDate": "2026-05-05T00:00:00",
      "sentDocumentNo": "",
      "isSent": false,
      "customerCode": "120001",
      "customerTitle": "ORNEK MUSTERI",
      "customerTcknVkn": "1234567890",
      "targetAlias": "urn:mail:ornek@firma.com",
      "invoiceProfileId": "TICARIFATURA",
      "invoiceTypeCode": "SATIS",
      "scenario": 0,
      "lineExtensionTotal": 1000.00,
      "taxTotal": 180.00,
      "chargeTotal": 0.00,
      "payableTotal": 1180.00,
      "shipmentDocumentNo": "",
      "shipmentDocumentDate": null,
      "returnInvoiceNo": "",
      "returnInvoiceDate": null,
      "warehouseName": "",
      "description": "Aciklama",
      "sourceLineCount": 1,
      "sourceLineSummary": "",
      "taxRateSummary": "%20.00"
    },
    {
      "documentSerie": "FRP",
      "documentOrderNo": 21645,
      "invoiceId": "FRP2026000021645",
      "documentDate": "2026-06-18T00:00:00",
      "sentDocumentNo": "FRM2026600076468",
      "isSent": true,
      "customerCode": "120002",
      "customerTitle": "GONDERILMIS MUSTERI",
      "customerTcknVkn": "1234567890",
      "targetAlias": "urn:mail:gonderilmis@firma.com",
      "invoiceProfileId": "TICARIFATURA",
      "invoiceTypeCode": "SATIS",
      "scenario": 0,
      "lineExtensionTotal": 1000.00,
      "taxTotal": 180.00,
      "chargeTotal": 0.00,
      "payableTotal": 1180.00,
      "shipmentDocumentNo": "",
      "shipmentDocumentDate": null,
      "returnInvoiceNo": "",
      "returnInvoiceDate": null,
      "warehouseName": "MERKEZ DEPO",
      "description": "",
      "sourceLineCount": 2,
      "sourceLineSummary": "0056 - CIRO PRIMI GELIRI % 20 | 0055 - CIRO PRIMI GELIRI % 10",
      "taxRateSummary": "%20.00 | %10.00"
    }
  ]
}
```

Davranis:

- kaynak veri Mikro `CARI_HESAP_HAREKETLERI`, `CARI_HESAPLAR`, `CARI_HESAP_ADRESLERI` ve `Furpa.dbo.FaturaSeries` ustunden okunur
- `Scenario = EFatura` icin yalniz e-fatura mukellefi ve e-fatura serisine bagli kayitlar gelir
- `Scenario = EArsiv` icin yalniz e-arsiv tarafina dusen kayitlar gelir
- `InvoiceSendingScenario` JSON response/body degeri sayisaldir: `0 = EFatura`, `1 = EArsiv`; query string tarafinda `EFatura` / `EArsiv` adlari da kullanilabilir
- `isSent/SentState = 0` ise `cha_belge_no` bos olan kayitlar, `1` ise dolu olan kayitlar, `-1` ise tumu doner
- `invoiceId` legacy WinForms mantigina uygun sekilde `seri + yil + 9 haneli sira` olarak uretilir
- `invoiceId`, UBL icindeki `cbc:ID` degeridir; PDF endpoint path'i icin bunun yerine `documentSerie` ve `documentOrderNo` kullanilir
- `sentDocumentNo` Mikro `cha_belge_no` alanidir; gonderim sonrasi kullaniciya gosterilen resmi belge numarasidir

Performans notlari:

- Liste endpoint'i hiz icin hafif modda calisir. Faturaya bagli sevkiyat/depo bilgisi, stok satiri istisna aramasi, iade referansi lookup'i, hizmet/demirbas satir ozeti ve KDV oran ozeti liste sirasinda hesaplanmaz.
- Bu agir alanlar detay/render/validate/send gibi belge odakli akislar sirasinda tam modda hesaplanir.
- UI liste ekraninda `shipmentDocumentNo`, `shipmentDocumentDate`, `warehouseName`, `sourceLineSummary`, `taxRateSummary`, `returnInvoiceNo` ve `returnInvoiceDate` alanlarini kesin kaynak gibi kullanmamalidir; kesin kontrol icin detay, iade adaylari veya validate akisi kullanilmalidir.
- UI mumkunse bu endpoint'i kisa tarih araligi ile cagirmalidir; gunluk listeleme en hizli kullanimdir.
- UI `isSent` ve `SentState` parametrelerinden sadece birini gondermelidir. Tercih edilen parametre `isSent`tir; ikisi birlikte gelirse backend `isSent` degerini esas alir.
- `isSent=-1` tum kayitlari getirdigi icin en pahali moddur; ekran varsayilani `isSent=0` veya ihtiyaca gore `isSent=1` olmalidir.
- Sorgu mevcut Mikro indeksinden yararlanmak icin once `CARI_HESAP_HAREKETLERI.cha_tarihi` ile daraltir, sonra dogruluk icin `cha_belge_tarih` filtresini de uygular.
- Bu optimizasyon `cha_tarihi` ve `cha_belge_tarih` ayni gun oldugu fatura akisinda guvenlidir; canli kontrolde 2026-07-07 gonderilmis e-fatura setinde farkli tarihli satir bulunmamistir.
- DBA ile kontrol edilmesi gereken mevcut indeks: `NDX_CARI_HESAP_HAREKETLERI_02 (cha_tarihi)`. Bu indeks kullanilmiyorsa istatistikler ve execution plan incelenmelidir.
- `STOK_HAREKETLERI.sth_fat_uid` icin modelde indeks gorunuyor; sevkiyat/istisna apply'lari bu indeksten yararlanmalidir. Canli planda bu indeks kullanilmiyorsa istatistikler guncellenmelidir.
- liste belge bazinda doner; ayni `cha_evrakno_seri` + `cha_evrakno_sira` altindaki birden fazla hizmet/cari hareket satiri tek fatura satirinda toplanir
- `sourceLineCount`, belge altinda birlesen Mikro kaynak cari hareket satiri sayisidir; hizmet faturalarinda tek fatura icindeki hizmet kalemlerini anlamak icin kullanilir
- `sourceLineSummary`, hizmet/demirbas kaynakli satirlarda `kod - ad` ozetidir; ornek: `0056 - CIRO PRIMI GELIRI % 20 | 0055 - CIRO PRIMI GELIRI % 10`
- `taxRateSummary`, kaynak satirlarin Mikro vergi pointer'larindan cozulen KDV oran ozetidir; farkli KDV'li hizmet satirlari ayni faturada gorunebilir
- `isSent = false` ise UI lokal HTML onizleme endpoint'ini acar
- `isSent = true` ise UI Uyumsoft outbox PDF endpoint'ini acar
- PDF URL'si response alanindan uretilmez; secili satirin `documentSerie`, `documentOrderNo` ve `scenario` degerleriyle backend endpoint'i cagrilir
- `invoiceProfileId` alani:
  - e-fatura icin `TICARIFATURA` veya `TEMELFATURA`
  - e-arsiv icin `EARSIVFATURA`
- `invoiceTypeCode` alani:
  - `IADE`, `ISTISNA`, `OZELMATRAH`, `SATIS`
- `serviceDocumentId`, `send` response'unda donen Uyumsoft ETTN degeridir ve backend bunu Mikro `cha_uuid` alanina yazar; liste DTO'su `cha_uuid` degerini ayrica acmadigi icin UI PDF lookup anahtarini kendisi kurmaz, belge bazli PDF endpoint'ini kullanir
- iade faturalarinda Mikro `EBELGE_EVRAK_HAREKETLERI` kaydi `ebh_related_uid = CARI_HESAP_HAREKETLERI.cha_Guid` ile baglanir
- `ebh_iade_fat_no1` ve `ebh_iade_fat_tarihi1` degerleri response'ta `returnInvoiceNo` / `returnInvoiceDate` olarak doner
- iade referansi doluysa UBL'ye `cac:BillingReference/cac:InvoiceDocumentReference` eklenir; XSLT'deki `Iadeye Konu Olan Faturalar` tablosu bu alandan dolar

Onizleme ve PDF butonlari icin kopyalanabilir UI kurali:

```ts
function canPreviewSendingInvoice(summary: InvoiceSendingListItemDto | null | undefined): boolean {
  return Boolean(summary?.documentSerie && summary.documentOrderNo);
}
```

UI onizleme aksiyonu `isSent` degerine gore ikiye ayrilir: gonderilmemis satir lokal HTML, gonderilmis satir Uyumsoft PDF acar.

#### Gonderilmemis fatura HTML onizlemesi

Yalniz `isSent = false` satirlar lokal onizleme endpoint'ini kullanir:

```http
GET /api/fatura-islemleri/fatura-gonderimi/FRP26/21791?scenario=EFatura
Authorization: Bearer {accessToken}
```

Bu endpoint:

- Uyumsoft'a fatura gondermez
- Uyumsoft outbox PDF servisini cagirmez
- Mikro verisinden UBL XML'i yeniden uretir
- secilen XSLT ile HTML olusturur
- HTML'e backend tarafinda ek bir QR/SVG eklemez
- JSON tipinde `InvoiceSendingDetailDto` doner; response dogrudan PDF veya `text/html` degildir

UI'nin kullanacagi alan:

```ts
const detail = await api.get<InvoiceSendingDetailDto>(
  `/api/fatura-islemleri/fatura-gonderimi/${encodeURIComponent(invoice.documentSerie)}/${invoice.documentOrderNo}`,
  { params: { scenario: invoice.scenario } }
);

previewFrame.srcdoc = detail.document.htmlContent;
```

#### Gonderilmis fatura Uyumsoft PDF

`isSent = true` satirlar icin:

```http
GET /api/fatura-islemleri/fatura-gonderimi/FRP26/21791/pdf?scenario=EFatura
Authorization: Bearer {accessToken}
Accept: application/pdf
```

Davranis:

- backend faturayi Mikro'dan `documentSerie + documentOrderNo` ile bulur
- lookup icin once `cha_uuid`, bossa `cha_Guid` kullanilir
- Uyumsoft `GetOutboxInvoicePdf` cagrilir
- response JSON degil, `application/pdf` binary veridir
- Uyumsoft'ta belge/PDF bulunamazsa UI lokal HTML'e sessizce gecmek yerine kullaniciya PDF'in alinamadigini bildirmelidir

```ts
if (invoice.isSent) {
  const response = await api.get(
    `/api/fatura-islemleri/fatura-gonderimi/${encodeURIComponent(invoice.documentSerie)}/${invoice.documentOrderNo}/pdf`,
    { params: { scenario: invoice.scenario }, responseType: "blob" }
  );

  const pdfUrl = URL.createObjectURL(response.data);
  window.open(pdfUrl, "_blank", "noopener,noreferrer");
} else {
  const detail = await api.get<InvoiceSendingDetailDto>(
    `/api/fatura-islemleri/fatura-gonderimi/${encodeURIComponent(invoice.documentSerie)}/${invoice.documentOrderNo}`,
    { params: { scenario: invoice.scenario } }
  );

  previewFrame.srcdoc = detail.document.htmlContent;
}
```

Karekod icin kesin UI kurali:

- `document.htmlContent` sadece bir kez DOM'a yazilmalidir
- ayni HTML hem ana container'a hem iframe'e birlikte yazilmamalidir
- UI `QRCode`, `qrcode.js`, canvas veya baska bir kutuphane ile ikinci karekod uretmemelidir
- `document.xmlContent` ekrana HTML olarak render edilmemelidir
- XSLT karekodu JavaScript ile olusturuyorsa iframe/webview script politikasi buna gore ayarlanmalidir

Backend karekod kurali:

- ortak renderer QRCoder veya baska bir kutuphane ile yeni karekod uretmez
- XSLT sonucuna statik SVG, canvas veya image eklenmez
- karekodun tek kaynagi embedded XSLT veya fallback XSLT'dir
- bu kural hem `fatura-gonderimi` hem `fatura-goruntuleme` HTML detay/render endpointlerinde gecerlidir

UI kontrolu:

```ts
const html = detail.document.htmlContent;
const qrContainerCount = (html.match(/\bid\s*=\s*["']qrcode["']/gi) ?? []).length;

console.log({ qrContainerCount });
// Fallback e-fatura XSLT icin beklenen container sayisi: 1
```

### Fatura Gonderimi Iade Referansi

#### UI uygulama kurali

Iade referansi endpointleri cagirilirken hedef faturanin kimligi sadece secilen liste/detail satirindan alinmalidir:

```ts
const documentSerie = invoice.documentSerie;
const documentOrderNo = invoice.documentOrderNo;
const scenario = invoice.scenario;
```

Asagidaki alanlar kullanilmamalidir:

- `invoiceId` icinden seri veya sira cikarmak
- ekranda gorunen resmi fatura numarasini parcalamak
- aktif sekmeye bakarak `scenario` degerini yeniden tahmin etmek
- `EFatura` veya `EArsiv` degerini sabit yazmak

Ornek liste satiri:

```json
{
  "documentSerie": "FRP",
  "documentOrderNo": 21763,
  "invoiceId": "FRP2026000021763",
  "invoiceTypeCode": "IADE",
  "scenario": 0,
  "returnInvoiceNo": "",
  "returnInvoiceDate": null
}
```

Bu satir icin dogru aday listesi cagrisi:

```http
GET /api/fatura-islemleri/fatura-gonderimi/FRP/21763/return-reference-candidates?scenario=EFatura
```

Dogru kaydetme cagrisi:

```http
PUT /api/fatura-islemleri/fatura-gonderimi/FRP/21763/return-reference
Content-Type: application/json
```

```json
{
  "scenario": 0,
  "sourceDocumentSerie": "ABC",
  "sourceDocumentOrderNo": 123,
  "useFallbackWhenNotSelected": false
}
```

Yanlis ornek:

```http
PUT /api/fatura-islemleri/fatura-gonderimi/FRP26/21763/return-reference
```

```json
{
  "scenario": 1
}
```

Bu ornekte iki hata vardir:

1. `FRP26`, `invoiceId` degerinden turetilmistir; route'ta response'taki gercek `documentSerie` olan `FRP` kullanilmalidir.
2. Fatura satiri `scenario = 0 (EFatura)` iken body'de `1 (EArsiv)` gonderilmistir. Backend bu durumda yalnizca e-Arsiv kuyrugunda arama yapar ve e-Fatura kaydini bulamaz.

#### Kullanici akisi

1. Liste/detail response'ta `invoiceTypeCode = IADE` ise UI her zaman `Iadeye konu fatura sec/degistir` aksiyonu gostermelidir.
2. `returnInvoiceNo` bos ise gonderimden once referans secimi zorunludur.
3. `returnInvoiceNo` doluysa mevcut referans gosterilir; kullanici bunun gecici sorgu/fallback ile doldugunu dusunuyorsa yine aday listesinden dogru faturayi secip guncelleyebilir.
4. UI adaylari secilen satirin `documentSerie`, `documentOrderNo` ve `scenario` degerleriyle ceker.
5. Kullanici dogru faturayi secerse referans kaydedilir.
6. Kullanici secemiyorsa gecici olarak fallback kullanilabilir; fallback ayni carinin son normal faturasini secer.
7. PUT body'deki `scenario`, aday listesi cagrisi ve secilen fatura satirindaki `scenario` ile ayni olmalidir.
8. Referans kaydedildikten sonra normal `send` endpoint'i cagrilir.

#### Route parametreleri

- `return-reference` ve `return-reference-candidates` route'larinda path parametresi olarak liste/detail response'undaki `documentSerie` ve `documentOrderNo` aynen kullanilmalidir.
- UI `invoiceId` veya fatura numarasindan seri/sira parse etmeye calismamalidir. Ornek `invoiceId = FRP2026000021626` ise path'e `FRP26/21626` gibi turetilmis deger gondermek yerine response'taki gercek `documentSerie` kullanilmalidir.
- Backend geriye uyumluluk icin `ABC26` gibi 3 harf + yil eki gorunen seriler bulunamazsa `ABC` ile de arama dener; yine de UI icin dogru kaynak response alanlaridir.

#### Scenario kurali

- Aday listesi GET sorgusundaki `scenario`, secilen satirin `scenario` alanidir.
- Kaydetme PUT body'deki `scenario`, secilen satirin `scenario` alanidir.
- UI `0` degerini bos/false saymamalidir; `0 = EFatura`, `1 = EArsiv` olarak normalize etmelidir.
- `EFatura` kaydi `EArsiv` ile; `EArsiv` kaydi `EFatura` ile sorgulanmamalidir.
- Ayni seri/sira diger senaryo filtresinde bulunmadigi icin yanlis scenario genellikle `404 Pending invoice was not found` hatasi uretir.
- UI state icinde sekme degisse bile acik modal, secildigi fatura satirinin kendi `scenario` degerini korumalidir.

Ornek UI endpoint olusturma:

```ts
const basePath =
  `/api/fatura-islemleri/fatura-gonderimi/` +
  `${encodeURIComponent(invoice.documentSerie)}/` +
  `${invoice.documentOrderNo}`;

const candidatesUrl =
  `${basePath}/return-reference-candidates` +
  `?scenario=${encodeURIComponent(invoice.scenario)}`;

const updateBody = {
  scenario: invoice.scenario,
  sourceDocumentSerie: selectedInvoice?.sourceDocumentSerie ?? null,
  sourceDocumentOrderNo: selectedInvoice?.sourceDocumentOrderNo ?? null,
  useFallbackWhenNotSelected: selectedInvoice == null
};
```

#### Aday listesini getirme

`GET /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/return-reference-candidates?scenario=EFatura`

Response `InvoiceReturnReferenceCandidatesResponse`:

```json
{
  "invoice": {
    "documentSerie": "FRP",
    "documentOrderNo": 21763,
    "invoiceId": "FRP2026000021763",
    "invoiceTypeCode": "IADE",
    "scenario": 0,
    "returnInvoiceNo": "",
    "returnInvoiceDate": null
  },
  "currentReference": null,
  "fallbackReference": {
    "sourceDocumentSerie": "ABC",
    "sourceDocumentOrderNo": 123,
    "invoiceNo": "ABC2026000000123",
    "invoiceDate": "2026-06-01T00:00:00",
    "isFallbackCandidate": true,
    "isGeneratedInvoiceNo": false
  },
  "candidates": []
}
```

#### Referansi kaydetme

`PUT /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/return-reference`

Secilen faturayi kaydetmek icin:

```json
{
  "scenario": 0,
  "sourceDocumentSerie": "ABC",
  "sourceDocumentOrderNo": 123,
  "useFallbackWhenNotSelected": false
}
```

Gecici fallback'i kaydetmek icin:

```json
{
  "scenario": 0,
  "useFallbackWhenNotSelected": true
}
```

#### 404 hata kontrol listesi

`Pending invoice was not found` cevabi alininca UI su alanlari loglayip karsilastirmalidir:

- secilen satirdaki `documentSerie`
- route'a yazilan `documentSerie`
- secilen satirdaki `documentOrderNo`
- route'a yazilan `documentOrderNo`
- secilen satirdaki `scenario`
- GET query veya PUT body ile gonderilen `scenario`

Ornek hata:

```text
Pending invoice was not found for FRP26/21763.
Scenario=EArsiv.
Tried series: FRP26, FRP.
```

Bu mesaj backend'in hem `FRP26` hem `FRP` serisini denedigini, fakat aramayi `EArsiv` filtresiyle yaptigini gosterir. Secilen satir `EFatura` ise once frontend body'deki `scenario` duzeltilmelidir.

Not: Kayit `EBELGE_EVRAK_HAREKETLERI.ebh_related_uid = iade faturasi cha_Guid` uzerinden update/insert edilir. `send` sirasinda iade referansi halen bos ise backend fallback'i otomatik deneyip kaydeder; fallback bulunamazsa gonderim durdurulur.

### Fatura Gonderimi Detay

`GET /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}?scenario=EFatura`

Calisan ornek:

```http
GET /api/fatura-islemleri/fatura-gonderimi/FRP26/21791?scenario=EFatura
Authorization: Bearer {accessToken}
```

Yetki:

- `fatura-islemleri.fatura-gonderimi.detail`

Response `InvoiceSendingDetailDto`:

- `summary`: secilen bekleyen fatura satirinin ozeti
- `document`: UBL XML'den render edilmis `InvoiceRenderedDocumentDto`

Ornek response iskeleti:

```json
{
  "summary": {
    "documentSerie": "FRP26",
    "documentOrderNo": 21791,
    "invoiceId": "FRP2026000021791",
    "isSent": true,
    "scenario": 0
  },
  "document": {
    "source": "pending-send",
    "invoiceId": "FRP2026000021791",
    "profile": 1,
    "appliedXsltName": "efatura.xslt",
    "xsltSource": "embedded-attachment",
    "usedEmbeddedXslt": true,
    "xmlContent": "<Invoice>...</Invoice>",
    "htmlContent": "<html>...</html>"
  }
}
```

UI sadece `document.htmlContent` alanini onizleme yuzeyine verir. `xmlContent`, hata ayiklama veya ham UBL goruntuleme ihtiyaci disinda son kullanici onizlemesinde kullanilmaz.

Davranis:

- secilen kayit Mikro'dan okunur
- belge tipi stok faturasi ise satirlar `STOK_HAREKETLERI` uzerinden, hizmet/demirbas ise ilgili hizmet sorgusu uzerinden toplanir
- backend UBL invoice uretir
- render icin once embedded XSLT denenir; yoksa `Assets/Xslt/efatura.xslt` veya `Assets/Xslt/earsiv.xslt` fallback olur
- e-fatura XSLT'si firma logosunu ve GIB karekod alanlarini icerir
- API, XSLT sonucu olusan HTML'e ikinci bir QR/SVG eklemez
- karekod icerigi ve gorseli tamamen secilen embedded veya fallback XSLT'nin sorumlulugundadir
- satir ve `Mal Hizmet Toplam Tutari` alanlari iskonto oncesi brut tutari gosterir; ilk `AllowanceCharge/BaseAmount` satir brutunun kaynagidir
- `Toplam Iskonto` UBL `AllowanceTotalAmount`, `Iskonto Sonrasi Vergi Haric Tutar` ise `TaxExclusiveAmount` alanindan gosterilir
- satir iskonto yuzdesinin bozulmamasi icin `AllowanceCharge/Amount` ve `AllowanceCharge/BaseAmount` en fazla 4 ondalik hassasiyetle yazilir; genel para toplamlari (`LineExtensionAmount`, `TaxAmount`, `PayableAmount`, `AllowanceTotalAmount`) 2 ondalik kalir
- bu endpoint sadece onizleme/render icindir; Uyumsoft'a gonderim yapmaz

### Fatura Gonderimi Render

`POST /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/render`

Yetki:

- `fatura-islemleri.fatura-gonderimi.detail`

Request:

```json
{
  "scenario": 0,
  "profile": "Auto",
  "preferEmbeddedXslt": true,
  "fallbackToGeneral": true
}
```

Davranis:

- `GET detail` ile ayni `InvoiceSendingDetailDto` tipini doner
- farki, XSLT secimini body ile override edebilmenizdir
- response yine JSON'dur; UI `document.htmlContent` alanini tek kez render eder
- QR davranisi `GET detail` ile aynidir: backend yeni QR uretmez, UI da ikinci QR uretmez

### Fatura Gonderimi Validate

`POST /api/fatura-islemleri/fatura-gonderimi/validate`

Yetki:

- `fatura-islemleri.fatura-gonderimi.create`

Request `send` endpoint'i ile aynidir.

Davranis:

- `scenario` zorunludur: `0 = EFatura`, `1 = EArsiv`; UI secili satirin `scenario` alanini aynen gondermelidir
- secilen belgeler tekillestirilir
- Mikro verisinden UBL XML uretilir
- iade referansi gerekiyorsa fallback sadece simule edilir, Mikro'ya yazilmaz
- UBL-TR is kurali ve XSD dogrulamalari calistirilir
- Uyumsoft'a fatura gonderilmez
- Mikro `cha_belge_no`, `cha_kilitli` veya baska alanlar guncellenmez
- bu endpoint UI'daki "Kontrol Et" butonunun karsiligidir; `send` hiz icin bu dogrulamalari tekrar calistirmaz

Response `ValidateInvoiceDocumentsResponse`:

```json
{
  "scenario": 0,
  "requestedCount": 2,
  "validCount": 1,
  "invalidCount": 1,
  "items": [
    {
      "documentSerie": "FAT",
      "documentOrderNo": 12345,
      "invoiceId": "FAT2026000012345",
      "customerCode": "120001",
      "customerTitle": "ORNEK MUSTERI",
      "isValid": true,
      "message": "Gonderim oncesi kontrol basarili."
    },
    {
      "documentSerie": "FAT",
      "documentOrderNo": 12346,
      "invoiceId": "FAT2026000012346",
      "customerCode": "",
      "customerTitle": "",
      "isValid": false,
      "message": "Target customer alias/e-mail is required."
    }
  ]
}
```

### Fatura Gonderimi Send

`POST /api/fatura-islemleri/fatura-gonderimi/send`

Yetki:

- `fatura-islemleri.fatura-gonderimi.create`

Request:

```json
{
  "scenario": 0,
  "documents": [
    {
      "documentSerie": "FAT",
      "documentOrderNo": 12345
    },
    {
      "documentSerie": "FAT",
      "documentOrderNo": 12346
    }
  ]
}
```

Not: `scenario` zorunludur. UI e-Arsiv satiri icin `1`, e-Fatura satiri icin `0` gondermelidir; alan bos birakilirsa backend artik varsayilan EFatura kabul etmez.

Response `SendInvoiceDocumentsResponse`:

```json
{
  "scenario": 0,
  "requestedCount": 2,
  "succeededCount": 1,
  "failedCount": 1,
  "items": [
    {
      "documentSerie": "FAT",
      "documentOrderNo": 12345,
      "invoiceId": "FAT2026000012345",
      "customerCode": "120001",
      "customerTitle": "ORNEK MUSTERI",
      "isSucceeded": true,
      "serviceDocumentId": "8f5f...",
      "serviceDocumentNumber": "FAT2026000012345",
      "message": "Gonderim basarili."
    },
    {
      "documentSerie": "FAT",
      "documentOrderNo": 12346,
      "invoiceId": "FAT2026000012346",
      "customerCode": "",
      "customerTitle": "",
      "isSucceeded": false,
      "serviceDocumentId": null,
      "serviceDocumentNumber": null,
      "message": "Belge zaten gonderilmis."
    }
  ]
}
```

Davranis:

- secimler duplicate ise backend tekilleÃƒâ€¦Ã…Â¸tirir
- gonderim Uyumsoft WCF client ile fatura bazli tek tek yapilir; boylece basarili/hatali kayitlar response icinde ayri ayri gorulur
- her belge icin UBL invoice uretilir ve Uyumsoft `SendInvoice` operasyonu cagrilir
- hiz icin UBL-TR is kurali ve XSD dogrulamalari burada tekrar calistirilmaz; bu kontroller icin kullanici once `/validate` endpoint'ini cagirir
- ayni belge icin SQL application lock alinir; ayni belge baska bir istek tarafindan gonderiliyorsa ikinci istek Uyumsoft'a cagrilmaz ve ilgili satir hata mesaji ile doner
- basarili donuste `serviceDocumentNumber` Mikro `cha_belge_no` alanina yazilir
- `serviceDocumentId` Uyumsoft'un teknik id'sidir; basarili gonderimde Mikro `cha_uuid` alanina yazilir, servis id bos donerse faturanin lokal UUID degeri fallback olarak saklanir
- sonraki liste ekraninda gonderilmis fatura PDF ve tekrar gonderim aksiyonlari backend tarafinda bu UUID uzerinden cozulur; UI teknik UUID gondermek zorunda degildir
- ayni anda `cha_kilitli = true`, `cha_degisti = true`, `cha_lastup_user = 39` ve `cha_lastup_date = now` set edilir
- zaten gonderilmis kayitlar response'ta `isSucceeded = false` ile doner; genel request tamamen patlatilmaz

UBL / gonderim kurallari:

- hedef alici alias'i `FaturaMail`, bos ise `Mail` fallback'i ile uretilir
- supplier bilgisi config tabanli sabit musteri kodundan cekilir; mevcut konfigrasyonda bu kod `32004621`'dir
- profil kurali:
  - e-fatura icin `EBelgeTuru = 0 -> TICARIFATURA`, diger durumda `TEMELFATURA`
  - e-arsiv icin `EARSIVFATURA`
- fatura tip kodu:
  - `Iade != 0 -> IADE`
  - `IstisnaKodu dolu -> ISTISNA`
  - `OzelMatrahKodu dolu -> OZELMATRAH`
  - aksi halde `SATIS`
- stok satirlarinda iskonto alanlari `AllowanceCharge` olarak satir bazinda XML'e yazilir
- `AllowanceCharge/MultiplierFactorNumeric` ondalik katsayi olarak yazilir; ornegin `%3 = 0.03`, `%5 = 0.05`. XSLT ekranda bu degeri `100` ile carparak yuzdeyi gosterir.
- `AllowanceCharge/Amount` ve `AllowanceCharge/BaseAmount` 4 ondaliga kadar hassas yazilir. Ornek: Mikro `sth_iskonto1 = 0.6042` ise UBL `Amount` degeri `0.6042` olur; bu sayede `20.14` baz tutarda %3 iskonto Uyumsoft/alici ekraninda %2.98 gibi gorunmez.
- e-arsiv gonderiminde `EArchiveInvoiceInfo DeliveryType="Electronic"` kullanilir

### Fatura Gonderimi Retry

`POST /api/fatura-islemleri/fatura-gonderimi/retry`

Yetki:

- `fatura-islemleri.fatura-gonderimi.create`

Request, `/send` ile ayni belge secim yapisini kullanir ve tek istekte en fazla 20 belge kabul eder:

```json
{
  "scenario": 0,
  "documents": [
    {
      "documentSerie": "FAT",
      "documentOrderNo": 12345
    }
  ]
}
```

Response `RetryInvoiceDocumentsResponse`:

```json
{
  "scenario": 0,
  "requestedCount": 1,
  "succeededCount": 1,
  "failedCount": 0,
  "items": [
    {
      "documentSerie": "FAT",
      "documentOrderNo": 12345,
      "invoiceId": "FAT2026000012345",
      "serviceInvoiceId": "8f5f...",
      "isSucceeded": true,
      "message": "Uyumsoft tekrar gonderim istegini kabul etti."
    }
  ]
}
```

Davranis:

- bu endpoint ilk gonderim yapmaz ve `/send` akisinin yerine kullanilmaz
- yalnizca Mikro'da `isSent = true` olan ve `cha_uuid`/Uyumsoft invoiceId bilgisi bulunan belgeler retry edilebilir
- UI `Tekrar Gonder` aksiyonunu yalnizca `isSent = true` satirlarda gostermelidir
- UI seri/sira gonderir; `serviceInvoiceId` backend tarafinda Mikro kaydindan cozulur
- gecerli secimlerin UUID'leri tek toplu Uyumsoft `RetrySendInvoices` operasyonuna verilir
- Uyumsoft operasyonu batch seviyesinde tek response dondurdugu icin servisin kabul/red sonucu batch icindeki tum gecerli satirlara uygulanir
- bulunamayan, gonderilmemis veya UUID'si bos belgeler Uyumsoft'a gonderilmez ve item bazinda `isSucceeded = false` doner
- retry sirasinda UBL yeniden uretilmez, `SendInvoice` cagrilmaz ve Mikro fatura alanlari tekrar guncellenmez

### Fatura Gonderimi XML Preview

`POST /api/fatura-islemleri/fatura-gonderimi/preview`

Yetki:

- `fatura-islemleri.fatura-gonderimi.create`

Request:

```json
{
  "invoiceId": "INV-2026-0001",
  "xmlContent": "<Invoice>...</Invoice>",
  "profile": "Auto",
  "preferEmbeddedXslt": true
}
```

Response:

- `InvoiceRenderedDocumentDto`

Bu endpoint ne zaman kullanilmali:

- UI kendi XML'ini olusturuyorsa ve sadece gorunumunu test etmek istiyorsa
- belge henuz Uyumsoft outbox'ta degilse
- kullaniciya "gondermeden once onizleme" gostermek istiyorsaniz

Fatura modulu notlari:

- is kurali tarafinda sade ozet sunudur: `fatura-gonderimi` gonderilmemis giden faturayi lokal HTML ile, gonderilmis giden faturayi Uyumsoft outbox PDF ile acar; bekleyen kaydi Uyumsoft'a yollar. `fatura-goruntuleme` ise Uyumsoft gelen/inbox faturasini acma/yazdirma akisidir
- bu repoda `fatura-gonderimi` icin pending list, detay/render, gonderilmis belge PDF ve send endpointleri vardir
- `fatura-goruntuleme` tarafi artik `uyumsoft_inbox_invoices` cache tablosundan liste alir; varsayilan acista Uyumsoft `GetInboxInvoicePdf` ile PDF datasini, HTML detayda `GetInboxInvoice` ile render datasini alir
- yeni eklendi: `POST /api/fatura-islemleri/fatura-goruntuleme/senkronize` ile secilen tarih araligi manuel olarak Uyumsoft'tan cache'e alinabilir
- `fatura-goruntuleme` icinde legacy'deki "goruntule" ve "yazdirildi say" ayrimi artik ayri endpointlerle temsil edilir
- `GET /{documentId}/detail` ile `POST render` ayni response tipini doner; fark, `POST render` ile XSLT davranisinin override edilebilmesidir
- `fatura-gonderimi` detail/send akisinda invoice XML Mikro verisinden backend tarafinda yeniden uretilir; UI ham XML kurmak zorunda degildir
- `fatura-gonderimi` send akisinda basarili sonuclarda Mikro `cha_belge_no` ve `cha_uuid` geri yazilir, kayit kilitlenir
- render sirasinda once embedded XSLT denenir; yoksa WebApi icindeki `Assets/Xslt/efatura.xslt` veya `Assets/Xslt/earsiv.xslt` fallback olarak kullanilir
- ortak renderer artik ek karekod uretmez; fatura-gonderimi ve fatura-goruntuleme HTML'inde karekodun tek kaynagi secilen XSLT'dir
- `fatura-goruntuleme` PDF/detail lookup anahtari `documentId`'dir; `invoiceId` ise kullaniciya gosterilen numaradir

## UI Tasarim Onerisi

Sol menu:

- `AramaIslemleri`
- `SiparisIslemleri`
- `SevkIslemleri`
- `MalKabulIslemleri`
- `StokIslemleri`
- `IadeIslemleri`
- `KasaIslemleri`
- `FaturaIslemleri`
- `OperasyonIslemleri`
- `KullaniciIslemleri`

Liste ekranlarinda onerilen kolonlar:

- Fiyat Gor icin: barkod, stok kodu, stok adi, fiyat, fiyat tipi, birim, blok durumlari
- Cari Bul icin: barkod, stok kodu, stok adi, varsayilan tedarikci, onerilen cari, son hareket tarihi, kaynaklar
- Depo siparisleri icin: belge tarihi, seri, sira, kaynak/hedef depo, satir sayisi, toplam miktar, teslim tarihi
- Firma siparisleri icin: belge tarihi, seri, sira, musteri, adres, satir sayisi, toplam miktar, teslim tarihi
- Firma sevkleri ve firma iadeleri icin: belge tarihi, seri, sira, cari, depo, satir sayisi, toplam miktar, toplam tutar
- Zayiat ve masraf fisleri icin: belge tarihi, seri, sira, creator, acceptor, depo, satir sayisi, toplam miktar
- Sayim sonuclari icin: belge tarihi, belge no, sayim adi, depo, satir sayisi, toplam miktar
- Etiket belgeleri icin: olusturma tarihi, documentId, depo
- Manav mal kabul ve etiket icin: olusturma tarihi, cari, evrak seri/sira, stok kodu, stok adi, brut kilo, net kilo, kasa sayisi, ortalama kasa kilosu, durum, Mikro aktarildi
- Kasa sayimlari icin: tarih, seri, sira, kasa no, z no, kasiyer, yonetici, toplam
- Kasa cirolari icin: is tarihi, sube, vardiya, kasiyer kodu, kasiyer adi, satis tutari, tahsilat tutari, komisyon, net tahsilat
- Depo iadeleri icin: belge tarihi, seri, sira, kaynak depo, hedef depo, satir sayisi, toplam miktar
- Fatura goruntuleme icin: fatura tarihi, documentId, invoiceId, musteri, TCKN/VKN, tip, tutar, yazdirildi, islendi, durum

Siparis detay ekraninda onerilen bolumler:

- ust kart: evrak bilgileri
- depo siparisinde depo bilgileri: mevcut depo / karsi depo
- firma siparisinde cari bilgileri: musteri, adres, temsilci kodu
- ozet alanlari: toplam miktar / kalan / toplam tutar
- kalem grid: stok kodu, stok adi, birim, miktar, teslim, kalan, fiyat, tutar, aciklama

## Notlar

- Liste ve detay endpointleri canli Mikro verisinden okur
- create endpointleri secili write connection uzerinden Mikro'ya yazar
- e-irsaliye gonderme endpointleri yeni modul degil; mevcut detay ekranlarinda buton/yardimci aksiyon gibi dusunulmelidir
- e-irsaliye PDF endpointleri de yeni modul degildir; ayni detay ekranlarinda `PDF Goster` veya `Yazdir` aksiyonu olarak dusunulmelidir
- e-irsaliye gonderimi mevcut evraktan uretilir; create endpointinden ayri bir ikinci kayit acmaz
- zayiat ve masraf fislerinde cari bulunmaz; UI header ve listede `creator` / `acceptor` alanlarini one cikarabilir
- sayim sonuclari modulunde belge serisi yoktur; detay acarken `documentNo` ile birlikte `documentDate` query parametresi gonderilmelidir
- etiket belgeleri modulunde detay route'u `documentId:int` ile calisir; seri/sira mantigi yoktur
- kasa sayimlari liste endpointi satir bazli calistigi icin ayni belge birden fazla kayit olarak gelebilir; UI gerekirse belge bazli group etmelidir
- fatura HTML goruntuleme backend tarafinda XSLT ile uretilir; UI sadece `htmlContent` render eder
- e-irsaliye PDF sadece gonderilmis evraklar icin alinabilir; gonderim yapilmadiysa UI `409` hatasini kullaniciya anlamli mesajla gostermelidir
- auth ve rol/yetki verileri `FurpaMerkezDb` tarafindadir
- operasyonel veriler `MikroDB_V16_FURPA_2024` tarafindadir
- `AuthDbContext` seed/model degisikligi yapildiginda yeni migration alinmalidir; aksi halde uygulama acilisinda `PendingModelChangesWarning` hatasi alinir

## Operasyon Islemleri

Bu modul eski `OperationsController` davranisinin yeni API'ye uyarlanmis halidir. UI tarafinda bu ekran agirlikli olarak "dosya uret ve durumunu takip et" mantiginda calismalidir; liste/detay CRUD ekrani gibi dusunulmemelidir.

Detayli teknik dokuman: [OPERASYON_ISLEMLERI_DETAYLI_API_DOKUMANI.md](OPERASYON_ISLEMLERI_DETAYLI_API_DOKUMANI.md)

Legacy farklarini okurken su noktalari esas alinmalidir:

- Hangfire ve SignalR beklentisi yoktur; bu modul application icindeki hosted queue + polling modeliyle calisir
- `warehouseNo` artik `ClaimTypes.Name` degil, `warehouse_no` claim'inden okunur
- `operasyon-islemleri.operations.all-warehouses` yoksa dosya olusturma aksiyonlari icin depo sorulmaz; backend JWT icindeki kullanici deposunu kullanir. Bu yetki varsa baska depo icin job baslatilacaksa query'de opsiyonel `warehouseNo` gonderilebilir.
- `promofile` de yeni kuyruk/polling modeliyle calisir; eski yardimci dosya zinciri job icinde uretilir
- `customerfile` sadece `EFATVNO.DAT` cari/vergi no dosyasini uretir.

Temel route:

- `api/operations`

Mevcut endpointler:

- `GET /api/operations/scalesfile?warehouseNo=110`
  - terazi dosyasi isi kuyruga alinir
  - response `202 Accepted`
  - body `OperationJobDto`
- `GET /api/operations/productbarcodeplunofile?warehouseNo=110`
  - urun/barcode/PLU dosya isi kuyruga alinir
  - eski uyumluluk icin `GET /api/operations/productbarcodeplonofile` da ayni isi yapar
  - response `202 Accepted`
- `GET /api/operations/cashierfile?warehouseNo=110`
  - kasiyer ve yetki dosyalari isi kuyruga alinir
  - response `202 Accepted`
- `GET /api/operations/promofile?warehouseNo=110`
  - promosyon ve yardimci POS dosyalari isi kuyruga alinir
  - response `202 Accepted`
  - Mayday/UYUM connection stringleri eksikse job `Failed` durumuna duser ve `errorMessage` ile sebep doner
- `GET /api/operations/customerfile?warehouseNo=110`
  - cari/vergi no dosyasi `EFATVNO.DAT` isi kuyruga alinir
  - response `202 Accepted`
  - alias: `GET /api/operations/einvoicevnofile`
- `GET /api/operations/jobs/{jobId}`
  - kuyruga atilan isin durumunu dondurur
  - admin olmayan kullanici baska deponun job detayini okuyamaz
  - response `OperationJobDetailDto`
- `GET /api/operations/getauthorizationfile`
  - authorization kayitlarini getirir
  - yeni alias: `GET /api/operations/authorization-files`
- `POST /api/operations/saveauthorizationfile`
  - authorization kayitlarini toplu gunceller
  - yeni alias: `POST /api/operations/authorization-files`

UI akis onerisi:

- kullanici "Terazi Dosyasi Olustur" der
- `GET /api/operations/scalesfile` cagrilir
- `202` donerse `jobId` alinip durum modal/paneli acilir
- UI belirli aralikla `GET /api/operations/jobs/{jobId}` poll eder
- `status = Succeeded` olursa basarili mesaj gosterilir
- `status = Failed` olursa `errorMessage` gosterilir

Ayni akis su ekran aksiyonlari icin de gecerlidir:

- `Urun/Barcode/PLU Dosyasi Olustur`
- `Kasiyer Dosyasi Olustur`
- `Promosyon Dosyasi Olustur`
- `Cari / EFATVNO Dosyasi Olustur`

Job response modelleri:

- `OperationJobDto`
  - `jobId`
  - `operation`
  - `status`
  - `warehouseNo`
  - `createdAtUtc`
- `OperationJobDetailDto`
  - `jobId`
  - `operation`
  - `status`
  - `warehouseNo`
  - `requestedByUserId`
  - `createdAtUtc`
  - `startedAtUtc`
  - `completedAtUtc`
  - `message`
  - `errorMessage`
  - `files`

Authorization file endpoint modelleri:

- `GET /api/operations/getauthorizationfile`
- alias: `GET /api/operations/authorization-files`
- Response: `AuthorizationFileDto[]`
- Her kayitta alanlar:
  - `id`
  - `updateDate`
  - `name`
  - `z`
  - `r`
  - `x`

- `POST /api/operations/saveauthorizationfile`
- alias: `POST /api/operations/authorization-files`
- Request body: `SaveAuthorizationFileHttpRequest[]`
- Her kayitta alanlar:
  - `id`
  - `updateDate`
  - `name`
  - `z`
  - `r`
  - `x`
- `updateDate` request'te opsiyoneldir.
- Response: `201 Created`, body yoktur.

Authorization file ekran akis onerisi:

- ekran acilisinda `GET /api/operations/getauthorizationfile`
- grid kolonlari:
  - `id`
  - `name`
  - `r`
  - `x`
  - `z`
  - `updateDate`
- kaydet aksiyonunda secili/tum satirlar `POST /api/operations/saveauthorizationfile` ile toplu gonderilir
- basarili durumda `201 Created` beklenmelidir

### Belge Akis ve Hata Takibi

Bu ekran sevk, iade, mal kabul, siparis ve e-irsaliye adimlarini Auth DB tarafinda izlemek icin eklendi. Mikro semasina yazmaz; kayitlar `document_flows` ve `document_flow_events` tablolarinda tutulur.

Alan mantigi:

- `sourceWarehouseNo`: belgeyi veya cikis hareketini baslatan depodur. Firma sevki, firma iadesi, depolar arasi sevk ve depo iadesi bu depoda cikis/aksiyon olarak gorunur.
- `targetWarehouseNo`: depolar arasi sevk ve depo iadesinde mal kabulu beklenen veya tamamlayan karsi depodur. Firma sevki ve firma iadesinde bos gelir.
- `currentStep = DocumentCreated`: belge API tarafindan olusturuldu.
- `currentStep = EDespatchSubmission`: e-irsaliye gonderim adimi calisti. `status = Failed` ise hata panelde kaynak depoya yazilir.
- `currentStep = WarehouseReceivingAccepted`: hedef depo mal kabul islemini tamamladı. Depo Operasyon Paneli bu adimi hedef depoda tamamlanan kabul olarak sayar.
- Depolar arasi belgelerde tek belge akis kaydi hem kaynak depo hem hedef depo icin kullanilir; liste filtresinde iki taraftan biri eslesirse kayit gelir.

### Mikro API Yazma Audit Kayitlari

Mikro API uzerinden yapilan teknik yazma cagrilari, Belge Akis Takibi'nden ayri olarak Auth DB icindeki `mikro_api_write_audits` tablosunda izlenir. Belge Akis Takibi is surecini, bu tablo ise Mikro HTTP isteginin teknik sonucunu kaydeder.

Config:

```json
"MikroApiWriteAudit": {
  "Enabled": true,
  "MaxResponseLength": 8000
}
```

- Ortam degiskeni ile acma/kapatma: `MikroApiWriteAudit__Enabled=true|false`
- Response siniri: `MikroApiWriteAudit__MaxResponseLength=8000`
- `Enabled=false` oldugunda audit servisi Auth DB'ye okuma veya yazma yapmaz.
- Audit kaydi basarisiz olursa asil Mikro API yazma islemi durdurulmaz; backend warning log uretir.
- Mikro login cagrisi audit kapsaminda degildir.
- Yalnizca `MikroApiClient` uzerinden yapilan POST yazma cagrilari kaydedilir.
- `MikroWriteRouting` ilgili islem icin `Database` ise Mikro API cagrisi yapilmayacagindan audit kaydi da olusmaz.
- Mevcut config'te yazma rotalari `Database` oldugu icin audit ancak ilgili rota `MikroApi` olarak degistirildiginde kayit uretir.

Kaydedilen temel alanlar:

| Alan | Aciklama |
|---|---|
| `request_id` | Her Mikro API cagrisi icin uretilen benzersiz istek kimligi |
| `correlation_id` | Gelen UI/API isteginin `X-Correlation-Id` degeri |
| `endpoint` | Cagrilan Mikro API path'i |
| `payload_hash` | Auth/sifre alani icermeyen is payload'inin SHA-256 ozeti; payload'in kendisi saklanmaz |
| `status` | `Pending`, `Succeeded`, `Failed`, `Unknown` veya `Recovered` |
| `http_status_code` | HTTP cevap kodu |
| `mikro_status_code` | Mikro response icindeki uygulama durum kodu |
| `response` | Config ile sinirlanan ham Mikro cevabi |
| `error` | Teknik veya Mikro hata mesaji |
| `attempt_count` | Retry dahil toplam deneme sayisi |
| `elapsed_milliseconds` | Mikro cagrisi toplam suresi |
| `recovered_document_no` | Mikro DB recovery sonrasinda bulunan belge no veya seri/sira referansi |
| `recovered_guid` | Recovery sonucunda bulunabiliyorsa ana hareket GUID'i |
| `document_flow_id` | Belge Akis kaydina opsiyonel baglanti; mevcut akislarda bos kalabilir |

Status anlami:

```text
Pending    Audit acildi, Mikro cevabi henuz tamamlanmadi
Succeeded  Mikro API basarili cevap verdi
Failed     HTTP veya Mikro uygulama cevabi hata dondu
Unknown    Timeout/baglanti hatasi nedeniyle sonuc kesinlestirilemedi
Recovered  Mikro API cevabindan sonra belge Mikro DB'de bulundu
```

Recovery destegi su Mikro API yazma akislari icin baglidir:

- sayim sonucu
- verilen depo siparisi
- verilen firma siparisi
- stok giris/zayiat/masraf fisi
- virman
- depolar arasi sevk
- depo iadesi
- firma sevk/iade hareketi
- firma mal kabul
- depo mal kabul kabul islemi

Bu kayitlar su anda backend operasyon/audit altyapisidir; UI icin ayrica bir liste veya detay endpoint'i yayinlanmamistir. Bu nedenle UI dogrudan tabloya baglanmamali ve Belge Akis ekraninin mevcut response modelinde audit alanlari beklememelidir.

Migration:

```text
20260708080714_AddMikroApiWriteAudit
```

Production'da `StartupTasks__ApplyAuthMigrations=false` ise migration deploy sirasinda Auth DB'ye ayrica uygulanmalidir.

### Depo Operasyon Paneli

Bu endpoint merkez yoneticisinin aktif depolari tek istekte izlemesi icindir. Depo numarasi ve adi Mikro `DEPOLAR` tablosundan okunur; operasyon sayilari yalnizca Furpa Merkez API'nin Auth DB'ye yazdigi belge akis kayitlarindan hesaplanir. Mikro veya baska bir uygulama uzerinden dogrudan yapilan islemler sayilara dahil edilmez.

```http
GET /api/operasyon-islemleri/depo-operasyon-paneli?date=2026-07-02
```

- Yalniz `operasyon-islemleri.depo-operasyon-paneli.list` ve `operasyon-islemleri.depo-operasyon-paneli.all-warehouses` yetkilerine sahip kullanicilar erisebilir.
- Modul kodu `operasyon-islemleri`, menu kodu `depo-operasyon-paneli`, menu adi `DepoOperasyonPaneli` degeridir.
- UI bu kaydi `Operasyon Islemleri > Depo Operasyon Paneli` menusu olarak gosterebilir.
- `date` opsiyoneldir ve `yyyy-MM-dd` formatindadir. Gonderilmezse API sunucusunun bugunku tarihi kullanilir.
- `todayShipmentCount`: secilen gunde API uzerinden olusturulan firma ve depolar arasi sevklerdir; kaynak depoya yazilir.
- `todayReturnCount`: secilen gunde API uzerinden olusturulan firma iadesi ve depo iadesi hareketleridir; kaynak depoya yazilir.
- `todayReceivingCount`: secilen gunde API uzerinden tamamlanan depo mal kabulleridir; hedef depoya yazilir.
- `pendingReceivingCount`: depolar arasi sevk veya depo iadesi olusturulmus, henuz depo mal kabulu tamamlanmamis kayitlardir; hedef depoya yazilir.
- `failedEDespatchCount`: son belge akis adimi basarisiz e-irsaliye gonderimi olan kayitlardir; kaynak depoya yazilir.
- `incompleteOperationCount`: bekleyen mal kabulleri ve basarisiz e-irsaliye gonderimlerini ifade eder. Genel ozette ayni belge bir kez sayilir.
- `averageReceivingMinutes`: secilen gunde tamamlanan mal kabullerinin sevk olusturma ile kabul arasindaki ortalama suresidir.
- `busiestWarehouse.value`: secilen gunun sevk, iade ve mal kabul toplami.
- `slowestWarehouse.value`: dakika cinsinden ortalama mal kabul suresi.
- `healthStatus`: e-irsaliye hatasi varsa `Critical`, bekleyen kabul varsa `Warning`, ikisi de yoksa `Healthy` doner.
- `trackingEnabled = false` ise yeni belge akisi yazimi kapalidir; panel mevcut eski kayitlardan hesaplanmaya devam eder.

Capraz depo mantigi:

- Depo 56 MANAV bir depolar arasi sevk keserse kayit `sourceWarehouseNo = 56`, `targetWarehouseNo = hedef depo` olarak tutulur.
- Ayni kayit MANAV satirinda `todayShipmentCount` olarak, hedef depo satirinda kabul edilene kadar `pendingReceivingCount` olarak gorunur.
- Hedef depo kabul islemini tamamladiginda ayni belge `currentStep = WarehouseReceivingAccepted` olur; artik hedef depo satirinda `todayReceivingCount` sayilir.
- Kabul tarihi sevk tarihinden farkliysa sevk kaynak deponun sevk gununde, kabul hedef deponun kabul gununde raporlanir.
- Depo iadesinde de ayni kaynak/hedef mantigi calisir; cikis deposunda `todayReturnCount`, hedef depoda bekleyen veya tamamlanan kabul sayaci beslenir.
- E-irsaliye adimi eski veya manuel olusmus bir depolar arasi belge icin ilk belge akis kaydini acarsa backend hedef depoyu Mikro `STOK_HAREKETLERI.sth_nakliyedeposu` alanindan cozer ve `targetWarehouseNo` olarak kaydeder.

Response ornegi:

```json
{
  "date": "2026-07-02",
  "generatedAtUtc": "2026-07-02T11:20:00Z",
  "trackingEnabled": true,
  "summary": {
    "warehouseCount": 60,
    "todayShipmentCount": 420,
    "todayReturnCount": 12,
    "todayReceivingCount": 385,
    "pendingReceivingCount": 35,
    "incompleteOperationCount": 38,
    "failedEDespatchCount": 4
  },
  "busiestWarehouse": {
    "warehouseNo": 12,
    "warehouseName": "Kadikoy",
    "value": 41
  },
  "slowestWarehouse": {
    "warehouseNo": 20,
    "warehouseName": "Pendik",
    "value": 97.5
  },
  "warehouses": [
    {
      "warehouseNo": 12,
      "warehouseName": "Kadikoy",
      "todayShipmentCount": 24,
      "todayReturnCount": 2,
      "todayReceivingCount": 17,
      "pendingReceivingCount": 3,
      "incompleteOperationCount": 3,
      "failedEDespatchCount": 0,
      "averageReceivingMinutes": 42.75,
      "healthStatus": "Warning"
    }
  ]
}
```

UI ekraninda ustte `summary` sayaclari, altta `warehouses` tablosu gosterilebilir. Depo satirina tiklandiginda ayni depo numarasiyla belge akis liste endpointine gidilerek ilgili belgeler acilabilir.

### Urun Dagilimlari

Bu ekran `docs/rapor-modulu-envanter.md` icindeki `FrmDagilim` workflow'unun API karsiligidir. Rapor degildir; satis verisine gore dagilim onerisi uretir, `Furpa.dbo.STOK_DAGILIM` kaydi acar, bolge bilgilendirme durumunu yonetir ve kesinlestirmede Mikro `DEPOLAR_ARASI_SIPARISLER` satirlari olusturur.

Menu:

- Modul: `OperasyonIslemleri`
- Menu: `UrunDagilimlari`
- Route kok: `api/operasyon-islemleri/urun-dagilimlari`

Yetki kodlari:

- `operasyon-islemleri.urun-dagilimlari.list`
- `operasyon-islemleri.urun-dagilimlari.detail`
- `operasyon-islemleri.urun-dagilimlari.create`
- `operasyon-islemleri.urun-dagilimlari.update`
- `operasyon-islemleri.urun-dagilimlari.delete`

Endpoint ozeti:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `GET /api/operasyon-islemleri/urun-dagilimlari/dagitim-merkezleri` | - | - | `ProductDistributionCenterDto[]` | `list` |
| `POST /api/operasyon-islemleri/urun-dagilimlari/oneri` | body | `ProductDistributionProposalHttpRequest` | `ProductDistributionProposalDto` | `create` |
| `POST /api/operasyon-islemleri/urun-dagilimlari/dengele` | body | `ProductDistributionBalanceHttpRequest` | `ProductDistributionBalanceDto` | `create` |
| `GET /api/operasyon-islemleri/urun-dagilimlari` | query | `ProductDistributionListHttpRequest` | `ProductDistributionListItemDto[]` | `list` |
| `GET /api/operasyon-islemleri/urun-dagilimlari/{documentNo}` | path | - | `ProductDistributionDetailDto` | `detail` |
| `POST /api/operasyon-islemleri/urun-dagilimlari` | body | `ProductDistributionSaveHttpRequest` | `ProductDistributionDetailDto` | `create` |
| `PUT /api/operasyon-islemleri/urun-dagilimlari/{documentNo}` | body | `ProductDistributionSaveHttpRequest` | `ProductDistributionDetailDto` | `update` |
| `POST /api/operasyon-islemleri/urun-dagilimlari/{documentNo}/bilgilendir` | body | `ProductDistributionNotifyHttpRequest` | `ProductDistributionNotificationDto` | `update` |
| `POST /api/operasyon-islemleri/urun-dagilimlari/{documentNo}/kesinlestir` | body | `ProductDistributionFinalizeHttpRequest` | `ProductDistributionFinalizeDto` | `update` |
| `DELETE /api/operasyon-islemleri/urun-dagilimlari/{documentNo}` | path | - | `ProductDistributionDeleteDto` | `delete` |

Route notu:

- `/docs/api/urun-dagilimlari` UI dokuman/yardim sayfasi olabilir; veri ceken backend route degildir.
- Backend veri route ailesi yalniz `api/operasyon-islemleri/urun-dagilimlari` kokundedir.

Request modelleri:

`ProductDistributionListHttpRequest` query:

```text
status                         int?       0, 1, 2
documentNo                     string?    max 50
stockCode                      string?    max 25
distributionCenterWarehouseNo  int?
createdFrom                    DateTime?
createdTo                      DateTime?
take                           int?       1..500
```

`ProductDistributionProposalHttpRequest` body:

```text
stockCode                      string     zorunlu, max 25
distributionCenterWarehouseNo  int        zorunlu
totalCaseQuantity              int?       1+; eski hedef toplam koli alani
targetCaseQuantity             int?       1+; onerilen hedef toplam koli alani
allocatedCaseQuantity          int?       1+; uyumluluk aliasi, targetCaseQuantity bos ise hedef olarak kabul edilir
salesDayCount                  int?       1..365, bos ise 42
referenceDate                  DateTime?  bos ise bugun
includeBranchesWithoutSales    bool
```


`ProductDistributionBalanceHttpRequest` body:

```text
stockCode                      string     zorunlu, max 25
targetCaseQuantity             int        0+; hedef toplam koli
salesDayCount                  int?       1..365, bos ise 42
referenceDate                  DateTime?  bos ise bugun
lines                          ProductDistributionBalanceLineHttpRequest[] zorunlu, min 1
```

`ProductDistributionBalanceLineHttpRequest` body:

```text
warehouseNo                    int        zorunlu
warehouseName                  string?    max 100
regionCode                     string?    max 25
lastSalesQuantity              double
currentStockQuantity           double
companyAverageDailySales       double
branchAverageDailySales        double
caseQuantity                   int        0+; mevcut satir koli
isLocked                       bool       true ise satir dengelemede degismez
```
`ProductDistributionSaveHttpRequest` body:

```text
stockCode                      string     zorunlu, max 25
distributionCenterWarehouseNo  int        zorunlu
totalCaseQuantity              int        0+; eski hedef toplam koli alani
targetCaseQuantity             int?       0+; onerilen hedef toplam koli alani
allocatedCaseQuantity          int?       0+; uyumluluk aliasi, targetCaseQuantity bos ise hedef olarak kabul edilir
distributedBy                  string?    max 100
lines                          ProductDistributionSaveLineHttpRequest[] zorunlu, min 1
```

`ProductDistributionSaveLineHttpRequest` body:

```text
warehouseNo                    int        zorunlu
caseQuantity                   int        0+; satir hedef/dagilim koli miktari
unitQuantity                   int?
lastSalesQuantity              double?
companyAverageDailySales       double?
branchAverageDailySales        double?
```

`ProductDistributionNotifyHttpRequest` body:

```text
notifyBy                       string?    max 100
markStockOrderingStopped       bool       default true
```

Bilgilendirme mail davranisi:

- SMTP ayarlari `ProductDistributionMail` config bolumunden okunur.
- Varsayilan `Enabled=false`; bu durumda endpoint eski hazirlama akisini korur, mail gondermez ve durum `Bilgilendirildi` olur.
- `Enabled=true` ise API `Bolge_Yoneticileri.bolge_muduru_eposta` adreslerine bolge bazli HTML mail gonderir.
- Mail konusu bolge bazlidir: `{regionCode}. Bolge, Urun Dagilimi Hk.`
- Mail basarili gitmeden yeni kayit `Bilgilendirildi` durumuna alinmaz. Eksik/gecersiz e-posta veya SMTP hatasi varsa `mailResults` icinde doner.
- Parola dokumanda veya kaynak kodda tutulmaz; canli ortamda `ProductDistributionMail__Password` gibi secret/env ayariyla verilmelidir.

`ProductDistributionFinalizeHttpRequest` body:

```text
finalizeBy                     string?    max 100
orderDate                      DateTime?
deliveryDate                   DateTime?
allowFinalizeWithoutNotification bool      geriye uyum alani; artik kesinlestirme icin zorunlu degil
```

Response DTO katalogu:

`ProductDistributionCenterDto`

```text
warehouseNo                    int
warehouseName                  string
regionCode                     string?
```

`ProductDistributionProposalDto`

```text
stock                          ProductDistributionStockDto
distributionCenter             ProductDistributionWarehouseDto
summary                        ProductDistributionSummaryDto
lines                          ProductDistributionLineDto[]
warnings                       string[]
```

`ProductDistributionBalanceDto`

```text
stock                          ProductDistributionStockDto
summary                        ProductDistributionSummaryDto
lines                          ProductDistributionBalanceLineDto[]
warnings                       string[]
```

`ProductDistributionBalanceLineDto`

```text
warehouseNo                    int
warehouseName                  string
regionCode                     string?
regionName                     string?    UI etiketi; orn. Bolge 1
lastSalesQuantity              double     miktar; quantityUnitName birimiyle okunur
currentStockQuantity           double     miktar; quantityUnitName birimiyle okunur
companyAverageDailySales       double     gunluk ortalama miktar; quantityUnitName/gun
branchAverageDailySales        double     gunluk ortalama miktar; quantityUnitName/gun
salesSharePercent              double     0..100; toplam satis icindeki pay
caseSharePercent               double     0..100; toplam koli icindeki pay
originalCaseQuantity           int        dengeleme oncesi koli
caseQuantity                   int        dengeleme sonrasi koli
caseDelta                      int        degisim, arti/eksi olabilir
unitQuantity                   int        caseQuantity * stock.packageFactor
quantityUnitName               string     miktar/adet alanlarinin birimi
caseUnitName                   string     koli alanlarinin birimi
isLocked                       bool
reason                         string     locked, balanced-up, balanced-down, unchanged
```

`ProductDistributionListItemDto`

```text
documentNo                     string
status                         ProductDistributionStatusDto
createdAt                      DateTime
finalizedAt                    DateTime?
stock                          ProductDistributionStockDto
distributionCenter             ProductDistributionWarehouseDto
distributedBy                  string?
lineCount                      int
totalCaseQuantity              int
totalUnitQuantity              int
```

`ProductDistributionDetailDto`

```text
header                         ProductDistributionHeaderDto
summary                        ProductDistributionSummaryDto
lines                          ProductDistributionLineDto[]
availableActions               ProductDistributionActionDto[]
```

`ProductDistributionHeaderDto`

```text
documentNo                     string
status                         ProductDistributionStatusDto
createdAt                      DateTime
finalizedAt                    DateTime?
stock                          ProductDistributionStockDto
distributionCenter             ProductDistributionWarehouseDto
distributedBy                  string?
```

`ProductDistributionStockDto`

```text
stockCode                      string
stockName                      string
barcode                        string?
packageFactor                  int
unitName                       string?
```

`ProductDistributionWarehouseDto`

```text
warehouseNo                    int
warehouseName                  string
regionCode                     string?
```

`ProductDistributionLineDto`

```text
warehouseNo                    int
warehouseName                  string
regionCode                     string?
regionName                     string?    UI etiketi; orn. Bolge 1
lastSalesQuantity              double     miktar; quantityUnitName birimiyle okunur
currentStockQuantity           double     miktar; quantityUnitName birimiyle okunur
companyAverageDailySales       double     gunluk ortalama miktar; quantityUnitName/gun
branchAverageDailySales        double     gunluk ortalama miktar; quantityUnitName/gun
salesSharePercent              double     0..100; toplam satis icindeki pay
caseSharePercent               double     0..100; toplam koli icindeki pay
caseQuantity                   int        koli; caseUnitName birimiyle okunur
unitQuantity                   int        caseQuantity * stock.packageFactor; quantityUnitName birimiyle okunur
quantityUnitName               string     miktar/adet alanlarinin birimi
caseUnitName                   string     koli alanlarinin birimi
reason                         string
```

`ProductDistributionSummaryDto`

```text
salesDayCount                  int
referenceDate                  DateTime
lineCount                      int
totalCaseQuantity              int
allocatedCaseQuantity          int
caseDifference                 int
totalUnitQuantity              int
isBalanced                     bool
message                        string
```

`ProductDistributionStatusDto`

```text
code                           int
name                           string
severity                       string
```

`ProductDistributionActionDto`

```text
code                           string     update, delete, notify, finalize
label                          string
enabled                        bool
reason                         string?
```

`ProductDistributionNotificationDto`

```text
documentNo                     string
status                         ProductDistributionStatusDto
statusChanged                  bool
stockOrderingStopped           bool
recipients                     ProductDistributionNotificationRecipientDto[]
subject                        string
message                        string
mailSendingEnabled             bool       SMTP gonderimi acik mi
sentEmailCount                 int
failedEmailCount               int
mailResults                    ProductDistributionNotificationMailResultDto[]
```

`ProductDistributionNotificationMailResultDto`

```text
regionCode                     string?
managerName                    string?
email                          string?
sent                           bool
message                        string
```

`ProductDistributionNotificationRecipientDto`

```text
regionCode                     string?
managerName                    string?
email                          string?
lineCount                      int
totalCaseQuantity              int
totalUnitQuantity              int
```

`ProductDistributionFinalizeDto`

```text
documentNo                     string
status                         ProductDistributionStatusDto
finalizedAt                    DateTime
createdDocumentCount           int
existingDocumentCount          int
totalUnitQuantity              int
orders                         ProductDistributionWarehouseOrderDto[]
```

`ProductDistributionWarehouseOrderDto`

```text
documentSerie                  string
documentOrderNo                int
inWarehouseNo                  int
inWarehouseName                string
outWarehouseNo                 int
outWarehouseName               string
lineCount                      int
totalUnitQuantity              int
alreadyExisted                 bool
```

`ProductDistributionDeleteDto`

```text
documentNo                     string
deleted                        bool
message                        string
```
Onerilen UI akisi:

1. Ekran acilisinda `GET .../dagitim-merkezleri` ile cikis depolari yuklenir.
2. Kullanici stok, dagitim merkezi ve toplam koli girer.
3. `POST .../oneri` cagrilir; API son 42 gun satisini varsayilan alir ve toplam koliyi satis payina gore tam dagitir.
4. Kullanici hedef veya satir koli degistirirse `POST .../dengele` ile kilitli satirlari koruyan yeni dagilim alinabilir.
5. UI `summary.isBalanced = true` beklemeli; kullanici satir degistirirse toplam koli farki sifirlanmadan kaydet butonu aktif olmamalidir.
6. `POST .../urun-dagilimlari` ile `STOK_DAGILIM` kaydi olusur ve `status.code = 0` doner.
7. Bilgilendirme opsiyoneldir. `POST .../{documentNo}/bilgilendir` SMTP aciksa bolge yoneticilerine mail gonderir; basarili olursa statusu `1` yapar, stok kartinda `sto_siparis_dursun = 1` isaretler ve `mailResults` ozetini doner.
8. SMTP kapaliysa eski davranis korunur; API mail gondermeden bilgilendirme bilgisini hazirlar ve statusu `1` yapar. UI `mailSendingEnabled`, `sentEmailCount`, `failedEmailCount` ve `mailResults` alanlarini kullaniciya gosterebilir.
9. `POST .../{documentNo}/kesinlestir` status `0` veya `1` iken calisir, statusu `2` yapar ve her pozitif adetli sube icin Mikro depo siparisi uretir. Ayni evrak tekrar cagrilirsa aciklama/evrak kontroluyle mevcut siparisleri tekrar uretmez.

`POST .../oneri` request:

```json
{
  "stockCode": "153.01.0001",
  "distributionCenterWarehouseNo": 50,
  "totalCaseQuantity": 120,
  "salesDayCount": 42,
  "referenceDate": "2026-07-24",
  "includeBranchesWithoutSales": false
}
```

Oneri response alanlari:

- `stock.packageFactor`: koli ici katsayi; adet = koli * katsayi.
- `summary.totalCaseQuantity`: kullanicinin girdigi toplam koli.
- `summary.allocatedCaseQuantity`: satirlara dagitilan koli.
- `summary.caseDifference`: kaydetmeden once `0` olmalidir.
- `lines[].regionCode` / `lines[].regionName`: subenin bolge kodu ve UI etiketi.
- `lines[].lastSalesQuantity`: secili donemde subenin satis miktari; birimi `quantityUnitName` alanindadir.
- `lines[].currentStockQuantity`: referans tarihte subedeki mevcut stok; birimi `quantityUnitName` alanindadir.
- `lines[].companyAverageDailySales` ve `lines[].branchAverageDailySales`: gunluk ortalama miktar; yuzde degildir.
- `lines[].salesSharePercent`: subenin toplam satis icindeki yuzdesi, `0..100`.
- `lines[].caseSharePercent`: subeye ayrilan kolinin toplam koli icindeki yuzdesi, `0..100`.
- `lines[].caseQuantity`: UI gridinde duzenlenebilir satir hedef/dagilim koli miktari; birimi `caseUnitName` alanindadir.
- `lines[].unitQuantity`: Mikro siparisine gidecek miktar; `caseQuantity * stock.packageFactor`, birimi `quantityUnitName` alanindadir.
- `lines[].reason`: `sales-share`, `equal-share`, `rounded-to-zero`, `no-period-sales` gibi UI ipucu.

`POST .../urun-dagilimlari/dengele` request:

```json
{
  "stockCode": "153.01.0001",
  "targetCaseQuantity": 2000,
  "lines": [
    {
      "warehouseNo": 110,
      "warehouseName": "Sube 110",
      "regionCode": "1",
      "lastSalesQuantity": 84,
      "currentStockQuantity": 12,
      "companyAverageDailySales": 1.45,
      "branchAverageDailySales": 2,
      "caseQuantity": 2100,
      "isLocked": false
    }
  ]
}
```

`POST/PUT .../urun-dagilimlari` request:

```json
{
  "stockCode": "153.01.0001",
  "distributionCenterWarehouseNo": 50,
  "targetCaseQuantity": 2100,
  "allocatedCaseQuantity": 2100,
  "distributedBy": "MERKEZ",
  "lines": [
    {
      "warehouseNo": 110,
      "caseQuantity": 2100,
      "unitQuantity": 25200,
      "lastSalesQuantity": 84,
      "companyAverageDailySales": 1.45,
      "branchAverageDailySales": 2
    }
  ]
}
```

Kayit kurallari:

- `POST .../dengele`, `targetCaseQuantity` ile mevcut satir toplam farkini kapatir; `isLocked=true` satirlara dokunmaz.
- `targetCaseQuantity` doluysa `lines[].caseQuantity` toplami bu degerle ayni olmalidir; bos ise `allocatedCaseQuantity`, o da bos ise `totalCaseQuantity` esas alinir.
- `unitQuantity` bos gonderilirse API `caseQuantity * stock.packageFactor` hesaplar.
- Ayni sube/depo iki satirda gonderilemez.
- Dagitim merkezi satir deposu olarak gonderilemez.
- Sadece `status.code = 0` olan kayitlar guncellenebilir veya silinebilir.

Durumlar:

| Kod | Ad | UI davranisi |
|---|---|---|
| `0` | `Kaydedildi` | Guncelle, sil, bilgilendir ve kesinlestir acik |
| `1` | `Bilgilendirildi` | Kesinlestir acik; guncelle/sil kapali |
| `2` | `Dagilim Yapildi` | Tum yazma aksiyonlari kapali |

`POST .../{documentNo}/bilgilendir` request:

```json
{
  "notifyBy": "MERKEZ",
  "markStockOrderingStopped": true
}
```

Response `recipients` alaninda bolge kodu, bolge muduru e-postasi, satir sayisi, toplam koli ve toplam adet doner. E-posta kaydi yoksa response basarili gelebilir ama `message` alaninda alici bulunamadigi belirtilir; UI bu durumda uyari gostermelidir.

`POST .../{documentNo}/kesinlestir` request:

```json
{
  "finalizeBy": "MERKEZ",
  "orderDate": "2026-07-24",
  "deliveryDate": "2026-07-24",
  "allowFinalizeWithoutNotification": false
}
```

Kesinlestirme sonucu:

- `orders[].documentSerie`: API `D{subeDepoNo}` serisi uretir.
- `orders[].documentOrderNo`: Mikro `DEPOLAR_ARASI_SIPARISLER` sira numarasi.
- `orders[].alreadyExisted`: ayni dagilim evraki icin daha once uretilmis siparis yeniden kullanildiysa `true`.
- `createdDocumentCount` ve `existingDocumentCount` UI toast/ozet icin kullanilabilir.

Teknik notlar:

- `STOK_DAGILIM.Evrak_No` uretimi transaction icinde `UPDLOCK/HOLDLOCK` ile yapilir; eski `max()+1` yarisi azaltildi.
- Eski `STOK_DAGILIM` kayitlarinda sayisal alanlar `nvarchar` ve virgullu ondalik (`1,6`) gelebilir; liste, detay ve bilgilendirme okumalari bu alanlari `TRY_CONVERT` + virgulu noktaya cevirme ile toleransli okur.
- `GET .../{documentNo}` detayinda Mikro stok karti artik yoksa response yine doner; `stockName` stok kodu fallback'iyle doldurulur.
- Kesinlestirme Mikro tarafinda `ssip_aciklama = "Dagilim {documentNo}"` ile izlenir ve tekrar cagrida cift siparis uretilmez.
- Bu endpointlerde depo scope claim'i uygulanmaz; merkezi operasyon kullanimi icin gorunurluk/yazma kontrolu permission setiyle yonetilir.

Temel route:

- `api/operasyon-islemleri/belge-akis-takibi`

Yetki ve depo ayrimi:

- Login olmus her depo kullanicisi kendi deposuyla iliskili akislari gorur.
- Depo kullanicisinda query ile gelen `warehouseNo` dikkate alinmaz; backend JWT icindeki depo numarasini kullanir.
- `operasyon-islemleri.belge-akis-takibi.all-warehouses` yetkisi olan kullanici tum depolari gorebilir ve `warehouseNo` filtresini kullanabilir.
- Detay endpointinde depo kullanicisi sadece kaynak veya hedef deposu kendi deposu olan akisi acabilir; aksi durumda `404` doner.
- Permission katalogunda `operasyon-islemleri.belge-akis-takibi.list`, `operasyon-islemleri.belge-akis-takibi.detail` ve `operasyon-islemleri.belge-akis-takibi.all-warehouses` kodlari vardir. API erisiminde veri ayrimi permission ve depo uzerinden yapilir.

Takibi acma/kapatma:

```json
"DocumentFlowTracking": {
  "Enabled": true
}
```

- `Enabled = true` ise yeni olaylar kaydedilir.
- `Enabled = false` ise yeni olay yazimi durur; mevcut eski kayitlar liste/detaydan okunmaya devam eder.
- Liste response icindeki `trackingEnabled` alani UI'nin "takip kapali" uyarisini gostermesi icin eklenmistir.
- Takip yazimi islem akisini bozmaz; takip kaydi sirasinda hata olursa asil sevk/iade/siparis islemi devam eder, hata loglanir.

Takip edilen isler:

- Verilen firma siparisi olusturma
- Verilen depo siparisi olusturma
- Onerilen firma siparisini siparise cevirme
- Onerilen depo siparisini siparise cevirme
- Firma sevki olusturma
- Depolar arasi sevk olusturma
- Firma iadesi olusturma
- Depo iadesi olusturma
- Firma mal kabul olusturma
- Depo mal kabul/kabul etme
- E-irsaliye gonderimi basarili/basarisiz sonucu
- Mikro evrak duzenleme islemleri:
  - Stok karti guncelleme
  - Stok depo ayari guncelleme/silme
  - Depo karti guncelleme
  - Cari karti guncelleme
  - Satis fiyati ekleme/guncelleme/silme
  - Stok hareket evraki guncelleme/silme
  - Cari hareket evraki guncelleme/silme

Mikro evrak duzenleme kaynakli akislar:

- Kart ve fiyat islemleri `StockCard`, `WarehouseCard`, `CustomerCard`, `StockSalesPrice` belge tipleriyle gorunur.
- Stok hareket evraki bilinen bir operasyon evrakiyse mevcut akis tipine baglanir:
  - firma sevki: `CompanyShipment`
  - firma iadesi: `CompanyReturn`
  - firma mal kabul: `CompanyReceiving`
  - depolar arasi sevk: `InterWarehouseShipment`
  - depo iadesi: `WarehouseReturn`
- Taninamayan stok/cari hareketleri `StockMovementDocument` veya `CustomerMovementDocument` olarak gorunur.
- Soft delete ve hard delete ikisi de timeline'da `DocumentDeleted` adimi olarak gorunur; olay mesaji silme modunu aciklar.
- Stok/cari hareket guncelleme timeline'da `DocumentUpdated` adimi olarak gorunur.

#### Belge Akis Liste

```http
GET /api/operasyon-islemleri/belge-akis-takibi?warehouseNo=1&startDate=2026-07-01&endDate=2026-07-01&documentType=CompanyShipment&status=Failed&search=FRM2026000000101&take=100
```

Query alanlari:

- `warehouseNo`: opsiyonel. Sadece `operasyon-islemleri.belge-akis-takibi.all-warehouses` yetkisi varsa etkilidir.
- `startDate`: opsiyonel. `updatedAtUtc` uzerinden filtreler.
- `endDate`: opsiyonel. Gun sonu dahil olacak sekilde filtreler.
- `documentType`: opsiyonel enum.
- `status`: opsiyonel enum.
- `search`: opsiyonel. `documentSerie`, `documentNo`, `externalDocumentNo`, `externalUuid` icinde arar.
- `take`: 1-500 arasi, varsayilan `100`.

Response:

```json
{
  "trackingEnabled": true,
  "totalCount": 1,
  "items": [
    {
      "id": "11111111-1111-1111-1111-111111111111",
      "documentType": "CompanyShipment",
      "sourceWarehouseNo": 1,
      "targetWarehouseNo": null,
      "documentSerie": "FRM2026",
      "documentOrderNo": 101,
      "documentNo": "FRM2026000000101",
      "externalDocumentNo": "FRM2026000000101",
      "externalUuid": "22222222-2222-2222-2222-222222222222",
      "status": "Succeeded",
      "currentStep": "EDespatchSubmission",
      "lastError": null,
      "createdAtUtc": "2026-07-01T08:10:00Z",
      "updatedAtUtc": "2026-07-01T08:12:00Z"
    }
  ]
}
```

#### Belge Akis Detay

```http
GET /api/operasyon-islemleri/belge-akis-takibi/{id}
```

Response liste alanlarina ek olarak `events` timeline doner:

```json
{
  "id": "11111111-1111-1111-1111-111111111111",
  "flowKey": "CompanyShipment:1:FRM2026:101",
  "documentType": "CompanyShipment",
  "sourceWarehouseNo": 1,
  "targetWarehouseNo": null,
  "documentSerie": "FRM2026",
  "documentOrderNo": 101,
  "documentNo": "FRM2026000000101",
  "externalDocumentNo": "FRM2026000000101",
  "externalUuid": "22222222-2222-2222-2222-222222222222",
  "status": "Succeeded",
  "currentStep": "EDespatchSubmission",
  "lastError": null,
  "lastChangedByUserId": null,
  "createdAtUtc": "2026-07-01T08:10:00Z",
  "updatedAtUtc": "2026-07-01T08:12:00Z",
  "events": [
    {
      "id": "33333333-3333-3333-3333-333333333333",
      "step": "DocumentCreated",
      "status": "Succeeded",
      "message": "Firma sevki olusturuldu.",
      "error": null,
      "changedByUserId": "44444444-4444-4444-4444-444444444444",
      "occurredAtUtc": "2026-07-01T08:10:00Z"
    },
    {
      "id": "55555555-5555-5555-5555-555555555555",
      "step": "EDespatchSubmission",
      "status": "Succeeded",
      "message": "E-irsaliye Uyumsoft'a gonderildi.",
      "error": null,
      "changedByUserId": null,
      "occurredAtUtc": "2026-07-01T08:12:00Z"
    }
  ]
}
```

Enum degerleri:

```text
documentType:
  CompanyShipment
  InterWarehouseShipment
  CompanyReturn
  WarehouseReturn
  CompanyReceiving
  IssuedCompanyOrder
  IssuedWarehouseOrder

status:
  Succeeded
  Failed

step/currentStep:
  DocumentCreated
  OrderCreated
  EDespatchSubmission
  WarehouseReceivingAccepted
```

UI onerisi:

- Liste gridinde belge tipi, kaynak depo, hedef depo, belge no, e-belge no, son adim, durum, son hata ve guncelleme tarihi kolonlari yeterlidir.
- Durum badge'i `Succeeded` icin yesil, `Failed` icin kirmizi kullanilabilir.
- Detayda timeline sirali gosterilmeli; hata varsa `error` alanindan kopyalanabilir teknik detay acilmalidir.
- `operasyon-islemleri.belge-akis-takibi.all-warehouses` varsa depo filtresi gosterilmeli; yoksa depo filtresi gizlenmeli veya pasif olmalidir.
- `trackingEnabled = false` ise ekranda "Yeni akis kaydi kapali, eski kayitlar goruntuleniyor" uyarisi gosterilmelidir.

Operasyon modulu notlari:

- bu modul Hangfire yerine uygulama ici hosted queue kullanir
- UI canli progress stream beklememelidir; polling yeterlidir
- `scalesfile` icin `BranchDetails` kaydi ve `ScalesType` bilgisi zorunludur
- `scalesfile`, `productbarcodeplunofile`, `productbarcodeplonofile`, `cashierfile`, `promofile`, `customerfile` ve `einvoicevnofile` endpointlerinde `warehouseNo` query parametresi opsiyoneldir; yalniz `operasyon-islemleri.operations.all-warehouses` yetkisi icin depo secimi anlamlidir
- `productbarcodeplunofile` ve `cashierfile` lokal export uretebilir; branch network path varsa ek olarak paylasima da kopyalanir
- `promofile` `PROMO.DAT`, `NOPROMO.DAT`, `NOCEK.DAT`, `NOYEMEK.DAT`, `GRUP.DAT`, `OZELKOD.DAT`, `EFATVNO.DAT` ve kasa bazli `MESAJ.xxx` dosyalarini uretir
- `customerfile` sadece `EFATVNO.DAT` uretir; kaynak `ConnectionStrings:UyumConnection` / `UYUMConnection` / `UyumDbConnection` altindaki `dbo.CarilerGib` tablosudur.
- export klasoru config'deki `OperationsExport:BasePath` ile verilebilir; bos ise uygulama altindaki `App_Data/OperationsExports` kullanilir
- `promofile` icin `ConnectionStrings:MaydayConnection` ve `ConnectionStrings:UyumConnection` ayarlari gereklidir

## Entegrasyon Islemleri

Bu modul, eski `Furpa.WorkerService` akisini yeni API icinde worker + manuel endpoint ayrimi ile yonetmek icin eklendi. UI tarafinda ana ekran `workbench/is-merkezi` mantigiyla, teknik detaylar ise gelismis bolumlerde kurgulanmalidir.

Yeni sade is merkezi yaklasimi:

- UI ana ekrani once `GET /api/integrations/axata-sync/workbench` veya Turkce alias olarak `GET /api/integrations/axata-sync/is-merkezi` endpointini cagirmalidir.
- Bu endpoint veri yazmaz; panel, ekran bolumleri, operasyon gruplari, endpoint sozlugu, terimler ve kurallari tek response'ta doner.
- Normal UI route ailesi `operations/...`, manuel kurtarma route ailesi `recovery/...`, teknik route ailesi `advanced/...` olarak ayrildi.
- Eski `live/...` ve `manual/...` route'lari geriye uyumluluk icin calismaya devam eder; yeni UI bunlari ana route olarak kullanmamalidir.
- Teknik listeler, raw farklar, job/outbox ve payload detaylari "Gelismis/teknik detay" olarak `GET /api/integrations/axata-sync/audit` ve `advanced/...` endpointlerinden acilmalidir.

Sade route ailesi:

| Route ailesi | Amac | Veri yazar mi? | UI konumu |
|---|---|---:|---|
| `GET /workbench`, `GET /is-merkezi` | Tum AXATA ekranini kuracak is merkezi response'u | Hayir | Ilk cagri |
| `GET /panel` | Yalniz ozet kartlar, akis ve oncelikli belgeler | Hayir | Hafif yenileme |
| `GET /status`, `GET /connection-test`, `GET /profiles`, `GET /audit` | Durum, baglanti, profil ve teknik fark analizi | Hayir | Kontrol/teknik detay |
| `operations/product-master/...` | Urun master onizle/gonder | Preview hayir, dispatch evet | Master veri |
| `operations/{taskCode}/documents/...` | Mikro evrak aday/onizle/AXATA'ya gonder | Dispatch evet | Mikro -> AXATA |
| `operations/c01-shipment/...` | C01 depo sevki onizle/import/rescue | Import evet | AXATA -> Mikro |
| `operations/c02-company-shipment/...` | C02 firma sevki onizle/import | Import evet | AXATA -> Mikro |
| `operations/c03-legacy-movement/...` | C03 legacy hareket onizle/import | Import evet | Gelismis operasyon |
| `operations/c04-legacy-transfer/...` | C04/C4 legacy transfer onizle/import | Import evet | Gelismis operasyon |
| `operations/g01-company-receiving/...` | G01 ATF firma mal kabul onizle/import | Import evet | AXATA -> Mikro |
| `operations/g02-warehouse-receiving/...` | G02 depo kabul onizle/import/rescue | Import evet | AXATA -> Mikro |
| `operations/dynamic-census/...` | AXATA stok duzeltme onizle/import | Import evet | Stok duzeltme |
| `recovery/...` | Elle body, serbest mal kabul/sayim, bekleyen depo kabul | Evet | Manuel kurtarma |
| `advanced/...` | Job, outbox, generic task execute | Duruma gore | Teknik detay |

Sonuc odakli kullanim icin onerilen ana yollar:

- Urun master: `operations/product-master/preview` ile kontrol et, secili/toplu urun icin `operations/product-master/dispatch` kullan. Job/outbox akisini ikincil/teknik arac olarak goster.
- Mikro -> AXATA evrak kurtarma: once `operations/{taskCode}/documents/candidates`, sonra `preview`, son olarak gercek gonderim icin `dispatch` kullan. `advanced/{taskCode}/documents/outbox` AXATA'ya gondermez, sadece dosya hazirlar.
- AXATA -> Mikro C01 sevk: once `operations/c01-shipment/preview`, uygun kayit varsa `operations/c01-shipment/import` kullan. Import ekraninda `acknowledge` secimi kullaniciya acik gosterilmelidir.
- AXATA -> Mikro C02 firma sevk: once `operations/c02-company-shipment/preview`, uygun kayit varsa `operations/c02-company-shipment/import` kullan. Backend firma sevki yazar, siparis satiri linkini `sth_sip_uid` ile kurar ve siparis teslim miktarini gunceller.
- AXATA -> Mikro C03/C4 legacy hareketler: once ilgili `operations/c03-legacy-movement/preview` veya `operations/c04-legacy-transfer/preview`, sonra `import` kullan. UI bu aksiyonlari gelismis/operasyonel import olarak etiketlemelidir.
- AXATA -> Mikro G01 firma mal kabul: once `operations/g01-company-receiving/preview`, uygun kayit varsa `import` kullan.
- AXATA -> Mikro G02 depo mal kabul: once `operations/g02-warehouse-receiving/preview`, uygun kayit varsa `import` kullan. Backend bekleyen Mikro sevk fisini kabul eder, siparis teslim miktarini AXATA kabul miktarina gore duzeltir ve sonra AXATA ack atar.
- AXATA -> Mikro DynamicCensus: once `operations/dynamic-census/preview`, uygun satir varsa `import` kullan. Backend `vw_stok_duzeltme` satirlarini Mikro stok duzeltme hareketine cevirir.
- Manuel body/import ekranlari: yalnizca operasyon AXATA body bilgisini elle sagladiginda kullanilacak yardimci araclar olarak konumlandir.

AXATA ekranlari icin genel sadelik ilkesi:

- UI ana hedefi "Mikro ve AXATA arasindaki durumu goster, uygun aksiyonu oner, kullanici onayi ile islemi tamamla" olmalidir.
- Her ekran once is sonucunu gostermelidir: bekleyen kayit, hatali kayit, gonderilebilir kayit, aktarildi/aktarilmadi durumu.
- Teknik kavramlar (`job`, `outbox`, `scheduler`, `fetch profile`, servis operasyon adi, raw payload) ana ekranda baskin olmamalidir; gerekirse "Gelismis/teknik detay" bolumunde katlanabilir sekilde gosterilmelidir.
- Kullaniciya ayni is icin birden fazla benzer buton sunma. Ana aksiyonlar `Onizle`, `Gonder`, `Mikro'ya Isle`, `Kabul Et`, `Tekrar Dene` gibi sonuc odakli olmalidir.
- Veri yazan aksiyonlar her zaman acikca ayristirilmalidir: AXATA'ya yazar, Mikro'ya yazar, sadece kontrol eder, sadece dosya hazirlar.
- Manuel islemler kurtarma ve operasyon destegi icindir; normal akis yerine gecen ana yol gibi sunulmamalidir.
- Liste ve fark ekranlari karar vermeye yardim etmelidir; kullanici ham payload veya servis alanlari icinde kaybolmadan hangi kayit icin hangi aksiyonun onerildigini gormelidir.

Temel route:

- `api/integrations/axata-sync`

Yetki kodlari:

- `entegrasyon-islemleri.axata-senkronizasyonu.list`
- `entegrasyon-islemleri.axata-senkronizasyonu.detail`
- `entegrasyon-islemleri.axata-senkronizasyonu.create`
- `entegrasyon-islemleri.axata-senkronizasyonu.update`

Desteklenen task kodlari:

- `firm-master-sync`
- `product-master-sync`
- `issued-warehouse-order-sync`
- `received-company-order-sync`
- `warehouse-inbound-order-sync`
- `company-receiving-sync`
- `inventory-count-sync`

Execution mode:

- `DryRun`
  - canli veriden payload uretilir ama dosya yazilmaz
- `Outbox`
  - payload `App_Data/AxataSynchronizationOutbox` altina JSON olarak yazilir
- `Live`
  - task destekliyorsa AXATA WCF servisine canli dispatch veya AXATA'dan Mikro'ya canli import yapar

Mevcut endpointler:

Not: Bu listede eski teknik route'lar da bulunabilir. Yeni UI icin oncelikli route'lar `workbench/is-merkezi`, `operations/...`, `recovery/...` ve `advanced/...` aileleridir. Eski `live/...` ve `manual/...` route'lari geriye uyumluluk icin korunur.

- `GET /api/integrations/axata-sync`
  - modulu, aktif task'lari, schedule ayarlarini ve son job'lari doner
  - response `AxataSynchronizationOverviewDto`
- `GET /api/integrations/axata-sync/status`
  - `GET /api/integrations/axata-sync` icin sade alias
  - veri yazmaz
- `GET /api/integrations/axata-sync/health`
  - Mikro SQL, Furpa SQL ve AXATA endpoint erisimi icin probe sonucunu doner
  - response `AxataSynchronizationConnectionTestDto`
- `GET /api/integrations/axata-sync/connection-test`
  - `health` icin sade alias
  - veri yazmaz
- `GET /api/integrations/axata-sync/fetch-profiles`
  - eski worker parity icin planlanan AXATA fetch/import profillerini listeler
  - her profil icin bugunku fallback route ve implementasyon durumu gorulebilir
  - response `AxataSynchronizationFetchProfilesOverviewDto`
- `GET /api/integrations/axata-sync/profiles`
  - `fetch-profiles` icin sade alias
  - veri yazmaz
- `GET /api/integrations/axata-sync/workbench?startDate=2026-08-05&endDate=2026-08-06&warehouseNo=50&take=50`
  - UI ana ekrani icin onerilen birincil endpointtir
  - `panel`, `screenSections`, `operationGroups`, `endpointGroups`, `glossary` ve `rules` alanlarini tek response'ta doner
  - veri yazmaz
  - response `AxataSynchronizationWorkbenchDto`
- `GET /api/integrations/axata-sync/is-merkezi?startDate=2026-08-05&endDate=2026-08-06&warehouseNo=50&take=50`
  - `workbench` icin Turkce route alias
  - veri yazmaz
- `GET /api/integrations/axata-sync/panel?startDate=2026-08-05&endDate=2026-08-06&warehouseNo=50&take=50`
  - UI ana ekrani icin sade kontrol paneli doner
  - Mikro -> AXATA -> Mikro akis durumunu tek response'ta ozetler
  - veri yazmaz; manuel mudahale icin kullanilacak route bilgilerini `actions` ve `primaryEndpoints` icinde verir
  - response `AxataSynchronizationPanelDto`
- `GET /api/integrations/axata-sync/live/products/preview?productCode=URUN001&take=20`
  - Mikro aktif stok, tum barkod ve birimlerini AXATA `addSKUMaster` paketinde onizler; veri yazmaz
  - response `AxataProductSynchronizationPreviewDto`
- `POST /api/integrations/axata-sync/live/products/dispatch`
  - `productCodes` bos ise `take` kadar aktif urunu, dolu ise secili urunleri 100'luk paketlerle AXATA `addSKUMaster` operasyonuna gonderir
  - response `AxataProductSynchronizationExecuteDto`
- `POST /api/integrations/axata-sync/live/products/{productCode}/dispatch`
  - tek Mikro urununu master, tum barkodlari ve birimleriyle AXATA'ya canli gonderir
  - response `AxataProductSynchronizationExecuteDto`
- `GET /api/integrations/axata-sync/live/audit/overview?startDate=2026-06-08&endDate=2026-06-08&warehouseNo=50&take=50`
  - eski worker calisirken Mikro ve AXATA arasindaki farklari kontrol eder; veri yazmaz
  - Mikro -> AXATA siparis tarafinda `ssip_special1` worker basari bayragini raporlar
  - `ssip_special1=1` oldugu halde belge genelinde Mikro sevk linki olmayan siparisleri `STOK_HAREKETLERI_EK.sth_subesip_uid` uzerinden yakalar; kismi linkli belgeleri ayri fark listesine alir
  - AXATA -> Mikro sevk tarafinda `getOutBoundDeliveryListAsync` ile `C01/C02/C03/C4`, `Status=0` kuyrugunu okur
  - C01 icin Mikro siparis satiri ve sevk fisi linkini de kontrol eder
  - response icindeki `operations` UI kontrol kulesi kartlari icin hazir aksiyon/route bilgisi tasir
  - response `AxataIntegrationAuditDto`
- `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/preview?movementType=C02&take=20`
  - AXATA `AxataServicePool.svc/getOutBoundDeliveryListAsync` uzerinden secili `MovementType` ve `Status=0` kuyrugunu canli okur
  - desteklenen hareket tipleri: `C01`, `C02`, `C03`, `C4`; `C04` alias olarak `C4` kabul edilir
  - Mikro'ya veri yazmaz ve AXATA ack/status guncellemez
  - C02/C03/C4 icin UI'nin kuyruk kontrol ekraninda kullanacagi guvenli preview endpoint'idir
  - response `AxataOutboundDeliveryQueuePreviewDto`
- `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/by-date?date=2026-06-19`
  - AXATA `ENT006` tablosundaki sevk basliklarini secilen tarihe gore listeler
  - tarih filtresi `ENT006.S06ITAR = yyyyMMdd` seklinde uygulanir
  - `ENT007` satirlari teslimat numarasina gore ozetlenir; satir sayisi ve toplam miktar response'a eklenir
  - Mikro'ya veya AXATA'ya veri yazmaz
  - response `AxataOutboundDeliveriesByDateDto`
- `GET /api/integrations/axata-sync/tasks/{taskCode}/preview?warehouseNo=1&take=10`
  - secili task icin canli veriden preview payload dondurur
  - response `AxataSynchronizationPreviewDto`
- `POST /api/integrations/axata-sync/jobs`
  - body ile task adi verilip job kuyruga alinir
  - response `202 Accepted`
  - body `AxataSynchronizationJobDto`
- `POST /api/integrations/axata-sync/tasks/{taskCode}/execute`
  - task code route'tan gelir, body ile execution mode ve opsiyonel `warehouseNo` verilir
  - response `202 Accepted`
  - body `AxataSynchronizationJobDto`
- `GET /api/integrations/axata-sync/jobs/{jobId}`
  - kuyruga alinan entegrasyon job detayini doner
  - response `AxataSynchronizationJobDetailDto`
- `POST /api/integrations/axata-sync/manual/tasks/{taskCode}/documents/preview`
  - worker kuyruguna girmeden tek evrak bazli payload preview doner
  - response `AxataSynchronizationManualDocumentDto`
  - yalnizca `issued-warehouse-order-sync`, `warehouse-inbound-order-sync`, `company-receiving-sync`, `inventory-count-sync` icin gecerlidir
- `POST /api/integrations/axata-sync/manual/tasks/{taskCode}/documents/execute`
  - tek evrak icin anlik `DryRun` veya `Outbox` calistirir
  - response `AxataSynchronizationManualDocumentDto`
  - worker disabled olsa bile, genel entegrasyon acik oldugu surece operasyonel kurtarma amacli kullanilabilir
- `GET /api/integrations/axata-sync/manual/tasks/{taskCode}/documents/candidates?warehouseNo=50&startDate=2026-04-23&endDate=2026-04-29&skip=0&take=25`
  - manuel kurtarma icin uygun evrak adaylarini listeler
  - response `AxataSynchronizationManualDocumentCandidatesDto`
  - `take` 1-100 araligindadir; 100'den fazla kayit icin `skip/take` ile sayfalama yapilir
  - 150 kayit ornegi: once `skip=0&take=100`, sonra `skip=100&take=100` cagrilir; ikinci response 50 item doner
  - `issued-warehouse-order-sync` icin `warehouseNo`, hedef depo degil AXATA kaynak/cikis depodur; backend Mikro `ssip_cikdepo = warehouseNo` filtresiyle aday listeler
  - `warehouse-inbound-order-sync` icin `warehouseNo`, AXATA giris/hedef depodur; backend Mikro `ssip_girdepo = warehouseNo` filtresiyle aday listeler
  - bu nedenle audit `unsyncedWarehouseOrders` icinde `outWarehouseNo=50` gelen evrak, candidates endpoint'inde `warehouseNo=50` ile aranmalidir
- `POST /api/integrations/axata-sync/manual/tasks/{taskCode}/documents/preview-batch`
  - secilen birden fazla evrak icin toplu payload preview doner
  - response `AxataSynchronizationManualDocumentBatchDto`
- `POST /api/integrations/axata-sync/manual/tasks/{taskCode}/documents/execute-batch`
  - secilen birden fazla evrak icin toplu `DryRun` veya `Outbox` calistirir
  - response `AxataSynchronizationManualDocumentBatchDto`
  - `ContinueOnError = true` ise hatali evraklar `Failures` icine yazilir, diger evraklar devam eder
- `POST /api/integrations/axata-sync/manual/tasks/{taskCode}/documents/dispatch`
  - secilen tek evraki eski AXATA worker kontratina uygun WCF client ile canli gonderir
  - response `AxataSynchronizationManualDispatchDto`
  - su an `issued-warehouse-order-sync`, `warehouse-inbound-order-sync` ve `company-receiving-sync` icin tanimlidir
  - `issued-warehouse-order-sync` worker parity icin `C01` hareket kodu ile `addOutboundOrder*` operasyonunu kullanir
  - `issued-warehouse-order-sync` basarili donerse `ssip_special1=1` bayragi `MikroWriteRouting:IssuedWarehouseOrder=Database` iken DB update ile, `MikroApi` iken `POST /Api/apiMethods/DepolarArasiSiparisDuzeltV2` ile satir `ssip_Guid` degerleri uzerinden yazilir; MikroApi modunda DB fallback yoktur ve yazim read-only geri okuma ile dogrulanir
  - `warehouse-inbound-order-sync` worker parity icin `G02` hareket kodu ile `addInboundOrder*` operasyonunu kullanir; basarili donerse `ssip_special1=1` bayragi `ssip_girdepo = warehouseNo` evreninde isaretlenir
  - `company-receiving-sync` worker parity icin verilen firma/satinalma siparisini `G01` hareket kodu ile `addInboundOrder*` operasyonuna gonderir; basarili donerse `sip_special1=1` bayragi isaretlenir
- `POST /api/integrations/axata-sync/manual/tasks/{taskCode}/documents/dispatch-batch`
  - secilen birden fazla evraki canli WCF dispatch ile toplu gonderir
  - response `AxataSynchronizationManualDispatchBatchDto`
  - `ContinueOnError = true` ise red alan veya hata veren evraklar `Failures` icine yazilir
- `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/preview?take=20`
  - AXATA `AxataServicePool.svc/getOutBoundDeliveryListAsync` uzerinden `MovementType=C01`, `Status=0` bekleyen depo sevklerini okur
  - Mikro depolar arasi siparis eslesmesini, kalan teslim miktarini ve import edilebilirlik durumunu gosterir
  - response `AxataOutboundDeliveryImportPreviewDto`
- `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/import`
  - AXATA C01 bekleyen teslimatlarini Mikro depolar arasi sevk fisine cevirir
  - Mikro fis ve `STOK_HAREKETLERI_EK` linkleri basarili yazildiktan sonra AXATA `AxataServicePoolEXT.svc/updIntegrationTableAsync` ile `ENT006.S06STAT=1` yapar
  - response `AxataOutboundDeliveryImportExecuteDto`
- `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c02/preview?take=20`
  - AXATA `getOutBoundDeliveryListAsync` uzerinden `MovementType=C02`, `Status=0` bekleyen firma sevk teslimatlarini okur
  - `S06TESL=seri.sira` ile Mikro alinan firma siparisi, `S07KALN/S07SKOD` ile siparis satiri eslestirilir
  - Mikro'ya veri yazmaz; `canImport`, miktar ve duplicate durumunu doner
  - response `AxataOutboundDeliveryImportPreviewDto`
- `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c02/import`
  - uygun C02 teslimatini Mikro firma sevk hareketine cevirir
  - `sip_teslim_miktar` alanlarini gunceller; `acknowledge=true` ise `ENT006.S06STAT=1` yapar
  - body `AxataOutboundDeliveryImportExecuteHttpRequest`
  - response `AxataOutboundDeliveryImportExecuteDto`
- `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c03/preview?take=20`
  - AXATA `MovementType=C03`, `Status=0` bekleyen legacy ozel cikis/firma iade teslimatlarini okur
  - Mikro'ya veri yazmaz; import edilebilirlik ve duplicate durumunu doner
  - response `AxataOutboundDeliveryImportPreviewDto`
- `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c03/import`
  - uygun C03 teslimatini eski worker mantigina uygun `F50` firma iade/ozel cikis hareketine cevirir
  - cari kodu AXATA `S06FIRM` alanindan alinir; bu alan bos ise import guvenli sayilmaz
  - `acknowledge=true` ise `ENT006.S06STAT=1` yapar
  - body `AxataOutboundDeliveryImportExecuteHttpRequest`
  - response `AxataOutboundDeliveryImportExecuteDto`
- `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c04/preview?take=20`
  - AXATA `MovementType=C4`, `Status=0` bekleyen legacy 50 -> 51 hareketlerini okur
  - route adi `c04`, AXATA sorgu hareket tipi `C4` olarak calisir
  - response `AxataOutboundDeliveryImportPreviewDto`
- `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c04/import`
  - uygun C4 teslimatini eski worker mantigina uygun 50 -> 51 depo hareketine cevirir
  - `acknowledge=true` ise `ENT006.S06STAT=1` yapar
  - body `AxataOutboundDeliveryImportExecuteHttpRequest`
  - response `AxataOutboundDeliveryImportExecuteDto`
- `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/{documentSerie}/{documentOrderNo}/preview?status=1`
  - `sentWarehouseOrdersMissingMikroShipments` listesindeki tek belge icin AXATA'dan `OrderNumber=seri.sira`, `MovementType=C01` teslimat detayini arar
  - `status` bos verilirse once `0`, sonra `1` denenir
  - Mikro'ya veri yazmaz; satir, depo, kalan miktar ve link durumunu kontrol eder
  - response `AxataOutboundDeliveryImportPreviewDto`
- `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/{documentSerie}/{documentOrderNo}/import`
  - AXATA'da teslimati kesilmis ama Mikro sevk linki eksik C01 belgeyi Mikro depolar arasi sevk fisine cevirir
  - AXATA satirlari Mikro siparis satirlariyla guvenli eslesmezse veya AXATA miktari Mikro kalan siparis miktarini asarsa veri yazmaz
  - Guvenli eslesme sirasi: `S07KALN + S07SKOD`, 1-bazli satir no farki, son olarak tekil stok + kalan miktar eslesmesi
  - body `AxataOutboundDeliveryDocumentImportExecuteHttpRequest`
  - response `AxataOutboundDeliveryImportExecuteDto`
- `GET /api/integrations/axata-sync/live/axata/inbound-deliveries/g02/preview?take=20`
  - AXATA `AxataServicePool.svc/getInboundDeliveryListAsync` uzerinden `MovementType=G02`, `Status=0` bekleyen giris teslimatlarini okur
  - `S16BNUM=seri.sira` ile Mikro `DEPOLAR_ARASI_SIPARISLER` satirlarini, `STOK_HAREKETLERI_EK.sth_subesip_uid` ile bekleyen sevk fisi linklerini eslestirir
  - Mikro'ya veri yazmaz; `canImport`, `warning`, AXATA/Mikro miktarlari ve mevcut link durumunu doner
  - response `AxataOutboundDeliveryImportPreviewDto`
- `POST /api/integrations/axata-sync/live/axata/inbound-deliveries/g02/import`
  - AXATA G02 bekleyen teslimatlarini Mikro'daki bekleyen depo mal kabul fisine uygular
  - Backend yeni sevk fisi yaratmaz; mevcut `STOK_HAREKETLERI` bekleyen sevk satirlarini `AcceptWarehouseReceivingUseCase` ile kabul eder
  - Kabulden sonra ilgili depo siparisi `ssip_teslim_miktar` alanlari AXATA kabul miktarina gore guncellenir; kabul miktari siparis miktarini asmadan kapanis (`ssip_kapat_fl`) yeniden hesaplanir
  - `acknowledge=true` ise Mikro yazim basarili olduktan sonra AXATA EXT `updIntegrationTableAsync` ile `ENT016_MST.S16STAT=1`, `IDField=S16ID` yapilir
  - response `AxataOutboundDeliveryImportExecuteDto`
- `GET /api/integrations/axata-sync/live/axata/inbound-deliveries/g02/documents/{documentSerie}/{documentOrderNo}/preview?status=1`
  - tek G02 belgeyi AXATA'dan `OrderNumber=seri.sira`, `MovementType=G02` ile arar; `status` bos ise once `0`, sonra `1` denenir
  - satir, depo, bekleyen kabul ve mevcut kabul durumunu kontrol eder; veri yazmaz
  - response `AxataOutboundDeliveryImportPreviewDto`
- `POST /api/integrations/axata-sync/live/axata/inbound-deliveries/g02/documents/{documentSerie}/{documentOrderNo}/import`
  - tek G02 belgeyi bekleyen Mikro sevk fisine kabul olarak uygular
  - AXATA satirlari Mikro siparis ve sevk satirlariyla guvenli eslesmezse veri yazmaz
  - body `AxataOutboundDeliveryDocumentImportExecuteHttpRequest`
  - response `AxataOutboundDeliveryImportExecuteDto`
- `GET /api/integrations/axata-sync/live/axata/inbound-atf/g01/preview?take=20`
  - AXATA `getInboundATFListAsync` uzerinden `MovementType=G01`, `Status=0` bekleyen ATF satirlarini okur
  - `S16SIPN=seri.sira` Mikro firma siparisi, `S16KALN` siparis satiri kabul edilir
  - Mikro'ya veri yazmaz; `canImport`, siparis/miktar/duplicate durumunu doner
  - response `AxataG01InboundAtfPreviewDto`
- `POST /api/integrations/axata-sync/live/axata/inbound-atf/g01/import`
  - uygun G01 ATF satirlarini Mikro `DocumentType=13` firma mal kabul hareketine cevirir
  - `MikroWriteRouting:CompanyReceiving=Database` ise eski DB transaction yolu kullanilir ve `sip_teslim_miktar` backend tarafinda guncellenir
  - `MikroWriteRouting:CompanyReceiving=MikroApi` ise `IrsaliyeKaydetV2` yolu kullanilir; backend olusan hareketlerde `sth_sip_uid` linklerini geri okuyup dogrulamadan AXATA ack atmaz
  - `acknowledge=true` ise basarili yazimdan sonra `ENT016_IRS.S16STAT=1` yapar
  - body `AxataOutboundDeliveryImportExecuteHttpRequest`
  - response `AxataG01InboundAtfExecuteDto`
- `GET /api/integrations/axata-sync/live/axata/dynamic-census/preview?take=50`
  - AXATA EXT `getViewDataAsync` ile `vw_stok_duzeltme` satirlarini okur
  - `S11STIP=1` giris, diger tipler cikis stok duzeltmesi olarak yorumlanir
  - Mikro'ya veri yazmaz; `canImport`, duplicate ve hedef hareket tiplerini doner
  - response `AxataDynamicCensusPreviewDto`
- `POST /api/integrations/axata-sync/live/axata/dynamic-census/import`
  - uygun `vw_stok_duzeltme` satirlarini Mikro `STOK_HAREKETLERI` dynamic census hareketine cevirir
  - `acknowledge=true` ise `ENT011.S11STAT=1` yapar
  - body `AxataOutboundDeliveryImportExecuteHttpRequest`
  - response `AxataDynamicCensusExecuteDto`
- `POST /api/integrations/axata-sync/manual/axata/outbound-deliveries/inter-warehouse-shipments`
  - AXATA outbound delivery verisini AXATA-native body ile Mikro depolar arasi sevke cevirir
  - response `CreateInterWarehouseShipmentResponse`
- `POST /api/integrations/axata-sync/manual/axata/outbound-deliveries/inter-warehouse-shipments/batch`
  - birden fazla AXATA outbound delivery kaydini toplu Mikro sevkine cevirir
  - response `AxataManualOutboundDeliveryBatchResponse`
- `POST /api/integrations/axata-sync/manual/axata/inbound-atf/company-receivings`
  - AXATA inbound ATF verisini AXATA-native body ile Mikro firma mal kabule cevirir
  - native ATF modelinde satir bazli fiili kabul alani yoktur; `quantity` hem `dispatchQuantity` hem `acceptedQuantity` gibi yazilir
  - bu nedenle bu endpoint'te `quantity` tek basina fark/iade olusturmaz
  - response `CreateCompanyReceivingResponse`
- `POST /api/integrations/axata-sync/manual/axata/inbound-atf/company-receivings/batch`
  - birden fazla AXATA inbound ATF kaydini toplu Mikro firma mal kabule cevirir
  - her item icin native ATF miktari tam kabul gibi islenir
  - response `AxataManualIncomingCompanyReceivingBatchResponse`
- `POST /api/integrations/axata-sync/manual/incoming/company-receivings`
  - AXATA'dan elle toparlanan firma mal kabul verisini Mikro'ya manuel yazar
  - body `CreateCompanyReceivingHttpRequest` ile aynidir; `dispatchQuantity`, `acceptedQuantity` ve `autoCreateReturnForPartialAcceptance` desteklenir
  - `acceptedQuantity < dispatchQuantity` ise firma iadesi otomatik olusabilir, e-irsaliye gonderimi yine kullanici aksiyonudur
  - response `CreateCompanyReceivingResponse`
- `POST /api/integrations/axata-sync/manual/incoming/company-receivings/batch`
  - birden fazla firma mal kabul payload'ini tek cagrida Mikro'ya yazar
  - her item tekli `manual/incoming/company-receivings` ile ayni otomatik iade kuralini kullanir
  - response `AxataManualIncomingCompanyReceivingBatchResponse`
- `POST /api/integrations/axata-sync/manual/incoming/inventory-counts`
  - AXATA'dan elle toparlanan sayim verisini Mikro'ya manuel yazar
  - response `CreateInventoryCountResponse`
- `POST /api/integrations/axata-sync/manual/incoming/inventory-counts/batch`
  - birden fazla sayim payload'ini tek cagrida Mikro'ya yazar
  - response `AxataManualIncomingInventoryCountBatchResponse`
- `GET /api/integrations/axata-sync/manual/incoming/warehouse-receivings?warehouseNo=1&startDate=2026-04-23&endDate=2026-04-29`
  - kabul bekleyen depo mal kabullerini entegrasyon ekranindan listeler
  - response `IReadOnlyCollection<WarehouseShippingListItemDto>`
- `GET /api/integrations/axata-sync/manual/incoming/warehouse-receivings/{documentSerie}/{documentOrderNo}?warehouseNo=1`
  - tek bekleyen depo mal kabul detayini doner
  - response `WarehouseShippingDetailDto`
- `POST /api/integrations/axata-sync/manual/incoming/warehouse-receivings/{documentSerie}/{documentOrderNo}/accept`
  - mevcut bekleyen depo mal kabulunu manuel kabul eder
  - response `AcceptWarehouseReceivingResponse`
- `POST /api/integrations/axata-sync/manual/incoming/warehouse-receivings/accept-batch`
  - birden fazla bekleyen depo mal kabulunu toplu kabul eder
  - response `AxataManualIncomingWarehouseReceivingBatchResponse`

Sade panel response ana alanlari:

```json
{
  "title": "Mikro -> AXATA -> Mikro fark kontrolu",
  "state": "MikroTransferRequired",
  "severity": "Critical",
  "message": "Mikro'da 120 siparis var; AXATA siparis eslesmesi 120, AXATA sevk 80, Mikro'ya baglanan sevk 75...",
  "isInSync": false,
  "generatedAtUtc": "2026-08-06T09:00:00Z",
  "startDate": "2026-08-05T00:00:00",
  "endDate": "2026-08-06T00:00:00",
  "warehouseNo": 50,
  "summaryCards": [
    {
      "code": "ready-to-import-mikro",
      "label": "Mikro'ya islenecek",
      "value": 5,
      "severity": "Critical",
      "description": "AXATA sevki hazir olup Mikro sevk linki eksik olan ve import edilebilecek belgeler."
    }
  ],
  "flowSteps": [
    {
      "code": "mikro-transfer",
      "label": "4. Mikro sevk donusu",
      "state": "Difference",
      "severity": "Critical",
      "currentDocumentCount": 75,
      "expectedDocumentCount": 80,
      "differenceDocumentCount": 5,
      "description": "AXATA'da sevki olusmus belgelerin Mikro STOK_HAREKETLERI_EK siparis linki var mi kontrol eder.",
      "listRoute": "/api/integrations/axata-sync/audit#interventionCandidates"
    }
  ],
  "actions": [
    {
      "code": "sent-to-axata-missing-mikro-shipment",
      "label": "AXATA sevk kesilmis Mikro donus eksik",
      "state": "ActionRequired",
      "severity": "Critical",
      "documentCount": 5,
      "lineCount": 20,
      "quantity": 430.0,
      "canExecute": true,
      "writesData": true,
      "listRoute": "/api/integrations/axata-sync/audit#sentWarehouseOrdersMissingMikroShipments",
      "previewRoute": "/api/integrations/axata-sync/operations/c01-shipment/documents/{documentSerie}/{documentOrderNo}/preview",
      "executeRoute": "/api/integrations/axata-sync/operations/c01-shipment/documents/{documentSerie}/{documentOrderNo}/import",
      "description": "AXATA C01 outbound delivery kaydi bulunan pozitif miktarli sevklerde Mikro link yoksa rescue yapilabilir."
    }
  ],
  "priorityDocuments": [
    {
      "documentSerie": "F50",
      "documentOrderNo": 16122,
      "documentNo": "F50.16122",
      "documentDate": "2026-08-05T00:00:00",
      "sourceWarehouseNo": 50,
      "targetWarehouseNo": 172,
      "synchronizationState": "WaitingForMikroTransfer",
      "synchronizationStateLabel": "AXATA sevki var, Mikro sevk linki yok",
      "severity": "Critical",
      "recommendedActionCode": "RESCUE_COMPLETED_C01",
      "recommendedActionTitle": "Tamamlanmis AXATA SEV'inin eksik Mikro linkini isle",
      "canExecute": true,
      "previewRoute": "/api/integrations/axata-sync/operations/c01-shipment/documents/F50/16122/preview?status=1",
      "executeRoute": "/api/integrations/axata-sync/operations/c01-shipment/documents/F50/16122/import",
      "mikroOrderQuantity": 430.0,
      "mikroDeliveredQuantity": 0.0,
      "axataShipmentQuantity": 430.0,
      "mikroLinkedShipmentQuantity": 0.0,
      "existingMikroShipmentLineCount": 0,
      "existingMikroShipmentQuantity": 0.0,
      "existingMikroShipmentDocumentNo": null,
      "quantitySummary": "Siparis 430 / Teslim 0 / AXATA sevk 430 / Mikro link 0",
      "reason": "AXATA'da 430 miktar SEV var, Mikro siparisine bagli sevk bulunamadi."
    }
  ],
  "primaryEndpoints": [
    {
      "code": "panel",
      "label": "Sade panel",
      "method": "GET",
      "route": "/api/integrations/axata-sync/panel",
      "writesData": false,
      "description": "UI ana ekrani icin ozet kartlari, akis adimlari, aksiyonlar ve oncelikli belgeleri dondurur."
    }
  ],
  "notes": []
}
```

Sade panel UI yerlesimi:

- Ust satir: `summaryCards`.
- Orta alan: `flowSteps`; her adim icin durum rengi `severity` alanindan alinmali.
- Sag/alt aksiyon listesi: `actions`; `writesData=true` aksiyonlarda onay modali acilmali.
- Belge listesi: `priorityDocuments`; UI gorunen durum icin `synchronizationStateLabel`, miktar ozet satiri icin `quantitySummary`, aksiyon butonu icin `recommendedActionTitle` kullanmali. `synchronizationState` teknik kod olarak filtre/renk/esleme icin saklanmali.
- `canExecute=true` ise once `previewRoute`, kullanici onayindan sonra `executeRoute` cagrilmali.
- `WaitingForMikroTransfer` teknik olarak "AXATA sevki var ama Mikro siparis satirlarina bagli `STOK_HAREKETLERI_EK.sth_subesip_uid` hareketi bulunamadi" anlamina gelir. `Siparis x / AXATA sevk x / Mikro link 0` goruluyorsa belge AXATA'da tamamlanmis olabilir ama Mikro'ya donus linki eksiktir; bu durumda C01 belge rescue/import preview ile kontrol edilmelidir.
- `MikroOrderDeliveredMissingLink` / `REVIEW_DELIVERED_ORDER_MISSING_LINK`: Mikro siparisinde `ssip_teslim_miktar` doludur ama `STOK_HAREKETLERI_EK.sth_subesip_uid` linki yoktur. Bu durumda UI import/execute butonu gostermemeli; cunku AXATA miktari kalan siparisten buyuk gorunur ve tekrar import duplicate/fazla sevk riski tasir.
- `MikroShipmentLinkMissing` / `REVIEW_EXISTING_MIKRO_SHIPMENT_LINK`: Mikro'da sevk fisi bulunur ama siparis satiri linki yoktur. UI bunu link/evrak izi onarimi veya manuel inceleme olarak gostermeli; otomatik C01 import butonu acilmamalidir.
- Teknik detay butonu: ayni query ile `GET /api/integrations/axata-sync/audit`.

AXATA live import ortak request modeli:

```json
{
  "take": 20,
  "continueOnError": true,
  "acknowledge": true,
  "dateMode": "today",
  "movementDate": null,
  "documentDate": null
}
```

- `take`: kac belge/satir islenecek. Outbound/G01/G02 icin 1-200, DynamicCensus icin backend 500'e kadar kabul eder.
- `continueOnError`: `true` ise hatali belge `failures` listesine eklenir ve digerleri denenir.
- `acknowledge`: `true` ise Mikro yazimi basarili olduktan sonra AXATA EXT status alanlari `1` yapilir. Yazim basarisizsa ack atilmaz.
- `dateMode`: C01 AXATA -> Mikro depo sevki icin kullanilir. Bos/null veya `today/bugun/current/api-date` gonderilirse Mikro `sth_tarih` ve `sth_belge_tarih` bugun olur. `axata/axata-date/teslimat/teslimat-tarihi` gonderilirse AXATA `S06ITAR` teslimat tarihi kullanilir. `custom/manual/elle` gonderilirse `movementDate` zorunludur, `documentDate` bos ise `movementDate` kullanilir. C02/C03/C04/G02/G01 akislari bu alanlari dikkate almaz.
- UI sade kullanim icin kisa route'lari tercih etmelidir; eski `live/axata/...` ve `operations/...` route'lari geriye uyumluluk icin calismaya devam eder.

AXATA import kisa route ozeti:

| Islem | Kisa route | Eski/uyumlu route |
| --- | --- | --- |
| Outbound kuyruk | `GET /api/integrations/axata-sync/outbound-deliveries?movementType=C01&take=20` | `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/preview` |
| C01 preview | `GET /api/integrations/axata-sync/c01/preview?take=20` | `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/preview` |
| C01 import | `POST /api/integrations/axata-sync/c01/import` | `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/import` |
| C01 belge preview | `GET /api/integrations/axata-sync/c01/documents/{documentSerie}/{documentOrderNo}/preview?status=1` | `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/{documentSerie}/{documentOrderNo}/preview` |
| C01 belge import | `POST /api/integrations/axata-sync/c01/documents/{documentSerie}/{documentOrderNo}/import` | `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/{documentSerie}/{documentOrderNo}/import` |
| C02 preview/import | `GET/POST /api/integrations/axata-sync/c02/preview|import` | `GET/POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c02/preview|import` |
| C03 preview/import | `GET/POST /api/integrations/axata-sync/c03/preview|import` | `GET/POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c03/preview|import` |
| C04 preview/import | `GET/POST /api/integrations/axata-sync/c04/preview|import` | `GET/POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c04/preview|import` |
| G02 preview/import | `GET/POST /api/integrations/axata-sync/g02/preview|import` | `GET/POST /api/integrations/axata-sync/live/axata/inbound-deliveries/g02/preview|import` |
| G02 belge preview/import | `GET/POST /api/integrations/axata-sync/g02/documents/{documentSerie}/{documentOrderNo}/preview|import` | `GET/POST /api/integrations/axata-sync/live/axata/inbound-deliveries/g02/documents/{documentSerie}/{documentOrderNo}/preview|import` |

C01/C02/C03/C04/G02 import preview response ortak ana alanlari:

```json
{
  "movementType": "C02",
  "pendingStatus": "0",
  "generatedAtUtc": "2026-08-05T10:30:00Z",
  "totalFetchedDocumentCount": 12,
  "returnedDocumentCount": 10,
  "totalLineCount": 45,
  "totalQuantity": 123.45,
  "documents": [
    {
      "axataSequenceNo": 123456,
      "axataDeliveryNo": "F50.15035",
      "documentSerie": "F50",
      "documentOrderNo": 15035,
      "movementType": "C02",
      "status": "0",
      "sourceWarehouseNo": 1,
      "targetWarehouseNo": 1,
      "axataDate": "2026-08-05T00:00:00",
      "axataLineCount": 3,
      "axataQuantity": 30.0,
      "mikroOrderLineCount": 3,
      "mikroOrderQuantity": 30.0,
      "mikroDeliveredQuantity": 0.0,
      "existingLinkedMovementLineCount": 0,
      "canImport": true,
      "warning": null
    }
  ],
  "notes": []
}
```

C01/C02/C03/C04/G02 import execute response ortak ana alanlari:

```json
{
  "movementType": "C02",
  "pendingStatus": "0",
  "generatedAtUtc": "2026-08-05T10:31:00Z",
  "requestedDocumentCount": 10,
  "succeededDocumentCount": 9,
  "failedDocumentCount": 1,
  "skippedDocumentCount": 1,
  "createdMovementLineCount": 27,
  "createdMovementQuantity": 90.0,
  "results": [
    {
      "axataSequenceNo": 123456,
      "axataDeliveryNo": "F50.15035",
      "documentSerie": "F50",
      "documentOrderNo": 15035,
      "movementSerie": "F50",
      "movementOrderNo": 15035,
      "createdMovementLineCount": 3,
      "createdMovementQuantity": 30.0,
      "acknowledged": true,
      "message": "Mikro kaydi olusturuldu ve AXATA ack atildi.",
      "axataDate": "2026-08-05T00:00:00",
      "movementDate": "2026-08-06T00:00:00",
      "documentDate": "2026-08-06T00:00:00",
      "movementDocumentNo": "F50-15035"
    }
  ],
  "failures": [
    {
      "axataSequenceNo": 123457,
      "axataDeliveryNo": "F50.15036",
      "errorMessage": "Mikro siparis satirlariyla guvenli eslesmedi."
    }
  ],
  "notes": []
}
```

- `axataDate`: AXATA teslimat/kabul kaydindan gelen tarih. C01 icin kaynak `ENT006.S06ITAR`.
- `movementDate`: Mikro hareket tarihi. C01 defaultta import gunudur; `dateMode=axata` verilirse AXATA tarihi olur.
- `documentDate`: Mikro belge tarihi. Bos birakilirsa `movementDate` ile ayni yazilir.
- `movementDocumentNo`: UI'da gostermek icin olusan Mikro evrak numarasi (`movementSerie-movementOrderNo`).

G01 preview response ana farklari:

```json
{
  "movementType": "G01",
  "pendingStatus": "0",
  "totalFetchedLineCount": 20,
  "returnedDocumentCount": 5,
  "importableDocumentCount": 4,
  "documents": [
    {
      "orderDocumentNo": "F50.1001",
      "documentSerie": "F50",
      "documentOrderNo": 1001,
      "customerCode": "CARI001",
      "despatchNo": "IRS123",
      "warehouseNo": 50,
      "axataLineCount": 2,
      "axataQuantity": 12.5,
      "mikroOrderLineCount": 2,
      "mikroOrderQuantity": 12.5,
      "mikroDeliveredQuantity": 0.0,
      "existingMovementLineCount": 0,
      "canImport": true,
      "warning": null
    }
  ]
}
```

DynamicCensus preview response ana farklari:

```json
{
  "viewName": "vw_stok_duzeltme",
  "pendingStatus": "0",
  "totalFetchedLineCount": 30,
  "returnedLineCount": 30,
  "importableLineCount": 28,
  "existingMovementLineCount": 2,
  "totalQuantity": 150.0,
  "lines": [
    {
      "rowNo": "98765",
      "stockCode": "001234",
      "quantity": 5.0,
      "axataStockType": "1",
      "movementType": 0,
      "movementGenre": 10,
      "documentType": 12,
      "documentSerie": "X",
      "inputWarehouseNo": 50,
      "outputWarehouseNo": 1,
      "canImport": true,
      "existingMovementExists": false,
      "warning": null
    }
  ]
}
```

UI icin endpoint davranis rehberi:

| UI bolumu | Endpoint | Ne yapar | Veri yazar mi? | UI aksiyonu |
|---|---|---|---|---|
| Sade Panel | `GET /api/integrations/axata-sync/panel` | Ozet kartlar, akis adimlari, aksiyonlar ve oncelikli belgeleri tek response'ta verir | Hayir | Sayfa ana verisi olarak cagir |
| Genel Durum | `GET /api/integrations/axata-sync` | Task listesini, aktif/pasif durumlari, worker/scheduler bilgisini ve son job'lari getirir | Hayir | Sayfa acilisinda cagir |
| Genel Durum | `GET /api/integrations/axata-sync/health` | Mikro SQL, Furpa SQL, AXATA Main ve EXT endpoint erisimini kontrol eder | Hayir | "Baglanti testi" veya otomatik durum karti |
| Profil Katalogu | `GET /api/integrations/axata-sync/fetch-profiles` | AXATA servislerinden hangi profillerin okunabilecegini ve backendde hangi seviyede desteklendigini listeler | Hayir | UI butonlarini capability'ye gore ac/kapat |
| Fark Analizi | `GET /api/integrations/axata-sync/live/audit/overview` | Mikro kaynakli siparis gonderimini, AXATA kaynakli sevk donusunu, pending/iptal AXATA sevklerini ve Mikro link durumunu birlikte kontrol eder | Hayir | "Kontrol et" butonu |
| AXATA Kuyruk | `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/preview` | C01/C02/C03/C4 pending outbound delivery kuyrugunu canli okur | Hayir | "AXATA kuyrugunu goster" butonu |
| AXATA Sevk Tarihi | `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/by-date` | AXATA `ENT006.S06ITAR` tarihine gore sevk basliklarini ve `ENT007` satir ozetini listeler | Hayir | "Tarihe gore sevkleri getir" |
| C01 Import | `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/preview` | C01 pending teslimatlari Mikro siparis satirlariyla eslestirir | Hayir | "C01 import onizle" butonu |
| C01 Import | `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/import` | Uygun C01 teslimatini Mikro depolar arasi sevk fisine cevirir; istenirse AXATA ack atar | Evet | "C01'i Mikro'ya isle" butonu |
| C02 Import | `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c02/preview` | C02 pending teslimatlari Mikro firma siparisiyle eslestirir | Hayir | "C02 import onizle" |
| C02 Import | `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c02/import` | Uygun C02 teslimatini Mikro firma sevk hareketine cevirir; istenirse AXATA ack atar | Evet | "C02'yi Mikro'ya isle" |
| C03 Import | `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c03/preview` | C03 legacy teslimatlari kontrol eder | Hayir | "C03 import onizle" |
| C03 Import | `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c03/import` | Uygun C03 teslimatini Mikro legacy firma iade/ozel cikis hareketine cevirir | Evet | "C03'u Mikro'ya isle" |
| C04 Import | `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c04/preview` | AXATA `C4` legacy teslimatlari kontrol eder | Hayir | "C04 import onizle" |
| C04 Import | `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c04/import` | Uygun C4 teslimatini Mikro 50 -> 51 legacy hareketine cevirir | Evet | "C04'u Mikro'ya isle" |
| C01 Rescue | `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/{serie}/{sira}/preview` | AXATA'da C01 sevki olusmus ama belge genelinde Mikro sevk linki olmayan tek belgeyi AXATA'dan belge bazinda arar | Hayir | "Eksik sevki onizle" |
| C01 Rescue | `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/{serie}/{sira}/import` | AXATA teslimat detayi bulunur ve Mikro siparisiyle eslesirse eksik Mikro sevkini olusturur | Evet | "Eksik sevki Mikro'ya dusur" |
| G02 Import | `GET /api/integrations/axata-sync/live/axata/inbound-deliveries/g02/preview` | G02 pending giris teslimatlarini Mikro siparis ve bekleyen sevk fisiyle eslestirir | Hayir | "G02 kabul onizle" butonu |
| G02 Import | `POST /api/integrations/axata-sync/live/axata/inbound-deliveries/g02/import` | Uygun G02 teslimatini mevcut Mikro bekleyen sevk fisine mal kabul olarak uygular; istenirse AXATA ack atar | Evet | "G02'yi Mikro'ya kabul et" butonu |
| G02 Rescue | `GET /api/integrations/axata-sync/live/axata/inbound-deliveries/g02/documents/{serie}/{sira}/preview` | Tek G02 belgeyi AXATA'dan belge bazinda arar ve Mikro kabul/link durumunu denetler | Hayir | "G02 belge onizle" |
| G02 Rescue | `POST /api/integrations/axata-sync/live/axata/inbound-deliveries/g02/documents/{serie}/{sira}/import` | Tek G02 belgeyi bekleyen Mikro sevk fisine kabul olarak uygular | Evet | "G02 belgeyi kabul et" |
| G01 Import | `GET /api/integrations/axata-sync/live/axata/inbound-atf/g01/preview` | G01 ATF satirlarini Mikro firma siparisiyle eslestirir | Hayir | "G01 ATF onizle" |
| G01 Import | `POST /api/integrations/axata-sync/live/axata/inbound-atf/g01/import` | Uygun G01 ATF satirlarini Mikro firma mal kabul hareketine cevirir | Evet | "G01 ATF'yi isle" |
| DynamicCensus | `GET /api/integrations/axata-sync/live/axata/dynamic-census/preview` | AXATA `vw_stok_duzeltme` satirlarini onizler | Hayir | "Stok duzeltme onizle" |
| DynamicCensus | `POST /api/integrations/axata-sync/live/axata/dynamic-census/import` | Uygun satirlari Mikro dynamic census hareketine cevirir | Evet | "Stok duzeltmeleri isle" |
| Mikro -> AXATA Manuel | `GET /manual/tasks/{taskCode}/documents/candidates` | Manuel kurtarma icin Mikro evrak adaylarini listeler | Hayir | "Evraklari getir" |
| Mikro -> AXATA Manuel | `POST /manual/tasks/{taskCode}/documents/preview` | Secili Mikro evrakindan AXATA payload preview uretir | Hayir | "Payload onizle" |
| Mikro -> AXATA Manuel | `POST /manual/tasks/{taskCode}/documents/execute` | Secili evrak icin `DryRun` veya `Outbox` calistirir | Outbox modunda dosya yazar | "Outbox'a hazirla" |
| Mikro -> AXATA Manuel | `POST /manual/tasks/{taskCode}/documents/dispatch` | Secili evraki AXATA Main servise WCF client ile gonderir | AXATA'ya yazar | "AXATA'ya gonder" |
| AXATA Body Manuel | `POST /manual/axata/outbound-deliveries/inter-warehouse-shipments` | Hazir AXATA outbound delivery body bilgisinden Mikro sevk fisi olusturur | Evet | "Body'den sevk olustur" |
| AXATA Body Manuel | `POST /manual/axata/inbound-atf/company-receivings` | Hazir AXATA inbound ATF body bilgisinden Mikro firma mal kabul olusturur | Evet | "ATF'den mal kabul olustur" |
| Serbest Incoming | `POST /manual/incoming/company-receivings` | Serbest body ile Mikro firma mal kabul olusturur | Evet | "Manuel mal kabul olustur" |
| Serbest Incoming | `POST /manual/incoming/inventory-counts` | Serbest body ile Mikro sayim sonucu olusturur | Evet | "Manuel sayim olustur" |
| Bekleyen Kabul | `GET /manual/incoming/warehouse-receivings` | Mikro'ya dusmus ama kabulde bekleyen depo mal kabullerini listeler | Hayir | "Bekleyenleri getir" |
| Bekleyen Kabul | `POST /manual/incoming/warehouse-receivings/{documentSerie}/{documentOrderNo}/accept` | Bekleyen depo mal kabulunu kabul eder | Evet | "Kabul et" |

UI'da asil karistirilmamasi gereken farklar:

| Kavram | Anlami | UI uyarisi |
|---|---|---|
| `preview` | Canli veriyi okur ve sonucu gosterir | Veri yazmaz |
| `execute` | `DryRun` veya `Outbox` calistirir | `Outbox` AXATA'ya gonderim degil, dosya hazirlama isidir |
| `dispatch` | Mikro evrakini AXATA Main servisine canli gonderir | AXATA tarafina yazar |
| `live/audit/overview` | Mikro ve AXATA durumunu karsilastirir | Mudahale yapmaz |
| `outbound-deliveries/preview` | AXATA C01/C02/C03/C4 pending kuyrugunu okur | Mikro'ya yazmaz, ack atmaz; `hasLiveImport` ilgili ozel import route'unu isaret eder |
| `outbound-deliveries/by-date` | AXATA `ENT006.S06ITAR` tarihine gore sevkleri listeler | Mikro'ya yazmaz, ack atmaz; pending filtrelemez |
| `c01/import` | AXATA C01 teslimatini Mikro sevke cevirir | Mikro'ya yazar, `acknowledge=true` ise AXATA EXT status gunceller |
| `c02/import` | AXATA C02 teslimatini Mikro firma sevke cevirir | Mikro'ya yazar, `acknowledge=true` ise AXATA EXT status gunceller |
| `c03/import` | AXATA C03 teslimatini Mikro legacy firma iade/ozel cikis hareketine cevirir | Mikro'ya yazar, `acknowledge=true` ise AXATA EXT status gunceller |
| `c04/import` | AXATA C4 teslimatini Mikro legacy 50 -> 51 hareketine cevirir | Mikro'ya yazar, `acknowledge=true` ise AXATA EXT status gunceller |
| `c01/documents/{serie}/{sira}/preview` | C01 teslimatini AXATA'da belge no ile arar, status verilmezse `0` sonra `1` dener | Veri yazmaz |
| `c01/documents/{serie}/{sira}/import` | AXATA'da C01 sevki olusmus ama belge genelinde Mikro sevk linki olmayan belgeyi Mikro'ya dusurur | Mikro'ya yazar, `acknowledge=true` ise AXATA EXT status gunceller |
| `g02/import` | AXATA G02 giris teslimatini mevcut Mikro bekleyen sevk fisine kabul olarak uygular | Mikro'ya yazar, `acknowledge=true` ise AXATA EXT `ENT016_MST.S16STAT` gunceller |
| `g02/documents/{serie}/{sira}/preview` | G02 teslimatini AXATA'da belge no ile arar, status verilmezse `0` sonra `1` dener | Veri yazmaz |
| `g02/documents/{serie}/{sira}/import` | Tek G02 teslimatini mevcut Mikro bekleyen sevk fisine kabul olarak uygular | Mikro'ya yazar, `acknowledge=true` ise AXATA EXT status gunceller |
| `g01/import` | AXATA G01 ATF satirlarini Mikro firma mal kabule cevirir | Mikro'ya yazar; `CompanyReceiving=Database` veya `MikroApi` rotasina uyar, `acknowledge=true` ise AXATA EXT `ENT016_IRS.S16STAT` gunceller |
| `dynamic-census/import` | AXATA EXT `vw_stok_duzeltme` satirlarini Mikro stok duzeltme hareketine cevirir | Mikro'ya yazar, `acknowledge=true` ise AXATA EXT `ENT011.S11STAT` gunceller |
| `manual/axata/*` | AXATA verisi body olarak UI/operasyon tarafindan saglanir | AXATA'dan canli fetch yapmaz |
| `manual/incoming/*` | Mikro'ya manuel belge yazar | AXATA status guncellemez |

Task bazli UI buton kurali:

| Task/profil | Liste | Preview | Outbox execute | Live dispatch | Live queue preview | Live import/ack |
|---|---|---|---|---|---|---|
| `firm-master-sync` | Yok | Var | Var | Var | Yok | Yok |
| `product-master-sync` | Yok | Var | Var | Var (`Live`) | Yok | Yok |
| `issued-warehouse-order-sync` | Var | Var | Var | Var | Yok | Yok |
| `received-company-order-sync` | Var | Var | Var | Var | Yok | Yok |
| `warehouse-inbound-order-sync` | Var | Var | Var | Var | Yok | Yok |
| `company-receiving-sync` | Var | Var | Var | Var | Yok | Yok |
| `inventory-count-sync` | Var | Var | Var | Yok | Yok | Var, task Live veya DynamicCensus route |
| `C01 outbound delivery` | AXATA kuyrugu + belge bazli rescue | Var | Yok | Yok | Var | Var |
| `C02 outbound delivery` | AXATA kuyrugu | Var | Yok | Yok | Var | Var |
| `C03 outbound delivery` | AXATA kuyrugu | Var | Yok | Yok | Var | Var |
| `C4 outbound delivery` | AXATA kuyrugu | Var | Yok | Yok | Var | Var |
| `G01 inbound ATF` | AXATA ATF kuyrugu | Var | Yok | Yok | Var | Var |
| `G02 inbound delivery` | AXATA G02 kuyrugu + belge bazli rescue | Var | Yok | Yok | Var | Var |
| `DynamicCensus EXT view` | AXATA EXT view | Var | Yok | Yok | Var | Var |

Ekranda gosterilecek durum alanlari:

| Response alani | Nerede gelir | UI yorumu |
|---|---|---|
| `isInSync` | audit overview | Tum kontrol basliklari temizse true |
| `workflowSummary.mikroOrderDocumentCount` | audit overview | Secilen tarihte Mikro'ya dusen ve akisin baslangic evrenini olusturan siparis sayisi |
| `workflowSummary.axataOrderDocumentCount` | audit overview | Mikro siparis numarasi ile AXATA `ENT000/ENT001` tarafinda gercekten bulunan siparis sayisi |
| `workflowSummary.axataShipmentDocumentCount` | audit overview | Secilen Mikro siparislerine bagli tum AXATA C01 SEV belge sayisi; sevk tarihi farkli gun olabilir |
| `workflowSummary.partiallyShippedDocumentCount` | audit overview | Toplam AXATA SEV miktari Mikro siparis miktarindan dusuk olan siparis sayisi |
| `workflowSummary.fullyShippedDocumentCount` | audit overview | Toplam AXATA SEV miktari Mikro siparis miktarina esit olan siparis sayisi |
| `workflowSummary.mikroLinkedShipmentDocumentCount` | audit overview | En az bir Mikro sevk hareketi siparis satirina baglanmis siparis sayisi |
| `workflowSummary.fullySynchronizedDocumentCount` | audit overview | AXATA siparisi, toplam SEV ve Mikro siparis baglantisi miktar olarak tamamlanan siparis sayisi |
| `workflowSummary.manualActionRequiredDocumentCount` | audit overview | Evrak bazinda manuel aksiyon onerilen siparis sayisi |
| `flowOverview` | audit overview | Mikro -> AXATA -> Mikro akisini okunur ozet olarak verir; ana sayilar, fark adimlari ve aksiyon gruplari burada toplanir |
| `flowOverview.steps` | audit overview | 1 Mikro siparis, 2 AXATA siparis, 3 AXATA sevk, 4 Mikro sevk donusu, 5 tamamlanan akis kartlari |
| `flowOverview.actionGroups` | audit overview | "Mikro'ya aktar", "AXATA ACK", "siparisi yeniden gonder", "bekle", "manuel incele" gibi aksiyonlara gore gruplanmis belgeler |
| `orderLifecycles` | audit overview | Her Mikro siparisi icin AXATA siparis, tum SEV'ler, Mikro baglanti durumu ve onerilen aksiyonu tek kayitta verir |
| `summary.unsentWarehouseOrderDocumentCount` | audit overview | Mikro'da AXATA'ya gitmemis depo siparisi sayisi |
| `summary.sentWarehouseOrderMissingMikroShipmentDocumentCount` | audit overview | AXATA'ya gonderildi isaretli ama belge genelinde Mikro sevk linki olmayan belge sayisi |
| `summary.sentWarehouseOrderMissingMikroShipmentLineCount` | audit overview | Belge genelinde hic Mikro sevk linki olmayan satir sayisi |
| `summary.sentWarehouseOrderMissingMikroShipmentQuantity` | audit overview | Belge genelinde hic Mikro sevk linki olmayan toplam miktar |
| `summary.sentWarehouseOrderShipmentDifferenceDocumentCount` | audit overview | En az bir sevk linki olan ama eksik link veya miktar farki bulunan belge sayisi |
| `summary.sentWarehouseOrderShipmentDifferenceLineCount` | audit overview | Kismi sevk/satir farki icindeki problemli satir sayisi |
| `summary.sentWarehouseOrderShipmentDifferenceQuantity` | audit overview | Kismi sevk/satir farki icindeki miktar farki |
| `summary.pendingOutboundDeliveryDocumentCount` | audit overview | AXATA'da Status=0 bekleyen sevk sayisi |
| `unsyncedWarehouseOrders` | audit overview | Mikro -> AXATA tarafinda tekrar gonderim adayi |
| `sentWarehouseOrdersMissingMikroShipments` | audit overview | AXATA'ya gitmis gorunen ama belge genelinde Mikro sevk fisi/linki olmayan belgeler; C01 rescue adayi |
| `sentWarehouseOrdersWithShipmentDifferences` | audit overview | Belge icinde en az bir Mikro sevk linki var ama eksik link veya miktar farki bulunur; kismi sevk/fark inceleme listesi |
| `pendingOutboundDeliveries` | audit overview | AXATA -> Mikro tarafinda bekleyen kuyruk |
| `interventionCandidates` | audit overview | C01 icin backendin guvenli mudahale adayi gordugu kayitlar |
| `operations` | audit overview | Kontrol kulesi kartlari; her operasyon icin route, sayac, severity ve yazma durumu verir |
| `currentHandling` | queue preview | Profilin sadece preview mu, import destekli mi oldugunu gosterir |
| `hasLiveImport` | queue preview | True ise ilgili profil icin canli import yolu vardir |
| `canImport` | C01 import preview | True ise C01 import endpoint'i ile Mikro'ya yazilabilir |
| `existingLinkedMovementLineCount` | C01 import preview/audit | Mikro sevk linki zaten varsa duplicate fis acilmamali |
| `acknowledged` | C01 import result | AXATA EXT status guncellemesi yapildi mi |
| `failures` | batch response'lar | Hatali evraklar kullaniciya satir bazinda gosterilmeli |
| `artifacts` | execute/outbox response | Uretilen JSON dosya bilgisi |
| `serviceState`, `serviceMessage` | dispatch response | AXATA servisinin dondugu sonuc |

Kullaniciya onerilen metinler:

- `Outbox`: "Payload dosyalandi. Bu islem AXATA'ya gonderim yapmaz."
- `Dispatch`: "Secili evrak AXATA servislerine canli gonderilecek."
- `AXATA synchronization is disabled in configuration.`: "AXATA entegrasyonu sunucu ayarlarinda kapali. Manuel gonderim icin sistem ayari acilmali."
- `C01 import`: "AXATA'daki C01 teslimat Mikro'da sevk fisine cevrilecek. Basarili olursa AXATA status guncellenebilir."
- `C01 rescue`: "AXATA'da sevki kesilmis gorunen bu belge Mikro'da sevk linki bulamadigi icin belge bazinda tekrar kontrol edilecek."
- `C02/C03/C4 import`: "AXATA'daki teslimat Mikro'da ilgili legacy/hareket tipine cevrilecek. Basarili olursa AXATA status guncellenebilir."
- `G01 import`: "AXATA G01 ATF satirlari Mikro firma siparisine baglanip mal kabul hareketine cevrilecek."
- `DynamicCensus import`: "AXATA stok duzeltme satirlari Mikro stok hareketine cevrilecek." Bu akis stok duzeltme/legacy hareket karakterindedir; su an `InventoryCount` sayim API'sine maplenmez ve DB-only calisir.
- `manual/axata body`: "Bu ekranda AXATA'dan veri cekilmez; girilen body Mikro belgesine cevrilir."

UI akis onerisi:

- kullanici once `GET /api/integrations/axata-sync` ile task listesini acar
- secili task icin `preview` cagrisi ile ornek payload gorur
- sonra `DryRun` veya `Outbox` modunda job baslatir
- `202` cevabindan `jobId` alinir
- UI belirli aralikla `GET /api/integrations/axata-sync/jobs/{jobId}` poll eder
- `status = Succeeded` olursa mesaj ve olusan artifact/path bilgileri gosterilir
- `status = Failed` olursa `errorMessage` ve `message` kullaniciya gosterilir

Ornek preview:

```http
GET /api/integrations/axata-sync/tasks/product-master-sync/preview?take=5
Authorization: Bearer {token}
```

Canli urun master job:

```http
POST /api/integrations/axata-sync/tasks/product-master-sync/execute
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "executionMode": "Live"
}
```

Tek urun:

```http
GET /api/integrations/axata-sync/live/products/preview?productCode=URUN001&take=1
POST /api/integrations/axata-sync/live/products/URUN001/dispatch
```

Secili veya toplu urun gonderme:

```http
POST /api/integrations/axata-sync/live/products/dispatch
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "productCodes": ["URUN001", "URUN002"],
  "continueOnError": true
}
```

`productCodes=[]` ve `take=500` gonderilirse sirali ilk 500 aktif Mikro urunu aktarilir.
Payload AXATA `SKUMaster` icinde `ENT004` master, `ENT003_List` barkodlar ve
`ENT004_UNIT_List` birimleri birlikte tasir. Canli urun endpointleri worker
kuyruguna bagli degildir. Zamanli otomatik aktarim icin global `WorkerEnabled`,
`SchedulerEnabled` ve `product-master-sync.ScheduleEnabled` alanlarinin ucunun
da `true` olmasi gerekir.

Ornek manual job:

```http
POST /api/integrations/axata-sync/jobs
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "taskCode": "issued-warehouse-order-sync",
  "executionMode": "Outbox",
  "warehouseNo": 50
}
```

Ornek route-based execute:

```http
POST /api/integrations/axata-sync/tasks/inventory-count-sync/execute
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "executionMode": "DryRun",
  "warehouseNo": 1
}
```

Ornek AXATA/Mikro fark kontrolu:

```http
GET /api/integrations/axata-sync/live/audit/overview?startDate=2026-06-08&endDate=2026-06-08&take=50
Authorization: Bearer {token}
```

Varsayilan `statuses` degeri `0,1` kabul edilir. Yani endpoint AXATA SQL `ENT006/ENT007`
tarafinda hem bekleyen (`Status=0`) hem tamamlanmis (`Status=1`) sevk kayitlarini okur.
Sadece bekleyen kuyrugu izlemek istenirse `statuses=0`, tamamlanmis sevk donuslerini
incelemek icin `statuses=1`, ikisini birlikte gormek icin `statuses=0,1` gonderilebilir.

Tek belgeyi debug etmek icin:

```http
GET /api/integrations/axata-sync/live/audit/overview?startDate=2026-06-01&endDate=2026-06-16&warehouseNo=50&documentSerie=F50&documentOrderNo=15035&statuses=0,1&take=50
Authorization: Bearer {token}
```

Bu cagri veri yazmaz. Amaci eski worker calisirken durumu anlamaktir:

- Ana izleme evreni secilen `startDate/endDate` araliginda Mikro `DEPOLAR_ARASI_SIPARISLER.ssip_tarih` alanina dusen siparislerdir
- Her Mikro siparisi AXATA `ENT000/ENT001` icinde evrak numarasi ile dogrudan aranir; `ssip_special1=1` yalnizca worker gonderim bayragidir ve AXATA'da gercek kayit bulundugunun yerine kullanilmaz
- Secilen Mikro siparisine ait AXATA C01 `ENT006/ENT007` SEV kayitlari sevk tarihinden bagimsiz aranir; boylece bir gun acilan siparisin sonraki gun kesilen sevki ayni yasam dongusunde gorulur
- Bir siparise ait birden fazla SEV miktari toplanir ve `PartiallyShipped`, `FullyShipped` veya `OverShipped` olarak siniflandirilir
- Mikro donusu once `STOK_HAREKETLERI_EK.sth_subesip_uid` ile bagli gercek `STOK_HAREKETLERI.sth_miktar` toplami uzerinden siniflandirilir. Link yoksa ek olarak `ssip_teslim_miktar` ve mevcut Mikro sevk fisi kontrol edilir; mevcut sevk aramasi siparis tarihinden 1 gun once baslar, 7 gun sonrasina kadar ayni depo + aciklama veya ayni stok/miktar imzasi arar. Sonuc `WaitingForMikroTransfer`, `MikroOrderMarkedDeliveredMissingLink`, `ExistingMikroShipmentMissingLink`, `PartiallyLinked` veya `FullyLinked` olabilir.
- `orderLifecycles[].recommendedAction` yeniden siparis gonderme, C01 import, tamamlanmis SEV rescue, sadece AXATA ACK, bekleme veya manuel fark inceleme kararini evrak bazinda verir
- `isInSync=true` ise secili tarih araliginda Mikro kaynakli siparis gonderim bayraklari tamam, AXATA `Status=0` bekleyen sevk kuyrugu bos, iptal/zero olmayan AXATA sevkleri Mikro'ya dusmus/baglanmis ve AXATA sevk kayitlarinda satirsiz/anomali belge yok demektir
- `unsyncedWarehouseOrders` Mikro'da olup worker basari bayragi tum satirlarda `1` olmayan depolar arasi siparisleri gosterir
- Entegrasyon iki yonludur: siparis tarafi Mikro kaynaklidir (`DEPOLAR_ARASI_SIPARISLER` -> AXATA), sevk donusu AXATA kaynaklidir (`ENT006/ENT007` -> Mikro sevk fisi/linki)
- Sevk donus problemi AXATA C01 sevklerinden hesaplanir; pozitif miktarli, iptal olmayan AXATA sevkinde `linkedMovementLineCount == 0` ise kritik `sentWarehouseOrdersMissingMikroShipments`, `linkedMovementLineCount > 0` olup eksik link veya miktar farki varsa uyari `sentWarehouseOrdersWithShipmentDifferences` listesine ayrilir
- `sentWarehouseOrdersMissingMikroShipments` AXATA'da C01 sevki olustugu halde Mikro'da belge genelinde hic `STOK_HAREKETLERI_EK.sth_subesip_uid` linki olmayan kritik sevk donus eksiklerini gosterir
- `sentWarehouseOrdersWithShipmentDifferences` belgede en az bir Mikro sevk linki oldugu halde eksik link veya siparis-teslim miktar farki bulunan kismi sevk/satir farki durumlarini gosterir; UI bunu dogrudan import aksiyonu degil inceleme uyarisi olarak ele almalidir
- Mikro siparis kontrolu merkezden cikan depo sevk akisi icin `ssip_cikdepo` uzerinden yapilir; `warehouseNo=50` merkezden cikacak depo siparislerini denetler
- Audit tarih filtresi siparis kontrolunde Mikro `ssip_tarih`, sevk kontrolunde AXATA `ENT006.S06ITAR` uzerinden calisir; `ssip_lastup_date` sadece Mikro siparis problem listelerinde en yeni guncellenen belgeyi one almak icin kullanilir
- AXATA sevk kontrolu `AxataConnection` uzerinden `ENT006` baslik ve `ENT007` satir tablolarindan okunur; WCF `getOutBoundDeliveryList` ana audit kaynagi degil, canli import/ack ve fallback icindir
- `summary.axataOutboundDeliveryDocumentCount`, `summary.axataOutboundDeliveryLineCount`, `summary.axataCompletedOutboundDeliveryDocumentCount`, `summary.axataCancelledOutboundDeliveryDocumentCount` ve `summary.axataEmptyOutboundDeliveryDocumentCount` secili `statuses` evreninin AXATA SQL ozetidir
- AXATA `S06IPTKOD` dolu olan veya `S06STTU=3` ve toplam sevk miktari `0` olan belgeler iptal/zero sevk olarak ayrilir; Mikro sevk fisi beklenmez
- `summary.sentWarehouseOrderMissingAxataOutboundDeliveryDocumentCount` Mikro'da `ssip_special1=1` gorunup secili AXATA sevk evreninde karsiligi bulunmayan ikincil tutarsizliklari gosterir; bu alan ana sevk donus alarmi degil inceleme bilgisidir
- `pendingOutboundDeliveries` yalnizca AXATA `Status=0` bekleyen sevkleri gosterir
- `axataOutboundDeliveries` secili `statuses` icindeki tum AXATA sevklerini sinirli liste olarak dondurur; `Status=1` tamamlanmis belgeler burada gorulur, `axataShipmentState/isCancelled/cancellationCode` alanlari iptal/zero ayrimini destekler
- `interventionCandidates` C01 icin guvenli mudahale adaylarini gosterir; UI manuel butonlari bu listeye veya `canIntervene=true` olan satirlara baglamalidir
- `operations` UI'nin "siparis AXATA'ya dustu mu", "bekleyen AXATA sevki var mi", "AXATA sevki kesilmis ama Mikro'ya dusmemis mi" kartlarini besler
- `Synchronized` ise AXATA sevki `Status=1` durumundadir ve Mikro sevk/link zaten vardir; UI bunu yesil/tamamlandi gostermeli, import/ack butonu acmamalidir
- `MikroShipmentExistsPendingAck` ise AXATA sevki `Status=0` durumundayken Mikro fis/link zaten vardir; duplicate fis acmadan sadece AXATA ack gerekebilir
- `ReadyForImport` ise AXATA satirlari Mikro siparis satirlariyla guvenli eslesmistir, sevk fisi yoktur ve C01 import ile mudahale edilebilir

`axataOutboundDeliveries[]` UI karar tablosu:

| AXATA `status` | `mikroCheckState` | Mikro link/miktar anlami | UI durumu | UI aksiyonu |
|---|---|---|---|---|
| `1` | `Synchronized` | AXATA sevk tamamlanmis, Mikro sevk linki mevcut | Yesil / Tamamlandi | Buton gosterme |
| `0` | `ReadyForImport` | AXATA sevki bekliyor, Mikro sevk linki yok, satirlar guvenli eslesmis | Sari / Aktarilabilir | C01 import butonu goster |
| `0` | `MikroShipmentExistsPendingAck` | Mikro sevk linki zaten var, AXATA hala bekliyor | Sari / ACK bekliyor | Sadece ACK/onarim aksiyonu goster; yeni fis uretme |
| `1` | `ReadyForImport` | AXATA tamamlanmis gorunuyor ama Mikro sevk linki yok | Kirmizi / Mikro donus eksik | Belge bazli rescue/import aksiyonu goster |
| `0` veya `1` | `OrderNotFound`, `OrderLineMismatch`, `Blocked` | Siparis veya satir eslesmesi guvenli degil | Kirmizi / Manuel inceleme | Otomatik import butonu gosterme |
| `0` veya `1` | `CancelledInAxata`, `EmptyAxataDelivery` | AXATA iptal/sifir miktarli veya satirsiz | Gri / Iptal veya bos | Mikro sevk bekleme, import butonu gosterme |

Ornek yorum:

```json
{
  "status": "1",
  "axataDeliveryNo": "D110.2040",
  "quantity": 195,
  "mikroDeliveredQuantity": 195,
  "existingLinkedMovementLineCount": 3,
  "mikroCheckState": "Synchronized",
  "canIntervene": false,
  "warning": "Mikro sevk linki mevcut ve AXATA status tamamlandi; islem gerekmiyor."
}
```

Bu ornek "AXATA sevk etmis, Mikro'da sevk/link var, miktar tam, islem yok" demektir. UI bu satiri hata veya mudahale adayi gibi gostermemelidir.

Ornek outbound delivery kuyruk preview:

```http
GET /api/integrations/axata-sync/live/axata/outbound-deliveries/preview?movementType=C02&take=20
Authorization: Bearer {token}
```

Bu cagri AXATA'da bekleyen secili hareket tipini kuyruk seviyesinde gosterir. C02/C03/C4 icin veri yazma, Mikro eslesme ve AXATA ack yoktur; UI bu endpoint sonucunu "bekleyen AXATA teslimatlari" olarak gostermelidir.

Ornek C01 AXATA'dan cekme preview:

```http
GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/preview?take=20
Authorization: Bearer {token}
```

Bu cagri AXATA'da bekleyen `MovementType=C01`, `Status=0` teslimatlari getirir; Mikro siparis satiri, depo ve kalan miktar kontrolunu yapar. Veri yazmaz ve AXATA status guncellemez.

Ornek C01 import:

```http
POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/import
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "take": 20,
  "continueOnError": true,
  "acknowledge": true
}
```

Import davranisi:

- AXATA fetch: `AxataServicePool.svc/getOutBoundDeliveryListAsync`
- Query: `CompanyCode=01`, `WarehouseCode=01`, `MovementType=C01`, `Status=0`
- Mikro eslesme: `S06TESL` degeri `DocumentSerie.DocumentOrderNo` olarak okunur
- Satir eslesme: once `S07KALN + S07SKOD` -> `ssip_satirno + ssip_stok_kod`, sonra 1-bazli satir no farki, son olarak tekil stok + kalan miktar kontrolu
- Mikro yazim: depolar arasi sevk fisi ve bagli satirlarda `sth_subesip_uid` ile Mikro tarafinda siparis linki/teslim etkisi
- Mikro tarih kuralı: C01 sevk Mikro'ya hangi gun import ediliyorsa `STOK_HAREKETLERI.sth_tarih` ve `sth_belge_tarih` o gun olur. AXATA `ENT006.S06ITAR` siparis/sevk izleme ve filtreleme bilgisidir; Mikro fis tarihi olarak kullanilmaz.
- AXATA ack: Mikro yazim basarili olursa `AxataServicePoolEXT.svc/updIntegrationTableAsync` ile `ENT006.S06STAT=1`, `IDField=S06SIRA`
- `acknowledge=false` verilirse Mikro yazilir ama AXATA status guncellenmez; bu sadece kontrollu test/kurtarma icin kullanilmalidir

Ornek C01 belge bazli rescue preview:

```http
GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/F50/15035/preview?status=1
Authorization: Bearer {token}
```

Bu cagri `sentWarehouseOrdersMissingMikroShipments` listesinden secilen belge icin AXATA'da `OrderNumber=F50.15035`, `MovementType=C01`, `Status=1` teslimat detayini arar. `status` bos birakilirsa backend once `0`, sonra `1` dener. Veri yazmaz.

Ornek C01 belge bazli rescue import:

```http
POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/F50/15035/import
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "status": "1",
  "acknowledge": false
}
```

Rescue davranisi:

- AXATA fetch: `AxataServicePool.svc/getOutBoundDeliveryListAsync`
- Query: `CompanyCode=01`, `WarehouseCode=01`, `MovementType=C01`, `OrderNumber=F50.15035`, `Status=1`
- Mikro eslesme: `S06TESL` -> `DocumentSerie.DocumentOrderNo`; satir eslesmesi guvenli eslesme kuralini kullanir (`S07KALN + S07SKOD`, 1-bazli satir no farki, tekil stok + kalan miktar)
- Mikro yazim: AXATA teslimat miktari Mikro kalan miktarini asmiyorsa depolar arasi sevk fisi ve bagli satirlarda `sth_subesip_uid` ile Mikro tarafinda siparis linki/teslim etkisi
- `sentWarehouseOrdersWithShipmentDifferences` listesindeki kismi sevk/satir farki belgeleri icin otomatik import onerilmez; once AXATA satirlariyla fark incelemesi yapilmalidir
- `acknowledge=false` tavsiye edilir; belge AXATA'da zaten `Status=1` ise tekrar ack gerekmeyebilir

Ornek manuel evrak preview:

```http
POST /api/integrations/axata-sync/manual/tasks/issued-warehouse-order-sync/documents/preview
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "warehouseNo": 50,
  "documentSerie": "O150",
  "documentOrderNo": 5219
}
```

`issued-warehouse-order-sync` icin bu body'deki `warehouseNo=50`, Mikro `ssip_cikdepo=50` anlamina gelir. Evrak hedef/giris deposu 150 olsa bile manuel preview/dispatch bu kaynak depo numarasi ile cagirilmalidir.

Ornek manuel evrak execute:

```http
POST /api/integrations/axata-sync/manual/tasks/inventory-count-sync/documents/execute
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "executionMode": "Outbox",
  "warehouseNo": 1,
  "documentNo": 1052,
  "documentDate": "2026-04-29T00:00:00"
}
```

Manuel kurtarma akis onerisi:

- Senaryo `Mikro -> AXATA`:
  - once `manual ... /documents/candidates` ile operasyon ekibine secilebilir evrak listesi goster
  - once `manual ... /documents/preview` ile tek evrak payload'i kontrol et
  - toplu kurtarma gerekiyorsa secilen evraklari `manual ... /documents/preview-batch` ile dogrula
  - veri dogruysa `manual ... /documents/execute` ile `DryRun` veya `Outbox` calistir
  - gercek gonderim gerekiyorsa `manual ... /documents/dispatch` veya `dispatch-batch` kullan
  - toplu yeniden gonderimde `manual ... /documents/execute-batch` kullan; `ContinueOnError = true` ise basarili ve hatali evraklar ayni response'ta ayrisir
  - `Outbox` sonucu artifact path'i operasyon ekibine verilebilir
- Senaryo `AXATA -> Mikro`:
  - AXATA C01 depo sevkleri bekliyorsa once `live/axata/outbound-deliveries/c01/preview` ile kontrol et
  - eslesmeler dogruysa `live/axata/outbound-deliveries/c01/import` ile Mikro sevki yaz ve AXATA ack at
  - `sentWarehouseOrdersMissingMikroShipments` icinde C01 belge gorunuyorsa once `live/axata/outbound-deliveries/c01/documents/{serie}/{sira}/preview?status=1` ile AXATA teslimat detayini dogrula
  - belge bazli preview `canImport=true` donerse `live/axata/outbound-deliveries/c01/documents/{serie}/{sira}/import` ile eksik Mikro sevkini olustur
  - AXATA G02 depo mal kabulleri bekliyorsa once `live/axata/inbound-deliveries/g02/preview` ile kontrol et
  - eslesmeler dogruysa `live/axata/inbound-deliveries/g02/import` ile mevcut Mikro sevk fisini kabul et ve AXATA ack at
  - tek G02 belge kurtarma gerekiyorsa `live/axata/inbound-deliveries/g02/documents/{serie}/{sira}/preview` ve uygun ise `import` kullan
  - AXATA C02/C03/C4 teslimatlari bekliyorsa once `live/axata/outbound-deliveries/preview?movementType=C02|C03|C4` ile kuyrugu goster, sonra ilgili `c02|c03|c04/preview` ve `import` endpointlerini kullan
  - AXATA G01 ATF satirlari bekliyorsa `live/axata/inbound-atf/g01/preview` ve uygun ise `import` kullan
  - AXATA DynamicCensus satirlari bekliyorsa `live/axata/dynamic-census/preview` ve uygun ise `import` kullan
  - AXATA outbound delivery verisi eldeyse `manual/axata/outbound-deliveries/inter-warehouse-shipments` ile dogrudan Mikro sevki yaz
  - AXATA inbound ATF verisi eldeyse `manual/axata/inbound-atf/company-receivings` ile dogrudan Mikro firma mal kabule cevir
  - AXATA ham verisi operasyon tarafinda toparlanmis ise `manual/incoming/company-receivings` veya `manual/incoming/inventory-counts` kullan
  - coklu belge geliyorsa `.../company-receivings/batch` veya `.../inventory-counts/batch` ile tek cagrida islenebilir
  - depo sevki zaten bekleyen belge olarak Mikro'ya dusmus ama kabulde takildiysa once `manual/incoming/warehouse-receivings` ile listele, gerekirse detay endpoint'i ile satirlari kontrol et, sonra `.../accept` veya `.../accept-batch` kullan
- Not:
  - Backend AXATA'dan WCF client ile C01/C02/C03/C04/G01/G02 ve DynamicCensus icin canli fetch/import yapar; belge bazli rescue su an C01 ve G02 icindir
  - `dispatch` endpoint'leri AXATA'ya canli yazim yapar; `execute` endpoint'leri ise sadece `DryRun/Outbox` icindir
  - eski worker operasyon isimleri kullanildigi icin canli AXATA dispatch sahada endpoint/credential ile dogrulanmalidir

Entegrasyon modulu notlari:

- worker ve scheduler backend tarafinda hosted service olarak calisir
- scheduler config ile kapali acilabilir; UI bunu overview ekraninda gostermelidir
- `preview` endpoint'i canli veriyi okur, test/mock veri kullanmaz
- `issued-warehouse-order-sync`, `warehouse-inbound-order-sync`, `company-receiving-sync` ve `inventory-count-sync` task'larinda `warehouseNo` gerekir
- `issued-warehouse-order-sync` icin `warehouseNo` AXATA kaynak/cikis depodur; aday liste, task preview, execute ve dispatch ayni `ssip_cikdepo` evrenine bakar
- `warehouse-inbound-order-sync` icin `warehouseNo` AXATA hedef/giris depodur; aday liste, task preview, execute ve dispatch ayni `ssip_girdepo` evrenine bakar
- `company-receiving-sync` ismine ragmen firma mal kabul fisini degil, `SIPARISLER.sip_tip=1` verilen firma/satinalma siparisini AXATA `G01` inbound order olarak gonderir
- Zamanli/live C01/C02/G01/G02 dispatch task'lari `Special1=1` olan kaynak siparisleri tekrar aday yapmaz; AXATA basarili donerse kaynak siparis satirlari `Special1=1` olarak isaretlenir
- `firm-master-sync` ve `product-master-sync` depo bagimsiz task'lardir
- `manual/tasks/{taskCode}/documents/*` endpoint'leri yalnizca evrak bazli task'larda kullanilmalidir
- `manual/tasks/{taskCode}/documents/dispatch*` endpoint'leri yalnizca AXATA'ya canli gonderim icindir; `Outbox` yerine kullanilir
- `manual/incoming/*` endpoint'leri worker'dan bagimsiz operasyonel kurtarma katmanidir
- `manual/axata/*` endpoint'leri AXATA-native request body'sini minimum donusumle Mikro write use-case'lerine baglar
- `live/audit/overview` endpoint'i eski worker calisirken kontrol/durum tespiti icindir; AXATA SQL `ENT006/ENT007` ve Mikro siparis/sevk linklerini okur, Mikro veya AXATA verisi yazmaz
- `live/axata/outbound-deliveries/preview` endpoint'i C01/C02/C03/C4 AXATA pending kuyrugunu canli okur; Mikro veya AXATA verisi yazmaz
- `live/axata/outbound-deliveries/c01|c02|c03|c04/*` endpoint'leri AXATA'dan canli outbound delivery cekip Mikro'ya yazar; AXATA ack sadece Mikro kaydi basarili olursa atilir
- `live/axata/inbound-atf/g01/*`, `live/axata/inbound-deliveries/g02/*` ve `live/axata/dynamic-census/*` endpoint'leri AXATA -> Mikro canli import endpointleridir
- `inventory-count-sync` Live execution otomatik scheduler acilirsa DynamicCensus importu calistirir; diger live import endpointleri manuel operasyon aksiyonudur
- toplu endpoint'lerde `ContinueOnError = true` ise HTTP 200 donup basarisiz item'lari `Failures` listesinde raporlar
- `Outbox` modu su an gercek WCF dispatch degil, payload uretim ve dosyalama asamasidir
- canli AXATA import/ack adapter'i C01/C02/C03/C4 outbound delivery, G01 inbound ATF, G02 inbound delivery ve DynamicCensus icin aktiftir
- `GET /api/integrations/axata-sync` icindeki her task artik `supportsManualDocuments`, `supportsLiveDispatch` ve varsa `liveOperationName` alanlarini da dondurur
- `GET /api/integrations/axata-sync/fetch-profiles` ile UI eski worker parity icin hedeflenen `C01/C02/C03/C04(query C4)/G01/G02` ve benzeri fetch profillerini okuyabilir

Bu modulun tasarim hedefi:

- eski worker'i birebir tasimak degil
- eski AXATA altyapisini task/handler/queue mantigiyla normalize etmek
- ileride yeni worker rahat yazilsin diye preview, scheduler, queue ve dispatch omurgasini sabitlemek
- ayni anda operasyon ekibine manuel kurtarma ve manuel aktarim ekranlari vermek

UI task/aksiyon matrisi:

| Task | Genel preview/job | Evrak aday listesi | Tekil/toplu manual execute | Canli dispatch | UI notu |
|---|---|---|---|---|---|
| `firm-master-sync` | Var | Yok | Yok | Var | firma master/adres canli AXATA dispatch |
| `product-master-sync` | Var | Yok | Yok | Var | urun master/barkod/birim canli AXATA dispatch |
| `issued-warehouse-order-sync` | Var | Var | Var | Var | Mikro -> AXATA manuel kurtarma icin ana task |
| `received-company-order-sync` | Var | Var | Var | Var | Mikro -> AXATA C02 alinan firma siparisi |
| `warehouse-inbound-order-sync` | Var | Var | Var | Var | Mikro -> AXATA G02 giris siparisi icin ana task |
| `company-receiving-sync` | Var | Var | Var | Var | Mikro -> AXATA G01 verilen firma/satinalma siparisi |
| `inventory-count-sync` | Var | Var | Var | Var | DryRun/Outbox Mikro sayim payload; Live AXATA DynamicCensus import |

UI manuel aktarim senaryolari:

- Mikro'da verilen depo siparisi var ve AXATA'ya yeniden gonderilecekse:
  - `manual/tasks/issued-warehouse-order-sync/documents/candidates`
  - `manual/tasks/issued-warehouse-order-sync/documents/preview`
  - gerekiyorsa `.../dispatch` veya `.../dispatch-batch`
- Mikro'da kesilmis `depolar-arasi-sevk` belgesi var ve bu belgenin AXATA'ya direkt gonderilmesi isteniyorsa:
  - su an hazir endpoint yok
  - UI bu belge tipi icin AXATA'ya manuel dispatch aksiyonu gostermemelidir
- Mikro'da verilen firma/satinalma siparisi var ve AXATA G01 inbound order olarak yeniden gonderilecekse:
  - `manual/tasks/company-receiving-sync/documents/candidates`
  - `manual/tasks/company-receiving-sync/documents/preview`
  - gerekiyorsa `.../dispatch` veya `.../dispatch-batch`
- AXATA outbound delivery verisi operasyon ekibinin elindeyse ve Mikro'da depolar arasi sevk yaratilacaksa:
  - `manual/axata/outbound-deliveries/inter-warehouse-shipments`
- AXATA C01 depo sevkleri AXATA'da bekliyorsa:
  - `live/axata/outbound-deliveries/c01/preview`
  - `live/axata/outbound-deliveries/c01/import`
- AXATA G02 depo mal kabulleri AXATA'da bekliyorsa:
  - `live/axata/inbound-deliveries/g02/preview`
  - `live/axata/inbound-deliveries/g02/import`
- AXATA'ya gonderilmis G02 siparisin kabul hareketi AXATA'da tamamlanmis ama Mikro kabul linki/statusu eksikse:
  - `live/axata/inbound-deliveries/g02/documents/{documentSerie}/{documentOrderNo}/preview?status=1`
  - uygun ise `live/axata/inbound-deliveries/g02/documents/{documentSerie}/{documentOrderNo}/import`
- AXATA'ya gonderilmis C01 siparisin sevki AXATA'da kesilmis ama Mikro sevk linki yoksa:
  - once `live/audit/overview` icindeki `sentWarehouseOrdersMissingMikroShipments` listesinden belgeyi sec
  - `live/axata/outbound-deliveries/c01/documents/{documentSerie}/{documentOrderNo}/preview?status=1`
  - uygun ise `live/axata/outbound-deliveries/c01/documents/{documentSerie}/{documentOrderNo}/import`
- AXATA C02/C03/C4 teslimatlari AXATA'da bekliyorsa:
  - `live/axata/outbound-deliveries/preview?movementType=C02`
  - `live/axata/outbound-deliveries/preview?movementType=C03`
  - `live/axata/outbound-deliveries/preview?movementType=C4`
  - ardindan `live/axata/outbound-deliveries/c02|c03|c04/preview` ve uygun ise `import`
- AXATA G01 inbound ATF bekliyorsa:
  - `live/axata/inbound-atf/g01/preview`
  - uygun ise `live/axata/inbound-atf/g01/import`
- AXATA inbound ATF verisi operasyon ekibinin elindeyse ve canli fetch kullanilmayacaksa:
  - `manual/axata/inbound-atf/company-receivings`
- Sevk zaten Mikro'ya dusmus ama kabulde takilmissa:
  - `manual/incoming/warehouse-receivings`
  - detail endpoint'i
  - `.../accept` veya `.../accept-batch`

UI'nin kullaniciya acik soylemesi gereken kritik sinirlar:

- C01 depo sevki icin AXATA'dan WCF client ile canli fetch/import vardir; pending kuyruk ve belge bazli rescue desteklenir
- C02/C03/C04 icin AXATA'dan cek, onizle, Mikro'ya yaz ve ack at akisi vardir
- G01 icin `live/axata/inbound-atf/g01/*`, G02 icin `live/axata/inbound-deliveries/g02/*` endpoint'leri kullanilir
- `dispatch*` endpoint'leri `firm-master-sync`, `product-master-sync`, `issued-warehouse-order-sync`, `received-company-order-sync`, `warehouse-inbound-order-sync` ve `company-receiving-sync` destek bilgisine gore aktiflenmelidir
- `depolar-arasi-sevk` belge detayi icin ayrica AXATA dispatch butonu acilmamalidir
- `firm-master-sync` icin UI preview/job/outbox ve live dispatch deneyimi sunabilir
- `product-master-sync` icin preview, toplu canli dispatch ve urun koduyla tekli canli dispatch sunulabilir
- `inventory-count-sync` icin UI Live aksiyonunu "AXATA DynamicCensus'i Mikro'ya isle" olarak etiketlemelidir; bu aksiyon Mikro sayim payload dispatch'i degildir
- `Outbox` basarisi "AXATA kabul etti" degil, "payload dosyalandi" anlamina gelir

UI ekran parcasi onerisi:

- `Genel Durum` sekmesi:
  - `GET /api/integrations/axata-sync`
  - `GET /api/integrations/axata-sync/health`
  - son job listesi ve task bazli durum
- `Kontrol / Fark Analizi` sekmesi:
  - `GET /api/integrations/axata-sync/live/audit/overview`
  - "siparisler AXATA'ya gitti mi", "AXATA sevkleri Mikro'ya dustu mu", "mudahaale adayi var mi" kartlari
  - kartlar icin once `operations` listesi okunmalidir; `state`, `severity`, `documentCount`, `previewRoute`, `executeRoute`, `canExecute`, `writesData` UI buton durumunu belirler
  - `sentWarehouseOrdersMissingMikroShipments` tablosunda belge satiri secilirse C01 belge bazli rescue preview/import route'lari kullanilir
  - `sentWarehouseOrdersWithShipmentDifferences` tablosu kismi sevk/satir farki incelemesi icindir; dogrudan import/ack butonu gostermemelidir
  - varsayilan tarih bugun olmali; tarih araligi ve depo filtresi opsiyonel verilmelidir
- `Mikro -> AXATA Manuel` sekmesi:
  - task secimi
  - aday liste
  - preview
  - dry-run/outbox
  - gerekiyorsa canli dispatch
- `AXATA -> Mikro Manuel` sekmesi:
  - C01 live preview/import
  - G02 live preview/import
  - native AXATA body ile outbound delivery / inbound ATF aktarimi
  - serbest body ile company receiving / inventory count aktarimi
  - batch import sonucunda `Failures` gosterimi
- `Bekleyen Kabuller` sekmesi:
  - `manual/incoming/warehouse-receivings`
  - detail
  - accept / accept-batch

Worker-ready bakis:

- backend'de worker, queue ve scheduler altyapisi vardir
- UI bu modulu "sadece manuel ekran" gibi degil, "ileride worker davranisini da kullanacak entegrasyon omurgasi" gibi ele almalidir
- bu sayede ayni task kodlari hem manuel operasyon hem zamanli worker icin tekrar kullanilabilir

UI'da sonraki faz icin acilabilecek ekranlar:

- `AXATA'dan Cek ve Islet` sekmesi
  - amac: operasyon ekibi AXATA body toplamak zorunda kalmadan tanimli profile gore fetch baslatsin
  - aktif profiller: `C01`, `G02`
  - kuyruk preview profilleri: `C02`, `C03`, `C04(query C4)`
  - planli import profilleri: `C02`, `C03`, `C04(query C4)`, `G01`
  - beklenen akis:
    - profil sec
    - preview al
    - secili kayitlari import et
    - import basariliysa ack sonucu goster
- `Ack/Retry Monitor` sekmesi
  - amac: AXATA'ya ack atilamayan veya yarim kalmis entegrasyonlari operasyon ekibi gorsun
  - bu ekran ancak backend'de kalici audit/retry tablolari eklenirse anlamli olur
- `Transport Profili` sekmesi
  - amac: task'in `V1` mi `V2` mi WCF operasyonu kullanacagini gostermek
  - ozellikle eski worker'da `addOutboundOrderV2Async` ve `addInboundOrderV2Async` kullanimi varsa faydalidir

UI tarafinda simdiden scaffold edilebilecek ama mevcut backend'de henuz aktif olmayan endpoint aileleri:

- `manual/fetch/outbound-deliveries/{profileCode}/preview` (`C01` icin yeni live route kullanilir)
- `manual/fetch/outbound-deliveries/{profileCode}/execute` (`C01` icin yeni live route kullanilir)
- `manual/fetch/inbound-deliveries/{profileCode}/preview`
- `manual/fetch/inbound-deliveries/{profileCode}/execute`

Bu route'lar bugun yoktur; ama ekran mimarisi kurarken ayrik bir `fetch-import` deneyimi dusunulmesi dogru olur.

### POS Muhasebe Aktarimi

Bu menu, eski `Furpa.ZReportWinUI` icindeki su operasyon ailesini web'e tasimak icin acildi:

- Z raporu iceri aktarma ve ERP'ye gonderme
- POS fatura staging ve ERP'ye gonderme
- gider pusulasi staging ve ERP'ye gonderme
- kasa / cihaz ile sube esleme bakimi

Temel route:

- `api/entegrasyon-islemleri/pos-muhasebe-aktarimi`

Yetki kodlari:

- `entegrasyon-islemleri.pos-muhasebe-aktarimi.list`
- `entegrasyon-islemleri.pos-muhasebe-aktarimi.detail`
- `entegrasyon-islemleri.pos-muhasebe-aktarimi.create`
- `entegrasyon-islemleri.pos-muhasebe-aktarimi.update`
- `entegrasyon-islemleri.pos-muhasebe-aktarimi.all-warehouses`

Depo kapsami icin bu surum notu:

- Permission katalogunda `all-warehouses` yetkisi vardir; UI depo seciciyi genel proje kuralina uygun olarak bu permission'a gore acmalidir.
- Bu controller su an `WarehouseNo` alanini merkezi `ResolveWarehouseNoForPolicy`/`ResolveWarehouseScopeForPolicy` ile cozumlemez; request'teki `WarehouseNo` dogrudan servise gider.
- Bu nedenle POS ekraninda `all-warehouses` yoksa UI depo secici gostermemeli ve POS fatura/gider pusulasi liste/import isteklerinde kullanicinin kendi `warehouseNo` degerini gondermelidir. `WarehouseNo` bos giderse bu POS servisinde branch filtresi uygulanmaz.
- `all-warehouses` varsa UI belirli depo icin `WarehouseNo` gonderebilir; tum subeler icin bos birakabilir.
- POS fatura ve gider pusulasi liste/import isteklerinde depo filtresi `BranchNo`/kaynak `Sube` uzerinden calisir.
- Z raporu liste/overview tarafinda `ZReportTotals` kaydinda branch kolonu olmadigi icin `WarehouseNo` bu surumde Z raporu kayitlarini daraltmaz; sube adi `CashRegisterBranches` eslesmesi uzerinden yalniz goruntuleme bilgisi olarak gelir.
- Detay, ERP'ye gonderme ve silme istekleri ID koleksiyonlari ile calisir; bu isteklerdeki `WarehouseNo` alani bu surumde ID kapsam kontrolu icin kullanilmaz.

Mevcut backend durumu:

- route ailesi aciktir
- controller, request contract'lari ve business DTO response'lari tanimlidir
- overview, liste, detay, POS fatura import, gider pusulasi import, header guncelleme, staging silme, kasa esleme bakimi ve ERP'ye gonderme endpoint'leri aktif olarak calisir
- Z raporu dosya parser'i henuz API tarafinda uygulanmamistir; `z-raporlari/ice-aktar` basarisiz import sonucu doner
- `erpye-gonder` endpoint'leri secili kayitlar icin Mikro tarafinda `MUHASEBE_FIS_DETAYLARI` ve `MUHASEBE_FISLERI` kayitlarini olusturur
- basarili ERP gonderiminde ilgili staging header kaydi `IsSent = true` yapilir; hata alan kayitlar batch response icinde satir bazli `success=false` doner
- liste endpoint'leri varsayilan olarak yalniz `IsSent = false` bekleyen kayitlari dondurur; bunun icin `OnlyPending=true` default gelir

UI bu menuyu tek sayfa icinde 4 tab olarak kurgulamalidir:

1. `Z Raporlari`
2. `POS Faturalar`
3. `Gider Pusulalari`
4. `Kasa Eslemeleri`

#### Z Raporlari Tab'i

Bu tab mevcut staging Z raporlarini listeleme, detay izleme, staging silme ve ERP'ye gonderme akisini tasir. Dosyadan Z raporu iceri aktarma parser'i henuz API tarafinda aktif degildir.

Mevcut akis:

- kullanici tarih ve bekleyen/tum kayit baglamina gore staging Z raporlarini listeler
- `WarehouseNo` bu surumde Z raporu listesini daraltmaz; Z raporu sube bilgisi kasa-sube eslemesinden `branchName` olarak gorunur
- belge baslik, KDV satiri ve odeme satiri bazinda detay inceler
- secilen raporlar ERP muhasebe fisine donusturulur
- ERP gonderimi icin `CashRegisterNo` degerinin `CashRegisterBranches` tablosunda sube ile eslenmis olmasi gerekir
- basarili gonderimde ilgili Z raporu staging header kaydi `IsSent = true` yapilir
- dosyadan `ice aktar` aksiyonu bugunku durumda basarisiz import sonuc satiri dondurur

Endpoint'ler:

- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari`
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/{totalId}`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/ice-aktar`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/erpye-gonder`
- `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari`

UI beklentisi:

- liste ekraninda durum, tarih, Z no, kasa no, sube ve toplam kolonlari hazir dusunulmelidir
- liste response'unda sube no yoktur; UI sube adini `branchName` alanindan gosterir
- detay ekraninda header + KDV satirlari + odeme satirlari alt panelli dusunulmelidir
- `ice aktar` butonu ayrik bir dialog ile acilmalidir; parser aktif olana kadar UI bu aksiyonu uyariyla sunabilir
- `ERP'ye gonder` aksiyonu coklu secim ile calisacakmis gibi tasarlanmalidir
- ERP gonderim sonucundaki satir mesajlari fis no / yevmiye no bilgisi tasiyabilir; UI bu mesaji satir bazli gostermelidir
- `sil` aksiyonu staging kaydi temizleme semantigiyle ele alinmalidir; ERP'de olusmus fis silme butonu gibi sunulmamalidir

#### POS Faturalar Tab'i

Bu tab'in hedefi POS kaynakli satis faturalarini once staging'e alip sonra ERP'ye aktarmaktir.

ERP'ye gonder aksiyonu secili faturalar icin Mikro tarafinda muhasebe fis detay ve fis header kayitlari olusturur. Basarili kayitlarda staging fatura header'i `IsSent = true` yapilir; hata alan kayitlar batch response icinde satir bazli doner.

Endpoint'ler:

- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar`
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/{invoiceId}`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/ice-aktar`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/erpye-gonder`
- `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/{invoiceId}`
- `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar`

UI beklentisi:

- liste ekraninda tarih bazli veri cekme aksiyonu vardir
- detay ekraninda `documentNo`, `customerTaxNo`, `paymentType` duzenleme alanlari dusunulmelidir
- satir duzeyi guncelleme bu surumde contract'ta yoktur; ekran agirlikla ust belge duzenleme mantigiyla tasarlanmalidir
- kullanici daha sonra ERP gonderimi icin birden fazla fatura secebilecekmis gibi secim modeli hazir tutulmalidir
- ERP gonderim sonucundaki `results[]` satirlari tek tek okunmali; basarili satir mesajlari fis no / yevmiye no bilgisi icerebilir

Kaynak veri davranisi:

- POS fatura importu iki kaynagi birlestirir: Furpa/Mayday kaynakli `Furpa.dbo.PosFaturas` ve opsiyonel `Vera.dbo.FATURA`
- Furpa/Mayday tarafinda yalniz `BelgeTuru = 2` alinir; `BelgeTipi` kaynak kolon gibi filtrelenmez, `BelgeTuru AS BelgeTipi` olarak uretilir
- Vera tarafi yalniz `VeraConnection` tanimliysa okunur; `BELGE_TIPI = 'FATURA'` ve `BELGE_TURU = 'FATURA'` filtresi kullanilir
- yeni staging kayitlari `Invoices` ve `InvoiceLines` tablolarina `IsSent = false` olarak yazilir
- ERP gonderiminde odeme tipine gore nakit / kredi karti mahsup hesabi, satis ve KDV satirlari muhasebe fisine yazilir

#### Gider Pusulalari Tab'i

Bu tab, POS gider pusulasi staging ve ERP'ye aktarim akisinin web karsiligidir.

ERP'ye gonder aksiyonu secili gider pusulalari icin Mikro tarafinda muhasebe fis detay ve fis header kayitlari olusturur. Basarili kayitlarda staging gider pusulasi header'i `IsSent = true` yapilir.

Endpoint'ler:

- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari`
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/{expenseId}`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/ice-aktar`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/erpye-gonder`
- `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/{expenseId}`
- `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari`

UI beklentisi:

- POS faturalar tab'ina paralel bir liste + detay kurgusu kullanilmalidir
- ayrim yalnizca is anlami ve kolon isimlerinde olmalidir
- detay formunda belge satirlari okunur, ama guncellenen alanlar header agirlikli olacakmis gibi dusunulmelidir
- ERP gonderim sonucundaki `results[]` satirlari tek tek okunmali; basarili satir mesajlari fis no / yevmiye no bilgisi icerebilir

Kaynak veri davranisi:

- gider pusulasi importu aktif WinUI davranisina uygun olarak Furpa kaynaklidir
- kaynak tablo `Furpa.dbo.PosFaturas`, satir hesap kaynagi `Furpa.dbo.PosFaturaSatirs` + Mikro `STOKLAR` eslesmesidir
- yalniz `BelgeTuru = 4` kayitlari alinir
- yeni staging kayitlari `ExpenseNotes` ve `ExpenseNoteLines` tablolarina `IsSent = false` olarak yazilir
- ERP gonderiminde odeme hesabi, gider hesabi ve indirilecek KDV satirlari muhasebe fisine yazilir

#### Kasa Eslemeleri Tab'i

Bu tab'in amaci yazar kasa / cihaz no ile sube arasindaki eslemeyi yonetmektir.

Endpoint'ler:

- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri`
- `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri/{mappingId}`

UI beklentisi:

- bu tab master-data ekranidir; tarih filtresi gerektirmez
- grid inline edit veya drawer edit mantigi uygundur
- minimum alanlar `cashRegisterNo` ve `branchNo` olarak dusunulmelidir
- request modelinde `branchName` ve `description` alanlari bulunsa da create/update tarafinda bu surumde kullanilmaz; response'taki `branchName`, `branchNo` ile Mikro depo adindan uretilir

#### UI Durum Yonetimi

Bu menu Z raporu dosya importu haric aktif backend akislariyla calisir. UI tarafinda su davranis onerilir:

- liste, detay, import, guncelleme ve silme aksiyonlari normal DTO response'lariyla calisir
- Z raporu dosya importu parser aktif olmadigi icin `success=false` sonuc satiri dondurur; UI bunu hata/uyari olarak gostermelidir
- ERP'ye gonderme aksiyonlari kayit bazli calisir; eksik kasa eslemesi, veri tutarsizligi veya muhasebe denge hatasi ilgili satirda `success=false` olarak doner
- toplu islemlerde response icindeki `results[]` satir bazli okunmali, tek bir hata tum batch basarisiz gibi gosterilmemelidir
- basarili ERP gonderim satirlari mesaj icinde fis no / yevmiye no bilgisi tasiyabilir
- `OnlyPending=true` varsayilani nedeniyle liste ekranlari ERP'ye gonderilmemis staging kayitlarini gosterir; arsiv/tum kayit gorunumu icin `OnlyPending=false` gonderilmelidir
- `sil` aksiyonu staging kaydini temizler; ERP'de olusmus muhasebe fisi silme aksiyonu gibi sunulmamalidir

#### Ekran Omurgasi

UI'nin tekrar buyuk refactor istememesi icin su omurga korunmalidir:

- tek menu, cok tab
- liste / detay / toplu islem ayrimi
- staging kaydi ile ERP kaydini ayri kavramlar olarak gosterme
- `Import`, `Detay`, `ERP'ye Gonder`, `Sil` aksiyonlarini her belge turunde ortak toolbar diliyle sunma

Bu nedenle frontend tarafinda bugunden su dil benimsenmelidir:

- `ice aktar` = kaynaktan staging'e cek
- `ERP'ye gonder` = staging'den muhasebe kaydina donustur
- `sil` = staging kaydini temizle
- `guncelle` = staging header verisini duzenle

Not:

- POS fatura, gider pusulasi ve mevcut staging Z raporlari icin ERP'ye gonderme aksiyonu Mikro muhasebe fis kayitlarini olusturur ve basarili staging header'lari `IsSent = true` yapar
- Z raporu liste/detay/silme mevcut staging tablolarini kullanir; dosyadan Z raporu parser'i henuz uygulanmamistir
- ID alanlari `int` tipindedir: `totalId`, `invoiceId`, `expenseId`, `mappingId`
- toplu gonderme ve silme isteklerinde belge tipine gore `TotalIds`, `InvoiceIds` veya `ExpenseIds` gonderilmelidir; geriye uyumluluk icin `DocumentIds` de `int` koleksiyonu olarak kabul edilir

#### Mevcut Request / Response Kontratlari

Bu menu artik scaffold response degil, belge tipine gore business DTO dondurur.

Endpoint bazli request / response ozet tablosu:

| Endpoint | Request kaynagi | Request modeli | Mevcut response |
|---|---|---|---|
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi` | query | `PosAccountingDateRangeHttpRequest` | `PosAccountingOverviewDto` |
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari` | query | `PosAccountingDateRangeHttpRequest` | `ZReportListItemDto[]` |
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/{totalId}` | path | `totalId: int` | `ZReportDetailDto` |
| `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/ice-aktar` | body | `ImportZReportsHttpRequest` | `PosAccountingImportResultDto` |
| `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/erpye-gonder` | body | `PosAccountingTransferHttpRequest` | `PosAccountingBatchResultDto` |
| `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari` | body | `PosAccountingDeleteHttpRequest` | `PosAccountingBatchResultDto` |
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar` | query | `PosAccountingDateRangeHttpRequest` | `BranchInvoiceListItemDto[]` |
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/{invoiceId}` | path | `invoiceId: int` | `BranchInvoiceDetailDto` |
| `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/ice-aktar` | body | `ImportPosDocumentsHttpRequest` | `PosAccountingImportResultDto` |
| `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/erpye-gonder` | body | `PosAccountingTransferHttpRequest` | `PosAccountingBatchResultDto` |
| `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/{invoiceId}` | body | `UpdatePosAccountingDocumentHttpRequest` | `BranchInvoiceDetailDto` |
| `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar` | body | `PosAccountingDeleteHttpRequest` | `PosAccountingBatchResultDto` |
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari` | query | `PosAccountingDateRangeHttpRequest` | `ExpenseNoteListItemDto[]` |
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/{expenseId}` | path | `expenseId: int` | `ExpenseNoteDetailDto` |
| `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/ice-aktar` | body | `ImportPosDocumentsHttpRequest` | `PosAccountingImportResultDto` |
| `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/erpye-gonder` | body | `PosAccountingTransferHttpRequest` | `PosAccountingBatchResultDto` |
| `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/{expenseId}` | body | `UpdatePosAccountingDocumentHttpRequest` | `ExpenseNoteDetailDto` |
| `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari` | body | `PosAccountingDeleteHttpRequest` | `PosAccountingBatchResultDto` |
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri` | query | `CashRegisterBranchMappingListHttpRequest` | `CashRegisterBranchMappingDto[]` |
| `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri` | body | `CashRegisterBranchMappingHttpRequest` | `CashRegisterBranchMappingDto` |
| `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri/{mappingId}` | body | `CashRegisterBranchMappingHttpRequest` | `CashRegisterBranchMappingDto` |

Request modellerinin alanlari:

```csharp
public sealed class PosAccountingDateRangeHttpRequest
{
    public DateTime? StartDate { get; init; }
    public DateTime? EndDate { get; init; }
    public int? WarehouseNo { get; init; }
    public bool OnlyPending { get; init; } = true;
}

public sealed class ImportZReportsHttpRequest
{
    public int? WarehouseNo { get; init; }
    public DateTime? BusinessDate { get; init; }
    public string? ReportPath { get; init; }
    public string? ImportMode { get; init; }
    public string? SourceCode { get; init; }
    public bool OverwriteExisting { get; init; }
}

public sealed class ImportPosDocumentsHttpRequest
{
    public int? WarehouseNo { get; init; }
    public DateTime? BusinessDate { get; init; }
    public DateTime? DateToGet { get; init; }
    public bool IncludePreviouslyImported { get; init; }
    public bool OverwriteExisting { get; init; }
}

public sealed class PosAccountingTransferHttpRequest
{
    public int? WarehouseNo { get; init; }
    public IReadOnlyCollection<int>? DocumentIds { get; init; }
    public IReadOnlyCollection<int>? TotalIds { get; init; }
    public IReadOnlyCollection<int>? InvoiceIds { get; init; }
    public IReadOnlyCollection<int>? ExpenseIds { get; init; }
    public bool ContinueOnError { get; init; } = true;
}

public sealed class PosAccountingDeleteHttpRequest
{
    public int? WarehouseNo { get; init; }
    public IReadOnlyCollection<int>? DocumentIds { get; init; }
    public IReadOnlyCollection<int>? TotalIds { get; init; }
    public IReadOnlyCollection<int>? InvoiceIds { get; init; }
    public IReadOnlyCollection<int>? ExpenseIds { get; init; }
}

public sealed class UpdatePosAccountingDocumentHttpRequest
{
    public string? DocumentNo { get; init; }
    public string? CustomerTaxNo { get; init; }
    public string? PaymentType { get; init; }
    public int? BranchNo { get; init; }
    public string? Description { get; init; }
}

public sealed class CashRegisterBranchMappingListHttpRequest
{
    public int? BranchNo { get; init; }
    public string? CashRegisterNo { get; init; }
}

public sealed class CashRegisterBranchMappingHttpRequest
{
    public string CashRegisterNo { get; init; } = string.Empty;
    public int? BranchNo { get; init; }
    public string? BranchName { get; init; }
    public string? Description { get; init; }
}
```

Alan notlari:

- `ImportPosDocumentsHttpRequest.DateToGet`, POS ekranlari icin `BusinessDate` alias'idir; iki alan da gelirse backend `BusinessDate` degerini kullanir
- `erpye-gonder` ve toplu `DELETE` body'lerinde belge tipine gore `TotalIds`, `InvoiceIds` veya `ExpenseIds` tercih edilmelidir
- `DocumentIds`, eski UI contract'lari icin geriye uyumlu yedek alandir
- `PosAccountingTransferHttpRequest.WarehouseNo` ve `PosAccountingDeleteHttpRequest.WarehouseNo` alanlari contract'ta vardir; bu surumde belge ID kapsam kontrolunde kullanilmaz
- POS fatura update islemi `DocumentNo`, `CustomerTaxNo` ve `PaymentType` alanlarini isler; `BranchNo` ve `Description` bu endpointte kullanilmaz
- gider pusulasi update islemi `BranchNo`, `DocumentNo` ve `PaymentType` alanlarini isler; `CustomerTaxNo` ve `Description` bu endpointte kullanilmaz
- kasa esleme create/update islemi `CashRegisterNo` ve `BranchNo` alanlarini isler; `BranchName` ve `Description` body alanlari bu surumde kullanilmaz

Toplu gonderme / silme body ornekleri:

```json
{
  "totalIds": [101, 102],
  "continueOnError": true
}
```

```json
{
  "invoiceIds": [125],
  "continueOnError": true
}
```

```json
{
  "expenseIds": [88],
  "continueOnError": true
}
```

Ortak import / batch response modelleri:

```csharp
public sealed record PosAccountingImportResultDto(
    string DocumentKind,
    DateTime BusinessDate,
    int ImportedCount,
    int SkippedCount,
    int ErrorCount,
    IReadOnlyCollection<PosAccountingOperationResultDto> Results);

public sealed record PosAccountingBatchResultDto(
    string DocumentKind,
    int RequestedCount,
    int SuccessCount,
    int ErrorCount,
    IReadOnlyCollection<PosAccountingOperationResultDto> Results);

public sealed record PosAccountingOperationResultDto(
    int? DocumentId,
    Guid? SourceGuid,
    bool Success,
    string Message);
```

Ornek import response:

```json
{
  "documentKind": "Invoice",
  "businessDate": "2026-06-09T00:00:00",
  "importedCount": 12,
  "skippedCount": 1,
  "errorCount": 0,
  "results": [
    {
      "documentId": 125,
      "sourceGuid": "4b7127f1-f7f7-4769-8641-8d1c6ff84d6f",
      "success": true,
      "message": "POS invoice was imported."
    }
  ]
}
```

Liste ve detay response'lari:

- `PosAccountingOverviewDto`: bekleyen Z raporu, fatura, gider pusulasi adet/tutar ozetleri ve kasa esleme adedi
- `ZReportListItemDto`: `totalId`, `billNo`, `zNo`, `cashRegisterNo`, `branchName`, `date`, `cashPaymentTotal`, `creditCardPaymentTotal`, `greatTotal`, `isSent`
- `ZReportDetailDto`: `header`, `details[]`, `bankDetails[]`
- `BranchInvoiceListItemDto`: `invoiceId`, `invoiceGuid`, `branchNo`, `branchName`, `documentNo`, `customerTaxNo`, `customerName`, `invoiceDate`, `paymentType`, `invoiceTotal`, `isSent`
- `BranchInvoiceDetailDto`: `header`, `lines[]`
- `ExpenseNoteListItemDto`: `expenseId`, `expenseGuid`, `documentNo`, `branchNo`, `branchName`, `expenseDate`, `paymentType`, `expenseTotal`, `isSent`
- `ExpenseNoteDetailDto`: `header`, `lines[]`
- `CashRegisterBranchMappingDto`: `id`, `cashRegisterNo`, `branchNo`, `branchName`

## Uyumsoft Entegrasyonu

Detayli ve Uyumsoft odakli ayri dokuman icin bkz. [UYUMSOFT_ENTEGRASYON_DOKUMANI.md](UYUMSOFT_ENTEGRASYON_DOKUMANI.md).

Bu bolum, Uyumsoft WCF client tabanli query modullerini anlatir. Bu moduller operasyonel sevk/iade ekranlarindaki mevcut `e-irsaliye gonder` ve `PDF getir` endpoint'lerinin yerine gecmez; onlar mevcut business akislari icin kullanilmaya devam eder. Yeni moduller, daha cok entegrasyon/operasyon destek ekibi icin "Uyumsoft'ta ne var, hangi GET operasyonlari acik, ilgili dokuman/paged query sonucu ne donuyor" ihtiyacini karsilar.

Bu entegrasyonun kapsami:

- Uyumsoft `BasicIntegration` servisi icin `e-fatura` query modulu
- Uyumsoft `BasicDespatchIntegration` servisi icin `e-irsaliye` query modulu
- sadece whitelist'e alinmis `Get*` operasyonlarinin acilmasi
- request body'sinde `parameters` listesiyle scalar parametre ve typed query model alani destegi
- response'un generic ve recursive bir agac modeli ile normalize edilmesi
- e-fatura `GetInboxInvoiceList` ve `GetOutboxInvoiceList` cevaplarinda frontend icin ayrica typed `invoiceList` alani donulmesi
- ileride `Send*`, `Save*`, `Query*`, `Change*`, `Set*` ailelerinin ayni omurgaya eklenebilecek sekilde tasarlanmasi

Bu moduller su an nerede kullanilir:

- entegrasyon destek/operator ekranlari
- Uyumsoft teknik baglanti dogrulama ve sistem tarihi kontrolu
- inbox/outbox belge arama, listeleme ve detay sorgulama
- PDF/view/envelope gibi Uyumsoft tarafindaki remote dokuman erisimi
- canli ortamda "servis ne donuyor" incelemesi
- UI debug ekranlari ve operasyonel self-service arayuzleri

Bu moduller ileride neler icin kullanilabilir:

- e-fatura remote inbox/outbox dashboard
- Uyumsoft durum loglari, red/cevap takibi
- operasyonel belge tekrar sorgulama ve typed response/payload JSON inceleme
- portal parity amacli alias/kullanici listeleme
- query builder bazli ileri seviye filtre ekranlari
- `SendInvoice`, `SendDespatch`, `SaveAsDraft`, `TransformAndSend` gibi yazan operasyonlar icin ayni route ailesinin genisletilmesi

Mevcut business akislardan farki:

- `POST /api/sevk-islemleri/.../e-irsaliye` ailesi mevcut Mikro evragini okuyup Uyumsoft'a gonderir
- bu yeni moduller ise Uyumsoft'un kendi GET operasyonlarini dogrudan query eder
- yeni moduller Mikro'da yeni evrak kesmez
- yeni moduller `invoiceId`, `despatchId`, `query`, `request` gibi Uyumsoft-side parametrelerle calisir
- UI bu modulleri normal depo/firma sevk detay ekraninda ana aksiyon gibi degil, entegrasyon/yonetim araci gibi konumlandirmalidir

### UI Icin Tek E-Fatura Kimlik Sozlesmesi

Frontend e-fatura liste, detay ve PDF islemlerinde asagidaki eslemeyi aynen uygulamalidir:

| API alani | Anlami | UI kullanimi |
|---|---|---|
| `invoiceUuid` | Uyumsoft teknik `InvoiceId` degeri | Row key ve tum teknik belge route'larinin path parametresi |
| `invoiceNumber` | Uyumsoft resmi `DocumentId` degeri | Kullaniciya gosterilen fatura numarasi ve arama metni |
| `direction` | Belgenin kutusu: `inbox` veya `outbox` | Badge/sekme bilgisi; PDF yolunu UI bununla yeniden uretmez |
| `pdfFilePath` | Backend'in UUID ve kutu bilgisinden olusturdugu hazir binary PDF yolu | `PDF Goster` aksiyonunda dogrudan cagrilir |
| `localDocumentId` | Uyumsoft outbox lokal belge referansi | Yardimci bilgi; teknik route anahtari degildir |

Kesin kurallar:

1. Liste kaynagi `response.invoiceList.items` alanidir.
2. UI resmi fatura numarasini `row.invoiceNumber` ile gosterir.
3. UI teknik kimlik olarak sadece `row.invoiceUuid` kullanir.
4. UI PDF URL'si uretmez; `row.pdfFilePath` degerini dogrudan cagirir.
5. UI `invoiceNumber`, `localDocumentId` veya ekranda gorunen metinden UUID/route turetmez.
6. UI yeni ekranlarda fatura numarasindan teknik UUID cozumleme denemesi yapmaz; UUID istegi hata verirse invoiceNumber ile otomatik fallback yapmaz.
7. `invoiceUuid` veya `pdfFilePath` bos ise PDF butonu pasif olur; satir veri hatasi olarak ele alinir.
8. `/pdf-file` cevabi JSON degil `application/pdf` binary veridir; istemci blob olarak okumali veya yetkili yeni sekme/iframe akisi kullanmalidir.

Kopyalanabilir temel UI akisi:

```ts
type UyumsoftInvoiceRow = {
  invoiceUuid: string | null;
  invoiceNumber: string | null;
  direction: "inbox" | "outbox";
  pdfFilePath: string | null;
};

function canOpenInvoicePdf(row: UyumsoftInvoiceRow): boolean {
  return Boolean(row.invoiceUuid && row.pdfFilePath);
}

async function openInvoicePdf(row: UyumsoftInvoiceRow, token: string) {
  if (!row.invoiceUuid || !row.pdfFilePath) {
    throw new Error("Faturanin teknik UUID/PDF yolu API cevabinda bulunamadi.");
  }

  const response = await fetch(row.pdfFilePath, {
    headers: { Authorization: `Bearer ${token}` }
  });

  if (!response.ok) {
    throw new Error(`Fatura PDF alinamadi. HTTP ${response.status}`);
  }

  const pdfBlob = await response.blob();
  const objectUrl = URL.createObjectURL(pdfBlob);
  window.open(objectUrl, "_blank", "noopener,noreferrer");
}
```

Isim benzerligine dikkat:

- route sablonundaki `{invoiceUuid}` Uyumsoft teknik kimligini ifade eder
- frontend response'undaki `invoiceUuid` bu route'a gonderilecek degerdir
- frontend response'undaki `invoiceNumber` route'a gonderilmez

### Route Aileleri

#### E-Fatura

- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/operations`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/{operationName}`
- `POST /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/{operationName}`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/system/date`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/system/date/formatted?format=yyyy-MM-dd`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceUuid}`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceUuid}/data`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceUuid}/view`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceUuid}/pdf`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceUuid}/pdf-file`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceUuid}/status-with-logs`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceUuid}`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceUuid}/data`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceUuid}/view`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceUuid}/pdf`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceUuid}/pdf-file`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceUuid}/status-with-logs`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceUuid}/response-view`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/invoices/{invoiceUuid}/envelope`

#### E-Irsaliye

- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/operations`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/get/{operationName}`
- `POST /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/get/{operationName}`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/system/date`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/system/date/formatted?format=yyyy-MM-dd`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/inbox/despatches/{despatchId}`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/inbox/despatches/{despatchId}/view`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/inbox/despatches/{despatchId}/pdf`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/inbox/despatches/{despatchId}/status-with-logs`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/outbox/despatches/{despatchId}`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/outbox/despatches/{despatchId}/view`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/outbox/despatches/{despatchId}/pdf`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/outbox/despatches/{despatchId}/status-with-logs`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/receipt-advices/{despatchId}/view`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/receipt-advices/{despatchId}/pdf`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/despatches/{despatchId}/envelope?isInbox=false`

Not:

- generic `GET/POST .../get/{operationName}` route'lari katalogdaki tum whitelist `Get*` operasyonlarini kapsar
- hazir alias `GET` route'lari katalogdaki sik kullanilan sistem tarihi ve tekil remote belge sorgularini operation formu kurmadan cagirabilmek icin vardir
- bu modullerde `/pdf`, `/view`, `/envelope` ile biten route'lar binary dosya degil, JSON `UyumsoftOperationResponseDto` doner
- e-fatura icin `/pdf-file` ile biten inbox/outbox route'lari istisnadir; direkt `application/pdf` binary response doner ve liste ekranlarindaki `PDF Goster` aksiyonlari icin onerilir
- `{invoiceUuid}` route'lari Uyumsoft teknik UUID bekler. Liste response'unda bu deger `invoiceList.items[].invoiceUuid` alanindadir.
- Liste cevabi ayrica hazir `invoiceList.items[].pdfFilePath` dondurur; yeni UI bu yolu dogrudan cagirir.
- fatura numarasiyla PDF cozumleme route'u yoktur; teknik UUID yoksa PDF butonu pasif kalir.

### Yetki Kodlari

#### E-Fatura

- `entegrasyon-islemleri.uyumsoft-e-fatura.list`
- `entegrasyon-islemleri.uyumsoft-e-fatura.detail`
- `entegrasyon-islemleri.uyumsoft-e-fatura.create`
- `entegrasyon-islemleri.uyumsoft-e-fatura.update`

Not:

- su an controller sadece `list` ve `detail` aksiyonlarini kullanir
- `create/update` permission'lari katalog standardi geregi otomatik olusur, ama aktif route baglantisi yoktur

#### E-Irsaliye

- `entegrasyon-islemleri.uyumsoft-e-irsaliye.list`
- `entegrasyon-islemleri.uyumsoft-e-irsaliye.detail`
- `entegrasyon-islemleri.uyumsoft-e-irsaliye.create`
- `entegrasyon-islemleri.uyumsoft-e-irsaliye.update`

Not:

- burada da aktif route kullanimi `list` ve `detail` ile sinirlidir

### Konfigurasyon ve Kimlik Bilgisi Modeli

Backend, `userInfo` bilgisini UI'dan almaz; server-side config ile WCF client tarafinda kendisi olusturur. Bu nedenle UI kullanicisi username/password gormez ve gondermez.

Su an kullanilan config anahtarlari:

- `EDespatch:EndpointUrl`
- `EDespatch:WsdlUrl`
- `EDespatch:Username`
- `EDespatch:Password`
- `EDespatch:ContractName`
- `EInvoice:EndpointUrl`
- `EInvoice:WsdlUrl`
- `EInvoice:Username`
- `EInvoice:Password`
- `EInvoice:ContractName`

Varsayilan adresler:

- e-fatura endpoint: `http://efatura.uyumsoft.com.tr/Services/BasicIntegration`
- e-fatura WSDL: `http://efatura.uyumsoft.com.tr/Services/BasicIntegration?wsdl`
- e-irsaliye endpoint: `http://efatura.uyumsoft.com.tr/Services/BasicDespatchIntegration`
- e-irsaliye WSDL: `http://efatura.uyumsoft.com.tr/Services/BasicDespatchIntegration?wsdl`

Onemli konfigurasyon notu:

- `EInvoice:Username` veya `EInvoice:Password` bos birakilirsa backend fallback olarak `EDespatch` credential'larini kullanir
- bu, ayni Uyumsoft musteri hesabi ile hem e-fatura hem e-irsaliye query yapilan kurulumlar icin kolaylik saglar
- ayri bir e-fatura hesabi kullanilacaksa `EInvoice:*` alanlari doldurulmalidir

### Endpoint Davranisi

#### `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura`

Amac:

- modulin genel bilgisini, resolve edilmis endpoint/WSDL adreslerini ve desteklenen GET operasyon listesini almak

Response:

- `UyumsoftConnectedServiceOverviewDto`

UI'da kullanim:

- ekran acilisinda servis karti / konfigurasyon ozet paneli
- "hangi operasyonlar acik" listesini dinamik almak
- hard-code edilmis operasyon listesi yerine backend source-of-truth'u kullanmak

#### `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/operations`

Amac:

- sadece operasyon listesini almak

Response:

- `UyumsoftOperationDefinitionDto[]`

UI'da kullanim:

- dropdown veya operasyon explorer
- kategori bazli filtreleme
- `parameters` alanina bakarak request formunu operasyon tipine gore dinamik cizme
- enum alanlarda `allowedValues` listesini dropdown olarak sunma
- array alanlarda ayni parametre adiyla coklu satir gonderebilme

Kisaltilmis response ornegi:

```json
[
  {
    "operationName": "GetOutboxInvoiceList",
    "groupName": "Giden Fatura",
    "soapAction": "GetOutboxInvoiceList",
    "requestHint": "Liste sorgusu alanlarini parameter olarak gonderin.",
    "parameters": [
      {
        "name": "PageIndex",
        "type": "int",
        "isArray": false,
        "isRequired": false,
        "description": "0 tabanli sayfa indexi. Bos veya eksi gelirse 0 kabul edilir.",
        "allowedValues": []
      },
      {
        "name": "PageSize",
        "type": "int",
        "isArray": false,
        "isRequired": false,
        "description": "Sayfa boyutu. Bos veya 0 gelirse 50 kabul edilir.",
        "allowedValues": []
      },
      {
        "name": "StatusInList",
        "type": "InvoiceStatus[]",
        "isArray": true,
        "isRequired": false,
        "description": "Dahil edilecek durum listesi.",
        "allowedValues": ["NotPrepared", "NotSend", "Draft", "Canceled", "Queued", "Processing", "SentToGib", "Approved", "WaitingForAprovement", "Declined", "Return", "EArchivedCanceled", "Error"]
      }
    ]
  }
]
```

Not:

- `allowedValues` Uyumsoft generated enum isimlerinden gelir; UI bu isimleri request'te aynen gondermelidir.
- `parameters` listesi WCF operasyon imzasindan otomatik uretilir. Bu yuzden e-fatura ve e-irsaliye generic operasyon ekranlari ayni mantikla form cizebilir.

#### `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/{operationName}`

Amac:

- whitelist'e alinmis tek bir GET operasyonunu query string ile calistirmak

Query:

- `parameter` tekrar eden query parametresidir ve `name=value` formatinda gonderilir
- direkt query alanlari da desteklenir; ornek `?PageIndex=0&PageSize=50&IsArchived=false`
- iki format birlikte gelirse hepsi ayni parameter listesine eklenir

Response:

- `UyumsoftOperationResponseDto`

Not:

- browser, test araci veya hizli operator kullanimi icin pratiktir
- kisa scalar parametreli operasyonlarda UI dogrudan bu route'u kullanabilir
- cok sayida parametre veya kompleks query model alanlari icin `POST` tercih edilmelidir
- ayni davranis `e-irsaliye` modulu icin de gecerlidir

#### `POST /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/{operationName}`

Amac:

- whitelist'e alinmis tek bir GET operasyonunu JSON body ile calistirmak

Request body:

- `UyumsoftOperationHttpRequest`

Response:

- `UyumsoftOperationResponseDto`

Not:

- ayni davranis `e-irsaliye` modulu icin de gecerlidir
- `operationName` buyuk/kucuk harf duyarli gibi dusunulmemeli; backend case-insensitive bakar
- buna ragmen UI exact isimleri her zaman `GET .../operations` cevabindan alip kullanmalidir
- cok alanli typed query modellerinde ana tercih bu route olmalidir
- `GetInboxInvoiceList` ve `GetOutboxInvoiceList` operasyonlarinda generic alanlara ek olarak typed `invoiceList` alani dolar
- `invoiceList.items[].invoiceUuid`, Uyumsoft `InvoiceId` degeridir ve PDF/detail endpointlerine gonderilecek teknik anahtardir
- `invoiceList.items[].invoiceNumber`, Uyumsoft `DocumentId` degeridir ve kullaniciya gosterilen resmi fatura numarasidir
- `invoiceList.items[].direction`, satirin `inbox` veya `outbox` kaynagindan geldigini belirtir
- `invoiceList.items[].pdfFilePath`, ilgili kutu ve teknik UUID icin backend tarafindan hazirlanmis PDF endpoint yoludur; UI bu alani dogrudan kullanir

#### Hazir alias `GET` route'lari

Amac:

- sistem tarihi ve tekil belge odakli sik sorgulari `operationName` secmeden ve generic request formu kurmadan cagirabilmek

Kullanim:

- e-fatura tarafinda `invoiceId` path parametresiyle calisir
- e-irsaliye tarafinda `despatchId` path parametresiyle calisir
- formatli sistem tarihi endpoint'lerinde `format` query parametresi kullanilir
- e-irsaliye envelope endpoint'inde `isInbox` query parametresi zorunludur

UI notu:

- entegrasyon ekraninda "Quick Actions" veya "Belge Aksiyonlari" gibi bir alan icinde bu hazir route'lar buton olarak sunulabilir

### Generic `GET` Query Formati

Tek endpoint uzerinden farkli operasyonlar `query string` ile de cagrilabilir.

Format:

- her scalar parametre icin ayri `parameter=name=value` query parametresi gonderilebilir
- veya parametreler direkt query alanlari olarak gonderilebilir
- array alanlarda direkt query formatinda ayni key tekrar edilebilir; ornek `?InvoiceIds=uuid1&InvoiceIds=uuid2`

Ornekler:

Sistem tarihi formatli alma:

```http
GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/GetSystemDateWithFormat?parameter=format=yyyy-MM-dd%20HH:mm:ss
Authorization: Bearer {token}
```

Direkt query ile gelen fatura listesi:

```http
GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/GetInboxInvoiceList?PageIndex=0&PageSize=50&ExecutionStartDate=2026-08-01T00:00:00&ExecutionEndDate=2026-08-10T23:59:59&OnlyNewestInvoices=true
Authorization: Bearer {token}
```

Envelope sorgusu:

```http
GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/get/GetDespatchEnvelope?parameter=despatchId=3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111&parameter=isInbox=false
Authorization: Bearer {token}
```

### `POST` Request Body Formati

Tek endpoint uzerinden farkli operasyonlar cagirildigi icin request body'si generic tutulmustur. Backend bu parametreleri generated WCF metod imzasina gore scalar argumanlara veya typed query model property'lerine basar.

Model:

```json
{
  "parameters": [
    { "name": "format", "value": "yyyy-MM-dd" }
  ]
}
```

Alan kurallari:

- `parameters`
  - scalar metod argumanlari ve query model property'leri icin kullanilir
  - ornek: `format`, `invoiceId`, `despatchId`, `isInbox`, `PageIndex`, `PageSize`, `IsArchived`
  - array alanlarda ayni `name` birden fazla kez gonderilebilir; ornek `InvoiceIds`, `StatusInList`, `DespatchIds`
  - array alanlar icin tekil ad da kabul edilir; ornek `InvoiceId` -> `InvoiceIds`, `DespatchId` -> `DespatchIds`
  - tarih alanlari ISO formatta gonderilmelidir; ornek `2026-08-01T00:00:00`
  - bool alanlar `true` / `false` olarak gonderilmelidir
  - enum alanlar icin `GET .../operations` cevabindaki `allowedValues` degerleri kullanilmalidir

### E-Fatura Generic Operasyon Parametreleri

UI sabit liste yazmak zorunda degildir; asagidaki liste `GET /operations` cevabindaki `parameters` alanindan okunmalidir. Yine de ana kullanim icin beklenen alanlar sunlardir:

- Tekil fatura operasyonlari: `invoiceId`
- Zarf operasyonu: `invoiceId`, `isInbox`
- Sistem tarihi formatli: `format`
- Kullanici alias sorgusu: `vknTckn`
- Kullanici listesi: `PageIndex`, `PageSize`
- Sistem kullanicisi filtreleri: `PageIndex`, `PageSize`, `Filter`, `SystemCreateDateBegin`, `SystemCreateDateEnd`, `FirstCreateDateBegin`, `FirstCreateDateEnd`, `UpdateDateBegin`, `UpdateDateEnd`
- Gelen fatura detay/veri sorgulari: `PageIndex`, `PageSize`, `ExecutionStartDate`, `ExecutionEndDate`, `InvoiceIds`, `InvoiceNumbers`, `SetTaken`, `OnlyNewestInvoices`
- Giden fatura detay/veri sorgulari: `PageIndex`, `PageSize`, `ExecutionStartDate`, `ExecutionEndDate`, `InvoiceIds`, `InvoiceNumbers`
- Gelen fatura liste sorgusu: `PageIndex`, `PageSize`, `ExecutionStartDate`, `ExecutionEndDate`, `CreateStartDate`, `CreateEndDate`, `Status`, `InvoiceIds`, `InvoiceNumbers`, `StatusInList`, `StatusNotInList`, `SortColumn`, `SortMode`, `IsArchived`, `TargetTitle`, `TargetTcknVkn`, `OnlyNewestInvoices`
- Giden fatura liste sorgusu: `PageIndex`, `PageSize`, `ExecutionStartDate`, `ExecutionEndDate`, `CreateStartDate`, `CreateEndDate`, `Status`, `InvoiceIds`, `InvoiceNumbers`, `StatusInList`, `StatusNotInList`, `SortColumn`, `SortMode`, `IsArchived`, `TargetTitle`, `TargetTcknVkn`, `Scenario`
- Ozet rapor: `startDate`, `endDate`, `periodFormat`

Durum/siralama/senaryo gibi enum alanlarin gecerli degerleri dokumanda sabit tutulmamalidir; UI `operations[].parameters[].allowedValues` listesini esas almalidir.

Ornekler:

Sistem tarihi formatli alma:

```http
POST /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/GetSystemDateWithFormat
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "parameters": [
    { "name": "format", "value": "yyyy-MM-dd HH:mm:ss" }
  ]
}
```

Tekil e-fatura PDF cekme:

```http
POST /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/GetOutboxInvoicePdf
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "parameters": [
    { "name": "invoiceId", "value": "9d6e0f84-3d3c-4c58-a1b0-4c0f8f4fd999" }
  ]
}
```

Paged e-fatura outbox listesi:

```http
POST /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/GetOutboxInvoiceList
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "parameters": [
    { "name": "PageIndex", "value": "0" },
    { "name": "PageSize", "value": "20" },
    { "name": "IsArchived", "value": "false" }
  ]
}
```

Bu operasyonun response'unda frontend listeyi `invoiceList.items` uzerinden okumali, `invoiceUuid` degerini row key olarak saklamali ve PDF aksiyonunda `pdfFilePath` alanini dogrudan kullanmalidir.

Kisaltilmis response ornegi:

```json
{
  "serviceKey": "e-invoice",
  "operationName": "GetOutboxInvoiceList",
  "isSucceeded": true,
  "invoiceList": {
    "pageIndex": 0,
    "pageSize": 20,
    "totalCount": 1,
    "totalPages": 1,
    "items": [
      {
        "invoiceUuid": "9d6e0f84-3d3c-4c58-a1b0-4c0f8f4fd999",
        "invoiceNumber": "FRM2026600075612",
        "direction": "outbox",
        "pdfFilePath": "/api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/9d6e0f84-3d3c-4c58-a1b0-4c0f8f4fd999/pdf-file",
        "localDocumentId": "FRM2026600075612",
        "scenario": "eInvoice",
        "status": "Completed",
        "createDateUtc": "2026-06-18T08:30:00Z",
        "payableAmount": 1250.00,
        "documentCurrencyCode": "TRY",
        "isArchived": false
      }
    ]
  },
  "nodes": [],
  "responsePayloadJson": "..."
}
```

Paged e-irsaliye outbox listesi:

```http
POST /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/get/GetOutboxDespatchList
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "parameters": [
    { "name": "PageIndex", "value": "1" },
    { "name": "PageSize", "value": "20" },
    { "name": "IsArchived", "value": "false" }
  ]
}
```

Envelope sorgusu:

```http
POST /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/get/GetDespatchEnvelope
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "parameters": [
    { "name": "despatchId", "value": "3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111" },
    { "name": "isInbox", "value": "false" }
  ]
}
```

### Hazir alias `GET` Ornekleri

Formatli sistem tarihi:

```http
GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/system/date/formatted?format=yyyy-MM-dd%20HH:mm:ss
Authorization: Bearer {token}
```

Tekil e-fatura PDF sorgusu:

```http
GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/9d6e0f84-3d3c-4c58-a1b0-4c0f8f4fd999/pdf
Authorization: Bearer {token}
```

Tekil e-fatura PDF dosyasi:

```http
GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/9d6e0f84-3d3c-4c58-a1b0-4c0f8f4fd999/pdf-file
Authorization: Bearer {token}
```

Frontend uygulama ornegi:

```ts
if (!row.pdfFilePath) {
  throw new Error("PDF yolu API cevabinda bulunamadi.");
}

const pdfUrl = row.pdfFilePath;
```

UI `pdfFilePath` degerini degistirmeden cagirir. `FRM2026600075612` gibi resmi fatura numarasindan URL uretmez.

Fatura numarasiyla giden e-fatura PDF cozumleme:

- `fatura-gonderimi` ekraninda kullanilmaz.
- Mikro liste kaynaginda Uyumsoft teknik `invoiceId`/ETTN kalici tutulmadigi icin `FRP...` gibi fatura numarasindan Uyumsoft PDF route'u uretilmez.
- Generic Uyumsoft outbox listesi kullaniliyorsa UI sadece API cevabinda hazir gelen `invoiceList.items[].pdfFilePath` alanini cagirir; bu alan yoksa PDF butonu pasif kalir.
- Frontend `invoiceId`, `invoiceNumber`, `sentDocumentNo` veya lokal belge referansindan kendi PDF URL'sini uretmemelidir.

Tekil e-irsaliye makbuz PDF sorgusu:

```http
GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/receipt-advices/3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111/pdf
Authorization: Bearer {token}
```

Tekil e-irsaliye envelope sorgusu:

```http
GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/despatches/3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111/envelope?isInbox=false
Authorization: Bearer {token}
```

Not:

- bu alias route'lar da `UyumsoftOperationResponseDto` JSON modeli doner
- path'te `/pdf` gecmesi binary dosya indirilecegi anlamina gelmez; PDF verisi response icindeki node/attribute/responsePayloadJson alanlarinda gelir
- e-fatura `/pdf-file` route'lari bu kuralin disindadir ve dogrudan PDF binary doner

UI request form onerisi:

- operasyon secildiginde `requestHint` alani yardim metni olarak gosterilsin
- scalar parametre ve query model alanlari ayni dinamik formda sunulsun
- cok degerli alanlar icin ayni parametre adini tekrar ekleyebilen liste UI'i kullanilsin
- request history / son kullanilan operasyon parametreleri lokal olarak cache'lenebilir
- sik kullanilan tekil belge sorgulari icin ayni ekranda ayrica hazir alias butonlari sunulabilir

### Response Formati

Tum operasyonlar normalize edilmis tek bir response modeline dondurulur:

- `serviceKey`
- `serviceName`
- `operationName`
- `resultElementName`
- `isSucceeded`
- `message`
- `scalarValue`
- `resultAttributes`
- `nodes`
- `invoiceList`
- `responsePayloadJson`

Alan anlami:

- `scalarValue`
  - basit response'lar icin hizli erisim alani
  - ornek: `GetSystemDateWithFormat`, `GenerateDocumentUrl` benzeri string/date donusleri
- `resultAttributes`
  - Uyumsoft result element'inin attribute'larini aynen tasir
  - genellikle `IsSucceded`, `Message`, `Value` gibi alanlar burada bulunur
- `nodes`
  - kompleks response'lar icin recursive tree yapisidir
  - paged result, item listesi, ic ice child node yapilari buradan okunur
- `invoiceList`
  - sadece e-fatura `GetInboxInvoiceList` ve `GetOutboxInvoiceList` cevaplarinda dolan typed liste alanidir
  - `pageIndex`, `pageSize`, `totalCount`, `totalPages`, `items` alanlarini tasir
  - diger operasyonlarda `null` olur
  - `items[].invoiceUuid`: Uyumsoft teknik `InvoiceId`; PDF/detail route'una gonderilir
  - `items[].invoiceNumber`: Uyumsoft resmi `DocumentId`; ekranda fatura no olarak gosterilir
  - `items[].direction`: `inbox` veya `outbox`
  - `items[].pdfFilePath`: UI'nin dogrudan cagiracagi `application/pdf` endpoint yolu
  - `items[].localDocumentId`, `scenario`, `scenarioCode`: outbox'a ozel alanlardir; inbox satirlarinda bos olabilir
  - `items[].isNew`, `isSeen`: inbox'a ozel alanlardir; outbox satirlarinda bos olabilir
- `responsePayloadJson`
  - WCF response objesinin JSON karsiligini verir
  - debug/response inceleme sekmesi icin uygundur

#### `invoiceList.items[]` Alan Sozlesmesi

| Alan | Tip | UI davranisi |
|---|---|---|
| `invoiceUuid` | `string/null` | Teknik Uyumsoft kimligi. Row key olarak saklanir; kullaniciya ana fatura no olarak gosterilmez. |
| `invoiceNumber` | `string/null` | Resmi fatura numarasi. Ana liste kolonunda gosterilir ve metin aramasinda kullanilir. |
| `direction` | `string` | `inbox` veya `outbox`. Salt okunur kutu bilgisidir. |
| `pdfFilePath` | `string/null` | PDF butonunun dogrudan cagiracagi relative API yolu. Bos ise buton pasif olur. |
| `localDocumentId` | `string/null` | Outbox lokal belge referansi. Route anahtari degildir. |
| `scenario` | `string/null` | Outbox senaryosu; ornek `eInvoice`, `eArchive`. |
| `scenarioCode` | `number/null` | Uyumsoft senaryo kodu. UI etiketi icin `scenario` tercih edilir. |
| `type` | `string` | Uyumsoft fatura turu metni. |
| `typeCode` | `number` | Uyumsoft fatura turu kodu. |
| `targetTcknVkn` | `string/null` | Hedef taraf TCKN/VKN bilgisi. |
| `targetTitle` | `string/null` | Hedef taraf unvani. |
| `envelopeIdentifier` | `string/null` | Uyumsoft zarf tanimlayicisi. |
| `status` | `string` | Belge durum metni. |
| `statusCode` | `number` | Belge durum kodu. |
| `envelopeStatus` | `string` | Zarf durum metni. |
| `envelopeStatusCode` | `number` | Zarf durum kodu. |
| `message` | `string/null` | Uyumsoft belge durum/aciklama mesaji. |
| `createDateUtc` | `date-time` | Uyumsoft kayit olusturma zamani, UTC. UI lokal saat dilimine cevirerek gosterebilir. |
| `executionDate` | `date-time/null` | Belgenin islem/yurutme zamani. |
| `payableAmount` | `decimal` | Odenecek toplam tutar. |
| `taxTotal` | `decimal` | Toplam vergi. |
| `taxExclusiveAmount` | `decimal` | Vergi haric toplam. |
| `documentCurrencyCode` | `string/null` | Belge para birimi; ornek `TRY`. |
| `exchangeRate` | `decimal` | Kur bilgisi. |
| `vat1`, `vat8`, `vat10`, `vat18`, `vat20` | `decimal` | Oran bazli KDV tutarlari. |
| `vat0TaxableAmount`, `vat1TaxableAmount`, `vat8TaxableAmount`, `vat10TaxableAmount`, `vat18TaxableAmount`, `vat20TaxableAmount` | `decimal` | Oran bazli vergilendirilebilir matrahlar. |
| `orderDocumentId` | `string/null` | Iliskili siparis belge numarasi. |
| `isArchived` | `boolean` | Uyumsoft arsiv durumu. |
| `invoiceTipType` | `string` | Fatura tip sinifi; ornek satis/iade karsiligi enum metni. |
| `invoiceTipTypeCode` | `number` | Fatura tip sinifi kodu. |
| `isNew` | `boolean/null` | Yalniz inbox satirlarinda yeni belge bilgisi. |
| `isSeen` | `boolean/null` | Yalniz inbox satirlarinda gorulme bilgisi. |

UI liste kolonlari icin minimum zorunlu set:

- `invoiceNumber`
- `targetTitle`
- `targetTcknVkn`
- `createDateUtc` veya `executionDate`
- `payableAmount`
- `documentCurrencyCode`
- `status`
- `direction`
- `pdfFilePath`

UI render onerisi:

- ustte ozet kart:
  - `serviceName`
  - `operationName`
  - `isSucceeded`
  - `message`
- altinda 3 sekme:
  - `Summary`
  - `Tree`
  - `Raw XML`
- `Tree` sekmesinde `nodes` recursive render edilmelidir
- `resultAttributes` ayri key-value panelinde gosterilmelidir
- `scalarValue` varsa ayri highlight kartta sunulmalidir

### Hata Davranisi

Bu modullerde exception middleware davranisi su sekildedir:

- `400 Bad Request`
  - eksik/hatali scalar parameter
  - eksik/hatali typed query parameter
  - katalogda olmayan `operationName`
- `401 Unauthorized`
  - token yok/gecersiz
- `403 Forbidden`
  - ilgili module permission'i yok
- `404 Not Found`
  - teknik UUID ile istenen remote belge/PDF bulunamadi
  - UI bu durumda ayni istegi tekrar tekrar denemez ve baska satirin UUID'sini kullanmaz
- `409 Conflict`
  - Uyumsoft remote service request'i reddetti
  - WCF servis hatasi dondu
  - server-side endpoint/credential/config eksik
- `500 Internal Server Error`
  - beklenmeyen parse/runtime problemi

UI notu:

- `409` cevaplarini "servis reddetti / uzak servis cevabi" gibi kullaniciya daha anlamli bir dille gostermek dogru olur
- `400` cevaplari ise lokal request form hatasi gibi ele alinmalidir
- hata response'undaki `correlationId`, destek/log incelemesi icin UI tarafinda kaydedilmelidir
- `pdfFilePath` cagrisi `404` donerse UI `invoiceNumber` ile fallback yapmamalidir; satiri yenileyip yeni `invoiceUuid/pdfFilePath` almak veya hatayi kullaniciya gostermek gerekir

### E-Fatura Modulu: Dahil Olan GET Operasyonlari

Not:

- asagidaki operasyonlarin tamami generic `GET/POST .../get/{operationName}` route'lari ile cagrilabilir
- hazir alias route'lar yalnizca sik kullanilan sistem tarihi ve tekil belge okuma senaryolarini kapsar

#### Sistem

- `GetSystemDate`
- `GetSystemDateWithFormat`
- `GetAccessToken`

#### Kullanicilar

- `GetEInvoiceUsers`
- `GetUserAliasses`
- `GetSystemUsersCompressedList`
- `GetSystemUsersCompressedListOld`

#### Gelen Fatura

- `GetInboxInvoices`
- `GetInboxInvoiceList`
- `GetInboxInvoice`
- `GetInboxInvoicesData`
- `GetInboxInvoiceData`
- `GetInboxInvoiceView`
- `GetInboxInvoicePdf`
- `GetInboxInvoiceStatusWithLogs`

#### Giden Fatura

- `GetOutboxInvoices`
- `GetOutboxInvoiceList`
- `GetOutboxInvoice`
- `GetOutboxInvoicesData`
- `GetOutboxInvoiceData`
- `GetOutboxInvoiceView`
- `GetOutboxInvoicePdf`
- `GetOutboxInvoiceStatusWithLogs`
- `GetOutboxInvoiceResponseView`

#### Dokuman

- `GetInvoiceEnvelope`

#### Raporlama

- `GetSummaryReport`
- `GetCustomerCreditInfo`

E-fatura modulu pratik kullanim alanlari:

- Uyumsoft inbox/outbox query paneli
- belirli invoiceId ile PDF/view cekme
- remote response XML debug ekranlari
- cari kredi / kullanici / alias destek ekranlari
- teknik destek ekibinin "servis ne donuyor" teyidi

### E-Irsaliye Modulu: Dahil Olan GET Operasyonlari

#### Sistem

- `GetSystemDate`
- `GetSystemDateWithFormat`
- `GetAccessToken`

#### Kullanicilar

- `GetEDespatchUsers`
- `GetUserAliasses`
- `GetCustomerCreditInfo`

#### Gelen Irsaliye

- `GetInboxDespatch`
- `GetInboxDespatches`
- `GetInboxDespatchList`
- `GetInboxDespatchesData`
- `GetInboxDespatchView`
- `GetInboxDespatchPdf`
- `GetInboxDespatchStatusWithLogs`

#### Giden Irsaliye

- `GetOutboxDespatch`
- `GetOutboxDespatches`
- `GetOutboxDespatchList`
- `GetOutboxDespatchesData`
- `GetOutboxDespatchView`
- `GetOutboxDespatchPdf`
- `GetOutboxDespatchStatusWithLogs`

#### Makbuz

- `GetReceiptAdviceView`
- `GetReceiptAdvicePdf`
- `GetInboxReceiptAdvicesList`
- `GetInboxReceiptAdvices`
- `GetInboxReceiptAdvicesData`

#### Dokuman

- `GetDespatchEnvelope`

E-irsaliye modulu pratik kullanim alanlari:

- Uyumsoft outbox e-irsaliye takibi
- despatch PDF ve view alma
- makbuz/receipt advice sorgulama
- envelope durumu ve arsiv/debug ihtiyaclari
- remote despatch id ile teknik destek ekranlari

### Su An Dahil Olmayan Ama Ayni Mimariye Uygun Operasyon Aileleri

E-fatura tarafinda gelecekte eklenebilir:

- `SendInvoice`
- `SendDraft`
- `SaveAsDraft`
- `CompressedSendInvoice`
- `QueryOutboxInvoiceStatus`
- `QueryInboxInvoiceStatus`
- `SetInvoicesTaken`
- `ChangeInvoiceArchiveStatus`

E-irsaliye tarafinda gelecekte eklenebilir:

- `SendDespatch`
- `SaveAsDraft`
- `SendDraft`
- `CompressedSendDespatch`
- `TransformAndSend`
- `QueryOutboxDespatchStatus`
- `QueryInboxDespatchStatus`
- `SetDespatchesTaken`
- `SetReceiptAdvicesTaken`
- `ChangeDespatchArchiveStatus`

Neden su an sadece GET acildi:

- UI tarafinda once destek/gozlem/query deneyimi kurulmak istendi
- yazan operasyonlarda request DTO semasi daha karmasiktir
- operational risk dusuk olsun diye ilk faz okuma odakli tutuldu
- ayni generic omurga ile sonraki fazda write operasyonlari da eklenebilecek

### UI Ekran Onerisi

`Uyumsoft E-Fatura` ve `Uyumsoft E-Irsaliye` icin ayri ama benzer iki ekran dusunulmelidir:

- `Servis Ozet` sekmesi
  - endpoint
  - WSDL
  - contract
  - yetki var/yok
- `Operasyon Explorer` sekmesi
  - kategori filtreli operasyon listesi
  - secili operasyon request hint'i
  - dynamic parameter formu
- `Sonuc` sekmesi
  - summary
  - tree
  - response payload
- opsiyonel `Template/History` alanlari
  - son kullanilan operasyon parametreleri
  - sik kullanilan query parametre setleri

UI'nin dikkat etmesi gereken sinirlar:

- backend sadece katalogdaki operasyonlari cagirir
- UI operationName'i manuel string olarak uretmemelidir
- `Get...Pdf` operasyonlari base64 veya data node dondugu icin UI raw sonucu dogrudan preview etmeyebilir; gerekirse ayrik base64 decode araci sonraki fazda eklenebilir
- mevcut business `e-irsaliye gonder` butonlari bu modullere tasinmamalidir

### Deployment ve Migration Notu

Bu ekleme icin yeni bir EF Core schema migration dosyasi gerekmemistir.

Sebep:

- yeni tablo/kolon/entity eklenmedi
- sadece yeni controller, service, permission catalog ve config anahtarlari eklendi

Projede zaten startup sirasinda su akis vardir:

- `Database.MigrateAsync()`
- `SynchronizePermissionCatalogAsync()`

Bu nedenle deploy sonrasi beklenen islem:

1. yeni build'i yayinla
2. `EInvoice:*` ve gerekirse `EDespatch:*` config alanlarini ortama tanimla
3. API'yi bir kez restart et
4. uygulama acilirken yeni permission kodlari otomatik senkronize olur
5. admin role mevcutsa eksik permission baglantilari da otomatik eklenir

Yani:

- migration dosyasi eklenmedi
- manuel `dotnet ef migrations add ...` ihtiyaci yok
- asil operasyonel adim konfigurasyon ve yetki dagitimidir

## Response Model Katalogu

Bu katalog backend source-of-truth olarak response modellerinin exact C# tanimlarini icerir.

Not:

- Asagidaki imzalar source code'dan alinmistir.
- Response JSON tarafinda alan adlari `camelCase` gelir.
- `IReadOnlyCollection<T>` donen response'lar JSON array olarak gelir.
- `application/pdf` donen endpointlerde JSON response modeli yoktur.
- `double` donen endpointlerde response body dogrudan sayisal degerdir.
- `POST /api/operations/saveauthorizationfile` ve `POST /api/operations/authorization-files` `201 Created` doner, response body yoktur.

### Ortak Modeller

```csharp
public sealed record ModuleActionScaffoldResponse(
    string ModuleCode,
    string ModuleName,
    string MenuCode,
    string MenuName,
    string ActionCode,
    string ActionName,
    string HttpMethod,
    string PermissionCode,
    string Route,
    string? ResourceId,
    bool IsImplemented,
    string Message);

public sealed record HomeWarehousePrioritiesDto(
    DateOnly Date,
    DateTime GeneratedAtUtc,
    int? WarehouseNo,
    string WarehouseName,
    string OverallStatus,
    string Headline,
    IReadOnlyCollection<HomePriorityMetricDto> Metrics,
    IReadOnlyCollection<HomePriorityItemDto> Priorities,
    IReadOnlyCollection<HomeQuickActionDto> QuickActions);

public sealed record HomePriorityMetricDto(
    string Code,
    string Label,
    int Value,
    string Severity,
    string? Route);

public sealed record HomePriorityItemDto(
    string Code,
    string Severity,
    string Title,
    string Description,
    int Count,
    string Route);

public sealed record HomeQuickActionDto(
    string Code,
    string Label,
    string Route,
    string? PermissionCode);

public sealed record FeedbackItemDto(
    Guid Id,
    string Type,
    string TypeName,
    string Title,
    string Message,
    string Status,
    string StatusName,
    string Priority,
    string PriorityName,
    Guid CreatedByUserId,
    string CreatedByUsername,
    string CreatedByFullName,
    int WarehouseNo,
    string WarehouseName,
    string? AdminNote,
    DateTime? ReadAtUtc,
    Guid? ReadByUserId,
    DateTime? StatusChangedAtUtc,
    Guid? StatusChangedByUserId,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc,
    DateTime? ClosedAtUtc);

public sealed record FeedbackSummaryDto(
    int MyOpenCount,
    int MyResolvedCount,
    string? LatestStatus,
    DateTime? LatestCreatedAtUtc);

public sealed record AnnouncementSummaryDto(
    int ActiveCount,
    int UnreadCount,
    Guid? LatestAnnouncementId,
    DateTime? LatestPublishedAtUtc);

public sealed record AnnouncementDto(
    Guid Id,
    string Title,
    string Message,
    string Priority,
    string PriorityName,
    string Status,
    string StatusName,
    Guid CreatedByUserId,
    string CreatedByUsername,
    string CreatedByFullName,
    DateTime? StartsAtUtc,
    DateTime? ExpiresAtUtc,
    DateTime PublishedAtUtc,
    DateTime? ArchivedAtUtc,
    Guid? ArchivedByUserId,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc,
    DateTime? ReadAtUtc,
    IReadOnlyCollection<AnnouncementTargetDto> Targets,
    AnnouncementReadSummaryDto? ReadSummary,
    IReadOnlyCollection<AnnouncementReadReceiptDto> ReadReceipts);

public sealed record AnnouncementTargetDto(
    Guid Id,
    string Type,
    string TypeName,
    int? WarehouseNo,
    string? WarehouseName,
    Guid? UserId,
    string? Username,
    string? UserFullName);

public sealed record AnnouncementReadSummaryDto(
    int ReadCount,
    int? TargetUserCount,
    int? UnreadCount,
    DateTime? LastReadAtUtc);

public sealed record AnnouncementReadReceiptListDto(
    Guid AnnouncementId,
    AnnouncementReadSummaryDto Summary,
    IReadOnlyCollection<AnnouncementReadReceiptDto> Readers);

public sealed record AnnouncementReadReceiptDto(
    Guid UserId,
    string Username,
    string UserFullName,
    string Email,
    int? WarehouseNo,
    string? WarehouseName,
    DateTime ReadAtUtc);

public sealed record AnnouncementTargetUserDto(
    Guid Id,
    string Username,
    string FullName,
    string Email,
    int? WarehouseNo,
    string? WarehouseName,
    string DisplayName);

public enum EDespatchDocumentType
{
    OutgoingCompanyShipment = 1,
    CompanyReturn = 2,
    InterWarehouseShipment = 3,
    WarehouseReturn = 4
}

public sealed record SendEDespatchResponse(
    EDespatchDocumentType DocumentType,
    string DocumentSerie,
    int DocumentOrderNo,
    string EDespatchDocumentNo,
    string EDespatchUuid,
    string ServiceDocumentId,
    string ServiceDocumentNumber,
    DateTime SentAt,
    string EndpointUrl,
    bool LocalMikroMetadataUpdated = true,
    string? Warning = null);

public enum UyumsoftConnectedServiceKind
{
    EInvoice = 1,
    EDespatch = 2
}

public sealed record UyumsoftConnectedServiceOverviewDto(
    string ServiceKey,
    string ServiceName,
    string EndpointUrl,
    string WsdlUrl,
    string ContractName,
    IReadOnlyCollection<UyumsoftOperationDefinitionDto> SupportedGetOperations);

public sealed record UyumsoftOperationDefinitionDto(
    string OperationName,
    string GroupName,
    string SoapAction,
    string RequestHint,
    IReadOnlyCollection<UyumsoftOperationParameterDefinitionDto> Parameters);

public sealed record UyumsoftOperationParameterDefinitionDto(
    string Name,
    string Type,
    bool IsArray,
    bool IsRequired,
    string? Description,
    IReadOnlyCollection<string> AllowedValues);

public sealed record UyumsoftOperationResponseDto(
    string ServiceKey,
    string ServiceName,
    string OperationName,
    string ResultElementName,
    bool IsSucceeded,
    string? Message,
    string? ScalarValue,
    IReadOnlyDictionary<string, string?> ResultAttributes,
    IReadOnlyCollection<UyumsoftResponseNodeDto> Nodes,
    UyumsoftInvoiceListDto? InvoiceList,
    string ResponsePayloadJson);

public sealed record UyumsoftResponseNodeDto(
    string Name,
    string? Value,
    IReadOnlyDictionary<string, string?> Attributes,
    IReadOnlyCollection<UyumsoftResponseNodeDto> Children);

public sealed record UyumsoftInvoiceListDto(
    int PageIndex,
    int PageSize,
    int TotalCount,
    int TotalPages,
    IReadOnlyCollection<UyumsoftInvoiceListItemDto> Items);

public sealed record UyumsoftInvoiceListItemDto(
    string? InvoiceUuid,
    string? InvoiceNumber,
    string Direction,
    string? PdfFilePath,
    string? LocalDocumentId,
    string? Scenario,
    int? ScenarioCode,
    string Type,
    int TypeCode,
    string? TargetTcknVkn,
    string? TargetTitle,
    string? EnvelopeIdentifier,
    string Status,
    int StatusCode,
    string EnvelopeStatus,
    int EnvelopeStatusCode,
    string? Message,
    DateTime CreateDateUtc,
    DateTime? ExecutionDate,
    decimal PayableAmount,
    decimal TaxTotal,
    decimal TaxExclusiveAmount,
    string? DocumentCurrencyCode,
    decimal ExchangeRate,
    decimal Vat1,
    decimal Vat8,
    decimal Vat10,
    decimal Vat18,
    decimal Vat20,
    decimal Vat0TaxableAmount,
    decimal Vat1TaxableAmount,
    decimal Vat8TaxableAmount,
    decimal Vat10TaxableAmount,
    decimal Vat18TaxableAmount,
    decimal Vat20TaxableAmount,
    string? OrderDocumentId,
    bool IsArchived,
    string InvoiceTipType,
    int InvoiceTipTypeCode,
    bool? IsNew,
    bool? IsSeen);
```

### Auth ve Yetki Modelleri

```csharp
public sealed record AuthResponse(
    string AccessToken,
    DateTime ExpiresAtUtc,
    UserDto User,
    string RefreshToken,
    DateTime RefreshTokenExpiresAtUtc);

public sealed record UserDto(
    Guid Id,
    string Username,
    string Email,
    string FirstName,
    string LastName,
    string WarehouseNo,
    string WarehouseName,
    bool IsActive,
    IReadOnlyCollection<string> Roles,
    IReadOnlyCollection<string> Permissions,
    IReadOnlyCollection<PermissionModuleDto> Modules,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc);

public sealed record RoleDto(
    Guid Id,
    string Name,
    string? Description,
    bool IsActive,
    IReadOnlyCollection<PermissionDto> Permissions,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc);

public sealed record PermissionDto(
    Guid Id,
    string Code,
    string Name,
    string? Description,
    string ModuleCode,
    string ModuleName,
    string MenuCode,
    string MenuName,
    string ActionCode,
    string ActionName,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc);

public sealed record PermissionModuleDto(
    string Code,
    string Name,
    IReadOnlyCollection<PermissionMenuDto> Menus);

public sealed record PermissionMenuDto(
    string Code,
    string Name,
    IReadOnlyCollection<PermissionActionDto> Actions);

public sealed record PermissionActionDto(
    string Code,
    string Name,
    string PermissionCode,
    string? Description);
```

### Arama Modelleri

```csharp
public sealed record ProductLookupItemDto(
    int WarehouseNo,
    string Barcode,
    string StockCode,
    string StockName,
    double Price,
    int PriceTypeCode,
    string UnitName,
    double UnitMultiplier,
    string SecondaryUnitName,
    double SecondaryUnitMultiplier,
    int? SalesBlockCode,
    int? OrderBlockCode,
    int? GoodsAcceptanceBlockCode,
    bool IsSalesBlocked,
    bool IsOrderBlocked,
    bool IsGoodsAcceptanceBlocked,
    string ProductManagerCode,
    string? RequestedBarcode = null,
    string? LookupBarcode = null,
    bool IsVariableWeightBarcode = false,
    double? EmbeddedQuantity = null,
    string? EmbeddedQuantityUnit = null,
    bool? IsBarcodeCheckDigitValid = null);

public sealed record ProductCustomerSuggestionResponse(
    bool IsProductFound,
    string StockCode,
    string? StockName,
    string? DefaultSupplierCode,
    string? DefaultSupplierName,
    IReadOnlyCollection<ProductCustomerSuggestionDto> Suggestions);

public sealed record ProductCustomerSuggestionDto(
    string CustomerCode,
    string CustomerName,
    string? TaxNoOrTckn,
    bool IsDefaultSupplier,
    int MovementCount,
    DateTime? LastMovementDate,
    string? LastDocumentNo,
    IReadOnlyCollection<string> Sources);

public sealed record BarcodeCustomerSuggestionResponse(
    bool IsFound,
    string Barcode,
    int WarehouseNo,
    string? ResolutionSource,
    string? StockCode,
    string? StockName,
    string? MatchedBarcode,
    string? PrimaryBarcode,
    string? CaseBarcode,
    double? UnitsPerCase,
    string? DefaultSupplierCode,
    string? DefaultSupplierName,
    IReadOnlyCollection<ProductCustomerSuggestionDto> Suggestions);

public sealed record CustomerLookupItemDto(
    string CustomerCode,
    string CustomerName,
    string CustomerTitle,
    string CustomerDisplayName,
    string TaxNumber,
    string TaxIdentityNo,
    string TaxOfficeNo,
    string TaxOfficeName,
    string MainCustomerCode,
    string RegionCode,
    string GroupCode,
    string SectorCode,
    string RepresentativeCode,
    string RepresentativeName,
    string MobilePhone,
    string Email,
    int? InvoiceAddressNo,
    int? ShippingAddressNo,
    bool IsLocked,
    bool IsClosed,
    bool IsEInvoiceCustomer,
    bool IsEDespatchCustomer,
    int SameTaxCustomerCount,
    string SelectionLabel);

public sealed record WarehouseLookupItemDto(
    int WarehouseNo,
    string WarehouseName,
    int? CompanyNo,
    int? BranchNo,
    string GroupCode,
    byte? WarehouseType,
    string ResponsibilityCenterCode,
    string ProjectCode,
    string Address,
    string District,
    string Province,
    bool IsInventoryExcluded);
```

### Siparis Modelleri

```csharp
public sealed record WarehouseOrderListItemDto(
    string? DocumentKey,
    DateTime DocumentDate,
    string DocumentSerie,
    int DocumentOrderNo,
    string DocumentNumber,
    int WarehouseNo,
    string WarehouseName,
    int RelatedWarehouseNo,
    string RelatedWarehouseName,
    int InWarehouseNo,
    string InWarehouseName,
    int OutWarehouseNo,
    string OutWarehouseName,
    int LineCount,
    double TotalQuantity,
    double TotalAmount,
    DateTime? DeliveryDate);

public sealed record WarehouseOrderHeaderDto(
    string? DocumentKey,
    DateTime DocumentDate,
    DateTime? DeliveryDate,
    string DocumentSerie,
    int DocumentOrderNo,
    string DocumentNumber,
    int WarehouseNo,
    string WarehouseName,
    int RelatedWarehouseNo,
    string RelatedWarehouseName,
    int InWarehouseNo,
    string InWarehouseName,
    int OutWarehouseNo,
    string OutWarehouseName,
    int LineCount,
    double TotalQuantity,
    double TotalDeliveredQuantity,
    double TotalRemainingQuantity,
    double TotalAmount,
    bool IsClosed);

public sealed record WarehouseOrderLineItemDto(
    Guid? LineGuid,
    int LineNo,
    string StockCode,
    string StockName,
    string UnitName,
    byte UnitPointer,
    double Quantity,
    double DeliveredQuantity,
    double RemainingQuantity,
    double UnitPrice,
    double LineAmount,
    bool IsClosed,
    string Description,
    string PackageCode,
    string ProjectCode,
    WarehouseOrderLineGreenGrocerCaseDto? GreenGrocerCase = null);

public sealed record WarehouseOrderLineGreenGrocerCaseDto(
    double InputQuantity,
    string InputMode,
    string ConversionMode,
    double EstimatedQuantity,
    string MicroUnit,
    double? AverageKgPerCase,
    double? UnitsPerCase,
    string AverageSource,
    int? AverageRecordCount,
    int? AverageCaseCount,
    double? CoefficientOfVariation,
    string Confidence,
    double? ActualShippedQuantity,
    double? ActualShippedCaseCount,
    string Status);

public sealed record WarehouseOrderDetailDto(
    WarehouseOrderHeaderDto Header,
    IReadOnlyCollection<WarehouseOrderLineItemDto> Items);

public sealed record CompanyOrderListItemDto(
    string? DocumentKey,
    DateTime DocumentDate,
    DateTime? DeliveryDate,
    string DocumentSerie,
    int DocumentOrderNo,
    string DocumentNumber,
    int WarehouseNo,
    string CustomerCode,
    string CustomerName,
    string CustomerTitle,
    string CustomerDisplayName,
    string CustomerAddress,
    string Description1,
    string Description2,
    string Deliverer,
    string Receiver,
    bool CanBeCalled,
    string CustomerRepresentativeCode,
    int LineCount,
    double TotalQuantity,
    double TotalDeliveredQuantity,
    double TotalRemainingQuantity,
    bool IsClosed,
    double TotalAmount);

public sealed record CompanyOrderHeaderDto(
    string? DocumentKey,
    DateTime DocumentDate,
    DateTime? DeliveryDate,
    string DocumentSerie,
    int DocumentOrderNo,
    string DocumentNumber,
    int WarehouseNo,
    string WarehouseName,
    string CustomerCode,
    string CustomerName,
    string CustomerTitle,
    string CustomerDisplayName,
    string CustomerAddress,
    string CustomerRepresentativeCode,
    string Description1,
    string Description2,
    string Deliverer,
    string Receiver,
    bool CanBeCalled,
    int LineCount,
    double TotalQuantity,
    double TotalDeliveredQuantity,
    double TotalRemainingQuantity,
    double TotalAmount,
    bool IsClosed);

public sealed record CompanyOrderLineItemDto(
    int LineNo,
    string StockCode,
    string StockName,
    string UnitName,
    byte UnitPointer,
    double Quantity,
    double DeliveredQuantity,
    double RemainingQuantity,
    double UnitPrice,
    double LineAmount,
    bool IsClosed,
    string Description,
    string PackageCode,
    string ProjectCode,
    Guid OrderGuid);

public sealed record CompanyOrderDetailDto(
    CompanyOrderHeaderDto Header,
    IReadOnlyCollection<CompanyOrderLineItemDto> Items);

public sealed record SuggestedWarehouseOrderListItemDto(
    string StockCode,
    string StockName,
    string ModelCode,
    string Barcode,
    double TargetOnHand,
    double SourceOnHand,
    double SalesQuantity,
    double OpenIncomingOrderQuantity,
    double PackageFactor,
    double MinDay,
    double RecommendedDay,
    double MaxDay,
    double RecommendedStockQuantity,
    double NeedQuantity,
    double SuggestedOrderQuantity);

public sealed record SuggestedWarehouseSourceProductDto(
    int SourceWarehouseNo,
    string SourceWarehouseName,
    string StockCode,
    string StockName,
    string ModelCode,
    string ModelName,
    string UnitName,
    string Barcode,
    double Quantity,
    double RecommendedQuantity,
    double UnitPrice,
    int UnitPointer);

public sealed record SuggestedCompanyOrderListItemDto(
    string SupplierCode,
    string SupplierName,
    string StockCode,
    string StockName,
    string ModelCode,
    string Barcode,
    double TargetOnHand,
    double SalesQuantity,
    double OpenCompanyOrderQuantity,
    double PackageFactor,
    double MinDay,
    double RecommendedDay,
    double MaxDay,
    double RecommendedStockQuantity,
    double NeedQuantity,
    double SuggestedOrderQuantity,
    double PurchasePrice,
    double MinimumPurchaseQuantity,
    int? DeliveryDay);

public sealed record CreateIssuedWarehouseOrderResponse(
    string DocumentSerie,
    int DocumentOrderNo,
    DateTime OrderDate,
    DateTime DeliveryDate,
    int InWarehouseNo,
    int OutWarehouseNo,
    int LineCount,
    double TotalQuantity,
    string WriteConnectionName);

public sealed record CreateIssuedCompanyOrderResponse(
    string DocumentSerie,
    int DocumentOrderNo,
    DateTime OrderDate,
    DateTime DeliveryDate,
    int WarehouseNo,
    string CustomerCode,
    int LineCount,
    double TotalQuantity,
    double TotalAmount,
    string WriteConnectionName);
```

### Sevk, Iade ve Mal Kabul Ortak Modelleri

```csharp
public sealed record WarehouseShippingListItemDto(
    DateTime? DocumentDate,
    DateTime? MovementDate,
    string DocumentNo,
    string DocumentSerie,
    int DocumentOrderNo,
    int SourceWarehouseNo,
    string SourceWarehouse,
    int TargetWarehouseNo,
    string TargetWarehouse,
    int ShippingWarehouseNo,
    byte ShippingState,
    bool IsReturn,
    string Plaque,
    string DriverNameSurname,
    string DriverTckn,
    string DescriptionEttn,
    string WarehouseOrderNo,
    int LineCount,
    double TotalQuantity);

public sealed record WarehouseShippingHeaderDto(
    DateTime? DocumentDate,
    DateTime? MovementDate,
    string DocumentNo,
    string DocumentSerie,
    int DocumentOrderNo,
    int SourceWarehouseNo,
    string SourceWarehouse,
    int TargetWarehouseNo,
    string TargetWarehouse,
    int ShippingWarehouseNo,
    byte ShippingState,
    bool IsReturn,
    string Plaque,
    string DriverNameSurname,
    string DriverTckn,
    string DescriptionEttn,
    string WarehouseOrderNo,
    IReadOnlyCollection<string> WarehouseOrderNos,
    int LineCount,
    double TotalQuantity,
    double TotalAmount);

public sealed record WarehouseShippingLineItemDto(
    Guid MovementGuid,
    int LineNo,
    string StockCode,
    string StockName,
    string UnitName,
    byte UnitPointer,
    double Quantity,
    double UnitPrice,
    double LineAmount,
    string Description,
    string PartyCode,
    int LotNo,
    string ProjectCode,
    string WarehouseOrderNo);

public sealed record WarehouseShippingDetailDto(
    WarehouseShippingHeaderDto Header,
    IReadOnlyCollection<WarehouseShippingLineItemDto> Items);

public sealed record CompanyMovementListItemDto(
    DateTime? DocumentDate,
    DateTime MovementCreateDate,
    DateTime? MovementDate,
    string DocumentNo,
    string DocumentSerie,
    int DocumentOrderNo,
    string CustomerCode,
    string CustomerName,
    string CustomerTitle,
    string CustomerDisplayName,
    int WarehouseNo,
    string WarehouseName,
    int InputWarehouseNo,
    string InputWarehouseName,
    int OutputWarehouseNo,
    string OutputWarehouseName,
    byte DocumentType,
    byte MovementType,
    byte ReturnType,
    string Description,
    int LineCount,
    double TotalQuantity,
    double TotalAmount);

public sealed record CompanyMovementHeaderDto(
    DateTime? DocumentDate,
    DateTime MovementCreateDate,
    DateTime? MovementDate,
    string DocumentNo,
    string DocumentSerie,
    int DocumentOrderNo,
    string CustomerCode,
    string CustomerName,
    string CustomerTitle,
    string CustomerDisplayName,
    string CustomerAddress,
    int WarehouseNo,
    string WarehouseName,
    int InputWarehouseNo,
    string InputWarehouseName,
    int OutputWarehouseNo,
    string OutputWarehouseName,
    byte DocumentType,
    byte MovementType,
    byte ReturnType,
    string Description,
    int LineCount,
    double TotalQuantity,
    double TotalAmount);

public sealed record CompanyMovementLineItemDto(
    int LineNo,
    string StockCode,
    string StockName,
    string UnitName,
    byte UnitPointer,
    double Quantity,
    double SecondaryQuantity,
    double UnitPrice,
    double LineAmount,
    double DiscountAmount,
    double ExpenseAmount,
    double TaxAmount,
    double NetWeight,
    double GrossWeight,
    string Description,
    string PartyCode,
    int LotNo,
    string ProjectCode,
    Guid? OrderGuid);

public sealed record CompanyMovementDetailDto(
    CompanyMovementHeaderDto Header,
    IReadOnlyCollection<CompanyMovementLineItemDto> Items);

public sealed record CreateInterWarehouseShipmentResponse(
    string DocumentSerie,
    int DocumentOrderNo,
    DateTime MovementDate,
    DateTime DocumentDate,
    string DocumentNo,
    int SourceWarehouseNo,
    int TargetWarehouseNo,
    int TransitWarehouseNo,
    int LineCount,
    int LinkedWarehouseOrderLineCount,
    double TotalQuantity,
    double TotalAmount,
    string WriteConnectionName);

public sealed record CreateWarehouseReturnResponse(
    string DocumentSerie,
    int DocumentOrderNo,
    DateTime MovementDate,
    DateTime DocumentDate,
    string DocumentNo,
    int SourceWarehouseNo,
    int TargetWarehouseNo,
    int TransitWarehouseNo,
    int LineCount,
    double TotalQuantity,
    double TotalAmount,
    string WriteConnectionName);

public sealed record CreateCompanyMovementResponse(
    string DocumentSerie,
    int DocumentOrderNo,
    DateTime MovementDate,
    DateTime DocumentDate,
    string DocumentNo,
    int WarehouseNo,
    string CustomerCode,
    int LineCount,
    double TotalQuantity,
    double TotalAmount,
    string WriteConnectionName);

public sealed record AcceptWarehouseReceivingResponse(
    string DocumentSerie,
    int DocumentOrderNo,
    int WarehouseNo,
    int SourceWarehouseNo,
    int TransitWarehouseNo,
    byte ShippingState,
    bool IsReturn,
    int LineCount,
    double TotalShippedQuantity,
    double TotalReceivedQuantity,
    double TotalMissingQuantity,
    double TotalExcessQuantity,
    bool HasDiscrepancy,
    string DifferenceResolutionStatus,
    string WriteConnectionName,
    IReadOnlyCollection<AcceptWarehouseReceivingLineResultDto> Lines);

public sealed record AcceptWarehouseReceivingLineResultDto(
    Guid MovementGuid,
    int LineNo,
    string StockCode,
    double ShippedQuantity,
    double ReceivedQuantity,
    double DifferenceQuantity,
    string DifferenceType);

public sealed record CreateCompanyReceivingResponse(
    string DocumentSerie,
    int DocumentOrderNo,
    DateTime MovementDate,
    DateTime DocumentDate,
    string DocumentNo,
    int WarehouseNo,
    string CustomerCode,
    int LineCount,
    double TotalReceivedQuantity,
    double TotalOrderLinkedQuantity,
    double TotalOrderlessQuantity,
    double TotalOrderOverReceivedQuantity,
    double TotalAmount,
    string WriteConnectionName,
    IReadOnlyCollection<CreateCompanyReceivingLineResultDto> Lines,
    double TotalDispatchQuantity = 0d,
    double TotalNetAcceptedQuantity = 0d,
    double TotalReturnedQuantity = 0d,
    int AutoCreatedReturnLineCount = 0,
    string? AutoCreatedReturnDocumentSerie = null,
    int? AutoCreatedReturnDocumentOrderNo = null,
    string ReturnEDespatchStatus = "Yok");

public sealed record CreateCompanyReceivingLineResultDto(
    Guid MovementGuid,
    int SourceLineNo,
    int MovementLineNo,
    string StockCode,
    Guid? OrderGuid,
    bool IsOrderLinked,
    string ReceivingMode,
    double RequestedQuantity,
    double AcceptedQuantity,
    double OrderLinkedQuantity,
    double OrderlessQuantity,
    double OrderRemainingBefore,
    double OrderRemainingAfter,
    double DispatchQuantity = 0d,
    double PhysicalAcceptedQuantity = 0d,
    double ReturnQuantity = 0d,
    string ReturnStatus = "Yok",
    Guid? ReturnMovementGuid = null,
    string? ReturnDocumentSerie = null,
    int? ReturnDocumentOrderNo = null,
    string ReturnEDespatchStatus = "Yok");
```

### Stok Modelleri

```csharp
public sealed record CreateStockReceiptResponse(
    string DocumentSerie,
    int DocumentOrderNo,
    DateTime MovementDate,
    DateTime DocumentDate,
    string DocumentNo,
    int WarehouseNo,
    string Creator,
    string Acceptor,
    int LineCount,
    double TotalQuantity,
    double TotalAmount,
    string WriteConnectionName);

public sealed record StockReceiptListItemDto(
    DateTime? DocumentDate,
    DateTime MovementCreateDate,
    DateTime? MovementDate,
    string DocumentNo,
    string DocumentSerie,
    int DocumentOrderNo,
    int WarehouseNo,
    string WarehouseName,
    string Creator,
    string Acceptor,
    string WorkOrderExpenseCode,
    byte DocumentType,
    byte MovementType,
    byte MovementGenre,
    string Description,
    int LineCount,
    double TotalQuantity,
    double TotalAmount);

public sealed record StockReceiptHeaderDto(
    DateTime? DocumentDate,
    DateTime MovementCreateDate,
    DateTime? MovementDate,
    string DocumentNo,
    string DocumentSerie,
    int DocumentOrderNo,
    int WarehouseNo,
    string WarehouseName,
    string Creator,
    string Acceptor,
    string WorkOrderExpenseCode,
    byte DocumentType,
    byte MovementType,
    byte MovementGenre,
    string Description,
    int LineCount,
    double TotalQuantity,
    double TotalAmount);

public sealed record StockReceiptLineItemDto(
    int RowNo,
    string StockCode,
    string StockName,
    string UnitName,
    byte UnitPointer,
    double Quantity,
    double Quantity2,
    double UnitPrice,
    double LineAmount,
    string Description,
    string PartyCode,
    int LotNo,
    string ProjectCode);

public sealed record StockReceiptDetailDto(
    StockReceiptHeaderDto Header,
    IReadOnlyCollection<StockReceiptLineItemDto> Items);

public sealed record CreateInventoryCountResponse(
    int DocumentNo,
    DateTime DocumentDate,
    int WarehouseNo,
    string Name,
    int LineCount,
    double TotalQuantity,
    string WriteConnectionName);

public sealed record InventoryCountListItemDto(
    DateTime? DocumentDate,
    DateTime CreatedAt,
    int DocumentNo,
    int WarehouseNo,
    string WarehouseName,
    string Name,
    int LineCount,
    double TotalQuantity);

public sealed record InventoryCountHeaderDto(
    DateTime? DocumentDate,
    DateTime CreatedAt,
    int DocumentNo,
    int WarehouseNo,
    string WarehouseName,
    string Name,
    int LineCount,
    double TotalQuantity);

public sealed record InventoryCountLineItemDto(
    int RowNo,
    string StockCode,
    string StockName,
    string Barcode,
    string UnitName,
    byte UnitPointer,
    double Quantity1,
    double Quantity2,
    double Quantity3,
    double Quantity4,
    double Quantity5);

public sealed record InventoryCountDetailDto(
    InventoryCountHeaderDto Header,
    IReadOnlyCollection<InventoryCountLineItemDto> Items);

public sealed record CreateLabelDocumentResponse(
    int DocumentId,
    DateTime CreateDate,
    int WarehouseNo,
    int LineCount);

public sealed record LabelDocumentListItemDto(
    int DocumentId,
    DateTime CreateDate,
    int WarehouseNo);

public sealed record LabelDocumentProductDto
{
    public string Package { get; init; } = string.Empty;
    public string PackageFactor { get; init; } = string.Empty;
    public DateTime LastUpdateDate { get; init; }
    public string BarcodeContent { get; init; } = string.Empty;
    public byte BulkSaleTaxRate { get; init; }
    public byte RetailSaleTaxRate { get; init; }
    public string ProductCode { get; init; } = string.Empty;
    public string ProductName { get; init; } = string.Empty;
    public string Barcode { get; init; } = string.Empty;
    public double OldPrice { get; init; }
    public double Price { get; init; }
    public string PriceChangeDate { get; init; } = string.Empty;
    public string SupplierCode { get; init; } = string.Empty;
    public byte IsClosedToSale { get; init; }
    public byte IsClosedToOrder { get; init; }
    public byte IsClosedToReceiving { get; init; }
    public bool IsPassive { get; init; }
    public string UnitName { get; init; } = string.Empty;
    public string UnitName2 { get; init; } = string.Empty;
    public string TypeCode { get; init; } = string.Empty;
    public byte IsDomestic { get; init; }
    public string Origin { get; init; } = string.Empty;
    public double UnitPriceFactor { get; init; }
    public string AlternativeUnitName { get; init; } = string.Empty;
    public int PluNo { get; init; }
    public string SectorCode { get; init; } = string.Empty;
    public short ShelfLife { get; init; }
    public string Type { get; init; } = string.Empty;
    public Guid? OrderGuid { get; init; }
    public bool CanBeCalled { get; init; }
    public double Quantity { get; init; }
    public double DeliveredQuantity { get; init; }
    public int DocumentOrderNo { get; init; }
    public string CategoryCode { get; init; } = string.Empty;
}

public sealed record LabelPriceChangedProductDto
{
    public string ProductCode { get; init; } = string.Empty;
    public string ProductName { get; init; } = string.Empty;
    public int PluNo { get; init; }
    public string AlternativeUnitName { get; init; } = string.Empty;
    public string Barcode { get; init; } = string.Empty;
    public IReadOnlyCollection<string> Barcodes { get; init; } = Array.Empty<string>();
    public byte IsDomestic { get; init; }
    public double OldPrice { get; init; }
    public string Origin { get; init; } = string.Empty;
    public double Price { get; init; }
    public string PriceChangeDate { get; init; } = string.Empty;
    public double UnitPriceFactor { get; init; }
    public string UnitName { get; init; } = string.Empty;
}

public sealed record LabelTagDto
{
    public int BranchNo { get; init; }
    public string BranchName { get; init; } = string.Empty;
    public string ProductionCity { get; init; } = string.Empty;
    public string ProductionDistrict { get; init; } = string.Empty;
    public string ProductName { get; init; } = string.Empty;
    public string GoodsType { get; init; } = string.Empty;
    public string GoodsGenus { get; init; } = string.Empty;
    public double Quantity { get; init; }
    public string TakenTag { get; init; } = string.Empty;
    public string Buyer { get; init; } = string.Empty;
    public DateTime ProductionDate { get; init; }
    public double BuyingPrice { get; init; }
    public DateTime ShippingDate { get; init; }
    public string Manufacturer { get; init; } = string.Empty;
}

public sealed record CreateVirmanResponse(
    string DocumentSerie,
    int DocumentOrderNo,
    DateTime MovementDate,
    DateTime DocumentDate,
    string DocumentNo,
    int WarehouseNo,
    IReadOnlyCollection<byte> MovementTypes,
    int LineCount,
    int IncomingLineCount,
    int OutgoingLineCount,
    double IncomingQuantity,
    double OutgoingQuantity,
    double TotalQuantity,
    double TotalAmount,
    string WriteConnectionName);

public sealed record VirmanListItemDto(
    DateTime? DocumentDate,
    DateTime MovementCreateDate,
    DateTime? MovementDate,
    string DocumentNo,
    string DocumentSerie,
    int DocumentOrderNo,
    int WarehouseNo,
    string WarehouseName,
    byte DocumentType,
    byte MovementGenre,
    IReadOnlyCollection<byte> MovementTypes,
    string Description,
    int LineCount,
    int IncomingLineCount,
    int OutgoingLineCount,
    double IncomingQuantity,
    double OutgoingQuantity,
    double TotalQuantity,
    double TotalAmount);

public sealed record VirmanHeaderDto(
    DateTime? DocumentDate,
    DateTime MovementCreateDate,
    DateTime? MovementDate,
    string DocumentNo,
    string DocumentSerie,
    int DocumentOrderNo,
    int WarehouseNo,
    string WarehouseName,
    byte DocumentType,
    byte MovementGenre,
    IReadOnlyCollection<byte> MovementTypes,
    string Description,
    int LineCount,
    int IncomingLineCount,
    int OutgoingLineCount,
    double IncomingQuantity,
    double OutgoingQuantity,
    double TotalQuantity,
    double TotalAmount);

public sealed record VirmanLineItemDto(
    int RowNo,
    string StockCode,
    string StockName,
    string UnitName,
    byte UnitPointer,
    byte MovementType,
    double Quantity,
    double Quantity2,
    double UnitPrice,
    double LineAmount,
    string Description,
    string PartyCode,
    int LotNo,
    string ProjectCode);

public sealed record VirmanDetailDto(
    VirmanHeaderDto Header,
    IReadOnlyCollection<VirmanLineItemDto> Items);
```

### Rapor Modelleri

```csharp
public sealed record SalesAnalysisAmountDto(
    string Code,
    string Name,
    double Amount);

public sealed record BankMovementAnalysisItemDto(
    int BranchNo,
    string BranchName,
    int ZNo,
    DateTime Date,
    string CashRegisterNo,
    string Bank,
    double BankAmount,
    int BankingNumber,
    string TerminalId);

public sealed record BranchBankMovementSummaryItemDto(
    int BranchNo,
    string BranchName,
    string Bank,
    double BankAmount,
    int BankingNumber);

public sealed record BankPaymentSummaryItemDto(
    string Bank,
    double Amount,
    int SlipNumber);

public sealed record BankPaymentSummaryReportDto(
    IReadOnlyCollection<BankPaymentSummaryItemDto> Items,
    double TotalAmount,
    int TotalSlipNumber);

public sealed record MerchantPaymentSummaryItemDto(
    string Bank,
    string MerchantNo,
    double Amount,
    int SlipNumber);

public sealed record MerchantPaymentSummaryReportDto(
    IReadOnlyCollection<MerchantPaymentSummaryItemDto> Items,
    double TotalAmount,
    int TotalSlipNumber);

public sealed record ValorPaymentSummaryItemDto(
    string Bank,
    int ValorDay,
    double Amount,
    int SlipNumber);

public sealed record ValorPaymentSummaryReportDto(
    IReadOnlyCollection<ValorPaymentSummaryItemDto> Items,
    double TotalAmount,
    int TotalSlipNumber);

public sealed record FoodCheckReportItemDto(
    int BranchNo,
    string BranchName,
    double Metropol,
    double Multinet,
    double Setcard,
    double SodexoKupon,
    double SodexoPos,
    double TicketKupon,
    double TicketPos,
    double Total);

public sealed record FoodCheckTotalsDto(
    double Metropol,
    double Multinet,
    double Setcard,
    double SodexoKupon,
    double SodexoPos,
    double TicketKupon,
    double TicketPos,
    double Total);

public sealed record FoodCheckReportDto(
    IReadOnlyCollection<FoodCheckReportItemDto> Items,
    FoodCheckTotalsDto Totals);

public sealed record MyoSalesReportItemDto(
    DateTime DocumentDate,
    int BranchNo,
    string BranchName,
    string DocumentSerie,
    int DocumentOrderNo,
    Guid? InvoiceGuid,
    string CustomerCode,
    string DocumentNo,
    string Description1,
    string Description2,
    string PaymentDescription,
    double SubTotal,
    double DiscountTotal,
    double NetAmount,
    double TotalTax,
    double Amount);

public sealed record MyoSalesReportDto(
    IReadOnlyCollection<MyoSalesReportItemDto> Items,
    double NetAmountTotal,
    double TotalTaxTotal,
    double AmountTotal,
    double DoorCashTotal,
    double DoorCreditCardTotal);

public sealed record MyoSalesByBranchItemDto(
    DateTime DocumentDate,
    int BranchNo,
    string BranchName,
    double Amount);

public sealed record ZReportBankAnalysisItemDto(
    string BranchName,
    int BranchNo,
    DateTime Date,
    int ZNo,
    string CashRegisterNo,
    string Bank,
    double BankAmount,
    int BankingNumber,
    string TerminalId,
    string MerchantNo);

public sealed record DiscountCardDetailItemDto(
    string CardNumber,
    int BranchNo,
    string BranchName,
    int UsageCount,
    double UsageTotal);

public sealed record MissingTurnoverBranchItemDto(
    int BranchNo,
    string BranchName,
    string Region);
```

### Ayar Modelleri

```csharp
public sealed record SettingsTypeOptionDto(
    byte Value,
    string Code,
    string Name,
    string Description,
    bool IsKnown);

public sealed record BranchSettingsLookupsDto(
    IReadOnlyCollection<SettingsTypeOptionDto> ScalesTypes,
    IReadOnlyCollection<SettingsTypeOptionDto> CashTypes);

public sealed record CashRegisterSettingsLookupsDto(
    IReadOnlyCollection<SettingsTypeOptionDto> CashTypes,
    IReadOnlyCollection<TerminalBankOptionDto> TerminalBanks);

public sealed record TerminalBankOptionDto(
    string PaymentName,
    int PaymentTypeNo,
    string AccountCode,
    string DisplayName);

public sealed record DeviceTypeDto(
    int Id,
    string DeviceName);

public sealed record DeviceDto(
    int Id,
    int BranchNo,
    int DeviceTypeId,
    string DeviceTypeName,
    string IpAddress,
    string Description);

public sealed record DeviceStatusDto(
    int BranchNo,
    int DeviceTypeId,
    string DeviceTypeName,
    string IpAddress,
    string Description,
    bool Online,
    long? LatencyMs,
    string? Error);

public sealed record BranchDetailDto(
    int BranchNo,
    string BranchIpAddress,
    string BranchScalesFolderPath,
    byte ScalesType,
    string ScalesTypeName,
    string ScalesTypeDescription,
    string PoskonFolderPath,
    string PosGenelFolderPath);

public sealed record CashRegistryDto(
    int DetailId,
    int BranchNo,
    int CashNo,
    byte CashType,
    string CashTypeName,
    string CashTypeDescription,
    string CashFinanceNumber);

public sealed record CashRegisterResponse(
    int BranchNo,
    int CashNo,
    byte CashType,
    string CashTypeName,
    string CashTypeDescription,
    IReadOnlyCollection<CashRegisterTerminalDto> Terminals);

public sealed record CashRegisterTerminalDto(
    int Id,
    string TerminalNo,
    string Bank,
    string TerminalId,
    string MerchantNo,
    int? CashNo);

// CashRegistryDto ek uyumluluk alanlari:
// CashRegisterNo = CashNo
// CashRegisterType = CashType
// CashRegisterTypeName = CashTypeName
// CashRegisterTypeDescription = CashTypeDescription
// CashRegisterTerminalDto ek uyumluluk alani:
// CashRegisterNo = TerminalNo

public sealed record CashRegisterMessageStatusDto(
    int BranchNo,
    int CashNo,
    byte CashType,
    string CashTypeName,
    string CashTypeDescription,
    int? State,
    string? StateName,
    string FilePath,
    string? Error);

public sealed record CashierDto(
    int CashierCode,
    string CashierName,
    string CashierAuthorization,
    bool CashierState);

public sealed record CashierPasswordMutationDto(
    int CashierCode,
    string GeneratedPassword,
    CashierDto Cashier);

public sealed record DespatchDriverDto(
    Guid Id,
    string FirstName,
    string LastName,
    string FullName,
    string PlateNumber,
    string Tckn,
    string MaskedTckn,
    bool IsActive,
    string? Notes,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc);
```

### Kasa Modelleri

```csharp
public sealed record CashSummaryReportItemDto(
    int WarehouseNo,
    string WarehouseName,
    double CashAmount,
    int CashAmountQuantity,
    double Akbank,
    int AkbankQuantity,
    double Halkbank,
    int HalkbankQuantity,
    double IsBankasi,
    int IsBankasiQuantity,
    double Teb,
    int TebQuantity,
    double YapiKredi,
    int YapiKrediQuantity,
    double ZiraatBankasi,
    int ZiraatBankasiQuantity,
    double Metropol,
    int MetropolQuantity,
    double Multinet,
    int MultinetQuantity,
    double Setcard,
    int SetcardQuantity,
    double SodexoKupon,
    int SodexoKuponQuantity,
    double SodexoPos,
    int SodexoPosQuantity,
    double TicketKupon,
    int TicketKuponQuantity,
    double TicketPos,
    int TicketPosQuantity,
    double ExpenseCompass,
    int ExpenseCompassQuantity,
    double StoreExpense,
    int StoreExpenseQuantity);

public sealed record CashSummaryListItemDto(
    int WarehouseNo,
    string WarehouseName,
    string DocumentSerie,
    int DocumentOrderNo,
    int CashNo,
    int ZReportNo,
    int CashierNo,
    int ManagerNo,
    DateTime SummaryDate,
    double Total);

public sealed record CashSummaryDetailItemDto(
    string TypeName,
    string PaymentName,
    int PaymentTypeId,
    int PaymentTypeNo,
    string AccountCode,
    string TerminalId,
    string Source,
    string Category,
    int SlipNumber,
    double Amount,
    string Description)
{
    public string PaymentTypeKey => "{PaymentTypeNo}|{ACCOUNT_CODE}|{TERMINAL_ID}";
}

public sealed record BanknoteMovementItemDto(
    double Value,
    int BanknoteType,
    int Quantity,
    double Total)
{
    public string BanknoteTypeName => "200 TL";
}

public sealed record BanknoteTrackDto(
    Guid BanknoteTrackId,
    int WarehouseNo,
    string WarehouseName,
    DateTime BanknoteTrackDate,
    double TotalAmount,
    double DeliveryTotalAmount,
    double DifferenceAmount,
    string Deliverer,
    string Receiver,
    DateTime CreateDate);

public sealed record BanknoteTrackDailySummaryTotalDto(
    DateTime DateToGet,
    int WarehouseNo,
    double TotalAmount);

public sealed record BanknoteTypeItemDto(
    double Value,
    double Quantity,
    double Total,
    int BanknoteType)
{
    public string BanknoteTypeName => "200 TL";
}

public sealed record GiftCheckMovementItemDto(
    double Value,
    int GiftCheckType,
    int Quantity,
    double Total)
{
    public string GiftCheckTypeName => "Hediye Çeki 100 TL";
}

public sealed record GiftCheckTypeItemDto(
    double Value,
    double Quantity,
    double Total,
    int GiftCheckType)
{
    public string GiftCheckTypeName => "Hediye Çeki 100 TL";
}

public sealed record PaymentTypeItemDto(
    string PaymentName,
    int PaymentTypeNo,
    string TerminalId,
    string AccountCode,
    int SlipNumber,
    double AmountValue)
{
    public int PaymentTypeId => PaymentTypeNo;
    public string PaymentTypeKey => "{PaymentTypeNo}|{ACCOUNT_CODE}|{TERMINAL_ID}";
}

public sealed record CashierItemDto(
    int CashierId,
    int CreateUser,
    DateTime CreateDate,
    int UpdateUser,
    DateTime UpdateDate,
    int CashierCode,
    string CashierName,
    string CashierPassword,
    string CashierAuthorization,
    bool CashierState);

public sealed record CashierSearchItemDto(
    int CashierCode,
    string CashierName,
    string CashierPassword,
    string CashierAuthorization,
    bool CashierState);

public sealed record CashRegistryItemDto(
    int DetailId,
    int BranchNo,
    int CashRegisterNo,
    byte CashRegisterType,
    string CashRegisterTypeName,
    string CashRegisterTypeDescription);

public sealed record CashRegisterDetailDto(
    int Id,
    string CashRegisterNo,
    string Bank,
    string TerminalId,
    string MerchantNo,
    int? CashNo);

public sealed record CashTurnoverListItemDto(
    DateTime BusinessDate,
    int WarehouseNo,
    string WarehouseName,
    int ShiftNo,
    string CashierCode,
    string CashierName,
    int ProductLineCount,
    double TotalSalesQuantity,
    double TotalSalesAmount,
    int PaymentLineCount,
    double TotalCollectionAmount,
    double TotalCustomerCommission,
    double NetCollectionAmount,
    string Source);

public sealed record CashTurnoverHeaderDto(
    DateTime BusinessDate,
    int WarehouseNo,
    string WarehouseName,
    int ShiftNo,
    string CashierCode,
    string CashierName,
    int ProductLineCount,
    double TotalSalesQuantity,
    double TotalSalesAmount,
    int PaymentLineCount,
    double TotalCollectionAmount,
    double TotalCustomerCommission,
    double NetCollectionAmount,
    string Source);

public sealed record CashTurnoverPaymentDetailItemDto(
    int PaymentTypeNo,
    string PaymentTypeName,
    string CashBankCode,
    string CashBankName,
    int PaymentLineCount,
    double Amount,
    double CustomerCommission,
    double NetAmount,
    string Source);

public sealed record CashTurnoverDetailDto(
    CashTurnoverHeaderDto Header,
    IReadOnlyCollection<CashTurnoverPaymentDetailItemDto> Payments);

public sealed record CashTurnoverOverviewDto(
    double DailyTotal,
    double DailyCashPayment,
    double DailyCreditCardPayment,
    double DailyGiftCardPayment,
    double DailyExpenseNoteTotal,
    int DailyCustomerCount,
    int DailyFurparaCardCustomerCount,
    int DailyDiscountCardCustomerCount,
    int DailyExpenseNoteCount,
    double AverageBasketAmount,
    int DailyFuturesSalesCount,
    double DailyFuturesSalesTotal,
    IReadOnlyCollection<CashTurnoverBranchOverviewItemDto> SubeCirolari);

public sealed record CashTurnoverBranchOverviewItemDto(
    string Region,
    int BranchNo,
    string BranchName,
    int CustomerCount,
    int DiscountCardCustomerCount,
    int FurparaCardCustomerCount,
    string LastBillTime,
    double CashTotal,
    double CreditTotal,
    double GiftCardTotal,
    double ExpenseNoteTotal,
    int ExpenseNoteCount,
    double OverallTotal,
    double FuturesSalesTotal,
    int FuturesSalesCount,
    double AverageBasketAmount);

public sealed record YeniKasaCiroOzetItemDto(
    DateTime BusinessDate,
    int WarehouseNo,
    string WarehouseName,
    string CashRegisterNo,
    string CashierCode,
    string CashierName,
    int SaleRowCount,
    int ReceiptCount,
    int ProductLineCount,
    double ProductQuantity,
    double SaleTotal,
    int PaymentLineCount,
    double PaymentTotal,
    double Difference,
    DateTime? FirstSaleAt,
    DateTime? LastSaleAt);

public sealed record YeniKasaKasaOzetItemDto(
    DateTime BusinessDate,
    int WarehouseNo,
    string WarehouseName,
    string CashRegisterNo,
    int SaleRowCount,
    int ReceiptCount,
    double SaleTotal,
    double PaymentTotal,
    double CashTotal,
    double CreditCardTotal,
    double GiftCardTotal,
    double OtherPaymentTotal,
    double UnknownPaymentTotal,
    double Difference,
    int CashierCount,
    DateTime? LastSaleAt);

public sealed record YeniKasaFisMutabakatItemDto(
    DateTime BusinessDate,
    int WarehouseNo,
    string WarehouseName,
    string CashRegisterNo,
    string CashierCode,
    string CashierName,
    string Uuid,
    string ReceiptNumber,
    int SaleRowCount,
    int ProductLineCount,
    int PaymentLineCount,
    double SaleTotal,
    double ProductLineTotal,
    double PaymentTotal,
    double SalePaymentDifference,
    double SaleLineDifference,
    string Status,
    IReadOnlyCollection<string> Issues,
    DateTime? ReceivedAt);

public sealed record YeniKasaAnomalyItemDto(
    string Type,
    string Severity,
    DateTime? BusinessDate,
    int WarehouseNo,
    string WarehouseName,
    string CashRegisterNo,
    string CashierCode,
    string Uuid,
    string ReceiptNumber,
    double SaleTotal,
    double PaymentTotal,
    double Difference,
    string Description);

public sealed record YeniKasaPaymentMethodItemDto(
    string PaymentMethodCode,
    string PaymentMethodName,
    string Category,
    int? PaymentMethodId,
    int? PavoMediator,
    int? PavoType,
    int PaymentLineCount,
    double Amount,
    bool IsKnown);

public sealed record YeniKasaSaglikOzetItemDto(
    DateTime BusinessDate,
    int WarehouseNo,
    string WarehouseName,
    string CashRegisterNo,
    int ReceiptCount,
    int ProblemReceiptCount,
    int CriticalProblemCount,
    double SaleTotal,
    double PaymentTotal,
    double DifferenceTotal,
    DateTime? LastSaleAt,
    string RiskLevel,
    IReadOnlyCollection<string> TopIssues);

public sealed record YeniKasaFisDetayDto(
    string Uuid,
    string ReceiptNumber,
    DateTime? BusinessDate,
    int WarehouseNo,
    string WarehouseName,
    string CashRegisterNo,
    string CashierCode,
    string CashierName,
    double SaleTotal,
    double ProductLineTotal,
    double PaymentTotal,
    double SalePaymentDifference,
    double SaleLineDifference,
    string Status,
    IReadOnlyCollection<string> Issues,
    IReadOnlyCollection<YeniKasaFisMutabakatItemDto> ReconciliationItems,
    IReadOnlyCollection<YeniKasaFisSatisSatiriDto> SaleRows,
    IReadOnlyCollection<YeniKasaFisUrunSatiriDto> ProductLines,
    IReadOnlyCollection<YeniKasaFisOdemeSatiriDto> Payments);

public sealed record YeniKasaFisSatisSatiriDto(
    int Id,
    string Uuid,
    string ReceiptNumber,
    DateTime ReceivedAt,
    int WarehouseNo,
    string WarehouseCode,
    string CashRegisterNo,
    string CashierCode,
    double SaleTotal,
    double RemainingAmount,
    string MarketId,
    string Status);

public sealed record YeniKasaFisUrunSatiriDto(
    int Id,
    string SaleUuid,
    decimal Quantity,
    double TotalPrice);

public sealed record YeniKasaFisOdemeSatiriDto(
    int Id,
    string SaleUuid,
    string PaymentMethodCode,
    string PaymentMethodName,
    string Category,
    int? PaymentMethodId,
    int? PavoMediator,
    int? PavoType,
    double Amount,
    bool IsIncludedInTotals);

public sealed record KasaCiroBranchDto(
    int BranchNo,
    string BranchName,
    string Region);

public sealed record KasaCiroImportResultDto(
    string RunId,
    string Status,
    DateTime StartDate,
    DateTime EndDate,
    int ProcessedDays,
    int ProcessedBranches,
    int ProcessedFiles,
    int SkippedEmptyBranches,
    int InsertedTotals,
    int UpdatedTotals,
    int InsertedDetails,
    int UpdatedDetails,
    int InsertedDiscountCards,
    int UpdatedDiscountCards,
    IReadOnlyCollection<KasaCiroImportIssueDto> Warnings,
    IReadOnlyCollection<KasaCiroImportIssueDto> Errors);

public sealed record KasaCiroImportIssueDto(
    DateTime? Date,
    int? BranchNo,
    int? CashRegisterNo,
    string? File,
    int? LineNo,
    string Message);

public sealed record KasaHareketBranchDto(
    int BranchNo,
    string BranchName,
    string Region);

public sealed record KasaHareketCashRegisterDto(
    int BranchNo,
    int CashRegisterNo,
    byte CashRegisterType,
    string CashRegisterTypeName,
    string CashRegisterTypeDescription);

public sealed record KasaHareketImportResultDto(
    string RunId,
    string ImportType,
    string Status,
    int ProcessedFiles,
    int ProcessedInvoices,
    int SkippedExistingInvoices,
    int InsertedLines,
    int InsertedPayments,
    int InsertedPromotions,
    IReadOnlyCollection<KasaHareketImportIssueDto> Warnings,
    IReadOnlyCollection<KasaHareketImportIssueDto> Errors);

public sealed record KasaHareketImportIssueDto(
    int? BranchNo,
    int? CashRegisterNo,
    string? File,
    string? ReceiptNo,
    int? LineNo,
    string Message);

public sealed record KasaHareketProcedureResultDto(
    string Procedure,
    string Message,
    DateTime Date,
    int? BranchNo,
    int? CashRegisterNo);

public sealed record KasaHareketReportRowDto(
    DateTime Date,
    int BranchNo,
    string BranchName,
    int CashRegisterNo,
    decimal NetAmount,
    decimal Expense,
    decimal CheckAmount,
    decimal Difference);

public sealed record CreateBanknoteTrackResponse(
    Guid BanknoteTrackId,
    DateTime BanknoteTrackDate,
    int WarehouseNo,
    bool Created);

public sealed record CreateCashSummaryResponse(
    string DocumentSerie,
    int DocumentOrderNo,
    DateTime SummaryDate,
    int WarehouseNo,
    int LineCount,
    double Total,
    string WriteConnectionName);

public sealed record UpdateCashSummaryDetailsResponse(
    string DocumentSerie,
    int DocumentOrderNo,
    int UpdatedLineCount,
    double TotalAmount);

public sealed record UpdateCashSummaryBanknotesResponse(
    string DocumentSerie,
    int DocumentOrderNo,
    int UpdatedLineCount,
    double TotalAmount);

public sealed record DeleteCashSummaryResponse(
    string DocumentSerie,
    int DocumentOrderNo,
    int DeletedSummaryLineCount,
    int DeletedBanknoteLineCount,
    int DeletedGiftCheckLineCount,
    int DeletedCustomerMovementCount);
```

### Fatura Modelleri

```csharp
public enum InvoiceDocumentProfile
{
    Auto = 0,
    EFatura = 1,
    EArsiv = 2
}

public enum InvoiceSendingScenario
{
    EFatura = 0,
    EArsiv = 1
}

public sealed record InvoiceRenderedDocumentDto(
    string Source,
    string InvoiceId,
    InvoiceDocumentProfile Profile,
    string AppliedXsltName,
    string XsltSource,
    bool UsedEmbeddedXslt,
    string XmlContent,
    string HtmlContent);

public sealed record InvoiceViewingListResponse(
    int TotalCount,
    int PageNumber,
    int PageSize,
    IReadOnlyCollection<InvoiceViewingListItemDto> Items);

public sealed record InvoiceViewingListItemDto(
    string DocumentId,
    string InvoiceId,
    string CustomerTitle,
    string CustomerTcknVkn,
    DateTime? CreateDate,
    DateTime? InvoiceDate,
    string InvoiceType,
    decimal InvoiceTotal,
    string DespatchId,
    bool IsProcessed,
    bool IsPrinted,
    bool IsStandard,
    string StatusCode,
    string Status,
    string EnvelopeIdentifier,
    string EnvelopeStatusCode,
    string Message,
    decimal TaxTotal,
    decimal TaxExclusiveAmount,
    string DocumentCurrencyCode,
    decimal ExchangeRate,
    string OrderDocumentId,
    bool IsArchived,
    string InvoiceTipType,
    int InvoiceTipTypeCode,
    bool? IsSeen);

public sealed record InvoiceViewingDetailDto(
    InvoiceViewingListItemDto Summary,
    InvoiceRenderedDocumentDto Document);

public sealed record InvoiceViewingPrintedStateResponse(
    InvoiceViewingListItemDto Summary,
    string Source);
```

Not:

- `InvoiceRenderedDocumentDto.InvoiceId`, inbox detay response'unda UI'nin gosterecegi fatura numarasini tasir.
- `GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}` PDF endpoint'inde lookup anahtari yine `documentId` olarak kalir.

### Operasyon Modelleri

```csharp
public sealed record OperationJobDto(
    Guid JobId,
    string Operation,
    string Status,
    int WarehouseNo,
    DateTime CreatedAtUtc);

public sealed record OperationJobDetailDto(
    Guid JobId,
    string Operation,
    string Status,
    int WarehouseNo,
    Guid RequestedByUserId,
    DateTime CreatedAtUtc,
    DateTime? StartedAtUtc,
    DateTime? CompletedAtUtc,
    string? Message,
    string? ErrorMessage,
    IReadOnlyCollection<GeneratedOperationFileDto> Files);

public sealed record GeneratedOperationFileDto(
    string FileName,
    string LocalPath,
    string? NetworkPath);

public sealed record AuthorizationFileDto
{
    public int Id { get; init; }
    public DateTime UpdateDate { get; init; }
    public string Name { get; init; } = string.Empty;
    public bool Z { get; init; }
    public bool R { get; init; }
    public bool X { get; init; }
}

public sealed record DocumentFlowListResponse(
    bool TrackingEnabled,
    int TotalCount,
    IReadOnlyCollection<DocumentFlowListItemDto> Items);

public sealed record DocumentFlowListItemDto(
    Guid Id,
    string DocumentType,
    int SourceWarehouseNo,
    int? TargetWarehouseNo,
    string DocumentSerie,
    int DocumentOrderNo,
    string? DocumentNo,
    string? ExternalDocumentNo,
    string? ExternalUuid,
    string Status,
    string CurrentStep,
    string? LastError,
    DateTime CreatedAtUtc,
    DateTime UpdatedAtUtc);

public sealed record DocumentFlowDetailDto(
    Guid Id,
    string FlowKey,
    string DocumentType,
    int SourceWarehouseNo,
    int? TargetWarehouseNo,
    string DocumentSerie,
    int DocumentOrderNo,
    string? DocumentNo,
    string? ExternalDocumentNo,
    string? ExternalUuid,
    string Status,
    string CurrentStep,
    string? LastError,
    Guid? LastChangedByUserId,
    DateTime CreatedAtUtc,
    DateTime UpdatedAtUtc,
    IReadOnlyCollection<DocumentFlowEventDto> Events);

public sealed record DocumentFlowEventDto(
    Guid Id,
    string Step,
    string Status,
    string Message,
    string? Error,
    Guid? ChangedByUserId,
    DateTime OccurredAtUtc);
```

### Entegrasyon Modelleri

```csharp
public sealed record AxataSynchronizationOverviewDto(
    bool Enabled,
    bool WorkerEnabled,
    bool SchedulerEnabled,
    string SourceDatabaseProfile,
    string MainEndpointUrl,
    string ExtendedEndpointUrl,
    IReadOnlyCollection<AxataSynchronizationTaskDto> Tasks,
    IReadOnlyCollection<AxataSynchronizationJobDto> RecentJobs);

public sealed record AxataSynchronizationTaskDto(
    string Code,
    string Name,
    string Description,
    string Flow,
    bool RequiresWarehouseNo,
    bool Enabled,
    bool ScheduleEnabled,
    int IntervalMinutes,
    int? DefaultWarehouseNo,
    string SourceSystem,
    string TargetSystem,
    bool SupportsManualDocuments,
    bool SupportsLiveDispatch,
    string? LiveOperationName);

public sealed record AxataSynchronizationPanelDto(
    string Title,
    string State,
    string Severity,
    string Message,
    bool IsInSync,
    DateTime GeneratedAtUtc,
    DateTime StartDate,
    DateTime EndDate,
    int? WarehouseNo,
    IReadOnlyCollection<AxataSynchronizationPanelMetricDto> SummaryCards,
    IReadOnlyCollection<AxataSynchronizationPanelFlowStepDto> FlowSteps,
    IReadOnlyCollection<AxataSynchronizationPanelActionDto> Actions,
    IReadOnlyCollection<AxataSynchronizationPanelDocumentDto> PriorityDocuments,
    IReadOnlyCollection<AxataSynchronizationPanelEndpointDto> PrimaryEndpoints,
    IReadOnlyCollection<string> Notes);

public sealed record AxataSynchronizationPanelMetricDto(
    string Code,
    string Label,
    int Value,
    string Severity,
    string Description);

public sealed record AxataSynchronizationPanelFlowStepDto(
    string Code,
    string Label,
    string State,
    string Severity,
    int CurrentDocumentCount,
    int ExpectedDocumentCount,
    int DifferenceDocumentCount,
    string Description,
    string? ListRoute);

public sealed record AxataSynchronizationPanelActionDto(
    string Code,
    string Label,
    string State,
    string Severity,
    int DocumentCount,
    int LineCount,
    double Quantity,
    bool CanExecute,
    bool WritesData,
    string? ListRoute,
    string? PreviewRoute,
    string? ExecuteRoute,
    string Description);

public sealed record AxataSynchronizationPanelDocumentDto(
    string DocumentSerie,
    int DocumentOrderNo,
    string DocumentNo,
    DateTime DocumentDate,
    int SourceWarehouseNo,
    int TargetWarehouseNo,
    string SynchronizationState,
    string SynchronizationStateLabel,
    string Severity,
    string RecommendedActionCode,
    string RecommendedActionTitle,
    bool CanExecute,
    string? PreviewRoute,
    string? ExecuteRoute,
    double MikroOrderQuantity,
    double MikroDeliveredQuantity,
    double AxataShipmentQuantity,
    double MikroLinkedShipmentQuantity,
    int ExistingMikroShipmentLineCount,
    double ExistingMikroShipmentQuantity,
    string? ExistingMikroShipmentDocumentNo,
    string QuantitySummary,
    string Reason);

public sealed record AxataSynchronizationPanelEndpointDto(
    string Code,
    string Label,
    string Method,
    string Route,
    bool WritesData,
    string Description);

public sealed record AxataSynchronizationWorkbenchDto(
    string Title,
    string Purpose,
    string State,
    string Severity,
    string Message,
    AxataSynchronizationPanelDto Panel,
    IReadOnlyCollection<AxataSynchronizationWorkbenchScreenSectionDto> ScreenSections,
    IReadOnlyCollection<AxataSynchronizationWorkbenchOperationGroupDto> OperationGroups,
    IReadOnlyCollection<AxataSynchronizationWorkbenchEndpointGroupDto> EndpointGroups,
    IReadOnlyCollection<AxataSynchronizationWorkbenchGlossaryItemDto> Glossary,
    IReadOnlyCollection<string> Rules);

public sealed record AxataSynchronizationWorkbenchScreenSectionDto(
    string Code,
    string Title,
    int SortOrder,
    string DataSource,
    string Purpose,
    string UiBehavior);

public sealed record AxataSynchronizationWorkbenchOperationGroupDto(
    string Code,
    string Title,
    string Direction,
    string Description,
    IReadOnlyCollection<AxataSynchronizationWorkbenchOperationDto> Operations);

public sealed record AxataSynchronizationWorkbenchOperationDto(
    string Code,
    string Title,
    string ShortTitle,
    string Direction,
    string SourceSystem,
    string TargetSystem,
    string? MovementType,
    string Purpose,
    string NormalFlow,
    string WhenToUse,
    string State,
    string Severity,
    int DocumentCount,
    int LineCount,
    double Quantity,
    bool CanExecute,
    bool WritesData,
    string WriteScope,
    string PrimaryButtonLabel,
    string ConfirmationMessage,
    string? ListRoute,
    string? PreviewRoute,
    string? ExecuteRoute,
    IReadOnlyCollection<string> EndpointCodes);

public sealed record AxataSynchronizationWorkbenchEndpointGroupDto(
    string Code,
    string Title,
    string Description,
    IReadOnlyCollection<AxataSynchronizationWorkbenchEndpointDto> Endpoints);

public sealed record AxataSynchronizationWorkbenchEndpointDto(
    string Code,
    string Title,
    string Method,
    string Route,
    string Level,
    bool WritesData,
    string WriteScope,
    string ButtonLabel,
    string Description,
    string? RequestModel,
    string? ResponseModel);

public sealed record AxataSynchronizationWorkbenchGlossaryItemDto(
    string Term,
    string UiLabel,
    string Meaning,
    string UserWarning);

public sealed record AxataSynchronizationFetchProfilesOverviewDto(
    DateTime GeneratedAtUtc,
    IReadOnlyCollection<AxataSynchronizationFetchProfileDto> Profiles,
    IReadOnlyCollection<string> Notes);

public sealed record AxataSynchronizationFetchProfileDto(
    string Code,
    string Name,
    string SourceSystem,
    string TargetSystem,
    string SourceEndpointKind,
    string SourceEndpointUrl,
    string FetchOperation,
    string AckEndpointKind,
    string AckEndpointUrl,
    string AckOperation,
    string CompanyCode,
    string WarehouseCode,
    string? MovementType,
    string PendingStatus,
    string CurrentHandling,
    string? CurrentRoute,
    bool IsImplemented);

public sealed record AxataSynchronizationPreviewDto(
    string TaskCode,
    string TaskName,
    int? WarehouseNo,
    int TotalRecordCount,
    int ReturnedRecordCount,
    DateTime GeneratedAtUtc,
    IReadOnlyCollection<AxataSynchronizationPreviewItemDto> Items,
    IReadOnlyCollection<string> Notes);

public sealed record AxataSynchronizationPreviewItemDto(
    string Key,
    string Summary,
    string PayloadJson);

public sealed record AxataSynchronizationJobDto(
    Guid JobId,
    string TaskCode,
    string TaskName,
    string Status,
    string ExecutionMode,
    string TriggerSource,
    int? WarehouseNo,
    DateTime CreatedAtUtc);

public sealed record AxataSynchronizationJobDetailDto(
    Guid JobId,
    string TaskCode,
    string TaskName,
    string Status,
    string ExecutionMode,
    string TriggerSource,
    int? WarehouseNo,
    Guid RequestedByUserId,
    DateTime CreatedAtUtc,
    DateTime? StartedAtUtc,
    DateTime? CompletedAtUtc,
    int AffectedRecordCount,
    string? Message,
    string? ErrorMessage,
    IReadOnlyCollection<AxataSynchronizationJobArtifactDto> Artifacts);

public sealed record AxataSynchronizationJobArtifactDto(
    string Name,
    string Kind,
    string Path);

public sealed record AxataSynchronizationManualDocumentDto(
    string TaskCode,
    string TaskName,
    string Flow,
    string ExecutionMode,
    int? WarehouseNo,
    string DocumentReference,
    DateTime GeneratedAtUtc,
    int AffectedRecordCount,
    string PayloadJson,
    IReadOnlyCollection<string> Notes,
    IReadOnlyCollection<AxataSynchronizationJobArtifactDto> Artifacts);

public sealed record AxataSynchronizationManualDocumentCandidatesDto(
    string TaskCode,
    string TaskName,
    string Flow,
    int? WarehouseNo,
    DateTime StartDate,
    DateTime EndDate,
    int TotalRecordCount,
    int SkippedRecordCount,
    int ReturnedRecordCount,
    DateTime GeneratedAtUtc,
    IReadOnlyCollection<AxataSynchronizationManualDocumentCandidateItemDto> Items,
    IReadOnlyCollection<string> Notes);

public sealed record AxataSynchronizationManualDocumentCandidateItemDto(
    string DocumentReference,
    string Summary,
    string? DocumentSerie,
    int? DocumentOrderNo,
    int? DocumentNo,
    DateTime? DocumentDate,
    string? DocumentIdentifier,
    int LineCount,
    double TotalQuantity);

public sealed record AxataSynchronizationManualDocumentBatchDto(
    string TaskCode,
    string TaskName,
    string Flow,
    string ExecutionMode,
    int? WarehouseNo,
    DateTime GeneratedAtUtc,
    int RequestedDocumentCount,
    int SucceededDocumentCount,
    int FailedDocumentCount,
    IReadOnlyCollection<AxataSynchronizationManualDocumentDto> Documents,
    IReadOnlyCollection<AxataSynchronizationManualDocumentBatchFailureDto> Failures,
    IReadOnlyCollection<string> Notes);

public sealed record AxataSynchronizationManualDocumentBatchFailureDto(
    string DocumentReference,
    string ErrorMessage);

public sealed record AxataSynchronizationManualDispatchDto(
    string TaskCode,
    string TaskName,
    string Flow,
    int? WarehouseNo,
    string DocumentReference,
    string OperationName,
    string EndpointUrl,
    DateTime DispatchedAtUtc,
    bool IsSuccess,
    int? ServiceState,
    string ServiceMessage,
    string PayloadJson,
    string RequestPayloadJson,
    string ResponsePayloadJson,
    IReadOnlyCollection<string> Notes);

public sealed record AxataSynchronizationManualDispatchBatchDto(
    string TaskCode,
    string TaskName,
    string Flow,
    int? WarehouseNo,
    DateTime DispatchedAtUtc,
    int RequestedDocumentCount,
    int SucceededDocumentCount,
    int FailedDocumentCount,
    IReadOnlyCollection<AxataSynchronizationManualDispatchDto> Documents,
    IReadOnlyCollection<AxataSynchronizationManualDocumentBatchFailureDto> Failures,
    IReadOnlyCollection<string> Notes);

public sealed record AxataIntegrationAuditDto(
    bool IsInSync,
    DateTime GeneratedAtUtc,
    DateTime StartDate,
    DateTime EndDate,
    int? WarehouseNo,
    AxataIntegrationAuditSummaryDto Summary,
    AxataOrderWorkflowSummaryDto WorkflowSummary,
    IReadOnlyCollection<AxataOrderLifecycleDto> OrderLifecycles,
    IReadOnlyCollection<AxataOutboundDeliveryMovementSummaryDto> OutboundDeliverySummaries,
    IReadOnlyCollection<AxataUnsyncedWarehouseOrderDto> UnsyncedWarehouseOrders,
    IReadOnlyCollection<AxataSentWarehouseOrderMissingShipmentDto> SentWarehouseOrdersMissingMikroShipments,
    IReadOnlyCollection<AxataSentWarehouseOrderMissingShipmentDto> SentWarehouseOrdersWithShipmentDifferences,
    IReadOnlyCollection<AxataPendingOutboundDeliveryDto> PendingOutboundDeliveries,
    IReadOnlyCollection<AxataPendingOutboundDeliveryDto> AxataOutboundDeliveries,
    IReadOnlyCollection<AxataPendingOutboundDeliveryDto> InterventionCandidates,
    IReadOnlyCollection<AxataIntegrationAuditOperationDto> Operations,
    IReadOnlyCollection<string> Notes);

public sealed record AxataIntegrationAuditSummaryDto(
    int MikroWarehouseOrderDocumentCount,
    int SentWarehouseOrderDocumentCount,
    int PartiallySentWarehouseOrderDocumentCount,
    int UnsentWarehouseOrderDocumentCount,
    int SentWarehouseOrderMissingMikroShipmentDocumentCount,
    int SentWarehouseOrderMissingMikroShipmentLineCount,
    double SentWarehouseOrderMissingMikroShipmentQuantity,
    int SentWarehouseOrderMissingMikroShipmentWithAxataDeliveryDocumentCount,
    int SentWarehouseOrderMissingMikroShipmentWithAxataDeliveryLineCount,
    double SentWarehouseOrderMissingMikroShipmentWithAxataDeliveryQuantity,
    int SentWarehouseOrderMissingAxataOutboundDeliveryDocumentCount,
    int SentWarehouseOrderMissingAxataOutboundDeliveryLineCount,
    double SentWarehouseOrderMissingAxataOutboundDeliveryQuantity,
    int SentWarehouseOrderShipmentDifferenceDocumentCount,
    int SentWarehouseOrderShipmentDifferenceLineCount,
    double SentWarehouseOrderShipmentDifferenceQuantity,
    int PendingOutboundDeliveryDocumentCount,
    int PendingOutboundDeliveryLineCount,
    double PendingOutboundDeliveryQuantity,
    int C01PendingDocumentCount,
    int C01MissingInMikroDocumentCount,
    int C01MikroExistsPendingAckDocumentCount,
    int AxataOutboundDeliveryDocumentCount,
    int AxataOutboundDeliveryLineCount,
    double AxataOutboundDeliveryQuantity,
    int AxataCompletedOutboundDeliveryDocumentCount,
    int AxataCancelledOutboundDeliveryDocumentCount,
    int AxataCancelledOutboundDeliveryLineCount,
    double AxataCancelledOutboundDeliveryQuantity,
    int AxataEmptyOutboundDeliveryDocumentCount);

public sealed record AxataOutboundDeliveryMovementSummaryDto(
    string MovementType,
    string PendingStatus,
    int PendingDocumentCount,
    int PendingLineCount,
    double PendingQuantity,
    int MikroMissingDocumentCount,
    int MikroExistsPendingAckDocumentCount,
    string CheckLevel);

public sealed record AxataIntegrationAuditOperationDto(
    string Code,
    string Title,
    string State,
    string Severity,
    int DocumentCount,
    int LineCount,
    double Quantity,
    string? ListRoute,
    string? PreviewRoute,
    string? ExecuteRoute,
    bool CanExecute,
    bool WritesData,
    string Description);

public sealed record AxataUnsyncedWarehouseOrderDto(
    string DocumentSerie,
    int DocumentOrderNo,
    DateTime DocumentDate,
    int InWarehouseNo,
    int OutWarehouseNo,
    int LineCount,
    int SentLineCount,
    int UnsentLineCount,
    double TotalQuantity,
    double SentQuantity,
    double UnsentQuantity,
    string State,
    DateTime? LastUpdateDate,
    string Warning);

public sealed record AxataSentWarehouseOrderMissingShipmentDto(
    string DocumentSerie,
    int DocumentOrderNo,
    DateTime DocumentDate,
    int InWarehouseNo,
    int OutWarehouseNo,
    int LineCount,
    int SentLineCount,
    int MissingMovementLinkLineCount,
    double TotalQuantity,
    double SentQuantity,
    double MissingMovementLinkQuantity,
    double DeliveredQuantity,
    int LinkedMovementLineCount,
    int DifferenceLineCount,
    double DifferenceQuantity,
    string DifferenceReason,
    string State,
    DateTime? LastUpdateDate,
    string Warning);

public sealed record AxataPendingOutboundDeliveryDto(
    string MovementType,
    string Status,
    long AxataSequenceNo,
    string AxataDeliveryNo,
    string DocumentSerie,
    int? DocumentOrderNo,
    int SourceWarehouseNo,
    int TargetWarehouseNo,
    DateTime? AxataDate,
    int LineCount,
    double Quantity,
    int MikroOrderLineCount,
    double MikroOrderQuantity,
    double MikroDeliveredQuantity,
    int ExistingLinkedMovementLineCount,
    string MikroCheckState,
    bool CanIntervene,
    string? Warning);

public sealed record AxataOutboundDeliveryQueuePreviewDto(
    string MovementType,
    string PendingStatus,
    DateTime GeneratedAtUtc,
    int TotalFetchedDocumentCount,
    int ReturnedDocumentCount,
    int TotalLineCount,
    double TotalQuantity,
    IReadOnlyCollection<AxataOutboundDeliveryQueueDocumentDto> Documents,
    IReadOnlyCollection<string> Notes);

public sealed record AxataOutboundDeliveryQueueDocumentDto(
    long AxataSequenceNo,
    string AxataDeliveryNo,
    string DocumentSerie,
    int? DocumentOrderNo,
    string MovementType,
    string Status,
    int SourceWarehouseNo,
    int TargetWarehouseNo,
    DateTime? AxataDate,
    int LineCount,
    double Quantity,
    bool HasLiveImport,
    string CurrentHandling,
    string? Warning);

public sealed record AxataOutboundDeliveriesByDateDto(
    DateTime Date,
    decimal AxataDateNumber,
    DateTime GeneratedAtUtc,
    int TotalDocumentCount,
    int TotalLineCount,
    double TotalQuantity,
    IReadOnlyCollection<AxataOutboundDeliveryByDateItemDto> Items);

public sealed record AxataOutboundDeliveryByDateItemDto(
    long AxataSequenceNo,
    string AxataDeliveryNo,
    string DocumentSerie,
    int? DocumentOrderNo,
    string Status,
    string? MovementType,
    string? SourceWarehouseCode,
    string? TargetWarehouseCode,
    DateTime? AxataDate,
    DateTime? TransferDate,
    int LineCount,
    double Quantity,
    string? VehiclePlate,
    string? DriverName);

public sealed record AxataOutboundDeliveryImportPreviewDto(
    string MovementType,
    string PendingStatus,
    DateTime GeneratedAtUtc,
    int TotalFetchedDocumentCount,
    int ReturnedDocumentCount,
    int TotalLineCount,
    double TotalQuantity,
    IReadOnlyCollection<AxataOutboundDeliveryImportDocumentDto> Documents,
    IReadOnlyCollection<string> Notes);

public sealed record AxataOutboundDeliveryImportExecuteDto(
    string MovementType,
    string PendingStatus,
    DateTime GeneratedAtUtc,
    int RequestedDocumentCount,
    int SucceededDocumentCount,
    int FailedDocumentCount,
    int SkippedDocumentCount,
    int CreatedMovementLineCount,
    double CreatedMovementQuantity,
    IReadOnlyCollection<AxataOutboundDeliveryImportResultDto> Results,
    IReadOnlyCollection<AxataOutboundDeliveryImportFailureDto> Failures,
    IReadOnlyCollection<string> Notes);

public sealed record AxataOutboundDeliveryImportDocumentDto(
    long AxataSequenceNo,
    string AxataDeliveryNo,
    string DocumentSerie,
    int DocumentOrderNo,
    string MovementType,
    string Status,
    int SourceWarehouseNo,
    int TargetWarehouseNo,
    DateTime? AxataDate,
    int AxataLineCount,
    double AxataQuantity,
    int MikroOrderLineCount,
    double MikroOrderQuantity,
    double MikroDeliveredQuantity,
    int ExistingLinkedMovementLineCount,
    bool CanImport,
    string? Warning);

public sealed record AxataOutboundDeliveryImportResultDto(
    long AxataSequenceNo,
    string AxataDeliveryNo,
    string DocumentSerie,
    int DocumentOrderNo,
    string MovementSerie,
    int MovementOrderNo,
    int CreatedMovementLineCount,
    double CreatedMovementQuantity,
    bool Acknowledged,
    string Message);

public sealed record AxataOutboundDeliveryImportFailureDto(
    long? AxataSequenceNo,
    string? AxataDeliveryNo,
    string ErrorMessage);

public sealed record AxataManualIncomingCompanyReceivingBatchResponse(
    int RequestedCount,
    int SucceededCount,
    int FailedCount,
    IReadOnlyCollection<CreateCompanyReceivingResponse> Results,
    IReadOnlyCollection<AxataManualIncomingBatchFailureResponse> Failures);

public sealed record AxataManualOutboundDeliveryBatchResponse(
    int RequestedCount,
    int SucceededCount,
    int FailedCount,
    IReadOnlyCollection<CreateInterWarehouseShipmentResponse> Results,
    IReadOnlyCollection<AxataManualIncomingBatchFailureResponse> Failures);

public sealed record AxataManualIncomingInventoryCountBatchResponse(
    int RequestedCount,
    int SucceededCount,
    int FailedCount,
    IReadOnlyCollection<CreateInventoryCountResponse> Results,
    IReadOnlyCollection<AxataManualIncomingBatchFailureResponse> Failures);

public sealed record AxataManualIncomingWarehouseReceivingBatchResponse(
    int RequestedCount,
    int SucceededCount,
    int FailedCount,
    IReadOnlyCollection<AcceptWarehouseReceivingResponse> Results,
    IReadOnlyCollection<AxataManualIncomingBatchFailureResponse> Failures);

public sealed record AxataManualIncomingBatchFailureResponse(
    string Reference,
    string ErrorMessage);

public sealed record AxataSynchronizationConnectionTestDto(
    DateTime TestedAtUtc,
    string SourceDatabaseProfile,
    IReadOnlyCollection<AxataSynchronizationProbeDto> Probes);

public sealed record AxataSynchronizationProbeDto(
    string Name,
    string Status,
    long? DurationMs,
    string? Message);
```

### Ozel Response Notlari

- `GET /` response modeli dokumanin basindaki `Root bilgi endpoint'i` bolumunde yer alir.
- `GET /api/kasa-islemleri/kasa-sayimlari/z-rapor-toplam` response body olarak `double` doner.
- E-irsaliye PDF endpointleri `application/pdf` binary response doner; JSON model yoktur.
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/.../pdf` ve `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/.../pdf` route'lari binary degil, JSON `UyumsoftOperationResponseDto` doner.
- Standart hata modeli `ProblemDetails` olarak dokumanin basinda tanimlidir.

## Request Model Katalogu

Bu bolumde yalnizca endpointlerin dogrudan baglandigi HTTP request modelleri yer alir. Alan adlari kaynak koddaki property adlariyla birebir yazilmistir.

### Auth ve Yetki Request Modelleri

- `RegisterUserRequest`: `Username`, `Email`, `Password`, `FirstName`, `LastName`, `WarehouseNo`, `WarehouseName`
- `LoginUserRequest`: `UsernameOrEmail`, `Password`
- `RefreshTokenBody`: `RefreshToken`
- `SavePermissionBody`: `Code`, `Name`, `Description`
- `SaveRoleBody`: `Name`, `Description`, `IsActive`
- `AssignPermissionsBody`: `PermissionIds`
- `UpdateUserBody`: `Username`, `Email`, `FirstName`, `LastName`, `WarehouseNo`, `WarehouseName`, `IsActive`, `NewPassword`
- `AssignRolesBody`: `RoleIds`

### Ortak Request Modelleri

- `HomeWarehousePrioritiesHttpRequest`: `Date`, `WarehouseNo`
- `WarehouseOrderDateRangeHttpRequest`: `WarehouseNo`, `StartDate`, `EndDate`
- `SendEDespatchHttpRequest`: `DriverId`, `Plaque`, `DriverNameSurname`, `DriverTckn`
- `ModuleActionRequest`: `Fields`
- `CreateFeedbackItemHttpRequest`: `Type`, `Title`, `Message`, `Priority`
- `FeedbackManagementListHttpRequest`: `Status`, `Type`, `WarehouseNo`, `StartDate`, `EndDate`, `Take`
- `ChangeFeedbackStatusHttpRequest`: `Status`, `AdminNote`
- `AnnouncementInboxHttpRequest`: `IncludeRead`, `Take`
- `AnnouncementManagementListHttpRequest`: `Status`, `TargetType`, `TargetWarehouseNo`, `TargetUserId`, `StartDate`, `EndDate`, `IncludeArchived`, `Take`
- `AnnouncementTargetUserSearchHttpRequest`: `Search`, `WarehouseNo`, `Take`
- `SaveAnnouncementHttpRequest`: `Title`, `Message`, `Priority`, `TargetType`, `TargetWarehouseNos`, `TargetUserIds`, `StartsAtUtc`, `ExpiresAtUtc`
- `CreateCompanyMovementHttpRequest`: `WarehouseNo`, `CustomerCode`, `MovementDate`, `DocumentDate`, `DocumentNo`, `Description`, `Deliverer`, `Receiver`, `Lines`
- `CreateCompanyMovementLineHttpRequest`: `StockCode`, `Quantity`, `UnitPrice`, `UnitPointer`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`, `CustomerResponsibilityCenter`, `ProductResponsibilityCenter`, `OrderLineGuid`
- `CreateStockReceiptHttpRequest`: `WarehouseNo`, `Creator`, `Acceptor`, `MovementDate`, `DocumentDate`, `DocumentNo`, `Description`, `Lines`
- `CreateStockReceiptLineHttpRequest`: `StockCode`, `Quantity`, `UnitPointer`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`
- `CreateInventoryCountHttpRequest`: `WarehouseNo`, `ClientRequestId`, `Name`, `DocumentDate`, `Lines`
- `CreateInventoryCountLineHttpRequest`: `StockCode`, `Quantity`, `Barcode`, `UnitPointer`
- `CreateVirmanHttpRequest`: `WarehouseNo`, `MovementDate`, `DocumentDate`, `DocumentNo`, `Description`, `Lines`
- `CreateVirmanLineHttpRequest`: `StockCode`, `MovementType`, `Quantity`, `UnitPointer`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`

### GreenGrocer Request Modelleri

- `GreenGrocerReportHttpRequest`: `Date`, `DateToGet`, `WarehouseNo`, `TypeCode`, `Search`, `IncludeLazyBranches`, `Take`
- `DeleteGreenGrocerOrderHttpRequest`: `DocumentSerie`, `DocumentOrderNo`, `WarehouseNo`
- `GreenGrocerProductCaseProfileListHttpRequest`: `Search`, `IncludeInactive`, `Take`
- `SaveGreenGrocerProductCaseProfileHttpRequest`: `IsActive`, `InputMode`, `ConversionMode`, `ManualKgPerCase`, `ManualUnitsPerCase`, `MinExpectedKgPerCase`, `MaxExpectedKgPerCase`, `AverageWindowDays`, `MinAverageRecordCount`, `MinAverageCaseCount`, `MaxCoefficientOfVariation`, `RequiresManualApproval`, `AllowOrderLinking`, `OverDeliveryTolerancePercent`, `Notes`
- `GreenGrocerProductCaseResolutionHttpRequest`: `StockCode`, `OrderDate`, `SourceWarehouseNo`, `InputQuantity`
- `GreenGrocerOperationsOverviewHttpRequest`: `StartDate`, `EndDate`, `WarehouseNo`, `TypeCode`, `Search`, `OnlyWithActivity`, `Take`
- `GreenGrocerOperationsAdjustmentPreviewHttpRequest`: `WarehouseNo`, `Direction`, `MovementDate`, `DocumentSerie`, `ReasonCode`, `Lines`
- `GreenGrocerOperationsAdjustmentApplyHttpRequest`: `ClientRequestId`, `WarehouseNo`, `Direction`, `MovementDate`, `DocumentDate`, `DocumentNo`, `DocumentSerie`, `CounterWarehouseNo`, `ReasonCode`, `Description`, `Creator`, `Acceptor`, `Lines`
- `GreenGrocerOperationsAdjustmentLineHttpRequest`: `StockCode`, `Quantity`, `UnitPointer`, `UnitPrice`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`

### Arama Request Modelleri

- `ProductSearchHttpRequest`: `WarehouseNo`, `Barcode`, `StockCode`, `StockName`, `SupplierCode`, `CompanyCode`, `Take`
- `ProductBarcodePriceLookupHttpRequest`: `WarehouseNo`, `Take`
- `CustomerSearchHttpRequest`: `SearchText`, `Take`
- `WarehouseSearchHttpRequest`: `SearchText`, `WarehouseNo`, `Take`
- `BarcodeResolutionHttpRequest`: `WarehouseNo`, `OperationType`, `TargetWarehouseNo`, `SupplierCode`, `CompanyCode`, `IsRefund`, `ScreenCode`
- `BarcodeCustomerLookupHttpRequest`: `Barcode`, `WarehouseNo`, `Take`
- `BarcodeCustomerLookupByPathHttpRequest`: `WarehouseNo`, `Take`
- `ProductCustomerSuggestionHttpRequest`: `WarehouseNo`, `Take`

### Siparis Request Modelleri

- `IssuedCompanyOrderListHttpRequest`: `WarehouseNo`, `StartDate`, `EndDate`, `CustomerCode`, `OnlyOpen`
- `CreateIssuedCompanyOrderHttpRequest`: `WarehouseNo`, `CustomerCode`, `OrderDate`, `DeliveryDate`, `Description1`, `Description2`, `Deliverer`, `Receiver`, `Lines`
- `CreateIssuedCompanyOrderLineHttpRequest`: `StockCode`, `Quantity`, `RecommendedQuantity`, `UnitPrice`, `UnitPointer`, `Description1`, `Description2`, `PackageCode`, `ProjectCode`, `CustomerResponsibilityCenter`, `ProductResponsibilityCenter`
- `CreateIssuedWarehouseOrderHttpRequest`: `InWarehouseNo`, `OutWarehouseNo`, `OrderDate`, `DeliveryDate`, `Description`, `Lines`
- `CreateIssuedWarehouseOrderLineHttpRequest`: `StockCode`, `Quantity`, `RecommendedQuantity`, `UnitPrice`, `UnitPointer`, `Description`, `PackageCode`, `ProjectCode`, `ResponsibilityCenter`, `GreenGrocerCase`
- `GreenGrocerOrderLineSnapshotHttpRequest`: `InputQuantity`, `InputMode`, `ConversionMode`, `MicroUnit`, `EstimatedQuantity`, `AverageKgPerCase`, `UnitsPerCase`, `AverageSource`, `AverageRecordCount`, `AverageCaseCount`, `CoefficientOfVariation`, `Confidence`
- `SuggestedWarehouseOrderListHttpRequest`: `TargetWarehouseNo`, `SourceWarehouseNo`, `LookbackDays`, `FallbackRecommendedDay`
- `ConvertSuggestedWarehouseOrderHttpRequest`: `TargetWarehouseNo`, `SourceWarehouseNo`, `OrderDate`, `DeliveryDate`, `Description`, `Lines`
- `ConvertSuggestedWarehouseOrderLineHttpRequest`: `StockCode`, `Quantity`, `RecommendedQuantity`, `UnitPrice`, `UnitPointer`, `Description`, `PackageCode`, `ProjectCode`, `ResponsibilityCenter`
- `SuggestedCompanyOrderListHttpRequest`: `WarehouseNo`, `SupplierCode`, `LookbackDays`, `FallbackRecommendedDay`
- `ConvertSuggestedCompanyOrderHttpRequest`: `WarehouseNo`, `SupplierCode`, `OrderDate`, `DeliveryDate`, `Description1`, `Description2`, `Deliverer`, `Receiver`, `Lines`
- `ConvertSuggestedCompanyOrderLineHttpRequest`: `StockCode`, `Quantity`, `RecommendedQuantity`, `UnitPrice`, `UnitPointer`, `Description1`, `Description2`, `PackageCode`, `ProjectCode`, `CustomerResponsibilityCenter`, `ProductResponsibilityCenter`

### Sevk, Iade ve Mal Kabul Request Modelleri

- `CreateInterWarehouseShipmentHttpRequest`: `SourceWarehouseNo`, `TargetWarehouseNo`, `TransitWarehouseNo`, `MovementDate`, `DocumentDate`, `DocumentNo`, `Description`, `Lines`
- `CreateInterWarehouseShipmentLineHttpRequest`: `StockCode`, `Quantity`, `WarehouseOrderLineGuid`, `UnitPrice`, `UnitPointer`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`, `CustomerResponsibilityCenter`, `ProductResponsibilityCenter`
- `CreateWarehouseReturnHttpRequest`: `SourceWarehouseNo`, `TargetWarehouseNo`, `TransitWarehouseNo`, `MovementDate`, `DocumentDate`, `DocumentNo`, `Description`, `Lines`
- `CreateWarehouseReturnLineHttpRequest`: `StockCode`, `Quantity`, `UnitPrice`, `UnitPointer`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`, `CustomerResponsibilityCenter`, `ProductResponsibilityCenter`
- `AcceptWarehouseReceivingHttpRequest`: `WarehouseNo`, `AllowDiscrepancy`, `Lines`
- `AcceptWarehouseReceivingLineHttpRequest`: `MovementGuid`, `ReceivedQuantity`
- `CreateCompanyReceivingHttpRequest`: `WarehouseNo`, `ClientRequestId`, `CustomerCode`, `MovementDate`, `DocumentDate`, `DocumentNo`, `Deliverer`, `Receiver`, `Description`, `AllowOrderOverReceiving`, `AutoCreateReturnForPartialAcceptance`, `Lines`
- `CreateCompanyReceivingLineHttpRequest`: `StockCode`, `Quantity`, `DispatchQuantity`, `AcceptedQuantity`, `UnitPrice`, `UnitPointer`, `LastConsumingDate`, `OrderGuid`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`, `CustomerResponsibilityCenter`, `ProductResponsibilityCenter`

### Stok ve Etiket Request Modelleri

- `LabelTagListHttpRequest`: `WarehouseNo`, `DateToGet`
- `ManavKunyeDetailedLabelTagListHttpRequest`: `WarehouseNo`, `DateToGet` opsiyonel
- `LabelPriceChangedProductListHttpRequest`: `WarehouseNo`, `DateTimeFilter`
- `CreateLabelDocumentHttpRequest`: `WarehouseNo`, `Lines`
- `CreateLabelDocumentLineHttpRequest`: `ProductCode`
- `ManavMalKabulVeEtiketReferenceSearchHttpRequest`: `Query`, `Take`
- `ManavMalKabulVeEtiketStockSearchHttpRequest`: `Query`, `Prefix`, `Take`
- `ManavMalKabulVeEtiketIncomingInvoiceHttpRequest`: `StartDate`, `EndDate`, `SupplierCode`, `SearchText`, `IncludeArchived`, `Take`
- `ManavMalKabulVeEtiketInvoiceDetailQuery`: `InvoiceLookupId`, `SupplierCode`
- `ManavMalKabulVeEtiketInvoiceDetailDto`: `InvoiceLookupId`, `InvoiceId`, `DocumentId`, `SupplierTitle`, `SupplierTaxNo`, `IssueDate`, `InvoiceTypeCode`, `DocumentCurrencyCode`, `TaxExclusiveAmount`, `TaxTotal`, `PayableAmount`, `DespatchId`, `MatchedSupplierCode`, `MatchedSupplierName`, `CanStartAcceptance`, `Lines`, `Warnings`
- `ManavMalKabulVeEtiketInvoiceLineDto`: `LineNo`, `LineId`, `StockCode`, `StockName`, `Barcode`, `UnitCode`, `Quantity`, `UnitPrice`, `LineAmount`, `TaxRatePercent`, `TaxAmount`, `TaxPointer`, `MatchedStockCode`, `MatchedStockName`, `MatchedBarcode`, `CanCreateAcceptance`, `Warnings`
- `ManavMalKabulVeEtiketDateHttpRequest`: `Date`
- `ManavMalKabulVeEtiketCalculationHttpRequest`: `GrossWeight`, `CaseTare`, `CaseCount`, `PalletTare`, `StockBarcode`
- `SaveManavMalKabulVeEtiketAcceptanceRecordHttpRequest`: `SupplierCode`, `SupplierName`, `DocumentSeries`, `DocumentNo`, `StockCode`, `StockName`, `StockBarcode`, `GrossWeight`, `CaseTare`, `CaseCount`, `PalletTare`, `ReceivedBy`, `CaseType`
- `ManavMalKabulVeEtiketDepotStockReportHttpRequest`: `WarehouseNo`, `Date`
- `ManavMalKabulVeEtiketCreateMicroGoodsReceiptHttpRequest`: `Date`, `SupplierCode`, `DocumentSeries`, `DocumentOrderNo`, `DocumentNo`, `MikroUserNo`, `Description`, `MarkAcceptanceRecordsTransferred`, `Lines`
- `ManavMalKabulVeEtiketCreateMicroGoodsReceiptLineHttpRequest`: `AcceptanceRecordId`, `StockCode`, `Quantity`, `UnitPrice`, `UnitPointer`, `TaxPointer`, `TaxRatePercent`, `TaxAmount`, `Description`
- `ManavMalKabulVeEtiketMicroGoodsReceiptQueryHttpRequest`: `Date`, `SupplierCode` opsiyonel

### Rapor Request Modelleri

- `StockOnHandReportHttpRequest`: `WarehouseNo`, `ReportDate`, `Search`, `SupplierCode`, `CategoryCode`, `ProducerCode`, `ProductManagerCode`, `ModelCode`, `OnlyWithStock`, `Take`
- `SupplierStockOnHandHttpRequest`: `WarehouseNo`, `ReportDate`, `SupplierCode` zorunlu, `Search`, `OnlyWithStock`, `Take`
- `CategoryStockOnHandHttpRequest`: `WarehouseNo`, `ReportDate`, `CategoryCode` zorunlu, `Search`, `OnlyWithStock`, `Take`
- `StockCategoryOptionHttpRequest`: `Search`, `OnlyActive`, `Take`
- `ProducerStockOnHandHttpRequest`: `WarehouseNo`, `ReportDate`, `ProducerCode` zorunlu, `Search`, `OnlyWithStock`, `Take`
- `ProductWarehouseStockHttpRequest`: `WarehouseNo`, `ReportDate`, `StockCodeOrBarcode` zorunlu, `OnlyWithStock`, `Take`
- `ProductWarehouseStockByPathHttpRequest`: path `stockCodeOrBarcode`, query `WarehouseNo`, `ReportDate`, `OnlyWithStock`, `Take`
- `StockCardDetailHttpRequest`: `WarehouseNo`, `Barcode`, `StockCode`, `StockName`, `SupplierCode`, `ProductManagerCode`, `Take`
- `WarehouseMissingStockHttpRequest`: `SourceWarehouseNo` zorunlu, `TargetWarehouseNo`, `ReportDate`, `Search`, `ModelCode`, `Take`
- `WarehouseZeroStockHttpRequest`: `WarehouseNo`, `ReportDate`, `ModelCode`, `Take`
- `StockMovementReportHttpRequest`: `WarehouseNo`, `StartDate` zorunlu, `EndDate` zorunlu, `StockCode`, `Take`
- `FilteredDateRangeReportHttpRequest`: `WarehouseNo`, `StartDate` zorunlu, `EndDate` zorunlu, `FilterType`, `FilterValue`, `Take`
- `ReturnBranchReportHttpRequest`: `WarehouseNo`, `StartDate` zorunlu, `EndDate` zorunlu, `StockCode` zorunlu, `Take`
- `NotSoldProductReportHttpRequest`: `WarehouseNo`, `StartDate` zorunlu, `EndDate` zorunlu, `ProductManagerCode`, `IncludeDls`, `Take`
- `ProfitabilityReportHttpRequest`: `WarehouseNo`, `StartDate` zorunlu, `EndDate` zorunlu, `Scope`, `FilterValue`, `Take`
- `CountingComparisonReportHttpRequest`: `WarehouseNo`, `CountDate` zorunlu, `DocumentNo`, `PackageCode`, `Take`
- `GET /api/rapor-islemleri/stok-raporlari/*` endpointleri body almaz; filtreler query parametresi olarak gonderilir.
- `Take` tum stok raporlari icin 1-1000 araligindadir; default endpoint bazinda 100, 250 veya 500 olabilir.
- `PromotionBulletinListHttpRequest`: `WarehouseNo`, `ActiveOn`, `OnlyActive`, `Search`, `Take`
- `PromotionBulletinOptionHttpRequest`: `WarehouseNo`, `ActiveOn`, `OnlyActive`, `Search`, `Take`
- `PromotionPerformanceHttpRequest`: `WarehouseNo`, `StartDate` opsiyonel, `EndDate` opsiyonel, `PromotionCode`, `Search`, `Take`
- `GET /api/rapor-islemleri/promosyon-raporlari/*` endpointleri body almaz; filtreler query parametresi olarak gonderilir.

### Mikro Evrak Duzenleme Request Modelleri

- `StockCardSearchHttpRequest`: `SearchText`, `IncludePassive`, `Take`
- `StockCardPatchHttpRequest`: `Name`, `ShortName`, `ForeignName`, `SupplierCode`, `StockType`, `CurrencyType`, `TrackingType`, `Unit1Name`, `Unit2Name`, `Unit3Name`, `Unit4Name`, `RetailTaxPointer`, `WholesaleTaxPointer`, `CategoryCode`, `MainGroupCode`, `SubGroupCode`, `BrandCode`, `SectorCode`, `RayonCode`, `ManufacturerCode`, `ResponsibilityCode`, `ShelfCode`, `Special1`, `Special2`, `Special3`, `SalesStopped`, `OrderStopped`, `ReceivingStopped`, `IsPassive`, `DiscountDisabled`
- `WarehouseCardPatchHttpRequest`: `Name`, `GroupCode`, `WarehouseType`, `ShipmentAutoPriceType`, `MovementType`, `AccountingCode`, `ResponsibilityCenter`, `ProjectCode`, `Special1`, `Special2`, `Special3`, `ShipmentAppliedPriceNo`, `LockDate`, adres/telefon/GPS alanlari, `ExcludedFromInventory`, `DetailTrackingType`, `RegionCode`, `OutgoingEDespatchEnabled`, `IncomingEDespatchEnabled`, `IsPassive`, `IsHidden`, `IsLocked`
- `CustomerCardPatchHttpRequest`: `Title1`, `Title2`, `Special1`, `Special2`, `Special3`, `MovementType`, `ConnectionType`, `PurchaseStockType`, `SalesStockType`, muhasebe/doviz/vergi alanlari, `SalesPriceListNo`, odeme/adres/grup/bolge/temsilci alanlari, `IsClosed`, `IsLocked`, e-fatura/e-irsaliye alanlari, iletisim alanlari, `RetailCustomer`
- `MikroDocumentFieldCatalogDto`: `Sections[]`; her section icinde `Code`, `Title`, `Endpoint`, `RequestModel`, `Fields[]`; her field icinde `ApiField`, `DisplayName`, `Scope`, `ValueType`, `MikroTable`, `MikroColumn`, `Editable`, `Description`
- `StockMovementDocumentLookupHttpRequest`: `DocumentSerie`, `DocumentOrderNo`, `DocumentType`, `MovementType`, `MovementKind`, `NormalReturn`, `WarehouseNo`
- `UpdateStockMovementDocumentHttpRequest`: `Lookup`, `Header`, `Lines`
- `StockMovementHeaderPatchHttpRequest`: `MovementDate`, `DocumentDate`, `GoodsAcceptanceDate`, `DocumentNo`, `CustomerCode`, `InputWarehouseNo`, `OutputWarehouseNo`, `Description`, `MovementGroupCode1`, `MovementGroupCode2`, `MovementGroupCode3`, `CustomerResponsibilityCenter`, `StockResponsibilityCenter`, `ProjectCode`
- `StockMovementLinePatchHttpRequest`: `MovementGuid`, `RowNo`, `GoodsAcceptanceDate`, `StockCode`, `UnitPointer`, `Quantity`, `SecondaryQuantity`, `Amount`, `Discount1..Discount6`, `Expense1..Expense4`, `ExpenseTaxPointer`, `ExpenseTaxAmount`, `TaxPointer`, `TaxAmount`, `NetWeight`, `GrossWeight`, `Description`, `Special1`, `Special2`, `Special3`, `PartyCode`, `LotNo`, `ProjectCode`, `CustomerResponsibilityCenter`, `StockResponsibilityCenter`, `InputWarehouseNo`, `OutputWarehouseNo`
- `InventoryCountDocumentLookupHttpRequest`: `WarehouseNo`, `DocumentNo`, `DocumentDate`
- `UpdateInventoryCountDocumentHttpRequest`: `Lookup`, `Header`, `Lines`
- `InventoryCountHeaderPatchHttpRequest`: `DocumentDate`, `WarehouseNo`, `Name`
- `InventoryCountLinePatchHttpRequest`: `CountGuid`, `RowNo`, `StockCode`, `Barcode`, `UnitPointer`, `Quantity1`, `Quantity2`, `Quantity3`, `Quantity4`, `Quantity5`, `RayonCode`, `CorridorCode`, `ShelfCode`, `PartyCode`, `LotNo`, `SerialNo`, `Special1`, `Special2`, `Special3`
- `CustomerMovementDocumentLookupHttpRequest`: `DocumentSerie`, `DocumentOrderNo`, `DocumentType`, `MovementType`, `MovementKind`, `NormalReturn`, `CustomerCode`
- `UpdateCustomerMovementDocumentHttpRequest`: `Lookup`, `Header`, `Lines`
- `CustomerMovementHeaderPatchHttpRequest`: `MovementDate`, `DocumentDate`, `DocumentNo`, `CustomerCode`, `TurnoverCustomerCode`, `Description`, `SellerCode`, `ProjectCode`, `ResponsibilityCenter`
- `CustomerMovementLinePatchHttpRequest`: `MovementGuid`, `RowNo`, `CustomerCode`, `TurnoverCustomerCode`, `Quantity`, `Amount`, `SubAmount`, `DueDay`, `Discount1..Discount6`, `Expense1..Expense4`, `Tax1..Tax5`, `Description`, `Special1`, `Special2`, `Special3`, `SellerCode`, `ProjectCode`, `ResponsibilityCenter`
- `CompanyOrderDocumentLookupHttpRequest`: `DocumentSerie`, `DocumentOrderNo`, `OrderType`, `OrderKind`, `WarehouseNo`, `CustomerCode`, `HardDelete`
- `UpdateCompanyOrderDocumentHttpRequest`: `Lookup`, `Header`, `Lines`
- `CompanyOrderHeaderPatchHttpRequest`: `OrderDate`, `DeliveryDate`, `DocumentDate`, `DocumentNo`, `CustomerCode`, `WarehouseNo`, `SellerCode`, `Description1`, `Description2`, `DeliveryType`, `AddressNo`, `CurrencyType`, `CurrencyRate`, `AlternativeCurrencyRate`, `CanBeCalled`, `IsClosed`, `CloseReasonCode`, `ProjectCode`, `CustomerResponsibilityCenter`, `StockResponsibilityCenter`
- `CompanyOrderLinePatchHttpRequest`: `OrderGuid`, `RowNo`, `DeliveryDate`, `StockCode`, `UnitPointer`, `Quantity`, `DeliveredQuantity`, `UnitPrice`, `Amount`, `PriceListNo`, `ValidUntil`, `ReservedQuantity`, `DeliveredFromReservation`, `Discount1..Discount6`, `Expense1..Expense4`, `TaxPointer`, `TaxAmount`, `Description1`, `Description2`, `Special1`, `Special2`, `Special3`, `PackageCode`, `PartyCode`, `LotNo`, `ProjectCode`, `CustomerResponsibilityCenter`, `StockResponsibilityCenter`, `CanBeCalled`, `IsClosed`, `CloseReasonCode`
- `WarehouseOrderDocumentLookupHttpRequest`: `DocumentSerie`, `DocumentOrderNo`, `WarehouseNo`, `InWarehouseNo`, `OutWarehouseNo`, `HardDelete`
- `UpdateWarehouseOrderDocumentHttpRequest`: `Lookup`, `Header`, `Lines`
- `WarehouseOrderHeaderPatchHttpRequest`: `OrderDate`, `DeliveryDate`, `DocumentDate`, `DocumentNo`, `InWarehouseNo`, `OutWarehouseNo`, `Description`, `IsClosed`, `CloseReasonCode`, `ProjectCode`, `ResponsibilityCenter`
- `WarehouseOrderLinePatchHttpRequest`: `OrderGuid`, `RowNo`, `DeliveryDate`, `StockCode`, `UnitPointer`, `Quantity`, `DeliveredQuantity`, `UnitPrice`, `Amount`, `Description`, `PriceListNo`, `ValidUntil`, `ReservedQuantity`, `DeliveredFromReservation`, `Special1`, `Special2`, `Special3`, `InWarehouseNo`, `OutWarehouseNo`, `IsClosed`, `CloseReasonCode`, `PackageCode`, `ProjectCode`, `ResponsibilityCenter`

### Ayar Request Modelleri

- `CreateDeviceHttpRequest`: `BranchNo`, `DeviceTypeId`, `IpAddress`, `Description`
- `CreateBranchSettingsHttpRequest`: `BranchNo`, `BranchIpAddress`, `BranchScalesFolderPath`, `ScalesType` (`0=CAS 16`, `1=CAS 500`), `PoskonFolderPath`, `PosGenelFolderPath`, `CashRegisters`
- `UpdateBranchSettingsHttpRequest`: `BranchIpAddress`, `BranchScalesFolderPath`, `ScalesType` (`0=CAS 16`, `1=CAS 500`), `PoskonFolderPath`, `PosGenelFolderPath`
- `CreateCashRegistryHttpRequest`: `CashNo`, `CashType`
- `CreateCashRegisterHttpRequest`: `BranchNo`, `CashNo`, `CashType`, `Terminals`
- `CreateCashRegisterTerminalHttpRequest`: `TerminalNo`, `Bank`, `TerminalId`, `MerchantNo`. `Bank` UI tarafinda `kasa-pos-terminalleri/secenekler` response'undaki `terminalBanks[].paymentName` degerinden secilmelidir; gorunen etiket icin `displayName` kullanilir.
- `CreateCashierHttpRequest`: `CashierName`, `CashierAuthorization`
- `UpdateCashierHttpRequest`: `CashierName`, `CashierAuthorization`, `CashierState`
- `DespatchDriverListHttpRequest`: `Search`, `IncludeInactive`, `Take`
- `SaveDespatchDriverHttpRequest`: `FirstName`, `LastName`, `PlateNumber`, `Tckn`, `IsActive`, `Notes`

### Kasa Request Modelleri

- `CashSummaryDateHttpRequest`: `DateToGet`, `WarehouseNo`
- `WarehouseOrderDateRangeHttpRequest`: `WarehouseNo`, `StartDate`, `EndDate`
- `CashTurnoverDetailHttpRequest`: `WarehouseNo`, `BusinessDate`, `ShiftNo`, `CashierCode`
- `YeniKasaAnalizHttpRequest`: `WarehouseNo`, `StartDate`, `EndDate`, `CashRegisterNo`, `CashierCode`, `Take`, `OnlyProblematic`
- `YeniKasaFisDetayHttpRequest`: `Uuid` veya `BusinessDate`, `WarehouseNo`, `CashRegisterNo`, `ReceiptNumber`
- `CashierPairHttpRequest`: `CashierCode`, `ManagerCode`
- `CashRegistryHttpRequest`: `BranchNo`
- `CashRegisterLookupHttpRequest`: `CashNo`, `CashRegisterNo`
- `CashierSearchHttpRequest`: `FilterString`
- `BankPaymentTypeHttpRequest`: `CashRegisterNo`
- `ZReportValueHttpRequest`: `WarehouseNo`, `DocumentSerie` (opsiyonel), `ZReportNo`, `CashNo`
- `CreateBanknoteTrackHttpRequest`: `WarehouseNo`, `BanknoteTrackDate`, `TotalAmount`, `DeliveryTotalAmount`, `Deliverer`, `Receiver`
- `CreateCashSummaryHttpRequest`: `WarehouseNo`, `CashNo`, `ZReportNo`, `CashierNo`, `ManagerNo`, `ZTotalValue`, `Total`, `SummaryDate`, `GiftCheckMovements`, `BanknoteMovements`, `PaymentTypes`, `StoreExpenses`
- `CreateGiftCheckMovementHttpRequest`: `GiftCheckType`, `Quantity`, `Total`, `Value`
- `CreateBanknoteMovementHttpRequest`: `BanknoteType`, `Quantity`, `Total`, `Value`
- `CreatePaymentTypeHttpRequest`: `PaymentName`, `PaymentTypeNo`, `AccountCode`, `TerminalId`, `SlipNumber`, `AmountValue`
- `CreateStoreExpenseHttpRequest`: `StoreExpensesType`, `Description`, `AmountValue`
- `UpdateCashSummaryDetailsHttpRequest`: `WarehouseNo`, `Details`
- `UpdateCashSummaryDetailLineHttpRequest`: `TypeName`, `PaymentTypeId`, `AccountCode`, `SlipNumber`, `Amount`, `TerminalId`, `Description`
- `UpdateCashSummaryBanknotesHttpRequest`: `WarehouseNo`, `BanknoteMovements`
- `UpdateCashSummaryBanknoteLineHttpRequest`: `Value`, `BanknoteType`, `Quantity`, `Total`
- `UpdateCashSummaryGiftChecksHttpRequest`: `WarehouseNo`, `GiftCheckMovements`
- `UpdateCashSummaryGiftCheckLineHttpRequest`: `GiftCheckType`, `Quantity`, `Total`, `Value`
- `KasaCiroImportHttpRequest`: `StartDate`, `EndDate`, `Branches`, `MovementRootPath`, `DryRun`
- `KasaHareketImportHttpRequest`: `StartDate`, `EndDate`, `Branches`, `CashRegisters`, `FileRootPath`, `SkipExisting`, `DryRun`
- `KasaHareketScheduledImportHttpRequest`: `Date`, `AddDay`, `FileRootPath`, `SkipExisting`, `DryRun`
- `KasaHareketDeleteStagingHttpRequest`: `Date`, `BranchNo`, `CashRegisterNo`
- `KasaHareketMikroTransferHttpRequest`: `Date`, `BranchNo`
- `KasaHareketMikroTransferRangeHttpRequest`: `StartDate`, `EndDate`
- `KasaHareketReportHttpRequest`: `Date`, `BranchNo`, `CashRegisterNo`

### Fatura Request Modelleri

- `InvoiceSendingListHttpRequest`: `StartDate`, `EndDate`, `Scenario`, `SentState`, `IsSent`
- `InvoiceSendingRenderHttpRequest`: `Scenario`, `Profile`, `PreferEmbeddedXslt`, `FallbackToDefaultXslt` (JSON body'de `fallbackToGeneral` olarak gonderilir)
- `InvoiceSendingBatchHttpRequest`: `Scenario`, `Documents[]`
- `InvoiceSendingBatchDocumentHttpRequest`: `DocumentSerie`, `DocumentOrderNo`
- `InvoiceViewingListHttpRequest`: `StartDate`, `EndDate`, `ProcessedState`, `IsProcessed`, `PrintedState`, `IsPrinted`, `SearchField`, `SearchText`, `InvoiceId`, `InvoiceNo`, `DespatchId`, `DespatchNo`, `CustomerTitle`, `CustomerTcknVkn`, `TcknVkn`, `DocumentId`, `Ettn`, `OrderDocumentId`, `Status`, `InvoiceType`, `MinInvoiceTotal`, `MaxInvoiceTotal`, `HasDespatchId`, `PageNumber`, `Page`, `PageSize`
- `InvoiceViewingSynchronizationHttpRequest`: `StartDate`, `EndDate`, `IncludeStatuses`
- `InvoiceViewingSynchronizationProgressResponse`: `IsRunning`, `Status`, `StartDate`, `EndDate`, `IncludeStatuses`, `QueryStartDate`, `QueryEndDate`, `PageIndex`, `PageNumber`, `PageSize`, `TotalCount`, `TotalPage`, `FetchedCount`, `MatchedCount`, `SkippedInvoiceDateOutOfRangeCount`, `SkippedDuplicateDocumentCount`, `InsertedCount`, `UpdatedCount`, `LastPageItemCount`, `LastPageMatchedCount`, `LastPageSkippedInvoiceDateOutOfRangeCount`, `LastPageSkippedDuplicateDocumentCount`, `LastPageInsertedCount`, `LastPageUpdatedCount`, `ProgressPercent`, `StartedAtUtc`, `LastUpdatedAtUtc`, `FinishedAtUtc`, `ElapsedMs`, `Message`, `AutomaticSynchronizationEnabled`, `SchedulerLastCheckedAtUtc`, `SchedulerLastCheckedLocal`, `SchedulerStatus`, `SchedulerMessage`, `SchedulerCurrentSlot`, `SchedulerNextSlot`, `SchedulerLastQueuedSlot`, `SchedulerLastQueuedAtUtc`, `SchedulerLastSkippedSlot`, `SchedulerLastSkippedAtUtc`, `SchedulerLastMissedSlot`, `SchedulerLastMissedAtUtc`
- `InvoiceViewingRenderHttpRequest`: `Profile`, `PreferEmbeddedXslt`, `FallbackToDefaultXslt` (JSON body'de `fallbackToGeneral` olarak gonderilir)
- `InvoiceViewingPrintedStateHttpRequest`: `IsPrinted`, `Source`
- `InvoicePreviewHttpRequest`: `InvoiceId`, `XmlContent`, `Profile`, `PreferEmbeddedXslt`
- `GET /api/fatura-islemleri/fatura-gonderimi` endpoint'i body almaz; query'de `StartDate`, `EndDate`, `Scenario` ve `isSent/SentState` kullanir
- `GET /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}` endpoint'i body almaz; `scenario` query parametresi kullanir
- `GET /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/pdf` endpoint'i body almaz; gonderilmis giden faturayi Uyumsoft outbox'tan PDF olarak alir ve `scenario` query parametresini kullanir
- `POST /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/render` endpoint'i body'de `InvoiceSendingRenderHttpRequest` alir
- `POST /api/fatura-islemleri/fatura-gonderimi/send` endpoint'i body'de `InvoiceSendingBatchHttpRequest` alir
- `POST /api/fatura-islemleri/fatura-goruntuleme/senkronize` endpoint'i body'de `InvoiceViewingSynchronizationHttpRequest` alir
- `GET /api/fatura-islemleri/fatura-goruntuleme/senkronize/progress` endpoint'i body almaz; son/aktif senkronizasyon durumunu doner
- `GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}` ve `/pdf` endpointleri body almaz; `documentId` path parametresiyle Uyumsoft `GetInboxInvoicePdf` cagirir
- `GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}/detail` endpoint'i body almaz; HTML detay icin `documentId` path parametresi kullanir
- `POST /api/fatura-islemleri/fatura-goruntuleme/{documentId}/render` endpoint'i body'de `InvoiceViewingRenderHttpRequest` alir
- `PATCH /api/fatura-islemleri/fatura-goruntuleme/{documentId}/printed` endpoint'i body'de `InvoiceViewingPrintedStateHttpRequest` alir

### Operasyon Request Modelleri

- `SaveAuthorizationFileHttpRequest`: `Id`, `UpdateDate`, `Name`, `Z`, `R`, `X`
- `GET /api/operations/scalesfile`, `productbarcodeplunofile`, `productbarcodeplonofile`, `cashierfile`, `promofile`, `customerfile` ve `einvoicevnofile` endpointleri body almaz; opsiyonel `warehouseNo` query parametresi yalniz `operasyon-islemleri.operations.all-warehouses` yetkili depo secimi icindir.
- `POST /api/operations/saveauthorizationfile` ve `POST /api/operations/authorization-files` body modeli tek obje degil, `IReadOnlyCollection<SaveAuthorizationFileHttpRequest>` dizisidir.
- `DocumentFlowListHttpRequest`: `WarehouseNo`, `StartDate`, `EndDate`, `DocumentType`, `Status`, `Search`, `Take`
- `GET /api/operasyon-islemleri/belge-akis-takibi` body almaz; filtreleri query parametresi olarak alir.
- `GET /api/operasyon-islemleri/belge-akis-takibi/{id}` body almaz; `id` belge akis kaydinin `Guid` degeridir.

### Entegrasyon Request Modelleri

- `UyumsoftOperationHttpRequest`: `Parameters`
- `UyumsoftOperationParameterHttpRequest`: `Name`, `Value`
- `AxataSynchronizationExecuteHttpRequest`: `TaskCode`, `ExecutionMode`, `WarehouseNo`
- `AxataSynchronizationExecuteTaskHttpRequest`: `ExecutionMode`, `WarehouseNo`
- `AxataSynchronizationManualDocumentCandidatesHttpRequest`: `WarehouseNo`, `StartDate`, `EndDate`, `Skip`, `Take`
- `AxataIntegrationAuditHttpRequest`: `StartDate`, `EndDate`, `WarehouseNo`, `Take`, `DocumentSerie`, `DocumentOrderNo`
- `AxataOutboundDeliveryQueuePreviewHttpRequest`: `MovementType`, `Take`
- `AxataOutboundDeliveriesByDateHttpRequest`: `Date`
- `AxataOutboundDeliveryImportPreviewHttpRequest`: `Take`
- `AxataOutboundDeliveryImportExecuteHttpRequest`: `Take`, `ContinueOnError`, `Acknowledge`
- `AxataOutboundDeliveryDocumentImportExecuteHttpRequest`: `Status`, `Acknowledge`
- `AxataSynchronizationManualDocumentHttpRequest`: `WarehouseNo`, `DocumentSerie`, `DocumentOrderNo`, `DocumentNo`, `DocumentDate`
- `AxataSynchronizationManualDocumentExecuteHttpRequest`: `WarehouseNo`, `DocumentSerie`, `DocumentOrderNo`, `DocumentNo`, `DocumentDate`, `ExecutionMode`
- `AxataSynchronizationManualDocumentItemHttpRequest`: `DocumentSerie`, `DocumentOrderNo`, `DocumentNo`, `DocumentDate`
- `AxataSynchronizationManualDocumentBatchHttpRequest`: `WarehouseNo`, `ContinueOnError`, `Documents`
- `AxataSynchronizationManualDocumentBatchExecuteHttpRequest`: `WarehouseNo`, `ContinueOnError`, `Documents`, `ExecutionMode`
- `AxataOutboundDeliveryHttpRequest`: `SourceWarehouseNo`, `TargetWarehouseNo`, `TransitWarehouseNo`, `MovementDate`, `DocumentDate`, `DocumentNo`, `AxataDeliveryNo`, `MovementCode`, `Description`, `Lines`
- `AxataOutboundDeliveryLineHttpRequest`: `LineNo`, `StockCode`, `Quantity`, `UnitPrice`, `UnitPointer`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`, `CustomerResponsibilityCenter`, `ProductResponsibilityCenter`
- `AxataOutboundDeliveryBatchHttpRequest`: `ContinueOnError`, `Items`
- `AxataInboundAtfCompanyReceivingHttpRequest`: `WarehouseNo`, `CustomerCode`, `MovementDate`, `DocumentDate`, `DocumentNo`, `AxataOrderNo`, `InvoiceNo`, `Deliverer`, `Receiver`, `Description`, `AllowOrderOverReceiving`, `Lines`
- `AxataInboundAtfCompanyReceivingLineHttpRequest`: `LineNo`, `StockCode`, `Quantity`, `UnitPrice`, `UnitPointer`, `LastConsumingDate`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`, `CustomerResponsibilityCenter`, `ProductResponsibilityCenter`
- `AxataInboundAtfCompanyReceivingBatchHttpRequest`: `ContinueOnError`, `Items`
- `AxataManualIncomingCompanyReceivingBatchHttpRequest`: `ContinueOnError`, `Items`
- `AxataManualIncomingInventoryCountBatchHttpRequest`: `ContinueOnError`, `Items`
- `AxataManualIncomingWarehouseReceivingBatchHttpRequest`: `ContinueOnError`, `Items`
- `AxataManualIncomingWarehouseReceivingBatchItemHttpRequest`: `DocumentSerie`, `DocumentOrderNo`, `AllowDiscrepancy`, `Lines`
- `PosAccountingDateRangeHttpRequest`: `StartDate`, `EndDate`, `WarehouseNo`, `OnlyPending`
- `ImportZReportsHttpRequest`: `WarehouseNo`, `BusinessDate`, `ReportPath`, `ImportMode`, `SourceCode`, `OverwriteExisting`
- `ImportPosDocumentsHttpRequest`: `WarehouseNo`, `BusinessDate`, `DateToGet`, `IncludePreviouslyImported`, `OverwriteExisting`
- `PosAccountingTransferHttpRequest`: `WarehouseNo`, `DocumentIds`, `TotalIds`, `InvoiceIds`, `ExpenseIds`, `ContinueOnError`
- `PosAccountingDeleteHttpRequest`: `WarehouseNo`, `DocumentIds`, `TotalIds`, `InvoiceIds`, `ExpenseIds`
- `UpdatePosAccountingDocumentHttpRequest`: `DocumentNo`, `CustomerTaxNo`, `PaymentType`, `BranchNo`, `Description`
- `CashRegisterBranchMappingListHttpRequest`: `BranchNo`, `CashRegisterNo`
- `CashRegisterBranchMappingHttpRequest`: `CashRegisterNo`, `BranchNo`, `BranchName`, `Description`
- `GET /api/integrations/axata-sync/tasks/{taskCode}/preview` endpoint'i body almaz; `warehouseNo` ve `take` query parametresi kullanir
- `GET /api/integrations/axata-sync/manual/tasks/{taskCode}/documents/candidates` endpoint'i body almaz; `warehouseNo`, `startDate`, `endDate`, `skip`, `take` query parametresi kullanir
- `issued-warehouse-order-sync` task'inda `warehouseNo` hedef depo degil AXATA kaynak/cikis depodur; Mikro filtre `ssip_cikdepo = warehouseNo` olur
- `warehouse-inbound-order-sync` task'inda `warehouseNo` AXATA hedef/giris depodur; Mikro filtre `ssip_girdepo = warehouseNo` olur
- `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/preview` endpoint'i body almaz; query'de `movementType` ve `take` kullanir; `movementType` bos ise `C01` kabul edilir, `C04` alias'i `C4` olarak sorgulanir
- `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/by-date` endpoint'i body almaz; query'de zorunlu `date` kullanir. Ornek: `date=2026-06-19`. Backend bu tarihi `yyyyMMdd` sayisal AXATA tarihine cevirip `ENT006.S06ITAR` alaninda filtreler
- `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/{documentSerie}/{documentOrderNo}/preview` endpoint'i body almaz; `status` query parametresi opsiyoneldir ve sadece `0` veya `1` olabilir
- `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/{documentSerie}/{documentOrderNo}/import` body'de `status` ve `acknowledge` alir; `acknowledge=false` kontrollu rescue icin onerilir
- `GET /api/integrations/axata-sync/live/axata/inbound-deliveries/g02/documents/{documentSerie}/{documentOrderNo}/preview` endpoint'i body almaz; `status` query parametresi opsiyoneldir ve sadece `0` veya `1` olabilir
- `POST /api/integrations/axata-sync/live/axata/inbound-deliveries/g02/documents/{documentSerie}/{documentOrderNo}/import` body'de `status` ve `acknowledge` alir; `acknowledge=false` kontrollu rescue icin onerilir
- `ExecutionMode` su an yalnizca `DryRun` veya `Outbox` olabilir
- `dispatch` ve `dispatch-batch` endpoint'leri `ExecutionMode` almaz; bunlar dogrudan canli AXATA WCF gonderimidir
- `issued-warehouse-order-sync` dispatch payload'i worker parity icin `C01`, `company-receiving-sync` dispatch payload'i verilen firma/satinalma siparisinden uretilip `G01` hareket kodu ile gonderilir
  - `warehouse-inbound-order-sync` dispatch payload'i worker parity icin `G02` hareket kodu ile `addInboundOrder*` operasyonuna gider
- `manual/tasks/{taskCode}/documents/preview` ve `manual/tasks/{taskCode}/documents/execute` request body alanlari task'a gore kullanilir:
  - `issued-warehouse-order-sync`: `DocumentSerie` + `DocumentOrderNo`
  - `warehouse-inbound-order-sync`: `DocumentSerie` + `DocumentOrderNo`
  - `company-receiving-sync`: `DocumentSerie` + `DocumentOrderNo`
  - `inventory-count-sync`: `DocumentNo` + `DocumentDate`
- `manual/tasks/{taskCode}/documents/preview-batch` ve `manual/tasks/{taskCode}/documents/execute-batch` endpoint'lerinde ayni alanlar `Documents[]` icinde gonderilir
- `manual/tasks/{taskCode}/documents/dispatch` ve `manual/tasks/{taskCode}/documents/dispatch-batch` endpoint'lerinde tekli/toplu belge secimi preview ile ayni kurali kullanir
- `GET /api/integrations/axata-sync/manual/incoming/warehouse-receivings` endpoint'i `WarehouseOrderDateRangeHttpRequest` query alanlarini kullanir
- toplu incoming endpoint'lerde `Items[]` elemanlari tekli create/accept endpoint body'leriyle ayni alanlari tasir
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari`, `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar` ve `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari` endpoint'leri query'de `PosAccountingDateRangeHttpRequest` kullanir
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/ice-aktar` body'de `ImportZReportsHttpRequest` alir
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/ice-aktar` ve `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/ice-aktar` body'de `ImportPosDocumentsHttpRequest` alir
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/*/erpye-gonder` ve `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/*` endpoint'leri secili belge listesi bekler; belge tipine gore `TotalIds[]`, `InvoiceIds[]` veya `ExpenseIds[]` tercih edilir, geriye uyumluluk icin `DocumentIds[]` int koleksiyonu da kabul edilir
- `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/{invoiceId}` ve `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/{expenseId}` body'de `UpdatePosAccountingDocumentHttpRequest` alir
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri` query'de `CashRegisterBranchMappingListHttpRequest` kullanir
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri` ve `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri/{mappingId}` body'de `CashRegisterBranchMappingHttpRequest` alir

### Ozel Request Notlari

- `CreateCompanyReceivingHttpRequest.DocumentNo` opsiyoneldir. Tam `seri + 9 haneli sayisal sira` gelirse aynen kullanilir; bos veya sadece sayisal gelirse backend cari unvanindan seri uretir; tam format olmayan ve harf iceren `ABC` gibi deger gelirse prefix kabul edilip siradaki sira uretilir. Ornek tam no: `ST12026000002395` -> `documentSerie = ST12026`, `documentOrderNo = 2395`
- Firma mal kabulde yeni UI `dispatchQuantity` ve `acceptedQuantity` alanlarini ayri kullanmalidir. `quantity` sadece eski uyumluluk alanidir ve tek basina gonderilirse hem sevk/irsaliye hem fiili kabul miktari gibi yorumlanir.
- `CreateCompanyReceivingLineHttpRequest.AcceptedQuantity`, `DispatchQuantity` degerinden buyuk olamaz. Eksik kabulde fark kadar firma iadesi `AutoCreateReturnForPartialAcceptance = true` ise otomatik olusur.
- Otomatik olusan firma iadesi icin e-irsaliye gonderimi otomatik degildir; UI response'taki `autoCreatedReturnDocumentSerie`, `autoCreatedReturnDocumentOrderNo` ve `returnEDespatchStatus` alanlariyla iade linki/statusu gosterir.
- `AxataInboundAtfCompanyReceivingHttpRequest` icin `DocumentNo`, `InvoiceNo` veya `AxataOrderNo` tam formatta ise aynen kullanilir; tam format degilse seri/prefix gibi degerlendirilir; hepsi bos ise backend cari unvanindan seri/sira uretir.
- `AxataInboundAtfCompanyReceivingLineHttpRequest` icinde yalnizca `Quantity` vardir; bu endpoint native ATF miktarini tam kabul sayar. Kismi kabul/iade gerekiyorsa `manual/incoming/company-receivings` endpoint'ine `dispatchQuantity` ve `acceptedQuantity` ayrimiyla payload gonderilmelidir.
- E-irsaliye olusturan endpointler body'de `SendEDespatchHttpRequest`, path'te `documentSerie` ve `documentOrderNo`, query'de opsiyonel `warehouseNo` alir.
- `POST /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/{operationName}` ve `POST /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/get/{operationName}` endpoint'leri body'de `UyumsoftOperationHttpRequest` alir.
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/{operationName}` ve `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/get/{operationName}` endpoint'leri body almaz; tekrar eden `parameter=name=value` query parametresi kullanir.
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/system/date/formatted` endpoint'i `format` query parametresi alir.
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/.../{invoiceUuid}` alias route'lari `invoiceUuid` path parametresiyle calisir.
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/.../{despatchId}` alias route'lari `despatchId` path parametresiyle calisir; `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/despatches/{despatchId}/envelope` icin ek olarak `isInbox` query parametresi zorunludur.
- Cok sayida detay endpointi ayri request class'i kullanmaz; path parametreleri ve opsiyonel `warehouseNo` query parametresi ile calisir.
- `GET /api/kasa-islemleri/etiket-belgeleri`, `GET /api/kasa-islemleri/etiket-belgeleri/son`, `GET /api/kasa-islemleri/etiket-belgeleri/tumu` ve `GET /api/kasa-islemleri/etiket-belgeleri/{documentId}` endpointleri ayri request class'i yerine dogrudan action parametreleri kullanir.
- `LabelPriceChangedProductListHttpRequest.DateTimeFilter` alaninin beklenen formati `dd.MM.yyyy HH:mm:ss` degeridir.





