#!/bin/bash
cargo run -p fireblocks-solana-cli -- --config "${1:?}" create-stake-account --verbose ./cli-tests/stake.json  1.3
