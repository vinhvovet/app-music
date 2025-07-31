import 'package:flutter/material.dart';

class AudioWaveAnimation extends StatefulWidget {
  final Color color;
  final double size;
  
  const AudioWaveAnimation({
    super.key,
    this.color = Colors.blue,
    this.size = 20.0,
  });

  @override
  State<AudioWaveAnimation> createState() => _AudioWaveAnimationState();
}

class _AudioWaveAnimationState extends State<AudioWaveAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    // Tạo 4 thanh sóng với animation khác nhau
    _controllers = List.generate(4, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 300 + (index * 100)),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.2,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    // Bắt đầu animations với delay khác nhau
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: 2,
                height: widget.size * _animations[index].value,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
