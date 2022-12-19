## `FoxFarm`

Gets WETH as collateral and FOXS as share, gives FOX as debt.
Also it is treasury of collaterals-WETHs- and SINs.




### `constructor(address oracleFeeder_, address feeTo_, address collateralToken_, address debtToken_, address shareToken_, address stableToken_, address coupon_, uint256 maxLTV_, uint256 cap_, uint256 feeRatio_, uint256 liquidationPenaltyRatio_, uint256 liquidationBufferRatio_)` (public)





### `initialize()` (public)





### `_borrow(address account_, uint256 id_, uint256 amount_)` (internal)





### `_repay(address account_, uint256 id_, uint256 amount_)` (internal)





### `_close(address account_, uint256 id_)` (internal)





### `mint(uint256 id_, uint256 depositAmount_, uint256 borrowAmount_)` (external)





### `redeem(uint256 id_, uint256 repayAmount_, uint256 withdrawAmount_)` (external)





### `recollateralize(address account_, uint256 id_, uint256 collateralAmount_, uint256 ltv_) → uint256 shareAmount_, uint256 bonusAmount_` (external)





### `buyback(address account_, uint256 id_, uint256 shareAmount_, uint256 ltv_) → uint256 debtAmount_` (external)





### `buybackCoupon(address account_, uint256 shareAmount_) → uint256 pid_, uint256 debtAmount_` (external)





### `pairAnnihilation(uint256 cid_, uint256 pid_)` (external)

Pair annihilation between SIN and NIS.




