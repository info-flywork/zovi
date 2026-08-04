import 'package:flutter/material.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/widgets/app_icon.dart';

/// Height + fade insert/remove without [SizeTransition]'s ClipRect, so
/// horizontal swipe overflow stays visible.
class ChatListItemTransition extends StatelessWidget {
  const ChatListItemTransition({
    required this.animation,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = animation.value.clamp(0.0, 1.0);
          return Align(
            alignment: Alignment.topCenter,
            heightFactor: t <= 0 ? 0.0001 : t,
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}

/// Sola kaydırınca kart kayar, sağda yuvarlatılmış çöp alanı açılır ve açık kalır.
class ChatSwipeDeleteTile extends StatefulWidget {
  const ChatSwipeDeleteTile({
    required this.child,
    required this.isOpen,
    required this.onOpenChanged,
    required this.onDeleteTap,
    super.key,
  });

  final Widget child;
  final bool isOpen;
  final ValueChanged<bool> onOpenChanged;
  final VoidCallback onDeleteTap;

  static const actionWidth = 72.0;

  @override
  State<ChatSwipeDeleteTile> createState() => _ChatSwipeDeleteTileState();
}

class _ChatSwipeDeleteTileState extends State<ChatSwipeDeleteTile> {
  var _offset = 0.0;

  @override
  void initState() {
    super.initState();
    _offset = widget.isOpen ? ChatSwipeDeleteTile.actionWidth : 0;
  }

  @override
  void didUpdateWidget(covariant ChatSwipeDeleteTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen == oldWidget.isOpen) return;
    setState(() {
      _offset = widget.isOpen ? ChatSwipeDeleteTile.actionWidth : 0;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset = (_offset - details.delta.dx).clamp(
        0.0,
        ChatSwipeDeleteTile.actionWidth,
      );
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final shouldOpen = _offset > ChatSwipeDeleteTile.actionWidth * 0.4 ||
        (details.primaryVelocity ?? 0) < -400;
    widget.onOpenChanged(shouldOpen);
    setState(() {
      _offset = shouldOpen ? ChatSwipeDeleteTile.actionWidth : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: widget.onDeleteTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: ChatSwipeDeleteTile.actionWidth,
              decoration: BoxDecoration(
                color: const Color(0xFFEC1C24),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Opacity(
                opacity: (_offset / ChatSwipeDeleteTile.actionWidth)
                    .clamp(0.0, 1.0),
                child: const AppIcon(
                  AssetPaths.iconTrash,
                  size: 26,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: Transform.translate(
            offset: Offset(-_offset, 0),
            child: ColoredBox(
              color: AppColors.white,
              child: SizedBox(
                width: double.infinity,
                child: widget.child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
