import 'package:flutter/material.dart';
import 'package:scalex_innovation/screens/login.dart';
import 'package:scalex_innovation/screens/signup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scalex_innovation/widgets/language_sheet.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(icon: Icons.chat_bubble_rounded, title: 'onboarding.page1_title', description: 'onboarding.page1_desc', color: const Color(0xFF6366F1)),
    OnboardingPage(icon: Icons.psychology_rounded, title: 'onboarding.page2_title', description: 'onboarding.page2_desc', color: const Color(0xFF8B5CF6)),
    OnboardingPage(icon: Icons.rocket_launch_rounded, title: 'onboarding.page3_title', description: 'onboarding.page3_desc', color: const Color(0xFFEC4899)),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _completeOnboarding();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Image.asset('assets/images/logo.png', height: 32),
              IconButton(
                icon: const Icon(Icons.language_rounded, color: Color(0xFF64748B)),
                onPressed: () => LanguageSheet.show(context),
              ),
              if (_currentPage < _pages.length - 1)
                TextButton(onPressed: _skipOnboarding, child: Text('onboarding.skip'.tr(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w600))),
            ]),
          ),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _pages.length,
              itemBuilder: (context, index) => _buildPage(_pages[index]),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(color: _currentPage == index ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                  );
                }),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(_currentPage == _pages.length - 1 ? 'onboarding.get_started'.tr() : 'onboarding.next'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              if (_currentPage == _pages.length - 1) ...[
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('onboarding.no_account'.tr(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 15)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      _completeOnboarding();
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
                    },
                    child: Text('onboarding.sign_up'.tr(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700, fontSize: 15)),
                  )
                ])
              ]
            ]),
          )
        ]),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 120, height: 120, decoration: BoxDecoration(color: page.color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(page.icon, size: 64, color: page.color)),
        const SizedBox(height: 48),
        Text(page.title.tr(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.2)),
        const SizedBox(height: 16),
        Text(page.description.tr(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.5))
      ]),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({required this.icon, required this.title, required this.description, required this.color});
}
