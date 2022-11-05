# Fractional Over Collateralized Stablecoin (FOX)

TBD

```
DAI + FRAX = FOX
```

<!--
How to increase capital efficiency?
- increase maxLTV: more easy, but more risky
- increase service's trust: in some ways, more risky. But collaterals are SAFU
- increase both maxLTV and trust: 😲

Solve Stablecoin's trilemma
-->

## Trust & Decentralization

TBD

## FOXS

TBD

# Mechanism

## Minting

- Only CDP Owner

```
                    MAX LTV: L%
+------------+          LTV: x%      +------------+
|    BNB     |-----------+---------->|    FOX     |
+------------+           |           +------------+
   Collateral            |              Stablecoin
                         |
+------------+           |
|    FOXS    |-----------+
+------------+   
       Shares
```

1. Approve `WETH` to `FoxFarm`.
2. Approve `FOXS` to `FoxFarm`.
3. Execute `openAndDepositAndBorrow()` in `FoxFarm`.

## Redeeming

- Only CDP Owner

```
                    MAX LTV: L%
+------------+          LTV: x%      +------------+
|    BNB     |<----------+-----------|    FOX     |
+------------+           |           +------------+
   Collateral            |              Stablecoin
                         |
+------------+           |
|    FOXS    |<----------+
+------------+   
       Shares
```

1. Approve `FOX` to `FoxFarm`.
2. Execute `repayAndWithdraw()` in `FoxFarm`.

## Recollateralization (+Bonus)

### Borrowing Debt

- Only CDP Owner

```
                    MAX LTV: L%
+------------+          LTV: x++%    +------------+
|    BNB     |           |           |    FOX     |
+------------+           |           +------------+
   Collateral            |              Stablecoin
                         |
+------------+           |
|    FOXS    |<----------+
+------------+   
       Shares
```

### Depositing Collateral

- Anyone

```
                    MAX LTV: L%
+------------+          LTV: x%      +------------+
|    BNB     |-----------+           |    FOX     |
+------------+           |           +------------+
   Collateral            |              Stablecoin
                         |
+------------+           |
|    FOXS    |<----------+
+------------+   
       Shares
```

## Buybacks

### Repaying Debt

- Anyone

```
                    MAX LTV: L%
+------------+          LTV: x--%    +------------+
|    BNB     |           ^           |    FOX     |
+------------+           |           +------------+
   Collateral            |              Stablecoin
                         |
+------------+           |
|    FOXS    |-----------+
+------------+   
       Shares
```

### Withdraw Collateral

- Only CDP Owner

```
                    MAX LTV: L%
+------------+          LTV: x%      +------------+
|    BNB     |<----------+           |    FOX     |
+------------+           |           +------------+
   Collateral            |              Stablecoin
                         |
+------------+           |
|    FOXS    |-----------+
+------------+   
       Shares
```

### Coupon (NFT)

- Anyone

```

                        LTV: -- 
                         ^
                         |
                         |
                         |
+------------+           |
|    FOXS    |-----------+
+------------+   
       Shares
```

## Liquidation

- Anyone

## Global Liquidation

- Governance

---

# Liquid Staking

We use [Ankr](https://www.ankr.com/bnb-liquid-staking/)'s aBNBc token.

## Requirements

- Minimum value to stake: 0.502 BNB (the 0.002 part is the relayer fee).
- Minimum value to unstake: 0.5 BNB.
- Unbond time: 7–10 days.

## Fees

- Base fee: 10% of the Liquid Staking rewards as a fee.
- Relayer fee: 0.002 BNB.
- Unstaking fee: 0.004 BNB.
- Unstaking relay fee: 0.000075 BNB.

---

# Safety

## Local CDP Health

## Global Health

## Trustlevel Upperbound

$trustLevel + maxLTV <= 100%$

---

# Market

## NFT Market

## Liquidation Auction

---

# How to Use

## 0. Requirements

```bash
$ npm install
```

## 1. Set `private.json`

```js
{
    "privateKey": <YOUR_PRIVATE_KEY>
}
```

See `config_sample.json` for example.

## 2. Deploy

```bash
$ npx hardhat run scripts/deploy.js
```

## 3. Test (Optional)

### Terminal #1

Run local node (forking from BSC testnet).

```bash
$ npx hardhat node --fork https://data-seed-prebsc-1-s1.binance.org:8545
```

### Terminal #2

Enter the hardhat console.

```bash
$ npx hardhat console --network localhost
```

### Console

```bash
# View
$ await ethers.provider.getBlockNumber();
$ await ethers.provider.getBlock();

# Mining
$ await network.provider.send("evm_setAutomine", [false]);
$ await network.provider.send("evm_setIntervalMining", [1000]);

# Increase Time & Block
$ await network.provider.send("evm_increaseTime", [10000]);
$ await ethers.provider.send("hardhat_mine", [ethers.utils.hexValue(10)]);

# Balance
$ await ethers.provider.getBalance("0xa29A12B879bCC89faE72687e09Da3c3995B91fe5")
```

### Test

Prefix `dotenv -e .env.test --`.

```bash
$ dotenv -e .env.test -- npx hardhat run scripts/deploy.js --network localhost
```

Deploy:

```bash
$ npx hardhat run scripts/deploy.js --network localhost
```

<!--
```bash
$ dotenv -e .env.test -- npx hardhat node --network hardhat
$ dotenv -e .env.test -- npx hardhat console --network localhost
$ dotenv -e .env.test -- npx hardhat run scripts/deploy.js --network localhost
```

0. set.js
1. deploy.js
2. fuel.js
3. mint.js
4. redeem.js

```bash
$ dotenv -e .env.test -- npx hardhat run scripts/deploy.js --network localhost
$ dotenv -e .env.test -- npx hardhat run scripts/fuel.js --network localhost
$ dotenv -e .env.test -- npx hardhat run scripts/mint.js --network localhost
```
-->

<!--
# Proof-of-Work
- [x] Moralis for oracle
- [x] Check additional conditions: total ratio, cdp ratio
- [x] Oracle feeder
- [x] WARNING or Restriction when protocol trust touches 100% collateral backing level
- [ ] Multiple collateral: LP as collateral (kind of liquid staking)
       - DAODAO
       - Shared Stablecoin
- [ ] BNB liquid staking -> ankr's aBNBc as collateral:
       - https://www.ankr.com/docs/staking/for-integrators/smart-contract-api/bnb-api/#stake-bnb-and-claim-abnbc
       - https://www.ankr.com/docs/staking/for-integrators/smart-contract-api/bnb-api/#unstake-abnbc-and-get-bnb
       - https://www.ankr.com/docs/staking/for-integrators/smart-contract-api/bnb-api/#get-apr

# Proof-of-Work (non-tech)
- [ ] solidity-docgen
- [ ] Docusaurus
- [ ] CI/CD

# Roadmap
- [ ] Airdrop: DAI, FRAX
- [ ] Treasury.sol (Ministry of Finance) & Vesting.sol
- [ ] Oracle confidence
- [ ] Over the liquid: Collateral Hedge (maybe delta neutral)
- [ ] NFT Market & Auction / Or adopting non-collateral lending feature
- [ ] Zap (FOXS <-> BNB)
- [ ] (optional) Swap
- [ ] (optional) Multichain
-->
