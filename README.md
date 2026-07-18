# Bitirim Stranger

Premium, standalone player-interaction, identity-discovery & passport system for the **Qbox** framework.

> Not a NoPixel clone — Bitirim's own visual identity, inspired by modern AAA multiplayer UI (GTA Online-style glassmorphism).

## Features

- **Floating player indicator** — glassmorphism card anchored to the waist bone, billboarded to camera, with smooth fade in/out and distance-based scaling.
- **Stranger system** — players see `Stranger / ID: n` until identities are shared. Privacy-preserving and one-directional.
- **Circular G radial menu** — animated, blurred background, mouse + ESC support, fully modular (`config/menu.lua`).
- **Passport request flow** — one active request per sender/target, 10s countdown, accept/decline, anti-spam cooldown.
- **Persistent known-people** — accepted identities survive reconnect / restart / character reload (oxmysql).
- **Config-driven everything** — colours, glow, blur, fonts, scale, timings, distances, keys.

## Dependencies

- `qbx_core`
- `ox_lib`
- `oxmysql`

This resource **never modifies** any `qbx_*` resource.

## Install

1. Drop the `bitirim_stranger` folder into your `resources`.
2. Ensure it **after** its dependencies:
   ```cfg
   ensure qbx_core
   ensure ox_lib
   ensure oxmysql
   ensure bitirim_stranger
   ```
3. The database table `bitirim_known_identities` is **auto-created** on start.
   (Optional manual import: `server/database/schema.sql`.)

## Configuration

| File | Controls |
|------|----------|
| `config/config.lua` | Interaction key/distances, performance, passport timeout, identity persistence |
| `config/theme.lua`  | Colours, glass/blur, glow, typography, animation timings, indicator scale |
| `config/menu.lua`   | Radial menu structure (add categories/actions here) |
| `config/passport.lua` | Passport fields + their Qbox data mappings, license definitions |

## How identity discovery works

Yasin targets Murat and selects **Documents → Passport**. Murat receives a prompt
(`Yasin wants to show you their passport — [Y] Accept [N] Decline`, 10s).
On accept, Murat's passport UI opens and **Murat permanently learns Yasin**.
Yasin still sees `Stranger` for Murat until Murat shares back. Reveals are stored
one-directionally in the database, so learning someone never exposes your own identity.

## Architecture

```
config/   shared, data-only configuration
shared/   utilities (client + server)
server/   identity persistence, passport request lifecycle
client/   proximity scan, indicator render, interaction, radial, passport
web/      NUI (glassmorphism)
```

### Extending the menu

Add an entry to `Bitirim.Menu.entries` in `config/menu.lua` with an `action`
string, then handle that string in `client/modules/radial.lua -> dispatch()`.
Categories can nest via `submenu`. Disabled entries render dimmed.

## Network contract

| Dir | Event | Purpose |
|-----|-------|---------|
| C→S | `bitirim:server:onReady` | character loaded handshake |
| C→S | `bitirim:server:requestPassport(targetId)` | send passport request |
| C→S | `bitirim:server:passportAccept/Decline(requestId)` | respond |
| S→C | `bitirim:client:reveal({[serverId]=name})` | earned identity |
| S→C | `bitirim:client:conceal(serverId)` | cache cleanup on drop |
| S→C | `bitirim:client:passportPrompt/passportDismiss/passportShow` | request UI |
| S→C | `bitirim:client:notify(data)` | ox_lib notification |

## Compatibility note

The NUI uses `backdrop-filter` and `color-mix()`. These require a modern FiveM
client (current CEF / Chromium 111+), which auto-updating FiveM clients ship.

## Version

`0.1.0` — Step 1 (backend) + Step 2 (client + NUI) complete.
