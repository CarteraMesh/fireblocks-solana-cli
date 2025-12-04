#!/bin/bash
source ./cli-tests/keys.sh
cargo run -p fireblocks-solana-cli -- --config "${1:?}" program deploy --verbose --program-id ./cli-tests/program-memo.json
