package com.ledger.ledger_mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class QuickAddWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { appWidgetId ->
            appWidgetManager.updateAppWidget(appWidgetId, buildViews(context))
        }
    }

    companion object {
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, QuickAddWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            ids.forEach { manager.updateAppWidget(it, buildViews(context)) }
        }

        private fun buildViews(context: Context): RemoteViews {
            return RemoteViews(context.packageName, R.layout.quick_add_widget).apply {
                setOnClickPendingIntent(R.id.quick_add_widget_title, pendingIntent(context, "wallet"))
                setOnClickPendingIntent(R.id.quick_add_wallet, pendingIntent(context, "wallet"))
                setOnClickPendingIntent(R.id.quick_add_paypay, pendingIntent(context, "paypay"))
                setOnClickPendingIntent(R.id.quick_add_suica, pendingIntent(context, "suica"))
                setOnClickPendingIntent(R.id.quick_add_paypay_qr, pendingIntent(context, "paypay_qr"))
                setOnClickPendingIntent(R.id.quick_add_cash, pendingIntent(context, "cash"))
            }
        }

        private fun pendingIntent(context: Context, source: String): PendingIntent {
            val intent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("ledger://quick-add?source=$source"),
                context,
                MainActivity::class.java
            ).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            return PendingIntent.getActivity(
                context,
                source.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }
}
