## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```


bambo@MrBello:~/Bits_Contract$ forge script script/Bits.s.sol --account deployer --broadcast --rpc-url https://rpc.sepolia.mantle.xyz
[⠒] Compiling...
[⠊] Compiling 16 files with Solc 0.8.33
[⠢] Solc 0.8.33 finished in 8.86s
Compiler run successful!
Enter keystore password:
Script ran successfully.

## Setting up 1 EVM.

==========================

Chain 5003

Estimated gas price: 100.000000001 gwei

Estimated total gas used for script: 5123290

Estimated amount required: 0.51232900000512329 MNT

==========================

##### mantle-sepolia
✅  [Success] Hash: 0xb671aee1b14342087e1362a4f8fbe6c20a43f1202af575f923bcf020ad8115ad
Contract Address: 0xcDFb1272Fad230337C553e8c5649d5C5cf361f03
Block: 38826822
Paid: 0.1954405408803 MNT (3908803 gas * 50.0001 gwei)

✅ Sequence #1 on mantle-sepolia | Total Paid: 0.1954405408803 MNT (3908803 gas * avg 50.0001 gwei)
                                                                                                                                                                           

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /home/bambo/Bits_Contract/broadcast/Bits.s.sol/5003/run-latest.json

Sensitive values saved to: /home/bambo/Bits_Contract/cache/Bits.s.sol/5003/run-latest.json

bambo@MrBello:~/Bits_Contract$ 


bambo@MrBello:~/Bits_Contract$ forge verify-contract 0xcDFb1272Fad230337C553e8c5649d5C5cf361f03 src/Bits.sol:Bits --chain 5003
Start verifying contract `0xcDFb1272Fad230337C553e8c5649d5C5cf361f03` deployed on mantle-sepolia
Attempting to verify on Sourcify. Pass the --etherscan-api-key <API_KEY> to verify on Etherscan, or use the --verifier flag to verify on another provider.

Submitting verification for [Bits] "0xcDFb1272Fad230337C553e8c5649d5C5cf361f03".
Submitted contract for verification:
        Verification Job ID: `35da8110-fc49-4b2a-8a19-bd2cce2b49d4`
        URL: https://sourcify.dev/server/v2/verify/35da8110-fc49-4b2a-8a19-bd2cce2b49d4
bambo@MrBello:~/Bits_Contract$ 