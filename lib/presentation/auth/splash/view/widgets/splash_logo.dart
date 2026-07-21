part of '../splash_view.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(43),
          child: Image.asset(
            AssetPaths.logoApp,
            width: 167,
            height: 167,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        Text(StringConstants.appName, style: AppTheme.brandWordmark),
        const SizedBox(height: 8),
        Text(
          StringConstants.tagline,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}
