import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: onLinkTap,
            child: Text(
              linkText,
              style: const TextStyle(
                color: AppColor.primary,
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
