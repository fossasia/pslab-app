package io.pslab.widget

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.*
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.text.FontWeight
import androidx.glance.unit.ColorProvider
import androidx.compose.ui.graphics.Color
import org.json.JSONArray
import org.json.JSONException
// Importa la tua MainActivity di Flutter per l'azione di click
import io.pslab.MainActivity

data class LogItem(val fileName: String, val instrument: String)

class WidgetProvider : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val jsonString = prefs.getString("logs_json_key", "[]") ?: "[]"
        val logList = mutableListOf<LogItem>()

        try {
            val jsonArray = JSONArray(jsonString)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                logList.add(
                    LogItem(
                        fileName = obj.optString("fileName", "Unknown File"),
                        instrument = obj.optString("instrument", "General")
                    )
                )
            }
        } catch (e: JSONException) {
            // Fallback in caso di errore
        }

        provideContent {
            GlanceWidgetLayout(context, logList)
        }
    }

    @Composable
    private fun GlanceWidgetLayout(context: Context, logs: List<LogItem>) {
        val openAppAction = actionStartActivity(Intent(context, MainActivity::class.java))

        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(Color(0xFFF5F5F5)),
            verticalAlignment = Alignment.Top,
            horizontalAlignment = Alignment.Start
        ) {
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .background(Color(0xFFD32F2F))
                    .padding(horizontal = 16.dp, vertical = 12.dp)
                    .clickable(openAppAction),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "PSLab Saved Logs",
                    style = TextStyle(
                        color = ColorProvider(Color.White),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                )
            }

            // CONTENUTO PRINCIPALE
            if (logs.isEmpty()) {
                Box(
                    modifier = GlanceModifier
                        .fillMaxSize()
                        .padding(16.dp)
                        .clickable(openAppAction),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "No logged data found",
                        style = TextStyle(color = ColorProvider(Color.Gray), fontSize = 14.sp)
                    )
                }
            } else {
                LazyColumn(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .defaultWeight()
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    items(logs) { log ->
                        LogItemCard(log, context)
                    }
                }
            }
        }
    }

    @Composable
    private fun LogItemCard(log: LogItem, context: Context) {
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .padding(vertical = 4.dp, horizontal = 4.dp)
                .background(Color.White)
                .clickable(actionStartActivity(Intent(context, MainActivity::class.java)))
        ) {
            Column(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .padding(12.dp)
            ) {
                Text(
                    text = log.fileName,
                    style = TextStyle(
                        color = ColorProvider(Color(0xFF212121)),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
                Text(
                    text = log.instrument.uppercase(),
                    style = TextStyle(
                        color = ColorProvider(Color(0xFFD32F2F)),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold
                    ),
                    modifier = GlanceModifier.padding(top = 4.dp)
                )
            }
        }
    }
}