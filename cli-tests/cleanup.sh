#!/bin/bash
source cli-tests/keys.sh
ADDRESS=$(cargo run -p solana-cli -- --config "${1:?}" address)
CONFIG="${1:?}"

function check_account() {
  cargo run -p solana-cli -- --config "$CONFIG" account "$1" 2>/dev/null
}

(check_account $TOKEN22 &&
  cargo run -p spl-token-cli -- --config "$CONFIG" close-mint --program-2022 --verbose $TOKEN22) ||
  echo "$TOKEN22 already closed"
(check_account $STAKE &&
  cargo run -p solana-cli -- --config "$CONFIG" withdraw-stake --verbose $STAKE "$ADDRESS" ALL) ||
  echo "$STAKE already closed"
(check_account $NONCE &&
  cargo run -p solana-cli -- --config "$CONFIG" withdraw-from-nonce-account --verbose $NONCE "$ADDRESS" 0.1) ||
  echo "$NONCE already closed"
