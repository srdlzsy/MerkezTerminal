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
version: 1.1.111+2111
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
$VersionName = "1.1.111"
$BuildNumber = "2111"
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

Ornek yeni manifest (`version: 1.1.111+2111` icin):

```json
{
  "version": "1.1.111",
  "apk": "http://10.0.0.100:802/Terminal/furpa-terminal-1.1.111-2111-universal.apk",
  "android": {
    "universalUrl": "http://10.0.0.100:802/Terminal/furpa-terminal-1.1.111-2111-universal.apk",
    "apks": {
      "arm64-v8a": "http://10.0.0.100:802/Terminal/furpa-terminal-1.1.111-2111-arm64-v8a.apk",
      "armeabi-v7a": "http://10.0.0.100:802/Terminal/furpa-terminal-1.1.111-2111-armeabi-v7a.apk",
      "x86_64": "http://10.0.0.100:802/Terminal/furpa-terminal-1.1.111-2111-x86_64.apk"
    }
  }
}
```

`version: 1.1.111+2111` ile uretilen APK'larda beklenen gercek kodlar:

```text
universal:   2111
armeabi-v7a: 3111
arm64-v8a:   4111
x86_64:      6111
```

Bu nedenle arm64 terminalde `4111` gorulmesi normaldir. Manifestte global
`buildNumber: 2111` verilirse arm64 cihazdaki kurulu `4110` ile yanlis
karsilastirma yapilip guncelleme bulunamayabilir.

Eski uygulamalar sadece `apk` alanini okur. Yeni uygulamalar cihaz ABI'sine uygun APK'yi `android.apks` icinden secer.

Yeni uygulama indirdigi APK'nin paket adini, imzasini, `version` ve gercek
Android `versionCode` degerini kurulumdan once dogrular. Yanlis/eski APK
sunulursa kurulum ekrani acilmaz ve kullaniciya Turkce hata gosterilir.

## 7. Sunucudan Kontrol Et

```powershell
Invoke-WebRequest "http://10.0.0.100:802/Terminal/version.json" | Select-Object -ExpandProperty Content
Invoke-WebRequest "http://10.0.0.100:802/Terminal/furpa-terminal-1.1.111-2111-arm64-v8a.apk" -Method Head
Invoke-WebRequest "http://10.0.0.100:802/Terminal/furpa-terminal-1.1.111-2111-armeabi-v7a.apk" -Method Head
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
  gosterilir: `Surum <versionName> (<versionCode>)`.
- `Kontrol` dugmesiyle sunucu manifesti elle yeniden kontrol edilebilir.
- Yeni surum varsa hedef surum Home ekraninda gorunur ve `Guncelle` dugmesi
  aktif olur.
- Indirme boyunca yuzde ve indirilen boyut gosterilir. APK paket adi, surumu,
  yapi numarasi ve imzasi dogrulanmadan Android kurulum ekrani acilmaz.
- Kurulum iptal edilirse Home ekraninda durum acikca belirtilir ve ayni gecerli
  APK tekrar indirilmeden kurulum yeniden acilir.
- Sonraki surum indirilirken eski APK cache dosyalari otomatik temizlenir.

## 11. Canlida Sorun Cikaran Surumden Geri Donus

Android, daha dusuk `versionCode` tasiyan APK'yi kurulu uygulamanin uzerine
normal guncelleme olarak kurmaz. Ornegin `1.1.109` kurulu cihaza `1.1.108`
APK'si dogrudan kurulamaz.

Bu kural, APK dogru oldugu halde yeni kodun sahada hata cikarmasi durumunda da
gecerlidir. Yani `1.1.109` canlida sorun cikardi diye saklanan `1.1.108` APK'si
kurulu uygulamanin uzerine normal yoldan geri kurulamaz.

Geri donus icin iki guvenli secenek vardir:

1. Guncel dalda soruna neden olan commitleri geri alip yeni bir surum ve daha
   yuksek build numarasiyla tekrar yayinlamak. Ornek: `1.1.110+2110`. Tavsiye
   edilen yontem budur; sonraki API/veri uyumlulugu ile cihazdaki taslaklar ve
   yerel veriler korunur.
2. Uygulamayi cihazdan kaldirip eski APK'yi temiz kurmak. Bu yontem uygulamanin
   cihazdaki yerel verilerini, kataloglarini ve gonderilmemis taslaklarini
   silebilir; saha cihazlarinda normal geri donus yontemi olarak kullanilmaz.

Yedek APK dosyasini saklamak yine faydalidir; ancak geri donus paketi olarak
kullanilacaksa eski kod tabanindan daha yuksek `versionCode` ile yeni APK
uretilmelidir. Debug ve release imzalari birbirinin uzerine kurulamaz.

Her yayin icin son sorunsuz kaynak commit'i veya Git etiketi saklanmalidir.
Ornek: `release/1.1.108`. Acil geri donuste tercihen sorunlu commitler guncel
dalda `git revert` ile geri alinir. Eski kaynak dogrudan kullanilacaksa mevcut
API sozlesmesi ve cihazdaki yerel veri formatiyla uyumlu oldugu kontrol edilir;
sonra surum numarasi ileri alinir ve ayni release anahtariyla yeniden derlenir.

### 1.1.108 Kaynak Siniri ve Geri Alinacak Commitler

Bu depoda `1.1.108+2108` surumunu hazirlayan son kaynak commit'i:

```text
728d572 chore(release): 1.1.108+2108 surumunu ve dokumanlari hazirla
```

`1.1.108` sonrasinda uygulama davranisini degistiren commitler eskiden yeniye
su siradadir:

```text
e4bfda0 feat(pda): create ve liste deneyimini optimize et
ef8d093 Firma mal kabul miktar sinirini dogrula
0f08c65 Firma mal kabul fiyat bilgisini netlestir
09a0db3 feat(pda): firma mal kabul akisini netlestir ve 1.1.109'u hazirla
6cddd36 Terminalde pasif ve DLS urun kontrollerini esitle
49961a7 fix(pda): en dar ekran ve buyuk yazi duzenlerini guclendir
```

`6402729` yalnizca guncelleme rehberindeki kurulu surum etiketini aciklar;
uygulama davranisini degistirmez. Birebir kaynak karsilastirmasi istenirse bu
commit de 108 tabaninda bulunmaz, ancak canli hatayi olusturan kod degisikligi
degildir.

110 icin hazirlanan fakat henuz commitlenmemis degisikliklerin commit kimligi
bu listede yer almaz. Bu degisiklikler commitlendikten sonra geri donus
yapilacaksa, olusan 110 commit'i de once geri alinmalidir.

#### Tavsiye Edilen Birebir 108 Tabanli Acil Paket

Mevcut calisma dalini geri sarmak yerine 108 commit'inden ayri dal ac:

```powershell
git switch -c hotfix/1.1.111-from-108 728d572
```

Ardindan `pubspec.yaml` surumunu eskiye dusurmeden ileri al:

```yaml
version: 1.1.111+2111
```

Bu paket 108'in uygulama kodunu tasir fakat Android tarafinda 109/110 kurulu
cihazlarin ustune kurulabilmesi icin daha yuksek surum numarasina sahip olur.
Derlemeden once guncel API sozlesmesi, yerel veritabani ve taslak uyumlulugu
mutlaka test edilmelidir.

#### Mevcut Dalda Revert Ile Geri Donus

110 degisiklikleri ayri bir commit olarak kaydedildikten sonra, once o commit'i;
ardindan asagidaki commitleri en yeniden en eskiye geri al:

```powershell
git revert --no-commit 49961a7 6cddd36 09a0db3 0f08c65 ef8d093 e4bfda0
```

Sonra cakismalari cozup surumu mevcut canli surumden ileri bir numaraya getir,
testleri calistir ve tek bir geri donus commit'i olustur. Kirli calisma agacinda
`git revert`, `git reset --hard` veya dal degistirme uygulanmaz; once mevcut
degisiklikler commitlenir ya da guvenli bir dala alinir.

Not: Sadece sorunlu bir 109 davranisini kaldirmak isteniyorsa butun bu zinciri
geri almak yerine ilgili commit secilerek revert edilmelidir. Yukaridaki tam
liste, uygulama davranisini gercekten 108 tabanina dondurmek icindir.

## 12. Kademeli Canli Yayin

Yeni APK'lari sunucuya yuklemek tek basina tum cihazlari guncellemez.
`version.json` eski surumde tutulurken yeni APK once pilot cihazlara elle
kurulabilir.

Tavsiye edilen sira:

1. Her cihaz modelinden en az bir terminal sec: Zebra, Honeywell ve telefon.
2. Yeni APK'yi bu 2-3 pilot cihaza elle kur.
3. Giris, sayim adi yazma, 13 haneli barkod okutma, miktar girme, kaleme ekleme,
   taslak, kaydetme ve uygulamayi yeniden acma akisini kontrol et.
4. Offline sayim ve offline firma mal kabulde birer taslak olusturup geri ac.
5. Pilot cihazlar temizse APK URL'lerini kontrol et ve `version.json` dosyasini
   en son yayinla.
6. Ilk 5-10 cihaz guncellendikten sonra hata kayitlarini izle; sorun yoksa tum
   cihazlara devam et.

Farkli kurulu surumler ayni anda bulunabilir. Ornegin `1.1.108`, `1.1.109` ve
`1.1.110` kullanan cihazlar, paket adi ve release imzasi ayni oldugu surece
dogrudan `1.1.111` surumune guncellenebilir. Ara surumleri tek tek kurmak gerekmez.

