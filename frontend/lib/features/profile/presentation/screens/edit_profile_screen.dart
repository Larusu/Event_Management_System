import 'package:campus_event_app/core/constants/error_codes.dart';
import 'package:campus_event_app/core/utils/validators.dart';
import 'package:campus_event_app/features/auth/presentation/widgets/app_button.dart';
import 'package:campus_event_app/features/auth/presentation/widgets/app_text_field.dart';
import 'package:campus_event_app/features/auth/providers/auth_provider.dart';
import 'package:campus_event_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:campus_event_app/shared/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  String? _currentPasswordError;
  String? _newPasswordError;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _contactController.text = user.contact;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPasswordError = null;
      _newPasswordError = null;
    });

    final newPassword = _newPasswordController.text.trim();
    final success = await context.read<AuthProvider>().updateProfile(
          currentPassword: _currentPasswordController.text,
          name: _nameController.text.trim(),
          contact: _contactController.text.trim(),
          newPassword: newPassword.isNotEmpty ? newPassword : null,
        );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (success) {
        AppDialog.info(
          context: context,
          icon: Icons.check_circle_outline_rounded,
          message: 'Your profile has been updated successfully.',
        ).then((_) {
          if (mounted) context.pop();
        });
      } else {
        final provider = context.read<AuthProvider>();
        final code = provider.errorCode;
        final message = provider.errorMessage;
        if (code == AuthErrorCodes.currentPasswordIncorrect) {
          _currentPasswordError = message;
        } else if (code == AuthErrorCodes.passwordSameAsCurrent) {
          _newPasswordError = message;
        } else {
          _errorMessage = message;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 30),
                  child: ProfileAvatar(),
                ),
                AppTextField(
                  controller: _nameController,
                  hintText: "Name",
                  isRequired: true,
                  validator: Validators.name,
                ),
                const SizedBox(height: 15),
                AppTextField(
                  controller: _contactController,
                  hintText: "Contact #",
                  keyboardType: TextInputType.phone,
                  isRequired: true,
                  validator: Validators.contact,
                ),
                const SizedBox(height: 15),
                AppTextField(
                  controller: _currentPasswordController,
                  hintText: "Current Password",
                  obscureText: true,
                  isRequired: true,
                  validator: Validators.password,
                ),
                if (_currentPasswordError != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _currentPasswordError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                AppTextField(
                  controller: _newPasswordController,
                  hintText: "New Password (optional)",
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    return Validators.password(value);
                  },
                ),
                if (_newPasswordError != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _newPasswordError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                AppTextField(
                  controller: _confirmPasswordController,
                  hintText: "Confirm New Password",
                  obscureText: true,
                  validator: (value) {
                    if (_newPasswordController.text.isEmpty) return null;
                    return Validators.confirmPassword(
                        value, _newPasswordController.text);
                  },
                ),
                const SizedBox(height: 15),
                if (_errorMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: AppButton(
                    label: "Save",
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
