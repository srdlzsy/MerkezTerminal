package com.furpa.furpa_merkez_terminal

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private var pendingApkFile: File? = null
    private lateinit var updateChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        updateChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            UPDATE_CHANNEL,
        )
        updateChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppVersion" -> result.success(appVersionName())
                "getAppVersionInfo" -> result.success(
                    mapOf(
                        "versionName" to appVersionName(),
                        "versionCode" to appVersionCode(),
                    ),
                )
                "getSupportedAbis" -> result.success(Build.SUPPORTED_ABIS.toList())
                "downloadAndInstallApk" -> {
                    val url = call.argument<String>("url")
                    val fileName = call.argument<String>("fileName")
                    val requestId = call.argument<String>("requestId")
                    val expectedVersion = call.argument<String>("expectedVersion")
                    val expectedVersionCode =
                        call.argument<Number>("expectedVersionCode")?.toLong()
                    if (url.isNullOrBlank()) {
                        result.error(
                            "INVALID_URL",
                            "APK adresi gecersiz.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    downloadAndInstallApk(
                        url,
                        sanitizedFileName(fileName ?: DEFAULT_APK_FILE_NAME),
                        requestId,
                        expectedVersion,
                        expectedVersionCode,
                        result,
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()

        val apkFile = pendingApkFile ?: return
        if (canInstallApks()) {
            pendingApkFile = null
            openInstaller(apkFile)
        }
    }

    private fun appVersionName(): String {
        val packageInfo = installedPackageInfo(0)
        return packageInfo.versionName ?: "0.0.0"
    }

    private fun appVersionCode(): Long = packageVersionCode(installedPackageInfo(0))

    private fun downloadAndInstallApk(
        url: String,
        fileName: String,
        requestId: String?,
        expectedVersion: String?,
        expectedVersionCode: Long?,
        result: MethodChannel.Result,
    ) {
        thread(name = "furpa-apk-download") {
            var connection: HttpURLConnection? = null
            var downloadedApkFile: File? = null
            try {
                val apkUrl = URL(url)
                connection = apkUrl.openConnection() as HttpURLConnection
                connection.connectTimeout = CONNECT_TIMEOUT_MS
                connection.readTimeout = READ_TIMEOUT_MS
                connection.instanceFollowRedirects = true
                connection.useCaches = false
                connection.requestMethod = "GET"
                connection.setRequestProperty("Cache-Control", "no-cache, no-store")
                connection.setRequestProperty("Pragma", "no-cache")
                connection.connect()

                val statusCode = connection.responseCode
                if (statusCode !in 200..299) {
                    throw IOException("APK indirilemedi. HTTP $statusCode")
                }
                val totalBytes = connection.contentLengthLong

                val updateDir = File(cacheDir, UPDATE_CACHE_DIR)
                if (!updateDir.exists() && !updateDir.mkdirs()) {
                    throw IOException("Guncelleme klasoru hazirlanamadi.")
                }
                ensureEnoughStorage(updateDir, totalBytes)

                val apkFile = File(updateDir, fileName)
                downloadedApkFile = apkFile
                if (apkFile.exists() && !apkFile.delete()) {
                    throw IOException("Eski guncelleme dosyasi silinemedi.")
                }
                var bytesDownloaded = 0L
                var lastProgressAt = 0L
                emitDownloadProgress(requestId, bytesDownloaded, totalBytes)
                connection.inputStream.use { input ->
                    FileOutputStream(apkFile).use { output ->
                        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                        while (true) {
                            val bytesRead = input.read(buffer)
                            if (bytesRead == -1) {
                                break
                            }
                            output.write(buffer, 0, bytesRead)
                            bytesDownloaded += bytesRead.toLong()

                            val now = System.currentTimeMillis()
                            if (
                                now - lastProgressAt >= PROGRESS_EMIT_INTERVAL_MS ||
                                totalBytes > 0 && bytesDownloaded >= totalBytes
                            ) {
                                emitDownloadProgress(
                                    requestId,
                                    bytesDownloaded,
                                    totalBytes,
                                )
                                lastProgressAt = now
                            }
                        }
                    }
                }
                emitDownloadProgress(requestId, bytesDownloaded, totalBytes)
                if (bytesDownloaded <= 0L) {
                    throw ApkValidationException("Indirilen APK dosyasi bos.")
                }
                if (totalBytes > 0L && bytesDownloaded != totalBytes) {
                    throw ApkValidationException(
                        "APK eksik indirildi ($bytesDownloaded / $totalBytes bayt).",
                    )
                }
                validateDownloadedApk(
                    apkFile,
                    expectedVersion,
                    expectedVersionCode,
                )

                runOnUiThread {
                    try {
                        result.success(openInstaller(apkFile))
                    } catch (error: Exception) {
                        result.error(
                            "INSTALL_FAILED",
                            error.localizedMessage ?: "Kurulum baslatilamadi.",
                            null,
                        )
                    }
                }
            } catch (error: InsufficientStorageException) {
                downloadedApkFile?.delete()
                runOnUiThread {
                    result.error(
                        "INSUFFICIENT_STORAGE",
                        error.localizedMessage,
                        null,
                    )
                }
            } catch (error: ApkValidationException) {
                downloadedApkFile?.delete()
                runOnUiThread {
                    result.error(
                        "INVALID_APK",
                        error.localizedMessage,
                        null,
                    )
                }
            } catch (error: Exception) {
                downloadedApkFile?.delete()
                runOnUiThread {
                    result.error(
                        "DOWNLOAD_FAILED",
                        error.localizedMessage ?: "APK indirilemedi.",
                        null,
                    )
                }
            } finally {
                connection?.disconnect()
            }
        }
    }

    private fun ensureEnoughStorage(updateDir: File, totalBytes: Long) {
        if (totalBytes <= 0L) {
            return
        }

        val requiredBytes = totalBytes * 2L + MIN_FREE_STORAGE_RESERVE_BYTES
        if (updateDir.usableSpace < requiredBytes) {
            val requiredMb = requiredBytes / BYTES_PER_MB
            val availableMb = updateDir.usableSpace / BYTES_PER_MB
            throw InsufficientStorageException(
                "Guncelleme icin yeterli bos alan yok. Gerekli: yaklasik " +
                    "$requiredMb MB, kullanilabilir: $availableMb MB.",
            )
        }
    }

    private fun validateDownloadedApk(
        apkFile: File,
        expectedVersion: String?,
        expectedVersionCode: Long?,
    ) {
        val signingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_SIGNATURES
        }
        val archiveInfo = archivePackageInfo(apkFile, signingFlags)
            ?: throw ApkValidationException(
                "Indirilen dosya gecerli bir Android APK'si degil.",
            )
        if (archiveInfo.packageName != packageName) {
            throw ApkValidationException(
                "Indirilen APK bu uygulamaya ait degil (${archiveInfo.packageName}).",
            )
        }

        val archiveVersion = archiveInfo.versionName.orEmpty()
        if (
            !expectedVersion.isNullOrBlank() &&
            normalizeVersion(archiveVersion) != normalizeVersion(expectedVersion)
        ) {
            throw ApkValidationException(
                "Sunucudaki APK surumu beklenen surumle uyusmuyor. " +
                    "Beklenen: $expectedVersion, APK: $archiveVersion. " +
                    "APK dosyasini yeniden yayinlayin.",
            )
        }

        val archiveVersionCode = packageVersionCode(archiveInfo)
        if (expectedVersionCode != null && archiveVersionCode != expectedVersionCode) {
            throw ApkValidationException(
                "Sunucudaki APK yapi numarasi uyusmuyor. " +
                    "Beklenen: $expectedVersionCode, APK: $archiveVersionCode.",
            )
        }

        val installedInfo = installedPackageInfo(signingFlags)
        val installedVersionCode = packageVersionCode(installedInfo)
        if (archiveVersionCode <= installedVersionCode) {
            throw ApkValidationException(
                "Indirilen APK yeni degil. Kurulu yapi: $installedVersionCode, " +
                    "APK yapisi: $archiveVersionCode. Sunucudaki dosyayi kontrol edin.",
            )
        }

        val installedSignatures = signingDigests(installedInfo)
        val archiveSignatures = signingDigests(archiveInfo)
        if (
            installedSignatures.isNotEmpty() &&
            archiveSignatures.isNotEmpty() &&
            installedSignatures.intersect(archiveSignatures).isEmpty()
        ) {
            throw ApkValidationException(
                "Guncelleme APK'sinin imzasi kurulu uygulamayla uyusmuyor.",
            )
        }
    }

    private fun installedPackageInfo(flags: Int): PackageInfo {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(
                packageName,
                PackageManager.PackageInfoFlags.of(flags.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, flags)
        }
    }

    private fun archivePackageInfo(apkFile: File, flags: Int): PackageInfo? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageArchiveInfo(
                apkFile.absolutePath,
                PackageManager.PackageInfoFlags.of(flags.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageArchiveInfo(apkFile.absolutePath, flags)
        }
    }

    private fun packageVersionCode(packageInfo: PackageInfo): Long {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            packageInfo.versionCode.toLong()
        }
    }

    private fun signingDigests(packageInfo: PackageInfo): Set<String> {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val signingInfo = packageInfo.signingInfo ?: return emptySet()
            if (signingInfo.hasMultipleSigners()) {
                signingInfo.apkContentsSigners
            } else {
                signingInfo.signingCertificateHistory
            }
        } else {
            @Suppress("DEPRECATION")
            packageInfo.signatures
        }

        return signatures.orEmpty().map { signature ->
            MessageDigest.getInstance("SHA-256")
                .digest(signature.toByteArray())
                .joinToString("") { byte -> "%02x".format(byte) }
        }.toSet()
    }

    private fun normalizeVersion(version: String): String {
        return version.trim().removePrefix("v").substringBefore("+")
    }

    private fun emitDownloadProgress(
        requestId: String?,
        bytesRead: Long,
        totalBytes: Long,
    ) {
        if (requestId.isNullOrBlank()) {
            return
        }

        runOnUiThread {
            updateChannel.invokeMethod(
                "downloadProgress",
                mapOf(
                    "requestId" to requestId,
                    "bytesRead" to bytesRead,
                    "totalBytes" to totalBytes,
                ),
            )
        }
    }

    private fun openInstaller(apkFile: File): Boolean {
        if (!apkFile.exists()) {
            throw IOException("APK dosyasi bulunamadi.")
        }

        if (!canInstallApks()) {
            pendingApkFile = apkFile
            val settingsIntent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:$packageName"),
            )
            openUnknownSourcesSettings(settingsIntent)
            return false
        }

        val apkUri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            apkFile,
        )
        val installIntent = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
            setDataAndType(apkUri, APK_MIME_TYPE)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, true)
            putExtra(Intent.EXTRA_RETURN_RESULT, true)
        }

        startActivity(installIntent)
        return true
    }

    private fun openUnknownSourcesSettings(settingsIntent: Intent) {
        try {
            startActivity(settingsIntent)
        } catch (_: ActivityNotFoundException) {
            startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS))
        }
    }

    private fun canInstallApks(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            packageManager.canRequestPackageInstalls()
    }

    private fun sanitizedFileName(fileName: String): String {
        val sanitized = fileName.replace(Regex("[^A-Za-z0-9._-]"), "_")
        return sanitized.ifBlank { DEFAULT_APK_FILE_NAME }
    }

    private companion object {
        const val UPDATE_CHANNEL = "furpa_merkez_terminal/update"
        const val DEFAULT_APK_FILE_NAME = "furpa-terminal-update.apk"
        const val UPDATE_CACHE_DIR = "updates"
        const val APK_MIME_TYPE = "application/vnd.android.package-archive"
        const val CONNECT_TIMEOUT_MS = 15_000
        const val READ_TIMEOUT_MS = 60_000
        const val PROGRESS_EMIT_INTERVAL_MS = 250L
        const val BYTES_PER_MB = 1024L * 1024L
        const val MIN_FREE_STORAGE_RESERVE_BYTES = 32L * BYTES_PER_MB
    }
}

private class InsufficientStorageException(message: String) : IOException(message)

private class ApkValidationException(message: String) : IOException(message)
