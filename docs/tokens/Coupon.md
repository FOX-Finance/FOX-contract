## `Coupon`

Gets FOXS as share, mints NIS as grant.

Similar with FoxFarm, but no collaterals, only shares and grants.


### `onlyPdcApprovedOrOwner(address msgSender, uint256 id_)`






### `constructor(address feeTo_, address grantToken_, uint256 feeRatio_)` (public)





### `setFeeTo(address newFeeTo)` (external)





### `setFeeRatio(uint256 newFeeRatio)` (external)





### `pause()` (public)





### `unpause()` (public)





### `pdc(uint256 id_) → struct ICoupon.PositionDiscountCoupon` (public)





### `mintTo(address toAccount_, uint256 shareAmount_, uint256 grantAmount_) → uint256 id_` (external)

Opens a PDC position.



### `burn(uint256 id_) → uint256 shareAmount_, uint256 grantAmount_` (external)

Closes the `id_` PDC position.



### `updateFee(uint256 id_) → uint256 additionalFee` (external)

Update fee.



### `_update(uint256 id_) → uint256 additionalFee` (internal)



Updates fee and timestamp.


