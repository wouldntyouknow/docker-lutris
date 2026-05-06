# Lutris on Selkies (Fedora 44)

A Lutris gaming container based on `linuxserver/baseimage-selkies:fedora44`,
accessible from any web browser, using modern streaming technology (think Sunshine, but without a client).

## Branches and image tags

| Branch | What it builds | Image tag |
|---|---|---|
| `main` *(default)* | Lutris + WineHQ **staging** Wine + WineGUI + Brave Origin Beta + Thunar / Double Commander / Midnight Commander | `ghcr.io/wouldntyouknow/docker-lutris:latest` |

Each commit on `main` is also published as an immutable
`ghcr.io/wouldntyouknow/docker-lutris:main-<short-sha>` tag, useful if
you want to pin a specific build and not surf the rolling `:latest`.

## Run

The shipped `docker-compose.yml` references `:latest` (the `main` build).
Download and start it:

```bash
docker compose up -d
```

Once running, open **https://host-ip:3001** (note: HTTPS, not HTTP —
the cert is self-signed, accept the warning). You can add basic auth
in the environment section, with keeping the default username (abc):

```yaml
    environment:
      - PASSWORD=yourpassword
```

Or with defining a new username:

      - DRINODE=/dev/dri/renderD128
      - DRI_NODE=/dev/dri/renderD128


This will add a super basic auth - do not expose this to the internet
without adding proper authentication mechanisms.


### Build locally

To build from the Dockerfile in your working tree instead of pulling
from GHCR, check out the branch you want and add a `build: .` line to
the service block:

```bash
git clone https://github.com/wouldntyouknow/docker-lutris.git
cd docker-lutris
git checkout main
# in docker-compose.yml, add 'build: .' under the lutris service
docker compose build
docker compose up -d
```

The local build will retag whatever you set `image:` to — so leaving
`image: ghcr.io/wouldntyouknow/docker-lutris:latest`
is fine; compose just builds locally and uses that tag instead of pulling.

## GPU acceleration

If you have multiple GPUs available, amend the compose file according to your
GPU needs (default is GPU0):

```yaml
    environment:
      - DRINODE=/dev/dri/renderD128
      - DRI_NODE=/dev/dri/renderD128
```

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

## Notes

**The container runs privileged.** Wine and many games trip Docker's default
seccomp filter. In the compose file, you'll most probably need either:

```yaml
    security_opt:
      - seccomp:unconfined
```

or

```yaml
    privileged: true
```

First, comment out `privileged: true` (#) and try. In case of issues, uncomment
and try again.

**Persistent `/config`.** Lutris stores Wine prefixes, runners, and games under
`~/.local/share/lutris/` and `~/Games/`, all inside `/config`. Without the
volume mount you redownload everything on every restart.

**Anti-cheat with kernel components doesn't work.** EAC and BattlEye in their
kernel modes can't function in a container. Single-player and many co-op
titles are fine; competitive multiplayer with kernel anti-cheat isn't.


