#!/bin/bash
set -e
cargo run -p spl-token-cli -- --config "${1}" create-token \
  --decimals 6 \
  --with-memo 'signed by fireblocks https://github.com/carteraMesh/fireblocks-solana' \
  --verbose \
  ./cli-tests/token.json
