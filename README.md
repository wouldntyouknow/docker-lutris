# Lutris on Selkies (Fedora 44)

A Lutris gaming container based on `linuxserver/baseimage-selkies:fedora44`,
accessible from any web browser.

## Layout

```
.
├── Dockerfile
├── docker-compose.yml
├── LICENSE
├── .github/workflows/build.yml   # GHCR publish on push to main / wine-stable
└── root
    └── defaults
        ├── autostart             # openbox session (X11 fallback)
        ├── autostart_wayland     # labwc session (default)
        ├── menu.xml              # right-click menu under openbox
        └── menu_wayland.xml      # right-click menu under labwc
```

## Branches and image tags

| Branch | What it builds | Image tag |
|---|---|---|
| `main` *(default)* | Lutris + WineHQ **staging** Wine + WineGUI + Brave Origin Beta + Thunar / Double Commander / Midnight Commander | `ghcr.io/wouldntyouknow/docker-lutris:latest` |
| `wine-stable` | Lutris + Fedora **stable** Wine, no WineGUI, otherwise identical | `ghcr.io/wouldntyouknow/docker-lutris:wine-stable` |

Each commit on `main` is also published as an immutable
`ghcr.io/wouldntyouknow/docker-lutris:main-<short-sha>` tag, useful if
you want to pin a specific build and not surf the rolling `:latest`.

## Pull & run

The shipped `docker-compose.yml` references `:latest` (the `main` build).
Pull and start it:

```bash
docker compose pull
docker compose up -d
```

To use the `wine-stable` build instead, edit `docker-compose.yml` and
change the `image:` line:

```yaml
services:
  lutris:
    image: ghcr.io/wouldntyouknow/docker-lutris:wine-stable
```

…then `docker compose pull && docker compose up -d` again.

Once running, open **https://localhost:3001** (note: HTTPS, not HTTP —
the cert is self-signed, accept the warning). Default credentials are
`abc` / `changeme` unless you edit them in `docker-compose.yml`.

### Build locally (for development)

To build from the Dockerfile in your working tree instead of pulling
from GHCR, check out the branch you want and add a `build: .` line to
the service block:

```bash
git clone https://github.com/wouldntyouknow/docker-lutris.git
cd docker-lutris
git checkout main          # or: git checkout wine-stable
# in docker-compose.yml, add 'build: .' under the lutris service
docker compose build
docker compose up -d
```

The local build will retag whatever you set `image:` to — so leaving
`image: ghcr.io/wouldntyouknow/docker-lutris:latest` (or `:wine-stable`)
is fine; compose just builds locally and uses that tag instead of pulling.

## GPU acceleration

**Intel / AMD / nouveau (open source drivers):** the default `devices: /dev/dri`
mapping is what you want. Verify inside the container by opening a terminal
and running `vulkaninfo --summary`.

**Nvidia:** comment out the `devices:` block in `docker-compose.yml` and
uncomment the `runtime: nvidia` and `deploy.resources.reservations.devices`
blocks at the bottom. You also need:

```bash
sudo nvidia-ctk runtime configure --runtime=docker --set-as-default
sudo systemctl restart docker
```

## Things that will bite you if you skip them

**Resolution clamping is mandatory once GPU accel is on.** The base image's
default 16K virtual framebuffer is a non-issue with CPU rendering but eats
GPU VRAM once you pass `/dev/dri` or `--gpus all`. The `SELKIES_MANUAL_*` and
`MAX_RESOLUTION` env vars in compose handle this.

**`seccomp:unconfined` is needed.** Wine and many games trip Docker's default
seccomp filter. Skip this and games crash on launch with weird signal errors.

**Persist `/config`.** Lutris stores Wine prefixes, runners, and games under
`~/.local/share/lutris/` and `~/Games/`, all inside `/config`. Without the
volume mount you redownload everything on every restart.

**Anti-cheat with kernel components doesn't work.** EAC and BattlEye in their
kernel modes can't function in a container. Single-player and many co-op
titles are fine; competitive multiplayer with kernel anti-cheat isn't.

**32-bit on Fedora is on borrowed time.** F44 ships i686 multilib, but the
project keeps proposing to drop it. If you want a long-lived setup, consider
testing Wine's WoW64 mode (`WINEARCH=wow64`) or be ready to revisit the base.

