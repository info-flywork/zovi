part of '../birthday_view.dart';

class BirthdayDatePicker extends StatefulWidget {
  const BirthdayDatePicker({
    required this.birthDate,
    required this.onDateChanged,
    super.key,
  });

  final DateTime birthDate;
  final ValueChanged<DateTime> onDateChanged;

  static const double itemExtent = 40;
  static const int visibleItemCount = 5;
  static const double height = itemExtent * visibleItemCount;

  @override
  State<BirthdayDatePicker> createState() => _BirthdayDatePickerState();
}

class _BirthdayDatePickerState extends State<BirthdayDatePicker> {
  late int _day;
  late int _month;
  late int _year;

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  int get _maxYear => DateTime.now().year;

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  List<int> get _years =>
      List.generate(_maxYear - 1899, (index) => 1900 + index);

  @override
  void initState() {
    super.initState();
    _applyDate(widget.birthDate);
    _initControllers();
  }

  @override
  void didUpdateWidget(BirthdayDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.birthDate != widget.birthDate) {
      _applyDate(widget.birthDate);
      _syncControllers();
    }
  }

  void _applyDate(DateTime date) {
    _year = date.year.clamp(1900, _maxYear);
    _month = date.month;
    _day = date.day.clamp(1, DateTime(_year, _month + 1, 0).day);
  }

  void _initControllers() {
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _yearController = FixedExtentScrollController(
      initialItem: _years.indexOf(_year),
    );
  }

  void _syncControllers() {
    if (_dayController.selectedItem != _day - 1) {
      _dayController.jumpToItem(_day - 1);
    }
    if (_monthController.selectedItem != _month - 1) {
      _monthController.jumpToItem(_month - 1);
    }
    final yearIndex = _years.indexOf(_year);
    if (_yearController.selectedItem != yearIndex) {
      _yearController.jumpToItem(yearIndex);
    }
  }

  void _emitDate() {
    final daysInMonth = _daysInMonth;
    if (_day > daysInMonth) {
      _day = daysInMonth;
      _dayController.jumpToItem(_day - 1);
    }

    widget.onDateChanged(DateTime(_year, _month, _day));
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: BirthdayDatePicker.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: BirthdayDatePicker.itemExtent,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 56,
                height: BirthdayDatePicker.height,
                child: _PickerColumn(
                  key: ValueKey('day-$_month-$_year'),
                  controller: _dayController,
                  itemCount: _daysInMonth,
                  selectedIndex: _day - 1,
                  labelBuilder: (index) => '${index + 1}',
                  onSelectedItemChanged: (index) {
                    setState(() => _day = index + 1);
                    _emitDate();
                  },
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 140,
                height: BirthdayDatePicker.height,
                child: _PickerColumn(
                  controller: _monthController,
                  itemCount: 12,
                  selectedIndex: _month - 1,
                  labelBuilder: (index) => _monthKeys[index].tr(),
                  onSelectedItemChanged: (index) {
                    setState(() => _month = index + 1);
                    _emitDate();
                  },
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 70,
                height: BirthdayDatePicker.height,
                child: _PickerColumn(
                  controller: _yearController,
                  itemCount: _years.length,
                  selectedIndex: _years.indexOf(_year),
                  labelBuilder: (index) => '${_years[index]}',
                  onSelectedItemChanged: (index) {
                    setState(() => _year = _years[index]);
                    _emitDate();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerColumn extends StatelessWidget {
  const _PickerColumn({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.selectedIndex,
    required this.labelBuilder,
    required this.onSelectedItemChanged,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedIndex;
  final String Function(int index) labelBuilder;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: BirthdayDatePicker.itemExtent,
        diameterRatio: 1.5,
        squeeze: 1.1,
        useMagnifier: true,
        magnification: 1.05,
        onSelectedItemChanged: onSelectedItemChanged,
        selectionOverlay: const SizedBox.shrink(),
        children: List.generate(
          itemCount,
          (index) {
            final distance = (selectedIndex - index).abs();
            final color = distance == 0
                ? AppColors.deepRoast
                : AppColors.deepRoast.withValues(
                    alpha: distance == 1 ? 0.5 : 0.25,
                  );
            final fontSize = switch (distance) {
              0 => 24.0,
              1 => 20.0,
              _ => 16.0,
            };

            return Center(
              child: Text(
                labelBuilder(index),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: 0,
                  color: color,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
