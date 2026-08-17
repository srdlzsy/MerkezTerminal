# APK Guncelleme Rehberi

Bu rehber Android terminal guncellemesini daha kucuk APK dosyalariyla dagitmak icindir.

## 1. Versiyon Artir

`pubspec.yaml` icindeki `version` alanini artir.

Ornek:

```yaml
version: 1.1.42+43
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

## 5. Sunucuya Kopyala

Sunucu klasorunu kendi ortamina gore degistir.

```powershell
$ServerPath = "\\10.0.0.100\Terminal"

Copy-Item "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" "$ServerPath\app-arm64-v8a-release.apk" -Force
Copy-Item "build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" "$ServerPath\app-armeabi-v7a-release.apk" -Force
Copy-Item "build/app/outputs/flutter-apk/app-x86_64-release.apk" "$ServerPath\app-x86_64-release.apk" -Force
Copy-Item "build/app/outputs/flutter-apk/app-release.apk" "$ServerPath\app-release.apk" -Force
```

## 6. version.json Guncelle

Ornek yeni manifest:

```json
{
  "version": "1.1.42",
  "apk": "http://10.0.0.100:802/Terminal/app-release.apk",
  "android": {
    "universalUrl": "http://10.0.0.100:802/Terminal/app-release.apk",
    "apks": {
      "arm64-v8a": "http://10.0.0.100:802/Terminal/app-arm64-v8a-release.apk",
      "armeabi-v7a": "http://10.0.0.100:802/Terminal/app-armeabi-v7a-release.apk",
      "x86_64": "http://10.0.0.100:802/Terminal/app-x86_64-release.apk"
    }
  }
}
```

Eski uygulamalar sadece `apk` alanini okur. Yeni uygulamalar cihaz ABI'sine uygun APK'yi `android.apks` icinden secer.

## 7. Sunucudan Kontrol Et

```powershell
Invoke-WebRequest "http://10.0.0.100:802/Terminal/version.json" | Select-Object -ExpandProperty Content
Invoke-WebRequest "http://10.0.0.100:802/Terminal/app-arm64-v8a-release.apk" -Method Head
Invoke-WebRequest "http://10.0.0.100:802/Terminal/app-armeabi-v7a-release.apk" -Method Head
```

## 8. Hizli Tek Komut Akisi

```powershell
flutter analyze
flutter test
flutter build apk --release --split-per-abi
flutter build apk --release
```

Sonra APK dosyalarini sunucuya kopyala ve `version.json` icindeki `version` degerini yeni surume cek.

