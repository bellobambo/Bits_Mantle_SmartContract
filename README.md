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

Judge-friendly explanation:

> Funds are split as 10% to the platform, 10% base rent to the landlord, and up to 80% to investors based only on the percentage of the property they have funded, with any unfunded investor share automatically going back to the landlord.

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

## Main Functions

### `register(string name, Role role, string matricNumber, string schoolName)`

Registers a user.

Examples:

```solidity
register("Ada Landlord", Role.Landlord, "", "");
register("Bola Investor", Role.Investor, "", "");
register("Dayo Student", Role.Student, "CSC/2024/001", "University of Lagos");
```

### `uploadHouse(HouseInput input)`

Allows a landlord to upload a hostel/property.

```solidity
uploadHouse(
  HouseInput({
    hostelName: "Bits Lodge",
    hostelLocation: "University Road, Lagos",
    schoolName: "University of Lagos",
    proofOfOwnership: "ipfs://proof",
    photos: ["ipfs://front", "ipfs://room"],
    roomCount: 10,
    yearlyRent: 12 ether,
    halfYearRent: 7 ether,
    propertyValue: 200 ether
  })
)
```

`ether` means 18-decimal native token units. On Mantle, these values represent MNT amounts. Naira conversion should be handled in the frontend.

### `invest(uint256 houseId)` payable

Allows an investor to invest in a house.

```solidity
invest{value: 20 ether}(1);
```

Rules:

- minimum investment is 10% of property value
- maximum investment is 50% of property value
- funding closes automatically when total invested equals property value

### `payRent(uint256 houseId, RentTerm term)` payable

Allows a student to pay rent.

```solidity
payRent{value: 12 ether}(1, RentTerm.FullYear);
```

Creates an on-chain receipt and distributes rent.

Rent term IDs:

```solidity
RentTerm.HalfYear = 0
RentTerm.FullYear = 1
```

### Read Functions

```solidity
getAllHouses()
getHouse(uint256 houseId)
getHousePhotos(uint256 houseId)
getOwnerHouses(address landlord)
getInvestorHouses(address investor)
getHouseInvestors(uint256 houseId)
getInvestment(uint256 houseId, address investor)
getReceipt(uint256 receiptId)
getPayoutHistory(uint256 houseId, address recipient)
getMyPayoutHistory(uint256 houseId)
getAIReviews(uint256 houseId)
getAIReview(uint256 houseId, uint256 index)
getAIReviewCount(uint256 houseId)
houseCount()
receiptCount()
users(address user)
platformOwner()
```

### AI Review Functions

```solidity
storePropertyVerificationReview(
  uint256 houseId,
  string status,
  uint256 confidenceBps,
  string summary,
  bytes32 evidenceHash,
  string evidenceURI
)
```

Stores AI verification results for a landlord's property.

```solidity
storeInvestmentReview(
  uint256 houseId,
  string status,
  uint256 confidenceBps,
  string summary,
  bytes32 evidenceHash,
  string evidenceURI
)
```

Stores AI risk/yield review results for an investor.

`confidenceBps` is in basis points, so:

```text
9200 = 92%
10000 = 100%
```

## Rental Receipt

Each rent payment creates a receipt containing:

- receipt ID
- house ID
- student wallet
- student name
- student school
- landlord wallet
- landlord name
- amount paid
- rent term
- payment date
- rent start date
- due date
- end date with grace period

Rent starts 7 days after payment and includes a 30-day grace period after the due date.

## Payout History

Landlords and investors can fetch payout history per property:

```solidity
getPayoutHistory(houseId, wallet)
getMyPayoutHistory(houseId)
```

Each payout record contains:

- receipt ID
- house ID
- recipient wallet
- recipient role
- amount
- timestamp

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
