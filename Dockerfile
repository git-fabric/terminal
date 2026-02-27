# git-fabric/terminal
#
# Claude Code + tmux + kubectl in a persistent container.
# Accessible via Tailscale SSH or kubectl exec.
# Runs as uid 1000 (node user from base image) — no su required.

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

# Claude Code (global install)
RUN npm install -g @anthropic-ai/claude-code

# node:22-alpine has node user at uid/gid 1000 — set up home dir
RUN mkdir -p /home/node/.config/tmux && chown -R node:node /home/node

# tmux config (copied as root, owned by node)
COPY --chown=node:node tmux.conf /home/node/.config/tmux/tmux.conf

USER node
WORKDIR /home/node

# Start a detached tmux session and keep the container alive.
# Attach via: kubectl exec -it <pod> -- tmux attach -t main
CMD ["bash", "-c", "tmux new-session -d -s main 2>/dev/null; exec sleep infinity"]
