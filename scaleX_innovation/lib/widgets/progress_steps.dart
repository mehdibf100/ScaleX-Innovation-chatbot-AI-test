import 'package:flutter/material.dart';


class ProgressSteps extends StatelessWidget {
  final int currentStep; // 0 or 1
  const ProgressSteps({Key? key, required this.currentStep}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 4, decoration: BoxDecoration(color: currentStep == 1 ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
      ],
    );
  }
}