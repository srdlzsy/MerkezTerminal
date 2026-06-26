# FurpaMerkezApi UI API Dokumani

Bu dokuman, mevcut backend durumuna gore frontend/UI tasarimi ve entegrasyonu icin hazirlanmistir.

## Genel Bilgiler

- API JSON dondurur.
- JSON alanlari `camelCase` gelir.
- Tarihler `ISO 8601` formatindadir.
- Yetki sistemi `module > menu > action` mantigindadir.
- UI menu agaci ve buton gorunurlugu `me` cevabindan uretilmelidir.
- Tarih aralikli liste endpointlerinde `StartDate` ve `EndDate` zorunludur; `WarehouseNo` verilmezse JWT icindeki depo kullanilir.
- Development CORS originleri su an `http://localhost:5176`, `http://localhost:5173` ve `http://localhost:4200` icin aciktir.

## Home / Ortak Sikayet Oneri

Bu modul home sayfasinda kucuk bir "Sikayet / Oneri" kutusu acmak ve yonetim tarafinda gelen kayitlari rol/yetkiye gore izlemek icin eklendi.

Veri Auth DB tarafinda tutulur:

- MSSQL tablo: `feedback_items`
- Migration: `20260609134038_AddFeedbackItems`
- Kullanici iliskileri: `created_by_user_id`, `read_by_user_id`, `status_changed_by_user_id` alanlari `app_users.id` alanina baglidir
- Admin role icin migration ile varsayilan yetkiler eklenir

Temel kural:

- Home endpointleri icin sadece login olmak yeterlidir.
- Kullanici kendi sikayet/onerisini olusturur, kendi gecmisini ve ozetini gorur.
- Yonetim endpointleri icin `Administrator` rolu veya ilgili permission gerekir.
- `Administrator` rolu tum kayitlari gorur ve tum yonetim aksiyonlarini kullanir.
- `ortak-islemler.sikayet-oneri.list-all` yetkisi olan kullanici tum depolari gorur.
- `list-all` yoksa yonetim listesi kullanicinin JWT deposu ile sinirlanir.

Yetki kodlari:

- `ortak-islemler.sikayet-oneri.list`
- `ortak-islemler.sikayet-oneri.detail`
- `ortak-islemler.sikayet-oneri.update`
- `ortak-islemler.sikayet-oneri.list-all`

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
- "Gecmisim" veya detay paneli icin `GET /api/home/sikayet-oneri/benim` kullanilir.
- Yonetim ekrani menu olarak `OrtakIslemler > SikayetOneri` altinda acilabilir.
- Yonetim gridinde tip, durum, oncelik, depo, olusturan kullanici, tarih ve admin notu kolonlari yeterlidir.
- Durum degisiminde `PATCH /durum`, sadece okunduya alma icin `PATCH /okundu` kullanilmalidir.

Endpoint ozeti:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `POST /api/home/sikayet-oneri` | body | `CreateFeedbackItemHttpRequest` | `FeedbackItemDto` | login |
| `GET /api/home/sikayet-oneri/benim` | - | - | `FeedbackItemDto[]` | login |
| `GET /api/home/sikayet-oneri/ozet` | - | - | `FeedbackSummaryDto` | login |
| `GET /api/yonetim/sikayet-oneri` | query | `FeedbackManagementListHttpRequest` | `FeedbackItemDto[]` | `list` veya `list-all` veya `Administrator` |
| `GET /api/yonetim/sikayet-oneri/{id}` | path | `id: guid` | `FeedbackItemDto` | `detail` veya `Administrator` |
| `PATCH /api/yonetim/sikayet-oneri/{id}/okundu` | path | `id: guid` | `FeedbackItemDto` | `update` veya `Administrator` |
| `PATCH /api/yonetim/sikayet-oneri/{id}/durum` | body | `ChangeFeedbackStatusHttpRequest` | `FeedbackItemDto` | `update` veya `Administrator` |

Yonetim endpointleri icin alias route:

```text
/api/ortak-islemler/sikayet-oneri
/api/ortak-islemler/sikayet-oneri/{id}
/api/ortak-islemler/sikayet-oneri/{id}/okundu
/api/ortak-islemler/sikayet-oneri/{id}/durum
```

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
warehouseNo  opsiyonel; sadece canViewAll kullanicilarda tum depo filtreleme anlamlidir
startDate    opsiyonel; createdAtUtc baslangic tarihi
endDate      opsiyonel; createdAtUtc bitis tarihi, gun sonu dahil kabul edilir
take         opsiyonel; default 100, max 500
```

Kapsam:

- `Administrator` veya `list-all`: tum kayitlar uzerinden filtreleme yapar.
- Sadece `list`: backend otomatik olarak kullanicinin JWT deposuna filtreler.
- `warehouseNo` verilse bile `list-all` yoksa kullanicinin kendi depo kapsami disina cikilamaz.

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

## Mobil Offline Pilot Kurallari

Bu bolum mobil uygulamanin offline iken olusturdugu fisleri internet geldiginde guvenli sekilde backend'e gondermesi icin create retry kurallarini anlatir.

Offline create pilotu su iki create akisinda vardir:

- `POST /api/mal-kabul-islemleri/firma-mal-kabulleri`
- `POST /api/stok-islemleri/sayim-sonuclari`

Bu iki endpoint legacy UI gibi normal online da kullanilabilir. Ancak mobil uygulama offline-first calisacaksa su kurallar uygulanmalidir:

- Her yeni create denemesi icin istemci tarafinda bir `clientRequestId` uretilmelidir. Format `GUID` olmali ve ayni mantiksal fis boyunca degismemelidir.
- `clientRequestId` teknik olarak opsiyoneldir, ama offline guvenli tekrar gonderim icin pratikte zorunludur.
- Kullanici ayni fis taslagini tekrar gonderiyorsa ayni `clientRequestId` kullanilmalidir.
- Kullanici fis icerigini degistirdiyse yeni bir `clientRequestId` uretilmelidir.
- Ayni kullanici, ayni islem ve ayni `clientRequestId` kombinasyonu backend tarafinda tekil kabul edilir.
- Ayni `clientRequestId` ile ayni payload tekrar gelirse backend ayni is sonucunu donmeye calisir; boylece timeout veya kopan internet sonrasi guvenli retry yapilabilir.
- Ayni `clientRequestId` ile farkli payload gelirse endpoint `409 Conflict` doner.
- Ayni `clientRequestId` halen isleniyorsa endpoint `409 Conflict` doner.
- POST cevabi cihaza ulasmadiysa mobil uygulama once ayni `clientRequestId` ile tekrar POST deneyebilir; durum hala belirsizse ilgili `offline-sync/{clientRequestId}` endpoint'i ile durum sorgulayabilir.

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
2. `accessToken` al
3. token'i `Authorization: Bearer {token}` ile sakla/gonder
4. `GET /api/auth/me` ile kullanici, roller, permission listesi ve module-menu-action agacini al
5. sol menu ve butonlari bu cevapla ciz

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
- Yani response alanlari `accessToken`, `expiresAtUtc` ve `user` alanlaridir.
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
  "isActive": true
}
```

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

Bu modul eski `SettingsController` islevlerini yeni API mimarisine uygun olarak 4 ayri menu altinda toplar:

- `AyarIslemleri > Cihazlar`
- `AyarIslemleri > SubeAyarlari`
- `AyarIslemleri > KasaPosTerminalleri`
- `AyarIslemleri > Kasiyerler`

Veri kaynaklari:

- Furpa DB: `DeviceDetails`, `DeviceTypes`, `BranchDetails`, `CashRegistryDetails`, `Cashiers`
- Mikro write DB: `CashRegisterDetails`, `CashRegisterBranches`

Onemli alan ayrimi:

- `cashNo`: integer kasa no, eski `CashRegistryDetail.CashRegisterNo` karsiligi
- `terminalNo`: string POS terminal no, eski `CashRegisterDetail.CashRegisterNo` karsiligi
- `branchNo`: sube/depo no

Kasiyer listelerinde sifre donmez. Yeni kasiyer olusturma ve sifre sifirlama response'lari uretilen sifreyi tek seferlik `generatedPassword` alaninda dondurur.

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
```

Endpoint ozeti:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `GET /api/ayar-islemleri/cihazlar/tipler` | - | - | `DeviceTypeDto[]` | `cihazlar.list` |
| `GET /api/ayar-islemleri/cihazlar?branchNo=110` | query | `branchNo?: int` | `DeviceDto[]` | `cihazlar.list` |
| `GET /api/ayar-islemleri/cihazlar/durum?branchNo=110` | query | `branchNo?: int` | `DeviceStatusDto[]` | `cihazlar.list` |
| `GET /api/ayar-islemleri/cihazlar/subeler/{branchNo}/durum` | path | `branchNo: int` | `DeviceStatusDto[]` | `cihazlar.list` |
| `POST /api/ayar-islemleri/cihazlar` | body | `CreateDeviceHttpRequest` | `DeviceDto` | `cihazlar.create` |
| `DELETE /api/ayar-islemleri/cihazlar/{id}` | path | `id: int` | - | `cihazlar.update` |
| `GET /api/ayar-islemleri/sube-ayarlari` | - | - | `BranchDetailDto[]` | `sube-ayarlari.list` |
| `GET /api/ayar-islemleri/sube-ayarlari/{branchNo}` | path | `branchNo: int` | `BranchDetailDto` | `sube-ayarlari.detail` |
| `GET /api/ayar-islemleri/sube-ayarlari/{branchNo}/kasalar` | path | `branchNo: int` | `CashRegistryDto[]` | `sube-ayarlari.detail` |
| `POST /api/ayar-islemleri/sube-ayarlari` | body | `CreateBranchSettingsHttpRequest` | `BranchDetailDto` | `sube-ayarlari.create` |
| `PUT /api/ayar-islemleri/sube-ayarlari/{branchNo}` | body + path | `UpdateBranchSettingsHttpRequest` | `BranchDetailDto` | `sube-ayarlari.update` |
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
    "cashType": 1
  }
]
```

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
  "terminals": [
    {
      "id": 15,
      "terminalNo": "POS001",
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

Kasa no'ya bagli terminal detaylarini listeler.

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
    "state": 0,
    "filePath": "\\\\192.168.1.5\\POSKON\\MESAJ.001",
    "error": null
  }
]
```

Durum hesabi:

- Dosyanin ilk satiri `1071` icerirse `state = 0`
- Diger durumlarda `state = 1`
- Dosya yoksa veya yetki/path hatasi varsa satir `state = null`, `error = hata mesaji` ile doner

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

## GreenGrocer / Manav Yesillik Raporlari

Bu modul eski `Furpa.GreenGrocerWebUI` icindeki manav/yesillik raporlarini yeni API'ye tasir.

Yetki:

- `green-grocer.reports.list`: raporlari goruntuleme
- `green-grocer.reports.update`: manav siparisi silme

Tarih query alani:

- `date` onerilir.
- Geriye uyum icin `dateToGet` de kabul edilir.

### Genel Manav Raporu

`GET /api/green-grocer/reports/summary?date=2026-06-04`

Alias:

`GET /api/green-grocer/reports?date=2026-06-04`

Amac:

- `DEPOLAR_ARASI_SIPARISLER` kayitlarini `STOKLAR.sto_model_kodu in ('10','11','12')` filtresiyle urun/tip bazinda toplar.

Response item:

```json
{
  "typeCode": "10",
  "productCode": "016201",
  "productName": "ELMA",
  "quantity": 42.5
}
```

### Sube/Evrak Bazli Manav Raporu

`GET /api/green-grocer/reports/by-branch?date=2026-06-04`

Response:

```json
{
  "items": [
    {
      "orderDate": "2026-06-04T00:00:00",
      "branchNo": 110,
      "branchName": "KESTEL 1",
      "documentSerie": "F110",
      "documentOrderNo": 1234,
      "typeCode": "10",
      "productCode": "016201",
      "productName": "ELMA",
      "quantity": 12
    }
  ],
  "lazyBranches": [
    {
      "branchNo": 120,
      "branchName": "ORNEK SUBE",
      "regionCode": "1"
    }
  ]
}
```

### Urun Bazli Manav Raporu

`GET /api/green-grocer/reports/by-product?date=2026-06-04`

Amac:

- Urunleri toplam miktar ve sube/evrak kirilimiyle dondurur.

### Yesillik Raporu

`GET /api/green-grocer/reports/greens?date=2026-06-04`

Amac:

- Yalnizca `STOKLAR.sto_model_kodu = '12'` olan satirlari sube ve evrak bilgisiyle listeler.

### Manav Siparisi Sil

`DELETE /api/green-grocer/orders?documentSerie=F110&documentOrderNo=1234`

Opsiyonel sube filtresi:

`DELETE /api/green-grocer/orders?documentSerie=F110&documentOrderNo=1234&warehouseNo=110`

Kural:

- Sadece son 24 saat icinde olusturulan evraklar silinebilir.
- Eski WebUI'deki `TimeSpan.Hours` davranisi yerine `TotalHours` kullanilir.
- Kayit yoksa `404`, 24 saat penceresi gecmisse `409 Conflict` doner.

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
- Mobil offline fiyat okutma icin tekil `fiyat-gor` endpointleri yerine `GET /api/mobile-sync/urun-fiyat-katalogu` ile depo bazli katalog cihaza indirilmelidir.
- Mobil offline cari ve depo secimleri icin online arama endpointleri yerine `GET /api/mobile-sync/cari-katalogu` ve `GET /api/mobile-sync/depo-katalogu` kataloglari cihaza indirilmelidir.
- Mal kabul create ekranlarinda cari secimini hizlandirmak icin `urunler/{stockCode}/cari-onerileri` endpoint'i yardimci olarak kullanilabilir.

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
barcode        opsiyonel; barkod ile exact arama
stockCode      opsiyonel; stok kodu ile exact arama
stockName      opsiyonel; stok adinda contains arama, en az 2 karakter
companyCode    opsiyonel; secilen firma/cari kodu filtresi
supplierCode   opsiyonel; companyCode ile ayni filtre icin geriye uyum alias'i
take           opsiyonel; default 20, max 100
```

Kural:

- `barcode`, `stockCode`, `stockName`, `companyCode` veya `supplierCode` alanlarindan en az biri verilmelidir.
- Bos arama engellenir; cunku Mikro procedure genis fiyat/stok seti dondurebilir.
- Firma icin urun ararken UI `companyCode` gondermelidir; backend bunu Mikro procedure tarafinda `@tedarikci` filtresine baglar.
- Bu filtre Mikro'da `SATINALMA_SARTLARI.sas_cari_kod` iliskisi uzerinden calisir; yani firma ile iliskili urunler listelenir.

Response:

```json
[
  {
    "warehouseNo": 110,
    "barcode": "8690000000000",
    "stockCode": "015550",
    "stockName": "Stok Adi",
    "price": 125.5,
    "priceTypeCode": 1,
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
    "productManagerCode": "PER001"
  }
]
```

UI kullanim notu:

- Mal kabulde `isGoodsAcceptanceBlocked = true` olan urunlerde uyari gosterilebilir.
- Siparis girisinde `isOrderBlocked = true` olan urunlerde uyari veya engel uygulanabilir.
- Satis/sevk formlarinda `isSalesBlocked = true` olan urunlerde uyari gosterilebilir.

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
barcode        opsiyonel; barkod ile exact arama
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

Mobil uygulamada barkod okutunca tek cevapta urun bulundu mu, stok kodu, koli barkodu, koli ici adet ve secili ekranda kullanilabilirlik bilgisi almak icin:

`GET /api/arama-islemleri/barkodlar/8690000000000/cozumle?warehouseNo=110&screenCode=firma-mal-kabulleri`

Query:

```text
warehouseNo    opsiyonel; verilmezse JWT icindeki depo kullanilir
screenCode     opsiyonel; ekran baglamini verir, kullanilabilirlik yorumu icin kullanilir
```

Desteklenen tipik `screenCode` degerleri:

- `firma-mal-kabulleri`
- `depo-mal-kabulleri`
- `sayim-sonuclari`
- `verilen-firma-siparisleri`
- `verilen-depo-siparisleri`
- `giden-firma-sevkleri`
- `giden-depolar-arasi-sevkler`
- `firma-iadeleri`
- `giden-depo-iadeleri`

Onemli not:

- Endpoint once `BARKOD_TANIMLARI` tablosunda exact barkod arar.
- Barkod bulunamazsa barkodu stok kodu veya global urun numarasi gibi degerlerle eslestirmeyi dener.
- `resolutionSource` alani eslestirmenin `barcode`, `stock-code`, `gtin` veya `not-found` kaynakli oldugunu anlatir.
- `caseBarcode` ve `unitsPerCase` alanlari koli/master barkod tespit edilebilirse dolar.
- `defaultSupplierCode` ve `defaultSupplierName` alanlari stok kartindaki varsayilan tedarikci bilgisini dondurur.
- `isUsableInScreen` ve `usabilityReason` alanlari secilen ekran icin pratik karar vermeyi kolaylastirir.

Response:

```json
{
  "isFound": true,
  "barcode": "8690000000000",
  "warehouseNo": 110,
  "screenCode": "firma-mal-kabulleri",
  "resolutionSource": "barcode",
  "stockCode": "015550",
  "stockName": "Stok Adi",
  "matchedBarcode": "8690000000000",
  "primaryBarcode": "8690000000000",
  "caseBarcode": "18690000000007",
  "unitsPerCase": 12,
  "matchedUnitPointer": 1,
  "matchedUnitName": "AD",
  "matchedUnitMultiplier": 1,
  "isBlocked": false,
  "isSalesBlocked": false,
  "isOrderBlocked": false,
  "isGoodsAcceptanceBlocked": false,
  "isUsableInScreen": true,
  "usabilityReason": "Urun mal kabul ekraninda kullanilabilir.",
  "defaultSupplierCode": "120.01.03106",
  "defaultSupplierName": "ORNEK TEDARIKCI"
}
```

Bulunamayan barkod davranisi:

- Endpoint `200 OK` ile doner, fakat `isFound = false` olur.
- Bu durumda UI hata modal'i yerine kullaniciya "urun bulunamadi" veya "barkod tanimsiz" gibi hizli bir mesaj gosterebilir.

UI kullanim notu:

- Kamera ile tek barkod okutulan ekranlarda once bu endpoint cagrilmalidir.
- `isFound = true` ve `isUsableInScreen = false` ise UI urunu satira eklemeden once blok nedenini gostermelidir.
- `caseBarcode` doluysa koli barkodu tekrar okutma, koli bozma veya alternatif birim secimi gibi kisayollar acilabilir.

### Urunden Cari Onerileri

Secili urun icin varsayilan tedarikciyi ve yakin gecmiste ayni urunle hareket gormus cari onerilerini getirmek icin:

`GET /api/arama-islemleri/urunler/015550/cari-onerileri?take=10`

Query:

```text
take    opsiyonel; default 10, max 25
```

Onemli not:

- Endpoint once stok kartini bulur; bulunamazsa `isProductFound = false` ve bos liste doner.
- Oneriler iki kaynaktan uretilir:
  - `varsayilan-tedarikci`: stok kartindaki `sto_sat_cari_kod`
  - `stok-hareketleri`: urunun bagli oldugu yakin tarihli stok hareketleri
- Ayni cari iki kaynaktan da gelirse `sources` alaninda iki kaynak birlikte doner.
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

Arama Islemleri altinda menu olarak gosterilebilecek hizli cari/firma bulma ekranidir. Backend once barkodu stokla eslestirir, sonra stok kartindaki varsayilan tedarikciyi ve yakin gecmis stok hareketlerinden cari onerilerini doner.

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

### Cari Ara

`GET /api/arama-islemleri/cariler?searchText=market&take=20`

Query:

```text
searchText   zorunlu, en az 2 karakter
take         opsiyonel; default 20, max 100
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
    "representativeCode": "TEM001",
    "representativeName": "Ad Soyad",
    "invoiceAddressNo": 1,
    "shippingAddressNo": 1,
    "isLocked": false,
    "isClosed": false
  }
]
```

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
- `documentSerie` backend tarafinda `F{loginKullaniciDepoNo}` olarak uretilir.
- `documentOrderNo` ayni seri icin test DB'deki mevcut maksimum sira okunarak uretilir; ilk evrak `0`, sonraki evraklar `1, 2...` seklinde gider.
- `inWarehouseNo` JWT icindeki kullanici deposundan gelir; body icinde gonderilmez.
- `outWarehouseNo` siparis verilen/karsi depo numarasidir.

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
- `documentSerie` backend tarafinda `F{loginKullaniciDepoNo}` olarak uretilir.
- `documentOrderNo` ayni seri/tip/cins icin write DB'deki maksimum sira okunarak uretilir; ilk evrak `0`, sonraki evraklar `1, 2...` seklinde gider.
- `warehouseNo` JWT icindeki kullanici deposundan gelir; body icinde gonderilmez.
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
      "projectCode": ""
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
  "warehouseOrderNo": "D110.1915",
  "lineCount": 8,
  "totalQuantity": 250
}
```

UI kullanim notlari:

- Liste ekraninda `documentSerie`, `documentOrderNo`, `sourceWarehouse`, `targetWarehouse`, `shippingState`, `plaque`, `driverNameSurname`, `lineCount`, `totalQuantity` yeterlidir
- `shippingState = 1` ise sevk hedef depoya ulasmis kabul edilebilir; diger durumlar icin operasyonel isimlendirme UI tarafinda netlestirilebilir
- `warehouseOrderNo` varsa sevkin hangi depo siparisine bagli oldugunu gostermek icin kullanilabilir
- Mal kabul satir eslestirmesi icin detay response icindeki `items[].movementGuid` kullanilmalidir; sadece stok kodu ile eslestirme ayni stoktan birden fazla satir oldugunda hatali olabilir
- Plaka, sofor adi ve sofor TCKN create ekraninda sorulmaz; kullanici bu bilgileri sadece e-irsaliye gonderirken zorunlu modal/form icinde girer

### Depolar Arasi Giden Sevk Olustur

Siparissiz sevk:

`POST /api/sevk-islemleri/depolar-arasi-sevkler/giden`

Geriye uyum icin root route da ayni create gibi calisir:

`POST /api/sevk-islemleri/depolar-arasi-sevkler`

Yetki:

- `sevk-islemleri.giden-depolar-arasi-sevkler.create`

Onemli not:

- Bu endpoint EF Core uzerinden ayri `MikroWriteDbContext` ile yazma yapar.
- Su an write hedefi canli `MikroConnection` degil; `MikroWriteConnection` yoksa `testMikroConnection` kullanilir.
- `STOK_HAREKETLERI` tablosuna `sth_evraktip = 17`, `sth_tip = 2`, `sth_cins = 6` olarak depolar arasi sevk yazar.
- `sourceWarehouseNo` JWT icindeki kullanici deposundan gelir; body icinde gonderilmez.
- `targetWarehouseNo` UI'da secilen hedef depodur ve `sth_nakliyedeposu` alanina yazilir.
- `transitWarehouseNo` verilmezse `60` kullanilir ve `sth_giris_depo_no` alanina yazilir.
- `documentSerie` backend tarafinda `F{loginKullaniciDepoNo}` olarak uretilir.
- `documentOrderNo` ayni seri ve `sth_evraktip = 17` icin write DB'deki maksimum sira okunarak uretilir.
- Satirda `warehouseOrderLineGuid` verilirse `STOK_HAREKETLERI_EK.sth_subesip_uid` ile depo siparis satirina baglanir.
- `warehouseOrderLineGuid` verilmezse satir siparissiz sevk olarak olusur.
- Siparise bagli satirda stok kodu, kaynak depo, hedef depo ve kalan miktar kontrol edilir.
- Plaka, sofor adi ve TCKN bu create request'inde gonderilmez. Bu alanlar e-irsaliye gonderim request'inde zorunludur.

Siparissiz request:

```json
{
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

### Depolar Arasi Giden Sevki E-Irsaliyeye Cevir

Detay ekranindaki mevcut evragi e-irsaliye olarak gondermek icin:

`POST /api/sevk-islemleri/depolar-arasi-sevkler/giden/F110/3694/e-irsaliye?warehouseNo=110`

Geriye uyum icin root route da ayni islem gibi calisir:

`POST /api/sevk-islemleri/depolar-arasi-sevkler/F110/3694/e-irsaliye?warehouseNo=110`

Yetki:

- `sevk-islemleri.giden-depolar-arasi-sevkler.detail`

Onemli not:

- Bu endpoint yeni evrak kesmez; mevcut sevk kaydini okuyup Uyumsoft e-irsaliye servisine yollar.
- UI tarafinda beklenen akis: kullanici once detay ekranini acar, sonra `E-Irsaliyeye Cevir` butonuna basar ve acilan formda plaka, sofor adi soyadi ve sofor TCKN girer.
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

- Bu endpoint EF Core uzerinden ayri `MikroWriteDbContext` ile yazma yapar.
- `STOK_HAREKETLERI` tablosuna `sth_evraktip = 1`, `sth_tip = 1`, `sth_normal_iade = 0` olarak firma giden sevki yazar.
- `warehouseNo` JWT icindeki kullanici deposundan gelir; body icinde gonderilmez.
- `customerCode` zorunludur ve write DB'de `CARI_HESAPLAR` icinde kontrol edilir.
- `documentSerie` backend tarafinda `F{loginKullaniciDepoNo}` olarak uretilir.
- `documentOrderNo` ayni seri, evrak tipi ve iade tipi icin write DB'deki mevcut maksimum sira okunarak uretilir; ilk evrak `0`, sonraki evraklar `1, 2...` seklinde gider.
- Plaka, sofor adi ve TCKN bu create request'inde gonderilmez. Bu alanlar e-irsaliye gonderim request'inde zorunludur.
- Satir bazinda `unitPrice` verilirse `totalAmount` `quantity * unitPrice` toplamindan olusur; verilmezse `0` olur.

Request:

```json
{
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
- Plaka, sofor adi soyadi ve sofor TCKN body'den alinir; basarili gonderimden sonra bu bilgiler ilgili Mikro hareket satirlarina yazilmaya calisilir.

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
- `warehouseNo` body icinden alinmaz; JWT icindeki kullanici deposu kullanilir.
- Bekleyen kabul icin hareketlerde `sth_nakliyedeposu = kullaniciDeposu` ve `sth_nakliyedurumu != 1` olmalidir.
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

### Firma Mal Kabul Icin E-Irsaliye ETTN Cozumleme

Kullanici tedarikci irsaliyesinin QR bilgisinden ETTN/UUID elde ettiyse resmi e-irsaliye ust bilgi, kalemler ve olasi cari eslesmelerini almak icin:

`GET /api/mal-kabul-islemleri/firma-mal-kabulleri/e-irsaliye/ettn/3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111?warehouseNo=110`

Yetki:

- `mal-kabul-islemleri.firma-mal-kabulleri.create`

Onemli not:

- Bu endpoint create request'i yerine gecmez; sadece create ekranina on bilgi ve on dolum verir.
- Uyumsoft gelen e-irsaliye baslik bilgileri `sender`, `receiver`, `despatchNumber`, `issueDate`, `notes` alanlarinda toplanir.
- `suggestedCustomers` alani gonderici firma VKN/TCKN ve unvanina gore Mikro cari adaylari dondurur.
- `primaryCustomerSuggestion` alanini UI varsayilan cari adayi gibi kullanabilir.
- Kalemlerde stok kodlari birebir tutusmasa bile ust bilgi yine de kullanilabilir; bu yuzden `matchedLineCount = 0` olsa bile `isFound = true` create ekrani icin degerlidir.
- Ic stok eslesmesi bulunan satirlarda `internalStockCode`, `internalStockName` ve `matchReason` dolar; bulunamayan satirlar UI'da manuel eslestirme icin ayrica gosterilmelidir.

Response:

```json
{
  "isFound": true,
  "warehouseNo": 110,
  "receivingContext": "firma-mal-kabulleri",
  "ettn": "3fd0e4f4-87a2-43f2-b5ca-f2a4fd778111",
  "despatchNumber": "IRS2026000001234",
  "issueDate": "2026-05-06T00:00:00",
  "actualDespatchDate": "2026-05-06T00:00:00",
  "profileId": "TEMELIRSALIYE",
  "despatchAdviceTypeCode": "SEVK",
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
      "canUseForGoodsAcceptance": true
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
      "canUseForGoodsAcceptance": false
    }
  ]
}
```

### Firma Mal Kabul Olustur

Secili cariden gelen urunler icin `STOK_HAREKETLERI` tablosuna yeni firma mal kabul hareketi yazar.

`POST /api/mal-kabul-islemleri/firma-mal-kabulleri`

Alias:

`POST /api/mal-kabul-islemleri/mal-kabuller/firma`

Yetki:

- `mal-kabul-islemleri.firma-mal-kabulleri.create`

Onemli not:

- Tek endpoint hem siparisli hem siparissiz mal kabul icin kullanilir.
- `warehouseNo` body icinden alinmaz; JWT icindeki kullanici deposu kullanilir.
- Mobil offline pilotta request'e `clientRequestId` eklenmelidir.
- Backend `sth_evraktip = 13`, `sth_tip = 0`, `sth_normal_iade = 0` olarak yeni giris hareketi olusturur.
- Mal kabul giris hareketinde `sth_miktar` irsaliye/gelen miktari olan `dispatchQuantity` ile yazilir.
- Fiili/net kabul miktari `acceptedQuantity` alanidir. UI farkli kabul durumunda `dispatchQuantity` ve `acceptedQuantity` alanlarini ayri gondermelidir.
- Eski uyumluluk icin `quantity` hala desteklenir; UI sadece `quantity` gonderirse backend bunu hem `dispatchQuantity` hem `acceptedQuantity` gibi yorumlar.
- `acceptedQuantity`, `dispatchQuantity` degerinden buyuk olamaz. `dispatchQuantity` sifirdan buyuk olmali, `acceptedQuantity` sifir olabilir.
- `autoCreateReturnForPartialAcceptance = true` varsayilandir. `acceptedQuantity < dispatchQuantity` ise backend ayni transaction icinde fark kadar firma iade evragi olusturur.
- Otomatik firma iade hareketi `sth_evraktip = 1`, `sth_tip = 1`, `sth_normal_iade = 1` olarak yazilir; seri `F{warehouseNo}` seklinde uretilir ve sira Mikro'daki sonraki uygun sira olur.
- Mikro net stok etkisi: `dispatchQuantity` kadar firma mal kabul girisi, fark kadar firma iade cikisi. Ornek: 10 geldi, 8 kabul edildi ise +10 mal kabul ve -2 firma iade yazilir; net stok 8 olur.
- Otomatik firma iade icin e-irsaliye gonderimi yapilmaz. Response'ta iade evrak link/status bilgisi doner; kullanici sonradan `POST /api/iade-islemleri/firma-iadeleri/{seri}/{sira}/e-irsaliye` ile gondermelidir.
- `autoCreateReturnForPartialAcceptance = false` gonderilirse fark icin iade evragi olusmaz; satir `returnStatus = IadeBekliyor` olarak doner ve UI bunu manuel cozum bekleyen fark gibi gostermelidir.
- Satirda `orderGuid` doluysa `sth_sip_uid = orderGuid` yazilir ve `SIPARISLER.sip_teslim_miktar` mal kabul hareket miktari, yani `dispatchQuantity`, kadar artirilir.
- Satirda `orderGuid` bos veya `null` ise `sth_sip_uid = Guid.Empty` yazilir ve siparis tablosuna dokunulmaz.
- Siparis kalanindan fazla kabul varsayilan olarak engellenir. `allowOrderOverReceiving = true` gonderilirse kalan kadar siparisli, fazla kisim siparissiz hareket olarak bolunur.
- `documentNo` opsiyoneldir. E-belge/e-irsaliye no varsa tam `seri + 9 haneli sayisal sira` formatinda gonderilebilir.
- Ornek tam `documentNo` degerleri: `ST12026000002395`, `C682026000003472`, `FRM2026600059281`, `OY32026000000162`
- Tam formatta `documentNo` gelirse `documentSerie` son 9 hane atilarak, `documentOrderNo` son 9 hane sayi olarak okunarak uretilir.
- `documentNo` bos gelirse backend cari unvanindan seri uretir ve ayni depo/seri icin siradaki `documentOrderNo` degerini verir.
- `documentNo` `ABC`, `ULK`, `FIRMA` gibi harf iceren ve tam format olmayan kisa bir deger gelirse backend bunu seri/prefix kabul eder, sadece harf-rakam karakterlerini kullanir ve siradaki sira numarasini uretir.
- `documentNo` bos veya sadece sayisal bir degerse backend seri icin cari unvanina duser.
- Response'taki `documentNo`, uretilen nihai `documentSerie + 9 haneli documentOrderNo` degeridir.
- Ayni depo icinde ayni `documentSerie + documentOrderNo` kombinasyonu tekrar kullanilamaz.
- Mobil retry icin backend `clientRequestId` izini `STOK_HAREKETLERI.sth_eticaret_kanal_kodu` alanina yazar ve ayni istek tekrar geldiginde bu iz uzerinden sonucu toparlayabilir.
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
- Kullanici QR'dan ETTN okutursa UI ilk adimda `GET /api/mal-kabul-islemleri/firma-mal-kabulleri/e-irsaliye/ettn/{ettn}` cagirabilir.
- Bu response'tan `primaryCustomerSuggestion` varsa cari alani icin varsayilan onerilir; `despatchNumber` ve `issueDate` alanlari `documentNo` ve `documentDate` icin on dolum adayi olarak kullanilabilir.
- `lines[].isMatched = true` olan satirlar tek tikla create satirina aktarilabilir; `isMatched = false` olanlar ayrica "manuel eslestir" listesine dusurulebilir.
- `DocumentNo` artik zorunlu degildir. E-belge/e-irsaliye no varsa UI tam `seri + 9 haneli sayisal sira` formatinda gonderebilir; yoksa bos gonderebilir.
- Kullanici e-belge olmayan firmalarda isterse `ABC`, `ULK`, cari unvanin ilk 2-3 harfi gibi harf iceren bir prefix girebilir. Backend bu prefix'ten seri uretip siradaki sira numarasini verir.
- UI kayit sonrasi ekranda mutlaka response'taki `documentNo`, `documentSerie` ve `documentOrderNo` alanlarini esas almalidir; bos veya prefix request'in kendisini evrak kimligi gibi saklamamalidir.
- Cari secildikten sonra kullanici manuel satir ekleyebilir. Manuel satirlarda `orderGuid = null` gonderilir.
- `Siparis Bagla` aksiyonunda UI secili carinin acik verilen firma siparislerini `GET /api/siparis-islemleri/verilen-firma-siparisleri?WarehouseNo=...&CustomerCode=...&OnlyOpen=true` ile listeler.
- Kullanici bir siparis secerse siparis detayi `GET /api/siparis-islemleri/verilen-firma-siparisleri/{seri}/{sira}?warehouseNo=...` ile acilir ve detaydaki `items[].orderGuid` mal kabul satirina tasinir.
- Siparisten veya e-irsaliyeden gelen satirda UI resmi/irsaliye miktarini `dispatchQuantity`, fiili sayilan miktari `acceptedQuantity` olarak tutmalidir. Normal durumda iki alan esit onerilir.
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
- `CARI_HESAP_HAREKETLERI` belgeleri
- `STOKLAR` stok kartlari
- `STOK_DEPO_DETAYLARI` depo bazli stok karti ayarlari
- `STOK_SATIS_FIYAT_LISTELERI` depo bazli stok satis fiyatlari

Menu:

- Module: `DuzeltmeIslemleri`
- Menu: `MikroEvrakDuzenleme`
- Route kok: `/api/duzeltme-islemleri/mikro-evrak-duzenleme`

Yetki kodlari:

- `duzeltme-islemleri.mikro-evrak-duzenleme.list`
- `duzeltme-islemleri.mikro-evrak-duzenleme.detail`
- `duzeltme-islemleri.mikro-evrak-duzenleme.update`

Genel kurallar:

- Detay endpointleri Mikro read connection uzerinden okur; guncelleme endpointleri Mikro write connection uzerinden yazar.
- Stok ve cari hareket belgelerinde `documentSerie` ve `documentOrderNo` zorunludur.
- `documentType`, `movementType`, `movementKind`, `normalReturn` filtreleri opsiyoneldir. Seri-sira birden fazla evrak tipi/cins/iade kombinasyonuna denk gelirse backend `409 Conflict` doner; UI kullaniciya "evrak tipi/cins/iade filtresi ile daraltin" mesaji gostermelidir.
- Satir guncellemeleri `movementGuid` ile yapilir. UI detay response'undaki `lines[].movementGuid` degerini satir modelinde saklamalidir.
- Request body'de `null` gelen alanlar degismez. Bos string gonderilirse ilgili metin alani bosaltma istegi olarak islenir.
- Kayitlarda Mikro audit alanlari guncellenir: `lastup_user`, `lastup_date`, `degisti`.
- Bu modul delete veya yeni evrak olusturma yapmaz; sadece whitelist icindeki alanlari gunceller.
- Stok satis fiyati endpoint'i istisna olarak eksik `STOK_SATIS_FIYAT_LISTELERI` kaydini olusturabilir.
- Satis fiyati kaydi `stockCode + priceListNo + warehouseNo + unitPointer + paymentPlanNo` birlesimiyle bulunur. Kayit varsa guncellenir, yoksa olusturulur.
- Satis fiyati upsert islemi `STOK_FIYAT_DEGISIKLIKLERI` tablosunda sentetik fiyat degisiklik evraki olusturmaz.
- `PUT /stok-kartlari/{stockCode}` global stok kartini degistirir ve tum depolari etkileyebilir.
- Sadece belirli bir depoyu kapatmak/acmak icin `/stok-kartlari/{stockCode}/depolar/{warehouseNo}` endpoint'i kullanilmalidir.

Endpoint ozeti:

| Endpoint | Request kaynagi | Request modeli | Response | Yetki |
|---|---|---|---|---|
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari` | query | `StockCardSearchHttpRequest` | `StockCardListItemDto[]` | `list` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}` | path | `stockCode` | `StockCardDetailDto` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}` | path + body | `StockCardPatchHttpRequest` | `StockCardUpdateResponse` | `update` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/depolar` | path + query | `warehouseNo?: int` | `StockCardWarehouseSettingsDto[]` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/depolar/{warehouseNo}` | path + body | `StockCardWarehousePatchHttpRequest` | `StockCardWarehouseUpdateResponse` | `update` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/satis-fiyatlari` | path + query | `warehouseNo?: int` | `StockSalesPriceDto[]` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/satis-fiyatlari/{warehouseNo}` | path + body | `StockSalesPriceUpsertHttpRequest` | `StockSalesPriceUpsertResponse` | `update` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-hareketleri` | query | `StockMovementDocumentLookupHttpRequest` | `StockMovementDocumentDto` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-hareketleri` | body | `UpdateStockMovementDocumentHttpRequest` | `StockMovementDocumentUpdateResponse` | `update` |
| `GET /api/duzeltme-islemleri/mikro-evrak-duzenleme/cari-hareketleri` | query | `CustomerMovementDocumentLookupHttpRequest` | `CustomerMovementDocumentDto` | `detail` |
| `PUT /api/duzeltme-islemleri/mikro-evrak-duzenleme/cari-hareketleri` | body | `UpdateCustomerMovementDocumentHttpRequest` | `CustomerMovementDocumentUpdateResponse` | `update` |

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

- `movementDate`, `documentDate`, `documentNo`, `customerCode`
- `inputWarehouseNo`, `outputWarehouseNo`, `shippingWarehouseNo`
- `description`, `movementGroupCode1`, `movementGroupCode2`, `movementGroupCode3`
- `customerResponsibilityCenter`, `stockResponsibilityCenter`, `projectCode`

Guncellenebilir satir alanlari:

- `rowNo`, `stockCode`, `unitPointer`, `quantity`, `secondaryQuantity`, `amount`
- `discount1..discount6`, `expense1..expense4`, `taxPointer`, `taxAmount`
- `netWeight`, `grossWeight`, `description`, `partyCode`, `lotNo`, `projectCode`
- `customerResponsibilityCenter`, `stockResponsibilityCenter`, `inputWarehouseNo`, `outputWarehouseNo`

Response `StockMovementDocumentUpdateResponse` doner; `document` alaninda kaydin guncel hali bulunur.

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

UI is akisi onerisi:

1. Kullanici evrak tipini secer: Stok Hareketi, Cari Hareketi veya Stok Karti.
2. Stok/cari hareketinde seri-sira girilir; evrak tipi/cins/iade alanlari varsa query'e eklenir.
3. Detay response'u geldikten sonra UI `movementGuid` alanlarini satir gridinde gizli anahtar olarak saklar.
4. Kullanici sadece degisen alanlari gonderir; degismeyen alanlar `null` veya body disinda birakilir.
5. `409 Conflict` gelirse filtreleri daraltma mesaji gosterilir.
6. Basarili `PUT` response'u guncel belge/kart halini dondurdugu icin UI gridini bu response ile yeniler.

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

- `warehouseNo` body icinden alinmaz; JWT icindeki kullanici deposu kullanilir
- backend `STOK_HAREKETLERI` tablosuna `sth_evraktip = 0`, `sth_tip = 1`, `sth_normal_iade = 0`, `sth_cins = 4` olarak kayit yazar
- `sth_cari_kodu` bos yazilir; bu fislerde cari baglantisi yoktur
- `creator` ve `acceptor` alanlari sirasiyla `sth_HareketGrupKodu1` ve `sth_HareketGrupKodu2` kolonlarina yazilir
- `documentSerie` backend tarafinda `F{loginKullaniciDepoNo}` olarak uretilir
- `documentOrderNo` ayni seri ve zayiat fis turu icin write DB'deki mevcut maksimum sira okunarak uretilir
- `totalAmount` su an satir tutarlari `0` yazildigi icin `0` doner

Request:

```json
{
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

- `warehouseNo` body icinden alinmaz; JWT icindeki kullanici deposu kullanilir
- backend `STOK_HAREKETLERI` tablosuna `sth_evraktip = 0`, `sth_tip = 1`, `sth_normal_iade = 0`, `sth_cins = 5` olarak kayit yazar
- `sth_isemri_gider_kodu` alanina sabit olarak `0032` yazilir
- `sth_cari_kodu` bos yazilir; bu fislerde cari baglantisi yoktur
- `creator` ve `acceptor` alanlari sirasiyla `sth_HareketGrupKodu1` ve `sth_HareketGrupKodu2` kolonlarina yazilir
- `documentSerie` backend tarafinda `F{loginKullaniciDepoNo}` olarak uretilir
- `documentOrderNo` ayni seri ve masraf fis turu icin write DB'deki mevcut maksimum sira okunarak uretilir
- `totalAmount` su an satir tutarlari `0` yazildigi icin `0` doner

Request:

```json
{
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

- `warehouseNo` body icinden alinmaz; JWT icindeki kullanici deposu kullanilir
- Mobil offline pilotta request'e `clientRequestId` eklenmelidir.
- backend `SAYIM_SONUCLARI` tablosuna yeni satirlar yazar
- `documentNo` ayni depo icin `sym_evrakno` maksimum degerinin bir fazlasi olarak uretilir
- `name` alani `sym_parti_kodu` kolonuna yazilir
- satirda `barcode` bos gelirse backend `BARKOD_TANIMLARI` tablosundan stok koduna gore barkod bulmaya calisir
- eski yapiya gore `sym_fileid = 28`, `sym_create_user = 39`, `sym_lastup_user = 39` degerleri kullanilir
- Mobil retry icin backend `clientRequestId` izini `SAYIM_SONUCLARI.sym_serino` alanina yazar ve ayni istek tekrar geldiginde bu iz uzerinden sonucu toparlayabilir.
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

Belirli bir tarih icin kullanicinin deposuna ait tag/view kayitlarini getirir.

`GET /api/kasa-islemleri/etiket-belgeleri/etiketler?dateToGet=2026-04-24`

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
- sadece Mikro `STOKLAR.sto_model_kodu` degeri `10`, `11`, `12` olan stoklar doner
- `salesPrice` alani Mikro `dbo.fn_StokSatisFiyati(stockCode, '1', branchNo, '1')` fonksiyonundan gelir
- `dateToGet` verilirse tarih filtresi secilen gunun tamamini kapsar; verilmezse `ShippingDate` son 1 ay ile sinirlanir
- liste `ShippingDate desc` siralanir
- menu permission kodu `kasa-islemleri.manav-kunye-etiket-yazdirma.list`; endpoint anonim oldugu icin API cagrisi token istemez

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

### Fiyati Degisen Etiket Urunleri

Belirli bir zaman bilgisinden sonra fiyati degisen ve etikete uygun urunleri getirir.

`GET /api/kasa-islemleri/etiket-belgeleri/fiyati-degisen-urunler?dateTimeFilter=24.04.2026%2008:00:00`

Uyumluluk icin eski route alias'i da desteklenir:

`GET /api/kasa-islemleri/etiket-belgeleri/get-by-date-for-label?dateTimeFilter=24.04.2026%2008:00:00`

Yetki:

- `kasa-islemleri.etiket-belgeleri.list`

Not:

- `warehouseNo` query ile alinmaz; dogrudan JWT icindeki kullanici deposu kullanilir
- `dateTimeFilter` formati `dd.MM.yyyy HH:mm:ss` olmalidir
- response modeli `LabelPriceChangedProductDto` doner
- veri Mikro tarafindaki urun, fiyat degisikligi, fiyat listesi ve barkod tablolarindan okunur

Response:

```json
[
  {
    "productCode": "015550",
    "productName": "URUN ADI",
    "pluNo": 15550,
    "alternativeUnitName": "KOLI",
    "barcode": "8690000000012",
    "isDomestic": 1,
    "oldPrice": 119.9,
    "origin": "TR",
    "price": 125.5,
    "priceChangeDate": "24.04.2026 08:15",
    "unitPriceFactor": 12.55,
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

- `warehouseNo` body icinde gonderilmez; JWT icindeki kullanici deposu kullanilir
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
- bu endpoint Mikro veritabaninda sadece SELECT yapar; insert/update/delete yoktur

### Virman Olustur

Secili kullanici deposu icin yeni virman evragi yazar.

`POST /api/stok-islemleri/virmanlar`

Yetki:

- `stok-islemleri.virmanlar.create`

Onemli not:

- `warehouseNo` body icinden alinmaz; JWT icindeki kullanici deposu kullanilir
- backend `STOK_HAREKETLERI` tablosuna `sth_evraktip = 6`, `sth_normal_iade = 0`, `sth_cins = 3` olacak sekilde kayit yazar
- `movementType` alaninin karsiligi satir bazinda `sth_tip` kolonuna yazilir; `2` gonderilirse backend Mikro uyumu icin satiri `1` cikis ve `0` giris olarak iki stok hareketine acar
- eski yapiya uygun olarak `sth_giris_depo_no` ve `sth_cikis_depo_no` ayni kullanici deposuna yazilir
- eski yapiya uygun olarak `sth_fiyat_liste_no = -1` ve `sth_teslim_tarihi = 1900-01-01` degerleri kullanilir
- `documentSerie` backend tarafinda `F{loginKullaniciDepoNo}` olarak uretilir
- `documentOrderNo` ayni seri ve virman turu icin write DB'deki mevcut maksimum sira okunarak uretilir
- `totalAmount` su an satir tutarlari `0` yazildigi icin `0` doner

Request:

```json
{
  "movementDate": "2026-04-21",
  "documentDate": "2026-04-21",
  "documentNo": "",
  "description": "Reyon duzenleme virmani",
  "lines": [
    {
      "stockCode": "015792",
      "movementType": 2,
      "quantity": 3,
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
  "documentOrderNo": 15,
  "movementDate": "2026-04-21T00:00:00",
  "documentDate": "2026-04-21T00:00:00",
  "documentNo": "",
  "warehouseNo": 110,
  "movementTypes": [0, 1],
  "lineCount": 2,
  "totalQuantity": 6,
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
    "movementTypes": [2],
    "description": "Reyon duzenleme virmani",
    "lineCount": 1,
    "totalQuantity": 3,
    "totalAmount": 0
  },
  "items": [
    {
      "rowNo": 0,
      "stockCode": "015792",
      "stockName": "URUN ADI",
      "unitName": "ADET",
      "unitPointer": 1,
      "movementType": 2,
      "quantity": 3,
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

- Bu endpoint EF Core uzerinden ayri `MikroWriteDbContext` ile yazma yapar.
- `STOK_HAREKETLERI` tablosuna `sth_evraktip = 17`, `sth_tip = 2`, `sth_cins = 6`, `sth_normal_iade = 1` olarak depo iadesi yazar.
- `sourceWarehouseNo` JWT icindeki kullanici deposundan gelir; body icinde gonderilmez.
- `targetWarehouseNo` iadenin donecegi/hedef depodur ve `sth_nakliyedeposu` alanina yazilir.
- `transitWarehouseNo` verilmezse `60` kullanilir ve `sth_giris_depo_no` alanina yazilir.
- `documentSerie` backend tarafinda `F{loginKullaniciDepoNo}` olarak uretilir.
- `documentOrderNo` ayni seri, evrak tipi ve iade tipi icin write DB'deki mevcut maksimum sira okunarak uretilir.
- Depolar arasi sevkten farki: `warehouseOrderLineGuid` yoktur, siparis baglama yapilmaz.
- Plaka, sofor adi ve TCKN bu create request'inde gonderilmez. Bu alanlar e-irsaliye gonderim request'inde zorunludur.

Request:

```json
{
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
- `warehouseNo` JWT icindeki kullanici deposundan gelir; body icinde gonderilmez.
- `customerCode` zorunludur ve write DB'de `CARI_HESAPLAR` icinde kontrol edilir.
- `documentSerie` backend tarafinda `F{loginKullaniciDepoNo}` olarak uretilir.
- `documentOrderNo` ayni seri, evrak tipi ve iade tipi icin write DB'deki mevcut maksimum sira okunarak uretilir; ilk evrak `0`, sonraki evraklar `1, 2...` seklinde gider.
- Plaka, sofor adi ve TCKN bu create request'inde gonderilmez. Bu alanlar e-irsaliye gonderim request'inde zorunludur.
- Request/response modeli firma giden sevk create ile aynidir; tek fark kaydin `returnType = 1` olarak yazilmasidir.

Request:

```json
{
  "customerCode": "120.01.001",
  "movementDate": "2026-04-17",
  "documentDate": "2026-04-17",
  "documentNo": "IAD-0001",
  "description": "",
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

Dort e-irsaliye gonderme endpointi de ayni request body modelini bekler ve ayni response modelini doner. `plaque`, `driverNameSurname` ve `driverTckn` zorunludur; UI bu alanlari sevk/iade create ekraninda degil, e-irsaliye gonderme aninda almalidir.

Request:

```json
{
  "plaque": "16 ABC 123",
  "driverNameSurname": "Ad Soyad",
  "driverTckn": "11111111111"
}
```

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

## Rapor Islemleri

### Satis Analizleri

Eski `Furpa.SalesMvcCoreUI` dashboard tarafindaki ciro disi raporlar bu API modulunde toplandi. Tum endpointler `GET` calisir, query tarafinda ortak `WarehouseOrderDateRangeHttpRequest` modelini kullanir.

Temel route:

- `api/rapor-islemleri/satis-analizleri`

Yetki kodu:

- `rapor-islemleri.satis-analizleri.list`

Request query alanlari:

```text
startDate    zorunlu, ISO tarih
endDate      zorunlu, ISO tarih
warehouseNo  opsiyonel
```

Not:

- `warehouseNo` verilirse tek sube filtrelenir.
- `warehouseNo` verilmezse tum subeler icin rapor doner.
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
- `skipExisting=true` iken duplicate kontrolu `Sube + KasaNo + FisNo + BelgeTuru + Tarih` alanlariyla yapilir
- `dryRun=true` import dosyalarini parse eder, barkod lookup ve hata/uyari listesi uretir, staging'e yazmaz
- barkod lookup Mikro barkod tanimlarindan urun kodu bulmaya calisir; bulunamayan barkodlar response `warnings` icinde doner
- HR import normal kasa hareketlerini, IP import iptal belgelerini staging'e alir
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

UI beklentisi:

- ekran tek menu olarak acilabilir; `Import`, `Rapor`, `Mikro Aktarim` sekmeleri yeterlidir
- ekran acilisinda `subeler`, sube secilince `subeler/{branchNo}/kasalar` cagrilmalidir
- import dialogunda tarih araligi zorunlu, sube/kasa filtreleri opsiyonel olmalidir
- `dryRun` bir onizleme modu gibi sunulmalidir; sonuc adetleri ve `warnings/errors` satir bazli gosterilmelidir
- `skipExisting=true` varsayilani korunmalidir; tekrar import gereken durumlarda kullanici bilincli olarak kapatmalidir
- `staging sil`, `Mikro'ya aktar`, `Mikro'dan sil` ve `aralik aktar` aksiyonlari ayri butonlar olmalidir
- procedure response'unda adet bilgisi yoktur; UI mesaj alanini ve calistirilan filtreleri gostermelidir

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

Response:

```json
[
  {
    "typeName": "Nakit",
    "paymentTypeId": 1,
    "accountCode": "",
    "slipNumber": 0,
    "amount": 11340.5,
    "terminalId": "",
    "description": ""
  },
  {
    "typeName": "Akbank POS",
    "paymentTypeId": 5,
    "accountCode": "POS-AKBANK",
    "slipNumber": 45612,
    "amount": 2500,
    "terminalId": "TERM-01",
    "description": ""
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
    "quantity": 3,
    "total": 300
  }
]
```

### Banknot Takipleri

Gunluk banknot teslim/toplam kayitlarini Kasa Islemleri altindaki ayri menu route'undan getirir.

`GET /api/kasa-islemleri/banknot-takipleri?dateToGet=2026-04-24&warehouseNo=110`

Yetki:

- `kasa-islemleri.banknot-takipleri.list`

Not:

- `warehouseNo = 1` gonderilirse tum depolar listelenir
- response modeli `BanknoteTrackDto` doner ve `banknoteTrackId` alanini GUID olarak icerir
- bu route'da `differenceAmount`, eski kodla uyumlu olarak `deliveryTotalAmount - totalAmount` hesaplanir

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

- `warehouseNo` body'de gonderilirse mevcut JWT deposu ile ayni olmak zorundadir
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

Bu endpointler kasa sayim formundaki secim kutulari ve yardimci alanlar icindir.

Yetki:

- tumu icin `kasa-islemleri.kasa-sayimlari.list`

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
    "paymentName": "Akbank POS",
    "paymentTypeNo": 5,
    "terminalId": "TERM-01",
    "accountCode": "",
    "slipNumber": 0,
    "amountValue": 0
  }
]
```

### Z Rapor Toplami

Paylasim klasorundeki Z rapor dosyasindan `NET CIRO` degerini okumaya calisir.

`GET /api/kasa-islemleri/kasa-sayimlari/z-rapor-toplam?documentSerie=KS110&warehouseNo=110&zReportNo=125&cashNo=1`

Yetki:

- `kasa-islemleri.kasa-sayimlari.detail`

Not:

- response `double` doner
- dosya bulunamazsa, config bos ise veya `NET CIRO` parse edilemezse `-1` doner
- backend `KasaSayimlari:ZReportBasePath` konfigurasyonunu kullanir

### Kasa Sayimi Olustur

Secili kullanici deposu icin yeni kasa sayimi yazar.

`POST /api/kasa-islemleri/kasa-sayimlari`

Yetki:

- `kasa-islemleri.kasa-sayimlari.create`

Onemli not:

- `warehouseNo` body'de opsiyoneldir; gonderilirse JWT deposu ile ayni olmalidir
- en az bir `paymentTypes` veya `storeExpenses` satiri zorunludur
- backend `Summaries`, `BanknoteMovements`, `GiftCheckMovements` ve `CARI_HESAP_HAREKETLERI` tarafina yazar
- `documentSerie` backend tarafinda `KS{loginKullaniciDepoNo}` olarak uretilir
- `documentOrderNo` ayni seri icin mevcut maksimum degerin bir fazlasi olarak uretilir

Request:

```json
{
  "cashNo": 1,
  "zReportNo": 125,
  "cashierNo": 1001,
  "managerNo": 1002,
  "zTotalValue": 15340.5,
  "total": 15340.5,
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
      "paymentName": "Nakit",
      "paymentTypeNo": 1,
      "accountCode": "",
      "terminalId": "",
      "slipNumber": 0,
      "amountValue": 11340.5
    }
  ],
  "storeExpenses": []
}
```

Response:

```json
{
  "documentSerie": "KS110",
  "documentOrderNo": 12,
  "summaryDate": "2026-04-24T00:00:00",
  "warehouseNo": 110,
  "lineCount": 1,
  "total": 15340.5,
  "writeConnectionName": "MikroConnection"
}
```

### Kasa Sayimi Guncelleme ve Silme

Belge uzerindeki satirlari ve fiziksel para detaylarini guncellemek icin ayri endpointler kullanilir.

Route'lar:

- `PUT /api/kasa-islemleri/kasa-sayimlari/KS110/12/detaylar`
- `PUT /api/kasa-islemleri/kasa-sayimlari/KS110/12/banknot-hareketleri`
- `DELETE /api/kasa-islemleri/kasa-sayimlari/KS110/12`

Yetki:

- uc endpoint icin de `kasa-islemleri.kasa-sayimlari.update`

Not:

- detay update request'inde `details` listesi zorunludur
- banknot update request'inde `banknoteMovements` bos gonderilirse mevcut banknot satirlari temizlenebilir
- `DELETE` cagrisinda `warehouseNo` body'den alinmaz; JWT deposu kullanilir

Detay update request:

```json
{
  "details": [
    {
      "typeName": "Nakit",
      "paymentTypeId": 1,
      "accountCode": "",
      "slipNumber": 0,
      "amount": 12000,
      "terminalId": "",
      "description": ""
    }
  ]
}
```

Detay update response:

```json
{
  "documentSerie": "KS110",
  "documentOrderNo": 12,
  "updatedLineCount": 1,
  "totalAmount": 12000
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

Delete response:

```json
{
  "documentSerie": "KS110",
  "documentOrderNo": 12,
  "deletedSummaryLineCount": 2,
  "deletedBanknoteLineCount": 1,
  "deletedGiftCheckLineCount": 0,
  "deletedCustomerMovementCount": 1
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

### Entegrasyon Islemleri

- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi`
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari`
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/{totalId}`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/ice-aktar`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/erpye-gonder`
- `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari`
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar`
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/{invoiceId}`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/ice-aktar`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/erpye-gonder`
- `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/{invoiceId}`
- `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar`
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari`
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/{expenseId}`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/ice-aktar`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/erpye-gonder`
- `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/{expenseId}`
- `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari`
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri`
- `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri/{mappingId}`

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
  -> menu permission'i: ortak-islemler.sikayet-oneri.list veya list-all
  -> Administrator rolu tum kayitlari ve aksiyonlari gorur
  -> list-all yoksa liste/detay/guncelleme kullanicinin JWT deposuyla sinirlanir
  -> liste icin GET /api/yonetim/sikayet-oneri veya /api/ortak-islemler/sikayet-oneri
  -> satir detay icin GET /api/yonetim/sikayet-oneri/{id}
  -> okundu isareti icin PATCH /api/yonetim/sikayet-oneri/{id}/okundu
  -> durum/not guncelleme icin PATCH /api/yonetim/sikayet-oneri/{id}/durum

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
  -> plaka, sofor adi soyadi ve sofor TCKN modal/form ile zorunlu alinir
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
  -> plaka, sofor adi soyadi ve sofor TCKN modal/form ile zorunlu alinir
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
  -> QR'dan gelen ETTN ile e-irsaliye ust bilgi ve kalemleri cekebilir
  -> GET /api/mal-kabul-islemleri/firma-mal-kabulleri/e-irsaliye/ettn/{ettn}
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
  -> plaka, sofor adi soyadi ve sofor TCKN modal/form ile zorunlu alinir
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
  -> plaka, sofor adi soyadi ve sofor TCKN modal/form ile zorunlu alinir
  -> POST /api/iade-islemleri/depo-iadeleri/giden/{seri}/{sira}/e-irsaliye
  -> basarili gonderimden sonra kullanici 'PDF Goster' derse
  -> GET /api/iade-islemleri/depo-iadeleri/giden/{seri}/{sira}/e-irsaliye/pdf

Kasa Islemleri / Kasa Sayimlari
  -> ekran acilisinda o gunun belge listesi icin GET /api/kasa-islemleri/kasa-sayimlari?dateToGet=...
  -> ust rapor kartlari icin GET /api/kasa-islemleri/kasa-sayimlari/rapor?dateToGet=...
  -> lookup alanlari icin kasiyer, kasa, odeme tipi ve banknot tipi endpointlerini paralel cagir
  -> kullanici satira tiklar
  -> GET /api/kasa-islemleri/kasa-sayimlari/{seri}/{sira}
  -> gerekiyorsa banknot ve hediye ceki detaylarini ayri sekmelerde
  -> GET /api/kasa-islemleri/kasa-sayimlari/{seri}/{sira}/banknot-hareketleri
  -> GET /api/kasa-islemleri/kasa-sayimlari/{seri}/{sira}/hediye-ceki-hareketleri
  -> Z rapor karsilastirmasi icin GET /api/kasa-islemleri/kasa-sayimlari/z-rapor-toplam?... 
  -> kullanici 'Yeni Kasa Sayimi' derse create ekranina gecer
  -> kaydetmek icin POST /api/kasa-islemleri/kasa-sayimlari
  -> detay duzenleme icin PUT /api/kasa-islemleri/kasa-sayimlari/{seri}/{sira}/detaylar
  -> banknot duzenleme icin PUT /api/kasa-islemleri/kasa-sayimlari/{seri}/{sira}/banknot-hareketleri
  -> silme icin DELETE /api/kasa-islemleri/kasa-sayimlari/{seri}/{sira}

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
  -> kullanici sube secince kasa filtresi icin GET /api/kasa-islemleri/kasa-hareket-aktarimi/subeler/{branchNo}/kasalar
  -> HR hareket dosyalarini staging'e almak icin POST /api/kasa-islemleri/kasa-hareket-aktarimi/hareketler/aktar
  -> IP iptal dosyalarini staging'e almak icin POST /api/kasa-islemleri/kasa-hareket-aktarimi/iptal-belgeleri/aktar
  -> zamanli/gunluk toplu calistirma icin POST /api/kasa-islemleri/kasa-hareket-aktarimi/zamanli-aktarim/calistir
  -> import oncesi dryRun=true ile parse/lookup sonucu gosterilebilir
  -> rapor gridini doldurmak icin GET /api/kasa-islemleri/kasa-hareket-aktarimi/rapor?date=...
  -> staging temizleme icin DELETE /api/kasa-islemleri/kasa-hareket-aktarimi/staging
  -> staging hareketlerini Mikro'ya yazmak icin POST /api/kasa-islemleri/kasa-hareket-aktarimi/mikro/aktar
  -> Mikro'ya yazilmis hareketleri silmek icin DELETE /api/kasa-islemleri/kasa-hareket-aktarimi/mikro
  -> tarih araligi toplu aktarim icin POST /api/kasa-islemleri/kasa-hareket-aktarimi/mikro/aralik-aktar
```

## Fatura Islemleri

Bu bolum 2026-06-19 tarihinde kaynak kod uzerinden yeniden dogrulanmistir.

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
  - onizleme icin HTML render eder
  - secilen belgeleri Uyumsoft `SendInvoice` ile gonderir
  - basarili cevapta donen belge numarasini tekrar Mikro `cha_belge_no` alanina yazar ve kaydi kilitler
- `fatura-goruntuleme`
  - eski `Furpa.FaturaGoruntulemeWinUI` parity'sini korur; listeyi artik Auth/PostgreSQL icindeki `uyumsoft_inbox_invoices` cache tablosundan okur
  - varsayilan belge acmada Uyumsoft `GetInboxInvoicePdf` ile PDF datasini alir
  - HTML detay/render gerektiginde Uyumsoft `GetInboxInvoice` ile XML alip `XML -> XSLT -> HTML` render eder
  - gercek print/isaretleme ayrimini koruyup `isPrinted` durumunu ayri endpoint ile gunceller

UI tarafinda karistirilmamasi gereken net kural:

- `fatura-gonderimi`, giden faturalarin ekranidir. Satir `isSent = false` veya `isSent = true` olsa da UI sadece lokal HTML onizleme acar.
- `fatura-gonderimi` listesinde Uyumsoft resmi PDF acma aksiyonu yoktur; Mikro kaynakta Uyumsoft teknik `invoiceId` kalici saklanmadigi icin gonderilmis giden faturalar Uyumsoft PDF endpointinden cozumlenmez.
- `fatura-goruntuleme`, gelen/inbox faturalari ve cache listesidir. Giden fatura PDF aksiyonunun ana yolu degildir.

`fatura-gonderimi` tarafinda eldeki herhangi bir XML'i manuel preview etme endpoint'i ayrica acik tutulmustur.

### UI Icin Kisa Karar Agaci

Mevcut API'yi kullanarak ilerleyecekseniz akisi su sekilde okuyun:

1. Giden faturalari listelemek icin `GET /api/fatura-islemleri/fatura-gonderimi`
2. Liste varsayilan olarak `isSent=0` ile gonderilmemisleri getirir. `isSent=1` gonderilmis giden faturalar icindir.
3. Kullanici herhangi bir giden fatura satirinda lokal onizleme acmak istediginde:
   - default davranis yeterliyse `GET /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}?scenario=...`
   - XSLT secimini elle kontrol etmek istiyorsaniz `POST /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/render`
   - UI response icindeki yalnizca `document.htmlContent` alanini tek bir iframe/webview icinde render eder
   - UI ayrica QR/karekod uretmez; karekodun tek kaynagi secilen XSLT'nin urettigi HTML'dir
4. Giden fatura satirinda resmi PDF butonu gosterilmez; Uyumsoft outbox/PDF endpoint'i cagrilmaz.
5. Secilen gonderilmemis faturalarin gonderime hazir olup olmadigini canli gonderim yapmadan kontrol etmek icin `POST /api/fatura-islemleri/fatura-gonderimi/validate`
6. Kontrol sonucu uygunsa secilen gonderilmemis faturalari canli Uyumsoft'a gondermek icin `POST /api/fatura-islemleri/fatura-gonderimi/send`
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

Kisa ornek:

`GET /api/fatura-islemleri/fatura-goruntuleme?StartDate=2026-05-01&EndDate=2026-05-05&isProcessed=-1&isPrinted=-1&SearchField=InvoiceId&SearchText=INV-2026&page=1&PageSize=50`

Geriye uyumlu ornek:

`GET /api/fatura-islemleri/fatura-goruntuleme?StartDate=2026-05-01&EndDate=2026-05-05&ProcessedState=-1&PrintedState=-1&SearchField=InvoiceId&SearchText=INV-2026&PageNumber=1&PageSize=50`

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
SearchField     opsiyonel; InvoiceDate, InvoiceId, CustomerTitle, CustomerTcknVkn, InvoiceTotal, DespatchId
SearchText      opsiyonel; SearchField verildiyse legacy arama semantigiyle uygulanir
page            opsiyonel; UI icin onerilen alias, default 1
PageNumber      opsiyonel; default 1
PageSize        opsiyonel; default 50, max 500
```

UI notu:

- yeni UI gelistirmelerinde `isProcessed`, `isPrinted` ve `page` kullanilmasi tavsiye edilir
- eski istemciler icin `ProcessedState`, `PrintedState` ve `PageNumber` hala desteklenir
- ayni request'te hem yeni hem eski alias gonderilirse yeni aliaslar (`isProcessed`, `isPrinted`, `page`) oncelikli kabul edilir

Response `InvoiceViewingListResponse`:

```json
{
  "totalCount": 245,
  "pageNumber": 1,
  "pageSize": 50,
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
      "status": "Onaylandi"
    }
  ]
}
```

Liste davranisi:

- temel kaynak Auth/PostgreSQL icindeki `uyumsoft_inbox_invoices` tablosudur
- `GET /api/fatura-islemleri/fatura-goruntuleme` otomatik Uyumsoft cagrisi yapmaz; sadece lokal cache/DB sonucunu doner
- yeni eklendi: `POST /api/fatura-islemleri/fatura-goruntuleme/senkronize` endpoint'i secilen tarih araligini Uyumsoft `GetInboxInvoiceList` operasyonu ile cache tabloya upsert eder
- legacy `GetInvoicesAsync(isProcessed, isPrinted)` akisindaki gibi tarih + islenme + yazdirilma filtresi uygulanir
- tarih filtresi `invoiceDate` veya fallback olarak `createDate` alanina uygulanir
- tarih araligi gun seviyesindedir; bitis tarihi SQL tarafinda `+1 gun exclusive` mantigi ile uygulanir
- `documentId` bu listedeki Uyumsoft teknik UUID/operasyon anahtaridir; UI row key, PDF, detay, render ve printed isteklerinde bunu aynen kullanir
- `invoiceId` kullaniciya gosterilecek resmi fatura numarasidir; route parametresi olarak kullanilmaz
- `ProcessedState` ve `PrintedState` legacy WinForms'taki gibi tri-state filtre davranisi saglar
- `customerTitle` response'a buyuk harfe cevrilmis gelir
- DB tarafindaki kolon `isStandart` olsa da API response'unda alan `isStandard` olarak gelir
- `statusCode` ham DB degeridir; `status` ise UI'de direkt gosterebileceginiz aciklama metnidir
- `status` mapping'i:
  - `1000` -> `Onaylandi`
  - `1100` -> `Onay Bekliyor`
  - `1200` -> `Reddedildi`
  - `1300` -> `Iade Edildi`
  - `1400` -> `E-Arsiv Iptal`
  - diger -> `Bilinmiyor`
- SQL tarafinda yalniz tarih + processed + printed filtreleri uygulanir
- arama semantigi legacy ile uyumludur ve SQL'den gelen sonuc seti uzerinde, paging'den once bellek tarafinda uygulanir:
  - `InvoiceDate` -> exact date
  - `InvoiceId` -> contains, case-insensitive
  - `CustomerTitle` -> contains, case-insensitive
  - `CustomerTcknVkn` -> contains
  - `InvoiceTotal` -> exact decimal
  - `DespatchId` -> contains, case-insensitive
- paging de legacy davranisa yakin olacak sekilde aramadan sonra uygulanir; su an SQL `OFFSET/FETCH` yerine API katmani `Skip/Take` kullanir
- bu nedenle mevcut implementasyon "tam server-side paging" degil, "SQL filtre + memory search + memory page" davranisindadir
- bu, WinUI'daki `invoiceList` / `filteredList` + `PagedList` mantiginin API karsiligidir
- eski WinUI'daki Excel export davranisi bu endpoint grubuna server-side olarak tasinmamistir; export ihtiyaci varsa UI kendi yukledigi veriyi kullanmali veya ayrica export endpoint'i tasarlanmalidir

### Fatura Goruntuleme Manuel Senkronizasyon

Yeni eklendi:

- bu endpoint listeyi donmez; yalnizca secilen tarih araligini Uyumsoft'tan cache tabloya senkronize eder
- UI tarafinda tipik akis `POST /senkronize` sonra `GET /fatura-goruntuleme` seklinde olmalidir

`POST /api/fatura-islemleri/fatura-goruntuleme/senkronize`

Yetki:

- `fatura-islemleri.fatura-goruntuleme.list`

Request body:

```json
{
  "startDate": "2026-05-01",
  "endDate": "2026-05-05"
}
```

Response:

- `204 NoContent`

Davranis:

- secilen tarih araligini Uyumsoft `GetInboxInvoiceList` ile okur
- gelen sonuc `uyumsoft_inbox_invoices` cache tablosuna upsert edilir
- tekrar eden veya degisiklik icermeyen sayfalar icin koruma vardir; sonsuz donguye girmez
- sync tamamlandiktan sonra UI ayni tarih araligiyla `GET /api/fatura-islemleri/fatura-goruntuleme` cagirip DB sonucunu alabilir

### Fatura Goruntuleme PDF

`GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}`

Alias:

`GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}/pdf`

Yetki:

- `fatura-islemleri.fatura-goruntuleme.detail`

Response:

- `UyumsoftOperationResponseDto`
- Backend Uyumsoft e-fatura `GetInboxInvoicePdf` operasyonunu `invoiceId = documentId` parametresiyle cagirir.
- PDF payload Uyumsoft response yapisina gore `scalarValue`, `nodes` veya `responsePayloadJson` icinde gelir; UI mevcut entegrasyon endpointindeki `GetInboxInvoicePdf` cevabi gibi yorumlamalidir.

Direkt PDF binary almak isteyen UI ekranlarinda liste satirindaki `documentId` teknik UUID olarak kullanilir:

`GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{documentId}/pdf-file`

Response:

- `Content-Type: application/pdf`
- `Content-Disposition: inline`
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
  `/api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/` +
  `${encodeURIComponent(row.documentId)}/pdf-file`;
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
      "shipmentDocumentNo": "IRS-001",
      "shipmentDocumentDate": "2026-05-05T00:00:00",
      "returnInvoiceNo": "",
      "returnInvoiceDate": null,
      "warehouseName": "MERKEZ DEPO",
      "description": "Aciklama"
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
      "description": ""
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
- `invoiceId`, UBL icindeki `cbc:ID` degeridir; UI bunu PDF URL'si uretmek icin kullanmaz
- `sentDocumentNo` Mikro `cha_belge_no` alanidir; gonderim sonrasi kullaniciya gosterilen resmi belge numarasidir
- `isSent = false` ise fatura henuz Uyumsoft'a gonderilmemistir; UI lokal onizleme acar
- `isSent = true` ise fatura Uyumsoft'a gonderilmis giden faturadir; UI yine lokal onizleme acar
- giden fatura listesinde resmi Uyumsoft PDF alani/URL'si donmez; mevcut Mikro kaynaginda Uyumsoft teknik `invoiceId` kalici tutulmadigi icin fatura numarasindan PDF cozumleme yapilmaz
- UI giden fatura ekraninda PDF butonu gostermez ve `invoiceId` / `sentDocumentNo` degerlerinden Uyumsoft PDF URL'si uretmez
- `invoiceProfileId` alani:
  - e-fatura icin `TICARIFATURA` veya `TEMELFATURA`
  - e-arsiv icin `EARSIVFATURA`
- `invoiceTypeCode` alani:
  - `IADE`, `ISTISNA`, `OZELMATRAH`, `SATIS`
- `serviceDocumentId`, sadece `send` response'unda anlik donen Uyumsoft teknik id'dir; Mikro liste kaynagi bunu kalici saklamadigi icin liste ekraninda bu alana bagimli UI yazilmamalidir
- iade faturalarinda Mikro `EBELGE_EVRAK_HAREKETLERI` kaydi `ebh_related_uid = CARI_HESAP_HAREKETLERI.cha_Guid` ile baglanir
- `ebh_iade_fat_no1` ve `ebh_iade_fat_tarihi1` degerleri response'ta `returnInvoiceNo` / `returnInvoiceDate` olarak doner
- iade referansi doluysa UBL'ye `cac:BillingReference/cac:InvoiceDocumentReference` eklenir; XSLT'deki `Iadeye Konu Olan Faturalar` tablosu bu alandan dolar

Onizleme ve PDF butonlari icin kopyalanabilir UI kurali:

```ts
function canPreviewSendingInvoice(summary: InvoiceSendingListItemDto | null | undefined): boolean {
  return Boolean(summary?.documentSerie && summary.documentOrderNo);
}
```

Onizleme butonu `isSent` degerine bakmaz; giden faturanin HTML'i Mikro verisinden lokal uretilir. Bu ekranda PDF butonu yoktur.

#### Onizleme icin tek kaynak kurali

Gonderilmemis ve gonderilmis giden faturalar ayni lokal onizleme endpoint'ini kullanir:

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

- secilen belgeler tekillestirilir
- Mikro verisinden UBL XML uretilir
- iade referansi gerekiyorsa fallback sadece simule edilir, Mikro'ya yazilmaz
- UBL-TR is kurali ve XSD dogrulamalari calistirilir
- Uyumsoft'a fatura gonderilmez
- Mikro `cha_belge_no`, `cha_kilitli` veya baska alanlar guncellenmez

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

- secimler duplicate ise backend tekilleştirir
- gonderim Uyumsoft WCF client ile fatura bazli tek tek yapilir; boylece basarili/hatali kayitlar response icinde ayri ayri gorulur
- her belge icin UBL invoice uretilir ve Uyumsoft `SendInvoice` operasyonu cagrilir
- basarili donuste `serviceDocumentNumber` Mikro `cha_belge_no` alanina yazilir
- `serviceDocumentId` Uyumsoft'un teknik id'sidir ve send response'unda bilgilendirme icin doner; mevcut Mikro tabloya yazilmadigi icin sonraki liste response'unda garanti edilmez
- sonraki liste ekraninda UI yine lokal onizleme kullanir; `serviceDocumentId` kalici saklanmadigi icin gonderilmis giden fatura PDF'i Uyumsoft'tan acilmaz
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
- e-arsiv gonderiminde `EArchiveInvoiceInfo DeliveryType="Electronic"` kullanilir

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

- is kurali tarafinda sade ozet sunudur: `fatura-gonderimi` giden faturayi lokal onizleme ve bekleyen kaydi Uyumsoft'a yollama akisidir, `fatura-goruntuleme` ise Uyumsoft gelen/inbox faturasini acma/yazdirma akisidir
- bu repoda `fatura-gonderimi` icin artik dogrudan pending list, detay/render ve send endpointleri vardir
- `fatura-goruntuleme` tarafi artik `uyumsoft_inbox_invoices` cache tablosundan liste alir; varsayilan acista Uyumsoft `GetInboxInvoicePdf` ile PDF datasini, HTML detayda `GetInboxInvoice` ile render datasini alir
- yeni eklendi: `POST /api/fatura-islemleri/fatura-goruntuleme/senkronize` ile secilen tarih araligi manuel olarak Uyumsoft'tan cache'e alinabilir
- `fatura-goruntuleme` icinde legacy'deki "goruntule" ve "yazdirildi say" ayrimi artik ayri endpointlerle temsil edilir
- `GET /{documentId}/detail` ile `POST render` ayni response tipini doner; fark, `POST render` ile XSLT davranisinin override edilebilmesidir
- `fatura-gonderimi` detail/send akisinda invoice XML Mikro verisinden backend tarafinda yeniden uretilir; UI ham XML kurmak zorunda degildir
- `fatura-gonderimi` send akisinda basarili sonuclarda Mikro `cha_belge_no` geri yazilir ve kayit kilitlenir
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
- `promofile` de yeni kuyruk/polling modeliyle calisir; eski yardimci dosya zinciri job icinde uretilir

Temel route:

- `api/operations`

Mevcut endpointler:

- `GET /api/operations/scalesfile`
  - terazi dosyasi isi kuyruga alinir
  - response `202 Accepted`
  - body `OperationJobDto`
- `GET /api/operations/productbarcodeplunofile`
  - urun/barcode/PLU dosya isi kuyruga alinir
  - eski uyumluluk icin `GET /api/operations/productbarcodeplonofile` da ayni isi yapar
  - response `202 Accepted`
- `GET /api/operations/cashierfile`
  - kasiyer ve yetki dosyalari isi kuyruga alinir
  - response `202 Accepted`
- `GET /api/operations/promofile`
  - promosyon ve yardimci POS dosyalari isi kuyruga alinir
  - response `202 Accepted`
  - Mayday/UYUM connection stringleri eksikse job `Failed` durumuna duser ve `errorMessage` ile sebep doner
- `GET /api/operations/jobs/{jobId}`
  - kuyruga atilan isin durumunu dondurur
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

Operasyon modulu notlari:

- bu modul Hangfire yerine uygulama ici hosted queue kullanir
- UI canli progress stream beklememelidir; polling yeterlidir
- `scalesfile` icin `BranchDetails` kaydi ve `ScalesType` bilgisi zorunludur
- `productbarcodeplunofile` ve `cashierfile` lokal export uretebilir; branch network path varsa ek olarak paylasima da kopyalanir
- `promofile` `PROMO.DAT`, `NOPROMO.DAT`, `NOCEK.DAT`, `NOYEMEK.DAT`, `GRUP.DAT`, `OZELKOD.DAT`, `EFATVNO.DAT` ve kasa bazli `MESAJ.xxx` dosyalarini uretir
- export klasoru config'deki `OperationsExport:BasePath` ile verilebilir; bos ise uygulama altindaki `App_Data/OperationsExports` kullanilir
- `promofile` icin `ConnectionStrings:MaydayConnection` ve `ConnectionStrings:UyumConnection` ayarlari gereklidir

## Entegrasyon Islemleri

Bu modul, eski `Furpa.WorkerService` akisini yeni API icinde worker + manuel endpoint ayrimi ile yonetmek icin eklendi. UI tarafinda bu ekran "entegrasyon gorevi sec, preview al, dry-run yap veya outbox'a at, sonra job durumunu izle" mantigiyla kurgulanmalidir.

Sonuc odakli kullanim icin onerilen ana yollar:

- Urun master: `live/products/preview` ile kontrol et, secili urun icin `live/products/{productCode}/dispatch`, toplu secim icin `live/products/dispatch` kullan. Job/outbox akisini ikincil/teknik arac olarak goster.
- Mikro -> AXATA evrak kurtarma: once `manual/tasks/{taskCode}/documents/candidates`, sonra `preview`, son olarak gercek gonderim icin `dispatch` kullan. `execute/Outbox` AXATA'ya gondermez, sadece dosya hazirlar.
- AXATA -> Mikro C01 sevk: once `live/axata/outbound-deliveries/c01/preview`, uygun kayit varsa `import` kullan. Import ekraninda `acknowledge` secimi kullaniciya acik gosterilmelidir.
- C02/C03/C4 kuyruklari: sadece `outbound-deliveries/preview` ile goruntule. Bu profiller icin otomatik Mikro yazma aksiyonu sunma.
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
- `company-receiving-sync`
- `inventory-count-sync`

Execution mode:

- `DryRun`
  - canli veriden payload uretilir ama dosya yazilmaz
- `Outbox`
  - payload `App_Data/AxataSynchronizationOutbox` altina JSON olarak yazilir

Mevcut endpointler:

- `GET /api/integrations/axata-sync`
  - modulu, aktif task'lari, schedule ayarlarini ve son job'lari doner
  - response `AxataSynchronizationOverviewDto`
- `GET /api/integrations/axata-sync/health`
  - Mikro SQL, Furpa SQL ve AXATA endpoint erisimi icin probe sonucunu doner
  - response `AxataSynchronizationConnectionTestDto`
- `GET /api/integrations/axata-sync/fetch-profiles`
  - eski worker parity icin planlanan AXATA fetch/import profillerini listeler
  - her profil icin bugunku fallback route ve implementasyon durumu gorulebilir
  - response `AxataSynchronizationFetchProfilesOverviewDto`
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
  - yalnizca `issued-warehouse-order-sync`, `company-receiving-sync`, `inventory-count-sync` icin gecerlidir
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
  - su an `issued-warehouse-order-sync` ve `company-receiving-sync` icin tanimlidir
  - `issued-warehouse-order-sync` worker parity icin `C01` hareket kodu ile `addOutboundOrder*` operasyonunu kullanir
  - `company-receiving-sync` worker parity icin `G01` hareket kodu ile `addInboundOrder*` operasyonunu kullanir
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

UI icin endpoint davranis rehberi:

| UI bolumu | Endpoint | Ne yapar | Veri yazar mi? | UI aksiyonu |
|---|---|---|---|---|
| Genel Durum | `GET /api/integrations/axata-sync` | Task listesini, aktif/pasif durumlari, worker/scheduler bilgisini ve son job'lari getirir | Hayir | Sayfa acilisinda cagir |
| Genel Durum | `GET /api/integrations/axata-sync/health` | Mikro SQL, Furpa SQL, AXATA Main ve EXT endpoint erisimini kontrol eder | Hayir | "Baglanti testi" veya otomatik durum karti |
| Profil Katalogu | `GET /api/integrations/axata-sync/fetch-profiles` | AXATA servislerinden hangi profillerin okunabilecegini ve backendde hangi seviyede desteklendigini listeler | Hayir | UI butonlarini capability'ye gore ac/kapat |
| Fark Analizi | `GET /api/integrations/axata-sync/live/audit/overview` | Mikro kaynakli siparis gonderimini, AXATA kaynakli sevk donusunu, pending/iptal AXATA sevklerini ve Mikro link durumunu birlikte kontrol eder | Hayir | "Kontrol et" butonu |
| AXATA Kuyruk | `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/preview` | C01/C02/C03/C4 pending outbound delivery kuyrugunu canli okur | Hayir | "AXATA kuyrugunu goster" butonu |
| AXATA Sevk Tarihi | `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/by-date` | AXATA `ENT006.S06ITAR` tarihine gore sevk basliklarini ve `ENT007` satir ozetini listeler | Hayir | "Tarihe gore sevkleri getir" |
| C01 Import | `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/preview` | C01 pending teslimatlari Mikro siparis satirlariyla eslestirir | Hayir | "C01 import onizle" butonu |
| C01 Import | `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/import` | Uygun C01 teslimatini Mikro depolar arasi sevk fisine cevirir; istenirse AXATA ack atar | Evet | "C01'i Mikro'ya isle" butonu |
| C01 Rescue | `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/{serie}/{sira}/preview` | AXATA'da C01 sevki olusmus ama belge genelinde Mikro sevk linki olmayan tek belgeyi AXATA'dan belge bazinda arar | Hayir | "Eksik sevki onizle" |
| C01 Rescue | `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/{serie}/{sira}/import` | AXATA teslimat detayi bulunur ve Mikro siparisiyle eslesirse eksik Mikro sevkini olusturur | Evet | "Eksik sevki Mikro'ya dusur" |
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
| `outbound-deliveries/preview` | AXATA C01/C02/C03/C4 pending kuyrugunu okur | Mikro'ya yazmaz, ack atmaz |
| `outbound-deliveries/by-date` | AXATA `ENT006.S06ITAR` tarihine gore sevkleri listeler | Mikro'ya yazmaz, ack atmaz; pending filtrelemez |
| `c01/import` | AXATA C01 teslimatini Mikro sevke cevirir | Mikro'ya yazar, `acknowledge=true` ise AXATA EXT status gunceller |
| `c01/documents/{serie}/{sira}/preview` | C01 teslimatini AXATA'da belge no ile arar, status verilmezse `0` sonra `1` dener | Veri yazmaz |
| `c01/documents/{serie}/{sira}/import` | AXATA'da C01 sevki olusmus ama belge genelinde Mikro sevk linki olmayan belgeyi Mikro'ya dusurur | Mikro'ya yazar, `acknowledge=true` ise AXATA EXT status gunceller |
| `manual/axata/*` | AXATA verisi body olarak UI/operasyon tarafindan saglanir | AXATA'dan canli fetch yapmaz |
| `manual/incoming/*` | Mikro'ya manuel belge yazar | AXATA status guncellemez |

Task bazli UI buton kurali:

| Task/profil | Liste | Preview | Outbox execute | Live dispatch | Live queue preview | Live import/ack |
|---|---|---|---|---|---|---|
| `firm-master-sync` | Yok | Var | Var | Yok | Yok | Yok |
| `product-master-sync` | Yok | Var | Var | Var (`Live`) | Yok | Yok |
| `issued-warehouse-order-sync` | Var | Var | Var | Var | Yok | Yok |
| `company-receiving-sync` | Var | Var | Var | Var | Yok | Yok |
| `inventory-count-sync` | Var | Var | Var | Yok | Yok | Yok |
| `C01 outbound delivery` | AXATA kuyrugu + belge bazli rescue | Var | Yok | Yok | Var | Var |
| `C02 outbound delivery` | AXATA kuyrugu | Kuyruk preview | Yok | Yok | Var | Yok |
| `C03 outbound delivery` | AXATA kuyrugu | Kuyruk preview | Yok | Yok | Var | Yok |
| `C4 outbound delivery` | AXATA kuyrugu | Kuyruk preview | Yok | Yok | Var | Yok |
| `G01 inbound ATF` | Yok | Yok | Yok | Yok | Yok | Yok, sadece body/manual import |
| `G02 inbound delivery` | Yok | Yok | Yok | Yok | Yok | Yok |

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
- `C02/C03/C4 preview`: "Bu hareket tipi icin simdilik sadece AXATA kuyrugu goruntulenir; Mikro'ya yazma yapilmaz."
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
- Mikro donusu `STOK_HAREKETLERI_EK.sth_subesip_uid` ile bagli gercek `STOK_HAREKETLERI.sth_miktar` toplami uzerinden `WaitingForMikroTransfer`, `PartiallyLinked` veya `FullyLinked` olarak siniflandirilir
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
- Mikro yazim: depolar arasi sevk fisi, `STOK_HAREKETLERI_EK.sth_subesip_uid` linki ve `ssip_teslim_miktar` guncellemesi
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
- Mikro yazim: AXATA teslimat miktari Mikro kalan miktarini asmiyorsa depolar arasi sevk fisi, `STOK_HAREKETLERI_EK.sth_subesip_uid` linki ve `ssip_teslim_miktar` guncellemesi
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
  - AXATA C02/C03/C4 teslimatlari bekliyorsa `live/axata/outbound-deliveries/preview?movementType=C02|C03|C4` ile sadece kuyruk durumunu goster
  - AXATA outbound delivery verisi eldeyse `manual/axata/outbound-deliveries/inter-warehouse-shipments` ile dogrudan Mikro sevki yaz
  - AXATA inbound ATF verisi eldeyse `manual/axata/inbound-atf/company-receivings` ile dogrudan Mikro firma mal kabule cevir
  - AXATA ham verisi operasyon tarafinda toparlanmis ise `manual/incoming/company-receivings` veya `manual/incoming/inventory-counts` kullan
  - coklu belge geliyorsa `.../company-receivings/batch` veya `.../inventory-counts/batch` ile tek cagrida islenebilir
  - depo sevki zaten bekleyen belge olarak Mikro'ya dusmus ama kabulde takildiysa once `manual/incoming/warehouse-receivings` ile listele, gerekirse detay endpoint'i ile satirlari kontrol et, sonra `.../accept` veya `.../accept-batch` kullan
- Not:
  - C01 icin backend AXATA'dan WCF client ile canli fetch/import yapar; C02/C03/C04 icin canli kuyruk preview vardir ama import/ack ayri fazdir; G01/G02 fetch-import akislari ayri fazdir
  - `dispatch` endpoint'leri AXATA'ya canli yazim yapar; `execute` endpoint'leri ise sadece `DryRun/Outbox` icindir
  - eski worker operasyon isimleri kullanildigi icin canli AXATA dispatch sahada endpoint/credential ile dogrulanmalidir

Entegrasyon modulu notlari:

- worker ve scheduler backend tarafinda hosted service olarak calisir
- scheduler config ile kapali acilabilir; UI bunu overview ekraninda gostermelidir
- `preview` endpoint'i canli veriyi okur, test/mock veri kullanmaz
- `issued-warehouse-order-sync`, `company-receiving-sync` ve `inventory-count-sync` task'larinda `warehouseNo` gerekir
- `issued-warehouse-order-sync` icin `warehouseNo` AXATA kaynak/cikis depodur; aday liste, task preview, execute ve dispatch ayni `ssip_cikdepo` evrenine bakar
- `firm-master-sync` ve `product-master-sync` depo bagimsiz task'lardir
- `manual/tasks/{taskCode}/documents/*` endpoint'leri yalnizca evrak bazli task'larda kullanilmalidir
- `manual/tasks/{taskCode}/documents/dispatch*` endpoint'leri yalnizca AXATA'ya canli gonderim icindir; `Outbox` yerine kullanilir
- `manual/incoming/*` endpoint'leri worker'dan bagimsiz operasyonel kurtarma katmanidir
- `manual/axata/*` endpoint'leri AXATA-native request body'sini minimum donusumle Mikro write use-case'lerine baglar
- `live/audit/overview` endpoint'i eski worker calisirken kontrol/durum tespiti icindir; AXATA SQL `ENT006/ENT007` ve Mikro siparis/sevk linklerini okur, Mikro veya AXATA verisi yazmaz
- `live/axata/outbound-deliveries/preview` endpoint'i C01/C02/C03/C4 AXATA pending kuyrugunu canli okur; Mikro veya AXATA verisi yazmaz
- `live/axata/outbound-deliveries/c01/*` endpoint'leri AXATA'dan canli C01 cekip Mikro'ya yazar; AXATA ack sadece Mikro kaydi basarili olursa atilir
- `live/axata/outbound-deliveries/c01/import` gerekiyorsa mudahale icindir; mevcut worker'in yerine otomatik calisan yeni worker olarak dusunulmemelidir
- toplu endpoint'lerde `ContinueOnError = true` ise HTTP 200 donup basarisiz item'lari `Failures` listesinde raporlar
- `Outbox` modu su an gercek WCF dispatch degil, payload uretim ve dosyalama asamasidir
- canli AXATA import/ack adapter'i su an C01 depo sevki icin aktiftir; pending kuyruk importu ve belge bazli rescue desteklenir; C02/C03/C4 icin kuyruk preview vardir, import yoktur
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
| `firm-master-sync` | Var | Yok | Yok | Yok | liste/preview/job ekraninda goster |
| `product-master-sync` | Var | Yok | Yok | Yok | liste/preview/job ekraninda goster |
| `issued-warehouse-order-sync` | Var | Var | Var | Var | Mikro -> AXATA manuel kurtarma icin ana task |
| `company-receiving-sync` | Var | Var | Var | Var | Mikro -> AXATA manuel kurtarma icin ana task |
| `inventory-count-sync` | Var | Var | Var | Yok | su an sadece preview/dry-run/outbox ve AXATA -> Mikro manuel incoming tarafinda kullanilir |

UI manuel aktarim senaryolari:

- Mikro'da verilen depo siparisi var ve AXATA'ya yeniden gonderilecekse:
  - `manual/tasks/issued-warehouse-order-sync/documents/candidates`
  - `manual/tasks/issued-warehouse-order-sync/documents/preview`
  - gerekiyorsa `.../dispatch` veya `.../dispatch-batch`
- Mikro'da kesilmis `depolar-arasi-sevk` belgesi var ve bu belgenin AXATA'ya direkt gonderilmesi isteniyorsa:
  - su an hazir endpoint yok
  - UI bu belge tipi icin AXATA'ya manuel dispatch aksiyonu gostermemelidir
- Mikro'da firma mal kabul belgesi var ve AXATA'ya yeniden gonderilecekse:
  - `manual/tasks/company-receiving-sync/documents/candidates`
  - `manual/tasks/company-receiving-sync/documents/preview`
  - gerekiyorsa `.../dispatch` veya `.../dispatch-batch`
- AXATA outbound delivery verisi operasyon ekibinin elindeyse ve Mikro'da depolar arasi sevk yaratilacaksa:
  - `manual/axata/outbound-deliveries/inter-warehouse-shipments`
- AXATA C01 depo sevkleri AXATA'da bekliyorsa:
  - `live/axata/outbound-deliveries/c01/preview`
  - `live/axata/outbound-deliveries/c01/import`
- AXATA'ya gonderilmis C01 siparisin sevki AXATA'da kesilmis ama Mikro sevk linki yoksa:
  - once `live/audit/overview` icindeki `sentWarehouseOrdersMissingMikroShipments` listesinden belgeyi sec
  - `live/axata/outbound-deliveries/c01/documents/{documentSerie}/{documentOrderNo}/preview?status=1`
  - uygun ise `live/axata/outbound-deliveries/c01/documents/{documentSerie}/{documentOrderNo}/import`
- AXATA C02/C03/C4 teslimatlari AXATA'da bekliyorsa:
  - `live/axata/outbound-deliveries/preview?movementType=C02`
  - `live/axata/outbound-deliveries/preview?movementType=C03`
  - `live/axata/outbound-deliveries/preview?movementType=C4`
  - bu profiller icin UI import/ack butonu gostermemelidir
- AXATA inbound ATF verisi operasyon ekibinin elindeyse ve Mikro'da firma mal kabul yaratilacaksa:
  - `manual/axata/inbound-atf/company-receivings`
- Sevk zaten Mikro'ya dusmus ama kabulde takilmissa:
  - `manual/incoming/warehouse-receivings`
  - detail endpoint'i
  - `.../accept` veya `.../accept-batch`

UI'nin kullaniciya acik soylemesi gereken kritik sinirlar:

- C01 depo sevki icin AXATA'dan WCF client ile canli fetch/import vardir; pending kuyruk ve belge bazli rescue desteklenir
- C02/C03/C04 icin "AXATA'dan cek ve kuyrukta goster" akisi vardir; "Mikro'ya yaz ve ack at" akisi henuz yoktur
- G01/G02 icin "AXATA'dan cek ve Mikro'ya yaz" akisi henuz yoktur
- `dispatch*` endpoint'leri sadece `issued-warehouse-order-sync` ve `company-receiving-sync` icin aktiflenmelidir
- `depolar-arasi-sevk` belge detayi icin ayrica AXATA dispatch butonu acilmamalidir
- `firm-master-sync` icin UI sadece preview/job/outbox deneyimi sunmalidir
- `product-master-sync` icin preview, toplu canli dispatch ve urun koduyla tekli canli dispatch sunulabilir
- `inventory-count-sync` icin UI canli dispatch butonu gostermemelidir
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
  - aktif profil: `C01`
  - kuyruk preview profilleri: `C02`, `C03`, `C04(query C4)`
  - planli import profilleri: `C02`, `C03`, `C04(query C4)`, `G01`, `G02`
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

- kullanici tarih ve depo baglamina gore staging Z raporlarini listeler
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
- request formunu operasyon tipine gore dinamik cizme

#### `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/{operationName}`

Amac:

- whitelist'e alinmis tek bir GET operasyonunu query string ile calistirmak

Query:

- `parameter` tekrar eden query parametresidir ve `name=value` formatinda gonderilir

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

- her scalar parametre icin ayri `parameter=name=value` query parametresi gonderilir

Ornekler:

Sistem tarihi formatli alma:

```http
GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/GetSystemDateWithFormat?parameter=format=yyyy-MM-dd%20HH:mm:ss
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
  - array alanlarda ayni `name` birden fazla kez gonderilebilir; ornek `despatchId` / `despatchIds`

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
    string EndpointUrl);

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
    string RequestHint);

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
    UserDto User);

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
    string ProductManagerCode);

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
    string RepresentativeCode,
    string RepresentativeName,
    int? InvoiceAddressNo,
    int? ShippingAddressNo,
    bool IsLocked,
    bool IsClosed);

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
    string ProjectCode);

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
    string PoskonFolderPath,
    string PosGenelFolderPath);

public sealed record CashRegistryDto(
    int DetailId,
    int BranchNo,
    int CashNo,
    byte CashType);

public sealed record CashRegisterResponse(
    int BranchNo,
    int CashNo,
    byte CashType,
    IReadOnlyCollection<CashRegisterTerminalDto> Terminals);

public sealed record CashRegisterTerminalDto(
    int Id,
    string TerminalNo,
    string Bank,
    string TerminalId,
    string MerchantNo,
    int? CashNo);

public sealed record CashRegisterMessageStatusDto(
    int BranchNo,
    int CashNo,
    byte CashType,
    int? State,
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
    int PaymentTypeId,
    string AccountCode,
    int SlipNumber,
    double Amount,
    string TerminalId,
    string Description);

public sealed record BanknoteMovementItemDto(
    double Value,
    int BanknoteType,
    int Quantity,
    double Total);

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

public sealed record BanknoteTypeItemDto(
    double Value,
    double Quantity,
    double Total,
    int BanknoteType);

public sealed record GiftCheckMovementItemDto(
    double Value,
    int GiftCheckType,
    int Quantity,
    double Total);

public sealed record GiftCheckTypeItemDto(
    double Value,
    double Quantity,
    double Total,
    int GiftCheckType);

public sealed record PaymentTypeItemDto(
    string PaymentName,
    int PaymentTypeNo,
    string TerminalId,
    string AccountCode,
    int SlipNumber,
    double AmountValue);

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
    byte CashRegisterType);

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
    byte CashRegisterType);

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
    string Status);

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
- `SavePermissionBody`: `Code`, `Name`, `Description`
- `SaveRoleBody`: `Name`, `Description`, `IsActive`
- `AssignPermissionsBody`: `PermissionIds`
- `UpdateUserBody`: `Username`, `Email`, `FirstName`, `LastName`, `WarehouseNo`, `WarehouseName`, `IsActive`
- `AssignRolesBody`: `RoleIds`

### Ortak Request Modelleri

- `WarehouseOrderDateRangeHttpRequest`: `WarehouseNo`, `StartDate`, `EndDate`
- `SendEDespatchHttpRequest`: `Plaque`, `DriverNameSurname`, `DriverTckn`
- `ModuleActionRequest`: `Fields`
- `CreateFeedbackItemHttpRequest`: `Type`, `Title`, `Message`, `Priority`
- `FeedbackManagementListHttpRequest`: `Status`, `Type`, `WarehouseNo`, `StartDate`, `EndDate`, `Take`
- `ChangeFeedbackStatusHttpRequest`: `Status`, `AdminNote`
- `CreateCompanyMovementHttpRequest`: `CustomerCode`, `MovementDate`, `DocumentDate`, `DocumentNo`, `Description`, `Lines`
- `CreateCompanyMovementLineHttpRequest`: `StockCode`, `Quantity`, `UnitPrice`, `UnitPointer`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`, `CustomerResponsibilityCenter`, `ProductResponsibilityCenter`
- `CreateStockReceiptHttpRequest`: `Creator`, `Acceptor`, `MovementDate`, `DocumentDate`, `DocumentNo`, `Description`, `Lines`
- `CreateStockReceiptLineHttpRequest`: `StockCode`, `Quantity`, `UnitPointer`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`
- `CreateInventoryCountHttpRequest`: `Name`, `DocumentDate`, `Lines`
- `CreateInventoryCountLineHttpRequest`: `StockCode`, `Quantity`, `Barcode`, `UnitPointer`
- `CreateVirmanHttpRequest`: `MovementDate`, `DocumentDate`, `DocumentNo`, `Description`, `Lines`
- `CreateVirmanLineHttpRequest`: `StockCode`, `MovementType`, `Quantity`, `UnitPointer`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`

### Arama Request Modelleri

- `ProductSearchHttpRequest`: `WarehouseNo`, `Barcode`, `StockCode`, `StockName`, `SupplierCode`, `CompanyCode`, `Take`
- `ProductBarcodePriceLookupHttpRequest`: `WarehouseNo`, `Take`
- `CustomerSearchHttpRequest`: `SearchText`, `Take`
- `WarehouseSearchHttpRequest`: `SearchText`, `WarehouseNo`, `Take`
- `BarcodeResolutionHttpRequest`: `WarehouseNo`, `ScreenCode`
- `BarcodeCustomerLookupHttpRequest`: `Barcode`, `WarehouseNo`, `Take`
- `BarcodeCustomerLookupByPathHttpRequest`: `WarehouseNo`, `Take`
- `ProductCustomerSuggestionHttpRequest`: `Take`

### Siparis Request Modelleri

- `IssuedCompanyOrderListHttpRequest`: `WarehouseNo`, `StartDate`, `EndDate`, `CustomerCode`, `OnlyOpen`
- `CreateIssuedCompanyOrderHttpRequest`: `CustomerCode`, `OrderDate`, `DeliveryDate`, `Description1`, `Description2`, `Deliverer`, `Receiver`, `Lines`
- `CreateIssuedCompanyOrderLineHttpRequest`: `StockCode`, `Quantity`, `RecommendedQuantity`, `UnitPrice`, `UnitPointer`, `Description1`, `Description2`, `PackageCode`, `ProjectCode`, `CustomerResponsibilityCenter`, `ProductResponsibilityCenter`
- `CreateIssuedWarehouseOrderHttpRequest`: `OutWarehouseNo`, `OrderDate`, `DeliveryDate`, `Description`, `Lines`
- `CreateIssuedWarehouseOrderLineHttpRequest`: `StockCode`, `Quantity`, `RecommendedQuantity`, `UnitPrice`, `UnitPointer`, `Description`, `PackageCode`, `ProjectCode`, `ResponsibilityCenter`

### Sevk, Iade ve Mal Kabul Request Modelleri

- `CreateInterWarehouseShipmentHttpRequest`: `TargetWarehouseNo`, `TransitWarehouseNo`, `MovementDate`, `DocumentDate`, `DocumentNo`, `Description`, `Lines`
- `CreateInterWarehouseShipmentLineHttpRequest`: `StockCode`, `Quantity`, `WarehouseOrderLineGuid`, `UnitPrice`, `UnitPointer`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`, `CustomerResponsibilityCenter`, `ProductResponsibilityCenter`
- `CreateWarehouseReturnHttpRequest`: `TargetWarehouseNo`, `TransitWarehouseNo`, `MovementDate`, `DocumentDate`, `DocumentNo`, `Description`, `Lines`
- `CreateWarehouseReturnLineHttpRequest`: `StockCode`, `Quantity`, `UnitPrice`, `UnitPointer`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`, `CustomerResponsibilityCenter`, `ProductResponsibilityCenter`
- `AcceptWarehouseReceivingHttpRequest`: `AllowDiscrepancy`, `Lines`
- `AcceptWarehouseReceivingLineHttpRequest`: `MovementGuid`, `ReceivedQuantity`
- `CreateCompanyReceivingHttpRequest`: `ClientRequestId`, `CustomerCode`, `MovementDate`, `DocumentDate`, `DocumentNo`, `Deliverer`, `Receiver`, `Description`, `AllowOrderOverReceiving`, `AutoCreateReturnForPartialAcceptance`, `Lines`
- `CreateCompanyReceivingLineHttpRequest`: `StockCode`, `Quantity`, `DispatchQuantity`, `AcceptedQuantity`, `UnitPrice`, `UnitPointer`, `LastConsumingDate`, `OrderGuid`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`, `CustomerResponsibilityCenter`, `ProductResponsibilityCenter`

### Stok ve Etiket Request Modelleri

- `LabelTagListHttpRequest`: `DateToGet`
- `ManavKunyeDetailedLabelTagListHttpRequest`: `WarehouseNo`, `DateToGet` opsiyonel
- `LabelPriceChangedProductListHttpRequest`: `DateTimeFilter`
- `CreateLabelDocumentHttpRequest`: `Lines`
- `CreateLabelDocumentLineHttpRequest`: `ProductCode`

### Mikro Evrak Duzenleme Request Modelleri

- `StockCardSearchHttpRequest`: `SearchText`, `IncludePassive`, `Take`
- `StockCardPatchHttpRequest`: `Name`, `ShortName`, `ForeignName`, `SupplierCode`, `StockType`, `CurrencyType`, `TrackingType`, `Unit1Name`, `Unit2Name`, `Unit3Name`, `Unit4Name`, `RetailTaxPointer`, `WholesaleTaxPointer`, `CategoryCode`, `MainGroupCode`, `SubGroupCode`, `BrandCode`, `SectorCode`, `RayonCode`, `ManufacturerCode`, `ResponsibilityCode`, `ShelfCode`, `SalesStopped`, `OrderStopped`, `ReceivingStopped`, `IsPassive`, `DiscountDisabled`
- `StockMovementDocumentLookupHttpRequest`: `DocumentSerie`, `DocumentOrderNo`, `DocumentType`, `MovementType`, `MovementKind`, `NormalReturn`, `WarehouseNo`
- `UpdateStockMovementDocumentHttpRequest`: `Lookup`, `Header`, `Lines`
- `StockMovementHeaderPatchHttpRequest`: `MovementDate`, `DocumentDate`, `DocumentNo`, `CustomerCode`, `InputWarehouseNo`, `OutputWarehouseNo`, `Description`, `MovementGroupCode1`, `MovementGroupCode2`, `MovementGroupCode3`, `CustomerResponsibilityCenter`, `StockResponsibilityCenter`, `ProjectCode`
- `StockMovementLinePatchHttpRequest`: `MovementGuid`, `RowNo`, `StockCode`, `UnitPointer`, `Quantity`, `SecondaryQuantity`, `Amount`, `Discount1..Discount6`, `Expense1..Expense4`, `TaxPointer`, `TaxAmount`, `NetWeight`, `GrossWeight`, `Description`, `PartyCode`, `LotNo`, `ProjectCode`, `CustomerResponsibilityCenter`, `StockResponsibilityCenter`, `InputWarehouseNo`, `OutputWarehouseNo`
- `CustomerMovementDocumentLookupHttpRequest`: `DocumentSerie`, `DocumentOrderNo`, `DocumentType`, `MovementType`, `MovementKind`, `NormalReturn`, `CustomerCode`
- `UpdateCustomerMovementDocumentHttpRequest`: `Lookup`, `Header`, `Lines`
- `CustomerMovementHeaderPatchHttpRequest`: `MovementDate`, `DocumentDate`, `DocumentNo`, `CustomerCode`, `TurnoverCustomerCode`, `Description`, `SellerCode`, `ProjectCode`, `ResponsibilityCenter`
- `CustomerMovementLinePatchHttpRequest`: `MovementGuid`, `RowNo`, `CustomerCode`, `TurnoverCustomerCode`, `Quantity`, `Amount`, `SubAmount`, `DueDay`, `Discount1..Discount6`, `Expense1..Expense4`, `Tax1..Tax5`, `Description`, `SellerCode`, `ProjectCode`, `ResponsibilityCenter`

### Ayar Request Modelleri

- `CreateDeviceHttpRequest`: `BranchNo`, `DeviceTypeId`, `IpAddress`, `Description`
- `CreateBranchSettingsHttpRequest`: `BranchNo`, `BranchIpAddress`, `BranchScalesFolderPath`, `ScalesType`, `PoskonFolderPath`, `PosGenelFolderPath`, `CashRegisters`
- `UpdateBranchSettingsHttpRequest`: `BranchIpAddress`, `BranchScalesFolderPath`, `ScalesType`, `PoskonFolderPath`, `PosGenelFolderPath`
- `CreateCashRegistryHttpRequest`: `CashNo`, `CashType`
- `CreateCashRegisterHttpRequest`: `BranchNo`, `CashNo`, `CashType`, `Terminals`
- `CreateCashRegisterTerminalHttpRequest`: `TerminalNo`, `Bank`, `TerminalId`, `MerchantNo`
- `CreateCashierHttpRequest`: `CashierName`, `CashierAuthorization`
- `UpdateCashierHttpRequest`: `CashierName`, `CashierAuthorization`, `CashierState`

### Kasa Request Modelleri

- `CashSummaryDateHttpRequest`: `DateToGet`, `WarehouseNo`
- `WarehouseOrderDateRangeHttpRequest`: `WarehouseNo`, `StartDate`, `EndDate`
- `CashTurnoverDetailHttpRequest`: `WarehouseNo`, `BusinessDate`, `ShiftNo`, `CashierCode`
- `CashierPairHttpRequest`: `CashierCode`, `ManagerCode`
- `CashRegistryHttpRequest`: `BranchNo`
- `CashRegisterLookupHttpRequest`: `CashNo`, `CashRegisterNo`
- `CashierSearchHttpRequest`: `FilterString`
- `BankPaymentTypeHttpRequest`: `CashRegisterNo`
- `ZReportValueHttpRequest`: `WarehouseNo`, `DocumentSerie`, `ZReportNo`, `CashNo`
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
- `InvoiceViewingListHttpRequest`: `StartDate`, `EndDate`, `ProcessedState`, `IsProcessed`, `PrintedState`, `IsPrinted`, `SearchField`, `SearchText`, `PageNumber`, `Page`, `PageSize`
- `InvoiceViewingSynchronizationHttpRequest`: `StartDate`, `EndDate`
- `InvoiceViewingRenderHttpRequest`: `Profile`, `PreferEmbeddedXslt`, `FallbackToDefaultXslt` (JSON body'de `fallbackToGeneral` olarak gonderilir)
- `InvoiceViewingPrintedStateHttpRequest`: `IsPrinted`, `Source`
- `InvoicePreviewHttpRequest`: `InvoiceId`, `XmlContent`, `Profile`, `PreferEmbeddedXslt`
- `GET /api/fatura-islemleri/fatura-gonderimi` endpoint'i body almaz; query'de `StartDate`, `EndDate`, `Scenario` ve `isSent/SentState` kullanir
- `GET /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}` endpoint'i body almaz; `scenario` query parametresi kullanir
- `POST /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/render` endpoint'i body'de `InvoiceSendingRenderHttpRequest` alir
- `POST /api/fatura-islemleri/fatura-gonderimi/send` endpoint'i body'de `InvoiceSendingBatchHttpRequest` alir
- `POST /api/fatura-islemleri/fatura-goruntuleme/senkronize` endpoint'i body'de `InvoiceViewingSynchronizationHttpRequest` alir
- `GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}` ve `/pdf` endpointleri body almaz; `documentId` path parametresiyle Uyumsoft `GetInboxInvoicePdf` cagirir
- `GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}/detail` endpoint'i body almaz; HTML detay icin `documentId` path parametresi kullanir
- `POST /api/fatura-islemleri/fatura-goruntuleme/{documentId}/render` endpoint'i body'de `InvoiceViewingRenderHttpRequest` alir
- `PATCH /api/fatura-islemleri/fatura-goruntuleme/{documentId}/printed` endpoint'i body'de `InvoiceViewingPrintedStateHttpRequest` alir

### Operasyon Request Modelleri

- `SaveAuthorizationFileHttpRequest`: `Id`, `UpdateDate`, `Name`, `Z`, `R`, `X`
- `POST /api/operations/saveauthorizationfile` ve `POST /api/operations/authorization-files` body modeli tek obje degil, `IReadOnlyCollection<SaveAuthorizationFileHttpRequest>` dizisidir.

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
- `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/preview` endpoint'i body almaz; query'de `movementType` ve `take` kullanir; `movementType` bos ise `C01` kabul edilir, `C04` alias'i `C4` olarak sorgulanir
- `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/by-date` endpoint'i body almaz; query'de zorunlu `date` kullanir. Ornek: `date=2026-06-19`. Backend bu tarihi `yyyyMMdd` sayisal AXATA tarihine cevirip `ENT006.S06ITAR` alaninda filtreler
- `GET /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/{documentSerie}/{documentOrderNo}/preview` endpoint'i body almaz; `status` query parametresi opsiyoneldir ve sadece `0` veya `1` olabilir
- `POST /api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/{documentSerie}/{documentOrderNo}/import` body'de `status` ve `acknowledge` alir; `acknowledge=false` kontrollu rescue icin onerilir
- `ExecutionMode` su an yalnizca `DryRun` veya `Outbox` olabilir
- `dispatch` ve `dispatch-batch` endpoint'leri `ExecutionMode` almaz; bunlar dogrudan canli AXATA WCF gonderimidir
- `issued-warehouse-order-sync` dispatch payload'i worker parity icin `C01`, `company-receiving-sync` dispatch payload'i `G01` hareket kodu ile gonderilir
- `manual/tasks/{taskCode}/documents/preview` ve `manual/tasks/{taskCode}/documents/execute` request body alanlari task'a gore kullanilir:
  - `issued-warehouse-order-sync`: `DocumentSerie` + `DocumentOrderNo`
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
