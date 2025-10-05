import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:scalex_innovation/screens/login.dart';
import 'package:scalex_innovation/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scalex_innovation/widgets/app_dialogs.dart';
import 'package:scalex_innovation/widgets/custom_text_field.dart';
import 'package:scalex_innovation/widgets/progress_steps.dart';
import 'package:scalex_innovation/widgets/language_sheet.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;
  int _currentStep = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      await AppDialogs.show(context,
          title: 'signup.passwords_not_match_title'.tr(),
          message: 'signup.passwords_not_match_msg'.tr());
      return;
    }
    if (_passwordController.text.length < 6) {
      await AppDialogs.show(context,
          title: 'signup.password_too_short_title'.tr(),
          message: 'signup.password_too_short_msg'.tr());
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await _authService.signUp(_emailController.text.trim(), _passwordController.text);
      await _authService.updateDisplayName(_nameController.text.trim());
      await _authService.sendEmailVerification();
      await AppDialogs.show(context,
          title: 'signup.success_title'.tr(),
          message: 'signup.success_msg'.tr(),
          success: true);
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      });
    } on FirebaseAuthException catch (e) {
      String message = 'signup.error_default'.tr();
      if (e.code == 'weak-password') message = 'signup.error_weak_password'.tr();
      else if (e.code == 'email-already-in-use') message = 'signup.error_email_exists'.tr();
      else if (e.code == 'invalid-email') message = 'signup.error_invalid_email'.tr();
      await AppDialogs.show(context, title: 'signup.error_title'.tr(), message: message);
    } catch (_) {
      await AppDialogs.show(context, title: 'signup.error_title'.tr(), message: 'signup.error_default'.tr());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showLanguageSheet() => LanguageSheet.show(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: const Icon(Icons.language_rounded, color: Color(0xFF64748B)),
                  onPressed: _showLanguageSheet,
                ),
              ],
            ),
            const SizedBox(height: 20),

            Center(
                child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                    child: Image.asset('assets/images/logo.png', height: 60))),
            const SizedBox(height: 32),

            Text('signup.title'.tr(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('signup.subtitle'.tr(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Color(0xFF64748B))),
            const SizedBox(height: 32),

            ProgressSteps(currentStep: _currentStep),
            const SizedBox(height: 32),

            if (_currentStep == 0) ...[
              CustomTextField(controller: _nameController, label: 'signup.name_label'.tr(), hint: 'signup.name_hint'.tr(), icon: Icons.person_rounded),
              const SizedBox(height: 20),
              CustomTextField(controller: _emailController, label: 'signup.email_label'.tr(), hint: 'signup.email_hint'.tr(), icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress),
            ] else ...[
              CustomTextField(controller: _passwordController, label: 'signup.password_label'.tr(), hint: 'signup.password_hint'.tr(), icon: Icons.lock_rounded, isPassword: true, isVisible: _passwordVisible, onVisibilityToggle: () => setState(() => _passwordVisible = !_passwordVisible)),
              const SizedBox(height: 20),
              CustomTextField(controller: _confirmPasswordController, label: 'signup.confirm_password_label'.tr(), hint: 'signup.password_hint'.tr(), icon: Icons.lock_rounded, isPassword: true, isVisible: _confirmPasswordVisible, onVisibilityToggle: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible)),
            ],

            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                  if (_currentStep == 0) {
                    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
                      AppDialogs.show(context, title: 'signup.fields_required_title'.tr(), message: 'signup.fields_required_msg'.tr());
                      return;
                    }
                    setState(() => _currentStep = 1);
                  } else {
                    _handleSignUp();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(_currentStep == 0 ? 'signup.continue'.tr() : 'signup.sign_up_button'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),

            if (_currentStep == 1) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: () => setState(() => _currentStep = 0), child: Text('signup.back'.tr(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600))),
            ],

            const SizedBox(height: 24),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('signup.already_registered'.tr(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 15)),
              const SizedBox(width: 4),
              GestureDetector(onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())), child: Text('signup.login'.tr(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700, fontSize: 15)))
            ])
          ]),
        ),
      ),
    );
  }
}