package io.github.xiaocaoooo.kanade

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // MediaServicePlugin 功能已迁移到 kanade_audio_plugin 中
        // 无需手动注册，Flutter会自动注册kanade_audio_plugin
        flutterEngine.plugins.add(MediaNotificationService())
    }
}
