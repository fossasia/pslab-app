package io.pslab.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
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

// Classe di supporto locale per mappare i log estratti dal JSON
data class LogItem(val fileName: String, val instrument: String)

class WidgetProvider : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        // Recuperiamo le SharedPreferences condivise con Flutter
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val jsonString = prefs.getString("logs_json_key", "[]") ?: "[]"

        val logList = mutableListOf<LogItem>()

        // Parsing sicuro della stringa JSON proveniente da Dart
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
            // Se il parsing fallisce, la lista resterà vuota
        }

        provideContent {
            GlanceWidgetLayout(logList)
        }
    }

    @Composable
    private fun GlanceWidgetLayout(logs: List<LogItem>) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(Color(0xFF212121))
                .padding(12.dp),
            verticalAlignment = Alignment.Top,
            horizontalAlignment = Alignment.Start
        ) {
            // Intestazione del Widget
            Text(
                text = "PSLab Saved Logs",
                style = TextStyle(
                    color = ColorProvider(Color.White),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                ),
                modifier = GlanceModifier.padding(bottom = 8.dp)
            )

            // Se la lista è vuota mostriamo un messaggio di fallback
            if (logs.isEmpty()) {
                Box(
                    modifier = GlanceModifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "No logged data found",
                        style = TextStyle(color = ColorProvider(Color.Gray), fontSize = 14.sp)
                    )
                }
            } else {
                // Equivalente nativo del ListView.builder
                LazyColumn(
                    modifier = GlanceModifier.fillMaxWidth().defaultWeight()
                ) {
                    items(logs) { log ->
                        LogItemRow(log)
                    }
                }
            }
        }
    }

    @Composable
    private fun LogItemRow(log: LogItem) {
        // Generiamo una riga per ogni singolo file di log
        Column(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(Color(0xFF2E2E2E))
                .padding(8.dp)
                .padding(bottom = 6.dp)
        ) {
            Text(
                text = log.fileName,
                style = TextStyle(
                    color = ColorProvider(Color.White),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            )
            Text(
                text = log.instrument.uppercase(),
                style = TextStyle(
                    color = ColorProvider(Color(0xFFFF5252)), // Un rosso simile al tuo primaryRed
                    fontSize = 11.sp
                ),
                modifier = GlanceModifier.padding(top = 2.dp)
            )
        }
    }
}