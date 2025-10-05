import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';


class DividerWithText extends StatelessWidget {
  final String textKey;
  const DividerWithText({Key? key, required this.textKey}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(textKey.tr(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14))),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }
}