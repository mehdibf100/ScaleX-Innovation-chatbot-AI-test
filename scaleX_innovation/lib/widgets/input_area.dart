// lib/widgets/input_area.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class InputArea extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Future<void> Function(String) onSend;
  final VoidCallback onAttach;
  final VoidCallback onVoiceToggle;
  final bool isListening;

  const InputArea({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
    required this.onVoiceToggle,
    required this.isListening,
  }) : super(key: key);

  @override
  State<InputArea> createState() => _InputAreaState();
}

class _InputAreaState extends State<InputArea> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();

    // animation pour la wave vocale
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..addListener(() {
        // rebuild to update wave heights
        if (widget.isListening) setState(() {});
      });

    if (widget.isListening) {
      _animController.repeat();
    }

    // écoute les changements du controller pour mettre à jour le bouton d'envoi
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant InputArea oldWidget) {
    super.didUpdateWidget(oldWidget);

    // gestion animation start/stop quand isListening change
    if (widget.isListening && !_animController.isAnimating) {
      _animController.repeat();
    } else if (!widget.isListening && _animController.isAnimating) {
      _animController.stop();
    }

    // si le controller a changé, bascule la listener proprement
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // rebuild pour mettre à jour l'état du bouton d'envoi
    if (mounted) setState(() {});
  }

  // send and clear controller
  Future<void> _handleSend() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    await widget.onSend(text);
    widget.controller.clear();
    setState(() {}); // refresh UI (bouton send)
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.controller.text.trim().isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: Colors.grey[600]),
              onPressed: widget.onAttach,
              tooltip: 'input.attach_tooltip'.tr(),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(24)),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // The TextField
                    TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      maxLines: null,
                      decoration: InputDecoration.collapsed(hintText: 'input.hint'.tr()),
                      style: const TextStyle(fontSize: 15),
                    ),

                    // Voice wave overlay on the right side inside the input when listening
                    Positioned(
                      right: 8,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: widget.isListening
                            ? Container(
                          key: const ValueKey('voice_wave'),
                          height: 32,
                          padding: const EdgeInsets.only(left: 6, right: 6),
                          child: VoiceWave(
                            controllerValue: _animController.value,
                            barCount: 5,
                            maxHeight: 18,
                            color: Colors.redAccent,
                          ),
                        )
                            : const SizedBox.shrink(
                          key: ValueKey('no_wave'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // mic button
            IconButton(
              icon: widget.isListening ? const Icon(Icons.mic, color: Colors.red) : const Icon(Icons.mic_none),
              onPressed: widget.onVoiceToggle,
              tooltip: widget.isListening ? 'input.voice_stop'.tr() : 'input.voice_input'.tr(),
            ),
            const SizedBox(width: 6),
            // send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isEmpty
                    ? null
                    : const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                color: isEmpty ? Colors.grey[300] : null,
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEmpty ? null : _handleSend,
                  borderRadius: BorderRadius.circular(24),
                  child: Tooltip(
                    message: 'input.send_tooltip'.tr(),
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// VoiceWave draws a simple animated set of vertical bars.
class VoiceWave extends StatelessWidget {
  final double controllerValue;
  final int barCount;
  final double maxHeight;
  final Color color;

  const VoiceWave({
    Key? key,
    required this.controllerValue,
    this.barCount = 5,
    this.maxHeight = 18,
    this.color = Colors.redAccent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bars = List.generate(barCount, (i) {
      final phase = (i / barCount) * 2 * pi;
      final t = controllerValue * 2 * pi;
      final val = (sin(t + phase) + 1) / 2; // 0..1
      final eased = Curves.easeInOut.transform(val);
      final h = 6 + eased * (maxHeight - 6); // min 6 to maxHeight
      return _buildBar(h);
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: bars
          .map((w) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: w,
      ))
          .toList(),
    );
  }

  Widget _buildBar(double height) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 3.4,
        height: height,
        decoration: BoxDecoration(color: color.withOpacity(0.95), borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}