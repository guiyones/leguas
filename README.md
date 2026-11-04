# Léguas

A walking game. You log your walks, and your traveler moves across a hand-painted world, clearing phases, beating bosses and filling a trophy with badges as the kilometers add up.

The name comes from the *légua* (league), the old unit of distance used on Brazil's colonial roads. The interface is in Brazilian Portuguese and built mainly for phones.

## What it does

- **Walks and routes:** log a walk in a few taps (date, distance, time), or save a route you repeat and reuse it. Stair sessions count too.
- **A world made of regions and phases:** each region follows a real trail and is split into phases with landmarks and a boss stretch. Progress on the map is proportional to the distance you've walked.
- **Progression:** XP per kilometer, levels and titles (Caminhante → Andarilho → … → Lenda das Léguas), daily missions, achievements, and a celebration screen when you clear a phase or level up.
- **Trophies:** every region has a trophy with one slot per phase. Earned badges snap into place, missing ones show as silhouettes.
- **Passwordless login:** email → 6-digit code → session. No passwords stored.

## How it's built

- **Rails 8.1** on Ruby 4.0, **SQLite**, **Hotwire** (Turbo + Stimulus) and **Tailwind CSS 4**
- **Solid Queue, Solid Cache and Solid Cable**, so there's no Redis to run
- **Kamal** + Thruster for deployment
- World content (regions, phases, landmarks, bosses) lives in YAML under `config/world/`, and the art is SVG in `app/assets/images/art/`. None of it goes into the database.
- Progress is never stored. Position, XP and badges are always derived from the sum of the user's walks (`User::Journey`), so there's no state that can drift out of sync.
- Built test-first with **Minitest**, including system tests. Logic tests run against a small fake world in `test/world/`.
- **CI on GitHub Actions:** Brakeman, bundler-audit, importmap audit, RuboCop, unit and system tests.

## Running locally

```bash
bin/setup        # installs gems, prepares the database, starts the server
bin/dev          # starts Rails + Tailwind watcher
```

Tests:

```bash
bin/rails test
bin/rails test:system
```

## Status

In active development. Next up is a Strava integration so walks can be imported automatically (design in `docs/superpowers/specs/`).
