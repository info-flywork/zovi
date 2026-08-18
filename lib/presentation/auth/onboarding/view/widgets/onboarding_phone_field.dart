part of '../onboarding_view.dart';

@immutable
final class OnboardingPhoneField extends StatefulWidget {
  const OnboardingPhoneField({
    required this.phone,
    required this.selectedCountry,
    required this.onChanged,
    required this.onCountryTap,
    super.key,
  });

  final String phone;
  final Country selectedCountry;
  final ValueChanged<String> onChanged;
  final VoidCallback onCountryTap;

  @override
  State<OnboardingPhoneField> createState() => _OnboardingPhoneFieldState();
}

final class _OnboardingPhoneFieldState extends State<OnboardingPhoneField> {
  late final TextEditingController _controller;
  late PhoneFormat _format;
  late CountryPhoneInputFormatter _formatter;

  @override
  void initState() {
    super.initState();
    _format = PhoneFormats.forCountry(widget.selectedCountry.isoCode);
    _formatter = CountryPhoneInputFormatter(_format);
    _controller = TextEditingController(
      text: _format.formatDigits(widget.phone),
    );
  }

  @override
  void didUpdateWidget(OnboardingPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedCountry.isoCode != widget.selectedCountry.isoCode) {
      _format = PhoneFormats.forCountry(widget.selectedCountry.isoCode);
      _formatter = CountryPhoneInputFormatter(_format);
      final digits = _format.limitDigits(widget.phone);
      _updateController(digits);
      if (digits != widget.phone) {
        widget.onChanged(digits);
      }
      return;
    }

    if (oldWidget.phone != widget.phone &&
        widget.phone != _format.limitDigits(_controller.text)) {
      _updateController(widget.phone);
    }
  }

  void _updateController(String digits) {
    final formatted = _format.formatDigits(digits);
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _handleChanged(String value) {
    final digits = _format.limitDigits(value);
    if (digits != widget.phone) {
      widget.onChanged(digits);
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
          'phone_number'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: -0.32,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderSoft),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onCountryTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AppColors.warmAmber),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CountryFlag(country: widget.selectedCountry),
                        const SizedBox(width: 8),
                        Text(
                          widget.selectedCountry.dialCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.32,
                            color: AppColors.deepRoast,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.mutedGray,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_formatter],
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  onChanged: _handleChanged,
                  decoration: InputDecoration(
                    hintText: _format.example,
                    hintStyle: const TextStyle(
                      color: AppColors.placeholder,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 14,
                    ),
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
