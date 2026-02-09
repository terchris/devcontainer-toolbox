# file: image/Dockerfile
# Description: Pre-built container image for devcontainer-toolbox
# This image contains everything from Dockerfile.base PLUS the toolbox
# scripts (manage/, additions/) at /opt/devcontainer-toolbox/.
#
# Build:
#   docker build -t devcontainer-toolbox:local -f image/Dockerfile .
#
# Multi-arch build:
#   docker buildx build --platform linux/amd64,linux/arm64 \
#     -t ghcr.io/ORG/REPO:TAG -f image/Dockerfile --push .

# =============================================================================
# BASE IMAGE
# =============================================================================
FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

# Switch to vscode user for all operations
USER vscode

# Set versions (update these as needed)
ARG NODE_VERSION=22.12.0

# Environment — no host-specific build args (those move to remoteEnv)
ENV DEBIAN_FRONTEND=noninteractive \
    DCT_HOME=/opt/devcontainer-toolbox

# =============================================================================
# COMBINED INSTALLATION — All tools in one layer for size optimization
# =============================================================================
# Packages: libcap2-bin, iputils-ping, iproute2, traceroute, jc, xdg-utils,
#           git, curl, wget, zip, unzip, ca-certificates, gnupg, lsb-release,
#           xz-utils, supervisor
# Tools: Node.js LTS, Docker CLI, GitHub CLI, Supervisord

RUN sudo rm -f /etc/apt/sources.list.d/yarn.list && \
    sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends \
        libcap2-bin \
        iputils-ping \
        iproute2 \
        traceroute \
        jc \
        xdg-utils \
        git \
        curl \
        wget \
        zip \
        unzip \
        ca-certificates \
        gnupg \
        lsb-release \
        xz-utils \
        supervisor && \
    # --- Node.js (direct binary install, multi-arch) ---
    ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
        amd64) NODE_ARCH="x64" ;; \
        arm64) NODE_ARCH="arm64" ;; \
        *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -o /tmp/node.tar.xz && \
    sudo tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 && \
    rm /tmp/node.tar.xz && \
    node --version && npm --version && \
    # --- GitHub CLI ---
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends gh && \
    # --- npm config for vscode user ---
    sudo mkdir -p /usr/local/lib/node_modules /usr/local/bin && \
    sudo chown -R vscode:vscode /usr/local/lib/node_modules /usr/local/bin && \
    npm config set prefix '/usr/local' && \
    echo 'export PATH=/usr/local/bin:$PATH' >> ~/.bashrc && \
    # --- Supervisord base structure ---
    sudo mkdir -p /var/log/supervisor /var/run/supervisor /etc/supervisor/conf.d && \
    sudo chown -R vscode:vscode /var/log/supervisor && \
    printf '%s\n' \
        '[supervisord]' \
        'nodaemon=true' \
        'user=root' \
        'logfile=/var/log/supervisor/supervisord.log' \
        'pidfile=/var/run/supervisord.pid' \
        'childlogdir=/var/log/supervisor' \
        '' \
        '[unix_http_server]' \
        'file=/var/run/supervisor.sock' \
        'chmod=0700' \
        '' \
        '[supervisorctl]' \
        'serverurl=unix:///var/run/supervisor.sock' \
        '' \
        '[rpcinterface:supervisor]' \
        'supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface' \
        '' \
        '[include]' \
        'files = /etc/supervisor/conf.d/*.conf' \
        | sudo tee /etc/supervisor/supervisord.conf > /dev/null && \
    # --- Cleanup ---
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archives/*

# =============================================================================
# TOOLBOX CODE — manage scripts, additions, libraries
# =============================================================================
# Copy toolbox code into the image at /opt/devcontainer-toolbox/
# Dev commands are made available via symlinks in /usr/local/bin/

COPY --chown=vscode:vscode .devcontainer/manage/ /opt/devcontainer-toolbox/manage/
COPY --chown=vscode:vscode .devcontainer/additions/ /opt/devcontainer-toolbox/additions/
COPY --chown=vscode:vscode version.txt /opt/devcontainer-toolbox/version.txt

# Create dev command symlinks in /usr/local/bin/ (already on PATH)
# Every dev-*.sh in manage/ gets a symlink so dev-help listings all work
RUN sudo ln -sf /opt/devcontainer-toolbox/manage/dev-setup.sh /usr/local/bin/dev-setup && \
    sudo ln -sf /opt/devcontainer-toolbox/manage/dev-help.sh /usr/local/bin/dev-help && \
    sudo ln -sf /opt/devcontainer-toolbox/manage/dev-check.sh /usr/local/bin/dev-check && \
    sudo ln -sf /opt/devcontainer-toolbox/manage/dev-docs.sh /usr/local/bin/dev-docs && \
    sudo ln -sf /opt/devcontainer-toolbox/manage/dev-env.sh /usr/local/bin/dev-env && \
    sudo ln -sf /opt/devcontainer-toolbox/manage/dev-services.sh /usr/local/bin/dev-services && \
    sudo ln -sf /opt/devcontainer-toolbox/manage/dev-test.sh /usr/local/bin/dev-test && \
    sudo ln -sf /opt/devcontainer-toolbox/manage/dev-template.sh /usr/local/bin/dev-template && \
    sudo ln -sf /opt/devcontainer-toolbox/manage/dev-update.sh /usr/local/bin/dev-update && \
    sudo ln -sf /opt/devcontainer-toolbox/manage/dev-logos.sh /usr/local/bin/dev-logos && \
    sudo ln -sf /opt/devcontainer-toolbox/manage/dev-cubes.sh /usr/local/bin/dev-cubes && \
    sudo ln -sf /opt/devcontainer-toolbox/manage/dev-log.sh /usr/local/bin/dev-log && \
    sudo ln -sf /opt/devcontainer-toolbox/manage/dev-tools.sh /usr/local/bin/dev-tools && \
    # Make all scripts executable (files owned by vscode via --chown)
    chmod +x /opt/devcontainer-toolbox/manage/*.sh && \
    chmod +x /opt/devcontainer-toolbox/additions/*.sh 2>/dev/null || true && \
    chmod +x /opt/devcontainer-toolbox/additions/lib/*.sh 2>/dev/null || true && \
    # Generate tools.json inventory at build time
    bash /opt/devcontainer-toolbox/manage/generate-tools-json.sh

# Install welcome message for new terminals
# Three locations needed for different shell startup paths:
#   /etc/profile.d/  — login shells (docker run -it, Podman)
#   /etc/bash.bashrc  — interactive non-login shells (standard bash)
#   ~/.bashrc         — VS Code terminals (uses --init-file which bypasses bash.bashrc)
RUN if [ -f /opt/devcontainer-toolbox/manage/dev-welcome.sh ]; then \
        sudo cp /opt/devcontainer-toolbox/manage/dev-welcome.sh /etc/profile.d/dev-welcome.sh && \
        sudo chmod +x /etc/profile.d/dev-welcome.sh && \
        if ! grep -q "dev-welcome.sh" /etc/bash.bashrc 2>/dev/null; then \
            echo "" | sudo tee -a /etc/bash.bashrc > /dev/null && \
            echo "# DevContainer Toolbox welcome message" | sudo tee -a /etc/bash.bashrc > /dev/null && \
            echo "source /etc/profile.d/dev-welcome.sh 2>/dev/null || true" | sudo tee -a /etc/bash.bashrc > /dev/null; \
        fi && \
        if ! grep -q "dev-welcome.sh" /home/vscode/.bashrc 2>/dev/null; then \
            echo "" >> /home/vscode/.bashrc && \
            echo "# DevContainer Toolbox welcome message" >> /home/vscode/.bashrc && \
            echo "source /etc/profile.d/dev-welcome.sh 2>/dev/null || true" >> /home/vscode/.bashrc; \
        fi \
    fi

# =============================================================================
# ENTRYPOINT — startup script that runs regardless of IDE
# =============================================================================
COPY --chown=vscode:vscode image/entrypoint.sh /opt/devcontainer-toolbox/entrypoint.sh
RUN chmod +x /opt/devcontainer-toolbox/entrypoint.sh

ENTRYPOINT ["/opt/devcontainer-toolbox/entrypoint.sh"]
CMD ["sleep", "infinity"]

# =============================================================================
# FINAL
# =============================================================================
ENV DEBIAN_FRONTEND=

# Container summary:
# - Python 3.12 (from base image)
# - Node.js 22.12.0 LTS with npm
# - Docker CLI 27.5.1 (static binary)
# - GitHub CLI (gh)
# - Supervisord for multi-process management
# - Toolbox scripts at /opt/devcontainer-toolbox/
# - Dev commands: dev-setup, dev-help, dev-check, dev-docs via /usr/local/bin/
# - ENTRYPOINT handles startup for all IDEs
# - Architectures: amd64, arm64
