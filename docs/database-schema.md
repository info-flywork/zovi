# Zovi — Veri Tabanı Şema Analizi

Kaynak: Flutter mock domain (`UserRepository`, auth, presentation modelleri).  
Gerçek API/Freezed modeli yok; bu doküman production hedef şemasıdır.

**Önerilen stack:** PostgreSQL 16 + PostGIS  
**PK:** UUID (`gen_random_uuid()`)  
**Zaman:** `TIMESTAMPTZ`  
**Medya:** DB’de URL; dosya object storage (S3/R2/GCS)  
**Soft delete:** `deleted_at`  
**Sosyal model:** Takip/arkadaşlık isteği → kabul → karşılıklı **arkadaş** (`friend_requests` + `friendships`). Asimetrik Instagram follow yok.  
**Not:** Harita UI’daki x/y yerine gerçek `lat/lng`.

---

## İçindekiler

1. [Auth](#1-auth)
2. [Kullanıcı / Profil](#2-kullanıcı--profil)
3. [Sosyal Graf](#3-sosyal-graf)
4. [Mekan / Harita / Check-in / Plan](#4-mekan--harita--check-in--plan)
5. [İçerik — Pulse / Story / Müzik](#5-içerik--pulse--story--müzik)
6. [Gamification](#6-gamification)
7. [Sohbet](#7-sohbet)
8. [Bildirim](#8-bildirim)
9. [Medya & Upload (CDN)](#9-medya--upload-cdn)
10. [İlişki özeti](#ilişki-özeti)
11. [Enum sözlüğü](#enum-sözlüğü)
12. [Kritik index’ler](#kritik-indexler)
13. [Ürün kuralları → DB kısıtları](#ürün-kuralları--db-kısıtları)
14. [Migration sırası](#migration-sırası)

---

## 1) Auth

### `users`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| phone_e164 | VARCHAR(20) | YES | | E.164, unique |
| email | CITEXT | YES | | unique |
| password_hash | TEXT | YES | | social’da null |
| primary_auth | ENUM('phone','google','apple') | NO | | SignupFlow |
| phone_verified_at | TIMESTAMPTZ | YES | | |
| email_verified_at | TIMESTAMPTZ | YES | | |
| status | ENUM('active','suspended','deleted') | NO | 'active' | |
| last_login_at | TIMESTAMPTZ | YES | | |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |
| deleted_at | TIMESTAMPTZ | YES | | soft delete |

**Index:** `UNIQUE(phone_e164)`, `UNIQUE(email)`, `(status)`, `(created_at)`

---

### `oauth_identities`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| user_id | UUID | NO | | FK → users.id ON DELETE CASCADE |
| provider | ENUM('google','apple') | NO | | |
| subject | VARCHAR(255) | NO | | provider sub |
| email | CITEXT | YES | | |
| raw_profile | JSONB | YES | | |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |

**Index:** `UNIQUE(provider, subject)`, `(user_id)`

---

### `otp_challenges`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| phone_e164 | VARCHAR(20) | NO | | |
| code_hash | TEXT | NO | | **HASH** (bcrypt/argon2), asla düz kod |
| attempts | SMALLINT | NO | 0 | |
| max_attempts | SMALLINT | NO | 5 | |
| expires_at | TIMESTAMPTZ | NO | | ~5 dk |
| consumed_at | TIMESTAMPTZ | YES | | |
| created_at | TIMESTAMPTZ | NO | now() | |

**Index:** `(phone_e164, created_at DESC)`, `(expires_at)`

---

### `sessions`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| user_id | UUID | NO | | FK → users.id CASCADE |
| refresh_token_hash | TEXT | NO | | |
| access_jti | VARCHAR(64) | YES | | |
| device_id | VARCHAR(128) | YES | | |
| device_name | VARCHAR(120) | YES | | |
| platform | ENUM('ios','android','web','unknown') | NO | 'unknown' | |
| app_version | VARCHAR(32) | YES | | |
| ip | INET | YES | | |
| user_agent | TEXT | YES | | |
| expires_at | TIMESTAMPTZ | NO | | |
| revoked_at | TIMESTAMPTZ | YES | | |
| created_at | TIMESTAMPTZ | NO | now() | |
| last_used_at | TIMESTAMPTZ | YES | | |

**Index:** `(user_id)`, `(expires_at)`, `UNIQUE(refresh_token_hash)`

---

### `user_onboarding_flags`

Prefs (`intro_done`, `onboarding_done`, permission) karşılığı.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| user_id | UUID | NO | | PK/FK → users.id |
| intro_done | BOOLEAN | NO | false | |
| onboarding_done | BOOLEAN | NO | false | |
| notification_permission | ENUM('unknown','granted','denied') | NO | 'unknown' | |
| location_permission | ENUM('unknown','granted','denied') | NO | 'unknown' | |
| updated_at | TIMESTAMPTZ | NO | now() | |

> `preferred_language` buradan **kaldırıldı** → `user_settings.preferred_language` içinde tutuluyor (duplicate önlendi).

---

## 2) Kullanıcı / Profil

### `user_profiles`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| user_id | UUID | NO | | PK/FK → users.id |
| full_name | VARCHAR(50) | NO | | UI: tek isim 25, isim+soyisim 50 |
| username | CITEXT | NO | | max 25, UNIQUE (UI: EditProfileFieldType.username = 25) |
| avatar_url | TEXT | YES | | CDN URL (varyantlar CDN transform ile) |
| avatar_storage_key | TEXT | YES | | S3/R2 key — cache invalidate / silme için |
| avatar_blurhash | VARCHAR(64) | YES | | placeholder |
| bio | VARCHAR(150) | YES | | |
| location_text | VARCHAR(120) | YES | | şehir metni |
| birth_date | DATE | YES | | birthday screen |
| gender | VARCHAR(32) | YES | | opsiyonel |
| is_verified | BOOLEAN | NO | false | |
| account_privacy | ENUM('public','friends') | NO | 'public' | public = herkes; friends = sadece arkadaşlar |
| equipped_title_id | UUID | YES | | FK → titles.id |
| streak_count | INT | NO | 0 | denormalize |
| coins | INT | NO | 0 | check-in ödül |
| check_ins_count | INT | NO | 0 | counter |
| friends_count | INT | NO | 0 | `friendships` aggregate |
| pending_incoming_requests_count | INT | NO | 0 | opsiyonel cache: gelen pending istek |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |

**CHECK:** `char_length(username) BETWEEN 1 AND 25`, `char_length(full_name) BETWEEN 1 AND 50`, `char_length(bio) <= 150`  
**Index:** `UNIQUE(username)`, trigram(username), trigram(full_name)

> `equipped_title_id` ile `user_titles.is_equipped` tekrarını önlemek için: **tek kaynak** `user_profiles.equipped_title_id` olsun; `user_titles.is_equipped` kaldırılabilir. (Aşağıda güncellendi.)

---

### `profile_links`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| user_id | UUID | NO | | FK → users.id CASCADE |
| title | VARCHAR(80) | NO | | |
| url | TEXT | NO | | |
| sort_order | SMALLINT | NO | 0 | |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |

**Index:** `(user_id, sort_order)`

---

### `user_settings`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| user_id | UUID | NO | | PK/FK |
| push_enabled | BOOLEAN | NO | true | |
| chat_notifications | BOOLEAN | NO | true | |
| story_notifications | BOOLEAN | NO | true | |
| pulse_notifications | BOOLEAN | NO | true | like_pulse, comment |
| check_in_notifications | BOOLEAN | NO | true | |
| friend_request_notifications | BOOLEAN | NO | true | |
| plan_notifications | BOOLEAN | NO | true | plan invites/reminders |
| mention_notifications | BOOLEAN | NO | true | |
| map_share_location | BOOLEAN | NO | true | |
| show_online_status | BOOLEAN | NO | true | |
| preferred_language | VARCHAR(8) | NO | 'en' | UI: 12 dil (bkz. AppLanguage enum) |
| updated_at | TIMESTAMPTZ | NO | now() | |

---

## 3) Sosyal Graf

### Ürün kuralı (kaynak gerçek)

Zovi’de asimetrik “takip” yok. Akış:

1. A, B’ye **istek** atar (`friend_requests`, status=`pending`)
2. B **kabul** eder → `friendships` satırı oluşur (A ↔ B karşılıklı arkadaş)
3. B reddeder / A iptal eder → arkadaşlık oluşmaz

UI’daki “Takip Et” / “Takip isteği gönderildi” metinleri bu isteği kasteder; kabul sonrası ilişki **arkadaşlıktır**.

`AccountPrivacy.friends` = profil / içerik yalnızca `friendships` olanlara görünür.

Check-in tag, harita friends filter, plan “arkadaşlara göster”, pulse/story `friends_only` audience → hepsi `friendships` üzerinden çözülür.

---

### `friend_requests`

Bekleyen / sonuçlanmış arkadaşlık (takip) istekleri.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| from_user_id | UUID | NO | | FK → users (isteği atan) |
| to_user_id | UUID | NO | | FK → users (alan) |
| status | ENUM('pending','accepted','rejected','cancelled') | NO | 'pending' | |
| message | VARCHAR(280) | YES | | opsiyonel not |
| created_at | TIMESTAMPTZ | NO | now() | |
| responded_at | TIMESTAMPTZ | YES | | accept/reject anı |
| cancelled_at | TIMESTAMPTZ | YES | | gönderen iptal |

**CHECK:** `from_user_id <> to_user_id`  
**Index:**
- `(to_user_id, status, created_at DESC)` — gelen kutusu
- `(from_user_id, status, created_at DESC)` — giden istekler
- UNIQUE partial: `(from_user_id, to_user_id) WHERE status = 'pending'` — aynı yönde tek açık istek

**Kurallar:**
- Zaten `friendships` varsa yeni istek atılamaz
- Ters yönde de `pending` varsa: ürün kararı — ya ikinci istek engellenir ya da “karşılıklı istek = auto-accept” yapılır (önerilen: auto-accept + friendship)
- `accepted` olunca **aynı transaction** içinde `friendships` insert + her iki kullanıcıda `friends_count++` + notification `friend_accepted`

---

### `friendships`

Kabul sonrası tek gerçek arkadaşlık kaydı (undirected).

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| user_low_id | UUID | NO | | FK → users, `min(a,b)` |
| user_high_id | UUID | NO | | FK → users, `max(a,b)` |
| requested_by | UUID | YES | | FK → users; isteği kim başlattı (audit) |
| created_from_request_id | UUID | YES | | FK → friend_requests.id |
| created_at | TIMESTAMPTZ | NO | now() | |

**UNIQUE:** `(user_low_id, user_high_id)`  
**CHECK:** `user_low_id < user_high_id`

**Index:** `(user_low_id)`, `(user_high_id)` — “arkadaş listem” sorguları

**Arkadaş mı?**  
`EXISTS friendships WHERE (user_low_id, user_high_id) = (min(me,other), max(me,other))`

**Unfriend:** satır silinir; `friends_count--` (her iki taraf). İstersen soft-delete (`ended_at`) tutulabilir; MVP hard delete yeterli.

---

### ~~`follows`~~ / ~~`follow_requests`~~ — kaldırıldı

Eski Instagram modeli (asimetrik follow + ayrı friend) **kullanılmıyor**.  
Tek yol: `friend_requests` → `friendships`.

---

### `blocks`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| blocker_id | UUID | NO | | FK |
| blocked_id | UUID | NO | | FK |
| created_at | TIMESTAMPTZ | NO | now() | |
| reason | VARCHAR(200) | YES | | |

**PK:** `(blocker_id, blocked_id)`

---

### `restricts`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| restrictor_id | UUID | NO | | FK |
| restricted_id | UUID | NO | | FK |
| created_at | TIMESTAMPTZ | NO | now() | |

**PK:** `(restrictor_id, restricted_id)`

---

### `reports`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| reporter_id | UUID | NO | | FK |
| target_user_id | UUID | YES | | FK |
| target_type | ENUM('user','pulse','story','check_in','message','plan','sticker','comment') | NO | | |
| target_id | UUID | YES | | polimorfik |
| reason_code | VARCHAR(64) | YES | | |
| reason_text | TEXT | YES | | |
| status | ENUM('open','reviewed','closed') | NO | 'open' | |
| created_at | TIMESTAMPTZ | NO | now() | |
| reviewed_at | TIMESTAMPTZ | YES | | |
| reviewer_id | UUID | YES | | |

**Index:** `(status, created_at)`, `(target_type, target_id)`

---

## 4) Mekan / Harita / Check-in / Plan

### `venues`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| name | VARCHAR(200) | NO | | Babylon İstanbul |
| category | ENUM('music','cafe','park','culture','restaurant','other') | NO | 'other' | plan filter |
| subtitle | VARCHAR(200) | YES | | |
| address | TEXT | YES | | |
| city | VARCHAR(100) | YES | | |
| country_code | CHAR(2) | YES | | TR |
| lat | DOUBLE PRECISION | NO | | |
| lng | DOUBLE PRECISION | NO | | |
| location | GEOGRAPHY(POINT,4326) | NO | | PostGIS |
| external_place_id | VARCHAR(128) | YES | | Google/Mapbox |
| people_count_cache | INT | NO | 0 | MapVenue.peopleCount |
| is_active | BOOLEAN | NO | true | |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |

**Index:** `GIST(location)`, `(category)`, trigram(name), `UNIQUE(external_place_id)`

---

### `check_ins`

Ürünün merkez aksiyonu (`CheckInItem`, `ActiveMapCheckIn`, create sheet).

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| user_id | UUID | NO | | FK → users |
| venue_id | UUID | YES | | FK → venues |
| place_name | VARCHAR(200) | NO | | denorm |
| caption | VARCHAR(160) | YES | | max 160 |
| lat | DOUBLE PRECISION | NO | | |
| lng | DOUBLE PRECISION | NO | | |
| location | GEOGRAPHY(POINT,4326) | NO | | |
| photo_privacy | ENUM('public','friends') | NO | 'friends' | |
| stamp_id | UUID | YES | | FK → stamp_catalog |
| title_id | UUID | YES | | FK → titles |
| coins_earned | INT | NO | 0 | ~150 demo |
| is_active_on_map | BOOLEAN | NO | true | ActiveMapCheckIn |
| checked_at | TIMESTAMPTZ | NO | now() | |
| map_expires_at | TIMESTAMPTZ | YES | | haritada kalma |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |
| deleted_at | TIMESTAMPTZ | YES | | |

**CHECK:** `NOT (stamp_id IS NOT NULL AND title_id IS NOT NULL)` — kullanıcı ya stamp ya title kazanır (`CheckInUnlockResult` union).  
**Index:** `(user_id, checked_at DESC)`, `GIST(location)`, `(venue_id, checked_at DESC)`, `(is_active_on_map) WHERE deleted_at IS NULL`

---

### `check_in_photos`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| check_in_id | UUID | NO | | FK CASCADE |
| url | TEXT | NO | | CDN URL |
| storage_key | TEXT | NO | | S3/R2 key |
| thumb_url | TEXT | YES | | |
| blurhash | VARCHAR(64) | YES | | |
| sort_order | SMALLINT | NO | 0 | |
| width | INT | YES | | |
| height | INT | YES | | |
| mime_type | VARCHAR(64) | YES | | |
| byte_size | INT | YES | | |
| created_at | TIMESTAMPTZ | NO | now() | |

**Index:** `(check_in_id, sort_order)`

---

### `check_in_tags`

`CheckInFriend` tagged friends.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| check_in_id | UUID | NO | | FK CASCADE |
| tagged_user_id | UUID | NO | | FK → users |
| created_at | TIMESTAMPTZ | NO | now() | |

**PK:** `(check_in_id, tagged_user_id)`  
**Index:** `(tagged_user_id)`

---

### `plans`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| user_id | UUID | NO | | FK |
| venue_id | UUID | YES | | FK |
| place_name | VARCHAR(200) | NO | | |
| subtitle | VARCHAR(200) | YES | | |
| category | ENUM('music','cafe','park','culture','restaurant','other') | YES | | |
| scheduled_at | TIMESTAMPTZ | NO | | selectedTime |
| note | TEXT | YES | | |
| show_to_friends | BOOLEAN | NO | true | |
| show_to_nearby | BOOLEAN | NO | false | |
| status | ENUM('scheduled','cancelled','done') | NO | 'scheduled' | |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |
| cancelled_at | TIMESTAMPTZ | YES | | |

**Index:** `(user_id, scheduled_at)`, `(scheduled_at) WHERE status='scheduled'`

> **UI gap:** `AddPlanDetailsView` şu an yalnızca `time-of-day` (`00:00`..`22:00`) topluyor, tarih seçici yok. `scheduled_at` TIMESTAMPTZ dolu tutulabilmesi için UI'ya date picker eklenmeli veya default olarak "bugün/yarın" atanmalı.

---

### `plan_invitees`

UI’daki friend avatars için.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| plan_id | UUID | NO | | FK CASCADE |
| user_id | UUID | NO | | FK |
| status | ENUM('invited','accepted','declined','cancelled') | NO | 'invited' | plan iptali/geri çekme |
| created_at | TIMESTAMPTZ | NO | now() | |

**PK:** `(plan_id, user_id)`

---

### `map_presence`

Canlı konum / aktif check-in. Ephemeral veya kısa TTL.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| user_id | UUID | NO | | PK/FK |
| lat | DOUBLE PRECISION | NO | | |
| lng | DOUBLE PRECISION | NO | | |
| location | GEOGRAPHY(POINT,4326) | NO | | |
| accuracy_m | DOUBLE PRECISION | YES | | |
| active_check_in_id | UUID | YES | | FK → check_ins |
| is_anonymous | BOOLEAN | NO | false | nearby anon |
| heading | DOUBLE PRECISION | YES | | |
| updated_at | TIMESTAMPTZ | NO | now() | TTL için |
| expires_at | TIMESTAMPTZ | YES | | stale cleanup |

**Index:** `GIST(location)`, `(updated_at)`, `(expires_at)`

---

## 5) İçerik — Pulse / Story / Müzik

### `music_tracks`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| title | VARCHAR(200) | NO | | |
| artist | VARCHAR(200) | NO | | |
| genre | VARCHAR(80) | YES | | |
| duration_ms | INT | NO | | |
| cover_url | TEXT | YES | | |
| audio_url | TEXT | NO | | |
| is_active | BOOLEAN | NO | true | |
| created_at | TIMESTAMPTZ | NO | now() | |

**Index:** trigram(title), trigram(artist), `(is_active)`

---

### `pulses`

Camera compose + PulseItem. Intro: 24 saat canlı.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| user_id | UUID | NO | | FK |
| media_url | TEXT | NO | | CDN URL (composed) |
| storage_key | TEXT | NO | | S3/R2 key |
| media_type | ENUM('image','video') | NO | 'image' | |
| thumb_url | TEXT | YES | | |
| blurhash | VARCHAR(64) | YES | | placeholder |
| width | INT | YES | | |
| height | INT | YES | | |
| mime_type | VARCHAR(64) | YES | | |
| byte_size | BIGINT | YES | | video için BIGINT |
| duration_ms | INT | YES | | video |
| caption | TEXT | YES | | |
| audience | ENUM('public','friends_only') | NO | 'friends_only' | |
| venue_id | UUID | YES | | FK |
| place_name | VARCHAR(200) | YES | | denorm |
| lat | DOUBLE PRECISION | YES | | |
| lng | DOUBLE PRECISION | YES | | |
| music_track_id | UUID | YES | | FK |
| music_clip_start_ms | INT | YES | | |
| music_clip_duration_ms | INT | YES | | |
| overlays | JSONB | YES | | text/stamp transform |
| like_count | INT | NO | 0 | |
| comment_count | INT | NO | 0 | gelecek |
| view_count | INT | NO | 0 | |
| created_at | TIMESTAMPTZ | NO | now() | |
| expires_at | TIMESTAMPTZ | NO | | created_at + 24h |
| deleted_at | TIMESTAMPTZ | YES | | |

> **Overlay `stampId` doğrulaması:** `overlays.stamps[].stampId` `stamp_catalog.id` VEYA `stickers.id` olabilir. JSONB FK vermez → doğrulama: (a) `kind: "catalog"|"sticker"` alanı zorunlu tut, (b) INSERT/UPDATE trigger'ıyla referansın var + `deleted_at IS NULL` olduğunu doğrula, (c) `stamp_catalog` / `stickers` yalnız **soft-delete** edilebilsin (hard delete sadece cleanup job'undan). Kullanıcı sadece kendi unlock'ladığı stamp'leri kullanabilecekse `user_stamps` kontrolü uygulama katmanında.

**`overlays` JSONB örneği:**

```json
{
  "texts": [
    {
      "id": "...",
      "text": "...",
      "fontId": "...",
      "bold": false,
      "italic": false,
      "underline": false,
      "uppercase": false,
      "align": "center",
      "fontSize": 24,
      "letterSpacing": 0,
      "lineHeight": 1.2,
      "color": "#FFFFFF",
      "x": 0.5,
      "y": 0.4,
      "scale": 1,
      "rotation": 0
    }
  ],
  "stamps": [
    {
      "stampId": "...",
      "x": 0.3,
      "y": 0.6,
      "scale": 1,
      "rotation": 0
    }
  ]
}
```

**Index:** `(user_id, created_at DESC)`, `(expires_at) WHERE deleted_at IS NULL`, `(audience, created_at DESC)`

---

### `stories`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| user_id | UUID | NO | | FK |
| media_url | TEXT | NO | | CDN URL |
| storage_key | TEXT | NO | | S3/R2 key |
| media_type | ENUM('image','video') | NO | 'image' | |
| thumb_url | TEXT | YES | | |
| blurhash | VARCHAR(64) | YES | | |
| width | INT | YES | | |
| height | INT | YES | | |
| mime_type | VARCHAR(64) | YES | | |
| byte_size | BIGINT | YES | | |
| duration_ms | INT | YES | | video |
| caption | TEXT | YES | | |
| audience | ENUM('public','friends_only') | NO | 'friends_only' | |
| is_reel | BOOLEAN | NO | false | StoryMediaItem.isReel |
| venue_id | UUID | YES | | FK → venues |
| place_name | VARCHAR(200) | YES | | denorm (StoryMediaItem.label) |
| lat | DOUBLE PRECISION | YES | | |
| lng | DOUBLE PRECISION | YES | | |
| music_track_id | UUID | YES | | FK → music_tracks |
| music_clip_start_ms | INT | YES | | |
| music_clip_duration_ms | INT | YES | | |
| overlays | JSONB | YES | | pulses ile aynı şema (text/stamp) |
| like_count | INT | NO | 0 | |
| view_count | INT | NO | 0 | |
| created_at | TIMESTAMPTZ | NO | now() | |
| expires_at | TIMESTAMPTZ | NO | | +24h |
| deleted_at | TIMESTAMPTZ | YES | | |

**Index:** `(user_id, created_at DESC)`, `(expires_at) WHERE deleted_at IS NULL`

> Alternatif: `pulses` + `stories` tek `media_posts(kind)` tablosunda birleştirilebilir.

---

### `story_views`

`markStoryViewed` / `isViewed` karşılığı.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| viewer_id | UUID | NO | | FK |
| story_id | UUID | NO | | FK CASCADE |
| viewed_at | TIMESTAMPTZ | NO | now() | |

**PK:** `(viewer_id, story_id)`  
**Index:** `(story_id)`

---

### `story_likes`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| user_id | UUID | NO | | FK |
| story_id | UUID | NO | | FK CASCADE |
| created_at | TIMESTAMPTZ | NO | now() | |

**PK:** `(user_id, story_id)`

---

### `pulse_tags`

Pulse'da tag'lenen arkadaşlar. UI `PulseItem.friendAvatars`.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| pulse_id | UUID | NO | | FK CASCADE |
| tagged_user_id | UUID | NO | | FK → users |
| created_at | TIMESTAMPTZ | NO | now() | |

**PK:** `(pulse_id, tagged_user_id)`  
**Index:** `(tagged_user_id)`

---

### `pulse_likes`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| user_id | UUID | NO | | FK |
| pulse_id | UUID | NO | | FK CASCADE |
| created_at | TIMESTAMPTZ | NO | now() | |

**PK:** `(user_id, pulse_id)`

---

### `media_drafts`

Camera drafts (`draft_{ms}.png`, overlays/music).

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| user_id | UUID | NO | | FK |
| local_path_or_url | TEXT | NO | | |
| thumb_url | TEXT | YES | | |
| meta | JSONB | YES | | overlays/music |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |

**Index:** `(user_id, updated_at DESC)`

---

## 6) Gamification

### `stamp_catalog`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| slug | VARCHAR(80) | NO | | UNIQUE |
| title | VARCHAR(120) | NO | | veya i18n key |
| title_key | VARCHAR(120) | YES | | |
| image_url | TEXT | NO | | CDN URL (PNG w/ transparency) |
| storage_key | TEXT | NO | | S3/R2 key |
| blurhash | VARCHAR(64) | YES | | |
| pack | VARCHAR(80) | NO | | zovi_stamps, night_owl |
| is_unlockable | BOOLEAN | NO | true | |
| sort_order | INT | NO | 0 | |
| created_at | TIMESTAMPTZ | NO | now() | |
| deleted_at | TIMESTAMPTZ | YES | | soft-delete zorunlu (overlay ref bütünlüğü) |

**Index:** `(pack)`, `UNIQUE(slug)`

---

### `user_stamps`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| user_id | UUID | NO | | FK |
| stamp_id | UUID | NO | | FK |
| source_check_in_id | UUID | YES | | FK |
| earned_at | TIMESTAMPTZ | NO | now() | |

**PK:** `(user_id, stamp_id)`  
**Index:** `(user_id, earned_at DESC)`

---

### `titles`

Night Flame, Explorer, Kurucu Kral vb.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| slug | VARCHAR(80) | NO | | UNIQUE |
| label | VARCHAR(120) | NO | | |
| label_key | VARCHAR(120) | YES | | i18n |
| emoji | VARCHAR(16) | YES | | |
| image_url | TEXT | YES | | |
| requirement | JSONB | YES | | `{"type":"night_checkins","target":5}` |
| created_at | TIMESTAMPTZ | NO | now() | |

---

### `user_titles`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| user_id | UUID | NO | | FK |
| title_id | UUID | NO | | FK |
| progress_current | INT | NO | 0 | 8/10 |
| progress_target | INT | YES | | |
| unlocked_at | TIMESTAMPTZ | YES | | |
| created_at | TIMESTAMPTZ | NO | now() | |

**UNIQUE:** `(user_id, title_id)`  
> `is_equipped` kaldırıldı — equipped title tek kaynak `user_profiles.equipped_title_id` (FK) üzerinden yönetilir (duplicate state riski önlendi).

---

### `stickers`

Create sticker — `my_creations` UGC.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| owner_id | UUID | NO | | FK |
| name | VARCHAR(80) | NO | | |
| description | TEXT | YES | | |
| image_url | TEXT | NO | | CDN URL |
| storage_key | TEXT | NO | | S3/R2 key |
| blurhash | VARCHAR(64) | YES | | |
| width | INT | YES | | |
| height | INT | YES | | |
| mime_type | VARCHAR(64) | YES | | |
| byte_size | INT | YES | | |
| style | ENUM('modern','sketch','colorful','anime') | NO | 'modern' | |
| visibility | ENUM('private','friends','public') | NO | 'private' | |
| moderation_status | ENUM('pending','approved','rejected','flagged') | NO | 'pending' | public UGC review |
| moderation_note | TEXT | YES | | rejection reason |
| flag_count | INT | NO | 0 | rapor sayacı |
| use_count | INT | NO | 0 | pulse/story/message'da kullanım |
| created_at | TIMESTAMPTZ | NO | now() | |
| deleted_at | TIMESTAMPTZ | YES | | soft-delete (overlay ref bütünlüğü) |

**Index:** `(owner_id, created_at DESC)`, `(visibility, moderation_status) WHERE deleted_at IS NULL`, `(moderation_status) WHERE moderation_status='pending'`

---

### `streak_days`

Lifestyle streak — kategori bazlı günlük aktivite.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| user_id | UUID | NO | | FK |
| day | DATE | NO | | |
| category | ENUM('culture','food','coffee','gym','music','park') | NO | | |
| points | INT | NO | 1 | |
| source_check_in_id | UUID | YES | | FK |
| created_at | TIMESTAMPTZ | NO | now() | |

**PK:** `(user_id, day, category)`  
**Index:** `(user_id, day DESC)`

---

### `coin_transactions`

Coin ledger. `user_profiles.coins` sadece cache; gerçek kaynak bu tablo.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| user_id | UUID | NO | | FK |
| delta | INT | NO | | +150 / -x |
| reason | ENUM('check_in','streak_bonus','title_unlock','stamp_unlock','plan_completed','admin_grant','spend_sticker','spend_font','other') | NO | | |
| source_type | VARCHAR(40) | YES | | check_in/title/... |
| source_id | UUID | YES | | polimorfik referans |
| balance_after | INT | NO | | denorm cache |
| created_at | TIMESTAMPTZ | NO | now() | |

**Index:** `(user_id, created_at DESC)`

---

### `tribes`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| slug | VARCHAR(80) | NO | | UNIQUE |
| emoji | VARCHAR(16) | NO | | |
| title_key | VARCHAR(120) | NO | | i18n |
| subtitle_key | VARCHAR(120) | YES | | |
| avatar_url | TEXT | YES | | |
| unlock_target | INT | NO | 10 | |
| conversation_id | UUID | YES | | FK → conversations |
| member_count_cache | INT | NO | 0 | |
| created_at | TIMESTAMPTZ | NO | now() | |

---

### `tribe_members`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| tribe_id | UUID | NO | | FK |
| user_id | UUID | NO | | FK |
| progress | INT | NO | 0 | |
| unlocked_at | TIMESTAMPTZ | YES | | |
| joined_at | TIMESTAMPTZ | NO | now() | |

**PK:** `(tribe_id, user_id)`

---

## 7) Sohbet

### `conversations`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| type | ENUM('dm','group') | NO | | |
| name | VARCHAR(120) | YES | | grup |
| avatar_url | TEXT | YES | | |
| tribe_id | UUID | YES | | FK |
| streak_count | INT | NO | 0 | GroupInfo |
| created_by | UUID | YES | | FK |
| created_at | TIMESTAMPTZ | NO | now() | |
| updated_at | TIMESTAMPTZ | NO | now() | |
| last_message_at | TIMESTAMPTZ | YES | | inbox sort |
| last_message_preview | VARCHAR(280) | YES | | denorm |
| deleted_at | TIMESTAMPTZ | YES | | |

**Index:** `(last_message_at DESC)`, `(type)`, `(tribe_id)`

---

### `conversation_members`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| conversation_id | UUID | NO | | FK CASCADE |
| user_id | UUID | NO | | FK |
| role | ENUM('member','admin') | NO | 'member' | |
| notifications_on | BOOLEAN | NO | true | GroupInfoView `_notificationsOn` |
| is_muted | BOOLEAN | NO | false | |
| translate_language | VARCHAR(8) | YES | | GroupInfoView `_languageLabel` (per-üye çeviri) |
| last_read_at | TIMESTAMPTZ | YES | | unread |
| joined_at | TIMESTAMPTZ | NO | now() | |
| left_at | TIMESTAMPTZ | YES | | |

**PK:** `(conversation_id, user_id)`  
**Index:** `(user_id)`, `(user_id, last_read_at)`

**DM kuralı:** `type=dm` → tam 2 aktif üye.

---

### `dm_pairs`

DM tekilliği.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| conversation_id | UUID | NO | | PK/FK |
| user_low_id | UUID | NO | | |
| user_high_id | UUID | NO | | |

**UNIQUE:** `(user_low_id, user_high_id)`  
**CHECK:** `user_low_id < user_high_id`

---

### `messages`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| conversation_id | UUID | NO | | FK CASCADE |
| sender_id | UUID | NO | | FK |
| type | ENUM('text','image','stamp','voice') | NO | | |
| text | TEXT | YES | | |
| media_url | TEXT | YES | | image/voice |
| thumb_url | TEXT | YES | | |
| stamp_id | UUID | YES | | FK → stamp_catalog (katalog stamp) |
| sticker_id | UUID | YES | | FK → stickers (kullanıcı UGC sticker) |
| voice_duration_ms | INT | YES | | |
| reply_to_message_id | UUID | YES | | FK self |
| created_at | TIMESTAMPTZ | NO | now() | |
| edited_at | TIMESTAMPTZ | YES | | |
| deleted_at | TIMESTAMPTZ | YES | | swipe-delete |

**CHECK:** message_type ile ilgili alanların uyumlu doldurulması (type='text' → text NOT NULL; type='image' → media_url NOT NULL; type='voice' → media_url + voice_duration_ms NOT NULL; type='stamp' → (stamp_id XOR sticker_id) NOT NULL).  
**Index:** `(conversation_id, created_at DESC)`, `(sender_id)`

---

### `message_reads`

Grup sohbetlerinde read receipts (DM için de kullanılabilir). `conversation_members.last_read_at` toplu; bu tablo per-message granülerlik verir (opsiyonel — MVP'de sadece `last_read_at` yeterli).

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| message_id | UUID | NO | | FK CASCADE |
| user_id | UUID | NO | | FK |
| read_at | TIMESTAMPTZ | NO | now() | |

**PK:** `(message_id, user_id)`  
**Index:** `(user_id, read_at DESC)`

---

### `chat_requests`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| from_user_id | UUID | NO | | FK |
| to_user_id | UUID | NO | | FK |
| preview | VARCHAR(280) | YES | | |
| status | ENUM('pending','accepted','declined') | NO | 'pending' | |
| is_unread | BOOLEAN | NO | true | |
| created_at | TIMESTAMPTZ | NO | now() | |
| responded_at | TIMESTAMPTZ | YES | | |
| resulting_conversation_id | UUID | YES | | FK |

**Index:** `(to_user_id, status, created_at DESC)`

---

## 8) Bildirim

### `notifications`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| recipient_id | UUID | NO | | FK |
| actor_id | UUID | YES | | FK |
| type | ENUM('friend_request','friend_accepted','like_story','like_story_agg','like_pulse','like_pulse_agg','check_in','chat_request','chat_message','plan_invite','plan_reminder','mention','story_reply','stamp_unlocked','title_unlocked','tribe_unlocked') | NO | | messageKey |
| object_type | VARCHAR(40) | YES | | story/check_in/friend_request/… |
| object_id | UUID | YES | | |
| thumbnail_url | TEXT | YES | | |
| agg_count | INT | YES | | people liked |
| title_key | VARCHAR(120) | YES | | |
| body_key | VARCHAR(120) | YES | | |
| payload | JSONB | YES | | named args |
| action | ENUM('none','accept_friend_request','open_story','open_chat','open_pulse','open_plan','open_profile','open_check_in','open_tribe','send_message') | NO | 'none' | |
| created_at | TIMESTAMPTZ | NO | now() | |
| read_at | TIMESTAMPTZ | YES | | |
| deleted_at | TIMESTAMPTZ | YES | | |

**Index:** `(recipient_id, created_at DESC)`, `(recipient_id) WHERE read_at IS NULL`

**UI messageKey eşlemesi (sosyal):**

| type | messageKey / UI |
|------|-----------------|
| friend_request | notifications_friend_request (“sana arkadaşlık isteği gönderdi”) |
| friend_accepted | notifications_accepted_friend (“arkadaşlık isteğini kabul etti”) |

> Eski asimetrik `follow` / `follow_request` / `started_following` type’ları **kullanılmıyor**. UI’daki “Takip Et” / “Takip isteği gönderildi” metinleri `friend_request` lifecycle’ına map’lenir.

---

### `account_deletion_requests`

`DeleteAccountSheet` free-text reason topluyor. Bu tabloya yazılıp async silme akışına düşer.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| user_id | UUID | NO | | FK → users |
| reason | TEXT | YES | | UI reason field |
| status | ENUM('pending','processing','cancelled','completed') | NO | 'pending' | |
| requested_at | TIMESTAMPTZ | NO | now() | |
| scheduled_purge_at | TIMESTAMPTZ | YES | | +30 gün grace |
| processed_at | TIMESTAMPTZ | YES | | |

**Index:** `(status, scheduled_purge_at)`, `(user_id)`

---

### `device_push_tokens`

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| user_id | UUID | NO | | FK |
| token | TEXT | NO | | UNIQUE |
| platform | ENUM('ios','android') | NO | | |
| created_at | TIMESTAMPTZ | NO | now() | |
| last_seen_at | TIMESTAMPTZ | YES | | |

**Index:** `(user_id)`, `UNIQUE(token)`

---

## 9) Medya & Upload (CDN)

### Genel yaklaşım

- **Depolama:** dosya S3/R2/GCS'te, DB'de sadece `storage_key` + `url`.
- **URL formatı:** `https://cdn.zovi.app/<storage_key>` (CloudFront/R2 önünde). Varyantlar (thumb/2x/webp) CDN transform (imgproxy/Cloudflare Images) ile üretilir → DB'de tek `url` yeter.
- **Upload:** client → backend'den presigned PUT URL alır → CDN'e direct upload → commit endpoint'i `upload_intents` kaydını `committed` yapar ve hedef tabloya (pulse/story/…) `storage_key`'i yazar.
- **Silme:** entity soft-delete (`deleted_at`) → cleanup job `media_cleanup_queue`'ya blob'u ekler → job N gün grace sonrası CDN'den siler.

---

### `upload_intents`

Presigned URL verilen ama henüz commit edilmemiş yüklemeler. Orphan blob önlemi.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| user_id | UUID | NO | | FK → users |
| purpose | ENUM('avatar','pulse','story','check_in_photo','sticker','chat_image','chat_voice') | NO | | |
| storage_key | TEXT | NO | | S3/R2 key (UNIQUE) |
| mime_type | VARCHAR(64) | YES | | client-declared |
| max_bytes | BIGINT | YES | | server enforced |
| status | ENUM('pending','committed','expired','failed') | NO | 'pending' | |
| committed_entity_type | VARCHAR(40) | YES | | pulse/story/... |
| committed_entity_id | UUID | YES | | |
| expires_at | TIMESTAMPTZ | NO | | ~15 dk |
| created_at | TIMESTAMPTZ | NO | now() | |
| committed_at | TIMESTAMPTZ | YES | | |

**Index:** `UNIQUE(storage_key)`, `(user_id, created_at DESC)`, `(status, expires_at)`  
**Cleanup job:** `status='pending' AND expires_at < now()` → `status='expired'` + blob delete.

---

### `media_cleanup_queue`

Soft-delete edilen entity'lerin CDN blob temizlik kuyruğu.

| Kolon | Tip | Null | Default | Açıklama |
|-------|-----|------|---------|----------|
| id | UUID | NO | gen_random_uuid() | PK |
| storage_key | TEXT | NO | | silinecek blob |
| source_entity_type | VARCHAR(40) | YES | | pulse/story/check_in_photo/sticker/avatar |
| source_entity_id | UUID | YES | | |
| delete_after_at | TIMESTAMPTZ | NO | | grace period sonu (ör. +7 gün) |
| status | ENUM('scheduled','deleted','failed') | NO | 'scheduled' | |
| attempts | SMALLINT | NO | 0 | |
| last_error | TEXT | YES | | |
| created_at | TIMESTAMPTZ | NO | now() | |
| processed_at | TIMESTAMPTZ | YES | | |

**Index:** `(status, delete_after_at)`, `UNIQUE(storage_key)`

---

### Alan konvansiyonları (medya içeren tüm tablolar)

Zorunlu (medya PK'sı gibi düşün):
- `storage_key TEXT NOT NULL` — CDN'de dosya key'i
- `url TEXT NOT NULL` (veya `media_url`) — CDN URL

Önerilen (bilinen değerlerse doldur):
- `thumb_url TEXT` — küçük placeholder (opsiyonel; CDN transform varsa gereksiz)
- `blurhash VARCHAR(64)` — lazy-load placeholder
- `width INT`, `height INT`, `mime_type VARCHAR(64)`, `byte_size BIGINT`
- Video ise: `duration_ms INT`

Bu konvansiyon uygulandı: `check_in_photos`, `pulses`, `stories`, `stickers`, `stamp_catalog`, `user_profiles.avatar_*`. Mesajlarda (`messages.media_url`) chat özelinde eklenebilir (opsiyonel; genelde tek boyut yeter).

---

## İlişki özeti

```
users 1──1 user_profiles
users 1──* profile_links / sessions / oauth_identities / user_settings
users *──* users          (friend_requests: from → to, pending/accepted/…)
users *──* users          (friendships: undirected pair — kabul sonrası)
users *──* users          (blocks, restricts)
users 1──* check_ins ──* check_in_photos
check_ins *──* users      (check_in_tags — sadece arkadaşlar tag’lenebilir)
check_ins N──1 venues
check_ins N──1 stamp_catalog / titles
users 1──* pulses / stories / media_drafts
stories 1──* story_views / story_likes
pulses 1──* pulse_likes
pulses N──1 music_tracks
users 1──* plans *──* users (plan_invitees — arkadaşlar)
users 1──1 map_presence
users *──* stamp_catalog  (user_stamps)
users *──* titles         (user_titles)
users 1──* stickers
users *──* tribes         (tribe_members)
tribes 1──1? conversations
conversations 1──* conversation_members / messages
conversations 1──1 dm_pairs (DM)
users 1──* notifications / chat_requests / device_push_tokens
users 1──* coin_transactions / account_deletion_requests
users 1──* upload_intents
```

---

## Enum sözlüğü

| Enum | Değerler | Kullanım |
|------|----------|----------|
| primary_auth / SignupFlow | phone, google, apple | users |
| user_status | active, suspended, deleted | users |
| account_privacy | public, friends | profiles, check_in photos — friends = friendships |
| audience | public, friends_only | pulses, stories — friends_only = friendships |
| venue_category | music, cafe, park, culture, restaurant, other | venues, plans |
| friend_request_status | pending, accepted, rejected, cancelled | friend_requests |
| message_type | text, image, stamp, voice | messages |
| conversation_type | dm, group | conversations |
| sticker_style | modern, sketch, colorful, anime | stickers |
| streak_category | culture, food, coffee, gym, music, park | streak_days |
| notification_type | friend_request, friend_accepted, like_story, like_story_agg, like_pulse, like_pulse_agg, check_in, chat_request, chat_message, plan_invite, plan_reminder, mention, story_reply, stamp_unlocked, title_unlocked, tribe_unlocked | notifications |
| notification_action | none, accept_friend_request, open_story, open_chat, open_pulse, open_plan, open_profile, open_check_in, open_tribe, send_message | notifications |
| app_language | en, tr, de, it, fr, ja, es, ru, ko, hi, pt, zh | user_settings.preferred_language (UI: AppLanguage) |
| coin_reason | check_in, streak_bonus, title_unlock, stamp_unlock, plan_completed, admin_grant, spend_sticker, spend_font, other | coin_transactions |
| deletion_status | pending, processing, cancelled, completed | account_deletion_requests |
| plan_invitee_status | invited, accepted, declined, cancelled | plan_invitees |
| report_target | user, pulse, story, check_in, message, plan, sticker, comment | reports |
| upload_purpose | avatar, pulse, story, check_in_photo, sticker, chat_image, chat_voice | upload_intents |
| upload_status | pending, committed, expired, failed | upload_intents |
| media_cleanup_status | scheduled, deleted, failed | media_cleanup_queue |
| sticker_moderation | pending, approved, rejected, flagged | stickers |
| permission_state | unknown, granted, denied | onboarding flags |
| platform | ios, android, web, unknown | sessions / push |
| plan_status | scheduled, cancelled, done | plans |
| media_type | image, video | pulses / stories |
| member_role | member, admin | conversation_members |

---

## Kritik index’ler

| Öncelik | Index | Neden |
|---------|-------|-------|
| Yüksek | venues/check_ins/map_presence `GIST(location)` | Harita nearby + venues |
| Yüksek | stories/pulses `(expires_at)` partial | 24s feed |
| Yüksek | notifications `(recipient_id, created_at)` | inbox |
| Yüksek | messages `(conversation_id, created_at)` | chat scroll |
| Orta | user_profiles.username CITEXT unique | lookup / search |
| Orta | friendships `(user_low_id)` / `(user_high_id)` | arkadaş listesi |
| Orta | friend_requests `(to_user_id, status)` | gelen istekler |
| Orta | check_ins `(user_id, checked_at)` | profil check-in tab |
| Düşük | music_tracks trigram | compose search |

---

## Ürün kuralları → DB kısıtları

- `full_name` VARCHAR(50); UI: boşluksuz max 25, boşluklu max 50
- `username` CITEXT max 15 (create) / 25 (edit) — **ürün kararıyla tek değere hizalanmalı**
- Check-in `caption` max 160
- Pulse/Story `expires_at = created_at + 24h` (intro copy)
- **Sosyal:** istek (`friend_requests`) → kabul → `friendships`. Asimetrik follow yok. UI “Takip Et” = istek gönder
- `AccountPrivacy.friends` / audience `friends_only` / harita friends / check-in tag → hepsi `friendships`
- Counter: `friends_count` (+ opsiyonel `pending_incoming_requests_count`); `followers_count` / `following_count` yok
- Medya: DB’de URL; dosya object storage’da
- Soft delete: users, pulses, stories, messages, stickers, check_ins, conversations

---

## Migration sırası

1. **Auth:** users → oauth_identities → otp_challenges → sessions → user_onboarding_flags  
2. **Profil:** user_profiles → profile_links → user_settings  
3. **Sosyal:** friend_requests → friendships → blocks → restricts → reports  
4. **Mekan:** venues → check_ins → check_in_photos → check_in_tags → plans → plan_invitees → map_presence  
5. **İçerik:** music_tracks → pulses → stories → story_views → story_likes → pulse_likes → pulse_tags → media_drafts  
6. **Gamification:** stamp_catalog → user_stamps → titles → user_titles → stickers → streak_days → coin_transactions → tribes → tribe_members  
7. **Chat:** conversations → conversation_members → dm_pairs → messages → message_reads → chat_requests  
8. **Bildirim:** notifications → device_push_tokens → account_deletion_requests  
9. **Medya:** upload_intents → media_cleanup_queue  

---

## Şema denetim özeti

### Sosyal model (güncel ürün kararı)

- **İstek at → kabul → arkadaş.** Kaynak: `friend_requests` + `friendships`.
- `follows` / `follow_requests` / asimetrik follow **kaldırıldı**.
- UI “Takip Et” / “Takip isteği gönderildi” → `friend_requests.pending`.
- “arkadaşlık isteğini kabul etti” → `friendships` + `friend_accepted` notification.
- `account_privacy = friends` → sadece arkadaşlar görür (private Instagram follow-approval değil).
- Profil counter: `friends_count` (+ opsiyonel gelen pending count). `followers_count` / `following_count` yok.

### Diğer düzeltmeler / eklemeler (önceki tur)

- `otp_challenges.code_hash` → HASH
- `preferred_language` → `user_settings`
- `user_titles.is_equipped` kaldırıldı → `user_profiles.equipped_title_id`
- `messages`: `stamp_id` + `sticker_id`
- `check_ins`: stamp XOR title CHECK
- Medya: `storage_key`, upload_intents, media_cleanup_queue
- `coin_transactions`, `account_deletion_requests`, `pulse_tags` (opsiyonel/gelecek)

### UI gap notları

- Connections ekranı mock’ta “takipçi / takip” Instagram dili kullanıyor; ürün modeline göre **arkadaş listesi + gelen istekler** olarak hizalanmalı
- Create profile username max 15 vs edit 25 — tek değere sabitlenmeli
- `AddPlanDetailsView` tarih toplamıyor → `scheduled_at`
- Comment/hashtag UI’da yok

---

## Mevcut uygulama durumu (önemli)

Şu an kalıcı olanlar yalnızca:

- Secure storage: `access_token`
- Prefs: `is_first_launch`, `intro_done`, `onboarding_done`

Profil, check-in, story, chat, bildirim vb. hepsi memory/mock (`UserRepository` + presentation).  
Bu doküman backend’e geçerken hedef şemadır.
