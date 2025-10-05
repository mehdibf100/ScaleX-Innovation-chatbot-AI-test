

// File: lib/widgets/scroll_to_bottom_button.dart
import 'package:flutter/material.dart';

class ScrollToBottomButton extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onPressed;

  const ScrollToBottomButton({Key? key, required this.animation, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 100,
      child: ScaleTransition(
        scale: animation,
        child: FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.arrow_downward, color: Color(0xFF667EEA)),
        ),
      ),
    );
  }
}
