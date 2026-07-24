class CameraComposeRouteArgs {
  const CameraComposeRouteArgs({required this.imagePath});

  final String imagePath;

  bool get isAsset => imagePath.startsWith('assets/');
}
