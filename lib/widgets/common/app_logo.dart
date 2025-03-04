import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? textColor;
  final bool showTagline;
  
  const AppLogo({
    Key? key,
    this.size = 40.0,
    this.textColor,
    this.showTagline = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Glam Connect',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: textColor ?? Colors.white,
            fontFamily: 'Cursive', // You'll need to add this font to your pubspec.yaml
          ),
        ),
        if (showTagline)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Connect with beauty professionals',
              style: TextStyle(
                fontSize: size * 0.3,
                color: textColor ?? Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
