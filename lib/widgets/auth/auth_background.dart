import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  final String backgroundImage;

  const AuthBackground({
    Key? key,
    required this.child,
    required this.backgroundImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image with dark overlay
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
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
