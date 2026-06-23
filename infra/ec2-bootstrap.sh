#!/usr/bin/env bash
# Bootstrap a fresh Ubuntu 22.04/24.04 EC2 instance (t4g.medium / arm64 recommended)
# to run the fintech one-box stack. Run as root (or with sudo) once.
set -euo pipefail

echo "==> Installing Docker Engine + Compose plugin"
apt-get update -y
apt-get install -y ca-certificates curl git
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

# Optional: a 2 GB swapfile gives a t4g.small headroom during image builds.
if [ ! -f /swapfile ]; then
  echo "==> Creating 2G swapfile"
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

APP_DIR=/opt/fintech
echo "==> Deploy directory: $APP_DIR"
echo "    Copy the project here (rsync/scp the whole fintech/ folder, or git clone each app),"
echo "    create $APP_DIR/.env from .env.example, then run:"
echo
echo "    cd $APP_DIR"
echo "    docker compose --profile bank --profile casino --profile edge up -d --build"
echo
echo "==> Done. Docker $(docker --version)"
