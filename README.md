# Furpa Merkez Terminal

## Proje Rehberi

Projenin calisma mantigi, klasor yapisi, menu akisi, offline sistem ve yeni ozellik ekleme adimlari icin:

`PROJE_CALISMA_REHBERI.md`

Flutter tabanli Furpa merkez el terminali uygulamasi.

## API Konfigürasyonu

Varsayilan API adresi:

`http://192.168.254.214:7508`

Uygulama bu adresi varsayilan olarak kullanir. Gerektiginde derleme aninda `dart-define` ile override edebilirsiniz:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.254.214:7508
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.254.214:7508
```

Isterseniz platform bazli override da verebilirsiniz:

```bash
flutter run --dart-define=API_BASE_URL_ANDROID=http://192.168.254.214:7508
flutter run --dart-define=API_BASE_URL_DESKTOP=http://localhost:7508
```

## Android Release

Android release build artik `android/key.properties` dosyasi varsa onu kullanir. Ornek dosya:

`android/key.properties.example`

Izlenecek adimlar:

1. Kendi upload keystore dosyanizi olusturun veya mevcut keystore'unuzu kullanin.
2. `android/key.properties.example` dosyasini `android/key.properties` olarak kopyalayip gercek bilgilerle doldurun.
3. `storeFile` alanini `android/` klasorune gore verin. Ornek: `app/upload-keystore.jks`
4. Ardindan release paket alin:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=http://192.168.254.214:7508
```

`key.properties` yoksa build debug signing ile devam eder; bu paket test icin kullanilabilir ama Play Store yayini icin uygun degildir.

## Yayin Notlari

- Android release icin internet izni ve cleartext HTTP destegi acilmistir.
- iOS tarafinda HTTP API icin App Transport Security istisnasi eklenmistir.
- Verilen API adresi ozel ag IP'sidir (`192.168.x.x`). Uygulama sadece ayni agda veya VPN uzerinden bu sunucuya erisebilir.
- Web yayini dusunuluyorsa HTTP yerine HTTPS ve uygun CORS/proxy yapisi gereklidir.
