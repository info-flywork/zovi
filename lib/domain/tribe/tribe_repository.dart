import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:zovi/core/cache/tribe_detail_cache.dart';
import 'package:zovi/core/network/network_manager.dart';
import 'package:zovi/core/utils/constants/asset_paths.dart';
import 'package:zovi/core/utils/enum/request_type.dart';

/// Display state resolved by the backend for a tribe relative to the user.
enum TribeState { member, unlocked, locked }

TribeState _stateFromRaw(Object? raw) {
  switch (raw) {
    case 'member':
      return TribeState.member;
    case 'unlocked':
      return TribeState.unlocked;
    default:
      return TribeState.locked;
  }
}

@immutable
final class TribeMember extends Equatable {
  const TribeMember({
    required this.userId,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.streakCount,
    required this.isMe,
  });

  factory TribeMember.fromJson(Map<String, dynamic> json) {
    return TribeMember(
      userId: (json['userId'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      username: (json['username'] as String?)?.trim() ?? '',
      avatarUrl: (json['avatarUrl'] as String?)?.trim() ?? '',
      streakCount: (json['streakCount'] as num?)?.toInt() ?? 0,
      isMe: json['isMe'] == true,
    );
  }

  final String userId;
  final String name;
  final String username;
  final String avatarUrl;
  final int streakCount;
  final bool isMe;

  @override
  List<Object?> get props =>
      [userId, name, username, avatarUrl, streakCount, isMe];
}

@immutable
final class Tribe extends Equatable {
  const Tribe({
    required this.id,
    required this.category,
    required this.areaLabel,
    required this.name,
    this.nameKey = '',
    required this.description,
    this.descriptionKey = '',
    required this.emoji,
    required this.cadenceLabel,
    required this.threshold,
    required this.progress,
    required this.progressLabel,
    required this.remaining,
    required this.state,
    required this.isFeatured,
    required this.memberCount,
    required this.avatars,
    this.areaKey = '',
    this.photoUrl = '',
    this.ownerUserId = '',
    this.isOwner = false,
    this.isUserCreated = false,
    this.conversationId = '',
    this.members = const [],
  });

  factory Tribe.fromJson(Map<String, dynamic> json) {
    final threshold = (json['threshold'] as num?)?.toInt() ?? 10;
    final progress = (json['progress'] as num?)?.toInt() ?? 0;
    final rawAvatars = json['avatars'];
    final avatars = <String>[
      if (rawAvatars is List)
        for (final a in rawAvatars)
          if (a is String && a.trim().isNotEmpty) a.trim(),
    ];
    final rawMembers = json['members'];
    final members = <TribeMember>[
      if (rawMembers is List)
        for (final m in rawMembers)
          if (m is Map<String, dynamic>)
            TribeMember.fromJson(m)
          else if (m is Map)
            TribeMember.fromJson(Map<String, dynamic>.from(m)),
    ];
    return Tribe(
      id: (json['id'] as String?)?.trim() ?? '',
      category: (json['category'] as String?)?.trim() ?? 'other',
      areaLabel: (json['areaLabel'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      nameKey: (json['nameKey'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      descriptionKey: (json['descriptionKey'] as String?)?.trim() ?? '',
      emoji: (json['emoji'] as String?)?.trim() ?? '✨',
      cadenceLabel: (json['cadenceLabel'] as String?)?.trim() ?? '',
      threshold: threshold,
      progress: progress,
      progressLabel:
          (json['progressLabel'] as String?)?.trim() ?? '$progress/$threshold',
      remaining: (json['remaining'] as num?)?.toInt() ??
          (threshold - progress).clamp(0, threshold),
      state: _stateFromRaw(json['state']),
      isFeatured: json['isFeatured'] == true,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? members.length,
      avatars: avatars,
      areaKey: (json['areaKey'] as String?)?.trim() ?? '',
      photoUrl: (json['photoUrl'] as String?)?.trim() ?? '',
      ownerUserId: (json['ownerUserId'] as String?)?.trim() ?? '',
      isOwner: json['isOwner'] == true,
      isUserCreated: json['isUserCreated'] == true,
      conversationId: (json['conversationId'] as String?)?.trim() ?? '',
      members: members,
    );
  }

  final String id;
  final String category;
  final String areaKey;
  final String areaLabel;
  final String name;
  final String nameKey;
  final String description;
  final String descriptionKey;

  String get localizedName {
    final key = nameKey.trim();
    if (key.isEmpty) return name;
    return key.tr();
  }

  String get localizedDescription {
    final key = descriptionKey.trim().isNotEmpty
        ? descriptionKey.trim()
        : nameKey.trim().replaceFirst('tribe_name_', 'tribe_desc_');
    if (key.isEmpty) return description;
    final translated = key.tr();
    if (translated == key) return description;
    return translated;
  }

  String get localizedCadence {
    if (cadenceLabel.trim().isNotEmpty) return cadenceLabel.trim();
    if (areaKey.startsWith('catalog-')) {
      final key = 'tribe_cadence_${areaKey.substring('catalog-'.length)}';
      final translated = key.tr();
      if (translated != key) return translated;
    }
    if (isUserCreated || areaKey.startsWith('custom-')) {
      return 'tribe_cadence_nearby'.tr();
    }
    return '';
  }
  final String emoji;
  final String cadenceLabel;
  final int threshold;
  final int progress;
  final String progressLabel;
  final int remaining;
  final TribeState state;
  final bool isFeatured;
  final int memberCount;
  final List<String> avatars;
  final String photoUrl;
  final String ownerUserId;
  final bool isOwner;
  final bool isUserCreated;
  final String conversationId;
  final List<TribeMember> members;

  bool get isMember => state == TribeState.member;
  bool get isUnlocked => state == TribeState.unlocked;
  bool get isLocked => state == TribeState.locked;

  String get displayAvatarPath {
    if (photoUrl.isNotEmpty) return photoUrl;
    if (areaKey.startsWith('catalog-')) {
      return AssetPaths.tribeCover(areaKey.substring('catalog-'.length));
    }
    if (isUserCreated || ownerUserId.isNotEmpty) {
      return AssetPaths.iconTribeNonamePhoto;
    }
    if (avatars.isNotEmpty) return avatars.first;
    return AssetPaths.iconTribeNonamePhoto;
  }

  Tribe copyWith({
    TribeState? state,
    int? memberCount,
    int? progress,
    String? conversationId,
    List<TribeMember>? members,
    List<String>? avatars,
    String? areaKey,
    String? photoUrl,
    String? ownerUserId,
    bool? isOwner,
    bool? isUserCreated,
  }) =>
      Tribe(
        id: id,
        category: category,
        areaLabel: areaLabel,
        name: name,
        nameKey: nameKey,
        description: description,
        descriptionKey: descriptionKey,
        emoji: emoji,
        cadenceLabel: cadenceLabel,
        threshold: threshold,
        progress: progress ?? this.progress,
        progressLabel: progressLabel,
        remaining: remaining,
        state: state ?? this.state,
        isFeatured: isFeatured,
        memberCount: memberCount ?? this.memberCount,
        avatars: avatars ?? this.avatars,
        areaKey: areaKey ?? this.areaKey,
        photoUrl: photoUrl ?? this.photoUrl,
        ownerUserId: ownerUserId ?? this.ownerUserId,
        isOwner: isOwner ?? this.isOwner,
        isUserCreated: isUserCreated ?? this.isUserCreated,
        conversationId: conversationId ?? this.conversationId,
        members: members ?? this.members,
      );

  @override
  List<Object?> get props => [
        id,
        category,
        areaLabel,
        name,
        nameKey,
        description,
        descriptionKey,
        emoji,
        cadenceLabel,
        threshold,
        progress,
        state,
        isFeatured,
        memberCount,
        avatars,
        areaKey,
        photoUrl,
        ownerUserId,
        isOwner,
        isUserCreated,
        conversationId,
        members,
      ];
}

@immutable
final class CreateTribeResult extends Equatable {
  const CreateTribeResult({required this.tribe, this.coinsBalance});

  final Tribe tribe;
  final int? coinsBalance;

  @override
  List<Object?> get props => [tribe, coinsBalance];
}

@immutable
final class TribeBoard extends Equatable {
  const TribeBoard({
    required this.featured,
    required this.tribes,
    this.hasMore = false,
    this.nextOffset = 0,
  });

  const TribeBoard.empty()
      : featured = const [],
        tribes = const [],
        hasMore = false,
        nextOffset = 0;

  final List<Tribe> featured;
  final List<Tribe> tribes;
  final bool hasMore;
  final int nextOffset;

  bool get isEmpty => featured.isEmpty && tribes.isEmpty;

  TribeBoard mergePage(TribeBoard page) {
    final seen = {for (final t in tribes) t.id};
    return TribeBoard(
      featured: featured.isNotEmpty ? featured : page.featured,
      tribes: [
        ...tribes,
        for (final t in page.tribes)
          if (!seen.contains(t.id)) t,
      ],
      hasMore: page.hasMore,
      nextOffset: page.nextOffset,
    );
  }

  @override
  List<Object?> get props => [featured, tribes, hasMore, nextOffset];
}

final class TribeRepository {
  TribeRepository(this._network, {TribeDetailCache? detailCache})
      : _detailCache = detailCache ?? TribeDetailCache();

  final NetworkManager _network;
  final TribeDetailCache _detailCache;
  static const _boardCacheTtl = Duration(minutes: 2);
  TribeBoard? _boardCache;
  DateTime? _boardCachedAt;
  Future<TribeBoard>? _boardInFlight;

  Tribe? peekTribeDetail(String tribeId) => _detailCache.peek(tribeId);

  /// Inbox / push opens often have tribeId or conversationId only.
  Tribe? findCachedTribe({String tribeId = '', String conversationId = ''}) {
    final tid = tribeId.trim();
    if (tid.isNotEmpty) {
      final detail = peekTribeDetail(tid);
      if (detail != null) return detail;
    }
    final board = peekTribes();
    if (board == null) return null;
    final all = [...board.featured, ...board.tribes];
    if (tid.isNotEmpty) {
      for (final tribe in all) {
        if (tribe.id == tid) return tribe;
      }
    }
    final cid = conversationId.trim();
    if (cid.isNotEmpty) {
      for (final tribe in all) {
        if (tribe.conversationId == cid) return tribe;
      }
    }
    return null;
  }

  TribeBoard? peekTribes({bool allowStale = true}) {
    final cached = _boardCache;
    if (cached == null) return null;
    final at = _boardCachedAt;
    if (allowStale || at == null) return cached;
    if (DateTime.now().difference(at) <= _boardCacheTtl) return cached;
    return null;
  }

  Future<TribeBoard> fetchTribes({
    bool forceRefresh = false,
    int limit = 15,
    int offset = 0,
  }) {
    if (!forceRefresh && offset == 0) {
      final fresh = peekTribes(allowStale: false);
      if (fresh != null) return Future.value(fresh);
      final inFlight = _boardInFlight;
      if (inFlight != null) return inFlight;
    }
    return _fetchTribesNetwork(limit: limit, offset: offset);
  }

  Future<TribeBoard> _fetchTribesNetwork({
    int limit = 15,
    int offset = 0,
  }) async {
    final future = _network
        .send<TribeBoard>(
          path: '/tribes',
          method: RequestType.get,
          queryParameters: {
            'limit': '$limit',
            'offset': '$offset',
          },
          parserModel: (json) => _boardFromJson(json),
        )
        .then((result) {
          final page = result ?? const TribeBoard.empty();
          if (offset == 0) {
            _boardCache = page;
          } else {
            final current = _boardCache ?? const TribeBoard.empty();
            _boardCache = current.mergePage(page);
          }
          _boardCachedAt = DateTime.now();
          final board = _boardCache ?? page;
          for (final tribe in [...board.featured, ...board.tribes]) {
            _detailCache.mergeFromListItem(tribe);
          }
          return offset == 0 ? page : board;
        });
    if (offset == 0) _boardInFlight = future;
    try {
      return await future;
    } finally {
      if (offset == 0 && identical(_boardInFlight, future)) {
        _boardInFlight = null;
      }
    }
  }

  /// Cached detail when available; otherwise fetches once and stores.
  Future<Tribe?> fetchTribeDetail(String tribeId) {
    final id = tribeId.trim();
    if (id.isEmpty) return Future.value(null);
    final cached = _detailCache.peek(id);
    if (cached != null && cached.members.isNotEmpty) {
      return Future.value(cached);
    }
    return refreshTribeDetail(id);
  }

  /// Always hits the network and refreshes the cache.
  Future<Tribe?> refreshTribeDetail(String tribeId) async {
    final id = tribeId.trim();
    if (id.isEmpty) return null;
    final result = await _network.send<Tribe?>(
      path: '/tribes/$id',
      method: RequestType.get,
      parserModel: (json) {
        final raw = json['tribe'];
        if (raw is Map<String, dynamic>) return Tribe.fromJson(raw);
        if (raw is Map) return Tribe.fromJson(Map<String, dynamic>.from(raw));
        return null;
      },
    );
    if (result != null) _detailCache.put(result);
    return result;
  }

  void clearDetailCache() {
    _detailCache.clear();
    _boardCache = null;
    _boardCachedAt = null;
    _boardInFlight = null;
  }

  /// Opt-in join. Returns the updated tribe (now a member) on success.
  Future<Tribe?> joinTribe(String tribeId) {
    return _network.send<Tribe?>(
      path: '/tribes/$tribeId/join',
      method: RequestType.post,
      parserModel: (json) {
        final raw = json['tribe'];
        if (raw is Map<String, dynamic>) {
          final tribe = Tribe.fromJson(raw);
          _detailCache.put(tribe);
          return tribe;
        }
        return null;
      },
    );
  }

  /// Opt-out leave. Returns the updated tribe (no longer a member) on success.
  Future<Tribe?> leaveTribe(String tribeId) {
    return _network.send<Tribe?>(
      path: '/tribes/$tribeId/leave',
      method: RequestType.post,
      parserModel: (json) {
        final raw = json['tribe'];
        if (raw is Map<String, dynamic>) {
          final tribe = Tribe.fromJson(raw);
          _detailCache.put(tribe);
          return tribe;
        }
        return null;
      },
    );
  }

  /// User-created group. Costs coins and returns the new tribe as member.
  Future<CreateTribeResult?> createTribe({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final result = await _network.send<CreateTribeResult?>(
      path: '/tribes',
      method: RequestType.post,
      data: {'name': trimmed},
      parserModel: (json) {
        final raw = json['tribe'];
        if (raw is! Map) return null;
        final tribe = Tribe.fromJson(
          raw is Map<String, dynamic>
              ? raw
              : Map<String, dynamic>.from(raw),
        );
        _detailCache.put(tribe);
        _boardCache = null;
        _boardCachedAt = null;
        return CreateTribeResult(
          tribe: tribe,
          coinsBalance: (json['coinsBalance'] as num?)?.toInt(),
        );
      },
    );
    return result;
  }

  Future<Tribe?> updateTribePhoto({
    required String tribeId,
    required String photoUrl,
  }) {
    final id = tribeId.trim();
    final url = photoUrl.trim();
    if (id.isEmpty || url.isEmpty) return Future.value(null);
    return _network.send<Tribe?>(
      path: '/tribes/$id/photo',
      method: RequestType.post,
      data: {'photoUrl': url},
      parserModel: (json) {
        final raw = json['tribe'];
        if (raw is! Map) return null;
        final tribe = Tribe.fromJson(
          raw is Map<String, dynamic>
              ? raw
              : Map<String, dynamic>.from(raw),
        );
        _detailCache.put(tribe);
        _boardCache = null;
        _boardCachedAt = null;
        return tribe;
      },
    );
  }

  Future<bool> deleteTribe(String tribeId) async {
    final id = tribeId.trim();
    if (id.isEmpty) return false;
    final result = await _network.send<Map<String, dynamic>>(
      path: '/tribes/$id',
      method: RequestType.delete,
      parserModel: (json) => json,
    );
    final deleted = result?['deleted'] == true;
    if (deleted) {
      _detailCache.remove(id);
      _boardCache = null;
      _boardCachedAt = null;
    }
    return deleted;
  }

  TribeBoard _boardFromJson(Map<String, dynamic> json) {
    List<Tribe> parseList(Object? raw) {
      if (raw is! List) return const [];
      final items = <Tribe>[];
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          items.add(Tribe.fromJson(item));
        } else if (item is Map) {
          items.add(Tribe.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return items;
    }

    return TribeBoard(
      featured: parseList(json['featured']),
      tribes: parseList(json['tribes']),
      hasMore: json['hasMore'] == true,
      nextOffset: (json['nextOffset'] as num?)?.toInt() ?? 0,
    );
  }
}
