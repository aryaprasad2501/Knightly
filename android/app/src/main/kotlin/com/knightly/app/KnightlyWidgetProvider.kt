package com.knightly.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// The "Knightly · Today" home-screen widget. Knightly writes the figures
/// (see lib/app/home_widget_sync.dart); this only lays them out. Tapping
/// opens the app.
class KnightlyWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.knightly_widget).apply {
                setTextViewText(R.id.widget_title, widgetData.getString("title", "KNIGHTLY · TODAY"))
                setTextViewText(R.id.widget_progress, widgetData.getString("progress", "—"))
                setTextViewText(R.id.widget_detail, widgetData.getString("detail", "Open Knightly to start"))
                setTextViewText(R.id.widget_water, widgetData.getString("water", ""))
                setTextViewText(R.id.widget_next, widgetData.getString("next", ""))
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
