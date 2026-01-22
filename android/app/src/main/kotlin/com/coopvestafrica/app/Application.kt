package com.coopvestafrica.app

import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry

class Application : FlutterApplication(), PluginRegistry.PluginRegistrantCallback {
    override fun onCreate() {
        super.onCreate()
    }

    override fun registerWith(registry: PluginRegistry) {
        // In modern Flutter, plugins are usually registered automatically via GeneratedPluginRegistrant.
        // If manual registration is needed for background messaging, it's typically handled 
        // within the plugin's own initialization or a custom registrant.
    }
}
