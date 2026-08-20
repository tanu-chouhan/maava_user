package com.hibermart.seller

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Loops the new-order alert until the seller acts on it.
 *
 * A foreground service rather than an in-app player: the alert matters most
 * when the app is backgrounded or killed, and no Dart runs there. Dart only
 * starts and stops it, over `MainActivity.ALARM_CHANNEL`.
 *
 * [ringingOrderId] is the single source of truth for "is it sounding". Keying
 * on the order id — not a bare boolean — is what stops the duplicate leg of the
 * same push restarting a loop that is already running, while still letting a
 * genuinely different order take over.
 */
class NewOrderAlarmService : Service() {

    private var player: MediaPlayer? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val orderId = intent?.getStringExtra(EXTRA_ORDER_ID).orEmpty()

        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }

        ringingOrderId = orderId
        startForeground(NOTIFICATION_ID, buildNotification(orderId))
        startLooping()

        // Redelivery would restart the siren after the seller had dealt with
        // the order, so the service dies with its task instead.
        return START_NOT_STICKY
    }

    private fun startLooping() {
        if (player != null) return
        player = MediaPlayer.create(this, R.raw.neworder)?.apply {
            isLooping = true
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            start()
        }
    }

    private fun buildNotification(orderId: String): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Silent: the looping player owns the sound. A channel that also
            // played it would double the alert.
            manager.createNotificationChannel(
                NotificationChannel(
                    SERVICE_CHANNEL_ID,
                    "New order alert",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply { setSound(null, null) },
            )
        }

        val open = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val pending = PendingIntent.getActivity(
            this,
            0,
            open ?: Intent(),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, SERVICE_CHANNEL_ID)
            .setContentTitle("New order received")
            .setContentText(if (orderId.isBlank()) "Open to accept" else "Order #$orderId")
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(true)
            .setSilent(true)
            .setContentIntent(pending)
            .build()
    }

    override fun onDestroy() {
        player?.run {
            if (isPlaying) stop()
            release()
        }
        player = null
        ringingOrderId = null
        super.onDestroy()
    }

    companion object {
        private const val NOTIFICATION_ID = 4711
        private const val SERVICE_CHANNEL_ID = "new_order_alarm_service"
        private const val EXTRA_ORDER_ID = "orderId"
        private const val ACTION_STOP = "com.hibermart.seller.STOP_ALARM"

        /** Order currently sounding, or null. Read by `isAlarmRinging`. */
        @JvmStatic
        var ringingOrderId: String? = null
            private set

        @JvmStatic
        fun start(context: Context, orderId: String) {
            // Already sounding for this order — do not restart the loop.
            if (ringingOrderId == orderId) return
            val intent = Intent(context, NewOrderAlarmService::class.java)
                .putExtra(EXTRA_ORDER_ID, orderId)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        @JvmStatic
        fun stop(context: Context) {
            ringingOrderId = null
            context.stopService(Intent(context, NewOrderAlarmService::class.java))
        }
    }
}
