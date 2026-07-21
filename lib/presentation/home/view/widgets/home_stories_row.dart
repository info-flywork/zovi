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
      height: 110,
      child: ListView.separated(
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
                      Container(
                        width: 68,
                        height: 68,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: story.hasStory
                              ? Border.all(
                                  color: AppColors.zoviOrange,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            story.avatarPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (story.isYou)
                        const Positioned(
                          right: -2,
                          bottom: -2,
                          child: AppIcon(AssetPaths.iconAddCircle, size: 24),
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
