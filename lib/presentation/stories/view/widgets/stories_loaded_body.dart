part of '../stories_view.dart';

class StoriesLoadedBody extends StatelessWidget {
  const StoriesLoadedBody({
    required this.stories,
    required this.onOpen,
    super.key,
  });

  final List<StoryPreview> stories;
  final ValueChanged<StoryPreview> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final story = stories[index];
        return ListTile(
          onTap: () => onOpen(story),
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.zoviOrange, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(story.avatarPath, fit: BoxFit.cover),
            ),
          ),
          title: Text(
            story.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('Yeni story'),
          trailing: Image.asset(
            AssetPaths.storyJulia,
            width: 48,
            height: 64,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
