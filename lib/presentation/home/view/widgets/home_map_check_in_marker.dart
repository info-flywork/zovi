part of '../home_view.dart';

class HomeMapCheckInMarker extends StatelessWidget {
  const HomeMapCheckInMarker({
    required this.avatarPath,
    required this.photoPaths,
    required this.stampImagePath,
    this.photoIndexListenable,
    super.key,
  });

  HomeMapCheckInMarker.fromActive(ActiveMapCheckIn checkIn, {super.key})
    : avatarPath = checkIn.avatarPath,
      photoPaths = checkIn.photoPaths,
      stampImagePath = checkIn.stampImagePath,
      photoIndexListenable =
          getIt<UserRepository>().checkInPhotoIndexListenable;

  HomeMapCheckInMarker.fromFriend(MapFriend friend, {super.key})
    : avatarPath = friend.avatarPath,
      photoPaths = friend.checkIn?.photoPaths ?? const [],
      stampImagePath = friend.checkIn?.stampImagePath ?? AssetPaths.stamp1,
      photoIndexListenable = getIt<UserRepository>()
          .friendCheckInPhotoIndexListenable(friend.name);

  final String avatarPath;
  final List<String> photoPaths;
  final String stampImagePath;
  final ValueListenable<int>? photoIndexListenable;

  /// Friends marker ile aynı avatar boyutu.
  static const avatarSize = 56.0;
  static const photoSize = 48.0;
  static const border = 3.0;
  static const stampSize = 36.0;

  /// Foto solda, avatar sağda örtüşür.
  static const photoLeft = 0.0;
  static const avatarLeft = 30.0;
  static const stampOffsetX = 34.0;
  static const stampOffsetY = 28.0;

  static double get width => avatarLeft + avatarSize + 8;
  static double get height => avatarSize + 12;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: photoLeft + 7,
            top: (avatarSize - photoSize) / 2,
            child: CheckInCyclingPhoto(
              paths: photoPaths,
              size: photoSize,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.zoviOrange, width: border),
              indexListenable: photoIndexListenable,
            ),
          ),
          Positioned(
            left: avatarLeft,
            top: 0,
            child: _CircleImage(
              path: avatarPath,
              isFile: false,
              size: avatarSize,
            ),
          ),
          Positioned(
            left: avatarLeft + stampOffsetX,
            top: stampOffsetY,
            child: Image.asset(
              stampImagePath,
              width: stampSize,
              height: stampSize,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleImage extends StatelessWidget {
  const _CircleImage({
    required this.path,
    required this.isFile,
    required this.size,
  });

  final String path;
  final bool isFile;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.zoviOrange,
          width: HomeMapCheckInMarker.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: isFile
            ? Image.file(File(path), fit: BoxFit.cover)
            : Image.asset(path, fit: BoxFit.cover),
      ),
    );
  }
}

/// Birden fazla check-in fotoğrafını 5 sn’de bir crossfade ile döndürür.
///
/// [indexListenable] verilirse tüm instance’lar aynı indeksi paylaşır
/// (marker + sheet senkron).
class CheckInCyclingPhoto extends StatefulWidget {
  const CheckInCyclingPhoto({
    required this.paths,
    required this.size,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.border,
    this.padding,
    this.gradient,
    this.interval = const Duration(seconds: 5),
    this.indexListenable,
    super.key,
  });

  final List<String> paths;
  final double size;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final Duration interval;
  final ValueListenable<int>? indexListenable;

  @override
  State<CheckInCyclingPhoto> createState() => _CheckInCyclingPhotoState();
}

class _CheckInCyclingPhotoState extends State<CheckInCyclingPhoto> {
  var _localIndex = 0;
  Timer? _timer;

  List<String> get _paths =>
      widget.paths.isEmpty ? const [AssetPaths.mapSecondAvatar] : widget.paths;

  bool get _usesSharedIndex => widget.indexListenable != null;

  @override
  void initState() {
    super.initState();
    widget.indexListenable?.addListener(_onSharedIndex);
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant CheckInCyclingPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.indexListenable != widget.indexListenable) {
      oldWidget.indexListenable?.removeListener(_onSharedIndex);
      widget.indexListenable?.addListener(_onSharedIndex);
    }
    if (!listEquals(oldWidget.paths, widget.paths) ||
        oldWidget.indexListenable != widget.indexListenable ||
        oldWidget.interval != widget.interval) {
      if (!_usesSharedIndex) _localIndex = 0;
      _syncTimer();
    }
  }

  void _onSharedIndex() {
    if (mounted) setState(() {});
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (_usesSharedIndex || _paths.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() => _localIndex = (_localIndex + 1) % _paths.length);
    });
  }

  @override
  void dispose() {
    widget.indexListenable?.removeListener(_onSharedIndex);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shared = widget.indexListenable?.value ?? 0;
    final index = (_usesSharedIndex ? shared : _localIndex) % _paths.length;
    final path = _paths[index];
    final outerRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final pad = (widget.padding?.resolve(Directionality.of(context)).left ?? 0);
    final innerRadius = widget.shape == BoxShape.circle
        ? null
        : BorderRadius.circular(
            (outerRadius.topLeft.x - pad).clamp(0.0, 999.0),
          );

    final image = ActiveMapCheckIn.isFilePath(path)
        ? Image.file(File(path), fit: BoxFit.cover)
        : Image.asset(path, fit: BoxFit.cover);

    final clipped = widget.shape == BoxShape.circle
        ? ClipOval(child: image)
        : ClipRRect(borderRadius: innerRadius!, child: image);

    return Container(
      width: widget.size,
      height: widget.size,
      padding: widget.padding,
      decoration: BoxDecoration(
        shape: widget.shape,
        borderRadius: widget.shape == BoxShape.circle ? null : outerRadius,
        border: widget.border,
        gradient: widget.gradient,
        boxShadow: widget.shape == BoxShape.circle
            ? const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: SizedBox.expand(key: ValueKey(path), child: clipped),
      ),
    );
  }
}
