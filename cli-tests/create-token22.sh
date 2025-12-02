#!/bin/bash
set -e
cargo run -p fireblocks-spl-token-cli -- --config "${1:?}" create-token \
  --decimals 6 --with-memo 'signed by fireblocks https://github.com/carteraMesh/fireblocks-solana' \
  --program-2022 \
  --enable-confidential-transfers auto \
  --enable-close \
  --enable-transfer-hook \
  --enable-pause \
  --verbose \
  ./cli-tests/token22.json
