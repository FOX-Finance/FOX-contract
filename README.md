# Fractional Over Collateralized Stablecoin (FOX)

TBD

```
DAI + FRAX = FOX
```

## Trust & Decentralization

## FOXS

# Mechanism

## Minting

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

TBD

## Global Liquidation

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
