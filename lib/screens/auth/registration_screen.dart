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

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _verificationId;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final phoneNumber = '+${_phoneController.text.trim()}';

      await ref
          .read(authServiceProvider)
          .signInWithPhone(
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

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $error')));
            },
          );
    }
  }

  Future<void> _verifyOtpAndRegister() async {
    if (_otpController.text.length == 6 && _verificationId != null) {
      setState(() {
        _isLoading = true;
      });

      final user = await ref
          .read(authServiceProvider)
          .verifyOTP(
            verificationId: _verificationId!,
            otp: _otpController.text.trim(),
          );

      if (user != null) {
        // Register user in Firestore
        final userModel = await ref
            .read(authServiceProvider)
            .registerUser(
              name: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              email: _emailController.text.trim(),
              city: _cityController.text.trim(),
            );

        setState(() {
          _isLoading = false;
        });

        if (userModel != null) {
          // Update main provider with new user
          await ref.read(mainProvider.notifier).getIfUserLoggedIn();

          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error creating user. Please try again.'),
              ),
            );
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
      backgroundImage:
          'assets/images/salon_background.png', // You'll need to add this image
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(size: 48),
          const SizedBox(height: 40),
          AuthFormContainer(
            title: _isOtpSent ? 'Verify OTP' : 'Sign Up',
            subtitle:
                _isOtpSent
                    ? 'Enter the 6-digit code sent to ${_phoneController.text}'
                    : 'Create an account to book beauty services',
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (!_isOtpSent) ...[
                    CustomTextField(
                      hintText: 'Name',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
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
                    CustomTextField(
                      hintText: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    CustomTextField(
                      hintText: 'City',
                      controller: _cityController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your city';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Sign up',
                      onPressed: _sendOtp,
                      isLoading: _isLoading,
                    ),
                  ] else ...[
                    CustomTextField(
                      hintText: 'Enter 4-digit OTP',
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.length != 4) {
                          return 'Please enter a valid 4-digit OTP';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Verify & Register',
                      onPressed: _verifyOtpAndRegister,
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
                        'Change Information',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AuthFooter(
            questionText: "Already have an account?",
            linkText: "Sign in here",
            onLinkTap: () {
              Navigator.of(context).pushNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}
