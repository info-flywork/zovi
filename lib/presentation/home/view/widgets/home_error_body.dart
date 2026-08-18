part of '../home_view.dart';

@immutable
final class HomeErrorBody extends StatelessWidget {
  const HomeErrorBody({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}
