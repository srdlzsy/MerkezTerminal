# Proje Calisma Rehberi

Bu belge, `Furpa Merkez Terminal` projesinin nasil calistigini, hangi dosyanin ne ise yaradigini ve projeye yeni bir sey eklerken nasil ilerlenmesi gerektigini anlatiyor.

## 0. Hizli Yon Bulma

Projeye yeni giren biri icin en pratik okuma sirasi:

1. Uygulama nasil aciliyor?
   - `lib/main.dart`
   - `lib/app/bootstrap.dart`
   - `lib/app/app.dart`
2. Bagimliliklar nerede kuruluyor?
   - `lib/app/dependencies.dart`
3. Menu hangi ekrani aciyor?
   - `lib/features/shell/presentation/routing/shell_module_registry.dart`
   - `lib/features/shell/presentation/views/home_shell_page.dart`
4. Tum HTTP istekleri nereden geciyor?
   - `lib/core/network/api_client.dart`
5. Oturum ve yetki nerede tutuluyor?
   - `lib/features/shell/presentation/view_models/app_session_controller.dart`
   - `lib/features/auth/data/auth_repository.dart`
6. Offline kuyruk nerede?
   - `lib/shared/offline/offline_sync_service.dart`
   - `lib/core/storage/local_database.dart`
   - `lib/core/storage/local_sqlite_database.dart`
7. Offline kataloglar nerede?
   - `lib/shared/offline/mobile_product_catalog_repository.dart`
   - `lib/shared/offline/mobile_customer_catalog_repository.dart`
   - `lib/shared/offline/mobile_warehouse_catalog_repository.dart`

Kisa sorumluluk haritasi:

```text
app/      -> uygulama ayaga kalkisi, tema, dependency kurulum
core/     -> network, config, storage, ortak teknik altyapi
features/ -> is modulleri, ekranlar, repository ve controller'lar
shared/   -> moduller arasi ortak widget, formatter, offline servisleri
test/     -> controller, repository ve kritik akis testleri
```

Bir dosyayi degistirmeden once su soruyu sor:

> Bu dosya sadece kendi feature'ini mi etkiliyor, yoksa app/core/shared seviyesinde herkesi etkileyen bir davranis mi degistiriyor?

`core/`, `shared/`, `app/` altindaki degisikliklerin etki alani genelde daha buyuktur. Bu dosyalarda degisiklik yaparken test ve manuel kontrol daha dikkatli yapilmalidir.

## 1. Proje Ne Yapiyor?

Bu proje Flutter ile yazilmis bir merkez terminal uygulamasi.

Ana is mantigi su:

1. Kullanici login olur.
2. Backend kullanicinin yetkilerini ve menu yapisini verir.
3. Uygulama gelen menuye gore ekranlari acabilir hale gelir.
4. Kullanici listeleri gorur, detay acar, create ekranlari ile yeni kayit ekler.
5. Bazi akislar internet varsa aninda sunucuya gider.
6. Bazi akislar internet yoksa offline taslak olarak cihaza yazilir ve daha sonra senkronize edilir.

Bu proje statik menulu basit bir uygulama degil. Menu, yetki ve bazi ekran davranislari kullanicidan gelen backend datasina gore sekilleniyor.

## 2. Giris Akisi

Uygulamanin acilis zinciri:

1. `lib/main.dart`
2. `lib/app/bootstrap.dart`
3. `lib/app/dependencies.dart`
4. `lib/app/app.dart`
5. `lib/features/shell/presentation/views/home_shell_page.dart`

Akis soyle:

### `main.dart`

Sadece `bootstrap()` cagirir.

### `bootstrap.dart`

- Flutter binding ayaga kalkar.
- `AppDependencies.create()` ile tum repository ve servisler uretilir.
- `FurpaMerkezApp` calistirilir.
- Arka planda `sessionController.restoreSession()` ile kayitli token varsa oturum geri yuklenmeye calisilir.

### `app.dart`

Burada uygulamanin ana state secimi yapilir:

- `booting` -> Splash
- `unauthenticated` -> Login
- `authenticated` -> Home shell

Yani route mantigi named routes uzerinden degil, session status uzerinden akiyor.

## 3. Klasor Yapisi

Ana `lib/` yapisi:

```text
lib/
  app/
  core/
  features/
  shared/
```

### `app/`

Uygulamanin kabugu:

- `bootstrap.dart`
- `app.dart`
- `dependencies.dart`
- `theme/`

### `core/`

Tum modullerin kullandigi temel katman:

- `config/` -> app config ve base url
- `network/` -> `ApiClient`, `ApiException`
- `storage/` -> token storage ve `LocalDatabase` / SQLite local tablo altyapisi
- `utils/` -> request epoch, safe notifier, tarih helperlari

### `features/`

Is modulleri burada:

- `auth`
- `shell`
- `order_operations`
- `shipping_operations`
- `acceptance_operations`
- `stock_operations`
- `return_operations`
- `company_movements`
- `legacy_tools`

### `shared/`

Ortak tekrar kullanilan parcalar:

- `widgets/`
- `formatters/`
- `offline/`
- `data/`
- `utils/`

## 4. Temel Mimari Mantik

Projede katman mantigi genel olarak su:

```text
UI/Page/Sheet
  -> Controller veya local State
    -> Repository
      -> ApiClient
        -> Backend
```

Sonra cevap ayni zincirle geri doner:

```text
Backend
  -> Model
    -> Repository
      -> Controller / StatefulWidget
        -> UI
```

### Repository ne yapiyor?

Repository, backend endpointlerini uygulama tarafinda anlamli methodlara donusturuyor.

Ornek:

- `fetchCounts()`
- `fetchCountDetail()`
- `createCount()`
- `searchProducts()`

Ornek dosya:

- `lib/features/stock_operations/inventory_counts/data/inventory_counts_repository.dart`

### Controller ne yapiyor?

Controller, ekran state'ini yonetiyor:

- loading
- error
- secili kayit
- create sonrasi listeyi yenileme
- stale request korumasi

Ornek:

- `lib/features/stock_operations/inventory_counts/presentation/view_models/inventory_counts_controller.dart`

### Page ne yapiyor?

Page genelde:

- controller olusturur
- filtreleri toplar
- list/detay alanlarini cizer
- create sheet acar

Ornek:

- `lib/features/stock_operations/inventory_counts/presentation/views/inventory_counts_page.dart`

### Widget / Sheet ne yapiyor?

Alt formlar, lookup sheetleri, create bottom sheetleri burada olur.

Ornek:

- `inventory_count_create_sheet.dart`
- `company_acceptance_create_sheet.dart`
- `outgoing_warehouse_shipment_create_sheet.dart`

## 5. Network Katmani Nasil Calisiyor?

Merkez parca:

- `lib/core/network/api_client.dart`

`ApiClient` sunlari yapar:

- base url ile final URI olusturur
- `Authorization: Bearer ...` header ekler
- timeout uygular
- json map/list decode eder
- hata response'larini `ApiException`'a cevirir

Yani repository dogrudan `http` ile ugrasmaz. Her sey `ApiClient` uzerinden gider.

## 6. Session ve Yetki Mantigi

### Login

`AuthRepository`:

- `/api/auth/login` cagirir
- gelen token ile `/api/auth/me` cagirir
- token ve cached session'i local storage'a yazar

Ilgili dosyalar:

- `lib/features/auth/data/auth_repository.dart`
- `lib/core/storage/token_storage.dart`

### Session restore

Uygulama acilinca:

- token okunur
- `/api/auth/me` ile gecerlilik kontrol edilir
- network yoksa, cached session varsa kullanilabilir

Bu sayede uygulama her acilista zorunlu login ekranina dusmez.

### Yetki ve menu

`AppSessionController` icinde:

- `currentUser`
- `accessToken`
- `menuEntries`

uretilir.

Menu, `CurrentUser.modules` icinden flatten edilir:

- `lib/features/shell/domain/menu_entry.dart`

## 7. Ana Shell ve Ekran Secimi

Projenin en kritik dosyalarindan biri:

- `lib/features/shell/presentation/views/home_shell_page.dart`
- `lib/features/shell/presentation/routing/shell_module_registry.dart`

Burada su olur:

1. Kullanici modulleri gorunur menulere cevrilir.
2. Sol menu veya dashboard secim yapar.
3. Secilen menu `ShellModuleRegistry` uzerinden ilgili page'e baglanir.

Iki ana pattern var:

### A. Dogrudan route key esleme

`moduleCode.menuCode` string'i ile exact route key eslemesi yapilir.

Ornek:

- `siparis-islemleri.verilen-firma-siparisleri`
- `stok-islemleri.sayim-sonuclari`

### B. Fallback route matching

Backend menu code bazen tam sabit olmayabilir. Bu durumda:

- exact route key
- menu code
- keyword

ile eslesen `ShellModuleRoute.matches(...)` mantigi calisir.

Bu kisim yeni ekran baglarken cok onemli.

## 8. Offline Mantigi

Bu projede offline sadece "ekrani ac" degil, gercek kuyruk mantigi ile calisiyor.

Temel dosyalar:

- `lib/shared/offline/offline_sync_service.dart`
- `lib/core/storage/local_database.dart`
- `lib/core/storage/local_sqlite_database.dart`
- `lib/shared/offline/mobile_product_catalog_repository.dart`
- `lib/shared/offline/mobile_customer_catalog_repository.dart`
- `lib/shared/offline/mobile_warehouse_catalog_repository.dart`

### Offline create akisi

Ornek sayim veya firma mal kabul create sirasinda:

1. Uygulama once online create dener.
2. Network hatasi varsa islem hemen fail olmak yerine kuyruga alinabilir.
3. Draft, local storage'a yazilir.
4. Sonra kullanici offline taslak ekranindan veya otomatik sync ile gonderebilir.

### Local storage nasil?

`LocalDatabase` ortak storage arayuzudur. Uygulamada bunun ana implementasyonu `LocalSqliteDatabase`tir.

`LocalSqliteDatabase`, `sqflite` uzerinden iki tip veri saklar:

- table: ayni key altinda birden fazla json row
- document: tek key altinda tek json document

Eski `SharedPreferencesAsync` tabanli offline draft/cache verileri varsa ilk acilista SQLite'a migrate edilmeye calisilir. Bu yuzden yeni offline veri yazarken dogrudan `SharedPreferencesAsync` kullanma; `LocalDatabase` uzerinden ilerle.

### Offline sync ne zaman olur?

`HomeShellPage` icinde:

- uygulama acilinca
- uygulama resume olunca
- her 45 saniyede bir

`offlineSyncService.syncPending(...)` calisir.

### Mobil kataloglar ne ise yariyor?

Offline urun/cari/depo aramalari icin eski "son aranan cache" yerine mobil katalog mantigi kullanilir:

- product catalog
- customer catalog
- warehouse catalog

Bu kataloglar local SQLite icinde saklanir. Arama ekranlari once API'den arar; API `ApiException` verirse ilgili local katalogdan sonuc donmeye calisir.

Ornekler:

- sayim ve urun arama akislarinda `MobileProductCatalogLocalRepository`
- firma mal kabul, firma hareketleri ve verilen firma siparislerinde `MobileCustomerCatalogLocalRepository`
- verilen depo siparisi, depo sevki ve depo iadesinde `MobileWarehouseCatalogLocalRepository`

Sync servisleri `AppDependencies` icinde kurulur:

- `MobileProductCatalogSyncService`
- `MobileCustomerCatalogSyncService`
- `MobileWarehouseCatalogSyncService`

Kullanici tetiklemesi `Fiyat Gor` ve `Var Yok` ekranlarindaki `Mobil Katalog Sync` butonudur. Bu buton sirasiyla urun, cari ve depo kataloglarini sync eder.

Kritik not: Local fallback'in sonuc verebilmesi icin ilgili katalog daha once cihaza inmis olmalidir. API yokken hic katalog yoksa arama bos donebilir.

## 9. Controller Yardimcilari

Iki kucuk ama onemli utility var:

### `RequestEpoch`

Dosya:

- `lib/core/utils/request_epoch.dart`

Amaci:

- Eski request gec donerse yeni secimi ezmesin.

Ozellikle listeden detaya tiklama gibi hizli akislar icin onemli.

### `SafeChangeNotifier`

Dosya:

- `lib/core/utils/safe_change_notifier.dart`

Amaci:

- widget dispose olduktan sonra `notifyListeners()` hatasi olmasin.

## 10. Feature Dosya Patterni

Bu projede ideal feature pattern genelde su:

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

Ama her feature birebir ayni degil.

Ornek:

- Bazi feature'larda controller var.
- Bazi create sheet'ler state'i kendi icinde tasiyor.
- Bazi repository'ler generic yapida tekrar kullaniliyor.

## 11. Generic Repository Kullanan Alanlar

Tum feature'lar sifirdan repository yazmiyor.

Ornek:

- `CompanyMovementsRepository`

Bu repository farkli endpoint path'leri ile tekrar kullaniliyor:

- giden firma sevkleri
- gelen firma sevkleri
- firma iadeleri

Bu pattern yeni ekran eklerken tekrar kullanima uygun mu diye once bakilmasi gerektigi anlamina gelir.

## 11.1 Projeyi Yonetilebilir Tutma Kurallari

Bu projede teknik borcu kontrol etmek icin en onemli konu, degisikligin hangi katmana ait oldugunu dogru secmektir.

### Degisiklik tipini once siniflandir

Her is icin once asagidaki tiplerden hangisi oldugunu belirle:

```text
UI-only          -> sadece gosterim, layout, label, renk, buton yeri
Feature logic    -> belirli bir ekranin state, filtre, create, detail davranisi
API contract     -> request/response modeli veya endpoint degisikligi
Offline contract -> local draft, sync, recover veya mobil katalog degisikligi
Cross-cutting    -> ApiClient, AppConfig, storage, session, theme, shared widget
```

Risk seviyesi:

- `UI-only` dusuk risklidir; widget kontrolu ve gerekirse snapshot/manual test yeterli olabilir.
- `Feature logic` icin controller veya page akisi test edilmelidir.
- `API contract` icin model parse, query param ve hata response'u kontrol edilmelidir.
- `Offline contract` yuksek risklidir; online create, offline kayit, sync ve duplicate recover birlikte dusunulmelidir.
- `Cross-cutting` en yuksek risklidir; birden fazla modul etkilenebilir.

### Dosya sorumluluklarini karistirma

Genel kural:

- `models/` sadece veri okuma/yazma ve request/response donusumu yapar.
- `repository` sadece API veya local storage erisimini bilir.
- `controller` ekran state'ini, loading/error/selection akisini yonetir.
- `page` kullanici etkilesimini ve layout'u yonetir.
- `widgets/` tekrar kullanilan kucuk UI parcalarini barindirir.

Bir repository icinde UI text'i, bir page icinde ham HTTP istegi veya bir model icinde navigasyon mantigi olmamali.

### Yeni alan eklerken zinciri tamamla

Bir form alanini eklemek genelde tek dosya degildir. Kontrol zinciri:

```text
Create sheet
  -> Create request model
    -> Repository body/query mapping
      -> Backend response model
        -> Detail/list UI
          -> Offline draft varsa local model
            -> Offline sync mapping
              -> Test
```

Bu zincirde bir halka eksik kalirsa en sik gorulen sorunlar:

- alan ekranda var ama backend'e gitmez
- backend'e gider ama offline taslakta kaybolur
- offline sync sonrasi eski data gonderilir
- detail ekraninda yeni alan gorunmez
- testler eski davranisi korudugu icin hata gec fark edilir

### `AppDependencies` buyumesini kontrol et

`lib/app/dependencies.dart` su an tum repository ve servisleri merkezi olarak kuruyor. Bu basit ve anlasilir, ama proje buyudukce dosya agirlasir.

Yeni dependency eklerken:

1. Gercekten global uygulama dependency'si mi?
2. Sadece tek feature icinde olusturulabilir mi?
3. Var olan generic repository yeniden kullanilabilir mi?
4. Testte fake yazmayi zorlastiriyor mu?

Eger bu dosya daha da buyurse ileride su sekilde bolunebilir:

```text
app/dependencies.dart
app/dependency_modules/auth_dependencies.dart
app/dependency_modules/order_dependencies.dart
app/dependency_modules/stock_dependencies.dart
app/dependency_modules/offline_dependencies.dart
```

Simdilik tek dosya kabul edilebilir; ama her yeni modul eklenirken gereksiz dependency tasimamak gerekir.

### Menu eslemesi tek merkezden yonetilmeli

Yeni ekran baglanirken ana merkez:

- `lib/features/shell/presentation/routing/shell_module_registry.dart`

Backend'den gelen menu adlari degisebilir. Bu yuzden route eslesmesinde mumkunse once exact key, sonra gerekiyorsa menu code/keyword fallback kullanilir.

Yeni menu acilmiyorsa sirayla sunlari kontrol et:

1. Backend kullaniciya bu menuyu gonderiyor mu?
2. Menu action listesi bos mu?
3. `moduleCode.menuCode` beklenen string mi?
4. `ShellModuleRegistry` icinde route var mi?
5. Page icin gerekli repository `AppDependencies` icinde veriliyor mu?

### Offline davranista duplicate riskini koru

Offline create akislarinda `clientRequestId` kritik. Bu alan:

- online create denenirken gonderilir
- network koparsa local draft icinde saklanir
- sync sirasinda tekrar gonderilir
- backend tarafinda recover/status kontrolu icin kullanilir

Bu alan kaybolursa ayni islem ikinci kez olusabilir veya recover calismaz.

Offline destekli feature'larda yeni alan eklerken su dosyalara ozellikle bak:

- online create request modeli
- offline draft modeli
- draft `toJson/fromJson`
- draft `toCreateRequest`
- `OfflineSyncService`
- offline liste/create UI

### Error ve loading state ayni dilde olmali

Ekranlarda hata gosterimi kullaniciya teknik stack trace gostermemeli. Repository/API hatalari `ApiException.message` uzerinden okunabilir olmali.

Controller patterninde beklenen state alanlari:

- `isLoading`
- `isDetailLoading`
- `isSubmitting`
- `errorMessage`
- `selected...`
- `items`

Bu isimlendirme feature'lar arasi tutarli tutulursa yeni ekran okumak kolaylasir.

### Model parse ederken toleransli ol

Backend bazen sayiyi string, tarihi null, bool'u 0/1 gibi dondurebilir. Bu projede modeller genelde helper methodlarla toleransli parse eder.

Yeni model yazarken:

- `DateTime.parse` yerine mumkunse `DateTime.tryParse`
- nullable alanlarda bos string kontrolu
- int/double parse helper'i
- list/map cast hatalarina karsi guvenli okuma

tercih edilmelidir.

## 12. Yeni Bir Sey Eklerken Hangi Yol Izlenmeli?

Yeni bir sey eklemeden once isi dogru kategoriye koy. Cunku her kategori farkli dosyalari etkiler.

### Once su karari ver

```text
Sadece ekranda bir metin/gorunum mu degisecek?
  -> UI-only

Var olan form/list/detail davranisi mi degisecek?
  -> Feature logic

Backend'e yeni alan veya yeni endpoint mi gidecek?
  -> API contract

Internet yokken de calismasi gerekiyor mu?
  -> Offline contract

Tum ekranlari etkileyen ortak bir davranis mi?
  -> Cross-cutting
```

### Genel ekleme akisi

Her yeni is icin temel akis:

1. Ilgili feature klasorunu bul.
2. Degisiklik hangi katmanlari etkiliyor not al.
3. Model gerekiyorsa once modeli guncelle.
4. API gerekiyorsa repository methodunu ekle/guncelle.
5. State gerekiyorsa controller'a ekle.
6. UI gerekiyorsa page veya widget'a ekle.
7. Menu ile yeni ekran acilacaksa `ShellModuleRegistry` baglantisini yap.
8. Offline gerekiyorsa draft + sync katmanini unutma.
9. Test ekle veya mevcut testi guncelle.
10. `dart format lib test`, `flutter analyze`, `flutter test` calistir.

### Hangi dosyadan baslayacagim?

| Eklemek istedigin sey | Once bakilacak yer | Sonra bakilacak yer |
| --- | --- | --- |
| Yeni buton | Ilgili `page.dart` veya `detail` widget | Controller/repository aksiyonu |
| Yeni form alani | Ilgili `create_sheet.dart` | request model, offline draft |
| Yeni liste kolonu/badge | Ilgili `page.dart` list item UI | list response modeli |
| Yeni filtre | Ilgili `page.dart` filtre state'i | repository query param |
| Yeni endpoint | Ilgili repository | model + controller/page |
| Yeni ekran | `features/...` yeni klasor | `AppDependencies`, `ShellModuleRegistry` |
| Yeni offline akis | online create modeli | offline draft, repository, sync service |
| Ortak hata/timeout davranisi | `ApiClient` | tum repository testleri |
| Yeni app config | `AppConfig` | README ve build komutlari |

### Yeni ekran ekleme dosya sirasi

Tamamen yeni bir ekran ekleyeceksen ideal dosya sirasi:

```text
1. lib/features/<module>/<feature>/data/models/<feature>_models.dart
2. lib/features/<module>/<feature>/data/<feature>_repository.dart
3. lib/features/<module>/<feature>/presentation/view_models/<feature>_controller.dart
4. lib/features/<module>/<feature>/presentation/views/<feature>_page.dart
5. lib/features/<module>/<feature>/presentation/widgets/...
6. lib/app/dependencies.dart
7. lib/features/shell/presentation/routing/shell_module_registry.dart
8. test/features/<module>/<feature>_controller_test.dart
```

Her ekran controller gerektirmeyebilir. Ama liste/detail/create gibi state'i olan ekranlarda controller kullanmak projeyi daha okunur tutar.

### Yeni alan ekleme dosya sirasi

Var olan create formuna yeni alan eklenecekse:

```text
1. create sheet state/controller
2. create request model
3. request toJson mapping
4. repository body/query param
5. detail/list response modeli
6. detail/list UI
7. offline draft varsa fromJson/toJson/toCreateRequest
8. ilgili test
```

Offline destekli ekranda 7. adim atlanirsa kullanici offline kayit yaptiginda yeni alan kaybolabilir.

### Yeni endpoint ekleme dosya sirasi

Yeni bir backend aksiyonu eklenecekse:

```text
1. request/response model
2. repository interface methodu
3. API repository implementation
4. controller methodu veya page action
5. loading/error state
6. UI butonu veya aksiyon tetigi
7. test
```

Endpoint hata dondurebiliyorsa `ApiException.message` kullaniciya anlasilir sekilde gosterilmeli.

Asagida en sik senaryolari ayirarak anlatiyorum.

### Senaryo A - Var olan bir create ekranina yeni alan eklemek

Ornek:

- create formuna `plaka`
- aciklama 2
- yeni checkbox
- yeni tarih alani

Izlenecek yol:

1. Ilgili create widget'i bul.
   Ornek:
   - `.../presentation/widgets/...create_sheet.dart`
2. Form state'ine controller veya alan ekle.
3. Submit sirasinda request modeline map et.
4. Ilgili create request modelinde alan yoksa onu ekle.
5. `toJson()` icinde backend'e gidecek sekle bagla.
6. Detay/listede de gosterilecekse ilgili view model veya detail UI'yi guncelle.
7. Eger ayni akis offline destekliyorsa offline draft modelini de guncelle.

Offline destek varsa atlanmamasi gereken yerler:

- offline draft model
- offline repository
- sync service mapping
- offline create sheet

### Senaryo B - Var olan ekrana yeni filtre, buton veya gosterim eklemek

Ornek:

- listeye yeni badge
- yeni filtre tarihi
- yeni refresh mantigi

Izlenecek yol:

1. Ilgili `Page` dosyasini bul.
2. Controller kullaniliyorsa state'i orada tut.
3. Sadece gorsel ise `Page` veya alt widget'ta tut.
4. Filtre backend'e gidiyorsa repository method imzasini guncelle.
5. Filter model varsa query param mapper'ini guncelle.

### Senaryo C - Var olan modula yeni endpoint eklemek

Ornek:

- create var ama cancel eklenecek
- detail var ama pdf indir eklenecek

Izlenecek yol:

1. Ilgili repository interface'ine method ekle.
2. API implementation'a endpoint bagla.
3. Gerekli response/request modeli varsa ekle.
4. UI butonunu ilgili page/detail ekranina ekle.
5. Hata ve loading state'ini controller veya page state'inde yonet.

### Senaryo D - Tamamen yeni bir ekran/modul eklemek

En onemli senaryo bu.

Adimlar:

1. Feature klasorunu olustur.
2. `data/models` altina request-response modellerini yaz.
3. `data/<feature>_repository.dart` olustur.
4. Repository abstract interface + API implementation yaz.
5. Gerekirse `presentation/view_models` altina controller yaz.
6. `presentation/views` altina page yaz.
7. Create/detay/filter alt widgetlarini `presentation/widgets` altina ayir.
8. `AppDependencies.create()` icinde repository instance'ini ekle.
9. `ShellModuleRegistry` constructor'una gerekli repository'yi ekle.
10. `ShellModuleRegistry._buildRoutes()` icinde ilgili menu eslemesini yap.
11. Eger backend menusu tutarsiz adlandirma kullaniyorsa `menuCodes` veya `keywords` fallback ekle.
12. Gerekirse test ekle.

### Senaryo E - Yeni ekran offline da calissin istiyorum

Bu biraz daha buyuk is.

Gerekenler:

1. Online create request modelin olmali.
2. Bunun local draft karsiligi olmali.
3. Offline repository olmali.
4. `OfflineSyncService` icine submit + sync draft mantigi eklenmeli.
5. Offline taslak liste ekranin olmali.
6. Lookup gerekiyorsa ilgili mobil katalog repository'si ve fallback mantigi eklenmeli.
7. Katalog sync gerekiyorsa `AppDependencies` ve `ShellModuleRegistry` uzerinden local/sync servisleri ekrana tasinmali.

Kisacasi offline destek, sadece "save locally" degil; ayri bir is akisi.

## 13. Yeni Modulu Menuye Baglama Rehberi

Bu kisim cok onemli.

Yeni bir page yazdin ama ekranda gorunmuyor ise buyuk ihtimalle baglanti eksiklerinden biri vardir.

Kontrol listesi:

1. Repository `AppDependencies` icinde olusturuldu mu?
2. Repository `ShellModuleRegistry` constructor'una eklendi mi?
3. `AppDependencies` icinde `ShellModuleRegistry` olusturulurken pass edildi mi?
4. `ShellModuleRegistry._buildRoutes()` icinde route baglandi mi?
5. Backend'den gelen `moduleCode` ve `menuCode` gercekten senin bekledigin isim mi?
6. Gerekirse `menuCodes` veya `keywords` ile fallback tanimlandi mi?
7. Kullanicide o menuye ait action var mi?

Ozellikle `canCreate` su mantikla belirleniyor:

```text
selectedMenu.actions.any((action) => action.code == 'create')
```

Yani create butonunun cikmasi sadece UI degil, permission datasina da bagli.

## 14. Ornek Zincir: Sayim Sonuclari

Bu modulu referans alin, cunku duzgun katmanli.

Dosyalar:

- `data/inventory_counts_repository.dart`
- `data/models/inventory_count_models.dart`
- `presentation/view_models/inventory_counts_controller.dart`
- `presentation/views/inventory_counts_page.dart`
- `presentation/widgets/inventory_count_create_sheet.dart`
- `test/features/stock_operations/inventory_counts_controller_test.dart`

Calisma mantigi:

1. Page controller olusturur.
2. Controller listeyi yukler.
3. Secili kayit varsa detay ister.
4. Create sheet request dondurur.
5. Page dogrudan repository'e gitmek yerine offline sync service uzerinden create eder.
6. Basariliysa liste tekrar yuklenir.

Bu pattern yeni liste-detay-create modulleri icin iyi bir referanstir.

## 15. Test Yazma Mantigi

Repo icinde testler ozellikle controller seviyesinde fake repository ile yazilmis.

Ornek:

- `test/features/stock_operations/inventory_counts_controller_test.dart`

Pattern:

1. Fake repository olustur.
2. Controller'i bu fake ile ayaga kaldir.
3. `loadCounts`, `createCount`, `selectCount` gibi akislar test edilir.
4. Hangi state'in secili oldugu assert edilir.

Yeni modulde controller varsa ayni patterni kullan.

### Test seviyesi nasil secilir?

Her degisiklik icin test seviyesi ayni olmak zorunda degil.

```text
UI label/layout             -> manuel kontrol yeterli olabilir
Controller state degisikligi -> controller unit test
Repository mapping          -> repository veya ApiClient fake response test
Offline sync                -> draft save + sync + recover test
Session/auth                -> AppSessionController/AuthRepository test
Shared helper               -> dogrudan unit test
```

Yeni test yazarken amac sadece coverage degil, ileride bozulmasi en olasi davranisi kilitlemektir.

Iyi test ornekleri:

- liste yuklenince ilk kayit seciliyor mu?
- create sonrasi liste yenileniyor mu?
- eski detail response yeni secimi eziyor mu?
- 401 gelince session recover calisiyor mu?
- network yokken offline draft kuyruga aliniyor mu?

Offline draft veya mobil katalog testlerinde gercek SQLite yerine `test/support/memory_local_database.dart` icindeki `MemoryLocalDatabase` kullanilabilir. Bu sayede repository testleri dosya sistemi veya platform SQLite'a baglanmadan calisir.

Ornek:

```dart
final repository = MobileProductCatalogLocalRepository(
  database: MemoryLocalDatabase(),
);
```

`TokenStorage` veya legacy SharedPreferences migration testlerinde `SharedPreferencesAsync` gerekiyorsa in-memory platform kurulmalidir. Ornek:

```dart
setUp(() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
});

tearDown(() {
  SharedPreferencesAsyncPlatform.instance = null;
});
```

Bu kurulmazsa SharedPreferences kullanan testlerde `The SharedPreferencesAsyncPlatform instance must be set` hatasi alinabilir.

## 16. Bu Projede Dikkat Edilmesi Gereken Tuzaklar

### 1. Sadece UI eklemek yetmez

Bir sey ekledigin zaman cogu zaman su katmanlardan birkaci birlikte degisir:

- model
- repository
- page
- create sheet
- offline draft
- test

### 2. Menu eslemesi unutulursa ekran hic acilmaz

Ozellikle yeni moduller icin ilk bakilacak yer `home_shell_page.dart`.

### 3. `clientRequestId` kritik

Offline/online recover mantigi icin create request'lerde `clientRequestId` korunur.
Bunu bozarsan duplicate veya recover akislarini kirabilirsin.

### 4. Offline destek varsa iki tarafta da alan ekle

Sadece online request modeline alan ekleyip offline draft'e eklemezsen veri kaybi olur.

### 5. Standalone page ile embedded page farkli olabilir

Offline sayfalarda `standalone` gibi page kabugu farklari var.
Route ile acilan sayfada `Scaffold/Material` eksik kalirsa siyah ekran gibi sorunlar gorulebilir.

### 6. Controller yarislari

Hizli secim degisikliklerinde stale response problemi olabilir.
Bu projede bunun icin `RequestEpoch` kullaniliyor.

### 7. Dispose sonrasi notify

Controller yaziyorsan `SafeChangeNotifier` patternini koru.

### 8. Token storage release icin hassas

Tokenlar su an `SharedPreferencesAsync` uzerinden saklaniyor.

Bu gelistirme ve lokal kullanim icin basit bir cozumdur. Uretim/release guvenligi artirilacaksa access token ve refresh token icin `flutter_secure_storage` gibi platform secure storage dusunulmelidir.

Ilgili dosya:

- `lib/core/storage/token_storage.dart`

### 9. HTTP ve cleartext ayarlari bilincli kullanilmali

Varsayilan API adresi lokal agdaki HTTP sunucusudur:

```text
http://192.168.254.214:7508
```

Android tarafinda cleartext traffic, iOS tarafinda App Transport Security istisnasi aciktir. Bu lokal ag/VPN senaryosu icin anlasilabilir, ama public release icin HTTPS tercih edilmelidir.

Kontrol edilecek yerler:

- `lib/core/config/app_config.dart`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

### 10. Offline storage buyurse SQLite semasi degerlendirilmeli

Offline draft ve mobil kataloglar su an `LocalDatabase` arayuzu arkasinda SQLite icinde JSON row/document olarak tutuluyor. Bu yapi SharedPreferences'a gore daha uygundur, ama veri cok buyurse tek tek JSON row saklamak veya tum tabloyu okuyup filtrelemek pahali hale gelebilir.

Eger offline veri buyurse veya ayni anda cok yazma/okuma ihtiyaci artarsa su alternatifler degerlendirilmeli:

- Drift veya typed SQLite tablolar
- Isar
- Hive

Bu gecis yapilacaksa once `LocalDatabase` arayuzu korunup alt implementasyon veya katalog repository'lerinin ic sorgu stratejisi degistirilmelidir.

### 11. Dependency guncellemesi major ise ayri is olarak yap

`flutter pub outdated` yeni major surumleri gosterebilir. Major guncellemeler ozellikle kamera, yazdirma ve platform pluginlerinde davranis degistirebilir.

Guncelleme stratejisi:

1. Ayri branch veya ayri is olarak ele al.
2. `flutter pub upgrade --major-versions` sonrasi changelog oku.
3. Android/iOS permission ve manifest degisikliklerini kontrol et.
4. `flutter analyze` ve `flutter test` calistir.
5. Kamera/barkod/yazdirma gibi native ozellikleri cihazda manuel dene.

## 17. Yeni Bir Ekran Eklerken Kisa Checklist

Asagidaki listeyi sirayla gec:

1. Backend endpointi net mi?
2. Request/response modeli yazildi mi?
3. Repository interface + API implementation tamam mi?
4. Gerekliyse controller var mi?
5. Page ve alt widgetlar ayrildi mi?
6. Dependency injection baglandi mi?
7. `HomeShellPage` icinde menu map'i yapildi mi?
8. Permission kaynakli `canCreate` veya benzeri aksiyonlar dusunuldu mu?
9. Offline gerekiyorsa draft + sync katmani eklendi mi?
10. Hata/loading/empty state'leri yazildi mi?
11. Liste/detail/create akisi stale response'a karsi guvenli mi?
12. Test ve en azindan `flutter analyze` calistirildi mi?
13. Offline veya native ozellik varsa cihazda manuel kontrol yapildi mi?

## 18. Gelistirme Sirasinda Pratik Komutlar

### Rutin kontrol sirasi

Bir degisiklik tamamlanmadan once ideal kontrol sirasi:

```text
1. dart format lib test
2. flutter analyze
3. flutter test
4. Degisiklik native/plugin etkiliyorsa cihazda manuel test
5. API contract degistiyse backend ile request/response kontrolu
6. Offline etkileniyorsa internet kapali/geri acik senaryosu
```

Kucuk UI degisikliklerinde tum manuel senaryolari calistirmak gerekmeyebilir, ama `flutter analyze` ve ilgili testler temiz olmalidir.

### Haftalik / periyodik bakim

Proje aktif gelistiriliyorsa arada su kontroller yapilabilir:

```bash
flutter pub outdated
flutter analyze
flutter test
```

Bakimda ozellikle sunlara bak:

- major dependency guncellemesi var mi?
- testler localde ve CI'da ayni sonucu veriyor mu?
- Android/iOS manifest izinleri gereksiz genislemis mi?
- offline draft formatinda migration gerektiren degisiklik var mi?
- README ve bu rehber yeni akisla uyumlu mu?

### Release oncesi kisa kontrol

Release veya saha test paketi almadan once su liste gecilmeli:

1. API base URL dogru mu?
2. HTTP/HTTPS ve cleartext ayari hedef ortama uygun mu?
3. Android signing dosyalari hazir mi?
4. Kamera/barkod izni cihazda calisiyor mu?
5. Yazdirma/PDF akisi hedef cihazda denenmis mi?
6. Login, session restore, logout denenmis mi?
7. Offline create + sync akisi denenmis mi?
8. `flutter analyze` temiz mi?
9. `flutter test` temiz mi?

### Android release signing ilk kurulum

Release APK'nin kullanici cihazinda guncelleme olarak kurulabilmesi icin ayni uygulama imzasi korunmalidir. Bu yuzden keystore dosyasi kaybedilmemeli ve sifreleri guvenli yerde saklanmalidir.

Bu projede Android imza ayari su dosyada yapilir:

```text
android/app/build.gradle.kts
```

Mantik su:

- `android/key.properties` varsa release build bu dosyadaki keystore ile imzalanir.
- `android/key.properties` yoksa build debug imzasina duser.
- Debug imzali APK saha test icin kurulabilir ama nihai dagitim sayilmamalidir.

Ilk kez release anahtari olusturma:

```powershell
keytool -genkeypair -v -keystore android\app\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Sonra `android/key.properties` dosyasi olusturulur:

```properties
storePassword=KEYSTORE_SIFRESI
keyPassword=KEY_SIFRESI
keyAlias=upload
storeFile=app/upload-keystore.jks
```

`keytool` sirasinda key password icin Enter ile ayni sifre kullanildiysa `storePassword` ve `keyPassword` ayni olabilir.

Asla commitlenmemesi gereken dosyalar:

```text
android/key.properties
android/app/upload-keystore.jks
```

`android/.gitignore` bu dosyalari ignore eder. Yine de commit oncesi `git status` ile kontrol edilmelidir.

Keystore olustu mu hizli kontrol:

```powershell
Test-Path android\key.properties
Test-Path android\app\upload-keystore.jks
```

Alias kontrolu gerekiyorsa:

```powershell
keytool -list -v -keystore android\app\upload-keystore.jks -alias upload
```

Bu komut sifre sorar; sifre ekrana yazilmaz.

### Yeni versiyon atma akisi

Yeni APK/AAB cikmadan once `pubspec.yaml` icindeki version artirilmalidir:

```yaml
version: 1.0.0+1
```

Burada:

- `1.0.0` kullanicinin gorecegi versiyondur.
- `+1` Android `versionCode` degeridir.
- Ayni cihaza veya Play Store'a guncelleme vermek icin `+` sonrasi sayi her release'te artmalidir.

Ornek:

```yaml
version: 1.0.1+2
```

Sadece ic test paketi alirken bile build numarasini artirmak kurulum karisikliklarini azaltir.

Yeni surumden once rutin komutlar:

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Icon degistiyse:

```powershell
flutter pub run flutter_launcher_icons
```

Release APK alma:

```powershell
flutter build apk --release
```

APK cikti yolu:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Play Store veya merkezi dagitim AAB istiyorsa:

```powershell
flutter build appbundle --release
```

AAB cikti yolu:

```text
build/app/outputs/bundle/release/app-release.aab
```

Hedef ortama gore API adresi build sirasinda verilecekse:

```powershell
flutter build apk --release --dart-define=API_BASE_URL_ANDROID=http://10.0.0.100:7508
```

### Otomatik APK guncelleme akisi

Android uygulama acilinca yeni surum kontrolu otomatik yapilir. Varsayilan manifest adresi:

```text
http://10.0.0.100:802/Terminal/version.json
```

Manifest formati:

```json
{
  "version": "1.0.3",
  "apk": "http://10.0.0.100:802/Terminal/app-release.apk"
}
```

Akis su sekildedir:

1. Uygulama acilirken `version.json` okunur.
2. `version` degeri cihazdaki uygulama versiyonundan buyukse kullaniciya "Yeni surum var, indirelim mi?" sorulur.
3. Kullanici `Indir` derse APK cache'e indirilir.
4. Android sistem kurulum ekrani acilir.
5. Cihazda bilinmeyen kaynaklardan kurulum izni kapaliysa izin sayfasi acilir; izin verilince kurulum ekrani otomatik devam eder.

Onemli ilk kurulum mantigi:

- Otomatik guncelleme kodu eski APK'nin icinde yoksa eski uygulama `version.json` kontrol edemez.
- Bu nedenle otomatik guncelleme sistemi eklendikten sonra uretilen ilk APK cihaza bir kere manuel kurulmalidir.
- Bundan sonraki surumlerde uygulama acilinca otomatik kontrol calisir.

Ornek:

1. Cihaza manuel olarak `1.1.5+6` kurulur. Bu APK artik otomatik guncelleme kodunu icerir.
2. Sonraki release `pubspec.yaml` icinde `version: 1.1.6+7` yapilir.
3. Yeni APK sunucuya `app-release.apk` olarak koyulur.
4. Sunucudaki `version.json` `1.1.6` gosterir.
5. Cihazda yüklü `1.1.5` uygulama acilinca `1.1.6` daha buyuk oldugu icin guncelleme sorusu cikar.

Bu akis su dosyalardadir:

```text
lib/core/update/app_update_service.dart
lib/app/app.dart
android/app/src/main/kotlin/com/furpa/furpa_merkez_terminal/MainActivity.kt
android/app/src/main/AndroidManifest.xml
android/app/src/main/res/xml/file_paths.xml
```

Yeni surumu yayinlarken:

1. `pubspec.yaml` icindeki `version` degerini artir.
2. `flutter build apk --release` ile APK al.
3. `build/app/outputs/flutter-apk/app-release.apk` dosyasini `http://10.0.0.100:802/Terminal/app-release.apk` olacak sekilde sunucuya koy.
4. Sunucudaki `version.json` icindeki `version` degerini APK'nin kullanici versiyonu ile ayni yap.
5. `apk` alaninin indirilebilir APK adresini gosterdigini kontrol et.

Ornek: `pubspec.yaml` icinde `version: 1.0.3+6` varsa `version.json` icindeki deger `1.0.3` olmalidir. Otomatik kontrol `+6` build numarasini degil kullanici versiyonunu karsilastirir; bu yuzden saha guncellemesi icin noktali versiyon da artirilmalidir.

Kritik kural:

- Cihazdaki uygulama `1.1.5` ise sunucudaki `version.json` da `1.1.5` ise guncelleme sorusu cikmaz.
- Guncelleme sorusu cikmasi icin sunucudaki `version` cihazdaki uygulama surumunden buyuk olmalidir.
- `version.json` icindeki `version`, sunucuya koyulan APK'nin `versionName` degeriyle ayni olmalidir.
- Sadece `+6`, `+7` gibi build numarasini artirmak otomatik guncelleme penceresi icin yetmez; `1.1.5 -> 1.1.6` gibi kullanici versiyonu da artmalidir.

APK'nin icindeki gercek surumu kontrol etmek icin:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.1.0-rc1\aapt.exe" dump badging build\app\outputs\flutter-apk\app-release.apk | Select-String "package:"
```

Beklenen ornek cikti:

```text
versionCode='7' versionName='1.1.6'
```

Sunucunun gercekten hangi `version.json` dosyasini servis ettigini kontrol etmek icin:

```powershell
(Invoke-WebRequest -Uri http://10.0.0.100:802/Terminal/version.json -UseBasicParsing).Content
```

Masaustundeki `C:\Users\devse\Desktop\version.json` dosyasini duzenlemek tek basina yeterli olmayabilir. Esas kontrol edilmesi gereken dosya, tarayicidan veya `Invoke-WebRequest` ile `http://10.0.0.100:802/Terminal/version.json` adresinden okunan dosyadir.

Guncelleme manifest adresi farkli ortamda degisecekse build sirasinda verilebilir:

```powershell
flutter build apk --release --dart-define=UPDATE_MANIFEST_URL=http://10.0.0.100:802/Terminal/version.json
```

Notlar:

- APK ayni `applicationId` ve ayni release keystore ile imzalanmali.
- `version.json` veya APK adresi HTTP ise Android manifestte cleartext traffic izni gerekir; bu projede aciktir.
- APK kurulumunu Android sistem kurucusu yapar, uygulama sessiz kurulum yapmaz.
- Ilk saha kurulumunda cihazda "bu uygulamadan kurulum" izni istenebilir.

Android uygulama kimligi su anda:

```text
com.furpa.furpa_merkez_terminal
```

Bu deger degistirilirse cihaz bunu eski uygulamanin guncellemesi olarak gormez; yeni uygulama gibi kurulur. Mecbur kalmadikca `applicationId` degistirilmemelidir.

### Saha cihazi guncelleme notlari

APK ayni `applicationId` ve ayni release keystore ile imzalandiysa mevcut uygulamanin uzerine guncelleme olarak kurulabilir.

ADB ile manuel kurulum:

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

Temiz kurulum gerekiyorsa once uygulama kaldirilabilir, ama bu lokal token/offline draft gibi cihazdaki uygulama verilerini silebilir. Offline kayit bekleyen cihazlarda once sync tamamlanmalidir.

Dagitimdan sonra sahada minimum manuel smoke test:

1. Uygulama aciliyor mu?
2. Ikon ve uygulama adi dogru mu?
3. Login oluyor mu?
4. Menu listesi geliyor mu?
5. Barkod/kamera izni calisiyor mu?
6. Kritik liste/detail ekranlari aciliyor mu?
7. Terminal geri tusu uygulamayi kapatmadan once menu/anasayfa akisini yapiyor mu?
8. Offline create kullanilan cihazda internet kapali/acik senaryosu calisiyor mu?
9. `version.json` daha yuksek versiyon gosterince guncelleme sorusu cikiyor mu?
10. `Indir` sonrasi APK kurulum ekrani aciliyor mu?

### Release icin eksik sayilacak durumlar

Asagidakilerden biri varsa paket "dagitima hazir" sayilmamalidir:

- `flutter analyze` hata veriyor.
- `flutter test` hata veriyor.
- `android/key.properties` yok veya bos alan iceriyor.
- `android/app/upload-keystore.jks` yok.
- `pubspec.yaml` `version` build numarasi artirilmamis.
- API base URL test/production hedefi icin yanlis.
- Otomatik guncelleme icin `version.json` ve APK sunucuya yuklenmemis veya yanlis URL gosteriyor.
- Kamera veya internet izni hedef cihazda denenmemis.
- Offline draft bekleyen cihazlara temiz kurulum yapilacaksa sync plani yok.
- Ikon/app adi degistiyse launcher icon ve manifest yeniden uretilmemis.

### Codex / Windows ortam notu

Bu proje Flutter SDK'yi `C:\dev\flutter` altindan kullaniyor. Codex sandbox sadece proje klasorune yazabiliyorsa `flutter analyze`, `flutter test`, `flutter pub get` gibi komutlar takilabilir.

Sebep proje buyuklugu degildir. Flutter komutlari calisirken SDK cache altina lock/cache dosyasi yazar:

```text
C:\dev\flutter\bin\cache\lockfile
C:\dev\flutter\bin\cache\flutter.bat.lock
```

Codex bu klasore yazamazsa `flutter.bat` sessizce lock bekleyebilir ve komut cikti vermeden uzun sure bitmeyebilir.

Kalici cozum icin `C:\Users\devse\.codex\config.toml` icinde root seviyede su ayarlar bulunmali:

```toml
model = "gpt-5.5"
model_reasoning_effort = "xhigh"
sandbox_mode = "workspace-write"

[windows]
sandbox = "elevated"

[sandbox_workspace_write]
writable_roots = [
  "C:\\Users\\devse\\Desktop\\PROJECTS\\FurpaMerkezTerminal",
  "C:\\dev\\flutter"
]
```

Onemli: `sandbox_mode = "workspace-write"` satiri herhangi bir `[section]` altinda kalmamali; dosyanin root seviyesinde, ilk section basligindan once durmali.

Config degistikten sonra Codex tamamen kapatilip tekrar acilmali.

Eger Flutter komutu daha once takildiysa once eski dart surecleri ve lock dosyalari temizlenebilir:

```powershell
Stop-Process -Name dart -Force -ErrorAction SilentlyContinue
Remove-Item C:\dev\flutter\bin\cache\lockfile -Force -ErrorAction SilentlyContinue
Remove-Item C:\dev\flutter\bin\cache\flutter.bat.lock -Force -ErrorAction SilentlyContinue
```

Format:

```bash
dart format lib test
```

Analiz:

```bash
flutter analyze
```

Test:

```bash
flutter test
```

Belirli dosya analizi:

```bash
dart analyze lib/features/stock_operations/inventory_counts/presentation/view_models/inventory_counts_controller.dart
```

## 19. Ozet

Bu projeyi anlamanin en kisa yolu su:

- `app/` = uygulama kabugu
- `core/` = temel altyapi
- `features/` = is modulleri
- `shared/` = ortak parcalar
- `HomeShellPage` = menu -> ekran esleme merkezi
- `AppDependencies` = dependency injection merkezi
- `ApiClient` = tum HTTP kapisi
- `OfflineSyncService` = offline kuyruk ve recover merkezi

Bir sey eklerken once su soruyu sor:

> Bu degisiklik sadece UI degisikligi mi, yoksa model + repository + menu + offline + test zincirini de etkiliyor mu?

Bu soruya dogru cevap verdiginde projede kaybolman cok azalir.
