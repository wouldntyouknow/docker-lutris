# Lutris on Selkies (Fedora 44)

A Lutris gaming container based on `linuxserver/baseimage-selkies:fedora44`,
accessible from any web browser.

## Layout

```
.
├── Dockerfile
├── docker-compose.yml
└── root
    └── defaults
        ├── autostart       # what runs in the desktop session (lutris)
        └── menu.xml        # right-click menu inside the desktop
```

## Pull & run

```bash
docker compose pull
docker compose up -d
```

Then open **https://localhost:3001** (note: HTTPS, not HTTP — the cert is
self-signed, accept the warning). Default credentials are `abc` / `changeme`
unless you edit them in `docker-compose.yml`.

### Build locally (for development)

If you've cloned the repo and want to build from source rather than pull the
published image, drop `build: .` into the `lutris` service in
`docker-compose.yml` and run:

```bash
docker compose build
docker compose up -d
```

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

