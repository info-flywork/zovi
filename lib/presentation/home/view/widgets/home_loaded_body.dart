part of '../home_view.dart';

class HomeLoadedBody extends StatelessWidget {
  const HomeLoadedBody({
    required this.stories,
    required this.mapFriends,
    required this.city,
    required this.onStoryTap,
    required this.onAddTap,
    super.key,
  });

  final List<StoryPreview> stories;
  final List<MapFriend> mapFriends;
  final String city;
  final ValueChanged<StoryPreview> onStoryTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const HomeHeaderSection(),
          HomeStoriesRow(stories: stories, onStoryTap: onStoryTap),
          Expanded(
            child: HomeMapSection(
              city: city,
              mapFriends: mapFriends,
              onAddTap: onAddTap,
            ),
          ),
        ],
      ),
    );
  }
}
