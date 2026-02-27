# git-fabric/terminal
#
# Claude Code + tmux + kubectl in a persistent container.
# Accessible via Tailscale SSH or kubectl exec.
# Runs as uid 1000 (fabric) throughout — no su required.

FROM node:22-alpine

# System tools
RUN apk add --no-cache \
    bash \
    curl \
    git \
    tmux \
    openssh-client \
    ca-certificates \
    jq \
    vim \
    less \
    procps

# kubectl
RUN KUBECTL_VERSION=$(curl -sSL https://dl.k8s.io/release/stable.txt) && \
    curl -sSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# node:22-alpine already has node user at uid 1000 / gid 1000
# Just ensure the home dir exists and is owned correctly
RUN mkdir -p /home/node && chown node:node /home/node

# Claude Code (global install — run as root then drop)
RUN npm install -g @anthropic-ai/claude-code

# Switch to node user (uid 1000) for runtime
USER node
WORKDIR /home/node

# tmux config: large scrollback, vi keys, sensible defaults
RUN mkdir -p /home/node/.config/tmux && printf '\
set -g history-limit 50000\n\
set -g mouse on\n\
set-window-option -g mode-keys vi\n\
set -g default-terminal "screen-256color"\n\
set -g status-style "bg=#1a1b26,fg=#a9b1d6"\n\
set -g status-left "#[fg=#7aa2f7][#S] "\n\
set -g status-right "#[fg=#9ece6a]%H:%M "\n\
' > /home/node/.config/tmux/tmux.conf

# Default: attach or create a named tmux session
CMD ["bash", "-c", "tmux new-session -A -s main"]
