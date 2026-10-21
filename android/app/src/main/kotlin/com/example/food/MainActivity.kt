package com.example.food

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    /// Keep the native splash up until Flutter has painted the same still frame.
    private var keepNativeSplash = true

    override fun onCreate(savedInstanceState: Bundle?) {
        // Flutter 3.27+ defaults to edge-to-edge on Android, which drew a black
        // status strip on Home and clipped the DEBUG banner. Opt out so content
        // lays out below the system bars (same as before).
        WindowCompat.setDecorFitsSystemWindows(window, true)

        val splashScreen = installSplashScreen()
        splashScreen.setKeepOnScreenCondition { keepNativeSplash }
        super.onCreate(savedInstanceState)
        splashScreen.setOnExitAnimationListener { splashView ->
            splashView.remove()
        }
    }

    override fun onFlutterUiDisplayed() {
        keepNativeSplash = false
        super.onFlutterUiDisplayed()
    }
}
