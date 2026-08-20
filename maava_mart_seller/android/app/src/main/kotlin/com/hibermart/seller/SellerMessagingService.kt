package com.hibermart.seller

import android.util.Log
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService

/**
 * Sees every push before Flutter does, so a new order can start ringing while
 * the app is backgrounded or killed — states where no Dart is running and
 * `MainActivity.ALARM_CHANNEL` therefore cannot be called.
 *
 * Registered in the manifest at `android:priority="1"`, above the plugin's own
 * `FlutterFirebaseMessagingService`. FCM delivers a message to exactly one
 * service, so this must extend that class and always delegate to `super`:
 * skipping it would swallow the tray notification and every Dart handler.
 *
 * The backend sends each new order as two messages (see
 * `notifyOwnersActionableAlert`) — a notification leg and a data-only leg. Both
 * can land here while the app is foregrounded; `NewOrderAlarmService` keys on
 * the order id so the second one does not restart a loop already running.
 */
class SellerMessagingService : FlutterFirebaseMessagingService() {

    override fun onMessageReceived(message: RemoteMessage) {
        // Anything thrown here would cost the seller the notification as well
        // as the ringtone, which is the failure this service exists to prevent.
        // In particular `startForegroundService` still throws on Android 12+ if
        // the FCM high-priority allowlist has lapsed.
        try {
            val data = message.data
            if (data["type"] == NEW_ORDER_TYPE) {
                val orderId = data["orderId"].orEmpty().ifBlank { data["orderMongoId"].orEmpty() }
                NewOrderAlarmService.start(this, orderId)
            }
        } catch (t: Throwable) {
            Log.w(TAG, "new-order alarm not started", t)
        }

        super.onMessageReceived(message)
    }

    private companion object {
        const val TAG = "SellerMessagingService"

        /** Matches `data.type` on the backend's new-order push. */
        const val NEW_ORDER_TYPE = "new_order"
    }
}
