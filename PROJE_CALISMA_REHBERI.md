# Proje Calisma Rehberi

Bu belge `Furpa Merkez Terminal` projesine yeni giren bir gelistiricinin
projeyi hizli anlamasi, dogru dosyadan baslamasi ve mevcut mimariyi bozmadan
degisiklik yapmasi icin hazirlanmistir.

Guncel durum:

- Son guncelleme: 2026-08-03
- Flutter uygulamasi: Furpa merkez el terminali / PDA arayuzu
- Guncel paket versiyonu: `1.1.37+38`
- Guncel test durumu: `flutter analyze` temiz, `flutter test` 93/93 basarili
- Ana tasarim hedefi: eski kullanici aliskanligini bozmadan hata yapmayi zorlastirmak

## 0. Hizli Yon Bulma

Projeye ilk kez giriyorsan dosyalari su sirayla oku:

1. Uygulama nasil ayaga kalkiyor?
   - `lib/main.dart`
   - `lib/app/bootstrap.dart`
   - `lib/app/app.dart`
2. Repository ve servisler nerede kuruluyor?
   - `lib/app/dependencies.dart`
3. Menu hangi ekrani aciyor?
   - `lib/features/shell/presentation/routing/shell_module_registry.dart`
   - `lib/features/shell/presentation/views/home_shell_page.dart`
4. Oturum, token ve yetki nerede?
   - `lib/features/shell/presentation/view_models/app_session_controller.dart`
   - `lib/features/auth/data/auth_repository.dart`
   - `lib/features/shell/domain/menu_entry.dart`
5. Tum HTTP istekleri nereden geciyor?
   - `lib/core/network/api_client.dart`
6. Barkod ve urun giris mantigi nerede?
   - `lib/shared/product_entry/product_entry_widgets.dart`
   - `lib/shared/product_entry/product_entry_controller.dart`
   - `lib/shared/data/barcode_resolution_repository.dart`
7. PDA ortak UI parcalari nerede?
   - `lib/shared/widgets/terminal_ui_parts.dart`
   - `lib/shared/widgets/terminal_create_page.dart`
   - `lib/shared/utils/terminal_feedback.dart`
8. Offline ve mobil katalog mantigi nerede?
   - `lib/shared/offline/offline_sync_service.dart`
   - `lib/core/storage/local_database.dart`
   - `lib/core/storage/local_sqlite_database.dart`
   - `lib/shared/offline/mobile_product_catalog_repository.dart`
   - `lib/shared/offline/mobile_customer_catalog_repository.dart`
   - `lib/shared/offline/mobile_warehouse_catalog_repository.dart`

Kisa klasor haritasi:

```text
lib/app/       -> uygulama kabugu, tema, dependency kurulum
lib/core/      -> network, config, update, storage, teknik altyapi
lib/features/  -> is modulleri, ekranlar, repository, controller
lib/shared/    -> ortak widget, formatter, offline, draft, barkod parcalari
test/          -> controller, widget, repository ve kritik akis testleri
```

Bir dosyayi degistirmeden once sunu sor:

> Bu degisiklik sadece tek feature'i mi etkiliyor, yoksa shared/core/app seviyesinde tum ekranlara mi yayiliyor?

`app/`, `core/` ve `shared/` altindaki degisiklikler genelde daha buyuk etki
alanina sahiptir. Bu dosyalarda mutlaka test calistir.

## 1. Proje Ne Yapiyor?

Bu proje Flutter ile yazilmis merkez el terminali uygulamasidir. Kullanici PDA
veya terminal cihazindan stok, siparis, sevk, iade, mal kabul, sayim, virman,
etiket ve yardimci arac islemlerini yapar.

Ana kullanim mantigi:

1. Kullanici login olur.
2. Backend kullanicinin menu ve yetkilerini dondurur.
3. Uygulama gelen menuye gore sadece yetkili ekranlari gosterir.
4. Kullanici liste/detail/create akislarini kullanir.
5. Create ekranlarinda barkod okutma ana akis olarak korunur.
6. Bazi islemler online API'ye gider.
7. Offline destekli islemler network yoksa local draft/kuyruk olarak saklanir.
8. Uygulama online oldugunda bekleyen offline islemleri senkronize eder.

Bu proje statik menulu bir uygulama degildir. Menu, yetki ve bazi davranislar
backend datasina gore sekillenir.

## 2. API Dokumani ile Iliski

Backend/API kontrati icin ana referans:

- `Yeni_UI_API_DOKUMANI.md`

Bu dosya cok genis bir API katalogudur. Proje gelistirirken su ayrim onemlidir:

- API dokumaninda endpoint olmasi, UI tarafinda mutlaka yeni ekran acilacak
  anlamina gelmez.
- UI ekran karari kullanici ihtiyaci, mevcut menu yapisi ve saha akisina gore
  verilir.
- Var olan ekrana entegre edilebilecek bir is icin yeni sayfa acilmaz.
- Yeni route/menu eklemek gerekiyorsa once `ShellModuleRegistry`, permission
  modeli ve kullanici akisina bakilir.

Ozellikle not:

- `Etiket Basim` API dokumaninda gecse bile bu projede su an ayri yeni ekran
  olarak eklenmeyecek bir is olarak kabul edilir.
- Manav kasa / GreenGrocer kasa cozumleme de ayri ekran olarak degil, mevcut
  verilen depo siparisi ve giden depo sevk akislarina entegre edilmis
  davranis olarak ele alinmalidir.

API dokumani guncellendiginde uygulama tarafinda sirayla su kontrol yapilir:

1. Degisen kisim bizim aktif ekrani etkiliyor mu?
2. Yeni alan request/response modeline girmeli mi?
3. Offline draft veya sync zinciri etkileniyor mu?
4. Permission/menu gorunurlugu degisiyor mu?
5. Mevcut PDA create akisi bozulmadan entegre edilebilir mi?
6. Test eklemek veya mevcut testi guncellemek gerekiyor mu?

## 3. Uygulama Acilis Akisi

Acilis zinciri:

```text
main.dart
  -> bootstrap.dart
    -> AppDependencies.create()
      -> FurpaMerkezApp
        -> HomeShellPage veya LoginPage
```

### `main.dart`

Sadece `bootstrap()` cagirir.

### `bootstrap.dart`

- Flutter binding'i ayaga kaldirir.
- `AppDependencies.create()` ile repository ve servisleri olusturur.
- `FurpaMerkezApp` widget'ini baslatir.
- Arka planda `sessionController.restoreSession()` ile kayitli oturumu geri
  yuklemeye calisir.

### `app.dart`

Uygulama route mantigi session status uzerinden ilerler:

```text
booting          -> SplashPage
unauthenticated  -> LoginPage
authenticated    -> HomeShellPage
```

Yani ana akista klasik named route listesi degil, session durumuna gore ekran
secimi vardir.

## 4. Konfigurasyon

Ana dosya:

- `lib/core/config/app_config.dart`

Guncel onemli ayarlar:

```text
AppConfig.appName = Furpa Merkez Terminal
AppConfig.requestTimeout = 300 saniye
Varsayilan API = http://10.0.0.100:7508
Varsayilan update manifest = http://10.0.0.100:802/Terminal/version.json
```

API adresi build sirasinda override edilebilir:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.0.100:7508
flutter build apk --release --dart-define=API_BASE_URL_ANDROID=http://10.0.0.100:7508
```

Platform bazli override:

```powershell
--dart-define=API_BASE_URL_ANDROID=http://10.0.0.100:7508
--dart-define=API_BASE_URL_DESKTOP=http://localhost:7508
--dart-define=API_BASE_URL_WEB=http://10.0.0.100:7508
```

Manav kasa / GreenGrocer flag'leri:

```text
GreenGrocerProductCases__Enabled
GreenGrocerProductCases__OrderLinkingEnabled
```

Guncel default degerler `false` durumundadir. Bu ozellikler acilacaksa build
sirasinda dart-define ile verilmelidir:

```powershell
flutter run `
  --dart-define=GreenGrocerProductCases__Enabled=true `
  --dart-define=GreenGrocerProductCases__OrderLinkingEnabled=true
```

Testlerde gerekiyorsa widget seviyesinde explicit override kullanilabilir.
Ornek:

```dart
GivenWarehouseOrderCreateSheet(
  greenGrocerProductCasesEnabled: true,
  greenGrocerProductCasesRepository: fakeRepository,
  ...
)
```

## 5. Temel Mimari

Genel veri akisi:

```text
UI Page / Sheet
  -> Controller veya StatefulWidget state
    -> Repository
      -> ApiClient
        -> Backend
```

Cevap donusu:

```text
Backend
  -> model parse
    -> repository sonucu
      -> controller/state
        -> UI
```

### Model

Model dosyalari:

- JSON parse eder.
- Request body uretir.
- Backend'in farkli tiplerde donebilecegi degerlere toleransli davranir.

Yeni model yazarken dikkat:

- `DateTime.parse` yerine mumkunse `DateTime.tryParse`
- `int`, `double`, `bool` icin helper veya toleransli parse
- `null`, bos string, `0/1`, string sayi gibi durumlara dikkat
- UI/navigasyon mantigi model icine yazilmamali

### Repository

Repository dosyalari:

- Endpoint path'lerini bilir.
- Query/body olusturur.
- `ApiClient` cagrisi yapar.
- Response'u modele cevirir.

Repository icinde UI widget veya snackbar mantigi olmamali.

### Controller

Controller olan ekranlarda controller:

- listeyi yukler
- detail secimini yonetir
- stale response riskini azaltir
- create sonrasi listeyi yeniler
- loading/error/submitting state'ini tutar

Ornek controller patternleri:

- `inventory_counts_controller.dart`
- `warehouse_returns_controller.dart`
- `outgoing_warehouse_shipments_controller.dart`
- `company_movements_controller.dart`

### Page

Page:

- filtreleri ve liste layout'unu yonetir
- controller'a baglanir
- detail sayfalarini acar
- create sheet/page acislarini tetikler

### Create Sheet

Bir cok create ekrani state'i kendi icinde tasir. Bu normaldir. Ozellikle
barkod okutma, focus, draft save ve satir merge gibi islemler create sheet
icinde yonetilir.

Create sheet'lerde artik ana hedef PDA hizli islem akisini korumaktir.

## 6. Menu, Yetki ve Shell

Ana dosyalar:

- `lib/features/shell/domain/menu_entry.dart`
- `lib/features/shell/presentation/view_models/app_session_controller.dart`
- `lib/features/shell/presentation/views/home_shell_page.dart`
- `lib/features/shell/presentation/routing/shell_module_registry.dart`

### Menu gorunurlugu

Backend kullaniciya module/menu/action yapisini dondurur. Uygulama bunu
gorunur menulere cevirir.

Guncel yetki mantigi:

- Menu route gorunurlugu `page` veya `manage` aksiyonlariyla okunur.
- Permission code suffix'i olarak `.page` ve `.manage` desteklenir.
- Eski `list/detail/create` gibi route gorunurluk suffix'leri ana kural
  degildir.
- `userPermissionCodes` flat listesi varsa fallback olarak kontrol edilir.

Bu mantik `menu_entry.dart` icindeki helper'larda toplanir:

```text
visiblePermissionModules(...)
flattenVisibleMenus(...)
hasMenuRoutePermission(...)
```

Yeni menu acilmiyorsa sirayla kontrol et:

1. Backend menuyu gercekten gonderiyor mu?
2. Menu action listesi icinde `page` veya `manage` var mi?
3. Permission code `.page` veya `.manage` ile geliyor mu?
4. `ShellModuleRegistry` icinde route eslemesi var mi?
5. Page icin gerekli repository `AppDependencies` icinde veriliyor mu?

### Ekran esleme

`ShellModuleRegistry` backend menusu ile Flutter ekranini baglar.

Iki esleme tipi var:

1. Exact route key:

```text
moduleCode.menuCode
```

2. Fallback matching:

```text
menu code
keyword
title
```

Yeni ekran eklerken once exact key ile bagla. Backend menu code'u degisebilir
diye gerekiyorsa fallback keyword ekle.

## 7. Network Katmani

Ana dosya:

- `lib/core/network/api_client.dart`

`ApiClient` sorumluluklari:

- base URL normalize eder
- endpoint ile final URI olusturur
- Authorization header ekler
- timeout uygular
- JSON map/list decode eder
- backend hata response'unu `ApiException` olarak tasir

Repository'ler dogrudan `http` kullanmamalidir. Tum HTTP istekleri
`ApiClient` uzerinden gecmelidir.

Hata gosterirken teknik stack trace kullaniciya verilmemeli. `ApiException`
icinden okunabilir mesaj uretilmeli.

## 8. Offline, Draft ve Mobil Kataloglar

Ana dosyalar:

```text
lib/shared/offline/offline_sync_service.dart
lib/core/storage/local_database.dart
lib/core/storage/local_sqlite_database.dart
lib/shared/drafts/create_draft_session.dart
lib/shared/drafts/create_draft_repository.dart
lib/shared/offline/mobile_product_catalog_repository.dart
lib/shared/offline/mobile_customer_catalog_repository.dart
lib/shared/offline/mobile_warehouse_catalog_repository.dart
```

### Local storage

`LocalDatabase` ortak storage arayuzudur. Ana implementasyon:

- `LocalSqliteDatabase`

Iki veri tipi kullanilir:

```text
table    -> ayni key altinda coklu JSON row
document -> tek key altinda tek JSON document
```

Yeni offline veri yazarken dogrudan `SharedPreferences` kullanma. `LocalDatabase`
uzerinden ilerle.

### Offline create akisi

Tipik akisi:

1. Kullanici create formunu doldurur.
2. Online create denenir.
3. Network kaynakli hata varsa local draft/kuyruk yazilir.
4. `clientRequestId` korunur.
5. Sync sirasinda ayni request tekrar gonderilir.
6. Backend duplicate/recover durumunu `clientRequestId` ile cozebilir.

`clientRequestId` kaybolursa ayni evrak iki kere olusabilir. Offline destekli
formlarda bu alan kritik kabul edilir.

### Draft session

Create ekranlarinda taslak mantigi icin:

- `CreateDraftSession`
- `CreateDraftRepository`
- `CreateDraftPicker`

kullanilir.

Yeni create form alani eklenirse draft payload'a da eklenmelidir. Aksi halde
kullanici ekran kapatip actiginda alan kaybolur.

### Mobil kataloglar

API yokken arama yapabilmek icin local kataloglar kullanilir:

- urun katalogu
- cari katalogu
- depo katalogu

Kullanim ornekleri:

- urun arama: `MobileProductCatalogLocalRepository`
- cari arama: `MobileCustomerCatalogLocalRepository`
- depo arama: `MobileWarehouseCatalogLocalRepository`

Not: Local fallback'in sonuc vermesi icin katalog daha once cihaza inmis
olmalidir.

## 9. Barkod, Urun Girisi ve Cozumleme

Ana dosyalar:

```text
lib/shared/product_entry/product_entry_widgets.dart
lib/shared/product_entry/product_entry_controller.dart
lib/shared/data/barcode_resolution_repository.dart
lib/shared/data/barcode_resolution_models.dart
```

### PDA barkod akisi

Eski kullanici aliskanligi korunur:

```text
Barkod okut
  -> urun bulunur
    -> miktar belirlenir
      -> sepete/kaleme eklenir
        -> barkod alani tekrar hazir olur
```

Yeni ekranda popup sayisi azaltildi. Ana hedef:

- barkod alani her zaman hizli erisilebilir olsun
- Enter/Tab/PDA okuyucu submit yapsin
- ayni urun tekrar okutulursa mevcut satirin miktari artsin
- basarili islemde kucuk feedback verilsin
- kritik hatada satir eklenmesin

### Ortak widget'lar

`ProductLookupField`:

- barkod/stok/urun arama input'u
- focus gelince metni secer
- PDA okuyucunun Enter/Tab davranisini yakalar
- soft keyboard'u gerektiginde baskilar
- dense input tasarimi kullanir

`TerminalResponsiveLookupRow`:

- input + arama butonu + kamera butonunu PDA genisligine gore dizer
- cok dar ekranda alt alta iner
- normal terminal genisliginde yatay kalmaya calisir

`TerminalSubmitOnTab`:

- `Tab`
- `Enter`
- `NumpadEnter`

tuslarini submit olarak yakalar.

### ProductEntryController

Ortak miktar ve duplicate mantigi:

- urun kimligi: barkod varsa barkod, yoksa stok kodu
- miktar parse/format
- unit multiplier fallback
- duplicate satir bulma

Yeni create ekraninda urun ekleme/merge yapacaksan once buradaki helper'lari
kullan.

### Barkod cozumleme

`BarcodeResolutionRepository` backend tarafindan gelen net urun kararini okur.
Frontend koli barkodu, alternatif barkod veya terazi barkodu gibi ayrimlari
tahmin etmemelidir. Backend sonucu ne donduruyorsa UI onu gostermelidir.

Create ekranlarinda request gonderirken mumkunse su bilgiler verilir:

```text
barcode
warehouseNo
operationType
screenCode
targetWarehouseNo
```

## 10. PDA Create Ekran Standardi

Bu proje artik create ekranlarinda PDA mantigini ana standart kabul eder.

Genel layout:

```text
TerminalSheetHeader
  -> kisa setup / evrak bilgisi
    -> sabit giris satiri
      -> Expanded CustomScrollView
        -> dolu kalemler
        -> validasyon mesaji
        -> kaydet/vazgec aksiyonlari
```

Kural:

- Header dikeyde az yer kaplamali.
- Evrak/setup bilgisi gerekmedikce buyuk scroll bolgesi olmamali.
- Girdi satiri kaybolmamali.
- Terminal ekraninda en buyuk alan kalem listesine kalmali.
- Dolu kalemler ve alttaki kaydet alani ayni scroll alaninda olmali.
- Kalem listesi icinde ikinci bir `ListView` acilmamali.
- 200 kalem gibi limitlere yaklasma kullaniciya erken gosterilmeli.

### Bos giris satiri kurali

Bulunamayan urun veya basarisiz barkod okutma kalem sayilmamalidir.

Dogru mantik:

```text
selectedProduct yoksa ve stockCode yoksa
  -> bu satir hala giris satiridir
```

Yanlis mantik:

```text
lookup text doluysa kalem say
```

Bu yanlis mantik su sorunlara yol acar:

- urun bulunamadi ama `1 kalem` gorunur
- giris satiri asagi kayar veya kaybolur
- kaydet sirasinda "urun secin" hatasi gereksiz cikar

Bu yuzden son create duzeninde `_isBlankLine` kontrolleri lookup text'e degil,
gercek urun/stok secimine gore yapilir.

### Satir ekleme kurali

Basarili urun bulmada:

1. Urun satira uygulanir.
2. Ayni urun daha once varsa miktar mevcut satira eklenir.
3. Kullaniciya kucuk feedback verilir.
4. En ustte yeni bos giris satiri olusturulur.
5. Focus yeni giris satirina doner.

Bulunamayan urunde:

1. Satir eklenmez.
2. Kalem sayisi artmaz.
3. Hata mesaji giris satirinda kalir.
4. Focus giris satirina doner.

### Miktar artirma/azaltma

`TerminalCompactProductLineCard` ve `TerminalQuantityStepper` kullanilir.

Manav/terazi gibi ozel satirlarda miktar step'i standart `1` olmak zorunda
degildir. Ornek:

- okutulan barkod 10 KG ise
- satir miktar step'i 10 olabilir
- arti butonu 10 artirir
- tekrar okutma toplam miktari 20 KG yapar

## 11. Giden Depolar Arasi Sevk Create Notlari

Ana dosya:

- `lib/features/shipping_operations/outgoing_warehouse_shipments/presentation/widgets/outgoing_warehouse_shipment_create_sheet.dart`

Bu ekran iki modla calisir:

```text
Siparissiz -> manuel sevk
Siparisli  -> depo siparisine bagli sevk
```

Guncel layout:

- `TerminalSheetHeader` en ustte kompakt durur.
- Sevk tipi ve hedef depo kismi dikeyde az yer kaplar.
- Girdigi satir sabit ust bolgede kalir.
- Dolu kalemler `CustomScrollView` icinde `SliverList` olarak akar.
- Validasyon ve `Vazgec / Sevki Hazirla` butonlari kalemlerle ayni scroll
  alanindadir.
- Kalem listesi icinde nested `ListView` yoktur.

Bu ekran icin kritik kural:

> Kalemler ve kaydet alani ayni scroll davranisini paylasmali.

Eger tekrar ic ice scroll eklenirse PDA'da kullanici kalemlerden kaydet
butonuna gecmekte zorlanir.

### Hedef depo model uyarisi

Backend bazen su tarz uyarilar dondurebilir:

```text
Hedef depo icin model kodu yoktur.
```

Bu inter-warehouse shipment icin her zaman blok sebebi degildir. Backend
`warnings/errors/operationDecision` dondurse bile ekran operasyon tipine gore
karari yorumlar. Mevcut testlerde bu uyarinin sevki bloklamamasi korunur.

### Manav depo sevk

Manav depoda KG'li barkod okutulunca miktar okutulan barkod kilosuna gore
artmalidir.

Ornek:

```text
1. okutma -> 10 KG
2. okutma -> toplam 20 KG
arti butonu -> +10 KG
eksi butonu -> -10 KG
```

Bu davranis `quantityStep` uzerinden satira tasinir.

## 12. Verilen Depo Siparisi ve Manav Kasa

Ana dosya:

- `lib/features/order_operations/given_warehouse_orders/presentation/widgets/given_warehouse_order_create_sheet.dart`

Manav kasa ozelligi yeni bir ekran degildir. Var olan verilen depo siparisi
create akisi icinde calisir.

Akis:

```text
Karsi depo sec
  -> urun/kasa gir
    -> miktar kasa/adet olarak girilir
      -> submit oncesi GreenGrocer preview cozumlenir
        -> Mikro'ya KG/ADET miktari gider
```

Ilgili repository:

- `lib/features/green_grocer/product_cases/data/green_grocer_product_cases_repository.dart`

Flag:

- `GreenGrocerProductCases__Enabled`

Testte explicit olarak acilabilir:

```dart
greenGrocerProductCasesEnabled: true
```

## 13. Firma Mal Kabul ve Offline Mal Kabul

Ana dosyalar:

```text
lib/features/acceptance_operations/company_acceptances/presentation/widgets/company_acceptance_create_sheet.dart
lib/features/acceptance_operations/offline_company_acceptances/presentation/views/offline_company_acceptances_page.dart
```

Guncel PDA standardi:

- E-irsaliye/cari/evrak alani sinirli yukseklikte scroll edebilir.
- Bu setup alani giris satirini asagi itip kaybettirmemelidir.
- `Teslim Eden` ve `Teslim Alan` gibi alanlar uygun genislikte yan yana gelir.
- Barkod/urun girisi `ProductLookupField` standardini kullanir.
- Siparisli ve siparissiz satirlar ayni fis icinde olabilir.
- Eksik kabul farki iade aksiyonuyla baglantilidir.

E-irsaliye QR/ETTN cozme:

- `e_despatch_qr_parser.dart`
- `resolveEDespatchByEttn`

QR bulunamazsa belge bilgileri forma aktarilabilir ama kalemler manuel
girilebilir.

## 14. Stok Giris, Sayim, Iade, Virman ve Diger Create Akislari

Ortak kural:

- Ust evrak bilgisi kompakt olmali.
- Girdigi satir sabit kalmali.
- Kalemler ana alani kullanmali.
- Bulunamayan urun kalem sayilmamali.

Ornek dosyalar:

```text
lib/features/stock_operations/stock_receipts/presentation/widgets/stock_receipt_create_sheet.dart
lib/features/stock_operations/inventory_counts/presentation/widgets/inventory_count_create_sheet.dart
lib/features/return_operations/warehouse_returns/presentation/widgets/warehouse_return_create_sheet.dart
lib/features/stock_operations/virman/presentation/views/virman_page.dart
lib/features/company_movements/shared/presentation/widgets/company_movement_create_sheet.dart
lib/features/stock_operations/label_documents/presentation/views/label_documents_page.dart
lib/features/stock_operations/offline_inventory_counts/presentation/views/offline_inventory_counts_page.dart
```

Stok giriste `Creator` ve `Acceptor` alanlari tek satira yatkin kompakt setup
olarak kullanilir. Uzun aciklama alani gereksiz yere ekranin buyuk kismini
kaplamamalidir.

## 15. Ortak PDA UI Parcalari

Ana dosya:

- `lib/shared/widgets/terminal_ui_parts.dart`

Sik kullanilan parcalar:

```text
TerminalSheetHeader
TerminalLineCountBadge
TerminalPdaRecordCard
TerminalPdaDetailPanel
TerminalPdaInfoGrid
TerminalPdaLineCard
TerminalCompactProductLineCard
TerminalCompactProductLineSummary
TerminalQuantityStepper
TerminalResponsiveLookupRow
TerminalMessageBlock
TerminalFormActionRow
TerminalFilterButton
```

Tasarim kurallari:

- Kart radius genelde 8px civari tutulur.
- Card icinde card kullanma.
- Gereksiz buyuk hero/marketing tasarimi yapma.
- Operasyon ekranlari sessiz, hizli okunur, tekrarli kullanim icin ergonomik
  olmalidir.
- Butonlarda uygun ikon varsa Material icon kullan.
- PDA'da text tasmasi olmamali; `maxLines`, `overflow`, responsive width
  kullan.
- Lookup ve aksiyonlar mumkunse ayni satirda kalir; cok dar ekranda alt satira
  iner.

## 16. Feature Dosya Patterni

Ideal pattern:

```text
features/<module>/<feature>/
  data/
    models/
    <feature>_repository.dart
  presentation/
    view_models/
    views/
    widgets/
```

Her feature birebir ayni olmayabilir:

- Bazi ekranlarda controller vardir.
- Bazi create sheet'ler local state kullanir.
- Bazi repository'ler generic tekrar kullanilir.

Ornek generic repository:

- `CompanyMovementsRepository`

Bu repository farkli hareket tiplerinde tekrar kullanilir:

- giden firma sevkleri
- gelen firma sevkleri
- firma iadeleri

Yeni feature eklemeden once benzer generic pattern var mi kontrol et.

## 17. Yeni Bir Sey Eklerken Yol Haritasi

Once degisikligi siniflandir:

```text
UI-only          -> layout, metin, buton, renk, spacing
Feature logic    -> belirli ekranin state/create/detail davranisi
API contract     -> endpoint, request, response, model
Offline contract -> draft, queue, sync, local catalog
Cross-cutting    -> ApiClient, AppConfig, storage, session, shared widget
```

Genel akis:

1. Ilgili feature klasorunu bul.
2. Degisiklik hangi katmanlari etkiliyor not al.
3. Model gerekiyorsa modeli guncelle.
4. Repository gerekiyorsa endpoint/body/query mapping yap.
5. State gerekiyorsa controller veya create state'e ekle.
6. UI gerekiyorsa page/widget/sheet'i guncelle.
7. Menu gerekiyorsa `ShellModuleRegistry` baglantisini yap.
8. Offline gerekiyorsa draft + sync zincirini unutma.
9. Test ekle veya mevcut testi guncelle.
10. `dart format`, `flutter analyze`, `flutter test` calistir.

### Yeni form alani ekleme checklist

```text
create sheet controller/state
create request model
request toJson/body mapping
repository create methodu
detail/list response modeli
detail/list UI
offline draft varsa payload
offline sync mapping varsa request donusumu
test
```

### Yeni endpoint ekleme checklist

```text
model
repository method
controller method
page/button/filter
error/loading state
test
```

### Yeni ekran ekleme checklist

```text
feature klasoru
models
repository
controller gerekiyorsa controller
page
widgets
AppDependencies
ShellModuleRegistry
menu permission kontrolu
test
```

## 18. Test Stratejisi

Guncel test durumu:

```text
flutter analyze -> temiz
flutter test    -> 93/93 basarili
```

Rutin komutlar:

```powershell
dart format lib test
flutter analyze
flutter test
```

Tek test dosyasi:

```powershell
flutter test test/features/shipping_operations/outgoing_warehouse_shipment_create_sheet_test.dart
```

Test seviyesi secimi:

- Model parse degisirse model/repository testi.
- Controller state degisirse controller testi.
- Create satiri, focus, barkod, layout degisirse widget testi.
- Offline sync degisirse offline sync testi.
- Shared widget degisirse shared widget testi ve en az bir feature testi.

Son create/PDA duzenlerinden sonra kritik test dosyalari:

```text
test/features/shipping_operations/outgoing_warehouse_shipment_create_sheet_test.dart
test/features/order_operations/given_warehouse_order_create_sheet_test.dart
test/features/stock_operations/stock_receipt_create_sheet_test.dart
test/features/acceptance_operations/company_acceptance_create_sheet_test.dart
test/features/return_operations/warehouse_return_create_sheet_test.dart
test/features/company_movements/company_movements_page_test.dart
test/shared/product_entry/product_entry_widgets_test.dart
test/shared/product_entry/product_entry_controller_test.dart
```

PDA layout testi yazarken sadece metin aramak yetmeyebilir. Kullanici davranisini
test et:

- barkod gir
- `Urun` butonuna bas
- kalem sayisi artiyor mu?
- giris satiri duruyor mu?
- duplicate okutma miktari artiriyor mu?
- bulunamayan urun kalem sayilmiyor mu?
- dar genislikte overflow yok mu?

## 19. Release ve Android Guncelleme

Paket versiyonu `pubspec.yaml` icindedir:

```yaml
version: 1.1.37+38
```

Burada:

- `1.1.37` kullanicinin gordugu versionName
- `+38` Android versionCode

Yeni release icin ikisi de bilincli artirilmalidir. Otomatik guncelleme
penceresi kullanici versiyonunu karsilastirir; sadece `+38 -> +39` yapmak
yeterli olmayabilir.

Release oncesi:

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --release
```

APK cikti:

```text
build/app/outputs/flutter-apk/app-release.apk
```

AAB cikti:

```powershell
flutter build appbundle --release
```

```text
build/app/outputs/bundle/release/app-release.aab
```

### Android signing

Gerekli dosyalar:

```text
android/key.properties
android/app/upload-keystore.jks
```

Bu dosyalar commitlenmemelidir. `git status` ile kontrol et.

### Otomatik APK guncelleme

Ana dosyalar:

```text
lib/core/update/app_update_service.dart
lib/app/app.dart
android/app/src/main/kotlin/com/furpa/furpa_merkez_terminal/MainActivity.kt
android/app/src/main/AndroidManifest.xml
android/app/src/main/res/xml/file_paths.xml
```

Varsayilan manifest:

```text
http://10.0.0.100:802/Terminal/version.json
```

Manifest ornegi:

```json
{
  "version": "1.1.38",
  "apk": "http://10.0.0.100:802/Terminal/app-release.apk"
}
```

Yayin akisi:

1. `pubspec.yaml` version artir.
2. Release APK al.
3. APK'yi sunucuya koy.
4. `version.json` icindeki `version` degerini APK versionName ile ayni yap.
5. Cihazda uygulamayi acip update penceresini kontrol et.

Android application id:

```text
com.furpa.furpa_merkez_terminal
```

Bu deger degisirse Android mevcut uygulamanin guncellemesi olarak gormez.

## 20. Gelistirme Ortami Notlari

Bu proje Windows ortaminda PowerShell ile calisiyor. Flutter SDK yolu:

```text
C:\dev\flutter
```

Flutter komutlari SDK cache altina lock/cache dosyasi yazabilir. Codex veya
benzeri sandbox ortamlarinda `C:\dev\flutter` yazilabilir degilse komutlar
takilabilir.

Takilan dart/flutter sureclerini temizlemek icin:

```powershell
Stop-Process -Name dart -Force -ErrorAction SilentlyContinue
Remove-Item C:\dev\flutter\bin\cache\lockfile -Force -ErrorAction SilentlyContinue
Remove-Item C:\dev\flutter\bin\cache\flutter.bat.lock -Force -ErrorAction SilentlyContinue
```

Bu calisma ortaminda `D:\PROJECTS\FURPA(Serdal OZSOY)\FurpaMerkezTerminal`
ana proje klasorudur.

## 21. Sik Tuzaklar

### 1. Bulunamayan urunu kalem saymak

Lookup text dolu diye satiri aktif kalem sayma. Gercek urun secimi veya stok
kodu yoksa satir giris satiridir.

### 2. Girdigi satiri scroll icinde kaybetmek

Create ekraninda giris satiri kullanicinin hizli okutma dongusudur. Header,
evrak alanlari veya liste scroll'u bu satiri kaybettirmemeli.

### 3. Nested scroll kullanmak

Kalem listesi icinde ayrica `ListView` acma. Dolu kalemler, validasyon ve
kaydet butonu ayni ana scroll icinde olmali.

### 4. Offline alanini unutmak

Online create request'e eklenen alan offline draft'a eklenmezse cihaz offline
senaryoda eski veri gonderir.

### 5. `clientRequestId` kaybetmek

Offline recover ve duplicate kontrolu bozulur.

### 6. Menu route baglamayi unutmak

Page yazilsa bile `ShellModuleRegistry` baglantisi yoksa kullanici ekrani
acamaz.

### 7. AppDependencies'e gereksiz dependency eklemek

Sadece tek feature icinde uretilebilecek nesneleri global hale getirme.

### 8. AppConfig default degerini fark etmemek

Feature flag kapaliysa test veya build sirasinda explicit acilmalidir.

### 9. Testi eski UI detayina baglamak

PDA UI degisikliginde tek uzun metin yerine parcalanmis grid kullanilabilir.
Test kullanici davranisini assert etmeli.

### 10. Release version artirmamak

APK build alinsa bile `version.json` ayni versiyonu gosterirse update penceresi
cikmaz.

## 22. Minimum Manuel Saha Kontrolu

Her release veya buyuk PDA degisikliginden sonra sahada su kontrol yapilmali:

1. Login oluyor mu?
2. Session restore calisiyor mu?
3. Yetkili menuler gorunuyor mu?
4. Liste/detail gecisleri calisiyor mu?
5. Giden depo sevk create'te hedef depo seciliyor mu?
6. Barkod okutunca urun geliyor mu?
7. Bulunamayan barkod kalem eklemiyor mu?
8. Ayni barkod tekrar okutulunca miktar artiyor mu?
9. Girdigi satir kaybolmadan tekrar okutmaya hazir kaliyor mu?
10. Kalem listesi ile kaydet butonu ayni scroll icinde mi?
11. Kamera barkod izni ve okuma calisiyor mu?
12. Offline destekli ekranlarda internet kapali/acik senaryosu calisiyor mu?
13. 320-390 px terminal genisliginde overflow yok mu?
14. Otomatik update penceresi dogru versiyonda cikiyor mu?

## 23. Commit Mesaji Ornekleri

PDA create akisi icin:

```text
feat: pda create ekranlarinda giris akisini sabitle

- Create ekranlarinda giris satirinin kaybolmasi engellendi
- Bulunamayan urunlerin kalem sayilmasi onlendi
- Barkod lookup satirlari ortak ProductLookupField davranisina yaklastirildi
- Kalem listesi ve kaydet aksiyonlari ayni scroll akisi icinde tutuldu
- Dar terminal genislikleri icin layout testleri guncellendi

Test:
- flutter analyze
- flutter test
```

Giden depo sevk scroll duzenlemesi icin:

```text
fix: depo sevk create scroll akisini kalemlerle birlestir

- Giden depo sevk create ekraninda nested ListView kaldirildi
- Manuel ve siparisli kalemler SliverList ile ana scroll alanina tasindi
- Validasyon ve Sevki Hazirla aksiyonu kalemlerle ayni scroll sonuna alindi
- Ilgili widget testleri CustomScrollView yapisina gore guncellendi

Test:
- flutter analyze
- flutter test
```

Genis kapsamli degisikliklerde commit mesaji mutlaka su bilgileri icermeli:

- Hangi ekranlar etkilendi?
- Is mantigi degisti mi, yoksa sadece layout mu?
- Offline veya API contract degisti mi?
- Hangi testler calisti?

## 24. Kisa Ozet

Bu projede kaybolmamayi saglayan ana fikir:

```text
app       -> uygulama kabugu ve dependency
core      -> network/config/storage/update
features  -> is ekranlari
shared    -> ortak PDA, barkod, offline ve draft parcalari
```

En kritik akillar:

- Menu backend datasindan gelir, route registry ile ekrana baglanir.
- Yetki gorunurlugu `page/manage` mantigiyla okunur.
- HTTP sadece `ApiClient` uzerinden gitmelidir.
- Offline create varsa `clientRequestId` ve draft zinciri korunmalidir.
- PDA create ekraninda giris satiri kullanicinin ana kas hafizasidir.
- Bulunamayan urun kalem degildir.
- Dolu kalemler ve kaydet aksiyonu ayni scroll alaninda olmalidir.
- Shared UI degisikligi yaptiktan sonra full test calistir.
