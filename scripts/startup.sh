#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/startup-script.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Starting Tailscale setup: $(date) ==="

# -------------------------------------------------------
# 1. Install Tailscale from official package repository
# -------------------------------------------------------
if ! command -v tailscale &>/dev/null; then
  echo "Installing Tailscale..."
  curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg \
    | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
  curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list \
    | tee /etc/apt/sources.list.d/tailscale.list

  apt-get update -qq
  apt-get install -y -qq tailscale
else
  echo "Tailscale already installed, skipping."
fi

# -------------------------------------------------------
# 2. Enable IP forwarding (required for subnet routing)
# -------------------------------------------------------
echo "Configuring IP forwarding..."

SYSCTL_CONF="/etc/sysctl.d/99-tailscale.conf"
cat > "$SYSCTL_CONF" <<SYSCTL
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
SYSCTL

sysctl -p "$SYSCTL_CONF"

# -------------------------------------------------------
# 3. Start Tailscale as subnet router
#    Auth key is not logged to avoid leaking secrets
# -------------------------------------------------------
echo "Starting Tailscale..."
set +x
tailscale up \
  --authkey="${tailscale_auth_key}" \
  --advertise-routes="${subnet_cidr}" \
  --accept-dns=false \
  --hostname="$(hostname)" 2>&1 | grep -v -- "--authkey" >> "$LOG_FILE" || true

echo "Tailscale status:"
tailscale status

# -------------------------------------------------------
# 4. Install development tools
# -------------------------------------------------------
echo "Installing development tools..."
export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq \
  git \
  curl \
  wget \
  build-essential \
  unzip \
  jq \
  htop \
  tmux \
  vim

# -------------------------------------------------------
# 5. Enable unattended security updates
# -------------------------------------------------------
echo "Configuring unattended upgrades..."
apt-get install -y -qq unattended-upgrades

cat > /etc/apt/apt.conf.d/20auto-upgrades <<'AUTOUPGRADE'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
AUTOUPGRADE

echo "=== Startup script completed: $(date) ==="
