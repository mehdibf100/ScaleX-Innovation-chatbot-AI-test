import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';


class AppDialogs {
  static Future<void> show(
      BuildContext context, {
        required String title,
        required String message,
        bool success = false,
      }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr(), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }
}