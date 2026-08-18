import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';

enum CameraTextEditorTab { keyboard, fonts, style, typography, color }

@immutable
final class CameraTextDraft {
  const CameraTextDraft({
    this.text = '',
    this.fontId = 'montserrat',
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.uppercase = false,
    this.align = TextAlign.center,
    this.fontSize = 28,
    this.letterSpacing = 0,
    this.lineHeight = 1.2,
    this.color = AppColors.white,
  });

  final String text;
  final String fontId;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool uppercase;
  final TextAlign align;
  final double fontSize;
  final double letterSpacing;
  final double lineHeight;
  final Color color;

  bool get hasContent => text.trim().isNotEmpty;

  String get displayText {
    final value = text.trim().isEmpty ? 'camera_text_placeholder'.tr() : text;
    return uppercase ? value.toUpperCase() : value;
  }

  TextStyle get textStyle {
    final base = _fontStyle(fontId);
    return base.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: underline ? TextDecoration.underline : TextDecoration.none,
      decorationColor: color,
      letterSpacing: letterSpacing,
      height: lineHeight,
    );
  }

  CameraTextDraft copyWith({
    String? text,
    String? fontId,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? uppercase,
    TextAlign? align,
    double? fontSize,
    double? letterSpacing,
    double? lineHeight,
    Color? color,
  }) {
    return CameraTextDraft(
      text: text ?? this.text,
      fontId: fontId ?? this.fontId,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      uppercase: uppercase ?? this.uppercase,
      align: align ?? this.align,
      fontSize: fontSize ?? this.fontSize,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      color: color ?? this.color,
    );
  }
}

TextStyle _fontStyle(String id) {
  return switch (id) {
    'amiri' => GoogleFonts.amiri(),
    'manrope' => GoogleFonts.manrope(),
    'bebas' => GoogleFonts.bebasNeue(),
    'marker' => GoogleFonts.permanentMarker(),
    'mandali' => GoogleFonts.mandali(),
    'oswald' => GoogleFonts.oswald(),
    'belgrano' => GoogleFonts.belgrano(),
    'changa' => GoogleFonts.changaOne(),
    'muna' => GoogleFonts.cairo(),
    'mysoul' => GoogleFonts.greatVibes(),
    'noteworthy' => GoogleFonts.patrickHand(),
    'oxygen' => GoogleFonts.oxygen(),
    'ponomar' => GoogleFonts.robotoSlab(),
    'puritan' => GoogleFonts.puritan(),
    _ => GoogleFonts.montserrat(),
  };
}

@immutable
final class _FontOption {
  const _FontOption(this.id, this.label, {this.locked = false});

  final String id;
  final String label;
  final bool locked;
}

const _fonts = [
  _FontOption('montserrat', 'Montserrat'),
  _FontOption('amiri', 'Amiri'),
  _FontOption('manrope', 'Manrope'),
  _FontOption('bebas', 'BEBAS NEUE'),
  _FontOption('marker', 'Marker Felt'),
  _FontOption('mandali', 'Mandali'),
  _FontOption('oswald', 'Oswald'),
  _FontOption('belgrano', 'Belgrano'),
  _FontOption('changa', 'Changa One'),
  _FontOption('muna', 'Muna'),
  _FontOption('mysoul', 'My Soul'),
  _FontOption('noteworthy', 'Noteworthy'),
  _FontOption('oxygen', 'Oxygen', locked: true),
  _FontOption('ponomar', 'Ponomar', locked: true),
  _FontOption('puritan', 'Puritan', locked: true),
];

const _colors = [
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFBECDDF),
  Color(0xFF305181),
  Color(0xFF71AC9B),
  Color(0xFF98C18A),
  Color(0xFFDDE8D9),
  Color(0xFFFAE9BA),
  Color(0xFFFDE977),
  Color(0xFFFAE9BA),
  Color(0xFFFDE977),
  Color(0xFFEEB836),
  Color(0xFFDE7B5D),
  Color(0xFFAE2A29),
  Color(0xFFDD655E),
  Color(0xFFCFA67D),
  Color(0xFFDDD2CF),
  Color(0xFFE7DDF0),
  Color(0xFFAE9FC4),
  Color(0xFF979797),
  Color(0xFFD9D9D9),
  Color(0xFF5A8736),
  Color(0xFF5A0051),
];

Future<CameraTextDraft?> showCameraTextEditorSheet(
  BuildContext context, {
  CameraTextDraft? initial,
}) {
  return showGeneralDialog<CameraTextDraft>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'text-editor',
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondary) {
      return CameraTextEditorSheet(initial: initial ?? const CameraTextDraft());
    },
    transitionBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

@immutable
final class CameraTextEditorSheet extends StatefulWidget {
  const CameraTextEditorSheet({required this.initial, super.key});

  final CameraTextDraft initial;

  @override
  State<CameraTextEditorSheet> createState() => _CameraTextEditorSheetState();
}

final class _CameraTextEditorSheetState extends State<CameraTextEditorSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late CameraTextDraft _draft;
  var _tab = CameraTextEditorTab.keyboard;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _controller = TextEditingController(text: widget.initial.text);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _update(CameraTextDraft draft) {
    setState(() {
      _draft = draft.copyWith(text: _controller.text);
    });
  }

  String get _previewLabel {
    final raw = _controller.text;
    if (raw.trim().isEmpty) return 'camera_text_placeholder'.tr();
    return _draft.uppercase ? raw.toUpperCase() : raw;
  }

  void _selectTab(CameraTextEditorTab tab) {
    setState(() => _tab = tab);
    if (tab == CameraTextEditorTab.keyboard) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
  }

  void _done() {
    Navigator.of(context).pop(_draft.copyWith(text: _controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardTab = _tab == CameraTextEditorTab.keyboard;
    final maxPanelHeight = MediaQuery.sizeOf(context).height * 0.45;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _done,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),

          Align(
            alignment: const Alignment(0, -0.35),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: isKeyboardTab
                  ? TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textAlign: _draft.align,
                      minLines: 1,
                      maxLines: 6,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.text,
                      cursorColor: AppColors.white,
                      style: _draft.textStyle,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'camera_text_placeholder'.tr(),
                        hintStyle: _draft.textStyle.copyWith(
                          color: AppColors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      onSubmitted: (_) => _done(),
                    )
                  : Text(
                      _previewLabel,
                      textAlign: _draft.align,
                      style: _draft.textStyle.copyWith(
                        color: _controller.text.trim().isEmpty
                            ? AppColors.white.withValues(alpha: 0.55)
                            : _draft.color,
                      ),
                    ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: double.infinity,
                    color: AppColors.black.withValues(alpha: 0.90),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Color(0XFFD9D9D9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _TabIcon(
                                  asset: AssetPaths.iconKeyboard,
                                  selected:
                                      _tab == CameraTextEditorTab.keyboard,
                                  onTap: () =>
                                      _selectTab(CameraTextEditorTab.keyboard),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TabIcon(
                                  asset: AssetPaths.iconT,
                                  selected: _tab == CameraTextEditorTab.fonts,
                                  onTap: () =>
                                      _selectTab(CameraTextEditorTab.fonts),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TabIcon(
                                  asset: AssetPaths.iconUnderline,
                                  selected: _tab == CameraTextEditorTab.style,
                                  onTap: () =>
                                      _selectTab(CameraTextEditorTab.style),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TabIcon(
                                  asset: AssetPaths.iconAa,
                                  selected:
                                      _tab == CameraTextEditorTab.typography,
                                  onTap: () => _selectTab(
                                    CameraTextEditorTab.typography,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TabIcon(
                                  asset: AssetPaths.iconColorful,
                                  selected: _tab == CameraTextEditorTab.color,
                                  onTap: () =>
                                      _selectTab(CameraTextEditorTab.color),
                                ),
                              ),
                            ],
                          ),
                          if (!isKeyboardTab) ...[
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: maxPanelHeight,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 240),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                layoutBuilder:
                                    (currentChild, previousChildren) {
                                      return Stack(
                                        alignment: Alignment.topCenter,
                                        clipBehavior: Clip.none,
                                        children: [
                                          ...previousChildren,
                                          ?currentChild,
                                        ],
                                      );
                                    },
                                child: KeyedSubtree(
                                  key: ValueKey(_tab),
                                  child: switch (_tab) {
                                    CameraTextEditorTab.keyboard =>
                                      const SizedBox.shrink(),
                                    CameraTextEditorTab.fonts => _FontsPanel(
                                      selectedId: _draft.fontId,
                                      onSelect: (id) =>
                                          _update(_draft.copyWith(fontId: id)),
                                    ),
                                    CameraTextEditorTab.style => _StylePanel(
                                      draft: _draft,
                                      onChanged: _update,
                                    ),
                                    CameraTextEditorTab.typography =>
                                      _TypographyPanel(
                                        draft: _draft,
                                        onChanged: _update,
                                      ),
                                    CameraTextEditorTab.color => _ColorPanel(
                                      selected: _draft.color,
                                      onSelect: (color) => _update(
                                        _draft.copyWith(color: color),
                                      ),
                                    ),
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
final class _TabIcon extends StatelessWidget {
  const _TabIcon({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 54,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.white.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
        ),
        alignment: Alignment.center,
        child: AppIcon(asset, color: AppColors.white),
      ),
    );
  }
}

@immutable
final class _FontsPanel extends StatelessWidget {
  const _FontsPanel({required this.selectedId, required this.onSelect});

  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      clipBehavior: Clip.none,
      padding: const EdgeInsets.only(bottom: 10, right: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 120 / 54,
      ),
      itemCount: _fonts.length,
      itemBuilder: (context, index) {
        final font = _fonts[index];
        final selected = font.id == selectedId;
        return GestureDetector(
          onTap: font.locked ? null : () => onSelect(font.id),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.white.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    font.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _fontStyle(font.id).copyWith(
                      color: AppColors.white.withValues(
                        alpha: font.locked ? 0.45 : 1,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 22 / 16,
                    ),
                  ),
                ),
              ),
              if (font.locked)
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A151B),
                      shape: BoxShape.circle,
                    ),
                    child: const AppIcon('assets/icons/lock-3.svg', size: 16),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

@immutable
final class _StylePanel extends StatelessWidget {
  const _StylePanel({required this.draft, required this.onChanged});

  final CameraTextDraft draft;
  final ValueChanged<CameraTextDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _StyleChip(
                icon: AssetPaths.iconBold,
                label: 'Bold',
                selected: draft.bold,
                onTap: () => onChanged(draft.copyWith(bold: !draft.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StyleChip(
                icon: AssetPaths.iconItalic,
                label: 'Italic',
                selected: draft.italic,
                onTap: () => onChanged(draft.copyWith(italic: !draft.italic)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StyleChip(
                icon: AssetPaths.iconUppercase,
                label: 'Uppercase',
                selected: draft.uppercase,
                onTap: () =>
                    onChanged(draft.copyWith(uppercase: !draft.uppercase)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _StyleChip(
          icon: AssetPaths.iconUnderline,
          label: 'Underline',
          selected: draft.underline,
          onTap: () => onChanged(draft.copyWith(underline: !draft.underline)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _AlignIcon(
                asset: AssetPaths.iconAlignLeft,
                selected: draft.align == TextAlign.left,
                onTap: () => onChanged(draft.copyWith(align: TextAlign.left)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AlignIcon(
                asset: AssetPaths.iconAlignMid,
                selected: draft.align == TextAlign.center,
                onTap: () => onChanged(draft.copyWith(align: TextAlign.center)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AlignIcon(
                asset: AssetPaths.iconAlignRight,
                selected: draft.align == TextAlign.right,
                onTap: () => onChanged(draft.copyWith(align: TextAlign.right)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AlignIcon(
                asset: AssetPaths.iconAll2,
                selected: draft.align == TextAlign.justify,
                onTap: () =>
                    onChanged(draft.copyWith(align: TextAlign.justify)),
              ),
            ),
          ],
        ),
        SizedBox(height: kBottomNavigationBarHeight / 2),
      ],
    );
  }
}

@immutable
final class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.white.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(icon, size: 20, color: AppColors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _AlignIcon extends StatelessWidget {
  const _AlignIcon({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 54,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.white.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
        ),
        alignment: Alignment.center,
        child: AppIcon(asset, size: 24, color: AppColors.white),
      ),
    );
  }
}

@immutable
final class _TypographyPanel extends StatelessWidget {
  const _TypographyPanel({required this.draft, required this.onChanged});

  final CameraTextDraft draft;
  final ValueChanged<CameraTextDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SliderRow(
          icon: AssetPaths.iconAa,
          value: draft.fontSize,
          min: 16,
          max: 56,
          display: draft.fontSize.round().toString(),
          onChanged: (v) => onChanged(draft.copyWith(fontSize: v)),
        ),
        const SizedBox(height: 14),
        _SliderRow(
          icon: AssetPaths.iconAbUnderline,
          value: draft.letterSpacing,
          min: -2,
          max: 12,
          display: draft.letterSpacing.round().toString(),
          onChanged: (v) => onChanged(draft.copyWith(letterSpacing: v)),
        ),
        const SizedBox(height: 14),
        _SliderRow(
          icon: AssetPaths.iconLinesLeft,
          value: draft.lineHeight,
          min: 0.9,
          max: 2.2,
          display: (draft.lineHeight * 10).round().toString(),
          onChanged: (v) => onChanged(draft.copyWith(lineHeight: v)),
        ),
        SizedBox(height: kBottomNavigationBarHeight / 3),
      ],
    );
  }
}

@immutable
final class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  final String icon;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, size: 24, color: AppColors.white),
        const SizedBox(width: 10),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.white,
              inactiveTrackColor: AppColors.white.withValues(alpha: 0.2),
              thumbColor: AppColors.white,
              overlayColor: AppColors.white.withValues(alpha: 0.12),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            display,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 24 / 16,
            ),
          ),
        ),
      ],
    );
  }
}

@immutable
final class _ColorPanel extends StatelessWidget {
  const _ColorPanel({required this.selected, required this.onSelect});

  final Color selected;
  final ValueChanged<Color> onSelect;

  Future<void> _openCustomPicker(BuildContext context) async {
    final result = await showGeneralDialog<Color>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'custom-color',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondary) {
        return _CustomColorPickerDialog(initial: selected);
      },
      transitionBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (result != null) onSelect(result);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 10,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: _colors.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return GestureDetector(
            onTap: () => _openCustomPicker(context),
            behavior: HitTestBehavior.opaque,
            child: const Center(
              child: Image(
                image: AssetImage('assets/icons/color-wheel.png'),
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          );
        }

        final color = _colors[index - 1];
        final isSelected = color.toARGB32() == selected.toARGB32();
        return GestureDetector(
          onTap: () => onSelect(color),
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: const Color(0xFF999999), width: 1),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

@immutable
final class _CustomColorPickerDialog extends StatefulWidget {
  const _CustomColorPickerDialog({required this.initial});

  final Color initial;

  @override
  State<_CustomColorPickerDialog> createState() =>
      _CustomColorPickerDialogState();
}

final class _CustomColorPickerDialogState extends State<_CustomColorPickerDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
  }

  void _update({double? hue, double? saturation, double? value}) {
    setState(() {
      _hsv = _hsv
          .withHue(hue ?? _hsv.hue)
          .withSaturation(saturation ?? _hsv.saturation)
          .withValue(value ?? _hsv.value);
    });
  }

  String get _hex {
    final hex = _hsv.toColor().toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    final pureHue = HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.sizeOf(context).width - 40,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2A242C),
                const Color(0xFF1A151B),
                Color.lerp(const Color(0xFF1A151B), color, 0.18)!,
              ],
            ),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 40,
                spreadRadius: -4,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.85),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.55),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'custom_color'.tr(),
                                style: TextStyle(
                                  color: AppColors.white.withValues(
                                    alpha: 0.55,
                                  ),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _hex,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SvPicker(
                      hsv: _hsv,
                      pureHue: pureHue,
                      onChanged: (saturation, value) =>
                          _update(saturation: saturation, value: value),
                    ),
                    const SizedBox(height: 16),
                    _HueBar(
                      hue: _hsv.hue,
                      onChanged: (hue) => _update(hue: hue),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.white,
                                side: BorderSide(
                                  color: AppColors.white.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text('cancel'.tr()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop(color),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.zoviOrange,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'done'.tr(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
final class _SvPicker extends StatelessWidget {
  const _SvPicker({
    required this.hsv,
    required this.pureHue,
    required this.onChanged,
  });

  final HSVColor hsv;
  final Color pureHue;
  final void Function(double saturation, double value) onChanged;

  void _handle(Offset local, Size size) {
    onChanged(
      (local.dx / size.width).clamp(0.0, 1.0),
      1 - (local.dy / size.height).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 180);
        return GestureDetector(
          onPanDown: (d) => _handle(d.localPosition, size),
          onPanUpdate: (d) => _handle(d.localPosition, size),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: pureHue),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.transparent],
                          ),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: hsv.saturation * size.width - 12,
                  top: (1 - hsv.value) * size.height - 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hsv.toColor(),
                      border: Border.all(color: AppColors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

@immutable
final class _HueBar extends StatelessWidget {
  const _HueBar({required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) =>
              onChanged((d.localPosition.dx / width * 360).clamp(0, 360)),
          onPanUpdate: (d) =>
              onChanged((d.localPosition.dx / width * 360).clamp(0, 360)),
          child: SizedBox(
            height: 28,
            width: width,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const SizedBox(
                    height: 14,
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFF0000),
                            Color(0xFFFFFF00),
                            Color(0xFF00FF00),
                            Color(0xFF00FFFF),
                            Color(0xFF0000FF),
                            Color(0xFFFF00FF),
                            Color(0xFFFF0000),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: (hue / 360) * width - 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                      border: Border.all(color: AppColors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
