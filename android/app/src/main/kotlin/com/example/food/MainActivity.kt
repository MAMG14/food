package com.example.food

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    /// Keep the native splash up until Flutter has painted the same still frame.
    private var keepNativeSplash = true

    override fun onCreate(savedInstanceState: Bundle?) {
        val splashScreen = installSplashScreen()
        splashScreen.setKeepOnScreenCondition { keepNativeSplash }
        super.onCreate(savedInstanceState)
        // FlutterActivity alone does not always get decorFits=false on Samsung /
        // API 35+ before the first frame, which leaves an opaque black status bar
        // above the AppBar. Force edge-to-edge and light (dark) system icons.
        applyEdgeToEdge()
        splashScreen.setOnExitAnimationListener { splashView ->
            applyEdgeToEdge()
            splashView.remove()
        }
    }

    override fun onFlutterUiDisplayed() {
        keepNativeSplash = false
        applyEdgeToEdge()
        super.onFlutterUiDisplayed()
    }

    override fun onPostResume() {
        super.onPostResume()
        applyEdgeToEdge()
    }

    private fun applyEdgeToEdge() {
        val window = window
        WindowCompat.setDecorFitsSystemWindows(window, false)
        @Suppress("DEPRECATION")
        window.statusBarColor = Color.TRANSPARENT
        @Suppress("DEPRECATION")
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
        WindowCompat.getInsetsController(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }
    }
}
