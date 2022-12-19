## `ICoupon`






### `setFeeTo(address newFeeTo)` (external)





### `setFeeRatio(uint256 newFeeRatio)` (external)





### `pause()` (external)





### `unpause()` (external)





### `pdc(uint256 id_) → struct ICoupon.PositionDiscountCoupon` (external)





### `mintTo(address toAccount_, uint256 shareAmount_, uint256 grantAmount_) → uint256 id_` (external)

Opens a PDC position.



### `burn(uint256 id_) → uint256 shareAmount_, uint256 grantAmount_` (external)

Closes the `id_` PDC position.



### `updateFee(uint256 id_) → uint256 additionalFee` (external)

Update fee.




### `Open(address account_, uint256 id_)`





### `Close(address account_, uint256 id_)`





### `Deposit(address account_, uint256 id_, uint256 amount)`





### `Withdraw(address account_, uint256 id_, uint256 amount)`





### `Borrow(address account_, uint256 id_, uint256 amount)`





### `Repay(address account_, uint256 id_, uint256 amount)`





### `Update(uint256 id_, uint256 prevFee, uint256 currFee, uint256 prevTimestamp, uint256 currTimestamp)`





### `SetFeeTo(address prevFeeTo, address currFeeTo)`





### `SetFeeRatio(uint256 prevFeeRatio, uint256 currFeeRatio)`





