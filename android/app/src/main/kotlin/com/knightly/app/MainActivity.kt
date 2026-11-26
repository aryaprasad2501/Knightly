package com.knightly.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts Flutter and the "knightly/documents" channel: saving and opening a
 * user-chosen file through Android's system file picker (Storage Access
 * Framework). Used by Backup & restore. No storage permission is needed and
 * nothing leaves the device unless the user picks a cloud folder themselves.
 */
class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (pending != null) {
                result.error("busy", "Another file dialog is already open.", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "save" -> {
                    val name = call.argument<String>("name") ?: "knightly-backup.json"
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error("bad_args", "Nothing to save.", null)
                        return@setMethodCallHandler
                    }
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = call.argument<String>("mimeType") ?: "application/json"
                        putExtra(Intent.EXTRA_TITLE, name)
                    }
                    pending = result
                    pendingBytes = bytes
                    startActivityForResult(intent, REQUEST_SAVE)
                }
                "open" -> {
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        // Many file managers label .json files as text or binary.
                        type = "*/*"
                        putExtra(
                            Intent.EXTRA_MIME_TYPES,
                            arrayOf("application/json", "text/plain", "application/octet-stream"),
                        )
                    }
                    pending = result
                    startActivityForResult(intent, REQUEST_OPEN)
                }
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("FlutterActivity still delivers picker results here.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_SAVE && requestCode != REQUEST_OPEN) return
        val result = pending ?: return
        val bytes = pendingBytes
        pending = null
        pendingBytes = null

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null) // The user closed the picker.
            return
        }
        try {
            if (requestCode == REQUEST_SAVE) {
                contentResolver.openOutputStream(uri, "wt")?.use { it.write(bytes) }
                    ?: throw IllegalStateException("The chosen location can't be written to.")
                result.success(mapOf("uri" to uri.toString(), "name" to displayName(uri)))
            } else {
                val content = contentResolver.openInputStream(uri)?.use { input ->
                    val buffer = java.io.ByteArrayOutputStream()
                    val chunk = ByteArray(64 * 1024)
                    var total = 0
                    while (true) {
                        val read = input.read(chunk)
                        if (read < 0) break
                        total += read
                        if (total > MAX_OPEN_BYTES) throw IllegalStateException("too_large")
                        buffer.write(chunk, 0, read)
                    }
                    buffer.toByteArray()
                } ?: throw IllegalStateException("The chosen file can't be read.")
                result.success(mapOf("name" to displayName(uri), "bytes" to content))
            }
        } catch (e: Exception) {
            result.error(if (e.message == "too_large") "too_large" else "io", e.message, null)
        }
    }

    private fun displayName(uri: Uri): String? =
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0) else null
        }

    companion object {
        private const val CHANNEL = "knightly/documents"
        private const val REQUEST_SAVE = 4101
        private const val REQUEST_OPEN = 4102
        private const val MAX_OPEN_BYTES = 32 * 1024 * 1024
    }
}
