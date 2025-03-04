import 'package:flutter/material.dart';
import 'package:glam_connect/screens/auth/login_screen.dart';
import 'package:glam_connect/screens/auth/registration_screen.dart';
import 'package:glam_connect/utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glam Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        // TODO: Add more routes as you create screens
      },
    );
  }
}
