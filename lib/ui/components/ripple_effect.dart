import 'package:flutter/material.dart';

class RippleEffect extends StatefulWidget {
  final Widget child;
  final Color rippleColor;
  final double radius;
  
  const RippleEffect({
    super.key,
    required this.child,
    this.rippleColor = Colors.blue,
    this.radius = 60.0,
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late Animation<double> _animation1;
  late Animation<double> _animation2;

  @override
  void initState() {
    super.initState();
    
    _controller1 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _controller2 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _animation1 = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller1,
      curve: Curves.easeOut,
    ));

    _animation2 = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller2,
      curve: Curves.easeOut,
    ));

    // Start animations with delay
    _controller1.repeat();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _controller2.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.radius,
      height: widget.radius,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // First ripple
          AnimatedBuilder(
            animation: _animation1,
            builder: (context, child) {
              return Container(
                width: widget.radius * _animation1.value,
                height: widget.radius * _animation1.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.rippleColor.withOpacity(
                      (1.0 - _animation1.value) * 0.3,
                    ),
                    width: 2,
                  ),
                ),
              );
            },
          ),
          // Second ripple
          AnimatedBuilder(
            animation: _animation2,
            builder: (context, child) {
              return Container(
                width: widget.radius * _animation2.value,
                height: widget.radius * _animation2.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.rippleColor.withOpacity(
                      (1.0 - _animation2.value) * 0.3,
                    ),
                    width: 2,
                  ),
                ),
              );
            },
          ),
          // Center content
          widget.child,
        ],
      ),
    );
  }
}
