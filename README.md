# Fractional Over Collateralized Stablecoin (FOX)

TBD

```
DAI + FRAX = FOX
```

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

# AMO

TBD

---

# How to Use

### 0. Requirements

```bash
$ npm install
```

### 1. Set `config.json`

```js
{
    "privateKey": <YOUR_PRIVATE_KEY>
}
```

See `config_sample.json` for example.

### 2. Deploy

```bash
$ npx hardhat run scripts/deploy.js
```

### 3. Test (Optional)

TBD

---

<!--
# TODO

- [ ] BNB liquid staking -> stBNB as collateral
- [ ] LP as collateral
- [ ] solidity-docgen
-->
