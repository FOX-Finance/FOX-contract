## `CDP`

Gets WETH as collateral, gives SIN as debt.


Abstract contract.

### `onlyCdpApprovedOrOwner(address msgSender, uint256 id_)`





### `onlyGloballyHealthy()`





### `updateIdFirst(uint256 id_)`





### `updateIdLast(uint256 id_)`





### `idRangeCheck(uint256 id_)`






### `constructor(string name_, string symbol_, address oracleFeeder_, address feeTo_, address collateralToken_, address debtToken_, uint256 maxLTV_, uint256 cap_, uint256 feeRatio_, uint256 liquidationPenaltyRatio_, uint256 liquidationBufferRatio_)` (internal)





### `setMaxLTV(uint256 newMaxLTV)` (external)





### `setCap(uint256 newCap)` (external)





### `setFeeTo(address newFeeTo)` (external)





### `setFeeRatio(uint256 newFeeRatio)` (external)





### `setLiquidationPenaltyRatio(uint256 newLiquidationPenaltyRatio)` (external)





### `setLiquidationProtocolFeeRatio(uint256 newLiquidationProtocolFeeRatio)` (external)





### `setLiquidationBufferRatio(uint256 newLiquidationBufferRatio)` (external)





### `pause()` (public)





### `unpause()` (public)





### `updateOracleFeeder(address newOracleFeeder)` (external)





### `updateCollateralPrice(uint256 newCollateralPrice, uint256 confidence)` (external)





### `isSafe(uint256 id_) → bool` (public)

CDP risk indicator.



### `globalLTV() → uint256 ltv_` (public)



multiplied by _DENOMINATOR.

### `currentLTV(uint256 id_) → uint256 ltv_` (public)



multiplied by _DENOMINATOR.

### `healthFactor(uint256 id_) → uint256 health` (public)



multiplied by _DENOMINATOR.

### `globalHealthFactor() → uint256 health` (public)



multiplied by _DENOMINATOR.

### `cdp(uint256 id_) → struct ICDP.CollateralizedDebtPosition` (external)





### `cdpInfo(uint256 id_) → uint256 collateralAmount_, uint256 ltv_, uint256 fee_` (external)





### `calculatedLtv(uint256 collateralAmount_, uint256 debtAmount_) → uint256 ltv_` (public)



multiplied by _DENOMINATOR.

### `collateralToken() → address` (public)





### `debtToken() → address` (public)





### `collateralPrice() → uint256` (public)





### `minimumCollateral() → uint256` (public)





### `debtAmountFromCollateralToLtv(uint256 collateralAmount_, uint256 ltv_) → uint256 debtAmount_` (public)





### `collateralAmountFromDebtWithLtv(uint256 debtAmount_, uint256 ltv_) → uint256 collateralAmount_` (public)





### `debtAmountRangeWhenLiquidate(uint256 id_) → uint256 upperBound_, uint256 lowerBound_` (public)





### `open() → uint256 id_` (external)

Opens a CDP position.



### `openAndDeposit(uint256 amount_) → uint256 id_` (external)

Opens a CDP position
and deposits `amount_` into the created CDP.

Requirements:

- Do `approve` first.



### `openAndDepositAndBorrow(uint256 depositAmount_, uint256 borrowAmount_) → uint256 id_` (external)





### `close(uint256 id_)` (external)

Closes the `id_` CDP position.



### `deposit(uint256 id_, uint256 amount_)` (external)



Deposits collateral into CDP.

Requirements:

- Do `approve` first.

### `depositAndBorrow(uint256 id_, uint256 depositAmount_, uint256 borrowAmount_)` (external)





### `withdraw(uint256 id_, uint256 amount_)` (external)

Withdraws collateral from `this` to `_msgSender()`.



### `borrow(uint256 id_, uint256 amount_)` (external)

Borrows `amount_` debts.



### `repay(uint256 id_, uint256 amount_)` (external)

Repays `amount_` debts.



### `repayAndWithdraw(uint256 id_, uint256 repayAmount_, uint256 withdrawAmount_)` (external)





### `liquidate(uint256 id_, uint256 amount_)` (external)





### `globalLiquidate(uint256 id_, uint256 amount_)` (external)

Liquidation fee is deducted and no upper bound exists when paused.


First `pause()`, then `globalLiquidate()`.

### `updateFee(uint256 id_) → uint256 additionalFee` (external)

Update fee.



### `_open(address account_) → uint256 id_` (internal)





### `_close(address account_, uint256 id_)` (internal)





### `_deposit(address account_, uint256 id_, uint256 amount_)` (internal)





### `_withdraw(address account_, uint256 id_, uint256 amount_)` (internal)





### `_borrow(address account_, uint256 id_, uint256 amount_)` (internal)





### `_repay(address account_, uint256 id_, uint256 amount_)` (internal)





### `_liquidate(address account_, uint256 id_, uint256 amount_, uint256 liquidationPenaltyRatio_, uint256 liquidationProtocolFeeRatio_)` (internal)





### `_update(uint256 id_) → uint256 additionalFee` (internal)



Updates fee and timestamp.


