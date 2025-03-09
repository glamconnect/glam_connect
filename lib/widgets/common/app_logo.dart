import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({Key? key, this.size = 220}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(25.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        //
      ),
      child: Center(child: Image.asset('assets/logo.png')),
    );
  }
}
