# syntax=docker/dockerfile:1
FROM ghcr.io/linuxserver/baseimage-selkies:fedora44

ENV TITLE=Lutris \
    SELKIES_DESKTOP=true \
    NO_FULL=true

RUN dnf install -y dnf-plugins-core && \
    rpm --import https://dl.winehq.org/wine-builds/winehq.key && \
    dnf config-manager addrepo --from-repofile=https://dl.winehq.org/wine-builds/fedora/44/winehq.repo && \
    dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-beta.s3.brave.com/brave-browser-beta.repo && \
    dnf install -y \
        # Core: Lutris + WineHQ staging (pulls 64- and 32-bit) + winetricks
        lutris \
        winehq-staging \
        winetricks \
        # Vulkan stack, 64- and 32-bit (essential for modern gaming, DXVK,
        # vkd3d-proton — Lutris downloads pinned DXVK/vkd3d builds per-prefix)
        mesa-vulkan-drivers \
        mesa-vulkan-drivers.i686 \
        vulkan-loader \
        vulkan-loader.i686 \
        vulkan-tools \
        # 32-bit OpenGL for older / 32-bit Wine games
        mesa-libGL.i686 \
        mesa-dri-drivers.i686 \
        # 32-bit audio so 32-bit Wine apps reach PulseAudio
        pulseaudio-libs.i686 \
        alsa-plugins-pulseaudio.i686 \
        # Performance tooling
        gamemode \
        mangohud \
        mangohud.i686 \
        # Common archive/utility tools used by winetricks and game installers
        cabextract \
        p7zip \
        p7zip-plugins \
        unzip \
        curl \
        xdg-utils \
        # File managers: Thunar (single-pane GUI), Double Commander
        # (Total Commander-style dual-pane GUI), Midnight Commander
        # (Norton/Far Commander-style TUI)
        Thunar \
        doublecmd-gtk \
        mc \
        # Fonts: Liberation for Western, Noto CJK so launchers and games
        # don't render Asian text as boxes
        python3-cairo \
        python3-gobject \
        cairo-gobject \
        liberation-fonts \
        google-noto-sans-fonts \
        google-noto-sans-cjk-fonts \
        # Web browser
        brave-origin-beta && \
    dnf clean all && \
    rm -rf \
        /var/cache/dnf \
        /tmp/* \
        /var/tmp/* \
        /usr/share/applications/com.brave.Origin.beta.desktop

# WineGUI: pull the latest RPM from the upstream GitHub releases.
# Pinned to whatever "latest" resolves to at build time — the GHCR image
# tags (latest, main-<sha>) make older versions retrievable if needed.
RUN WINEGUI_VERSION=$(curl -fsSL "https://api.github.com/repos/winegui/WineGUI/releases/latest" \
        | awk -F '"' '/tag_name/ {print $4; exit}') && \
    curl -fsSL -o /tmp/winegui.rpm \
        "https://github.com/winegui/WineGUI/releases/download/${WINEGUI_VERSION}/WineGUI-${WINEGUI_VERSION}.rpm" && \
    dnf install -y /tmp/winegui.rpm && \
    dnf clean all && \
    rm -rf /tmp/winegui.rpm /var/cache/dnf

# Defaults: autostart, openbox menu, anything else under root/
COPY /root /

EXPOSE 3000 3001
VOLUME /config
