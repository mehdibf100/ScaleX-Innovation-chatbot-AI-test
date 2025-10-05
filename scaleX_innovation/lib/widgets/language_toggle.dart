// lib/widgets/language_toggle.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive/hive.dart';

class LanguageToggle extends StatefulWidget {
  const LanguageToggle({Key? key}) : super(key: key);

  @override
  State<LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<LanguageToggle> {
  String _current = 'en';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final box = await Hive.openBox('settings');
      final saved = box.get('locale', defaultValue: 'en') as String;
      setState(() => _current = saved);
    } catch (_) {}
  }

  Future<void> _setLocale(String code) async {
    final locale = Locale(code);
    await context.setLocale(locale);
    final box = await Hive.openBox('settings');
    await box.put('locale', code);
    setState(() => _current = code);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.language, color: Colors.grey[700]),
      onSelected: (v) => _setLocale(v),
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'en', child: Text('English')),
        PopupMenuItem(value: 'ar', child: Text('العربية')),
      ],
    );
  }
}
