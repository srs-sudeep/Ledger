package com.ledger.ledger_mobile

import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ledger/shortcuts"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncQuickAddShortcuts" -> {
                    syncQuickAddShortcuts()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun syncQuickAddShortcuts() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) return
        val shortcutManager = getSystemService(ShortcutManager::class.java) ?: return
        shortcutManager.dynamicShortcuts = listOf(
            buildShortcut(
                id = "quick_credit_card",
                shortLabelRes = R.string.shortcut_credit_card_short,
                longLabelRes = R.string.shortcut_credit_card_long,
                source = "credit_card"
            ),
            buildShortcut(
                id = "quick_suica",
                shortLabelRes = R.string.shortcut_suica_short,
                longLabelRes = R.string.shortcut_suica_long,
                source = "suica"
            ),
            buildShortcut(
                id = "quick_paypay_qr",
                shortLabelRes = R.string.shortcut_paypay_qr_short,
                longLabelRes = R.string.shortcut_paypay_qr_long,
                source = "paypay_qr"
            ),
            buildShortcut(
                id = "quick_cash",
                shortLabelRes = R.string.shortcut_cash_short,
                longLabelRes = R.string.shortcut_cash_long,
                source = "cash"
            )
        )
    }

    private fun buildShortcut(
        id: String,
        shortLabelRes: Int,
        longLabelRes: Int,
        source: String
    ): ShortcutInfo {
        val intent = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("ledger:///quick-add?source=$source"),
            this,
            MainActivity::class.java
        ).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        return ShortcutInfo.Builder(this, id)
            .setShortLabel(getString(shortLabelRes))
            .setLongLabel(getString(longLabelRes))
            .setIcon(Icon.createWithResource(this, R.drawable.splash_logo))
            .setIntent(intent)
            .build()
    }
}
