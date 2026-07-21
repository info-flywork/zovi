import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';

class AuthProgressBar extends StatelessWidget {
  const AuthProgressBar({
    required this.activeIndex,
    this.stepCount = 3,
    super.key,
  });

  final int activeIndex;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(stepCount, (index) {
        final active = index <= activeIndex;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: index == stepCount - 1 ? 0 : 10),
            decoration: BoxDecoration(
              color: active ? AppColors.zoviOrange : AppColors.progressInactive,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
