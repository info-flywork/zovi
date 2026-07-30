part of '../birthday_view.dart';

mixin BirthdayViewMixin on State<BirthdayView> {
  void showErrorSnackbar(String message) {
    AppSnackbar.instance.show(context, message, isError: true);
  }

  void onDateChanged(DateTime value) {
    context.read<BirthdayBloc>().add(BirthdayDateChanged(value));
  }

  void onContinue() {
    context.read<BirthdayBloc>().add(const BirthdayContinueTapped());
  }
}
