package com.hibermart.seller

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNewOrderChannel()
        createDefaultChannel()
    }

    /**
     * Lets Dart drive the ringtone that the native service owns.
     *
     * The service is the only thing that ever plays it — in the foreground too
     * — so there is exactly one player in every app state and no way for two
     * copies to overlap.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ALARM_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAlarm" -> {
                    val orderId = call.argument<String>("orderId").orEmpty()
                    if (orderId.isBlank()) {
                        result.error("no_order_id", "orderId is required", null)
                    } else {
                        NewOrderAlarmService.start(this, orderId)
                        result.success(true)
                    }
                }

                "stopAlarm" -> {
                    NewOrderAlarmService.stop(this)
                    result.success(true)
                }

                "isAlarmRinging" ->
                    result.success(NewOrderAlarmService.ringingOrderId != null)

                else -> result.notImplemented()
            }
        }
    }

    /**
     * The channel every non-new-order push lands on.
     *
     * The backend sends `new_order_channel` only for new orders and
     * `high_importance_channel` for everything else — order cancelled, order
     * claimed, admin broadcasts, subscription and FSSAI reminders.
     *
     * This must exist. When a push names a channel the device does not have,
     * FCM falls back to `default_notification_channel_id` from the manifest, so
     * with only the new-order channel present *every* notification inherited
     * the custom ringtone. The whole point of this channel is that it uses the
     * system notification sound.
     */
    private fun createDefaultChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(DEFAULT_CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            DEFAULT_CHANNEL_ID,
            "General notifications",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Order updates, payouts and announcements"
            // No setSound() call: a channel created without one uses the
            // device's default notification tone, which is exactly what these
            // are supposed to sound like.
            enableVibration(true)
        }
        manager.createNotificationChannel(channel)
    }

    /**
     * Creates the channel the backend addresses new-order pushes to
     * (androidChannelId: new_order_channel).
     *
     * This is the only way a new order can make a noise while the app is
     * backgrounded or killed: Dart is not running then, so the looping in-app
     * alert cannot start and the channel's own sound is what the seller hears.
     *
     * Created here rather than left to FCM because a channel's sound and
     * importance are fixed at creation. If FCM auto-creates it first, the
     * alert arrives with the default tone at default importance and no later
     * code can change it — only a reinstall can.
     */
    private fun createNewOrderChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(NEW_ORDER_CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            NEW_ORDER_CHANNEL_ID,
            "New orders",
            // HIGH so the alert is a heads-up with sound. Anything lower is
            // silently demoted to a tray entry the seller never notices.
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Orders waiting to be accepted"
            setSound(
                Uri.parse("android.resource://$packageName/raw/neworder"),
                AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    // Ringtone usage, not NOTIFICATION: it plays the whole
                    // asset and carries through Do Not Disturb exemptions the
                    // seller may have set for the app.
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                    .build(),
            )
            enableVibration(true)
        }
        manager.createNotificationChannel(channel)
    }

    private companion object {
        const val ALARM_CHANNEL = "com.hibermart.seller/new_order_alarm"

        /** Custom ringtone. Backend uses this for `type == "new_order"` only. */
        const val NEW_ORDER_CHANNEL_ID = "new_order_channel"

        /** System sound. Backend's `FCM_DEFAULT_CHANNEL_ID` for everything else. */
        const val DEFAULT_CHANNEL_ID = "high_importance_channel"
    }
}
