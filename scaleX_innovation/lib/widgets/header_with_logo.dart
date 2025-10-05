import 'package:flutter/material.dart';
import 'package:scalex_innovation/widgets/language_sheet.dart';


class HeaderWithLogo extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack;


  const HeaderWithLogo({Key? key, this.showBack = false, this.onBack}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showBack)
          IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF64748B)), onPressed: onBack)
        else
          const SizedBox(width: 48),
        Image.asset('assets/images/logo.png', height: 32),
        IconButton(icon: const Icon(Icons.language_rounded, color: Color(0xFF64748B)), onPressed: () => LanguageSheet.show(context)),
      ],
    );
  }
}