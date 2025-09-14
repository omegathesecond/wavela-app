package com.yeboverify.yebo_verify

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // TODO: Fingerprint plugin temporarily disabled for testing
        // Uncomment when ready to test fingerprint functionality
        // flutterEngine.plugins.add(FingerprintPlugin())
    }
}
