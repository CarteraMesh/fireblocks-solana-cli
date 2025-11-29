#!/bin/bash

target="${1:?}"

for i in account fee_calculator epoch_schedule native_token program_pack program_option instruction transaction message signature pubkey hash clock; do
  git ls-files $target | xargs sed -i s/solana_$i::/solana_sdk::$i::/g
done

git ls-files $target | xargs sed -i s/solana_seed_phrase::generate_seed_from_seed_phrase_and_passphrase/solana_sdk::signer::keypair::generate_seed_from_seed_phrase_and_passphrase/g
git ls-files $target | xargs sed -i s/solana_fee_structure/solana_sdk::fee/g
git ls-files $target | xargs sed -i s/solana_signer/solana_sdk::signature/g
git ls-files $target | xargs sed -i s/solana_keypair/solana_sdk::signature/g
git ls-files $target | xargs sed -i s/solana_rpc_client_nonce_utils/solana_client::nonce_utils/g
git ls-files $target | xargs sed -i s/solana_rpc_client/solana_client/g
git ls-files $target | xargs sed -i s/solana_signer::SignerError/solana_sdk::signature::SignerError/g
git ls-files $target | xargs sed -i s/solana_client_nonce_utils/solana_client::nonce_utils/g
git ls-files $target | xargs sed -i s/solana_client_api::config::RpcTransactionConfig/solana_client::rpc_config::RpcTransactionConfig/g
git ls-files $target | xargs sed -i s/solana_client_api::config/solana_client::rpc_config/g
git ls-files $target | xargs sed -i s/BlockhashQuery::new_from_matches/crate::new_from_matches/g crates/cli/src/*.rs
