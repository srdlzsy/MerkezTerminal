# Terminal Guvenli Create Akisi

Bu dokuman terminal create ekranlari icin uygulanacak nihai kullanici ve entegrasyon sozlesmesidir. Ayrintili API modelleri icin `UI_API_DOKUMANI.md`, tam route/model listesi icin `API_SOZLESME_REFERANSI.md` kullanilir.

## Hedef

- Kullanici Kaydet'e bastigi ekranda sonucu gorur.
- Yavas internet veya sunucu yogunlugu ikinci evrak olusturmaz.
- Form, satirlar ve `clientRequestId` kesin sonuc alinincaya kadar korunur.
- Teknik sorun yalniz ilgili evragi bekletir; diger ekranlar ve yeni bagimsiz evraklar acik kalir.
- UI hata metni eslestirmez; `recommendedAction` alanini uygular.

## Yerel Kayit

Ilk Kaydet aninda tek transaction ile su veri yerel veritabanina yazilir:

```text
userId
clientType
warehouseNo
operationCode
clientRequestId
payloadSnapshot
createdAt
uiStatus
recommendedAction
lastCheckedAt
```

Kurallar:

- `clientRequestId` GUID'dir ve tek mantiksal kaydetme denemesi boyunca degismez.
- `payloadSnapshot`, POST edilen body'nin aynisidir. Pending durumda ekrandaki son form degerlerinden yeniden uretilmez.
- Basarili business response veya `ClearCancelled` gelmeden yerel kayit silinmez.
- Uygulama kapanirsa kayit kalir; acilista once status/readback ile uzlastirilir.

## Ayni Ekran Akisi

```text
Duzenleniyor
  -> Kaydet
Kaydediliyor
  -> 200/201
Kaydedildi

Kaydediliyor
  -> timeout / HTTP 0 / 500 / 502 / 503 / 504
Sonuc kontrol ediliyor
  -> status/readback
Kaydedildi | Bekleniyor | Islem gerekiyor
```

Kaydet sirasinda:

- Form otomatik kapanmaz.
- Liste veya Bulut ekranina zorunlu yonlendirme yapilmaz.
- Form alanlari ve Kaydet yalniz bu evrak icin kilitlenir.
- Kullanici bilincli olarak geri giderse islem devam eder ve header/home seviyesinde bekleyen islem sayisi gosterilebilir.
- Kullanici ayni evragi yeniden acarsa saklanan snapshot ve mevcut durum gosterilir.

Basarida:

- `result.documentSerie` ve `result.documentOrderNo` gosterilir.
- Yerel pending kayit atomik olarak silinir.
- `Tamam` ve `Yeni Evrak` aksiyonlari acilir.
- Recovery ile bulunan mevcut evrak da normal basari gibi gosterilir; ikinci evrak yazilmaz.

## Karar Tablosu

| `recommendedAction` | Terminal davranisi | Kullanici metni |
|---|---|---|
| `Completed` | Sonucu goster, pending kaydi sil. | `Evrak kaydedildi.` |
| `WaitAndCheck` | POST yapma; `retryAfterSeconds` sonrasinda status GET yap. | `Kayit sonucu kontrol ediliyor.` |
| `RetrySameRequest` | Saklanan snapshot'i ayni `clientRequestId` ile POST et. | `Baglanti kuruldu, kayit guvenli sekilde devam ediyor.` |
| `RecheckExisting` | Ortak `yeniden-dogrula` POST'unu cagir; create POST yapma. | `Mikro kaydi yeniden kontrol ediliyor.` |
| `RestoreOriginalRequest` | Orijinal snapshot'i geri yukle; degismis body ile gonderme. | `Bekleyen evragin icerigi degistirilmis.` |
| `NeedsReview` | Otomatik istek/POST durdur; kaydi koru. | `Bu evrak kontrol bekliyor. Diger islemlere devam edebilirsiniz.` |
| `ClearCancelled` | Pending kaydi sil; basari mesaji verme. | `Islem iptal edildi; Mikro evraki olusturulmadi.` |

Ham `errorCode`, `retryable`, `clientRequestId` ve `correlationId` ana kullanici mesajinda gosterilmez. Teknik ayrinti panelinde veya destek bilgisinde bulunabilir.

## HTTP Senaryolari

### 200 veya 201

- Business response kesin sonuctur.
- Belge numarasi gosterilir ve pending kayit silinir.

### 400

- Mikro yazimi baslamamistir.
- Ayni form acik ve duzenlenebilir kalir.
- Alan hatasi ilgili input yaninda gosterilir.
- Kullanici duzelttikten sonra bu yeni kaydetme denemesi icin snapshot yeniden alinir.

### 401

- Snapshot ve `clientRequestId` korunur.
- Login yenilenir.
- Login sonrasi once status GET yapilir; otomatik yeni GUID uretilmez.

### 403

- Otomatik retry yapilmaz.
- Form korunur, yetki/depo mesaji gosterilir.

### 404 Status

- Backend rezervasyonu bulunamamistir; request body sunucuya hic ulasmamis olabilir.
- Saklanan ayni snapshot ve ayni `clientRequestId` ile create POST bir kez yeniden gonderilir.
- Yeni GUID uretilmez.

### 409

- `recommendedAction` uygulanir.
- `retryable=true` tek basina POST sebebi degildir.
- `MIKRO_WRITE_OUTCOME_UNCONFIRMED` ve `MIKRO_DOCUMENT_INCOMPLETE` durumunda POST yapilmaz.
- Yalniz `RetrySameRequest` POST'a izin verir.

### HTTP 0, 500, 502, 503, 504 veya Timeout

- Sonuc belirsiz kabul edilir.
- Snapshot/id korunur.
- Once status GET yapilir.
- Status da gecici hata verirse artan bekleme uygulanir.

## Polling

- Ilk kontrol `retryAfterSeconds` kadar sonra yapilir; verilmezse 5 saniye kullanilir.
- Gecici hatalarda 5, 10, 20 ve en fazla 30 saniye beklenir.
- Onceki istek bitmeden yenisi baslatilmaz.
- Ekran gorunurken ayni evrak icin tek polling dongusu bulunur.
- Kullanici ekrandan ayrilinca sik polling durur; pending kayit silinmez.
- Uygulama odaga geldiginde veya bekleyen islemler acildiginda tek status kontrolu yapilir.
- `Completed`, `NeedsReview`, `RestoreOriginalRequest` ve `ClearCancelled` son durumlarinda polling durur.
- `RecheckExisting` otomatik sonsuz dongu degildir. Bir salt-okuma kontrolunden sonra `NeedsReview` gelirse kullaniciya ayni buton tekrar tekrar sunulmaz.

## Yeniden Dogrulama

Ortak endpoint:

```http
POST /api/mobile-sync/guvenli-yazmalar/{clientRequestId}/yeniden-dogrula
Content-Type: application/json
Authorization: Bearer {accessToken}

{
  "operationCode": "mal-kabul-islemleri.firma-mal-kabulleri.create"
}
```

Guvenlik ve davranis:

- Yalniz login kullanicinin kendi kullanici, JWT depo, operasyon ve istek kimligi kaydi okunur.
- Baska kullanici veya depo kaydi acilmaz.
- Mikro'ya create/update/delete yazmaz.
- Tam eslesme `Completed` yapar.
- Eksik satir `Incomplete + WaitAndCheck` olur.
- Kalici fark `Mismatch + NeedsReview` olur.
- Belge bulunamazsa normal kullaniciya ikinci create izni verilmez; karar kayit bazli incelemeye gider.

Firma mal kabul icin eski operasyon-ozel endpoint de ayni amacla kullanilabilir:

```text
POST /api/mal-kabul-islemleri/firma-mal-kabulleri/offline-sync/{clientRequestId}/yeniden-dogrula
```

## Yetkili Kararlari

Yetkili yalniz kalici belirsizlikte devreye girer:

- `yeniden-dogrula`: Salt-okuma kontrolunu tekrarlar.
- `tekrar-ac`: Yalniz Mikro'da belge olmadigi kesinlestiyse `SAFE_WRITE_RETRY_ALLOWED + RetrySameRequest` verir.
- `iptal`: Auth DB kaydini `Cancelled` yapar; Mikro belgesini silmez.

`tekrar-ac` sonrasinda terminal yeni id veya yeni body uretmez. Saklanan ayni snapshot/id ile POST yapar. Backend bu ozel karari normal belirsiz sonuçtan ayirir ve yazimin gercekten tekrar baslamasina izin verir.

## Desteklenen Operation Code Degerleri

```text
mal-kabul-islemleri.firma-mal-kabulleri.create
stok-islemleri.sayim-sonuclari.create
siparis-islemleri.verilen-depo-siparisleri.create
siparis-islemleri.verilen-firma-siparisleri.create
sevk-islemleri.giden-depolar-arasi-sevkler.create
sevk-islemleri.giden-firma-sevkleri.create
iade-islemleri.giden-depo-iadeleri.create
iade-islemleri.firma-iadeleri.create
stok-islemleri.zayiat-fisleri.create
stok-islemleri.masraf-fisleri.create
stok-islemleri.virmanlar.create
green-grocer.operations.adjustment.apply
```

## Kabul Kriterleri

- Kaydet sonrasi form kesin sonuc gelmeden kapanmaz.
- Cift tik iki POST olusturmaz.
- Timeout sonrasi yeni GUID uretilmez.
- `WaitAndCheck` durumunda create POST atilmaz.
- `RetrySameRequest` disinda otomatik POST atilmaz.
- Tam eslesmeyen veya eksik belge `Completed` sayilmaz.
- Uygulama yeniden acildiginda pending islem kaybolmaz.
- Tek pending evrak diger evraklari veya tum modulu kilitlemez.
- Iptal sonucu basarili evrak gibi gosterilmez.
- Teknik kararlar mesaj metniyle degil `recommendedAction` ile verilir.
