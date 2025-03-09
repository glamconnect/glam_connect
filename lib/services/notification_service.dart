import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission for iOS
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get the token and listen for token refresh
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      // TODO: Send this token to your server
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('FCM Token Refreshed: $newToken');
      }
      // TODO: Send the new token to your server
    });

    // Handle incoming messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print('Message also contained a notification: ${message.notification}');
        }
        // TODO: Show local notification
      }
    });

    // Handle message when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Message clicked! ${message.data}');
      }
      // TODO: Handle navigation based on message data
    });
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
