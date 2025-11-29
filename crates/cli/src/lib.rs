use {clap::ArgMatches, solana_client::blockhash_query::BlockhashQuery};

macro_rules! ACCOUNT_STRING {
    () => {
        r#" Address is one of:
  * a base58-encoded public key
  * a path to a keypair file
  * a hyphen; signals a JSON-encoded keypair on stdin
  * the 'ASK' keyword; to recover a keypair via its seed phrase
  * a hardware wallet keypair URL (i.e. usb://ledger)"#
    };
}

macro_rules! pubkey {
    ($arg:expr, $help:expr) => {
        $arg.takes_value(true)
            .validator(is_valid_pubkey)
            .help(concat!($help, ACCOUNT_STRING!()))
    };
}

#[macro_use]
extern crate const_format;

extern crate serde_derive;

pub mod address_lookup_table;
pub mod checks;
pub mod clap_app;
pub mod cli;
pub mod cluster_query;
pub mod compute_budget;
pub mod feature;
pub mod inflation;
pub mod memo;
pub mod nonce;
pub mod program;
pub mod program_v4;
pub mod spend_utils;
pub mod stake;
pub mod test_utils;
pub mod validator_info;
pub mod vote;
pub mod wallet;

use solana_clap_utils::{
    input_parsers::{pubkey_of, value_of},
    nonce::NONCE_ARG,
    offline::{BLOCKHASH_ARG, SIGN_ONLY_ARG},
};

pub fn new_from_matches(matches: &ArgMatches<'_>) -> BlockhashQuery {
    let blockhash = value_of(matches, BLOCKHASH_ARG.name);
    let sign_only = matches.is_present(SIGN_ONLY_ARG.name);
    let nonce_account = pubkey_of(matches, NONCE_ARG.name);
    BlockhashQuery::new(blockhash, sign_only, nonce_account)
}
