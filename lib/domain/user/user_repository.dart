import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zovi/core/theme/app_colors.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/domain/auth/auth_repository.dart';

// Domain keeps map marker positions as normalized x/y (-1..1).

@immutable
final class ProfileLink extends Equatable {
  const ProfileLink({required this.title, required this.url});

  final String title;
  final String url;

  String get displayUrl => url
      .replaceFirst(RegExp(r'^https?://'), '')
      .replaceFirst(RegExp(r'/+$'), '');

  @override
  List<Object?> get props => [title, url];
}

@immutable
final class UserProfile extends Equatable {
  const UserProfile({
    required this.name,
    required this.username,
    required this.avatarPath,
    required this.location,
    required this.bio,
    required this.checkIns,
    required this.followers,
    required this.friends,
    this.coins = 0,
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
      followers: (profileMap['followersCount'] as num?)?.toInt() ?? 0,
      friends:
          (profileMap['followingCount'] as num?)?.toInt() ??
          (profileMap['friendsCount'] as num?)?.toInt() ??
          0,
      coins: (profileMap['coins'] as num?)?.toInt() ?? 0,
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
  final int coins;
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
    int? coins,
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
      coins: coins ?? this.coins,
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
    coins,
    accountPrivacy,
    links,
  ];
}

/// Başka kullanıcının profil ekranı için genişletilmiş profil.
@immutable
final class PublicUserProfile extends Equatable {
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
    this.links = const [],
    this.isFollowing = false,
    this.areFriends = false,
    this.isSelf = false,
    this.hasActiveStory = false,
    this.storyIsViewed = false,
    this.isHydrated = true,
    this.isPrivate = false,
    this.relationship = const FollowRelationship(),
    this.blockedByMe = false,
    this.restrictedByMe = false,
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
  final List<ProfileLink> links;
  final bool isFollowing;

  /// Real friendship from API — not flipped by the local "Takip Et" toggle.
  final bool areFriends;
  final bool isSelf;
  final bool hasActiveStory;
  final bool storyIsViewed;

  /// False until the first successful `/users/by-username` response for this user.
  final bool isHydrated;

  /// `accountPrivacy == 'friends'` — following needs an approved request.
  final bool isPrivate;
  final FollowRelationship relationship;

  /// Viewer has blocked this profile (still openable to unblock).
  final bool blockedByMe;

  /// Viewer has restricted this profile (content still visible, demoted in feeds).
  final bool restrictedByMe;

  String get usernameHandle =>
      username.startsWith('@') ? username.substring(1) : username;

  String get usernameWithAt =>
      username.startsWith('@') ? username : '@$username';

  /// Plans / pulses / stamps / check-ins — only if viewer follows owner (or self).
  bool get canSeeFriendContent => isSelf || relationship.following;

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
    bool? isPrivate,
    FollowRelationship? relationship,
    int? followers,
    int? friends,
    String? location,
    String? bio,
    List<ProfileLink>? links,
    bool? blockedByMe,
    bool? restrictedByMe,
  }) {
    return PublicUserProfile(
      userId: userId,
      name: name,
      username: username,
      avatarPath: avatarPath,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      checkIns: checkIns,
      followers: followers ?? this.followers,
      friends: friends ?? this.friends,
      isVerified: isVerified,
      streak: streak,
      explorerTitle: explorerTitle,
      mapPlaceName: mapPlaceName,
      mapDistanceKm: mapDistanceKm,
      mutualFriendsCount: mutualFriendsCount,
      mutualFriendAvatars: mutualFriendAvatars,
      links: links ?? this.links,
      isFollowing: isFollowing ?? this.isFollowing,
      areFriends: areFriends ?? this.areFriends,
      isSelf: isSelf ?? this.isSelf,
      hasActiveStory: hasActiveStory ?? this.hasActiveStory,
      storyIsViewed: storyIsViewed ?? this.storyIsViewed,
      isHydrated: isHydrated ?? this.isHydrated,
      isPrivate: isPrivate ?? this.isPrivate,
      relationship: relationship ?? this.relationship,
      blockedByMe: blockedByMe ?? this.blockedByMe,
      restrictedByMe: restrictedByMe ?? this.restrictedByMe,
    );
  }

  factory PublicUserProfile.fromApi({
    required Map<String, dynamic> profile,
    List<ProfileLink> links = const [],
  }) {
    final username = (profile['username'] as String?)?.trim() ?? '';
    final handle = username.isEmpty
        ? 'user'
        : (username.startsWith('@') ? username.substring(1) : username);
    final avatarUrl = (profile['avatarUrl'] as String?)?.trim() ?? '';
    final relRaw = profile['relationship'];
    final relationship = FollowRelationship.fromJson(
      relRaw is Map ? Map<String, dynamic>.from(relRaw) : null,
    );
    final following = profile['isFollowing'] == true || relationship.following;

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
      followers: (profile['followersCount'] as num?)?.toInt() ?? 0,
      friends:
          (profile['followingCount'] as num?)?.toInt() ??
          (profile['friendsCount'] as num?)?.toInt() ??
          0,
      isVerified: profile['isVerified'] == true,
      streak: (profile['streakCount'] as num?)?.toInt() ?? 0,
      explorerTitle: '',
      mapPlaceName: '',
      mapDistanceKm: '',
      mutualFriendsCount: 0,
      mutualFriendAvatars: const [],
      links: links,
      isFollowing: following,
      areFriends: following,
      isSelf: profile['isSelf'] == true,
      hasActiveStory: profile['hasActiveStory'] == true,
      storyIsViewed: profile['storyIsViewed'] == true,
      isHydrated: true,
      isPrivate:
          (profile['accountPrivacy'] as String?)?.trim().toLowerCase() ==
          'friends',
      relationship: relationship,
      blockedByMe: profile['blockedByMe'] == true,
      restrictedByMe: profile['restrictedByMe'] == true,
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
    links,
    isFollowing,
    areFriends,
    isSelf,
    hasActiveStory,
    storyIsViewed,
    isHydrated,
    relationship.following,
    relationship.followedBy,
    relationship.outgoingRequest,
    relationship.incomingRequest,
    blockedByMe,
    restrictedByMe,
  ];
}

@immutable
final class StoryPreview extends Equatable {
  const StoryPreview({
    required this.name,
    required this.avatarPath,
    this.username,
    this.isYou = false,
    this.hasStory = true,
    this.isViewed = false,
    this.userId,
  });

  final String name;
  final String avatarPath;
  final String? username;
  final bool isYou;
  final bool hasStory;
  final bool isViewed;
  final String? userId;

  String get storyLabel {
    final handle = (username ?? '').trim();
    if (handle.isEmpty) return name;
    return handle.startsWith('@') ? handle.substring(1) : handle;
  }

  StoryPreview copyWith({
    String? name,
    String? avatarPath,
    String? username,
    bool? isYou,
    bool? hasStory,
    bool? isViewed,
    String? userId,
  }) {
    return StoryPreview(
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      username: username ?? this.username,
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
    username,
    isYou,
    hasStory,
    isViewed,
    userId,
  ];
}

@immutable
final class StoryMediaItem extends Equatable {
  const StoryMediaItem({
    required this.imagePath,
    required this.label,
    required this.avatarPath,
    this.thumbnailPath,
    this.caption = '',
    this.isReel = false,
    this.isVerified = true,
    this.storyId,
    this.userId,
    this.username,
    this.musicAudioUrl,
    this.musicTrackId,
    this.musicTitle,
    this.musicArtist,
    this.musicCoverUrl,
    this.musicClipStartMs,
    this.musicClipDurationMs,
    this.expiresAt,
    this.likeCount = 0,
    this.likedByMe = false,
    this.isViewed = false,
    this.isPulse = false,
    this.isVideo = false,
  });

  final String imagePath;
  final String label;
  final String avatarPath;
  final String? thumbnailPath;
  final String caption;
  final bool isReel;
  final bool isVerified;
  final String? storyId;
  final String? userId;

  /// Handle for profile navigation — [label] is a display name, not a username.
  final String? username;

  String get storyLabel {
    final handle = (username ?? '').trim();
    if (handle.isEmpty) return label;
    return handle.startsWith('@') ? handle.substring(1) : handle;
  }
  final String? musicAudioUrl;
  final String? musicTrackId;
  final String? musicTitle;
  final String? musicArtist;
  final String? musicCoverUrl;
  final int? musicClipStartMs;
  final int? musicClipDurationMs;
  final DateTime? expiresAt;
  final int likeCount;
  final bool likedByMe;
  final bool isViewed;
  final bool isPulse;
  final bool isVideo;

  bool get isNetworkImage =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  /// Grid tile URL — prefers API thumbnail when available.
  String get gridImagePath {
    final thumb = thumbnailPath?.trim() ?? '';
    if (thumb.isNotEmpty) return thumb;
    return imagePath;
  }

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
    String? thumbnailPath,
    String? caption,
    bool? isReel,
    bool? isVerified,
    String? storyId,
    String? userId,
    String? username,
    String? musicAudioUrl,
    String? musicTrackId,
    String? musicTitle,
    String? musicArtist,
    String? musicCoverUrl,
    int? musicClipStartMs,
    int? musicClipDurationMs,
    DateTime? expiresAt,
    int? likeCount,
    bool? likedByMe,
    bool? isViewed,
    bool? isPulse,
    bool? isVideo,
  }) {
    return StoryMediaItem(
      imagePath: imagePath ?? this.imagePath,
      label: label ?? this.label,
      avatarPath: avatarPath ?? this.avatarPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      caption: caption ?? this.caption,
      isReel: isReel ?? this.isReel,
      isVerified: isVerified ?? this.isVerified,
      storyId: storyId ?? this.storyId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      musicAudioUrl: musicAudioUrl ?? this.musicAudioUrl,
      musicTrackId: musicTrackId ?? this.musicTrackId,
      musicTitle: musicTitle ?? this.musicTitle,
      musicArtist: musicArtist ?? this.musicArtist,
      musicCoverUrl: musicCoverUrl ?? this.musicCoverUrl,
      musicClipStartMs: musicClipStartMs ?? this.musicClipStartMs,
      musicClipDurationMs: musicClipDurationMs ?? this.musicClipDurationMs,
      expiresAt: expiresAt ?? this.expiresAt,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      isViewed: isViewed ?? this.isViewed,
      isPulse: isPulse ?? this.isPulse,
      isVideo: isVideo ?? this.isVideo,
    );
  }

  @override
  List<Object?> get props => [
    imagePath,
    label,
    avatarPath,
    thumbnailPath,
    caption,
    isReel,
    isVerified,
    storyId,
    userId,
    username,
    musicAudioUrl,
    musicTrackId,
    musicTitle,
    musicArtist,
    musicCoverUrl,
    musicClipStartMs,
    musicClipDurationMs,
    expiresAt,
    likeCount,
    likedByMe,
    isViewed,
    isPulse,
    isVideo,
  ];
}

@immutable
final class MapFriend extends Equatable {
  const MapFriend({
    required this.name,
    required this.avatarPath,
    required this.streak,
    required this.lat,
    required this.lng,
    this.userId = '',
    this.username = '',
    this.isFriend = true,
    this.distanceMeters,
    this.locationLabel,
    this.etaMinutes,
    this.checkIn,
    this.x = 0,
    this.y = 0,
  });

  factory MapFriend.fromMapPresence(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble() ?? 0;
    final lng = (json['lng'] as num?)?.toDouble() ?? 0;
    final distance = (json['distanceMeters'] as num?)?.toInt();
    final name = (json['fullName'] as String?)?.trim().isNotEmpty == true
        ? (json['fullName'] as String).trim()
        : ((json['username'] as String?)?.trim() ?? 'user');
    final username = (json['username'] as String?)?.trim() ?? '';
    final isAnon = json['isAnonymous'] == true;
    final isFriend =
        json['isFriend'] == true || (json['isFriend'] == null && !isAnon);
    final rawCheckIn = json['activeCheckIn'];
    FriendMapCheckIn? checkIn;
    if (rawCheckIn is Map) {
      final map = Map<String, dynamic>.from(rawCheckIn);
      final photosRaw = map['photoUrls'];
      final photos = <String>[
        if (photosRaw is List)
          for (final p in photosRaw)
            if ('$p'.trim().isNotEmpty) '$p'.trim(),
      ];
      final place = (map['placeName'] as String?)?.trim() ?? '';
      final title = (map['titleLabel'] as String?)?.trim();
      final stampSlug = (map['stampSlug'] as String?)?.trim();
      final checkedAt = DateTime.tryParse(
        '${map['checkedAt'] ?? ''}',
      )?.toLocal();
      final isFresh =
          checkedAt == null ||
          DateTime.now().difference(checkedAt) <= const Duration(hours: 24);
      if (!isFresh) {
        checkIn = null;
      } else {
        checkIn = FriendMapCheckIn(
          placeName: place,
          photoPaths: photos,
          stampImagePath: stampSlug == 'founder'
              ? AssetPaths.stamp16
              : AssetPaths.stamp1,
          checkedAt: checkedAt,
          titleLabel: (title != null && title.isNotEmpty) ? title : null,
        );
      }
    }
    return MapFriend(
      userId: (json['userId'] as String?)?.trim() ?? '',
      username: username,
      name: isAnon ? 'Anonim' : name,
      avatarPath: (json['avatarUrl'] as String?)?.trim() ?? '',
      streak: (json['streakCount'] as num?)?.toInt() ?? 0,
      lat: lat,
      lng: lng,
      isFriend: isFriend,
      distanceMeters: distance,
      locationLabel: (json['locationText'] as String?)?.trim(),
      etaMinutes: distance == null
          ? null
          : (distance / 80).round().clamp(1, 180),
      checkIn: checkIn,
    );
  }

  final String userId;
  final String username;
  final String name;
  final String avatarPath;
  final int streak;
  final double lat;
  final double lng;
  final bool isFriend;
  final int? distanceMeters;
  final String? locationLabel;
  final int? etaMinutes;
  final FriendMapCheckIn? checkIn;

  /// Legacy relative offsets — unused when [lat]/[lng] are set.
  final double x;
  final double y;

  bool get hasCheckIn => checkIn != null;

  /// Map / story-row label — username, falling back to display name.
  String get mapLabel {
    if (name == 'Anonim') return name;
    final handle = username.trim();
    if (handle.isEmpty) return name;
    return handle.startsWith('@') ? handle.substring(1) : handle;
  }

  String get profileHandle {
    if (username.isEmpty) return name;
    return username.startsWith('@') ? username : '@$username';
  }

  MapFriend copyWith({
    String? userId,
    String? username,
    String? name,
    String? avatarPath,
    int? streak,
    double? lat,
    double? lng,
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
      userId: userId ?? this.userId,
      username: username ?? this.username,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      streak: streak ?? this.streak,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
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
    userId,
    username,
    name,
    avatarPath,
    streak,
    lat,
    lng,
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
@immutable
final class FriendMapCheckIn extends Equatable {
  const FriendMapCheckIn({
    required this.photoPaths,
    required this.stampImagePath,
    required this.placeName,
    this.checkedAt,
    this.titleLabel,
  });

  final List<String> photoPaths;
  final String stampImagePath;
  final String placeName;
  final DateTime? checkedAt;
  final String? titleLabel;

  bool get hasTitle => titleLabel != null && titleLabel!.trim().isNotEmpty;

  @override
  List<Object?> get props => [
    photoPaths,
    stampImagePath,
    placeName,
    checkedAt,
    titleLabel,
  ];
}

@immutable
final class MapVenue extends Equatable {
  const MapVenue({
    required this.name,
    required this.peopleCount,
    required this.lat,
    required this.lng,
    this.photoPath,
    this.x = 0,
    this.y = 0,
  });

  final String name;
  final int peopleCount;
  final double lat;
  final double lng;
  final String? photoPath;
  final double x;
  final double y;

  @override
  List<Object?> get props => [name, peopleCount, lat, lng, photoPath, x, y];
}

@immutable
final class CheckInItem extends Equatable {
  const CheckInItem({
    required this.placeName,
    required this.when,
    required this.imagePath,
    this.id = '',
    this.accentColor = AppColors.locationBlue,
  });

  factory CheckInItem.fromJson(Map<String, dynamic> json, {int index = 0}) {
    final checkedAt = DateTime.tryParse(
      '${json['checkedAt'] ?? ''}',
    )?.toLocal();
    final photos = json['photoUrls'];
    var imagePath = '';
    if (photos is List) {
      for (final p in photos) {
        final url = '$p'.trim();
        if (url.isNotEmpty) {
          imagePath = url;
          break;
        }
      }
    }
    final id = (json['id'] as String?)?.trim() ?? '';
    return CheckInItem(
      id: id,
      placeName: (json['placeName'] as String?)?.trim() ?? '',
      when: checkedAt != null ? _formatCheckInWhen(checkedAt) : '',
      imagePath: imagePath,
      accentColor: _checkInAccentColor(id: id, index: index),
    );
  }

  final String id;
  final String placeName;
  final String when;
  final String imagePath;
  final Color accentColor;

  bool get hasPhoto => imagePath.trim().isNotEmpty;

  bool get isNetwork =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  @override
  List<Object?> get props => [id, placeName, when, imagePath, accentColor];
}

/// Soft tint behind the check-in thumb — rotates per item.
Color _checkInAccentColor({required String id, required int index}) {
  const palette = <Color>[
    Color(0x1A448AFF), // blue @ 10%
    Color(0x1AFF5C1A), // orange @ 10%
    Color(0x1A34C759), // green @ 10%
    Color(0x1AAF52DE), // purple @ 10%
    Color(0x1A00C7BE), // teal @ 10%
    Color(0x1AFFCC00), // yellow @ 10%
  ];
  if (id.isNotEmpty) {
    return palette[id.hashCode.abs() % palette.length];
  }
  return palette[index % palette.length];
}

String _formatCheckInWhen(DateTime at) {
  final local = at.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final time = _formatCheckInClock(local);

  if (day == today) return 'Bugün · $time';
  if (day == today.subtract(const Duration(days: 1))) return 'Dün · $time';
  return '${day.day}.${day.month}.${day.year} · $time';
}

String _formatCheckInClock(DateTime at) {
  final hour24 = at.hour;
  final minute = at.minute.toString().padLeft(2, '0');
  final isPm = hour24 >= 12;
  var hour12 = hour24 % 12;
  if (hour12 == 0) hour12 = 12;
  return '$hour12:$minute${isPm ? 'pm' : 'am'}';
}

@immutable
final class PulseItem extends Equatable {
  const PulseItem({
    required this.imagePath,
    this.id = '',
    this.time = '',
    this.placeName = '',
    this.subtitle = '',
    this.friendAvatars = const [],
    this.friendsLabel = '',
    this.sourceType = '',
    this.mediaType = 'image',
    this.createdAt,
  });

  factory PulseItem.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(
      '${json['createdAt'] ?? ''}',
    )?.toLocal();
    final place = (json['placeName'] as String?)?.trim() ?? '';
    final caption = (json['caption'] as String?)?.trim() ?? '';
    return PulseItem(
      id: (json['id'] as String?)?.trim() ?? '',
      imagePath: (json['mediaUrl'] as String?)?.trim() ?? '',
      time: createdAt != null ? _formatPulseTime(createdAt) : '',
      placeName: place,
      subtitle: caption,
      sourceType: (json['sourceType'] as String?)?.trim() ?? '',
      mediaType: (json['mediaType'] as String?)?.trim().isNotEmpty == true
          ? (json['mediaType'] as String).trim()
          : 'image',
      createdAt: createdAt,
    );
  }

  final String id;
  final String imagePath;
  final String time;
  final String placeName;
  final String subtitle;
  final List<String> friendAvatars;
  final String friendsLabel;
  final String sourceType;
  final String mediaType;
  final DateTime? createdAt;

  bool get isVideo => mediaType.toLowerCase() == 'video';

  bool get isNetwork =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  bool get isFilePath =>
      imagePath.startsWith('/') || imagePath.startsWith('file:');

  @override
  List<Object?> get props => [
    id,
    imagePath,
    time,
    placeName,
    subtitle,
    friendAvatars,
    friendsLabel,
    sourceType,
    mediaType,
    createdAt,
  ];
}

String _formatPulseTime(DateTime at) {
  final now = DateTime.now();
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${at.day}.${at.month}.${at.year}';
}

@immutable
final class StampItem extends Equatable {
  const StampItem({required this.imagePath, required this.title, this.id = ''});

  factory StampItem.fromCatalog(StampCatalogItem item) {
    return StampItem(id: item.id, imagePath: item.imageUrl, title: item.name);
  }

  final String id;
  final String imagePath;
  final String title;

  bool get isNetwork =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  @override
  List<Object?> get props => [id, imagePath, title];
}

@immutable
final class ActiveMapCheckIn extends Equatable {
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

  String get photoPath => photoPaths.isNotEmpty ? photoPaths.first : '';

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

@immutable
final class PlanItem extends Equatable {
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

  bool get hasJoiningFriends =>
      friendAvatars.isNotEmpty || (int.tryParse(friendsLabel.trim()) ?? 0) > 0;

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

/// Cached public-profile tabs (plans / pulse / stamps / check-in).
@immutable
final class FriendProfileSections {
  const FriendProfileSections({
    required this.plans,
    required this.pulses,
    required this.stamps,
    required this.checkIns,
  });

  final List<PlanItem> plans;
  final List<PulseItem> pulses;
  final List<StampItem> stamps;
  final List<CheckInItem> checkIns;
}

@immutable
final class NearbyAddPlanPlace extends Equatable {
  const NearbyAddPlanPlace({
    required this.categoryKey,
    required this.placeName,
    required this.subtitle,
    required this.distanceLabel,
    required this.friendAvatars,
    required this.friendsLabel,
    this.lat = 0,
    this.lng = 0,
  });

  final String categoryKey;
  final String placeName;
  final String subtitle;
  final String distanceLabel;
  final List<String> friendAvatars;
  final String friendsLabel;
  final double lat;
  final double lng;

  bool get hasJoiningFriends =>
      friendAvatars.isNotEmpty || (int.tryParse(friendsLabel.trim()) ?? 0) > 0;

  NearbyAddPlanPlace withJoiningFriends({
    required List<String> friendAvatars,
    required String friendsLabel,
  }) {
    return NearbyAddPlanPlace(
      categoryKey: categoryKey,
      placeName: placeName,
      subtitle: subtitle,
      distanceLabel: distanceLabel,
      friendAvatars: friendAvatars,
      friendsLabel: friendsLabel,
      lat: lat,
      lng: lng,
    );
  }

  @override
  List<Object?> get props => [
    categoryKey,
    placeName,
    subtitle,
    distanceLabel,
    friendAvatars,
    friendsLabel,
    lat,
    lng,
  ];
}

final class UserRepository {
  UserRepository(this._authRepository);

  final AuthRepository _authRepository;
  static const int _nearbyPlacesDisplayLimit = 40;
  static const double _nearbyPlacesSearchRadiusMeters = 3000;
  static const double _nearbyPlacesRefreshDistanceMeters = 400;
  static const Duration _nearbyPlacesMaxCacheAge = Duration(minutes: 30);
  static const Duration _mapVenuesMaxCacheAge = Duration(minutes: 12);
  List<NearbyAddPlanPlace> _nearbyAddPlanPlacesCache = const [];
  Position? _nearbyAddPlanPlacesCachePosition;
  DateTime? _nearbyAddPlanPlacesCachedAt;
  Future<List<NearbyAddPlanPlace>>? _nearbyAddPlanPlacesInFlight;
  Map<String, FriendJoiningPlace> _friendJoiningByPlace = const {};
  Future<Map<String, FriendJoiningPlace>>? _friendJoiningInFlight;
  final Map<String, ({DateTime at, List<MapVenue> items})> _mapVenuesCache = {};
  final Map<String, Future<List<MapVenue>>> _mapVenuesInFlight = {};

  UserProfile _currentUser = const UserProfile(
    name: '',
    username: '@',
    avatarPath: '',
    location: '',
    bio: '',
    checkIns: 0,
    followers: 0,
    friends: 0,
    coins: 0,
    accountPrivacy: 'public',
    links: [],
  );

  bool _profileHydrated = false;
  Future<UserProfile>? _profileInFlight;
  DateTime? _homeBootstrapAt;

  /// Navbar / diğer yerler profil avatarını dinleyebilir.
  final currentUserListenable = ValueNotifier<UserProfile?>(null);

  /// Splash [warmHomeBootstrap] az önce bittiyse home soft-refresh atlanabilir.
  bool get isHomeBootstrapFresh {
    final at = _homeBootstrapAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < const Duration(seconds: 8);
  }

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

  /// Prefetch own pulses so the profile Pulse tab paints from cache.
  void warmMyPulsesCache() {
    unawaited(getPulses().catchError((_) => const <PulseItem>[]));
  }

  /// Splash sonrası home shimmer olmasın diye kritik feed'i burada ısıt.
  /// Profil + stories + map friends paralel; [getCurrentUser] in-flight paylaşılır.
  Future<void> warmHomeBootstrap() async {
    await Future.wait<void>([
      getCurrentUser().then((_) {}, onError: (_) {}),
      getStories().then((_) {}, onError: (_) {}),
      getMapFriends().then((_) {}, onError: (_) {}),
      restoreActiveMapCheckIn().then((_) {}, onError: (_) {}),
    ]);

    _homeBootstrapAt = DateTime.now();
    warmStampCaches();
    warmMyPulsesCache();
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
    _profileInFlight = null;
    _homeBootstrapAt = null;
    _currentUser = const UserProfile(
      name: '',
      username: '@',
      avatarPath: '',
      location: '',
      bio: '',
      checkIns: 0,
      followers: 0,
      friends: 0,
      coins: 0,
      accountPrivacy: 'public',
      links: [],
    );
    currentUserListenable.value = null;

    _sessionUserId = null;
    _clearStoryCaches();
    _clearProfileSectionCaches();
    _publicProfileCache.clear();

    _activeMapCheckIn = null;
    activeMapCheckInListenable.value = null;
    mapFriendsListenable.value = const [];
    checkInPhotoIndexListenable.value = 0;

    _nearbyAddPlanPlacesCache = const [];
    _nearbyAddPlanPlacesCachePosition = null;
    _nearbyAddPlanPlacesCachedAt = null;
    _nearbyAddPlanPlacesInFlight = null;
    _mapVenuesCache.clear();
    _mapVenuesInFlight.clear();

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
  DateTime? _storyFeedFetchedAt;
  static const _storyFeedTtl = Duration(seconds: 90);
  String? _sessionUserId;

  List<PulseItem> _cachedMyPulses = const [];
  var _myPulsesFetched = false;
  final _friendSectionsCache = <String, FriendProfileSections>{};
  List<Map<String, dynamic>>? _friendshipStreaksCache;

  void _clearProfileSectionCaches() {
    _cachedMyPulses = const [];
    _myPulsesFetched = false;
    _friendSectionsCache.clear();
    _friendshipStreaksCache = null;
  }

  List<PulseItem> peekMyPulses() => _cachedMyPulses;

  bool get hasFetchedMyPulses => _myPulsesFetched;

  FriendProfileSections? peekFriendSections(String username) {
    final key = _profileKey(username);
    if (key.isEmpty) return null;
    return _friendSectionsCache[key];
  }

  void cacheFriendSections(
    String username, {
    required List<PlanItem> plans,
    required List<PulseItem> pulses,
    required List<StampItem> stamps,
    required List<CheckInItem> checkIns,
  }) {
    final key = _profileKey(username);
    if (key.isEmpty) return;
    _friendSectionsCache[key] = FriendProfileSections(
      plans: List<PlanItem>.unmodifiable(plans),
      pulses: List<PulseItem>.unmodifiable(pulses),
      stamps: List<StampItem>.unmodifiable(stamps),
      checkIns: List<CheckInItem>.unmodifiable(checkIns),
    );
    for (final pulse in pulses) {
      if (!pulse.isNetwork) continue;
      NetworkImage(pulse.imagePath).resolve(ImageConfiguration.empty);
    }
  }

  void forgetFriendSections(String username) {
    final key = _profileKey(username);
    if (key.isEmpty) return;
    _friendSectionsCache.remove(key);
  }

  void _cacheMyPulses(List<PulseItem> items) {
    _cachedMyPulses = List<PulseItem>.unmodifiable(items);
    _myPulsesFetched = true;
    for (final pulse in items) {
      if (!pulse.isNetwork) continue;
      NetworkImage(pulse.imagePath).resolve(ImageConfiguration.empty);
    }
  }

  void prependMyPulse(PulseItem pulse) {
    if (pulse.imagePath.trim().isEmpty) return;
    _cacheMyPulses([
      pulse,
      for (final existing in _cachedMyPulses)
        if (existing.id.isEmpty || existing.id != pulse.id) existing,
    ]);
  }

  void _clearStoryCaches() {
    _cachedMyStoryItems = const [];
    _cachedExploreItems = const [];
    _friendStoryItemsByUserId.clear();
    _lastStoryPreviews = const [];
    _lastFriendPreviews = const [];
    _viewedStoryIds.clear();
    _viewedStoryAvatarPaths.clear();
    _storyFeedFetchedAt = null;
  }

  /// Drop a blocked user from local story/map caches immediately.
  void purgeUserFromSocialFeeds(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return;

    _friendStoryItemsByUserId.remove(id);
    _lastFriendPreviews = List<StoryPreview>.unmodifiable([
      for (final p in _lastFriendPreviews)
        if (p.userId != id) p,
    ]);
    _lastStoryPreviews = List<StoryPreview>.unmodifiable([
      for (final p in _lastStoryPreviews)
        if (p.userId != id) p,
    ]);
    _cachedExploreItems = List<StoryMediaItem>.unmodifiable([
      for (final item in _cachedExploreItems)
        if ((item.userId ?? '') != id) item,
    ]);
    mapFriendsListenable.value = [
      for (final f in mapFriendsListenable.value)
        if (f.userId != id) f,
    ];
    // Stale hydrated profiles would still show follow/content until refetch.
    _friendSectionsCache.removeWhere((key, _) {
      final profile = _publicProfileCache[key];
      return profile?.userId == id;
    });
    _publicProfileCache.removeWhere((_, profile) => profile.userId == id);
  }

  /// Safety net for the case where a logout did not run its cleanup: if the
  /// feed comes back for a different account, drop what we held.
  void _ensureStoryCachesFor(String userId) {
    if (userId.isEmpty || _sessionUserId == userId) return;
    if (_sessionUserId != null) {
      _clearStoryCaches();
      _clearProfileSectionCaches();
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
            thumbnailPath: story.thumbnailUrl,
            label: label,
            avatarPath: avatar,
            caption: '',
            isReel: story.isVideo,
            isVideo: story.isVideo,
            isVerified: false,
            storyId: story.id,
            userId: story.userId,
            username: handle != null && handle.isNotEmpty
                ? handle
                : story.authorUsername,
            musicAudioUrl: story.musicAudioUrl,
            musicTrackId: story.musicTrackId,
            musicTitle: story.musicTitle,
            musicArtist: story.musicArtist,
            musicCoverUrl: story.musicCoverUrl,
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
      if (item.isVideo) continue;
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
  ValueListenable<int> friendCheckInPhotoIndexListenable(String key) {
    return _friendPhotoIndexes.putIfAbsent(key, () => ValueNotifier<int>(0));
  }

  void setActiveMapCheckIn(ActiveMapCheckIn? checkIn) {
    _activeMapCheckIn = checkIn;
    activeMapCheckInListenable.value = checkIn;
    _restartCheckInPhotoCycle(checkIn);
    if (checkIn != null) {
      recordCheckInCompleted();
    }
  }

  /// İlk check-in intro sheet’inin bir daha çıkmaması için lokal sayaç.
  void recordCheckInCompleted({int? checkInsCount}) {
    if (checkInsCount != null) {
      if (checkInsCount <= _currentUser.checkIns) return;
      _currentUser = _currentUser.copyWith(checkIns: checkInsCount);
      currentUserListenable.value = _currentUser;
      return;
    }
    if (_currentUser.checkIns > 0) return;
    _currentUser = _currentUser.copyWith(checkIns: 1);
    currentUserListenable.value = _currentUser;
  }

  Future<Map<String, dynamic>> submitCheckIn({
    required String placeName,
    required double lat,
    required double lng,
    String? caption,
    String photoPrivacy = 'public',
    List<String> taggedUserIds = const [],
    List<String> photoUrls = const [],
    String? category,
    String? locale,
  }) async {
    final result = await _authRepository.submitCheckIn(
      placeName: placeName,
      lat: lat,
      lng: lng,
      caption: caption,
      photoPrivacy: photoPrivacy,
      taggedUserIds: taggedUserIds,
      photoUrls: photoUrls,
      category: category,
      locale: locale,
    );
    invalidateFriendshipStreaks();
    recordCheckInCompleted(checkInsCount: _currentUser.checkIns + 1);
    _applyCoinsBalance(result['coinsBalance']);
    return result;
  }

  Future<Map<String, dynamic>> acceptFounderReward(String checkInId) {
    return _authRepository.acceptFounderReward(checkInId);
  }

  Future<Map<String, dynamic>> acceptStampOffer(String checkInId) async {
    final result = await _authRepository.acceptStampOffer(checkInId);
    _applyCoinsBalance(result['coinsBalance']);
    return result;
  }

  Future<void> revealProfileViewer(String viewerUserId) async {
    final result = await _authRepository.revealProfileViewer(viewerUserId);
    _applyCoinsBalance(result?['coinsBalance']);
  }

  Future<int> revealAllProfileViewers() async {
    final result = await _authRepository.revealAllProfileViewers();
    _applyCoinsBalance(result?['coinsBalance']);
    return (result?['revealedCount'] as num?)?.toInt() ?? 0;
  }

  void _applyCoinsBalance(Object? raw) {
    final coins = (raw as num?)?.toInt();
    if (coins == null || coins == _currentUser.coins) return;
    _currentUser = _currentUser.copyWith(coins: coins);
    currentUserListenable.value = _currentUser;
  }

  Future<List<Map<String, dynamic>>> fetchFriendshipStreaks({
    int limit = 50,
  }) async {
    final rows = await _authRepository.fetchFriendshipStreaks(limit: limit);
    _friendshipStreaksCache = [
      for (final row in rows) Map<String, dynamic>.from(row),
    ];
    return _friendshipStreaksCache!;
  }

  List<Map<String, dynamic>>? peekFriendshipStreaks() {
    final cached = _friendshipStreaksCache;
    if (cached == null) return null;
    return [for (final row in cached) Map<String, dynamic>.from(row)];
  }

  void invalidateFriendshipStreaks() {
    _friendshipStreaksCache = null;
  }

  /// App cold-start: restore self check-in marker from API.
  Future<ActiveMapCheckIn?> restoreActiveMapCheckIn() async {
    try {
      final raw = await _authRepository.fetchActiveCheckIn();
      if (raw == null) {
        if (_activeMapCheckIn != null) {
          setActiveMapCheckIn(null);
        }
        return null;
      }
      final photosRaw = raw['photoUrls'];
      final photos = <String>[
        if (photosRaw is List)
          for (final p in photosRaw)
            if ('$p'.trim().isNotEmpty) '$p'.trim(),
      ];
      final place = (raw['placeName'] as String?)?.trim() ?? '';
      final stampSlug = (raw['stampSlug'] as String?)?.trim();
      final stampImageUrl = (raw['stampImageUrl'] as String?)?.trim();
      final title = (raw['titleLabel'] as String?)?.trim();
      final checkedAt = DateTime.tryParse(
        '${raw['checkedAt'] ?? ''}',
      )?.toLocal();
      if (checkedAt != null &&
          DateTime.now().difference(checkedAt) > const Duration(hours: 24)) {
        if (_activeMapCheckIn != null) {
          setActiveMapCheckIn(null);
        }
        return null;
      }
      final avatar = _currentUser.hasPhoto ? _currentUser.avatarPath : '';
      final restored = ActiveMapCheckIn(
        stampImagePath: (stampImageUrl != null && stampImageUrl.isNotEmpty)
            ? stampImageUrl
            : stampSlug == 'founder'
            ? AssetPaths.stamp16
            : AssetPaths.stamp1,
        photoPaths: photos,
        placeName: place.isNotEmpty ? place : 'check_in_venue_empty',
        checkedAt: checkedAt ?? DateTime.now(),
        titleLabel: (title != null && title.isNotEmpty) ? title : null,
        avatarPath: avatar,
      );
      setActiveMapCheckIn(restored);
      return restored;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('restoreActiveMapCheckIn failed: $e');
      }
      return _activeMapCheckIn;
    }
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
    final activeKeys = <String>{};
    for (final friend in friends) {
      final checkIn = friend.checkIn;
      if (checkIn == null) continue;
      final key = friend.userId.isNotEmpty ? friend.userId : friend.name;
      activeKeys.add(key);
      _restartFriendPhotoCycle(key, checkIn.photoPaths);
    }
    for (final key in _friendPhotoTimers.keys.toList()) {
      if (activeKeys.contains(key)) continue;
      _friendPhotoTimers.remove(key)?.cancel();
      _friendPhotoIndexes[key]?.value = 0;
    }
  }

  void _restartFriendPhotoCycle(String key, List<String> photoPaths) {
    _friendPhotoTimers.remove(key)?.cancel();
    final index = _friendPhotoIndexes.putIfAbsent(
      key,
      () => ValueNotifier<int>(0),
    );
    index.value = 0;
    if (photoPaths.length < 2) return;
    _friendPhotoTimers[key] = Timer.periodic(const Duration(seconds: 5), (_) {
      MapFriend? friend;
      for (final f in mapFriendsListenable.value) {
        final fKey = f.userId.isNotEmpty ? f.userId : f.name;
        if (fKey == key) {
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
    final inFlight = _profileInFlight;
    if (inFlight != null) return inFlight;

    final future = () async {
      final payload = await _authRepository.fetchMyProfilePayload();
      _currentUser = UserProfile.fromAuthMe(payload);
      _profileHydrated = true;
      currentUserListenable.value = _currentUser;
      return _currentUser;
    }();

    _profileInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_profileInFlight, future)) {
        _profileInFlight = null;
      }
    }
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
        followers: (profile['followersCount'] as num?)?.toInt(),
        friends:
            (profile['followingCount'] as num?)?.toInt() ??
            (profile['friendsCount'] as num?)?.toInt(),
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
    final handle = username.startsWith('@')
        ? username.substring(1)
        : username.trim();
    final nameChanged = name.trim() != _currentUser.name.trim();
    final usernameChanged =
        handle.toLowerCase() != _currentUser.usernameHandle.toLowerCase();
    final bioChanged = saveBio && bio.trim() != _currentUser.bio.trim();
    final linksChanged = !_sameLinks(links, _currentUser.links);
    final avatarDirty =
        localAvatarPath != null &&
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
    final links = <ProfileLink>[];
    final rawLinks = payload['links'];
    if (rawLinks is List) {
      for (final item in rawLinks) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final title = (map['title'] as String?)?.trim() ?? '';
        final url = (map['url'] as String?)?.trim() ?? '';
        if (url.isEmpty) continue;
        links.add(ProfileLink(title: title, url: url));
      }
    }
    final profile = PublicUserProfile.fromApi(
      profile: Map<String, dynamic>.from(profileRaw),
      links: links,
    );
    _publicProfileCache[key] = profile;
    return profile;
  }

  /// Persists the device's current place label so other users can see it as
  /// text on the public profile. No-ops when unchanged.
  Future<void> syncLiveLocationLabel(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    final capped = trimmed.length > 120 ? trimmed.substring(0, 120) : trimmed;
    if (capped == _currentUser.location.trim()) return;
    try {
      await _authRepository.saveProfile(locationText: capped);
      _currentUser = _currentUser.copyWith(location: capped);
      currentUserListenable.value = _currentUser;
    } catch (_) {
      // Offline — keep the local label; next open retries.
    }
  }

  Future<void> updateCurrentUser(UserProfile user) async {
    _currentUser = user;
    _profileHydrated = true;
    currentUserListenable.value = user;
  }

  /// Sync peek — Plan Ekle / check-in sheet can paint immediately.
  List<NearbyAddPlanPlace> peekNearbyAddPlanPlaces({int limit = 40}) {
    if (_nearbyAddPlanPlacesCache.isEmpty) return const [];
    final safeLimit = limit.clamp(1, _nearbyPlacesDisplayLimit);
    return _applyFriendJoiningSync(
      _nearbyAddPlanPlacesCache.take(safeLimit).toList(growable: false),
    );
  }

  bool _isNearbyCacheFresh({Position? position}) {
    final cachedAt = _nearbyAddPlanPlacesCachedAt;
    if (_nearbyAddPlanPlacesCache.isEmpty || cachedAt == null) return false;
    if (DateTime.now().difference(cachedAt) >= _nearbyPlacesMaxCacheAge) {
      return false;
    }
    final cachedPosition = _nearbyAddPlanPlacesCachePosition;
    if (position == null || cachedPosition == null) return true;
    final movedMeters = Geolocator.distanceBetween(
      cachedPosition.latitude,
      cachedPosition.longitude,
      position.latitude,
      position.longitude,
    );
    return movedMeters < _nearbyPlacesRefreshDistanceMeters;
  }

  Future<List<NearbyAddPlanPlace>> getNearbyAddPlanPlaces({
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final safeLimit = limit.clamp(1, _nearbyPlacesDisplayLimit);

    // Fast path: valid cache, no GPS / Places call.
    if (!forceRefresh && _isNearbyCacheFresh()) {
      return _withFriendJoining(
        _nearbyAddPlanPlacesCache.take(safeLimit).toList(),
      );
    }

    // Dedupe parallel callers (Plan Ekle firstBatch + remaining, check-in…).
    final inFlight = _nearbyAddPlanPlacesInFlight;
    if (inFlight != null) {
      final shared = await inFlight;
      return _withFriendJoining(shared.take(safeLimit).toList());
    }

    final future = _fetchNearbyAddPlanPlaces(
      safeLimit: safeLimit,
      forceRefresh: forceRefresh,
    );
    _nearbyAddPlanPlacesInFlight = future;
    try {
      final places = await future;
      return _withFriendJoining(places);
    } finally {
      if (identical(_nearbyAddPlanPlacesInFlight, future)) {
        _nearbyAddPlanPlacesInFlight = null;
      }
    }
  }

  Future<List<NearbyAddPlanPlace>> _fetchNearbyAddPlanPlaces({
    required int safeLimit,
    required bool forceRefresh,
  }) async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        return peekNearbyAddPlanPlaces(limit: safeLimit);
      }
    }

    Position? position = await Geolocator.getLastKnownPosition();
    try {
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
    } catch (_) {
      // Keep last-known if fresh GPS fails.
    }
    if (position == null) {
      return peekNearbyAddPlanPlaces(limit: safeLimit);
    }

    if (!forceRefresh && _isNearbyCacheFresh(position: position)) {
      return _nearbyAddPlanPlacesCache.take(safeLimit).toList();
    }

    String area = '';
    try {
      final placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        area = (p.subLocality ?? p.locality ?? p.subAdministrativeArea ?? '')
            .trim();
      }
    } catch (_) {}

    try {
      final raw = await _authRepository.fetchNearbyPlaces(
        lat: position.latitude,
        lng: position.longitude,
        radiusMeters: _nearbyPlacesSearchRadiusMeters,
        limit: _nearbyPlacesDisplayLimit,
      );

      final seen = <String>{};
      final itemsWithDistance = <({NearbyAddPlanPlace place, double meters})>[];
      for (final row in raw) {
        final name = (row['placeName'] as String?)?.trim() ?? '';
        if (name.isEmpty || seen.contains(name.toLowerCase())) continue;
        final placeLat = (row['lat'] as num?)?.toDouble();
        final placeLng = (row['lng'] as num?)?.toDouble();
        if (placeLat == null || placeLng == null) continue;

        seen.add(name.toLowerCase());
        final categoryRaw = (row['categoryKey'] as String?)?.trim() ?? '';
        final category = categoryRaw.isNotEmpty ? categoryRaw : 'culture';
        final meters =
            (row['distanceMeters'] as num?)?.toDouble() ??
            Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              placeLat,
              placeLng,
            );
        itemsWithDistance.add((
          place: NearbyAddPlanPlace(
            categoryKey: category,
            placeName: name,
            subtitle:
                '${_categoryLabel(category)}${area.isEmpty ? '' : ' · $area'}',
            distanceLabel: _formatDistance(meters),
            friendAvatars: const [],
            friendsLabel: '0',
            lat: placeLat,
            lng: placeLng,
          ),
          meters: meters,
        ));
      }
      itemsWithDistance.sort((a, b) => a.meters.compareTo(b.meters));
      final items = itemsWithDistance
          .map((item) => item.place)
          .take(_nearbyPlacesDisplayLimit)
          .toList();

      // Boş cevap eski dolu cache’i ezmesin (API hata / kota).
      if (items.isEmpty) {
        return peekNearbyAddPlanPlaces(limit: safeLimit);
      }

      _nearbyAddPlanPlacesCache = items;
      _nearbyAddPlanPlacesCachePosition = position;
      _nearbyAddPlanPlacesCachedAt = DateTime.now();
      return items.take(safeLimit).toList();
    } catch (e, st) {
      debugPrint('getNearbyAddPlanPlaces failed: $e');
      debugPrintStack(stackTrace: st);
      return peekNearbyAddPlanPlaces(limit: safeLimit);
    }
  }

  static String _categoryLabel(String categoryKey) {
    switch (categoryKey) {
      case 'music':
        return 'Music';
      case 'cafe':
        return 'Kafe';
      case 'park':
        return 'Park';
      case 'restaurant':
        return 'Restorant';
      case 'gym':
        return 'Gym';
      case 'culture':
      default:
        return 'Kültür';
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
    final myAvatar = _currentUser.hasPhoto ? _currentUser.avatarPath : '';
    final myLabel = _currentUser.name.trim().isEmpty
        ? 'You'
        : _currentUser.name;

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
        name: 'your_story'.tr(),
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
      _friendStoryItemsByUserId[friend.userId] =
          List<StoryMediaItem>.unmodifiable(items);
      previews.add(
        StoryPreview(
          name: friend.displayName,
          username: friend.username,
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
        _friendStoryItemsByUserId[id] = List<StoryMediaItem>.unmodifiable(
          items,
        );
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

  Future<PulseLikeSnapshot?> togglePulseLike({
    required String pulseId,
    required bool like,
  }) async {
    final id = pulseId.trim();
    if (id.isEmpty) return null;
    try {
      final updated = like
          ? await _authRepository.likePulseRemote(id)
          : await _authRepository.unlikePulseRemote(id);
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
    final avatar = _currentUser.hasPhoto ? _currentUser.avatarPath : '';
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
    bool isVideo = false,
  }) async {
    final created = await _authRepository.publishStory(
      imagePath: imagePath,
      audience: audience,
      musicTrackId: musicTrackId,
      musicClipStartMs: musicClipStartMs,
      musicClipDurationMs: musicClipDurationMs,
      isVideo: isVideo,
    );
    final label = _currentUser.name.trim().isEmpty ? 'You' : _currentUser.name;
    final avatar = _currentUser.hasPhoto ? _currentUser.avatarPath : '';
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
    if (audience == 'public' && mapped.isNotEmpty) {
      _prependExploreItem(mapped.first);
    }
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

  bool get isStoryFeedFresh {
    final at = _storyFeedFetchedAt;
    if (at == null || _cachedExploreItems.isEmpty) return false;
    return DateTime.now().difference(at) < _storyFeedTtl;
  }

  Future<List<StoryMediaItem>> getStoryFeed({bool forceRefresh = false}) async {
    if (!forceRefresh && isStoryFeedFresh) {
      return peekStoryFeed();
    }
    try {
      final now = DateTime.now();
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      final storiesById = <String, ({DateTime createdAt, StoryMediaItem item})>{};
      final pulsesByKey = <String, ({DateTime createdAt, StoryMediaItem item})>{};

      void addStory(PublishedStory story) {
        if (story.mediaUrl.isEmpty) return;
        if (story.audience == 'friends_only') return;
        if (story.expiresAt != null && !story.expiresAt!.isAfter(now)) return;
        final id = story.id.trim();
        if (id.isEmpty) return;
        storiesById[id] = (
          createdAt: story.createdAt ?? epoch,
          item: StoryMediaItem(
            imagePath: story.mediaUrl,
            thumbnailPath: story.thumbnailUrl,
            label: story.displayAuthorName,
            avatarPath: story.authorAvatarUrl ?? '',
            caption: '',
            isReel: story.isVideo,
            isVideo: story.isVideo,
            isVerified: false,
            storyId: story.id,
            userId: story.userId,
            username: story.authorUsername,
            musicAudioUrl: story.musicAudioUrl,
            musicTrackId: story.musicTrackId,
            musicTitle: story.musicTitle,
            musicArtist: story.musicArtist,
            musicCoverUrl: story.musicCoverUrl,
            musicClipStartMs: story.musicClipStartMs,
            musicClipDurationMs: story.musicClipDurationMs,
            expiresAt: story.expiresAt,
            likeCount: story.likeCount,
            likedByMe: story.likedByMe,
            isViewed: story.isViewed,
          ),
        );
      }

      void addPulse(Map<String, dynamic> raw, {bool mine = false}) {
        final audience = (raw['audience'] as String?)?.trim() ?? 'public';
        if (audience == 'friends_only') return;
        final mediaUrl = (raw['mediaUrl'] as String?)?.trim() ?? '';
        if (mediaUrl.isEmpty) return;
        final expiresAt = DateTime.tryParse(
          '${raw['expiresAt'] ?? ''}',
        )?.toLocal();
        if (expiresAt != null && !expiresAt.isAfter(now)) return;
        final id = (raw['id'] as String?)?.trim() ?? '';
        final key = id.isNotEmpty ? 'pulse:$id' : 'pulse:$mediaUrl';
        final createdAt = DateTime.tryParse(
          '${raw['createdAt'] ?? ''}',
        )?.toLocal();
        pulsesByKey[key] = (
          createdAt: createdAt ?? epoch,
          item: _storyItemFromPulseRaw(raw, mine: mine),
        );
      }

      final stories = await _authRepository.fetchExploreStories(
        forceRefresh: forceRefresh,
      );
      for (final story in stories) {
        addStory(story);
      }

      var pulses = _authRepository.peekExplorePulses();
      try {
        final extra = await _authRepository.fetchExplorePulses(
          forceRefresh: forceRefresh,
        );
        pulses = _mergePulseMaps(pulses, extra);
      } catch (_) {}
      for (final raw in pulses) {
        addPulse(raw);
      }
      try {
        final mine = await _authRepository.fetchMyPulses();
        for (final raw in mine) {
          addPulse(raw, mine: true);
        }
      } catch (_) {}

      try {
        final mineStories = await _authRepository.fetchMyActiveStories();
        for (final story in mineStories) {
          addStory(story);
        }
      } catch (_) {}

      final entries = [...storiesById.values, ...pulsesByKey.values]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final items = [for (final entry in entries) entry.item];
      _cacheExploreItems(items);
      return items;
    } catch (_) {
      return peekStoryFeed();
    }
  }

  List<Map<String, dynamic>> _mergePulseMaps(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final raw in [...a, ...b]) {
      final id = (raw['id'] as String?)?.trim() ?? '';
      final media = (raw['mediaUrl'] as String?)?.trim() ?? '';
      final key = id.isNotEmpty ? id : media;
      if (key.isEmpty || !seen.add(key)) continue;
      out.add(raw);
    }
    return out;
  }

  StoryMediaItem _storyItemFromPulseRaw(
    Map<String, dynamic> raw, {
    bool mine = false,
  }) {
    final mediaUrl = (raw['mediaUrl'] as String?)?.trim() ?? '';
    final expiresAt = DateTime.tryParse(
      '${raw['expiresAt'] ?? ''}',
    )?.toLocal();
    var authorName = (raw['authorName'] as String?)?.trim() ?? '';
    var authorUsername = (raw['authorUsername'] as String?)?.trim() ?? '';
    var authorAvatar = (raw['authorAvatarUrl'] as String?)?.trim() ?? '';
    var userId = (raw['userId'] as String?)?.trim() ?? '';
    if (mine) {
      if (authorName.isEmpty) {
        authorName = _currentUser.name.trim().isEmpty
            ? 'You'
            : _currentUser.name.trim();
      }
      if (authorUsername.isEmpty) {
        authorUsername = _currentUser.usernameHandle;
      }
      if (authorAvatar.isEmpty && _currentUser.hasPhoto) {
        authorAvatar = _currentUser.avatarPath;
      }
      if (userId.isEmpty) userId = _sessionUserId ?? '';
    }
    final caption = (raw['caption'] as String?)?.trim() ?? '';
    final isVideo = (raw['mediaType'] as String?)?.trim().toLowerCase() ==
        'video';
    final pulseId = (raw['id'] as String?)?.trim() ?? '';
    final thumbnailUrl = (raw['thumbnailUrl'] as String?)?.trim();
    return StoryMediaItem(
      imagePath: mediaUrl,
      thumbnailPath: thumbnailUrl?.isNotEmpty == true ? thumbnailUrl : null,
      label: authorName.isNotEmpty
          ? authorName
          : (authorUsername.isNotEmpty ? authorUsername : 'User'),
      avatarPath: authorAvatar,
      caption: caption,
      isReel: isVideo,
      isVideo: isVideo,
      isVerified: false,
      storyId: pulseId.isEmpty ? null : pulseId,
      userId: userId.isEmpty ? null : userId,
      username: authorUsername.isEmpty ? null : authorUsername,
      expiresAt: expiresAt,
      likeCount: (raw['likeCount'] as num?)?.toInt() ?? 0,
      likedByMe: raw['likedByMe'] == true,
      isPulse: true,
    );
  }

  void _prependExploreItem(StoryMediaItem item) {
    if (item.imagePath.isEmpty) return;
    _cachedExploreItems = List<StoryMediaItem>.unmodifiable([
      item,
      for (final existing in _cachedExploreItems)
        if (existing.imagePath != item.imagePath ||
            existing.isPulse != item.isPulse)
          existing,
    ]);
  }

  void _cacheExploreItems(List<StoryMediaItem> items) {
    _cachedExploreItems = List<StoryMediaItem>.unmodifiable(items);
    _storyFeedFetchedAt = DateTime.now();
  }

  Future<List<MapFriend>> getMapFriends({double? lat, double? lng}) async {
    try {
      var queryLat = lat;
      var queryLng = lng;
      if (queryLat == null || queryLng == null) {
        final last = await Geolocator.getLastKnownPosition();
        queryLat = last?.latitude;
        queryLng = last?.longitude;
      }
      if (queryLat == null || queryLng == null) {
        mapFriendsListenable.value = const [];
        return const [];
      }

      final raw = await _authRepository.fetchMapNearby(
        lat: queryLat,
        lng: queryLng,
        filter: 'friends',
      );
      final friends = [for (final item in raw) MapFriend.fromMapPresence(item)];
      mapFriendsListenable.value = friends;
      _syncFriendPhotoCycles(friends);
      return friends;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getMapFriends failed: $e');
      }
      mapFriendsListenable.value = const [];
      return const [];
    }
  }

  /// Publishes device location for friends filter + refreshes nearby friends.
  Future<void> syncMapPresence({
    required double lat,
    required double lng,
    double? accuracyM,
    String? locationLabel,
  }) async {
    try {
      await _authRepository.upsertMapPresence(
        lat: lat,
        lng: lng,
        accuracyM: accuracyM,
        locationLabel: locationLabel,
      );
    } catch (_) {
      // Offline — still try to load friends with last known coords.
    }
    await getMapFriends(lat: lat, lng: lng);
  }

  /// Arkadaş check-in’ini haritada anlık günceller.
  MapFriend? applyFriendCheckIn({
    required String name,
    required FriendMapCheckIn checkIn,
    String? userId,
    double? lat,
    double? lng,
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
      final matchById =
          userId != null && userId.isNotEmpty && friend.userId == userId;
      final matchByName = friend.name == name;
      if (!matchById && !matchByName) {
        next.add(friend);
        continue;
      }
      updatedFriend = friend.copyWith(
        checkIn: checkIn,
        lat: lat,
        lng: lng,
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
    final key = updatedFriend.userId.isNotEmpty
        ? updatedFriend.userId
        : updatedFriend.name;
    _restartFriendPhotoCycle(key, checkIn.photoPaths);
    return updatedFriend;
  }

  Future<List<MapFriend>> getMapNearbyAnons({double? lat, double? lng}) async {
    try {
      var queryLat = lat;
      var queryLng = lng;
      if (queryLat == null || queryLng == null) {
        final last = await Geolocator.getLastKnownPosition();
        queryLat = last?.latitude;
        queryLng = last?.longitude;
      }
      if (queryLat == null || queryLng == null) return const [];

      final raw = await _authRepository.fetchMapNearby(
        lat: queryLat,
        lng: queryLng,
        filter: 'anon',
      );
      return [for (final item in raw) MapFriend.fromMapPresence(item)];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getMapNearbyAnons failed: $e');
      }
      return const [];
    }
  }

  Future<List<MapVenue>> getMapVenues({double? lat, double? lng}) async {
    try {
      var queryLat = lat;
      var queryLng = lng;
      if (queryLat == null || queryLng == null) {
        final last = await Geolocator.getLastKnownPosition();
        queryLat = last?.latitude;
        queryLng = last?.longitude;
      }
      if (queryLat == null || queryLng == null) return const [];

      final radiusMeters = _nearbyPlacesSearchRadiusMeters;
      final roundedLat = queryLat.toStringAsFixed(3);
      final roundedLng = queryLng.toStringAsFixed(3);
      final key = 'venues:$roundedLat:$roundedLng:${radiusMeters.round()}:40';

      final cached = _mapVenuesCache[key];
      if (cached != null &&
          DateTime.now().difference(cached.at) <= _mapVenuesMaxCacheAge) {
        return cached.items;
      }

      final inFlight = _mapVenuesInFlight[key];
      if (inFlight != null) return inFlight;

      final future = () async {
        final raw = await _authRepository.fetchNearbyPlaces(
          lat: queryLat!,
          lng: queryLng!,
          radiusMeters: radiusMeters,
          limit: 40,
        );
        final items = <MapVenue>[
          for (final row in raw)
            if (((row['placeName'] as String?)?.trim().isNotEmpty ?? false) &&
                ((row['lat'] as num?) != null && (row['lng'] as num?) != null))
              MapVenue(
                name: (row['placeName'] as String).trim(),
                peopleCount: 0,
                lat: (row['lat'] as num?)?.toDouble() ?? 0,
                lng: (row['lng'] as num?)?.toDouble() ?? 0,
                photoPath: (row['photoUrl'] as String?)?.trim().isNotEmpty == true
                    ? (row['photoUrl'] as String).trim()
                    : null,
              ),
        ];
        if (items.isNotEmpty) {
          _mapVenuesCache[key] = (at: DateTime.now(), items: items);
        }
        return items;
      }();

      _mapVenuesInFlight[key] = future;
      try {
        return await future;
      } finally {
        if (identical(_mapVenuesInFlight[key], future)) {
          _mapVenuesInFlight.remove(key);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getMapVenues failed: $e');
      }
      return const [];
    }
  }

  Future<bool> hasUnreadMessages() async {
    // Prefer ChatRepository via HomeBloc; kept for backward-compat callers.
    return false;
  }

  Future<List<CheckInItem>> getCheckIns({String? forUsername}) async {
    try {
      final raw = _isCurrentProfileRequest(forUsername)
          ? await _authRepository.fetchMyCheckIns()
          : await _authRepository.fetchUserCheckInsByUsername(forUsername!);
      return [
        for (var i = 0; i < raw.length; i++)
          CheckInItem.fromJson(raw[i], index: i),
      ].where((c) => c.placeName.isNotEmpty).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getCheckIns failed: $e');
      }
      return const [];
    }
  }

  Future<List<PulseItem>> getPulses({String? forUsername}) async {
    try {
      final isMe = _isCurrentProfileRequest(forUsername);
      final raw = isMe
          ? await _authRepository.fetchMyPulses()
          : await _authRepository.fetchUserPulsesByUsername(forUsername!);
      final items = [
        for (final item in raw) PulseItem.fromJson(item),
      ].where((p) => p.imagePath.isNotEmpty).toList();
      if (isMe) _cacheMyPulses(items);
      return items;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getPulses failed: $e');
      }
      if (_isCurrentProfileRequest(forUsername) && _cachedMyPulses.isNotEmpty) {
        return _cachedMyPulses;
      }
      return const [];
    }
  }

  Future<PulseItem?> createPulseFromPhoto({
    required String imagePath,
    String sourceType = 'direct',
    String audience = 'public',
    String? placeName,
    double? lat,
    double? lng,
    String? caption,
    bool isVideo = false,
  }) async {
    try {
      final raw = await _authRepository.createPulse(
        imagePath: imagePath,
        sourceType: sourceType,
        audience: audience,
        placeName: placeName,
        lat: lat,
        lng: lng,
        caption: caption,
        isVideo: isVideo,
      );
      final pulse = PulseItem.fromJson(raw);
      prependMyPulse(pulse);
      if (audience != 'friends_only') {
        _prependExploreItem(_storyItemFromPulseRaw(raw, mine: true));
      }
      return pulse;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('createPulseFromPhoto failed: $e');
      }
      return null;
    }
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
      final joiningFuture = _fetchFriendJoiningByPlace();
      final List<UserPlanItem> remote;
      if (_isCurrentProfileRequest(forUsername)) {
        remote = await _authRepository.fetchTodayPlans();
      } else {
        remote = await _authRepository.fetchUserPlansByUsername(forUsername!);
      }
      await joiningFuture;
      final excludeUsername = _isCurrentProfileRequest(forUsername)
          ? null
          : forUsername;
      return [
        for (final item in remote)
          _planItemFromRemote(item, excludeUsername: excludeUsername),
      ];
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

  PlanItem _planItemFromRemote(
    UserPlanItem item, {
    String? excludeUsername,
  }) {
    final hour = item.scheduledAt.hour.toString().padLeft(2, '0');
    final minute = item.scheduledAt.minute.toString().padLeft(2, '0');
    final joining = _joiningForPlace(
      item.placeName,
      excludeUsername: excludeUsername,
    );
    return PlanItem(
      id: item.id,
      time: '$hour:$minute',
      placeName: item.placeName,
      subtitle: item.subtitle,
      friendAvatars: joining?.friendAvatars ?? const [],
      friendsLabel: '${joining?.friendsCount ?? 0}',
      note: item.note,
      showToFriends: item.showToFriends,
      showToNearby: item.showToNearby,
    );
  }

  static String _normalizePlaceKey(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<Map<String, FriendJoiningPlace>> _fetchFriendJoiningByPlace() async {
    final inFlight = _friendJoiningInFlight;
    if (inFlight != null) return inFlight;

    final future = () async {
      try {
        final items = await _authRepository.fetchFriendJoiningPlaces();
        final map = <String, FriendJoiningPlace>{};
        for (final item in items) {
          final key = _normalizePlaceKey(item.placeName);
          if (key.isEmpty) continue;
          map[key] = item;
        }
        _friendJoiningByPlace = map;
        return map;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('fetchFriendJoiningPlaces failed: $e');
        }
        return _friendJoiningByPlace;
      }
    }();

    _friendJoiningInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_friendJoiningInFlight, future)) {
        _friendJoiningInFlight = null;
      }
    }
  }

  FriendJoiningPlace? _joiningForPlace(
    String placeName, {
    String? excludeUsername,
  }) {
    final info = _friendJoiningByPlace[_normalizePlaceKey(placeName)];
    if (info == null || info.friendsCount <= 0) return null;

    final exclude = _profileKey(excludeUsername);
    if (exclude.isEmpty) return info;

    final avatars = <String>[];
    final usernames = <String>[];
    for (var i = 0; i < info.friendUsernames.length; i++) {
      final username = _profileKey(info.friendUsernames[i]);
      if (username.isNotEmpty && username == exclude) continue;
      usernames.add(info.friendUsernames[i]);
      avatars.add(i < info.friendAvatars.length ? info.friendAvatars[i] : '');
    }
    if (usernames.isEmpty && avatars.isEmpty) return null;
    return FriendJoiningPlace(
      placeName: info.placeName,
      friendsCount: usernames.isNotEmpty ? usernames.length : avatars.length,
      friendAvatars: avatars,
      friendUsernames: usernames,
    );
  }

  Future<List<NearbyAddPlanPlace>> _withFriendJoining(
    List<NearbyAddPlanPlace> places,
  ) async {
    if (places.isEmpty) return places;
    await _fetchFriendJoiningByPlace();
    return _applyFriendJoiningSync(places);
  }

  List<NearbyAddPlanPlace> _applyFriendJoiningSync(
    List<NearbyAddPlanPlace> places,
  ) {
    if (places.isEmpty || _friendJoiningByPlace.isEmpty) return places;
    return places.map((place) {
      final joining = _joiningForPlace(place.placeName);
      return place.withJoiningFriends(
        friendAvatars: joining?.friendAvatars ?? const [],
        friendsLabel: '${joining?.friendsCount ?? 0}',
      );
    }).toList(growable: false);
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
