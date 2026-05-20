# Bits Smart Contract

Bits is an AI x RWA student housing contract deployed on Mantle. It lets landlords tokenize hostel cashflows, investors fund fractions of real properties, and students pay rent with on-chain receipts.


## What Bits Does

- Landlords register and upload hostel/property listings.
- Investors invest in properties using Mantle-native token payments.
- Students pay rent on-chain and receive rental receipts.
- Rent is split automatically between the platform, landlord, and investors.
- Investors only earn from the percentage of the property they funded.
- The landlord keeps the rent share for the unfunded percentage.
- Owners and investors can view payout history per property.
- AI review records can be stored on-chain for property verification and investment/risk review.

## Roles

Role IDs:

```solidity
Role.None = 0
Role.Landlord = 1
Role.Student = 2
Role.Investor = 3
```

### Landlord

Landlords can:

- register with name and role
- upload hostel details
- receive investor funding immediately
- receive rent payouts
- view their houses
- view payout history per house
- store AI property verification reviews

### Investor

Investors can:

- register with name and role
- browse houses
- invest between 10% and 50% of a property value
- receive rent payouts based on funded percentage
- view houses they invested in
- view payout history per house
- store AI investment/risk reviews

### Student

Students can:

- register with name, matric number, and school
- browse hostel listings
- pay rent on-chain
- receive a rental receipt with start date, due date, end date, landlord details, and student details

## Fund Split

When a student pays rent:

```text
10% -> platform
10% -> base landlord share
up to 80% -> investors, based on funded property percentage
unfunded investor share -> landlord
```

Funds are split as 10% to the platform, 10% base rent to the landlord, and up to 80% to investors based only on the percentage of the property they have funded, with any unfunded investor share automatically going back to the landlord.

Example:

```text
Student pays rent: 240 MNT
Property funded: 10%

Platform: 24 MNT
Investor pool max: 192 MNT
Actual investor payout: 19.2 MNT
Landlord base share: 24 MNT
Unfunded investor share to landlord: 172.8 MNT

Final:
Platform = 24 MNT
Investors = 19.2 MNT
Landlord = 196.8 MNT
```




## AI x RWA Positioning

Bits brings student housing cashflows on-chain as a real-world asset.

AI can be used for:

- property valuation
- property verification
- token/funding recommendations
- investor risk scoring
- yield forecasting
- student application screening

Mantle is used for:

- property funding records
- transparent rent payment
- automatic rent distribution
- rental receipts
- payout history
- AI review evidence hashes and URIs

## Build

```bash
forge build
```

## Test

```bash
forge test
```

## Format

```bash
forge fmt
```

## Deploy To Mantle Sepolia

Create or import a deployer keystore:

```bash
cast wallet import deployer --interactive
```

Deploy:

```bash
forge script script/Bits.s.sol --account deployer --broadcast --rpc-url https://rpc.sepolia.mantle.xyz
```

Current deployed contract:

```text
0xcDFb1272Fad230337C553e8c5649d5C5cf361f03
```

## Verify

Sourcify:

```bash
forge verify-contract 0xcDFb1272Fad230337C553e8c5649d5C5cf361f03 src/Bits.sol:Bits --chain 5003
```

Mantle Sepolia Blockscout:

```bash
forge verify-contract 0xcDFb1272Fad230337C553e8c5649d5C5cf361f03 src/Bits.sol:Bits --chain 5003 --verifier blockscout --verifier-url https://explorer.sepolia.mantle.xyz/api
```

## ABI

After building, the ABI is generated at:

```text
out/Bits.sol/Bits.json
```

Extract ABI only:

```bash
jq '.abi' out/Bits.sol/Bits.json > BitsABI.json
```
