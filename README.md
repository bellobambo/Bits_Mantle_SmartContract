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



bambo@MrBello:~/Bits_Contract$ cast wallet import deployer --interactive
Enter private key:
Enter password: 
`deployer` keystore was saved successfully. Address: 0x323d8ee95b5e81bf21d05237ac1501c41328ba50
bambo@MrBello:~/Bits_Contract$ 


bambo@MrBello:~/Bits_Contract$ forge script script/Bits.s.sol --account deployer --broadcast --rpc-url https://rpc.sepolia.mantle.xyz
[⠢] Compiling...
No files changed, compilation skipped
Enter keystore password:
Script ran successfully.

## Setting up 1 EVM.

==========================

Chain 5003

Estimated gas price: 100.000000001 gwei

Estimated total gas used for script: 3994432

Estimated amount required: 0.399443200003994432 MNT

==========================

##### mantle-sepolia
✅  [Success] Hash: 0x35cea4df1f71d2eb34b0779fc4fcc927fc1346fe3a8330388d100dbd0cbdec9b
Contract Address: 0xbf16c7cA893c075758bc18f66d5A993372A6914d
Block: 38788527
Paid: 0.152364400003047288 MNT (3047288 gas * 50.000000001 gwei)

✅ Sequence #1 on mantle-sepolia | Total Paid: 0.152364400003047288 MNT (3047288 gas * avg 50.000000001 gwei)
                                                                                                                                                                        

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /home/bambo/Bits_Contract/broadcast/Bits.s.sol/5003/run-latest.json

Sensitive values saved to: /home/bambo/Bits_Contract/cache/Bits.s.sol/5003/run-latest.json

bambo@MrBello:~/Bits_Contract$ 