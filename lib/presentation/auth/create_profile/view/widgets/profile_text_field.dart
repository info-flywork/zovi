part of '../create_profile_view.dart';

@immutable
final class ProfileTextField extends StatefulWidget {
  const ProfileTextField({
    required this.label,
    required this.hint,
    required this.iconPath,
    required this.iconBackgroundColor,
    required this.value,
    required this.onChanged,
    this.inputFormatters,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    super.key,
  });

  final String label;
  final String hint;
  final String iconPath;
  final Color iconBackgroundColor;
  final String value;
  final ValueChanged<String> onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  State<ProfileTextField> createState() => _ProfileTextFieldState();
}

final class _ProfileTextFieldState extends State<ProfileTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(ProfileTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      final selection = _controller.selection;
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset.clamp(0, widget.value.length),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 20 / 16,
            letterSpacing: -0.32,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 64,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x0D000000)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AppIcon(widget.iconPath, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: widget.onChanged,
                  inputFormatters: widget.inputFormatters,
                  keyboardType: widget.keyboardType,
                  textCapitalization: widget.textCapitalization,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 20 / 16,
                    letterSpacing: -0.32,
                    color: AppColors.deepRoast,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 20 / 16,
                      letterSpacing: -0.32,
                      color: AppColors.black.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tek isim: 25, isim + soyisim (boşluk varsa): 50.
@immutable
final class FullNameLengthLimitingFormatter extends TextInputFormatter {
  const FullNameLengthLimitingFormatter();

  static const singleNameMax = 25;
  static const fullNameMax = 50;
  static const usernameMax = 15;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final maxLen = text.contains(RegExp(r'\s')) ? fullNameMax : singleNameMax;
    if (text.length <= maxLen) return newValue;
    final limited = text.substring(0, maxLen);
    return TextEditingValue(
      text: limited,
      selection: TextSelection.collapsed(offset: limited.length),
    );
  }
}
