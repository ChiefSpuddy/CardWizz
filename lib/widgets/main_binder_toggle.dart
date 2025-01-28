import 'package:flutter/material.dart';
import '../constants/colors.dart';

class MainBinderToggle extends StatelessWidget {
  final bool showMain;
  final ValueChanged<bool> onToggle;

  const MainBinderToggle({
    super.key,
    required this.showMain,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient.scale(0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonWidth = constraints.maxWidth / 2 - 4;
          return Stack(
            children: [
              // Animated selection indicator
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: showMain ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: buttonWidth,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildToggleButton('Main', showMain, true),
                  _buildToggleButton('Binder', !showMain, false),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, bool isMain) {
    return GestureDetector(
      onTap: () => onToggle(isMain),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
