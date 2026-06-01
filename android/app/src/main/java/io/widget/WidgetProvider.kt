package io.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.compose.ui.graphics.Color

class WidgetProvider : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val title = "PSLab Widget"
        val message = "Test is working"

        provideContent {
            GlanceWidgetLayout(title, message)
        }
    }

    @Composable
    private fun GlanceWidgetLayout(title: String, message: String) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(Color(0xFF212121))
                .padding(16.dp),
            verticalAlignment = Alignment.Top,
            horizontalAlignment = Alignment.Start
        ) {
            Text(
                text = title,
                style = TextStyle(
                    color = ColorProvider(Color.White),
                    fontSize = 18.sp
                )
            )
            Text(
                text = message,
                style = TextStyle(
                    color = ColorProvider(Color.LightGray),
                    fontSize = 14.sp
                ),
                modifier = GlanceModifier.padding(top = 8.dp)
            )
        }
    }
}