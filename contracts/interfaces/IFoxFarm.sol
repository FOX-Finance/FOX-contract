// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ICDP.sol";

interface IFoxFarm is ICDP {
    //============ View Functions ============//

    function requiredShareAmountFromCollateralWithLtv(
        uint256 collateralAmount_,
        uint256 ltv_
    ) external view returns (uint256 shareAmount_);

    function requiredCollateralAmountFromShareWithLtv(
        uint256 shareAmount_,
        uint256 ltv_
    ) external view returns (uint256 collateralAmount_);

    function expectedMintAmountWithLtv(
        uint256 collateralAmount_,
        uint256 ltv_,
        uint256 shareAmount_
    ) external view returns (uint256 stableAmount_);

    function expectedRedeemAmountWithLtv(uint256 stableAmount_, uint256 ltv_)
        external
        view
        returns (uint256 collateralAmount_, uint256 shareAmount_);

    function exchangedShareAmountFromCollateralWithLtv(
        uint256 collateralAmount_,
        uint256 ltv_
    ) external view returns (uint256 shareAmount_);

    function exchangedCollateralAmountFromShareWithLtv(
        uint256 shareAmount_,
        uint256 ltv_
    ) external view returns (uint256 collateralAmount_);

    //============ FOX Operations ============//

    function recollateralizeBorrowDebt(
        address account_,
        uint256 id_,
        uint256 amount_
    ) external returns (uint256 shareAmount_, uint256 bonusAmount_);

    function recollateralizeDepositCollateral(
        address account_,
        uint256 id_,
        uint256 amount_
    ) external returns (uint256 shareAmount_, uint256 bonusAmount_);

    function buybackRepayDebt(
        address account_,
        uint256 id_,
        uint256 amount_
    ) external returns (uint256 debtAmount_);

    function buybackWithdrawCollateral(
        address account_,
        uint256 id_,
        uint256 amount_
    ) external returns (uint256 debtAmount_);

    //============ Coupon Operations ============//

    function buybackCoupon(address account_, uint256 amount_)
        external
        returns (uint256 cid_, uint256 debtAmount_);

    function pairAnnihilation(uint256 id_, uint256 cid_) external;
}
