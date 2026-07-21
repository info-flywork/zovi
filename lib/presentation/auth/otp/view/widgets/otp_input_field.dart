part of '../otp_view.dart';

class OtpInputField extends StatefulWidget {
  const OtpInputField({
    required this.code,
    required this.onChanged,
    super.key,
  });

  final String code;
  final ValueChanged<String> onChanged;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(() => setState(() {}));
    _controller = TextEditingController(text: widget.code);
  }

  @override
  void didUpdateWidget(covariant OtpInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code && _controller.text != widget.code) {
      _controller
        ..text = widget.code
        ..selection = TextSelection.collapsed(offset: widget.code.length);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  int get _activeIndex {
    if (!_focusNode.hasFocus) {
      return widget.code.length.clamp(0, 5);
    }
    return widget.code.length.clamp(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        SizedBox(
          width: 1,
          height: 1,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: widget.onChanged,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          behavior: HitTestBehavior.translucent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final digit = index < widget.code.length ? widget.code[index] : '';
              final isFilled = digit.isNotEmpty;
              final isActive = _focusNode.hasFocus && index == _activeIndex;

              return _OtpDigitBox(
                digit: digit,
                isFilled: isFilled,
                isActive: isActive,
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _OtpDigitBox extends StatelessWidget {
  const _OtpDigitBox({
    required this.digit,
    required this.isFilled,
    required this.isActive,
  });

  final String digit;
  final bool isFilled;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final borderColor = isFilled || isActive
        ? AppColors.warmAmber
        : AppColors.creamBase;

    return Container(
      width: 44,
      height: 60,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: Text(
        digit,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          height: 40 / 32,
          letterSpacing: -0.64,
          color: AppColors.zoviOrange,
        ),
      ),
    );
  }
}
