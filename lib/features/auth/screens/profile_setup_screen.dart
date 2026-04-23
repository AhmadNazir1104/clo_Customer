import 'dart:io';

import 'package:libaas/features/auth/view_model/auth_provider.dart';
import 'package:libaas/features/auth/view_model/auth_state.dart';
import 'package:libaas/utils/app_colors.dart';
import 'package:libaas/utils/phone_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _profilePhoto;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 600);
    if (picked != null) setState(() => _profilePhoto = File(picked.path));
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      // Normalize to local format so it matches Firestore customer doc IDs
      final phone = normalizeToLocal(
          FirebaseAuth.instance.currentUser?.phoneNumber ?? '');
      ref.read(authProvider.notifier).saveUserProfile(
            name: _nameController.text,
            city: _cityController.text,
            phone: phone,
            profilePhoto: _profilePhoto,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AccountSetupSuccess) {
        context.go('/home/orders');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    final isLoading = ref.watch(authProvider) is AuthLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                const Text(
                  'Set up your\nprofile',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This helps your tailor identify you',
                  style: TextStyle(fontSize: 15, color: AppColors.gray),
                ),
                const SizedBox(height: 36),
                // ── Photo picker ──────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _profilePhoto != null
                              ? FileImage(_profilePhoto!)
                              : null,
                          child: _profilePhoto == null
                              ? const Icon(Icons.person,
                                  size: 52, color: AppColors.gray)
                              : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppColors.navy,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.camera_alt,
                                size: 16, color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Add photo (optional)',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500),
                  ),
                ),
                const SizedBox(height: 32),
                // ── Name ──────────────────────────────────────────────────
                _buildLabel('Full Name'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hint: 'e.g. Ahmed Khan',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 24),
                // ── City ──────────────────────────────────────────────────
                _buildLabel('City'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _cityController,
                  hint: 'e.g. Lahore',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'City is required' : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      disabledBackgroundColor:
                          AppColors.navy.withValues(alpha: 0.5),
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: AppColors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Save & Continue',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.dark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.grey.shade400, fontWeight: FontWeight.w400),
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.navy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.red, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
