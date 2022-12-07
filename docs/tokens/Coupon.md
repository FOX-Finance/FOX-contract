## `Coupon`

Gets FOXS as share, mints NIS as grant.

Similar with FoxFarm, but no collaterals, only shares and grants.


### `onlySgpApprovedOrOwner(address msgSender, uint256 id_)`






### `constructor(address feeTo_, address grantToken_, uint256 feeRatio_)` (public)





### `setFeeTo(address newFeeTo)` (external)





### `setFeeRatio(uint256 newFeeRatio)` (external)





### `pause()` (public)





### `unpause()` (public)





### `mintTo(address toAccount_, uint256 shareAmount_, uint256 grantAmount_) → uint256 id_` (external)

Opens a SGP position.



### `burn(uint256 id_) → uint256 shareAmount_, uint256 grantAmount_` (external)

Closes the `id_` SGP position.



### `updateFee(uint256 id_) → uint256 additionalFee` (external)

Update fee.



### `_update(uint256 id_) → uint256 additionalFee` (internal)



Updates fee and timestamp.


