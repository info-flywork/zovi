part of '../home_view.dart';

class HomeStoriesRow extends StatelessWidget {
  const HomeStoriesRow({
    required this.stories,
    required this.onStoryTap,
    super.key,
  });

  final List<StoryPreview> stories;
  final ValueChanged<StoryPreview> onStoryTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 105,
      child: ListView.separated(
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final story = stories[index];
          final isViewed = story.isViewed && story.hasStory;
          return GestureDetector(
            onTap: () => onStoryTap(story),
            child: SizedBox(
              width: 68,
              child: Opacity(
                opacity: isViewed ? 0.45 : 1,
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ProfileAvatar(
                          path: story.avatarPath,
                          size: 68,
                          showGradientRing: story.hasStory && !story.isViewed,
                          showSeenRing: story.hasStory && story.isViewed,
                        ),
                        if (story.isYou)
                          Positioned(
                            right: 0,
                            bottom: -3,
                            child: GestureDetector(
                              onTap: () => context.push(RoutePaths.camera.path),
                              child: AppIcon(
                                AssetPaths.iconAddCircleBlack,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      story.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
