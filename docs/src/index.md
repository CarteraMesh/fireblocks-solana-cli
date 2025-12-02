# Introduction

Fireblocks<>Solana Rust integration providing enterprise-grade security with developer-friendly tooling.

## Features 

- **Remote Signing**: Use Fireblocks as a drop-in replacement for local Solana keypairs
- **Advanced Validation**: Deep program inspection via co-signer callbacks with strongly-typed Rust decoders

---

## Remote Signing

> [!WARNING]
> Standard Solana tooling stores private keys in cleartext on disk.

This integration replaces that with Fireblocks' secure key management.

Here's a transaction signed via Fireblocks sending [SOL on devnet](https://orb.helius.dev/tx/3M6xzFVSgj9fdpmFizFHU2UPRZWZPm1CrDcSpKe2Mo6uHkBxeK4XHJ8oW4ygwH275U3b5HP36pvdT7CiDfyzjq3t?cluster=devnet&tab=instruction):

<script src="https://asciinema.org/a/734209.js" id="asciicast-734209" async="true"></script>

### Configuration

Standard Solana config (`~/.config/solana/cli/config.yml`):

```yaml
json_rpc_url: "https://api.devnet.solana.com"
keypair_path: "/home/user/.config/solana/id.json"  # Cleartext private key
```

With Fireblocks integration:

```yaml
json_rpc_url: "https://api.devnet.solana.com"
keypair_path: "fireblocks://sandbox"  # Secure remote signing
```

This single line change enables:
- **Security**: Keys never leave Fireblocks' secure enclaves
- **Convenience**: Approve via mobile app (biometrics + PIN) or auto-sign with co-signer
- **Compliance**: Policy enforcement and comprehensive audit logs
- **Compatibility**: Works with existing Solana CLI and SDK code

See [Signer](./signer.md) for implementation details.

---

## Co-Signer Validation

Go beyond basic policy rules with deep transaction inspection. Use Carbon's strongly-typed Rust decoders to understand exactly what a transaction does before signing.

**Example**: Automatically approve USDC transfers under $1,000 but require manual approval for larger amounts.

See detailed examples and implementation guide [here](./cosigner.md).
