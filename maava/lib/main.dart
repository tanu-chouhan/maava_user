import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maava/src/core/constants/app_constants.dart';
import 'package:maava/src/food_user_application.dart';
import 'package:maava/src/platform/notifications/push_service.dart';
import 'package:maava/src/quick/core/local_storage/shared_prefs_storage.dart';
import 'package:maava/src/quick/core/network/media_url.dart';
import 'package:maava/src/quick/di/repository_providers.dart' as quick_di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[APP] App Started');

  final firebaseOk = await ensureFirebaseInitialized();
  if (firebaseOk) {
    debugPrint('[APP] Firebase Initialized');
  }

  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('[FCM] Background Handler Registered');
  } catch (e) {
    debugPrint('[FCM] Background Handler Registration failed: $e');
  }

  // Quick-commerce module: resolve relative /uploads/... image paths and give
  // it its key-value store (the food side keeps its own storage tiers).
  MediaUrl.configure(AppConstants.baseUrl);
  final quickStorage = await SharedPrefsStorage.create();

  runApp(
    ProviderScope(
      overrides: [
        quick_di.localStorageProvider.overrideWithValue(quickStorage),
      ],
      child: const FoodUserApplication(),
    ),
  );
}
