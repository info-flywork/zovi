import 'package:equatable/equatable.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';

// Domain keeps map marker positions as normalized x/y (-1..1).

class ProfileLink extends Equatable {
  const ProfileLink({
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  String get displayUrl =>
      url.replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'/+$'), '');

  @override
  List<Object?> get props => [title, url];
}

class UserProfile extends Equatable {
  const UserProfile({
    required this.name,
    required this.username,
    required this.avatarPath,
    required this.location,
    required this.bio,
    required this.checkIns,
    required this.followers,
    required this.friends,
    this.links = const [],
  });

  final String name;
  final String username;
  final String avatarPath;
  final String location;
  final String bio;
  final int checkIns;
  final int followers;
  final int friends;
  final List<ProfileLink> links;

  String get usernameHandle =>
      username.startsWith('@') ? username.substring(1) : username;

  UserProfile copyWith({
    String? name,
    String? username,
    String? avatarPath,
    String? location,
    String? bio,
    int? checkIns,
    int? followers,
    int? friends,
    List<ProfileLink>? links,
  }) {
    return UserProfile(
      name: name ?? this.name,
      username: username ?? this.username,
      avatarPath: avatarPath ?? this.avatarPath,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      checkIns: checkIns ?? this.checkIns,
      followers: followers ?? this.followers,
      friends: friends ?? this.friends,
      links: links ?? this.links,
    );
  }

  @override
  List<Object?> get props => [
    name,
    username,
    avatarPath,
    location,
    bio,
    checkIns,
    followers,
    friends,
    links,
  ];
}

class StoryPreview extends Equatable {
  const StoryPreview({
    required this.name,
    required this.avatarPath,
    this.isYou = false,
    this.hasStory = true,
  });

  final String name;
  final String avatarPath;
  final bool isYou;
  final bool hasStory;

  @override
  List<Object?> get props => [name, avatarPath, isYou, hasStory];
}

class StoryMediaItem extends Equatable {
  const StoryMediaItem({
    required this.imagePath,
    required this.label,
    required this.avatarPath,
    this.caption =
        'Lorem Ipsum is simply dummy text of the printing and typesetting industry...',
    this.isReel = false,
    this.isVerified = true,
  });

  final String imagePath;
  final String label;
  final String avatarPath;
  final String caption;
  final bool isReel;
  final bool isVerified;

  @override
  List<Object?> get props => [
    imagePath,
    label,
    avatarPath,
    caption,
    isReel,
    isVerified,
  ];
}

class MapFriend extends Equatable {
  const MapFriend({
    required this.name,
    required this.avatarPath,
    required this.streak,
    required this.x,
    required this.y,
    this.isFriend = true,
    this.distanceMeters,
    this.locationLabel,
    this.etaMinutes,
  });

  final String name;
  final String avatarPath;
  final int streak;
  final double x;
  final double y;
  final bool isFriend;
  final int? distanceMeters;
  final String? locationLabel;
  final int? etaMinutes;

  @override
  List<Object?> get props => [
        name,
        avatarPath,
        streak,
        x,
        y,
        isFriend,
        distanceMeters,
        locationLabel,
        etaMinutes,
      ];
}

class MapVenue extends Equatable {
  const MapVenue({
    required this.name,
    required this.peopleCount,
    required this.x,
    required this.y,
  });

  final String name;
  final int peopleCount;
  final double x;
  final double y;

  @override
  List<Object?> get props => [name, peopleCount, x, y];
}

class CheckInItem extends Equatable {
  const CheckInItem({
    required this.placeName,
    required this.when,
    required this.imagePath,
  });

  final String placeName;
  final String when;
  final String imagePath;

  @override
  List<Object?> get props => [placeName, when, imagePath];
}

class PulseItem extends Equatable {
  const PulseItem({
    required this.imagePath,
    required this.time,
    required this.placeName,
    required this.subtitle,
    required this.friendAvatars,
    required this.friendsLabel,
  });

  final String imagePath;
  final String time;
  final String placeName;
  final String subtitle;
  final List<String> friendAvatars;
  final String friendsLabel;

  @override
  List<Object?> get props => [
    imagePath,
    time,
    placeName,
    subtitle,
    friendAvatars,
    friendsLabel,
  ];
}

class StampItem extends Equatable {
  const StampItem({required this.imagePath, required this.title});

  final String imagePath;
  final String title;

  @override
  List<Object?> get props => [imagePath, title];
}

class PlanItem extends Equatable {
  const PlanItem({
    required this.time,
    required this.placeName,
    required this.subtitle,
    required this.friendAvatars,
    required this.friendsLabel,
  });

  final String time;
  final String placeName;
  final String subtitle;
  final List<String> friendAvatars;
  final String friendsLabel;

  @override
  List<Object?> get props => [
    time,
    placeName,
    subtitle,
    friendAvatars,
    friendsLabel,
  ];
}

class UserRepository {
  UserProfile _currentUser = const UserProfile(
    name: 'Jhon Doe',
    username: '@jhondoe4512',
    avatarPath: AssetPaths.pulseJhon,
    location: 'Birmingham, England',
    bio: 'I like exploring',
    checkIns: 5,
    followers: 98,
    friends: 12,
    links: [
      ProfileLink(
        title: 'My Website!',
        url: 'https://jhondoe4512.com',
      ),
    ],
  );

  Future<UserProfile> getCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _currentUser;
  }

  Future<void> updateCurrentUser(UserProfile user) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _currentUser = user;
  }

  Future<List<StoryPreview>> getStories() async {
    return const [
      StoryPreview(
        name: 'Your story',
        avatarPath: AssetPaths.avatarYou,
        isYou: true,
        hasStory: false,
      ),
      StoryPreview(name: 'Lyra', avatarPath: AssetPaths.avatarLyra),
      StoryPreview(name: 'Jessica', avatarPath: AssetPaths.avatarJessica),
      StoryPreview(name: 'Sona', avatarPath: AssetPaths.avatarSona),
      StoryPreview(name: 'Nova', avatarPath: AssetPaths.avatarNova),
    ];
  }

  Future<List<StoryMediaItem>> getStoryFeed() async {
    return const [
      StoryMediaItem(
        imagePath: AssetPaths.avatarLyra,
        label: 'Lyra Jhonson',
        avatarPath: AssetPaths.avatarLyra,
        isReel: true,
      ),
      StoryMediaItem(
        imagePath: AssetPaths.avatarJessica,
        label: 'Jessica Blues',
        avatarPath: AssetPaths.avatarJessica,
        isReel: true,
      ),
      StoryMediaItem(
        imagePath: AssetPaths.avatarYou,
        label: 'You',
        avatarPath: AssetPaths.avatarYou,
        isReel: true,
        isVerified: false,
      ),
      StoryMediaItem(
        imagePath: AssetPaths.avatarSona,
        label: 'Sona Black',
        avatarPath: AssetPaths.avatarSona,
        isReel: true,
      ),
      StoryMediaItem(
        imagePath: AssetPaths.checkinPlace,
        label: 'Desert Trip',
        avatarPath: AssetPaths.avatarJulia,
      ),
      StoryMediaItem(
        imagePath: AssetPaths.mapFirst,
        label: 'Mountains',
        avatarPath: AssetPaths.avatarNova,
      ),
      StoryMediaItem(
        imagePath: AssetPaths.pulseJhon,
        label: 'Drive',
        avatarPath: AssetPaths.avatarYou,
      ),
      StoryMediaItem(
        imagePath: AssetPaths.pulseJessica,
        label: 'Roadtrip',
        avatarPath: AssetPaths.avatarJessica,
      ),
      StoryMediaItem(
        imagePath: AssetPaths.pulse1,
        label: 'Speed',
        avatarPath: AssetPaths.avatarSona,
      ),
      StoryMediaItem(
        imagePath: AssetPaths.mapSecond,
        label: 'City Walk',
        avatarPath: AssetPaths.avatarLyra,
      ),
      StoryMediaItem(
        imagePath: AssetPaths.storyJulia,
        label: 'Julia Ivanova',
        avatarPath: AssetPaths.avatarJulia,
        isReel: true,
      ),
      StoryMediaItem(
        imagePath: AssetPaths.pulse2,
        label: 'Cat',
        avatarPath: AssetPaths.avatarNova,
      ),
      StoryMediaItem(
        imagePath: AssetPaths.pulse3,
        label: 'Ginger',
        avatarPath: AssetPaths.avatarJulia,
      ),
      StoryMediaItem(
        imagePath: AssetPaths.blueLocation,
        label: 'Cruise',
        avatarPath: AssetPaths.avatarYou,
      ),
      StoryMediaItem(
        imagePath: AssetPaths.avatarNova,
        label: 'Nova',
        avatarPath: AssetPaths.avatarNova,
      ),
    ];
  }

  Future<List<MapFriend>> getMapFriends() async {
    return const [
      MapFriend(
        name: 'Lyra',
        avatarPath: AssetPaths.avatarLyra,
        streak: 12,
        x: -0.45,
        y: -0.15,
        locationLabel: 'Silver Lake, Los Angeles',
        etaMinutes: 15,
        distanceMeters: 120,
      ),
      MapFriend(
        name: 'Sona',
        avatarPath: AssetPaths.avatarSona,
        streak: 5,
        x: 0.45,
        y: -0.05,
        locationLabel: 'Echo Park, Los Angeles',
        etaMinutes: 10,
        distanceMeters: 50,
      ),
    ];
  }

  Future<List<MapFriend>> getMapNearbyAnons() async {
    return const [
      MapFriend(
        name: 'Anonim',
        avatarPath: AssetPaths.iconPinkPerson,
        streak: 0,
        x: -0.28,
        y: 0.02,
        isFriend: false,
        distanceMeters: 300,
      ),
      MapFriend(
        name: 'Anonim',
        avatarPath: AssetPaths.iconPinkPerson,
        streak: 0,
        x: 0.28,
        y: -0.02,
        isFriend: false,
        distanceMeters: 180,
      ),
    ];
  }

  Future<List<MapVenue>> getMapVenues() async {
    return const [
      MapVenue(
        name: 'Beverly Hills',
        peopleCount: 12,
        x: -0.22,
        y: -0.12,
      ),
      MapVenue(
        name: 'Santa Monica',
        peopleCount: 8,
        x: 0.32,
        y: 0.08,
      ),
    ];
  }

  Future<bool> hasUnreadMessages() async {
    return true;
  }

  Future<List<CheckInItem>> getCheckIns() async {
    return const [
      CheckInItem(
        placeName: 'Babylon İstanbul',
        when: 'Today · 11:14pm',
        imagePath: AssetPaths.blueLocation,
      ),
      CheckInItem(
        placeName: 'Blue Bottle Coffee',
        when: 'Yesterday · 10:24 am',
        imagePath: AssetPaths.blueLocation,
      ),
      CheckInItem(
        placeName: 'Green Park',
        when: '2 days ago · 04:45 pm',
        imagePath: AssetPaths.blueLocation,
      ),
    ];
  }

  Future<List<PulseItem>> getPulses() async {
    const friends = [
      AssetPaths.avatarLyra,
      AssetPaths.avatarJessica,
      AssetPaths.avatarSona,
    ];
    return const [
      PulseItem(
        imagePath: AssetPaths.pulse1,
        time: '08:00 PM',
        placeName: 'Babylon İstanbul',
        subtitle: 'Konser · Beyoğlu',
        friendAvatars: friends,
        friendsLabel: '5+ friends\nare joining',
      ),
      PulseItem(
        imagePath: AssetPaths.pulse2,
        time: '09:30 PM',
        placeName: 'Blue Bottle Coffee',
        subtitle: 'Cafe · Kadıköy',
        friendAvatars: friends,
        friendsLabel: '3+ friends\nare joining',
      ),
      PulseItem(
        imagePath: AssetPaths.pulse3,
        time: '11:00 AM',
        placeName: 'Green Park',
        subtitle: 'Park · Beşiktaş',
        friendAvatars: friends,
        friendsLabel: '8+ friends are joining',
      ),
    ];
  }

  Future<List<StampItem>> getStamps() async {
    return const [
      StampItem(imagePath: AssetPaths.stamp1, title: 'After Hours'),
      StampItem(imagePath: AssetPaths.stamp2, title: 'VIP Pass'),
      StampItem(imagePath: AssetPaths.stamp3, title: 'DJ Booth'),
      StampItem(imagePath: AssetPaths.stamp4, title: 'Surf Mode'),
      StampItem(imagePath: AssetPaths.stamp5, title: 'Barista'),
      StampItem(imagePath: AssetPaths.stamp6, title: 'Brunch Club'),
      StampItem(imagePath: AssetPaths.stamp7, title: 'Globetrotter'),
      StampItem(imagePath: AssetPaths.stamp8, title: 'Need Coffee'),
      StampItem(imagePath: AssetPaths.stamp9, title: 'Power Duo'),
      StampItem(imagePath: AssetPaths.stamp10, title: 'On The Decks'),
      StampItem(imagePath: AssetPaths.stamp11, title: 'Soulmates'),
      StampItem(imagePath: AssetPaths.stamp12, title: 'Day & Night'),
      StampItem(imagePath: AssetPaths.stamp13, title: 'Music Fest'),
      StampItem(imagePath: AssetPaths.stamp14, title: 'Spark Pals'),
      StampItem(imagePath: AssetPaths.stamp15, title: 'Foodies'),
      StampItem(imagePath: AssetPaths.stamp16, title: 'Founder'),
      StampItem(imagePath: AssetPaths.stamp17, title: 'Peekaboo'),
    ];
  }

  Future<List<PlanItem>> getTodayPlans() async {
    const friends = [
      AssetPaths.avatarLyra,
      AssetPaths.avatarJessica,
      AssetPaths.avatarSona,
    ];
    return const [
      PlanItem(
        time: '08:00 PM',
        placeName: 'Babylon İstanbul',
        subtitle: 'Konser · Beyoğlu',
        friendAvatars: friends,
        friendsLabel: '5+ friends\nare joining',
      ),
      PlanItem(
        time: '10:00 PM',
        placeName: 'Babylon İstanbul',
        subtitle: 'Konser · Beyoğlu',
        friendAvatars: friends,
        friendsLabel: '5+ friends\nare joining',
      ),
    ];
  }
}
