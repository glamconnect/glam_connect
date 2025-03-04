import 'package:flutter/material.dart';

class AuthFooter extends StatelessWidget {
  final String questionText;
  final String linkText;
  final VoidCallback onLinkTap;
  
  const AuthFooter({
    Key? key,
    required this.questionText,
    required this.linkText,
    required this.onLinkTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            questionText,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: onLinkTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              linkText,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
