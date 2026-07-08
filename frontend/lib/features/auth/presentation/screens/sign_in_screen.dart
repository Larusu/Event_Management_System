import 'package:campus_event_app/core/utils/validators.dart';
import 'package:campus_event_app/features/auth/presentation/widgets/app_button.dart';
import 'package:campus_event_app/features/auth/presentation/widgets/app_text_field.dart';
import 'package:campus_event_app/features/auth/providers/auth_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await context.read<AuthProvider>().signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (!success) {
        _errorMessage = context.read<AuthProvider>().errorMessage;
      }
    });
    // Navigation on success is handled by the route guard reacting to the
    // AuthProvider status change.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Log in account",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    const Text(
                      "Enter your email to sign in for this app",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    AppTextField(
                        controller: _emailController,
                        hintText: "Email",
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email),
                    const SizedBox(
                      height: 15,
                    ),
                    AppTextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      hintText: "Password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: Validators.password),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        mouseCursor: SystemMouseCursors.click,
                        onTap: () {
                          Navigator.pushNamed(context, '/forgot-password');
                        },
                        child: Text(
                          "Forgot password?",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (_errorMessage != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: AppButton(
                        label: "Sign in",
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _signIn,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.labelMedium,
                        children: [
                          TextSpan(
                            text: "Dont have an account?",
                          ),
                          TextSpan(text: " "),
                          TextSpan(
                            text: "Sign up",
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                    ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushNamed(context, '/sign-up');
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
