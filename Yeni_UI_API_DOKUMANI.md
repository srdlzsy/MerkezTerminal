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

### Kunye Etiket Yazdirma Detayli Liste

Belirli bir depo ve tarih icin kunye etiket kayitlarini stok kodu, stok adi, satis fiyati ve urun birimi bilgileriyle getirir. Mevcut `GET /api/kasa-islemleri/kunye-etiket-yazdirma` endpointi degismeden kalir; bu endpoint zengin response gereken ekranlar icindir.

`GET /api/kasa-islemleri/kunye-etiket-yazdirma/detayli-etiketler?warehouseNo=110&dateToGet=2026-04-24`

Yetki:

- `kasa-islemleri.kunye-etiket-yazdirma.list`

Query:

- `warehouseNo` zorunlu, 1 veya daha buyuk depo numarasi
- `dateToGet` zorunlu, sorgulanacak sevk tarihi

Not:

- response modeli `KunyeLabelTagDto` doner
- veri `[Furpa].[dbo].[VwKunyeNet]`, `[KUNYENET].[dbo].[FaturaIslem]`, `[KUNYENET].[dbo].[MuhStok]` ve Mikro `dbo.STOKLAR` joinlerinden okunur
- `salesPrice` alani Mikro `dbo.fn_StokSatisFiyati(stockCode, '1', branchNo, '1')` fonksiyonundan gelir
- tarih filtresi secilen gunun tamamini kapsar

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
- `movementType` alaninin karsiligi satir bazinda `sth_tip` kolonuna yazilir
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
  "movementTypes": [2],
  "lineCount": 1,
  "totalQuantity": 3,
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
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/{reportId}`
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
  -> depo ve tarih bazli zengin response icin GET /api/kasa-islemleri/kunye-etiket-yazdirma/detayli-etiketler?warehouseNo=...&dateToGet=...
  -> zengin liste satirlarini KunyeLabelTagDto ile goster
  -> detayli-etiketler endpointi token istemez
  -> yetki kodu kasa-islemleri.kunye-etiket-yazdirma.list

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
```

## Fatura Islemleri

Bu bolum 2026-05-06 tarihinde kaynak kod uzerinden yeniden dogrulanmistir.

Kodla dogrulanan ana dosyalar:

- `src/FurpaMerkezApi.WebApi/Controllers/Modules/FaturaIslemleri/FaturaGoruntuleme/FaturaGoruntulemeController.cs`
- `src/FurpaMerkezApi.Infrastructure/Modules/FaturaIslemleri/FaturaGoruntuleme/InvoiceViewingService.cs`
- `src/FurpaMerkezApi.Infrastructure/Modules/FaturaIslemleri/FaturaGoruntuleme/InvoiceViewingQueryExecutor.cs`
- `src/FurpaMerkezApi.Infrastructure/Modules/FaturaIslemleri/FaturaGoruntuleme/GetInvoiceViewingDocumentUseCase.cs`
- `src/FurpaMerkezApi.Infrastructure/Modules/FaturaIslemleri/FaturaGoruntuleme/RenderInvoiceViewingDocumentUseCase.cs`
- `src/FurpaMerkezApi.Infrastructure/Modules/FaturaIslemleri/FaturaGonderimi/InvoiceSendingService.cs`
- `src/FurpaMerkezApi.Infrastructure/Services/EInvoiceDocumentRenderer.cs`
- `src/FurpaMerkezApi.WebApi/Controllers/Modules/FaturaIslemleri/FaturaGonderimi/FaturaGonderimiController.cs`

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

UI tarafinda artik ayri iki operasyon mantigi vardir:

- `gonderim = Mikro bekleyen faturayi sec, onizle, Uyumsoft'a yolla`
- `goruntuleme = mevcut/gelen belgeyi ac, render et, yazdirildi durumunu yonet`

`fatura-gonderimi` tarafinda ayrica ileri seviye operasyonlar da acik tutulmustur:

- Uyumsoft outbox arama
- outbox belgesi render etme
- eldeki herhangi bir XML'i manuel preview etme

### UI Icin Kisa Karar Agaci

Mevcut API'yi kullanarak ilerleyecekseniz akisi su sekilde okuyun:

1. Mikro'daki bekleyen faturalari listelemek icin `GET /api/fatura-islemleri/fatura-gonderimi`
2. Kullanici bir bekleyen fatura satirina tiklayip onizleme acmak istediginde:
   - default davranis yeterliyse `GET /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}?scenario=...`
   - XSLT secimini elle kontrol etmek istiyorsaniz `POST /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/render`
3. Secilen bekleyen faturalari canli Uyumsoft'a gondermek icin `POST /api/fatura-islemleri/fatura-gonderimi/send`
4. Yeni eklendi: secilen tarih araligini Uyumsoft'tan cache tabloya almak icin `POST /api/fatura-islemleri/fatura-goruntuleme/senkronize`
5. Lokal cache/DB'deki gonderilmis belge listesini doldurmak icin `GET /api/fatura-islemleri/fatura-goruntuleme`
6. Gonderilmis belgeyi resmi PDF olarak acmak icin `GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}` veya `/pdf` alias'i kullanilir.
7. HTML render/onizleme gerekiyorsa:
   - default davranis yeterliyse `GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}/detail`
   - XSLT secimini elle kontrol etmek istiyorsaniz `POST /api/fatura-islemleri/fatura-goruntuleme/{documentId}/render`
8. Kullanici PDF/HTML'i gercekten yazdirdiktan veya acikca onay verdikten sonra `PATCH /api/fatura-islemleri/fatura-goruntuleme/{documentId}/printed`
9. Uyumsoft outbox tarafindaki giden faturayi sorgulamak gerekiyorsa `POST /api/fatura-islemleri/fatura-gonderimi/outbox/search`
10. Uyumsoft outbox'taki tekil belgeyi gostermek gerekiyorsa `GET /api/fatura-islemleri/fatura-gonderimi/outbox/{invoiceId}`
11. UI lokal veya baska bir kaynaktan XML uretip sadece goruntusunu gormek istiyorsa `POST /api/fatura-islemleri/fatura-gonderimi/preview`

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
- `documentId` bu listedeki operasyon anahtaridir; UI icinde row key olarak bunun saklanmasi gerekir
- `invoiceId` ekranda gostereceginiz fatura numarasidir; detay ve update bununla acilmaz
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
- PDF payload Uyumsoft response yapisina gore `scalarValue`, `nodes` veya `rawXml` icinde gelir; UI mevcut entegrasyon endpointindeki `GetInboxInvoicePdf` cevabi gibi yorumlamalidir.

Bu endpoint ne icin kullanilmali:

- kullanici liste satirina tiklayip faturanin resmi PDF'ini acmak istediginde
- fatura goruntuleme ekraninda varsayilan belge acma aksiyonu icin

Bu endpoint ne yapmaz:

- `isPrinted` alanini kendiliginden guncellemez
- kullanicinin "yazdirildi" karari yerine gecmez

### Fatura Goruntuleme HTML Detay

`GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}/detail`

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
- `xmlContent` debug, inceleme veya raw XML sekmesi icin kullanilabilir
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
      "scenario": "EFatura",
      "lineExtensionTotal": 1000.00,
      "taxTotal": 180.00,
      "chargeTotal": 0.00,
      "payableTotal": 1180.00,
      "shipmentDocumentNo": "IRS-001",
      "shipmentDocumentDate": "2026-05-05T00:00:00",
      "warehouseName": "MERKEZ DEPO",
      "description": "Aciklama"
    }
  ]
}
```

Davranis:

- kaynak veri Mikro `CARI_HESAP_HAREKETLERI`, `CARI_HESAPLAR`, `CARI_HESAP_ADRESLERI` ve `Furpa.dbo.FaturaSeries` ustunden okunur
- `Scenario = EFatura` icin yalniz e-fatura mukellefi ve e-fatura serisine bagli kayitlar gelir
- `Scenario = EArsiv` icin yalniz e-arsiv tarafina dusen kayitlar gelir
- `isSent/SentState = 0` ise `cha_belge_no` bos olan kayitlar, `1` ise dolu olan kayitlar, `-1` ise tumu doner
- `invoiceId` legacy WinForms mantigina uygun sekilde `seri + yil + 9 haneli sira` olarak uretilir
- `invoiceProfileId` alani:
  - e-fatura icin `TICARIFATURA` veya `TEMELFATURA`
  - e-arsiv icin `EARSIVFATURA`
- `invoiceTypeCode` alani:
  - `IADE`, `ISTISNA`, `OZELMATRAH`, `SATIS`

### Fatura Gonderimi Detay

`GET /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}?scenario=EFatura`

Yetki:

- `fatura-islemleri.fatura-gonderimi.detail`

Response `InvoiceSendingDetailDto`:

- `summary`: secilen bekleyen fatura satirinin ozeti
- `document`: UBL XML'den render edilmis `InvoiceRenderedDocumentDto`

Davranis:

- secilen kayit Mikro'dan okunur
- belge tipi stok faturasi ise satirlar `STOK_HAREKETLERI` uzerinden, hizmet/demirbas ise ilgili hizmet sorgusu uzerinden toplanir
- backend UBL invoice uretir
- render icin once embedded XSLT denenir; yoksa `Assets/Xslt/efatura.xslt` veya `Assets/Xslt/earsiv.xslt` fallback olur
- bu endpoint sadece onizleme/render icindir; Uyumsoft'a gonderim yapmaz

### Fatura Gonderimi Render

`POST /api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/render`

Yetki:

- `fatura-islemleri.fatura-gonderimi.detail`

Request:

```json
{
  "scenario": "EFatura",
  "profile": "Auto",
  "preferEmbeddedXslt": true,
  "fallbackToGeneral": true
}
```

Davranis:

- `GET detail` ile ayni `InvoiceSendingDetailDto` tipini doner
- farki, XSLT secimini body ile override edebilmenizdir

### Fatura Gonderimi Send

`POST /api/fatura-islemleri/fatura-gonderimi/send`

Yetki:

- `fatura-islemleri.fatura-gonderimi.create`

Request:

```json
{
  "scenario": "EFatura",
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
  "scenario": "EFatura",
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
- gonderim `batch SOAP array` yerine fatura bazli tek tek yapilir; boylece basarili/hatali kayitlar response icinde ayri ayri gorulur
- her belge icin UBL invoice uretilir ve Uyumsoft `SendInvoice` operasyonu cagrilir
- basarili donuste `serviceDocumentNumber` Mikro `cha_belge_no` alanina yazilir
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
- e-arsiv gonderiminde `EArchiveInvoiceInfo DeliveryType="Electronic"` kullanilir

### Fatura Gonderimi Outbox Arama

`POST /api/fatura-islemleri/fatura-gonderimi/outbox/search`

Yetki:

- `fatura-islemleri.fatura-gonderimi.list`

Request body:

- `UyumsoftOperationHttpRequest`

Davranis:

- bu endpoint Uyumsoft `GetOutboxInvoices` operasyonunu API icinden cagirir
- body icindeki `payloadXml` ve `parameters` dogrudan Uyumsoft sorgusuna aktarilir
- response normalize edilmis bir liste DTO'su degil, Uyumsoft'un genel response modelidir
- yani UI bu endpointte "backend business listesi" degil, "Uyumsoft sorgu cevabi" ile calisir

Response:

- `UyumsoftOperationResponseDto`

### Fatura Gonderimi Outbox Belge Render

`GET /api/fatura-islemleri/fatura-gonderimi/outbox/{invoiceId}?profile=Auto&preferEmbeddedXslt=true`

Yetki:

- `fatura-islemleri.fatura-gonderimi.detail`

Query:

```text
profile             opsiyonel; Auto, EFatura, EArsiv
preferEmbeddedXslt  opsiyonel; default true
```

Response `InvoiceRenderedDocumentDto`:

```json
{
  "source": "outbox",
  "invoiceId": "INV-2026-0001",
  "profile": "EFatura",
  "appliedXsltName": "efatura.xslt",
  "xsltSource": "asset-efatura",
  "usedEmbeddedXslt": false,
  "xmlContent": "<Invoice>...</Invoice>",
  "htmlContent": "<html>...</html>"
}
```

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

- is kurali tarafinda sade ozet sunudur: `fatura-gonderimi` bekleyen faturayi secip Uyumsoft'a yollama akisidir, `fatura-goruntuleme` ise Uyumsoft tarafindaki giden faturayi acma/yazdirma akisidir
- bu repoda `fatura-gonderimi` icin artik dogrudan pending list, detay/render ve send endpointleri vardir
- `fatura-goruntuleme` tarafi artik `uyumsoft_inbox_invoices` cache tablosundan liste alir; varsayilan acista Uyumsoft `GetInboxInvoicePdf` ile PDF datasini, HTML detayda `GetInboxInvoice` ile render datasini alir
- yeni eklendi: `POST /api/fatura-islemleri/fatura-goruntuleme/senkronize` ile secilen tarih araligi manuel olarak Uyumsoft'tan cache'e alinabilir
- `fatura-goruntuleme` icinde legacy'deki "goruntule" ve "yazdirildi say" ayrimi artik ayri endpointlerle temsil edilir
- `GET /{documentId}/detail` ile `POST render` ayni response tipini doner; fark, `POST render` ile XSLT davranisinin override edilebilmesidir
- `fatura-gonderimi` detail/send akisinda invoice XML Mikro verisinden backend tarafinda yeniden uretilir; UI ham XML kurmak zorunda degildir
- `fatura-gonderimi` send akisinda basarili sonuclarda Mikro `cha_belge_no` geri yazilir ve kayit kilitlenir
- render sirasinda once embedded XSLT denenir; yoksa WebApi icindeki `Assets/Xslt/efatura.xslt` veya `Assets/Xslt/earsiv.xslt` fallback olarak kullanilir
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
- `GET /api/integrations/axata-sync/live/audit/overview?startDate=2026-06-08&endDate=2026-06-08&warehouseNo=110&take=50`
  - eski worker calisirken Mikro ve AXATA arasindaki farklari kontrol eder; veri yazmaz
  - Mikro -> AXATA siparis tarafinda `ssip_special1` worker basari bayragini raporlar
  - AXATA -> Mikro sevk tarafinda `getOutBoundDeliveryListAsync` ile `C01/C02/C03/C4`, `Status=0` kuyrugunu okur
  - C01 icin Mikro siparis satiri ve sevk fisi linkini de kontrol eder
  - response `AxataIntegrationAuditDto`
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
- `GET /api/integrations/axata-sync/manual/tasks/{taskCode}/documents/candidates?warehouseNo=1&startDate=2026-04-23&endDate=2026-04-29&take=25`
  - manuel kurtarma icin uygun evrak adaylarini listeler
  - response `AxataSynchronizationManualDocumentCandidatesDto`
- `POST /api/integrations/axata-sync/manual/tasks/{taskCode}/documents/preview-batch`
  - secilen birden fazla evrak icin toplu payload preview doner
  - response `AxataSynchronizationManualDocumentBatchDto`
- `POST /api/integrations/axata-sync/manual/tasks/{taskCode}/documents/execute-batch`
  - secilen birden fazla evrak icin toplu `DryRun` veya `Outbox` calistirir
  - response `AxataSynchronizationManualDocumentBatchDto`
  - `ContinueOnError = true` ise hatali evraklar `Failures` icine yazilir, diger evraklar devam eder
- `POST /api/integrations/axata-sync/manual/tasks/{taskCode}/documents/dispatch`
  - secilen tek evraki eski AXATA worker kontratina uygun SOAP envelope ile canli gonderir
  - response `AxataSynchronizationManualDispatchDto`
  - su an `issued-warehouse-order-sync` ve `company-receiving-sync` icin tanimlidir
- `POST /api/integrations/axata-sync/manual/tasks/{taskCode}/documents/dispatch-batch`
  - secilen birden fazla evraki canli SOAP dispatch ile toplu gonderir
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
  "warehouseNo": 1
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

Bu cagri veri yazmaz. Amaci eski worker calisirken durumu anlamaktir:

- `isInSync=true` ise secili tarih araliginda Mikro siparis bayraklari tamam ve AXATA pending sevk kuyrugu bos demektir
- `unsyncedWarehouseOrders` Mikro'da olup worker basari bayragi tum satirlarda `1` olmayan depolar arasi siparisleri gosterir
- `pendingOutboundDeliveries` AXATA'da `Status=0` bekleyen sevkleri gosterir
- `interventionCandidates` C01 icin guvenli mudahale adaylarini gosterir
- `MikroShipmentExistsPendingAck` ise Mikro fis/link zaten vardir; duplicate fis acmadan sadece AXATA ack gerekebilir
- `ReadyForImport` ise Mikro siparis satiri eslesmistir ama sevk fisi yoktur; C01 import ile mudahale edilebilir

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
- Satir eslesme: `S07KALN + S07SKOD` -> `ssip_satirno + ssip_stok_kod`
- Mikro yazim: depolar arasi sevk fisi, `STOK_HAREKETLERI_EK.sth_subesip_uid` linki ve `ssip_teslim_miktar` guncellemesi
- AXATA ack: Mikro yazim basarili olursa `AxataServicePoolEXT.svc/updIntegrationTableAsync` ile `ENT006.S06STAT=1`, `IDField=S06SIRA`
- `acknowledge=false` verilirse Mikro yazilir ama AXATA status guncellenmez; bu sadece kontrollu test/kurtarma icin kullanilmalidir

Ornek manuel evrak preview:

```http
POST /api/integrations/axata-sync/manual/tasks/issued-warehouse-order-sync/documents/preview
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "warehouseNo": 1,
  "documentSerie": "SFR",
  "documentOrderNo": 2451
}
```

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
  - AXATA outbound delivery verisi eldeyse `manual/axata/outbound-deliveries/inter-warehouse-shipments` ile dogrudan Mikro sevki yaz
  - AXATA inbound ATF verisi eldeyse `manual/axata/inbound-atf/company-receivings` ile dogrudan Mikro firma mal kabule cevir
  - AXATA ham verisi operasyon tarafinda toparlanmis ise `manual/incoming/company-receivings` veya `manual/incoming/inventory-counts` kullan
  - coklu belge geliyorsa `.../company-receivings/batch` veya `.../inventory-counts/batch` ile tek cagrida islenebilir
  - depo sevki zaten bekleyen belge olarak Mikro'ya dusmus ama kabulde takildiysa once `manual/incoming/warehouse-receivings` ile listele, gerekirse detay endpoint'i ile satirlari kontrol et, sonra `.../accept` veya `.../accept-batch` kullan
- Not:
  - C01 icin backend AXATA'dan canli SOAP fetch yapar; C02/C03/C04/G01/G02 fetch-import akislari ayri fazdir
  - `dispatch` endpoint'leri AXATA'ya canli yazim yapar; `execute` endpoint'leri ise sadece `DryRun/Outbox` icindir
  - eski worker operasyon isimleri kullanildigi icin canli AXATA dispatch sahada endpoint/credential ile dogrulanmalidir

Entegrasyon modulu notlari:

- worker ve scheduler backend tarafinda hosted service olarak calisir
- scheduler config ile kapali acilabilir; UI bunu overview ekraninda gostermelidir
- `preview` endpoint'i canli veriyi okur, test/mock veri kullanmaz
- `issued-warehouse-order-sync`, `company-receiving-sync` ve `inventory-count-sync` task'larinda `warehouseNo` gerekir
- `firm-master-sync` ve `product-master-sync` depo bagimsiz task'lardir
- `manual/tasks/{taskCode}/documents/*` endpoint'leri yalnizca evrak bazli task'larda kullanilmalidir
- `manual/tasks/{taskCode}/documents/dispatch*` endpoint'leri yalnizca AXATA'ya canli gonderim icindir; `Outbox` yerine kullanilir
- `manual/incoming/*` endpoint'leri worker'dan bagimsiz operasyonel kurtarma katmanidir
- `manual/axata/*` endpoint'leri AXATA-native request body'sini minimum donusumle Mikro write use-case'lerine baglar
- `live/audit/overview` endpoint'i eski worker calisirken kontrol/durum tespiti icindir; Mikro veya AXATA verisi yazmaz
- `live/axata/outbound-deliveries/c01/*` endpoint'leri AXATA'dan canli C01 cekip Mikro'ya yazar; AXATA ack sadece Mikro kaydi basarili olursa atilir
- `live/axata/outbound-deliveries/c01/import` gerekiyorsa mudahale icindir; mevcut worker'in yerine otomatik calisan yeni worker olarak dusunulmemelidir
- toplu endpoint'lerde `ContinueOnError = true` ise HTTP 200 donup basarisiz item'lari `Failures` listesinde raporlar
- `Outbox` modu su an gercek SOAP dispatch degil, payload uretim ve dosyalama asamasidir
- canli AXATA belge fetch/ack adapter'i su an C01 depo sevki icin aktiftir; diger hareket tipleri planli profildir
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
- AXATA inbound ATF verisi operasyon ekibinin elindeyse ve Mikro'da firma mal kabul yaratilacaksa:
  - `manual/axata/inbound-atf/company-receivings`
- Sevk zaten Mikro'ya dusmus ama kabulde takilmissa:
  - `manual/incoming/warehouse-receivings`
  - detail endpoint'i
  - `.../accept` veya `.../accept-batch`

UI'nin kullaniciya acik soylemesi gereken kritik sinirlar:

- C01 depo sevki icin AXATA'dan canli SOAP fetch/import vardir
- C02/C03/C04/G01/G02 icin "AXATA'dan cek ve Mikro'ya yaz" akisi henuz yoktur
- `dispatch*` endpoint'leri sadece `issued-warehouse-order-sync` ve `company-receiving-sync` icin aktiflenmelidir
- `depolar-arasi-sevk` belge detayi icin ayrica AXATA dispatch butonu acilmamalidir
- `firm-master-sync` ve `product-master-sync` icin UI sadece preview/job/outbox deneyimi sunmalidir
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
  - planli profiller: `C02`, `C03`, `C04(query C4)`, `G01`, `G02`
  - beklenen akis:
    - profil sec
    - preview al
    - secili kayitlari import et
    - import basariliysa ack sonucu goster
- `Ack/Retry Monitor` sekmesi
  - amac: AXATA'ya ack atilamayan veya yarim kalmis entegrasyonlari operasyon ekibi gorsun
  - bu ekran ancak backend'de kalici audit/retry tablolari eklenirse anlamli olur
- `Transport Profili` sekmesi
  - amac: task'in `V1` mi `V2` mi SOAP operasyonu kullanacagini gostermek
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
- controller ve request contract'lari tanimlidir
- tum endpoint'ler su an `501 Not Implemented` doner
- response modeli `ModuleActionScaffoldResponse`'dur
- yani UI ekrani cizilebilir, fakat business veri beklenmemelidir

UI bu menuyu tek sayfa icinde 4 tab olarak kurgulamalidir:

1. `Z Raporlari`
2. `POS Faturalar`
3. `Gider Pusulalari`
4. `Kasa Eslemeleri`

#### Z Raporlari Tab'i

Bu tab'in hedefi gelecekte su akisi yurutmektir:

- kullanici tarih ve depo baglamini secer
- secili import kaynagina gore Z raporlari staging alana okunur
- belge baslik, KDV satiri ve odeme satiri bazinda incelenir
- secilen raporlar ERP muhasebe fisine donusturulur
- hatali veya tekrarli importlar loglanir

Scaffold endpoint'ler:

- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari`
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/{reportId}`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/ice-aktar`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/erpye-gonder`
- `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari`

UI beklentisi:

- liste ekraninda durum, tarih, Z no, kasa no, sube ve toplam kolonlari hazir dusunulmelidir
- detay ekraninda header + KDV satirlari + odeme satirlari alt panelli dusunulmelidir
- `ice aktar` butonu ayrik bir dialog ile acilmalidir
- `ERP'ye gonder` aksiyonu coklu secim ile calisacakmis gibi tasarlanmalidir
- `sil` aksiyonu staging kaydi temizleme semantigiyle ele alinmalidir; ERP'de olusmus fis silme butonu gibi sunulmamalidir

#### POS Faturalar Tab'i

Bu tab'in hedefi gelecekte POS kaynakli satis faturalarini once staging'e alip sonra ERP'ye aktarmaktir.

Scaffold endpoint'ler:

- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar`
- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/{invoiceId}`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/ice-aktar`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/erpye-gonder`
- `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/{invoiceId}`
- `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar`

UI beklentisi:

- liste ekraninda tarih bazli veri cekme aksiyonu vardir
- detay ekraninda `documentNo`, `customerTaxNo`, `paymentType`, `branchNo`, `description` duzenleme alanlari dusunulmelidir
- satir duzeyi guncelleme bu surumde contract'ta yoktur; ekran agirlikla ust belge duzenleme mantigiyla tasarlanmalidir
- kullanici daha sonra ERP gonderimi icin birden fazla fatura secebilecekmis gibi secim modeli hazir tutulmalidir

#### Gider Pusulalari Tab'i

Bu tab, POS gider pusulasi staging ve ERP'ye aktarim akisinin web karsiligidir.

Scaffold endpoint'ler:

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

#### Kasa Eslemeleri Tab'i

Bu tab'in amaci yazar kasa / cihaz no ile sube arasindaki eslemeyi yonetmektir.

Scaffold endpoint'ler:

- `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri`
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri`
- `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri/{mappingId}`

UI beklentisi:

- bu tab master-data ekranidir; tarih filtresi gerektirmez
- grid inline edit veya drawer edit mantigi uygundur
- minimum alanlar `cashRegisterNo` ve `branchNo` olarak dusunulmelidir

#### UI Durum Yonetimi

Bu menu scaffold oldugu icin UI tarafinda su davranis onerilir:

- route acik olsa da ilk cagrida `501` gelirse ekran "hazir ama backend baglanmadi" uyarisina dussun
- `ModuleActionScaffoldResponse.message` kullaniciya dogrudan gosterilebilir
- tab'ler simdiden cizilebilir, ama kayit listeleri yerine placeholder / empty-state kartlari kullanilmalidir
- aksiyon butonlari gorunsun fakat tiklandiginda backend `501` cevabi kullaniciya net anlatilsin

#### Gelecek Faz Icin Ekran Beklentisi

Bu menu ileride gercek implementasyona gectiginde UI'nin tekrar buyuk refactor istememesi icin su omurga korunmalidir:

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

- bu bolumde anlatilan is akislarinin buyuk kismi hedef tasarimdir
- bugun dogrulanabilen durum, yalnizca route + yetki + HTTP contract + scaffold response varligidir
- gercek veri modeli ve business response DTO'lari backend implementasyon fazinda netlesecektir

#### Mevcut Request / Response Kontratlari

Bu menu su an scaffold oldugu icin `liste`, `detay`, `import`, `gonder`, `sil` ve `guncelle` endpoint'lerinin tumu response olarak ayni modeli doner:

- `ModuleActionScaffoldResponse`

Yani bugunku backend durumunda:

- ozel `ZReportListItemDto`
- ozel `PosInvoiceDetailDto`
- ozel `ExpenseNoteDetailDto`
- ozel `CashRegisterBranchMappingDto`

gibi business response DTO'lari henuz yoktur.

UI tarafi bu fazda response'u su mantikla ele almalidir:

- `isImplemented = false`
- `message = backend iskelet endpoint aciklamasi`
- `moduleCode`, `menuCode`, `actionCode` alanlari ile ekran aksiyonu eslenebilir

Endpoint bazli request / response ozet tablosu:

| Endpoint | Request kaynagi | Request modeli | Mevcut response |
|---|---|---|---|
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi` | body yok | body yok | `ModuleActionScaffoldResponse` |
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari` | query | `PosAccountingDateRangeHttpRequest` | `ModuleActionScaffoldResponse` |
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/{reportId}` | path | `reportId: Guid` | `ModuleActionScaffoldResponse` |
| `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/ice-aktar` | body | `ImportZReportsHttpRequest` | `ModuleActionScaffoldResponse` |
| `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/erpye-gonder` | body | `PosAccountingTransferHttpRequest` | `ModuleActionScaffoldResponse` |
| `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari` | body | `PosAccountingDeleteHttpRequest` | `ModuleActionScaffoldResponse` |
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar` | query | `PosAccountingDateRangeHttpRequest` | `ModuleActionScaffoldResponse` |
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/{invoiceId}` | path | `invoiceId: Guid` | `ModuleActionScaffoldResponse` |
| `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/ice-aktar` | body | `ImportPosDocumentsHttpRequest` | `ModuleActionScaffoldResponse` |
| `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/erpye-gonder` | body | `PosAccountingTransferHttpRequest` | `ModuleActionScaffoldResponse` |
| `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/{invoiceId}` | body | `UpdatePosAccountingDocumentHttpRequest` | `ModuleActionScaffoldResponse` |
| `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar` | body | `PosAccountingDeleteHttpRequest` | `ModuleActionScaffoldResponse` |
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari` | query | `PosAccountingDateRangeHttpRequest` | `ModuleActionScaffoldResponse` |
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/{expenseId}` | path | `expenseId: Guid` | `ModuleActionScaffoldResponse` |
| `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/ice-aktar` | body | `ImportPosDocumentsHttpRequest` | `ModuleActionScaffoldResponse` |
| `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/erpye-gonder` | body | `PosAccountingTransferHttpRequest` | `ModuleActionScaffoldResponse` |
| `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/{expenseId}` | body | `UpdatePosAccountingDocumentHttpRequest` | `ModuleActionScaffoldResponse` |
| `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari` | body | `PosAccountingDeleteHttpRequest` | `ModuleActionScaffoldResponse` |
| `GET /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri` | query | `CashRegisterBranchMappingListHttpRequest` | `ModuleActionScaffoldResponse` |
| `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri` | body | `CashRegisterBranchMappingHttpRequest` | `ModuleActionScaffoldResponse` |
| `PUT /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri/{mappingId}` | body | `CashRegisterBranchMappingHttpRequest` | `ModuleActionScaffoldResponse` |

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
    public string? ImportMode { get; init; }
    public string? SourceCode { get; init; }
    public bool OverwriteExisting { get; init; }
}

public sealed class ImportPosDocumentsHttpRequest
{
    public int? WarehouseNo { get; init; }
    public DateTime? BusinessDate { get; init; }
    public bool IncludePreviouslyImported { get; init; }
    public bool OverwriteExisting { get; init; }
}

public sealed class PosAccountingTransferHttpRequest
{
    public int? WarehouseNo { get; init; }
    public IReadOnlyCollection<Guid> DocumentIds { get; init; }
    public bool ContinueOnError { get; init; } = true;
}

public sealed class PosAccountingDeleteHttpRequest
{
    public int? WarehouseNo { get; init; }
    public IReadOnlyCollection<Guid> DocumentIds { get; init; }
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

Mevcut response modeli:

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
```

Ornek scaffold response:

```json
{
  "moduleCode": "entegrasyon-islemleri",
  "moduleName": "EntegrasyonIslemleri",
  "menuCode": "pos-muhasebe-aktarimi",
  "menuName": "PosMuhasebeAktarimi",
  "actionCode": "list",
  "actionName": "Listele",
  "httpMethod": "GET",
  "permissionCode": "entegrasyon-islemleri.pos-muhasebe-aktarimi.list",
  "route": "/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar",
  "resourceId": null,
  "isImplemented": false,
  "message": "Bu endpoint iskelet olarak acildi. Is kurali ve Mikro veritabani entegrasyonu sonraki adimda baglanacak."
}
```

## Uyumsoft Entegrasyonu

Detayli ve Uyumsoft odakli ayri dokuman icin bkz. [UYUMSOFT_ENTEGRASYON_DOKUMANI.md](UYUMSOFT_ENTEGRASYON_DOKUMANI.md).

Bu bolum, yeni eklenen Uyumsoft connected-service query modullerini anlatir. Bu moduller operasyonel sevk/iade ekranlarindaki mevcut `e-irsaliye gonder` ve `PDF getir` endpoint'lerinin yerine gecmez; onlar mevcut business akislari icin kullanilmaya devam eder. Yeni moduller, daha cok entegrasyon/operasyon destek ekibi icin "Uyumsoft'ta ne var, hangi GET operasyonlari acik, ilgili dokuman/paged query sonucu ne donuyor" ihtiyacini karsilar.

Bu entegrasyonun kapsami:

- Uyumsoft `BasicIntegration` servisi icin `e-fatura` query modulu
- Uyumsoft `BasicDespatchIntegration` servisi icin `e-irsaliye` query modulu
- sadece whitelist'e alinmis `Get*` operasyonlarinin acilmasi
- request body'sinde scalar parametre + XML fragment (`payloadXml`) destegi
- response'un generic ve recursive bir agac modeli ile normalize edilmesi
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
- operasyonel belge tekrar sorgulama ve raw XML inceleme
- portal parity amacli alias/kullanici listeleme
- query builder bazli ileri seviye filtre ekranlari
- `SendInvoice`, `SendDespatch`, `SaveAsDraft`, `TransformAndSend` gibi yazan operasyonlar icin ayni route ailesinin genisletilmesi

Mevcut business akislardan farki:

- `POST /api/sevk-islemleri/.../e-irsaliye` ailesi mevcut Mikro evragini okuyup Uyumsoft'a gonderir
- bu yeni moduller ise Uyumsoft'un kendi GET operasyonlarini dogrudan query eder
- yeni moduller Mikro'da yeni evrak kesmez
- yeni moduller `invoiceId`, `despatchId`, `query`, `request` gibi Uyumsoft-side parametrelerle calisir
- UI bu modulleri normal depo/firma sevk detay ekraninda ana aksiyon gibi degil, entegrasyon/yonetim araci gibi konumlandirmalidir

### Route Aileleri

#### E-Fatura

- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/operations`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/{operationName}`
- `POST /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/{operationName}`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/system/date`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/system/date/formatted?format=yyyy-MM-dd`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceId}`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceId}/data`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceId}/view`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceId}/pdf`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceId}/status-with-logs`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceId}`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceId}/data`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceId}/view`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceId}/pdf`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceId}/status-with-logs`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceId}/response-view`
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/invoices/{invoiceId}/envelope`

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

Backend, `userInfo` bilgisini UI'dan almaz; server-side config ile SOAP envelope icine kendisi yerlestirir. Bu nedenle UI kullanicisi username/password gormez ve gondermez.

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

- `payloadXml` opsiyonel
- `parameter` tekrar eden query parametresidir ve `name=value` formatinda gonderilir

Response:

- `UyumsoftOperationResponseDto`

Not:

- browser, test araci veya hizli operator kullanimi icin pratiktir
- kisa scalar parametreli operasyonlarda UI dogrudan bu route'u kullanabilir
- uzun veya kompleks XML payload'lar icin URL encode ve uzunluk sebepleriyle `POST` tercih edilmelidir
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
- `payloadXml` ile kompleks `<query>...</query>` veya `<request>...</request>` yapilari gonderilecekse ana tercih bu route olmalidir

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

- `payloadXml` opsiyoneldir
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

Not:

- `payloadXml` query string ile de gonderilebilir; ancak gercek UI akislari icin uzun XML'lerde `POST` kullanmak daha guvenlidir

### `POST` Request Body Formati

Tek endpoint uzerinden farkli operasyonlar cagirildigi icin request body'si generic tutulmustur.

Model:

```json
{
  "payloadXml": "<query>...</query>",
  "parameters": [
    { "name": "format", "value": "yyyy-MM-dd" }
  ]
}
```

Alan kurallari:

- `parameters`
  - scalar child element'ler icin kullanilir
  - ornek: `format`, `invoiceId`, `despatchId`, `isInbox`
- `payloadXml`
  - kompleks query/request objeleri icin kullanilir
  - root wrapper gerekmez; backend bunu kendisi fragment olarak parse eder
  - gonderilen XML, Uyumsoft operasyonunun bekledigi child element adi ile baslamalidir
  - ornek: `<query>...</query>`, `<request>...</request>`
- `parameters` ve `payloadXml` birlikte kullanilabilir

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

Paged e-irsaliye outbox listesi:

```http
POST /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/get/GetOutboxDespatchList
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "payloadXml": "<query><PageIndex>1</PageIndex><PageSize>20</PageSize><IsArchived>false</IsArchived></query>"
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
- path'te `/pdf` gecmesi binary dosya indirilecegi anlamina gelmez; PDF verisi response icindeki node/attribute/rawXml alanlarinda gelir

UI request form onerisi:

- operasyon secildiginde `requestHint` alani yardim metni olarak gosterilsin
- "scalar parametre" ve "payloadXml" ayni ekranda ama ayrik bloklar halinde sunulsun
- `payloadXml` icin monospaced multiline editor kullanilsin
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
- `rawXml`

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
- `rawXml`
  - SOAP body'nin tamamini degil, ilgili `...Result` element'inin XML'ini verir
  - debug/raw inceleme sekmesi icin uygundur

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
  - invalid `payloadXml`
  - katalogda olmayan `operationName`
- `401 Unauthorized`
  - token yok/gecersiz
- `403 Forbidden`
  - ilgili module permission'i yok
- `409 Conflict`
  - Uyumsoft remote service request'i reddetti
  - SOAP fault dondu
  - server-side endpoint/credential/config eksik
- `500 Internal Server Error`
  - beklenmeyen parse/runtime problemi

UI notu:

- `409` cevaplarini "servis reddetti / uzak servis cevabi" gibi kullaniciya daha anlamli bir dille gostermek dogru olur
- `400` cevaplari ise lokal request form hatasi gibi ele alinmalidir

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
  - dynamic form + payloadXml editor
- `Sonuc` sekmesi
  - summary
  - tree
  - raw xml
- opsiyonel `Template/History` alanlari
  - son kullanilan operasyon parametreleri
  - sik kullanilan query XML'leri

UI'nin dikkat etmesi gereken sinirlar:

- backend sadece katalogdaki operasyonlari cagirir
- UI operationName'i manuel string olarak uretmemelidir
- `payloadXml` dogrudan XML fragment oldugu icin text-area validation ve escaping konusunda dikkatli davranilmalidir
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
    string RawXml);

public sealed record UyumsoftResponseNodeDto(
    string Name,
    string? Value,
    IReadOnlyDictionary<string, string?> Attributes,
    IReadOnlyCollection<UyumsoftResponseNodeDto> Children);
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
    string RequestXml,
    string ResponseXml,
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
    IReadOnlyCollection<AxataOutboundDeliveryMovementSummaryDto> OutboundDeliverySummaries,
    IReadOnlyCollection<AxataUnsyncedWarehouseOrderDto> UnsyncedWarehouseOrders,
    IReadOnlyCollection<AxataPendingOutboundDeliveryDto> PendingOutboundDeliveries,
    IReadOnlyCollection<AxataPendingOutboundDeliveryDto> InterventionCandidates,
    IReadOnlyCollection<string> Notes);

public sealed record AxataIntegrationAuditSummaryDto(
    int MikroWarehouseOrderDocumentCount,
    int SentWarehouseOrderDocumentCount,
    int PartiallySentWarehouseOrderDocumentCount,
    int UnsentWarehouseOrderDocumentCount,
    int PendingOutboundDeliveryDocumentCount,
    int PendingOutboundDeliveryLineCount,
    double PendingOutboundDeliveryQuantity,
    int C01PendingDocumentCount,
    int C01MissingInMikroDocumentCount,
    int C01MikroExistsPendingAckDocumentCount);

public sealed record AxataOutboundDeliveryMovementSummaryDto(
    string MovementType,
    string PendingStatus,
    int PendingDocumentCount,
    int PendingLineCount,
    double PendingQuantity,
    int MikroMissingDocumentCount,
    int MikroExistsPendingAckDocumentCount,
    string CheckLevel);

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
- `LabelPriceChangedProductListHttpRequest`: `DateTimeFilter`
- `CreateLabelDocumentHttpRequest`: `Lines`
- `CreateLabelDocumentLineHttpRequest`: `ProductCode`

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
- `POST /api/fatura-islemleri/fatura-gonderimi/outbox/search` body'de `UyumsoftOperationHttpRequest` alir
- `POST /api/fatura-islemleri/fatura-goruntuleme/senkronize` endpoint'i body'de `InvoiceViewingSynchronizationHttpRequest` alir
- `GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}` ve `/pdf` endpointleri body almaz; `documentId` path parametresiyle Uyumsoft `GetInboxInvoicePdf` cagirir
- `GET /api/fatura-islemleri/fatura-goruntuleme/{documentId}/detail` endpoint'i body almaz; HTML detay icin `documentId` path parametresi kullanir
- `POST /api/fatura-islemleri/fatura-goruntuleme/{documentId}/render` endpoint'i body'de `InvoiceViewingRenderHttpRequest` alir
- `PATCH /api/fatura-islemleri/fatura-goruntuleme/{documentId}/printed` endpoint'i body'de `InvoiceViewingPrintedStateHttpRequest` alir
- `GET /api/fatura-islemleri/fatura-gonderimi/outbox/{invoiceId}` endpoint'i body almaz; `invoiceId` path parametresiyle birlikte `profile` ve `preferEmbeddedXslt` query parametrelerini kullanir

### Operasyon Request Modelleri

- `SaveAuthorizationFileHttpRequest`: `Id`, `UpdateDate`, `Name`, `Z`, `R`, `X`
- `POST /api/operations/saveauthorizationfile` ve `POST /api/operations/authorization-files` body modeli tek obje degil, `IReadOnlyCollection<SaveAuthorizationFileHttpRequest>` dizisidir.

### Entegrasyon Request Modelleri

- `UyumsoftOperationHttpRequest`: `PayloadXml`, `Parameters`
- `UyumsoftOperationParameterHttpRequest`: `Name`, `Value`
- `AxataSynchronizationExecuteHttpRequest`: `TaskCode`, `ExecutionMode`, `WarehouseNo`
- `AxataSynchronizationExecuteTaskHttpRequest`: `ExecutionMode`, `WarehouseNo`
- `AxataSynchronizationManualDocumentCandidatesHttpRequest`: `WarehouseNo`, `StartDate`, `EndDate`, `Take`
- `AxataIntegrationAuditHttpRequest`: `StartDate`, `EndDate`, `WarehouseNo`, `Take`
- `AxataOutboundDeliveryImportPreviewHttpRequest`: `Take`
- `AxataOutboundDeliveryImportExecuteHttpRequest`: `Take`, `ContinueOnError`, `Acknowledge`
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
- `ImportZReportsHttpRequest`: `WarehouseNo`, `BusinessDate`, `ImportMode`, `SourceCode`, `OverwriteExisting`
- `ImportPosDocumentsHttpRequest`: `WarehouseNo`, `BusinessDate`, `IncludePreviouslyImported`, `OverwriteExisting`
- `PosAccountingTransferHttpRequest`: `WarehouseNo`, `DocumentIds`, `ContinueOnError`
- `PosAccountingDeleteHttpRequest`: `WarehouseNo`, `DocumentIds`
- `UpdatePosAccountingDocumentHttpRequest`: `DocumentNo`, `CustomerTaxNo`, `PaymentType`, `BranchNo`, `Description`
- `CashRegisterBranchMappingListHttpRequest`: `BranchNo`, `CashRegisterNo`
- `CashRegisterBranchMappingHttpRequest`: `CashRegisterNo`, `BranchNo`, `BranchName`, `Description`
- `GET /api/integrations/axata-sync/tasks/{taskCode}/preview` endpoint'i body almaz; `warehouseNo` ve `take` query parametresi kullanir
- `GET /api/integrations/axata-sync/manual/tasks/{taskCode}/documents/candidates` endpoint'i body almaz; `warehouseNo`, `startDate`, `endDate`, `take` query parametresi kullanir
- `ExecutionMode` su an yalnizca `DryRun` veya `Outbox` olabilir
- `dispatch` ve `dispatch-batch` endpoint'leri `ExecutionMode` almaz; bunlar dogrudan canli AXATA SOAP gonderimidir
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
- `POST /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/*/erpye-gonder` ve `DELETE /api/entegrasyon-islemleri/pos-muhasebe-aktarimi/*` endpoint'leri secili belge listesi bekler; `DocumentIds[]` GUID koleksiyonudur
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
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/get/{operationName}` ve `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/get/{operationName}` endpoint'leri body almaz; opsiyonel `payloadXml` ve tekrar eden `parameter=name=value` query parametresi kullanir.
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/system/date/formatted` endpoint'i `format` query parametresi alir.
- `GET /api/entegrasyon-islemleri/uyumsoft/e-fatura/.../{invoiceId}` alias route'lari `invoiceId` path parametresiyle calisir.
- `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/.../{despatchId}` alias route'lari `despatchId` path parametresiyle calisir; `GET /api/entegrasyon-islemleri/uyumsoft/e-irsaliye/despatches/{despatchId}/envelope` icin ek olarak `isInbox` query parametresi zorunludur.
- Cok sayida detay endpointi ayri request class'i kullanmaz; path parametreleri ve opsiyonel `warehouseNo` query parametresi ile calisir.
- `GET /api/kasa-islemleri/etiket-belgeleri`, `GET /api/kasa-islemleri/etiket-belgeleri/son`, `GET /api/kasa-islemleri/etiket-belgeleri/tumu` ve `GET /api/kasa-islemleri/etiket-belgeleri/{documentId}` endpointleri ayri request class'i yerine dogrudan action parametreleri kullanir.
- `LabelPriceChangedProductListHttpRequest.DateTimeFilter` alaninin beklenen formati `dd.MM.yyyy HH:mm:ss` degeridir.
