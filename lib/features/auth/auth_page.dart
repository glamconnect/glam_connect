import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/main_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/auth_background.dart';
import '../../widgets/auth/auth_footer.dart';
import '../../widgets/auth/auth_form_container.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../utils/constants.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isRegistration = false;

  void _toggleAuthMode() {
    setState(() {
      isRegistration = !isRegistration;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child:
            isRegistration
                ? RegistrationForm(
                  key: const ValueKey('RegForm'),
                  onToggle: _toggleAuthMode,
                )
                : LoginForm(
                  key: const ValueKey('LoginForm'),
                  onToggle: _toggleAuthMode,
                ),
      ),
    );
  }
}

// auth_page.dart - Updated LoginForm
class LoginForm extends ConsumerStatefulWidget {
  final VoidCallback onToggle;
  const LoginForm({super.key, required this.onToggle});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;

  // Existing _sendOtp and _verifyOtp methods from LoginScreen
  // ...

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      backgroundImage: 'assets/images/salon_background.png',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(),
          const SizedBox(height: 40),
          AuthFormContainer(
            title: _isOtpSent ? 'Verify OTP' : 'Sign In',
            subtitle: '',
            child: Form(
              key: _formKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    _isOtpSent ? _buildOtpVerification() : _buildPhoneInput(),
              ),
            ),
          ),
          AuthFooter(
            questionText: "Don't have an account?",
            linkText: "Sign up here",
            onLinkTap: widget.onToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      children: [
        CustomTextField(
          hintText: 'Phone number (e.g., 3XXXXXXX, we will add 973)',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            // Remove any non-digit characters and 973 prefix if present
            String cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');
            if (cleanNumber.startsWith('973')) {
              cleanNumber = cleanNumber.substring(3);
            }

            if (cleanNumber.length != 8) {
              return 'Please enter exactly 8 digits (973 will be added automatically)';
            }

            // Update controller with clean 8-digit number
            if (cleanNumber != value) {
              _phoneController.text = cleanNumber;
            }
            return null;
          },
        ),
        CustomButton(
          text: 'Continue',
          onPressed: _sendOtp,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildOtpVerification() {
    return Column(
      children: [
        CustomTextField(
          hintText: 'Enter 4-digit OTP (0000 always works)',
          controller: _otpController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the OTP';
            }
            if (value.length != 4) {
              return 'OTP must be 4 digits';
            }
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
              return 'OTP must contain only digits';
            }
            return null;
          },
        ),
        CustomButton(
          text: 'Verify & Sign In',
          onPressed: _verifyOtp,
          isLoading: _isLoading,
        ),
        TextButton(
          onPressed:
              () => setState(() {
                _isOtpSent = false;
                _otpController.clear();
              }),
          child: const Text('Change Phone Number'),
        ),
      ],
    );
  }

  // Add to _LoginFormState class
  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Format phone number with 973 prefix
      final phoneNumber = Constants.formatPhoneNumber(_phoneController.text);

      // First check if user exists
      final authService = ref.read(authServiceProvider);
      final (user, error) = await authService.login(phoneNumber);

      if (error != null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $error')));
        return;
      }

      // If user exists, proceed with OTP verification
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final otp = _otpController.text.trim();
    final phoneNumber = '+973${_phoneController.text.trim().padLeft(8, '0')}';

    // For testing, accept only 0000 as valid OTP
    if (otp != '0000') {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. For testing, use 0000')),
      );
      return;
    }

    // Get user data again to ensure it's fresh
    final (user, error) = await ref
        .read(authServiceProvider)
        .login(phoneNumber);

    setState(() => _isLoading = false);

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $error')));
        widget.onToggle(); // Switch to registration if user not found
      }
      return;
    }

    if (mounted) {
      await ref.read(mainProvider.notifier).getIfUserLoggedIn();
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}

class RegistrationForm extends ConsumerStatefulWidget {
  final VoidCallback onToggle;
  const RegistrationForm({super.key, required this.onToggle});

  @override
  ConsumerState<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends ConsumerState<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isOtpSent = false;

  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // Format phone number with 973 prefix
      final phoneNumber = Constants.formatPhoneNumber(_phoneController.text);

      // Check if phone number already exists
      final user = await ref
          .read(authServiceProvider)
          .getUserByPhone(phoneNumber);

      if (user != null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number already registered')),
        );
        widget.onToggle(); // Switch to login
        return;
      }

      // If phone number is available, proceed with OTP
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });
    }
  }

  Future<void> _verifyOtpAndRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final otp = _otpController.text.trim();

    // For testing, accept only 0000 as valid OTP
    if (otp != '0000') {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. For testing, use 0000')),
      );
      return;
    }

    // Register the new user
    final (registeredUser, regError) = await ref
        .read(authServiceProvider)
        .registerUser(
          name: _nameController.text.trim(),
          phoneNumber: Constants.formatPhoneNumber(_phoneController.text),
          email: _emailController.text.trim(),
          city: _cityController.text.trim(),
        );

    setState(() => _isLoading = false);

    if (regError != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(regError)));
      }
      return;
    }

    await ref.read(mainProvider.notifier).getIfUserLoggedIn();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      backgroundImage: 'assets/images/salon_background.png',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(),
          const SizedBox(height: 40),
          AuthFormContainer(
            title: _isOtpSent ? 'Verify OTP' : 'Sign Up',
            subtitle: '',
            child: Form(
              key: _formKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    _isOtpSent
                        ? _buildOtpVerification()
                        : _buildRegistrationForm(),
              ),
            ),
          ),
          AuthFooter(
            questionText: "Already have an account?",
            linkText: "Sign in here",
            onLinkTap: widget.onToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      children: [
        CustomTextField(
          hintText: 'Name',
          controller: _nameController,
          validator: (value) => value?.isEmpty ?? true ? 'Enter name' : null,
        ),
        CustomTextField(
          hintText: 'Phone number (e.g., 3XXXXXXX, we will add 973)',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            // Remove any non-digit characters and 973 prefix if present
            String cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');
            if (cleanNumber.startsWith('973')) {
              cleanNumber = cleanNumber.substring(3);
            }

            if (cleanNumber.length != 8) {
              return 'Please enter exactly 8 digits (973 will be added automatically)';
            }

            // Update controller with clean 8-digit number
            if (cleanNumber != value) {
              _phoneController.text = cleanNumber;
            }
            return null;
          },
        ),
        CustomTextField(
          hintText: 'Email',
          controller: _emailController,
          validator:
              (value) => value?.contains('@') ?? false ? null : 'Invalid email',
        ),
        CustomTextField(
          hintText: 'City',
          controller: _cityController,
          validator: (value) => value?.isEmpty ?? true ? 'Enter city' : null,
        ),
        CustomButton(
          text: 'Send OTP',
          onPressed: _sendOtp,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildOtpVerification() {
    return Column(
      children: [
        CustomTextField(
          hintText: 'Enter 4-digit OTP (0000 always works)',
          controller: _otpController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the OTP';
            }
            if (value.length != 4) {
              return 'OTP must be 4 digits';
            }
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
              return 'OTP must contain only digits';
            }
            return null;
          },
        ),
        CustomButton(
          text: 'Verify & Register',
          onPressed: _verifyOtpAndRegister,
          isLoading: _isLoading,
        ),
        TextButton(
          onPressed:
              () => setState(() {
                _isOtpSent = false;
                _otpController.clear();
              }),
          child: const Text('Edit Details'),
        ),
      ],
    );
  }
}
