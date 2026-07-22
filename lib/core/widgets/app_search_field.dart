import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';

/// Ortak arama alanı — 300ms debounce ile `onDebouncedChanged` tetikler.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    required this.hintText,
    this.controller,
    this.onDebouncedChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.isDark = false,
    super.key,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onDebouncedChanged;
  final Duration debounceDuration;
  final bool isDark;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onDebouncedChanged?.call(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final fill = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF4F4F9);
    final hintColor =
        isDark ? const Color(0x99FFFFFF) : const Color(0xFFB9B9C6);
    final textColor = isDark ? AppColors.white : AppColors.deepRoast;
    final iconColor = isDark ? AppColors.white : null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(99999),
      ),
      child: Row(
        children: [
          AppIcon(AssetPaths.iconSearch, size: 24, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              cursorColor: isDark ? AppColors.zoviOrange : null,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 20 / 16,
                letterSpacing: -0.32,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 20 / 16,
                  letterSpacing: -0.32,
                  color: hintColor,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
