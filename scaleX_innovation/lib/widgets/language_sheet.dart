// lib/widgets/language_sheet.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageSheet {
  /// Affiche le bottom sheet des langues.
  /// Ajoute des protections pour éviter un affichage vide (images manquantes, clavier, etc.)
  static Future<void> show(BuildContext context) async {
    debugPrint('LanguageSheet.show called'); // debugger simple

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true, // important pour éviter que la sheet soit coupée
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            // permet au contenu d'être visible même si le clavier est ouvert
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLanguageOption(context, 'English', 'assets/images/flags/en.png', 'en'),
                  _buildLanguageOption(context, 'العربية', 'assets/images/flags/ar.png', 'ar'),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildLanguageOption(BuildContext context, String title, String flagPath, String code) {
    final isSelected = EasyLocalization.of(context)?.locale.languageCode == code;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(
          flagPath,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          // si l'asset est manquant on affiche une icône de remplacement
          errorBuilder: (context, error, stackTrace) {
            debugPrint('LanguageSheet: asset not found -> $flagPath');
            return Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
              child: const Icon(Icons.flag, size: 18, color: Color(0xFF64748B)),
            );
          },
        ),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: isSelected == true ? const Icon(Icons.check_circle_rounded, color: Color(0xFF6366F1), size: 24) : null,
      onTap: () {
        // garde la sécurité si easy_localization non initialisé
        try {
          context.setLocale(Locale(code));
        } catch (e) {
          debugPrint('LanguageSheet: setLocale failed -> $e');
        }
        Navigator.pop(context);
      },
    );
  }
}
