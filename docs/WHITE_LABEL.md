# White Label Platform

## Phase 1 + 1.5 workflow

```bash
# 1) Create client from official template (schemaVersion 2)
dart run tool/create_client.dart \
  --id=acme \
  --app-name=Acme \
  --package=com.acme.app \
  --firebase-project=acme-123

# 2) Edit clients/acme/client.yaml + assets + manifest.json

# 3) Validate (fails build if incomplete)
dart run tool/validate_client.dart --client=acme

# 4) Generate split branding sources
dart run tool/generate_brand.dart --client=acme

# 5) Patch Android / iOS / Web (calls generate_brand + validate)
dart run tool/update_brand.dart --client=acme

# 6) Firebase options + .firebaserc
dart run tool/sync_firebase.dart --client=acme
```

### Migrate old clients (schema 1 → 2)

```bash
dart run tool/migrate_client.dart --client=shawka
# dry-run: dart run tool/migrate_client.dart --client=shawka --dry-run
```

## Layout

- `clients/templates/default_client.yaml` — official template (`schemaVersion: 2`)
- `clients/<id>/client.yaml` — source of truth
- `clients/<id>/manifest.json` — enterprise client manifest
- `lib/config/branding/` — `Branding.current` + `ClientConfig`
- `lib/config/branding/generated/` — `colors.g.dart`, `strings.g.dart`, `assets.g.dart`, `branding.g.dart`, `branding_values.g.dart`
- `assets/branding/current/` — active logo/splash/favicon
- `tool/migrations/` — schema migration engine (`v1_to_v2.dart`, …)

## Nested enterprise features (yaml)

```yaml
payment:
  paymob: { enabled: true }
  stripe: { enabled: false }
  cash: { enabled: true }

features:
  delivery: { enabled: true }
  pharmacy: { enabled: true }
  grocery: { enabled: true }
  wallet: { enabled: true }
  coupons: { enabled: true }
  subscriptions: { enabled: false }
  loyalty: { enabled: true }
  marketplace: { enabled: false }
```

Flags are available on `Branding.current` / `BrandingMeta` for Phase 2 dynamic business wiring.

## Pre-launch checklist (before first client / Store)

1. **Custom domain** — replace `matlobgo.web.app` with e.g. `shawka.app` / `app.shawka.com` (Firebase Hosting + DNS), then regenerate brand + update `web/index.html` / sitemap OG URLs.
2. **Support email** — use a mailbox that actually receives mail (`support@shawka.app`). Never ship `support@example.com` or an unused company inbox.
3. **Observability (week 1)** — Crashlytics, Analytics, Performance Monitoring enabled and dashboards watched.
4. **Backup** — Firestore, Storage, Remote Config, Cloud Functions before real production traffic.
5. **Release tag** — `v1.0.0-shawka` as the immutable baseline; no feature rush — soak 1–2 weeks, then plan `v1.1`.

## Pre-launch notes

- Dart package id remains `matlobgo` (technical / Firebase compatibility).
- User-facing brand is **Shawka | Skeena** / **شوكة وسكينة** via `Branding.current` / `AppBranding`.
- Hosting URL may still be `matlobgo.web.app` until a custom domain is attached — OG/canonical follow that URL.
- FCM Android channel ids (`matlobgo_*`) stay technical for existing installs; do not rename without a migration plan.
- Support email SSOT: `clients/shawka/client.yaml` → regenerate with `generate_brand`.

Active client palette is extracted from the official logo:

| Token | Hex | Role |
|-------|-----|------|
| primary | `#D4AF37` | Metallic gold |
| primary_light | `#F1D27B` | Gold highlight |
| primary_dark | `#8E6D2F` | Bronze gold |
| secondary | `#0A0A0A` | Ink / charcoal |
| accent | `#E8C547` | Bright gold |

Design system: `lib/core/theme/app_colors.dart` + `AppPalette` + `AppTheme` (M3 light/dark).

```bash
# Refresh logo derivatives + generate branding
dart run tool/prepare_brand_assets.dart --client=shawka
dart run tool/update_brand.dart --client=shawka
flutter pub run flutter_launcher_icons
```
