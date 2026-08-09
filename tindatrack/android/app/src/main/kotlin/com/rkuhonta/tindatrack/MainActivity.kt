package com.rkuhonta.tindatrack

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CSV_EXPORT_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != SAVE_CSV_EXPORT_METHOD) {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                saveCsvExport(call)
                result.success(null)
            } catch (error: IllegalArgumentException) {
                result.error("invalid_csv_export", error.message, null)
            } catch (error: IOException) {
                result.error("csv_export_io", error.message, null)
            } catch (error: SecurityException) {
                result.error("csv_export_permission", error.message, null)
            }
        }
    }

    private fun saveCsvExport(call: MethodCall) {
        val productsFileName = requireArgument(call, "productsFileName")
        val productsCsv = requireArgument(call, "productsCsv")
        val stockHistoryFileName = requireArgument(call, "stockHistoryFileName")
        val stockHistoryCsv = requireArgument(call, "stockHistoryCsv")

        saveCsvFile(productsFileName, productsCsv)
        saveCsvFile(stockHistoryFileName, stockHistoryCsv)
    }

    private fun requireArgument(call: MethodCall, key: String): String {
        return call.argument<String>(key)
            ?: throw IllegalArgumentException("Missing CSV export argument: $key")
    }

    private fun saveCsvFile(fileName: String, content: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveCsvFileWithMediaStore(fileName, content)
            return
        }

        saveCsvFileLegacy(fileName, content)
    }

    private fun saveCsvFileWithMediaStore(fileName: String, content: String) {
        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, "text/csv")
            put(
                MediaStore.Downloads.RELATIVE_PATH,
                "${Environment.DIRECTORY_DOWNLOADS}/TindaTrack",
            )
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IOException("Could not create Downloads CSV file")

        try {
            resolver.openOutputStream(uri)?.use { output ->
                output.write(content.toByteArray(Charsets.UTF_8))
            } ?: throw IOException("Could not open Downloads CSV file")

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } catch (error: IOException) {
            resolver.delete(uri, null, null)
            throw error
        } catch (error: RuntimeException) {
            resolver.delete(uri, null, null)
            throw error
        }
    }

    private fun saveCsvFileLegacy(fileName: String, content: String) {
        val downloads = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS,
        )
        val exportDirectory = File(downloads, "TindaTrack")
        if (!exportDirectory.exists() && !exportDirectory.mkdirs()) {
            throw IOException("Could not create Downloads/TindaTrack")
        }

        FileOutputStream(File(exportDirectory, fileName)).use { output ->
            output.write(content.toByteArray(Charsets.UTF_8))
        }
    }

    companion object {
        private const val CSV_EXPORT_CHANNEL = "com.rkuhonta.tindatrack/csv_export"
        private const val SAVE_CSV_EXPORT_METHOD = "saveCsvExportToDownloads"
    }
}