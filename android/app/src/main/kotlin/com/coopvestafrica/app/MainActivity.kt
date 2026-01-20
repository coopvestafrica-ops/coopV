package com.coopvestafrica.app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

/**
 * MainActivity - Flutter v2 embedding
 * 
 * Uses the new Flutter embedding API (io.flutter.embedding.android.FlutterActivity)
 * The old v1 embedding (io.flutter.app.FlutterActivity) has been removed.
 */
class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}
