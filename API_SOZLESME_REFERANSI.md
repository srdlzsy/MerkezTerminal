# API Sozlesme Referansi

Bu dosya test hostundaki ApiExplorer ve Swagger metadata'sindan uretilir. Canli DB veya dis servise baglanilmaz.
Ana rehber: [UI_API_DOKUMANI.md](UI_API_DOKUMANI.md). Makine formati: [API_SOZLESMESI.json](API_SOZLESMESI.json).

Kapsam: kayitli HTTP method/route ve alias'lar, binding kaynagi, request alanlari, tanimli response tipleri, controller/action yetki metadata'si ve erisilen JSON modelleri. Servis icindeki kosullu depo/permission kontrolleri, hata kodlari, feature flag'ler ve is kurallari ana rehberde ayrica okunmalidir. Modelde zorunluluk, yalniz OpenAPI/validasyon metadata'sini ifade eder; kosullu zorunluluklar ana rehberdedir.

`bildirilmemis` response tipi, runtime cevabinin bos oldugu anlamina gelmez. Anonim endpointler konfigurasyon/ag/servis kontrollerine tabi olabilir. JWT fallback policy, acik Authorize olmasa da uygulanir.

Endpoint sayisi (method + route): 746. Model sayisi: 684.

Bunlara ek olarak EndpointDataSource uzerinden dogrulanan iki health route'u vardir: `/health/live`, `/health/ready`. Bu middleware route'larinda method kisiti yoktur; istemci GET kullanmalidir. Anonimdir, JSON dondurur; Healthy/Degraded=200, Unhealthy=503. `live` yalniz prosesi, `ready` core_dependencies, operations_export_path ve background_workers kontrollerini olcer. Alanlar: status (string), durationMilliseconds (number), checks (ad -> status/durationMilliseconds/description/data). Tum runtime route'lari envanterde yer alir; yeni ve ApiExplorer disinda kalan route eklenirse test basarisiz olur.

Ozel response'lar: `/` Hosting:ExposeDiagnosticsOnRoot=false iken yalniz service/status; true iken architecture/authDatabase/businessDatabase/swagger ekler. E-irsaliye PDF endpointleri application/pdf binary/inline doner. Operations authorization-files/saveauthorizationfile POST 201 body dondurmez. Ana rehberdeki ozel response notlari bu metadata bosluklarini tamamlar.

## Endpointler

| Method | Route | Yetki | Parametreler (kaynak: ad / tip) | Tanimli response |
|---|---|---|---|---|
| GET | `/` | Anonim |  | 200: bildirilmemis |
| GET | `/api/arama-islemleri/barkodlar/{barcode}/cariler` | JWT + arama-islemleri.cari-bul.list | path: barcode / string (zorunlu)<br>query: WarehouseNo / integer (int32)<br>query: Take / integer (int32) | 401: ProblemDetails<br>200: BarcodeCustomerSuggestionResponse<br>400: ProblemDetails<br>403: ProblemDetails |
| GET | `/api/arama-islemleri/barkodlar/{barcode}/cozumle` | JWT | path: barcode / string (zorunlu)<br>query: WarehouseNo / integer (int32)<br>query: OperationType / string<br>query: TargetWarehouseNo / integer (int32)<br>query: SupplierCode / string<br>query: CompanyCode / string<br>query: IsRefund / boolean<br>query: ScreenCode / string | 401: ProblemDetails<br>200: BarcodeResolutionDto<br>400: ProblemDetails |
| GET | `/api/arama-islemleri/barkodlar/{barcode}/fiyat` | JWT + arama-islemleri.fiyat-gor.list | path: barcode / string (zorunlu)<br>query: WarehouseNo / integer (int32)<br>query: SourceWarehouseNo / integer (int32)<br>query: IncludeDelisted / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>200: IReadOnlyCollection&lt;ProductLookupItemDto&gt;<br>400: ProblemDetails<br>403: ProblemDetails |
| GET | `/api/arama-islemleri/cari-bul` | JWT + arama-islemleri.cari-bul.list | query: Barcode / string (zorunlu)<br>query: WarehouseNo / integer (int32)<br>query: Take / integer (int32) | 401: ProblemDetails<br>200: BarcodeCustomerSuggestionResponse<br>400: ProblemDetails<br>403: ProblemDetails |
| GET | `/api/arama-islemleri/cariler` | JWT | query: SearchText / string (zorunlu)<br>query: Take / integer (int32) | 401: ProblemDetails<br>200: IReadOnlyCollection&lt;CustomerLookupItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/arama-islemleri/depolar` | JWT | query: SearchText / string<br>query: WarehouseNo / integer (int32)<br>query: Take / integer (int32) | 401: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseLookupItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/arama-islemleri/depolar/kaynaklar` | JWT | query: SearchText / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>200: IReadOnlyCollection&lt;SourceWarehouseLookupItemDto&gt; |
| GET | `/api/arama-islemleri/fiyat-gor` | JWT + arama-islemleri.fiyat-gor.list | query: WarehouseNo / integer (int32)<br>query: Barcode / string<br>query: StockCode / string<br>query: StockName / string<br>query: SupplierCode / string<br>query: CompanyCode / string<br>query: SourceWarehouseNo / integer (int32)<br>query: IncludeDelisted / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>200: IReadOnlyCollection&lt;ProductLookupItemDto&gt;<br>400: ProblemDetails<br>403: ProblemDetails |
| GET | `/api/arama-islemleri/urunler` | JWT | query: WarehouseNo / integer (int32)<br>query: Barcode / string<br>query: StockCode / string<br>query: StockName / string<br>query: SupplierCode / string<br>query: CompanyCode / string<br>query: SourceWarehouseNo / integer (int32)<br>query: IncludeDelisted / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>200: IReadOnlyCollection&lt;ProductLookupItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/arama-islemleri/urunler/{stockCode}/cari-onerileri` | JWT | path: stockCode / string (zorunlu)<br>query: WarehouseNo / integer (int32)<br>query: Take / integer (int32) | 401: ProblemDetails<br>200: ProductCustomerSuggestionResponse<br>400: ProblemDetails |
| GET | `/api/arama-islemleri/urunler/{stockCode}/son-kunye` | Anonim | path: stockCode / string (zorunlu)<br>query: WarehouseNo / integer (int32) | 401: ProblemDetails<br>200: ProductLatestTagDto<br>400: ProblemDetails |
| GET | `/api/arama-islemleri/var-yok` | JWT + arama-islemleri.var-yok.list | query: WarehouseNo / integer (int32)<br>query: Barcode / string<br>query: StockCode / string<br>query: StockName / string<br>query: IncludeDelisted / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>200: IReadOnlyCollection&lt;ProductAvailabilityItemDto&gt;<br>400: ProblemDetails<br>403: ProblemDetails |
| POST | `/api/auth/login` | Anonim | body: request / LoginUserRequest (zorunlu) | 200: AuthResponse<br>401: ProblemDetails |
| POST | `/api/auth/logout` | Anonim | body: request / RefreshTokenBody (zorunlu) | 204: bildirilmemis |
| GET | `/api/auth/me` | JWT |  | 200: UserDto<br>401: ProblemDetails |
| POST | `/api/auth/refresh` | Anonim | body: request / RefreshTokenBody (zorunlu) | 200: AuthResponse<br>401: ProblemDetails |
| POST | `/api/auth/register` | Anonim | body: request / RegisterUserRequest (zorunlu) | 200: AuthResponse<br>400: ProblemDetails<br>403: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/auth/warehouse-context` | JWT |  | 200: WarehouseContextResponse<br>401: ProblemDetails |
| GET | `/api/ayar-islemleri/b2b-ayarlari/bultenler` | JWT + ayar-islemleri.b2b-ayarlari.list | query: Search / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;B2BBulletinDto&gt; |
| POST | `/api/ayar-islemleri/b2b-ayarlari/bultenler` | JWT + ayar-islemleri.b2b-ayarlari.create | body: request / SaveB2BBulletinHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: B2BBulletinDto<br>400: ProblemDetails |
| DELETE | `/api/ayar-islemleri/b2b-ayarlari/bultenler/{id}` | JWT + ayar-islemleri.b2b-ayarlari.delete | path: id / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>204: bildirilmemis<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/ayar-islemleri/b2b-ayarlari/bultenler/{id}` | JWT + ayar-islemleri.b2b-ayarlari.update | path: id / integer (int32) (zorunlu)<br>body: request / SaveB2BBulletinHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: B2BBulletinDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/ayar-islemleri/b2b-ayarlari/kullanicilar` | JWT + ayar-islemleri.b2b-ayarlari.list | query: Search / string<br>query: IncludeInactive / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;B2BUserDto&gt; |
| GET | `/api/ayar-islemleri/b2b-ayarlari/kullanicilar/{userId}` | JWT + ayar-islemleri.b2b-ayarlari.detail | path: userId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: B2BUserDetailDto<br>404: ProblemDetails |
| PUT | `/api/ayar-islemleri/b2b-ayarlari/kullanicilar/{userId}` | JWT + ayar-islemleri.b2b-ayarlari.update | path: userId / string (uuid) (zorunlu)<br>body: request / UpdateB2BUserHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: B2BUserDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/ayar-islemleri/cihazlar` | JWT + ayar-islemleri.cihazlar.list | query: branchNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;DeviceDto&gt;<br>400: ProblemDetails |
| POST | `/api/ayar-islemleri/cihazlar` | JWT + ayar-islemleri.cihazlar.create | body: request / CreateDeviceHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: DeviceDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/ayar-islemleri/cihazlar/durum` | JWT + ayar-islemleri.cihazlar.list | query: branchNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;DeviceStatusDto&gt;<br>400: ProblemDetails |
| GET | `/api/ayar-islemleri/cihazlar/subeler/{branchNo}/durum` | JWT + ayar-islemleri.cihazlar.list | path: branchNo / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;DeviceStatusDto&gt;<br>400: ProblemDetails |
| GET | `/api/ayar-islemleri/cihazlar/tipler` | JWT + ayar-islemleri.cihazlar.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;DeviceTypeDto&gt; |
| DELETE | `/api/ayar-islemleri/cihazlar/{id}` | JWT + ayar-islemleri.cihazlar.update | path: id / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>204: bildirilmemis<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/ayar-islemleri/kasa-pos-terminalleri` | JWT + ayar-islemleri.kasa-pos-terminalleri.create | body: request / CreateCashRegisterHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CashRegisterResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/ayar-islemleri/kasa-pos-terminalleri/kasalar/{cashNo}/terminaller` | JWT + ayar-islemleri.kasa-pos-terminalleri.list | path: cashNo / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashRegisterTerminalDto&gt;<br>400: ProblemDetails |
| GET | `/api/ayar-islemleri/kasa-pos-terminalleri/mevcut-sube/mesaj-durumlari` | JWT + ayar-islemleri.kasa-pos-terminalleri.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashRegisterMessageStatusDto&gt;<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/ayar-islemleri/kasa-pos-terminalleri/secenekler` | JWT + ayar-islemleri.kasa-pos-terminalleri.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashRegisterSettingsLookupsDto |
| DELETE | `/api/ayar-islemleri/kasa-pos-terminalleri/subeler/{branchNo}/kasalar/{cashNo}` | JWT + ayar-islemleri.kasa-pos-terminalleri.update | path: branchNo / integer (int32) (zorunlu)<br>path: cashNo / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>204: bildirilmemis<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/ayar-islemleri/kasa-pos-terminalleri/subeler/{branchNo}/mesaj-durumlari` | JWT + ayar-islemleri.kasa-pos-terminalleri.list | path: branchNo / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashRegisterMessageStatusDto&gt;<br>400: ProblemDetails<br>404: ProblemDetails |
| DELETE | `/api/ayar-islemleri/kasa-pos-terminalleri/subeler/{branchNo}/terminaller/{terminalNo}` | JWT + ayar-islemleri.kasa-pos-terminalleri.update | path: branchNo / integer (int32) (zorunlu)<br>path: terminalNo / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>204: bildirilmemis<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/ayar-islemleri/kasiyerler` | JWT + ayar-islemleri.kasiyerler.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashierDto&gt; |
| POST | `/api/ayar-islemleri/kasiyerler` | JWT + ayar-islemleri.kasiyerler.create | body: request / CreateCashierHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CashierPasswordMutationDto<br>400: ProblemDetails |
| PUT | `/api/ayar-islemleri/kasiyerler/{cashierCode}` | JWT + ayar-islemleri.kasiyerler.update | path: cashierCode / integer (int32) (zorunlu)<br>body: request / UpdateCashierHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashierDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/ayar-islemleri/kasiyerler/{cashierCode}/sifre-sifirla` | JWT + ayar-islemleri.kasiyerler.update | path: cashierCode / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashierPasswordMutationDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/ayar-islemleri/soforler` | JWT + ayar-islemleri.soforler.list | query: Search / string<br>query: IncludeInactive / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;DespatchDriverDto&gt;<br>400: ProblemDetails |
| POST | `/api/ayar-islemleri/soforler` | JWT + ayar-islemleri.soforler.create | body: request / SaveDespatchDriverHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: DespatchDriverDto<br>400: ProblemDetails<br>409: ProblemDetails |
| DELETE | `/api/ayar-islemleri/soforler/{id}` | JWT + ayar-islemleri.soforler.delete | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>204: bildirilmemis<br>404: ProblemDetails |
| GET | `/api/ayar-islemleri/soforler/{id}` | JWT + ayar-islemleri.soforler.detail | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: DespatchDriverDto<br>404: ProblemDetails |
| PUT | `/api/ayar-islemleri/soforler/{id}` | JWT + ayar-islemleri.soforler.update | path: id / string (uuid) (zorunlu)<br>body: request / SaveDespatchDriverHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: DespatchDriverDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/ayar-islemleri/sube-ayarlari` | JWT + ayar-islemleri.sube-ayarlari.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;BranchDetailDto&gt; |
| POST | `/api/ayar-islemleri/sube-ayarlari` | JWT + ayar-islemleri.sube-ayarlari.create | body: request / CreateBranchSettingsHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: BranchDetailDto<br>400: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/ayar-islemleri/sube-ayarlari/secenekler` | JWT + ayar-islemleri.sube-ayarlari.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: BranchSettingsLookupsDto |
| GET | `/api/ayar-islemleri/sube-ayarlari/{branchNo}` | JWT + ayar-islemleri.sube-ayarlari.detail | path: branchNo / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: BranchDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/ayar-islemleri/sube-ayarlari/{branchNo}` | JWT + ayar-islemleri.sube-ayarlari.update | path: branchNo / integer (int32) (zorunlu)<br>body: request / UpdateBranchSettingsHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: BranchDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/ayar-islemleri/sube-ayarlari/{branchNo}/kasalar` | JWT + ayar-islemleri.sube-ayarlari.detail | path: branchNo / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashRegistryDto&gt;<br>400: ProblemDetails |
| GET | `/api/ayar-islemleri/terminal-cihazlari` | JWT + ayar-islemleri.terminal-cihazlari.list | query: WarehouseNo / integer (int32)<br>query: Search / string<br>query: AppVersion / string<br>query: IsCurrentVersion / boolean<br>query: ActiveWithinDays / integer (int32)<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;TerminalInstallationDto&gt; |
| GET | `/api/ayar-islemleri/terminal-cihazlari/ozet` | JWT + ayar-islemleri.terminal-cihazlari.list | query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: TerminalInstallationSummaryDto |
| GET | `/api/ayar-islemleri/terminal-cihazlari/{id}` | JWT + ayar-islemleri.terminal-cihazlari.detail | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: TerminalInstallationDto<br>404: ProblemDetails |
| GET | `/api/ayar-islemleri/veritabani-izleme/anlik` | JWT + ayar-islemleri.veritabani-izleme.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: DatabaseMonitoringSnapshotDto |
| GET | `/api/ayar-islemleri/veritabani-izleme/genel-bakis` | JWT + ayar-islemleri.veritabani-izleme.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: MonitoringOverviewDto |
| GET | `/api/ayar-islemleri/veritabani-izleme/guvenli-yazmalar` | JWT + ayar-islemleri.veritabani-izleme.detail | query: Status / string<br>query: OperationCode / string<br>query: WarehouseNo / integer (int32)<br>query: Retryable / boolean<br>query: IncludeCompleted / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;SafeWriteMonitoringItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/ayar-islemleri/veritabani-izleme/olaylar` | JWT + ayar-islemleri.veritabani-izleme.detail | query: take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;DatabaseMonitoringIncidentDto&gt; |
| GET | `/api/ayar-islemleri/veritabani-izleme/oturum-sonlandirma-gecmisi` | JWT + ayar-islemleri.veritabani-izleme.detail | query: take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;DatabaseSessionTerminationDto&gt; |
| GET | `/api/ayar-islemleri/veritabani-izleme/oturumlar/{sessionId}/rollback-durumu` | JWT + ayar-islemleri.veritabani-izleme.detail | path: sessionId / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: DatabaseRollbackStatusDto |
| POST | `/api/ayar-islemleri/veritabani-izleme/oturumlar/{sessionId}/sonlandir` | JWT + ayar-islemleri.veritabani-izleme.terminate-session | path: sessionId / integer (int32) (zorunlu)<br>body: request / TerminateDatabaseSessionHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: DatabaseSessionTerminationDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/ayar-islemleri/veritabani-izleme/workerlar` | JWT + ayar-islemleri.veritabani-izleme.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: WorkerMonitoringSnapshotDto |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/alan-haritasi` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: MikroDocumentFieldCatalogDto |
| DELETE | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/banknot-takipleri/{banknoteTrackId}` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.delete | path: banknoteTrackId / string (uuid) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: MikroDocumentDeleteResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/banknot-takipleri/{banknoteTrackId}` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.detail | path: banknoteTrackId / string (uuid) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: BanknoteTrackDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/banknot-takipleri/{banknoteTrackId}` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.update | path: banknoteTrackId / string (uuid) (zorunlu)<br>query: warehouseNo / integer (int32)<br>body: request / BanknoteTrackPatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: BanknoteTrackUpdateResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| DELETE | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/cari-hareketleri` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.delete | query: DocumentSerie / string (zorunlu)<br>query: DocumentOrderNo / integer (int32)<br>query: DocumentType / integer (int32)<br>query: MovementType / integer (int32)<br>query: MovementKind / integer (int32)<br>query: NormalReturn / integer (int32)<br>query: CustomerCode / string<br>query: HardDelete / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: MikroDocumentDeleteResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/cari-hareketleri` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.detail | query: DocumentSerie / string (zorunlu)<br>query: DocumentOrderNo / integer (int32)<br>query: DocumentType / integer (int32)<br>query: MovementType / integer (int32)<br>query: MovementKind / integer (int32)<br>query: NormalReturn / integer (int32)<br>query: CustomerCode / string<br>query: HardDelete / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: CustomerMovementDocumentDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| PUT | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/cari-hareketleri` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.update | body: request / UpdateCustomerMovementDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CustomerMovementDocumentUpdateResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/cariler` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.list | query: SearchText / string<br>query: IncludePassive / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CustomerCardListItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/cariler/{customerCode}` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.detail | path: customerCode / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CustomerCardDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/cariler/{customerCode}` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.update | path: customerCode / string (zorunlu)<br>body: request / CustomerCardPatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CustomerCardUpdateResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/cariler/{customerCode}/adresler` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.detail | path: customerCode / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CustomerAddressDto&gt;<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/cariler/{customerCode}/adresler/{addressNo}` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.update | path: customerCode / string (zorunlu)<br>path: addressNo / integer (int32) (zorunlu)<br>body: request / CustomerAddressPatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CustomerAddressUpdateResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| DELETE | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/depo-siparisleri` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.delete | query: DocumentSerie / string (zorunlu)<br>query: DocumentOrderNo / integer (int32)<br>query: WarehouseNo / integer (int32)<br>query: InWarehouseNo / integer (int32)<br>query: OutWarehouseNo / integer (int32)<br>query: HardDelete / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: MikroDocumentDeleteResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/depo-siparisleri` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.detail | query: DocumentSerie / string (zorunlu)<br>query: DocumentOrderNo / integer (int32)<br>query: WarehouseNo / integer (int32)<br>query: InWarehouseNo / integer (int32)<br>query: OutWarehouseNo / integer (int32)<br>query: HardDelete / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseOrderDocumentDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| PUT | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/depo-siparisleri` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.update | body: request / UpdateWarehouseOrderDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseOrderDocumentUpdateResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/depolar` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.list | query: SearchText / string<br>query: IncludePassive / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseCardListItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/depolar/{warehouseNo}` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.detail | path: warehouseNo / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseCardDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/depolar/{warehouseNo}` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.update | path: warehouseNo / integer (int32) (zorunlu)<br>body: request / WarehouseCardPatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseCardUpdateResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| DELETE | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/firma-siparisleri` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.delete | query: DocumentSerie / string (zorunlu)<br>query: DocumentOrderNo / integer (int32)<br>query: OrderType / integer (int32)<br>query: OrderKind / integer (int32)<br>query: WarehouseNo / integer (int32)<br>query: CustomerCode / string<br>query: HardDelete / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: MikroDocumentDeleteResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/firma-siparisleri` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.detail | query: DocumentSerie / string (zorunlu)<br>query: DocumentOrderNo / integer (int32)<br>query: OrderType / integer (int32)<br>query: OrderKind / integer (int32)<br>query: WarehouseNo / integer (int32)<br>query: CustomerCode / string<br>query: HardDelete / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: CompanyOrderDocumentDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| PUT | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/firma-siparisleri` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.update | body: request / UpdateCompanyOrderDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CompanyOrderDocumentUpdateResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/sayim-sonuclari` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.detail | query: WarehouseNo / integer (int32)<br>query: DocumentNo / integer (int32)<br>query: DocumentDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: InventoryCountDocumentDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| PUT | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/sayim-sonuclari` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.update | body: request / UpdateInventoryCountDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: InventoryCountDocumentUpdateResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| DELETE | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-hareketleri` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.delete | query: DocumentSerie / string (zorunlu)<br>query: DocumentOrderNo / integer (int32)<br>query: DocumentType / integer (int32)<br>query: MovementType / integer (int32)<br>query: MovementKind / integer (int32)<br>query: NormalReturn / integer (int32)<br>query: WarehouseNo / integer (int32)<br>query: HardDelete / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: MikroDocumentDeleteResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-hareketleri` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.detail | query: DocumentSerie / string (zorunlu)<br>query: DocumentOrderNo / integer (int32)<br>query: DocumentType / integer (int32)<br>query: MovementType / integer (int32)<br>query: MovementKind / integer (int32)<br>query: NormalReturn / integer (int32)<br>query: WarehouseNo / integer (int32)<br>query: HardDelete / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockMovementDocumentDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| PUT | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-hareketleri` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.update | body: request / UpdateStockMovementDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockMovementDocumentUpdateResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.list | query: SearchText / string<br>query: IncludePassive / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;StockCardListItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.detail | path: stockCode / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockCardDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.update | path: stockCode / string (zorunlu)<br>body: request / StockCardPatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockCardUpdateResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/depolar` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.detail | path: stockCode / string (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;StockCardWarehouseSettingsDto&gt;<br>400: ProblemDetails<br>404: ProblemDetails |
| DELETE | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/depolar/{warehouseNo}` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.delete | path: stockCode / string (zorunlu)<br>path: warehouseNo / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: MikroDocumentDeleteResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/depolar/{warehouseNo}` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.update | path: stockCode / string (zorunlu)<br>path: warehouseNo / integer (int32) (zorunlu)<br>body: request / StockCardWarehousePatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockCardWarehouseUpdateResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/satis-fiyatlari` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.detail | path: stockCode / string (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;StockSalesPriceDto&gt;<br>400: ProblemDetails<br>404: ProblemDetails |
| DELETE | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/satis-fiyatlari/{warehouseNo}` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.delete | path: stockCode / string (zorunlu)<br>path: warehouseNo / integer (int32) (zorunlu)<br>query: PriceListNo / integer (int32)<br>query: PaymentPlanNo / integer (int32)<br>query: UnitPointer / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: MikroDocumentDeleteResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/duzeltme-islemleri/mikro-evrak-duzenleme/stok-kartlari/{stockCode}/satis-fiyatlari/{warehouseNo}` | JWT + duzeltme-islemleri.mikro-evrak-duzenleme.update | path: stockCode / string (zorunlu)<br>path: warehouseNo / integer (int32) (zorunlu)<br>body: request / StockSalesPriceUpsertHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockSalesPriceUpsertResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.list | query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: OnlyPending / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: PosAccountingOverviewDto<br>400: ProblemDetails |
| DELETE | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.update | body: request / PosAccountingDeleteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: PosAccountingBatchResultDto<br>400: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.list | query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: OnlyPending / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ExpenseNoteListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/erpye-gonder` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.create | body: request / PosAccountingTransferHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: PosAccountingBatchResultDto<br>400: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/ice-aktar` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.create | body: request / ImportPosDocumentsHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: PosAccountingImportResultDto<br>400: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/{expenseId}` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.detail | path: expenseId / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ExpenseNoteDetailDto<br>404: ProblemDetails |
| PUT | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/gider-pusulalari/{expenseId}` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.update | path: expenseId / integer (int32) (zorunlu)<br>body: request / UpdatePosAccountingDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ExpenseNoteDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.list | query: BranchNo / integer (int32)<br>query: CashRegisterNo / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashRegisterBranchMappingDto&gt;<br>400: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.create | body: request / CashRegisterBranchMappingHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashRegisterBranchMappingDto<br>400: ProblemDetails<br>409: ProblemDetails |
| PUT | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/kasa-eslemeleri/{mappingId}` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.update | path: mappingId / integer (int32) (zorunlu)<br>body: request / CashRegisterBranchMappingHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashRegisterBranchMappingDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| DELETE | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.update | body: request / PosAccountingDeleteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: PosAccountingBatchResultDto<br>400: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.list | query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: OnlyPending / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;BranchInvoiceListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/erpye-gonder` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.create | body: request / PosAccountingTransferHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: PosAccountingBatchResultDto<br>400: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/ice-aktar` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.create | body: request / ImportPosDocumentsHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: PosAccountingImportResultDto<br>400: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/{invoiceId}` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.detail | path: invoiceId / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: BranchInvoiceDetailDto<br>404: ProblemDetails |
| PUT | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/pos-faturalar/{invoiceId}` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.update | path: invoiceId / integer (int32) (zorunlu)<br>body: request / UpdatePosAccountingDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: BranchInvoiceDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| DELETE | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.update | body: request / PosAccountingDeleteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: PosAccountingBatchResultDto<br>400: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.list | query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: OnlyPending / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ZReportListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/erpye-gonder` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.create | body: request / PosAccountingTransferHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: PosAccountingBatchResultDto<br>400: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/ice-aktar` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.create | body: request / ImportZReportsHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: PosAccountingImportResultDto<br>400: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/pos-muhasebe-aktarimi/z-raporlari/{totalId}` | JWT + entegrasyon-islemleri.pos-muhasebe-aktarimi.detail | path: totalId / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ZReportDetailDto<br>404: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/trendyol-go` | JWT + entegrasyon-islemleri.trendyol-go.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: TrendyolGoConnectionStatusDto |
| GET | `/api/entegrasyon-islemleri/trendyol-go/brands` | JWT + entegrasyon-islemleri.trendyol-go.list | query: page / integer (int32)<br>query: size / integer (int32)<br>query: name / string | 401: ProblemDetails<br>403: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/trendyol-go/catalog/dispatch` | JWT + entegrasyon-islemleri.trendyol-go.update | body: request / TrendyolGoCatalogDispatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: TrendyolGoCatalogDispatch |
| GET | `/api/entegrasyon-islemleri/trendyol-go/catalog/preview` | JWT + entegrasyon-islemleri.trendyol-go.list | query: storeId / integer (int64)<br>query: view / string<br>query: search / string<br>query: take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: TrendyolGoCatalogPreview |
| GET | `/api/entegrasyon-islemleri/trendyol-go/claims` | JWT + entegrasyon-islemleri.trendyol-go.list | query: ClaimItemStatus / string<br>query: StartDate / integer (int64)<br>query: EndDate / integer (int64)<br>query: Page / integer (int32)<br>query: Size / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails |
| PUT | `/api/entegrasyon-islemleri/trendyol-go/claims/{claimId}/accept` | JWT + entegrasyon-islemleri.trendyol-go.update | path: claimId / string (zorunlu)<br>body: payload / JsonElement (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/trendyol-go/claims/{claimId}/items/objectionable` | JWT + entegrasyon-islemleri.trendyol-go.detail | path: claimId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/trendyol-go/claims/{claimId}/items/objections` | JWT + entegrasyon-islemleri.trendyol-go.update | path: claimId / string (zorunlu)<br>body: payload / JsonElement (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| PUT | `/api/entegrasyon-islemleri/trendyol-go/claims/{claimId}/reject` | JWT + entegrasyon-islemleri.trendyol-go.update | path: claimId / string (zorunlu)<br>body: payload / JsonElement (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/trendyol-go/connection-test` | JWT + entegrasyon-islemleri.trendyol-go.detail | query: storeId / integer (int64) | 401: ProblemDetails<br>403: ProblemDetails<br>200: TrendyolGoConnectionStatusDto |
| POST | `/api/entegrasyon-islemleri/trendyol-go/invoice-links` | JWT + entegrasyon-islemleri.trendyol-go.update | body: payload / JsonElement (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/trendyol-go/orders` | JWT + entegrasyon-islemleri.trendyol-go.list | query: StoreId / integer (int64)<br>query: StartDate / integer (int64)<br>query: EndDate / integer (int64)<br>query: Page / integer (int32)<br>query: Size / integer (int32)<br>query: Status / string[]<br>query: SortDirection / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: JsonElement |
| GET | `/api/entegrasyon-islemleri/trendyol-go/orders/by-number/{orderNumber}` | JWT + entegrasyon-islemleri.trendyol-go.detail | path: orderNumber / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: JsonElement |
| GET | `/api/entegrasyon-islemleri/trendyol-go/orders/{orderId}/invoice-amount` | JWT + entegrasyon-islemleri.trendyol-go.detail | path: orderId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: JsonElement |
| GET | `/api/entegrasyon-islemleri/trendyol-go/packages/by-ids` | JWT + entegrasyon-islemleri.trendyol-go.detail | query: id / string[] | 401: ProblemDetails<br>403: ProblemDetails |
| PUT | `/api/entegrasyon-islemleri/trendyol-go/packages/{packageId}/invoiced` | JWT + entegrasyon-islemleri.trendyol-go.update | path: packageId / string (zorunlu)<br>body: request / TrendyolGoInvoiceHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: JsonElement<br>204: bildirilmemis |
| PUT | `/api/entegrasyon-islemleri/trendyol-go/packages/{packageId}/items/unsupplied` | JWT + entegrasyon-islemleri.trendyol-go.update | path: packageId / string (zorunlu)<br>body: payload / JsonElement (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| PUT | `/api/entegrasyon-islemleri/trendyol-go/packages/{packageId}/manual-delivered` | JWT + entegrasyon-islemleri.trendyol-go.update | path: packageId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| PUT | `/api/entegrasyon-islemleri/trendyol-go/packages/{packageId}/manual-shipped` | JWT + entegrasyon-islemleri.trendyol-go.update | path: packageId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| PUT | `/api/entegrasyon-islemleri/trendyol-go/packages/{packageId}/mark-alternative` | JWT + entegrasyon-islemleri.trendyol-go.update | path: packageId / string (zorunlu)<br>body: payload / JsonElement (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| PUT | `/api/entegrasyon-islemleri/trendyol-go/packages/{packageId}/picked` | JWT + entegrasyon-islemleri.trendyol-go.update | path: packageId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: JsonElement<br>204: bildirilmemis |
| POST | `/api/entegrasyon-islemleri/trendyol-go/price-stock/dispatch` | JWT + entegrasyon-islemleri.trendyol-go.update | body: request / TrendyolGoPriceStockDispatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/trendyol-go/price-stock/preview` | JWT + entegrasyon-islemleri.trendyol-go.list | query: storeId / integer (int64)<br>query: view / string | 401: ProblemDetails<br>403: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/trendyol-go/price-stock/preview/refresh` | JWT + entegrasyon-islemleri.trendyol-go.list | query: storeId / integer (int64) | 401: ProblemDetails<br>403: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/trendyol-go/products` | JWT + entegrasyon-islemleri.trendyol-go.list | query: StoreId / integer (int64)<br>query: ListType / string<br>query: Barcode / string<br>query: StockCode / string<br>query: StartDate / integer (int64)<br>query: EndDate / integer (int64)<br>query: BrandIds / integer (int64)[]<br>query: Page / integer (int32)<br>query: Size / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/trendyol-go/products` | JWT + entegrasyon-islemleri.trendyol-go.update | body: payload / JsonElement (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| PUT | `/api/entegrasyon-islemleri/trendyol-go/products` | JWT + entegrasyon-islemleri.trendyol-go.update | body: payload / JsonElement (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/trendyol-go/products/batch-requests/{batchRequestId}` | JWT + entegrasyon-islemleri.trendyol-go.detail | path: batchRequestId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/trendyol-go/products/price-and-inventory` | JWT + entegrasyon-islemleri.trendyol-go.update | body: payload / JsonElement (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| PUT | `/api/entegrasyon-islemleri/trendyol-go/products/sale-off` | JWT + entegrasyon-islemleri.trendyol-go.update | body: payload / JsonElement (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| PUT | `/api/entegrasyon-islemleri/trendyol-go/products/sale-on` | JWT + entegrasyon-islemleri.trendyol-go.update | body: payload / JsonElement (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/trendyol-go/products/seller-attributes` | JWT + entegrasyon-islemleri.trendyol-go.update | body: payload / JsonElement (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/trendyol-go/status` | JWT + entegrasyon-islemleri.trendyol-go.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: TrendyolGoConnectionStatusDto |
| GET | `/api/entegrasyon-islemleri/trendyol-go/stores` | JWT + entegrasyon-islemleri.trendyol-go.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;TrendyolGoStoreMappingDto&gt; |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftConnectedServiceOverviewDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/get/{operationName}` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: operationName / string (zorunlu)<br>query: parameter / string[] | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto<br>400: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/get/{operationName}` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: operationName / string (zorunlu)<br>body: request / UyumsoftOperationHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto<br>400: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceUuid}` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: invoiceUuid / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceUuid}/data` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: invoiceUuid / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceUuid}/pdf` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: invoiceUuid / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceUuid}/pdf-file` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: invoiceUuid / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FileContentResult |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceUuid}/status-with-logs` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: invoiceUuid / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/inbox/invoices/{invoiceUuid}/view` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: invoiceUuid / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/invoices/{invoiceUuid}/envelope` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: invoiceUuid / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/operations` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;UyumsoftOperationDefinitionDto&gt; |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceUuid}` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: invoiceUuid / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceUuid}/data` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: invoiceUuid / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceUuid}/pdf` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: invoiceUuid / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceUuid}/pdf-file` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: invoiceUuid / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FileContentResult |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceUuid}/response-view` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: invoiceUuid / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceUuid}/status-with-logs` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: invoiceUuid / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/outbox/invoices/{invoiceUuid}/view` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | path: invoiceUuid / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/system/date` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-fatura/system/date/formatted` | JWT + entegrasyon-islemleri.uyumsoft-e-fatura.detail | query: format / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftConnectedServiceOverviewDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/despatches/{despatchId}/envelope` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail | path: despatchId / string (zorunlu)<br>query: isInbox / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/get/{operationName}` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail | path: operationName / string (zorunlu)<br>query: parameter / string[] | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto<br>400: ProblemDetails |
| POST | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/get/{operationName}` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail | path: operationName / string (zorunlu)<br>body: request / UyumsoftOperationHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto<br>400: ProblemDetails |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/inbox/despatches/{despatchId}` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail | path: despatchId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/inbox/despatches/{despatchId}/pdf` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail | path: despatchId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/inbox/despatches/{despatchId}/status-with-logs` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail | path: despatchId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/inbox/despatches/{despatchId}/view` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail | path: despatchId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/operations` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;UyumsoftOperationDefinitionDto&gt; |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/outbox/despatches/{despatchId}` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail | path: despatchId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/outbox/despatches/{despatchId}/pdf` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail | path: despatchId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/outbox/despatches/{despatchId}/status-with-logs` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail | path: despatchId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/outbox/despatches/{despatchId}/view` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail | path: despatchId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/receipt-advices/{despatchId}/pdf` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail | path: despatchId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/receipt-advices/{despatchId}/view` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail | path: despatchId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/system/date` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/entegrasyon-islemleri/uyumsoft/e-irsaliye/system/date/formatted` | JWT + entegrasyon-islemleri.uyumsoft-e-irsaliye.detail | query: format / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: UyumsoftOperationResponseDto |
| GET | `/api/fatura-islemleri/fatura-gonderimi` | JWT + fatura-islemleri.fatura-gonderimi.list | query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: Scenario / FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingScenario<br>query: SentState / integer (int32)<br>query: isSent / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: InvoiceSendingListResponse<br>400: ProblemDetails |
| POST | `/api/fatura-islemleri/fatura-gonderimi/preview` | JWT + fatura-islemleri.fatura-gonderimi.create | body: request / InvoicePreviewHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: InvoiceRenderedDocumentDto<br>400: ProblemDetails |
| POST | `/api/fatura-islemleri/fatura-gonderimi/retry` | JWT + fatura-islemleri.fatura-gonderimi.create | body: request / InvoiceSendingBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: RetryInvoiceDocumentsResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/fatura-islemleri/fatura-gonderimi/send` | JWT + fatura-islemleri.fatura-gonderimi.create | body: request / InvoiceSendingBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SendInvoiceDocumentsResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/fatura-islemleri/fatura-gonderimi/validate` | JWT + fatura-islemleri.fatura-gonderimi.create | body: request / InvoiceSendingBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ValidateInvoiceDocumentsResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}` | JWT + fatura-islemleri.fatura-gonderimi.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: scenario / FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingScenario | 401: ProblemDetails<br>403: ProblemDetails<br>200: InvoiceSendingDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/pdf` | JWT + fatura-islemleri.fatura-gonderimi.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: scenario / FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingScenario | 401: ProblemDetails<br>403: ProblemDetails<br>200: FileContentResult<br>404: ProblemDetails |
| POST | `/api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/render` | JWT + fatura-islemleri.fatura-gonderimi.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / InvoiceSendingRenderHttpRequest | 401: ProblemDetails<br>403: ProblemDetails<br>200: InvoiceSendingDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/return-reference` | JWT + fatura-islemleri.fatura-gonderimi.create | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / UpdateInvoiceReturnReferenceHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UpdateInvoiceReturnReferenceResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/fatura-islemleri/fatura-gonderimi/{documentSerie}/{documentOrderNo}/return-reference-candidates` | JWT + fatura-islemleri.fatura-gonderimi.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: scenario / FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingScenario | 401: ProblemDetails<br>403: ProblemDetails<br>200: InvoiceReturnReferenceCandidatesResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/fatura-islemleri/fatura-goruntuleme` | JWT + fatura-islemleri.fatura-goruntuleme.list | query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: ProcessedState / integer (int32)<br>query: isProcessed / integer (int32)<br>query: PrintedState / integer (int32)<br>query: isPrinted / integer (int32)<br>query: SearchField / FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGoruntuleme.InvoiceViewingSearchField<br>query: SearchText / string<br>query: ApplyDateFilterWithSearch / boolean<br>query: useDateFilterWithSearch / boolean<br>query: InvoiceId / string<br>query: invoiceNo / string<br>query: DespatchId / string<br>query: despatchNo / string<br>query: CustomerTitle / string<br>query: CustomerTcknVkn / string<br>query: tcknVkn / string<br>query: DocumentId / string<br>query: ettn / string<br>query: OrderDocumentId / string<br>query: Status / string<br>query: InvoiceType / string<br>query: MinInvoiceTotal / number (double)<br>query: MaxInvoiceTotal / number (double)<br>query: HasDespatchId / boolean<br>query: PageNumber / integer (int32)<br>query: page / integer (int32)<br>query: PageSize / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: InvoiceViewingListResponse<br>400: ProblemDetails |
| POST | `/api/fatura-islemleri/fatura-goruntuleme/senkronize` | JWT + fatura-islemleri.fatura-goruntuleme.list | body: request / InvoiceViewingSynchronizationHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>202: InvoiceViewingSynchronizationProgressResponse<br>400: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/fatura-islemleri/fatura-goruntuleme/senkronize/progress` | JWT + fatura-islemleri.fatura-goruntuleme.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: InvoiceViewingSynchronizationProgressResponse |
| GET | `/api/fatura-islemleri/fatura-goruntuleme/{documentId}` | JWT + fatura-islemleri.fatura-goruntuleme.detail | path: documentId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FileContentResult<br>400: ProblemDetails |
| GET | `/api/fatura-islemleri/fatura-goruntuleme/{documentId}/detail` | JWT + fatura-islemleri.fatura-goruntuleme.detail | path: documentId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: InvoiceViewingDetailDto<br>404: ProblemDetails |
| GET | `/api/fatura-islemleri/fatura-goruntuleme/{documentId}/pdf` | JWT + fatura-islemleri.fatura-goruntuleme.detail | path: documentId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FileContentResult<br>400: ProblemDetails |
| GET | `/api/fatura-islemleri/fatura-goruntuleme/{documentId}/pdf/print` | JWT + fatura-islemleri.fatura-goruntuleme.detail | path: documentId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FileContentResult<br>400: ProblemDetails |
| GET | `/api/fatura-islemleri/fatura-goruntuleme/{documentId}/pdf/yazdirma` | JWT + fatura-islemleri.fatura-goruntuleme.detail | path: documentId / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FileContentResult<br>400: ProblemDetails |
| PATCH | `/api/fatura-islemleri/fatura-goruntuleme/{documentId}/printed` | JWT + fatura-islemleri.fatura-goruntuleme.update | path: documentId / string (zorunlu)<br>body: request / InvoiceViewingPrintedStateHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: InvoiceViewingPrintedStateResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/fatura-islemleri/fatura-goruntuleme/{documentId}/render` | JWT + fatura-islemleri.fatura-goruntuleme.detail | path: documentId / string (zorunlu)<br>body: request / InvoiceViewingRenderHttpRequest | 401: ProblemDetails<br>403: ProblemDetails<br>200: InvoiceViewingDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/green-grocer/operations/adjustments` | JWT + green-grocer.operations.create | body: request / GreenGrocerOperationsAdjustmentApplyHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: GreenGrocerOperationsAdjustmentApplyResponse<br>200: GreenGrocerOperationsAdjustmentApplyResponse<br>400: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/green-grocer/operations/adjustments/offline-sync/{clientRequestId}` | JWT + green-grocer.operations.create | path: clientRequestId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OfflineSyncStatusDto&lt;GreenGrocerOperationsAdjustmentApplyResponse&gt;<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/green-grocer/operations/adjustments/preview` | JWT + green-grocer.operations.list | body: request / GreenGrocerOperationsAdjustmentPreviewHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: GreenGrocerOperationsAdjustmentPreviewDto<br>400: ProblemDetails |
| POST | `/api/green-grocer/operations/duzeltmeler` | JWT + green-grocer.operations.create | body: request / GreenGrocerOperationsAdjustmentApplyHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: GreenGrocerOperationsAdjustmentApplyResponse<br>200: GreenGrocerOperationsAdjustmentApplyResponse<br>400: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/green-grocer/operations/duzeltmeler/offline-sync/{clientRequestId}` | JWT + green-grocer.operations.create | path: clientRequestId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OfflineSyncStatusDto&lt;GreenGrocerOperationsAdjustmentApplyResponse&gt;<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/green-grocer/operations/duzeltmeler/onizleme` | JWT + green-grocer.operations.list | body: request / GreenGrocerOperationsAdjustmentPreviewHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: GreenGrocerOperationsAdjustmentPreviewDto<br>400: ProblemDetails |
| GET | `/api/green-grocer/operations/overview` | JWT + green-grocer.operations.list | query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: TypeCode / string<br>query: Search / string<br>query: OnlyWithActivity / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: GreenGrocerOperationsOverviewDto<br>400: ProblemDetails |
| GET | `/api/green-grocer/operations/ozet` | JWT + green-grocer.operations.list | query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: TypeCode / string<br>query: Search / string<br>query: OnlyWithActivity / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: GreenGrocerOperationsOverviewDto<br>400: ProblemDetails |
| DELETE | `/api/green-grocer/orders` | JWT + green-grocer.reports.update | query: DocumentSerie / string (zorunlu)<br>query: DocumentOrderNo / integer (int32) (zorunlu)<br>query: WarehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: DeleteGreenGrocerOrderResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/green-grocer/product-case-profiles` | JWT + green-grocer.product-case-profiles.list | query: Search / string<br>query: IncludeInactive / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;GreenGrocerProductCaseProfileDto&gt;<br>400: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/green-grocer/product-case-profiles/cozumleme-onizleme` | JWT + green-grocer.product-case-profiles.list | body: request / GreenGrocerProductCaseResolutionHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: GreenGrocerProductCaseResolutionDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/green-grocer/product-case-profiles/resolution-preview` | JWT + green-grocer.product-case-profiles.list | body: request / GreenGrocerProductCaseResolutionHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: GreenGrocerProductCaseResolutionDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| DELETE | `/api/green-grocer/product-case-profiles/{stockCode}` | JWT + green-grocer.product-case-profiles.delete | path: stockCode / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>204: bildirilmemis<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/green-grocer/product-case-profiles/{stockCode}` | JWT + green-grocer.product-case-profiles.detail | path: stockCode / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: GreenGrocerProductCaseProfileDto<br>404: ProblemDetails<br>409: ProblemDetails |
| PUT | `/api/green-grocer/product-case-profiles/{stockCode}` | JWT + green-grocer.product-case-profiles.update | path: stockCode / string (zorunlu)<br>body: request / SaveGreenGrocerProductCaseProfileHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: GreenGrocerProductCaseProfileDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/green-grocer/reports` | JWT + green-grocer.reports.list | query: Date / string (date-time)<br>query: DateToGet / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: TypeCode / string<br>query: Search / string<br>query: IncludeLazyBranches / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;GreenGrocerProductReportItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/green-grocer/reports/by-branch` | JWT + green-grocer.reports.list | query: Date / string (date-time)<br>query: DateToGet / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: TypeCode / string<br>query: Search / string<br>query: IncludeLazyBranches / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: GreenGrocerBranchReportDto<br>400: ProblemDetails |
| GET | `/api/green-grocer/reports/by-product` | JWT + green-grocer.reports.list | query: Date / string (date-time)<br>query: DateToGet / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: TypeCode / string<br>query: Search / string<br>query: IncludeLazyBranches / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;GreenGrocerProductReportGroupDto&gt;<br>400: ProblemDetails |
| GET | `/api/green-grocer/reports/dashboard` | JWT + green-grocer.reports.list | query: Date / string (date-time)<br>query: DateToGet / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: TypeCode / string<br>query: Search / string<br>query: IncludeLazyBranches / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: GreenGrocerDashboardDto<br>400: ProblemDetails |
| GET | `/api/green-grocer/reports/greens` | JWT + green-grocer.reports.list | query: Date / string (date-time)<br>query: DateToGet / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: TypeCode / string<br>query: Search / string<br>query: IncludeLazyBranches / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;GreenGrocerGreenReportItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/green-grocer/reports/ozet` | JWT + green-grocer.reports.list | query: Date / string (date-time)<br>query: DateToGet / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: TypeCode / string<br>query: Search / string<br>query: IncludeLazyBranches / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: GreenGrocerDashboardDto<br>400: ProblemDetails |
| GET | `/api/green-grocer/reports/sube` | JWT + green-grocer.reports.list | query: Date / string (date-time)<br>query: DateToGet / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: TypeCode / string<br>query: Search / string<br>query: IncludeLazyBranches / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: GreenGrocerBranchReportDto<br>400: ProblemDetails |
| GET | `/api/green-grocer/reports/summary` | JWT + green-grocer.reports.list | query: Date / string (date-time)<br>query: DateToGet / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: TypeCode / string<br>query: Search / string<br>query: IncludeLazyBranches / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;GreenGrocerProductReportItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/green-grocer/reports/tip-secenekleri` | JWT + green-grocer.reports.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;GreenGrocerTypeOptionDto&gt; |
| GET | `/api/green-grocer/reports/type-options` | JWT + green-grocer.reports.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;GreenGrocerTypeOptionDto&gt; |
| GET | `/api/green-grocer/reports/urun` | JWT + green-grocer.reports.list | query: Date / string (date-time)<br>query: DateToGet / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: TypeCode / string<br>query: Search / string<br>query: IncludeLazyBranches / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;GreenGrocerProductReportGroupDto&gt;<br>400: ProblemDetails |
| GET | `/api/green-grocer/reports/yesillik` | JWT + green-grocer.reports.list | query: Date / string (date-time)<br>query: DateToGet / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: TypeCode / string<br>query: Search / string<br>query: IncludeLazyBranches / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;GreenGrocerGreenReportItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/home/depo-oncelikleri` | JWT | query: Date / string (date)<br>query: WarehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: HomeWarehousePrioritiesDto<br>400: ProblemDetails |
| GET | `/api/home/duyurular` | JWT | query: IncludeRead / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>200: IReadOnlyCollection&lt;AnnouncementDto&gt;<br>400: ProblemDetails |
| GET | `/api/home/duyurular/ozet` | JWT |  | 401: ProblemDetails<br>200: AnnouncementSummaryDto |
| PATCH | `/api/home/duyurular/{id}/okundu` | JWT | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>200: AnnouncementDto<br>404: ProblemDetails |
| POST | `/api/home/sikayet-oneri` | JWT | body: request / CreateFeedbackItemHttpRequest (zorunlu) | 401: ProblemDetails<br>201: FeedbackItemDto<br>400: ProblemDetails |
| GET | `/api/home/sikayet-oneri/benim` | JWT |  | 401: ProblemDetails<br>200: IReadOnlyCollection&lt;FeedbackItemDto&gt; |
| GET | `/api/home/sikayet-oneri/ozet` | JWT |  | 401: ProblemDetails<br>200: FeedbackSummaryDto |
| GET | `/api/iade-islemleri/depo-iadeleri` | JWT + iade-islemleri.giden-depo-iadeleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseShippingListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/iade-islemleri/depo-iadeleri` | JWT + iade-islemleri.giden-depo-iadeleri.create | body: request / CreateWarehouseReturnHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateWarehouseReturnResponse<br>400: ProblemDetails |
| GET | `/api/iade-islemleri/depo-iadeleri/gelen` | JWT + iade-islemleri.gelen-depo-iadeleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseShippingListItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/iade-islemleri/depo-iadeleri/gelen/{documentSerie}/{documentOrderNo}` | JWT + iade-islemleri.gelen-depo-iadeleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseShippingDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/iade-islemleri/depo-iadeleri/giden` | JWT + iade-islemleri.giden-depo-iadeleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseShippingListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/iade-islemleri/depo-iadeleri/giden` | JWT + iade-islemleri.giden-depo-iadeleri.create | body: request / CreateWarehouseReturnHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateWarehouseReturnResponse<br>400: ProblemDetails |
| GET | `/api/iade-islemleri/depo-iadeleri/giden/offline-sync/{clientRequestId}` | JWT + iade-islemleri.giden-depo-iadeleri.create | path: clientRequestId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OfflineSyncStatusDto&lt;CreateWarehouseReturnResponse&gt;<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/iade-islemleri/depo-iadeleri/giden/{documentSerie}/{documentOrderNo}` | JWT + iade-islemleri.giden-depo-iadeleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseShippingDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/iade-islemleri/depo-iadeleri/giden/{documentSerie}/{documentOrderNo}` | JWT + iade-islemleri.giden-depo-iadeleri.update | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32)<br>body: request / UpdateWarehouseShippingDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UpdateWarehouseShippingDocumentResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/iade-islemleri/depo-iadeleri/giden/{documentSerie}/{documentOrderNo}/e-irsaliye` | JWT + iade-islemleri.giden-depo-iadeleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32)<br>body: request / SendEDespatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SendEDespatchResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/iade-islemleri/depo-iadeleri/giden/{documentSerie}/{documentOrderNo}/e-irsaliye/pdf` | JWT + iade-islemleri.giden-depo-iadeleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: bildirilmemis<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/iade-islemleri/depo-iadeleri/iade-edilebilir-urunler` | JWT + iade-islemleri.giden-depo-iadeleri.create | query: WarehouseNo / integer (int32)<br>query: TargetWarehouseNo / integer (int32)<br>query: Search / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseReturnEligibleProductsDto<br>400: ProblemDetails |
| GET | `/api/iade-islemleri/depo-iadeleri/offline-sync/{clientRequestId}` | JWT + iade-islemleri.giden-depo-iadeleri.create | path: clientRequestId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OfflineSyncStatusDto&lt;CreateWarehouseReturnResponse&gt;<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/iade-islemleri/depo-iadeleri/{documentSerie}/{documentOrderNo}` | JWT + iade-islemleri.giden-depo-iadeleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseShippingDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/iade-islemleri/depo-iadeleri/{documentSerie}/{documentOrderNo}` | JWT + iade-islemleri.giden-depo-iadeleri.update | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32)<br>body: request / UpdateWarehouseShippingDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UpdateWarehouseShippingDocumentResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/iade-islemleri/depo-iadeleri/{documentSerie}/{documentOrderNo}/e-irsaliye` | JWT + iade-islemleri.giden-depo-iadeleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32)<br>body: request / SendEDespatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SendEDespatchResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/iade-islemleri/depo-iadeleri/{documentSerie}/{documentOrderNo}/e-irsaliye/pdf` | JWT + iade-islemleri.giden-depo-iadeleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: bildirilmemis<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| PUT | `/api/iade-islemleri/depo-iadeleri/{id}` | JWT + iade-islemleri.giden-depo-iadeleri.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/iade-islemleri/firma-iadeleri` | JWT + iade-islemleri.firma-iadeleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CompanyMovementListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/iade-islemleri/firma-iadeleri` | JWT + iade-islemleri.firma-iadeleri.create | body: request / CreateCompanyMovementHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateCompanyMovementResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/iade-islemleri/firma-iadeleri/offline-sync/{clientRequestId}` | JWT + iade-islemleri.firma-iadeleri.create | path: clientRequestId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OfflineSyncStatusDto&lt;CreateCompanyMovementResponse&gt;<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/iade-islemleri/firma-iadeleri/{documentSerie}/{documentOrderNo}` | JWT + iade-islemleri.firma-iadeleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CompanyMovementDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/iade-islemleri/firma-iadeleri/{documentSerie}/{documentOrderNo}/e-irsaliye` | JWT + iade-islemleri.firma-iadeleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32)<br>body: request / SendEDespatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SendEDespatchResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/iade-islemleri/firma-iadeleri/{documentSerie}/{documentOrderNo}/e-irsaliye/pdf` | JWT + iade-islemleri.firma-iadeleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: bildirilmemis<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| PUT | `/api/iade-islemleri/firma-iadeleri/{id}` | JWT + iade-islemleri.firma-iadeleri.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/integrations/axata-sync` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationOverviewDto |
| GET | `/api/integrations/axata-sync/advanced/audit` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: Take / integer (int32)<br>query: DocumentSerie / string<br>query: DocumentOrderNo / integer (int32)<br>query: Statuses / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataIntegrationAuditDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/advanced/jobs` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataSynchronizationExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>202: AxataSynchronizationJobDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/advanced/jobs/{jobId}` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: jobId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationJobDetailDto<br>404: ProblemDetails |
| POST | `/api/integrations/axata-sync/advanced/tasks/{taskCode}/execute` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: taskCode / string (zorunlu)<br>body: request / AxataSynchronizationExecuteTaskHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>202: AxataSynchronizationJobDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/advanced/tasks/{taskCode}/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: taskCode / string (zorunlu)<br>query: warehouseNo / integer (int32)<br>query: take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/advanced/{taskCode}/documents/outbox` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: taskCode / string (zorunlu)<br>body: request / AxataSynchronizationManualDocumentExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationManualDocumentDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/integrations/axata-sync/advanced/{taskCode}/documents/outbox-batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: taskCode / string (zorunlu)<br>body: request / AxataSynchronizationManualDocumentBatchExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationManualDocumentBatchDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/integrations/axata-sync/audit` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: Take / integer (int32)<br>query: DocumentSerie / string<br>query: DocumentOrderNo / integer (int32)<br>query: Statuses / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataIntegrationAuditDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/c01/documents/{documentSerie}/{documentOrderNo}/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / AxataOutboundDeliveryDocumentImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/integrations/axata-sync/c01/documents/{documentSerie}/{documentOrderNo}/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: status / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/integrations/axata-sync/c01/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/c01/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/c02/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/c02/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/c03/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/c03/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/c04/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/c04/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/connection-test` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationConnectionTestDto |
| GET | `/api/integrations/axata-sync/fetch-profiles` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationFetchProfilesOverviewDto |
| POST | `/api/integrations/axata-sync/g02/documents/{documentSerie}/{documentOrderNo}/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / AxataOutboundDeliveryDocumentImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/integrations/axata-sync/g02/documents/{documentSerie}/{documentOrderNo}/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: status / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/integrations/axata-sync/g02/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/g02/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/health` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationConnectionTestDto |
| GET | `/api/integrations/axata-sync/is-merkezi` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.list | query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: Take / integer (int32)<br>query: DocumentSerie / string<br>query: DocumentOrderNo / integer (int32)<br>query: Statuses / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationWorkbenchDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/jobs` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataSynchronizationExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>202: AxataSynchronizationJobDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/jobs/{jobId}` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: jobId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationJobDetailDto<br>404: ProblemDetails |
| GET | `/api/integrations/axata-sync/live/audit/overview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: Take / integer (int32)<br>query: DocumentSerie / string<br>query: DocumentOrderNo / integer (int32)<br>query: Statuses / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataIntegrationAuditDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/live/axata/dynamic-census/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataDynamicCensusExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/live/axata/dynamic-census/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataDynamicCensusPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/live/axata/inbound-atf/g01/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataG01InboundAtfExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/live/axata/inbound-atf/g01/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataG01InboundAtfPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/live/axata/inbound-deliveries/g02/documents/{documentSerie}/{documentOrderNo}/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / AxataOutboundDeliveryDocumentImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/integrations/axata-sync/live/axata/inbound-deliveries/g02/documents/{documentSerie}/{documentOrderNo}/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: status / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/integrations/axata-sync/live/axata/inbound-deliveries/g02/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/live/axata/inbound-deliveries/g02/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/live/axata/outbound-deliveries/by-date` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Date / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveriesByDateDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/{documentSerie}/{documentOrderNo}/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / AxataOutboundDeliveryDocumentImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/integrations/axata-sync/live/axata/outbound-deliveries/c01/documents/{documentSerie}/{documentOrderNo}/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: status / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/integrations/axata-sync/live/axata/outbound-deliveries/c01/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/live/axata/outbound-deliveries/c01/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/live/axata/outbound-deliveries/c02/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/live/axata/outbound-deliveries/c02/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/live/axata/outbound-deliveries/c03/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/live/axata/outbound-deliveries/c03/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/live/axata/outbound-deliveries/c04/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/live/axata/outbound-deliveries/c04/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/live/axata/outbound-deliveries/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: MovementType / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryQueuePreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/live/products/dispatch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataProductSynchronizationDispatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataProductSynchronizationExecuteDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/integrations/axata-sync/live/products/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: ProductCode / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataProductSynchronizationPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/live/products/{productCode}/dispatch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: productCode / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataProductSynchronizationExecuteDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/axata/inbound-atf/company-receivings` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataInboundAtfCompanyReceivingHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateCompanyReceivingResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/axata/inbound-atf/company-receivings/batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataInboundAtfCompanyReceivingBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataManualIncomingCompanyReceivingBatchResponse<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/axata/outbound-deliveries/inter-warehouse-shipments` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateInterWarehouseShipmentResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/axata/outbound-deliveries/inter-warehouse-shipments/batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataManualOutboundDeliveryBatchResponse<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/incoming/company-receivings` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / CreateCompanyReceivingHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateCompanyReceivingResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/incoming/company-receivings/batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataManualIncomingCompanyReceivingBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataManualIncomingCompanyReceivingBatchResponse<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/incoming/inventory-counts` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / CreateInventoryCountHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateInventoryCountResponse<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/incoming/inventory-counts/batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataManualIncomingInventoryCountBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataManualIncomingInventoryCountBatchResponse<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/manual/incoming/warehouse-receivings` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseShippingListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/incoming/warehouse-receivings/accept-batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.update | body: request / AxataManualIncomingWarehouseReceivingBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataManualIncomingWarehouseReceivingBatchResponse<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/manual/incoming/warehouse-receivings/{documentSerie}/{documentOrderNo}` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseShippingDetailDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/incoming/warehouse-receivings/{documentSerie}/{documentOrderNo}/accept` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.update | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / AcceptWarehouseReceivingHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AcceptWarehouseReceivingResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/integrations/axata-sync/manual/tasks/{taskCode}/documents/candidates` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: taskCode / string (zorunlu)<br>query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: Skip / integer (int32)<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationManualDocumentCandidatesDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/tasks/{taskCode}/documents/dispatch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: taskCode / string (zorunlu)<br>body: request / AxataSynchronizationManualDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationManualDispatchDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/tasks/{taskCode}/documents/dispatch-batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: taskCode / string (zorunlu)<br>body: request / AxataSynchronizationManualDocumentBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationManualDispatchBatchDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/tasks/{taskCode}/documents/execute` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: taskCode / string (zorunlu)<br>body: request / AxataSynchronizationManualDocumentExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationManualDocumentDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/tasks/{taskCode}/documents/execute-batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: taskCode / string (zorunlu)<br>body: request / AxataSynchronizationManualDocumentBatchExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationManualDocumentBatchDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/tasks/{taskCode}/documents/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: taskCode / string (zorunlu)<br>body: request / AxataSynchronizationManualDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationManualDocumentDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/integrations/axata-sync/manual/tasks/{taskCode}/documents/preview-batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: taskCode / string (zorunlu)<br>body: request / AxataSynchronizationManualDocumentBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationManualDocumentBatchDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/c01-shipment/documents/{documentSerie}/{documentOrderNo}/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / AxataOutboundDeliveryDocumentImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/integrations/axata-sync/operations/c01-shipment/documents/{documentSerie}/{documentOrderNo}/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: status / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/c01-shipment/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/operations/c01-shipment/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/c02-company-shipment/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/operations/c02-company-shipment/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/c03-legacy-movement/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/operations/c03-legacy-movement/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/c04-legacy-transfer/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/operations/c04-legacy-transfer/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/dynamic-census/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataDynamicCensusExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/operations/dynamic-census/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataDynamicCensusPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/g01-company-receiving/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataG01InboundAtfExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/operations/g01-company-receiving/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataG01InboundAtfPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/g02-warehouse-receiving/documents/{documentSerie}/{documentOrderNo}/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / AxataOutboundDeliveryDocumentImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/integrations/axata-sync/operations/g02-warehouse-receiving/documents/{documentSerie}/{documentOrderNo}/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: status / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/g02-warehouse-receiving/import` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryImportExecuteHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportExecuteDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/operations/g02-warehouse-receiving/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryImportPreviewDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/operations/outbound-delivery-queue/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: MovementType / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryQueuePreviewDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/operations/outbound-shipments/by-date` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: Date / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveriesByDateDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/product-master/dispatch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataProductSynchronizationDispatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataProductSynchronizationExecuteDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/integrations/axata-sync/operations/product-master/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: ProductCode / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataProductSynchronizationPreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/product-master/products/{productCode}/dispatch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: productCode / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataProductSynchronizationExecuteDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/integrations/axata-sync/operations/{taskCode}/documents/candidates` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: taskCode / string (zorunlu)<br>query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: Skip / integer (int32)<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationManualDocumentCandidatesDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/{taskCode}/documents/dispatch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: taskCode / string (zorunlu)<br>body: request / AxataSynchronizationManualDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationManualDispatchDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/{taskCode}/documents/dispatch-batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: taskCode / string (zorunlu)<br>body: request / AxataSynchronizationManualDocumentBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationManualDispatchBatchDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/{taskCode}/documents/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: taskCode / string (zorunlu)<br>body: request / AxataSynchronizationManualDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationManualDocumentDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/integrations/axata-sync/operations/{taskCode}/documents/preview-batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: taskCode / string (zorunlu)<br>body: request / AxataSynchronizationManualDocumentBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationManualDocumentBatchDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/integrations/axata-sync/outbound-deliveries` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: MovementType / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryQueuePreviewDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/panel` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.list | query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: Take / integer (int32)<br>query: DocumentSerie / string<br>query: DocumentOrderNo / integer (int32)<br>query: Statuses / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationPanelDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/profiles` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationFetchProfilesOverviewDto |
| GET | `/api/integrations/axata-sync/queues/outbound-deliveries` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | query: MovementType / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataOutboundDeliveryQueuePreviewDto<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/recovery/company-receivings/from-atf-body` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataInboundAtfCompanyReceivingHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateCompanyReceivingResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/integrations/axata-sync/recovery/company-receivings/from-atf-body-batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataInboundAtfCompanyReceivingBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataManualIncomingCompanyReceivingBatchResponse<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/recovery/company-receivings/manual` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / CreateCompanyReceivingHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateCompanyReceivingResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/integrations/axata-sync/recovery/company-receivings/manual-batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataManualIncomingCompanyReceivingBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataManualIncomingCompanyReceivingBatchResponse<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/recovery/inventory-counts/manual` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / CreateInventoryCountHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateInventoryCountResponse<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/recovery/inventory-counts/manual-batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataManualIncomingInventoryCountBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataManualIncomingInventoryCountBatchResponse<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/recovery/outbound-deliveries/from-body` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateInterWarehouseShipmentResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/integrations/axata-sync/recovery/outbound-deliveries/from-body-batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | body: request / AxataOutboundDeliveryBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataManualOutboundDeliveryBatchResponse<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/recovery/warehouse-receivings` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseShippingListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/integrations/axata-sync/recovery/warehouse-receivings/accept-batch` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.update | body: request / AxataManualIncomingWarehouseReceivingBatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataManualIncomingWarehouseReceivingBatchResponse<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/recovery/warehouse-receivings/{documentSerie}/{documentOrderNo}` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseShippingDetailDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/integrations/axata-sync/recovery/warehouse-receivings/{documentSerie}/{documentOrderNo}/accept` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.update | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / AcceptWarehouseReceivingHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AcceptWarehouseReceivingResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/integrations/axata-sync/status` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationOverviewDto |
| POST | `/api/integrations/axata-sync/tasks/{taskCode}/execute` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.create | path: taskCode / string (zorunlu)<br>body: request / AxataSynchronizationExecuteTaskHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>202: AxataSynchronizationJobDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/tasks/{taskCode}/preview` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.detail | path: taskCode / string (zorunlu)<br>query: warehouseNo / integer (int32)<br>query: take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationPreviewDto<br>400: ProblemDetails |
| GET | `/api/integrations/axata-sync/workbench` | JWT + entegrasyon-islemleri.axata-senkronizasyonu.list | query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: Take / integer (int32)<br>query: DocumentSerie / string<br>query: DocumentOrderNo / integer (int32)<br>query: Statuses / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: AxataSynchronizationWorkbenchDto<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/banknot-takipleri` | JWT + kasa-islemleri.banknot-takipleri.list | query: DateToGet / string (date-time) (zorunlu)<br>query: WarehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;BanknoteTrackDto&gt;<br>400: ProblemDetails |
| POST | `/api/kasa-islemleri/banknot-takipleri` | JWT + kasa-islemleri.banknot-takipleri.create | body: request / CreateBanknoteTrackHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CreateBanknoteTrackResponse<br>201: CreateBanknoteTrackResponse<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/banknot-takipleri/sayim-toplami` | JWT + kasa-islemleri.banknot-takipleri.list | query: DateToGet / string (date-time) (zorunlu)<br>query: WarehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: BanknoteTrackDailySummaryTotalDto<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/banknot-takipleri/{banknoteTrackId}` | JWT + kasa-islemleri.banknot-takipleri.detail | path: banknoteTrackId / string (uuid) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: BanknoteTrackDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/kasa-islemleri/birlik-kart-sorgulama/detay` | JWT + kasa-islemleri.birlik-kart-sorgulama.detail | body: request / BirlikKartDetayRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: BirlikKartDetayResponse<br>400: ProblemDetails |
| POST | `/api/kasa-islemleri/birlik-kart-sorgulama/guncelle` | JWT + kasa-islemleri.birlik-kart-sorgulama.update | body: request / BirlikKartSorgulamaGuncelleRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: BirlikKartGuncelleResponse<br>400: ProblemDetails |
| POST | `/api/kasa-islemleri/birlik-kart-sorgulama/sorgula` | JWT + kasa-islemleri.birlik-kart-sorgulama.list | body: request / BirlikKartSorgulamaRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: BirlikKartSorgulamaResponse<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/etiket-belgeleri` | JWT + kasa-islemleri.etiket-belgeleri.list | query: warehouseNo / integer (int32)<br>query: take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;LabelDocumentListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/kasa-islemleri/etiket-belgeleri` | JWT + kasa-islemleri.etiket-belgeleri.create | body: request / CreateLabelDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateLabelDocumentResponse<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/etiket-belgeleri/aktif-promosyonlu-urunler` | JWT + kasa-islemleri.etiket-belgeleri.list | query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;LabelActivePromotionProductDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/etiket-belgeleri/etiketler` | JWT + kasa-islemleri.etiket-belgeleri.list | query: WarehouseNo / integer (int32)<br>query: DateToGet / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;LabelTagDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/etiket-belgeleri/fiyati-degisen-urunler` | JWT + kasa-islemleri.etiket-belgeleri.list | query: WarehouseNo / integer (int32)<br>query: DateTimeFilter / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;LabelPriceChangedProductDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/etiket-belgeleri/get-by-date-for-label` | JWT + kasa-islemleri.etiket-belgeleri.list | query: WarehouseNo / integer (int32)<br>query: DateTimeFilter / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;LabelPriceChangedProductDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/etiket-belgeleri/son` | JWT + kasa-islemleri.etiket-belgeleri.list | query: warehouseNo / integer (int32)<br>query: take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;LabelDocumentListItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/etiket-belgeleri/tumu` | JWT + kasa-islemleri.etiket-belgeleri.list | query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;LabelDocumentListItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/etiket-belgeleri/{documentId}` | JWT + kasa-islemleri.etiket-belgeleri.detail | path: documentId / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;LabelDocumentProductDto&gt;<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/kasa-islemleri/etiket-belgeleri/{id}` | JWT + kasa-islemleri.etiket-belgeleri.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| POST | `/api/kasa-islemleri/kasa-ciro-aktarimi/metin/aktar` | JWT + kasa-islemleri.kasa-ciro-aktarimi.create | body: request / KasaCiroImportHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: KasaCiroImportResultDto<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-ciro-aktarimi/subeler` | JWT + kasa-islemleri.kasa-ciro-aktarimi.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;KasaCiroBranchDto&gt; |
| GET | `/api/kasa-islemleri/kasa-cirolari` | JWT + kasa-islemleri.kasa-cirolari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashTurnoverListItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-cirolari/detay` | JWT + kasa-islemleri.kasa-cirolari.detail | query: WarehouseNo / integer (int32)<br>query: BusinessDate / string (date-time) (zorunlu)<br>query: ShiftNo / integer (int32) (zorunlu)<br>query: CashierCode / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashTurnoverDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-cirolari/eski` | JWT + kasa-islemleri.kasa-cirolari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashTurnoverListItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-cirolari/eski/detay` | JWT + kasa-islemleri.kasa-cirolari.detail | query: WarehouseNo / integer (int32)<br>query: BusinessDate / string (date-time) (zorunlu)<br>query: ShiftNo / integer (int32) (zorunlu)<br>query: CashierCode / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashTurnoverDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-cirolari/eski/ozet` | JWT + kasa-islemleri.kasa-cirolari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashTurnoverOverviewDto<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-cirolari/ozet` | JWT + kasa-islemleri.kasa-cirolari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashTurnoverOverviewDto<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-cirolari/toplam` | JWT + kasa-islemleri.kasa-cirolari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashTurnoverListItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-cirolari/toplam/detay` | JWT + kasa-islemleri.kasa-cirolari.detail | query: WarehouseNo / integer (int32)<br>query: BusinessDate / string (date-time) (zorunlu)<br>query: ShiftNo / integer (int32) (zorunlu)<br>query: CashierCode / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashTurnoverDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-cirolari/toplam/ozet` | JWT + kasa-islemleri.kasa-cirolari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashTurnoverOverviewDto<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-cirolari/yeni` | JWT + kasa-islemleri.kasa-cirolari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashTurnoverListItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-cirolari/yeni/detay` | JWT + kasa-islemleri.kasa-cirolari.detail | query: WarehouseNo / integer (int32)<br>query: BusinessDate / string (date-time) (zorunlu)<br>query: ShiftNo / integer (int32) (zorunlu)<br>query: CashierCode / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashTurnoverDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-cirolari/yeni/ozet` | JWT + kasa-islemleri.kasa-cirolari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashTurnoverOverviewDto<br>400: ProblemDetails |
| POST | `/api/kasa-islemleri/kasa-hareket-aktarimi/hareketler/aktar` | JWT + kasa-islemleri.kasa-hareket-aktarimi.create | body: request / KasaHareketImportHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: KasaHareketImportResultDto<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-hareket-aktarimi/icmal-karsilastirma` | JWT + kasa-islemleri.kasa-hareket-aktarimi.detail | query: Date / string (date-time) (zorunlu)<br>query: BranchNo / integer (int32)<br>query: CashRegisterNo / integer (int32)<br>query: Tolerance / number (double) | 401: ProblemDetails<br>403: ProblemDetails<br>200: KasaHareketCashSummaryComparisonDto<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-hareket-aktarimi/icmal-karsilastirma/detay` | JWT + kasa-islemleri.kasa-hareket-aktarimi.detail | query: Date / string (date-time) (zorunlu)<br>query: BranchNo / integer (int32) (zorunlu)<br>query: CashRegisterNo / integer (int32) (zorunlu)<br>query: ReceiptTake / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: KasaHareketDetailDto<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-hareket-aktarimi/icmal-karsilastirma/excel` | JWT + kasa-islemleri.kasa-hareket-aktarimi.detail | query: Date / string (date-time) (zorunlu)<br>query: BranchNo / integer (int32)<br>query: CashRegisterNo / integer (int32)<br>query: Tolerance / number (double) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FileContentResult<br>400: ProblemDetails |
| POST | `/api/kasa-islemleri/kasa-hareket-aktarimi/iptal-belgeleri/aktar` | JWT + kasa-islemleri.kasa-hareket-aktarimi.create | body: request / KasaHareketImportHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: KasaHareketImportResultDto<br>400: ProblemDetails |
| DELETE | `/api/kasa-islemleri/kasa-hareket-aktarimi/mikro` | JWT + kasa-islemleri.kasa-hareket-aktarimi.update | body: request / KasaHareketMikroTransferHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: KasaHareketProcedureResultDto<br>400: ProblemDetails |
| POST | `/api/kasa-islemleri/kasa-hareket-aktarimi/mikro/aktar` | JWT + kasa-islemleri.kasa-hareket-aktarimi.create | body: request / KasaHareketMikroTransferHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: KasaHareketProcedureResultDto<br>400: ProblemDetails |
| POST | `/api/kasa-islemleri/kasa-hareket-aktarimi/mikro/aralik-aktar` | JWT + kasa-islemleri.kasa-hareket-aktarimi.create | body: request / KasaHareketMikroTransferRangeHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: KasaHareketProcedureResultDto<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-hareket-aktarimi/rapor` | JWT + kasa-islemleri.kasa-hareket-aktarimi.detail | query: Date / string (date-time) (zorunlu)<br>query: BranchNo / integer (int32)<br>query: CashRegisterNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;KasaHareketReportRowDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-hareket-aktarimi/rapor/excel` | JWT + kasa-islemleri.kasa-hareket-aktarimi.detail | query: Date / string (date-time) (zorunlu)<br>query: BranchNo / integer (int32)<br>query: CashRegisterNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FileContentResult<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-hareket-aktarimi/rapor/ozet` | JWT + kasa-islemleri.kasa-hareket-aktarimi.detail | query: Date / string (date-time) (zorunlu)<br>query: BranchNo / integer (int32)<br>query: CashRegisterNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: KasaHareketReportSummaryDto<br>400: ProblemDetails |
| DELETE | `/api/kasa-islemleri/kasa-hareket-aktarimi/staging` | JWT + kasa-islemleri.kasa-hareket-aktarimi.update | body: request / KasaHareketDeleteStagingHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: KasaHareketProcedureResultDto<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-hareket-aktarimi/subeler` | JWT + kasa-islemleri.kasa-hareket-aktarimi.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;KasaHareketBranchDto&gt; |
| GET | `/api/kasa-islemleri/kasa-hareket-aktarimi/subeler/{branchNo}/kasalar` | JWT + kasa-islemleri.kasa-hareket-aktarimi.list | path: branchNo / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;KasaHareketCashRegisterDto&gt;<br>400: ProblemDetails |
| POST | `/api/kasa-islemleri/kasa-hareket-aktarimi/zamanli-aktarim/calistir` | JWT + kasa-islemleri.kasa-hareket-aktarimi.create | body: request / KasaHareketScheduledImportHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: KasaHareketImportResultDto<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-sayimlari` | JWT + kasa-islemleri.kasa-sayimlari.list | query: DateToGet / string (date-time) (zorunlu)<br>query: WarehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashSummaryListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/kasa-islemleri/kasa-sayimlari` | JWT + kasa-islemleri.icmal-kaydi-girisi.create | body: request / CreateCashSummaryHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateCashSummaryResponse<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-sayimlari/banknot-tipleri` | JWT + kasa-islemleri.icmal-kaydi-girisi.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;BanknoteTypeItemDto&gt; |
| POST | `/api/kasa-islemleri/kasa-sayimlari/deletesummary` | JWT + kasa-islemleri.kasa-sayimlari.delete | body: request / LegacyDeleteCashSummaryHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: DeleteCashSummaryResponse<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-sayimlari/hediye-ceki-tipleri` | JWT + kasa-islemleri.icmal-kaydi-girisi.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;GiftCheckTypeItemDto&gt; |
| GET | `/api/kasa-islemleri/kasa-sayimlari/kasa-detayi` | JWT + kasa-islemleri.icmal-kaydi-girisi.list | query: CashNo / integer (int32)<br>query: CashRegisterNo / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashRegisterDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-sayimlari/kasalar` | JWT + kasa-islemleri.icmal-kaydi-girisi.list | query: BranchNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashRegistryItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-sayimlari/kasiyerler` | JWT + kasa-islemleri.icmal-kaydi-girisi.list | query: FilterString / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashierSearchItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-sayimlari/kasiyerler/ikili` | JWT + kasa-islemleri.icmal-kaydi-girisi.list | query: CashierCode / integer (int32) (zorunlu)<br>query: ManagerCode / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashierItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-sayimlari/odeme-tipleri/banka` | JWT + kasa-islemleri.icmal-kaydi-girisi.list | query: CashRegisterNo / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;PaymentTypeItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-sayimlari/odeme-tipleri/magaza-masrafi` | JWT + kasa-islemleri.icmal-kaydi-girisi.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;PaymentTypeItemDto&gt; |
| GET | `/api/kasa-islemleri/kasa-sayimlari/odeme-tipleri/masraf-pusulasi` | JWT + kasa-islemleri.icmal-kaydi-girisi.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;PaymentTypeItemDto&gt; |
| GET | `/api/kasa-islemleri/kasa-sayimlari/odeme-tipleri/online` | JWT + kasa-islemleri.icmal-kaydi-girisi.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;PaymentTypeItemDto&gt; |
| GET | `/api/kasa-islemleri/kasa-sayimlari/odeme-tipleri/yemek-ceki` | JWT + kasa-islemleri.icmal-kaydi-girisi.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;PaymentTypeItemDto&gt; |
| GET | `/api/kasa-islemleri/kasa-sayimlari/online-kasa-detaylari` | JWT + kasa-islemleri.icmal-kaydi-girisi.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashRegisterDetailDto&gt; |
| GET | `/api/kasa-islemleri/kasa-sayimlari/rapor` | JWT + kasa-islemleri.kasa-sayimlari.list | query: DateToGet / string (date-time) (zorunlu)<br>query: WarehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashSummaryReportItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/kasa-islemleri/kasa-sayimlari/updatebanknotemovements` | JWT + kasa-islemleri.kasa-sayimlari.update | body: request / LegacyUpdateCashSummaryBanknotesHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UpdateCashSummaryBanknotesResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/kasa-islemleri/kasa-sayimlari/updategiftcheckmovements` | JWT + kasa-islemleri.kasa-sayimlari.update | body: request / LegacyUpdateCashSummaryGiftChecksHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UpdateCashSummaryGiftChecksResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/kasa-islemleri/kasa-sayimlari/updatesummarydetails` | JWT + kasa-islemleri.kasa-sayimlari.update | body: request / LegacyUpdateCashSummaryDetailsHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UpdateCashSummaryDetailsResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-sayimlari/z-rapor-toplam` | JWT + kasa-islemleri.icmal-kaydi-girisi.list | query: WarehouseNo / integer (int32)<br>query: DocumentSerie / string<br>query: ZReportNo / integer (int32) (zorunlu)<br>query: CashNo / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: Double<br>400: ProblemDetails |
| DELETE | `/api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}` | JWT + kasa-islemleri.kasa-sayimlari.delete | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: DeleteCashSummaryResponse<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}` | JWT + kasa-islemleri.kasa-sayimlari.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashSummaryDetailItemDto&gt;<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/banknot-hareketleri` | JWT + kasa-islemleri.kasa-sayimlari.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;BanknoteMovementItemDto&gt;<br>400: ProblemDetails |
| PUT | `/api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/banknot-hareketleri` | JWT + kasa-islemleri.kasa-sayimlari.update | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / UpdateCashSummaryBanknotesHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UpdateCashSummaryBanknotesResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/detaylar` | JWT + kasa-islemleri.kasa-sayimlari.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CashSummaryDetailItemDto&gt;<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/detaylar` | JWT + kasa-islemleri.kasa-sayimlari.update | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / UpdateCashSummaryDetailsHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UpdateCashSummaryDetailsResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/hediye-ceki-hareketleri` | JWT + kasa-islemleri.kasa-sayimlari.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;GiftCheckMovementItemDto&gt;<br>400: ProblemDetails |
| PUT | `/api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/hediye-ceki-hareketleri` | JWT + kasa-islemleri.kasa-sayimlari.update | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / UpdateCashSummaryGiftChecksHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UpdateCashSummaryGiftChecksResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/kasa-sayimlari/{documentSerie}/{documentOrderNo}/z-rapor-toplam` | JWT + kasa-islemleri.kasa-sayimlari.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CashSummaryZReportTotalDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/kunye-etiket-yazdirma` | JWT + kasa-islemleri.kunye-etiket-yazdirma.list | query: DateToGet / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;LabelTagDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-kunye-etiket-yazdirma/detayli-etiketler` | Anonim | query: WarehouseNo / integer (int32) (zorunlu)<br>query: DateToGet / string (date-time) | 200: IReadOnlyCollection&lt;KunyeLabelTagDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records` | JWT + kasa-islemleri.manav-mal-kabul-etiket.list | query: Date / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ManavMalKabulVeEtiketAcceptanceRecordDto&gt;<br>400: ProblemDetails |
| POST | `/api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records` | JWT + kasa-islemleri.manav-mal-kabul-etiket.create | body: request / SaveManavMalKabulVeEtiketAcceptanceRecordHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: ManavMalKabulVeEtiketAcceptanceRecordDto<br>400: ProblemDetails |
| POST | `/api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records/calculate` | JWT + kasa-islemleri.manav-mal-kabul-etiket.create | body: request / ManavMalKabulVeEtiketCalculationHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ManavMalKabulVeEtiketCalculationDto<br>400: ProblemDetails |
| DELETE | `/api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records/{id}` | JWT + kasa-islemleri.manav-mal-kabul-etiket.delete | path: id / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>204: bildirilmemis<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records/{id}` | JWT + kasa-islemleri.manav-mal-kabul-etiket.detail | path: id / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ManavMalKabulVeEtiketAcceptanceRecordDto<br>404: ProblemDetails |
| PUT | `/api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records/{id}` | JWT + kasa-islemleri.manav-mal-kabul-etiket.update | path: id / integer (int32) (zorunlu)<br>body: request / SaveManavMalKabulVeEtiketAcceptanceRecordHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ManavMalKabulVeEtiketAcceptanceRecordDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/acceptance-records/{id}/label` | JWT + kasa-islemleri.manav-mal-kabul-etiket.detail | path: id / integer (int32) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ManavMalKabulVeEtiketLabelDto<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/incoming-invoices` | JWT + kasa-islemleri.manav-mal-kabul-etiket.list | query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: SupplierCode / string<br>query: SearchText / string<br>query: IncludeArchived / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ManavMalKabulVeEtiketIncomingInvoiceDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/incoming-invoices/ettn/{ettn}` | JWT + kasa-islemleri.manav-mal-kabul-etiket.detail | path: ettn / string (zorunlu)<br>query: supplierCode / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: ManavMalKabulVeEtiketInvoiceDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/incoming-invoices/{invoiceLookupId}/detail` | JWT + kasa-islemleri.manav-mal-kabul-etiket.detail | path: invoiceLookupId / string (zorunlu)<br>query: supplierCode / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: ManavMalKabulVeEtiketInvoiceDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/kasa-islemleri/manav-mal-kabul-etiket/labels/preview` | JWT + kasa-islemleri.manav-mal-kabul-etiket.create | body: request / SaveManavMalKabulVeEtiketAcceptanceRecordHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ManavMalKabulVeEtiketLabelDto<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/micro/goods-receipts` | JWT + kasa-islemleri.manav-mal-kabul-etiket.list | query: Date / string (date-time) (zorunlu)<br>query: SupplierCode / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ManavMalKabulVeEtiketMicroGoodsReceiptDocumentDto&gt;<br>400: ProblemDetails |
| POST | `/api/kasa-islemleri/manav-mal-kabul-etiket/micro/goods-receipts` | JWT + kasa-islemleri.manav-mal-kabul-etiket.transfer | body: request / ManavMalKabulVeEtiketCreateMicroGoodsReceiptHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: ManavMalKabulVeEtiketCreateMicroGoodsReceiptResultDto<br>400: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/micro/goods-receipts/comparison` | JWT + kasa-islemleri.manav-mal-kabul-etiket.list | query: Date / string (date-time) (zorunlu)<br>query: SupplierCode / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ManavMalKabulVeEtiketGoodsReceiptComparisonItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/reports/depot-stock` | JWT + kasa-islemleri.manav-mal-kabul-etiket.list | query: WarehouseNo / integer (int32)<br>query: Date / string (date-time) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ManavMalKabulVeEtiketDepotStockReportItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/reports/received-products` | JWT + kasa-islemleri.manav-mal-kabul-etiket.list | query: Date / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ManavMalKabulVeEtiketReceivedProductReportItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/stocks` | JWT + kasa-islemleri.manav-mal-kabul-etiket.list | query: Query / string<br>query: Prefix / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ManavMalKabulVeEtiketStockSuggestionDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/stocks/by-name` | JWT + kasa-islemleri.manav-mal-kabul-etiket.list | query: name / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ManavMalKabulVeEtiketStockSuggestionDto<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/stocks/{stockCode}` | JWT + kasa-islemleri.manav-mal-kabul-etiket.list | path: stockCode / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ManavMalKabulVeEtiketStockSuggestionDto<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/suppliers` | JWT + kasa-islemleri.manav-mal-kabul-etiket.list | query: Query / string (zorunlu)<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ManavMalKabulVeEtiketSupplierSuggestionDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/manav-mal-kabul-etiket/suppliers/by-name` | JWT + kasa-islemleri.manav-mal-kabul-etiket.list | query: name / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ManavMalKabulVeEtiketSupplierSuggestionDto<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/yeni-kasa-analizleri/anomaliler` | JWT + kasa-islemleri.yeni-kasa-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: CashRegisterNo / string<br>query: CashierCode / string<br>query: Take / integer (int32)<br>query: OnlyProblematic / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;YeniKasaAnomalyItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/yeni-kasa-analizleri/ciro-ozeti` | JWT + kasa-islemleri.yeni-kasa-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: CashRegisterNo / string<br>query: CashierCode / string<br>query: Take / integer (int32)<br>query: OnlyProblematic / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;YeniKasaCiroOzetItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/yeni-kasa-analizleri/fis-detay` | JWT + kasa-islemleri.yeni-kasa-analizleri.list | query: Uuid / string<br>query: BusinessDate / string (date-time)<br>query: WarehouseNo / integer (int32)<br>query: CashRegisterNo / string<br>query: ReceiptNumber / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: YeniKasaFisDetayDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kasa-islemleri/yeni-kasa-analizleri/fis-mutabakat` | JWT + kasa-islemleri.yeni-kasa-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: CashRegisterNo / string<br>query: CashierCode / string<br>query: Take / integer (int32)<br>query: OnlyProblematic / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;YeniKasaFisMutabakatItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/yeni-kasa-analizleri/kasa-ozeti` | JWT + kasa-islemleri.yeni-kasa-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: CashRegisterNo / string<br>query: CashierCode / string<br>query: Take / integer (int32)<br>query: OnlyProblematic / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;YeniKasaKasaOzetItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/yeni-kasa-analizleri/odeme-tipleri` | JWT + kasa-islemleri.yeni-kasa-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: CashRegisterNo / string<br>query: CashierCode / string<br>query: Take / integer (int32)<br>query: OnlyProblematic / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;YeniKasaPaymentMethodItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kasa-islemleri/yeni-kasa-analizleri/saglik-ozeti` | JWT + kasa-islemleri.yeni-kasa-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: CashRegisterNo / string<br>query: CashierCode / string<br>query: Take / integer (int32)<br>query: OnlyProblematic / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;YeniKasaSaglikOzetItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/kullanici-islemleri/kullanicilar` | JWT + kullanici-islemleri.kullanicilar.manage |  | 200: IReadOnlyCollection&lt;UserDto&gt; |
| GET | `/api/kullanici-islemleri/kullanicilar/{id}` | JWT + kullanici-islemleri.kullanicilar.manage | path: id / string (uuid) (zorunlu) | 200: UserDto<br>404: ProblemDetails |
| PUT | `/api/kullanici-islemleri/kullanicilar/{id}` | JWT + kullanici-islemleri.kullanicilar.manage | path: id / string (uuid) (zorunlu)<br>body: request / UpdateUserBody (zorunlu) | 200: UserDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/kullanici-islemleri/kullanicilar/{id}/client-roles` | JWT + kullanici-islemleri.kullanicilar.manage | path: id / string (uuid) (zorunlu) | 200: IReadOnlyCollection&lt;UserClientRoleDto&gt;<br>404: ProblemDetails |
| PUT | `/api/kullanici-islemleri/kullanicilar/{id}/client-roles/{clientType}` | JWT + kullanici-islemleri.kullanicilar.manage | path: id / string (uuid) (zorunlu)<br>path: clientType / string (zorunlu)<br>body: request / AssignClientRolesBody (zorunlu) | 200: IReadOnlyCollection&lt;UserClientRoleDto&gt;<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/kullanici-islemleri/kullanicilar/{id}/roles` | JWT + kullanici-islemleri.kullanicilar.manage | path: id / string (uuid) (zorunlu)<br>body: request / AssignRolesBody (zorunlu) | 200: UserDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kullanici-islemleri/roller` | JWT + kullanici-islemleri.roller.manage |  | 200: IReadOnlyCollection&lt;RoleDto&gt; |
| POST | `/api/kullanici-islemleri/roller` | JWT + kullanici-islemleri.roller.manage | body: request / SaveRoleBody (zorunlu) | 200: RoleDto<br>400: ProblemDetails<br>409: ProblemDetails |
| PUT | `/api/kullanici-islemleri/roller/{id}` | JWT + kullanici-islemleri.roller.manage | path: id / string (uuid) (zorunlu)<br>body: request / SaveRoleBody (zorunlu) | 200: RoleDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/kullanici-islemleri/roller/{id}/permissions` | JWT + kullanici-islemleri.roller.manage | path: id / string (uuid) (zorunlu)<br>body: request / AssignPermissionsBody (zorunlu) | 200: RoleDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/kullanici-islemleri/yetkiler` | JWT + kullanici-islemleri.yetkiler.manage |  | 200: IReadOnlyCollection&lt;PermissionDto&gt; |
| POST | `/api/kullanici-islemleri/yetkiler` | JWT + kullanici-islemleri.yetkiler.manage | body: request / SavePermissionBody (zorunlu) | 200: PermissionDto<br>400: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/kullanici-islemleri/yetkiler/catalog` | JWT + kullanici-islemleri.yetkiler.manage |  | 200: IReadOnlyCollection&lt;PermissionModuleDto&gt; |
| PUT | `/api/kullanici-islemleri/yetkiler/{id}` | JWT + kullanici-islemleri.yetkiler.manage | path: id / string (uuid) (zorunlu)<br>body: request / SavePermissionBody (zorunlu) | 200: PermissionDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/legacy/e-irsaliye/{documentKind}/giden/{documentSerie}/{documentOrderNo}/durum` | Anonim | path: documentKind / string (zorunlu)<br>path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 400: ProblemDetails<br>403: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails<br>200: GetEDespatchStatusResponse |
| POST | `/api/legacy/e-irsaliye/{documentKind}/giden/{documentSerie}/{documentOrderNo}/gonder` | Anonim | path: documentKind / string (zorunlu)<br>path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32)<br>body: request / LegacySendEDespatchHttpRequest (zorunlu) | 400: ProblemDetails<br>403: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails<br>200: SendEDespatchResponse |
| GET | `/api/legacy/e-irsaliye/{documentKind}/giden/{documentSerie}/{documentOrderNo}/pdf` | Anonim | path: documentKind / string (zorunlu)<br>path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 400: ProblemDetails<br>403: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails<br>200: bildirilmemis |
| GET | `/api/legacy/e-irsaliye/{documentKind}/{documentSerie}/{documentOrderNo}/durum` | Anonim | path: documentKind / string (zorunlu)<br>path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 400: ProblemDetails<br>403: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails<br>200: GetEDespatchStatusResponse |
| POST | `/api/legacy/e-irsaliye/{documentKind}/{documentSerie}/{documentOrderNo}/gonder` | Anonim | path: documentKind / string (zorunlu)<br>path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32)<br>body: request / LegacySendEDespatchHttpRequest (zorunlu) | 400: ProblemDetails<br>403: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails<br>200: SendEDespatchResponse |
| GET | `/api/legacy/e-irsaliye/{documentKind}/{documentSerie}/{documentOrderNo}/pdf` | Anonim | path: documentKind / string (zorunlu)<br>path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 400: ProblemDetails<br>403: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails<br>200: bildirilmemis |
| GET | `/api/mal-kabul-islemleri/depo-mal-kabulleri` | JWT + mal-kabul-islemleri.depo-mal-kabulleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseShippingListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/mal-kabul-islemleri/depo-mal-kabulleri` | JWT + mal-kabul-islemleri.depo-mal-kabulleri.create | body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/mal-kabul-islemleri/depo-mal-kabulleri/e-irsaliye/ettn/{ettn}` | JWT + mal-kabul-islemleri.depo-mal-kabulleri.update | path: ettn / string (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: InboundDespatchLookupResponse<br>400: ProblemDetails |
| GET | `/api/mal-kabul-islemleri/depo-mal-kabulleri/{documentSerie}/{documentOrderNo}` | JWT + mal-kabul-islemleri.depo-mal-kabulleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseShippingDetailDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/mal-kabul-islemleri/depo-mal-kabulleri/{documentSerie}/{documentOrderNo}/kabul` | JWT + mal-kabul-islemleri.depo-mal-kabulleri.update | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / AcceptWarehouseReceivingHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AcceptWarehouseReceivingResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| PUT | `/api/mal-kabul-islemleri/depo-mal-kabulleri/{id}` | JWT + mal-kabul-islemleri.depo-mal-kabulleri.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/mal-kabul-islemleri/firma-mal-kabulleri` | JWT + mal-kabul-islemleri.firma-mal-kabulleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CompanyMovementListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/mal-kabul-islemleri/firma-mal-kabulleri` | JWT + mal-kabul-islemleri.firma-mal-kabulleri.create | body: request / CreateCompanyReceivingHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateCompanyReceivingResponse<br>200: CreateCompanyReceivingResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/mal-kabul-islemleri/firma-mal-kabulleri/e-irsaliye/ettn/{ettn}` | JWT + mal-kabul-islemleri.firma-mal-kabulleri.create | path: ettn / string (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: InboundDespatchLookupResponse<br>400: ProblemDetails |
| GET | `/api/mal-kabul-islemleri/firma-mal-kabulleri/offline-sync/{clientRequestId}` | JWT + mal-kabul-islemleri.firma-mal-kabulleri.create | path: clientRequestId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OfflineSyncStatusDto&lt;CreateCompanyReceivingResponse&gt;<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/mal-kabul-islemleri/firma-mal-kabulleri/resmi-belge/ettn/{ettn}` | JWT + mal-kabul-islemleri.firma-mal-kabulleri.create | path: ettn / string (zorunlu)<br>query: warehouseNo / integer (int32)<br>query: documentKind / string | 401: ProblemDetails<br>403: ProblemDetails<br>200: InboundDespatchLookupResponse<br>400: ProblemDetails |
| GET | `/api/mal-kabul-islemleri/firma-mal-kabulleri/{documentSerie}/{documentOrderNo}` | JWT + mal-kabul-islemleri.firma-mal-kabulleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CompanyMovementDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/mal-kabul-islemleri/firma-mal-kabulleri/{id}` | JWT + mal-kabul-islemleri.firma-mal-kabulleri.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/mal-kabul-islemleri/mal-kabul-farklari` | JWT + mal-kabul-islemleri.mal-kabul-farklari.list | query: Scope / string<br>query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseReceivingDifferenceDto&gt;<br>400: ProblemDetails |
| GET | `/api/mal-kabul-islemleri/mal-kabul-farklari/accepted` | JWT + mal-kabul-islemleri.mal-kabul-farklari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseReceivingDifferenceDto&gt;<br>400: ProblemDetails |
| GET | `/api/mal-kabul-islemleri/mal-kabul-farklari/created` | JWT + mal-kabul-islemleri.mal-kabul-farklari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseReceivingDifferenceDto&gt;<br>400: ProblemDetails |
| GET | `/api/mal-kabul-islemleri/mal-kabul-farklari/kabul-ettigim` | JWT + mal-kabul-islemleri.mal-kabul-farklari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseReceivingDifferenceDto&gt;<br>400: ProblemDetails |
| GET | `/api/mal-kabul-islemleri/mal-kabul-farklari/olusturdugum` | JWT + mal-kabul-islemleri.mal-kabul-farklari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseReceivingDifferenceDto&gt;<br>400: ProblemDetails |
| GET | `/api/mal-kabul-islemleri/mal-kabuller/depo-sevkleri/{documentSerie}/{documentOrderNo}` | JWT + mal-kabul-islemleri.depo-mal-kabulleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseShippingDetailDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/mal-kabul-islemleri/mal-kabuller/depo-sevkleri/{documentSerie}/{documentOrderNo}/kabul` | JWT + mal-kabul-islemleri.depo-mal-kabulleri.update | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>body: request / AcceptWarehouseReceivingHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AcceptWarehouseReceivingResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/mal-kabul-islemleri/mal-kabuller/firma` | JWT + mal-kabul-islemleri.firma-mal-kabulleri.create | body: request / CreateCompanyReceivingHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateCompanyReceivingResponse<br>200: CreateCompanyReceivingResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/mobile-sync/cari-katalogu` | JWT | query: Since / string (date-time)<br>query: Cursor / string<br>query: PageSize / integer (int32) | 401: ProblemDetails<br>200: MobileCustomerCatalogResponse<br>400: ProblemDetails |
| GET | `/api/mobile-sync/depo-katalogu` | JWT | query: Since / string (date-time)<br>query: Cursor / string<br>query: PageSize / integer (int32) | 401: ProblemDetails<br>200: MobileWarehouseCatalogResponse<br>400: ProblemDetails |
| GET | `/api/mobile-sync/urun-fiyat-katalogu` | JWT + arama-islemleri.fiyat-gor.list | query: WarehouseNo / integer (int32)<br>query: Since / string (date-time)<br>query: Cursor / string<br>query: PageSize / integer (int32) | 401: ProblemDetails<br>200: MobileProductPriceCatalogResponse<br>400: ProblemDetails<br>403: ProblemDetails |
| GET | `/api/operasyon-islemleri/belge-akis-takibi` | JWT + operasyon-islemleri.belge-akis-takibi.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: DocumentType / FurpaMerkezApi.Domain.Entities.DocumentFlowType<br>query: Status / FurpaMerkezApi.Domain.Entities.DocumentFlowStatus<br>query: Search / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: DocumentFlowListResponse<br>400: ProblemDetails |
| GET | `/api/operasyon-islemleri/belge-akis-takibi/{id}` | JWT + operasyon-islemleri.belge-akis-takibi.detail | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: DocumentFlowDetailDto<br>404: ProblemDetails |
| GET | `/api/operasyon-islemleri/depo-operasyon-paneli` | JWT + operasyon-islemleri.depo-operasyon-paneli.all-warehouses + operasyon-islemleri.depo-operasyon-paneli.list | query: date / string (date) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseOperationsDashboardDto |
| GET | `/api/operasyon-islemleri/firma-evrak-takibi` | JWT + operasyon-islemleri.firma-evrak-takibi.list | query: Date / string (date) (zorunlu)<br>query: WarehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CompanyDocumentTrackingDto<br>400: ProblemDetails |
| GET | `/api/operasyon-islemleri/urun-dagilimlari` | JWT + operasyon-islemleri.urun-dagilimlari.list | query: Status / integer (int32)<br>query: DocumentNo / string<br>query: StockCode / string<br>query: DistributionCenterWarehouseNo / integer (int32)<br>query: CreatedFrom / string (date-time)<br>query: CreatedTo / string (date-time)<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ProductDistributionListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/operasyon-islemleri/urun-dagilimlari` | JWT + operasyon-islemleri.urun-dagilimlari.create | body: request / ProductDistributionSaveHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: ProductDistributionDetailDto<br>400: ProblemDetails |
| GET | `/api/operasyon-islemleri/urun-dagilimlari/dagitim-merkezleri` | JWT + operasyon-islemleri.urun-dagilimlari.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ProductDistributionCenterDto&gt; |
| POST | `/api/operasyon-islemleri/urun-dagilimlari/dengele` | JWT + operasyon-islemleri.urun-dagilimlari.create | body: request / ProductDistributionBalanceHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ProductDistributionBalanceDto<br>400: ProblemDetails |
| POST | `/api/operasyon-islemleri/urun-dagilimlari/oneri` | JWT + operasyon-islemleri.urun-dagilimlari.create | body: request / ProductDistributionProposalHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ProductDistributionProposalDto<br>400: ProblemDetails |
| DELETE | `/api/operasyon-islemleri/urun-dagilimlari/{documentNo}` | JWT + operasyon-islemleri.urun-dagilimlari.delete | path: documentNo / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ProductDistributionDeleteDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/operasyon-islemleri/urun-dagilimlari/{documentNo}` | JWT + operasyon-islemleri.urun-dagilimlari.detail | path: documentNo / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ProductDistributionDetailDto<br>404: ProblemDetails |
| PUT | `/api/operasyon-islemleri/urun-dagilimlari/{documentNo}` | JWT + operasyon-islemleri.urun-dagilimlari.update | path: documentNo / string (zorunlu)<br>body: request / ProductDistributionSaveHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ProductDistributionDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/operasyon-islemleri/urun-dagilimlari/{documentNo}/bilgilendir` | JWT + operasyon-islemleri.urun-dagilimlari.update | path: documentNo / string (zorunlu)<br>body: request / ProductDistributionNotifyHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ProductDistributionNotificationDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/operasyon-islemleri/urun-dagilimlari/{documentNo}/kesinlestir` | JWT + operasyon-islemleri.urun-dagilimlari.update | path: documentNo / string (zorunlu)<br>body: request / ProductDistributionFinalizeHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ProductDistributionFinalizeDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/operations/authorization-files` | JWT + operasyon-islemleri.operations.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;AuthorizationFileDto&gt; |
| POST | `/api/operations/authorization-files` | JWT + operasyon-islemleri.operations.update | body: fileList / IReadOnlyCollection&lt;SaveAuthorizationFileHttpRequest&gt; (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: bildirilmemis<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/operations/cashierfile` | JWT + operasyon-islemleri.operations.create | query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>202: OperationJobDto<br>400: ProblemDetails |
| GET | `/api/operations/customerfile` | JWT + operasyon-islemleri.operations.create | query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>202: OperationJobDto<br>400: ProblemDetails |
| GET | `/api/operations/einvoicevnofile` | JWT + operasyon-islemleri.operations.create | query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>202: OperationJobDto<br>400: ProblemDetails |
| GET | `/api/operations/getauthorizationfile` | JWT + operasyon-islemleri.operations.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;AuthorizationFileDto&gt; |
| GET | `/api/operations/jobs/{jobId}` | JWT + operasyon-islemleri.operations.detail | path: jobId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OperationJobDetailDto<br>404: ProblemDetails |
| GET | `/api/operations/productbarcodeplonofile` | JWT + operasyon-islemleri.operations.create | query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>202: OperationJobDto<br>400: ProblemDetails |
| GET | `/api/operations/productbarcodeplunofile` | JWT + operasyon-islemleri.operations.create | query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>202: OperationJobDto<br>400: ProblemDetails |
| GET | `/api/operations/promofile` | JWT + operasyon-islemleri.operations.create | query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>202: OperationJobDto<br>400: ProblemDetails |
| POST | `/api/operations/saveauthorizationfile` | JWT + operasyon-islemleri.operations.update | body: fileList / IReadOnlyCollection&lt;SaveAuthorizationFileHttpRequest&gt; (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: bildirilmemis<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/operations/scalesfile` | JWT + operasyon-islemleri.operations.create | query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>202: OperationJobDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/ortak-islemler/duyurular` | JWT + ortak-islemler.duyurular.list | query: Status / string<br>query: TargetType / string<br>query: TargetWarehouseNo / integer (int32)<br>query: TargetUserId / string (uuid)<br>query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: IncludeArchived / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;AnnouncementDto&gt;<br>400: ProblemDetails |
| POST | `/api/ortak-islemler/duyurular` | JWT + ortak-islemler.duyurular.create | body: request / SaveAnnouncementHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: AnnouncementDto<br>400: ProblemDetails |
| GET | `/api/ortak-islemler/duyurular/hedef-kullanicilar` | JWT + ortak-islemler.duyurular.list | query: Search / string<br>query: WarehouseNo / integer (int32)<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;AnnouncementTargetUserDto&gt;<br>400: ProblemDetails |
| GET | `/api/ortak-islemler/duyurular/{id}` | JWT + ortak-islemler.duyurular.detail | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AnnouncementDto<br>404: ProblemDetails |
| PUT | `/api/ortak-islemler/duyurular/{id}` | JWT + ortak-islemler.duyurular.update | path: id / string (uuid) (zorunlu)<br>body: request / SaveAnnouncementHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AnnouncementDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PATCH | `/api/ortak-islemler/duyurular/{id}/arsivle` | JWT + ortak-islemler.duyurular.archive | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AnnouncementDto<br>404: ProblemDetails |
| GET | `/api/ortak-islemler/duyurular/{id}/okuyanlar` | JWT + ortak-islemler.duyurular.detail | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AnnouncementReadReceiptListDto<br>404: ProblemDetails |
| GET | `/api/ortak-islemler/sikayet-oneri` | JWT + ortak-islemler.sikayet-oneri.list | query: Status / string<br>query: Type / string<br>query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;FeedbackItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/ortak-islemler/sikayet-oneri` | JWT | body: request / CreateFeedbackItemHttpRequest (zorunlu) | 401: ProblemDetails<br>201: FeedbackItemDto<br>400: ProblemDetails |
| GET | `/api/ortak-islemler/sikayet-oneri/benim` | JWT |  | 401: ProblemDetails<br>200: IReadOnlyCollection&lt;FeedbackItemDto&gt; |
| GET | `/api/ortak-islemler/sikayet-oneri/ozet` | JWT |  | 401: ProblemDetails<br>200: FeedbackSummaryDto |
| GET | `/api/ortak-islemler/sikayet-oneri/{id}` | JWT + ortak-islemler.sikayet-oneri.detail | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FeedbackItemDto<br>404: ProblemDetails |
| PATCH | `/api/ortak-islemler/sikayet-oneri/{id}/durum` | JWT + ortak-islemler.sikayet-oneri.update | path: id / string (uuid) (zorunlu)<br>body: request / ChangeFeedbackStatusHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FeedbackItemDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PATCH | `/api/ortak-islemler/sikayet-oneri/{id}/okundu` | JWT + ortak-islemler.sikayet-oneri.update | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FeedbackItemDto<br>404: ProblemDetails |
| GET | `/api/permissions` | JWT + kullanici-islemleri.yetkiler.manage |  | 200: IReadOnlyCollection&lt;PermissionDto&gt; |
| POST | `/api/permissions` | JWT + kullanici-islemleri.yetkiler.manage | body: request / SavePermissionBody (zorunlu) | 200: PermissionDto<br>400: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/permissions/catalog` | JWT + kullanici-islemleri.yetkiler.manage |  | 200: IReadOnlyCollection&lt;PermissionModuleDto&gt; |
| PUT | `/api/permissions/{id}` | JWT + kullanici-islemleri.yetkiler.manage | path: id / string (uuid) (zorunlu)<br>body: request / SavePermissionBody (zorunlu) | 200: PermissionDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/rapor-islemleri/promosyon-raporlari/bulten-secenekleri` | JWT + rapor-islemleri.promosyon-raporlari.list | query: WarehouseNo / integer (int32)<br>query: ActiveOn / string (date-time)<br>query: OnlyActive / boolean<br>query: Search / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;PromotionBulletinOptionDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/promosyon-raporlari/bultenler` | JWT + rapor-islemleri.promosyon-raporlari.list | query: WarehouseNo / integer (int32)<br>query: ActiveOn / string (date-time)<br>query: OnlyActive / boolean<br>query: Search / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;PromotionBulletinListItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/promosyon-raporlari/bultenler/secenekler` | JWT + rapor-islemleri.promosyon-raporlari.list | query: WarehouseNo / integer (int32)<br>query: ActiveOn / string (date-time)<br>query: OnlyActive / boolean<br>query: Search / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;PromotionBulletinOptionDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/promosyon-raporlari/performans` | JWT + rapor-islemleri.promosyon-raporlari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: PromotionCode / string<br>query: Search / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: PromotionPerformanceReportDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/promosyon-raporlari/performans/sube` | JWT + rapor-islemleri.promosyon-raporlari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: PromotionCode / string<br>query: Search / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;PromotionBranchPerformanceItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/promosyon-raporlari/satis-marj-etkisi` | JWT + rapor-islemleri.promosyon-raporlari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: PromotionCode / string<br>query: Search / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: PromotionPerformanceReportDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/banka-hareketleri` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;BankMovementAnalysisItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/banka-hareketleri/sube` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;BranchBankMovementSummaryItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/banka-odeme-ozetleri/banka` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: BankPaymentSummaryReportDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/banka-odeme-ozetleri/merchant` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: MerchantPaymentSummaryReportDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/banka-odeme-ozetleri/valor` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: ValorPaymentSummaryReportDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/eksik-cirolar` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;MissingTurnoverBranchItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/indirim-kartlari` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;DiscountCardDetailItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/marketyo-satislari` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: MyoSalesReportDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/marketyo-satislari/sube` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;MyoSalesByBranchItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/yemek-cekleri` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FoodCheckReportDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/yemek-cekleri/genel-toplam` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SalesAnalysisAmountDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/yemek-cekleri/metropol-toplam` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SalesAnalysisAmountDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/yemek-cekleri/multinet-toplam` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SalesAnalysisAmountDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/yemek-cekleri/setcard-toplam` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SalesAnalysisAmountDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/yemek-cekleri/sodexo-kupon-toplam` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SalesAnalysisAmountDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/yemek-cekleri/sodexo-pos-toplam` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SalesAnalysisAmountDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/yemek-cekleri/ticket-kupon-toplam` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SalesAnalysisAmountDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/yemek-cekleri/ticket-pos-toplam` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SalesAnalysisAmountDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/yemek-cekleri/toplamlar` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FoodCheckTotalsDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/satis-analizleri/z-rapor-banka-analizi` | JWT + rapor-islemleri.satis-analizleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ZReportBankAnalysisItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/depo-sifir-stok` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: ReportDate / string (date-time)<br>query: ModelCode / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseZeroStockDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/depoda-var-subede-yok` | JWT + rapor-islemleri.stok-raporlari.list | query: SourceWarehouseNo / integer (int32) (zorunlu)<br>query: TargetWarehouseNo / integer (int32)<br>query: ReportDate / string (date-time)<br>query: Search / string<br>query: ModelCode / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseMissingStockDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/envanter-degeri` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: ReportDate / string (date-time)<br>query: Search / string<br>query: SupplierCode / string<br>query: CategoryCode / string<br>query: ProducerCode / string<br>query: ProductManagerCode / string<br>query: ModelCode / string<br>query: OnlyWithStock / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockOnHandReportDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/giris-cikis-karsilastirma` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: FilterType / string<br>query: FilterValue / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;MovementInOutComparisonDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/hareketler` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: StockCode / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;StockMovementReportItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/iadeler/subeler` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: StockCode / string (zorunlu)<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ReturnBranchReportItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/karlilik` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: Scope / string<br>query: FilterValue / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ProfitabilityReportItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/kategori-secenekleri` | JWT + rapor-islemleri.stok-raporlari.list | query: Search / string<br>query: OnlyActive / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;StockCategoryOptionDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/kategori-son-stok` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: ReportDate / string (date-time)<br>query: CategoryCode / string (zorunlu)<br>query: Search / string<br>query: OnlyWithStock / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockOnHandReportDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/satislar/satmayan-urunler` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: ProductManagerCode / string<br>query: IncludeDls / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;NotSoldProductReportItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/satislar/sube-detay` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: FilterType / string<br>query: FilterValue / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;BranchSalesReportItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/satislar/yil-karsilastirma` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: FilterType / string<br>query: FilterValue / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;YearSalesComparisonItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/sayim-karsilastirma` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: CountDate / string (date-time) (zorunlu)<br>query: DocumentNo / integer (int32)<br>query: PackageCode / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CountingComparisonReportItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/son-stok` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: ReportDate / string (date-time)<br>query: Search / string<br>query: SupplierCode / string<br>query: CategoryCode / string<br>query: ProducerCode / string<br>query: ProductManagerCode / string<br>query: ModelCode / string<br>query: OnlyWithStock / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockOnHandReportDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/stok-kartlari` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: Barcode / string<br>query: StockCode / string<br>query: StockName / string<br>query: SupplierCode / string<br>query: ProductManagerCode / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;StockCardDetailDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/tedarikci-son-stok` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: ReportDate / string (date-time)<br>query: SupplierCode / string (zorunlu)<br>query: Search / string<br>query: OnlyWithStock / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockOnHandReportDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/uretici-son-stok` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: ReportDate / string (date-time)<br>query: ProducerCode / string (zorunlu)<br>query: Search / string<br>query: OnlyWithStock / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockOnHandReportDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/urun-ara` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: Barcode / string<br>query: StockCode / string<br>query: StockName / string<br>query: SupplierCode / string<br>query: ProductManagerCode / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;StockCardDetailDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/urun-depo-durum` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: ReportDate / string (date-time)<br>query: StockCodeOrBarcode / string (zorunlu)<br>query: OnlyWithStock / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ProductWarehouseStockDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/urun-sevk-dagilimi` | JWT + rapor-islemleri.stok-raporlari.list | query: WarehouseNo / integer (int32)<br>query: ShipmentDate / string (date-time)<br>query: StockCodeOrBarcode / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ProductShipmentDistributionDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/stok-raporlari/urun/{stockCodeOrBarcode}/depo-durum` | JWT + rapor-islemleri.stok-raporlari.list | path: stockCodeOrBarcode / string (zorunlu)<br>query: WarehouseNo / integer (int32)<br>query: ReportDate / string (date-time)<br>query: OnlyWithStock / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;ProductWarehouseStockDto&gt;<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/tedarikci-performans-karnesi` | JWT + rapor-islemleri.tedarikci-performans-karnesi.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: CustomerCode / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SupplierPerformanceReportDto<br>400: ProblemDetails |
| GET | `/api/rapor-islemleri/tedarikci-performans-karnesi/{customerCode}` | JWT + rapor-islemleri.tedarikci-performans-karnesi.detail | path: customerCode / string (zorunlu)<br>query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: EventTake / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SupplierPerformanceDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/roles` | JWT + kullanici-islemleri.roller.manage |  | 200: IReadOnlyCollection&lt;RoleDto&gt; |
| POST | `/api/roles` | JWT + kullanici-islemleri.roller.manage | body: request / SaveRoleBody (zorunlu) | 200: RoleDto<br>400: ProblemDetails<br>409: ProblemDetails |
| PUT | `/api/roles/{id}` | JWT + kullanici-islemleri.roller.manage | path: id / string (uuid) (zorunlu)<br>body: request / SaveRoleBody (zorunlu) | 200: RoleDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/roles/{id}/permissions` | JWT + kullanici-islemleri.roller.manage | path: id / string (uuid) (zorunlu)<br>body: request / AssignPermissionsBody (zorunlu) | 200: RoleDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/sevk-islemleri/depolar-arasi-sevkler` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseShippingListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/sevk-islemleri/depolar-arasi-sevkler` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.create | body: request / CreateInterWarehouseShipmentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateInterWarehouseShipmentResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/sevk-islemleri/depolar-arasi-sevkler/gelen` | JWT + sevk-islemleri.gelen-depolar-arasi-sevkler.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseShippingListItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/sevk-islemleri/depolar-arasi-sevkler/gelen/{documentSerie}/{documentOrderNo}` | JWT + sevk-islemleri.gelen-depolar-arasi-sevkler.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseShippingDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/sevk-islemleri/depolar-arasi-sevkler/giden` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseShippingListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/sevk-islemleri/depolar-arasi-sevkler/giden` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.create | body: request / CreateInterWarehouseShipmentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateInterWarehouseShipmentResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/sevk-islemleri/depolar-arasi-sevkler/giden/offline-sync/{clientRequestId}` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.create | path: clientRequestId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OfflineSyncStatusDto&lt;CreateInterWarehouseShipmentResponse&gt;<br>404: ProblemDetails<br>409: ProblemDetails |
| DELETE | `/api/sevk-islemleri/depolar-arasi-sevkler/giden/{documentSerie}/{documentOrderNo}` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.delete | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: DeleteWarehouseShippingDocumentResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/sevk-islemleri/depolar-arasi-sevkler/giden/{documentSerie}/{documentOrderNo}` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseShippingDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/sevk-islemleri/depolar-arasi-sevkler/giden/{documentSerie}/{documentOrderNo}` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.update | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32)<br>body: request / UpdateWarehouseShippingDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UpdateWarehouseShippingDocumentResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/sevk-islemleri/depolar-arasi-sevkler/giden/{documentSerie}/{documentOrderNo}/e-irsaliye` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32)<br>body: request / SendEDespatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SendEDespatchResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/sevk-islemleri/depolar-arasi-sevkler/giden/{documentSerie}/{documentOrderNo}/e-irsaliye/pdf` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: bildirilmemis<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/sevk-islemleri/depolar-arasi-sevkler/offline-sync/{clientRequestId}` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.create | path: clientRequestId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OfflineSyncStatusDto&lt;CreateInterWarehouseShipmentResponse&gt;<br>404: ProblemDetails<br>409: ProblemDetails |
| DELETE | `/api/sevk-islemleri/depolar-arasi-sevkler/{documentSerie}/{documentOrderNo}` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.delete | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: DeleteWarehouseShippingDocumentResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/sevk-islemleri/depolar-arasi-sevkler/{documentSerie}/{documentOrderNo}` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseShippingDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/sevk-islemleri/depolar-arasi-sevkler/{documentSerie}/{documentOrderNo}` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.update | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32)<br>body: request / UpdateWarehouseShippingDocumentHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: UpdateWarehouseShippingDocumentResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| POST | `/api/sevk-islemleri/depolar-arasi-sevkler/{documentSerie}/{documentOrderNo}/e-irsaliye` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32)<br>body: request / SendEDespatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SendEDespatchResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/sevk-islemleri/depolar-arasi-sevkler/{documentSerie}/{documentOrderNo}/e-irsaliye/pdf` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: bildirilmemis<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| PUT | `/api/sevk-islemleri/depolar-arasi-sevkler/{id}` | JWT + sevk-islemleri.giden-depolar-arasi-sevkler.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/sevk-islemleri/firma-sevkleri` | JWT + sevk-islemleri.giden-firma-sevkleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CompanyMovementListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/sevk-islemleri/firma-sevkleri` | JWT + sevk-islemleri.giden-firma-sevkleri.create | body: request / CreateCompanyMovementHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateCompanyMovementResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/sevk-islemleri/firma-sevkleri/gelen` | JWT + sevk-islemleri.gelen-firma-sevkleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CompanyMovementListItemDto&gt;<br>400: ProblemDetails |
| GET | `/api/sevk-islemleri/firma-sevkleri/gelen/{documentSerie}/{documentOrderNo}` | JWT + sevk-islemleri.gelen-firma-sevkleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CompanyMovementDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/sevk-islemleri/firma-sevkleri/giden` | JWT + sevk-islemleri.giden-firma-sevkleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CompanyMovementListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/sevk-islemleri/firma-sevkleri/giden` | JWT + sevk-islemleri.giden-firma-sevkleri.create | body: request / CreateCompanyMovementHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateCompanyMovementResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/sevk-islemleri/firma-sevkleri/giden/offline-sync/{clientRequestId}` | JWT + sevk-islemleri.giden-firma-sevkleri.create | path: clientRequestId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OfflineSyncStatusDto&lt;CreateCompanyMovementResponse&gt;<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/sevk-islemleri/firma-sevkleri/giden/{documentSerie}/{documentOrderNo}` | JWT + sevk-islemleri.giden-firma-sevkleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CompanyMovementDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/sevk-islemleri/firma-sevkleri/giden/{documentSerie}/{documentOrderNo}/e-irsaliye` | JWT + sevk-islemleri.giden-firma-sevkleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32)<br>body: request / SendEDespatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SendEDespatchResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/sevk-islemleri/firma-sevkleri/giden/{documentSerie}/{documentOrderNo}/e-irsaliye/pdf` | JWT + sevk-islemleri.giden-firma-sevkleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: bildirilmemis<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/sevk-islemleri/firma-sevkleri/offline-sync/{clientRequestId}` | JWT + sevk-islemleri.giden-firma-sevkleri.create | path: clientRequestId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OfflineSyncStatusDto&lt;CreateCompanyMovementResponse&gt;<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/sevk-islemleri/firma-sevkleri/{documentSerie}/{documentOrderNo}` | JWT + sevk-islemleri.giden-firma-sevkleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CompanyMovementDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/sevk-islemleri/firma-sevkleri/{documentSerie}/{documentOrderNo}/e-irsaliye` | JWT + sevk-islemleri.giden-firma-sevkleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32)<br>body: request / SendEDespatchHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: SendEDespatchResponse<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/sevk-islemleri/firma-sevkleri/{documentSerie}/{documentOrderNo}/e-irsaliye/pdf` | JWT + sevk-islemleri.giden-firma-sevkleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: bildirilmemis<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| PUT | `/api/sevk-islemleri/firma-sevkleri/{id}` | JWT + sevk-islemleri.giden-firma-sevkleri.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/siparis-islemleri/alinan-depo-siparisleri` | JWT + siparis-islemleri.alinan-depo-siparisleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseOrderListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/siparis-islemleri/alinan-depo-siparisleri` | JWT + siparis-islemleri.alinan-depo-siparisleri.create | body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/siparis-islemleri/alinan-depo-siparisleri/key/{documentKey}` | JWT + siparis-islemleri.alinan-depo-siparisleri.detail | path: documentKey / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseOrderDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/siparis-islemleri/alinan-depo-siparisleri/toplu-yazdir` | JWT + siparis-islemleri.alinan-depo-siparisleri.print | body: request / BulkPrintReceivedWarehouseOrdersHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FileContentResult<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/siparis-islemleri/alinan-depo-siparisleri/{documentSerie}/{documentOrderNo}` | JWT + siparis-islemleri.alinan-depo-siparisleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseOrderDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/siparis-islemleri/alinan-depo-siparisleri/{id}` | JWT + siparis-islemleri.alinan-depo-siparisleri.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/siparis-islemleri/alinan-firma-siparisleri` | JWT + siparis-islemleri.alinan-firma-siparisleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CompanyOrderListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/siparis-islemleri/alinan-firma-siparisleri` | JWT + siparis-islemleri.alinan-firma-siparisleri.create | body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/siparis-islemleri/alinan-firma-siparisleri/key/{documentKey}` | JWT + siparis-islemleri.alinan-firma-siparisleri.detail | path: documentKey / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CompanyOrderDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/siparis-islemleri/alinan-firma-siparisleri/{documentSerie}/{documentOrderNo}` | JWT + siparis-islemleri.alinan-firma-siparisleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CompanyOrderDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/siparis-islemleri/alinan-firma-siparisleri/{id}` | JWT + siparis-islemleri.alinan-firma-siparisleri.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/siparis-islemleri/onerilen-depo-siparisleri` | JWT + siparis-islemleri.onerilen-depo-siparisleri.list | query: TargetWarehouseNo / integer (int32)<br>query: SourceWarehouseNo / integer (int32)<br>query: LookbackDays / integer (int32)<br>query: FallbackRecommendedDay / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;SuggestedWarehouseOrderListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/siparis-islemleri/onerilen-depo-siparisleri/convert-to-order` | JWT + siparis-islemleri.onerilen-depo-siparisleri.create | body: request / ConvertSuggestedWarehouseOrderHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateIssuedWarehouseOrderResponse<br>400: ProblemDetails |
| GET | `/api/siparis-islemleri/onerilen-depo-siparisleri/kaynak-depo-urunleri` | JWT + siparis-islemleri.onerilen-depo-siparisleri.list | query: sourceWarehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;SuggestedWarehouseSourceProductDto&gt;<br>400: ProblemDetails |
| GET | `/api/siparis-islemleri/onerilen-depo-siparisleri/manav` | JWT + siparis-islemleri.onerilen-depo-siparisleri.list |  | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;SuggestedWarehouseSourceProductDto&gt;<br>400: ProblemDetails |
| GET | `/api/siparis-islemleri/onerilen-firma-siparisleri` | JWT + siparis-islemleri.onerilen-firma-siparisleri.list | query: WarehouseNo / integer (int32)<br>query: SupplierCode / string (zorunlu)<br>query: LookbackDays / integer (int32)<br>query: FallbackRecommendedDay / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;SuggestedCompanyOrderListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/siparis-islemleri/onerilen-firma-siparisleri/convert-to-order` | JWT + siparis-islemleri.onerilen-firma-siparisleri.create | body: request / ConvertSuggestedCompanyOrderHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateIssuedCompanyOrderResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/siparis-islemleri/verilen-depo-siparisleri` | JWT + siparis-islemleri.verilen-depo-siparisleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;WarehouseOrderListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/siparis-islemleri/verilen-depo-siparisleri` | JWT + siparis-islemleri.verilen-depo-siparisleri.create | body: request / CreateIssuedWarehouseOrderHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateIssuedWarehouseOrderResponse<br>400: ProblemDetails |
| GET | `/api/siparis-islemleri/verilen-depo-siparisleri/key/{documentKey}` | JWT + siparis-islemleri.verilen-depo-siparisleri.detail | path: documentKey / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseOrderDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/siparis-islemleri/verilen-depo-siparisleri/{documentSerie}/{documentOrderNo}` | JWT + siparis-islemleri.verilen-depo-siparisleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: WarehouseOrderDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/siparis-islemleri/verilen-depo-siparisleri/{id}` | JWT + siparis-islemleri.verilen-depo-siparisleri.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/siparis-islemleri/verilen-firma-siparisleri` | JWT + siparis-islemleri.verilen-firma-siparisleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu)<br>query: CustomerCode / string<br>query: OnlyOpen / boolean | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;CompanyOrderListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/siparis-islemleri/verilen-firma-siparisleri` | JWT + siparis-islemleri.verilen-firma-siparisleri.create | body: request / CreateIssuedCompanyOrderHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateIssuedCompanyOrderResponse<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/siparis-islemleri/verilen-firma-siparisleri/firma-urunleri` | JWT + siparis-islemleri.verilen-firma-siparisleri.create | query: WarehouseNo / integer (int32)<br>query: CustomerCode / string (zorunlu)<br>query: Search / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;IssuedCompanyOrderSupplierProductDto&gt;<br>400: ProblemDetails |
| GET | `/api/siparis-islemleri/verilen-firma-siparisleri/key/{documentKey}` | JWT + siparis-islemleri.verilen-firma-siparisleri.detail | path: documentKey / string (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CompanyOrderDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/siparis-islemleri/verilen-firma-siparisleri/{documentSerie}/{documentOrderNo}` | JWT + siparis-islemleri.verilen-firma-siparisleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: CompanyOrderDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/siparis-islemleri/verilen-firma-siparisleri/{id}` | JWT + siparis-islemleri.verilen-firma-siparisleri.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/stok-islemleri/masraf-fisleri` | JWT + stok-islemleri.masraf-fisleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;StockReceiptListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/stok-islemleri/masraf-fisleri` | JWT + stok-islemleri.masraf-fisleri.create | body: request / CreateStockReceiptHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateStockReceiptResponse<br>400: ProblemDetails |
| GET | `/api/stok-islemleri/masraf-fisleri/offline-sync/{clientRequestId}` | JWT + stok-islemleri.masraf-fisleri.create | path: clientRequestId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OfflineSyncStatusDto&lt;CreateStockReceiptResponse&gt;<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/stok-islemleri/masraf-fisleri/{documentSerie}/{documentOrderNo}` | JWT + stok-islemleri.masraf-fisleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockReceiptDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/stok-islemleri/masraf-fisleri/{id}` | JWT + stok-islemleri.masraf-fisleri.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/stok-islemleri/sayim-sonuclari` | JWT + stok-islemleri.sayim-sonuclari.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;InventoryCountListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/stok-islemleri/sayim-sonuclari` | JWT + stok-islemleri.sayim-sonuclari.create | body: request / CreateInventoryCountHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateInventoryCountResponse<br>200: CreateInventoryCountResponse<br>400: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/stok-islemleri/sayim-sonuclari/offline-sync/{clientRequestId}` | JWT + stok-islemleri.sayim-sonuclari.create | path: clientRequestId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OfflineSyncStatusDto&lt;CreateInventoryCountResponse&gt;<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/stok-islemleri/sayim-sonuclari/{documentNo}` | JWT + stok-islemleri.sayim-sonuclari.detail | path: documentNo / integer (int32) (zorunlu)<br>query: documentDate / string (date-time) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: InventoryCountDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/stok-islemleri/sayim-sonuclari/{id}` | JWT + stok-islemleri.sayim-sonuclari.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/stok-islemleri/stok-anomali-merkezi` | JWT + stok-islemleri.stok-anomali-merkezi.list | query: WarehouseNo / integer (int32)<br>query: Type / FurpaMerkezApi.Domain.Entities.StockAnomalyType<br>query: Status / FurpaMerkezApi.Domain.Entities.StockAnomalyStatus<br>query: Severity / FurpaMerkezApi.Domain.Entities.StockAnomalySeverity<br>query: ProductManagerCode / string<br>query: HasProductManager / boolean<br>query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: Search / string<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockAnomalyListResponse<br>400: ProblemDetails |
| GET | `/api/stok-islemleri/stok-anomali-merkezi/satin-almacilar` | JWT + stok-islemleri.stok-anomali-merkezi.list | query: WarehouseNo / integer (int32)<br>query: Status / FurpaMerkezApi.Domain.Entities.StockAnomalyStatus | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;StockAnomalyProductManagerDto&gt; |
| POST | `/api/stok-islemleri/stok-anomali-merkezi/tara` | JWT + stok-islemleri.stok-anomali-merkezi.scan | body: request / StockAnomalyScanHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockAnomalyScanResponse<br>400: ProblemDetails |
| GET | `/api/stok-islemleri/stok-anomali-merkezi/{id}` | JWT + stok-islemleri.stok-anomali-merkezi.detail | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockAnomalyDetailDto<br>404: ProblemDetails |
| POST | `/api/stok-islemleri/stok-anomali-merkezi/{id}/durum` | JWT + stok-islemleri.stok-anomali-merkezi.update | path: id / string (uuid) (zorunlu)<br>body: request / ChangeStockAnomalyStatusHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockAnomalyDetailDto<br>404: ProblemDetails<br>400: ProblemDetails |
| GET | `/api/stok-islemleri/virmanlar` | JWT + stok-islemleri.virmanlar.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;VirmanListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/stok-islemleri/virmanlar` | JWT + stok-islemleri.virmanlar.create | body: request / CreateVirmanHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateVirmanResponse<br>400: ProblemDetails |
| GET | `/api/stok-islemleri/virmanlar/donusum-onerisi` | JWT + stok-islemleri.virmanlar.create | query: SourceStockCode / string (zorunlu)<br>query: SourceQuantity / number (double) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: VirmanConversionSuggestionDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/stok-islemleri/virmanlar/offline-sync/{clientRequestId}` | JWT + stok-islemleri.virmanlar.create | path: clientRequestId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OfflineSyncStatusDto&lt;CreateVirmanResponse&gt;<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/stok-islemleri/virmanlar/{documentSerie}/{documentOrderNo}` | JWT + stok-islemleri.virmanlar.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: VirmanDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/stok-islemleri/virmanlar/{id}` | JWT + stok-islemleri.virmanlar.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| GET | `/api/stok-islemleri/zayiat-fisleri` | JWT + stok-islemleri.zayiat-fisleri.list | query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time) (zorunlu)<br>query: EndDate / string (date-time) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;StockReceiptListItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/stok-islemleri/zayiat-fisleri` | JWT + stok-islemleri.zayiat-fisleri.create | body: request / CreateStockReceiptHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: CreateStockReceiptResponse<br>400: ProblemDetails |
| GET | `/api/stok-islemleri/zayiat-fisleri/offline-sync/{clientRequestId}` | JWT + stok-islemleri.zayiat-fisleri.create | path: clientRequestId / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: OfflineSyncStatusDto&lt;CreateStockReceiptResponse&gt;<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/stok-islemleri/zayiat-fisleri/{documentSerie}/{documentOrderNo}` | JWT + stok-islemleri.zayiat-fisleri.detail | path: documentSerie / string (zorunlu)<br>path: documentOrderNo / integer (int32) (zorunlu)<br>query: warehouseNo / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: StockReceiptDetailDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PUT | `/api/stok-islemleri/zayiat-fisleri/{id}` | JWT + stok-islemleri.zayiat-fisleri.update | path: id / string (zorunlu)<br>body: request / ModuleActionRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>501: ModuleActionScaffoldResponse |
| POST | `/api/terminal-installations/heartbeat` | JWT | body: request / TerminalHeartbeatHttpRequest (zorunlu) | 200: TerminalInstallationDto<br>400: ProblemDetails<br>401: ProblemDetails<br>403: ProblemDetails |
| GET | `/api/users` | JWT + kullanici-islemleri.kullanicilar.manage |  | 200: IReadOnlyCollection&lt;UserDto&gt; |
| GET | `/api/users/{id}` | JWT + kullanici-islemleri.kullanicilar.manage | path: id / string (uuid) (zorunlu) | 200: UserDto<br>404: ProblemDetails |
| PUT | `/api/users/{id}` | JWT + kullanici-islemleri.kullanicilar.manage | path: id / string (uuid) (zorunlu)<br>body: request / UpdateUserBody (zorunlu) | 200: UserDto<br>400: ProblemDetails<br>404: ProblemDetails<br>409: ProblemDetails |
| GET | `/api/users/{id}/client-roles` | JWT + kullanici-islemleri.kullanicilar.manage | path: id / string (uuid) (zorunlu) | 200: IReadOnlyCollection&lt;UserClientRoleDto&gt;<br>404: ProblemDetails |
| PUT | `/api/users/{id}/client-roles/{clientType}` | JWT + kullanici-islemleri.kullanicilar.manage | path: id / string (uuid) (zorunlu)<br>path: clientType / string (zorunlu)<br>body: request / AssignClientRolesBody (zorunlu) | 200: IReadOnlyCollection&lt;UserClientRoleDto&gt;<br>400: ProblemDetails<br>404: ProblemDetails |
| POST | `/api/users/{id}/roles` | JWT + kullanici-islemleri.kullanicilar.manage | path: id / string (uuid) (zorunlu)<br>body: request / AssignRolesBody (zorunlu) | 200: UserDto<br>400: ProblemDetails<br>404: ProblemDetails |
| GET | `/api/yonetim/duyurular` | JWT + ortak-islemler.duyurular.list | query: Status / string<br>query: TargetType / string<br>query: TargetWarehouseNo / integer (int32)<br>query: TargetUserId / string (uuid)<br>query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: IncludeArchived / boolean<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;AnnouncementDto&gt;<br>400: ProblemDetails |
| POST | `/api/yonetim/duyurular` | JWT + ortak-islemler.duyurular.create | body: request / SaveAnnouncementHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>201: AnnouncementDto<br>400: ProblemDetails |
| GET | `/api/yonetim/duyurular/hedef-kullanicilar` | JWT + ortak-islemler.duyurular.list | query: Search / string<br>query: WarehouseNo / integer (int32)<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;AnnouncementTargetUserDto&gt;<br>400: ProblemDetails |
| GET | `/api/yonetim/duyurular/{id}` | JWT + ortak-islemler.duyurular.detail | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AnnouncementDto<br>404: ProblemDetails |
| PUT | `/api/yonetim/duyurular/{id}` | JWT + ortak-islemler.duyurular.update | path: id / string (uuid) (zorunlu)<br>body: request / SaveAnnouncementHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AnnouncementDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PATCH | `/api/yonetim/duyurular/{id}/arsivle` | JWT + ortak-islemler.duyurular.archive | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AnnouncementDto<br>404: ProblemDetails |
| GET | `/api/yonetim/duyurular/{id}/okuyanlar` | JWT + ortak-islemler.duyurular.detail | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: AnnouncementReadReceiptListDto<br>404: ProblemDetails |
| GET | `/api/yonetim/sikayet-oneri` | JWT + ortak-islemler.sikayet-oneri.list | query: Status / string<br>query: Type / string<br>query: WarehouseNo / integer (int32)<br>query: StartDate / string (date-time)<br>query: EndDate / string (date-time)<br>query: Take / integer (int32) | 401: ProblemDetails<br>403: ProblemDetails<br>200: IReadOnlyCollection&lt;FeedbackItemDto&gt;<br>400: ProblemDetails |
| POST | `/api/yonetim/sikayet-oneri` | JWT | body: request / CreateFeedbackItemHttpRequest (zorunlu) | 401: ProblemDetails<br>201: FeedbackItemDto<br>400: ProblemDetails |
| GET | `/api/yonetim/sikayet-oneri/benim` | JWT |  | 401: ProblemDetails<br>200: IReadOnlyCollection&lt;FeedbackItemDto&gt; |
| GET | `/api/yonetim/sikayet-oneri/ozet` | JWT |  | 401: ProblemDetails<br>200: FeedbackSummaryDto |
| GET | `/api/yonetim/sikayet-oneri/{id}` | JWT + ortak-islemler.sikayet-oneri.detail | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FeedbackItemDto<br>404: ProblemDetails |
| PATCH | `/api/yonetim/sikayet-oneri/{id}/durum` | JWT + ortak-islemler.sikayet-oneri.update | path: id / string (uuid) (zorunlu)<br>body: request / ChangeFeedbackStatusHttpRequest (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FeedbackItemDto<br>400: ProblemDetails<br>404: ProblemDetails |
| PATCH | `/api/yonetim/sikayet-oneri/{id}/okundu` | JWT + ortak-islemler.sikayet-oneri.update | path: id / string (uuid) (zorunlu) | 401: ProblemDetails<br>403: ProblemDetails<br>200: FeedbackItemDto<br>404: ProblemDetails |

## JSON Modelleri

### FurpaMerkezApi.Application.Abstractions.Services.EDespatchDocumentType

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|

Enum degerleri JSON sozlesmesinde bulunur.

### FurpaMerkezApi.Application.Abstractions.Services.GetEDespatchStatusResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | FurpaMerkezApi.Application.Abstractions.Services.EDespatchDocumentType | Hayir |  |
| `eDespatchDocumentNo` | string | Hayir | nullable |
| `eDespatchUuid` | string | Hayir | nullable |
| `isSentToUyumsoft` | boolean | Hayir |  |
| `localMikroMetadataUpdateQueued` | boolean | Hayir |  |
| `localMikroMetadataUpdated` | boolean | Hayir |  |
| `sentAtUtc` | string (date-time) | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `warning` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Abstractions.Services.SendEDespatchResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | FurpaMerkezApi.Application.Abstractions.Services.EDespatchDocumentType | Hayir |  |
| `eDespatchDocumentNo` | string | Hayir | nullable |
| `eDespatchUuid` | string | Hayir | nullable |
| `endpointUrl` | string | Hayir | nullable |
| `localMikroMetadataUpdateQueued` | boolean | Hayir |  |
| `localMikroMetadataUpdated` | boolean | Hayir |  |
| `sentAt` | string (date-time) | Hayir |  |
| `serviceDocumentId` | string | Hayir | nullable |
| `serviceDocumentNumber` | string | Hayir | nullable |
| `warning` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Authentication.Contracts.AuthResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accessToken` | string | Hayir | nullable |
| `expiresAtUtc` | string (date-time) | Hayir |  |
| `refreshToken` | string | Hayir | nullable |
| `refreshTokenExpiresAtUtc` | string (date-time) | Hayir |  |
| `user` | FurpaMerkezApi.Application.Identity.Contracts.UserDto | Hayir |  |

### FurpaMerkezApi.Application.Authentication.Contracts.WarehouseContextResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `currentWarehouseName` | string | Hayir | nullable |
| `currentWarehouseNo` | string | Hayir | nullable |
| `isTerminalUser` | boolean | Hayir |  |
| `reason` | string | Hayir | nullable |
| `requiresRelogin` | boolean | Hayir |  |
| `serverTimeUtc` | string (date-time) | Hayir |  |
| `tokenWarehouseName` | string | Hayir | nullable |
| `tokenWarehouseNo` | string | Hayir | nullable |
| `userId` | string (uuid) | Hayir |  |
| `username` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Identity.Contracts.PermissionActionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `name` | string | Hayir | nullable |
| `permissionCode` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Identity.Contracts.PermissionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `actionCode` | string | Hayir | nullable |
| `actionName` | string | Hayir | nullable |
| `code` | string | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `description` | string | Hayir | nullable |
| `id` | string (uuid) | Hayir |  |
| `menuCode` | string | Hayir | nullable |
| `menuName` | string | Hayir | nullable |
| `moduleCode` | string | Hayir | nullable |
| `moduleName` | string | Hayir | nullable |
| `name` | string | Hayir | nullable |
| `updatedAtUtc` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.Application.Identity.Contracts.PermissionMenuDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `actions` | FurpaMerkezApi.Application.Identity.Contracts.PermissionActionDto[] | Hayir | nullable |
| `code` | string | Hayir | nullable |
| `name` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Identity.Contracts.PermissionModuleDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `menus` | FurpaMerkezApi.Application.Identity.Contracts.PermissionMenuDto[] | Hayir | nullable |
| `name` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Identity.Contracts.RoleDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAtUtc` | string (date-time) | Hayir |  |
| `description` | string | Hayir | nullable |
| `id` | string (uuid) | Hayir |  |
| `isActive` | boolean | Hayir |  |
| `name` | string | Hayir | nullable |
| `permissions` | FurpaMerkezApi.Application.Identity.Contracts.PermissionDto[] | Hayir | nullable |
| `updatedAtUtc` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.Application.Identity.Contracts.UserClientRoleDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientType` | string | Hayir | nullable |
| `roleId` | string (uuid) | Hayir |  |
| `roleName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Identity.Contracts.UserDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAtUtc` | string (date-time) | Hayir |  |
| `email` | string | Hayir | nullable |
| `firstName` | string | Hayir | nullable |
| `id` | string (uuid) | Hayir |  |
| `isActive` | boolean | Hayir |  |
| `lastName` | string | Hayir | nullable |
| `modules` | FurpaMerkezApi.Application.Identity.Contracts.PermissionModuleDto[] | Hayir | nullable |
| `permissions` | string[] | Hayir | nullable |
| `roles` | string[] | Hayir | nullable |
| `updatedAtUtc` | string (date-time) | Hayir | nullable |
| `username` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AramaIslemleri.ProductAvailability.ProductAvailabilityItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `currentStockQuantity` | number (double) | Hayir |  |
| `delistReason` | string | Hayir | nullable |
| `embeddedQuantity` | number (double) | Hayir | nullable |
| `embeddedQuantityUnit` | string | Hayir | nullable |
| `goodsAcceptanceBlockCode` | integer (int32) | Hayir | nullable |
| `hasStock` | boolean | Hayir |  |
| `isBarcodeCheckDigitValid` | boolean | Hayir | nullable |
| `isDelisted` | boolean | Hayir |  |
| `isGoodsAcceptanceBlocked` | boolean | Hayir |  |
| `isOrderBlocked` | boolean | Hayir |  |
| `isPassive` | boolean | Hayir |  |
| `isSalesBlocked` | boolean | Hayir |  |
| `isVariableWeightBarcode` | boolean | Hayir |  |
| `lookupBarcode` | string | Hayir | nullable |
| `orderBlockCode` | integer (int32) | Hayir | nullable |
| `price` | number (double) | Hayir |  |
| `priceTypeCode` | integer (int32) | Hayir |  |
| `productManagerCode` | string | Hayir | nullable |
| `requestedBarcode` | string | Hayir | nullable |
| `salesBlockCode` | integer (int32) | Hayir | nullable |
| `secondaryUnitMultiplier` | number (double) | Hayir |  |
| `secondaryUnitName` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitMultiplier` | number (double) | Hayir |  |
| `unitName` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AramaIslemleri.ProductCustomerSuggestions.BarcodeCustomerSuggestionResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `caseBarcode` | string | Hayir | nullable |
| `defaultSupplierCode` | string | Hayir | nullable |
| `defaultSupplierName` | string | Hayir | nullable |
| `isFound` | boolean | Hayir |  |
| `matchedBarcode` | string | Hayir | nullable |
| `primaryBarcode` | string | Hayir | nullable |
| `resolutionSource` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `suggestions` | FurpaMerkezApi.Application.Modules.AramaIslemleri.ProductCustomerSuggestions.ProductCustomerSuggestionDto[] | Hayir | nullable |
| `unitMultiplier` | number (double) | Hayir | nullable |
| `unitsPerCase` | number (double) | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AramaIslemleri.ProductCustomerSuggestions.ProductCustomerSuggestionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | nullable |
| `customerName` | string | Hayir | nullable |
| `isDefaultSupplier` | boolean | Hayir |  |
| `lastDocumentNo` | string | Hayir | nullable |
| `lastMovementDate` | string (date-time) | Hayir | nullable |
| `movementCount` | integer (int32) | Hayir |  |
| `sources` | string[] | Hayir | nullable |
| `taxNoOrTckn` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AramaIslemleri.ProductCustomerSuggestions.ProductCustomerSuggestionResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `defaultSupplierCode` | string | Hayir | nullable |
| `defaultSupplierName` | string | Hayir | nullable |
| `isProductFound` | boolean | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `suggestions` | FurpaMerkezApi.Application.Modules.AramaIslemleri.ProductCustomerSuggestions.ProductCustomerSuggestionDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AramaIslemleri.ProductLatestTag.ProductLatestTagDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `buyer` | string | Hayir | nullable |
| `buyingPrice` | number (double) | Hayir |  |
| `goodsGenus` | string | Hayir | nullable |
| `goodsType` | string | Hayir | nullable |
| `manufacturer` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `productUnit` | string | Hayir | nullable |
| `productionCity` | string | Hayir | nullable |
| `productionDate` | string (date-time) | Hayir |  |
| `productionDistrict` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `salesPrice` | number (double) | Hayir |  |
| `shippingDate` | string (date-time) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `takenTag` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AramaIslemleri.ResolveBarcode.BarcodeResolutionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `barcodeKind` | string | Hayir | nullable |
| `caseBarcode` | string | Hayir | nullable |
| `defaultSupplierCode` | string | Hayir | nullable |
| `defaultSupplierName` | string | Hayir | nullable |
| `embeddedQuantity` | number (double) | Hayir | nullable |
| `embeddedQuantityUnit` | string | Hayir | nullable |
| `errors` | string[] | Hayir | nullable |
| `hasPurchaseRequirement` | boolean | Hayir | nullable |
| `isAllowedForTargetWarehouse` | boolean | Hayir | nullable |
| `isAlternativeBarcode` | boolean | Hayir |  |
| `isBarcodeCheckDigitValid` | boolean | Hayir | nullable |
| `isBlocked` | boolean | Hayir |  |
| `isCaseBarcode` | boolean | Hayir |  |
| `isFound` | boolean | Hayir |  |
| `isGoodsAcceptanceBlocked` | boolean | Hayir |  |
| `isOrderBlocked` | boolean | Hayir |  |
| `isPassive` | boolean | Hayir |  |
| `isPrimaryBarcode` | boolean | Hayir |  |
| `isSalesBlocked` | boolean | Hayir |  |
| `isUsableInOperation` | boolean | Hayir |  |
| `isUsableInScreen` | boolean | Hayir |  |
| `isVariableWeightBarcode` | boolean | Hayir |  |
| `lookupBarcode` | string | Hayir | nullable |
| `matchedBarcode` | string | Hayir | nullable |
| `matchedUnitMultiplier` | number (double) | Hayir | nullable |
| `matchedUnitName` | string | Hayir | nullable |
| `matchedUnitPointer` | integer (int32) | Hayir | nullable |
| `matchedUnitsPerCase` | number (double) | Hayir | nullable |
| `operationDecision` | string | Hayir | nullable |
| `operationType` | string | Hayir | nullable |
| `priceTypeCode` | integer (int32) | Hayir | nullable |
| `primaryBarcode` | string | Hayir | nullable |
| `productModelCode` | string | Hayir | nullable |
| `purchaseGrossPrice` | number (double) | Hayir | nullable |
| `purchasePrice` | number (double) | Hayir | nullable |
| `purchasePriceSource` | string | Hayir | nullable |
| `purchaseRequirementReason` | string | Hayir | nullable |
| `purchaseSupplierCode` | string | Hayir | nullable |
| `resolutionSource` | string | Hayir | nullable |
| `salesPrice` | number (double) | Hayir | nullable |
| `screenCode` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `supplierCode` | string | Hayir | nullable |
| `targetWarehouseModelCodes` | string[] | Hayir | nullable |
| `targetWarehouseNo` | integer (int32) | Hayir | nullable |
| `targetWarehouseReason` | string | Hayir | nullable |
| `unitMultiplier` | number (double) | Hayir | nullable |
| `unitsPerCase` | number (double) | Hayir | nullable |
| `usabilityReason` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |
| `warnings` | string[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AramaIslemleri.SearchCustomers.CustomerLookupItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | nullable |
| `customerDisplayName` | string | Hayir | nullable |
| `customerName` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `email` | string | Hayir | nullable |
| `groupCode` | string | Hayir | nullable |
| `invoiceAddressNo` | integer (int32) | Hayir | nullable |
| `isClosed` | boolean | Hayir |  |
| `isEDespatchCustomer` | boolean | Hayir |  |
| `isEInvoiceCustomer` | boolean | Hayir |  |
| `isLocked` | boolean | Hayir |  |
| `mainCustomerCode` | string | Hayir | nullable |
| `mobilePhone` | string | Hayir | nullable |
| `regionCode` | string | Hayir | nullable |
| `representativeCode` | string | Hayir | nullable |
| `representativeName` | string | Hayir | nullable |
| `sameTaxCustomerCount` | integer (int32) | Hayir |  |
| `sectorCode` | string | Hayir | nullable |
| `selectionLabel` | string | Hayir | nullable |
| `shippingAddressNo` | integer (int32) | Hayir | nullable |
| `taxIdentityNo` | string | Hayir | nullable |
| `taxNumber` | string | Hayir | nullable |
| `taxOfficeName` | string | Hayir | nullable |
| `taxOfficeNo` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AramaIslemleri.SearchProducts.ProductLookupItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `delistReason` | string | Hayir | nullable |
| `embeddedQuantity` | number (double) | Hayir | nullable |
| `embeddedQuantityUnit` | string | Hayir | nullable |
| `goodsAcceptanceBlockCode` | integer (int32) | Hayir | nullable |
| `hasPurchaseRequirement` | boolean | Hayir |  |
| `isBarcodeCheckDigitValid` | boolean | Hayir | nullable |
| `isDelisted` | boolean | Hayir |  |
| `isGoodsAcceptanceBlocked` | boolean | Hayir |  |
| `isOrderBlocked` | boolean | Hayir |  |
| `isPassive` | boolean | Hayir |  |
| `isSalesBlocked` | boolean | Hayir |  |
| `isVariableWeightBarcode` | boolean | Hayir |  |
| `lookupBarcode` | string | Hayir | nullable |
| `modelCode` | string | Hayir | nullable |
| `orderBlockCode` | integer (int32) | Hayir | nullable |
| `price` | number (double) | Hayir |  |
| `priceTypeCode` | integer (int32) | Hayir |  |
| `procurementType` | string | Hayir | nullable |
| `productManagerCode` | string | Hayir | nullable |
| `purchaseGrossPrice` | number (double) | Hayir | nullable |
| `purchasePrice` | number (double) | Hayir | nullable |
| `purchasePriceSource` | string | Hayir | nullable |
| `purchaseSupplierCode` | string | Hayir | nullable |
| `requestedBarcode` | string | Hayir | nullable |
| `salesBlockCode` | integer (int32) | Hayir | nullable |
| `secondaryUnitMultiplier` | number (double) | Hayir |  |
| `secondaryUnitName` | string | Hayir | nullable |
| `sourceWarehouses` | FurpaMerkezApi.Application.Modules.AramaIslemleri.SearchProducts.ProductSourceWarehouseDto[] | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitMultiplier` | number (double) | Hayir |  |
| `unitName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AramaIslemleri.SearchProducts.ProductSourceWarehouseDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AramaIslemleri.SearchWarehouses.SourceWarehouseLookupItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `displayName` | string | Hayir | nullable |
| `modelCodes` | string[] | Hayir | nullable |
| `modelNames` | string[] | Hayir | nullable |
| `sourceWarehouseName` | string | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AramaIslemleri.SearchWarehouses.WarehouseLookupItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `address` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir | nullable |
| `companyNo` | integer (int32) | Hayir | nullable |
| `district` | string | Hayir | nullable |
| `groupCode` | string | Hayir | nullable |
| `isInventoryExcluded` | boolean | Hayir |  |
| `projectCode` | string | Hayir | nullable |
| `province` | string | Hayir | nullable |
| `responsibilityCenterCode` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |
| `warehouseType` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.B2BBulletinDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createDate` | string (date-time) | Hayir |  |
| `definition` | string | Hayir | nullable |
| `id` | integer (int32) | Hayir |  |
| `link` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.B2BUserAccountDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accountId` | string (uuid) | Hayir |  |
| `category` | string | Hayir | nullable |
| `id` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.B2BUserDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accounts` | FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.B2BUserAccountDto[] | Hayir | nullable |
| `createDate` | string (date-time) | Hayir |  |
| `menus` | string | Hayir | nullable |
| `status` | boolean | Hayir |  |
| `userEndDate` | string (date-time) | Hayir |  |
| `userFullName` | string | Hayir | nullable |
| `userId` | string (uuid) | Hayir |  |
| `userMail` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.B2BUserDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accountCount` | integer (int32) | Hayir |  |
| `categories` | string[] | Hayir | nullable |
| `createDate` | string (date-time) | Hayir |  |
| `menus` | string | Hayir | nullable |
| `status` | boolean | Hayir |  |
| `userEndDate` | string (date-time) | Hayir |  |
| `userFullName` | string | Hayir | nullable |
| `userId` | string (uuid) | Hayir |  |
| `userMail` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.BranchDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchIpAddress` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `branchScalesFolderPath` | string | Hayir | nullable |
| `posGenelFolderPath` | string | Hayir | nullable |
| `poskonFolderPath` | string | Hayir | nullable |
| `scalesType` | integer (int32) | Hayir |  |
| `scalesTypeDescription` | string | Hayir | nullable |
| `scalesTypeName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.BranchSettingsLookupsDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashTypes` | FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.SettingsTypeOptionDto[] | Hayir | nullable |
| `scalesTypes` | FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.SettingsTypeOptionDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.CashRegisterMessageStatusDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir |  |
| `cashNo` | integer (int32) | Hayir |  |
| `cashType` | integer (int32) | Hayir |  |
| `cashTypeDescription` | string | Hayir | nullable |
| `cashTypeName` | string | Hayir | nullable |
| `error` | string | Hayir | nullable |
| `filePath` | string | Hayir | nullable |
| `state` | integer (int32) | Hayir | nullable |
| `stateName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.CashRegisterResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir |  |
| `cashNo` | integer (int32) | Hayir |  |
| `cashType` | integer (int32) | Hayir |  |
| `cashTypeDescription` | string | Hayir | nullable |
| `cashTypeName` | string | Hayir | nullable |
| `terminals` | FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.CashRegisterTerminalDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.CashRegisterSettingsLookupsDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashTypes` | FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.SettingsTypeOptionDto[] | Hayir | nullable |
| `terminalBanks` | FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.TerminalBankOptionDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.CashRegisterTerminalDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `bank` | string | Hayir | nullable |
| `cashNo` | integer (int32) | Hayir | nullable |
| `cashRegisterNo` | string | Hayir | nullable |
| `id` | integer (int32) | Hayir |  |
| `merchantNo` | string | Hayir | nullable |
| `terminalId` | string | Hayir | nullable |
| `terminalNo` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.CashRegistryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir |  |
| `cashFinanceNumber` | string | Hayir | nullable |
| `cashNo` | integer (int32) | Hayir |  |
| `cashRegisterNo` | integer (int32) | Hayir |  |
| `cashRegisterType` | integer (int32) | Hayir |  |
| `cashRegisterTypeDescription` | string | Hayir | nullable |
| `cashRegisterTypeName` | string | Hayir | nullable |
| `cashType` | integer (int32) | Hayir |  |
| `cashTypeDescription` | string | Hayir | nullable |
| `cashTypeName` | string | Hayir | nullable |
| `detailId` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.CashierDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashierAuthorization` | string | Hayir | nullable |
| `cashierCode` | integer (int32) | Hayir |  |
| `cashierName` | string | Hayir | nullable |
| `cashierState` | boolean | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.CashierPasswordMutationDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashier` | FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.CashierDto | Hayir |  |
| `cashierCode` | integer (int32) | Hayir |  |
| `generatedPassword` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.DeviceDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir |  |
| `description` | string | Hayir | nullable |
| `deviceTypeId` | integer (int32) | Hayir |  |
| `deviceTypeName` | string | Hayir | nullable |
| `id` | integer (int32) | Hayir |  |
| `ipAddress` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.DeviceStatusDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir |  |
| `description` | string | Hayir | nullable |
| `deviceTypeId` | integer (int32) | Hayir |  |
| `deviceTypeName` | string | Hayir | nullable |
| `error` | string | Hayir | nullable |
| `ipAddress` | string | Hayir | nullable |
| `latencyMs` | integer (int64) | Hayir | nullable |
| `online` | boolean | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.DeviceTypeDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deviceName` | string | Hayir | nullable |
| `id` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.SettingsTypeOptionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `isKnown` | boolean | Hayir |  |
| `name` | string | Hayir | nullable |
| `value` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Ayarlar.TerminalBankOptionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accountCode` | string | Hayir | nullable |
| `displayName` | string | Hayir | nullable |
| `paymentName` | string | Hayir | nullable |
| `paymentTypeNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.Soforler.DespatchDriverDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAtUtc` | string (date-time) | Hayir |  |
| `firstName` | string | Hayir | nullable |
| `fullName` | string | Hayir | nullable |
| `id` | string (uuid) | Hayir |  |
| `isActive` | boolean | Hayir |  |
| `lastName` | string | Hayir | nullable |
| `maskedTckn` | string | Hayir | nullable |
| `notes` | string | Hayir | nullable |
| `plateNumber` | string | Hayir | nullable |
| `tckn` | string | Hayir | nullable |
| `updatedAtUtc` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.TerminalCihazlari.TerminalInstallationDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `androidSdk` | integer (int32) | Hayir | nullable |
| `androidVersion` | string | Hayir | nullable |
| `appVersion` | string | Hayir | nullable |
| `buildNumber` | integer (int32) | Hayir |  |
| `deviceId` | string | Hayir | nullable |
| `deviceModel` | string | Hayir | nullable |
| `firstSeenAtUtc` | string (date-time) | Hayir |  |
| `id` | string (uuid) | Hayir |  |
| `isActiveLast24Hours` | boolean | Hayir |  |
| `isActiveLast7Days` | boolean | Hayir |  |
| `isCurrentVersion` | boolean | Hayir | nullable |
| `lastIpAddress` | string | Hayir | nullable |
| `lastSeenAtUtc` | string (date-time) | Hayir |  |
| `manufacturer` | string | Hayir | nullable |
| `previousWarehouseNo` | integer (int32) | Hayir | nullable |
| `supportedAbis` | string[] | Hayir | nullable |
| `userFullName` | string | Hayir | nullable |
| `userId` | string (uuid) | Hayir |  |
| `username` | string | Hayir | nullable |
| `versionChangedAtUtc` | string (date-time) | Hayir | nullable |
| `warehouseChangeCount` | integer (int32) | Hayir |  |
| `warehouseChangedAtUtc` | string (date-time) | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.TerminalCihazlari.TerminalInstallationSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `activeLast24HoursCount` | integer (int32) | Hayir |  |
| `activeLast30DaysCount` | integer (int32) | Hayir |  |
| `activeLast7DaysCount` | integer (int32) | Hayir |  |
| `currentAppVersion` | string | Hayir | nullable |
| `currentBuildNumber` | integer (int32) | Hayir | nullable |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `isVersionManifestAvailable` | boolean | Hayir |  |
| `outdatedInstallationCount` | integer (int32) | Hayir | nullable |
| `registeredInstallationCount` | integer (int32) | Hayir |  |
| `versionManifestCheckedAtUtc` | string (date-time) | Hayir | nullable |
| `versions` | FurpaMerkezApi.Application.Modules.AyarIslemleri.TerminalCihazlari.TerminalVersionDistributionDto[] | Hayir | nullable |
| `warehouseChangedInstallationCount` | integer (int32) | Hayir |  |
| `warehouses` | FurpaMerkezApi.Application.Modules.AyarIslemleri.TerminalCihazlari.TerminalWarehouseDistributionDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.TerminalCihazlari.TerminalVersionDistributionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `activeLast7DaysCount` | integer (int32) | Hayir |  |
| `appVersion` | string | Hayir | nullable |
| `buildNumber` | integer (int32) | Hayir |  |
| `installationCount` | integer (int32) | Hayir |  |
| `isCurrentVersion` | boolean | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.TerminalCihazlari.TerminalWarehouseDistributionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `activeLast7DaysCount` | integer (int32) | Hayir |  |
| `installationCount` | integer (int32) | Hayir |  |
| `outdatedCount` | integer (int32) | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseActiveRequestDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `blockingSessionId` | integer (int32) | Hayir | nullable |
| `canTerminate` | boolean | Hayir |  |
| `clientAddress` | string | Hayir | nullable |
| `command` | string | Hayir | nullable |
| `cpuMilliseconds` | integer (int64) | Hayir |  |
| `databaseName` | string | Hayir | nullable |
| `elapsedMilliseconds` | integer (int64) | Hayir |  |
| `hostName` | string | Hayir | nullable |
| `hostProcessId` | integer (int32) | Hayir | nullable |
| `logicalReads` | integer (int64) | Hayir |  |
| `loginName` | string | Hayir | nullable |
| `loginTime` | string (date-time) | Hayir |  |
| `openTransactionCount` | integer (int32) | Hayir |  |
| `percentComplete` | number (double) | Hayir |  |
| `programName` | string | Hayir | nullable |
| `reads` | integer (int64) | Hayir |  |
| `recommendation` | string | Hayir | nullable |
| `requestId` | integer (int32) | Hayir |  |
| `sessionId` | integer (int32) | Hayir |  |
| `severity` | string | Hayir | nullable |
| `sqlText` | string | Hayir | nullable |
| `startTime` | string (date-time) | Hayir |  |
| `status` | string | Hayir | nullable |
| `waitMilliseconds` | integer (int64) | Hayir |  |
| `waitResource` | string | Hayir | nullable |
| `waitType` | string | Hayir | nullable |
| `writes` | integer (int64) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseBlockingEdgeDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `blockedSessionId` | integer (int32) | Hayir |  |
| `blockedSqlText` | string | Hayir | nullable |
| `blockingSessionId` | integer (int32) | Hayir |  |
| `depth` | integer (int32) | Hayir |  |
| `rootSessionId` | integer (int32) | Hayir |  |
| `waitMilliseconds` | integer (int64) | Hayir |  |
| `waitType` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseIncidentOverviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `criticalCount` | integer (int32) | Hayir |  |
| `lastSeenAtUtc` | string (date-time) | Hayir | nullable |
| `openCount` | integer (int32) | Hayir |  |
| `warningCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseMonitoringIncidentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `blockingSessionId` | integer (int32) | Hayir | nullable |
| `databaseName` | string | Hayir | nullable |
| `elapsedMilliseconds` | integer (int64) | Hayir |  |
| `firstSeenAtUtc` | string (date-time) | Hayir |  |
| `hostName` | string | Hayir | nullable |
| `id` | string (uuid) | Hayir |  |
| `lastSeenAtUtc` | string (date-time) | Hayir |  |
| `loginName` | string | Hayir | nullable |
| `occurrenceCount` | integer (int32) | Hayir |  |
| `programName` | string | Hayir | nullable |
| `recommendation` | string | Hayir | nullable |
| `resolvedAtUtc` | string (date-time) | Hayir | nullable |
| `sessionId` | integer (int32) | Hayir |  |
| `severity` | string | Hayir | nullable |
| `sqlText` | string | Hayir | nullable |
| `type` | string | Hayir | nullable |
| `waitType` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseMonitoringOverviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `activeRequestCount` | integer (int32) | Hayir |  |
| `blockedRequestCount` | integer (int32) | Hayir |  |
| `longRunningRequestCount` | integer (int32) | Hayir |  |
| `openTransactionCount` | integer (int32) | Hayir |  |
| `status` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseMonitoringSnapshotDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `activeRequestCount` | integer (int32) | Hayir |  |
| `blockedRequestCount` | integer (int32) | Hayir |  |
| `blocking` | FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseBlockingEdgeDto[] | Hayir | nullable |
| `databaseName` | string | Hayir | nullable |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `longRunningRequestCount` | integer (int32) | Hayir |  |
| `openTransactionCount` | integer (int32) | Hayir |  |
| `openTransactions` | FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseOpenTransactionDto[] | Hayir | nullable |
| `overallStatus` | string | Hayir | nullable |
| `recommendations` | FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseRecommendationDto[] | Hayir | nullable |
| `requests` | FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseActiveRequestDto[] | Hayir | nullable |
| `rootBlockerCount` | integer (int32) | Hayir |  |
| `serverName` | string | Hayir | nullable |
| `thresholds` | FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseMonitoringThresholdsDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseMonitoringThresholdsDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `blockingSeconds` | integer (int32) | Hayir |  |
| `longRunningSeconds` | integer (int32) | Hayir |  |
| `maxIncidentCount` | integer (int32) | Hayir |  |
| `openTransactionSeconds` | integer (int32) | Hayir |  |
| `refreshSeconds` | integer (int32) | Hayir |  |
| `retentionHours` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseOpenTransactionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `ageMilliseconds` | integer (int64) | Hayir |  |
| `canTerminate` | boolean | Hayir |  |
| `clientAddress` | string | Hayir | nullable |
| `hostName` | string | Hayir | nullable |
| `hostProcessId` | integer (int32) | Hayir | nullable |
| `lastSqlText` | string | Hayir | nullable |
| `loginName` | string | Hayir | nullable |
| `loginTime` | string (date-time) | Hayir |  |
| `openTransactionCount` | integer (int32) | Hayir |  |
| `programName` | string | Hayir | nullable |
| `recommendation` | string | Hayir | nullable |
| `sessionId` | integer (int32) | Hayir |  |
| `severity` | string | Hayir | nullable |
| `transactionBeginTime` | string (date-time) | Hayir |  |
| `transactionId` | integer (int64) | Hayir |  |
| `transactionState` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseRecommendationDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `affectedSessionCount` | integer (int32) | Hayir |  |
| `code` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `severity` | string | Hayir | nullable |
| `title` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseRollbackStatusDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `checkedAtUtc` | string (date-time) | Hayir |  |
| `isRollingBack` | boolean | Hayir |  |
| `message` | string | Hayir | nullable |
| `sessionId` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseSessionTerminationDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `completedAtUtc` | string (date-time) | Hayir | nullable |
| `databaseName` | string | Hayir | nullable |
| `error` | string | Hayir | nullable |
| `hostName` | string | Hayir | nullable |
| `hostProcessId` | integer (int32) | Hayir | nullable |
| `id` | string (uuid) | Hayir |  |
| `isSucceeded` | boolean | Hayir |  |
| `loginName` | string | Hayir | nullable |
| `loginTime` | string (date-time) | Hayir |  |
| `programName` | string | Hayir | nullable |
| `reason` | string | Hayir | nullable |
| `requestedAtUtc` | string (date-time) | Hayir |  |
| `requestedByUserId` | string (uuid) | Hayir |  |
| `sessionId` | integer (int32) | Hayir |  |
| `sqlText` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.MonitoringOverviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `database` | FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseMonitoringOverviewDto | Hayir |  |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `headline` | string | Hayir | nullable |
| `incidents` | FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.DatabaseIncidentOverviewDto | Hayir |  |
| `overallStatus` | string | Hayir | nullable |
| `overallStatusName` | string | Hayir | nullable |
| `safeWrites` | FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.SafeWriteMonitoringOverviewDto | Hayir |  |
| `workers` | FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.WorkerMonitoringSnapshotDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.SafeWriteMonitoringItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `ageSeconds` | integer (int64) | Hayir |  |
| `clientRequestId` | string (uuid) | Hayir |  |
| `completedAtUtc` | string (date-time) | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `errorCode` | string | Hayir | nullable |
| `errorMessage` | string | Hayir | nullable |
| `id` | string (uuid) | Hayir |  |
| `operationCode` | string | Hayir | nullable |
| `requestedByUserId` | string (uuid) | Hayir |  |
| `retryable` | boolean | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `updatedAtUtc` | string (date-time) | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.SafeWriteMonitoringOverviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `completedCount` | integer (int32) | Hayir |  |
| `manualReviewCount` | integer (int32) | Hayir |  |
| `processingCount` | integer (int32) | Hayir |  |
| `retryableFailureCount` | integer (int32) | Hayir |  |
| `staleProcessingCount` | integer (int32) | Hayir |  |
| `unclassifiedFailureCount` | integer (int32) | Hayir |  |
| `windowHours` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.WorkerMonitoringItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `activity` | string | Hayir | nullable |
| `code` | string | Hayir | nullable |
| `hasUnresolvedFailure` | boolean | Hayir |  |
| `heartbeatAgeSeconds` | integer (int64) | Hayir | nullable |
| `isCritical` | boolean | Hayir |  |
| `isEnabled` | boolean | Hayir |  |
| `lastError` | string | Hayir | nullable |
| `lastFailureAtUtc` | string (date-time) | Hayir | nullable |
| `lastHeartbeatAtUtc` | string (date-time) | Hayir | nullable |
| `lastSuccessAtUtc` | string (date-time) | Hayir | nullable |
| `name` | string | Hayir | nullable |
| `oldestQueuedAgeSeconds` | integer (int64) | Hayir | nullable |
| `oldestQueuedAtUtc` | string (date-time) | Hayir | nullable |
| `queuedCount` | integer (int32) | Hayir |  |
| `recommendation` | string | Hayir | nullable |
| `registeredAtUtc` | string (date-time) | Hayir |  |
| `requiresAttention` | boolean | Hayir |  |
| `runningCount` | integer (int32) | Hayir |  |
| `staleAfterSeconds` | integer (int32) | Hayir |  |
| `status` | string | Hayir | nullable |
| `statusName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.WorkerMonitoringSnapshotDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `overallStatus` | string | Hayir | nullable |
| `workers` | FurpaMerkezApi.Application.Modules.AyarIslemleri.VeritabaniIzleme.WorkerMonitoringItemDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.Common.CompanyMovements.CompanyMovementDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.Common.CompanyMovements.CompanyMovementHeaderDto | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.Common.CompanyMovements.CompanyMovementLineItemDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.Common.CompanyMovements.CompanyMovementHeaderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerAddress` | string | Hayir | nullable |
| `customerCode` | string | Hayir | nullable |
| `customerDisplayName` | string | Hayir | nullable |
| `customerName` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `deliverer` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | integer (int32) | Hayir |  |
| `inputWarehouseName` | string | Hayir | nullable |
| `inputWarehouseNo` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `movementCreateDate` | string (date-time) | Hayir |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `movementType` | integer (int32) | Hayir |  |
| `outputWarehouseName` | string | Hayir | nullable |
| `outputWarehouseNo` | integer (int32) | Hayir |  |
| `receiver` | string | Hayir | nullable |
| `returnType` | integer (int32) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.Common.CompanyMovements.CompanyMovementLineItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | nullable |
| `discountAmount` | number (double) | Hayir |  |
| `expenseAmount` | number (double) | Hayir |  |
| `grossWeight` | number (double) | Hayir |  |
| `lineAmount` | number (double) | Hayir |  |
| `lineNo` | integer (int32) | Hayir |  |
| `lotNo` | integer (int32) | Hayir |  |
| `netWeight` | number (double) | Hayir |  |
| `orderGuid` | string (uuid) | Hayir | nullable |
| `partyCode` | string | Hayir | nullable |
| `projectCode` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `secondaryQuantity` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `taxAmount` | number (double) | Hayir |  |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |
| `unitPrice` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.Common.CompanyMovements.CompanyMovementListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | nullable |
| `customerDisplayName` | string | Hayir | nullable |
| `customerName` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | integer (int32) | Hayir |  |
| `inputWarehouseName` | string | Hayir | nullable |
| `inputWarehouseNo` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `movementCreateDate` | string (date-time) | Hayir |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `movementType` | integer (int32) | Hayir |  |
| `outputWarehouseName` | string | Hayir | nullable |
| `outputWarehouseNo` | integer (int32) | Hayir |  |
| `returnType` | integer (int32) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.Common.CompanyMovements.CreateCompanyMovementResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `movementDate` | string (date-time) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |
| `writeConnectionName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.Common.OfflineSync.OfflineSyncStatusDto.Of.FurpaMerkezApi.Application.Modules.Common.CompanyMovements.CreateCompanyMovementResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientRequestId` | string (uuid) | Hayir |  |
| `completedAtUtc` | string (date-time) | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `errorCode` | string | Hayir | nullable |
| `errorMessage` | string | Hayir | nullable |
| `operationCode` | string | Hayir | nullable |
| `result` | FurpaMerkezApi.Application.Modules.Common.CompanyMovements.CreateCompanyMovementResponse | Hayir |  |
| `retryAfterSeconds` | integer (int32) | Hayir | nullable |
| `retryable` | boolean | Hayir | nullable |
| `status` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.Common.OfflineSync.OfflineSyncStatusDto.Of.FurpaMerkezApi.Application.Modules.GreenGrocer.Operations.GreenGrocerOperationsAdjustmentApplyResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientRequestId` | string (uuid) | Hayir |  |
| `completedAtUtc` | string (date-time) | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `errorCode` | string | Hayir | nullable |
| `errorMessage` | string | Hayir | nullable |
| `operationCode` | string | Hayir | nullable |
| `result` | FurpaMerkezApi.Application.Modules.GreenGrocer.Operations.GreenGrocerOperationsAdjustmentApplyResponse | Hayir |  |
| `retryAfterSeconds` | integer (int32) | Hayir | nullable |
| `retryable` | boolean | Hayir | nullable |
| `status` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.Common.OfflineSync.OfflineSyncStatusDto.Of.FurpaMerkezApi.Application.Modules.IadeIslemleri.DepoIadeleri.Create.CreateWarehouseReturnResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientRequestId` | string (uuid) | Hayir |  |
| `completedAtUtc` | string (date-time) | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `errorCode` | string | Hayir | nullable |
| `errorMessage` | string | Hayir | nullable |
| `operationCode` | string | Hayir | nullable |
| `result` | FurpaMerkezApi.Application.Modules.IadeIslemleri.DepoIadeleri.Create.CreateWarehouseReturnResponse | Hayir |  |
| `retryAfterSeconds` | integer (int32) | Hayir | nullable |
| `retryable` | boolean | Hayir | nullable |
| `status` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.Common.OfflineSync.OfflineSyncStatusDto.Of.FurpaMerkezApi.Application.Modules.MalKabulIslemleri.MalKabuller.CompanyReceiving.CreateCompanyReceivingResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientRequestId` | string (uuid) | Hayir |  |
| `completedAtUtc` | string (date-time) | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `errorCode` | string | Hayir | nullable |
| `errorMessage` | string | Hayir | nullable |
| `operationCode` | string | Hayir | nullable |
| `result` | FurpaMerkezApi.Application.Modules.MalKabulIslemleri.MalKabuller.CompanyReceiving.CreateCompanyReceivingResponse | Hayir |  |
| `retryAfterSeconds` | integer (int32) | Hayir | nullable |
| `retryable` | boolean | Hayir | nullable |
| `status` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.Common.OfflineSync.OfflineSyncStatusDto.Of.FurpaMerkezApi.Application.Modules.SevkIslemleri.DepolarArasiSevkler.Create.CreateInterWarehouseShipmentResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientRequestId` | string (uuid) | Hayir |  |
| `completedAtUtc` | string (date-time) | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `errorCode` | string | Hayir | nullable |
| `errorMessage` | string | Hayir | nullable |
| `operationCode` | string | Hayir | nullable |
| `result` | FurpaMerkezApi.Application.Modules.SevkIslemleri.DepolarArasiSevkler.Create.CreateInterWarehouseShipmentResponse | Hayir |  |
| `retryAfterSeconds` | integer (int32) | Hayir | nullable |
| `retryable` | boolean | Hayir | nullable |
| `status` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.Common.OfflineSync.OfflineSyncStatusDto.Of.FurpaMerkezApi.Application.Modules.StokIslemleri.Common.CreateStockReceiptResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientRequestId` | string (uuid) | Hayir |  |
| `completedAtUtc` | string (date-time) | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `errorCode` | string | Hayir | nullable |
| `errorMessage` | string | Hayir | nullable |
| `operationCode` | string | Hayir | nullable |
| `result` | FurpaMerkezApi.Application.Modules.StokIslemleri.Common.CreateStockReceiptResponse | Hayir |  |
| `retryAfterSeconds` | integer (int32) | Hayir | nullable |
| `retryable` | boolean | Hayir | nullable |
| `status` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.Common.OfflineSync.OfflineSyncStatusDto.Of.FurpaMerkezApi.Application.Modules.StokIslemleri.SayimSonuclari.CreateInventoryCountResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientRequestId` | string (uuid) | Hayir |  |
| `completedAtUtc` | string (date-time) | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `errorCode` | string | Hayir | nullable |
| `errorMessage` | string | Hayir | nullable |
| `operationCode` | string | Hayir | nullable |
| `result` | FurpaMerkezApi.Application.Modules.StokIslemleri.SayimSonuclari.CreateInventoryCountResponse | Hayir |  |
| `retryAfterSeconds` | integer (int32) | Hayir | nullable |
| `retryable` | boolean | Hayir | nullable |
| `status` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.Common.OfflineSync.OfflineSyncStatusDto.Of.FurpaMerkezApi.Application.Modules.StokIslemleri.Virmanlar.CreateVirmanResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientRequestId` | string (uuid) | Hayir |  |
| `completedAtUtc` | string (date-time) | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `errorCode` | string | Hayir | nullable |
| `errorMessage` | string | Hayir | nullable |
| `operationCode` | string | Hayir | nullable |
| `result` | FurpaMerkezApi.Application.Modules.StokIslemleri.Virmanlar.CreateVirmanResponse | Hayir |  |
| `retryAfterSeconds` | integer (int32) | Hayir | nullable |
| `retryable` | boolean | Hayir | nullable |
| `status` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.BanknoteTrackUpdateResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `banknoteTrack` | FurpaMerkezApi.Application.Modules.KasaIslemleri.BanknotTakipleri.BanknoteTrackDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentUpdateSummary | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CompanyOrderDocumentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CompanyOrderDocumentHeaderDto | Hayir |  |
| `lines` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CompanyOrderDocumentLineDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CompanyOrderDocumentHeaderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `addressNo` | integer (int32) | Hayir |  |
| `alternativeCurrencyRate` | number (double) | Hayir |  |
| `canBeCalled` | boolean | Hayir |  |
| `closeReasonCode` | string | Hayir | nullable |
| `createdAt` | string (date-time) | Hayir |  |
| `currencyRate` | number (double) | Hayir |  |
| `currencyType` | integer (int32) | Hayir |  |
| `customerCode` | string | Hayir | nullable |
| `customerResponsibilityCenter` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `deliveryType` | string | Hayir | nullable |
| `description1` | string | Hayir | nullable |
| `description2` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `isClosed` | boolean | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `orderDate` | string (date-time) | Hayir | nullable |
| `orderKind` | integer (int32) | Hayir |  |
| `orderType` | integer (int32) | Hayir |  |
| `projectCode` | string | Hayir | nullable |
| `sellerCode` | string | Hayir | nullable |
| `stockResponsibilityCenter` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `totalDeliveredQuantity` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `totalRemainingQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CompanyOrderDocumentLineDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `canBeCalled` | boolean | Hayir |  |
| `closeReasonCode` | string | Hayir | nullable |
| `customerResponsibilityCenter` | string | Hayir | nullable |
| `deliveredFromReservation` | number (double) | Hayir |  |
| `deliveredQuantity` | number (double) | Hayir |  |
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `description1` | string | Hayir | nullable |
| `description2` | string | Hayir | nullable |
| `discount1` | number (double) | Hayir |  |
| `discount2` | number (double) | Hayir |  |
| `discount3` | number (double) | Hayir |  |
| `discount4` | number (double) | Hayir |  |
| `discount5` | number (double) | Hayir |  |
| `discount6` | number (double) | Hayir |  |
| `expense1` | number (double) | Hayir |  |
| `expense2` | number (double) | Hayir |  |
| `expense3` | number (double) | Hayir |  |
| `expense4` | number (double) | Hayir |  |
| `isClosed` | boolean | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `lotNo` | integer (int32) | Hayir |  |
| `orderGuid` | string (uuid) | Hayir |  |
| `packageCode` | string | Hayir | nullable |
| `partyCode` | string | Hayir | nullable |
| `priceListNo` | integer (int32) | Hayir |  |
| `projectCode` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `remainingQuantity` | number (double) | Hayir |  |
| `reservedQuantity` | number (double) | Hayir |  |
| `rowNo` | integer (int32) | Hayir |  |
| `special1` | string | Hayir | nullable |
| `special2` | string | Hayir | nullable |
| `special3` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `stockResponsibilityCenter` | string | Hayir | nullable |
| `taxAmount` | number (double) | Hayir |  |
| `taxPointer` | integer (int32) | Hayir |  |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |
| `unitPrice` | number (double) | Hayir |  |
| `validUntil` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CompanyOrderDocumentUpdateResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `document` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CompanyOrderDocumentDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentUpdateSummary | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerAddressDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `addressCode` | string | Hayir | nullable |
| `addressGuid` | string (uuid) | Hayir |  |
| `addressNo` | integer (int32) | Hayir |  |
| `apartmentNo` | string | Hayir | nullable |
| `apartmentUnitNo` | string | Hayir | nullable |
| `avenue` | string | Hayir | nullable |
| `city` | string | Hayir | nullable |
| `country` | string | Hayir | nullable |
| `createdAt` | string (date-time) | Hayir |  |
| `customerCode` | string | Hayir | nullable |
| `district` | string | Hayir | nullable |
| `eDespatchAlias` | string | Hayir | nullable |
| `eInvoiceAlias` | string | Hayir | nullable |
| `faxNo` | string | Hayir | nullable |
| `isHidden` | boolean | Hayir |  |
| `isLocked` | boolean | Hayir |  |
| `isPassive` | boolean | Hayir |  |
| `isPrintEnabled` | boolean | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `latitude` | number (double) | Hayir |  |
| `longitude` | number (double) | Hayir |  |
| `neighborhood` | string | Hayir | nullable |
| `note` | string | Hayir | nullable |
| `phoneAreaCode` | string | Hayir | nullable |
| `phoneCountryCode` | string | Hayir | nullable |
| `phoneNo1` | string | Hayir | nullable |
| `phoneNo2` | string | Hayir | nullable |
| `postalCode` | string | Hayir | nullable |
| `quarter` | string | Hayir | nullable |
| `representativeCode` | string | Hayir | nullable |
| `street` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerAddressUpdateResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `address` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerAddressDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentUpdateSummary | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerCardDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accountingCode` | string | Hayir | nullable |
| `accountingCode1` | string | Hayir | nullable |
| `accountingCode2` | string | Hayir | nullable |
| `connectionType` | integer (int32) | Hayir |  |
| `createdAt` | string (date-time) | Hayir |  |
| `currencyType` | integer (int32) | Hayir |  |
| `currencyType1` | integer (int32) | Hayir |  |
| `currencyType2` | integer (int32) | Hayir |  |
| `customerCode` | string | Hayir | nullable |
| `customerGuid` | string (uuid) | Hayir |  |
| `defaultEDespatchType` | integer (int32) | Hayir |  |
| `defaultEInvoiceType` | integer (int32) | Hayir |  |
| `defaultInputWarehouseNo` | integer (int32) | Hayir |  |
| `defaultOutputWarehouseNo` | integer (int32) | Hayir |  |
| `eDespatchEnabled` | boolean | Hayir |  |
| `eInvoiceEnabled` | boolean | Hayir |  |
| `email` | string | Hayir | nullable |
| `groupCode` | string | Hayir | nullable |
| `invoiceAddressNo` | integer (int32) | Hayir |  |
| `isClosed` | boolean | Hayir |  |
| `isLocked` | boolean | Hayir |  |
| `kepAddress` | string | Hayir | nullable |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `mersisNo` | string | Hayir | nullable |
| `mobilePhone` | string | Hayir | nullable |
| `movementType` | integer (int32) | Hayir |  |
| `optionDay` | integer (int32) | Hayir |  |
| `parentCustomerCode` | string | Hayir | nullable |
| `paymentDay` | integer (int32) | Hayir |  |
| `paymentPlanNo` | integer (int32) | Hayir |  |
| `paymentType` | integer (int32) | Hayir |  |
| `purchaseStockType` | integer (int32) | Hayir |  |
| `reconciliationEmail` | string | Hayir | nullable |
| `regionCode` | string | Hayir | nullable |
| `registryNo` | string | Hayir | nullable |
| `representativeCode` | string | Hayir | nullable |
| `retailCustomer` | boolean | Hayir |  |
| `salesPriceListNo` | integer (int32) | Hayir |  |
| `salesStockType` | integer (int32) | Hayir |  |
| `sectorCode` | string | Hayir | nullable |
| `shippingAddressNo` | integer (int32) | Hayir |  |
| `special1` | string | Hayir | nullable |
| `special2` | string | Hayir | nullable |
| `special3` | string | Hayir | nullable |
| `taxNo` | string | Hayir | nullable |
| `taxOffice` | string | Hayir | nullable |
| `taxOfficeCode` | string | Hayir | nullable |
| `taxOfficeNo` | string | Hayir | nullable |
| `title1` | string | Hayir | nullable |
| `title2` | string | Hayir | nullable |
| `website` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerCardListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | nullable |
| `groupCode` | string | Hayir | nullable |
| `isClosed` | boolean | Hayir |  |
| `isLocked` | boolean | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `regionCode` | string | Hayir | nullable |
| `representativeCode` | string | Hayir | nullable |
| `taxNo` | string | Hayir | nullable |
| `taxOffice` | string | Hayir | nullable |
| `title1` | string | Hayir | nullable |
| `title2` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerCardUpdateResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCard` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerCardDetailDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentUpdateSummary | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerMovementDocumentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerMovementDocumentHeaderDto | Hayir |  |
| `lines` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerMovementDocumentLineDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerMovementDocumentHeaderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAt` | string (date-time) | Hayir |  |
| `customerCode` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | integer (int32) | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `movementKind` | integer (int32) | Hayir |  |
| `movementTypes` | integer (int32)[] | Hayir | nullable |
| `normalReturn` | integer (int32) | Hayir |  |
| `projectCode` | string | Hayir | nullable |
| `responsibilityCenter` | string | Hayir | nullable |
| `sellerCode` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `totalSubAmount` | number (double) | Hayir |  |
| `turnoverCustomerCode` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerMovementDocumentLineDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `customerCode` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `discount1` | number (double) | Hayir |  |
| `discount2` | number (double) | Hayir |  |
| `discount3` | number (double) | Hayir |  |
| `discount4` | number (double) | Hayir |  |
| `discount5` | number (double) | Hayir |  |
| `discount6` | number (double) | Hayir |  |
| `dueDay` | integer (int32) | Hayir |  |
| `expense1` | number (double) | Hayir |  |
| `expense2` | number (double) | Hayir |  |
| `expense3` | number (double) | Hayir |  |
| `expense4` | number (double) | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `movementGuid` | string (uuid) | Hayir |  |
| `movementKind` | integer (int32) | Hayir |  |
| `movementType` | integer (int32) | Hayir |  |
| `normalReturn` | integer (int32) | Hayir |  |
| `projectCode` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `responsibilityCenter` | string | Hayir | nullable |
| `rowNo` | integer (int32) | Hayir |  |
| `sellerCode` | string | Hayir | nullable |
| `special1` | string | Hayir | nullable |
| `special2` | string | Hayir | nullable |
| `special3` | string | Hayir | nullable |
| `subAmount` | number (double) | Hayir |  |
| `tax1` | number (double) | Hayir |  |
| `tax2` | number (double) | Hayir |  |
| `tax3` | number (double) | Hayir |  |
| `tax4` | number (double) | Hayir |  |
| `tax5` | number (double) | Hayir |  |
| `turnoverCustomerCode` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerMovementDocumentUpdateResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `document` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerMovementDocumentDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentUpdateSummary | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.InventoryCountDocumentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.InventoryCountDocumentHeaderDto | Hayir |  |
| `lines` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.InventoryCountDocumentLineDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.InventoryCountDocumentHeaderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAt` | string (date-time) | Hayir |  |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | integer (int32) | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `name` | string | Hayir | nullable |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.InventoryCountDocumentLineDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `corridorCode` | string | Hayir | nullable |
| `countGuid` | string (uuid) | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `lotNo` | integer (int32) | Hayir |  |
| `partyCode` | string | Hayir | nullable |
| `quantity1` | number (double) | Hayir |  |
| `quantity2` | number (double) | Hayir |  |
| `quantity3` | number (double) | Hayir |  |
| `quantity4` | number (double) | Hayir |  |
| `quantity5` | number (double) | Hayir |  |
| `rayonCode` | string | Hayir | nullable |
| `rowNo` | integer (int32) | Hayir |  |
| `serialNo` | string | Hayir | nullable |
| `shelfCode` | string | Hayir | nullable |
| `special1` | string | Hayir | nullable |
| `special2` | string | Hayir | nullable |
| `special3` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.InventoryCountDocumentUpdateResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `document` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.InventoryCountDocumentDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentUpdateSummary | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentDeleteResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deleteUser` | integer (int32) | Hayir |  |
| `deletedAt` | string (date-time) | Hayir |  |
| `deletedRowCount` | integer (int32) | Hayir |  |
| `deletionMode` | string | Hayir | nullable |
| `target` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentFieldCatalogDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `sections` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentFieldSectionDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentFieldMappingDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `apiField` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `displayName` | string | Hayir | nullable |
| `editable` | boolean | Hayir |  |
| `mikroColumn` | string | Hayir | nullable |
| `mikroTable` | string | Hayir | nullable |
| `scope` | string | Hayir | nullable |
| `valueType` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentFieldSectionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `endpoint` | string | Hayir | nullable |
| `fields` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentFieldMappingDto[] | Hayir | nullable |
| `requestModel` | string | Hayir | nullable |
| `title` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentUpdateSummary

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `target` | string | Hayir | nullable |
| `updateUser` | integer (int32) | Hayir |  |
| `updatedAt` | string (date-time) | Hayir |  |
| `updatedRowCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockCardDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `brandCode` | string | Hayir | nullable |
| `categoryCode` | string | Hayir | nullable |
| `createdAt` | string (date-time) | Hayir |  |
| `currencyType` | integer (int32) | Hayir |  |
| `discountDisabled` | boolean | Hayir |  |
| `foreignName` | string | Hayir | nullable |
| `isPassive` | boolean | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `mainGroupCode` | string | Hayir | nullable |
| `manufacturerCode` | string | Hayir | nullable |
| `name` | string | Hayir | nullable |
| `orderStopped` | boolean | Hayir |  |
| `rayonCode` | string | Hayir | nullable |
| `receivingStopped` | boolean | Hayir |  |
| `responsibilityCode` | string | Hayir | nullable |
| `retailTaxPointer` | integer (int32) | Hayir |  |
| `salesStopped` | boolean | Hayir |  |
| `sectorCode` | string | Hayir | nullable |
| `shelfCode` | string | Hayir | nullable |
| `shortName` | string | Hayir | nullable |
| `special1` | string | Hayir | nullable |
| `special2` | string | Hayir | nullable |
| `special3` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockType` | integer (int32) | Hayir |  |
| `subGroupCode` | string | Hayir | nullable |
| `supplierCode` | string | Hayir | nullable |
| `trackingType` | integer (int32) | Hayir |  |
| `unit1Name` | string | Hayir | nullable |
| `unit2Name` | string | Hayir | nullable |
| `unit3Name` | string | Hayir | nullable |
| `unit4Name` | string | Hayir | nullable |
| `wholesaleTaxPointer` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockCardListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `categoryCode` | string | Hayir | nullable |
| `isPassive` | boolean | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `mainGroupCode` | string | Hayir | nullable |
| `name` | string | Hayir | nullable |
| `shortName` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `subGroupCode` | string | Hayir | nullable |
| `supplierCode` | string | Hayir | nullable |
| `unit1Name` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockCardUpdateResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `stockCard` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockCardDetailDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentUpdateSummary | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockCardWarehouseSettingsDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `discountDisabled` | boolean | Hayir |  |
| `globalDiscountDisabled` | boolean | Hayir |  |
| `globalIsPassive` | boolean | Hayir |  |
| `globalOrderStopped` | boolean | Hayir |  |
| `globalReceivingStopped` | boolean | Hayir |  |
| `globalSalesStopped` | boolean | Hayir |  |
| `hasAnyOverride` | boolean | Hayir |  |
| `hasWarehouseDetail` | boolean | Hayir |  |
| `isPassive` | boolean | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `orderStopped` | boolean | Hayir |  |
| `receivingStopped` | boolean | Hayir |  |
| `salesStopped` | boolean | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockCardWarehouseUpdateResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `summary` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentUpdateSummary | Hayir |  |
| `warehouseSettings` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockCardWarehouseSettingsDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockMovementDocumentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockMovementDocumentHeaderDto | Hayir |  |
| `lines` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockMovementDocumentLineDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockMovementDocumentHeaderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAt` | string (date-time) | Hayir |  |
| `customerCode` | string | Hayir | nullable |
| `customerResponsibilityCenter` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | integer (int32) | Hayir |  |
| `goodsAcceptanceDate` | string (date-time) | Hayir | nullable |
| `inputWarehouseName` | string | Hayir | nullable |
| `inputWarehouseNo` | integer (int32) | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `movementGroupCode1` | string | Hayir | nullable |
| `movementGroupCode2` | string | Hayir | nullable |
| `movementGroupCode3` | string | Hayir | nullable |
| `movementKind` | integer (int32) | Hayir |  |
| `movementTypes` | integer (int32)[] | Hayir | nullable |
| `normalReturn` | integer (int32) | Hayir |  |
| `outputWarehouseName` | string | Hayir | nullable |
| `outputWarehouseNo` | integer (int32) | Hayir |  |
| `projectCode` | string | Hayir | nullable |
| `shippingWarehouseName` | string | Hayir | nullable |
| `shippingWarehouseNo` | integer (int32) | Hayir |  |
| `stockResponsibilityCenter` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockMovementDocumentLineDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `customerResponsibilityCenter` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `discount1` | number (double) | Hayir |  |
| `discount2` | number (double) | Hayir |  |
| `discount3` | number (double) | Hayir |  |
| `discount4` | number (double) | Hayir |  |
| `discount5` | number (double) | Hayir |  |
| `discount6` | number (double) | Hayir |  |
| `expense1` | number (double) | Hayir |  |
| `expense2` | number (double) | Hayir |  |
| `expense3` | number (double) | Hayir |  |
| `expense4` | number (double) | Hayir |  |
| `expenseTaxAmount` | number (double) | Hayir |  |
| `expenseTaxPointer` | integer (int32) | Hayir |  |
| `goodsAcceptanceDate` | string (date-time) | Hayir | nullable |
| `grossWeight` | number (double) | Hayir |  |
| `inputWarehouseNo` | integer (int32) | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `lotNo` | integer (int32) | Hayir |  |
| `movementGuid` | string (uuid) | Hayir |  |
| `netWeight` | number (double) | Hayir |  |
| `outputWarehouseNo` | integer (int32) | Hayir |  |
| `partyCode` | string | Hayir | nullable |
| `projectCode` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `rowNo` | integer (int32) | Hayir |  |
| `secondaryQuantity` | number (double) | Hayir |  |
| `special1` | string | Hayir | nullable |
| `special2` | string | Hayir | nullable |
| `special3` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `stockResponsibilityCenter` | string | Hayir | nullable |
| `taxAmount` | number (double) | Hayir |  |
| `taxPointer` | integer (int32) | Hayir |  |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |
| `unitPrice` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockMovementDocumentUpdateResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `document` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockMovementDocumentDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentUpdateSummary | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockSalesPriceDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `changeReason` | integer (int32) | Hayir |  |
| `createdAt` | string (date-time) | Hayir |  |
| `currencyType` | integer (int32) | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `paymentPlanNo` | integer (int32) | Hayir |  |
| `price` | number (double) | Hayir |  |
| `priceGuid` | string (uuid) | Hayir |  |
| `priceListName` | string | Hayir | nullable |
| `priceListNo` | integer (int32) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockSalesPriceUpsertResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `created` | boolean | Hayir |  |
| `previousPrice` | number (double) | Hayir | nullable |
| `salesPrice` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockSalesPriceDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentUpdateSummary | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseCardDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accountingCode` | string | Hayir | nullable |
| `addressCode` | string | Hayir | nullable |
| `apartmentNo` | string | Hayir | nullable |
| `apartmentUnitNo` | string | Hayir | nullable |
| `authorizedEmail` | string | Hayir | nullable |
| `avenue` | string | Hayir | nullable |
| `city` | string | Hayir | nullable |
| `country` | string | Hayir | nullable |
| `createdAt` | string (date-time) | Hayir |  |
| `detailTrackingType` | integer (int32) | Hayir |  |
| `district` | string | Hayir | nullable |
| `excludedFromInventory` | boolean | Hayir |  |
| `faxNo` | string | Hayir | nullable |
| `groupCode` | string | Hayir | nullable |
| `incomingEDespatchEnabled` | boolean | Hayir |  |
| `isHidden` | boolean | Hayir |  |
| `isLocked` | boolean | Hayir |  |
| `isPassive` | boolean | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `latitude` | number (double) | Hayir |  |
| `lockDate` | string (date-time) | Hayir | nullable |
| `longitude` | number (double) | Hayir |  |
| `movementType` | integer (int32) | Hayir |  |
| `name` | string | Hayir | nullable |
| `neighborhood` | string | Hayir | nullable |
| `outgoingEDespatchEnabled` | boolean | Hayir |  |
| `phoneAreaCode` | string | Hayir | nullable |
| `phoneCountryCode` | string | Hayir | nullable |
| `phoneNo1` | string | Hayir | nullable |
| `phoneNo2` | string | Hayir | nullable |
| `postalCode` | string | Hayir | nullable |
| `projectCode` | string | Hayir | nullable |
| `quarter` | string | Hayir | nullable |
| `regionCode` | string | Hayir | nullable |
| `responsibilityCenter` | string | Hayir | nullable |
| `shipmentAppliedPriceNo` | integer (int32) | Hayir |  |
| `shipmentAutoPriceType` | integer (int32) | Hayir |  |
| `special1` | string | Hayir | nullable |
| `special2` | string | Hayir | nullable |
| `special3` | string | Hayir | nullable |
| `street` | string | Hayir | nullable |
| `warehouseGuid` | string (uuid) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |
| `warehouseType` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseCardListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `city` | string | Hayir | nullable |
| `district` | string | Hayir | nullable |
| `groupCode` | string | Hayir | nullable |
| `isHidden` | boolean | Hayir |  |
| `isPassive` | boolean | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `name` | string | Hayir | nullable |
| `regionCode` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |
| `warehouseType` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseCardUpdateResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `summary` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentUpdateSummary | Hayir |  |
| `warehouseCard` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseCardDetailDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseOrderDocumentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseOrderDocumentHeaderDto | Hayir |  |
| `lines` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseOrderDocumentLineDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseOrderDocumentHeaderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `closeReasonCode` | string | Hayir | nullable |
| `createdAt` | string (date-time) | Hayir |  |
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `inWarehouseName` | string | Hayir | nullable |
| `inWarehouseNo` | integer (int32) | Hayir |  |
| `isClosed` | boolean | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `orderDate` | string (date-time) | Hayir | nullable |
| `outWarehouseName` | string | Hayir | nullable |
| `outWarehouseNo` | integer (int32) | Hayir |  |
| `projectCode` | string | Hayir | nullable |
| `responsibilityCenter` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `totalDeliveredQuantity` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `totalRemainingQuantity` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseOrderDocumentLineDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `closeReasonCode` | string | Hayir | nullable |
| `deliveredFromReservation` | number (double) | Hayir |  |
| `deliveredQuantity` | number (double) | Hayir |  |
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `inWarehouseName` | string | Hayir | nullable |
| `inWarehouseNo` | integer (int32) | Hayir |  |
| `isClosed` | boolean | Hayir |  |
| `lastUpdatedAt` | string (date-time) | Hayir | nullable |
| `orderGuid` | string (uuid) | Hayir |  |
| `outWarehouseName` | string | Hayir | nullable |
| `outWarehouseNo` | integer (int32) | Hayir |  |
| `packageCode` | string | Hayir | nullable |
| `priceListNo` | integer (int32) | Hayir |  |
| `projectCode` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `remainingQuantity` | number (double) | Hayir |  |
| `reservedQuantity` | number (double) | Hayir |  |
| `responsibilityCenter` | string | Hayir | nullable |
| `rowNo` | integer (int32) | Hayir |  |
| `special1` | string | Hayir | nullable |
| `special2` | string | Hayir | nullable |
| `special3` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |
| `unitPrice` | number (double) | Hayir |  |
| `validUntil` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseOrderDocumentUpdateResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `document` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseOrderDocumentDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.MikroDocumentUpdateSummary | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataDynamicCensusExecuteDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdDocumentCount` | integer (int32) | Hayir |  |
| `createdMovementLineCount` | integer (int32) | Hayir |  |
| `createdMovementQuantity` | number (double) | Hayir |  |
| `failedLineCount` | integer (int32) | Hayir |  |
| `failures` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataDynamicCensusFailureDto[] | Hayir | nullable |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `notes` | string[] | Hayir | nullable |
| `pendingStatus` | string | Hayir | nullable |
| `requestedLineCount` | integer (int32) | Hayir |  |
| `results` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataDynamicCensusResultDto[] | Hayir | nullable |
| `skippedLineCount` | integer (int32) | Hayir |  |
| `succeededLineCount` | integer (int32) | Hayir |  |
| `viewName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataDynamicCensusFailureDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `errorMessage` | string | Hayir | nullable |
| `rowNo` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataDynamicCensusLineDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataStockType` | string | Hayir | nullable |
| `canImport` | boolean | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | integer (int32) | Hayir |  |
| `existingMovementExists` | boolean | Hayir |  |
| `inputWarehouseNo` | integer (int32) | Hayir |  |
| `movementGenre` | integer (int32) | Hayir |  |
| `movementType` | integer (int32) | Hayir |  |
| `outputWarehouseNo` | integer (int32) | Hayir |  |
| `quantity` | number (double) | Hayir |  |
| `rowNo` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `warning` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataDynamicCensusPreviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `existingMovementLineCount` | integer (int32) | Hayir |  |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `importableLineCount` | integer (int32) | Hayir |  |
| `lines` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataDynamicCensusLineDto[] | Hayir | nullable |
| `notes` | string[] | Hayir | nullable |
| `pendingStatus` | string | Hayir | nullable |
| `returnedLineCount` | integer (int32) | Hayir |  |
| `totalFetchedLineCount` | integer (int32) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `viewName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataDynamicCensusResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `acknowledged` | boolean | Hayir |  |
| `message` | string | Hayir | nullable |
| `movementLineNo` | integer (int32) | Hayir |  |
| `movementOrderNo` | integer (int32) | Hayir |  |
| `movementSerie` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `rowNo` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataG01InboundAtfDocumentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataLineCount` | integer (int32) | Hayir |  |
| `axataQuantity` | number (double) | Hayir |  |
| `canImport` | boolean | Hayir |  |
| `customerCode` | string | Hayir | nullable |
| `despatchNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `existingMovementLineCount` | integer (int32) | Hayir |  |
| `mikroDeliveredQuantity` | number (double) | Hayir |  |
| `mikroOrderLineCount` | integer (int32) | Hayir |  |
| `mikroOrderQuantity` | number (double) | Hayir |  |
| `orderDocumentNo` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |
| `warning` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataG01InboundAtfExecuteDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdMovementLineCount` | integer (int32) | Hayir |  |
| `createdMovementQuantity` | number (double) | Hayir |  |
| `failedDocumentCount` | integer (int32) | Hayir |  |
| `failures` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataG01InboundAtfFailureDto[] | Hayir | nullable |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `movementType` | string | Hayir | nullable |
| `notes` | string[] | Hayir | nullable |
| `pendingStatus` | string | Hayir | nullable |
| `requestedDocumentCount` | integer (int32) | Hayir |  |
| `results` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataG01InboundAtfResultDto[] | Hayir | nullable |
| `skippedDocumentCount` | integer (int32) | Hayir |  |
| `succeededDocumentCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataG01InboundAtfFailureDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `errorMessage` | string | Hayir | nullable |
| `orderDocumentNo` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataG01InboundAtfPreviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documents` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataG01InboundAtfDocumentDto[] | Hayir | nullable |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `importableDocumentCount` | integer (int32) | Hayir |  |
| `movementType` | string | Hayir | nullable |
| `notes` | string[] | Hayir | nullable |
| `pendingStatus` | string | Hayir | nullable |
| `returnedDocumentCount` | integer (int32) | Hayir |  |
| `totalFetchedLineCount` | integer (int32) | Hayir |  |
| `totalLineCount` | integer (int32) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataG01InboundAtfResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `acknowledged` | boolean | Hayir |  |
| `createdMovementLineCount` | integer (int32) | Hayir |  |
| `createdMovementQuantity` | number (double) | Hayir |  |
| `message` | string | Hayir | nullable |
| `movementOrderNo` | integer (int32) | Hayir |  |
| `movementSerie` | string | Hayir | nullable |
| `orderDocumentNo` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataIntegrationAuditDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataOutboundDeliveries` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataPendingOutboundDeliveryDto[] | Hayir | nullable |
| `endDate` | string (date-time) | Hayir |  |
| `flowOverview` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataIntegrationFlowOverviewDto | Hayir |  |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `interventionCandidates` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataPendingOutboundDeliveryDto[] | Hayir | nullable |
| `isInSync` | boolean | Hayir |  |
| `notes` | string[] | Hayir | nullable |
| `operations` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataIntegrationAuditOperationDto[] | Hayir | nullable |
| `orderLifecycles` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOrderLifecycleDto[] | Hayir | nullable |
| `outboundDeliverySummaries` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryMovementSummaryDto[] | Hayir | nullable |
| `pendingOutboundDeliveries` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataPendingOutboundDeliveryDto[] | Hayir | nullable |
| `sentWarehouseOrdersMissingMikroShipments` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSentWarehouseOrderMissingShipmentDto[] | Hayir | nullable |
| `sentWarehouseOrdersWithShipmentDifferences` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSentWarehouseOrderMissingShipmentDto[] | Hayir | nullable |
| `startDate` | string (date-time) | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataIntegrationAuditSummaryDto | Hayir |  |
| `unsyncedWarehouseOrders` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataUnsyncedWarehouseOrderDto[] | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |
| `workflowSummary` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOrderWorkflowSummaryDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataIntegrationAuditOperationDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `canExecute` | boolean | Hayir |  |
| `code` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `documentCount` | integer (int32) | Hayir |  |
| `executeRoute` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `listRoute` | string | Hayir | nullable |
| `previewRoute` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `severity` | string | Hayir | nullable |
| `state` | string | Hayir | nullable |
| `title` | string | Hayir | nullable |
| `writesData` | boolean | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataIntegrationAuditSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataCancelledOutboundDeliveryDocumentCount` | integer (int32) | Hayir |  |
| `axataCancelledOutboundDeliveryLineCount` | integer (int32) | Hayir |  |
| `axataCancelledOutboundDeliveryQuantity` | number (double) | Hayir |  |
| `axataCompletedOutboundDeliveryDocumentCount` | integer (int32) | Hayir |  |
| `axataEmptyOutboundDeliveryDocumentCount` | integer (int32) | Hayir |  |
| `axataOutboundDeliveryDocumentCount` | integer (int32) | Hayir |  |
| `axataOutboundDeliveryLineCount` | integer (int32) | Hayir |  |
| `axataOutboundDeliveryQuantity` | number (double) | Hayir |  |
| `c01MikroExistsPendingAckDocumentCount` | integer (int32) | Hayir |  |
| `c01MissingInMikroDocumentCount` | integer (int32) | Hayir |  |
| `c01PendingDocumentCount` | integer (int32) | Hayir |  |
| `mikroWarehouseOrderDocumentCount` | integer (int32) | Hayir |  |
| `partiallySentWarehouseOrderDocumentCount` | integer (int32) | Hayir |  |
| `pendingOutboundDeliveryDocumentCount` | integer (int32) | Hayir |  |
| `pendingOutboundDeliveryLineCount` | integer (int32) | Hayir |  |
| `pendingOutboundDeliveryQuantity` | number (double) | Hayir |  |
| `sentWarehouseOrderDocumentCount` | integer (int32) | Hayir |  |
| `sentWarehouseOrderMissingAxataOutboundDeliveryDocumentCount` | integer (int32) | Hayir |  |
| `sentWarehouseOrderMissingAxataOutboundDeliveryLineCount` | integer (int32) | Hayir |  |
| `sentWarehouseOrderMissingAxataOutboundDeliveryQuantity` | number (double) | Hayir |  |
| `sentWarehouseOrderMissingMikroShipmentDocumentCount` | integer (int32) | Hayir |  |
| `sentWarehouseOrderMissingMikroShipmentLineCount` | integer (int32) | Hayir |  |
| `sentWarehouseOrderMissingMikroShipmentQuantity` | number (double) | Hayir |  |
| `sentWarehouseOrderMissingMikroShipmentWithAxataDeliveryDocumentCount` | integer (int32) | Hayir |  |
| `sentWarehouseOrderMissingMikroShipmentWithAxataDeliveryLineCount` | integer (int32) | Hayir |  |
| `sentWarehouseOrderMissingMikroShipmentWithAxataDeliveryQuantity` | number (double) | Hayir |  |
| `sentWarehouseOrderShipmentDifferenceDocumentCount` | integer (int32) | Hayir |  |
| `sentWarehouseOrderShipmentDifferenceLineCount` | integer (int32) | Hayir |  |
| `sentWarehouseOrderShipmentDifferenceQuantity` | number (double) | Hayir |  |
| `unsentWarehouseOrderDocumentCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataIntegrationFlowActionGroupDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `canExecute` | boolean | Hayir |  |
| `code` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `documentCount` | integer (int32) | Hayir |  |
| `documents` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataIntegrationFlowDocumentRefDto[] | Hayir | nullable |
| `executeRoute` | string | Hayir | nullable |
| `previewRoute` | string | Hayir | nullable |
| `severity` | string | Hayir | nullable |
| `title` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataIntegrationFlowDocumentRefDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataShipmentQuantity` | number (double) | Hayir |  |
| `documentDate` | string (date-time) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `mikroLinkedShipmentQuantity` | number (double) | Hayir |  |
| `mikroOrderQuantity` | number (double) | Hayir |  |
| `reason` | string | Hayir | nullable |
| `recommendedActionCode` | string | Hayir | nullable |
| `synchronizationState` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataIntegrationFlowOverviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `ackOnlyDocumentCount` | integer (int32) | Hayir |  |
| `actionGroups` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataIntegrationFlowActionGroupDto[] | Hayir | nullable |
| `axataCancelledShipmentDocumentCount` | integer (int32) | Hayir |  |
| `axataCompletedShipmentDocumentCount` | integer (int32) | Hayir |  |
| `axataOrderDifferenceDocumentCount` | integer (int32) | Hayir |  |
| `axataOrderDocumentCount` | integer (int32) | Hayir |  |
| `axataPendingShipmentDocumentCount` | integer (int32) | Hayir |  |
| `axataShipmentDocumentCount` | integer (int32) | Hayir |  |
| `fullySynchronizedDocumentCount` | integer (int32) | Hayir |  |
| `manualReviewDocumentCount` | integer (int32) | Hayir |  |
| `mikroLinkedShipmentDocumentCount` | integer (int32) | Hayir |  |
| `mikroOrderDocumentCount` | integer (int32) | Hayir |  |
| `narrative` | string | Hayir | nullable |
| `readyToImportToMikroDocumentCount` | integer (int32) | Hayir |  |
| `severity` | string | Hayir | nullable |
| `state` | string | Hayir | nullable |
| `steps` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataIntegrationFlowStepDto[] | Hayir | nullable |
| `title` | string | Hayir | nullable |
| `waitingForAxataShipmentDocumentCount` | integer (int32) | Hayir |  |
| `waitingForMikroTransferDocumentCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataIntegrationFlowStepDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `currentDocumentCount` | integer (int32) | Hayir |  |
| `description` | string | Hayir | nullable |
| `differenceDocumentCount` | integer (int32) | Hayir |  |
| `expectedDocumentCount` | integer (int32) | Hayir |  |
| `listRoute` | string | Hayir | nullable |
| `severity` | string | Hayir | nullable |
| `state` | string | Hayir | nullable |
| `title` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOrderLifecycleDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataCancelledShipmentDocumentCount` | integer (int32) | Hayir |  |
| `axataCompletedShipmentDocumentCount` | integer (int32) | Hayir |  |
| `axataOrderExists` | boolean | Hayir | nullable |
| `axataOrderLineCount` | integer (int32) | Hayir |  |
| `axataOrderQuantity` | number (double) | Hayir |  |
| `axataOrderState` | string | Hayir | nullable |
| `axataPendingShipmentDocumentCount` | integer (int32) | Hayir |  |
| `axataShipmentDocumentCount` | integer (int32) | Hayir |  |
| `axataShipmentLineCount` | integer (int32) | Hayir |  |
| `axataShipmentQuantity` | number (double) | Hayir |  |
| `documentDate` | string (date-time) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `existingMikroShipmentDocumentNo` | string | Hayir | nullable |
| `existingMikroShipmentLineCount` | integer (int32) | Hayir |  |
| `existingMikroShipmentQuantity` | number (double) | Hayir |  |
| `mikroDeliveredQuantity` | number (double) | Hayir |  |
| `mikroDispatchFlagState` | string | Hayir | nullable |
| `mikroLinkedShipmentLineCount` | integer (int32) | Hayir |  |
| `mikroLinkedShipmentQuantity` | number (double) | Hayir |  |
| `mikroOrderLineCount` | integer (int32) | Hayir |  |
| `mikroOrderQuantity` | number (double) | Hayir |  |
| `mikroSentFlagLineCount` | integer (int32) | Hayir |  |
| `mikroTransferState` | string | Hayir | nullable |
| `recommendedAction` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOrderRecommendedActionDto | Hayir |  |
| `shipmentState` | string | Hayir | nullable |
| `shipments` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOrderShipmentReferenceDto[] | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `synchronizationState` | string | Hayir | nullable |
| `targetWarehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOrderRecommendedActionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `canExecute` | boolean | Hayir |  |
| `code` | string | Hayir | nullable |
| `executeRoute` | string | Hayir | nullable |
| `previewRoute` | string | Hayir | nullable |
| `reason` | string | Hayir | nullable |
| `requiresManualAction` | boolean | Hayir |  |
| `severity` | string | Hayir | nullable |
| `title` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOrderShipmentReferenceDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataDeliveryNo` | string | Hayir | nullable |
| `axataSequenceNo` | integer (int64) | Hayir |  |
| `cancellationCode` | string | Hayir | nullable |
| `isCancelled` | boolean | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `quantity` | number (double) | Hayir |  |
| `shipmentDate` | string (date-time) | Hayir | nullable |
| `status` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOrderWorkflowSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataOrderDocumentCount` | integer (int32) | Hayir |  |
| `axataOrderMissingDocumentCount` | integer (int32) | Hayir |  |
| `axataOrderQuantityMismatchDocumentCount` | integer (int32) | Hayir |  |
| `axataOrderUnknownDocumentCount` | integer (int32) | Hayir |  |
| `axataShipmentDocumentCount` | integer (int32) | Hayir |  |
| `fullyLinkedInMikroDocumentCount` | integer (int32) | Hayir |  |
| `fullyShippedDocumentCount` | integer (int32) | Hayir |  |
| `fullySynchronizedDocumentCount` | integer (int32) | Hayir |  |
| `manualActionRequiredDocumentCount` | integer (int32) | Hayir |  |
| `mikroLinkedShipmentDocumentCount` | integer (int32) | Hayir |  |
| `mikroOrderDocumentCount` | integer (int32) | Hayir |  |
| `overShippedDocumentCount` | integer (int32) | Hayir |  |
| `partiallyLinkedInMikroDocumentCount` | integer (int32) | Hayir |  |
| `partiallyShippedDocumentCount` | integer (int32) | Hayir |  |
| `waitingForAxataShipmentDocumentCount` | integer (int32) | Hayir |  |
| `waitingForMikroTransferDocumentCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveriesByDateDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataDateNumber` | number (double) | Hayir |  |
| `date` | string (date-time) | Hayir |  |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryByDateItemDto[] | Hayir | nullable |
| `totalDocumentCount` | integer (int32) | Hayir |  |
| `totalLineCount` | integer (int32) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryByDateItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataDate` | string (date-time) | Hayir | nullable |
| `axataDeliveryNo` | string | Hayir | nullable |
| `axataSequenceNo` | integer (int64) | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir | nullable |
| `documentSerie` | string | Hayir | nullable |
| `driverName` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `movementType` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `sourceWarehouseCode` | string | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `targetWarehouseCode` | string | Hayir | nullable |
| `transferDate` | string (date-time) | Hayir | nullable |
| `vehiclePlate` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryImportDocumentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataDate` | string (date-time) | Hayir | nullable |
| `axataDeliveryNo` | string | Hayir | nullable |
| `axataLineCount` | integer (int32) | Hayir |  |
| `axataQuantity` | number (double) | Hayir |  |
| `axataSequenceNo` | integer (int64) | Hayir |  |
| `canImport` | boolean | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `existingLinkedMovementLineCount` | integer (int32) | Hayir |  |
| `mikroDeliveredQuantity` | number (double) | Hayir |  |
| `mikroOrderLineCount` | integer (int32) | Hayir |  |
| `mikroOrderQuantity` | number (double) | Hayir |  |
| `movementType` | string | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `status` | string | Hayir | nullable |
| `targetWarehouseNo` | integer (int32) | Hayir |  |
| `warning` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryImportExecuteDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdMovementLineCount` | integer (int32) | Hayir |  |
| `createdMovementQuantity` | number (double) | Hayir |  |
| `failedDocumentCount` | integer (int32) | Hayir |  |
| `failures` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryImportFailureDto[] | Hayir | nullable |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `movementType` | string | Hayir | nullable |
| `notes` | string[] | Hayir | nullable |
| `pendingStatus` | string | Hayir | nullable |
| `requestedDocumentCount` | integer (int32) | Hayir |  |
| `results` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryImportResultDto[] | Hayir | nullable |
| `skippedDocumentCount` | integer (int32) | Hayir |  |
| `succeededDocumentCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryImportFailureDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataDeliveryNo` | string | Hayir | nullable |
| `axataSequenceNo` | integer (int64) | Hayir | nullable |
| `errorMessage` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryImportPreviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documents` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryImportDocumentDto[] | Hayir | nullable |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `movementType` | string | Hayir | nullable |
| `notes` | string[] | Hayir | nullable |
| `pendingStatus` | string | Hayir | nullable |
| `returnedDocumentCount` | integer (int32) | Hayir |  |
| `totalFetchedDocumentCount` | integer (int32) | Hayir |  |
| `totalLineCount` | integer (int32) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryImportResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `acknowledged` | boolean | Hayir |  |
| `axataDate` | string (date-time) | Hayir | nullable |
| `axataDeliveryNo` | string | Hayir | nullable |
| `axataSequenceNo` | integer (int64) | Hayir |  |
| `createdMovementLineCount` | integer (int32) | Hayir |  |
| `createdMovementQuantity` | number (double) | Hayir |  |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `message` | string | Hayir | nullable |
| `movementDate` | string (date-time) | Hayir | nullable |
| `movementDocumentNo` | string | Hayir | nullable |
| `movementOrderNo` | integer (int32) | Hayir |  |
| `movementSerie` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryMovementSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `checkLevel` | string | Hayir | nullable |
| `mikroExistsPendingAckDocumentCount` | integer (int32) | Hayir |  |
| `mikroMissingDocumentCount` | integer (int32) | Hayir |  |
| `movementType` | string | Hayir | nullable |
| `pendingDocumentCount` | integer (int32) | Hayir |  |
| `pendingLineCount` | integer (int32) | Hayir |  |
| `pendingQuantity` | number (double) | Hayir |  |
| `pendingStatus` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryQueueDocumentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataDate` | string (date-time) | Hayir | nullable |
| `axataDeliveryNo` | string | Hayir | nullable |
| `axataSequenceNo` | integer (int64) | Hayir |  |
| `currentHandling` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir | nullable |
| `documentSerie` | string | Hayir | nullable |
| `hasLiveImport` | boolean | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `movementType` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `status` | string | Hayir | nullable |
| `targetWarehouseNo` | integer (int32) | Hayir |  |
| `warning` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryQueuePreviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documents` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryQueueDocumentDto[] | Hayir | nullable |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `movementType` | string | Hayir | nullable |
| `notes` | string[] | Hayir | nullable |
| `pendingStatus` | string | Hayir | nullable |
| `returnedDocumentCount` | integer (int32) | Hayir |  |
| `totalFetchedDocumentCount` | integer (int32) | Hayir |  |
| `totalLineCount` | integer (int32) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataPendingOutboundDeliveryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataDate` | string (date-time) | Hayir | nullable |
| `axataDeliveryNo` | string | Hayir | nullable |
| `axataSequenceNo` | integer (int64) | Hayir |  |
| `axataShipmentState` | string | Hayir | nullable |
| `canIntervene` | boolean | Hayir |  |
| `cancellationCode` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir | nullable |
| `documentSerie` | string | Hayir | nullable |
| `existingLinkedMovementLineCount` | integer (int32) | Hayir |  |
| `isCancelled` | boolean | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `mikroCheckState` | string | Hayir | nullable |
| `mikroDeliveredQuantity` | number (double) | Hayir |  |
| `mikroOrderLineCount` | integer (int32) | Hayir |  |
| `mikroOrderQuantity` | number (double) | Hayir |  |
| `movementType` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `status` | string | Hayir | nullable |
| `targetWarehouseNo` | integer (int32) | Hayir |  |
| `warning` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataProductSynchronizationExecuteDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `dispatchedAtUtc` | string (date-time) | Hayir |  |
| `endpointUrl` | string | Hayir | nullable |
| `failedProductCount` | integer (int32) | Hayir |  |
| `notes` | string[] | Hayir | nullable |
| `operationName` | string | Hayir | nullable |
| `requestedProductCount` | integer (int32) | Hayir |  |
| `results` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataProductSynchronizationResultDto[] | Hayir | nullable |
| `succeededProductCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataProductSynchronizationItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcodeCount` | integer (int32) | Hayir |  |
| `barcodes` | string[] | Hayir | nullable |
| `mainUnit` | string | Hayir | nullable |
| `payloadJson` | string | Hayir | nullable |
| `productCode` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `unitCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataProductSynchronizationPreviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `notes` | string[] | Hayir | nullable |
| `productCode` | string | Hayir | nullable |
| `products` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataProductSynchronizationItemDto[] | Hayir | nullable |
| `returnedRecordCount` | integer (int32) | Hayir |  |
| `totalRecordCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataProductSynchronizationResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcodeCount` | integer (int32) | Hayir |  |
| `isSuccess` | boolean | Hayir |  |
| `productCode` | string | Hayir | nullable |
| `serviceMessage` | string | Hayir | nullable |
| `serviceState` | integer (int32) | Hayir | nullable |
| `unitCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSentWarehouseOrderMissingShipmentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataOutboundDeliveryDate` | string (date-time) | Hayir | nullable |
| `axataOutboundDeliveryExists` | boolean | Hayir |  |
| `axataOutboundDeliveryLineCount` | integer (int32) | Hayir |  |
| `axataOutboundDeliveryQuantity` | number (double) | Hayir |  |
| `axataOutboundDeliveryStatus` | string | Hayir | nullable |
| `deliveredQuantity` | number (double) | Hayir |  |
| `differenceLineCount` | integer (int32) | Hayir |  |
| `differenceQuantity` | number (double) | Hayir |  |
| `differenceReason` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `inWarehouseNo` | integer (int32) | Hayir |  |
| `lastUpdateDate` | string (date-time) | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `linkedMovementLineCount` | integer (int32) | Hayir |  |
| `missingMovementLinkLineCount` | integer (int32) | Hayir |  |
| `missingMovementLinkQuantity` | number (double) | Hayir |  |
| `outWarehouseNo` | integer (int32) | Hayir |  |
| `sentLineCount` | integer (int32) | Hayir |  |
| `sentQuantity` | number (double) | Hayir |  |
| `state` | string | Hayir | nullable |
| `totalQuantity` | number (double) | Hayir |  |
| `warning` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationConnectionTestDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `probes` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationProbeDto[] | Hayir | nullable |
| `sourceDatabaseProfile` | string | Hayir | nullable |
| `testedAtUtc` | string (date-time) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationFetchProfileDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `ackEndpointKind` | string | Hayir | nullable |
| `ackEndpointUrl` | string | Hayir | nullable |
| `ackOperation` | string | Hayir | nullable |
| `code` | string | Hayir | nullable |
| `companyCode` | string | Hayir | nullable |
| `currentHandling` | string | Hayir | nullable |
| `currentRoute` | string | Hayir | nullable |
| `fetchOperation` | string | Hayir | nullable |
| `isImplemented` | boolean | Hayir |  |
| `movementType` | string | Hayir | nullable |
| `name` | string | Hayir | nullable |
| `pendingStatus` | string | Hayir | nullable |
| `sourceEndpointKind` | string | Hayir | nullable |
| `sourceEndpointUrl` | string | Hayir | nullable |
| `sourceSystem` | string | Hayir | nullable |
| `targetSystem` | string | Hayir | nullable |
| `warehouseCode` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationFetchProfilesOverviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `notes` | string[] | Hayir | nullable |
| `profiles` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationFetchProfileDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationJobArtifactDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `kind` | string | Hayir | nullable |
| `name` | string | Hayir | nullable |
| `path` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationJobDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `affectedRecordCount` | integer (int32) | Hayir |  |
| `artifacts` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationJobArtifactDto[] | Hayir | nullable |
| `completedAtUtc` | string (date-time) | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `errorMessage` | string | Hayir | nullable |
| `executionMode` | string | Hayir | nullable |
| `jobId` | string (uuid) | Hayir |  |
| `message` | string | Hayir | nullable |
| `requestedByUserId` | string (uuid) | Hayir |  |
| `startedAtUtc` | string (date-time) | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `taskCode` | string | Hayir | nullable |
| `taskName` | string | Hayir | nullable |
| `triggerSource` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationJobDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAtUtc` | string (date-time) | Hayir |  |
| `executionMode` | string | Hayir | nullable |
| `jobId` | string (uuid) | Hayir |  |
| `status` | string | Hayir | nullable |
| `taskCode` | string | Hayir | nullable |
| `taskName` | string | Hayir | nullable |
| `triggerSource` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDispatchBatchDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `dispatchedAtUtc` | string (date-time) | Hayir |  |
| `documents` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDispatchDto[] | Hayir | nullable |
| `failedDocumentCount` | integer (int32) | Hayir |  |
| `failures` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentBatchFailureDto[] | Hayir | nullable |
| `flow` | string | Hayir | nullable |
| `notes` | string[] | Hayir | nullable |
| `requestedDocumentCount` | integer (int32) | Hayir |  |
| `succeededDocumentCount` | integer (int32) | Hayir |  |
| `taskCode` | string | Hayir | nullable |
| `taskName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDispatchDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `dispatchedAtUtc` | string (date-time) | Hayir |  |
| `documentReference` | string | Hayir | nullable |
| `endpointUrl` | string | Hayir | nullable |
| `flow` | string | Hayir | nullable |
| `isSuccess` | boolean | Hayir |  |
| `notes` | string[] | Hayir | nullable |
| `operationName` | string | Hayir | nullable |
| `payloadJson` | string | Hayir | nullable |
| `requestPayloadJson` | string | Hayir | nullable |
| `responsePayloadJson` | string | Hayir | nullable |
| `serviceMessage` | string | Hayir | nullable |
| `serviceState` | integer (int32) | Hayir | nullable |
| `taskCode` | string | Hayir | nullable |
| `taskName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentBatchDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documents` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentDto[] | Hayir | nullable |
| `executionMode` | string | Hayir | nullable |
| `failedDocumentCount` | integer (int32) | Hayir |  |
| `failures` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentBatchFailureDto[] | Hayir | nullable |
| `flow` | string | Hayir | nullable |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `notes` | string[] | Hayir | nullable |
| `requestedDocumentCount` | integer (int32) | Hayir |  |
| `succeededDocumentCount` | integer (int32) | Hayir |  |
| `taskCode` | string | Hayir | nullable |
| `taskName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentBatchFailureDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentReference` | string | Hayir | nullable |
| `errorMessage` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentCandidateItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentIdentifier` | string | Hayir | nullable |
| `documentNo` | integer (int32) | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir | nullable |
| `documentReference` | string | Hayir | nullable |
| `documentSerie` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `summary` | string | Hayir | nullable |
| `totalQuantity` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentCandidatesDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `endDate` | string (date-time) | Hayir |  |
| `flow` | string | Hayir | nullable |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentCandidateItemDto[] | Hayir | nullable |
| `notes` | string[] | Hayir | nullable |
| `returnedRecordCount` | integer (int32) | Hayir |  |
| `skippedRecordCount` | integer (int32) | Hayir |  |
| `startDate` | string (date-time) | Hayir |  |
| `taskCode` | string | Hayir | nullable |
| `taskName` | string | Hayir | nullable |
| `totalRecordCount` | integer (int32) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `affectedRecordCount` | integer (int32) | Hayir |  |
| `artifacts` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationJobArtifactDto[] | Hayir | nullable |
| `documentReference` | string | Hayir | nullable |
| `executionMode` | string | Hayir | nullable |
| `flow` | string | Hayir | nullable |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `notes` | string[] | Hayir | nullable |
| `payloadJson` | string | Hayir | nullable |
| `taskCode` | string | Hayir | nullable |
| `taskName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationOverviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `enabled` | boolean | Hayir |  |
| `extendedEndpointUrl` | string | Hayir | nullable |
| `mainEndpointUrl` | string | Hayir | nullable |
| `recentJobs` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationJobDto[] | Hayir | nullable |
| `schedulerEnabled` | boolean | Hayir |  |
| `sourceDatabaseProfile` | string | Hayir | nullable |
| `tasks` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationTaskDto[] | Hayir | nullable |
| `workerEnabled` | boolean | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPanelActionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `canExecute` | boolean | Hayir |  |
| `code` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `documentCount` | integer (int32) | Hayir |  |
| `executeRoute` | string | Hayir | nullable |
| `label` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `listRoute` | string | Hayir | nullable |
| `previewRoute` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `severity` | string | Hayir | nullable |
| `state` | string | Hayir | nullable |
| `writesData` | boolean | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPanelDocumentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataShipmentQuantity` | number (double) | Hayir |  |
| `canExecute` | boolean | Hayir |  |
| `documentDate` | string (date-time) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `executeRoute` | string | Hayir | nullable |
| `existingMikroShipmentDocumentNo` | string | Hayir | nullable |
| `existingMikroShipmentLineCount` | integer (int32) | Hayir |  |
| `existingMikroShipmentQuantity` | number (double) | Hayir |  |
| `mikroDeliveredQuantity` | number (double) | Hayir |  |
| `mikroLinkedShipmentQuantity` | number (double) | Hayir |  |
| `mikroOrderQuantity` | number (double) | Hayir |  |
| `previewRoute` | string | Hayir | nullable |
| `quantitySummary` | string | Hayir | nullable |
| `reason` | string | Hayir | nullable |
| `recommendedActionCode` | string | Hayir | nullable |
| `recommendedActionTitle` | string | Hayir | nullable |
| `severity` | string | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `synchronizationState` | string | Hayir | nullable |
| `synchronizationStateLabel` | string | Hayir | nullable |
| `targetWarehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPanelDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `actions` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPanelActionDto[] | Hayir | nullable |
| `endDate` | string (date-time) | Hayir |  |
| `flowSteps` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPanelFlowStepDto[] | Hayir | nullable |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `isInSync` | boolean | Hayir |  |
| `message` | string | Hayir | nullable |
| `notes` | string[] | Hayir | nullable |
| `primaryEndpoints` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPanelEndpointDto[] | Hayir | nullable |
| `priorityDocuments` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPanelDocumentDto[] | Hayir | nullable |
| `severity` | string | Hayir | nullable |
| `startDate` | string (date-time) | Hayir |  |
| `state` | string | Hayir | nullable |
| `summaryCards` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPanelMetricDto[] | Hayir | nullable |
| `title` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPanelEndpointDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `label` | string | Hayir | nullable |
| `method` | string | Hayir | nullable |
| `route` | string | Hayir | nullable |
| `writesData` | boolean | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPanelFlowStepDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `currentDocumentCount` | integer (int32) | Hayir |  |
| `description` | string | Hayir | nullable |
| `differenceDocumentCount` | integer (int32) | Hayir |  |
| `expectedDocumentCount` | integer (int32) | Hayir |  |
| `label` | string | Hayir | nullable |
| `listRoute` | string | Hayir | nullable |
| `severity` | string | Hayir | nullable |
| `state` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPanelMetricDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `label` | string | Hayir | nullable |
| `severity` | string | Hayir | nullable |
| `value` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPreviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPreviewItemDto[] | Hayir | nullable |
| `notes` | string[] | Hayir | nullable |
| `returnedRecordCount` | integer (int32) | Hayir |  |
| `taskCode` | string | Hayir | nullable |
| `taskName` | string | Hayir | nullable |
| `totalRecordCount` | integer (int32) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPreviewItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `key` | string | Hayir | nullable |
| `payloadJson` | string | Hayir | nullable |
| `summary` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationProbeDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `durationMs` | integer (int64) | Hayir | nullable |
| `message` | string | Hayir | nullable |
| `name` | string | Hayir | nullable |
| `status` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationTaskDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `defaultWarehouseNo` | integer (int32) | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `enabled` | boolean | Hayir |  |
| `flow` | string | Hayir | nullable |
| `intervalMinutes` | integer (int32) | Hayir |  |
| `liveOperationName` | string | Hayir | nullable |
| `name` | string | Hayir | nullable |
| `requiresWarehouseNo` | boolean | Hayir |  |
| `scheduleEnabled` | boolean | Hayir |  |
| `sourceSystem` | string | Hayir | nullable |
| `supportsLiveDispatch` | boolean | Hayir |  |
| `supportsManualDocuments` | boolean | Hayir |  |
| `targetSystem` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationWorkbenchDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `endpointGroups` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationWorkbenchEndpointGroupDto[] | Hayir | nullable |
| `glossary` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationWorkbenchGlossaryItemDto[] | Hayir | nullable |
| `message` | string | Hayir | nullable |
| `operationGroups` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationWorkbenchOperationGroupDto[] | Hayir | nullable |
| `panel` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationPanelDto | Hayir |  |
| `purpose` | string | Hayir | nullable |
| `rules` | string[] | Hayir | nullable |
| `screenSections` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationWorkbenchScreenSectionDto[] | Hayir | nullable |
| `severity` | string | Hayir | nullable |
| `state` | string | Hayir | nullable |
| `title` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationWorkbenchEndpointDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `buttonLabel` | string | Hayir | nullable |
| `code` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `level` | string | Hayir | nullable |
| `method` | string | Hayir | nullable |
| `requestModel` | string | Hayir | nullable |
| `responseModel` | string | Hayir | nullable |
| `route` | string | Hayir | nullable |
| `title` | string | Hayir | nullable |
| `writeScope` | string | Hayir | nullable |
| `writesData` | boolean | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationWorkbenchEndpointGroupDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `endpoints` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationWorkbenchEndpointDto[] | Hayir | nullable |
| `title` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationWorkbenchGlossaryItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `meaning` | string | Hayir | nullable |
| `term` | string | Hayir | nullable |
| `uiLabel` | string | Hayir | nullable |
| `userWarning` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationWorkbenchOperationDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `canExecute` | boolean | Hayir |  |
| `code` | string | Hayir | nullable |
| `confirmationMessage` | string | Hayir | nullable |
| `direction` | string | Hayir | nullable |
| `documentCount` | integer (int32) | Hayir |  |
| `endpointCodes` | string[] | Hayir | nullable |
| `executeRoute` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `listRoute` | string | Hayir | nullable |
| `movementType` | string | Hayir | nullable |
| `normalFlow` | string | Hayir | nullable |
| `previewRoute` | string | Hayir | nullable |
| `primaryButtonLabel` | string | Hayir | nullable |
| `purpose` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `severity` | string | Hayir | nullable |
| `shortTitle` | string | Hayir | nullable |
| `sourceSystem` | string | Hayir | nullable |
| `state` | string | Hayir | nullable |
| `targetSystem` | string | Hayir | nullable |
| `title` | string | Hayir | nullable |
| `whenToUse` | string | Hayir | nullable |
| `writeScope` | string | Hayir | nullable |
| `writesData` | boolean | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationWorkbenchOperationGroupDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `direction` | string | Hayir | nullable |
| `operations` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationWorkbenchOperationDto[] | Hayir | nullable |
| `title` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationWorkbenchScreenSectionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `dataSource` | string | Hayir | nullable |
| `purpose` | string | Hayir | nullable |
| `sortOrder` | integer (int32) | Hayir |  |
| `title` | string | Hayir | nullable |
| `uiBehavior` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataUnsyncedWarehouseOrderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentDate` | string (date-time) | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `inWarehouseNo` | integer (int32) | Hayir |  |
| `lastUpdateDate` | string (date-time) | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `outWarehouseNo` | integer (int32) | Hayir |  |
| `sentLineCount` | integer (int32) | Hayir |  |
| `sentQuantity` | number (double) | Hayir |  |
| `state` | string | Hayir | nullable |
| `totalQuantity` | number (double) | Hayir |  |
| `unsentLineCount` | integer (int32) | Hayir |  |
| `unsentQuantity` | number (double) | Hayir |  |
| `warning` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.BranchInvoiceDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.BranchInvoiceListItemDto | Hayir |  |
| `lines` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.BranchInvoiceLineDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.BranchInvoiceLineDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `invoiceId` | integer (int32) | Hayir |  |
| `lineId` | integer (int32) | Hayir |  |
| `taxAmount` | number (double) | Hayir |  |
| `taxRate` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.BranchInvoiceListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `customerName` | string | Hayir | nullable |
| `customerTaxNo` | string | Hayir | nullable |
| `documentNo` | integer (int32) | Hayir |  |
| `invoiceDate` | string (date-time) | Hayir |  |
| `invoiceGuid` | string (uuid) | Hayir |  |
| `invoiceId` | integer (int32) | Hayir |  |
| `invoiceTotal` | number (double) | Hayir |  |
| `isSent` | boolean | Hayir |  |
| `paymentType` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.CashRegisterBranchMappingDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `cashRegisterNo` | string | Hayir | nullable |
| `id` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.ExpenseNoteDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.ExpenseNoteListItemDto | Hayir |  |
| `lines` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.ExpenseNoteLineDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.ExpenseNoteLineDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `expenseNoteId` | integer (int32) | Hayir |  |
| `lineId` | integer (int32) | Hayir |  |
| `taxAmount` | number (double) | Hayir |  |
| `taxRate` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.ExpenseNoteListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `expenseDate` | string (date-time) | Hayir |  |
| `expenseGuid` | string (uuid) | Hayir |  |
| `expenseId` | integer (int32) | Hayir |  |
| `expenseTotal` | number (double) | Hayir |  |
| `isSent` | boolean | Hayir |  |
| `paymentType` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.PosAccountingBatchResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentKind` | string | Hayir | nullable |
| `errorCount` | integer (int32) | Hayir |  |
| `requestedCount` | integer (int32) | Hayir |  |
| `results` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.PosAccountingOperationResultDto[] | Hayir | nullable |
| `successCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.PosAccountingImportResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `businessDate` | string (date-time) | Hayir |  |
| `documentKind` | string | Hayir | nullable |
| `errorCount` | integer (int32) | Hayir |  |
| `importedCount` | integer (int32) | Hayir |  |
| `results` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.PosAccountingOperationResultDto[] | Hayir | nullable |
| `skippedCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.PosAccountingOperationResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentId` | integer (int32) | Hayir | nullable |
| `message` | string | Hayir | nullable |
| `sourceGuid` | string (uuid) | Hayir | nullable |
| `success` | boolean | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.PosAccountingOverviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashRegisterMappingCount` | integer (int32) | Hayir |  |
| `pendingExpenseNoteCount` | integer (int32) | Hayir |  |
| `pendingExpenseNoteTotal` | number (double) | Hayir |  |
| `pendingInvoiceCount` | integer (int32) | Hayir |  |
| `pendingInvoiceTotal` | number (double) | Hayir |  |
| `pendingZReportCount` | integer (int32) | Hayir |  |
| `pendingZReportTotal` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.ZReportBankDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `bank` | string | Hayir | nullable |
| `bankAmount` | number (double) | Hayir |  |
| `bankDetailId` | integer (int32) | Hayir |  |
| `bankingNumber` | integer (int32) | Hayir |  |
| `totalId` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.ZReportDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `bankDetails` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.ZReportBankDetailDto[] | Hayir | nullable |
| `details` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.ZReportDetailLineDto[] | Hayir | nullable |
| `header` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.ZReportListItemDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.ZReportDetailLineDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `billTaxTotal` | number (double) | Hayir |  |
| `billTotal` | number (double) | Hayir |  |
| `detailId` | integer (int32) | Hayir |  |
| `taxRate` | integer (int32) | Hayir |  |
| `totalId` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.ZReportListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `billNo` | integer (int32) | Hayir |  |
| `branchName` | string | Hayir | nullable |
| `cashPaymentTotal` | number (double) | Hayir |  |
| `cashRegisterNo` | string | Hayir | nullable |
| `creditCardPaymentTotal` | number (double) | Hayir |  |
| `date` | string (date-time) | Hayir |  |
| `greatTotal` | number (double) | Hayir |  |
| `isSent` | boolean | Hayir |  |
| `totalId` | integer (int32) | Hayir |  |
| `zNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.TrendyolGo.TrendyolGoCatalogDispatch

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `batchCount` | integer (int32) | Hayir |  |
| `nextStep` | string | Hayir | nullable |
| `sentCount` | integer (int32) | Hayir |  |
| `storeId` | integer (int64) | Hayir |  |
| `upstreamResponses` | [] | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.TrendyolGo.TrendyolGoCatalogPreview

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `existingCount` | integer (int32) | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.TrendyolGo.TrendyolGoCatalogRow[] | Hayir | nullable |
| `mappingRequiredCount` | integer (int32) | Hayir |  |
| `previewHash` | string | Hayir | nullable |
| `readyCount` | integer (int32) | Hayir |  |
| `skippedCount` | integer (int32) | Hayir |  |
| `storeId` | integer (int64) | Hayir |  |
| `storeName` | string | Hayir | nullable |
| `totalCount` | integer (int32) | Hayir |  |
| `view` | string | Hayir | nullable |
| `visibleCount` | integer (int32) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.TrendyolGo.TrendyolGoCatalogRow

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `mikroBrandCode` | string | Hayir | nullable |
| `mikroCategoryCode` | string | Hayir | nullable |
| `mikroPrice` | number (double) | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `reason` | string | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `trendyolBrandId` | integer (int64) | Hayir | nullable |
| `trendyolCategoryId` | integer (int64) | Hayir | nullable |
| `vatRate` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.TrendyolGo.TrendyolGoConnectionStatusDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `baseUrl` | string | Hayir | nullable |
| `checkedAtUtc` | string (date-time) | Hayir |  |
| `credentialsConfigured` | boolean | Hayir |  |
| `enabled` | boolean | Hayir |  |
| `environment` | string | Hayir | nullable |
| `integrationReferenceCode` | string | Hayir | nullable |
| `message` | string | Hayir | nullable |
| `reachable` | boolean | Hayir | nullable |
| `supplierId` | integer (int64) | Hayir |  |
| `upstreamStatusCode` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.TrendyolGo.TrendyolGoStoreMappingDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `storeId` | integer (int64) | Hayir |  |
| `storeName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.UyumsoftServisleri.UyumsoftConnectedServiceOverviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `contractName` | string | Hayir | nullable |
| `endpointUrl` | string | Hayir | nullable |
| `serviceKey` | string | Hayir | nullable |
| `serviceName` | string | Hayir | nullable |
| `supportedGetOperations` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.UyumsoftServisleri.UyumsoftOperationDefinitionDto[] | Hayir | nullable |
| `wsdlUrl` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.UyumsoftServisleri.UyumsoftInvoiceListDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `items` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.UyumsoftServisleri.UyumsoftInvoiceListItemDto[] | Hayir | nullable |
| `pageIndex` | integer (int32) | Hayir |  |
| `pageSize` | integer (int32) | Hayir |  |
| `totalCount` | integer (int32) | Hayir |  |
| `totalPages` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.UyumsoftServisleri.UyumsoftInvoiceListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createDateUtc` | string (date-time) | Hayir |  |
| `direction` | string | Hayir | nullable |
| `documentCurrencyCode` | string | Hayir | nullable |
| `envelopeIdentifier` | string | Hayir | nullable |
| `envelopeStatus` | string | Hayir | nullable |
| `envelopeStatusCode` | integer (int32) | Hayir |  |
| `exchangeRate` | number (double) | Hayir |  |
| `executionDate` | string (date-time) | Hayir | nullable |
| `invoiceNumber` | string | Hayir | nullable |
| `invoiceTipType` | string | Hayir | nullable |
| `invoiceTipTypeCode` | integer (int32) | Hayir |  |
| `invoiceUuid` | string | Hayir | nullable |
| `isArchived` | boolean | Hayir |  |
| `isNew` | boolean | Hayir | nullable |
| `isSeen` | boolean | Hayir | nullable |
| `localDocumentId` | string | Hayir | nullable |
| `message` | string | Hayir | nullable |
| `orderDocumentId` | string | Hayir | nullable |
| `payableAmount` | number (double) | Hayir |  |
| `pdfFilePath` | string | Hayir | nullable |
| `scenario` | string | Hayir | nullable |
| `scenarioCode` | integer (int32) | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `statusCode` | integer (int32) | Hayir |  |
| `targetTcknVkn` | string | Hayir | nullable |
| `targetTitle` | string | Hayir | nullable |
| `taxExclusiveAmount` | number (double) | Hayir |  |
| `taxTotal` | number (double) | Hayir |  |
| `type` | string | Hayir | nullable |
| `typeCode` | integer (int32) | Hayir |  |
| `vat0TaxableAmount` | number (double) | Hayir |  |
| `vat1` | number (double) | Hayir |  |
| `vat10` | number (double) | Hayir |  |
| `vat10TaxableAmount` | number (double) | Hayir |  |
| `vat18` | number (double) | Hayir |  |
| `vat18TaxableAmount` | number (double) | Hayir |  |
| `vat1TaxableAmount` | number (double) | Hayir |  |
| `vat20` | number (double) | Hayir |  |
| `vat20TaxableAmount` | number (double) | Hayir |  |
| `vat8` | number (double) | Hayir |  |
| `vat8TaxableAmount` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.UyumsoftServisleri.UyumsoftOperationDefinitionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `groupName` | string | Hayir | nullable |
| `operationName` | string | Hayir | nullable |
| `parameters` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.UyumsoftServisleri.UyumsoftOperationParameterDefinitionDto[] | Hayir | nullable |
| `requestHint` | string | Hayir | nullable |
| `soapAction` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.UyumsoftServisleri.UyumsoftOperationParameterDefinitionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `allowedValues` | string[] | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `isArray` | boolean | Hayir |  |
| `isRequired` | boolean | Hayir |  |
| `name` | string | Hayir | nullable |
| `type` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.UyumsoftServisleri.UyumsoftOperationResponseDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `invoiceList` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.UyumsoftServisleri.UyumsoftInvoiceListDto | Hayir |  |
| `isSucceeded` | boolean | Hayir |  |
| `message` | string | Hayir | nullable |
| `nodes` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.UyumsoftServisleri.UyumsoftResponseNodeDto[] | Hayir | nullable |
| `operationName` | string | Hayir | nullable |
| `responsePayloadJson` | string | Hayir | nullable |
| `resultAttributes` | object | Hayir | nullable |
| `resultElementName` | string | Hayir | nullable |
| `scalarValue` | string | Hayir | nullable |
| `serviceKey` | string | Hayir | nullable |
| `serviceName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.UyumsoftServisleri.UyumsoftResponseNodeDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `attributes` | object | Hayir | nullable |
| `children` | FurpaMerkezApi.Application.Modules.EntegrasyonIslemleri.UyumsoftServisleri.UyumsoftResponseNodeDto[] | Hayir | nullable |
| `name` | string | Hayir | nullable |
| `value` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.Common.InvoiceDocumentProfile

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|

Enum degerleri JSON sozlesmesinde bulunur.

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.Common.InvoiceRenderedDocumentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `appliedXsltName` | string | Hayir | nullable |
| `htmlContent` | string | Hayir | nullable |
| `invoiceId` | string | Hayir | nullable |
| `profile` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.Common.InvoiceDocumentProfile | Hayir |  |
| `source` | string | Hayir | nullable |
| `usedEmbeddedXslt` | boolean | Hayir |  |
| `xmlContent` | string | Hayir | nullable |
| `xsltSource` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceReturnReferenceCandidateDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAt` | string (date-time) | Hayir |  |
| `customerCode` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `invoiceDate` | string (date-time) | Hayir | nullable |
| `invoiceNo` | string | Hayir | nullable |
| `isCurrentReference` | boolean | Hayir |  |
| `isFallbackCandidate` | boolean | Hayir |  |
| `isGeneratedInvoiceNo` | boolean | Hayir |  |
| `lineExtensionTotal` | number (double) | Hayir |  |
| `payableTotal` | number (double) | Hayir |  |
| `sourceDocumentOrderNo` | integer (int32) | Hayir |  |
| `sourceDocumentSerie` | string | Hayir | nullable |
| `taxTotal` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceReturnReferenceCandidatesResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `candidates` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceReturnReferenceCandidateDto[] | Hayir | nullable |
| `currentReference` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceReturnReferenceDto | Hayir |  |
| `fallbackReference` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceReturnReferenceCandidateDto | Hayir |  |
| `invoice` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingListItemDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceReturnReferenceDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `invoiceDate` | string (date-time) | Hayir | nullable |
| `invoiceNo` | string | Hayir | nullable |
| `source` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `document` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.Common.InvoiceRenderedDocumentDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingListItemDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `chargeTotal` | number (double) | Hayir |  |
| `customerCode` | string | Hayir | nullable |
| `customerTcknVkn` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `discountTotal` | number (double) | Hayir |  |
| `documentDate` | string (date-time) | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `grossTotal` | number (double) | Hayir |  |
| `invoiceId` | string | Hayir | nullable |
| `invoiceProfileId` | string | Hayir | nullable |
| `invoiceTypeCode` | string | Hayir | nullable |
| `isSent` | boolean | Hayir |  |
| `lineExtensionTotal` | number (double) | Hayir |  |
| `payableTotal` | number (double) | Hayir |  |
| `returnInvoiceDate` | string (date-time) | Hayir | nullable |
| `returnInvoiceNo` | string | Hayir | nullable |
| `scenario` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingScenario | Hayir |  |
| `sentDocumentNo` | string | Hayir | nullable |
| `shipmentDocumentDate` | string (date-time) | Hayir | nullable |
| `shipmentDocumentNo` | string | Hayir | nullable |
| `sourceLineCount` | integer (int32) | Hayir |  |
| `sourceLineSummary` | string | Hayir | nullable |
| `targetAlias` | string | Hayir | nullable |
| `taxRateSummary` | string | Hayir | nullable |
| `taxTotal` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingListResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `items` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingListItemDto[] | Hayir | nullable |
| `totalCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingScenario

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|

Enum degerleri JSON sozlesmesinde bulunur.

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.RetryInvoiceDocumentResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `invoiceId` | string | Hayir | nullable |
| `isSucceeded` | boolean | Hayir |  |
| `message` | string | Hayir | nullable |
| `serviceInvoiceId` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.RetryInvoiceDocumentsResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `failedCount` | integer (int32) | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.RetryInvoiceDocumentResultDto[] | Hayir | nullable |
| `requestedCount` | integer (int32) | Hayir |  |
| `scenario` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingScenario | Hayir |  |
| `succeededCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.SendInvoiceDocumentResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `invoiceId` | string | Hayir | nullable |
| `isSucceeded` | boolean | Hayir |  |
| `message` | string | Hayir | nullable |
| `serviceDocumentId` | string | Hayir | nullable |
| `serviceDocumentNumber` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.SendInvoiceDocumentsResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `failedCount` | integer (int32) | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.SendInvoiceDocumentResultDto[] | Hayir | nullable |
| `requestedCount` | integer (int32) | Hayir |  |
| `scenario` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingScenario | Hayir |  |
| `succeededCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.UpdateInvoiceReturnReferenceResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `invoice` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingListItemDto | Hayir |  |
| `reference` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceReturnReferenceDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.ValidateInvoiceDocumentResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `invoiceId` | string | Hayir | nullable |
| `isValid` | boolean | Hayir |  |
| `message` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.ValidateInvoiceDocumentsResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `invalidCount` | integer (int32) | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.ValidateInvoiceDocumentResultDto[] | Hayir | nullable |
| `requestedCount` | integer (int32) | Hayir |  |
| `scenario` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingScenario | Hayir |  |
| `validCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGoruntuleme.InvoiceViewingDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `document` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.Common.InvoiceRenderedDocumentDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGoruntuleme.InvoiceViewingListItemDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGoruntuleme.InvoiceViewingListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createDate` | string (date-time) | Hayir | nullable |
| `customerTcknVkn` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `despatchId` | string | Hayir | nullable |
| `documentCurrencyCode` | string | Hayir | nullable |
| `documentId` | string | Hayir | nullable |
| `envelopeIdentifier` | string | Hayir | nullable |
| `envelopeStatusCode` | string | Hayir | nullable |
| `exchangeRate` | number (double) | Hayir |  |
| `invoiceDate` | string (date-time) | Hayir | nullable |
| `invoiceId` | string | Hayir | nullable |
| `invoiceTipType` | string | Hayir | nullable |
| `invoiceTipTypeCode` | integer (int32) | Hayir |  |
| `invoiceTotal` | number (double) | Hayir |  |
| `invoiceType` | string | Hayir | nullable |
| `isArchived` | boolean | Hayir |  |
| `isPrinted` | boolean | Hayir |  |
| `isProcessed` | boolean | Hayir |  |
| `isSeen` | boolean | Hayir | nullable |
| `isStandard` | boolean | Hayir |  |
| `message` | string | Hayir | nullable |
| `orderDocumentId` | string | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `statusCode` | string | Hayir | nullable |
| `taxExclusiveAmount` | number (double) | Hayir |  |
| `taxTotal` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGoruntuleme.InvoiceViewingListResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `items` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGoruntuleme.InvoiceViewingListItemDto[] | Hayir | nullable |
| `pageNumber` | integer (int32) | Hayir |  |
| `pageSize` | integer (int32) | Hayir |  |
| `totalCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGoruntuleme.InvoiceViewingPrintedStateResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `source` | string | Hayir | nullable |
| `summary` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGoruntuleme.InvoiceViewingListItemDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGoruntuleme.InvoiceViewingSearchField

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|

Enum degerleri JSON sozlesmesinde bulunur.

### FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGoruntuleme.InvoiceViewingSynchronizationProgressResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `automaticSynchronizationEnabled` | boolean | Hayir | nullable |
| `elapsedMs` | integer (int64) | Hayir |  |
| `endDate` | string (date-time) | Hayir | nullable |
| `fetchedCount` | integer (int32) | Hayir |  |
| `finishedAtUtc` | string (date-time) | Hayir | nullable |
| `includeStatuses` | boolean | Hayir | nullable |
| `insertedCount` | integer (int32) | Hayir |  |
| `isRunning` | boolean | Hayir |  |
| `lastPageInsertedCount` | integer (int32) | Hayir |  |
| `lastPageItemCount` | integer (int32) | Hayir |  |
| `lastPageMatchedCount` | integer (int32) | Hayir |  |
| `lastPageSkippedDuplicateDocumentCount` | integer (int32) | Hayir |  |
| `lastPageSkippedInvoiceDateOutOfRangeCount` | integer (int32) | Hayir |  |
| `lastPageUpdatedCount` | integer (int32) | Hayir |  |
| `lastUpdatedAtUtc` | string (date-time) | Hayir | nullable |
| `matchedCount` | integer (int32) | Hayir |  |
| `message` | string | Hayir | nullable |
| `pageIndex` | integer (int32) | Hayir |  |
| `pageNumber` | integer (int32) | Hayir |  |
| `pageSize` | integer (int32) | Hayir |  |
| `progressPercent` | number (double) | Hayir |  |
| `queryEndDate` | string (date-time) | Hayir | nullable |
| `queryStartDate` | string (date-time) | Hayir | nullable |
| `schedulerCurrentSlot` | string | Hayir | nullable |
| `schedulerLastCheckedAtUtc` | string (date-time) | Hayir | nullable |
| `schedulerLastCheckedLocal` | string (date-time) | Hayir | nullable |
| `schedulerLastMissedAtUtc` | string (date-time) | Hayir | nullable |
| `schedulerLastMissedSlot` | string | Hayir | nullable |
| `schedulerLastQueuedAtUtc` | string (date-time) | Hayir | nullable |
| `schedulerLastQueuedSlot` | string | Hayir | nullable |
| `schedulerLastSkippedAtUtc` | string (date-time) | Hayir | nullable |
| `schedulerLastSkippedSlot` | string | Hayir | nullable |
| `schedulerMessage` | string | Hayir | nullable |
| `schedulerNextSlot` | string | Hayir | nullable |
| `schedulerStatus` | string | Hayir | nullable |
| `skippedDuplicateDocumentCount` | integer (int32) | Hayir |  |
| `skippedInvoiceDateOutOfRangeCount` | integer (int32) | Hayir |  |
| `startDate` | string (date-time) | Hayir | nullable |
| `startedAtUtc` | string (date-time) | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `totalCount` | integer (int32) | Hayir |  |
| `totalPage` | integer (int32) | Hayir |  |
| `updatedCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Operations.GreenGrocerOperationsAdjustmentApplyResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientRequestId` | string (uuid) | Hayir |  |
| `connectionStringName` | string | Hayir | nullable |
| `counterWarehouseNo` | integer (int32) | Hayir |  |
| `direction` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `movementDate` | string (date-time) | Hayir |  |
| `movementGuids` | string (uuid)[] | Hayir | nullable |
| `reasonCode` | string | Hayir | nullable |
| `reasonName` | string | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Operations.GreenGrocerOperationsAdjustmentPreviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `counterWarehouseNo` | integer (int32) | Hayir |  |
| `direction` | string | Hayir | nullable |
| `directionName` | string | Hayir | nullable |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `movementGenre` | integer (int32) | Hayir |  |
| `movementType` | integer (int32) | Hayir |  |
| `reasonCode` | string | Hayir | nullable |
| `reasonName` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Operations.GreenGrocerOperationsOverviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `endDate` | string (date-time) | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.GreenGrocer.Operations.GreenGrocerOperationsProductItemDto[] | Hayir | nullable |
| `productCount` | integer (int32) | Hayir |  |
| `startDate` | string (date-time) | Hayir |  |
| `statusSummaries` | FurpaMerkezApi.Application.Modules.GreenGrocer.Operations.GreenGrocerOperationsStatusSummaryDto[] | Hayir | nullable |
| `totalAdjustmentInQuantity` | number (double) | Hayir |  |
| `totalAdjustmentNetQuantity` | number (double) | Hayir |  |
| `totalAdjustmentOutQuantity` | number (double) | Hayir |  |
| `totalCurrentStockQuantity` | number (double) | Hayir |  |
| `totalLatestCountQuantity` | number (double) | Hayir |  |
| `totalOrderEstimatedQuantity` | number (double) | Hayir |  |
| `totalOrderInputQuantity` | number (double) | Hayir |  |
| `totalPurchaseAmount` | number (double) | Hayir |  |
| `totalPurchaseQuantity` | number (double) | Hayir |  |
| `totalShipmentQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Operations.GreenGrocerOperationsProductItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `adjustmentDocumentCount` | integer (int32) | Hayir |  |
| `adjustmentInQuantity` | number (double) | Hayir |  |
| `adjustmentNetQuantity` | number (double) | Hayir |  |
| `adjustmentOutQuantity` | number (double) | Hayir |  |
| `countDifferenceAtCountDate` | number (double) | Hayir | nullable |
| `currentStockQuantity` | number (double) | Hayir |  |
| `flags` | string[] | Hayir | nullable |
| `lastAdjustmentDate` | string (date-time) | Hayir | nullable |
| `lastAdjustmentDocument` | string | Hayir | nullable |
| `lastAdjustmentReason` | string | Hayir | nullable |
| `lastAdjustmentSeries` | string | Hayir | nullable |
| `lastCountDate` | string (date-time) | Hayir | nullable |
| `lastCountDocumentNo` | integer (int32) | Hayir | nullable |
| `lastCountQuantity` | number (double) | Hayir | nullable |
| `lastPurchaseDate` | string (date-time) | Hayir | nullable |
| `lastPurchaseDocument` | string | Hayir | nullable |
| `lastShipmentDate` | string (date-time) | Hayir | nullable |
| `lastShipmentDocument` | string | Hayir | nullable |
| `lastSupplierCode` | string | Hayir | nullable |
| `lastSupplierName` | string | Hayir | nullable |
| `modelCode` | string | Hayir | nullable |
| `modelName` | string | Hayir | nullable |
| `orderBranchCount` | integer (int32) | Hayir |  |
| `orderEstimatedQuantity` | number (double) | Hayir |  |
| `orderInputQuantity` | number (double) | Hayir |  |
| `orderLineCount` | integer (int32) | Hayir |  |
| `orderMicroQuantity` | number (double) | Hayir |  |
| `primaryStatusCode` | string | Hayir | nullable |
| `primaryStatusName` | string | Hayir | nullable |
| `purchaseAmount` | number (double) | Hayir |  |
| `purchaseDocumentCount` | integer (int32) | Hayir |  |
| `purchaseQuantity` | number (double) | Hayir |  |
| `purchaseUnitPrice` | number (double) | Hayir |  |
| `shipmentBranchCount` | integer (int32) | Hayir |  |
| `shipmentDocumentCount` | integer (int32) | Hayir |  |
| `shipmentQuantity` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `systemQuantityAtCountDate` | number (double) | Hayir | nullable |
| `unitName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Operations.GreenGrocerOperationsStatusSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `adjustmentNetQuantity` | number (double) | Hayir |  |
| `currentStockQuantity` | number (double) | Hayir |  |
| `orderEstimatedQuantity` | number (double) | Hayir |  |
| `productCount` | integer (int32) | Hayir |  |
| `purchaseQuantity` | number (double) | Hayir |  |
| `shipmentQuantity` | number (double) | Hayir |  |
| `statusCode` | string | Hayir | nullable |
| `statusName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.ProductCases.GreenGrocerProductCaseProfileDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `allowOrderLinking` | boolean | Hayir |  |
| `averageWindowDays` | integer (int32) | Hayir |  |
| `conversionMode` | string | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `id` | string (uuid) | Hayir |  |
| `inputMode` | string | Hayir | nullable |
| `isActive` | boolean | Hayir |  |
| `manualKgPerCase` | number (double) | Hayir | nullable |
| `manualUnitsPerCase` | number (double) | Hayir | nullable |
| `maxCoefficientOfVariation` | number (double) | Hayir |  |
| `maxExpectedKgPerCase` | number (double) | Hayir | nullable |
| `minAverageCaseCount` | integer (int32) | Hayir |  |
| `minAverageRecordCount` | integer (int32) | Hayir |  |
| `minExpectedKgPerCase` | number (double) | Hayir | nullable |
| `modelCode` | string | Hayir | nullable |
| `modelName` | string | Hayir | nullable |
| `notes` | string | Hayir | nullable |
| `overDeliveryTolerancePercent` | number (double) | Hayir |  |
| `requiresManualApproval` | boolean | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unit1` | string | Hayir | nullable |
| `unit2` | string | Hayir | nullable |
| `unit2Factor` | number (double) | Hayir |  |
| `updatedAtUtc` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.ProductCases.GreenGrocerProductCaseResolutionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `averageCaseCount` | integer (int32) | Hayir | nullable |
| `averageKgPerCase` | number (double) | Hayir | nullable |
| `averageRecordCount` | integer (int32) | Hayir | nullable |
| `averageSource` | string | Hayir | nullable |
| `coefficientOfVariation` | number (double) | Hayir | nullable |
| `confidence` | string | Hayir | nullable |
| `conversionMode` | string | Hayir | nullable |
| `errors` | string[] | Hayir | nullable |
| `estimatedQuantity` | number (double) | Hayir |  |
| `inputMode` | string | Hayir | nullable |
| `inputQuantity` | number (double) | Hayir |  |
| `isOrderLinkable` | boolean | Hayir |  |
| `isUsable` | boolean | Hayir |  |
| `latestLabelDate` | string (date-time) | Hayir | nullable |
| `microUnit` | string | Hayir | nullable |
| `modelCode` | string | Hayir | nullable |
| `modelName` | string | Hayir | nullable |
| `requiresManualApproval` | boolean | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unit1` | string | Hayir | nullable |
| `unit2` | string | Hayir | nullable |
| `unit2Factor` | number (double) | Hayir |  |
| `unitsPerCase` | number (double) | Hayir | nullable |
| `warnings` | string[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.DeleteGreenGrocerOrderResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deletedAt` | string (date-time) | Hayir |  |
| `deletedLineCount` | integer (int32) | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `latestCreateDate` | string (date-time) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerBranchReportDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `items` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerBranchReportItemDto[] | Hayir | nullable |
| `lazyBranches` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerLazyBranchDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerBranchReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branch` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportWarehouseDto | Hayir |  |
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `canDelete` | boolean | Hayir |  |
| `caseInfo` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportCaseInfoDto | Hayir |  |
| `document` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportDocumentDto | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `globalProductCode` | string | Hayir | nullable |
| `latestCreateDate` | string (date-time) | Hayir |  |
| `orderDate` | string (date-time) | Hayir |  |
| `primaryBarcode` | string | Hayir | nullable |
| `product` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportProductDto | Hayir |  |
| `productCode` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `typeCode` | string | Hayir | nullable |
| `typeName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerBranchSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branch` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportWarehouseDto | Hayir |  |
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `caseInfo` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportCaseInfoDto | Hayir |  |
| `documentCount` | integer (int32) | Hayir |  |
| `productCount` | integer (int32) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerDashboardDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchCount` | integer (int32) | Hayir |  |
| `branches` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerBranchSummaryDto[] | Hayir | nullable |
| `caseInfo` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportCaseInfoDto | Hayir |  |
| `documentCount` | integer (int32) | Hayir |  |
| `lazyBranchCount` | integer (int32) | Hayir |  |
| `lazyBranches` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerLazyBranchDto[] | Hayir | nullable |
| `productCount` | integer (int32) | Hayir |  |
| `reportDate` | string (date-time) | Hayir |  |
| `topProducts` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerProductReportItemDto[] | Hayir | nullable |
| `totalQuantity` | number (double) | Hayir |  |
| `typeSummaries` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerTypeSummaryDto[] | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerGreenReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branch` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportWarehouseDto | Hayir |  |
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `canDelete` | boolean | Hayir |  |
| `caseInfo` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportCaseInfoDto | Hayir |  |
| `document` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportDocumentDto | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `globalProductCode` | string | Hayir | nullable |
| `latestCreateDate` | string (date-time) | Hayir |  |
| `orderDate` | string (date-time) | Hayir |  |
| `primaryBarcode` | string | Hayir | nullable |
| `product` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportProductDto | Hayir |  |
| `productCode` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `rowNo` | integer (int32) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `typeCode` | string | Hayir | nullable |
| `typeName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerLazyBranchDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branch` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportWarehouseDto | Hayir |  |
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `regionCode` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerProductBranchItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branch` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportWarehouseDto | Hayir |  |
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `canDelete` | boolean | Hayir |  |
| `caseInfo` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportCaseInfoDto | Hayir |  |
| `document` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportDocumentDto | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `latestCreateDate` | string (date-time) | Hayir |  |
| `quantity` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerProductReportGroupDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branches` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerProductBranchItemDto[] | Hayir | nullable |
| `caseInfo` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportCaseInfoDto | Hayir |  |
| `globalProductCode` | string | Hayir | nullable |
| `primaryBarcode` | string | Hayir | nullable |
| `product` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportProductDto | Hayir |  |
| `productCode` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `totalQuantity` | number (double) | Hayir |  |
| `typeCode` | string | Hayir | nullable |
| `typeName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerProductReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `caseInfo` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportCaseInfoDto | Hayir |  |
| `globalProductCode` | string | Hayir | nullable |
| `primaryBarcode` | string | Hayir | nullable |
| `product` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportProductDto | Hayir |  |
| `productCode` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `typeCode` | string | Hayir | nullable |
| `typeName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportCaseInfoDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `averageCaseCount` | integer (int32) | Hayir | nullable |
| `averageKgPerCase` | number (double) | Hayir | nullable |
| `averageRecordCount` | integer (int32) | Hayir | nullable |
| `averageSource` | string | Hayir | nullable |
| `coefficientOfVariation` | number (double) | Hayir | nullable |
| `confidence` | string | Hayir | nullable |
| `estimatedQuantity` | number (double) | Hayir |  |
| `inputMode` | string | Hayir | nullable |
| `inputQuantity` | number (double) | Hayir |  |
| `microUnit` | string | Hayir | nullable |
| `unitsPerCase` | number (double) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportDocumentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportProductDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `displayName` | string | Hayir | nullable |
| `globalProductCode` | string | Hayir | nullable |
| `modelCode` | string | Hayir | nullable |
| `modelName` | string | Hayir | nullable |
| `primaryBarcode` | string | Hayir | nullable |
| `productCode` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `shortName` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportWarehouseDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `regionCode` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerTypeOptionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `isGreens` | boolean | Hayir |  |
| `typeCode` | string | Hayir | nullable |
| `typeName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerTypeSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchCount` | integer (int32) | Hayir |  |
| `caseInfo` | FurpaMerkezApi.Application.Modules.GreenGrocer.Reports.GreenGrocerReportCaseInfoDto | Hayir |  |
| `documentCount` | integer (int32) | Hayir |  |
| `productCount` | integer (int32) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `typeCode` | string | Hayir | nullable |
| `typeName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.Home.DepoOncelikleri.HomePriorityItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `count` | integer (int32) | Hayir |  |
| `description` | string | Hayir | nullable |
| `route` | string | Hayir | nullable |
| `severity` | string | Hayir | nullable |
| `title` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.Home.DepoOncelikleri.HomePriorityMetricDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `label` | string | Hayir | nullable |
| `route` | string | Hayir | nullable |
| `severity` | string | Hayir | nullable |
| `value` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.Home.DepoOncelikleri.HomeQuickActionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `label` | string | Hayir | nullable |
| `permissionCode` | string | Hayir | nullable |
| `route` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.Home.DepoOncelikleri.HomeWarehousePrioritiesDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `date` | string (date) | Hayir |  |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `headline` | string | Hayir | nullable |
| `metrics` | FurpaMerkezApi.Application.Modules.Home.DepoOncelikleri.HomePriorityMetricDto[] | Hayir | nullable |
| `overallStatus` | string | Hayir | nullable |
| `priorities` | FurpaMerkezApi.Application.Modules.Home.DepoOncelikleri.HomePriorityItemDto[] | Hayir | nullable |
| `quickActions` | FurpaMerkezApi.Application.Modules.Home.DepoOncelikleri.HomeQuickActionDto[] | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.IadeIslemleri.DepoIadeleri.Create.CreateWarehouseReturnResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentDate` | string (date-time) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `movementDate` | string (date-time) | Hayir |  |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `targetWarehouseNo` | integer (int32) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `transitWarehouseNo` | integer (int32) | Hayir |  |
| `writeConnectionName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.IadeIslemleri.DepoIadeleri.EligibleProducts.WarehouseReturnEligibleProductDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `caseBarcode` | string | Hayir | nullable |
| `currentStockQuantity` | number (double) | Hayir |  |
| `decision` | string | Hayir | nullable |
| `hasPurchaseRequirement` | boolean | Hayir |  |
| `isReturnable` | boolean | Hayir |  |
| `modelCode` | string | Hayir | nullable |
| `modelName` | string | Hayir | nullable |
| `procurementType` | string | Hayir | nullable |
| `productSourceWarehouseName` | string | Hayir | nullable |
| `productSourceWarehouseNo` | integer (int32) | Hayir |  |
| `returnWarehouseName` | string | Hayir | nullable |
| `returnWarehouseNo` | integer (int32) | Hayir |  |
| `returnableQuantity` | number (double) | Hayir |  |
| `secondaryUnitName` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitMultiplier` | number (double) | Hayir |  |
| `unitName` | string | Hayir | nullable |
| `warnings` | string[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.IadeIslemleri.DepoIadeleri.EligibleProducts.WarehouseReturnEligibleProductsDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `items` | FurpaMerkezApi.Application.Modules.IadeIslemleri.DepoIadeleri.EligibleProducts.WarehouseReturnEligibleProductDto[] | Hayir | nullable |
| `sourceWarehouseName` | string | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `totalCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.BanknotTakipleri.BanknoteTrackDailySummaryTotalDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `dateToGet` | string (date-time) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.BanknotTakipleri.BanknoteTrackDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `banknoteTrackDate` | string (date-time) | Hayir |  |
| `banknoteTrackId` | string (uuid) | Hayir |  |
| `createDate` | string (date-time) | Hayir |  |
| `deliverer` | string | Hayir | nullable |
| `deliveryTotalAmount` | number (double) | Hayir |  |
| `differenceAmount` | number (double) | Hayir |  |
| `receiver` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.BanknotTakipleri.CreateBanknoteTrackResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `banknoteTrackDate` | string (date-time) | Hayir |  |
| `banknoteTrackId` | string (uuid) | Hayir |  |
| `created` | boolean | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.BirlikKartSorgulama.BirlikKartDetayRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cekNo` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.BirlikKartSorgulama.BirlikKartDetayResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `baslangic` | string (date-time) | Hayir | nullable |
| `bitis` | string (date-time) | Hayir | nullable |
| `cariKod` | string | Hayir | nullable |
| `cekNo` | string | Hayir | nullable |
| `flag` | boolean | Hayir | nullable |
| `isFound` | boolean | Hayir |  |
| `kartNo` | string | Hayir | nullable |
| `kartTipi` | integer (int32) | Hayir | nullable |
| `kasaNo` | integer (int32) | Hayir | nullable |
| `message` | string | Hayir | nullable |
| `puan` | number (double) | Hayir | nullable |
| `subeKodu` | string | Hayir | nullable |
| `tutar` | number (double) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.BirlikKartSorgulama.BirlikKartGuncelleResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `isUpdated` | boolean | Hayir |  |
| `message` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.BirlikKartSorgulama.BirlikKartSorgulamaGuncelleRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `baslangic` | string (date-time) | Hayir | nullable |
| `bitis` | string (date-time) | Hayir | nullable |
| `cariKod` | string | Hayir | nullable |
| `cekNo` | string | Hayir | nullable |
| `flag` | boolean | Hayir | nullable |
| `kartTipi` | integer (int32) | Hayir | nullable |
| `kasaNo` | integer (int32) | Hayir | nullable |
| `puan` | number (double) | Hayir | nullable |
| `subeKodu` | string | Hayir | nullable |
| `tutar` | number (double) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.BirlikKartSorgulama.BirlikKartSorgulamaRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `kartNo` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.BirlikKartSorgulama.BirlikKartSorgulamaResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `baslangic` | string (date-time) | Hayir | nullable |
| `bitis` | string (date-time) | Hayir | nullable |
| `cariKod` | string | Hayir | nullable |
| `cekNo` | string | Hayir | nullable |
| `flag` | boolean | Hayir | nullable |
| `isFound` | boolean | Hayir |  |
| `kartNo` | string | Hayir | nullable |
| `kartTipi` | integer (int32) | Hayir | nullable |
| `kasaNo` | integer (int32) | Hayir | nullable |
| `message` | string | Hayir | nullable |
| `puan` | number (double) | Hayir | nullable |
| `subeKodu` | string | Hayir | nullable |
| `tutar` | number (double) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.EtiketBelgeleri.CreateLabelDocumentResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createDate` | string (date-time) | Hayir |  |
| `documentId` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.EtiketBelgeleri.LabelActivePromotionProductDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `alternativeUnitName` | string | Hayir | nullable |
| `barcode` | string | Hayir | nullable |
| `barcodes` | string[] | Hayir | nullable |
| `pluNo` | integer (int32) | Hayir |  |
| `price` | number (double) | Hayir |  |
| `productCode` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `promotion` | FurpaMerkezApi.Application.Modules.KasaIslemleri.EtiketBelgeleri.LabelPromotionDto | Hayir |  |
| `unitName` | string | Hayir | nullable |
| `unitPriceFactor` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.EtiketBelgeleri.LabelDocumentListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createDate` | string (date-time) | Hayir |  |
| `documentId` | integer (int32) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.EtiketBelgeleri.LabelDocumentProductDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `alternativeUnitName` | string | Hayir | nullable |
| `barcode` | string | Hayir | nullable |
| `barcodeContent` | string | Hayir | nullable |
| `bulkSaleTaxRate` | integer (int32) | Hayir |  |
| `canBeCalled` | boolean | Hayir |  |
| `categoryCode` | string | Hayir | nullable |
| `deliveredQuantity` | number (double) | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `isClosedToOrder` | integer (int32) | Hayir |  |
| `isClosedToReceiving` | integer (int32) | Hayir |  |
| `isClosedToSale` | integer (int32) | Hayir |  |
| `isDomestic` | integer (int32) | Hayir |  |
| `isPassive` | boolean | Hayir |  |
| `lastUpdateDate` | string (date-time) | Hayir |  |
| `oldPrice` | number (double) | Hayir |  |
| `orderGuid` | string (uuid) | Hayir | nullable |
| `origin` | string | Hayir | nullable |
| `package` | string | Hayir | nullable |
| `packageFactor` | string | Hayir | nullable |
| `pluNo` | integer (int32) | Hayir |  |
| `price` | number (double) | Hayir |  |
| `priceChangeDate` | string | Hayir | nullable |
| `productCode` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `promotion` | FurpaMerkezApi.Application.Modules.KasaIslemleri.EtiketBelgeleri.LabelPromotionDto | Hayir |  |
| `quantity` | number (double) | Hayir |  |
| `retailSaleTaxRate` | integer (int32) | Hayir |  |
| `sectorCode` | string | Hayir | nullable |
| `shelfLife` | integer (int32) | Hayir |  |
| `supplierCode` | string | Hayir | nullable |
| `type` | string | Hayir | nullable |
| `typeCode` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |
| `unitName2` | string | Hayir | nullable |
| `unitPriceFactor` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.EtiketBelgeleri.LabelPriceChangedProductDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `alternativeUnitName` | string | Hayir | nullable |
| `barcode` | string | Hayir | nullable |
| `barcodes` | string[] | Hayir | nullable |
| `isDomestic` | integer (int32) | Hayir |  |
| `oldPrice` | number (double) | Hayir |  |
| `origin` | string | Hayir | nullable |
| `pluNo` | integer (int32) | Hayir |  |
| `price` | number (double) | Hayir |  |
| `priceChangeDate` | string | Hayir | nullable |
| `productCode` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `promotion` | FurpaMerkezApi.Application.Modules.KasaIslemleri.EtiketBelgeleri.LabelPromotionDto | Hayir |  |
| `unitName` | string | Hayir | nullable |
| `unitPriceFactor` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.EtiketBelgeleri.LabelPromotionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `campaignText` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `discountAmount` | number (double) | Hayir |  |
| `discountRate` | number (double) | Hayir |  |
| `discountType` | string | Hayir | nullable |
| `discountValue` | number (double) | Hayir |  |
| `discountedProductCode` | string | Hayir | nullable |
| `discountedQuantity` | number (double) | Hayir |  |
| `effectiveUnitPrice` | number (double) | Hayir | nullable |
| `expirationDate` | string (date-time) | Hayir | nullable |
| `isActive` | boolean | Hayir |  |
| `normalPrice` | number (double) | Hayir |  |
| `productRole` | string | Hayir | nullable |
| `promotionCode` | string | Hayir | nullable |
| `promotionName` | string | Hayir | nullable |
| `promotionPrice` | number (double) | Hayir |  |
| `promotionType` | string | Hayir | nullable |
| `requiredProductCode` | string | Hayir | nullable |
| `requiredQuantity` | number (double) | Hayir |  |
| `source` | string | Hayir | nullable |
| `startDate` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.EtiketBelgeleri.LabelTagDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `buyer` | string | Hayir | nullable |
| `buyingPrice` | number (double) | Hayir |  |
| `goodsGenus` | string | Hayir | nullable |
| `goodsType` | string | Hayir | nullable |
| `manufacturer` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `productionCity` | string | Hayir | nullable |
| `productionDate` | string (date-time) | Hayir |  |
| `productionDistrict` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `shippingDate` | string (date-time) | Hayir |  |
| `takenTag` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaCiroAktarimi.KasaCiroBranchDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `region` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaCiroAktarimi.KasaCiroImportIssueDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir | nullable |
| `cashRegisterNo` | integer (int32) | Hayir | nullable |
| `date` | string (date-time) | Hayir | nullable |
| `file` | string | Hayir | nullable |
| `lineNo` | integer (int32) | Hayir | nullable |
| `message` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaCiroAktarimi.KasaCiroImportResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `endDate` | string (date-time) | Hayir |  |
| `errors` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaCiroAktarimi.KasaCiroImportIssueDto[] | Hayir | nullable |
| `insertedDetails` | integer (int32) | Hayir |  |
| `insertedDiscountCards` | integer (int32) | Hayir |  |
| `insertedTotals` | integer (int32) | Hayir |  |
| `processedBranches` | integer (int32) | Hayir |  |
| `processedDays` | integer (int32) | Hayir |  |
| `processedFiles` | integer (int32) | Hayir |  |
| `runId` | string | Hayir | nullable |
| `skippedEmptyBranches` | integer (int32) | Hayir |  |
| `startDate` | string (date-time) | Hayir |  |
| `status` | string | Hayir | nullable |
| `updatedDetails` | integer (int32) | Hayir |  |
| `updatedDiscountCards` | integer (int32) | Hayir |  |
| `updatedTotals` | integer (int32) | Hayir |  |
| `warnings` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaCiroAktarimi.KasaCiroImportIssueDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaCirolari.CashTurnoverBranchOverviewItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `averageBasketAmount` | number (double) | Hayir |  |
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `cashTotal` | number (double) | Hayir |  |
| `collectionTotal` | number (double) | Hayir |  |
| `comparisonTotal` | number (double) | Hayir |  |
| `creditTotal` | number (double) | Hayir |  |
| `customerCount` | integer (int32) | Hayir |  |
| `discountCardCustomerCount` | integer (int32) | Hayir |  |
| `expenseNoteCount` | integer (int32) | Hayir |  |
| `expenseNoteTotal` | number (double) | Hayir |  |
| `furparaCardCustomerCount` | integer (int32) | Hayir |  |
| `futuresSalesCount` | integer (int32) | Hayir |  |
| `futuresSalesTotal` | number (double) | Hayir |  |
| `giftCardTotal` | number (double) | Hayir |  |
| `grossSalesTotal` | number (double) | Hayir |  |
| `lastBillTime` | string | Hayir | nullable |
| `overallTotal` | number (double) | Hayir |  |
| `paymentDataMissing` | boolean | Hayir |  |
| `region` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaCirolari.CashTurnoverDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaCirolari.CashTurnoverHeaderDto | Hayir |  |
| `payments` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaCirolari.CashTurnoverPaymentDetailItemDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaCirolari.CashTurnoverHeaderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `businessDate` | string (date-time) | Hayir |  |
| `cashierCode` | string | Hayir | nullable |
| `cashierName` | string | Hayir | nullable |
| `comparisonTotal` | number (double) | Hayir |  |
| `futuresSalesTotal` | number (double) | Hayir |  |
| `grossSalesTotal` | number (double) | Hayir |  |
| `netCollectionAmount` | number (double) | Hayir |  |
| `paymentDataMissing` | boolean | Hayir |  |
| `paymentLineCount` | integer (int32) | Hayir |  |
| `productLineCount` | integer (int32) | Hayir |  |
| `shiftNo` | integer (int32) | Hayir |  |
| `source` | string | Hayir | nullable |
| `totalCollectionAmount` | number (double) | Hayir |  |
| `totalCustomerCommission` | number (double) | Hayir |  |
| `totalSalesAmount` | number (double) | Hayir |  |
| `totalSalesQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaCirolari.CashTurnoverListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `businessDate` | string (date-time) | Hayir |  |
| `cashierCode` | string | Hayir | nullable |
| `cashierName` | string | Hayir | nullable |
| `comparisonTotal` | number (double) | Hayir |  |
| `futuresSalesTotal` | number (double) | Hayir |  |
| `grossSalesTotal` | number (double) | Hayir |  |
| `netCollectionAmount` | number (double) | Hayir |  |
| `paymentDataMissing` | boolean | Hayir |  |
| `paymentLineCount` | integer (int32) | Hayir |  |
| `productLineCount` | integer (int32) | Hayir |  |
| `shiftNo` | integer (int32) | Hayir |  |
| `source` | string | Hayir | nullable |
| `totalCollectionAmount` | number (double) | Hayir |  |
| `totalCustomerCommission` | number (double) | Hayir |  |
| `totalSalesAmount` | number (double) | Hayir |  |
| `totalSalesQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaCirolari.CashTurnoverOverviewDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `averageBasketAmount` | number (double) | Hayir |  |
| `dailyCashPayment` | number (double) | Hayir |  |
| `dailyCollectionTotal` | number (double) | Hayir |  |
| `dailyComparisonTotal` | number (double) | Hayir |  |
| `dailyCreditCardPayment` | number (double) | Hayir |  |
| `dailyCustomerCount` | integer (int32) | Hayir |  |
| `dailyDiscountCardCustomerCount` | integer (int32) | Hayir |  |
| `dailyExpenseNoteCount` | integer (int32) | Hayir |  |
| `dailyExpenseNoteTotal` | number (double) | Hayir |  |
| `dailyFurparaCardCustomerCount` | integer (int32) | Hayir |  |
| `dailyFuturesSalesCount` | integer (int32) | Hayir |  |
| `dailyFuturesSalesTotal` | number (double) | Hayir |  |
| `dailyGiftCardPayment` | number (double) | Hayir |  |
| `dailyGrossSalesTotal` | number (double) | Hayir |  |
| `dailyPaymentDataMissingBranchCount` | integer (int32) | Hayir |  |
| `dailyTotal` | number (double) | Hayir |  |
| `subeCirolari` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaCirolari.CashTurnoverBranchOverviewItemDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaCirolari.CashTurnoverPaymentDetailItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `cashBankCode` | string | Hayir | nullable |
| `cashBankName` | string | Hayir | nullable |
| `customerCommission` | number (double) | Hayir |  |
| `netAmount` | number (double) | Hayir |  |
| `paymentLineCount` | integer (int32) | Hayir |  |
| `paymentTypeName` | string | Hayir | nullable |
| `paymentTypeNo` | integer (int32) | Hayir |  |
| `source` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketBranchDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `region` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketCashRegisterDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir |  |
| `cashRegisterNo` | integer (int32) | Hayir |  |
| `cashRegisterType` | integer (int32) | Hayir |  |
| `cashRegisterTypeDescription` | string | Hayir | nullable |
| `cashRegisterTypeName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketCashSummaryComparisonDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir | nullable |
| `cashRegisterNo` | integer (int32) | Hayir | nullable |
| `date` | string (date-time) | Hayir |  |
| `rows` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketCashSummaryComparisonRowDto[] | Hayir | nullable |
| `summary` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketCashSummaryComparisonSummaryDto | Hayir |  |
| `tolerance` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketCashSummaryComparisonRowDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `cashRegisterNo` | integer (int32) | Hayir |  |
| `cashSummaryAmount` | number (double) | Hayir |  |
| `cashSummaryDocumentCount` | integer (int32) | Hayir |  |
| `date` | string (date-time) | Hayir |  |
| `differenceAmount` | number (double) | Hayir |  |
| `movementCheckAmount` | number (double) | Hayir |  |
| `movementExpense` | number (double) | Hayir |  |
| `movementNetAmount` | number (double) | Hayir |  |
| `movementZReportAmount` | number (double) | Hayir |  |
| `status` | string | Hayir | nullable |
| `statusName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketCashSummaryComparisonSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `balancedCount` | integer (int32) | Hayir |  |
| `differenceCount` | integer (int32) | Hayir |  |
| `missingCashSummaryCount` | integer (int32) | Hayir |  |
| `missingMovementCount` | integer (int32) | Hayir |  |
| `rowCount` | integer (int32) | Hayir |  |
| `totalCashSummaryAmount` | number (double) | Hayir |  |
| `totalDifferenceAmount` | number (double) | Hayir |  |
| `totalMovementZReportAmount` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketCashSummaryDocumentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashNo` | integer (int32) | Hayir |  |
| `cashierName` | string | Hayir | nullable |
| `cashierNo` | integer (int32) | Hayir |  |
| `createDate` | string (date-time) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `managerName` | string | Hayir | nullable |
| `managerNo` | integer (int32) | Hayir |  |
| `paymentLineCount` | integer (int32) | Hayir |  |
| `summaryDate` | string (date-time) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `zReportNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketCashSummaryPaymentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accountCode` | string | Hayir | nullable |
| `amount` | number (double) | Hayir |  |
| `isIncludedInComparison` | boolean | Hayir |  |
| `paymentTypeId` | integer (int32) | Hayir |  |
| `paymentTypeName` | string | Hayir | nullable |
| `slipCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketCashierSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashierCode` | string | Hayir | nullable |
| `cashierName` | string | Hayir | nullable |
| `checkAmount` | number (double) | Hayir |  |
| `expense` | number (double) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `netAmount` | number (double) | Hayir |  |
| `receiptCount` | integer (int32) | Hayir |  |
| `zReportAmount` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `canceledReceipts` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketReceiptDto[] | Hayir | nullable |
| `cashRegisterNo` | integer (int32) | Hayir |  |
| `cashSummaryDocuments` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketCashSummaryDocumentDto[] | Hayir | nullable |
| `cashSummaryPayments` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketCashSummaryPaymentDto[] | Hayir | nullable |
| `cashierSummaries` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketCashierSummaryDto[] | Hayir | nullable |
| `comparison` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketCashSummaryComparisonRowDto | Hayir |  |
| `date` | string (date-time) | Hayir |  |
| `movementPaymentSummaries` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketPaymentSummaryDto[] | Hayir | nullable |
| `movementReport` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketReportRowDto | Hayir |  |
| `receipts` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketReceiptDto[] | Hayir | nullable |
| `summary` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketDetailSummaryDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketDetailSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `canceledReceiptCount` | integer (int32) | Hayir |  |
| `cashSummaryAmount` | number (double) | Hayir |  |
| `cashSummaryDocumentCount` | integer (int32) | Hayir |  |
| `cashSummaryPaymentCount` | integer (int32) | Hayir |  |
| `differenceAmount` | number (double) | Hayir |  |
| `maxReceiptNo` | integer (int32) | Hayir | nullable |
| `minReceiptNo` | integer (int32) | Hayir | nullable |
| `missingReceiptNos` | integer (int32)[] | Hayir | nullable |
| `movementCheckAmount` | number (double) | Hayir |  |
| `movementExpense` | number (double) | Hayir |  |
| `movementLineCount` | integer (int32) | Hayir |  |
| `movementNetAmount` | number (double) | Hayir |  |
| `movementPaymentCount` | integer (int32) | Hayir |  |
| `movementZReportAmount` | number (double) | Hayir |  |
| `receiptCount` | integer (int32) | Hayir |  |
| `returnedReceiptCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketImportIssueDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir | nullable |
| `cashRegisterNo` | integer (int32) | Hayir | nullable |
| `file` | string | Hayir | nullable |
| `lineNo` | integer (int32) | Hayir | nullable |
| `message` | string | Hayir | nullable |
| `receiptNo` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketImportResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `errors` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketImportIssueDto[] | Hayir | nullable |
| `importType` | string | Hayir | nullable |
| `insertedLines` | integer (int32) | Hayir |  |
| `insertedPayments` | integer (int32) | Hayir |  |
| `insertedPromotions` | integer (int32) | Hayir |  |
| `processedFiles` | integer (int32) | Hayir |  |
| `processedInvoices` | integer (int32) | Hayir |  |
| `runId` | string | Hayir | nullable |
| `skippedExistingInvoices` | integer (int32) | Hayir |  |
| `status` | string | Hayir | nullable |
| `warnings` | FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketImportIssueDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketPaymentSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `paymentCount` | integer (int32) | Hayir |  |
| `paymentType` | integer (int32) | Hayir |  |
| `paymentTypeName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketProcedureResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir | nullable |
| `cashRegisterNo` | integer (int32) | Hayir | nullable |
| `date` | string (date-time) | Hayir |  |
| `message` | string | Hayir | nullable |
| `procedure` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketReceiptDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir |  |
| `cancelReason` | integer (int32) | Hayir |  |
| `cancelReasonName` | string | Hayir | nullable |
| `cardNumber` | string | Hayir | nullable |
| `cashRegisterNo` | integer (int32) | Hayir |  |
| `cashierCode` | string | Hayir | nullable |
| `cashierName` | string | Hayir | nullable |
| `checkAmount` | number (double) | Hayir |  |
| `customerCurrentCode` | string | Hayir | nullable |
| `date` | string (date-time) | Hayir |  |
| `discountAmount` | number (double) | Hayir |  |
| `documentKind` | integer (int32) | Hayir |  |
| `documentKindName` | string | Hayir | nullable |
| `expenseAmount` | number (double) | Hayir |  |
| `fiscalMemoryCode` | string | Hayir | nullable |
| `grossAmount` | number (double) | Hayir |  |
| `invoiceGuid` | string (uuid) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `netAmount` | number (double) | Hayir |  |
| `paymentCount` | integer (int32) | Hayir |  |
| `processResult` | string | Hayir | nullable |
| `promotionCount` | integer (int32) | Hayir |  |
| `receiptNo` | integer (int32) | Hayir |  |
| `taxAmount` | number (double) | Hayir |  |
| `time` | string (date-span) | Hayir |  |
| `zNo` | string | Hayir | nullable |
| `zReportAmount` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketReportRowDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `cashRegisterNo` | integer (int32) | Hayir |  |
| `checkAmount` | number (double) | Hayir |  |
| `date` | string (date-time) | Hayir |  |
| `difference` | number (double) | Hayir |  |
| `expense` | number (double) | Hayir |  |
| `netAmount` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketReportSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir | nullable |
| `cashRegisterNo` | integer (int32) | Hayir | nullable |
| `date` | string (date-time) | Hayir |  |
| `rowCount` | integer (int32) | Hayir |  |
| `totalCheckAmount` | number (double) | Hayir |  |
| `totalDifference` | number (double) | Hayir |  |
| `totalExpense` | number (double) | Hayir |  |
| `totalNetAmount` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.BanknoteMovementItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `banknoteType` | integer (int32) | Hayir |  |
| `banknoteTypeName` | string | Hayir | nullable |
| `quantity` | integer (int32) | Hayir |  |
| `total` | number (double) | Hayir |  |
| `value` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.BanknoteTypeItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `banknoteType` | integer (int32) | Hayir |  |
| `banknoteTypeName` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `total` | number (double) | Hayir |  |
| `value` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.CashRegisterDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `bank` | string | Hayir | nullable |
| `cashNo` | integer (int32) | Hayir | nullable |
| `cashRegisterNo` | string | Hayir | nullable |
| `id` | integer (int32) | Hayir |  |
| `merchantNo` | string | Hayir | nullable |
| `terminalId` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.CashRegistryItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir |  |
| `cashRegisterNo` | integer (int32) | Hayir |  |
| `cashRegisterType` | integer (int32) | Hayir |  |
| `cashRegisterTypeDescription` | string | Hayir | nullable |
| `cashRegisterTypeName` | string | Hayir | nullable |
| `detailId` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.CashSummaryDetailItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accountCode` | string | Hayir | nullable |
| `amount` | number (double) | Hayir |  |
| `category` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `paymentName` | string | Hayir | nullable |
| `paymentTypeId` | integer (int32) | Hayir |  |
| `paymentTypeKey` | string | Hayir | nullable |
| `paymentTypeNo` | integer (int32) | Hayir |  |
| `slipNumber` | integer (int32) | Hayir |  |
| `source` | string | Hayir | nullable |
| `terminalId` | string | Hayir | nullable |
| `typeName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.CashSummaryListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashNo` | integer (int32) | Hayir |  |
| `cashierNo` | integer (int32) | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `managerNo` | integer (int32) | Hayir |  |
| `summaryDate` | string (date-time) | Hayir |  |
| `total` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |
| `zReportNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.CashSummaryReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `akbank` | number (double) | Hayir |  |
| `akbankQuantity` | integer (int32) | Hayir |  |
| `cashAmount` | number (double) | Hayir |  |
| `cashAmountQuantity` | integer (int32) | Hayir |  |
| `expenseCompass` | number (double) | Hayir |  |
| `expenseCompassQuantity` | integer (int32) | Hayir |  |
| `halkbank` | number (double) | Hayir |  |
| `halkbankQuantity` | integer (int32) | Hayir |  |
| `isBankasi` | number (double) | Hayir |  |
| `isBankasiQuantity` | integer (int32) | Hayir |  |
| `metropol` | number (double) | Hayir |  |
| `metropolQuantity` | integer (int32) | Hayir |  |
| `multinet` | number (double) | Hayir |  |
| `multinetQuantity` | integer (int32) | Hayir |  |
| `setcard` | number (double) | Hayir |  |
| `setcardQuantity` | integer (int32) | Hayir |  |
| `sodexoKupon` | number (double) | Hayir |  |
| `sodexoKuponQuantity` | integer (int32) | Hayir |  |
| `sodexoPos` | number (double) | Hayir |  |
| `sodexoPosQuantity` | integer (int32) | Hayir |  |
| `storeExpense` | number (double) | Hayir |  |
| `storeExpenseQuantity` | integer (int32) | Hayir |  |
| `teb` | number (double) | Hayir |  |
| `tebQuantity` | integer (int32) | Hayir |  |
| `ticketKupon` | number (double) | Hayir |  |
| `ticketKuponQuantity` | integer (int32) | Hayir |  |
| `ticketPos` | number (double) | Hayir |  |
| `ticketPosQuantity` | integer (int32) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |
| `yapiKredi` | number (double) | Hayir |  |
| `yapiKrediQuantity` | integer (int32) | Hayir |  |
| `ziraatBankasi` | number (double) | Hayir |  |
| `ziraatBankasiQuantity` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.CashSummaryZReportTotalDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `zTotalValue` | number (double) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.CashierItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashierAuthorization` | string | Hayir | nullable |
| `cashierCode` | integer (int32) | Hayir |  |
| `cashierId` | integer (int32) | Hayir |  |
| `cashierName` | string | Hayir | nullable |
| `cashierPassword` | string | Hayir | nullable |
| `cashierState` | boolean | Hayir |  |
| `createDate` | string (date-time) | Hayir |  |
| `createUser` | integer (int32) | Hayir |  |
| `updateDate` | string (date-time) | Hayir |  |
| `updateUser` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.CashierSearchItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashierAuthorization` | string | Hayir | nullable |
| `cashierCode` | integer (int32) | Hayir |  |
| `cashierName` | string | Hayir | nullable |
| `cashierPassword` | string | Hayir | nullable |
| `cashierState` | boolean | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.CreateCashSummaryResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `summaryDate` | string (date-time) | Hayir |  |
| `total` | number (double) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |
| `writeConnectionName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.DeleteCashSummaryResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deletedBanknoteLineCount` | integer (int32) | Hayir |  |
| `deletedCustomerMovementCount` | integer (int32) | Hayir |  |
| `deletedGiftCheckLineCount` | integer (int32) | Hayir |  |
| `deletedSummaryLineCount` | integer (int32) | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.GiftCheckMovementItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `giftCheckType` | integer (int32) | Hayir |  |
| `giftCheckTypeName` | string | Hayir | nullable |
| `quantity` | integer (int32) | Hayir |  |
| `total` | number (double) | Hayir |  |
| `value` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.GiftCheckTypeItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `giftCheckType` | integer (int32) | Hayir |  |
| `giftCheckTypeName` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `total` | number (double) | Hayir |  |
| `value` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.PaymentTypeItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accountCode` | string | Hayir | nullable |
| `amountValue` | number (double) | Hayir |  |
| `paymentGenus` | integer (int32) | Hayir |  |
| `paymentName` | string | Hayir | nullable |
| `paymentTypeId` | integer (int32) | Hayir |  |
| `paymentTypeKey` | string | Hayir | nullable |
| `paymentTypeNo` | integer (int32) | Hayir |  |
| `slipNumber` | integer (int32) | Hayir |  |
| `terminalId` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.UpdateCashSummaryBanknotesResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `updatedLineCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.UpdateCashSummaryDetailsResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `updatedLineCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KasaSayimlari.UpdateCashSummaryGiftChecksResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `updatedLineCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.KunyeEtiketYazdirma.KunyeLabelTagDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `buyer` | string | Hayir | nullable |
| `buyingPrice` | number (double) | Hayir |  |
| `goodsGenus` | string | Hayir | nullable |
| `goodsType` | string | Hayir | nullable |
| `manufacturer` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `productUnit` | string | Hayir | nullable |
| `productionCity` | string | Hayir | nullable |
| `productionDate` | string (date-time) | Hayir |  |
| `productionDistrict` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `salesPrice` | number (double) | Hayir |  |
| `shippingDate` | string (date-time) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `takenTag` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketAcceptanceRecordDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `averageCaseWeight` | number (double) | Hayir |  |
| `barcodeSymbology` | string | Hayir | nullable |
| `caseCount` | integer (int32) | Hayir |  |
| `caseTare` | number (double) | Hayir |  |
| `caseTotalTare` | number (double) | Hayir |  |
| `caseType` | string | Hayir | nullable |
| `createdAt` | string (date-time) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentSeries` | string | Hayir | nullable |
| `grossWeight` | number (double) | Hayir |  |
| `id` | integer (int32) | Hayir |  |
| `labelBarcode` | string | Hayir | nullable |
| `labelBarcodeRaw` | string | Hayir | nullable |
| `microTransferred` | boolean | Hayir |  |
| `netReceivedWeight` | number (double) | Hayir |  |
| `palletTare` | number (double) | Hayir |  |
| `receivedBy` | string | Hayir | nullable |
| `seriesAndNumber` | string | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `stockBarcode` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `supplierCode` | string | Hayir | nullable |
| `supplierName` | string | Hayir | nullable |
| `updatedAt` | string (date-time) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketCalculationDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `averageCaseWeight` | number (double) | Hayir |  |
| `barcodeSymbology` | string | Hayir | nullable |
| `caseTotalTare` | number (double) | Hayir |  |
| `labelBarcode` | string | Hayir | nullable |
| `labelBarcodeRaw` | string | Hayir | nullable |
| `netReceivedWeight` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketCreateMicroGoodsReceiptResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createUserNo` | integer (int32) | Hayir |  |
| `date` | string (date-time) | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSeries` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `lines` | FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketMicroGoodsReceiptLineDto[] | Hayir | nullable |
| `offlineTraceKey` | string | Hayir | nullable |
| `seriesAndNumber` | string | Hayir | nullable |
| `supplierCode` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `totalTax` | number (double) | Hayir |  |
| `updatedAcceptanceRecordCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketDepotStockReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `currentStock` | number (double) | Hayir |  |
| `modelCode` | string | Hayir | nullable |
| `purchasePriceWithVat` | number (double) | Hayir |  |
| `responsible` | string | Hayir | nullable |
| `salesPrice` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketGoodsReceiptComparisonItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `date` | string (date-time) | Hayir |  |
| `difference` | number (double) | Hayir |  |
| `labelNetWeight` | number (double) | Hayir |  |
| `labelRowCount` | integer (int32) | Hayir |  |
| `microAmount` | number (double) | Hayir |  |
| `microDocument` | string | Hayir | nullable |
| `microQuantity` | number (double) | Hayir |  |
| `microRowCount` | integer (int32) | Hayir |  |
| `status` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `supplierCode` | string | Hayir | nullable |
| `supplierName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketIncomingInvoiceDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `canStartAcceptance` | boolean | Hayir |  |
| `createDate` | string (date-time) | Hayir | nullable |
| `despatchId` | string | Hayir | nullable |
| `documentCurrencyCode` | string | Hayir | nullable |
| `documentId` | string | Hayir | nullable |
| `exchangeRate` | number (double) | Hayir |  |
| `invoiceDate` | string (date-time) | Hayir | nullable |
| `invoiceId` | string | Hayir | nullable |
| `invoiceTipType` | string | Hayir | nullable |
| `invoiceTipTypeCode` | integer (int32) | Hayir |  |
| `invoiceTotal` | number (double) | Hayir |  |
| `invoiceType` | string | Hayir | nullable |
| `isArchived` | boolean | Hayir |  |
| `isPrinted` | boolean | Hayir |  |
| `isProcessed` | boolean | Hayir |  |
| `isSeen` | boolean | Hayir | nullable |
| `isStandard` | boolean | Hayir |  |
| `lastSynchronizedAtUtc` | string (date-time) | Hayir |  |
| `matchedSupplierCode` | string | Hayir | nullable |
| `matchedSupplierName` | string | Hayir | nullable |
| `message` | string | Hayir | nullable |
| `orderDocumentId` | string | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `statusCode` | string | Hayir | nullable |
| `supplierTaxNo` | string | Hayir | nullable |
| `supplierTitle` | string | Hayir | nullable |
| `taxExclusiveAmount` | number (double) | Hayir |  |
| `taxTotal` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketInvoiceDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `canStartAcceptance` | boolean | Hayir |  |
| `despatchId` | string | Hayir | nullable |
| `documentCurrencyCode` | string | Hayir | nullable |
| `documentId` | string | Hayir | nullable |
| `invoiceId` | string | Hayir | nullable |
| `invoiceLookupId` | string | Hayir | nullable |
| `invoiceTypeCode` | string | Hayir | nullable |
| `issueDate` | string (date-time) | Hayir | nullable |
| `lines` | FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketInvoiceLineDto[] | Hayir | nullable |
| `matchedSupplierCode` | string | Hayir | nullable |
| `matchedSupplierName` | string | Hayir | nullable |
| `payableAmount` | number (double) | Hayir |  |
| `supplierTaxNo` | string | Hayir | nullable |
| `supplierTitle` | string | Hayir | nullable |
| `taxExclusiveAmount` | number (double) | Hayir |  |
| `taxTotal` | number (double) | Hayir |  |
| `totalCaseCount` | integer (int32) | Hayir | nullable |
| `totalGrossWithTareQuantity` | number (double) | Hayir | nullable |
| `totalNetQuantity` | number (double) | Hayir | nullable |
| `totalTareQuantity` | number (double) | Hayir | nullable |
| `warnings` | string[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketInvoiceLineDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `canCreateAcceptance` | boolean | Hayir |  |
| `caseCount` | integer (int32) | Hayir | nullable |
| `grossWithTareQuantity` | number (double) | Hayir | nullable |
| `lineAmount` | number (double) | Hayir |  |
| `lineId` | string | Hayir | nullable |
| `lineNo` | integer (int32) | Hayir |  |
| `matchedBarcode` | string | Hayir | nullable |
| `matchedStockCode` | string | Hayir | nullable |
| `matchedStockName` | string | Hayir | nullable |
| `netQuantity` | number (double) | Hayir | nullable |
| `note` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `tareQuantity` | number (double) | Hayir | nullable |
| `taxAmount` | number (double) | Hayir |  |
| `taxPointer` | integer (int32) | Hayir | nullable |
| `taxRatePercent` | number (double) | Hayir |  |
| `unitCode` | string | Hayir | nullable |
| `unitPrice` | number (double) | Hayir |  |
| `warnings` | string[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketLabelDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `averageCaseWeight` | number (double) | Hayir |  |
| `barcodeSymbology` | string | Hayir | nullable |
| `caseTare` | number (double) | Hayir |  |
| `caseType` | string | Hayir | nullable |
| `labelBarcode` | string | Hayir | nullable |
| `labelBarcodeRaw` | string | Hayir | nullable |
| `labelCount` | integer (int32) | Hayir |  |
| `labelDate` | string (date-time) | Hayir |  |
| `recordId` | integer (int32) | Hayir | nullable |
| `stockBarcode` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `supplierName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketMicroGoodsReceiptDocumentDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createUserNo` | integer (int32) | Hayir |  |
| `date` | string (date-time) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSeries` | string | Hayir | nullable |
| `firstCreatedAt` | string (date-time) | Hayir |  |
| `invoiceGuid` | string | Hayir | nullable |
| `lastCreatedAt` | string (date-time) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `lines` | FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketMicroGoodsReceiptLineDto[] | Hayir | nullable |
| `offlineTraceKey` | string | Hayir | nullable |
| `seriesAndNumber` | string | Hayir | nullable |
| `supplierCode` | string | Hayir | nullable |
| `supplierName` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `totalTax` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketMicroGoodsReceiptLineDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `barcode` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `inWarehouseNo` | integer (int32) | Hayir |  |
| `lineNo` | integer (int32) | Hayir |  |
| `movementGuid` | string | Hayir | nullable |
| `outWarehouseNo` | integer (int32) | Hayir |  |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `taxAmount` | number (double) | Hayir |  |
| `taxPointer` | integer (int32) | Hayir |  |
| `unitName` | string | Hayir | nullable |
| `unitPrice` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketReceivedProductReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `caseCount` | integer (int32) | Hayir |  |
| `caseTotalTare` | number (double) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentSeries` | string | Hayir | nullable |
| `grossWeight` | number (double) | Hayir |  |
| `invoiceDifference` | number (double) | Hayir |  |
| `invoiceQuantity` | number (double) | Hayir |  |
| `labelRowCount` | integer (int32) | Hayir |  |
| `microAmount` | number (double) | Hayir |  |
| `microDocument` | string | Hayir | nullable |
| `microRowCount` | integer (int32) | Hayir |  |
| `netReceivedWeight` | number (double) | Hayir |  |
| `palletTare` | number (double) | Hayir |  |
| `seriesAndNumber` | string | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `supplierCode` | string | Hayir | nullable |
| `supplierName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketStockSuggestionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `modelCode` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |
| `wholesaleTaxPointer` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketSupplierSuggestionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `supplierCode` | string | Hayir | nullable |
| `supplierName` | string | Hayir | nullable |
| `supplierTaxNo` | string | Hayir | nullable |
| `supplierTitle2` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.YeniKasaAnalizleri.YeniKasaAnomalyItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `businessDate` | string (date-time) | Hayir | nullable |
| `cashRegisterNo` | string | Hayir | nullable |
| `cashierCode` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `difference` | number (double) | Hayir |  |
| `paymentTotal` | number (double) | Hayir |  |
| `receiptNumber` | string | Hayir | nullable |
| `saleTotal` | number (double) | Hayir |  |
| `severity` | string | Hayir | nullable |
| `type` | string | Hayir | nullable |
| `uuid` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.YeniKasaAnalizleri.YeniKasaCiroOzetItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `businessDate` | string (date-time) | Hayir |  |
| `cashRegisterNo` | string | Hayir | nullable |
| `cashierCode` | string | Hayir | nullable |
| `cashierName` | string | Hayir | nullable |
| `difference` | number (double) | Hayir |  |
| `firstSaleAt` | string (date-time) | Hayir | nullable |
| `lastSaleAt` | string (date-time) | Hayir | nullable |
| `paymentLineCount` | integer (int32) | Hayir |  |
| `paymentTotal` | number (double) | Hayir |  |
| `productLineCount` | integer (int32) | Hayir |  |
| `productQuantity` | number (double) | Hayir |  |
| `receiptCount` | integer (int32) | Hayir |  |
| `saleRowCount` | integer (int32) | Hayir |  |
| `saleTotal` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.YeniKasaAnalizleri.YeniKasaFisDetayDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `businessDate` | string (date-time) | Hayir | nullable |
| `cashRegisterNo` | string | Hayir | nullable |
| `cashierCode` | string | Hayir | nullable |
| `cashierName` | string | Hayir | nullable |
| `issues` | string[] | Hayir | nullable |
| `paymentTotal` | number (double) | Hayir |  |
| `payments` | FurpaMerkezApi.Application.Modules.KasaIslemleri.YeniKasaAnalizleri.YeniKasaFisOdemeSatiriDto[] | Hayir | nullable |
| `productLineTotal` | number (double) | Hayir |  |
| `productLines` | FurpaMerkezApi.Application.Modules.KasaIslemleri.YeniKasaAnalizleri.YeniKasaFisUrunSatiriDto[] | Hayir | nullable |
| `receiptNumber` | string | Hayir | nullable |
| `reconciliationItems` | FurpaMerkezApi.Application.Modules.KasaIslemleri.YeniKasaAnalizleri.YeniKasaFisMutabakatItemDto[] | Hayir | nullable |
| `saleLineDifference` | number (double) | Hayir |  |
| `salePaymentDifference` | number (double) | Hayir |  |
| `saleRows` | FurpaMerkezApi.Application.Modules.KasaIslemleri.YeniKasaAnalizleri.YeniKasaFisSatisSatiriDto[] | Hayir | nullable |
| `saleTotal` | number (double) | Hayir |  |
| `status` | string | Hayir | nullable |
| `uuid` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.YeniKasaAnalizleri.YeniKasaFisMutabakatItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `businessDate` | string (date-time) | Hayir |  |
| `cashRegisterNo` | string | Hayir | nullable |
| `cashierCode` | string | Hayir | nullable |
| `cashierName` | string | Hayir | nullable |
| `issues` | string[] | Hayir | nullable |
| `paymentLineCount` | integer (int32) | Hayir |  |
| `paymentTotal` | number (double) | Hayir |  |
| `productLineCount` | integer (int32) | Hayir |  |
| `productLineTotal` | number (double) | Hayir |  |
| `receiptNumber` | string | Hayir | nullable |
| `receivedAt` | string (date-time) | Hayir | nullable |
| `saleLineDifference` | number (double) | Hayir |  |
| `salePaymentDifference` | number (double) | Hayir |  |
| `saleRowCount` | integer (int32) | Hayir |  |
| `saleTotal` | number (double) | Hayir |  |
| `status` | string | Hayir | nullable |
| `uuid` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.YeniKasaAnalizleri.YeniKasaFisOdemeSatiriDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `category` | string | Hayir | nullable |
| `id` | integer (int32) | Hayir |  |
| `isIncludedInTotals` | boolean | Hayir |  |
| `pavoMediator` | integer (int32) | Hayir | nullable |
| `pavoType` | integer (int32) | Hayir | nullable |
| `paymentMethodCode` | string | Hayir | nullable |
| `paymentMethodId` | integer (int32) | Hayir | nullable |
| `paymentMethodName` | string | Hayir | nullable |
| `saleUuid` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.YeniKasaAnalizleri.YeniKasaFisSatisSatiriDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashRegisterNo` | string | Hayir | nullable |
| `cashierCode` | string | Hayir | nullable |
| `id` | integer (int32) | Hayir |  |
| `marketId` | string | Hayir | nullable |
| `receiptNumber` | string | Hayir | nullable |
| `receivedAt` | string (date-time) | Hayir |  |
| `remainingAmount` | number (double) | Hayir |  |
| `saleTotal` | number (double) | Hayir |  |
| `status` | string | Hayir | nullable |
| `uuid` | string | Hayir | nullable |
| `warehouseCode` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.YeniKasaAnalizleri.YeniKasaFisUrunSatiriDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `id` | integer (int32) | Hayir |  |
| `quantity` | number (double) | Hayir |  |
| `saleUuid` | string | Hayir | nullable |
| `totalPrice` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.YeniKasaAnalizleri.YeniKasaKasaOzetItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `businessDate` | string (date-time) | Hayir |  |
| `cashRegisterNo` | string | Hayir | nullable |
| `cashTotal` | number (double) | Hayir |  |
| `cashierCount` | integer (int32) | Hayir |  |
| `creditCardTotal` | number (double) | Hayir |  |
| `difference` | number (double) | Hayir |  |
| `giftCardTotal` | number (double) | Hayir |  |
| `lastSaleAt` | string (date-time) | Hayir | nullable |
| `nonCollectionPaymentTotal` | number (double) | Hayir |  |
| `otherPaymentTotal` | number (double) | Hayir |  |
| `paymentTotal` | number (double) | Hayir |  |
| `receiptCount` | integer (int32) | Hayir |  |
| `saleRowCount` | integer (int32) | Hayir |  |
| `saleTotal` | number (double) | Hayir |  |
| `unknownPaymentTotal` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.YeniKasaAnalizleri.YeniKasaPaymentMethodItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `category` | string | Hayir | nullable |
| `isKnown` | boolean | Hayir |  |
| `pavoMediator` | integer (int32) | Hayir | nullable |
| `pavoType` | integer (int32) | Hayir | nullable |
| `paymentLineCount` | integer (int32) | Hayir |  |
| `paymentMethodCode` | string | Hayir | nullable |
| `paymentMethodId` | integer (int32) | Hayir | nullable |
| `paymentMethodName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.KasaIslemleri.YeniKasaAnalizleri.YeniKasaSaglikOzetItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `businessDate` | string (date-time) | Hayir |  |
| `cashRegisterNo` | string | Hayir | nullable |
| `criticalProblemCount` | integer (int32) | Hayir |  |
| `differenceTotal` | number (double) | Hayir |  |
| `lastSaleAt` | string (date-time) | Hayir | nullable |
| `paymentTotal` | number (double) | Hayir |  |
| `problemReceiptCount` | integer (int32) | Hayir |  |
| `receiptCount` | integer (int32) | Hayir |  |
| `riskLevel` | string | Hayir | nullable |
| `saleTotal` | number (double) | Hayir |  |
| `topIssues` | string[] | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.MalKabulIslemleri.Common.EIrsaliyeLookup.InboundDespatchCustomerSuggestionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | nullable |
| `customerName` | string | Hayir | nullable |
| `isPrimarySuggestion` | boolean | Hayir |  |
| `matchReason` | string | Hayir | nullable |
| `taxNoOrTckn` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.MalKabulIslemleri.Common.EIrsaliyeLookup.InboundDespatchLineDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `buyerItemCode` | string | Hayir | nullable |
| `canUseForGoodsAcceptance` | boolean | Hayir |  |
| `description` | string | Hayir | nullable |
| `internalStockCode` | string | Hayir | nullable |
| `internalStockName` | string | Hayir | nullable |
| `isGoodsAcceptanceBlocked` | boolean | Hayir |  |
| `isMatched` | boolean | Hayir |  |
| `lineAmount` | number (double) | Hayir | nullable |
| `lineNo` | integer (int32) | Hayir | nullable |
| `manufacturerItemCode` | string | Hayir | nullable |
| `matchReason` | string | Hayir | nullable |
| `netUnitPrice` | number (double) | Hayir | nullable |
| `priceSource` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `quantitySource` | string | Hayir | nullable |
| `sellerItemCode` | string | Hayir | nullable |
| `unitCode` | string | Hayir | nullable |
| `unitPrice` | number (double) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.MalKabulIslemleri.Common.EIrsaliyeLookup.InboundDespatchLookupResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `actualDespatchDate` | string (date-time) | Hayir | nullable |
| `actualDespatchTime` | string (time) | Hayir | nullable |
| `currencyCode` | string | Hayir | nullable |
| `despatchAdviceTypeCode` | string | Hayir | nullable |
| `despatchNumber` | string | Hayir | nullable |
| `despatchReferences` | string[] | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir | nullable |
| `documentSerie` | string | Hayir | nullable |
| `driverNameSurname` | string | Hayir | nullable |
| `driverTckn` | string | Hayir | nullable |
| `ettn` | string | Hayir | nullable |
| `invoiceDate` | string (date-time) | Hayir | nullable |
| `invoiceNumber` | string | Hayir | nullable |
| `invoiceTotal` | number (double) | Hayir | nullable |
| `isFound` | boolean | Hayir |  |
| `issueDate` | string (date-time) | Hayir | nullable |
| `lines` | FurpaMerkezApi.Application.Modules.MalKabulIslemleri.Common.EIrsaliyeLookup.InboundDespatchLineDto[] | Hayir | nullable |
| `matchedLineCount` | integer (int32) | Hayir |  |
| `notes` | string[] | Hayir | nullable |
| `plaque` | string | Hayir | nullable |
| `primaryCustomerSuggestion` | FurpaMerkezApi.Application.Modules.MalKabulIslemleri.Common.EIrsaliyeLookup.InboundDespatchCustomerSuggestionDto | Hayir |  |
| `profileId` | string | Hayir | nullable |
| `receiver` | FurpaMerkezApi.Application.Modules.MalKabulIslemleri.Common.EIrsaliyeLookup.InboundDespatchPartyDto | Hayir |  |
| `receivingContext` | string | Hayir | nullable |
| `sender` | FurpaMerkezApi.Application.Modules.MalKabulIslemleri.Common.EIrsaliyeLookup.InboundDespatchPartyDto | Hayir |  |
| `sourceDocumentKind` | string | Hayir | nullable |
| `sourceDocumentLabel` | string | Hayir | nullable |
| `sourceDocumentNumber` | string | Hayir | nullable |
| `suggestedCustomers` | FurpaMerkezApi.Application.Modules.MalKabulIslemleri.Common.EIrsaliyeLookup.InboundDespatchCustomerSuggestionDto[] | Hayir | nullable |
| `taxExclusiveAmount` | number (double) | Hayir | nullable |
| `taxTotal` | number (double) | Hayir | nullable |
| `totalLineCount` | integer (int32) | Hayir |  |
| `unmatchedLineCount` | integer (int32) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |
| `warnings` | string[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.MalKabulIslemleri.Common.EIrsaliyeLookup.InboundDespatchPartyDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `alias` | string | Hayir | nullable |
| `city` | string | Hayir | nullable |
| `taxNoOrTckn` | string | Hayir | nullable |
| `title` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.MalKabulIslemleri.MalKabulFarklari.WarehouseReceivingDifferenceDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | nullable |
| `differenceQuantity` | number (double) | Hayir |  |
| `differenceType` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `isReturn` | boolean | Hayir |  |
| `lineNo` | integer (int32) | Hayir |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `movementGuid` | string (uuid) | Hayir |  |
| `productCode` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `receivedQuantity` | number (double) | Hayir |  |
| `sourceWarehouse` | string | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `targetWarehouse` | string | Hayir | nullable |
| `targetWarehouseNo` | integer (int32) | Hayir |  |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.MalKabulIslemleri.MalKabuller.Accept.AcceptWarehouseReceivingLineResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `differenceQuantity` | number (double) | Hayir |  |
| `differenceType` | string | Hayir | nullable |
| `lineNo` | integer (int32) | Hayir |  |
| `movementGuid` | string (uuid) | Hayir |  |
| `receivedQuantity` | number (double) | Hayir |  |
| `shippedQuantity` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.MalKabulIslemleri.MalKabuller.Accept.AcceptWarehouseReceivingResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `differenceResolutionStatus` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `hasDiscrepancy` | boolean | Hayir |  |
| `isReturn` | boolean | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `lines` | FurpaMerkezApi.Application.Modules.MalKabulIslemleri.MalKabuller.Accept.AcceptWarehouseReceivingLineResultDto[] | Hayir | nullable |
| `shippingState` | integer (int32) | Hayir |  |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `totalExcessQuantity` | number (double) | Hayir |  |
| `totalMissingQuantity` | number (double) | Hayir |  |
| `totalReceivedQuantity` | number (double) | Hayir |  |
| `totalShippedQuantity` | number (double) | Hayir |  |
| `transitWarehouseNo` | integer (int32) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |
| `writeConnectionName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.MalKabulIslemleri.MalKabuller.CompanyReceiving.CreateCompanyReceivingLineResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `acceptedQuantity` | number (double) | Hayir |  |
| `dispatchQuantity` | number (double) | Hayir |  |
| `isOrderLinked` | boolean | Hayir |  |
| `movementGuid` | string (uuid) | Hayir |  |
| `movementLineNo` | integer (int32) | Hayir |  |
| `orderGuid` | string (uuid) | Hayir | nullable |
| `orderLinkedQuantity` | number (double) | Hayir |  |
| `orderRemainingAfter` | number (double) | Hayir |  |
| `orderRemainingBefore` | number (double) | Hayir |  |
| `orderlessQuantity` | number (double) | Hayir |  |
| `physicalAcceptedQuantity` | number (double) | Hayir |  |
| `receivingMode` | string | Hayir | nullable |
| `requestedQuantity` | number (double) | Hayir |  |
| `returnDocumentOrderNo` | integer (int32) | Hayir | nullable |
| `returnDocumentSerie` | string | Hayir | nullable |
| `returnEDespatchStatus` | string | Hayir | nullable |
| `returnMovementGuid` | string (uuid) | Hayir | nullable |
| `returnQuantity` | number (double) | Hayir |  |
| `returnStatus` | string | Hayir | nullable |
| `sourceLineNo` | integer (int32) | Hayir |  |
| `stockCode` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.MalKabulIslemleri.MalKabuller.CompanyReceiving.CreateCompanyReceivingResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `autoCreatedReturnDocumentOrderNo` | integer (int32) | Hayir | nullable |
| `autoCreatedReturnDocumentSerie` | string | Hayir | nullable |
| `autoCreatedReturnLineCount` | integer (int32) | Hayir |  |
| `customerCode` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `lines` | FurpaMerkezApi.Application.Modules.MalKabulIslemleri.MalKabuller.CompanyReceiving.CreateCompanyReceivingLineResultDto[] | Hayir | nullable |
| `movementDate` | string (date-time) | Hayir |  |
| `returnEDespatchStatus` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `totalDispatchQuantity` | number (double) | Hayir |  |
| `totalNetAcceptedQuantity` | number (double) | Hayir |  |
| `totalOrderLinkedQuantity` | number (double) | Hayir |  |
| `totalOrderOverReceivedQuantity` | number (double) | Hayir |  |
| `totalOrderlessQuantity` | number (double) | Hayir |  |
| `totalReceivedQuantity` | number (double) | Hayir |  |
| `totalReturnedQuantity` | number (double) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |
| `writeConnectionName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.MobileSync.CustomerCatalog.MobileCustomerCatalogItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | nullable |
| `customerDisplayName` | string | Hayir | nullable |
| `customerName` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `invoiceAddressNo` | integer (int32) | Hayir | nullable |
| `isClosed` | boolean | Hayir |  |
| `isDeleted` | boolean | Hayir |  |
| `isLocked` | boolean | Hayir |  |
| `representativeCode` | string | Hayir | nullable |
| `representativeName` | string | Hayir | nullable |
| `shippingAddressNo` | integer (int32) | Hayir | nullable |
| `taxNumber` | string | Hayir | nullable |
| `updatedAt` | string (date-time) | Hayir |  |

### FurpaMerkezApi.Application.Modules.MobileSync.CustomerCatalog.MobileCustomerCatalogResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deletedCustomerCodes` | string[] | Hayir | nullable |
| `generatedAt` | string (date-time) | Hayir |  |
| `hasMore` | boolean | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.MobileSync.CustomerCatalog.MobileCustomerCatalogItemDto[] | Hayir | nullable |
| `nextCursor` | string | Hayir | nullable |
| `pageSize` | integer (int32) | Hayir |  |
| `since` | string (date-time) | Hayir | nullable |
| `syncToken` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.MobileSync.ProductPriceCatalog.MobileProductPriceCatalogItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `goodsAcceptanceBlockCode` | integer (int32) | Hayir | nullable |
| `isDeleted` | boolean | Hayir |  |
| `isGoodsAcceptanceBlocked` | boolean | Hayir |  |
| `isOrderBlocked` | boolean | Hayir |  |
| `isPassive` | boolean | Hayir |  |
| `isSalesBlocked` | boolean | Hayir |  |
| `lookupSource` | string | Hayir | nullable |
| `matchedUnitMultiplier` | number (double) | Hayir |  |
| `orderBlockCode` | integer (int32) | Hayir | nullable |
| `price` | number (double) | Hayir |  |
| `priceTypeCode` | integer (int32) | Hayir |  |
| `productManagerCode` | string | Hayir | nullable |
| `salesBlockCode` | integer (int32) | Hayir | nullable |
| `secondaryUnitMultiplier` | number (double) | Hayir |  |
| `secondaryUnitName` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitMultiplier` | number (double) | Hayir |  |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |
| `updatedAt` | string (date-time) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.MobileSync.ProductPriceCatalog.MobileProductPriceCatalogResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deletedBarcodes` | string[] | Hayir | nullable |
| `generatedAt` | string (date-time) | Hayir |  |
| `hasMore` | boolean | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.MobileSync.ProductPriceCatalog.MobileProductPriceCatalogItemDto[] | Hayir | nullable |
| `nextCursor` | string | Hayir | nullable |
| `pageSize` | integer (int32) | Hayir |  |
| `since` | string (date-time) | Hayir | nullable |
| `syncToken` | string (date-time) | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.MobileSync.WarehouseCatalog.MobileWarehouseCatalogItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `address` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir | nullable |
| `companyNo` | integer (int32) | Hayir | nullable |
| `district` | string | Hayir | nullable |
| `groupCode` | string | Hayir | nullable |
| `isDeleted` | boolean | Hayir |  |
| `isInventoryExcluded` | boolean | Hayir |  |
| `projectCode` | string | Hayir | nullable |
| `province` | string | Hayir | nullable |
| `responsibilityCenterCode` | string | Hayir | nullable |
| `updatedAt` | string (date-time) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |
| `warehouseType` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.MobileSync.WarehouseCatalog.MobileWarehouseCatalogResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deletedWarehouseNos` | integer (int32)[] | Hayir | nullable |
| `generatedAt` | string (date-time) | Hayir |  |
| `hasMore` | boolean | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.MobileSync.WarehouseCatalog.MobileWarehouseCatalogItemDto[] | Hayir | nullable |
| `nextCursor` | string | Hayir | nullable |
| `pageSize` | integer (int32) | Hayir |  |
| `since` | string (date-time) | Hayir | nullable |
| `syncToken` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.BelgeAkisTakibi.DocumentFlowDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAtUtc` | string (date-time) | Hayir |  |
| `currentStep` | string | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | string | Hayir | nullable |
| `events` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.BelgeAkisTakibi.DocumentFlowEventDto[] | Hayir | nullable |
| `externalDocumentNo` | string | Hayir | nullable |
| `externalUuid` | string | Hayir | nullable |
| `flowKey` | string | Hayir | nullable |
| `id` | string (uuid) | Hayir |  |
| `lastChangedByUserId` | string (uuid) | Hayir | nullable |
| `lastError` | string | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `status` | string | Hayir | nullable |
| `targetWarehouseNo` | integer (int32) | Hayir | nullable |
| `updatedAtUtc` | string (date-time) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.BelgeAkisTakibi.DocumentFlowEventDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `changedByUserId` | string (uuid) | Hayir | nullable |
| `error` | string | Hayir | nullable |
| `id` | string (uuid) | Hayir |  |
| `message` | string | Hayir | nullable |
| `occurredAtUtc` | string (date-time) | Hayir |  |
| `status` | string | Hayir | nullable |
| `step` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.BelgeAkisTakibi.DocumentFlowListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAtUtc` | string (date-time) | Hayir |  |
| `currentStep` | string | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | string | Hayir | nullable |
| `externalDocumentNo` | string | Hayir | nullable |
| `externalUuid` | string | Hayir | nullable |
| `id` | string (uuid) | Hayir |  |
| `lastError` | string | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `status` | string | Hayir | nullable |
| `targetWarehouseNo` | integer (int32) | Hayir | nullable |
| `updatedAtUtc` | string (date-time) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.BelgeAkisTakibi.DocumentFlowListResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `items` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.BelgeAkisTakibi.DocumentFlowListItemDto[] | Hayir | nullable |
| `totalCount` | integer (int32) | Hayir |  |
| `trackingEnabled` | boolean | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.DepoOperasyonPaneli.WarehouseOperationsDashboardDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `busiestWarehouse` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.DepoOperasyonPaneli.WarehouseOperationsDashboardHighlightDto | Hayir |  |
| `date` | string (date) | Hayir |  |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `slowestWarehouse` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.DepoOperasyonPaneli.WarehouseOperationsDashboardHighlightDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.DepoOperasyonPaneli.WarehouseOperationsDashboardSummaryDto | Hayir |  |
| `trackingEnabled` | boolean | Hayir |  |
| `warehouses` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.DepoOperasyonPaneli.WarehouseOperationsDashboardItemDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.DepoOperasyonPaneli.WarehouseOperationsDashboardHighlightDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `value` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.DepoOperasyonPaneli.WarehouseOperationsDashboardItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `averageReceivingMinutes` | number (double) | Hayir | nullable |
| `failedEDespatchCount` | integer (int32) | Hayir |  |
| `healthStatus` | string | Hayir | nullable |
| `incompleteOperationCount` | integer (int32) | Hayir |  |
| `pendingReceivingCount` | integer (int32) | Hayir |  |
| `todayReceivingCount` | integer (int32) | Hayir |  |
| `todayReturnCount` | integer (int32) | Hayir |  |
| `todayShipmentCount` | integer (int32) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.DepoOperasyonPaneli.WarehouseOperationsDashboardSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `failedEDespatchCount` | integer (int32) | Hayir |  |
| `incompleteOperationCount` | integer (int32) | Hayir |  |
| `pendingReceivingCount` | integer (int32) | Hayir |  |
| `todayReceivingCount` | integer (int32) | Hayir |  |
| `todayReturnCount` | integer (int32) | Hayir |  |
| `todayShipmentCount` | integer (int32) | Hayir |  |
| `warehouseCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.FirmaEvrakTakibi.CompanyDocumentTrackingDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `companyReceivingCount` | integer (int32) | Hayir |  |
| `companyReturnCount` | integer (int32) | Hayir |  |
| `date` | string (date) | Hayir |  |
| `documentCount` | integer (int32) | Hayir |  |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.FirmaEvrakTakibi.CompanyDocumentTrackingItemDto[] | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.FirmaEvrakTakibi.CompanyDocumentTrackingItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | nullable |
| `customerDisplayName` | string | Hayir | nullable |
| `customerName` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `deliverer` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentKind` | string | Hayir | nullable |
| `documentKindName` | string | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `movementCreateDate` | string (date-time) | Hayir |  |
| `receiver` | string | Hayir | nullable |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.Operations.AuthorizationFileDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `id` | integer (int32) | Hayir |  |
| `name` | string | Hayir | nullable |
| `r` | boolean | Hayir |  |
| `updateDate` | string (date-time) | Hayir |  |
| `x` | boolean | Hayir |  |
| `z` | boolean | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.Operations.GeneratedOperationFileDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `fileName` | string | Hayir | nullable |
| `localPath` | string | Hayir | nullable |
| `networkPath` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.Operations.OperationJobDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `completedAtUtc` | string (date-time) | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `errorMessage` | string | Hayir | nullable |
| `files` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.Operations.GeneratedOperationFileDto[] | Hayir | nullable |
| `jobId` | string (uuid) | Hayir |  |
| `message` | string | Hayir | nullable |
| `operation` | string | Hayir | nullable |
| `requestedByUserId` | string (uuid) | Hayir |  |
| `startedAtUtc` | string (date-time) | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.Operations.OperationJobDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAtUtc` | string (date-time) | Hayir |  |
| `jobId` | string (uuid) | Hayir |  |
| `operation` | string | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionActionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `enabled` | boolean | Hayir |  |
| `label` | string | Hayir | nullable |
| `reason` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionBalanceDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `lines` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionBalanceLineDto[] | Hayir | nullable |
| `stock` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionStockDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionSummaryDto | Hayir |  |
| `warnings` | string[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionBalanceLineDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchAverageDailySales` | number (double) | Hayir |  |
| `caseDelta` | integer (int32) | Hayir |  |
| `caseQuantity` | integer (int32) | Hayir |  |
| `caseSharePercent` | number (double) | Hayir |  |
| `caseUnitName` | string | Hayir | nullable |
| `companyAverageDailySales` | number (double) | Hayir |  |
| `currentStockQuantity` | number (double) | Hayir |  |
| `isLocked` | boolean | Hayir |  |
| `lastSalesQuantity` | number (double) | Hayir |  |
| `originalCaseQuantity` | integer (int32) | Hayir |  |
| `quantityUnitName` | string | Hayir | nullable |
| `reason` | string | Hayir | nullable |
| `regionCode` | string | Hayir | nullable |
| `regionName` | string | Hayir | nullable |
| `salesSharePercent` | number (double) | Hayir |  |
| `unitQuantity` | integer (int32) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionCenterDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `regionCode` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionDeleteDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deleted` | boolean | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `message` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `availableActions` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionActionDto[] | Hayir | nullable |
| `header` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionHeaderDto | Hayir |  |
| `lines` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionLineDto[] | Hayir | nullable |
| `summary` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionSummaryDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionFinalizeDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdDocumentCount` | integer (int32) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `existingDocumentCount` | integer (int32) | Hayir |  |
| `finalizedAt` | string (date-time) | Hayir |  |
| `orders` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionWarehouseOrderDto[] | Hayir | nullable |
| `status` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionStatusDto | Hayir |  |
| `totalUnitQuantity` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionHeaderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAt` | string (date-time) | Hayir |  |
| `distributedBy` | string | Hayir | nullable |
| `distributionCenter` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionWarehouseDto | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `finalizedAt` | string (date-time) | Hayir | nullable |
| `status` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionStatusDto | Hayir |  |
| `stock` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionStockDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionLineDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchAverageDailySales` | number (double) | Hayir |  |
| `caseQuantity` | integer (int32) | Hayir |  |
| `caseSharePercent` | number (double) | Hayir |  |
| `caseUnitName` | string | Hayir | nullable |
| `companyAverageDailySales` | number (double) | Hayir |  |
| `currentStockQuantity` | number (double) | Hayir |  |
| `lastSalesQuantity` | number (double) | Hayir |  |
| `quantityUnitName` | string | Hayir | nullable |
| `reason` | string | Hayir | nullable |
| `regionCode` | string | Hayir | nullable |
| `regionName` | string | Hayir | nullable |
| `salesSharePercent` | number (double) | Hayir |  |
| `unitQuantity` | integer (int32) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAt` | string (date-time) | Hayir |  |
| `distributedBy` | string | Hayir | nullable |
| `distributionCenter` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionWarehouseDto | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `finalizedAt` | string (date-time) | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `status` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionStatusDto | Hayir |  |
| `stock` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionStockDto | Hayir |  |
| `totalCaseQuantity` | integer (int32) | Hayir |  |
| `totalUnitQuantity` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionNotificationDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentNo` | string | Hayir | nullable |
| `failedEmailCount` | integer (int32) | Hayir |  |
| `mailResults` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionNotificationMailResultDto[] | Hayir | nullable |
| `mailSendingEnabled` | boolean | Hayir |  |
| `message` | string | Hayir | nullable |
| `recipients` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionNotificationRecipientDto[] | Hayir | nullable |
| `sentEmailCount` | integer (int32) | Hayir |  |
| `status` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionStatusDto | Hayir |  |
| `statusChanged` | boolean | Hayir |  |
| `stockOrderingStopped` | boolean | Hayir |  |
| `subject` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionNotificationMailResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `email` | string | Hayir | nullable |
| `managerName` | string | Hayir | nullable |
| `message` | string | Hayir | nullable |
| `regionCode` | string | Hayir | nullable |
| `sent` | boolean | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionNotificationRecipientDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `email` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `managerName` | string | Hayir | nullable |
| `regionCode` | string | Hayir | nullable |
| `totalCaseQuantity` | integer (int32) | Hayir |  |
| `totalUnitQuantity` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionProposalDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `distributionCenter` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionWarehouseDto | Hayir |  |
| `lines` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionLineDto[] | Hayir | nullable |
| `stock` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionStockDto | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionSummaryDto | Hayir |  |
| `warnings` | string[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionStatusDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | integer (int32) | Hayir |  |
| `name` | string | Hayir | nullable |
| `severity` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionStockDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `packageFactor` | integer (int32) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `allocatedCaseQuantity` | integer (int32) | Hayir |  |
| `caseDifference` | integer (int32) | Hayir |  |
| `isBalanced` | boolean | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `message` | string | Hayir | nullable |
| `referenceDate` | string (date-time) | Hayir |  |
| `salesDayCount` | integer (int32) | Hayir |  |
| `totalCaseQuantity` | integer (int32) | Hayir |  |
| `totalUnitQuantity` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionWarehouseDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `regionCode` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OperasyonIslemleri.UrunDagilimlari.ProductDistributionWarehouseOrderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `alreadyExisted` | boolean | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `inWarehouseName` | string | Hayir | nullable |
| `inWarehouseNo` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `outWarehouseName` | string | Hayir | nullable |
| `outWarehouseNo` | integer (int32) | Hayir |  |
| `totalUnitQuantity` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OrtakIslemler.Duyurular.AnnouncementDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `archivedAtUtc` | string (date-time) | Hayir | nullable |
| `archivedByUserId` | string (uuid) | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `createdByFullName` | string | Hayir | nullable |
| `createdByUserId` | string (uuid) | Hayir |  |
| `createdByUsername` | string | Hayir | nullable |
| `expiresAtUtc` | string (date-time) | Hayir | nullable |
| `id` | string (uuid) | Hayir |  |
| `message` | string | Hayir | nullable |
| `priority` | string | Hayir | nullable |
| `priorityName` | string | Hayir | nullable |
| `publishedAtUtc` | string (date-time) | Hayir |  |
| `readAtUtc` | string (date-time) | Hayir | nullable |
| `readReceipts` | FurpaMerkezApi.Application.Modules.OrtakIslemler.Duyurular.AnnouncementReadReceiptDto[] | Hayir | nullable |
| `readSummary` | FurpaMerkezApi.Application.Modules.OrtakIslemler.Duyurular.AnnouncementReadSummaryDto | Hayir |  |
| `startsAtUtc` | string (date-time) | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `statusName` | string | Hayir | nullable |
| `targets` | FurpaMerkezApi.Application.Modules.OrtakIslemler.Duyurular.AnnouncementTargetDto[] | Hayir | nullable |
| `title` | string | Hayir | nullable |
| `updatedAtUtc` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OrtakIslemler.Duyurular.AnnouncementReadReceiptDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `email` | string | Hayir | nullable |
| `readAtUtc` | string (date-time) | Hayir |  |
| `userFullName` | string | Hayir | nullable |
| `userId` | string (uuid) | Hayir |  |
| `username` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OrtakIslemler.Duyurular.AnnouncementReadReceiptListDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `announcementId` | string (uuid) | Hayir |  |
| `readers` | FurpaMerkezApi.Application.Modules.OrtakIslemler.Duyurular.AnnouncementReadReceiptDto[] | Hayir | nullable |
| `summary` | FurpaMerkezApi.Application.Modules.OrtakIslemler.Duyurular.AnnouncementReadSummaryDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.OrtakIslemler.Duyurular.AnnouncementReadSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `lastReadAtUtc` | string (date-time) | Hayir | nullable |
| `readCount` | integer (int32) | Hayir |  |
| `targetUserCount` | integer (int32) | Hayir | nullable |
| `unreadCount` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OrtakIslemler.Duyurular.AnnouncementSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `activeCount` | integer (int32) | Hayir |  |
| `latestAnnouncementId` | string (uuid) | Hayir | nullable |
| `latestPublishedAtUtc` | string (date-time) | Hayir | nullable |
| `unreadCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OrtakIslemler.Duyurular.AnnouncementTargetDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `id` | string (uuid) | Hayir |  |
| `type` | string | Hayir | nullable |
| `typeName` | string | Hayir | nullable |
| `userFullName` | string | Hayir | nullable |
| `userId` | string (uuid) | Hayir | nullable |
| `username` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OrtakIslemler.Duyurular.AnnouncementTargetUserDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `displayName` | string | Hayir | nullable |
| `email` | string | Hayir | nullable |
| `fullName` | string | Hayir | nullable |
| `id` | string (uuid) | Hayir |  |
| `username` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.OrtakIslemler.SikayetOneri.FeedbackItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `adminNote` | string | Hayir | nullable |
| `closedAtUtc` | string (date-time) | Hayir | nullable |
| `createdAtUtc` | string (date-time) | Hayir |  |
| `createdByFullName` | string | Hayir | nullable |
| `createdByUserId` | string (uuid) | Hayir |  |
| `createdByUsername` | string | Hayir | nullable |
| `id` | string (uuid) | Hayir |  |
| `message` | string | Hayir | nullable |
| `priority` | string | Hayir | nullable |
| `priorityName` | string | Hayir | nullable |
| `readAtUtc` | string (date-time) | Hayir | nullable |
| `readByUserId` | string (uuid) | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `statusChangedAtUtc` | string (date-time) | Hayir | nullable |
| `statusChangedByUserId` | string (uuid) | Hayir | nullable |
| `statusName` | string | Hayir | nullable |
| `title` | string | Hayir | nullable |
| `type` | string | Hayir | nullable |
| `typeName` | string | Hayir | nullable |
| `updatedAtUtc` | string (date-time) | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.OrtakIslemler.SikayetOneri.FeedbackSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `latestCreatedAtUtc` | string (date-time) | Hayir | nullable |
| `latestStatus` | string | Hayir | nullable |
| `myOpenCount` | integer (int32) | Hayir |  |
| `myResolvedCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.PromosyonRaporlari.PromotionBranchPerformanceItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `discountAmount` | number (double) | Hayir |  |
| `estimatedCostAmount` | number (double) | Hayir |  |
| `grossSalesAmount` | number (double) | Hayir |  |
| `marginAmount` | number (double) | Hayir |  |
| `marginPercent` | number (double) | Hayir |  |
| `netSalesAmount` | number (double) | Hayir |  |
| `promotionCode` | string | Hayir | nullable |
| `promotionName` | string | Hayir | nullable |
| `promotionType` | string | Hayir | nullable |
| `receiptCount` | integer (int32) | Hayir |  |
| `soldQuantity` | number (double) | Hayir |  |
| `usageCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.PromosyonRaporlari.PromotionBulletinListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNos` | integer (int32)[] | Hayir | nullable |
| `customerCode` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `discountAmount` | number (double) | Hayir | nullable |
| `discountRate` | number (double) | Hayir | nullable |
| `endDate` | string (date-time) | Hayir | nullable |
| `isActive` | boolean | Hayir |  |
| `isPassive` | boolean | Hayir |  |
| `limitAmount` | number (double) | Hayir | nullable |
| `pluNo` | integer (int32) | Hayir | nullable |
| `productPluNo` | integer (int32) | Hayir | nullable |
| `promotionCode` | string | Hayir | nullable |
| `promotionName` | string | Hayir | nullable |
| `promotionType` | string | Hayir | nullable |
| `startDate` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.PromosyonRaporlari.PromotionBulletinOptionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `endDate` | string (date-time) | Hayir | nullable |
| `isActive` | boolean | Hayir |  |
| `promotionCode` | string | Hayir | nullable |
| `promotionName` | string | Hayir | nullable |
| `promotionType` | string | Hayir | nullable |
| `startDate` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.PromosyonRaporlari.PromotionPerformanceItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | nullable |
| `discountAmount` | number (double) | Hayir |  |
| `discountToGrossSalesPercent` | number (double) | Hayir |  |
| `estimatedCostAmount` | number (double) | Hayir |  |
| `firstSaleDate` | string (date-time) | Hayir | nullable |
| `grossSalesAmount` | number (double) | Hayir |  |
| `lastSaleDate` | string (date-time) | Hayir | nullable |
| `marginAmount` | number (double) | Hayir |  |
| `marginPercent` | number (double) | Hayir |  |
| `netSalesAmount` | number (double) | Hayir |  |
| `promotionCode` | string | Hayir | nullable |
| `promotionName` | string | Hayir | nullable |
| `promotionType` | string | Hayir | nullable |
| `receiptCount` | integer (int32) | Hayir |  |
| `soldQuantity` | number (double) | Hayir |  |
| `usageCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.PromosyonRaporlari.PromotionPerformanceReportDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `discountAmount` | number (double) | Hayir |  |
| `endDate` | string (date-time) | Hayir |  |
| `estimatedCostAmount` | number (double) | Hayir |  |
| `grossSalesAmount` | number (double) | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.RaporIslemleri.PromosyonRaporlari.PromotionPerformanceItemDto[] | Hayir | nullable |
| `marginAmount` | number (double) | Hayir |  |
| `marginPercent` | number (double) | Hayir |  |
| `netSalesAmount` | number (double) | Hayir |  |
| `promotionCount` | integer (int32) | Hayir |  |
| `receiptCount` | integer (int32) | Hayir |  |
| `soldQuantity` | number (double) | Hayir |  |
| `startDate` | string (date-time) | Hayir |  |
| `usageCount` | integer (int32) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.BankMovementAnalysisItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `bank` | string | Hayir | nullable |
| `bankAmount` | number (double) | Hayir |  |
| `bankingNumber` | integer (int32) | Hayir |  |
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `cashRegisterNo` | string | Hayir | nullable |
| `date` | string (date-time) | Hayir |  |
| `terminalId` | string | Hayir | nullable |
| `zNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.BankPaymentSummaryItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `bank` | string | Hayir | nullable |
| `slipNumber` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.BankPaymentSummaryReportDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `items` | FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.BankPaymentSummaryItemDto[] | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `totalSlipNumber` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.BranchBankMovementSummaryItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `bank` | string | Hayir | nullable |
| `bankAmount` | number (double) | Hayir |  |
| `bankingNumber` | integer (int32) | Hayir |  |
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.DiscountCardDetailItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `cardNumber` | string | Hayir | nullable |
| `usageCount` | integer (int32) | Hayir |  |
| `usageTotal` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.FoodCheckReportDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `items` | FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.FoodCheckReportItemDto[] | Hayir | nullable |
| `totals` | FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.FoodCheckTotalsDto | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.FoodCheckReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `metropol` | number (double) | Hayir |  |
| `multinet` | number (double) | Hayir |  |
| `setcard` | number (double) | Hayir |  |
| `sodexoKupon` | number (double) | Hayir |  |
| `sodexoPos` | number (double) | Hayir |  |
| `ticketKupon` | number (double) | Hayir |  |
| `ticketPos` | number (double) | Hayir |  |
| `total` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.FoodCheckTotalsDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `metropol` | number (double) | Hayir |  |
| `multinet` | number (double) | Hayir |  |
| `setcard` | number (double) | Hayir |  |
| `sodexoKupon` | number (double) | Hayir |  |
| `sodexoPos` | number (double) | Hayir |  |
| `ticketKupon` | number (double) | Hayir |  |
| `ticketPos` | number (double) | Hayir |  |
| `total` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.MerchantPaymentSummaryItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `bank` | string | Hayir | nullable |
| `merchantNo` | string | Hayir | nullable |
| `slipNumber` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.MerchantPaymentSummaryReportDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `items` | FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.MerchantPaymentSummaryItemDto[] | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `totalSlipNumber` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.MissingTurnoverBranchItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `region` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.MyoSalesByBranchItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `documentDate` | string (date-time) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.MyoSalesReportDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amountTotal` | number (double) | Hayir |  |
| `doorCashTotal` | number (double) | Hayir |  |
| `doorCreditCardTotal` | number (double) | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.MyoSalesReportItemDto[] | Hayir | nullable |
| `netAmountTotal` | number (double) | Hayir |  |
| `totalTaxTotal` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.MyoSalesReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `customerCode` | string | Hayir | nullable |
| `description1` | string | Hayir | nullable |
| `description2` | string | Hayir | nullable |
| `discountTotal` | number (double) | Hayir |  |
| `documentDate` | string (date-time) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `invoiceGuid` | string (uuid) | Hayir | nullable |
| `netAmount` | number (double) | Hayir |  |
| `paymentDescription` | string | Hayir | nullable |
| `subTotal` | number (double) | Hayir |  |
| `totalTax` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.SalesAnalysisAmountDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `code` | string | Hayir | nullable |
| `name` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.ValorPaymentSummaryItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `bank` | string | Hayir | nullable |
| `slipNumber` | integer (int32) | Hayir |  |
| `valorDay` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.ValorPaymentSummaryReportDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `items` | FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.ValorPaymentSummaryItemDto[] | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `totalSlipNumber` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.SatisAnalizleri.ZReportBankAnalysisItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `bank` | string | Hayir | nullable |
| `bankAmount` | number (double) | Hayir |  |
| `bankingNumber` | integer (int32) | Hayir |  |
| `branchName` | string | Hayir | nullable |
| `branchNo` | integer (int32) | Hayir |  |
| `cashRegisterNo` | string | Hayir | nullable |
| `date` | string (date-time) | Hayir |  |
| `merchantNo` | string | Hayir | nullable |
| `terminalId` | string | Hayir | nullable |
| `zNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.BranchSalesReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `barcode` | string | Hayir | nullable |
| `currentStock` | number (double) | Hayir |  |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `taxAmount` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.CountingComparisonReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `countDate` | string (date-time) | Hayir |  |
| `countQuantity` | number (double) | Hayir |  |
| `differenceQuantity` | number (double) | Hayir |  |
| `differenceSalesValue` | number (double) | Hayir |  |
| `documentNo` | integer (int32) | Hayir |  |
| `salesPrice` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `systemQuantity` | number (double) | Hayir |  |
| `unitName` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.MovementInOutComparisonDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `categoryCode` | string | Hayir | nullable |
| `netQuantity` | number (double) | Hayir |  |
| `producerCode` | string | Hayir | nullable |
| `productManagerCode` | string | Hayir | nullable |
| `productManagerName` | string | Hayir | nullable |
| `purchaseAmount` | number (double) | Hayir |  |
| `purchaseQuantity` | number (double) | Hayir |  |
| `returnAmount` | number (double) | Hayir |  |
| `returnQuantity` | number (double) | Hayir |  |
| `salesAmount` | number (double) | Hayir |  |
| `salesQuantity` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `supplierCode` | string | Hayir | nullable |
| `supplierName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.NotSoldProductReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `currentStock` | number (double) | Hayir |  |
| `lastSaleDate` | string (date-time) | Hayir | nullable |
| `productManagerCode` | string | Hayir | nullable |
| `productManagerName` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `supplierCode` | string | Hayir | nullable |
| `supplierName` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.ProductShipmentDistributionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentCount` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `shipmentDate` | string (date-time) | Hayir |  |
| `sourceWarehouseName` | string | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `targetWarehouseName` | string | Hayir | nullable |
| `targetWarehouseNo` | integer (int32) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `unitName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.ProductWarehouseStockDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `goodsAcceptanceBlockCode` | integer (int32) | Hayir | nullable |
| `isPassive` | boolean | Hayir |  |
| `orderBlockCode` | integer (int32) | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `salesBlockCode` | integer (int32) | Hayir | nullable |
| `salesPrice` | number (double) | Hayir |  |
| `salesValue` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.ProfitabilityReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `costAmount` | number (double) | Hayir |  |
| `groupCode` | string | Hayir | nullable |
| `groupName` | string | Hayir | nullable |
| `profitAmount` | number (double) | Hayir |  |
| `profitPercent` | number (double) | Hayir |  |
| `salesAmount` | number (double) | Hayir |  |
| `salesQuantity` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.ReturnBranchReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `customerCode` | string | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `returnDate` | string (date-time) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.StockCardDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `brandCode` | string | Hayir | nullable |
| `categoryCode` | string | Hayir | nullable |
| `goodsAcceptanceBlockCode` | integer (int32) | Hayir | nullable |
| `isDeleted` | boolean | Hayir |  |
| `isPassive` | boolean | Hayir |  |
| `modelCode` | string | Hayir | nullable |
| `orderBlockCode` | integer (int32) | Hayir | nullable |
| `producerCode` | string | Hayir | nullable |
| `productManagerCode` | string | Hayir | nullable |
| `productManagerName` | string | Hayir | nullable |
| `rayonCode` | string | Hayir | nullable |
| `salesBlockCode` | integer (int32) | Hayir | nullable |
| `salesPrice` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `supplierCode` | string | Hayir | nullable |
| `supplierName` | string | Hayir | nullable |
| `unit1Multiplier` | number (double) | Hayir |  |
| `unit1Name` | string | Hayir | nullable |
| `unit2Multiplier` | number (double) | Hayir |  |
| `unit2Name` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.StockCategoryOptionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `categoryCode` | string | Hayir | nullable |
| `categoryName` | string | Hayir | nullable |
| `productCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.StockMovementReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `customerCode` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | integer (int32) | Hayir |  |
| `inputWarehouseName` | string | Hayir | nullable |
| `inputWarehouseNo` | integer (int32) | Hayir | nullable |
| `movementDate` | string (date-time) | Hayir |  |
| `movementGuid` | string (uuid) | Hayir |  |
| `movementKind` | integer (int32) | Hayir |  |
| `movementType` | integer (int32) | Hayir |  |
| `normalReturn` | integer (int32) | Hayir |  |
| `outputWarehouseName` | string | Hayir | nullable |
| `outputWarehouseNo` | integer (int32) | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.StockOnHandReportDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `items` | FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.StockOnHandReportItemDto[] | Hayir | nullable |
| `reportDate` | string (date-time) | Hayir |  |
| `returnedCount` | integer (int32) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `totalSalesValue` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.StockOnHandReportItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `categoryCode` | string | Hayir | nullable |
| `goodsAcceptanceBlockCode` | integer (int32) | Hayir | nullable |
| `isPassive` | boolean | Hayir |  |
| `modelCode` | string | Hayir | nullable |
| `orderBlockCode` | integer (int32) | Hayir | nullable |
| `producerCode` | string | Hayir | nullable |
| `productManagerCode` | string | Hayir | nullable |
| `productManagerName` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `rayonCode` | string | Hayir | nullable |
| `salesBlockCode` | integer (int32) | Hayir | nullable |
| `salesPrice` | number (double) | Hayir |  |
| `salesValue` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `supplierCode` | string | Hayir | nullable |
| `supplierName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.WarehouseMissingStockDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `modelCode` | string | Hayir | nullable |
| `productManagerCode` | string | Hayir | nullable |
| `productManagerName` | string | Hayir | nullable |
| `salesPrice` | number (double) | Hayir |  |
| `sourceQuantity` | number (double) | Hayir |  |
| `sourceWarehouseName` | string | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `supplierCode` | string | Hayir | nullable |
| `supplierName` | string | Hayir | nullable |
| `targetQuantity` | number (double) | Hayir |  |
| `targetWarehouseName` | string | Hayir | nullable |
| `targetWarehouseNo` | integer (int32) | Hayir |  |
| `unitName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.WarehouseZeroStockDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `modelCode` | string | Hayir | nullable |
| `productManagerCode` | string | Hayir | nullable |
| `productManagerName` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `salesPrice` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `supplierCode` | string | Hayir | nullable |
| `supplierName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.StokRaporlari.YearSalesComparisonItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amountChangePercent` | number (double) | Hayir |  |
| `amountDifference` | number (double) | Hayir |  |
| `barcode` | string | Hayir | nullable |
| `currentAmount` | number (double) | Hayir |  |
| `currentQuantity` | number (double) | Hayir |  |
| `previousAmount` | number (double) | Hayir |  |
| `previousQuantity` | number (double) | Hayir |  |
| `quantityChangePercent` | number (double) | Hayir |  |
| `quantityDifference` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierInvoicePerformanceDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `incomingInvoiceAmount` | number (double) | Hayir |  |
| `incomingInvoiceCount` | integer (int32) | Hayir |  |
| `issuedInvoiceAmount` | number (double) | Hayir |  |
| `issuedInvoiceCount` | integer (int32) | Hayir |  |
| `note` | string | Hayir | nullable |
| `state` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierOrderPerformanceDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `averageLateDays` | number (double) | Hayir |  |
| `deliveredQuantity` | number (double) | Hayir |  |
| `deliveryRate` | number (double) | Hayir |  |
| `documentCount` | integer (int32) | Hayir |  |
| `lateDeliveredLineCount` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `openLateLineCount` | integer (int32) | Hayir |  |
| `orderedQuantity` | number (double) | Hayir |  |
| `remainingQuantity` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierOutageImpactDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `attribution` | string | Hayir | nullable |
| `documentCount` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `quantity` | number (double) | Hayir |  |
| `quantityRate` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceCardDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `grade` | string | Hayir | nullable |
| `invoices` | FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierInvoicePerformanceDto | Hayir |  |
| `orders` | FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierOrderPerformanceDto | Hayir |  |
| `outageImpact` | FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierOutageImpactDto | Hayir |  |
| `receiving` | FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierReceivingPerformanceDto | Hayir |  |
| `returns` | FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierReturnPerformanceDto | Hayir |  |
| `riskLevel` | string | Hayir | nullable |
| `score` | number (double) | Hayir |  |
| `scoreBreakdown` | FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceScoreBreakdownDto | Hayir |  |
| `signals` | FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceSignalDto[] | Hayir | nullable |
| `taxNoOrTckn` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `card` | FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceCardDto | Hayir |  |
| `events` | FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceEventDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceEventDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir |  |
| `description` | string | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `eventDate` | string (date-time) | Hayir | nullable |
| `eventType` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `relatedQuantity` | number (double) | Hayir |  |
| `source` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceInsightDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `customerCode` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `severity` | string | Hayir | nullable |
| `title` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceReportDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `endDate` | string (date-time) | Hayir |  |
| `generatedAtUtc` | string (date-time) | Hayir |  |
| `insights` | FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceInsightDto[] | Hayir | nullable |
| `items` | FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceCardDto[] | Hayir | nullable |
| `startDate` | string (date-time) | Hayir |  |
| `summary` | FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceSummaryDto | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceScoreBreakdownDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deliveryPenalty` | number (double) | Hayir |  |
| `differencePenalty` | number (double) | Hayir |  |
| `invoicePenalty` | number (double) | Hayir |  |
| `outagePenalty` | number (double) | Hayir |  |
| `returnPenalty` | number (double) | Hayir |  |
| `totalPenalty` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceSignalDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `severity` | string | Hayir | nullable |
| `title` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierPerformanceSummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `averageScore` | number (double) | Hayir |  |
| `criticalSupplierCount` | integer (int32) | Hayir |  |
| `headline` | string | Hayir | nullable |
| `invoiceMetricsState` | string | Hayir | nullable |
| `overallStatus` | string | Hayir | nullable |
| `returnedSupplierCount` | integer (int32) | Hayir |  |
| `supplierCount` | integer (int32) | Hayir |  |
| `totalExcessQuantity` | number (double) | Hayir |  |
| `totalIncomingInvoiceAmount` | number (double) | Hayir |  |
| `totalIssuedInvoiceAmount` | number (double) | Hayir |  |
| `totalMissingQuantity` | number (double) | Hayir |  |
| `totalOrderedQuantity` | number (double) | Hayir |  |
| `totalOutageImpactQuantity` | number (double) | Hayir |  |
| `totalReceivedQuantity` | number (double) | Hayir |  |
| `totalReturnedQuantity` | number (double) | Hayir |  |
| `warningSupplierCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierReceivingPerformanceDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `differenceLineCount` | integer (int32) | Hayir |  |
| `differenceRate` | number (double) | Hayir |  |
| `documentCount` | integer (int32) | Hayir |  |
| `excessQuantity` | number (double) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `missingQuantity` | number (double) | Hayir |  |
| `receivedAmount` | number (double) | Hayir |  |
| `receivedQuantity` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.RaporIslemleri.TedarikciPerformansKarnesi.SupplierReturnPerformanceDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentCount` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `returnRate` | number (double) | Hayir |  |
| `returnedAmount` | number (double) | Hayir |  |
| `returnedQuantity` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.SevkIslemleri.Common.DeleteWarehouseShippingDocumentResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deletedAt` | string (date-time) | Hayir |  |
| `deletedLineCount` | integer (int32) | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `targetWarehouseNo` | integer (int32) | Hayir |  |
| `updateUser` | integer (int32) | Hayir |  |
| `writeConnectionName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.SevkIslemleri.Common.UpdateWarehouseShippingDocumentResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `addedLineCount` | integer (int32) | Hayir |  |
| `deletedLineCount` | integer (int32) | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `isReturn` | boolean | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `targetWarehouseNo` | integer (int32) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `transitWarehouseNo` | integer (int32) | Hayir |  |
| `updateUser` | integer (int32) | Hayir |  |
| `updatedAt` | string (date-time) | Hayir |  |
| `updatedLineCount` | integer (int32) | Hayir |  |
| `writeConnectionName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.SevkIslemleri.Common.WarehouseShippingDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.SevkIslemleri.Common.WarehouseShippingHeaderDto | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.SevkIslemleri.Common.WarehouseShippingLineItemDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.SevkIslemleri.Common.WarehouseShippingHeaderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `descriptionEttn` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `driverNameSurname` | string | Hayir | nullable |
| `driverTckn` | string | Hayir | nullable |
| `isReturn` | boolean | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `plaque` | string | Hayir | nullable |
| `shippingState` | integer (int32) | Hayir |  |
| `shippingWarehouseNo` | integer (int32) | Hayir |  |
| `sourceWarehouse` | string | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `targetWarehouse` | string | Hayir | nullable |
| `targetWarehouseNo` | integer (int32) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseOrderNo` | string | Hayir | nullable |
| `warehouseOrderNos` | string[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.SevkIslemleri.Common.WarehouseShippingLineItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | nullable |
| `lineAmount` | number (double) | Hayir |  |
| `lineNo` | integer (int32) | Hayir |  |
| `lotNo` | integer (int32) | Hayir |  |
| `movementGuid` | string (uuid) | Hayir |  |
| `partyCode` | string | Hayir | nullable |
| `projectCode` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |
| `unitPrice` | number (double) | Hayir |  |
| `warehouseOrderNo` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.SevkIslemleri.Common.WarehouseShippingListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `descriptionEttn` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `driverNameSurname` | string | Hayir | nullable |
| `driverTckn` | string | Hayir | nullable |
| `isReturn` | boolean | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `plaque` | string | Hayir | nullable |
| `shippingState` | integer (int32) | Hayir |  |
| `shippingWarehouseNo` | integer (int32) | Hayir |  |
| `sourceWarehouse` | string | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `targetWarehouse` | string | Hayir | nullable |
| `targetWarehouseNo` | integer (int32) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseOrderNo` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.SevkIslemleri.DepolarArasiSevkler.Create.CreateInterWarehouseShipmentResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentDate` | string (date-time) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `linkedWarehouseOrderLineCount` | integer (int32) | Hayir |  |
| `movementDate` | string (date-time) | Hayir |  |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `targetWarehouseNo` | integer (int32) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `transitWarehouseNo` | integer (int32) | Hayir |  |
| `writeConnectionName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.CompanyOrderDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.CompanyOrderHeaderDto | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.CompanyOrderLineItemDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.CompanyOrderHeaderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `canBeCalled` | boolean | Hayir |  |
| `customerAddress` | string | Hayir | nullable |
| `customerCode` | string | Hayir | nullable |
| `customerDisplayName` | string | Hayir | nullable |
| `customerName` | string | Hayir | nullable |
| `customerRepresentativeCode` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `deliverer` | string | Hayir | nullable |
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `description1` | string | Hayir | nullable |
| `description2` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir |  |
| `documentKey` | string | Hayir | nullable |
| `documentNumber` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `isClosed` | boolean | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `receiver` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `totalDeliveredQuantity` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `totalRemainingQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.CompanyOrderLineItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deliveredQuantity` | number (double) | Hayir |  |
| `description` | string | Hayir | nullable |
| `isClosed` | boolean | Hayir |  |
| `lineAmount` | number (double) | Hayir |  |
| `lineNo` | integer (int32) | Hayir |  |
| `orderGuid` | string (uuid) | Hayir |  |
| `packageCode` | string | Hayir | nullable |
| `projectCode` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `remainingQuantity` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |
| `unitPrice` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.CompanyOrderListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `canBeCalled` | boolean | Hayir |  |
| `customerAddress` | string | Hayir | nullable |
| `customerCode` | string | Hayir | nullable |
| `customerDisplayName` | string | Hayir | nullable |
| `customerName` | string | Hayir | nullable |
| `customerRepresentativeCode` | string | Hayir | nullable |
| `customerTitle` | string | Hayir | nullable |
| `deliverer` | string | Hayir | nullable |
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `description1` | string | Hayir | nullable |
| `description2` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir |  |
| `documentKey` | string | Hayir | nullable |
| `documentNumber` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `isClosed` | boolean | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `receiver` | string | Hayir | nullable |
| `totalAmount` | number (double) | Hayir |  |
| `totalDeliveredQuantity` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `totalRemainingQuantity` | number (double) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.SuggestedCompanyOrderListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `deliveryDay` | integer (int32) | Hayir | nullable |
| `maxDay` | number (double) | Hayir |  |
| `minDay` | number (double) | Hayir |  |
| `minimumPurchaseQuantity` | number (double) | Hayir |  |
| `modelCode` | string | Hayir | nullable |
| `needQuantity` | number (double) | Hayir |  |
| `openCompanyOrderQuantity` | number (double) | Hayir |  |
| `purchasePrice` | number (double) | Hayir |  |
| `recommendedDay` | number (double) | Hayir |  |
| `recommendedStockQuantity` | number (double) | Hayir |  |
| `salesQuantity` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `suggestedOrderQuantity` | number (double) | Hayir |  |
| `supplierCode` | string | Hayir | nullable |
| `supplierName` | string | Hayir | nullable |
| `targetOnHand` | number (double) | Hayir |  |
| `unitMultiplier` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.SuggestedWarehouseOrderListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `maxDay` | number (double) | Hayir |  |
| `minDay` | number (double) | Hayir |  |
| `modelCode` | string | Hayir | nullable |
| `needQuantity` | number (double) | Hayir |  |
| `openIncomingOrderQuantity` | number (double) | Hayir |  |
| `recommendedDay` | number (double) | Hayir |  |
| `recommendedStockQuantity` | number (double) | Hayir |  |
| `salesQuantity` | number (double) | Hayir |  |
| `sourceOnHand` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `suggestedOrderQuantity` | number (double) | Hayir |  |
| `targetOnHand` | number (double) | Hayir |  |
| `unitMultiplier` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.WarehouseOrderDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.WarehouseOrderHeaderDto | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.WarehouseOrderLineItemDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.WarehouseOrderHeaderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir |  |
| `documentKey` | string | Hayir | nullable |
| `documentNumber` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `inWarehouseName` | string | Hayir | nullable |
| `inWarehouseNo` | integer (int32) | Hayir |  |
| `isClosed` | boolean | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `outWarehouseName` | string | Hayir | nullable |
| `outWarehouseNo` | integer (int32) | Hayir |  |
| `relatedWarehouseName` | string | Hayir | nullable |
| `relatedWarehouseNo` | integer (int32) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalDeliveredQuantity` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `totalRemainingQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.WarehouseOrderLineGreenGrocerCaseDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `actualShippedCaseCount` | number (double) | Hayir | nullable |
| `actualShippedQuantity` | number (double) | Hayir | nullable |
| `averageCaseCount` | integer (int32) | Hayir | nullable |
| `averageKgPerCase` | number (double) | Hayir | nullable |
| `averageRecordCount` | integer (int32) | Hayir | nullable |
| `averageSource` | string | Hayir | nullable |
| `coefficientOfVariation` | number (double) | Hayir | nullable |
| `confidence` | string | Hayir | nullable |
| `conversionMode` | string | Hayir | nullable |
| `estimatedQuantity` | number (double) | Hayir |  |
| `inputMode` | string | Hayir | nullable |
| `inputQuantity` | number (double) | Hayir |  |
| `microUnit` | string | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `unitsPerCase` | number (double) | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.WarehouseOrderLineItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deliveredQuantity` | number (double) | Hayir |  |
| `description` | string | Hayir | nullable |
| `greenGrocerCase` | FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.WarehouseOrderLineGreenGrocerCaseDto | Hayir |  |
| `isClosed` | boolean | Hayir |  |
| `lineAmount` | number (double) | Hayir |  |
| `lineGuid` | string (uuid) | Hayir | nullable |
| `lineNo` | integer (int32) | Hayir |  |
| `packageCode` | string | Hayir | nullable |
| `projectCode` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `remainingQuantity` | number (double) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |
| `unitPrice` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.Common.WarehouseOrderListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir |  |
| `documentKey` | string | Hayir | nullable |
| `documentNumber` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `inWarehouseName` | string | Hayir | nullable |
| `inWarehouseNo` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `outWarehouseName` | string | Hayir | nullable |
| `outWarehouseNo` | integer (int32) | Hayir |  |
| `relatedWarehouseName` | string | Hayir | nullable |
| `relatedWarehouseNo` | integer (int32) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.OnerilenDepoSiparisleri.SourceProducts.SuggestedWarehouseSourceProductDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `caseBarcode` | string | Hayir | nullable |
| `modelCode` | string | Hayir | nullable |
| `modelName` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `recommendedQuantity` | number (double) | Hayir |  |
| `secondaryUnitName` | string | Hayir | nullable |
| `sourceWarehouseName` | string | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitMultiplier` | number (double) | Hayir |  |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |
| `unitPrice` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.VerilenDepoSiparisleri.Create.CreateIssuedWarehouseOrderResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deliveryDate` | string (date-time) | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `inWarehouseNo` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `orderDate` | string (date-time) | Hayir |  |
| `outWarehouseNo` | integer (int32) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `writeConnectionName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.VerilenFirmaSiparisleri.Create.CreateIssuedCompanyOrderResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | nullable |
| `deliveryDate` | string (date-time) | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `orderDate` | string (date-time) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |
| `writeConnectionName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.SiparisIslemleri.VerilenFirmaSiparisleri.SupplierProducts.IssuedCompanyOrderSupplierProductDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `caseBarcode` | string | Hayir | nullable |
| `customerCode` | string | Hayir | nullable |
| `customerName` | string | Hayir | nullable |
| `deliveryDay` | integer (int32) | Hayir | nullable |
| `minimumPurchaseQuantity` | number (double) | Hayir |  |
| `modelCode` | string | Hayir | nullable |
| `modelName` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `recommendedQuantity` | number (double) | Hayir |  |
| `secondaryUnitName` | string | Hayir | nullable |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitMultiplier` | number (double) | Hayir |  |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |
| `unitPrice` | number (double) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.StokIslemleri.Common.CreateStockReceiptResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `acceptor` | string | Hayir | nullable |
| `creator` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `lineCount` | integer (int32) | Hayir |  |
| `movementDate` | string (date-time) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |
| `writeConnectionName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.StokIslemleri.Common.StockReceiptDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.StokIslemleri.Common.StockReceiptHeaderDto | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.StokIslemleri.Common.StockReceiptLineItemDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.StokIslemleri.Common.StockReceiptHeaderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `acceptor` | string | Hayir | nullable |
| `creator` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `movementCreateDate` | string (date-time) | Hayir |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `movementGenre` | integer (int32) | Hayir |  |
| `movementType` | integer (int32) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |
| `workOrderExpenseCode` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.StokIslemleri.Common.StockReceiptLineItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | nullable |
| `lineAmount` | number (double) | Hayir |  |
| `lotNo` | integer (int32) | Hayir |  |
| `partyCode` | string | Hayir | nullable |
| `projectCode` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `quantity2` | number (double) | Hayir |  |
| `rowNo` | integer (int32) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |
| `unitPrice` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.StokIslemleri.Common.StockReceiptListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `acceptor` | string | Hayir | nullable |
| `creator` | string | Hayir | nullable |
| `description` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `movementCreateDate` | string (date-time) | Hayir |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `movementGenre` | integer (int32) | Hayir |  |
| `movementType` | integer (int32) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |
| `workOrderExpenseCode` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.StokIslemleri.SayimSonuclari.CreateInventoryCountResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentDate` | string (date-time) | Hayir |  |
| `documentNo` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `name` | string | Hayir | nullable |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |
| `writeConnectionName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.StokIslemleri.SayimSonuclari.InventoryCountDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.StokIslemleri.SayimSonuclari.InventoryCountHeaderDto | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.StokIslemleri.SayimSonuclari.InventoryCountLineItemDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.StokIslemleri.SayimSonuclari.InventoryCountHeaderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAt` | string (date-time) | Hayir |  |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `name` | string | Hayir | nullable |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.StokIslemleri.SayimSonuclari.InventoryCountLineItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | nullable |
| `quantity1` | number (double) | Hayir |  |
| `quantity2` | number (double) | Hayir |  |
| `quantity3` | number (double) | Hayir |  |
| `quantity4` | number (double) | Hayir |  |
| `quantity5` | number (double) | Hayir |  |
| `rowNo` | integer (int32) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.StokIslemleri.SayimSonuclari.InventoryCountListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createdAt` | string (date-time) | Hayir |  |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | integer (int32) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `name` | string | Hayir | nullable |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.StokIslemleri.StokAnomaliMerkezi.StockAnomalyDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `actualQuantity` | number (double) | Hayir | nullable |
| `averageQuantity` | number (double) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir | nullable |
| `documentSerie` | string | Hayir | nullable |
| `events` | FurpaMerkezApi.Application.Modules.StokIslemleri.StokAnomaliMerkezi.StockAnomalyEventDto[] | Hayir | nullable |
| `evidence` | string | Hayir | nullable |
| `expectedQuantity` | number (double) | Hayir | nullable |
| `firstDetectedAtUtc` | string (date-time) | Hayir |  |
| `id` | string (uuid) | Hayir |  |
| `lastChangedByUserId` | string (uuid) | Hayir | nullable |
| `lastDetectedAtUtc` | string (date-time) | Hayir |  |
| `message` | string | Hayir | nullable |
| `movementGuid` | string (uuid) | Hayir | nullable |
| `occurredAtUtc` | string (date-time) | Hayir | nullable |
| `productCode` | string | Hayir | nullable |
| `productManagerCode` | string | Hayir | nullable |
| `productManagerName` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir | nullable |
| `relatedWarehouseName` | string | Hayir | nullable |
| `relatedWarehouseNo` | integer (int32) | Hayir | nullable |
| `resolvedAtUtc` | string (date-time) | Hayir | nullable |
| `severity` | string | Hayir | nullable |
| `sourceKey` | string | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `type` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.StokIslemleri.StokAnomaliMerkezi.StockAnomalyEventDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `changedByUserId` | string (uuid) | Hayir | nullable |
| `eventType` | string | Hayir | nullable |
| `id` | string (uuid) | Hayir |  |
| `message` | string | Hayir | nullable |
| `occurredAtUtc` | string (date-time) | Hayir |  |
| `status` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.StokIslemleri.StokAnomaliMerkezi.StockAnomalyListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `actualQuantity` | number (double) | Hayir | nullable |
| `averageQuantity` | number (double) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir | nullable |
| `documentSerie` | string | Hayir | nullable |
| `expectedQuantity` | number (double) | Hayir | nullable |
| `firstDetectedAtUtc` | string (date-time) | Hayir |  |
| `id` | string (uuid) | Hayir |  |
| `lastDetectedAtUtc` | string (date-time) | Hayir |  |
| `message` | string | Hayir | nullable |
| `occurredAtUtc` | string (date-time) | Hayir | nullable |
| `productCode` | string | Hayir | nullable |
| `productManagerCode` | string | Hayir | nullable |
| `productManagerName` | string | Hayir | nullable |
| `productName` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir | nullable |
| `relatedWarehouseName` | string | Hayir | nullable |
| `relatedWarehouseNo` | integer (int32) | Hayir | nullable |
| `severity` | string | Hayir | nullable |
| `status` | string | Hayir | nullable |
| `type` | string | Hayir | nullable |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.StokIslemleri.StokAnomaliMerkezi.StockAnomalyListResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `items` | FurpaMerkezApi.Application.Modules.StokIslemleri.StokAnomaliMerkezi.StockAnomalyListItemDto[] | Hayir | nullable |
| `summary` | FurpaMerkezApi.Application.Modules.StokIslemleri.StokAnomaliMerkezi.StockAnomalySummaryDto | Hayir |  |
| `totalCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.StokIslemleri.StokAnomaliMerkezi.StockAnomalyProductManagerDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `anomalyCount` | integer (int32) | Hayir |  |
| `code` | string | Hayir | nullable |
| `isAssigned` | boolean | Hayir |  |
| `name` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.StokIslemleri.StokAnomaliMerkezi.StockAnomalyScanResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `detectedCount` | integer (int32) | Hayir |  |
| `finishedAtUtc` | string (date-time) | Hayir |  |
| `rules` | FurpaMerkezApi.Application.Modules.StokIslemleri.StokAnomaliMerkezi.StockAnomalyScanRuleResultDto[] | Hayir | nullable |
| `startedAtUtc` | string (date-time) | Hayir |  |

### FurpaMerkezApi.Application.Modules.StokIslemleri.StokAnomaliMerkezi.StockAnomalyScanRuleResultDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `detectedCount` | integer (int32) | Hayir |  |
| `error` | string | Hayir | nullable |
| `type` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.StokIslemleri.StokAnomaliMerkezi.StockAnomalySummaryDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `acknowledgedCount` | integer (int32) | Hayir |  |
| `criticalCount` | integer (int32) | Hayir |  |
| `highCount` | integer (int32) | Hayir |  |
| `ignoredCount` | integer (int32) | Hayir |  |
| `openCount` | integer (int32) | Hayir |  |
| `resolvedCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.StokIslemleri.Virmanlar.ConversionSuggestion.VirmanConversionSuggestionDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `confidencePercent` | number (double) | Hayir |  |
| `isReliable` | boolean | Hayir |  |
| `lookbackEndDate` | string (date-time) | Hayir |  |
| `lookbackStartDate` | string (date-time) | Hayir |  |
| `maximumSampleCount` | integer (int32) | Hayir |  |
| `minimumConfidencePercent` | number (double) | Hayir |  |
| `minimumSampleCount` | integer (int32) | Hayir |  |
| `multiplier` | number (double) | Hayir | nullable |
| `multiplierConfidencePercent` | number (double) | Hayir |  |
| `multiplierMatchCount` | integer (int32) | Hayir |  |
| `sampleCount` | integer (int32) | Hayir |  |
| `sourceQuantity` | number (double) | Hayir |  |
| `sourceStockCode` | string | Hayir | nullable |
| `sourceStockName` | string | Hayir | nullable |
| `sourceUnitName` | string | Hayir | nullable |
| `suggestionSource` | string | Hayir | nullable |
| `targetConfidencePercent` | number (double) | Hayir |  |
| `targetMatchCount` | integer (int32) | Hayir |  |
| `targetQuantity` | number (double) | Hayir | nullable |
| `targetStockCode` | string | Hayir | nullable |
| `targetStockName` | string | Hayir | nullable |
| `targetUnitName` | string | Hayir | nullable |
| `warning` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.StokIslemleri.Virmanlar.CreateVirmanResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentDate` | string (date-time) | Hayir |  |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `incomingLineCount` | integer (int32) | Hayir |  |
| `incomingQuantity` | number (double) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `movementDate` | string (date-time) | Hayir |  |
| `movementTypes` | integer (int32)[] | Hayir | nullable |
| `outgoingLineCount` | integer (int32) | Hayir |  |
| `outgoingQuantity` | number (double) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir |  |
| `writeConnectionName` | string | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.StokIslemleri.Virmanlar.VirmanDetailDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.Application.Modules.StokIslemleri.Virmanlar.VirmanHeaderDto | Hayir |  |
| `items` | FurpaMerkezApi.Application.Modules.StokIslemleri.Virmanlar.VirmanLineItemDto[] | Hayir | nullable |

### FurpaMerkezApi.Application.Modules.StokIslemleri.Virmanlar.VirmanHeaderDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | integer (int32) | Hayir |  |
| `incomingLineCount` | integer (int32) | Hayir |  |
| `incomingQuantity` | number (double) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `movementCreateDate` | string (date-time) | Hayir |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `movementGenre` | integer (int32) | Hayir |  |
| `movementTypes` | integer (int32)[] | Hayir | nullable |
| `outgoingLineCount` | integer (int32) | Hayir |  |
| `outgoingQuantity` | number (double) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Application.Modules.StokIslemleri.Virmanlar.VirmanLineItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | nullable |
| `lineAmount` | number (double) | Hayir |  |
| `lotNo` | integer (int32) | Hayir |  |
| `movementType` | integer (int32) | Hayir |  |
| `partyCode` | string | Hayir | nullable |
| `projectCode` | string | Hayir | nullable |
| `quantity` | number (double) | Hayir |  |
| `quantity2` | number (double) | Hayir |  |
| `rowNo` | integer (int32) | Hayir |  |
| `stockCode` | string | Hayir | nullable |
| `stockName` | string | Hayir | nullable |
| `unitName` | string | Hayir | nullable |
| `unitPointer` | integer (int32) | Hayir |  |
| `unitPrice` | number (double) | Hayir |  |

### FurpaMerkezApi.Application.Modules.StokIslemleri.Virmanlar.VirmanListItemDto

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Hayir |  |
| `documentSerie` | string | Hayir | nullable |
| `documentType` | integer (int32) | Hayir |  |
| `incomingLineCount` | integer (int32) | Hayir |  |
| `incomingQuantity` | number (double) | Hayir |  |
| `lineCount` | integer (int32) | Hayir |  |
| `movementCreateDate` | string (date-time) | Hayir |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `movementGenre` | integer (int32) | Hayir |  |
| `movementTypes` | integer (int32)[] | Hayir | nullable |
| `outgoingLineCount` | integer (int32) | Hayir |  |
| `outgoingQuantity` | number (double) | Hayir |  |
| `totalAmount` | number (double) | Hayir |  |
| `totalQuantity` | number (double) | Hayir |  |
| `warehouseName` | string | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir |  |

### FurpaMerkezApi.Domain.Entities.DocumentFlowStatus

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|

Enum degerleri JSON sozlesmesinde bulunur.

### FurpaMerkezApi.Domain.Entities.DocumentFlowType

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|

Enum degerleri JSON sozlesmesinde bulunur.

### FurpaMerkezApi.Domain.Entities.StockAnomalySeverity

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|

Enum degerleri JSON sozlesmesinde bulunur.

### FurpaMerkezApi.Domain.Entities.StockAnomalyStatus

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|

Enum degerleri JSON sozlesmesinde bulunur.

### FurpaMerkezApi.Domain.Entities.StockAnomalyType

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|

Enum degerleri JSON sozlesmesinde bulunur.

### FurpaMerkezApi.WebApi.Controllers.AuthController.LoginUserRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientType` | string | Hayir | minLength=0; maxLength=20; nullable |
| `deviceId` | string | Hayir | minLength=0; maxLength=100; nullable |
| `password` | string | Evet | minLength=0; maxLength=200 |
| `usernameOrEmail` | string | Evet | minLength=0; maxLength=200 |

### FurpaMerkezApi.WebApi.Controllers.AuthController.RefreshTokenBody

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `refreshToken` | string | Evet | minLength=0; maxLength=500 |

### FurpaMerkezApi.WebApi.Controllers.AuthController.RegisterUserRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `email` | string (email) | Evet | minLength=0; maxLength=200 |
| `firstName` | string | Evet | minLength=0; maxLength=100 |
| `lastName` | string | Evet | minLength=0; maxLength=100 |
| `password` | string | Evet | minLength=6; maxLength=200 |
| `username` | string | Evet | minLength=0; maxLength=50 |
| `warehouseName` | string | Evet | minLength=0; maxLength=150 |
| `warehouseNo` | string | Evet | minLength=0; maxLength=50 |

### FurpaMerkezApi.WebApi.Controllers.Legacy.LegacySendEDespatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deliverer` | string | Hayir | minLength=0; maxLength=25; nullable |
| `driverId` | string (uuid) | Hayir | nullable |
| `driverNameSurname` | string | Hayir | minLength=0; maxLength=25; nullable |
| `driverTckn` | string | Hayir | minLength=0; maxLength=25; nullable |
| `expectedLineCount` | integer (int32) | Evet | min=1; max=2147483647 |
| `plaque` | string | Hayir | minLength=0; maxLength=25; nullable |
| `receiver` | string | Hayir | minLength=0; maxLength=25; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.AyarIslemleri.B2BAyarlari.SaveB2BBulletinHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `createDate` | string (date-time) | Hayir | nullable |
| `definition` | string | Evet | minLength=1 |
| `link` | string | Evet | minLength=1 |

### FurpaMerkezApi.WebApi.Controllers.Modules.AyarIslemleri.B2BAyarlari.UpdateB2BUserHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `menus` | string | Hayir | nullable |
| `status` | boolean | Evet |  |
| `userEndDate` | string (date-time) | Evet |  |
| `userFullName` | string | Evet | minLength=0; maxLength=70 |
| `userMail` | string (email) | Evet | minLength=0; maxLength=150 |

### FurpaMerkezApi.WebApi.Controllers.Modules.AyarIslemleri.Cihazlar.CreateDeviceHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Evet | min=1; max=2147483647 |
| `description` | string | Evet | minLength=0; maxLength=255 |
| `deviceTypeId` | integer (int32) | Evet | min=1; max=2147483647 |
| `ipAddress` | string | Evet | minLength=0; maxLength=100 |

### FurpaMerkezApi.WebApi.Controllers.Modules.AyarIslemleri.KasaPosTerminalleri.CreateCashRegisterHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Evet | min=1; max=2147483647 |
| `cashNo` | integer (int32) | Evet | min=1; max=2147483647 |
| `cashType` | integer (int32) | Evet | min=0; max=255 |
| `terminals` | FurpaMerkezApi.WebApi.Controllers.Modules.AyarIslemleri.KasaPosTerminalleri.CreateCashRegisterTerminalHttpRequest[] | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.AyarIslemleri.KasaPosTerminalleri.CreateCashRegisterTerminalHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `bank` | string | Evet | minLength=0; maxLength=100 |
| `merchantNo` | string | Evet | minLength=0; maxLength=40 |
| `terminalId` | string | Evet | minLength=0; maxLength=40 |
| `terminalNo` | string | Evet | minLength=0; maxLength=40 |

### FurpaMerkezApi.WebApi.Controllers.Modules.AyarIslemleri.Kasiyerler.CreateCashierHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashierAuthorization` | string | Evet | minLength=0; maxLength=100 |
| `cashierName` | string | Evet | minLength=0; maxLength=100 |

### FurpaMerkezApi.WebApi.Controllers.Modules.AyarIslemleri.Kasiyerler.UpdateCashierHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashierAuthorization` | string | Evet | minLength=0; maxLength=100 |
| `cashierName` | string | Evet | minLength=0; maxLength=100 |
| `cashierState` | boolean | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.AyarIslemleri.Soforler.SaveDespatchDriverHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `firstName` | string | Evet | minLength=0; maxLength=60 |
| `isActive` | boolean | Hayir |  |
| `lastName` | string | Evet | minLength=0; maxLength=60 |
| `notes` | string | Hayir | minLength=0; maxLength=1000; nullable |
| `plateNumber` | string | Evet | minLength=0; maxLength=20 |
| `tckn` | string | Evet | minLength=1; pattern=^\d{11}$ |

### FurpaMerkezApi.WebApi.Controllers.Modules.AyarIslemleri.SubeAyarlari.CreateBranchSettingsHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchIpAddress` | string | Evet | minLength=0; maxLength=100 |
| `branchNo` | integer (int32) | Evet | min=1; max=2147483647 |
| `branchScalesFolderPath` | string | Evet | minLength=0; maxLength=255 |
| `cashRegisters` | FurpaMerkezApi.WebApi.Controllers.Modules.AyarIslemleri.SubeAyarlari.CreateCashRegistryHttpRequest[] | Hayir | nullable |
| `posGenelFolderPath` | string | Evet | minLength=0; maxLength=255 |
| `poskonFolderPath` | string | Evet | minLength=0; maxLength=255 |
| `scalesType` | integer (int32) | Evet | min=0; max=1 |

### FurpaMerkezApi.WebApi.Controllers.Modules.AyarIslemleri.SubeAyarlari.CreateCashRegistryHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashNo` | integer (int32) | Evet | min=1; max=2147483647 |
| `cashType` | integer (int32) | Evet | min=0; max=255 |

### FurpaMerkezApi.WebApi.Controllers.Modules.AyarIslemleri.SubeAyarlari.UpdateBranchSettingsHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchIpAddress` | string | Evet | minLength=0; maxLength=100 |
| `branchScalesFolderPath` | string | Evet | minLength=0; maxLength=255 |
| `posGenelFolderPath` | string | Evet | minLength=0; maxLength=255 |
| `poskonFolderPath` | string | Evet | minLength=0; maxLength=255 |
| `scalesType` | integer (int32) | Evet | min=0; max=1 |

### FurpaMerkezApi.WebApi.Controllers.Modules.AyarIslemleri.VeritabaniIzleme.TerminateDatabaseSessionHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `expectedHostProcessId` | integer (int32) | Hayir | nullable |
| `expectedLoginTime` | string (date-time) | Evet |  |
| `expectedProgramName` | string | Hayir | minLength=0; maxLength=256; nullable |
| `reason` | string | Evet | minLength=10; maxLength=500 |

### FurpaMerkezApi.WebApi.Controllers.Modules.Common.CreateCompanyMovementHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientRequestId` | string (uuid) | Hayir | nullable |
| `customerCode` | string | Evet | minLength=0; maxLength=25 |
| `deliverer` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.Common.CreateCompanyMovementLineHttpRequest[] | Evet |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `receiver` | string | Hayir | minLength=0; maxLength=25; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.Common.CreateCompanyMovementLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lotNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `orderLineGuid` | string (uuid) | Hayir | nullable |
| `partyCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `productResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |
| `unitPrice` | number (double) | Hayir | min=0 |

### FurpaMerkezApi.WebApi.Controllers.Modules.Common.CreateInventoryCountHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientRequestId` | string (uuid) | Hayir | nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.Common.CreateInventoryCountLineHttpRequest[] | Evet |  |
| `name` | string | Hayir | minLength=0; maxLength=25; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.Common.CreateInventoryCountLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | minLength=0; maxLength=50; nullable |
| `quantity` | number (double) | Hayir | min=0 |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |

### FurpaMerkezApi.WebApi.Controllers.Modules.Common.CreateStockReceiptHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `acceptor` | string | Evet | minLength=0; maxLength=25 |
| `clientRequestId` | string (uuid) | Hayir | nullable |
| `creator` | string | Evet | minLength=0; maxLength=25 |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.Common.CreateStockReceiptLineHttpRequest[] | Evet |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.Common.CreateStockReceiptLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lotNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `partyCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |

### FurpaMerkezApi.WebApi.Controllers.Modules.Common.CreateVirmanHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientRequestId` | string (uuid) | Hayir | nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.Common.CreateVirmanLineHttpRequest[] | Evet |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.Common.CreateVirmanLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lotNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `movementType` | integer (int32) | Hayir | min=0; max=255 |
| `partyCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |

### FurpaMerkezApi.WebApi.Controllers.Modules.Common.ModuleActionRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `fields` | object | Hayir | nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.Common.ModuleActionScaffoldResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `actionCode` | string | Hayir | nullable |
| `actionName` | string | Hayir | nullable |
| `httpMethod` | string | Hayir | nullable |
| `isImplemented` | boolean | Hayir |  |
| `menuCode` | string | Hayir | nullable |
| `menuName` | string | Hayir | nullable |
| `message` | string | Hayir | nullable |
| `moduleCode` | string | Hayir | nullable |
| `moduleName` | string | Hayir | nullable |
| `permissionCode` | string | Hayir | nullable |
| `resourceId` | string | Hayir | nullable |
| `route` | string | Hayir | nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.Common.SendEDespatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deliverer` | string | Hayir | minLength=0; maxLength=25; nullable |
| `driverId` | string (uuid) | Hayir | nullable |
| `driverNameSurname` | string | Hayir | minLength=0; maxLength=25; nullable |
| `driverTckn` | string | Hayir | minLength=0; maxLength=25; nullable |
| `plaque` | string | Hayir | minLength=0; maxLength=25; nullable |
| `receiver` | string | Hayir | minLength=0; maxLength=25; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.Common.UpdateWarehouseShippingDocumentHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.Common.UpdateWarehouseShippingDocumentLineHttpRequest[] | Hayir | nullable |
| `movementDate` | string (date-time) | Hayir | nullable |
| `targetWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `transitWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.Common.UpdateWarehouseShippingDocumentLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `action` | string | Hayir | minLength=0; maxLength=20; nullable |
| `amount` | number (double) | Hayir | min=0; nullable |
| `customerResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lotNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `movementGuid` | string (uuid) | Hayir | nullable |
| `partyCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `productResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir | nullable |
| `rowNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `stockCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `unitPointer` | integer (int32) | Hayir | min=1; max=4; nullable |
| `unitPrice` | number (double) | Hayir | min=0; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.BanknoteTrackPatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `banknoteTrackDate` | string (date-time) | Hayir | nullable |
| `deliverer` | string | Hayir | minLength=0; maxLength=100; nullable |
| `deliveryTotalAmount` | number (double) | Hayir | min=0; nullable |
| `receiver` | string | Hayir | minLength=0; maxLength=100; nullable |
| `totalAmount` | number (double) | Hayir | min=0; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CompanyOrderDocumentLookupHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `documentOrderNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `documentSerie` | string | Evet | minLength=0; maxLength=20 |
| `hardDelete` | boolean | Hayir |  |
| `orderKind` | integer (int32) | Hayir | min=0; max=255; nullable |
| `orderType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CompanyOrderHeaderPatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `addressNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `alternativeCurrencyRate` | number (double) | Hayir | min=0; nullable |
| `canBeCalled` | boolean | Hayir | nullable |
| `closeReasonCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `currencyRate` | number (double) | Hayir | min=0; nullable |
| `currencyType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `customerCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `customerResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `deliveryType` | string | Hayir | minLength=0; maxLength=4; nullable |
| `description1` | string | Hayir | minLength=0; maxLength=50; nullable |
| `description2` | string | Hayir | minLength=0; maxLength=50; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `isClosed` | boolean | Hayir | nullable |
| `orderDate` | string (date-time) | Hayir | nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `sellerCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `stockResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CompanyOrderLinePatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir | min=0; nullable |
| `canBeCalled` | boolean | Hayir | nullable |
| `closeReasonCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `customerResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `deliveredFromReservation` | number (double) | Hayir | min=0; nullable |
| `deliveredQuantity` | number (double) | Hayir | min=0; nullable |
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `description1` | string | Hayir | minLength=0; maxLength=50; nullable |
| `description2` | string | Hayir | minLength=0; maxLength=50; nullable |
| `discount1` | number (double) | Hayir | min=0; nullable |
| `discount2` | number (double) | Hayir | min=0; nullable |
| `discount3` | number (double) | Hayir | min=0; nullable |
| `discount4` | number (double) | Hayir | min=0; nullable |
| `discount5` | number (double) | Hayir | min=0; nullable |
| `discount6` | number (double) | Hayir | min=0; nullable |
| `expense1` | number (double) | Hayir | min=0; nullable |
| `expense2` | number (double) | Hayir | min=0; nullable |
| `expense3` | number (double) | Hayir | min=0; nullable |
| `expense4` | number (double) | Hayir | min=0; nullable |
| `isClosed` | boolean | Hayir | nullable |
| `lotNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `orderGuid` | string (uuid) | Hayir |  |
| `packageCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `partyCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `priceListNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir | min=0; nullable |
| `reservedQuantity` | number (double) | Hayir | min=0; nullable |
| `rowNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `special1` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special2` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special3` | string | Hayir | minLength=0; maxLength=4; nullable |
| `stockCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `stockResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `taxAmount` | number (double) | Hayir | min=0; nullable |
| `taxPointer` | integer (int32) | Hayir | min=0; max=255; nullable |
| `unitPointer` | integer (int32) | Hayir | min=1; max=4; nullable |
| `unitPrice` | number (double) | Hayir | min=0; nullable |
| `validUntil` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerAddressPatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `addressCode` | string | Hayir | minLength=0; maxLength=10; nullable |
| `apartmentNo` | string | Hayir | minLength=0; maxLength=10; nullable |
| `apartmentUnitNo` | string | Hayir | minLength=0; maxLength=10; nullable |
| `avenue` | string | Hayir | minLength=0; maxLength=50; nullable |
| `city` | string | Hayir | minLength=0; maxLength=50; nullable |
| `country` | string | Hayir | minLength=0; maxLength=50; nullable |
| `district` | string | Hayir | minLength=0; maxLength=50; nullable |
| `eDespatchAlias` | string | Hayir | minLength=0; maxLength=120; nullable |
| `eInvoiceAlias` | string | Hayir | minLength=0; maxLength=120; nullable |
| `faxNo` | string | Hayir | minLength=0; maxLength=10; nullable |
| `isHidden` | boolean | Hayir | nullable |
| `isLocked` | boolean | Hayir | nullable |
| `isPassive` | boolean | Hayir | nullable |
| `isPrintEnabled` | boolean | Hayir | nullable |
| `latitude` | number (double) | Hayir | min=-90; max=90; nullable |
| `longitude` | number (double) | Hayir | min=-180; max=180; nullable |
| `neighborhood` | string | Hayir | minLength=0; maxLength=50; nullable |
| `note` | string | Hayir | minLength=0; maxLength=127; nullable |
| `phoneAreaCode` | string | Hayir | minLength=0; maxLength=5; nullable |
| `phoneCountryCode` | string | Hayir | minLength=0; maxLength=5; nullable |
| `phoneNo1` | string | Hayir | minLength=0; maxLength=10; nullable |
| `phoneNo2` | string | Hayir | minLength=0; maxLength=10; nullable |
| `postalCode` | string | Hayir | minLength=0; maxLength=8; nullable |
| `quarter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `representativeCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `street` | string | Hayir | minLength=0; maxLength=50; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerCardPatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accountingCode` | string | Hayir | minLength=0; maxLength=40; nullable |
| `accountingCode1` | string | Hayir | minLength=0; maxLength=40; nullable |
| `accountingCode2` | string | Hayir | minLength=0; maxLength=40; nullable |
| `connectionType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `currencyType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `currencyType1` | integer (int32) | Hayir | min=0; max=255; nullable |
| `currencyType2` | integer (int32) | Hayir | min=0; max=255; nullable |
| `defaultEDespatchType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `defaultEInvoiceType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `defaultInputWarehouseNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `defaultOutputWarehouseNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `eDespatchEnabled` | boolean | Hayir | nullable |
| `eInvoiceEnabled` | boolean | Hayir | nullable |
| `email` | string (email) | Hayir | minLength=0; maxLength=127; nullable |
| `groupCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `invoiceAddressNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `isClosed` | boolean | Hayir | nullable |
| `isLocked` | boolean | Hayir | nullable |
| `kepAddress` | string | Hayir | minLength=0; maxLength=80; nullable |
| `mersisNo` | string | Hayir | minLength=0; maxLength=25; nullable |
| `mobilePhone` | string | Hayir | minLength=0; maxLength=20; nullable |
| `movementType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `optionDay` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `parentCustomerCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `paymentDay` | integer (int32) | Hayir | min=0; max=255; nullable |
| `paymentPlanNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `paymentType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `purchaseStockType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `reconciliationEmail` | string (email) | Hayir | minLength=0; maxLength=80; nullable |
| `regionCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `registryNo` | string | Hayir | minLength=0; maxLength=15; nullable |
| `representativeCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `retailCustomer` | boolean | Hayir | nullable |
| `salesPriceListNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `salesStockType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `sectorCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `shippingAddressNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `special1` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special2` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special3` | string | Hayir | minLength=0; maxLength=4; nullable |
| `taxNo` | string | Hayir | minLength=0; maxLength=10; nullable |
| `taxOffice` | string | Hayir | minLength=0; maxLength=50; nullable |
| `taxOfficeCode` | string | Hayir | minLength=0; maxLength=10; nullable |
| `taxOfficeNo` | string | Hayir | minLength=0; maxLength=15; nullable |
| `title1` | string | Hayir | minLength=0; maxLength=127; nullable |
| `title2` | string | Hayir | minLength=0; maxLength=127; nullable |
| `website` | string | Hayir | minLength=0; maxLength=30; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerMovementDocumentLookupHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `documentOrderNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `documentSerie` | string | Evet | minLength=0; maxLength=20 |
| `documentType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `hardDelete` | boolean | Hayir |  |
| `movementKind` | integer (int32) | Hayir | min=0; max=255; nullable |
| `movementType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `normalReturn` | integer (int32) | Hayir | min=0; max=255; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerMovementHeaderPatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description` | string | Hayir | minLength=0; maxLength=40; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `movementDate` | string (date-time) | Hayir | nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `responsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `sellerCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `turnoverCustomerCode` | string | Hayir | minLength=0; maxLength=25; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerMovementLinePatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir | min=0; nullable |
| `customerCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description` | string | Hayir | minLength=0; maxLength=40; nullable |
| `discount1` | number (double) | Hayir | min=0; nullable |
| `discount2` | number (double) | Hayir | min=0; nullable |
| `discount3` | number (double) | Hayir | min=0; nullable |
| `discount4` | number (double) | Hayir | min=0; nullable |
| `discount5` | number (double) | Hayir | min=0; nullable |
| `discount6` | number (double) | Hayir | min=0; nullable |
| `dueDay` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `expense1` | number (double) | Hayir | min=0; nullable |
| `expense2` | number (double) | Hayir | min=0; nullable |
| `expense3` | number (double) | Hayir | min=0; nullable |
| `expense4` | number (double) | Hayir | min=0; nullable |
| `movementGuid` | string (uuid) | Hayir |  |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir | min=0; nullable |
| `responsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `rowNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `sellerCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `special1` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special2` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special3` | string | Hayir | minLength=0; maxLength=4; nullable |
| `subAmount` | number (double) | Hayir | min=0; nullable |
| `tax1` | number (double) | Hayir | min=0; nullable |
| `tax2` | number (double) | Hayir | min=0; nullable |
| `tax3` | number (double) | Hayir | min=0; nullable |
| `tax4` | number (double) | Hayir | min=0; nullable |
| `tax5` | number (double) | Hayir | min=0; nullable |
| `turnoverCustomerCode` | string | Hayir | minLength=0; maxLength=25; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.InventoryCountDocumentLookupHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentDate` | string (date-time) | Evet |  |
| `documentNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.InventoryCountHeaderPatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentDate` | string (date-time) | Hayir | nullable |
| `name` | string | Hayir | minLength=0; maxLength=25; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.InventoryCountLinePatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcode` | string | Hayir | minLength=0; maxLength=50; nullable |
| `corridorCode` | string | Hayir | minLength=0; maxLength=4; nullable |
| `countGuid` | string (uuid) | Hayir |  |
| `lotNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `partyCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity1` | number (double) | Hayir | min=0; nullable |
| `quantity2` | number (double) | Hayir | min=0; nullable |
| `quantity3` | number (double) | Hayir | min=0; nullable |
| `quantity4` | number (double) | Hayir | min=0; nullable |
| `quantity5` | number (double) | Hayir | min=0; nullable |
| `rayonCode` | string | Hayir | minLength=0; maxLength=4; nullable |
| `rowNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `serialNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `shelfCode` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special1` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special2` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special3` | string | Hayir | minLength=0; maxLength=4; nullable |
| `stockCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `unitPointer` | integer (int32) | Hayir | min=1; max=4; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockCardPatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `brandCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `categoryCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `currencyType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `discountDisabled` | boolean | Hayir | nullable |
| `foreignName` | string | Hayir | minLength=0; maxLength=127; nullable |
| `isPassive` | boolean | Hayir | nullable |
| `mainGroupCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `manufacturerCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `name` | string | Hayir | minLength=0; maxLength=127; nullable |
| `orderStopped` | boolean | Hayir | nullable |
| `rayonCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `receivingStopped` | boolean | Hayir | nullable |
| `responsibilityCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `retailTaxPointer` | integer (int32) | Hayir | min=0; max=255; nullable |
| `salesStopped` | boolean | Hayir | nullable |
| `sectorCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `shelfCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `shortName` | string | Hayir | minLength=0; maxLength=50; nullable |
| `special1` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special2` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special3` | string | Hayir | minLength=0; maxLength=4; nullable |
| `stockType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `subGroupCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `supplierCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `trackingType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `unit1Name` | string | Hayir | minLength=0; maxLength=10; nullable |
| `unit2Name` | string | Hayir | minLength=0; maxLength=10; nullable |
| `unit3Name` | string | Hayir | minLength=0; maxLength=10; nullable |
| `unit4Name` | string | Hayir | minLength=0; maxLength=10; nullable |
| `wholesaleTaxPointer` | integer (int32) | Hayir | min=0; max=255; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockCardWarehousePatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `discountDisabled` | boolean | Hayir | nullable |
| `isPassive` | boolean | Hayir | nullable |
| `orderStopped` | boolean | Hayir | nullable |
| `receivingStopped` | boolean | Hayir | nullable |
| `resetToGlobal` | boolean | Hayir |  |
| `salesStopped` | boolean | Hayir | nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockMovementDocumentLookupHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentOrderNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `documentSerie` | string | Evet | minLength=0; maxLength=20 |
| `documentType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `hardDelete` | boolean | Hayir |  |
| `movementKind` | integer (int32) | Hayir | min=0; max=255; nullable |
| `movementType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `normalReturn` | integer (int32) | Hayir | min=0; max=255; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockMovementHeaderPatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `customerResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `goodsAcceptanceDate` | string (date-time) | Hayir | nullable |
| `inputWarehouseNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `movementDate` | string (date-time) | Hayir | nullable |
| `movementGroupCode1` | string | Hayir | minLength=0; maxLength=25; nullable |
| `movementGroupCode2` | string | Hayir | minLength=0; maxLength=25; nullable |
| `movementGroupCode3` | string | Hayir | minLength=0; maxLength=25; nullable |
| `outputWarehouseNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `shippingWarehouseNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `stockResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockMovementLinePatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir | min=0; nullable |
| `customerResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `discount1` | number (double) | Hayir | min=0; nullable |
| `discount2` | number (double) | Hayir | min=0; nullable |
| `discount3` | number (double) | Hayir | min=0; nullable |
| `discount4` | number (double) | Hayir | min=0; nullable |
| `discount5` | number (double) | Hayir | min=0; nullable |
| `discount6` | number (double) | Hayir | min=0; nullable |
| `expense1` | number (double) | Hayir | min=0; nullable |
| `expense2` | number (double) | Hayir | min=0; nullable |
| `expense3` | number (double) | Hayir | min=0; nullable |
| `expense4` | number (double) | Hayir | min=0; nullable |
| `expenseTaxAmount` | number (double) | Hayir | min=0; nullable |
| `expenseTaxPointer` | integer (int32) | Hayir | min=0; max=255; nullable |
| `goodsAcceptanceDate` | string (date-time) | Hayir | nullable |
| `grossWeight` | number (double) | Hayir | min=0; nullable |
| `inputWarehouseNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `lotNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `movementGuid` | string (uuid) | Hayir |  |
| `netWeight` | number (double) | Hayir | min=0; nullable |
| `outputWarehouseNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `partyCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir | min=0; nullable |
| `rowNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `secondaryQuantity` | number (double) | Hayir | min=0; nullable |
| `special1` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special2` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special3` | string | Hayir | minLength=0; maxLength=4; nullable |
| `stockCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `stockResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `taxAmount` | number (double) | Hayir | min=0; nullable |
| `taxPointer` | integer (int32) | Hayir | min=0; max=255; nullable |
| `unitPointer` | integer (int32) | Hayir | min=1; max=4; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockSalesPriceUpsertHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `changeReason` | integer (int32) | Hayir | min=0; max=255 |
| `currencyType` | integer (int32) | Hayir | min=0; max=255 |
| `paymentPlanNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `price` | number (double) | Hayir |  |
| `priceListNo` | integer (int32) | Hayir | min=1; max=2147483647 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=4 |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.UpdateCompanyOrderDocumentHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CompanyOrderHeaderPatchHttpRequest | Hayir |  |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CompanyOrderLinePatchHttpRequest[] | Hayir | nullable |
| `lookup` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CompanyOrderDocumentLookupHttpRequest | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.UpdateCustomerMovementDocumentHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerMovementHeaderPatchHttpRequest | Hayir |  |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerMovementLinePatchHttpRequest[] | Hayir | nullable |
| `lookup` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.CustomerMovementDocumentLookupHttpRequest | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.UpdateInventoryCountDocumentHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.InventoryCountHeaderPatchHttpRequest | Hayir |  |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.InventoryCountLinePatchHttpRequest[] | Hayir | nullable |
| `lookup` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.InventoryCountDocumentLookupHttpRequest | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.UpdateStockMovementDocumentHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockMovementHeaderPatchHttpRequest | Hayir |  |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockMovementLinePatchHttpRequest[] | Hayir | nullable |
| `lookup` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.StockMovementDocumentLookupHttpRequest | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.UpdateWarehouseOrderDocumentHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `header` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseOrderHeaderPatchHttpRequest | Hayir |  |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseOrderLinePatchHttpRequest[] | Hayir | nullable |
| `lookup` | FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseOrderDocumentLookupHttpRequest | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseCardPatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accountingCode` | string | Hayir | minLength=0; maxLength=40; nullable |
| `addressCode` | string | Hayir | minLength=0; maxLength=10; nullable |
| `apartmentNo` | string | Hayir | minLength=0; maxLength=10; nullable |
| `apartmentUnitNo` | string | Hayir | minLength=0; maxLength=10; nullable |
| `authorizedEmail` | string (email) | Hayir | minLength=0; maxLength=50; nullable |
| `avenue` | string | Hayir | minLength=0; maxLength=50; nullable |
| `city` | string | Hayir | minLength=0; maxLength=50; nullable |
| `country` | string | Hayir | minLength=0; maxLength=50; nullable |
| `detailTrackingType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `district` | string | Hayir | minLength=0; maxLength=50; nullable |
| `excludedFromInventory` | boolean | Hayir | nullable |
| `faxNo` | string | Hayir | minLength=0; maxLength=10; nullable |
| `groupCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `incomingEDespatchEnabled` | boolean | Hayir | nullable |
| `isHidden` | boolean | Hayir | nullable |
| `isLocked` | boolean | Hayir | nullable |
| `isPassive` | boolean | Hayir | nullable |
| `latitude` | number (double) | Hayir | nullable |
| `lockDate` | string (date-time) | Hayir | nullable |
| `longitude` | number (double) | Hayir | nullable |
| `movementType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `name` | string | Hayir | minLength=0; maxLength=50; nullable |
| `neighborhood` | string | Hayir | minLength=0; maxLength=50; nullable |
| `outgoingEDespatchEnabled` | boolean | Hayir | nullable |
| `phoneAreaCode` | string | Hayir | minLength=0; maxLength=5; nullable |
| `phoneCountryCode` | string | Hayir | minLength=0; maxLength=5; nullable |
| `phoneNo1` | string | Hayir | minLength=0; maxLength=10; nullable |
| `phoneNo2` | string | Hayir | minLength=0; maxLength=10; nullable |
| `postalCode` | string | Hayir | minLength=0; maxLength=8; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quarter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `regionCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `responsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `shipmentAppliedPriceNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `shipmentAutoPriceType` | integer (int32) | Hayir | min=0; max=255; nullable |
| `special1` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special2` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special3` | string | Hayir | minLength=0; maxLength=4; nullable |
| `street` | string | Hayir | minLength=0; maxLength=50; nullable |
| `warehouseType` | integer (int32) | Hayir | min=0; max=255; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseOrderDocumentLookupHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentOrderNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `documentSerie` | string | Evet | minLength=0; maxLength=20 |
| `hardDelete` | boolean | Hayir |  |
| `inWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `outWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseOrderHeaderPatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `closeReasonCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `inWarehouseNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `isClosed` | boolean | Hayir | nullable |
| `orderDate` | string (date-time) | Hayir | nullable |
| `outWarehouseNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `responsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.DuzeltmeIslemleri.MikroEvrakDuzenleme.WarehouseOrderLinePatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amount` | number (double) | Hayir | min=0; nullable |
| `closeReasonCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `deliveredFromReservation` | number (double) | Hayir | min=0; nullable |
| `deliveredQuantity` | number (double) | Hayir | min=0; nullable |
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `inWarehouseNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `isClosed` | boolean | Hayir | nullable |
| `orderGuid` | string (uuid) | Hayir |  |
| `outWarehouseNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `packageCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `priceListNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir | min=0; nullable |
| `reservedQuantity` | number (double) | Hayir | min=0; nullable |
| `responsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `rowNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `special1` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special2` | string | Hayir | minLength=0; maxLength=4; nullable |
| `special3` | string | Hayir | minLength=0; maxLength=4; nullable |
| `stockCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `unitPointer` | integer (int32) | Hayir | min=1; max=4; nullable |
| `unitPrice` | number (double) | Hayir | min=0; nullable |
| `validUntil` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataInboundAtfCompanyReceivingBatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `continueOnError` | boolean | Hayir |  |
| `items` | FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataInboundAtfCompanyReceivingHttpRequest[] | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataInboundAtfCompanyReceivingHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `allowOrderOverReceiving` | boolean | Hayir |  |
| `axataOrderNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `customerCode` | string | Evet | minLength=0; maxLength=25 |
| `deliverer` | string | Hayir | minLength=0; maxLength=100; nullable |
| `description` | string | Hayir | minLength=0; maxLength=250; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Evet | min=1; max=2147483647 |
| `documentSerie` | string | Evet | minLength=0; maxLength=20; pattern=^[A-Za-z0-9]+$ |
| `invoiceNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataInboundAtfCompanyReceivingLineHttpRequest[] | Evet |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `receiver` | string | Hayir | minLength=0; maxLength=100; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataInboundAtfCompanyReceivingLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lastConsumingDate` | string (date-time) | Hayir | nullable |
| `lineNo` | integer (int32) | Hayir | min=1; max=2147483647 |
| `lotNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `partyCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `productResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |
| `unitPrice` | number (double) | Hayir | min=0 |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataManualIncomingBatchFailureResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `errorMessage` | string | Hayir | nullable |
| `reference` | string | Hayir | nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataManualIncomingCompanyReceivingBatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `continueOnError` | boolean | Hayir |  |
| `items` | FurpaMerkezApi.WebApi.Controllers.Modules.MalKabulIslemleri.FirmaMalKabulleri.CreateCompanyReceivingHttpRequest[] | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataManualIncomingCompanyReceivingBatchResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `failedCount` | integer (int32) | Hayir |  |
| `failures` | FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataManualIncomingBatchFailureResponse[] | Hayir | nullable |
| `requestedCount` | integer (int32) | Hayir |  |
| `results` | FurpaMerkezApi.Application.Modules.MalKabulIslemleri.MalKabuller.CompanyReceiving.CreateCompanyReceivingResponse[] | Hayir | nullable |
| `succeededCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataManualIncomingInventoryCountBatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `continueOnError` | boolean | Hayir |  |
| `items` | FurpaMerkezApi.WebApi.Controllers.Modules.Common.CreateInventoryCountHttpRequest[] | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataManualIncomingInventoryCountBatchResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `failedCount` | integer (int32) | Hayir |  |
| `failures` | FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataManualIncomingBatchFailureResponse[] | Hayir | nullable |
| `requestedCount` | integer (int32) | Hayir |  |
| `results` | FurpaMerkezApi.Application.Modules.StokIslemleri.SayimSonuclari.CreateInventoryCountResponse[] | Hayir | nullable |
| `succeededCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataManualIncomingWarehouseReceivingBatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `continueOnError` | boolean | Hayir |  |
| `items` | FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataManualIncomingWarehouseReceivingBatchItemHttpRequest[] | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataManualIncomingWarehouseReceivingBatchItemHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `allowDiscrepancy` | boolean | Hayir |  |
| `documentOrderNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `documentSerie` | string | Evet | minLength=0; maxLength=25 |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.MalKabulIslemleri.DepoMalKabulleri.AcceptWarehouseReceivingLineHttpRequest[] | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataManualIncomingWarehouseReceivingBatchResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `failedCount` | integer (int32) | Hayir |  |
| `failures` | FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataManualIncomingBatchFailureResponse[] | Hayir | nullable |
| `requestedCount` | integer (int32) | Hayir |  |
| `results` | FurpaMerkezApi.Application.Modules.MalKabulIslemleri.MalKabuller.Accept.AcceptWarehouseReceivingResponse[] | Hayir | nullable |
| `succeededCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataManualOutboundDeliveryBatchResponse

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `failedCount` | integer (int32) | Hayir |  |
| `failures` | FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataManualIncomingBatchFailureResponse[] | Hayir | nullable |
| `requestedCount` | integer (int32) | Hayir |  |
| `results` | FurpaMerkezApi.Application.Modules.SevkIslemleri.DepolarArasiSevkler.Create.CreateInterWarehouseShipmentResponse[] | Hayir | nullable |
| `succeededCount` | integer (int32) | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryBatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `continueOnError` | boolean | Hayir |  |
| `items` | FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryHttpRequest[] | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryDocumentImportExecuteHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `acknowledge` | boolean | Hayir |  |
| `dateMode` | string | Hayir | minLength=0; maxLength=20; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `movementDate` | string (date-time) | Hayir | nullable |
| `status` | string | Hayir | pattern=^[01]$; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `axataDeliveryNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `description` | string | Hayir | minLength=0; maxLength=250; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryLineHttpRequest[] | Evet |  |
| `movementCode` | string | Hayir | minLength=0; maxLength=10; nullable |
| `movementDate` | string (date-time) | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |
| `targetWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |
| `transitWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryImportExecuteHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `acknowledge` | boolean | Hayir |  |
| `continueOnError` | boolean | Hayir |  |
| `dateMode` | string | Hayir | minLength=0; maxLength=20; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `movementDate` | string (date-time) | Hayir | nullable |
| `take` | integer (int32) | Hayir | min=1; max=200; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataOutboundDeliveryLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lineNo` | integer (int32) | Hayir | min=1; max=2147483647 |
| `lotNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `partyCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `productResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |
| `unitPrice` | number (double) | Hayir | min=0 |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataProductSynchronizationDispatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `continueOnError` | boolean | Hayir |  |
| `productCodes` | string[] | Hayir | nullable |
| `take` | integer (int32) | Hayir | min=1; max=100000; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationExecuteHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `executionMode` | string | Evet | minLength=1; pattern=^(DryRun\|Outbox\|Live)$ |
| `taskCode` | string | Evet | minLength=0; maxLength=100 |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationExecuteTaskHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `executionMode` | string | Evet | minLength=1; pattern=^(DryRun\|Outbox\|Live)$ |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentBatchExecuteHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `continueOnError` | boolean | Hayir |  |
| `documents` | FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentItemHttpRequest[] | Evet |  |
| `executionMode` | string | Evet | minLength=1; pattern=^(DryRun\|Outbox\|Live)$ |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentBatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `continueOnError` | boolean | Hayir |  |
| `documents` | FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentItemHttpRequest[] | Evet |  |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentExecuteHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `documentOrderNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `documentSerie` | string | Hayir | minLength=0; maxLength=25; nullable |
| `executionMode` | string | Evet | minLength=1; pattern=^(DryRun\|Outbox\|Live)$ |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `documentOrderNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `documentSerie` | string | Hayir | minLength=0; maxLength=25; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.AxataSenkronizasyonu.AxataSynchronizationManualDocumentItemHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `documentOrderNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `documentSerie` | string | Hayir | minLength=0; maxLength=25; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.Common.UyumsoftOperationHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `parameters` | FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.Common.UyumsoftOperationParameterHttpRequest[] | Hayir | nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.Common.UyumsoftOperationParameterHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `name` | string | Evet | minLength=0; maxLength=100 |
| `value` | string | Hayir | nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.CashRegisterBranchMappingHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchName` | string | Hayir | minLength=0; maxLength=100; nullable |
| `branchNo` | integer (int32) | Evet | min=1; max=2147483647 |
| `cashRegisterNo` | string | Evet | minLength=1; maxLength=40 |
| `description` | string | Hayir | minLength=0; maxLength=100; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.ImportPosDocumentsHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `businessDate` | string (date-time) | Hayir | nullable |
| `dateToGet` | string (date-time) | Hayir | nullable |
| `includePreviouslyImported` | boolean | Hayir |  |
| `overwriteExisting` | boolean | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.ImportZReportsHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `businessDate` | string (date-time) | Hayir | nullable |
| `importMode` | string | Hayir | minLength=0; maxLength=50; nullable |
| `overwriteExisting` | boolean | Hayir |  |
| `reportPath` | string | Hayir | minLength=0; maxLength=400; nullable |
| `sourceCode` | string | Hayir | minLength=0; maxLength=100; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.PosAccountingDeleteHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentIds` | integer (int32)[] | Hayir | nullable |
| `expenseIds` | integer (int32)[] | Hayir | nullable |
| `invoiceIds` | integer (int32)[] | Hayir | nullable |
| `totalIds` | integer (int32)[] | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.PosAccountingTransferHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `continueOnError` | boolean | Hayir |  |
| `documentIds` | integer (int32)[] | Hayir | nullable |
| `expenseIds` | integer (int32)[] | Hayir | nullable |
| `invoiceIds` | integer (int32)[] | Hayir | nullable |
| `totalIds` | integer (int32)[] | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.PosMuhasebeAktarimi.UpdatePosAccountingDocumentHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `customerTaxNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `description` | string | Hayir | minLength=0; maxLength=250; nullable |
| `documentNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `paymentType` | string | Hayir | minLength=0; maxLength=30; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.TrendyolGo.TrendyolGoCatalogDispatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcodes` | string[] | Hayir | nullable |
| `previewHash` | string | Evet | minLength=1 |
| `sendAll` | boolean | Hayir |  |
| `storeId` | integer (int64) | Hayir | min=1 |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.TrendyolGo.TrendyolGoInvoiceHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `bagCount` | integer (int32) | Hayir | min=0; max=10; nullable |
| `invoiceAmount` | number (double) | Hayir | min=0; max=79228162514264337593543950335; nullable |
| `invoiceTaxAmount` | number (double) | Hayir | min=0; max=79228162514264337593543950335; nullable |
| `receiptLink` | string (uri) | Hayir | maxLength=2048; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.EntegrasyonIslemleri.TrendyolGo.TrendyolGoPriceStockDispatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `barcodes` | string[] | Hayir | nullable |
| `mode` | string | Hayir | pattern=^(?i:selected\|changed\|all-existing)$; nullable |
| `previewHash` | string | Evet | minLength=1 |
| `sendAll` | boolean | Hayir |  |
| `storeId` | integer (int64) | Hayir | min=1 |

### FurpaMerkezApi.WebApi.Controllers.Modules.FaturaIslemleri.FaturaGonderimi.InvoicePreviewHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `invoiceId` | string | Hayir | nullable |
| `preferEmbeddedXslt` | boolean | Hayir |  |
| `profile` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.Common.InvoiceDocumentProfile | Hayir |  |
| `xmlContent` | string | Evet | minLength=1 |

### FurpaMerkezApi.WebApi.Controllers.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingBatchDocumentHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentOrderNo` | integer (int32) | Evet | min=1; max=2147483647 |
| `documentSerie` | string | Evet | minLength=1 |

### FurpaMerkezApi.WebApi.Controllers.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingBatchHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documents` | FurpaMerkezApi.WebApi.Controllers.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingBatchDocumentHttpRequest[] | Evet |  |
| `scenario` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingScenario | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingRenderHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `fallbackToGeneral` | boolean | Hayir |  |
| `preferEmbeddedXslt` | boolean | Hayir | nullable |
| `profile` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.Common.InvoiceDocumentProfile | Hayir |  |
| `scenario` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingScenario | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.FaturaIslemleri.FaturaGonderimi.UpdateInvoiceReturnReferenceHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `scenario` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.FaturaGonderimi.InvoiceSendingScenario | Hayir |  |
| `sourceDocumentOrderNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `sourceDocumentSerie` | string | Hayir | minLength=0; maxLength=20; nullable |
| `useFallbackWhenNotSelected` | boolean | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.FaturaIslemleri.FaturaGoruntuleme.InvoiceViewingPrintedStateHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `isPrinted` | boolean | Evet |  |
| `source` | string | Hayir | nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.FaturaIslemleri.FaturaGoruntuleme.InvoiceViewingRenderHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `fallbackToGeneral` | boolean | Hayir |  |
| `preferEmbeddedXslt` | boolean | Hayir | nullable |
| `profile` | FurpaMerkezApi.Application.Modules.FaturaIslemleri.Common.InvoiceDocumentProfile | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.FaturaIslemleri.FaturaGoruntuleme.InvoiceViewingSynchronizationHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `endDate` | string (date-time) | Evet |  |
| `includeStatuses` | boolean | Hayir | nullable |
| `startDate` | string (date-time) | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.GreenGrocer.Operations.GreenGrocerOperationsAdjustmentApplyHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `acceptor` | string | Hayir | minLength=0; maxLength=25; nullable |
| `clientRequestId` | string (uuid) | Evet |  |
| `counterWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |
| `creator` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `direction` | string | Evet | minLength=0; maxLength=30 |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `documentSerie` | string | Hayir | minLength=0; maxLength=20; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.GreenGrocer.Operations.GreenGrocerOperationsAdjustmentLineHttpRequest[] | Evet |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `reasonCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |

### FurpaMerkezApi.WebApi.Controllers.Modules.GreenGrocer.Operations.GreenGrocerOperationsAdjustmentLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lotNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `partyCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir | min=0.0001 |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |
| `unitPrice` | number (double) | Hayir | min=0 |

### FurpaMerkezApi.WebApi.Controllers.Modules.GreenGrocer.Operations.GreenGrocerOperationsAdjustmentPreviewHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `direction` | string | Evet | minLength=0; maxLength=30 |
| `documentSerie` | string | Hayir | minLength=0; maxLength=20; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.GreenGrocer.Operations.GreenGrocerOperationsAdjustmentLineHttpRequest[] | Evet |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `reasonCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |

### FurpaMerkezApi.WebApi.Controllers.Modules.GreenGrocer.ProductCases.GreenGrocerProductCaseResolutionHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `inputQuantity` | number (double) | Hayir | min=0.0001 |
| `orderDate` | string (date-time) | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `targetWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.GreenGrocer.ProductCases.SaveGreenGrocerProductCaseProfileHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `allowOrderLinking` | boolean | Hayir |  |
| `averageWindowDays` | integer (int32) | Hayir | min=1; max=365 |
| `conversionMode` | string | Evet | minLength=0; maxLength=60 |
| `inputMode` | string | Evet | minLength=0; maxLength=40 |
| `isActive` | boolean | Hayir |  |
| `manualKgPerCase` | number (double) | Hayir | min=0.0001; nullable |
| `manualUnitsPerCase` | number (double) | Hayir | min=0.0001; nullable |
| `maxCoefficientOfVariation` | number (double) | Hayir | min=0; max=10 |
| `maxExpectedKgPerCase` | number (double) | Hayir | min=0; nullable |
| `minAverageCaseCount` | integer (int32) | Hayir | min=0; max=100000 |
| `minAverageRecordCount` | integer (int32) | Hayir | min=0; max=100000 |
| `minExpectedKgPerCase` | number (double) | Hayir | min=0; nullable |
| `notes` | string | Hayir | minLength=0; maxLength=1000; nullable |
| `overDeliveryTolerancePercent` | number (double) | Hayir | min=0; max=1000 |
| `requiresManualApproval` | boolean | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.IadeIslemleri.DepoIadeleri.CreateWarehouseReturnHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientRequestId` | string (uuid) | Hayir | nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.IadeIslemleri.DepoIadeleri.CreateWarehouseReturnLineHttpRequest[] | Evet |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `targetWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |
| `transitWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.IadeIslemleri.DepoIadeleri.CreateWarehouseReturnLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lotNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `partyCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `productResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |
| `unitPrice` | number (double) | Hayir | min=0 |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.BanknotTakipleri.CreateBanknoteTrackHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `banknoteTrackDate` | string (date-time) | Evet |  |
| `deliverer` | string | Hayir | minLength=0; maxLength=100; nullable |
| `deliveryTotalAmount` | number (double) | Hayir | min=0 |
| `receiver` | string | Hayir | minLength=0; maxLength=100; nullable |
| `totalAmount` | number (double) | Hayir | min=0 |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.EtiketBelgeleri.CreateLabelDocumentHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.EtiketBelgeleri.CreateLabelDocumentLineHttpRequest[] | Evet |  |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.EtiketBelgeleri.CreateLabelDocumentLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `productCode` | string | Evet | minLength=0; maxLength=25 |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaCiroAktarimi.KasaCiroImportHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branches` | integer (int32)[] | Hayir | nullable |
| `dryRun` | boolean | Hayir |  |
| `endDate` | string (date-time) | Evet |  |
| `movementRootPath` | string | Hayir | minLength=0; maxLength=400; nullable |
| `startDate` | string (date-time) | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketDeleteStagingHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `cashRegisterNo` | integer (int32) | Hayir | min=0; max=999; nullable |
| `date` | string (date-time) | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketImportHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branches` | integer (int32)[] | Hayir | nullable |
| `cashRegisters` | integer (int32)[] | Hayir | nullable |
| `dryRun` | boolean | Hayir |  |
| `endDate` | string (date-time) | Evet |  |
| `fileRootPath` | string | Hayir | minLength=0; maxLength=400; nullable |
| `skipExisting` | boolean | Hayir |  |
| `startDate` | string (date-time) | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketMikroTransferHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `date` | string (date-time) | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketMikroTransferRangeHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `endDate` | string (date-time) | Evet |  |
| `startDate` | string (date-time) | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaHareketAktarimi.KasaHareketScheduledImportHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `addDay` | integer (int32) | Hayir | min=-30; max=30; nullable |
| `date` | string (date-time) | Hayir | nullable |
| `dryRun` | boolean | Hayir |  |
| `fileRootPath` | string | Hayir | minLength=0; maxLength=400; nullable |
| `skipExisting` | boolean | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.CreateBanknoteMovementHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `banknoteType` | integer (int32) | Evet | min=1; max=2147483647 |
| `quantity` | integer (int32) | Evet | min=0; max=2147483647 |
| `total` | number (double) | Hayir |  |
| `value` | number (double) | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.CreateCashSummaryHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `banknoteMovements` | FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.CreateBanknoteMovementHttpRequest[] | Hayir | nullable |
| `cashNo` | integer (int32) | Evet | min=1; max=2147483647 |
| `cashierNo` | integer (int32) | Evet | min=1; max=2147483647 |
| `giftCheckMovements` | FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.CreateGiftCheckMovementHttpRequest[] | Hayir | nullable |
| `managerNo` | integer (int32) | Evet | min=1; max=2147483647 |
| `paymentTypes` | FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.CreatePaymentTypeHttpRequest[] | Hayir | nullable |
| `storeExpenses` | FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.CreateStoreExpenseHttpRequest[] | Hayir | nullable |
| `summaryDate` | string (date-time) | Evet |  |
| `total` | number (double) | Hayir |  |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `zReportNo` | integer (int32) | Evet | min=0; max=2147483647 |
| `zTotalValue` | number (double) | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.CreateGiftCheckMovementHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `giftCheckType` | integer (int32) | Evet | min=1; max=2147483647 |
| `quantity` | integer (int32) | Evet | min=0; max=2147483647 |
| `total` | number (double) | Hayir |  |
| `value` | number (double) | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.CreatePaymentTypeHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accountCode` | string | Hayir | minLength=0; maxLength=40; nullable |
| `amountValue` | number (double) | Hayir |  |
| `paymentName` | string | Evet | minLength=0; maxLength=100 |
| `paymentTypeNo` | integer (int32) | Evet | min=1; max=2147483647 |
| `slipNumber` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `terminalId` | string | Hayir | minLength=0; maxLength=40; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.CreateStoreExpenseHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `amountValue` | number (double) | Hayir |  |
| `description` | string | Hayir | minLength=0; maxLength=250; nullable |
| `storeExpensesType` | integer (int32) | Evet | min=1; max=2147483647 |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.LegacyDeleteCashSummaryHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `cashNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `cashierNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `documentOrderNo` | integer (int32) | Evet | min=0; max=2147483647 |
| `documentSerie` | string | Evet | minLength=0; maxLength=20 |
| `managerNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `summaryDate` | string (date-time) | Hayir | nullable |
| `total` | number (double) | Hayir |  |
| `warehouse` | string | Hayir | minLength=0; maxLength=100; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `zReportNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.LegacyUpdateCashSummaryBanknoteLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `banknoteType` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `banknoteTypeID` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `quantity` | integer (int32) | Evet | min=0; max=2147483647 |
| `total` | number (double) | Hayir |  |
| `value` | number (double) | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.LegacyUpdateCashSummaryBanknotesHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `banknoteMovements` | FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.LegacyUpdateCashSummaryBanknoteLineHttpRequest[] | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Evet | min=0; max=2147483647 |
| `documentSerie` | string | Evet | minLength=0; maxLength=20 |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.LegacyUpdateCashSummaryDetailLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accountCode` | string | Hayir | minLength=0; maxLength=40; nullable |
| `amount` | number (double) | Hayir |  |
| `description` | string | Hayir | minLength=0; maxLength=250; nullable |
| `paymentTypeID` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `paymentTypeId` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `slipNumber` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `terminalId` | string | Hayir | minLength=0; maxLength=40; nullable |
| `typeName` | string | Hayir | minLength=0; maxLength=50; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.LegacyUpdateCashSummaryDetailsHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentOrderNo` | integer (int32) | Evet | min=0; max=2147483647 |
| `documentSerie` | string | Evet | minLength=0; maxLength=20 |
| `summariesDetails` | FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.LegacyUpdateCashSummaryDetailLineHttpRequest[] | Evet |  |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.LegacyUpdateCashSummaryGiftCheckLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `giftCheckType` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `giftCheckTypeID` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `quantity` | integer (int32) | Evet | min=0; max=2147483647 |
| `total` | number (double) | Hayir |  |
| `value` | number (double) | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.LegacyUpdateCashSummaryGiftChecksHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentOrderNo` | integer (int32) | Evet | min=0; max=2147483647 |
| `documentSerie` | string | Evet | minLength=0; maxLength=20 |
| `giftCheckMovements` | FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.LegacyUpdateCashSummaryGiftCheckLineHttpRequest[] | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.UpdateCashSummaryBanknoteLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `banknoteType` | integer (int32) | Evet | min=1; max=2147483647 |
| `quantity` | integer (int32) | Evet | min=0; max=2147483647 |
| `total` | number (double) | Hayir |  |
| `value` | number (double) | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.UpdateCashSummaryBanknotesHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `banknoteMovements` | FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.UpdateCashSummaryBanknoteLineHttpRequest[] | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.UpdateCashSummaryDetailLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `accountCode` | string | Hayir | minLength=0; maxLength=40; nullable |
| `amount` | number (double) | Hayir |  |
| `description` | string | Hayir | minLength=0; maxLength=250; nullable |
| `paymentTypeId` | integer (int32) | Evet | min=0; max=2147483647 |
| `slipNumber` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `terminalId` | string | Hayir | minLength=0; maxLength=40; nullable |
| `typeName` | string | Hayir | minLength=0; maxLength=50; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.UpdateCashSummaryDetailsHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `details` | FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.UpdateCashSummaryDetailLineHttpRequest[] | Evet |  |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.UpdateCashSummaryGiftCheckLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `giftCheckType` | integer (int32) | Evet | min=1; max=2147483647 |
| `quantity` | integer (int32) | Evet | min=0; max=2147483647 |
| `total` | number (double) | Hayir |  |
| `value` | number (double) | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.UpdateCashSummaryGiftChecksHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `giftCheckMovements` | FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.KasaSayimlari.UpdateCashSummaryGiftCheckLineHttpRequest[] | Hayir | nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketCalculationHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `caseCount` | integer (int32) | Hayir | nullable |
| `caseTare` | number (double) | Hayir |  |
| `grossWeight` | number (double) | Hayir |  |
| `palletTare` | number (double) | Hayir | nullable |
| `stockBarcode` | string | Hayir | minLength=0; maxLength=50; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketCreateMicroGoodsReceiptHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `date` | string (date-time) | Evet |  |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `documentNo` | string | Hayir | minLength=0; maxLength=25; nullable |
| `documentOrderNo` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `documentSeries` | string | Hayir | minLength=0; maxLength=25; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketCreateMicroGoodsReceiptLineHttpRequest[] | Evet |  |
| `markAcceptanceRecordsTransferred` | boolean | Hayir |  |
| `mikroUserNo` | integer (int32) | Hayir | min=0; max=32767; nullable |
| `supplierCode` | string | Evet | minLength=0; maxLength=25 |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.ManavMalKabulVeEtiket.ManavMalKabulVeEtiketCreateMicroGoodsReceiptLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `acceptanceRecordId` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `taxAmount` | number (double) | Hayir | nullable |
| `taxPointer` | integer (int32) | Hayir | min=0; max=255; nullable |
| `taxRatePercent` | number (double) | Hayir | min=0; max=100; nullable |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |
| `unitPrice` | number (double) | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.KasaIslemleri.ManavMalKabulVeEtiket.SaveManavMalKabulVeEtiketAcceptanceRecordHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `caseCount` | integer (int32) | Hayir | nullable |
| `caseTare` | number (double) | Hayir |  |
| `caseType` | string | Evet | minLength=0; maxLength=20 |
| `documentNo` | string | Evet | minLength=0; maxLength=25 |
| `documentSeries` | string | Hayir | minLength=0; maxLength=25; nullable |
| `grossWeight` | number (double) | Hayir |  |
| `palletTare` | number (double) | Hayir | nullable |
| `receivedBy` | string | Evet | minLength=0; maxLength=100 |
| `stockBarcode` | string | Evet | minLength=0; maxLength=50 |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `stockName` | string | Evet | minLength=0; maxLength=255 |
| `supplierCode` | string | Evet | minLength=0; maxLength=25 |
| `supplierName` | string | Evet | minLength=0; maxLength=255 |

### FurpaMerkezApi.WebApi.Controllers.Modules.MalKabulIslemleri.DepoMalKabulleri.AcceptWarehouseReceivingHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `allowDiscrepancy` | boolean | Hayir |  |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.MalKabulIslemleri.DepoMalKabulleri.AcceptWarehouseReceivingLineHttpRequest[] | Evet |  |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.MalKabulIslemleri.DepoMalKabulleri.AcceptWarehouseReceivingLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `movementGuid` | string (uuid) | Hayir |  |
| `receivedQuantity` | number (double) | Hayir | min=0 |

### FurpaMerkezApi.WebApi.Controllers.Modules.MalKabulIslemleri.FirmaMalKabulleri.CreateCompanyReceivingHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `allowOrderOverReceiving` | boolean | Hayir |  |
| `autoCreateReturnForPartialAcceptance` | boolean | Hayir |  |
| `clientRequestId` | string (uuid) | Hayir | nullable |
| `customerCode` | string | Evet | minLength=0; maxLength=25 |
| `deliverer` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `despatchNumber` | string | Hayir | minLength=0; maxLength=50; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentOrderNo` | integer (int32) | Evet | min=1; max=2147483647 |
| `documentSerie` | string | Evet | minLength=0; maxLength=20; pattern=^[A-Za-z0-9]+$ |
| `ettn` | string | Hayir | minLength=0; maxLength=50; nullable |
| `invoiceDate` | string (date-time) | Hayir | nullable |
| `invoiceNumber` | string | Hayir | minLength=0; maxLength=50; nullable |
| `issueDate` | string (date-time) | Hayir | nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.MalKabulIslemleri.FirmaMalKabulleri.CreateCompanyReceivingLineHttpRequest[] | Evet |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `officialDocumentDate` | string (date-time) | Hayir | nullable |
| `officialDocumentEttn` | string | Hayir | minLength=0; maxLength=50; nullable |
| `officialDocumentKind` | string | Hayir | minLength=0; maxLength=30; nullable |
| `officialDocumentNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `receiver` | string | Hayir | minLength=0; maxLength=25; nullable |
| `sourceDocumentDate` | string (date-time) | Hayir | nullable |
| `sourceDocumentKind` | string | Hayir | minLength=0; maxLength=30; nullable |
| `sourceDocumentNumber` | string | Hayir | minLength=0; maxLength=50; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.MalKabulIslemleri.FirmaMalKabulleri.CreateCompanyReceivingLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `acceptedQuantity` | number (double) | Hayir | min=0; nullable |
| `customerResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `dispatchQuantity` | number (double) | Hayir | nullable |
| `lastConsumingDate` | string (date-time) | Hayir | nullable |
| `lotNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `orderGuid` | string (uuid) | Hayir | nullable |
| `partyCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `productResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir | nullable |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |
| `unitPrice` | number (double) | Hayir | min=0 |

### FurpaMerkezApi.WebApi.Controllers.Modules.OperasyonIslemleri.ProductDistributionBalanceHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.OperasyonIslemleri.ProductDistributionBalanceLineHttpRequest[] | Evet |  |
| `referenceDate` | string (date-time) | Hayir | nullable |
| `salesDayCount` | integer (int32) | Hayir | min=1; max=365; nullable |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `targetCaseQuantity` | integer (int32) | Hayir | min=0; max=2147483647 |

### FurpaMerkezApi.WebApi.Controllers.Modules.OperasyonIslemleri.ProductDistributionBalanceLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchAverageDailySales` | number (double) | Hayir |  |
| `caseQuantity` | integer (int32) | Hayir | min=0; max=2147483647 |
| `companyAverageDailySales` | number (double) | Hayir |  |
| `currentStockQuantity` | number (double) | Hayir |  |
| `isLocked` | boolean | Hayir |  |
| `lastSalesQuantity` | number (double) | Hayir |  |
| `regionCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `warehouseName` | string | Hayir | minLength=0; maxLength=100; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |

### FurpaMerkezApi.WebApi.Controllers.Modules.OperasyonIslemleri.ProductDistributionFinalizeHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `allowFinalizeWithoutNotification` | boolean | Hayir |  |
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `finalizeBy` | string | Hayir | minLength=0; maxLength=100; nullable |
| `orderDate` | string (date-time) | Hayir | nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.OperasyonIslemleri.ProductDistributionNotifyHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `markStockOrderingStopped` | boolean | Hayir |  |
| `notifyBy` | string | Hayir | minLength=0; maxLength=100; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.OperasyonIslemleri.ProductDistributionProposalHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `allocatedCaseQuantity` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `distributionCenterWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |
| `includeBranchesWithoutSales` | boolean | Hayir |  |
| `referenceDate` | string (date-time) | Hayir | nullable |
| `salesDayCount` | integer (int32) | Hayir | min=1; max=365; nullable |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `targetCaseQuantity` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `totalCaseQuantity` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.OperasyonIslemleri.ProductDistributionSaveHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `allocatedCaseQuantity` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `distributedBy` | string | Hayir | minLength=0; maxLength=100; nullable |
| `distributionCenterWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.OperasyonIslemleri.ProductDistributionSaveLineHttpRequest[] | Evet |  |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `targetCaseQuantity` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `totalCaseQuantity` | integer (int32) | Hayir | min=0; max=2147483647 |

### FurpaMerkezApi.WebApi.Controllers.Modules.OperasyonIslemleri.ProductDistributionSaveLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `branchAverageDailySales` | number (double) | Hayir | min=0; nullable |
| `caseQuantity` | integer (int32) | Hayir | min=0; max=2147483647 |
| `companyAverageDailySales` | number (double) | Hayir | min=0; nullable |
| `lastSalesQuantity` | number (double) | Hayir | min=0; nullable |
| `unitQuantity` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |

### FurpaMerkezApi.WebApi.Controllers.Modules.OperasyonIslemleri.SaveAuthorizationFileHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `id` | integer (int32) | Hayir | min=1; max=2147483647 |
| `name` | string | Evet | minLength=0; maxLength=100 |
| `r` | boolean | Hayir |  |
| `updateDate` | string (date-time) | Hayir | nullable |
| `x` | boolean | Hayir |  |
| `z` | boolean | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.OrtakIslemler.Duyurular.SaveAnnouncementHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `expiresAtUtc` | string (date-time) | Hayir | nullable |
| `message` | string | Evet | minLength=0; maxLength=4000 |
| `priority` | string | Hayir | minLength=0; maxLength=30; nullable |
| `startsAtUtc` | string (date-time) | Hayir | nullable |
| `targetType` | string | Evet | minLength=0; maxLength=30 |
| `targetUserIds` | string (uuid)[] | Hayir | nullable |
| `targetWarehouseNos` | integer (int32)[] | Hayir | nullable |
| `title` | string | Evet | minLength=0; maxLength=140 |

### FurpaMerkezApi.WebApi.Controllers.Modules.OrtakIslemler.SikayetOneri.ChangeFeedbackStatusHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `adminNote` | string | Hayir | minLength=0; maxLength=1000; nullable |
| `status` | string | Evet | minLength=0; maxLength=30 |

### FurpaMerkezApi.WebApi.Controllers.Modules.OrtakIslemler.SikayetOneri.CreateFeedbackItemHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `message` | string | Evet | minLength=0; maxLength=2000 |
| `priority` | string | Hayir | minLength=0; maxLength=30; nullable |
| `title` | string | Evet | minLength=0; maxLength=120 |
| `type` | string | Evet | minLength=0; maxLength=30 |

### FurpaMerkezApi.WebApi.Controllers.Modules.SevkIslemleri.DepolarArasiSevkler.CreateInterWarehouseShipmentHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `clientRequestId` | string (uuid) | Hayir | nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `documentDate` | string (date-time) | Hayir | nullable |
| `documentNo` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.SevkIslemleri.DepolarArasiSevkler.CreateInterWarehouseShipmentLineHttpRequest[] | Evet |  |
| `movementDate` | string (date-time) | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `targetWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |
| `transitWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.SevkIslemleri.DepolarArasiSevkler.CreateInterWarehouseShipmentLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lotNo` | integer (int32) | Hayir | min=0; max=2147483647 |
| `partyCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `productResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir |  |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |
| `unitPrice` | number (double) | Hayir | min=0 |
| `warehouseOrderLineGuid` | string (uuid) | Hayir | nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.AlinanDepoSiparisleri.BulkPrintReceivedWarehouseOrdersHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `documentKeys` | string[] | Evet |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.OnerilenDepoSiparisleri.ConvertSuggestedWarehouseOrderHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.OnerilenDepoSiparisleri.ConvertSuggestedWarehouseOrderLineHttpRequest[] | Evet |  |
| `orderDate` | string (date-time) | Hayir | nullable |
| `sourceWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |
| `targetWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.OnerilenDepoSiparisleri.ConvertSuggestedWarehouseOrderLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `packageCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir |  |
| `recommendedQuantity` | number (double) | Hayir | min=0; nullable |
| `responsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |
| `unitPrice` | number (double) | Hayir | min=0 |

### FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.OnerilenFirmaSiparisleri.ConvertSuggestedCompanyOrderHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deliverer` | string | Hayir | minLength=0; maxLength=25; nullable |
| `deliveryDate` | string (date-time) | Evet |  |
| `description1` | string | Hayir | minLength=0; maxLength=50; nullable |
| `description2` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.OnerilenFirmaSiparisleri.ConvertSuggestedCompanyOrderLineHttpRequest[] | Evet |  |
| `orderDate` | string (date-time) | Hayir | nullable |
| `receiver` | string | Hayir | minLength=0; maxLength=25; nullable |
| `supplierCode` | string | Evet | minLength=0; maxLength=25 |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.OnerilenFirmaSiparisleri.ConvertSuggestedCompanyOrderLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description1` | string | Hayir | minLength=0; maxLength=50; nullable |
| `description2` | string | Hayir | minLength=0; maxLength=50; nullable |
| `packageCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `productResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir |  |
| `recommendedQuantity` | number (double) | Hayir | min=0; nullable |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |
| `unitPrice` | number (double) | Hayir | min=0 |

### FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.VerilenDepoSiparisleri.CreateIssuedWarehouseOrderHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `deliveryDate` | string (date-time) | Hayir | nullable |
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `inWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.VerilenDepoSiparisleri.CreateIssuedWarehouseOrderLineHttpRequest[] | Evet |  |
| `orderDate` | string (date-time) | Hayir | nullable |
| `outWarehouseNo` | integer (int32) | Hayir | min=1; max=2147483647 |

### FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.VerilenDepoSiparisleri.CreateIssuedWarehouseOrderLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | minLength=0; maxLength=50; nullable |
| `greenGrocerCase` | FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.VerilenDepoSiparisleri.GreenGrocerOrderLineSnapshotHttpRequest | Hayir |  |
| `packageCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir |  |
| `recommendedQuantity` | number (double) | Hayir | min=0; nullable |
| `responsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |
| `unitPrice` | number (double) | Hayir | min=0 |

### FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.VerilenDepoSiparisleri.GreenGrocerOrderLineSnapshotHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `averageCaseCount` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `averageKgPerCase` | number (double) | Hayir | nullable |
| `averageRecordCount` | integer (int32) | Hayir | min=0; max=2147483647; nullable |
| `averageSource` | string | Evet | minLength=0; maxLength=60 |
| `coefficientOfVariation` | number (double) | Hayir | min=0; nullable |
| `confidence` | string | Evet | minLength=0; maxLength=30 |
| `conversionMode` | string | Evet | minLength=0; maxLength=60 |
| `estimatedQuantity` | number (double) | Hayir |  |
| `inputMode` | string | Evet | minLength=0; maxLength=40 |
| `inputQuantity` | number (double) | Hayir |  |
| `microUnit` | string | Evet | minLength=0; maxLength=20 |
| `unitsPerCase` | number (double) | Hayir | nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.VerilenFirmaSiparisleri.CreateIssuedCompanyOrderHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerCode` | string | Evet | minLength=0; maxLength=25 |
| `deliverer` | string | Hayir | minLength=0; maxLength=25; nullable |
| `deliveryDate` | string (date-time) | Evet |  |
| `description1` | string | Hayir | minLength=0; maxLength=50; nullable |
| `description2` | string | Hayir | minLength=0; maxLength=50; nullable |
| `lines` | FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.VerilenFirmaSiparisleri.CreateIssuedCompanyOrderLineHttpRequest[] | Evet |  |
| `orderDate` | string (date-time) | Hayir | nullable |
| `receiver` | string | Hayir | minLength=0; maxLength=25; nullable |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.Modules.SiparisIslemleri.VerilenFirmaSiparisleri.CreateIssuedCompanyOrderLineHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `customerResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `description1` | string | Hayir | minLength=0; maxLength=50; nullable |
| `description2` | string | Hayir | minLength=0; maxLength=50; nullable |
| `packageCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `productResponsibilityCenter` | string | Hayir | minLength=0; maxLength=25; nullable |
| `projectCode` | string | Hayir | minLength=0; maxLength=25; nullable |
| `quantity` | number (double) | Hayir |  |
| `recommendedQuantity` | number (double) | Hayir | min=0; nullable |
| `stockCode` | string | Evet | minLength=0; maxLength=25 |
| `unitPointer` | integer (int32) | Hayir | min=1; max=255 |
| `unitPrice` | number (double) | Hayir | min=0 |

### FurpaMerkezApi.WebApi.Controllers.Modules.StokIslemleri.StokAnomaliMerkezi.ChangeStockAnomalyStatusHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `note` | string | Hayir | minLength=0; maxLength=500; nullable |
| `status` | FurpaMerkezApi.Domain.Entities.StockAnomalyStatus | Hayir |  |

### FurpaMerkezApi.WebApi.Controllers.Modules.StokIslemleri.StokAnomaliMerkezi.StockAnomalyScanHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `dormantDays` | integer (int32) | Hayir | min=1; max=3650 |
| `endDate` | string (date-time) | Hayir | nullable |
| `highQuantityLookbackDays` | integer (int32) | Hayir | min=1; max=365 |
| `highQuantityMinimum` | number (double) | Hayir | min=0 |
| `highQuantityMultiplier` | number (double) | Hayir | min=1.01; max=100 |
| `pendingTransferHours` | integer (int32) | Hayir | min=1; max=720 |
| `startDate` | string (date-time) | Hayir | nullable |
| `takePerRule` | integer (int32) | Hayir | min=1; max=1000 |
| `warehouseNo` | integer (int32) | Hayir | min=1; max=2147483647; nullable |

### FurpaMerkezApi.WebApi.Controllers.PermissionsController.SavePermissionBody

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `code` | string | Evet | minLength=0; maxLength=100 |
| `description` | string | Hayir | minLength=0; maxLength=250; nullable |
| `name` | string | Evet | minLength=0; maxLength=100 |

### FurpaMerkezApi.WebApi.Controllers.RolesController.AssignPermissionsBody

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `permissionIds` | string (uuid)[] | Evet | nullable |

### FurpaMerkezApi.WebApi.Controllers.RolesController.SaveRoleBody

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `description` | string | Hayir | minLength=0; maxLength=250; nullable |
| `isActive` | boolean | Evet |  |
| `name` | string | Evet | minLength=0; maxLength=100 |

### FurpaMerkezApi.WebApi.Controllers.TerminalHeartbeatHttpRequest

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `androidSdk` | integer (int32) | Hayir | min=1; max=1000; nullable |
| `androidVersion` | string | Hayir | minLength=0; maxLength=40; nullable |
| `appVersion` | string | Evet | minLength=0; maxLength=40 |
| `buildNumber` | integer (int32) | Hayir | min=1; max=2147483647 |
| `deviceModel` | string | Hayir | minLength=0; maxLength=150; nullable |
| `manufacturer` | string | Hayir | minLength=0; maxLength=100; nullable |
| `supportedAbis` | string[] | Hayir | nullable |

### FurpaMerkezApi.WebApi.Controllers.UsersController.AssignClientRolesBody

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `roleIds` | string (uuid)[] | Evet | nullable |

### FurpaMerkezApi.WebApi.Controllers.UsersController.AssignRolesBody

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `roleIds` | string (uuid)[] | Evet | nullable |

### FurpaMerkezApi.WebApi.Controllers.UsersController.UpdateUserBody

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `email` | string (email) | Evet | minLength=0; maxLength=200 |
| `firstName` | string | Evet | minLength=0; maxLength=100 |
| `isActive` | boolean | Evet |  |
| `lastName` | string | Evet | minLength=0; maxLength=100 |
| `newPassword` | string | Hayir | minLength=0; maxLength=200; nullable |
| `username` | string | Evet | minLength=0; maxLength=50 |
| `warehouseName` | string | Evet | minLength=0; maxLength=150 |
| `warehouseNo` | string | Evet | minLength=0; maxLength=50 |

### Microsoft.AspNetCore.Mvc.ProblemDetails

| JSON alani | Tip | Zorunlu | Sinirlar |
|---|---|---|---|
| `detail` | string | Hayir | nullable |
| `instance` | string | Hayir | nullable |
| `status` | integer (int32) | Hayir | nullable |
| `title` | string | Hayir | nullable |
| `type` | string | Hayir | nullable |

