# zovi.app deep link hosting

Deploy the contents of this folder to the `zovi.app` origin (HTTPS).

## Required files

| Path | Purpose |
|------|---------|
| `/.well-known/apple-app-site-association` | iOS Universal Links (no `.json` extension, `application/json`) |
| `/.well-known/assetlinks.json` | Android App Links verification |
| `/u/*` | Fallback landing when the app is not installed |

## Nginx example

```nginx
server {
  server_name zovi.app www.zovi.app;

  location /.well-known/apple-app-site-association {
    default_type application/json;
  }

  location /.well-known/assetlinks.json {
    default_type application/json;
  }

  location /u/ {
    try_files /u/index.html =404;
  }
}
```

## Android fingerprint

Replace `REPLACE_WITH_UPLOAD_OR_DEBUG_SHA256` in `assetlinks.json`:

```bash
# debug
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# release: Play Console → App signing → SHA-256 certificate fingerprint
```

## Apple

- Team ID in AASA: `JK42R39DT5` (from Xcode `DEVELOPMENT_TEAM`)
- Bundle ID: `com.flywork.zovi`
- Enable Associated Domains capability for the App ID in Apple Developer portal

## App link format

`https://zovi.app/u/{username}`
