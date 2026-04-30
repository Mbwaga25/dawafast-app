import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:afyalink/core/theme.dart';

class AfyaLinkLoader extends StatefulWidget {
  final double size;
  final String message;

  const AfyaLinkLoader({
    super.key,
    this.size = 180,
    this.message = 'Loading...',
  });

  @override
  State<AfyaLinkLoader> createState() => _AfyaLinkLoaderState();
}

class _AfyaLinkLoaderState extends State<AfyaLinkLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: SvgPicture.asset(
                    'lib/assets/images/afyalink-logo-horizontal.svg',
                    width: widget.size,
                    placeholderBuilder: (context) => const CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 40,
            child: LinearProgressIndicator(
              backgroundColor: AppTheme.borderColor,
              color: AppTheme.primaryTeal,
              minHeight: 2,
            ),
          ),
          if (widget.message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              widget.message,
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontSize: 14,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AfyaLinkScaffoldLoader extends StatelessWidget {
  final String message;
  const AfyaLinkScaffoldLoader({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AfyaLinkLoader(message: message),
    );
  }
}
