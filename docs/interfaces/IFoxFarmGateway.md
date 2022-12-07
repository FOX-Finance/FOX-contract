## `IFoxFarmGateway`






### `defaultValuesMint(address account_, uint256 id_) → uint256 collateralAmount_, uint256 ltv_, uint256 shareAmount_, uint256 stableAmount_` (external)





### `ltvRangeWhenMint(uint256 id_, uint256 collateralAmount_, uint256 shareAmount_) → uint256 upperBound_, uint256 lowerBound_` (external)





### `collateralAmountRangeWhenMint(address account_, uint256 id_, uint256 ltv_, uint256 shareAmount_) → uint256 upperBound_, uint256 lowerBound_` (external)





### `shareAmountRangeWhenMint(address account_, uint256 id_, uint256 collateralAmount_, uint256 ltv_) → uint256 upperBound_, uint256 lowerBound_` (external)





### `requiredShareAmountFromCollateralToLtv(uint256 id_, uint256 newCollateralAmount_, uint256 ltv_) → uint256 shareAmount_` (external)





### `requiredCollateralAmountFromShareToLtv(uint256 id_, uint256 newShareAmount_, uint256 ltv_) → uint256 collateralAmount_` (external)





### `expectedMintAmountToLtv(uint256 id_, uint256 newCollateralAmount_, uint256 ltv_, uint256 newShareAmount_) → uint256 newStableAmount_` (external)





### `defaultValueRedeem(address account_, uint256 id_) → uint256 stableAmount_, uint256 collateralAmount_, uint256 ltv_, uint256 shareAmount_` (external)





### `ltvRangeWhenRedeem(uint256 id_, uint256 collectedStableAmount_) → uint256 upperBound_, uint256 lowerBound_` (external)





### `stableAmountRangeWhenRedeem(address account_, uint256 id_) → uint256 upperBound_, uint256 lowerBound_` (external)





### `expectedRedeemAmountToLtv(uint256 id_, uint256 collectedStableAmount_, uint256 ltv_) → uint256 emittedCollateralAmount_, uint256 emittedShareAmount_` (external)





### `defaultValuesRecollateralize(address account_, uint256 id_) → uint256 collateralAmount_, uint256 ltv_, uint256 shareAmount_` (external)





### `ltvRangeWhenRecollateralize(uint256 id_, uint256 collateralAmount_) → uint256 upperBound_, uint256 lowerBound_` (external)





### `collateralAmountRangeWhenRecollateralize(address account_, uint256 id_, uint256 ltv_) → uint256 upperBound_, uint256 lowerBound_` (external)





### `exchangedShareAmountFromCollateralToLtv(uint256 id_, uint256 collateralAmount_, uint256 ltv_) → uint256 shareAmount_` (external)





### `defaultValuesBuyback(address account_, uint256 id_) → uint256 shareAmount_, uint256 collateralAmount_, uint256 ltv_` (external)





### `ltvRangeWhenBuyback(uint256 id_, uint256 shareAmount_) → uint256 upperBound_, uint256 lowerBound_` (external)





### `shareAmountRangeWhenBuyback(uint256 id_) → uint256 upperBound_, uint256 lowerBound_` (external)





### `exchangedCollateralAmountFromShareToLtv(uint256 id_, uint256 shareAmount_, uint256 ltv_) → uint256 collateralAmount_` (external)






