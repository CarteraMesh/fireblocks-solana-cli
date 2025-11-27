#!/bin/bash
source scripts/keys.sh
cargo run -p spl-token-cli -- --config "${1:?}" close-mint --program-2022 --verbose $TOKEN22 || echo "$TOKEN22 already closed"
cargo run -p spl-token-cli -- --config "${1:?}" close-mint  --verbose $TOKEN || echo "$TOKEN already closed"
ADDRESS=$(cargo run -p solana-cli -- --config "${1}" address)
cargo run -p solana-cli -- --config "${1:?}" withdraw-stake  --verbose $STAKE "$ADDRESS" ALL || echo "$STAKE already closed"
