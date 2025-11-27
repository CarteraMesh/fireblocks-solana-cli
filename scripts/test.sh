#!/bin/bash
set -e

CONFIG="$HOME/.config/solana/cli/fb-test.yml"
if [ -n "$1" ]; then
    CONFIG="$1"
fi
./scripts/cleanup.sh "$CONFIG" || echo "warn cleanup failed"
./scripts/stake.sh "$CONFIG"
./scripts/create-token.sh "$CONFIG"
echo "Waiting for block confirmation..."
sleep 70
./scripts/cleanup.sh "$CONFIG"
