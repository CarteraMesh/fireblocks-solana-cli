# Introduction

Fireblocks<>Solana Rust integration

## Features 

 - Remote signing support
 - Advanced Co-signer program validation


## Remote Signing

Here is a modified version of solana CLI which uses fireblocks as a signing provider to send some [SOL](https://orb.helius.dev/tx/3M6xzFVSgj9fdpmFizFHU2UPRZWZPm1CrDcSpKe2Mo6uHkBxeK4XHJ8oW4ygwH275U3b5HP36pvdT7CiDfyzjq3t?cluster=devnet&tab=instruction).

<script src="https://asciinema.org/a/734209.js" id="asciicast-734209" async="true"></script>

### Setup

This is solana's configuration file:

```yaml
---
json_rpc_url: "https://api.devnet.solana.com"
keypair_path: "/home/user/.config/solana/id.json"
```

This informs the solana [CLI](https://solana.com/docs/intro/installation#solana-config) and [SDK](https://docs.rs/solana-cli-config/2.3.6/solana_cli_config/struct.Config.html#structfield.keypair_path) where the private key is stored (which is cleartext)

### Secure & Convenient

```yaml
keypair_path: fireblocks://sandbox
```

This small config enables seamless integration with Fireblocks SDK and all benefits around security, convenience, and flexibility.
Transactions can be signed automatically with a co-signer or approved from your secure mobile device via biometrics and PIN. Comprehensive policies can block unwanted requests.

See [Signer](./signer.md) reference for implementation details.

---

## Co-Signer Validation

Use rust with strongly typed program decoder to accurately understand the transaction and validate it before signing.

See examples [here](./cosigner.md)
