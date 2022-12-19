## `IFOX`






### `trustLevel() → uint256` (external)





### `stablePrice() → uint256` (external)





### `sharePrice() → uint256` (external)





### `mintFeeRatio() → uint256` (external)





### `burnFeeRatio() → uint256` (external)





### `bonusRatio() → uint256` (external)





### `setFeeTo(address newFeeTo)` (external)





### `setMintFeeRatio(uint256 newMintFeeRatio)` (external)





### `setBurnFeeRatio(uint256 newBunrFeeRatio)` (external)





### `setBonusRatio(uint256 newBonusRatio)` (external)





### `pause()` (external)





### `unpause()` (external)





### `updateOracleFeeder(address newOracleFeeder)` (external)





### `updateStablePrice(uint256 newStablePrice, uint256 confidence)` (external)





### `updateStablePriceWithTrustLevel(uint256 newStablePrice, uint256 confidence)` (external)





### `updateSharePrice(uint256 newSharePrice, uint256 confidence)` (external)





### `updateTrustLevel()` (external)





### `updateStep(enum IFOX.Step step_)` (external)





### `currentTrustLevel() → uint256` (external)





### `deltaTrust() → int256` (external)





### `deltaTrustLevel() → int256` (external)





### `requiredStableAmountFromDebt(uint256 debtAmount_) → uint256 stableAmount_` (external)





### `requiredStableAmountFromDebtWithBurnFee(uint256 debtAmount_) → uint256 stableAmount_` (external)





### `requiredShareAmountFromDebt(uint256 debtAmount_) → uint256 shareAmount_` (external)





### `requiredShareAmountFromStable(uint256 stableAmount_) → uint256 shareAmount_` (external)





### `requiredShareAmountFromStableWithMintFee(uint256 stableAmount_) → uint256 shareAmount_` (external)



Uses to `borrow()`. Must consider mint fee.

### `requiredShareAmountFromStableWithBurnFee(uint256 stableAmount_) → uint256 shareAmount_` (external)





### `requiredDebtAmountFromShare(uint256 shareAmount_) → uint256 debtAmount_` (external)





### `requiredDebtAmountFromStable(uint256 stableAmount_) → uint256 debtAmount_` (external)





### `requiredDebtAmountFromStableWithMintFee(uint256 stableAmount_) → uint256 debtAmount_` (external)





### `requiredDebtAmountFromStableWithBurnFee(uint256 stableAmount_) → uint256 debtAmount_` (external)





### `expectedMintAmount(uint256 debtAmount_, uint256 shareAmount_) → uint256 stableAmount_` (external)





### `expectedMintAmountWithMintFee(uint256 debtAmount_, uint256 shareAmount_) → uint256 stableAmount_, uint256 mintFee_` (external)





### `expectedRedeemAmount(uint256 stableAmount_) → uint256 debtAmount_, uint256 shareAmount_` (external)





### `expectedRedeemAmountWithBurnFee(uint256 stableAmount_) → uint256 debtAmount_, uint256 shareAmount_, uint256 burnFee_` (external)





### `shortfallRecollateralizeAmount() → uint256 debtAmount_` (external)





### `surplusBuybackAmount() → uint256 debtAmount_` (external)





### `exchangedShareAmountFromDebt(uint256 debtAmount_) → uint256 shareAmount_` (external)





### `exchangedShareAmountFromDebtWithBonus(uint256 debtAmount_) → uint256 shareAmount_` (external)





### `exchangedDebtAmountFromShare(uint256 shareAmount_) → uint256 debtAmount_` (external)





### `mint(address toAccount_, uint256 debtAmount_, uint256 shareAmount_) → uint256 stableAmount_` (external)





### `redeem(address toAccount_, uint256 stableAmount_) → uint256 debtAmount_, uint256 shareAmount_` (external)





### `recollateralize(address toAccount_, uint256 debtAmount_) → uint256 shareAmount_, uint256 bonusAmount_` (external)





### `buyback(address toAccount_, uint256 shareAmount_) → uint256 debtAmount_` (external)





### `approveMax(address spender)` (external)






### `SetFeeTo(address prevFeeTo, address currFeeTo)`





### `SetMintFeeRatio(uint256 prevMintFeeRatio, uint256 currMintFeeRatio)`





### `SetBurnFeeRatio(uint256 prevBurnFeeRatio, uint256 currBurnFeeRatio)`





### `SetBonusRatio(uint256 prevBonusRatio, uint256 currBonusRatio)`





### `Initialize(address foxFarm)`





