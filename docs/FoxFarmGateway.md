## `FoxFarmGateway`






### `constructor(contract IERC20 collateralToken_, contract IERC20 shareToken_, contract IFOX stableToken_, contract IFoxFarm foxFarm_)` (public)





### `defaultValuesMint(address account_, uint256 id_) → uint256 collateralAmount_, uint256 ltv_, uint256 shareAmount_, uint256 stableAmount_` (external)





### `ltvRangeWhenMint(uint256 id_, uint256 collateralAmount_, uint256 shareAmount_) → uint256 upperBound_, uint256 lowerBound_` (public)





### `collateralAmountRangeWhenMint(address account_, uint256 id_, uint256 ltv_, uint256 shareAmount_) → uint256 upperBound_, uint256 lowerBound_` (public)





### `shareAmountRangeWhenMint(address account_, uint256 id_, uint256 collateralAmount_, uint256 ltv_) → uint256 upperBound_, uint256 lowerBound_` (public)





### `requiredCollateralAmountFromShareToLtv(uint256 id_, uint256 newShareAmount_, uint256 ltv_) → uint256 collateralAmount_` (public)





### `requiredShareAmountFromCollateralToLtv(uint256 id_, uint256 newCollateralAmount_, uint256 ltv_) → uint256 shareAmount_` (public)





### `expectedMintAmountToLtv(uint256 id_, uint256 newCollateralAmount_, uint256 ltv_, uint256 newShareAmount_) → uint256 newStableAmount_` (public)





### `defaultValueRedeem(address account_, uint256 id_) → uint256 stableAmount_, uint256 collateralAmount_, uint256 ltv_, uint256 shareAmount_` (external)





### `ltvRangeWhenRedeem(uint256 id_, uint256 stableAmount_) → uint256 upperBound_, uint256 lowerBound_` (public)





### `stableAmountRangeWhenRedeem(address account_, uint256 id_) → uint256 upperBound_, uint256 lowerBound_` (public)





### `expectedRedeemAmountToLtv(uint256 id_, uint256 collectedStableAmount_, uint256 ltv_) → uint256 emittedCollateralAmount_, uint256 emittedShareAmount_` (public)





### `defaultValuesRecollateralize(address account_, uint256 id_) → uint256 collateralAmount_, uint256 ltv_, uint256 shareAmount_` (public)





### `ltvRangeWhenRecollateralize(uint256 id_, uint256 collateralAmount_) → uint256 upperBound_, uint256 lowerBound_` (public)



always be same (can be decreased by new collateral amount)
or increasing LTV.

### `collateralAmountRangeWhenRecollateralize(address account_, uint256 id_, uint256 ltv_) → uint256 upperBound_, uint256 lowerBound_` (public)



0 to shorfall.

### `exchangedShareAmountFromCollateralToLtv(uint256 id_, uint256 collateralAmount_, uint256 ltv_) → uint256 shareAmount_` (public)



No consideration about shortfall.

### `defaultValuesBuyback(address account_, uint256 id_) → uint256 shareAmount_, uint256 collateralAmount_, uint256 ltv_` (external)





### `ltvRangeWhenBuyback(uint256 id_, uint256 shareAmount_) → uint256 upperBound_, uint256 lowerBound_` (public)



always be same or decreasing LTV.

### `shareAmountRangeWhenBuyback(address account_, uint256 id_) → uint256 upperBound_, uint256 lowerBound_` (public)



0 to surplus.

### `exchangedCollateralAmountFromShareToLtv(uint256 id_, uint256 shareAmount_, uint256 ltv_) → uint256 collateralAmount_` (public)



for buyback


