#!/bin/bash
set -e
cargo run -p spl-token-cli -- --config "${1:?}" create-token \
  --decimals 6 --with-memo 'signed by fireblocks https://github.com/carteraMesh/fireblocks-solana-cli' \
  --program-2022 \
  --enable-confidential-transfers auto \
  --enable-close \
  --enable-transfer-hook \
  --enable-pause \
  --verbose \
  ./scripts/token22.json

cargo run -p spl-token-cli -- --config "${1}" create-token \
  --decimals 6 --with-memo 'signed by fireblocks https://github.com/carteraMesh/fireblocks-solana-cli' \
  --verbose \
  ./scripts/token.json
