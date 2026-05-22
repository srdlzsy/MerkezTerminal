package com.furpa.furpa_merkez_terminal

import android.content.Intent
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
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private var pendingApkFile: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            UPDATE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppVersion" -> result.success(appVersionName())
                "downloadAndInstallApk" -> {
                    val url = call.argument<String>("url")
                    val fileName = call.argument<String>("fileName")
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
        val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(
                packageName,
                PackageManager.PackageInfoFlags.of(0),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, 0)
        }

        return packageInfo.versionName ?: "0.0.0"
    }

    private fun downloadAndInstallApk(
        url: String,
        fileName: String,
        result: MethodChannel.Result,
    ) {
        thread(name = "furpa-apk-download") {
            var connection: HttpURLConnection? = null
            try {
                val apkUrl = URL(url)
                connection = apkUrl.openConnection() as HttpURLConnection
                connection.connectTimeout = CONNECT_TIMEOUT_MS
                connection.readTimeout = READ_TIMEOUT_MS
                connection.instanceFollowRedirects = true
                connection.requestMethod = "GET"
                connection.connect()

                val statusCode = connection.responseCode
                if (statusCode !in 200..299) {
                    throw IOException("APK indirilemedi. HTTP $statusCode")
                }

                val apkFile = File(cacheDir, fileName)
                connection.inputStream.use { input ->
                    FileOutputStream(apkFile).use { output ->
                        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                        while (true) {
                            val bytesRead = input.read(buffer)
                            if (bytesRead == -1) {
                                break
                            }
                            output.write(buffer, 0, bytesRead)
                        }
                    }
                }

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
            } catch (error: Exception) {
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
            startActivity(settingsIntent)
            return false
        }

        val apkUri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            apkFile,
        )
        val installIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(apkUri, APK_MIME_TYPE)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        startActivity(installIntent)
        return true
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
        const val APK_MIME_TYPE = "application/vnd.android.package-archive"
        const val CONNECT_TIMEOUT_MS = 15_000
        const val READ_TIMEOUT_MS = 60_000
    }
}
