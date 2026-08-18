part of '../onboarding_view.dart';

@immutable
final class CountryPickerSheet extends StatefulWidget {
  const CountryPickerSheet({
    required this.selectedCountry,
    super.key,
  });

  final Country selectedCountry;

  static Future<Country?> show(
    BuildContext context, {
    required Country selectedCountry,
  }) {
    return showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CountryPickerSheet(selectedCountry: selectedCountry),
    );
  }

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

final class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  List<Country> get _filteredCountries {
    return Countries.all
        .where((country) => country.matchesQuery(_query))
        .toList();
  }

  bool get _showEmptyState => _query.isNotEmpty && _filteredCountries.isEmpty;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.progressInactive,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'country_picker_title'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: AppColors.deepRoast,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'country_search_hint'.tr(),
                  hintStyle: const TextStyle(
                    color: AppColors.placeholder,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.mutedGray,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceGray,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppColors.borderSoft),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppColors.borderSoft),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(
                      color: AppColors.zoviOrange,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: _showEmptyState
                  ? _CountrySearchEmpty()
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _filteredCountries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final country = _filteredCountries[index];
                  final isSelected =
                      country.isoCode == widget.selectedCountry.isoCode;

                  return Material(
                    color: isSelected
                        ? AppColors.zoviOrange.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pop(country),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            _CountryFlag(country: country),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                country.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: AppColors.deepRoast,
                                  letterSpacing: -0.32,
                                ),
                              ),
                            ),
                            Text(
                              country.dialCode,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppColors.zoviOrange
                                    : AppColors.textSecondary,
                                letterSpacing: -0.32,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.zoviOrange,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _CountrySearchEmpty extends StatelessWidget {
  const _CountrySearchEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.zoviOrange.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.public_off_rounded,
                size: 36,
                color: AppColors.zoviOrange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'country_not_found_title'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.36,
                color: AppColors.deepRoast,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'country_not_found_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
final class _CountryFlag extends StatelessWidget {
  const _CountryFlag({required this.country});

  final Country country;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceGray,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        country.flagEmoji,
        style: const TextStyle(fontSize: 20, height: 1),
      ),
    );
  }
}
