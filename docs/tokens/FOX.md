## `FOX`

Gets SIN and FOXS, gives FOX as debt.




### `constructor(address oracleFeeder_, address feeTo_, address debtToken_, address shareToken_, uint256 mintFeeRatio_, uint256 burnFeeRatio_, uint256 bonusRatio_)` (public)





### `initialize(address foxFarm_)` (external)





### `setFeeTo(address newFeeTo)` (external)





### `setMintFeeRatio(uint256 newMintFeeRatio)` (external)





### `setBurnFeeRatio(uint256 newBunrFeeRatio)` (external)





### `setBonusRatio(uint256 newBonusRatio)` (external)





### `pause()` (public)





### `unpause()` (public)





### `updateOracleFeeder(address newOracleFeeder)` (external)





### `updateStablePrice(uint256 newStablePrice, uint256 confidence)` (external)





### `updateStablePriceWithTrustLevel(uint256 newStablePrice, uint256 confidence)` (external)





### `updateSharePrice(uint256 newSharePrice, uint256 confidence)` (external)





### `updateTrustLevel()` (external)





### `_updateTrustLevel()` (internal)





### `updateStep(enum IFOX.Step step_)` (external)





### `stablePrice() → uint256` (public)





### `sharePrice() → uint256` (public)





### `currentTrustLevel() → uint256` (public)





### `deltaTrust() → int256` (public)

Returns error of stablecoin price.


Over-trusted when `deltaTrust()` > 0.
Under-trusted when `deltaTrust()` < 0.
Neutal-trusted when `deltaTrust()` == 0.

### `deltaTrustLevel() → int256` (public)





### `requiredStableAmountFromDebt(uint256 debtAmount_) → uint256 stableAmount_` (public)





### `requiredStableAmountFromDebtWithBurnFee(uint256 debtAmount_) → uint256 stableAmount_` (public)



Uses to `repay()` in `close()`. Must consider burn fee.

### `requiredShareAmountFromDebt(uint256 debtAmount_) → uint256 shareAmount_` (public)





### `requiredShareAmountFromStable(uint256 stableAmount_) → uint256 shareAmount_` (public)





### `requiredShareAmountFromStableWithMintFee(uint256 stableAmount_) → uint256 shareAmount_` (public)



Uses to `borrow()`. Must consider mint fee.

### `requiredShareAmountFromStableWithBurnFee(uint256 stableAmount_) → uint256 shareAmount_` (public)





### `requiredDebtAmountFromShare(uint256 shareAmount_) → uint256 debtAmount_` (public)





### `requiredDebtAmountFromStable(uint256 stableAmount_) → uint256 debtAmount_` (public)





### `requiredDebtAmountFromStableWithMintFee(uint256 stableAmount_) → uint256 debtAmount_` (public)



Uses to `borrow()`. Must consider mint fee.

### `requiredDebtAmountFromStableWithBurnFee(uint256 stableAmount_) → uint256 debtAmount_` (public)





### `expectedMintAmount(uint256 debtAmount_, uint256 shareAmount_) → uint256 stableAmount_` (public)





### `expectedMintAmountWithMintFee(uint256 debtAmount_, uint256 shareAmount_) → uint256 stableAmount_, uint256 mintFee_` (public)





### `expectedRedeemAmount(uint256 stableAmount_) → uint256 debtAmount_, uint256 shareAmount_` (public)





### `expectedRedeemAmountWithBurnFee(uint256 stableAmount_) → uint256 debtAmount_, uint256 shareAmount_, uint256 burnFee_` (public)





### `shortfallRecollateralizeAmount() → uint256 debtAmount_` (public)

Indicates allowable recoll amount



### `exchangedShareAmountFromDebt(uint256 debtAmount_) → uint256 shareAmount_` (public)





### `exchangedShareAmountFromDebtWithBonus(uint256 debtAmount_) → uint256 shareAmount_` (public)





### `surplusBuybackAmount() → uint256 debtAmount_` (public)

Indicates allowable buyback amount



### `exchangedDebtAmountFromShare(uint256 shareAmount_) → uint256 debtAmount_` (public)





### `mint(address toAccount_, uint256 debtAmount_, uint256 shareAmount_) → uint256 stableAmount_` (external)





### `redeem(address toAccount_, uint256 stableAmount_) → uint256 debtAmount_, uint256 shareAmount_` (external)





### `recollateralize(address toAccount_, uint256 debtAmount_) → uint256 shareAmount_, uint256 bonusAmount_` (external)





### `buyback(address toAccount_, uint256 shareAmount_) → uint256 debtAmount_` (external)





### `skim(address toAccount_) → uint256 shareAmount_` (external)





### `approveMax(address spender)` (public)






