## `ICDP`






### `collateralToken() → address` (external)





### `debtToken() → address` (external)





### `collateralPrice() → uint256` (external)





### `minimumCollateral() → uint256` (external)





### `maxLTV() → uint256` (external)





### `cap() → uint256` (external)





### `id() → uint256` (external)





### `totalCollateral() → uint256` (external)





### `totalDebt() → uint256` (external)





### `totalFee() → uint256` (external)





### `setMaxLTV(uint256 newMaxLTV)` (external)





### `setCap(uint256 newCap)` (external)





### `setFeeTo(address newFeeTo)` (external)





### `setFeeRatio(uint256 newFeeRatio)` (external)





### `setLiquidationPenaltyRatio(uint256 newLiquidationPenaltyRatio)` (external)





### `setLiquidationProtocolFeeRatio(uint256 newLiquidationProtocolFeeRatio)` (external)





### `setLiquidationBufferRatio(uint256 newLiquidationBufferRatio)` (external)





### `pause()` (external)





### `unpause()` (external)





### `updateOracleFeeder(address newOracleFeeder)` (external)





### `updateCollateralPrice(uint256 newCollateralPrice, uint256 confidence)` (external)





### `isSafe(uint256 id_) → bool` (external)





### `globalLTV() → uint256 ltv_` (external)





### `currentLTV(uint256 id_) → uint256 ltv_` (external)





### `healthFactor(uint256 id_) → uint256 health` (external)





### `globalHealthFactor() → uint256 health` (external)





### `cdp(uint256 id_) → struct ICDP.CollateralizedDebtPosition` (external)





### `cdpInfo(uint256 id_) → uint256 collateralAmount_, uint256 ltv_, uint256 fee_` (external)





### `calculatedLtv(uint256 collateralAmount_, uint256 debtAmount_) → uint256 ltv_` (external)





### `debtAmountFromCollateralToLtv(uint256 collateralAmount_, uint256 ltv_) → uint256 debtAmount_` (external)





### `collateralAmountFromDebtWithLtv(uint256 debtAmount_, uint256 ltv_) → uint256 collateralAmount_` (external)





### `debtAmountRangeWhenLiquidate(uint256 id_) → uint256 upperBound_, uint256 lowerBound_` (external)





### `open() → uint256 id_` (external)





### `openAndDeposit(uint256 amount_) → uint256 id_` (external)





### `openAndDepositAndBorrow(uint256 depositAmount_, uint256 borrowAmount_) → uint256 id_` (external)





### `close(uint256 id_)` (external)





### `deposit(uint256 id_, uint256 amount_)` (external)





### `depositAndBorrow(uint256 id_, uint256 depositAmount_, uint256 borrowAmount_)` (external)





### `withdraw(uint256 id_, uint256 amount_)` (external)





### `borrow(uint256 id_, uint256 amount_)` (external)





### `repay(uint256 id_, uint256 amount_)` (external)





### `repayAndWithdraw(uint256 id_, uint256 repayAmount_, uint256 withdrawAmount_)` (external)





### `liquidate(uint256 id_, uint256 amount_)` (external)





### `globalLiquidate(uint256 id_, uint256 amount_)` (external)





### `updateFee(uint256 id_) → uint256 additionalFee` (external)






### `Open(address account_, uint256 id_)`





### `Close(address account_, uint256 id_)`





### `Deposit(address account_, uint256 id_, uint256 amount)`





### `Withdraw(address account_, uint256 id_, uint256 amount)`





### `Borrow(address account_, uint256 id_, uint256 amount)`





### `Repay(address account_, uint256 id_, uint256 amount)`





### `Update(uint256 id_, uint256 prevFee, uint256 currFee, uint256 prevTimestamp, uint256 currTimestamp)`





### `Liquidate(address account_, uint256 id_, uint256 debtAmount_, uint256 collateralAmount_)`





### `SetMaxLTV(uint256 prevMaxLTV, uint256 currMaxLTV)`





### `SetCap(uint256 prevCap, uint256 currCap)`





### `SetFeeTo(address prevFeeTo, address currFeeTo)`





### `SetFeeRatio(uint256 prevFeeRatio, uint256 currFeeRatio)`





### `SetLiquidationPenaltyRatio(uint256 prevLiquidationPenaltyRatio, uint256 currLiquidationPenaltyRatio)`





### `SetLiquidationProtocolFeeRatio(uint256 prevLiquidationProtocolFeeRatio, uint256 currLiquidationProtocolFeeRatio)`





### `SetLiquidationBufferRatio(uint256 prevLiquidationBufferRatio, uint256 currLiquidationBufferRatio)`





