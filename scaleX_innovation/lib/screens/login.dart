import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:scalex_innovation/screens/signup.dart';
import 'package:scalex_innovation/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scalex_innovation/widgets/app_dialogs.dart';
import 'package:scalex_innovation/widgets/custom_text_field.dart';
import 'package:scalex_innovation/widgets/divider_with_text.dart';
import 'package:scalex_innovation/widgets/language_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _passwordVisible = false;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      await AppDialogs.show(context, title: 'login.fields_required_title'.tr(), message: 'login.fields_required_msg'.tr());
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await _authService.signIn(_emailController.text.trim(), _passwordController.text);
      if (credential.user != null && credential.user!.emailVerified) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        await AppDialogs.show(context, title: 'login.email_unverified_title'.tr(), message: 'login.email_unverified_msg'.tr());
      }
    } on FirebaseAuthException catch (e) {
      String message = 'login.auth_error_default'.tr();
      if (e.code == 'user-not-found') message = 'login.auth_error_user_not_found'.tr();
      else if (e.code == 'wrong-password') message = 'login.auth_error_wrong_password'.tr();
      else if (e.code == 'invalid-email') message = 'login.auth_error_invalid_email'.tr();
      await AppDialogs.show(context, title: 'login.auth_error_title'.tr(), message: message);
    } catch (_) {
      await AppDialogs.show(context, title: 'login.auth_error_title'.tr(), message: 'login.auth_error_default'.tr());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('Erreur de connexion Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la connexion avec Google')),
      );
    }
  }


  void _showForgotPasswordSheet() {
    final TextEditingController _resetEmailController = TextEditingController(text: _emailController.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text('login.forgot_password_title'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            CustomTextField(controller: _resetEmailController, label: 'login.email_label'.tr(), hint: 'login.email_hint'.tr(), icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final email = _resetEmailController.text.trim();
                  if (email.isEmpty) {
                    await AppDialogs.show(context, title: 'login.fields_required_title'.tr(), message: 'login.fields_required_msg'.tr());
                    return;
                  }
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    await _authService.sendPasswordResetEmail(email);
                    await AppDialogs.show(context, title: 'login.reset_sent_title'.tr(), message: 'login.reset_sent_msg'.tr(), success: true);
                  } on FirebaseAuthException catch (e) {
                    await AppDialogs.show(context, title: 'login.auth_error_title'.tr(), message: e.message ?? 'login.auth_error_default'.tr());
                  } catch (_) {
                    await AppDialogs.show(context, title: 'login.auth_error_title'.tr(), message: 'login.auth_error_default'.tr());
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('login.reset_password_button'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          Align(
          alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.language_rounded, color: Color(0xFF64748B)),
              onPressed: () => LanguageSheet.show(context),
            ),
          ),
            const SizedBox(height: 20),

            Center(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)), child: Image.asset('assets/images/logo.png', height: 60))),
            const SizedBox(height: 32),

            Text('login.welcome'.tr(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('login.subtitle'.tr(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Color(0xFF64748B))),
            const SizedBox(height: 40),

            CustomTextField(controller: _emailController, label: 'login.email_label'.tr(), hint: 'login.email_hint'.tr(), icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),

            CustomTextField(controller: _passwordController, label: 'login.password_label'.tr(), hint: 'login.password_hint'.tr(), icon: Icons.lock_rounded, isPassword: true, isVisible: _passwordVisible, onVisibilityToggle: () => setState(() => _passwordVisible = !_passwordVisible)),

            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _showForgotPasswordSheet, child: Text('login.forgot_password'.tr(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600, fontSize: 14)))),
            const SizedBox(height: 24),

            SizedBox(height: 52, child: ElevatedButton(onPressed: _isLoading ? null : _handleLogin, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : Text('login.login_button'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
            const SizedBox(height: 24),

            const DividerWithText(textKey: 'login.or'),
            const SizedBox(height: 24),

            SizedBox(height: 52, child: OutlinedButton(onPressed: _isLoading ? null : _handleGoogleSignIn, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Color(0xFFE2E8F0)), backgroundColor: Colors.white), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.g_mobiledata, size: 22, color: Color(0xFF6366F1)), SizedBox(width: 8), Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827)))]))),
            const SizedBox(height: 24),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('login.no_account'.tr(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 15)), const SizedBox(width: 4), GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())), child: Text('login.sign_up'.tr(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700, fontSize: 15)))])
          ]),
        ),
      ),
    );
  }
}