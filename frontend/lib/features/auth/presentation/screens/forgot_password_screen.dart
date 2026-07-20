import 'package:campus_event_app/core/utils/validators.dart';
import 'package:campus_event_app/features/auth/presentation/widgets/app_button.dart';
import 'package:campus_event_app/features/auth/presentation/widgets/app_text_field.dart';
import 'package:campus_event_app/features/auth/providers/auth_provider.dart';
import 'package:campus_event_app/shared/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _forgotPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await context.read<AuthProvider>().forgotPassword(
          _emailController.text.trim(),
        );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (success) {
        AppDialog.info(
          context: context,
          icon: Icons.email_rounded,
          message: 'A reset password link has been sent to your email. '
              'Please check your inbox to reset your password',
        ).then((_) {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      } else {
        _errorMessage = context.read<AuthProvider>().errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Forgot password",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    "Enter your email to reset your password",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  AppTextField(
                      controller: _emailController,
                      hintText: "Email",
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email),
                  const SizedBox(height: 5),
                  if (_errorMessage != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: AppButton(
                      label: "Send",
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _forgotPassword,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
