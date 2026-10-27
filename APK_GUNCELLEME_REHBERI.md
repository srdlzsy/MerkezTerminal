# APK Guncelleme Rehberi

Bu rehber Android terminal guncellemesini daha kucuk APK dosyalariyla dagitmak icindir.

## 1. Versiyon Artir

`pubspec.yaml` icindeki `version` alanini artir.

`+` isaretinden sonraki temel build numarasi her yayinda artirilmalidir.
`--split-per-abi` kullanildiginda Flutter bu temel degere ABI farki ekler.
Bu nedenle terminalde gorunen gercek Android `versionCode`, `pubspec.yaml`
icindeki temel build numarasindan farkli olabilir.

Ornek:

```yaml
version: 1.1.104+2104
```

Kontrol:

```powershell
Select-String -Path pubspec.yaml -Pattern "^version:"
```

## 2. Test Et

```powershell
flutter analyze
flutter test
```

## 3. ABI Bazli APK Uret

```powershell
flutter build apk --release --split-per-abi
```

Olusan dosyalar:

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

Terminal cihazlar genelde `arm64-v8a` veya `armeabi-v7a` kullanir.

## 4. Istege Bagli Universal APK Uret

ABI eslesmezse fallback olarak universal APK kullanmak icin:

```powershell
flutter build apk --release
```

Olusan dosya:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 5. Sunucuya Surumlu Adla Kopyala

Ayni URL altinda eski APK'nin cache'ten gelmemesi icin her yayin farkli dosya
adi kullanmalidir. Sunucu klasorunu kendi ortamina gore degistir.

```powershell
$ServerPath = "\\10.0.0.100\Terminal"
$VersionName = "1.1.104"
$BuildNumber = "2104"
$ReleaseId = "$VersionName-$BuildNumber"

Copy-Item "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" "$ServerPath\furpa-terminal-$ReleaseId-arm64-v8a.apk" -Force
Copy-Item "build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" "$ServerPath\furpa-terminal-$ReleaseId-armeabi-v7a.apk" -Force
Copy-Item "build/app/outputs/flutter-apk/app-x86_64-release.apk" "$ServerPath\furpa-terminal-$ReleaseId-x86_64.apk" -Force
Copy-Item "build/app/outputs/flutter-apk/app-release.apk" "$ServerPath\furpa-terminal-$ReleaseId-universal.apk" -Force
```

## 6. version.json Guncelle

APK dosyalarini sunucuya kopyalayip URL'lerini kontrol ettikten sonra
`version.json` dosyasini en son yayinla. Coklu ABI dagitiminda APK'lar farkli
gercek `versionCode` degerleri tasidigi icin manifestte tek bir global
`buildNumber` yayinlama. Guncelleme karari `version` uzerinden verilir; indirilen
APK'nin gercek yapi numarasi kurulumdan once cihazdaki APK ile karsilastirilir.

Ornek yeni manifest (`version: 1.1.104+2104` icin):

```json
{
  "version": "1.1.104",
  "apk": "http://10.0.0.100:802/Terminal/furpa-terminal-1.1.104-2104-universal.apk",
  "android": {
    "universalUrl": "http://10.0.0.100:802/Terminal/furpa-terminal-1.1.104-2104-universal.apk",
    "apks": {
      "arm64-v8a": "http://10.0.0.100:802/Terminal/furpa-terminal-1.1.104-2104-arm64-v8a.apk",
      "armeabi-v7a": "http://10.0.0.100:802/Terminal/furpa-terminal-1.1.104-2104-armeabi-v7a.apk",
      "x86_64": "http://10.0.0.100:802/Terminal/furpa-terminal-1.1.104-2104-x86_64.apk"
    }
  }
}
```

`version: 1.1.104+2104` ile uretilen APK'larda beklenen gercek kodlar:

```text
universal:   2104
armeabi-v7a: 3104
arm64-v8a:   4104
x86_64:      6104
```

Bu nedenle arm64 terminalde `4104` gorulmesi normaldir. Manifestte global
`buildNumber: 2104` verilirse arm64 cihazdaki kurulu `4103` ile yanlis
karsilastirma yapilip guncelleme bulunamayabilir.

Eski uygulamalar sadece `apk` alanini okur. Yeni uygulamalar cihaz ABI'sine uygun APK'yi `android.apks` icinden secer.

Yeni uygulama indirdigi APK'nin paket adini, imzasini, `version` ve gercek
Android `versionCode` degerini kurulumdan once dogrular. Yanlis/eski APK
sunulursa kurulum ekrani acilmaz ve kullaniciya Turkce hata gosterilir.

## 7. Sunucudan Kontrol Et

```powershell
Invoke-WebRequest "http://10.0.0.100:802/Terminal/version.json" | Select-Object -ExpandProperty Content
Invoke-WebRequest "http://10.0.0.100:802/Terminal/furpa-terminal-1.1.104-2104-arm64-v8a.apk" -Method Head
Invoke-WebRequest "http://10.0.0.100:802/Terminal/furpa-terminal-1.1.104-2104-armeabi-v7a.apk" -Method Head
```

Kontrol listesi:

- APK URL'leri `200` donuyor mu?
- `Content-Length` sifirdan buyuk mu?
- APK release anahtariyla imzalandi mi?
- `version.json` icindeki `version`, APK ile ayni mi?
- Secilen ABI APK'sinin gercek `versionCode` degeri kurulu APK'dan buyuk mu?
- `version.json`, tum APK dosyalari kopyalandiktan sonra mi yayinlandi?

## 8. Hizli Tek Komut Akisi

```powershell
flutter analyze
flutter test
flutter build apk --release --split-per-abi
flutter build apk --release
```

Sonra APK dosyalarini surumlu adlarla sunucuya kopyala. URL'leri kontrol et ve
`version.json` dosyasini en son yeni `version` ile yayinla.

## 9. Guncelleme Tekrar Gorunuyorsa

Kurulumdan sonra ayni guncelleme tekrar cikiyorsa su noktalari kontrol et:

1. Android kurulum ekraninda `Kur` secenegine basildi mi? Sadece ekranin
   acilmasi kurulumun tamamlandigi anlamina gelmez.
2. Cihazda yeterli bos alan var mi? Uygulama artik indirmeden once alan kontrolu
   yapar ve yetersizse gerekli/kullanilabilir MB bilgisini gosterir.
3. Sunucudaki APK gercekten yeni `versionCode` degerini tasiyor mu?
4. APK ayni release sertifikasiyla imzalandi mi?
5. Sabit/eski bir APK URL'si cache'ten donuyor mu? Her yayin icin yukaridaki
   surumlu dosya adlarini kullan.

## 10. Terminalde Guncelleme Akisi

- Home ekraninda kurulu `versionName` ve Android `versionCode` birlikte
  gosterilir: `Surum 1.1.89 (90)`.
- `Kontrol` dugmesiyle sunucu manifesti elle yeniden kontrol edilebilir.
- Yeni surum varsa hedef surum Home ekraninda gorunur ve `Guncelle` dugmesi
  aktif olur.
- Indirme boyunca yuzde ve indirilen boyut gosterilir. APK paket adi, surumu,
  yapi numarasi ve imzasi dogrulanmadan Android kurulum ekrani acilmaz.
- Kurulum iptal edilirse Home ekraninda durum acikca belirtilir ve ayni gecerli
  APK tekrar indirilmeden kurulum yeniden acilir.
- Sonraki surum indirilirken eski APK cache dosyalari otomatik temizlenir.

