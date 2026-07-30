import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';

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
    this.accountPrivacy = 'public',
    this.links = const [],
  });

  factory UserProfile.fromAuthMe(Map<String, dynamic> json) {
    final profile = json['profile'];
    final profileMap = profile is Map<String, dynamic> ? profile : const {};
    final rawLinks = json['links'];
    final links = <ProfileLink>[];
    if (rawLinks is List) {
      for (final item in rawLinks) {
        if (item is! Map<String, dynamic>) continue;
        final title = (item['title'] as String?)?.trim() ?? '';
        final url = (item['url'] as String?)?.trim() ?? '';
        if (title.isEmpty || url.isEmpty) continue;
        links.add(ProfileLink(title: title, url: url));
      }
    }

    final username = (profileMap['username'] as String?)?.trim() ?? '';
    final handle = username.isEmpty
        ? '@user'
        : (username.startsWith('@') ? username : '@$username');
    final avatarUrl = (profileMap['avatarUrl'] as String?)?.trim() ?? '';

    return UserProfile(
      name: (profileMap['fullName'] as String?)?.trim().isNotEmpty == true
          ? (profileMap['fullName'] as String).trim()
          : 'User',
      username: handle,
      avatarPath: avatarUrl,
      location: (profileMap['locationText'] as String?)?.trim() ?? '',
      bio: (profileMap['bio'] as String?)?.trim() ?? '',
      checkIns: (profileMap['checkInsCount'] as num?)?.toInt() ?? 0,
      followers: 0,
      friends: (profileMap['friendsCount'] as num?)?.toInt() ?? 0,
      accountPrivacy:
          (profileMap['accountPrivacy'] as String?)?.trim().toLowerCase() ??
          'public',
      links: links,
    );
  }

  final String name;
  final String username;
  final String avatarPath;
  final String location;
  final String bio;
  final int checkIns;
  final int followers;
  final int friends;
  final String accountPrivacy;
  final List<ProfileLink> links;

  String get usernameHandle =>
      username.startsWith('@') ? username.substring(1) : username;

  /// Gerçek fotoğraf var mı (CDN / lokal dosya). Asset placeholder sayılmaz.
  bool get hasPhoto {
    if (avatarPath.isEmpty) return false;
    return avatarPath.startsWith('http://') ||
        avatarPath.startsWith('https://') ||
        avatarPath.startsWith('/') ||
        avatarPath.startsWith('file:');
  }

  UserProfile copyWith({
    String? name,
    String? username,
    String? avatarPath,
    String? location,
    String? bio,
    int? checkIns,
    int? followers,
    int? friends,
    String? accountPrivacy,
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
      accountPrivacy: accountPrivacy ?? this.accountPrivacy,
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
        accountPrivacy,
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
    this.userId = '',
    this.isVerified = false,
    this.streak = 0,
    this.explorerTitle = '',
    this.mapPlaceName = '',
    this.mapDistanceKm = '',
    this.mutualFriendsCount = 0,
    this.mutualFriendAvatars = const [],
    this.isFollowing = false,
    this.areFriends = false,
    this.isSelf = false,
    this.hasActiveStory = false,
    this.storyIsViewed = false,
    this.isHydrated = true,
  });

  final String userId;
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

  /// Real friendship from API — not flipped by the local "Takip Et" toggle.
  final bool areFriends;
  final bool isSelf;
  final bool hasActiveStory;
  final bool storyIsViewed;

  /// False until the first successful `/users/by-username` response for this user.
  final bool isHydrated;

  String get usernameHandle =>
      username.startsWith('@') ? username.substring(1) : username;

  String get usernameWithAt =>
      username.startsWith('@') ? username : '@$username';

  /// Plans / pulses / stamps / check-ins / map — friends (or self) only.
  bool get canSeeFriendContent => isSelf || areFriends;

  factory PublicUserProfile.skeleton({
    required String username,
    String name = '',
    String avatarPath = '',
    String userId = '',
    bool hasActiveStory = false,
  }) {
    final handle = username.startsWith('@')
        ? username.substring(1)
        : username.trim();
    return PublicUserProfile(
      userId: userId,
      name: name.trim().isNotEmpty ? name.trim() : handle,
      username: '@$handle',
      avatarPath: avatarPath,
      location: '',
      bio: '',
      checkIns: 0,
      followers: 0,
      friends: 0,
      hasActiveStory: hasActiveStory,
      isHydrated: false,
    );
  }

  PublicUserProfile copyWith({
    bool? isFollowing,
    bool? areFriends,
    bool? isSelf,
    bool? hasActiveStory,
    bool? storyIsViewed,
    bool? isHydrated,
  }) {
    return PublicUserProfile(
      userId: userId,
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
      areFriends: areFriends ?? this.areFriends,
      isSelf: isSelf ?? this.isSelf,
      hasActiveStory: hasActiveStory ?? this.hasActiveStory,
      storyIsViewed: storyIsViewed ?? this.storyIsViewed,
      isHydrated: isHydrated ?? this.isHydrated,
    );
  }

  factory PublicUserProfile.fromApi({
    required Map<String, dynamic> profile,
  }) {
    final username = (profile['username'] as String?)?.trim() ?? '';
    final handle = username.isEmpty
        ? 'user'
        : (username.startsWith('@') ? username.substring(1) : username);
    final avatarUrl = (profile['avatarUrl'] as String?)?.trim() ?? '';
    final friends = profile['isFollowing'] == true;

    return PublicUserProfile(
      userId: (profile['userId'] as String?)?.trim() ?? '',
      name: (profile['fullName'] as String?)?.trim().isNotEmpty == true
          ? (profile['fullName'] as String).trim()
          : handle,
      username: '@$handle',
      avatarPath: avatarUrl,
      location: (profile['locationText'] as String?)?.trim() ?? '',
      bio: (profile['bio'] as String?)?.trim() ?? '',
      checkIns: (profile['checkInsCount'] as num?)?.toInt() ?? 0,
      followers: 0,
      friends: (profile['friendsCount'] as num?)?.toInt() ?? 0,
      isVerified: profile['isVerified'] == true,
      streak: (profile['streakCount'] as num?)?.toInt() ?? 0,
      explorerTitle: '',
      mapPlaceName: '',
      mapDistanceKm: '',
      mutualFriendsCount: 0,
      mutualFriendAvatars: const [],
      isFollowing: friends,
      areFriends: friends,
      isSelf: profile['isSelf'] == true,
      hasActiveStory: profile['hasActiveStory'] == true,
      storyIsViewed: profile['storyIsViewed'] == true,
      isHydrated: true,
    );
  }

  @override
  List<Object?> get props => [
        userId,
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
        areFriends,
        isSelf,
        hasActiveStory,
        storyIsViewed,
        isHydrated,
      ];
}

class StoryPreview extends Equatable {
  const StoryPreview({
    required this.name,
    required this.avatarPath,
    this.isYou = false,
    this.hasStory = true,
    this.isViewed = false,
    this.userId,
  });

  final String name;
  final String avatarPath;
  final bool isYou;
  final bool hasStory;
  final bool isViewed;
  final String? userId;

  StoryPreview copyWith({
    String? name,
    String? avatarPath,
    bool? isYou,
    bool? hasStory,
    bool? isViewed,
    String? userId,
  }) {
    return StoryPreview(
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      isYou: isYou ?? this.isYou,
      hasStory: hasStory ?? this.hasStory,
      isViewed: isViewed ?? this.isViewed,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [
    name,
    avatarPath,
    isYou,
    hasStory,
    isViewed,
    userId,
  ];
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
    this.storyId,
    this.userId,
    this.username,
    this.musicAudioUrl,
    this.musicTrackId,
    this.musicClipStartMs,
    this.musicClipDurationMs,
    this.expiresAt,
    this.likeCount = 0,
    this.likedByMe = false,
    this.isViewed = false,
  });

  final String imagePath;
  final String label;
  final String avatarPath;
  final String caption;
  final bool isReel;
  final bool isVerified;
  final String? storyId;
  final String? userId;

  /// Handle for profile navigation — [label] is a display name, not a username.
  final String? username;
  final String? musicAudioUrl;
  final String? musicTrackId;
  final int? musicClipStartMs;
  final int? musicClipDurationMs;
  final DateTime? expiresAt;
  final int likeCount;
  final bool likedByMe;
  final bool isViewed;

  bool get isNetworkImage =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  bool get hasMusic =>
      musicAudioUrl != null && musicAudioUrl!.trim().isNotEmpty;

  bool get isExpired {
    final exp = expiresAt;
    if (exp == null) return false;
    return !exp.isAfter(DateTime.now());
  }

  StoryMediaItem copyWith({
    String? imagePath,
    String? label,
    String? avatarPath,
    String? caption,
    bool? isReel,
    bool? isVerified,
    String? storyId,
    String? userId,
    String? username,
    String? musicAudioUrl,
    String? musicTrackId,
    int? musicClipStartMs,
    int? musicClipDurationMs,
    DateTime? expiresAt,
    int? likeCount,
    bool? likedByMe,
    bool? isViewed,
  }) {
    return StoryMediaItem(
      imagePath: imagePath ?? this.imagePath,
      label: label ?? this.label,
      avatarPath: avatarPath ?? this.avatarPath,
      caption: caption ?? this.caption,
      isReel: isReel ?? this.isReel,
      isVerified: isVerified ?? this.isVerified,
      storyId: storyId ?? this.storyId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      musicAudioUrl: musicAudioUrl ?? this.musicAudioUrl,
      musicTrackId: musicTrackId ?? this.musicTrackId,
      musicClipStartMs: musicClipStartMs ?? this.musicClipStartMs,
      musicClipDurationMs: musicClipDurationMs ?? this.musicClipDurationMs,
      expiresAt: expiresAt ?? this.expiresAt,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  @override
  List<Object?> get props => [
    imagePath,
    label,
    avatarPath,
    caption,
    isReel,
    isVerified,
    storyId,
    userId,
    username,
    musicAudioUrl,
    musicTrackId,
    musicClipStartMs,
    musicClipDurationMs,
    expiresAt,
    likeCount,
    likedByMe,
    isViewed,
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
  const StampItem({
    required this.imagePath,
    required this.title,
    this.id = '',
  });

  factory StampItem.fromCatalog(StampCatalogItem item) {
    return StampItem(
      id: item.id,
      imagePath: item.imageUrl,
      title: item.name,
    );
  }

  final String id;
  final String imagePath;
  final String title;

  bool get isNetwork =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  @override
  List<Object?> get props => [id, imagePath, title];
}

class ActiveMapCheckIn extends Equatable {
  const ActiveMapCheckIn({
    required this.stampImagePath,
    required this.photoPaths,
    required this.placeName,
    this.avatarPath = '',
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
    this.id,
    this.note = '',
    this.showToFriends = true,
    this.showToNearby = false,
  });

  final String? id;
  final String time;
  final String placeName;
  final String subtitle;
  final List<String> friendAvatars;
  final String friendsLabel;
  final String note;
  final bool showToFriends;
  final bool showToNearby;

  @override
  List<Object?> get props => [
    id,
    time,
    placeName,
    subtitle,
    friendAvatars,
    friendsLabel,
    note,
    showToFriends,
    showToNearby,
  ];
}

class NearbyAddPlanPlace extends Equatable {
  const NearbyAddPlanPlace({
    required this.categoryKey,
    required this.placeName,
    required this.subtitle,
    required this.distanceLabel,
    required this.friendAvatars,
    required this.friendsLabel,
  });

  final String categoryKey;
  final String placeName;
  final String subtitle;
  final String distanceLabel;
  final List<String> friendAvatars;
  final String friendsLabel;

  @override
  List<Object?> get props => [
        categoryKey,
        placeName,
        subtitle,
        distanceLabel,
        friendAvatars,
        friendsLabel,
      ];
}

class UserRepository {
  UserRepository(this._authRepository);

  final AuthRepository _authRepository;
  final Dio _publicDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: const {'User-Agent': 'zovi-app/1.0'},
    ),
  );
  static const int _nearbyPlacesDisplayLimit = 20;
  static const int _nearbyPlacesCandidateLimit = 80;
  static const double _nearbyPlacesSearchRadiusMeters = 2500;
  static const double _nearbyPlacesRefreshDistanceMeters = 300;
  static const Duration _nearbyPlacesMaxCacheAge = Duration(minutes: 10);
  List<NearbyAddPlanPlace> _nearbyAddPlanPlacesCache = const [];
  Position? _nearbyAddPlanPlacesCachePosition;
  DateTime? _nearbyAddPlanPlacesCachedAt;

  UserProfile _currentUser = const UserProfile(
    name: '',
    username: '@',
    avatarPath: '',
    location: '',
    bio: '',
    checkIns: 0,
    followers: 0,
    friends: 0,
    accountPrivacy: 'public',
    links: [],
  );

  bool _profileHydrated = false;

  /// Navbar / diğer yerler profil avatarını dinleyebilir.
  final currentUserListenable = ValueNotifier<UserProfile?>(null);

  /// Warm stamp/sticker disk cache after login so story sheets open instantly.
  /// Best-effort: failures here must never surface to the UI.
  void warmStampCaches({String locale = 'en'}) {
    unawaited(
      _authRepository
          .fetchOwnedPickerStamps(locale: locale)
          .catchError((_) => const <StampCatalogItem>[]),
    );
    unawaited(
      _authRepository
          .fetchStampCatalog(locale: locale)
          .catchError((_) => const <StampCatalogItem>[]),
    );
  }

  /// Splash / login sonrası cache'lenmiş profil. Yoksa null.
  UserProfile? get cachedCurrentUser =>
      _profileHydrated ? _currentUser : currentUserListenable.value;

  bool get hasCachedProfile {
    final user = cachedCurrentUser;
    if (user == null) return false;
    return user.name.trim().isNotEmpty && user.usernameHandle.isNotEmpty;
  }

  /// Wipes everything tied to the signed-in account so the next login never
  /// paints the previous user's photos or stories.
  void clearSessionCache() {
    _profileHydrated = false;
    _currentUser = const UserProfile(
      name: '',
      username: '@',
      avatarPath: '',
      location: '',
      bio: '',
      checkIns: 0,
      followers: 0,
      friends: 0,
      accountPrivacy: 'public',
      links: [],
    );
    currentUserListenable.value = null;

    _sessionUserId = null;
    _clearStoryCaches();
    _publicProfileCache.clear();

    _activeMapCheckIn = null;
    activeMapCheckInListenable.value = null;
    mapFriendsListenable.value = const [];
    checkInPhotoIndexListenable.value = 0;

    _nearbyAddPlanPlacesCache = const [];
    _nearbyAddPlanPlacesCachePosition = null;
    _nearbyAddPlanPlacesCachedAt = null;

    _authRepository.clearSessionCaches();
  }

  ActiveMapCheckIn? _activeMapCheckIn;
  final activeMapCheckInListenable = ValueNotifier<ActiveMapCheckIn?>(null);
  final checkInPhotoIndexListenable = ValueNotifier<int>(0);
  final mapFriendsListenable = ValueNotifier<List<MapFriend>>(const []);
  final _viewedStoryAvatarPaths = <String>{};
  final _viewedStoryIds = <String>{};
  List<StoryMediaItem> _cachedMyStoryItems = const [];
  List<StoryPreview> _lastStoryPreviews = const [];
  final _friendStoryItemsByUserId = <String, List<StoryMediaItem>>{};
  final _publicProfileCache = <String, PublicUserProfile>{};
  List<StoryPreview> _lastFriendPreviews = const [];
  List<StoryMediaItem> _cachedExploreItems = const [];
  String? _sessionUserId;

  void _clearStoryCaches() {
    _cachedMyStoryItems = const [];
    _cachedExploreItems = const [];
    _friendStoryItemsByUserId.clear();
    _lastStoryPreviews = const [];
    _lastFriendPreviews = const [];
    _viewedStoryIds.clear();
    _viewedStoryAvatarPaths.clear();
  }

  /// Safety net for the case where a logout did not run its cleanup: if the
  /// feed comes back for a different account, drop what we held.
  void _ensureStoryCachesFor(String userId) {
    if (userId.isEmpty || _sessionUserId == userId) return;
    if (_sessionUserId != null) {
      _clearStoryCaches();
      _authRepository.clearSessionCaches();
    }
    _sessionUserId = userId;
  }

  List<StoryMediaItem> _mapPublishedStories(
    List<PublishedStory> stories, {
    required String label,
    required String avatar,
    String? username,
  }) {
    final now = DateTime.now();
    final handle = username?.trim();
    return [
      for (final story in stories)
        if (story.mediaUrl.isNotEmpty &&
            (story.expiresAt == null || story.expiresAt!.isAfter(now)))
          StoryMediaItem(
            imagePath: story.mediaUrl,
            label: label,
            avatarPath: avatar,
            caption: '',
            isReel: false,
            isVerified: false,
            storyId: story.id,
            userId: story.userId,
            username: handle != null && handle.isNotEmpty
                ? handle
                : story.authorUsername,
            musicAudioUrl: story.musicAudioUrl,
            musicTrackId: story.musicTrackId,
            musicClipStartMs: story.musicClipStartMs,
            musicClipDurationMs: story.musicClipDurationMs,
            expiresAt: story.expiresAt,
            likeCount: story.likeCount,
            likedByMe: story.likedByMe,
            isViewed: story.isViewed,
          ),
    ];
  }

  void _cacheMyStoryItems(List<StoryMediaItem> items) {
    _cachedMyStoryItems = List<StoryMediaItem>.unmodifiable(items);
    for (final item in items) {
      final path = item.imagePath;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        NetworkImage(path).resolve(ImageConfiguration.empty);
      }
    }
  }

  /// Instant open path for "Your story" — populated by [getStories] / publish.
  List<StoryMediaItem> peekMyActiveStoryItems() {
    final now = DateTime.now();
    final valid = [
      for (final item in _cachedMyStoryItems)
        if (item.expiresAt == null || item.expiresAt!.isAfter(now)) item,
    ];
    if (valid.length != _cachedMyStoryItems.length) {
      _cacheMyStoryItems(valid);
    }
    return valid;
  }
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
    final payload = await _authRepository.fetchMyProfilePayload();
    _currentUser = UserProfile.fromAuthMe(payload);
    _profileHydrated = true;
    currentUserListenable.value = _currentUser;
    return _currentUser;
  }

  /// Sadece gönderilen alanları PATCH eder; /auth/me çağırmaz.
  Future<UserProfile> patchProfileFields({
    String? fullName,
    String? username,
    String? bio,
  }) async {
    final result = await _authRepository.saveProfile(
      fullName: fullName,
      username: username,
      bio: bio,
    );
    final profile = result?['profile'];
    if (profile is Map<String, dynamic>) {
      final rawUsername = (profile['username'] as String?)?.trim() ?? '';
      final handle = rawUsername.isEmpty
          ? _currentUser.username
          : (rawUsername.startsWith('@') ? rawUsername : '@$rawUsername');
      _currentUser = _currentUser.copyWith(
        name: (profile['fullName'] as String?)?.trim().isNotEmpty == true
            ? (profile['fullName'] as String).trim()
            : null,
        username: handle,
        bio: profile.containsKey('bio')
            ? ((profile['bio'] as String?)?.trim() ?? '')
            : null,
        location: (profile['locationText'] as String?)?.trim(),
        avatarPath: (profile['avatarUrl'] as String?)?.trim().isNotEmpty == true
            ? (profile['avatarUrl'] as String).trim()
            : null,
        checkIns: (profile['checkInsCount'] as num?)?.toInt(),
        friends: (profile['friendsCount'] as num?)?.toInt(),
      );
    } else {
      _currentUser = _currentUser.copyWith(
        name: fullName?.trim(),
        username: username != null
            ? '@${username.replaceFirst('@', '').trim()}'
            : null,
        bio: bio?.trim(),
      );
    }
    _profileHydrated = true;
    currentUserListenable.value = _currentUser;
    return _currentUser;
  }

  Future<UserProfile> patchProfileLinks(List<ProfileLink> links) async {
    if (_sameLinks(links, _currentUser.links)) return _currentUser;
    await _authRepository.replaceProfileLinks(
      links.map((l) => (title: l.title, url: l.url)).toList(),
    );
    _currentUser = _currentUser.copyWith(links: links);
    _profileHydrated = true;
    currentUserListenable.value = _currentUser;
    return _currentUser;
  }

  Future<UserProfile> patchAvatarFile(String filePath) async {
    final uploadedUrl = await _authRepository.uploadAvatar(filePath);
    _currentUser = _currentUser.copyWith(avatarPath: uploadedUrl);
    _profileHydrated = true;
    currentUserListenable.value = _currentUser;
    return _currentUser;
  }

  /// Sadece değişen parçaları yazar. Değişiklik yoksa istek atmaz.
  Future<UserProfile> saveCurrentUserProfile({
    required String name,
    required String username,
    required String bio,
    required List<ProfileLink> links,
    String? localAvatarPath,
    bool saveBio = false,
  }) async {
    final handle =
        username.startsWith('@') ? username.substring(1) : username.trim();
    final nameChanged = name.trim() != _currentUser.name.trim();
    final usernameChanged =
        handle.toLowerCase() != _currentUser.usernameHandle.toLowerCase();
    final bioChanged =
        saveBio && bio.trim() != _currentUser.bio.trim();
    final linksChanged = !_sameLinks(links, _currentUser.links);
    final avatarDirty = localAvatarPath != null &&
        localAvatarPath.isNotEmpty &&
        (localAvatarPath.startsWith('/') ||
            localAvatarPath.startsWith('file:'));

    if (!nameChanged &&
        !usernameChanged &&
        !bioChanged &&
        !linksChanged &&
        !avatarDirty) {
      return _currentUser.copyWith(
        name: name.trim(),
        username: '@$handle',
        bio: bio.trim(),
        links: links,
      );
    }

    var avatarPath = _currentUser.avatarPath;
    final dirtyAvatarPath = localAvatarPath;
    if (avatarDirty && dirtyAvatarPath != null) {
      final filePath = dirtyAvatarPath.startsWith('file:')
          ? Uri.parse(dirtyAvatarPath).toFilePath()
          : dirtyAvatarPath;
      avatarPath = await _authRepository.uploadAvatar(filePath);
    }

    if (nameChanged || usernameChanged || bioChanged) {
      await patchProfileFields(
        fullName: nameChanged ? name.trim() : null,
        username: usernameChanged ? handle : null,
        bio: bioChanged ? bio.trim() : null,
      );
    }

    if (linksChanged) {
      await _authRepository.replaceProfileLinks(
        links.map((l) => (title: l.title, url: l.url)).toList(),
      );
      _currentUser = _currentUser.copyWith(links: links);
    }

    _currentUser = _currentUser.copyWith(
      name: name.trim(),
      username: '@$handle',
      bio: bio.trim(),
      avatarPath: avatarPath.startsWith('http') ? avatarPath : null,
      links: links,
    );
    _profileHydrated = true;
    currentUserListenable.value = _currentUser;
    return _currentUser;
  }

  static bool _sameLinks(List<ProfileLink> a, List<ProfileLink> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].title != b[i].title || a[i].url != b[i].url) return false;
    }
    return true;
  }

  PublicUserProfile? peekPublicUserProfile(String username) {
    final key = _profileKey(username);
    if (key.isEmpty) return null;
    return _publicProfileCache[key];
  }

  Future<PublicUserProfile> getPublicUserProfile(String username) async {
    final handle = username.startsWith('@') ? username.substring(1) : username;
    final key = handle.toLowerCase().trim();

    final payload = await _authRepository.fetchPublicProfileByUsername(key);
    final profileRaw = payload['profile'];
    if (profileRaw is! Map) {
      throw StateError('User not found');
    }
    final profile = PublicUserProfile.fromApi(
      profile: Map<String, dynamic>.from(profileRaw),
    );
    _publicProfileCache[key] = profile;
    return profile;
  }


  Future<void> updateCurrentUser(UserProfile user) async {
    _currentUser = user;
    _profileHydrated = true;
    currentUserListenable.value = user;
  }

  Future<List<NearbyAddPlanPlace>> getNearbyAddPlanPlaces({int limit = 20}) async {
    final safeLimit = limit.clamp(1, 20);
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        return const [];
      }
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );

    final cachedAt = _nearbyAddPlanPlacesCachedAt;
    final cachedPosition = _nearbyAddPlanPlacesCachePosition;
    if (_nearbyAddPlanPlacesCache.isNotEmpty &&
        cachedAt != null &&
        cachedPosition != null) {
      final movedMeters = Geolocator.distanceBetween(
        cachedPosition.latitude,
        cachedPosition.longitude,
        position.latitude,
        position.longitude,
      );
      final cacheAge = DateTime.now().difference(cachedAt);
      if (movedMeters < _nearbyPlacesRefreshDistanceMeters &&
          cacheAge < _nearbyPlacesMaxCacheAge) {
        return _nearbyAddPlanPlacesCache.take(safeLimit).toList();
      }
    }

    String area = '';
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        area =
            (p.subLocality ?? p.locality ?? p.subAdministrativeArea ?? '').trim();
      }
    } catch (_) {}

    final candidateLimit = (safeLimit * 4).clamp(40, _nearbyPlacesCandidateLimit);
    final query = '''
[out:json][timeout:12];
(
  node["name"]["amenity"](around:${_nearbyPlacesSearchRadiusMeters.toInt()},${position.latitude},${position.longitude});
  node["name"]["tourism"](around:${_nearbyPlacesSearchRadiusMeters.toInt()},${position.latitude},${position.longitude});
  node["name"]["leisure"](around:${_nearbyPlacesSearchRadiusMeters.toInt()},${position.latitude},${position.longitude});
);
out body $candidateLimit;
''';

    try {
      final response = await _publicDio.post<dynamic>(
        'https://overpass-api.de/api/interpreter',
        data: query,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final data = response.data;
      if (data is! Map) return _nearbyAddPlanPlacesCache;
      final elements = data['elements'];
      if (elements is! List) return _nearbyAddPlanPlacesCache;

      final seen = <String>{};
      final itemsWithDistance = <({NearbyAddPlanPlace place, double meters})>[];
      for (final element in elements) {
        if (element is! Map) continue;
        final tags = element['tags'];
        if (tags is! Map) continue;
        if (_shouldSkipPlace(tags)) continue;
        final name = (tags['name'] as String?)?.trim() ?? '';
        if (name.isEmpty || seen.contains(name.toLowerCase())) continue;

        final lat = (element['lat'] as num?)?.toDouble();
        final lon = (element['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;

        seen.add(name.toLowerCase());
        final category = _categoryFromTags(tags);
        final subtitle =
            '${_categoryLabel(category)}${area.isEmpty ? '' : ' · $area'}';
        final meters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          lat,
          lon,
        );
        itemsWithDistance.add((
          place: NearbyAddPlanPlace(
            categoryKey: category,
            placeName: name,
            subtitle: subtitle,
            distanceLabel: _formatDistance(meters),
            friendAvatars: const [],
            friendsLabel: '0',
          ),
          meters: meters,
        ));
      }
      itemsWithDistance.sort((a, b) => a.meters.compareTo(b.meters));
      final items = itemsWithDistance
          .map((item) => item.place)
          .take(_nearbyPlacesDisplayLimit)
          .toList();
      _nearbyAddPlanPlacesCache = items;
      _nearbyAddPlanPlacesCachePosition = position;
      _nearbyAddPlanPlacesCachedAt = DateTime.now();
      return items.take(safeLimit).toList();
    } catch (_) {
      return _nearbyAddPlanPlacesCache.take(safeLimit).toList();
    }
  }

  static String _categoryFromTags(Map tags) {
    final amenity = (tags['amenity'] as String?)?.toLowerCase() ?? '';
    final leisure = (tags['leisure'] as String?)?.toLowerCase() ?? '';
    final tourism = (tags['tourism'] as String?)?.toLowerCase() ?? '';

    if (amenity == 'cafe') return 'cafe';
    if (amenity == 'restaurant' ||
        amenity == 'fast_food' ||
        amenity == 'food_court') {
      return 'restaurant';
    }
    if (amenity == 'bar' || amenity == 'pub' || amenity == 'nightclub') {
      return 'music';
    }
    if (leisure == 'park' || leisure == 'garden') return 'park';
    if (tourism == 'museum' || tourism == 'gallery' || tourism == 'attraction') {
      return 'culture';
    }
    return 'culture';
  }

  static bool _shouldSkipPlace(Map tags) {
    final amenity = (tags['amenity'] as String?)?.toLowerCase() ?? '';
    final healthcare = (tags['healthcare'] as String?)?.toLowerCase() ?? '';
    final shop = (tags['shop'] as String?)?.toLowerCase() ?? '';
    final office = (tags['office'] as String?)?.toLowerCase() ?? '';
    final emergency = (tags['emergency'] as String?)?.toLowerCase() ?? '';
    final highway = (tags['highway'] as String?)?.toLowerCase() ?? '';
    final parking = (tags['parking'] as String?)?.toLowerCase() ?? '';
    final name = (tags['name'] as String?)?.toLowerCase() ?? '';

    final socialFacility =
        (tags['social_facility'] as String?)?.toLowerCase() ?? '';

    const blockedAmenities = {
      'pharmacy',
      'hospital',
      'clinic',
      'doctors',
      'dentist',
      'veterinary',
      'bank',
      'atm',
      'taxi',
      'taxi_rank',
      'fuel',
      'parking',
      'parking_entrance',
      'parking_space',
      'bus_station',
      'police',
      'fire_station',
      'social_facility',
      'community_centre',
      'ngo',
      'foundation',
      'orphanage',
      'childcare',
      'kindergarten',
    };

    const blockedNameKeywords = {
      'otopark',
      'ispark',
      'i̇spark',
      'vakif',
      'vakıf',
      'vakfi',
      'vakfı',
      'dernek',
      'çocuk yuvası',
      'cocuk yuvasi',
      'çocuk yuvasi',
      'cocuk yuvası',
      'çocuk yuv',
      'cocuk yuv',
      'kreş',
      'kres',
      'kavsak',
      'kavşak',
    };

    if (blockedAmenities.contains(amenity)) return true;
    if (highway == 'motorway_junction' || highway == 'junction') return true;
    if (parking.isNotEmpty) return true;
    if (socialFacility.isNotEmpty) return true;
    if (office == 'ngo' || office == 'association' || office == 'foundation') {
      return true;
    }
    if (blockedNameKeywords.any(name.contains)) return true;
    if (healthcare.isNotEmpty) return true;
    if (shop == 'chemist' || shop == 'pharmacy') return true;
    if (office == 'healthcare') return true;
    if (emergency == 'yes') return true;
    return false;
  }

  static String _categoryLabel(String categoryKey) {
    switch (categoryKey) {
      case 'music':
        return 'Konser';
      case 'cafe':
        return 'Cafe';
      case 'park':
        return 'Park';
      case 'restaurant':
        return 'Restaurant';
      case 'culture':
      default:
        return 'Kultur';
    }
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  Future<List<StoryPreview>> getStories() async {
    if (currentUserListenable.value == null) {
      try {
        await getCurrentUser();
      } catch (_) {}
    }
    final myAvatar =
        _currentUser.hasPhoto ? _currentUser.avatarPath : '';
    final myLabel =
        _currentUser.name.trim().isEmpty ? 'You' : _currentUser.name;

    var ownHasStory = false;
    var ownIsViewed = false;
    String? ownUserId;
    var friendPreviews = <StoryPreview>[];
    try {
      final feed = await _authRepository.fetchStoryFeed();
      final me = feed.me;
      _ensureStoryCachesFor(me.userId);
      ownHasStory = me.hasStory;
      ownIsViewed = me.isViewed;
      ownUserId = me.userId.isEmpty ? null : me.userId;
      if (me.stories.isNotEmpty) {
        _cacheMyStoryItems(
          _mapPublishedStories(
            me.stories,
            label: myLabel,
            avatar: myAvatar.isNotEmpty ? myAvatar : me.avatarUrl,
            username: _currentUser.usernameHandle,
          ),
        );
      } else if (!ownHasStory) {
        _cacheMyStoryItems(const []);
      }
      friendPreviews = _cacheFriendStories(feed.friends);
    } catch (_) {
      // Keep the last known rings on network failure.
      friendPreviews = _lastFriendPreviews;
    }

    final base = [
      StoryPreview(
        name: 'Your story',
        avatarPath: myAvatar,
        isYou: true,
        hasStory: ownHasStory,
        isViewed: ownIsViewed,
        userId: ownUserId,
      ),
      ...friendPreviews,
    ];

    _lastStoryPreviews = List<StoryPreview>.unmodifiable(base);
    return _applyViewedState(base);
  }

  /// Rings straight from local state — avoids waiting on `/stories/feed`
  /// after closing the viewer.
  List<StoryPreview> peekStories() {
    if (_lastStoryPreviews.isEmpty) return const [];
    return _applyViewedState(_lastStoryPreviews);
  }

  List<StoryPreview> _cacheFriendStories(List<StoryFeedUser> friends) {
    _friendStoryItemsByUserId.clear();
    final previews = <StoryPreview>[];
    for (final friend in friends) {
      final items = _mapPublishedStories(
        friend.stories,
        label: friend.displayName,
        avatar: friend.avatarUrl,
        username: friend.username,
      );
      if (items.isEmpty) continue;
      _friendStoryItemsByUserId[friend.userId] = List<StoryMediaItem>
          .unmodifiable(items);
      previews.add(
        StoryPreview(
          name: friend.displayName,
          avatarPath: friend.avatarUrl,
          isViewed: friend.isViewed,
          userId: friend.userId,
        ),
      );
    }
    _lastFriendPreviews = List<StoryPreview>.unmodifiable(previews);
    return _lastFriendPreviews;
  }

  /// Stories of a friend already loaded by the feed — lets the viewer open
  /// without a second round-trip.
  List<StoryMediaItem> peekStoryItemsForUser(String? userId) {
    if (userId == null || userId.isEmpty) return const [];
    final items = _friendStoryItemsByUserId[userId];
    if (items == null) return const [];
    final now = DateTime.now();
    return [
      for (final item in items)
        if (item.expiresAt == null || item.expiresAt!.isAfter(now)) item,
    ];
  }

  /// Fetch (and cache) stories visible to the viewer for a profile avatar tap.
  Future<List<StoryMediaItem>> getStoryItemsForUser(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return const [];

    final cached = peekStoryItemsForUser(id);
    if (cached.isNotEmpty) return cached;

    try {
      final payload = await _authRepository.fetchStoriesByUserId(id);
      final label = payload.name.trim().isNotEmpty
          ? payload.name.trim()
          : (payload.username.trim().isNotEmpty
              ? payload.username.trim()
              : 'User');
      final items = _mapPublishedStories(
        payload.stories,
        label: label,
        avatar: payload.avatarUrl,
        username: payload.username,
      );
      if (items.isNotEmpty) {
        _friendStoryItemsByUserId[id] = List<StoryMediaItem>.unmodifiable(items);
      }
      return items;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getStoryItemsForUser failed for $id: $e');
      }
      return const [];
    }
  }

  List<StoryPreview> _applyViewedState(List<StoryPreview> previews) {
    final ownViewed = _isOwnStoryViewedLocally();
    final withViewed = [
      for (final story in previews)
        story.isYou
            ? story.copyWith(isViewed: story.isViewed || ownViewed)
            : story.copyWith(
                isViewed:
                    story.isViewed ||
                    _isFriendStoryViewedLocally(story.userId) ||
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

  bool _isOwnStoryViewedLocally() {
    if (_cachedMyStoryItems.isEmpty) return false;
    return _cachedMyStoryItems.every(
      (item) => item.isViewed || _viewedStoryIds.contains(item.storyId),
    );
  }

  bool _isFriendStoryViewedLocally(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    final items = _friendStoryItemsByUserId[userId];
    if (items == null || items.isEmpty) return false;
    return items.every(
      (item) => item.isViewed || _viewedStoryIds.contains(item.storyId),
    );
  }

  void markStoryViewed(String avatarPath) {
    if (avatarPath.isEmpty) return;
    _viewedStoryAvatarPaths.add(avatarPath);
  }

  Future<void> markStoryViewedById(String storyId) async {
    final id = storyId.trim();
    if (id.isEmpty) return;
    _viewedStoryIds.add(id);
    _markCachedStoryViewed(id);
    try {
      await _authRepository.markStoryViewedRemote(id);
    } catch (_) {
      // Local ring still updates via markStoryViewed(avatarPath).
    }
  }

  void _markCachedStoryViewed(String storyId) {
    if (_cachedMyStoryItems.isNotEmpty) {
      _cacheMyStoryItems([
        for (final item in _cachedMyStoryItems)
          if (item.storyId == storyId) item.copyWith(isViewed: true) else item,
      ]);
    }

    if (_cachedExploreItems.any((item) => item.storyId == storyId)) {
      _cachedExploreItems = List<StoryMediaItem>.unmodifiable([
        for (final item in _cachedExploreItems)
          if (item.storyId == storyId) item.copyWith(isViewed: true) else item,
      ]);
    }

    for (final entry in _friendStoryItemsByUserId.entries) {
      if (!entry.value.any((item) => item.storyId == storyId)) continue;
      _friendStoryItemsByUserId[entry.key] = List<StoryMediaItem>.unmodifiable([
        for (final item in entry.value)
          if (item.storyId == storyId) item.copyWith(isViewed: true) else item,
      ]);
      break;
    }
  }

  Future<PublishedStory?> toggleStoryLike({
    required String storyId,
    required bool like,
  }) async {
    final id = storyId.trim();
    if (id.isEmpty) return null;
    try {
      final updated = like
          ? await _authRepository.likeStoryRemote(id)
          : await _authRepository.unlikeStoryRemote(id);
      _patchCachedStoryLike(
        storyId: updated.id,
        likedByMe: updated.likedByMe,
        likeCount: updated.likeCount,
      );
      return updated;
    } catch (_) {
      return null;
    }
  }

  void _patchCachedStoryLike({
    required String storyId,
    required bool likedByMe,
    required int likeCount,
  }) {
    List<StoryMediaItem> patch(List<StoryMediaItem> items) => [
      for (final item in items)
        if (item.storyId == storyId)
          item.copyWith(likedByMe: likedByMe, likeCount: likeCount)
        else
          item,
    ];

    if (_cachedMyStoryItems.any((item) => item.storyId == storyId)) {
      _cacheMyStoryItems(patch(_cachedMyStoryItems));
    }

    if (_cachedExploreItems.any((item) => item.storyId == storyId)) {
      _cachedExploreItems = List<StoryMediaItem>.unmodifiable(
        patch(_cachedExploreItems),
      );
    }

    for (final entry in _friendStoryItemsByUserId.entries) {
      if (!entry.value.any((item) => item.storyId == storyId)) continue;
      _friendStoryItemsByUserId[entry.key] = List<StoryMediaItem>.unmodifiable(
        patch(entry.value),
      );
      break;
    }
  }

  Future<List<StoryMediaItem>> getMyActiveStoryItems({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = peekMyActiveStoryItems();
      if (cached.isNotEmpty) return cached;
    }

    final stories = await _authRepository.fetchMyActiveStories();
    final label = _currentUser.name.trim().isEmpty ? 'You' : _currentUser.name;
    final avatar =
        _currentUser.hasPhoto ? _currentUser.avatarPath : '';
    final items = _mapPublishedStories(
      stories,
      label: label,
      avatar: avatar,
      username: _currentUser.usernameHandle,
    );
    _cacheMyStoryItems(items);
    return items;
  }

  Future<PublishedStory> publishStory({
    required String imagePath,
    required String audience,
    String? musicTrackId,
    int? musicClipStartMs,
    int? musicClipDurationMs,
  }) async {
    final created = await _authRepository.publishStory(
      imagePath: imagePath,
      audience: audience,
      musicTrackId: musicTrackId,
      musicClipStartMs: musicClipStartMs,
      musicClipDurationMs: musicClipDurationMs,
    );
    final label = _currentUser.name.trim().isEmpty ? 'You' : _currentUser.name;
    final avatar =
        _currentUser.hasPhoto ? _currentUser.avatarPath : '';
    final mapped = _mapPublishedStories(
      [created],
      label: label,
      avatar: avatar,
      username: _currentUser.usernameHandle,
    );
    // Newest first — prepend published story onto existing cache.
    final merged = [
      ...mapped,
      for (final item in peekMyActiveStoryItems())
        if (item.storyId != created.id) item,
    ];
    _cacheMyStoryItems(merged);
    return created;
  }

  bool isStoryViewed(String avatarPath) =>
      _viewedStoryAvatarPaths.contains(avatarPath);

  /// Explore grid straight from cache — keeps like/viewed edits made in the
  /// viewer without waiting on `/stories/explore`.
  List<StoryMediaItem> peekStoryFeed() {
    final now = DateTime.now();
    return [
      for (final item in _cachedExploreItems)
        if (item.expiresAt == null || item.expiresAt!.isAfter(now)) item,
    ];
  }

  Future<List<StoryMediaItem>> getStoryFeed({
    bool forceRefresh = false,
  }) async {
    try {
      final stories = await _authRepository.fetchExploreStories(
        forceRefresh: forceRefresh,
      );
      final now = DateTime.now();
      final items = [
        for (final story in stories)
          if (story.mediaUrl.isNotEmpty &&
              (story.expiresAt == null || story.expiresAt!.isAfter(now)))
            StoryMediaItem(
              imagePath: story.mediaUrl,
              label: story.displayAuthorName,
              avatarPath: story.authorAvatarUrl ?? '',
              caption: '',
              isReel: false,
              isVerified: false,
              storyId: story.id,
              userId: story.userId,
              username: story.authorUsername,
              musicAudioUrl: story.musicAudioUrl,
              musicTrackId: story.musicTrackId,
              musicClipStartMs: story.musicClipStartMs,
              musicClipDurationMs: story.musicClipDurationMs,
              expiresAt: story.expiresAt,
              likeCount: story.likeCount,
              likedByMe: story.likedByMe,
              isViewed: story.isViewed,
            ),
      ];
      _cacheExploreItems(items);
      return items;
    } catch (_) {
      return peekStoryFeed();
    }
  }

  void _cacheExploreItems(List<StoryMediaItem> items) {
    _cachedExploreItems = List<StoryMediaItem>.unmodifiable(items);
    for (final item in items) {
      if (!item.isNetworkImage) continue;
      NetworkImage(item.imagePath).resolve(ImageConfiguration.empty);
    }
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
    // Check-in media feed is not backed by an API yet — never return mock data.
    return const [];
  }

  Future<List<PulseItem>> getPulses({String? forUsername}) async {
    // Pulses are not backed by an API yet — never return mock data.
    return const [];
  }

  Future<List<StampItem>> getStamps({String? forUsername}) async {
    try {
      if (_isCurrentProfileRequest(forUsername)) {
        final remote = await _authRepository.fetchMyStamps();
        return remote.map(StampItem.fromCatalog).toList();
      }
      final remote = await _authRepository.fetchUserStampsByUsername(
        forUsername!,
      );
      return remote.map(StampItem.fromCatalog).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getStamps failed: $e');
      }
      return const [];
    }
  }

  Future<List<PlanItem>> getTodayPlans({String? forUsername}) async {
    try {
      if (_isCurrentProfileRequest(forUsername)) {
        final remote = await _authRepository.fetchTodayPlans();
        return remote.map(_planItemFromRemote).toList();
      }
      final remote = await _authRepository.fetchUserPlansByUsername(
        forUsername!,
      );
      return remote.map(_planItemFromRemote).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getTodayPlans failed: $e');
      }
      return const [];
    }
  }

  Future<PlanItem> createPlan({
    required String placeName,
    required String subtitle,
    required String category,
    required DateTime scheduledAt,
    required bool showToFriends,
    required bool showToNearby,
    String? note,
  }) async {
    final created = await _authRepository.createPlan(
      placeName: placeName,
      subtitle: subtitle,
      category: category,
      scheduledAt: scheduledAt,
      showToFriends: showToFriends,
      showToNearby: showToNearby,
      note: note,
    );
    return _planItemFromRemote(created);
  }

  PlanItem _planItemFromRemote(UserPlanItem item) {
    final hour = item.scheduledAt.hour.toString().padLeft(2, '0');
    final minute = item.scheduledAt.minute.toString().padLeft(2, '0');
    return PlanItem(
      id: item.id,
      time: '$hour:$minute',
      placeName: item.placeName,
      subtitle: item.subtitle,
      friendAvatars: const [],
      friendsLabel: '0',
      note: item.note,
      showToFriends: item.showToFriends,
      showToNearby: item.showToNearby,
    );
  }

  String _profileKey(String? forUsername) {
    if (forUsername == null || forUsername.trim().isEmpty) return '';
    final value = forUsername.trim();
    return (value.startsWith('@') ? value.substring(1) : value).toLowerCase();
  }

  bool _isCurrentProfileRequest(String? forUsername) {
    if (forUsername == null || forUsername.trim().isEmpty) return true;
    final requested = _profileKey(forUsername);
    final current = _currentUser.usernameHandle.toLowerCase().trim();
    return requested == current;
  }
}
