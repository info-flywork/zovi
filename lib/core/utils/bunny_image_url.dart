/// Bunny CDN Optimizer query params — resizes/re-compresses on delivery.
/// Ignored (returns the url unchanged) for non-Bunny hosts or zones without
/// the optimizer enabled.
String bunnySizedUrl(String url, int width, {int quality = 75}) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.host.contains('b-cdn.net')) return url;
  if (uri.queryParameters.containsKey('width')) return url;
  return uri.replace(
    queryParameters: {
      ...uri.queryParameters,
      'width': '$width',
      'quality': '$quality',
    },
  ).toString();
}
