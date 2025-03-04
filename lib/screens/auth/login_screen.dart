import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/providers/main_provider.dart';
import 'package:glam_connect/services/auth_service.dart';
import 'package:glam_connect/widgets/auth/auth_background.dart';
import 'package:glam_connect/widgets/auth/auth_footer.dart';
import 'package:glam_connect/widgets/auth/auth_form_container.dart';
import 'package:glam_connect/widgets/common/app_logo.dart';
import 'package:glam_connect/widgets/common/custom_button.dart';
import 'package:glam_connect/widgets/common/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _verificationId;

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

      final phoneNumber = '+${_phoneController.text.trim()}';
      
      await ref.read(authServiceProvider).signInWithPhone(
        phoneNumber: phoneNumber,
        onVerificationSent: (verificationId) {
          setState(() {
            _isLoading = false;
            _isOtpSent = true;
            _verificationId = verificationId;
          });
        },
        onError: (error) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        },
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length == 6 && _verificationId != null) {
      setState(() {
        _isLoading = true;
      });

      final user = await ref.read(authServiceProvider).verifyOTP(
        verificationId: _verificationId!,
        otp: _otpController.text.trim(),
      );

      if (user != null) {
        // Check if user exists in Firestore
        final userModel = await ref.read(authServiceProvider).getUserByPhone(
          _phoneController.text.trim(),
        );
        
        setState(() {
          _isLoading = false;
        });
        
        if (userModel != null) {
          // Update main provider with user
          await ref.read(mainProvider.notifier).getIfUserLoggedIn();
          
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        } else {
          // User not registered, redirect to registration
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/register');
          }
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid OTP. Please try again.')),
          );
        }
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
      backgroundImage: 'assets/images/salon_background.png', // Updated to match constants.dart
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(size: 48),
          const SizedBox(height: 40),
          AuthFormContainer(
            title: _isOtpSent ? 'Verify OTP' : 'Sign In',
            subtitle: _isOtpSent
                ? 'Enter the 4-digit code sent to ${_phoneController.text}'
                : 'Enter your phone number to continue',
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
                        if (value.length < 8) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Continue',
                      onPressed: _sendOtp,
                      isLoading: _isLoading,
                    ),
                  ] else ...[
                    CustomTextField(
                      hintText: 'Enter 4-digit OTP',
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length != 6) {
                          return 'Please enter a valid 4-digit OTP';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Verify & Sign In',
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
              Navigator.of(context).pushNamed('/register');
            },
          ),
        ],
      ),
    );
  }
}
