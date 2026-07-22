import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_button.dart';
import 'package:zovi/core/widgets/app_icon.dart';

enum AppLanguage {
  english('en', AssetPaths.flagEnglish, 'language_english'),
  german('de', AssetPaths.flagGerman, 'language_german'),
  italian('it', AssetPaths.flagItalian, 'language_italian'),
  french('fr', AssetPaths.flagFrench, 'language_french'),
  turkish('tr', AssetPaths.flagTurkish, 'language_turkish'),
  japanese('ja', AssetPaths.flagJapanese, 'language_japanese'),
  spanish('es', AssetPaths.flagSpanish, 'language_spanish'),
  russian('ru', AssetPaths.flagRussian, 'language_russian'),
  korean('ko', AssetPaths.flagKorean, 'language_korean'),
  hindi('hi', AssetPaths.flagHindi, 'language_hindi'),
  portuguese('pt', AssetPaths.flagPortuguese, 'language_portuguese'),
  chinese('zh', AssetPaths.flagChinese, 'language_chinese');

  const AppLanguage(this.code, this.flagAsset, this.labelKey);

  final String code;
  final String flagAsset;
  final String labelKey;

  String get label => labelKey.tr();

  /// Uygulama çevirisi şu an yalnızca en/tr.
  Locale get appLocale =>
      code == 'tr' ? const Locale('tr') : const Locale('en');

  static AppLanguage fromLocale(Locale locale) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == locale.languageCode,
      orElse: () => AppLanguage.english,
    );
  }
}

Future<AppLanguage?> showLanguageSheet(
  BuildContext context, {
  required AppLanguage initial,
}) {
  return showModalBottomSheet<AppLanguage>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => LanguageSheet(initial: initial),
  );
}

class LanguageSheet extends StatefulWidget {
  const LanguageSheet({required this.initial, super.key});

  final AppLanguage initial;

  @override
  State<LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<LanguageSheet> {
  late AppLanguage _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.progressInactive,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            behavior: HitTestBehavior.opaque,
                            child: const AppIcon(
                              AssetPaths.iconBack,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'settings_language'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1,
                              letterSpacing: -0.32,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: AppLanguage.values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final language = AppLanguage.values[index];
                    final selected = language == _selected;
                    return _LanguageRow(
                      language: language,
                      selected: selected,
                      onTap: () => setState(() => _selected = language),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: AppButton(
                    label: 'save_changes'.tr(),
                    onPressed: () => Navigator.of(context).pop(_selected),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ClipOval(
              child: SvgPicture.asset(
                language.flagAsset,
                width: 37,
                height: 37,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                language.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: -0.16,
                  color: selected ? AppColors.zoviOrange : AppColors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
