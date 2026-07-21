part of '../chat_view.dart';

class ChatLoadedBody extends StatelessWidget {
  const ChatLoadedBody({super.key});

  @override
  Widget build(BuildContext context) {
    final chats = [
      ('Lyra', AssetPaths.avatarLyra, 'Hey, coffee later?'),
      ('Jessica', AssetPaths.avatarJessica, 'Check this place out'),
      ('Sona', AssetPaths.avatarSona, '🔥 streak continuing'),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: chats.length,
      separatorBuilder: (_, _) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final item = chats[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 28,
            backgroundImage: AssetImage(item.$2),
          ),
          title: Text(
            item.$1,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            item.$3,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        );
      },
    );
  }
}
