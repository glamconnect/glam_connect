import 'package:flutter/material.dart';
import 'package:glam_connect/widgets/auth/auth_background.dart';
import 'package:glam_connect/widgets/auth/auth_footer.dart';
import 'package:glam_connect/widgets/auth/auth_form_container.dart';
import 'package:glam_connect/widgets/common/app_logo.dart';
import 'package:glam_connect/widgets/common/custom_button.dart';
import 'package:glam_connect/widgets/common/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _verificationId;
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // TODO: Implement Firebase Phone Authentication
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

      setState(() {
        _isLoading = false;
        _isOtpSent = true;
        _verificationId = 'dummy-verification-id';
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length == 6) {
      setState(() {
        _isLoading = true;
      });

      // TODO: Implement OTP verification with Firebase
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

      setState(() {
        _isLoading = false;
      });

      // Navigate to home page after successful verification
      if (mounted) {
        // TODO: Navigate to appropriate screen based on user role
        // Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      backgroundImage: 'assets/images/salon_background.png', // You'll need to add this image
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(size: 48),
          const SizedBox(height: 40),
          AuthFormContainer(
            title: _isOtpSent ? 'Verify OTP' : 'Login',
            subtitle: _isOtpSent
                ? 'Enter the 6-digit code sent to ${_phoneController.text}'
                : 'You can log in using your phone number by verifying an OTP.',
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (!_isOtpSent) ...[
                    CustomTextField(
                      hintText: 'Phone number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Login',
                      onPressed: _sendOtp,
                      isLoading: _isLoading,
                    ),
                  ] else ...[
                    CustomTextField(
                      hintText: 'Enter 6-digit OTP',
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length != 6) {
                          return 'Please enter a valid 6-digit OTP';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Verify',
                      onPressed: _verifyOtp,
                      isLoading: _isLoading,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isOtpSent = false;
                          _otpController.clear();
                        });
                      },
                      child: const Text(
                        'Change Phone Number',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AuthFooter(
            questionText: "Don't have an account?",
            linkText: "Sign up here",
            onLinkTap: () {
              // TODO: Navigate to registration screen
              // Navigator.of(context).pushNamed('/register');
            },
          ),
        ],
      ),
    );
  }
}
