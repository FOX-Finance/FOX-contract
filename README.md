# Fractional Over Collateralized Stablecoin (FOX)

```
DAI + FRAX = FOX
```

---

# Requirements

```bash
$ npm install
```

# Set `.env`

and/or `.env.test` for test environment.

Now we can use pre-defined values as environment variable, with a command prefix `dotenv -e .env.test --`.

# Deploy

```bash
$ dotenv -e .env.test -- npx hardhat run scripts/deploy.js --network localhost
```

<!--
How to increase capital efficiency?
- increase maxLTV: more easy, but more risky
- increase service's trust: in some ways, more risky. But collaterals are SAFU
- increase both maxLTV and trust: 😲

Solve Stablecoin's trilemma
-->

<!--
# Market

## NFT Market

## Liquidation Auction
-->

<!--
# Proof-of-Work
- [x] Moralis for oracle
- [x] Check additional conditions: total ratio, cdp ratio
- [x] Oracle feeder
- [x] WARNING or Restriction when protocol trust touches 100% collateral backing level
- [x] CDP update first (modifier)
- [x] FoxFarm Gateway for view functions
- [ ] Refactoring interfaces
- [ ] `feeTo` -> share fees to FOXS holders
- [ ] PSM
- [ ] "Swap is more cheaper" message
- [x] Use ethers.BigNumber instead of BigInt

# Future Work
- [ ] Frontend advanced page
- [ ] Multiple collateral: LP as collateral (kind of liquid staking)
       - DAODAO
       - Shared Stablecoin
- [ ] BNB liquid staking -> ankr's aBNBc as collateral:
       - https://www.ankr.com/docs/staking/for-integrators/smart-contract-api/bnb-api/#stake-bnb-and-claim-abnbc
       - https://www.ankr.com/docs/staking/for-integrators/smart-contract-api/bnb-api/#unstake-abnbc-and-get-bnb
       - https://www.ankr.com/docs/staking/for-integrators/smart-contract-api/bnb-api/#get-apr
- [ ] Is FOX is security token?

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
- [ ] Swap
- [ ] Multichain
-->
