package com.knightly.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// One small widget per Knightly module, so people place only the ones they
/// want. Knightly writes `<key>_title`, `<key>_value` and `<key>_detail`
/// (lib/app/home_widget_sync.dart); tapping opens that module's screen.
abstract class ModuleWidgetProvider(private val key: String, private val fallbackTitle: String) :
    HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.knightly_widget_module).apply {
                setTextViewText(R.id.module_title, widgetData.getString("${key}_title", fallbackTitle))
                setTextViewText(R.id.module_value, widgetData.getString("${key}_value", "—"))
                setTextViewText(R.id.module_detail, widgetData.getString("${key}_detail", "Open Knightly"))
                setOnClickPendingIntent(
                    R.id.module_root,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("knightly://widget/$key"),
                    ),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

class MissionsWidgetProvider : ModuleWidgetProvider("mission", "MISSIONS")
class HabitsWidgetProvider : ModuleWidgetProvider("habits", "HABITS")
class WaterWidgetProvider : ModuleWidgetProvider("water", "WATER")
class EventWidgetProvider : ModuleWidgetProvider("event", "NEXT EVENT")
