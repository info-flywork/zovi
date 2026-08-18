import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zovi/core/cache/tribe_detail_cache.dart';
import 'package:zovi/core/network/network_manager.dart';
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
    required this.description,
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
      description: (json['description'] as String?)?.trim() ?? '',
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
      conversationId: (json['conversationId'] as String?)?.trim() ?? '',
      members: members,
    );
  }

  final String id;
  final String category;
  final String areaLabel;
  final String name;
  final String description;
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
  final String conversationId;
  final List<TribeMember> members;

  bool get isMember => state == TribeState.member;
  bool get isUnlocked => state == TribeState.unlocked;
  bool get isLocked => state == TribeState.locked;

  Tribe copyWith({
    TribeState? state,
    int? memberCount,
    int? progress,
    String? conversationId,
    List<TribeMember>? members,
    List<String>? avatars,
  }) =>
      Tribe(
        id: id,
        category: category,
        areaLabel: areaLabel,
        name: name,
        description: description,
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
        conversationId: conversationId ?? this.conversationId,
        members: members ?? this.members,
      );

  @override
  List<Object?> get props => [
        id,
        category,
        areaLabel,
        name,
        description,
        emoji,
        cadenceLabel,
        threshold,
        progress,
        state,
        isFeatured,
        memberCount,
        avatars,
        conversationId,
        members,
      ];
}

@immutable
final class TribeBoard extends Equatable {
  const TribeBoard({required this.featured, required this.tribes});

  const TribeBoard.empty()
      : featured = const [],
        tribes = const [];

  final List<Tribe> featured;
  final List<Tribe> tribes;

  bool get isEmpty => featured.isEmpty && tribes.isEmpty;

  @override
  List<Object?> get props => [featured, tribes];
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

  Future<TribeBoard> fetchTribes({bool forceRefresh = false}) {
    if (!forceRefresh) {
      final fresh = peekTribes(allowStale: false);
      if (fresh != null) return Future.value(fresh);
      final inFlight = _boardInFlight;
      if (inFlight != null) return inFlight;
    }
    return _fetchTribesNetwork();
  }

  Future<TribeBoard> _fetchTribesNetwork() async {
    // Best-effort: rank tribes near the user. Uses only the cached last-known
    // position so it never triggers a permission prompt here.
    final query = <String, dynamic>{};
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        query['lat'] = pos.latitude;
        query['lng'] = pos.longitude;
      }
    } catch (_) {
      // Location unavailable — server falls back to last check-in / city-wide.
    }

    final future = _network
        .send<TribeBoard>(
          path: '/tribes',
          method: RequestType.get,
          queryParameters: query.isEmpty ? null : query,
          parserModel: (json) => _boardFromJson(json),
        )
        .then((result) {
          final board = result ?? const TribeBoard.empty();
          _boardCache = board;
          _boardCachedAt = DateTime.now();
          for (final tribe in [...board.featured, ...board.tribes]) {
            _detailCache.mergeFromListItem(tribe);
          }
          return board;
        });
    _boardInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_boardInFlight, future)) _boardInFlight = null;
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
    );
  }
}
