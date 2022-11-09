// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ICDP.sol";

interface IFoxFarm is ICDP {
    //============ FOX Operations ============//

    function mint(
        uint256 id_,
        uint256 depositAmount_,
        uint256 borrowAmount_
    ) external;

    function redeem(
        uint256 id_,
        uint256 repayAmount_,
        uint256 withdrawAmount_
    ) external;

    function recollateralize(
        address account_,
        uint256 id_,
        uint256 collateralAmount_,
        uint256 ltv_
    ) external returns (uint256 shareAmount_, uint256 bonusAmount_);

    function buybackRepayDebt(uint256 id_, uint256 amount_)
        external
        returns (uint256 debtAmount_);

    function buybackWithdrawCollateral(
        address account_,
        uint256 id_,
        uint256 amount_,
        uint256 ltv_
    ) external returns (uint256 debtAmount_);

    //============ Coupon Operations ============//

    function buybackCoupon(address account_, uint256 amount_)
        external
        returns (uint256 cid_, uint256 debtAmount_);

    function pairAnnihilation(uint256 id_, uint256 cid_) external;
}
