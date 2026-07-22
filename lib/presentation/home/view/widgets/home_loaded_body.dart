part of '../home_view.dart';

class HomeLoadedBody extends StatelessWidget {
  const HomeLoadedBody({
    required this.stories,
    required this.mapFriends,
    required this.hasUnreadMessages,
    required this.onStoryTap,
    required this.onAddTap,
    super.key,
  });

  final List<StoryPreview> stories;
  final List<MapFriend> mapFriends;
  final bool hasUnreadMessages;
  final ValueChanged<StoryPreview> onStoryTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          HomeHeaderSection(hasUnreadMessages: hasUnreadMessages),
          HomeStoriesRow(stories: stories, onStoryTap: onStoryTap),
          Expanded(
            child: HomeMapSection(
              mapFriends: mapFriends,
              onAddTap: onAddTap,
            ),
          ),
        ],
      ),
    );
  }
}
