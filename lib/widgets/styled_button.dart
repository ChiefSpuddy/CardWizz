import 'package:flutter/material.dart';

class StyledButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData? icon;
  final Color? color;
  final bool isOutlined;
  final bool isWide;
  final bool hasGlow;
  final bool isLoading;

  const StyledButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.color,
    this.isOutlined = false,
    this.isWide = false,
    this.hasGlow = false,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<StyledButton> createState() => _StyledButtonState();
}

class _StyledButtonState extends State<StyledButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      _controller.forward();
      setState(() {
        _isPressed = true;
      });
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapCancel() {
    _controller.reverse();
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonColor = widget.color ?? colorScheme.primary;
    final textColor = widget.isOutlined ? buttonColor : Colors.white;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: widget.isWide ? double.infinity : null,
                height: 56,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isWide ? 24 : 32,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.isOutlined ? Colors.transparent : buttonColor,
                  borderRadius: BorderRadius.circular(20),
                  border: widget.isOutlined
                      ? Border.all(color: buttonColor, width: 2)
                      : null,
                  boxShadow: widget.hasGlow && !widget.isOutlined
                      ? [
                          BoxShadow(
                            color: buttonColor.withOpacity(0.5),
                            spreadRadius: _isPressed ? 1 : 2,
                            blurRadius: _isPressed ? 5 : 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: widget.isWide ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null && !widget.isLoading) ...[
                      Icon(widget.icon, color: textColor),
                      const SizedBox(width: 12),
                    ],
                    if (widget.isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(textColor),
                        ),
                      )
                    else
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
