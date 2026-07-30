import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:zovi/core/cache/music_catalog_cache.dart';
import 'package:zovi/core/cache/stamp_catalog_cache.dart';
import 'package:zovi/core/cache/stamp_image_cache.dart';
import 'package:zovi/core/cache/story_catalog_cache.dart';
import 'package:zovi/core/cache/story_draft_cache.dart';
import 'package:zovi/core/managers/auth_cache_manager.dart';
import 'package:zovi/core/managers/shared_pref_manager.dart';
import 'package:zovi/core/network/network_manager.dart';
import 'package:zovi/core/utils/enum/request_type.dart';
import 'package:zovi/domain/auth/models/auth_session.dart';
import 'package:zovi/domain/auth/models/story_draft_item.dart';
import 'package:zovi/domain/auth/models/username_availability.dart';
import 'package:zovi/domain/auth/models/username_taken_exception.dart';

export 'package:zovi/domain/auth/models/story_draft_item.dart';

class AuthRepository {
  AuthRepository(
    this._authCache,
    this._prefs,
    this._network, {
    MusicCatalogCache? musicCatalogCache,
    StampCatalogCache? stampCatalogCache,
    StoryCatalogCache? storyCatalogCache,
    StampImageCache? stampImageCache,
    StoryDraftCache? storyDraftCache,
  }) : _musicCatalogCache = musicCatalogCache ?? MusicCatalogCache(),
       _stampCatalogCache = stampCatalogCache ?? StampCatalogCache(),
       _storyCatalogCache = storyCatalogCache ?? StoryCatalogCache(),
       _stampImageCache = stampImageCache ?? StampImageCache(),
       _storyDraftCache = storyDraftCache ?? StoryDraftCache();

  final AuthCacheManager _authCache;
  final SharedPrefManager _prefs;
  final NetworkManager _network;
  final MusicCatalogCache _musicCatalogCache;
  final StampCatalogCache _stampCatalogCache;
  final StoryCatalogCache _storyCatalogCache;
  final StampImageCache _stampImageCache;
  final StoryDraftCache _storyDraftCache;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String? _phoneVerificationId;
  int? _phoneResendToken;
  bool _googleInitialized = false;
  CachedPersonalInfo? _cachedPersonalInfo;
  List<StampCatalogItem>? _cachedMyStamps;
  List<UserStickerItem>? _cachedMyStickers;
  List<StampCatalogItem>? _cachedOwnedPickerStamps;

  /// Splash /auth/me sonrası doldurulur; PersonalInfo loading göstermesin.
  CachedPersonalInfo? get cachedPersonalInfo => _cachedPersonalInfo;

  void clearPersonalInfoCache() {
    _cachedPersonalInfo = null;
  }

  /// Drops every per-account cache. Catalogs (stamps, music) stay since they
  /// are the same for all users; downloaded image files also stay on disk.
  void clearSessionCaches() {
    _cachedPersonalInfo = null;
    _storyCatalogCache.clear();
    _storyDraftCache.clear();
    _cachedMyStamps = null;
    _cachedMyStickers = null;
    _cachedOwnedPickerStamps = null;
  }

  /// Web client ID from `google-services.json` (client_type 3) — needed for
  /// Firebase ID tokens on Android / Google Sign-In.
  static const _googleServerClientId =
      '226127781305-5e4gb2jlk2ou56tu1lpve7043ri97e77.apps.googleusercontent.com';

  Future<bool> isFirstLaunch() => _prefs.isFirstLaunch();

  Future<bool> isIntroDone() => _prefs.isIntroDone();

  Future<bool> isAuthenticated() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null && token.isNotEmpty) {
        await _authCache.saveAccessToken(token);
        return true;
      }
    }
    final cached = await _authCache.getAccessToken();
    return cached != null && cached.isNotEmpty;
  }

  /// Firebase UID of the signed-in user — used to scope local drafts.
  String? get currentFirebaseUid => _firebaseAuth.currentUser?.uid;

  Future<bool> isOnboardingDone() => _prefs.isOnboardingDone();

  Future<void> completeIntro() async {
    await _prefs.setIntroDone();
  }

  /// [phone] national digits only; [dialCode] like `+90`.
  Future<void> sendVerificationCode({
    required String phone,
    required String dialCode,
  }) async {
    final e164 = _toE164(dialCode: dialCode, phone: phone);
    final completer = Completer<void>();

    if (kDebugMode) {
      debugPrint('PhoneAuth send → $e164');
    }

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: e164,
      forceResendingToken: _phoneResendToken,
      verificationCompleted: (credential) async {
        try {
          await _firebaseAuth.signInWithCredential(credential);
          await _persistIdToken();
          if (!completer.isCompleted) completer.complete();
        } catch (e, st) {
          if (!completer.isCompleted) completer.completeError(e, st);
        }
      },
      verificationFailed: (error) {
        if (kDebugMode) {
          debugPrint(
            'PhoneAuth verificationFailed: ${error.code} ${error.message}',
          );
          debugPrint('PhoneAuth verificationFailed raw: $error');
        }
        if (!completer.isCompleted) completer.completeError(error);
      },
      codeSent: (verificationId, resendToken) {
        if (kDebugMode) {
          debugPrint('PhoneAuth codeSent');
        }
        _phoneVerificationId = verificationId;
        _phoneResendToken = resendToken;
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _phoneVerificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );

    await completer.future;
  }

  Future<AuthSession> verifyCode(String phone, String code) async {
    final verificationId = _phoneVerificationId;
    if (verificationId == null || verificationId.isEmpty) {
      throw StateError('Phone verification session expired.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    await _firebaseAuth.signInWithCredential(credential);
    return _persistIdToken();
  }

  Future<AuthSession> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google Sign-In did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await _firebaseAuth.signInWithCredential(credential);
    return _persistIdToken();
  }

  Future<AuthSession> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final idToken = appleCredential.identityToken;
    if (idToken == null) {
      throw StateError('Apple Sign-In did not return an identity token.');
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    await _firebaseAuth.signInWithCredential(oauthCredential);
    return _persistIdToken();
  }

  Future<AuthSession> syncSession() => _persistIdToken();

  Future<void> completeOnboarding({String? mockToken}) async {
    if (mockToken != null) {
      await _authCache.saveAccessToken(mockToken);
    } else {
      await _persistIdToken();
    }
    await _prefs.setOnboardingDone();
    await _prefs.setIntroDone();
    await _prefs.setFirstLaunchDone();
  }

  Future<void> logout() async {
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Google may not have been used this session.
      }
    }
    await _firebaseAuth.signOut();
    await _authCache.clearAll();
    _googleInitialized = false;
    _phoneVerificationId = null;
    _phoneResendToken = null;
    clearSessionCaches();
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
    _googleInitialized = true;
  }

  Future<AuthSession> _persistIdToken() async {
    final token = await _firebaseAuth.currentUser?.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('Firebase user has no ID token.');
    }
    await _authCache.saveAccessToken(token);
    return _syncBackendUser();
  }

  /// Upserts the Firebase user into MySQL via Node API.
  Future<AuthSession> _syncBackendUser() async {
    final result = await _network.send<AuthSession>(
      path: '/auth/sync',
      method: RequestType.post,
      parserModel: AuthSession.fromJson,
    );
    if (result == null) {
      throw StateError('Auth sync failed.');
    }
    if (result.nextStep == 'home' || result.onboardingDone) {
      await _prefs.setOnboardingDone();
      await _prefs.setIntroDone();
      await _prefs.setFirstLaunchDone();
    }
    return result;
  }

  Future<UsernameAvailability> checkUsernameAvailability(String username) async {
    final result = await _network.send<UsernameAvailability>(
      path: '/users/username/availability',
      method: RequestType.get,
      queryParameters: {'username': username},
      parserModel: UsernameAvailability.fromJson,
    );
    if (result == null) {
      throw StateError('Username availability check failed.');
    }
    return result;
  }

  /// Public profile lookup by username (auth required).
  Future<Map<String, dynamic>> fetchPublicProfileByUsername(
    String username,
  ) async {
    final handle = username.startsWith('@') ? username.substring(1) : username;
    final result = await _network.send<Map<String, dynamic>>(
      path: '/users/by-username/${Uri.encodeComponent(handle.trim())}',
      method: RequestType.get,
      parserModel: (json) => json,
    );
    if (result == null) {
      throw StateError('Public profile fetch failed.');
    }
    return result;
  }

  Future<List<UserPlanItem>> fetchUserPlansByUsername(String username) async {
    final handle = username.startsWith('@') ? username.substring(1) : username;
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 1));
    final result = await _network.send<Map<String, dynamic>>(
      path:
          '/users/by-username/${Uri.encodeComponent(handle.trim())}/plans',
      method: RequestType.get,
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
      parserModel: (json) => json,
    );
    final raw = result?['plans'];
    if (raw is! List) return const [];
    final items = <UserPlanItem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      items.add(UserPlanItem.fromJson(Map<String, dynamic>.from(item)));
    }
    return items;
  }

  Future<List<StampCatalogItem>> fetchUserStampsByUsername(
    String username, {
    String? locale,
  }) async {
    final handle = username.startsWith('@') ? username.substring(1) : username;
    final localeKey = (locale ?? 'en').trim();
    final result = await _network.send<Map<String, dynamic>>(
      path:
          '/users/by-username/${Uri.encodeComponent(handle.trim())}/stamps',
      method: RequestType.get,
      queryParameters: {
        if (localeKey.isNotEmpty) 'locale': localeKey,
      },
      parserModel: (json) => json,
    );
    final raw = result?['stamps'];
    if (raw is! List) return const [];
    final items = <StampCatalogItem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final parsed = StampCatalogItem.fromJson(Map<String, dynamic>.from(item));
      if (parsed.imageUrl.isEmpty) continue;
      items.add(parsed);
    }
    unawaited(_prefetchStampImages(items));
    return items;
  }

  Future<({
    String userId,
    String name,
    String username,
    String avatarUrl,
    List<PublishedStory> stories,
  })> fetchStoriesByUserId(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) {
      return (
        userId: '',
        name: '',
        username: '',
        avatarUrl: '',
        stories: const <PublishedStory>[],
      );
    }
    final result = await _network.send<Map<String, dynamic>>(
      path: '/stories/by-user/${Uri.encodeComponent(id)}',
      method: RequestType.get,
      parserModel: (json) => json,
    );
    final raw = result?['stories'];
    final stories = <PublishedStory>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        stories.add(PublishedStory.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return (
      userId: (result?['userId'] as String?)?.trim() ?? id,
      name: (result?['name'] as String?)?.trim() ?? '',
      username: (result?['username'] as String?)?.trim() ?? '',
      avatarUrl: (result?['avatarUrl'] as String?)?.trim() ?? '',
      stories: stories,
    );
  }

  Future<Map<String, dynamic>?> saveProfile({
    String? fullName,
    String? username,
    DateTime? birthDate,
    String? bio,
    String? accountPrivacy,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['fullName'] = fullName.trim();
      if (username != null) data['username'] = username.trim().toLowerCase();
      if (birthDate != null) {
        final y = birthDate.year.toString().padLeft(4, '0');
        final m = birthDate.month.toString().padLeft(2, '0');
        final d = birthDate.day.toString().padLeft(2, '0');
        data['birthDate'] = '$y-$m-$d';
      }
      if (bio != null) data['bio'] = bio.trim();
      if (accountPrivacy != null && accountPrivacy.trim().isNotEmpty) {
        data['accountPrivacy'] = accountPrivacy.trim().toLowerCase();
      }
      if (data.isEmpty) return null;

      final result = await _network.send<Map<String, dynamic>>(
        path: '/users/me/profile',
        method: RequestType.patch,
        data: data,
        parserModel: (json) => json,
      );
      if (birthDate != null) {
        _cachedPersonalInfo =
            (_cachedPersonalInfo ?? CachedPersonalInfo.empty).copyWith(
              birthDate: birthDate,
            );
      }
      final profile = result?['profile'];
      if (profile is Map) {
        final raw = profile['birthDate']?.toString();
        final parsed = raw == null || raw.isEmpty
            ? null
            : DateTime.tryParse(raw);
        if (parsed != null) {
          _cachedPersonalInfo =
              (_cachedPersonalInfo ?? CachedPersonalInfo.empty).copyWith(
                birthDate: parsed,
              );
        }
      }
      return result;
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map<String, dynamic>) {
        final error = body['error'];
        if (error is Map<String, dynamic> && error['code'] == 'USERNAME_TAKEN') {
          final raw = error['suggestions'];
          final suggestions = raw is List
              ? raw.map((e) => e.toString()).toList()
              : <String>[];
          throw UsernameTakenException(suggestions);
        }
      }
      rethrow;
    }
  }

  Future<void> updateAccountPrivacy(String accountPrivacy) async {
    await saveProfile(accountPrivacy: accountPrivacy);
  }

  Future<String> uploadAvatar(String filePath) async {
    final result = await _network.uploadFile<Map<String, dynamic>>(
      path: '/users/me/avatar',
      filePath: filePath,
      fieldName: 'avatar',
      parserModel: (json) => json,
    );
    final url = result?['avatarUrl'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('Avatar upload failed.');
    }
    return url;
  }

  Future<void> replaceProfileLinks(
    List<({String title, String url})> links,
  ) async {
    await _network.send<Map<String, dynamic>>(
      path: '/users/me/links',
      method: RequestType.put,
      data: {
        'links': links
            .map((l) => {'title': l.title, 'url': l.url})
            .toList(),
      },
      parserModel: (json) => json,
    );
  }

  Future<Map<String, dynamic>> fetchMyProfilePayload() async {
    final result = await _network.send<Map<String, dynamic>>(
      path: '/auth/me',
      method: RequestType.get,
      parserModel: (json) => json,
    );
    if (result == null) {
      throw StateError('Failed to load profile.');
    }
    _cachedPersonalInfo = CachedPersonalInfo.fromAuthMe(result);
    return result;
  }

  List<StampCatalogItem>? peekStampCatalog({String? locale}) {
    return _stampCatalogCache.peek(locale ?? 'en');
  }

  Future<List<StampCatalogItem>> fetchStampCatalog({
    String? locale,
    bool forceRefresh = false,
  }) async {
    final localeKey = (locale ?? 'en').trim();
    if (!forceRefresh) {
      final cached = _stampCatalogCache.peek(localeKey);
      if (cached != null) return cached;
    }

    final result = await _network.send<Map<String, dynamic>>(
      path: '/stamps',
      method: RequestType.get,
      queryParameters: {
        if (localeKey.isNotEmpty) 'locale': localeKey,
      },
      parserModel: (json) => json,
    );
    final raw = result?['stamps'];
    if (raw is! List) return const [];
    final items = <StampCatalogItem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final parsed = StampCatalogItem.fromJson(Map<String, dynamic>.from(item));
      if (parsed.imageUrl.isEmpty) continue;
      items.add(parsed);
    }
    _stampCatalogCache.put(localeKey, items);
    unawaited(_prefetchStampImages(items));
    return items;
  }

  Future<List<StampCatalogItem>> fetchMyStamps({
    String? locale,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedMyStamps != null) {
      return _cachedMyStamps!;
    }
    final localeKey = (locale ?? 'en').trim();
    final result = await _network.send<Map<String, dynamic>>(
      path: '/users/me/stamps',
      method: RequestType.get,
      queryParameters: {
        if (localeKey.isNotEmpty) 'locale': localeKey,
      },
      parserModel: (json) => json,
    );
    final raw = result?['stamps'];
    if (raw is! List) {
      _cachedMyStamps = const [];
      return const [];
    }
    final items = <StampCatalogItem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final parsed = StampCatalogItem.fromJson(Map<String, dynamic>.from(item));
      if (parsed.imageUrl.isEmpty) continue;
      items.add(parsed);
    }
    _cachedMyStamps = items;
    unawaited(_prefetchStampImages(items));
    return items;
  }

  List<StampCatalogItem>? peekOwnedPickerStamps() => _cachedOwnedPickerStamps;

  /// Stickers the user created + stamps they earned (Blue Tick, etc.).
  /// Used by story/chat sticker sheets — never the full public catalog.
  Future<List<StampCatalogItem>> fetchOwnedPickerStamps({
    String? locale,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedOwnedPickerStamps != null) {
      return _cachedOwnedPickerStamps!;
    }

    // Degrade gracefully: one failing endpoint must not empty the picker.
    final stickersFuture = fetchMyStickers(
      forceRefresh: forceRefresh,
    ).catchError((_) => const <UserStickerItem>[]);
    final earnedFuture = fetchMyStamps(
      locale: locale,
      forceRefresh: forceRefresh,
    ).catchError((_) => const <StampCatalogItem>[]);
    final stickers = await stickersFuture;
    final earned = await earnedFuture;

    final seen = <String>{};
    final items = <StampCatalogItem>[];

    for (final sticker in stickers) {
      if (sticker.imageUrl.isEmpty || !seen.add(sticker.id)) continue;
      items.add(
        StampCatalogItem(
          id: sticker.id,
          name: sticker.title.trim().isEmpty ? 'Sticker' : sticker.title,
          imageUrl: sticker.imageUrl,
        ),
      );
    }
    for (final stamp in earned) {
      if (stamp.imageUrl.isEmpty || !seen.add(stamp.id)) continue;
      items.add(stamp);
    }

    _cachedOwnedPickerStamps = items;
    unawaited(_prefetchStampImages(items));
    return items;
  }

  void invalidateOwnedStickersCache() {
    _cachedMyStickers = null;
    _cachedMyStamps = null;
    _cachedOwnedPickerStamps = null;
  }

  Future<void> _prefetchStampImages(List<StampCatalogItem> items) {
    return _stampImageCache.prefetchAll(
      items.map((item) => (id: item.id, url: item.imageUrl)),
    );
  }

  MusicTracksPage? peekMusicTracks({
    String? query,
    int offset = 0,
    int limit = 10,
  }) {
    return _musicCatalogCache.peek(
      query: query ?? '',
      offset: offset,
      limit: limit,
    );
  }

  Future<MusicTracksPage> fetchMusicTracks({
    String? query,
    int offset = 0,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final q = query?.trim() ?? '';
    if (!forceRefresh) {
      final cached = _musicCatalogCache.peek(
        query: q,
        offset: offset,
        limit: limit,
      );
      if (cached != null) return cached;
    }

    final result = await _network.send<Map<String, dynamic>>(
      path: '/music/tracks',
      method: RequestType.get,
      queryParameters: {
        if (q.isNotEmpty) 'q': q,
        'offset': offset,
        'limit': limit,
      },
      parserModel: (json) => json,
      // Lazy Suno expand can take a few minutes on empty tail pages.
      receiveTimeout: const Duration(minutes: 5),
    );
    final raw = result?['tracks'];
    if (raw is! List) {
      return const MusicTracksPage(
        tracks: [],
        hasMore: false,
        nextOffset: 0,
        expanding: false,
      );
    }
    final items = <MusicTrackItem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final parsed = MusicTrackItem.fromJson(Map<String, dynamic>.from(item));
      if (parsed.audioUrl.isEmpty) continue;
      items.add(parsed);
    }
    final hasMore = result?['hasMore'] == true;
    final expanding = result?['expanding'] == true;
    final nextOffset =
        (result?['nextOffset'] as num?)?.toInt() ?? (offset + items.length);
    final page = MusicTracksPage(
      tracks: items,
      hasMore: hasMore,
      nextOffset: nextOffset,
      expanding: expanding,
    );
    // Don't cache in-flight expand empty pages — wait for real rows.
    if (items.isNotEmpty || !expanding) {
      _musicCatalogCache.put(query: q, offset: offset, page: page);
    }
    return page;
  }

  Future<List<UserStickerItem>> fetchMyStickers({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedMyStickers != null) {
      return _cachedMyStickers!;
    }
    final result = await _network.send<Map<String, dynamic>>(
      path: '/users/me/stickers',
      method: RequestType.get,
      parserModel: (json) => json,
    );
    final raw = result?['stickers'];
    if (raw is! List) {
      _cachedMyStickers = const [];
      return const [];
    }
    final items = <UserStickerItem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final parsed = UserStickerItem.fromJson(Map<String, dynamic>.from(item));
      if (parsed.imageUrl.isEmpty) continue;
      items.add(parsed);
    }
    _cachedMyStickers = items;
    unawaited(
      _stampImageCache.prefetchAll(
        items.map((item) => (id: item.id, url: item.imageUrl)),
      ),
    );
    return items;
  }

  Future<UserStickerItem> generateSticker({
    required String imagePath,
    required String style,
    required String name,
    required String description,
  }) async {
    final result = await _network.uploadFile<Map<String, dynamic>>(
      path: '/users/me/stickers/generate',
      filePath: imagePath,
      fieldName: 'image',
      data: {
        'style': style,
        'title': name.trim(),
        'description': description.trim(),
      },
      parserModel: (json) => json,
    );
    final raw = result?['sticker'];
    if (raw is! Map) {
      throw StateError('Sticker generation failed.');
    }
    final sticker = UserStickerItem.fromJson(Map<String, dynamic>.from(raw));
    invalidateOwnedStickersCache();
    unawaited(
      _stampImageCache.prefetch(stampId: sticker.id, url: sticker.imageUrl),
    );
    return sticker;
  }

  Future<PublishedStory> publishStory({
    required String imagePath,
    required String audience,
    String? musicTrackId,
    int? musicClipStartMs,
    int? musicClipDurationMs,
  }) async {
    final result = await _network.uploadFile<Map<String, dynamic>>(
      path: '/stories',
      filePath: imagePath,
      fieldName: 'image',
      data: {
        'audience': audience,
        if (musicTrackId != null && musicTrackId.isNotEmpty)
          'musicTrackId': musicTrackId,
        if (musicClipStartMs != null)
          'musicClipStartMs': '$musicClipStartMs',
        if (musicClipDurationMs != null)
          'musicClipDurationMs': '$musicClipDurationMs',
      },
      parserModel: (json) => json,
    );
    final raw = result?['story'];
    if (raw is! Map) {
      throw StateError('Story publish failed.');
    }
    return PublishedStory.fromJson(Map<String, dynamic>.from(raw));
  }

  List<StoryDraftItem>? peekStoryDrafts() => _storyDraftCache.peek();

  bool get storyDraftsNeedRefresh =>
      _storyDraftCache.dirty || !_storyDraftCache.hasCache;

  Future<List<StoryDraftItem>> fetchStoryDrafts({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        !_storyDraftCache.dirty &&
        _storyDraftCache.hasCache) {
      return _storyDraftCache.peek() ?? const [];
    }

    final result = await _network.send<Map<String, dynamic>>(
      path: '/drafts',
      method: RequestType.get,
      parserModel: (json) => json,
    );
    final raw = result?['drafts'];
    if (raw is! List) {
      _storyDraftCache.put(const []);
      return const [];
    }
    final items = <StoryDraftItem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final parsed = StoryDraftItem.fromJson(Map<String, dynamic>.from(item));
      if (parsed.mediaUrl.isEmpty) continue;
      items.add(parsed);
    }
    _storyDraftCache.put(items);
    unawaited(
      _stampImageCache.prefetchAll(
        items.map((item) => (id: item.id, url: item.mediaUrl)),
      ),
    );
    return items;
  }

  Future<StoryDraftItem> uploadStoryDraft(String imagePath) async {
    final result = await _network.uploadFile<Map<String, dynamic>>(
      path: '/drafts',
      filePath: imagePath,
      fieldName: 'image',
      parserModel: (json) => json,
    );
    final raw = result?['draft'];
    if (raw is! Map) {
      throw StateError('Draft upload failed.');
    }
    final draft = StoryDraftItem.fromJson(Map<String, dynamic>.from(raw));
    // Next drafts sheet open should refetch + recache from CDN/API.
    _storyDraftCache.markDirty();
    unawaited(
      _stampImageCache.prefetch(stampId: draft.id, url: draft.mediaUrl),
    );
    return draft;
  }

  Future<void> deleteStoryDraft(String draftId) async {
    final id = draftId.trim();
    if (id.isEmpty) return;
    await _network.send<Map<String, dynamic>>(
      path: '/drafts/$id',
      method: RequestType.delete,
      parserModel: (json) => json,
    );
    _storyDraftCache.markDirty();
  }

  Future<StoryFeed> fetchStoryFeed() async {
    final result = await _network.send<Map<String, dynamic>>(
      path: '/stories/feed',
      method: RequestType.get,
      parserModel: (json) => json,
    );

    final me = result?['me'];
    final feedMe = me is Map
        ? StoryFeedMe.fromJson(_withTopLevelStories(result, me))
        : const StoryFeedMe(
            userId: '',
            name: '',
            avatarUrl: '',
            hasStory: false,
            isViewed: false,
          );

    final rawFriends = result?['friends'];
    final friends = <StoryFeedUser>[];
    if (rawFriends is List) {
      for (final item in rawFriends) {
        if (item is! Map) continue;
        final parsed = StoryFeedUser.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (parsed.userId.isEmpty || parsed.stories.isEmpty) continue;
        friends.add(parsed);
      }
    }

    return StoryFeed(me: feedMe, friends: friends);
  }

  Map<String, dynamic> _withTopLevelStories(
    Map<String, dynamic>? result,
    Map<dynamic, dynamic> me,
  ) {
    final meMap = Map<String, dynamic>.from(me);
    // Prefer top-level stories (feed payload) when present.
    final topStories = result?['stories'];
    if (topStories is List && meMap['stories'] == null) {
      meMap['stories'] = topStories;
    }
    return meMap;
  }

  List<PublishedStory>? peekExploreStories() => _storyCatalogCache.peek();

  Future<List<PublishedStory>> fetchExploreStories({
    int limit = 120,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _storyCatalogCache.peek();
      if (cached != null) return cached;
    }

    final result = await _network.send<Map<String, dynamic>>(
      path: '/stories/explore',
      method: RequestType.get,
      queryParameters: {'limit': '$limit'},
      parserModel: (json) => json,
    );
    final raw = result?['stories'];
    if (raw is! List) return const [];
    final items = [
      for (final item in raw)
        if (item is Map)
          PublishedStory.fromJson(Map<String, dynamic>.from(item)),
    ];
    _storyCatalogCache.put(items);
    return items;
  }

  Future<List<PublishedStory>> fetchMyActiveStories() async {
    final result = await _network.send<Map<String, dynamic>>(
      path: '/stories/me',
      method: RequestType.get,
      parserModel: (json) => json,
    );
    final raw = result?['stories'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          PublishedStory.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<void> markStoryViewedRemote(String storyId) async {
    final id = storyId.trim();
    if (id.isEmpty) return;
    await _network.send<Map<String, dynamic>>(
      path: '/stories/$id/view',
      method: RequestType.post,
      parserModel: (json) => json,
    );
  }

  Future<PublishedStory> likeStoryRemote(String storyId) async {
    final id = storyId.trim();
    if (id.isEmpty) {
      throw ArgumentError('storyId is empty');
    }
    final result = await _network.send<Map<String, dynamic>>(
      path: '/stories/$id/like',
      method: RequestType.post,
      parserModel: (json) => json,
    );
    final raw = result?['story'];
    if (raw is! Map) {
      throw StateError('Story like failed.');
    }
    return PublishedStory.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<PublishedStory> unlikeStoryRemote(String storyId) async {
    final id = storyId.trim();
    if (id.isEmpty) {
      throw ArgumentError('storyId is empty');
    }
    final result = await _network.send<Map<String, dynamic>>(
      path: '/stories/$id/like',
      method: RequestType.delete,
      parserModel: (json) => json,
    );
    final raw = result?['story'];
    if (raw is! Map) {
      throw StateError('Story unlike failed.');
    }
    return PublishedStory.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> requestAccountDeletion({String? reason}) async {
    await _network.send<Map<String, dynamic>>(
      path: '/users/me/deletion-request',
      method: RequestType.post,
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      parserModel: (json) => json,
    );
  }

  Future<List<BlockedAccount>> fetchBlockedUsers() async {
    final result = await _network.send<Map<String, dynamic>>(
      path: '/users/me/blocked',
      method: RequestType.get,
      parserModel: (json) => json,
    );
    final raw = result?['users'];
    if (raw is! List) return const [];
    final users = <BlockedAccount>[];
    for (final item in raw) {
      if (item is! Map) continue;
      users.add(BlockedAccount.fromJson(Map<String, dynamic>.from(item)));
    }
    return users;
  }

  Future<void> unblockUser(String blockedUserId) async {
    await _network.send<Map<String, dynamic>>(
      path: '/users/me/blocked/$blockedUserId',
      method: RequestType.delete,
      parserModel: (json) => json,
    );
  }

  Future<UserPlanItem> createPlan({
    required String placeName,
    required String subtitle,
    required String category,
    required DateTime scheduledAt,
    required bool showToFriends,
    required bool showToNearby,
    String? note,
  }) async {
    final result = await _network.send<Map<String, dynamic>>(
      path: '/users/me/plans',
      method: RequestType.post,
      data: {
        'placeName': placeName.trim(),
        'subtitle': subtitle.trim(),
        'category': category.trim().isEmpty ? 'other' : category.trim(),
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'note': note?.trim() ?? '',
        'showToFriends': showToFriends,
        'showToNearby': showToNearby,
      },
      parserModel: (json) => json,
    );
    final raw = result?['plan'];
    if (raw is! Map) {
      throw StateError('Plan create failed.');
    }
    return UserPlanItem.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<List<UserPlanItem>> fetchTodayPlans() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 1));
    final result = await _network.send<Map<String, dynamic>>(
      path: '/users/me/plans',
      method: RequestType.get,
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
      parserModel: (json) => json,
    );
    final raw = result?['plans'];
    if (raw is! List) return const [];
    final items = <UserPlanItem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      items.add(UserPlanItem.fromJson(Map<String, dynamic>.from(item)));
    }
    return items;
  }

  static String _toE164({required String dialCode, required String phone}) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final code = dialCode.startsWith('+') ? dialCode : '+$dialCode';
    // Drop a single leading 0 after country code (common TR local format).
    final national = digits.startsWith('0') ? digits.substring(1) : digits;
    return '$code$national';
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

class CachedPersonalInfo {
  const CachedPersonalInfo({
    required this.email,
    required this.phoneE164,
    required this.primaryAuth,
    this.birthDate,
  });

  static const empty = CachedPersonalInfo(
    email: '',
    phoneE164: '',
    primaryAuth: 'phone',
  );

  factory CachedPersonalInfo.fromAuthMe(Map<String, dynamic> json) {
    final user = json['user'];
    final profile = json['profile'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : const {};
    final profileMap =
        profile is Map ? Map<String, dynamic>.from(profile) : const {};
    final birthRaw = profileMap['birthDate']?.toString();
    return CachedPersonalInfo(
      email: (userMap['email'] as String?)?.trim() ?? '',
      phoneE164: (userMap['phoneE164'] as String?)?.trim() ?? '',
      primaryAuth:
          (userMap['primaryAuth'] as String?)?.trim().toLowerCase() ?? 'phone',
      birthDate: birthRaw == null || birthRaw.isEmpty
          ? null
          : DateTime.tryParse(birthRaw),
    );
  }

  final String email;
  final String phoneE164;
  final String primaryAuth;
  final DateTime? birthDate;

  bool get isPhoneAuth => primaryAuth == 'phone';

  String get contactValue => isPhoneAuth ? phoneE164 : email;

  CachedPersonalInfo copyWith({
    String? email,
    String? phoneE164,
    String? primaryAuth,
    DateTime? birthDate,
  }) {
    return CachedPersonalInfo(
      email: email ?? this.email,
      phoneE164: phoneE164 ?? this.phoneE164,
      primaryAuth: primaryAuth ?? this.primaryAuth,
      birthDate: birthDate ?? this.birthDate,
    );
  }
}

class StampCatalogItem {
  const StampCatalogItem({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory StampCatalogItem.fromJson(Map<String, dynamic> json) {
    return StampCatalogItem(
      id: (json['id'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      imageUrl: (json['cdnUrl'] as String?)?.trim() ?? '',
    );
  }

  final String id;
  final String name;
  final String imageUrl;
}

class MusicTrackItem {
  const MusicTrackItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.durationMs,
    required this.coverUrl,
    required this.audioUrl,
  });

  factory MusicTrackItem.fromJson(Map<String, dynamic> json) {
    return MusicTrackItem(
      id: (json['id'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      artist: (json['artist'] as String?)?.trim() ?? '',
      genre: (json['genre'] as String?)?.trim() ?? '',
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      coverUrl: (json['coverUrl'] as String?)?.trim() ?? '',
      audioUrl: (json['audioUrl'] as String?)?.trim() ?? '',
    );
  }

  final String id;
  final String title;
  final String artist;
  final String genre;
  final int durationMs;
  final String coverUrl;
  final String audioUrl;
}

class MusicTracksPage {
  const MusicTracksPage({
    required this.tracks,
    required this.hasMore,
    required this.nextOffset,
    this.expanding = false,
  });

  final List<MusicTrackItem> tracks;
  final bool hasMore;
  final int nextOffset;
  final bool expanding;
}

class UserStickerItem {
  const UserStickerItem({
    required this.id,
    required this.title,
    required this.imageUrl,
  });

  factory UserStickerItem.fromJson(Map<String, dynamic> json) {
    return UserStickerItem(
      id: (json['id'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      imageUrl: (json['imageUrl'] as String?)?.trim() ?? '',
    );
  }

  final String id;
  final String title;
  final String imageUrl;
}

class UserPlanItem {
  const UserPlanItem({
    required this.id,
    required this.placeName,
    required this.subtitle,
    required this.category,
    required this.scheduledAt,
    required this.note,
    required this.showToFriends,
    required this.showToNearby,
  });

  factory UserPlanItem.fromJson(Map<String, dynamic> json) {
    final scheduledRaw = json['scheduledAt'];
    DateTime scheduledAt;
    if (scheduledRaw is String && scheduledRaw.trim().isNotEmpty) {
      scheduledAt = DateTime.tryParse(scheduledRaw)?.toLocal() ?? DateTime.now();
    } else {
      scheduledAt = DateTime.now();
    }
    return UserPlanItem(
      id: (json['id'] as String?)?.trim() ?? '',
      placeName: (json['placeName'] as String?)?.trim() ?? '',
      subtitle: (json['subtitle'] as String?)?.trim() ?? '',
      category: (json['category'] as String?)?.trim() ?? 'other',
      scheduledAt: scheduledAt,
      note: (json['note'] as String?)?.trim() ?? '',
      showToFriends: json['showToFriends'] == true,
      showToNearby: json['showToNearby'] == true,
    );
  }

  final String id;
  final String placeName;
  final String subtitle;
  final String category;
  final DateTime scheduledAt;
  final String note;
  final bool showToFriends;
  final bool showToNearby;
}

class BlockedAccount {
  const BlockedAccount({
    required this.userId,
    required this.username,
    required this.avatarUrl,
  });

  factory BlockedAccount.fromJson(Map<String, dynamic> json) {
    return BlockedAccount(
      userId: (json['userId'] as String?)?.trim() ?? '',
      username: (json['username'] as String?)?.trim() ?? '',
      avatarUrl: (json['avatarUrl'] as String?)?.trim() ?? '',
    );
  }

  final String userId;
  final String username;
  final String avatarUrl;
}

class StoryFeed {
  const StoryFeed({required this.me, this.friends = const []});

  final StoryFeedMe me;
  final List<StoryFeedUser> friends;
}

class StoryFeedUser {
  const StoryFeedUser({
    required this.userId,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.isViewed,
    this.stories = const [],
  });

  factory StoryFeedUser.fromJson(Map<String, dynamic> json) {
    final rawStories = json['stories'];
    final stories = <PublishedStory>[];
    if (rawStories is List) {
      for (final item in rawStories) {
        if (item is Map) {
          stories.add(
            PublishedStory.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return StoryFeedUser(
      userId: (json['userId'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      username: (json['username'] as String?)?.trim() ?? '',
      avatarUrl: (json['avatarUrl'] as String?)?.trim() ?? '',
      isViewed: json['isViewed'] == true,
      stories: stories,
    );
  }

  final String userId;
  final String name;
  final String username;
  final String avatarUrl;
  final bool isViewed;
  final List<PublishedStory> stories;

  String get displayName {
    if (name.isNotEmpty) return name;
    if (username.isNotEmpty) return username;
    return 'User';
  }
}

class StoryFeedMe {
  const StoryFeedMe({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.hasStory,
    required this.isViewed,
    this.stories = const [],
  });

  factory StoryFeedMe.fromJson(Map<String, dynamic> json) {
    final rawStories = json['stories'];
    final stories = <PublishedStory>[];
    if (rawStories is List) {
      for (final item in rawStories) {
        if (item is Map) {
          stories.add(
            PublishedStory.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return StoryFeedMe(
      userId: (json['userId'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      avatarUrl: (json['avatarUrl'] as String?)?.trim() ?? '',
      hasStory: json['hasStory'] == true,
      isViewed: json['isViewed'] == true,
      stories: stories,
    );
  }

  final String userId;
  final String name;
  final String avatarUrl;
  final bool hasStory;
  final bool isViewed;
  final List<PublishedStory> stories;
}

class PublishedStory {
  const PublishedStory({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    required this.audience,
    this.musicTrackId,
    this.musicClipStartMs,
    this.musicClipDurationMs,
    this.musicAudioUrl,
    this.musicTitle,
    this.musicArtist,
    this.musicCoverUrl,
    this.createdAt,
    this.expiresAt,
    this.isViewed = false,
    this.likeCount = 0,
    this.likedByMe = false,
    this.authorName,
    this.authorUsername,
    this.authorAvatarUrl,
  });

  factory PublishedStory.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value)?.toLocal();
      }
      return null;
    }

    return PublishedStory(
      id: (json['id'] as String?)?.trim() ?? '',
      userId: (json['userId'] as String?)?.trim() ?? '',
      mediaUrl: (json['mediaUrl'] as String?)?.trim() ?? '',
      audience: (json['audience'] as String?)?.trim() ?? 'friends_only',
      musicTrackId: (json['musicTrackId'] as String?)?.trim(),
      musicClipStartMs: (json['musicClipStartMs'] as num?)?.toInt(),
      musicClipDurationMs: (json['musicClipDurationMs'] as num?)?.toInt(),
      musicAudioUrl: (json['musicAudioUrl'] as String?)?.trim(),
      musicTitle: (json['musicTitle'] as String?)?.trim(),
      musicArtist: (json['musicArtist'] as String?)?.trim(),
      musicCoverUrl: (json['musicCoverUrl'] as String?)?.trim(),
      createdAt: parseDate(json['createdAt']),
      expiresAt: parseDate(json['expiresAt']),
      isViewed: json['isViewed'] == true,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] == true,
      authorName: (json['authorName'] as String?)?.trim(),
      authorUsername: (json['authorUsername'] as String?)?.trim(),
      authorAvatarUrl: (json['authorAvatarUrl'] as String?)?.trim(),
    );
  }

  final String id;
  final String userId;
  final String mediaUrl;
  final String audience;
  final String? musicTrackId;
  final int? musicClipStartMs;
  final int? musicClipDurationMs;
  final String? musicAudioUrl;
  final String? musicTitle;
  final String? musicArtist;
  final String? musicCoverUrl;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool isViewed;
  final int likeCount;
  final bool likedByMe;
  final String? authorName;
  final String? authorUsername;
  final String? authorAvatarUrl;

  String get displayAuthorName {
    final name = authorName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final username = authorUsername?.trim() ?? '';
    if (username.isNotEmpty) return username;
    return 'User';
  }
}
