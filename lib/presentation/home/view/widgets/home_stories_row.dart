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
          return GestureDetector(
            onTap: () => onStoryTap(story),
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ProfileAvatar(
                        path: story.avatarPath,
                        size: 68,
                        showGradientRing: story.hasStory,
                      ),
                      if (story.isYou)
                        const Positioned(
                          right: 0,
                          bottom: -3,
                          child: AppIcon(
                            AssetPaths.iconAddCircleBlack,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
          );
        },
      ),
    );
  }
}
