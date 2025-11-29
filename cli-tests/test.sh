#!/bin/bash
set -e

CONFIG="$HOME/.config/solana/cli/fb-test.yml"
if [ -n "$1" ]; then
  CONFIG="$1"
fi
./cli-tests/cleanup.sh "$CONFIG" || echo "warn cleanup failed"
./cli-tests/stake.sh "$CONFIG"
./cli-tests/create-token.sh "$CONFIG"
echo "Waiting for block confirmation..."
sleep 70
./cli-tests/cleanup.sh "$CONFIG"
