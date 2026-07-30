part of '../create_profile_view.dart';

mixin CreateProfileViewMixin on State<CreateProfileView> {
  void showErrorSnackbar(String message) {
    AppSnackbar.instance.show(context, message, isError: true);
  }

  void onFullNameChanged(String value) {
    context.read<CreateProfileBloc>().add(CreateProfileFullNameChanged(value));
  }

  void onUsernameChanged(String value) {
    context.read<CreateProfileBloc>().add(CreateProfileUsernameChanged(value));
  }

  void onSuggestionSelected(String value) {
    context
        .read<CreateProfileBloc>()
        .add(CreateProfileUsernameSuggestionSelected(value));
  }

  void onContinue() {
    context.read<CreateProfileBloc>().add(const CreateProfileContinueTapped());
  }
}
