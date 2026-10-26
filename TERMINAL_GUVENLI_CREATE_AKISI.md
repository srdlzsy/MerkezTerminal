# Terminal Guvenli Create Akisi

Bu dokuman terminal create ekranlari icin uygulanacak nihai kullanici ve entegrasyon sozlesmesidir. Ayrintili API modelleri icin `UI_API_DOKUMANI.md`, tam route/model listesi icin `API_SOZLESME_REFERANSI.md` kullanilir.

## Hedef

- Kullanici Kaydet'e bastigi ekranda sonucu gorur.
- Yavas internet veya sunucu yogunlugu ikinci evrak olusturmaz.
- Form, satirlar ve `clientRequestId` kesin sonuc alinincaya kadar ayni ekranda korunur.
- Teknik sorun yalniz ilgili evragi bekletir; diger ekranlar ve yeni bagimsiz evraklar acik kalir.
- Terminal kendi kendine ikinci create POST'u, `Dogrula` dongusu veya periyodik senkronizasyon baslatmaz.

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
- Basarili business response gelmeden belirsiz/pending kayit silinmez. Mikro yaziminin baslamadigi kesinlesirse guvenlik snapshot'i kapatilir; yalniz duzenlenebilir normal form taslagi korunur.
- Uygulama kapanirsa belirsiz kayit kalir. Sonraki acilista en fazla bir salt-okuma status kontrolu yapilabilir; create POST baslatilmaz.

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
Kaydedildi | Olusmadi, yeniden Kaydet | Sonuc kontrol ediliyor
```

Kaydet sirasinda:

- Form otomatik kapanmaz.
- Liste veya Bulut ekranina zorunlu yonlendirme yapilmaz.
- Form alanlari ve Kaydet yalniz bu evrak icin kilitlenir.
- Kullanici bilincli olarak geri giderse islem devam eder ve header/home seviyesinde bekleyen islem sayisi gosterilebilir.
- Kullanici ayni evragi yeniden acarsa saklanan snapshot ve mevcut durum gosterilir.

Basarida:

- `result.documentSerie` ve `result.documentOrderNo` gosterilir.
- Yerel pending kayit tamamlandi olarak isaretlenir ve create taslagi silinir. Ayni `clientRequestId` ile gec gelen/eski bir yerel kopya yeniden bekleyen islem olarak acilamaz; gorunmeyen tamamlanma isareti 7 gun korunur ve sonra cihazdan temizlenir.
- Form kapanir ve guncel liste yenilenir. Basari akisi icinde ekstra `Tamam` onayi zorunlu degildir.
- Recovery ile bulunan mevcut evrak da normal basari gibi gosterilir; ikinci evrak yazilmaz.
- Create business response'u basarili geldikten sonraki liste yenileme ayri ve ikincil bir islemdir. Liste yenileme veya response parse hatasi create sonucunu geriye donuk basarisiza ceviremez ve ikinci POST baslatamaz.

## Cihazdaki Create Verisi

- Basarili create'te tam request payload ve form taslagi temizlenir; yalniz `clientRequestId` ile tamamlanma zamani 7 gunluk tekrar-koruma isareti olarak kalir.
- Sonucu belirsiz veya kesin yazilmamis isteklerde ayni body/id ile guvenli sonuc alabilmek icin yalniz o kaydin snapshot'i korunur. Eski snapshot sayisi yeni, bagimsiz bir create'i bloke etmez.
- Teknik pending snapshot'lari kullanici/depo/modul basina en fazla 5 kayit ve en fazla 30 gun saklanir. Tamamlanma isaretleri 7 gun tutulur ve ayni kapsamda en fazla 50 kayitla sinirlidir.
- Kullanici tarafindan acikca kaydedilmis normal taslaklar kendi taslak ekraninda basariya veya kullanici silmesine kadar kalir. Arka plan bunlari otomatik create etmez.

## Karar Tablosu

| `recommendedAction` | Terminal davranisi | Kullanici metni |
|---|---|---|
| `Completed` | Sonucu goster, pending kaydi sil. | `Evrak kaydedildi.` |
| `WaitAndCheck` | POST yapma; `retryAfterSeconds` sonrasinda status GET yap. | `Kayit sonucu kontrol ediliyor.` |
| `RetrySameRequest` | Ayni body ve `clientRequestId` ile en fazla bir otomatik POST yap. Bu deneme de kesin olarak baslamazsa donguyu durdur ve kullanicinin acik Kaydet aksiyonunu bekle. | `Kayit Mikro'ya yazilmadi. Bilgiler taslakta korundu; ayni kaydi yeniden kaydedebilirsiniz.` |
| `EditAndRetry` | Offline snapshot'i sil, normal form taslagini ayni satirlarla yeniden ac. Duzenlemeden sonra yeni kaydetme denemesi ve yeni `clientRequestId` olustur. | `Seri veya sira numarasini degistirip yeniden kaydedin.` |
| `RefreshList` | Offline snapshot'i sil, ikinci create yapma ve listeyi yenile. | `Bu resmi belge zaten alinmis; mevcut evraki kontrol edin.` |
| `RecheckExisting` | Kullaniciya `Dogrula` butonu acma. Yalniz trace, depo ve temel satir icerigi birebir eslesiyorsa API gercek seri/sirayi `Completed` sonucu olarak dondurur. | `Evrak zaten kayitli: F53/...` |
| `RestoreOriginalRequest` | Orijinal snapshot'i geri yukle; degismis body ile gonderme. | `Bekleyen evragin icerigi degistirilmis.` |
| `NeedsReview` | Yalniz ayni trace'in birden fazla belgeye cozulmesi gibi tek belge numarasi verilemeyen teknik tutarsizlikta kullanilir. Terminal otomatik POST/dogrulama yapmaz. | `Kayit yeniden gonderilmedi.` |
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
- `400 Bad Request` kesin form/istek hatasidir; terminal status endpointi, `yeniden-dogrula` veya guvenli tekrar akisini cagiramaz.
- Bu kayit pending/guvenli-yazma listesinde tutulmaz. Yalniz kullanicinin duzenleyebilecegi cihaz taslagi korunur; taslak `hasBeenSubmitted=false` kabul edilir.
- API hata basliklarini Turkce dondurur. Mevcut Turkce is kurali mesaji korunur; SQL execution strategy, stack trace veya Ingilizce framework mesaji kullaniciya aciklanmaz.
- Terminal eski bir API/proxy cevabinda Ingilizce veya teknik mesaj alsa bile HTTP durumuna gore Turkce yonlendirme gosterir. `400` alanlari duzeltmeyi, `401` yeniden girisi, `403` yetkiyi, `404` listeyi yenilemeyi, `409` cakisan islemi kontrol etmeyi, `5xx` ise kisa sure sonra yeniden denemeyi anlatir.
- Beklenmeyen terminal calisma zamani hatalarinda `Null check operator`, stack trace veya HTML proxy govdesi ekrana basilmaz. Kullaniciya form bilgisinin korundugu soylenir; teknik inceleme icin varsa destek kodu gosterilmeye devam eder.
- Daha once Offline Firma Mal Kabul veya Offline Sayim listesinden gonderilmeye calisilan taslak `400` alirsa gonderim metadata'si temizlenir. Kartta `Durumu Kontrol Et`, `Dogrula` veya `Tekrar Dene` yerine yalniz normal `Kaydet` aksiyonu bulunur.
- Uygulama acilisi, odaga donus ve agin geri gelmesi bu taslak icin status GET veya create POST uretmez. Kullanici hatali alani duzeltip `Kaydet` demeden sunucuya yeni istek gitmez.
- Create satirlarindaki gercek miktar alanlari en fazla `100000` olabilir. Barkod veya baska uzun bir sayi miktar alanina okutulursa API guvenli yazma rezervasyonu ya da Mikro yazimi baslatmadan `400 Bad Request` doner.
- UI miktar alaninda `100000` ustunu yerelde de engeller; yine de backend kontrolu asil guvenlik siniridir.
- Merkez depo siparisinde `outWarehouseNo=50` ve stok kartindaki koli katsayisi `1`den buyukse miktar koli katinda olmalidir. Ornek: koli ici `9` ise `9`, `18`, `27` gecerlidir; `10` gecersizdir.
- Terminal koli adedini ana giris olarak kullanmali ve toplam adedi `koliAdedi * unitMultiplier` ile hesaplamalidir. Adet elle degistirilebiliyorsa koli disi deger Kaydet'ten once engellenip en yakin gecerli alt/ust miktarlar gosterilmelidir.
- API koli disi miktari otomatik yuvarlamaz; `400` cevabi Mikro yaziminin baslamadigi anlamina gelir. Form duzeltilebilir kalir ve duzeltilen body yeni kaydetme denemesi olarak gonderilir.
- Kullanici duzelttikten sonra bu yeni kaydetme denemesi icin snapshot yeniden alinir.

### 401

- Snapshot ve `clientRequestId` korunur.
- Login yenilenir.
- Login sonrasi once status GET yapilir; otomatik yeni GUID uretilmez.

### 403

- Otomatik retry yapilmaz.
- Form korunur, yetki/depo mesaji gosterilir.

### 404 Status

- Belirsiz foreground POST sonrasi status `404` donerse Auth DB rezervasyonu olusmamistir; rezervasyon Mikro yazimindan once yapildigi icin ayni body ve `clientRequestId` ile bir guvenli otomatik POST yapilir.
- Uygulama acilisi/odaga donus gibi pasif status kontrolundeki `404` create POST baslatmaz; taslak gonderilmemis ve duzenlenebilir duruma cevrilir. Yeni POST yalniz kullanici `Kaydet` dediginde baslar.
- Bir guvenli otomatik tekrar zaten kullanilmisken status `404` donerse yeni otomatik POST yapilmaz; taslak ayni body ve kimlikle korunur, kullanici ayni ekrandan yeniden `Kaydet` diyebilir.
- Yeni GUID uretilmez.
- Kullanici uygulamayi acip kapatsa da ayni body ve ayni `clientRequestId` korunur; yeni evrak veya yeni istek kimligi uretilmez.
- Daha once `retryable=false` veri butunlugu karari verilmis bir kaydin status endpointi `404` donerse bu guvenlik karari kaldirilmaz ve otomatik POST baslatilmaz.

### 409

- `recommendedAction` uygulanir.
- `retryable=true` tek basina POST sebebi degildir.
- `MIKRO_WRITE_IN_PROGRESS` kullaniciya manuel `Tekrar Dene` olarak sunulmaz; UI ayni ekranda otomatik status kontrolu yapar.
- `MIKRO_WRITE_OUTCOME_UNCONFIRMED` ve `MIKRO_DOCUMENT_INCOMPLETE` durumunda POST yapilmaz.
- `MIKRO_DOCUMENT_IDENTITY_CONFLICT`, `retryable=false`, `recommendedAction=EditAndRetry`: Mikro yazimi baslamamistir. Kayit Offline listesine alinmaz; form ve satirlar korunarak seri/sira duzeltmesine acilir.
- `MIKRO_OFFICIAL_DOCUMENT_ALREADY_RECEIVED`, `retryable=false`, `recommendedAction=RefreshList`: ayni cari ve resmi belge daha once alinmistir. Kayit Offline listesine alinmaz, ikinci create yapilmaz ve gecmis listesi yenilenir.
- `RetrySameRequest` yalniz API'nin salt-okuma readback ile Mikro'da belge olmadigini kesinlestirdigi karardir. Terminal ortak API istemcisi ayni body ve `clientRequestId` ile en fazla bir otomatik POST yapar. Bu deneme de guvenli sekilde baslamazsa otomatik POST dongusu kapanir; kullanici taslagi ayni ekrandan Kaydet ile yeniden deneyebilir.

### HTTP 0, 500, 502, 503, 504 veya Timeout

- Sonuc belirsiz kabul edilir.
- Snapshot/id korunur.
- Once status GET yapilir.
- Status da gecici hata verirse artan bekleme uygulanir.

## Durum Kontrolu ve Terminal Yuku

- Terminalde 5 saniyelik veya baska bir periyodik offline senkronizasyon timer'i calismaz.
- Gonderilmemis yerel taslak uygulama acilisinda, odaga donuste veya ag geri geldiginde otomatik GET/POST uretmez. POST yalniz kullanicinin `Kaydet` aksiyonuyla baslar.
- Uygulama ilk acildiginda veya yeniden odaga geldiginde yalniz daha once POST edilmis ve sonucu belirsiz kayitlar icin status GET yapilabilir. Tek calismada firma mal kabulden en fazla bir ve sayimdan en fazla bir kayit kontrol edilir.
- Ayni kayit 45 saniyeden once yeniden kontrol edilmez; response'taki `retryAfterSeconds`/`retryNotBefore` daha uzunsa bu sureye uyulur.
- Bu pasif kontrol yalniz status GET'tir. Create POST veya `yeniden-dogrula` POST'u uretmez.
- Terminal normal create ekraninda `Durumu Kontrol Et` veya `Mikro Kaydini Dogrula` dongusu kurmaz. Ilk `Kaydet` sirasindaki ortak istemci gerekli status GET'lerini kendisi yapar; uygulama yeniden acilirsa yalniz gecici/belirsiz kayit icin bir sinirli status GET yapilabilir.
- Onceki istek bitmeden ayni servis calismasi yeniden baslatilmaz. Offline ekranlar kendi kendine periyodik yenilenmez.
- `Completed` veya `ClearCancelled` sonucu yerel kaydi tamamlanma isaretiyle temizler. Gec gelen autosave ayni kaydi yeniden canlandiramaz.
- Pasif status kontrolundeki `404` kaydi gonderilmemis yerel taslaga cevirir; belirsiz foreground POST sonrasi status `404` ise ayni body/id ile bir guvenli otomatik POST'a izin verir. Onceki guvenli tekrar hakki kullanilmissa veya kayit `retryable=false` ise otomatik POST yapilmaz.
- `NeedsReview` ve `RestoreOriginalRequest` kayitlari otomatik donguye alinmaz.

### Siparis Create Istisnasi

- Verilen depo/firma siparisinde yeni formdan gelen body her zaman yeni formun body-sidir; onceki bir pending istegin payload-i yeni siparise kopyalanmaz. Yeni formun `clientRequestId`-si yoksa yeni kimlik uretilir; retry yalniz bekleyen kaydin kendi kimligiyle yapilir.
- Verilen depo siparisinde `orderDate` ve `deliveryDate` terminal tarafinda otomatik tarihlerdir. Onceki gunden kalan taslak acildiginda ve form gece boyunca acik kalip ertesi gun kaydedildiginde, gecmiste kalan otomatik siparis tarihi kayit gunune tasinir; teslim tarihi de siparis tarihinden once olamaz. Boylece bugun Mikro'ya yazilan siparis eski taslak tarihiyle olusmaz.
- Eski belirsiz siparis kaydi cihazda ayri tutulur ve yeni, bagimsiz siparisleri engellemez. Kayitli pending durumu uygulama acilisinda yalniz bir kez status GET ile uzlastirilir; timer, manuel `Dogrula`/`Tekrar Dene` dongusu veya status sonucundan otomatik ikinci POST yoktur.
- Onerilen depo/firma siparisini donusturme ekranlarinda bekleyen kayit icin uygulama acilisinda tek status GET yapilabilir. Kartta kullaniciya tekrar/dogrulama aksiyonu gosterilmez; API'nin foreground create akisi normalde sonucu ayni ekranda kesinlestirir.
- Siparis readback’i belge seri/sira, depo/cari, tarih, satir sayisi ve sirasi, stok, miktar, birim ve fiyat/tutar gibi esas alanlari dogrular. Mikro tarafinda normalize edilebilen aciklama, paket/proje ve sorumluluk merkezi gibi yardimci alanlar tek basina icerik cakismasi sayilmaz.
- SQL execution strategy ayni create callback’ini tekrar calistirirsa API once `clientRequestId` trace’iyle Mikro readback yapar. Mevcut evrak tam eslesirse yeni INSERT yerine mevcut belge sonucu dondurulur; trace bulunamazsa normal create devam eder. Ayni trace birden fazla evraka veya farkli temel icerige cikarsa ikinci create yapilmaz.

## Teknik Yeniden Dogrulama

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

## Backend Yuk Kontrolu

- Ayni `clientRequestId` ile ayni POST, ilk islem halen taze `Processing` durumundaysa ikinci Mikro yazisi veya rakip readback baslatmaz.
- Tekrar POST mevcut sonuca en fazla 15 saniye baglanir. Ilk islem bu arada tamamlanirsa ayni kesin business response'u doner; tamamlanmazsa `WaitAndCheck` verir.
- Create sahibinin server-side calisma siniri 4 dakikadir. `Processing` kaydi 4 dakika 30 saniyeden once sahipsiz kabul edilmez; bu sure icinde status endpointi rakip recovery sorgusu acmaz.
- Mikro readback create sahibinin kendi uzlastirma adiminda, `Failed + retryable=true` kaydinda veya 4 dakika 30 saniyelik lease asildiktan sonra calisir.
- Arka plan uzlastiricisi 30 saniyede bir en fazla 10 uygun kaydi kontrol eder. Belgeyi bulursa `Completed`, bulunmadigini kesinlestirirse `RetrySameRequest` yapar; yeni create yazisi baslatmaz.
- Terminalin ortak API istemcisi asagidaki 14 kritik create akisinda POST ve sonuc uzlastirmasini ayni ekran istegi icinde yurutur: firma mal kabul, sayim sonucu, verilen depo siparisi, onerilen depo siparisini siparise cevirme, verilen firma siparisi, onerilen firma siparisini siparise cevirme, depolar arasi sevk, firma sevki, depo iadesi, firma iadesi, zayiat, masraf, virman ve manav MNV duzeltmesi.
- Normal `200/201` create cevabinda bekleme penceresi calismaz; sonuc hemen forma iletilir ve form kapanir. Yalniz `WaitAndCheck`, HTTP 0 veya `5xx` gibi belirsiz cevaplarda ortak istemci ayni ekranda ilgili `offline-sync/{clientRequestId}` adresine GET atarak sonucu kontrol eder. Bu GET'ler yeni create yazisi baslatmaz.
- Create isteginin toplam istemci siniri 5 dakikadir. Ilk POST'a en fazla yaklasik 4 dakika 30 saniye ayrilir; kalan sure status GET kontrolleri icindir. GET araligi artan beklemeyle yaklasik 3, 6, 12, 24 ve en fazla 30 saniyeye cikar. Bu 5 dakika sabit bekleme degil, yalniz geciken/sonucu belirsiz islem icin ust sinirdir.
- Backend `SAFE_WRITE_RETRY_ALLOWED` ile belgenin hic olusmadigini kesinlestirirse terminal ayni body ve `clientRequestId` ile tek bir otomatik POST daha yapar. Bu ikinci deneme de kesin yazilmadi sonucu verirse yeni otomatik POST yapilmaz; ayni taslak/kimlik daha sonra kullanicinin acik Kaydet aksiyonu icin korunur.
- Status `Completed` ve `result` dondururse bu normal basari cevabi gibi forma iletilir, pending snapshot ve form taslagi temizlenir, form kapanir ve liste yenilenir. Status `RetrySameRequest` yalniz bu tek guvenli tekrar hakki verir; tekrar hakki tuketildikten sonra response `SAFE_WRITE_RETRY_EXHAUSTED` olur.
- Modul veya offline liste ekrani acildiginda yerel kayit okunur; daha once POST edilmis ve sonucu belirsiz istek icin en fazla bir status GET yapilabilir. Ekran acilisi create POST veya `yeniden-dogrula` baslatmaz. Kesin yazilmadi taslagi kullanici Kaydet demeden tekrar gonderilmez.
- Bes dakikada sonuc kesinlesmezse kullanici formda bekletilmez: form kapatilir ve guvenli snapshot cihazda kalir. Terminal surekli arka plan dongusu calistirmaz. Sonraki uygulama odaklanmasinda en fazla bir sinirli status GET sonucu kesinlestirmeyi dener. Kesin basari gelince pending snapshot ve form taslagi temizlenir; bekleyen deneme kullanicinin yeni evrak kaydetmesini engellemez.
- Bu kurallar cok sayida terminalin ayni evrak icin paralel 180 saniyelik sorgular acmasini engeller.

Firma mal kabul icin eski operasyon-ozel endpoint de ayni amacla kullanilabilir:

```text
POST /api/mal-kabul-islemleri/firma-mal-kabulleri/offline-sync/{clientRequestId}/yeniden-dogrula
```

## Istisnai Teknik Inceleme

Normal timeout, sunucu yogunlugu, seri/sira cakismasi, alinmis resmi belge ve kapanmis siparis satiri yetkili islemi gerektirmez. Bunlar otomatik uzlastirilir veya form/liste karariyla kapanir. Yalniz Mikro'da ayni anahtarda farkli satir icerigi bulunmasi gibi gercek veri butunlugu uyusmazligi teknik incelemeye kalabilir:

Terminal bu istisnai kaydi kullaniciya tekrar tekrar `Dogrula` aksiyonu olarak yuklemez. Teknik pending kaydini kapatir, normal cihaz taslagini korur ve diger islemleri serbest birakir. Eski APK'dan kalan `manualReview`/`recheckExisting` yerel kayitlari yeni surum ilk okumada temizler.

- `yeniden-dogrula`: Salt-okuma kontrolunu tekrarlar.
- `tekrar-ac`: Normal akista arka plan uzlastiricisi Mikro'da belge olmadigini kesinlestirince otomatik `SAFE_WRITE_RETRY_ALLOWED + RetrySameRequest` verir; manuel kullanim yalniz istisnai kayitlar icindir.
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
- Pasif ekran-acilisi status kontrolu create POST baslatmaz. Yalniz foreground `Kaydet` akisi, backend belgenin hic yazilmadigini kesinlestirirse ayni body/id ile en fazla bir guvenli otomatik tekrar yapabilir.
- Ekran acilisi kaydi kendiliginden yeniden gondermez veya dogrulamaz. Kullanici aksiyonu olmadan create POST baslamaz.
- Tam eslesmeyen veya eksik belge `Completed` sayilmaz.
- Uygulama yeniden acildiginda pending islem kaybolmaz.
- Tek pending evrak diger evraklari veya tum modulu kilitlemez.
- Iptal sonucu basarili evrak gibi gosterilmez.
- Teknik kararlar mesaj metniyle degil `recommendedAction` ile verilir.
- Yazimin baslamadigi kesin seri/sira ve resmi belge cakismalari Offline/Bulut sayacini artirmaz.
- Firma mal kabul, verilen firma siparisi ve firma iadesi create islemlerinde stok-cari uyumu rezervasyondan once backend tarafinda yeniden dogrulanir. Uyumsuz stok `400` ile ayni formda duzeltilir; Mikro yazimi ve guvenli yazma rezervasyonu baslamaz.
- Cari baglamli firma urun seciminde API erisilemiyorsa genel yerel urun katalogu uyumluymus gibi kullanilmaz. Cari-stok iliskisi online dogrulanmadan yeni satir eklenmez.
- Offline Firma Mal Kabul ve Offline Sayim ekraninda gonderilmemis taslak yalniz `Kaydet` ile POST edilir. Daha once gonderilmis belirsiz kayit icin uygulama/sayfa acilisinda en fazla bir otomatik status GET yapilir; kullaniciya manuel `Durumu Kontrol Et` dongusu acilmaz.
- Daha once sunucuya ulasmis belirsiz kayitlar arka planda yalniz status/readback ile uzlastirilir. `Completed` veya `Cancelled` kesin sonucunda yerel kayit tamamlanma isaretiyle kapatilir; gec kalan autosave ayni kaydi tekrar taslak olarak diriltemez.
