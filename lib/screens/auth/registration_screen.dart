import 'package:flutter/material.dart';
import 'package:glam_connect/widgets/auth/auth_background.dart';
import 'package:glam_connect/widgets/auth/auth_footer.dart';
import 'package:glam_connect/widgets/auth/auth_form_container.dart';
import 'package:glam_connect/widgets/common/app_logo.dart';
import 'package:glam_connect/widgets/common/custom_button.dart';
import 'package:glam_connect/widgets/common/custom_text_field.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
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

      // TODO: Implement Firebase Phone Authentication
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

      setState(() {
        _isLoading = false;
        _isOtpSent = true;
        _verificationId = 'dummy-verification-id';
      });
    }
  }

  Future<void> _verifyOtpAndRegister() async {
    if (_otpController.text.length == 6) {
      setState(() {
        _isLoading = true;
      });

      // TODO: Implement OTP verification with Firebase
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

      // TODO: Create user in Firestore
      
      setState(() {
        _isLoading = false;
      });

      // Navigate to home page after successful registration
      if (mounted) {
        // TODO: Navigate to appropriate screen
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
      backgroundImage: 'assets/images/salon_background.jpg', // You'll need to add this image
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(size: 48),
          const SizedBox(height: 40),
          AuthFormContainer(
            title: _isOtpSent ? 'Verify OTP' : 'Sign Up',
            subtitle: _isOtpSent
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
              // TODO: Navigate to login screen
              // Navigator.of(context).pushNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}
