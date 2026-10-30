package vn.vietschool.snapdrop

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val clipboard by lazy { getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager }
    private var shareChannel: MethodChannel? = null

    // Ảnh share đến trước khi Dart sẵn sàng (app mở nguội từ share).
    private var pendingShare: List<ByteArray>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "snapdrop/share").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeInitialShare" -> {
                        result.success(pendingShare)
                        pendingShare = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
        pendingShare = readSharedImages(intent)
        consume(intent)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "snapdrop/clipboard").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "peek" -> result.success(peek())
                    "readImage" -> result.success(readImage())
                    "writeTestImage" -> {
                        writeTestImage(call.arguments as ByteArray)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("clipboard", e.message, null)
            }
        }
    }

    // App đang chạy (singleTop) nhận thêm share → đẩy thẳng sang Dart.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val images = readSharedImages(intent) ?: return
        consume(intent)
        shareChannel?.invokeMethod("onShare", images)
    }

    private fun readSharedImages(intent: Intent?): List<ByteArray>? {
        if (intent == null || intent.type?.startsWith("image/") != true) return null
        val uris: List<Uri> = when (intent.action) {
            Intent.ACTION_SEND -> listOfNotNull(streamExtra(intent))
            Intent.ACTION_SEND_MULTIPLE -> streamListExtra(intent)
            else -> emptyList()
        }
        // Đọc ngay: quyền đọc URI chỉ được cấp kèm intent này.
        val images = uris.mapNotNull { uri ->
            runCatching { contentResolver.openInputStream(uri)?.use { it.readBytes() } }.getOrNull()
        }
        return images.ifEmpty { null }
    }

    @Suppress("DEPRECATION")
    private fun streamExtra(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else intent.getParcelableExtra(Intent.EXTRA_STREAM)

    @Suppress("DEPRECATION")
    private fun streamListExtra(intent: Intent): List<Uri> =
        (if (Build.VERSION.SDK_INT >= 33) intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)) ?: emptyList()

    // Tránh xử lý lại cùng một share khi Activity bị tạo lại (xoay màn hình…).
    private fun consume(intent: Intent?) {
        intent?.action = Intent.ACTION_MAIN
    }

    // Bước 1: chỉ đọc ClipDescription (MIME + timestamp), KHÔNG đọc nội dung
    // → Android 12+ không hiện toast "đã dán từ clipboard".
    private fun peek(): Map<String, Any?> {
        val desc = clipboard.primaryClipDescription ?: return mapOf("hasImage" to false)
        val hasImage = (0 until desc.mimeTypeCount).any { desc.getMimeType(it).startsWith("image/") }
        if (!hasImage) return mapOf("hasImage" to false)
        val ts = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) desc.timestamp else null
        return mapOf(
            "hasImage" to true,
            "id" to "android-${ts ?: desc.hashCode()}",
            "ageMs" to ts?.let { ageOf(it) },
        )
    }

    // Tuổi của ảnh (ms). Phòng trường hợp timestamp theo đồng hồ boot thay vì wall clock.
    private fun ageOf(ts: Long): Long {
        val now = System.currentTimeMillis()
        val yearMs = 365L * 24 * 3600 * 1000
        return if (kotlin.math.abs(now - ts) < yearMs) now - ts else SystemClock.elapsedRealtime() - ts
    }

    // Chỉ gọi khi người dùng bấm chip / chọn đích đến.
    private fun readImage(): ByteArray? {
        val clip = clipboard.primaryClip ?: return null
        for (i in 0 until clip.itemCount) {
            val uri = clip.getItemAt(i).uri ?: continue
            val type = contentResolver.getType(uri) ?: continue
            if (!type.startsWith("image/")) continue
            return contentResolver.openInputStream(uri)?.use { it.readBytes() }
        }
        return null
    }

    private fun writeTestImage(png: ByteArray) {
        val dir = File(cacheDir, "clip").apply { mkdirs() }
        val file = File(dir, "test-${System.currentTimeMillis()}.png").apply { writeBytes(png) }
        val uri = FileProvider.getUriForFile(this, "$packageName.clipprovider", file)
        clipboard.setPrimaryClip(ClipData.newUri(contentResolver, "Ảnh test", uri))
    }
}
