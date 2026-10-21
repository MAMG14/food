package com.example.food

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    /// Keep the native splash up until Flutter has painted the same still frame.
    private var keepNativeSplash = true

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        splashScreen.setKeepOnScreenCondition { keepNativeSplash }
        super.onCreate(savedInstanceState)
        // No zoom-out; just reveal the Flutter still underneath.
        splashScreen.setOnExitAnimationListener { splashView ->
            splashView.remove()
        }
    }

    override fun onFlutterUiDisplayed() {
        keepNativeSplash = false
        super.onFlutterUiDisplayed()
    }
}
