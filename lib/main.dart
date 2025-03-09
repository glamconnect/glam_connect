import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/firebase_options.dart';
import 'package:glam_connect/providers/main_provider.dart';
import 'package:glam_connect/screens/main_navigation.dart';
import 'package:glam_connect/screens/splash_screen.dart';
import 'package:glam_connect/services/auth_service.dart';
import 'package:glam_connect/services/notification_service.dart';
import 'package:glam_connect/services/shared_preferences_service.dart';
import 'package:glam_connect/utils/app_theme.dart';

import 'features/auth/auth_page.dart';

// Handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('Handling a background message: ${message.messageId}');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}, ${message.notification?.body}');
  } catch (e) {
    print('Error handling background message: $e');
  }
}

// Global error handler
void _handleError(Object error, StackTrace stack) {
  print('Uncaught error: $error');
  print('Stack trace: $stack');
}

void main() async {
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };
  
  WidgetsFlutterBinding.ensureInitialized();
  
  // Handle errors in async code
  PlatformDispatcher.instance.onError = (error, stack) {
    _handleError(error, stack);
    return true; // Prevent the error from propagating
  };

  try {
    // Initialize Firebase with options
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    print('Error initializing Firebase: $e');
    rethrow; // Re-throw to crash the app if Firebase fails to initialize
  }

  try {
    // Request permission for iOS
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
  } catch (e) {
    print('Error requesting notification permissions: $e');
  }



  // Set background message handler
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('Background message handler registered');
  } catch (e) {
    print('Error registering background message handler: $e');
  }

  // Initialize services
  final container = ProviderContainer();
  try {
    // Initialize SharedPreferences first
    await container.read(sharedPreferencesServiceFutureProvider.future);
    print('SharedPreferences service initialized');

    // Initialize auth service
    await container.read(authServiceFutureProvider.future);
    print('Auth service initialized');

    // Then initialize notification service
    await container.read(notificationServiceProvider).initialize();
    print('Notification service initialized');
  } catch (e, stack) {
    print('Error initializing services: $e');
    print('Stack trace: $stack');
    // Show error screen instead of crashing
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to Initialize App',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Restart app
                      Restart.restartApp();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return; // Don't proceed with normal app initialization
  }

  runApp(ProviderScope(parent: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch app state
    final appState = ref.watch(mainProvider);

    return MaterialApp(
      title: 'Glam Connect',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: appState.isLoading
          ? const SplashScreen()
          : appState.isUserLoggedIn
              ? const MainNavigationPage()
              : const AuthPage(),
      routes: {
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const MainNavigationPage(),
      }
    );
  }
}
