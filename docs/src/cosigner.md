# Co-signer Validation

## Problem

Fireblocks policies provide transaction-level controls (amount limits, destination whitelists) but lack deep inspection of Solana program instructions. For complex DeFi operations, you need to understand what the transaction actually does before signing.

## Solution: Carbon + Co-signer Callbacks

[Carbon](https://github.com/sevenlabs-hq/carbon) is a Rust framework that decodes Solana program instructions into strongly-typed data structures. We leverage it for transaction validation in [co-signer callbacks](https://developers.fireblocks.com/reference/response-object).

> [!NOTE]
> Carbon was originally built for indexers but works perfectly for transaction validation due to its strongly-typed decoders.

### How It Works

```text
Fireblocks Transaction Request
         |
         v
Co-signer Callback Handler (your Rust service)
         |
         v
Carbon Decoder (parse instruction data)
         |
         v
Business Logic (validate against rules)
         |
         v
Response: APPROVE | REJECT | RETRY
```

The callback handler has 30 seconds to respond with:
- `APPROVE` - Sign the transaction
- `REJECT` - Deny with optional reason (logged in audit)
- `RETRY` - Retry up to 20 times over 60 minutes
- `IGNORE` - Skip this approval (for multi-sig scenarios)

## Benefits

- **Type Safety**: Compile-time guarantees on instruction parsing
- **Performance**: Rust's speed ensures sub-second validation
- **Maintainability**: Strongly-typed code vs parsing raw bytes
- **Testing**: Unit test business rules against real transaction data
- **Coverage**: 60+ popular Solana programs already supported

## Example: CCTP Transfer Limits

Circle's [CCTP](https://developers.circle.com/cctp) enables cross-chain USDC transfers. The protocol burns USDC on the source chain and mints on the destination. 

**Business Requirement**: Block any cross-chain transfer exceeding 1,000 USDC.

With Carbon, we decode the [depositForBurn](https://github.com/circlefin/solana-cctp-contracts/blob/master/programs/v2/token-messenger-minter-v2/src/token_messenger_v2/instructions/deposit_for_burn.rs) instruction:

```rust
use carbon_circle_cctp_decoder::TokenMessengerMinterV2Instruction;

pub struct CctpValidator;

#[async_trait]
impl Processor for CctpValidator {
    type InputType = InstructionProcessorInputType<TokenMessengerMinterV2Instruction>;

    async fn process(
        &mut self,
        data: Self::InputType,
        _metrics: Arc<MetricsCollection>,
    ) -> CarbonResult<()> {
        let (metadata, ix, _nested_instructions, _idx) = data;

        match ix.data {
            TokenMessengerMinterV2Instruction::DepositForBurn(args) => {
                let amount_usdc = args.params.amount / 1_000_000; // USDC has 6 decimals
                
                if amount_usdc > 1_000 {
                    // Return REJECT to Fireblocks callback
                    return Err(format!("Transfer amount {} USDC exceeds limit", amount_usdc));
                }
                
                tracing::info!(amount_usdc, "CCTP transfer approved");
                Ok(())
            }
            _ => Ok(()), // Ignore other instructions
        }
    }
}

## Advanced: Cross-Program Invocations (CPIs)

Carbon decodes nested instruction calls, critical for DeFi protocols. Example: Jupiter's swap router internally calls the Token Program to perform swaps.

**Use Case**: Validate that a Jupiter swap doesn't exceed slippage tolerance or interacts only with approved liquidity pools.

```rust
use carbon_jupiter_swap_decoder::JupiterSwapInstruction;

match ix.data {
    JupiterSwapInstruction::SharedAccountsRoute(args) => {
        // Inspect swap parameters, check slippage, validate pools
        let slippage_bps = args.quoted_out_amount - args.slippage_bps;
        if slippage_bps > MAX_SLIPPAGE {
            return Err("Slippage too high");
        }
    }
    _ => {}
}
```

## Implementation Requirements

1. Deploy co-signer infrastructure (AWS Nitro Enclaves or GCP Confidential Space)
2. Configure callback endpoint in Fireblocks console
3. Implement Carbon-based validation logic
4. Test against real Solana transactions
5. Production monitoring and audit log integration

**Note**: Co-signer infrastructure requires significant compute resources (large EC2 Nitro instances for SGX/enclave support). 

### Program Decoders

Decoders for most popular Solana programs are published and maintained:

| Crate Name                                 | Description                               | Program ID                                   |
| ------------------------------------------ | ----------------------------------------- | -------------------------------------------- |
| `carbon-address-lookup-table-decoder`      | Address Lookup Table Decoder              | AddressLookupTab1e1111111111111111111111111  |
| `carbon-associated-token-account-decoder`  | Associated Token Account Decoder          | ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL |
| `carbon-bonkswap-decoder`                  | Bonkswap Program Decoder                  | BSwp6bEBihVLdqJRKGgzjcGLHkcTuzmSo1TQkHepzH8p |
| `carbon-boop-decoder`                      | Boop Decoder                              | boop8hVGQGqehUK2iVEMEnMrL5RbjywRzHKBmBE7ry4  |
| `carbon-bubblegum-decoder`                 | Bubblegum Decoder                         | BGUMAp9Gq7iTEuizy4pqaxsTyUCBK68MDfK752saRPUY |
| `carbon-circle-cctp-decoder`               | Circle Decoder                            | CCTPV2Sm4AdWt5296sk4P66VBZ7bEhcARwFaaS9YPbeC |
| `carbon-drift-v2-decoder`                  | Drift V2 Program Decoder                  | dRiftyHA39MWEi3m9aunc5MzRF1JYuBsbn6VPcn33UH  |
| `carbon-fluxbeam-decoder`                  | Fluxbeam Program Decoder                  | FLUXubRmkEi2q6K3Y9kBPg9248ggaZVsoSFhtJHSrm1X |
| `carbon-gavel-decoder`                     | Gavel Pool Decoder                        | srAMMzfVHVAtgSJc8iH6CfKzuWuUTzLHVCE81QU1rgi  |
| `carbon-heaven-decoder`                    | Heaven Program Decoder                    | HEAVENoP2qxoeuF8Dj2oT1GHEnu49U5mJYkdeC8BAX2o |
| `carbon-jupiter-dca-decoder`               | Jupiter DCA Program Decoder               | DCA265Vj8a9CEuX1eb1LWRnDT7uK6q1xMipnNyatn23M |
| `carbon-jupiter-limit-order-decoder`       | Jupiter Limit Order Program Decoder       | jupoNjAxXgZ4rjzxzPMP4oxduvQsQtZzyknqvzYNrNu  |
| `carbon-jupiter-limit-order-2-decoder`     | Jupiter Limit Order 2 Program Decoder     | j1o2qRpjcyUwEvwtcfhEQefh773ZgjxcVRry7LDqg5X  |
| `carbon-jupiter-perpetuals-decoder`        | Jupiter Perpetuals Program Decoder        | PERPHjGBqRHArX4DySjwM6UJHiR3sWAatqfdBS2qQJu  |
| `carbon-jupiter-swap-decoder`              | Jupiter Swap Program Decoder              | JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4  |
| `carbon-kamino-farms-decoder`              | Kamino Farms Program Decoder              | FarmsPZpWu9i7Kky8tPN37rs2TpmMrAZrC7S7vJa91Hr |
| `carbon-kamino-lending-decoder`            | Kamino Lend Decoder                       | KLend2g3cP87fffoy8q1mQqGKjrxjC8boSyAYavgmjD  |
| `carbon-kamino-limit-order-decoder`        | Kamino Limit Order Program Decoder        | LiMoM9rMhrdYrfzUCxQppvxCSG1FcrUK9G8uLq4A1GF  |
| `carbon-kamino-vault-decoder`              | Kamino Vault Decoder                      | kvauTFR8qm1dhniz6pYuBZkuene3Hfrs1VQhVRgCNrr  |
| `carbon-lifinity-amm-v2-decoder`           | Lifinity AMM V2 Program Decoder           | 2wT8Yq49kHgDzXuPxZSaeLaH1qbmGXtEyPy64bL7aD3c |
| `carbon-marginfi-v2-decoder`               | Marginfi V2 Program Decoder               | MFv2hWf31Z9kbCa1snEPYctwafyhdvnV7FZnsebVacA  |
| `carbon-marinade-finance-decoder`          | Marinade Finance Program Decoder          | MarBmsSgKXdrN1egZf5sqe1TMai9K1rChYNDJgjq7aD  |
| `carbon-memo-program-decoder`              | SPL Memo Program Decoder                  | Memo1UhkJRfHyvLMcVucJwxXeuD728EqVDDwQDxFMNo  |
| `carbon-meteora-damm-v2-decoder`           | Meteora DAMM V2 Program Decoder           | cpamdpZCGKUy5JxQXB4dcpGPiikHawvSWAd6mEn1sGG  |
| `carbon-meteora-dbc-decoder`               | Meteora DBC Program Decoder               | dbcij3LWUppWqq96dh6gJWwBifmcGfLSB5D4DuSMaqN  |
| `carbon-meteora-dlmm-decoder`              | Meteora DLMM Program Decoder              | LBUZKhRxPF3XUpBCjp4YzTKgLccjZhTSDM9YuVaPwxo  |
| `carbon-meteora-pools-decoder`             | Meteora Pools Program Decoder             | Eo7WjKq67rjJQSZxS6z3YkapzY3eMj6Xy8X5EQVn5UaB |
| `carbon-meteora-vault-decoder`             | Meteora Vault Program Decoder             | 24Uqj9JCLxUeoC3hGfh5W3s9FM9uCHDS2SG3LYwBpyTi |
| `carbon-moonshot-decoder`                  | Moonshot Program Decoder                  | MoonCVVNZFSYkqNXP6bxHLPL6QQJiMagDL3qcqUQTrG  |
| `carbon-mpl-core-decoder`                  | MPL Core Program Decoder                  | CoREENxT6tW1HoK8ypY1SxRMZTcVPm7R94rH4PZNhX7d |
| `carbon-mpl-token-metadata-decoder`        | MPL Token Metadata Program Decoder        | metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s  |
| `carbon-name-service-decoder`              | SPL Name Service Program Decoder          | namesLPneVptA9Z5rqUDD9tMTWEJwofgaYwp8cawRkX  |
| `carbon-okx-dex-decoder`                   | OKX DEX Decoder                           | 6m2CDdhRgxpH4WjvdzxAYbGxwdGUz5MziiL5jek2kBma |
| `carbon-openbook-v2-decoder`               | Openbook V2 Program Decoder               | opnb2LAfJYbRMAHHvqjCwQxanZn7ReEHp1k81EohpZb  |
| `carbon-orca-whirlpool-decoder`            | Orca Whirlpool Program Decoder            | whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc  |
| `carbon-pancake-swap-decoder`              | Pancake Swap Program Decoder              | HpNfyc2Saw7RKkQd8nEL4khUcuPhQ7WwY1B2qjx8jxFq |
| `carbon-phoenix-v1-decoder`                | Phoenix V1 Program Decoder                | PhoeNiXZ8ByJGLkxNfZRnkUfjvmuYqLR89jjFHGqdXY  |
| `carbon-pumpfun-decoder`                   | Pumpfun Program Decoder                   | 6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P  |
| `carbon-pump-swap-decoder`                 | PumpSwap Program Decoder                  | pAMMBay6oceH9fJKBRHGP5D4bD4sWpmSwMn52FMfXEA  |
| `carbon-pump-fees-decoder`                 | Pump Fees Program Decoder                 | pfeeUxB6jkeY1Hxd7CsFCAjcbHA9rWtchMGdZ6VojVZ  |
| `carbon-raydium-amm-v4-decoder`            | Raydium AMM V4 Program Decoder            | 675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8 |
| `carbon-raydium-clmm-decoder`              | Raydium CLMM Program Decoder              | CAMMCzo5YL8w4VFF8KVHrK22GGUsp5VTaW7grrKgrWqK |
| `carbon-raydium-cpmm-decoder`              | Raydium CPMM Program Decoder              | CPMMoo8L3F4NbTegBCKVNunggL7H1ZpdTHKxQB5qKP1C |
| `carbon-raydium-launchpad-decoder`         | Raydium Launchpad Program Decoder         | LanMV9sAd7wArD4vJFi2qDdfnVhFxYSUg6eADduJ3uj  |
| `carbon-raydium-liquidity-locking-decoder` | Raydium Liquidity Locking Program Decoder | LockrWmn6K5twhz3y9w1dQERbmgSaRkfnTeTKbpofwE  |
| `carbon-raydium-stable-swap-decoder`       | Raydium Stable Swap Program Decoder       | 5quBtoiQqxF9Jv6KYKctB59NT3gtJD2Y65kdnB1Uev3h |
| `carbon-sharky-decoder`                    | SharkyFi Decoder                          | SHARKobtfF1bHhxD2eqftjHBdVSCbKo9JtgK71FhELP  |
| `carbon-solayer-pool-restaking-decoder`    | Solayer Pool Restaking Program Decoder    | sSo1iU21jBrU9VaJ8PJib1MtorefUV4fzC9GURa2KNn  |
| `carbon-stabble-stable-swap-decoder`       | Stabble Stable Swap Decoder               | swapNyd8XiQwJ6ianp9snpu4brUqFxadzvHebnAXjJZ  |
| `carbon-stabble-weighted-swap-decoder`     | Stabble Weighted Swap Decoder             | swapFpHZwjELNnjvThjajtiVmkz3yPQEHjLtka2fwHW  |
| `carbon-stake-program-decoder`             | Stake Program Decoder                     | Stake11111111111111111111111111111111111111  |
| `carbon-swig-decoder`                      | Swig Decoder                              | swigypWHEksbC64pWKwah1WTeh9JXwx8H1rJHLdbQMB  |
| `carbon-system-program-decoder`            | System Program Decoder                    | 11111111111111111111111111111111             |
| `carbon-token-2022-decoder`                | Token 2022 Program Decoder                | TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb  |
| `carbon-token-program-decoder`             | Token Program Decoder                     | TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA  |
| `carbon-vertigo-decoder`                   | Vertigo Program Decoder                   | vrTGoBuy5rYSxAfV3jaRJWHH6nN9WK4NRExGxsk1bCJ  |
| `carbon-virtuals-decoder`                  | Virtuals Program Decoder                  | 5U3EU2ubXtK84QcRjWVmYt9RaDyA8gKxdUrPFXmZyaki |
| `carbon-wavebreak-decoder`                 | Wavebreak Program Decoder                 | waveQX2yP3H1pVU8djGvEHmYg8uamQ84AuyGtpsrXTF  |
| `carbon-zeta-decoder`                      | Zeta Program Decoder                      | ZETAxsqBRek56DhiGXrn75yj2NHU3aYUnxvHXpkf3aD  |
