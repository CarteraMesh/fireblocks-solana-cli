#!/bin/bash
set -e
cargo run -p solana-cli -- --config "${1:?}" --verbose address-lookup-table create --output json > /tmp/lookup.json
cat /tmp/lookup.json
ADDRESS="$(jq -r '.lookupTableAddress'  /tmp/lookup.json)"
cargo run -p solana-cli -- --config "${1:?}" --verbose address-lookup-table deactivate  --bypass-warning  $ADDRESS
