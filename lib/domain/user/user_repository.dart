import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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

/// Başka kullanıcının profil ekranı için genişletilmiş profil.
class PublicUserProfile extends Equatable {
  const PublicUserProfile({
    required this.name,
    required this.username,
    required this.avatarPath,
    required this.location,
    required this.bio,
    required this.checkIns,
    required this.followers,
    required this.friends,
    this.isVerified = false,
    this.streak = 0,
    this.explorerTitle = '',
    this.mapPlaceName = '',
    this.mapDistanceKm = '',
    this.mutualFriendsCount = 0,
    this.mutualFriendAvatars = const [],
    this.isFollowing = false,
  });

  final String name;
  final String username;
  final String avatarPath;
  final String location;
  final String bio;
  final int checkIns;
  final int followers;
  final int friends;
  final bool isVerified;
  final int streak;
  final String explorerTitle;
  final String mapPlaceName;
  final String mapDistanceKm;
  final int mutualFriendsCount;
  final List<String> mutualFriendAvatars;
  final bool isFollowing;

  String get usernameHandle =>
      username.startsWith('@') ? username.substring(1) : username;

  String get usernameWithAt =>
      username.startsWith('@') ? username : '@$username';

  PublicUserProfile copyWith({bool? isFollowing}) {
    return PublicUserProfile(
      name: name,
      username: username,
      avatarPath: avatarPath,
      location: location,
      bio: bio,
      checkIns: checkIns,
      followers: followers,
      friends: friends,
      isVerified: isVerified,
      streak: streak,
      explorerTitle: explorerTitle,
      mapPlaceName: mapPlaceName,
      mapDistanceKm: mapDistanceKm,
      mutualFriendsCount: mutualFriendsCount,
      mutualFriendAvatars: mutualFriendAvatars,
      isFollowing: isFollowing ?? this.isFollowing,
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
        isVerified,
        streak,
        explorerTitle,
        mapPlaceName,
        mapDistanceKm,
        mutualFriendsCount,
        mutualFriendAvatars,
        isFollowing,
      ];
}

class StoryPreview extends Equatable {
  const StoryPreview({
    required this.name,
    required this.avatarPath,
    this.isYou = false,
    this.hasStory = true,
    this.isViewed = false,
  });

  final String name;
  final String avatarPath;
  final bool isYou;
  final bool hasStory;
  final bool isViewed;

  StoryPreview copyWith({
    String? name,
    String? avatarPath,
    bool? isYou,
    bool? hasStory,
    bool? isViewed,
  }) {
    return StoryPreview(
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      isYou: isYou ?? this.isYou,
      hasStory: hasStory ?? this.hasStory,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  @override
  List<Object?> get props => [name, avatarPath, isYou, hasStory, isViewed];
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
    this.checkIn,
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
  final FriendMapCheckIn? checkIn;

  bool get hasCheckIn => checkIn != null;

  MapFriend copyWith({
    String? name,
    String? avatarPath,
    int? streak,
    double? x,
    double? y,
    bool? isFriend,
    int? distanceMeters,
    String? locationLabel,
    int? etaMinutes,
    FriendMapCheckIn? checkIn,
    bool clearCheckIn = false,
  }) {
    return MapFriend(
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      streak: streak ?? this.streak,
      x: x ?? this.x,
      y: y ?? this.y,
      isFriend: isFriend ?? this.isFriend,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      locationLabel: locationLabel ?? this.locationLabel,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      checkIn: clearCheckIn ? null : (checkIn ?? this.checkIn),
    );
  }

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
        checkIn,
      ];
}

/// Arkadaşın haritadaki aktif check-in’i.
class FriendMapCheckIn extends Equatable {
  const FriendMapCheckIn({
    required this.photoPaths,
    required this.stampImagePath,
    required this.placeName,
    this.checkedAt,
  });

  final List<String> photoPaths;
  final String stampImagePath;
  final String placeName;
  final DateTime? checkedAt;

  @override
  List<Object?> get props => [photoPaths, stampImagePath, placeName, checkedAt];
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

class ActiveMapCheckIn extends Equatable {
  const ActiveMapCheckIn({
    required this.stampImagePath,
    required this.photoPaths,
    required this.placeName,
    this.avatarPath = AssetPaths.avatarYou,
    this.checkedAt,
    this.titleLabel,
  });

  final String stampImagePath;
  final List<String> photoPaths;
  final String placeName;
  final String avatarPath;
  final DateTime? checkedAt;

  /// Doluysa map'te stamp yerine unvan kartı gösterilir (örn. "👑 Kurucu Kral").
  final String? titleLabel;

  bool get hasTitle => titleLabel != null && titleLabel!.trim().isNotEmpty;

  String get photoPath =>
      photoPaths.isNotEmpty ? photoPaths.first : AssetPaths.mapSecondAvatar;

  static bool isFilePath(String path) =>
      path.isNotEmpty && !path.startsWith('assets/');

  bool get isFilePhoto => isFilePath(photoPath);

  @override
  List<Object?> get props => [
        stampImagePath,
        photoPaths,
        placeName,
        avatarPath,
        checkedAt,
        titleLabel,
      ];
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

  ActiveMapCheckIn? _activeMapCheckIn;
  final activeMapCheckInListenable = ValueNotifier<ActiveMapCheckIn?>(null);
  final checkInPhotoIndexListenable = ValueNotifier<int>(0);
  final mapFriendsListenable = ValueNotifier<List<MapFriend>>(const []);
  final _viewedStoryAvatarPaths = <String>{};
  Timer? _checkInPhotoTimer;
  final _friendPhotoIndexes = <String, ValueNotifier<int>>{};
  final _friendPhotoTimers = <String, Timer>{};

  ActiveMapCheckIn? get activeMapCheckIn => _activeMapCheckIn;

  /// Marker + sheet aynı indeksi paylaşsın diye arkadaş bazlı foto döngüsü.
  ValueListenable<int> friendCheckInPhotoIndexListenable(String name) {
    return _friendPhotoIndexes.putIfAbsent(
      name,
      () => ValueNotifier<int>(0),
    );
  }

  void setActiveMapCheckIn(ActiveMapCheckIn? checkIn) {
    _activeMapCheckIn = checkIn;
    activeMapCheckInListenable.value = checkIn;
    _restartCheckInPhotoCycle(checkIn);
  }

  void _restartCheckInPhotoCycle(ActiveMapCheckIn? checkIn) {
    _checkInPhotoTimer?.cancel();
    _checkInPhotoTimer = null;
    checkInPhotoIndexListenable.value = 0;
    final paths = checkIn?.photoPaths ?? const <String>[];
    if (paths.length < 2) return;
    _checkInPhotoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final len = _activeMapCheckIn?.photoPaths.length ?? 0;
      if (len < 2) return;
      checkInPhotoIndexListenable.value =
          (checkInPhotoIndexListenable.value + 1) % len;
    });
  }

  void _syncFriendPhotoCycles(List<MapFriend> friends) {
    final activeNames = <String>{};
    for (final friend in friends) {
      final checkIn = friend.checkIn;
      if (checkIn == null) continue;
      activeNames.add(friend.name);
      _restartFriendPhotoCycle(friend.name, checkIn.photoPaths);
    }
    for (final name in _friendPhotoTimers.keys.toList()) {
      if (activeNames.contains(name)) continue;
      _friendPhotoTimers.remove(name)?.cancel();
      _friendPhotoIndexes[name]?.value = 0;
    }
  }

  void _restartFriendPhotoCycle(String name, List<String> photoPaths) {
    _friendPhotoTimers.remove(name)?.cancel();
    final index = _friendPhotoIndexes.putIfAbsent(
      name,
      () => ValueNotifier<int>(0),
    );
    index.value = 0;
    if (photoPaths.length < 2) return;
    _friendPhotoTimers[name] = Timer.periodic(const Duration(seconds: 5), (_) {
      MapFriend? friend;
      for (final f in mapFriendsListenable.value) {
        if (f.name == name) {
          friend = f;
          break;
        }
      }
      final len = friend?.checkIn?.photoPaths.length ?? 0;
      if (len < 2) return;
      index.value = (index.value + 1) % len;
    });
  }

  Future<UserProfile> getCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _currentUser;
  }

  Future<PublicUserProfile> getPublicUserProfile(String username) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final handle = username.startsWith('@') ? username.substring(1) : username;
    final key = handle.toLowerCase().trim();
    final byKey = _publicProfiles[key];
    if (byKey != null) return byKey;

    for (final profile in _publicProfiles.values) {
      final profileHandle = profile.usernameHandle.toLowerCase();
      final fullName = profile.name.toLowerCase();
      final firstName = fullName.split(RegExp(r'\s+')).first;
      if (profileHandle == key ||
          fullName == key ||
          firstName == key ||
          fullName.startsWith(key)) {
        return profile;
      }
    }

    return PublicUserProfile(
      name: handle,
      username: '@$handle',
      avatarPath: AssetPaths.avatarJulia,
      location: 'Los Angeles, CA',
      bio:
          "Someone who loves getting lost in the streets at midnight. There's a story around every corner.",
      checkIns: 124,
      followers: 1252,
      friends: 102,
      isVerified: true,
      streak: 5,
      explorerTitle: 'City Explorer',
      mapPlaceName: 'New York, Times Square',
      mapDistanceKm: '210km',
      mutualFriendsCount: 13,
      mutualFriendAvatars: const [
        AssetPaths.avatarLyra,
        AssetPaths.avatarJessica,
        AssetPaths.avatarSona,
      ],
    );
  }

  static final _publicProfiles = <String, PublicUserProfile>{
    'juliaivanova': const PublicUserProfile(
      name: 'Julia Ivanova',
      username: '@juliaivanova',
      avatarPath: AssetPaths.avatarJulia,
      location: 'Los Angeles, CA',
      bio:
          "Someone who loves getting lost in the streets at midnight. There's a story around every corner.",
      checkIns: 124,
      followers: 1252,
      friends: 102,
      isVerified: true,
      streak: 5,
      explorerTitle: 'City Explorer',
      mapPlaceName: 'New York, Times Square',
      mapDistanceKm: '210km',
      mutualFriendsCount: 13,
      mutualFriendAvatars: [
        AssetPaths.avatarLyra,
        AssetPaths.avatarJessica,
        AssetPaths.avatarSona,
      ],
    ),
    'lyra': const PublicUserProfile(
      name: 'Lyra Jhonson',
      username: '@lyrajhonson',
      avatarPath: AssetPaths.avatarLyra,
      location: 'Silver Lake, Los Angeles',
      bio: 'Midnight walks, vinyl nights, and collecting stamps around the city.',
      checkIns: 86,
      followers: 940,
      friends: 71,
      isVerified: true,
      streak: 12,
      explorerTitle: 'Night Explorer',
      mapPlaceName: 'Silver Lake, Los Angeles',
      mapDistanceKm: '120m',
      mutualFriendsCount: 9,
      mutualFriendAvatars: [
        AssetPaths.avatarJessica,
        AssetPaths.avatarSona,
        AssetPaths.avatarJulia,
      ],
      isFollowing: true,
    ),
    'lyrajhonson': const PublicUserProfile(
      name: 'Lyra Jhonson',
      username: '@lyrajhonson',
      avatarPath: AssetPaths.avatarLyra,
      location: 'Silver Lake, Los Angeles',
      bio: 'Midnight walks, vinyl nights, and collecting stamps around the city.',
      checkIns: 86,
      followers: 940,
      friends: 71,
      isVerified: true,
      streak: 12,
      explorerTitle: 'Night Explorer',
      mapPlaceName: 'Silver Lake, Los Angeles',
      mapDistanceKm: '120m',
      mutualFriendsCount: 9,
      mutualFriendAvatars: [
        AssetPaths.avatarJessica,
        AssetPaths.avatarSona,
        AssetPaths.avatarJulia,
      ],
      isFollowing: true,
    ),
    'sona': const PublicUserProfile(
      name: 'Sona Black',
      username: '@sonablack',
      avatarPath: AssetPaths.avatarSona,
      location: 'Echo Park, Los Angeles',
      bio: 'Always nearby for coffee, concerts, and spontaneous check-ins.',
      checkIns: 53,
      followers: 612,
      friends: 44,
      isVerified: true,
      streak: 5,
      explorerTitle: 'City Hopper',
      mapPlaceName: 'Echo Park, Los Angeles',
      mapDistanceKm: '50m',
      mutualFriendsCount: 6,
      mutualFriendAvatars: [
        AssetPaths.avatarLyra,
        AssetPaths.avatarJessica,
        AssetPaths.avatarNova,
      ],
    ),
    'sonablack': const PublicUserProfile(
      name: 'Sona Black',
      username: '@sonablack',
      avatarPath: AssetPaths.avatarSona,
      location: 'Echo Park, Los Angeles',
      bio: 'Always nearby for coffee, concerts, and spontaneous check-ins.',
      checkIns: 53,
      followers: 612,
      friends: 44,
      isVerified: true,
      streak: 5,
      explorerTitle: 'City Hopper',
      mapPlaceName: 'Echo Park, Los Angeles',
      mapDistanceKm: '50m',
      mutualFriendsCount: 6,
      mutualFriendAvatars: [
        AssetPaths.avatarLyra,
        AssetPaths.avatarJessica,
        AssetPaths.avatarNova,
      ],
    ),
    'jessica': const PublicUserProfile(
      name: 'Jessica Black',
      username: '@jessica.3712',
      avatarPath: AssetPaths.avatarJessica,
      location: 'Los Angeles, CA',
      bio: 'Coffee, sunsets, and late-night walks.',
      checkIns: 48,
      followers: 820,
      friends: 64,
      isVerified: true,
      streak: 12,
      explorerTitle: 'City Explorer',
      mapPlaceName: 'Echo Park, Los Angeles',
      mapDistanceKm: '4km',
      mutualFriendsCount: 8,
      mutualFriendAvatars: [
        AssetPaths.avatarLyra,
        AssetPaths.avatarSona,
        AssetPaths.avatarNova,
      ],
    ),
    'jessica.3712': const PublicUserProfile(
      name: 'Jessica Black',
      username: '@jessica.3712',
      avatarPath: AssetPaths.avatarJessica,
      location: 'Los Angeles, CA',
      bio: 'Coffee, sunsets, and late-night walks.',
      checkIns: 48,
      followers: 820,
      friends: 64,
      isVerified: true,
      streak: 12,
      explorerTitle: 'City Explorer',
      mapPlaceName: 'Echo Park, Los Angeles',
      mapDistanceKm: '4km',
      mutualFriendsCount: 8,
      mutualFriendAvatars: [
        AssetPaths.avatarLyra,
        AssetPaths.avatarSona,
        AssetPaths.avatarNova,
      ],
    ),
    'jonathanjnt': const PublicUserProfile(
      name: 'Jonathan Sam',
      username: '@jonathanjnt',
      avatarPath: AssetPaths.avatarAlex,
      location: 'Los Angeles, CA',
      bio: 'Always chasing the next check-in.',
      checkIns: 31,
      followers: 410,
      friends: 40,
      streak: 3,
      explorerTitle: 'Night Owl',
      mapPlaceName: 'Santa Monica Pier',
      mapDistanceKm: '18km',
      mutualFriendsCount: 5,
      mutualFriendAvatars: [
        AssetPaths.avatarJessica,
        AssetPaths.avatarLyra,
        AssetPaths.avatarNova,
      ],
    ),
    'hannahfood': const PublicUserProfile(
      name: 'Just Hannah',
      username: '@hannahfood',
      avatarPath: AssetPaths.avatarSona,
      location: 'Los Angeles, CA',
      bio: 'Food first, everything else later.',
      checkIns: 77,
      followers: 1503,
      friends: 88,
      isVerified: true,
      streak: 9,
      explorerTitle: 'Foodie',
      mapPlaceName: 'Downtown LA',
      mapDistanceKm: '12km',
      mutualFriendsCount: 11,
      mutualFriendAvatars: [
        AssetPaths.avatarJessica,
        AssetPaths.avatarLyra,
        AssetPaths.avatarAlex,
      ],
    ),
    'nova': const PublicUserProfile(
      name: 'Nova',
      username: '@nova',
      avatarPath: AssetPaths.avatarNova,
      location: 'Los Angeles, CA',
      bio: 'Making things and meeting people.',
      checkIns: 22,
      followers: 290,
      friends: 35,
      streak: 2,
      explorerTitle: 'Creator',
      mapPlaceName: 'Silver Lake, Los Angeles',
      mapDistanceKm: '7km',
      mutualFriendsCount: 4,
      mutualFriendAvatars: [
        AssetPaths.avatarJessica,
        AssetPaths.avatarSona,
        AssetPaths.avatarLyra,
      ],
    ),
    'clara.smith': const PublicUserProfile(
      name: 'Make With Clara',
      username: '@clara.smith',
      avatarPath: AssetPaths.avatarNova,
      location: 'Los Angeles, CA',
      bio: 'Making things and meeting people.',
      checkIns: 22,
      followers: 290,
      friends: 35,
      streak: 2,
      explorerTitle: 'Creator',
      mapPlaceName: 'Silver Lake, Los Angeles',
      mapDistanceKm: '7km',
      mutualFriendsCount: 4,
      mutualFriendAvatars: [
        AssetPaths.avatarJessica,
        AssetPaths.avatarSona,
        AssetPaths.avatarLyra,
      ],
    ),
  };

  Future<void> updateCurrentUser(UserProfile user) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _currentUser = user;
  }

  Future<List<StoryPreview>> getStories() async {
    const base = [
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

    final withViewed = [
      for (final story in base)
        story.copyWith(
          isViewed: !story.isYou &&
              _viewedStoryAvatarPaths.contains(story.avatarPath),
        ),
    ];

    withViewed.sort((a, b) {
      if (a.isYou != b.isYou) return a.isYou ? -1 : 1;
      if (a.isViewed != b.isViewed) return a.isViewed ? 1 : -1;
      return 0;
    });
    return withViewed;
  }

  void markStoryViewed(String avatarPath) {
    if (avatarPath.isEmpty) return;
    _viewedStoryAvatarPaths.add(avatarPath);
  }

  bool isStoryViewed(String avatarPath) =>
      _viewedStoryAvatarPaths.contains(avatarPath);

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
    const friends = [
      MapFriend(
        name: 'Lyra',
        avatarPath: AssetPaths.avatarLyra,
        streak: 12,
        x: -0.45,
        y: -0.15,
        locationLabel: 'Silver Lake, Los Angeles',
        etaMinutes: 15,
        distanceMeters: 120,
        checkIn: FriendMapCheckIn(
          photoPaths: [AssetPaths.mapFirst, AssetPaths.pulse1],
          stampImagePath: AssetPaths.stamp3,
          placeName: 'Silver Lake, Los Angeles',
        ),
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
    mapFriendsListenable.value = friends;
    _syncFriendPhotoCycles(friends);
    return friends;
  }

  /// Arkadaş check-in’ini haritada anlık günceller.
  MapFriend? applyFriendCheckIn({
    required String name,
    required FriendMapCheckIn checkIn,
    double? x,
    double? y,
    int? distanceMeters,
    int? etaMinutes,
  }) {
    final current = mapFriendsListenable.value;
    if (current.isEmpty) return null;

    MapFriend? updatedFriend;
    final next = <MapFriend>[];
    for (final friend in current) {
      if (friend.name != name) {
        next.add(friend);
        continue;
      }
      updatedFriend = friend.copyWith(
        checkIn: checkIn,
        x: x,
        y: y,
        distanceMeters: distanceMeters,
        etaMinutes: etaMinutes,
        locationLabel: checkIn.placeName,
      );
      next.add(updatedFriend);
    }

    if (updatedFriend == null) return null;
    mapFriendsListenable.value = next;
    _restartFriendPhotoCycle(name, checkIn.photoPaths);
    return updatedFriend;
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

  Future<List<CheckInItem>> getCheckIns({String? forUsername}) async {
    final key = _profileKey(forUsername);
    final all = const [
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
      CheckInItem(
        placeName: 'Silver Lake Reservoir',
        when: 'Today · 02:10pm',
        imagePath: AssetPaths.mapFirst,
      ),
      CheckInItem(
        placeName: 'Echo Park Lake',
        when: 'Yesterday · 07:40 pm',
        imagePath: AssetPaths.pulse1,
      ),
    ];
    if (key.contains('lyra')) {
      return [all[3], all[0], all[1]];
    }
    if (key.contains('sona')) {
      return [all[4], all[2]];
    }
    if (key.contains('jessica')) {
      return [all[1], all[4], all[2]];
    }
    return all.take(3).toList();
  }

  Future<List<PulseItem>> getPulses({String? forUsername}) async {
    const friends = [
      AssetPaths.avatarLyra,
      AssetPaths.avatarJessica,
      AssetPaths.avatarSona,
    ];
    final all = const [
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
      PulseItem(
        imagePath: AssetPaths.mapFirst,
        time: '04:00 PM',
        placeName: 'Silver Lake',
        subtitle: 'Walk · LA',
        friendAvatars: friends,
        friendsLabel: '2+ friends\nare joining',
      ),
      PulseItem(
        imagePath: AssetPaths.pulseJessica,
        time: '06:15 PM',
        placeName: 'Echo Park',
        subtitle: 'Hangout · LA',
        friendAvatars: friends,
        friendsLabel: '4+ friends\nare joining',
      ),
    ];
    final key = _profileKey(forUsername);
    if (key.contains('lyra')) return [all[3], all[0], all[1]];
    if (key.contains('sona')) return [all[4], all[2]];
    if (key.contains('jessica')) return [all[1], all[4], all[0]];
    return all.take(3).toList();
  }

  Future<List<StampItem>> getStamps({String? forUsername}) async {
    final all = const [
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
    final key = _profileKey(forUsername);
    if (key.contains('lyra')) return all.take(9).toList();
    if (key.contains('sona')) return all.skip(4).take(8).toList();
    if (key.contains('jessica')) return all.skip(2).take(10).toList();
    return all;
  }

  Future<List<PlanItem>> getTodayPlans({String? forUsername}) async {
    const friends = [
      AssetPaths.avatarLyra,
      AssetPaths.avatarJessica,
      AssetPaths.avatarSona,
    ];
    final all = const [
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
      PlanItem(
        time: '05:30 PM',
        placeName: 'Silver Lake Coffee',
        subtitle: 'Cafe · LA',
        friendAvatars: friends,
        friendsLabel: '2+ friends\nare joining',
      ),
      PlanItem(
        time: '07:00 PM',
        placeName: 'Echo Park Hangout',
        subtitle: 'Meetup · LA',
        friendAvatars: friends,
        friendsLabel: '3+ friends\nare joining',
      ),
    ];
    final key = _profileKey(forUsername);
    if (key.contains('lyra')) return [all[2], all[0]];
    if (key.contains('sona')) return [all[3]];
    if (key.contains('jessica')) return [all[1], all[3]];
    return all.take(2).toList();
  }

  String _profileKey(String? forUsername) {
    if (forUsername == null || forUsername.trim().isEmpty) return '';
    final value = forUsername.trim();
    return (value.startsWith('@') ? value.substring(1) : value).toLowerCase();
  }
}
