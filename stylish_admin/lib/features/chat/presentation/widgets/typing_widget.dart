import 'package:flutter/material.dart';
import 'package:stylish_admin/core/theme/theme.dart';

class TypingWidget extends StatefulWidget {
  const TypingWidget({super.key});

  @override
  State<TypingWidget> createState() => _TypingWidgetState();
}

class _TypingWidgetState extends State<TypingWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (indext) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _animations = _controllers
        .map(
          (controller) => Tween<double>(begin: 0.4, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          ),
        )
        .toList();
    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) => Container(
            margin: const EdgeInsets.only(right: 4),
            child: Opacity(
              opacity: _animations[index].value,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
