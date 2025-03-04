import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  final String backgroundImage;
  final double overlayOpacity;

  const AuthBackground({
    Key? key,
    required this.child,
    required this.backgroundImage,
    this.overlayOpacity = 0.4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
          
          // Overlay for better text visibility
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(overlayOpacity),
            ),
          ),
          
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
