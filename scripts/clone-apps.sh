#!/usr/bin/env bash
# Clone the five app repos as siblings of docker-compose.yml so the build
# contexts (./Portfolio, ./mock-bank, ...) resolve. Run from the repo root:
#   ./scripts/clone-apps.sh
set -euo pipefail
ORG="https://github.com/george-garcia"

clone () { # repo  target-dir  [branch]
  local repo="$1" dir="$2" branch="${3:-}"
  if [ -d "$dir/.git" ]; then
    echo "==> $dir exists, pulling latest"
    git -C "$dir" pull --ff-only || true
    return
  fi
  if [ -n "$branch" ]; then
    git clone --branch "$branch" "$ORG/$repo.git" "$dir"
  else
    git clone "$ORG/$repo.git" "$dir"
  fi
}

clone Portfolio             Portfolio
clone Ticketing-tool-client Ticketing-tool-client
clone Ticketing-tool-server Ticketing-tool-server
clone mock-bank             mock-bank           feat/partner-apis-and-card-reveal
clone lucky-spin-casino     mock-gambling-site  main
clone Glow                  Glow                main

echo
echo "All app repos are in place next to docker-compose.yml."
