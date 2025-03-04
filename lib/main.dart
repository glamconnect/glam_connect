import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/firebase_options.dart';
import 'package:glam_connect/providers/main_provider.dart';
import 'package:glam_connect/screens/auth/login_screen.dart';
import 'package:glam_connect/screens/auth/registration_screen.dart';
import 'package:glam_connect/screens/main_navigation.dart';
import 'package:glam_connect/screens/splash_screen.dart';
import 'package:glam_connect/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(mainProvider);

    return MaterialApp(
      title: 'Glam Connect',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: appState.isLoading 
          ? const SplashScreen() 
          : appState.isUserLoggedIn 
              ? const MainNavigationPage() 
              : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/home': (context) => const MainNavigationPage(),
      },
    );
  }
}
