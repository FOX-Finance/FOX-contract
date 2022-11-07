// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ICDP.sol";

interface IFoxFarm is ICDP {
    //============ View Functions (Mint) ============//

    function defaultValuesMint(address account_, uint256 id_)
        external
        view
        returns (
            uint256 collateralAmount_,
            uint256 ltv_,
            uint256 shareAmount_,
            uint256 stableAmount_
        );

    function ltvRangeWhenMint(
        uint256 id_,
        uint256 collateralAmount_,
        uint256 shareAmount_
    ) external view returns (uint256 upperBound_, uint256 lowerBound_);

    function collateralAmountRangeWhenMint(
        address account_,
        uint256 id_,
        uint256 ltv_,
        uint256 shareAmount_
    ) external view returns (uint256 upperBound_, uint256 lowerBound_);

    function shareAmountRangeWhenMint(
        address account_,
        uint256 id_,
        uint256 collateralAmount_,
        uint256 ltv_
    ) external view returns (uint256 upperBound_, uint256 lowerBound_);

    function requiredShareAmountFromCollateralToLtv(
        uint256 id_,
        uint256 newCollateralAmount_,
        uint256 ltv_
    ) external view returns (uint256 shareAmount_);

    function requiredCollateralAmountFromShareToLtv(
        uint256 id_,
        uint256 newShareAmount_,
        uint256 ltv_
    ) external view returns (uint256 collateralAmount_);

    //============ View Functions (Redeem) ============//

    function ltvRangeWhenRedeem(uint256 id_, uint256 collectedStableAmount_)
        external
        view
        returns (uint256 upperBound_, uint256 lowerBound_);

    // TODO: function stableAmountRangeWhenRedeem

    function ltvRangeWhenRecollateralize(uint256 id_, uint256 collateralAmount_)
        external
        view
        returns (uint256 upperBound_, uint256 lowerBound_);

    function collateralAmountRangeWhenRecollateralize(uint256 id_, uint256 ltv_)
        external
        view
        returns (uint256 upperBound_, uint256 lowerBound_);

    function ltvRangeWhenBuyback(uint256 id_, uint256 shareAmount_)
        external
        view
        returns (uint256 upperBound_, uint256 lowerBound_);

    function shareAmountRangeWhenBuyback(uint256 id_)
        external
        view
        returns (uint256 upperBound_, uint256 lowerBound_);

    function expectedMintAmountToLtv(
        uint256 id_,
        uint256 newCollateralAmount_,
        uint256 ltv_,
        uint256 newShareAmount_
    ) external view returns (uint256 newStableAmount_);

    function expectedRedeemAmountToLtv(
        uint256 id_,
        uint256 collectedStableAmount_,
        uint256 ltv_
    )
        external
        view
        returns (uint256 emittedCollateralAmount_, uint256 emittedShareAmount_);

    function exchangedShareAmountFromCollateralToLtv(
        uint256 id_,
        uint256 collateralAmount_,
        uint256 ltv_
    ) external view returns (uint256 shareAmount_);

    function exchangedCollateralAmountFromShareToLtv(
        uint256 id_,
        uint256 shareAmount_,
        uint256 ltv_
    ) external view returns (uint256 collateralAmount_);

    //============ FOX Operations ============//

    function recollateralizeBorrowDebtToLtv(
        address account_,
        uint256 id_,
        uint256 ltv_
    ) external returns (uint256 shareAmount_, uint256 bonusAmount_);

    function recollateralizeDepositCollateral(
        address account_,
        uint256 id_,
        uint256 amount_
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
