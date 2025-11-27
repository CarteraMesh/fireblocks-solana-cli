#!/bin/bash
set -e
cargo run -p solana-cli -- --config "${1:?}" create-stake-account --verbose ./scripts/stake.json  1.3
