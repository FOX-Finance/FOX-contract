// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./utils/Nonzero.sol";
import "./tokens/CDP.sol";
import "./interfaces/IFOX.sol";
import "./interfaces/ICoupon.sol";

/**
 * @title FOX Finance Farm.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets WETH as collateral and FOXS as share, gives FOX as debt.
 * Also it is treasury of collaterals-WETHs- and SINs.
 */
contract FoxFarm is CDP, Nonzero {
    IFOX internal immutable _stableToken;
    ICoupon internal immutable _coupon;

    //============ Initialize ============//

    constructor(
        address oracleFeeder_,
        address feeTo_,
        address collateralToken_, // WETH
        address debtToken_, // SIN
        address stableToken_, // FOX
        address coupon_,
        uint256 maxLTV_,
        uint256 cap_,
        uint256 feeRatio_ // stability fee
    )
        nonzeroAddress(oracleFeeder_)
        nonzeroAddress(collateralToken_)
        nonzeroAddress(debtToken_)
        nonzeroAddress(coupon_)
        CDP(
            "FoxFarm",
            "FOXCDP",
            oracleFeeder_,
            feeTo_,
            collateralToken_,
            debtToken_,
            maxLTV_,
            cap_,
            feeRatio_
        )
        nonzeroAddress(stableToken_)
    {
        _stableToken = IFOX(stableToken_);
        _coupon = ICoupon(coupon_);
    }

    //============ View Functions ============//

    //============ CDP Internal Operations (override) ============//

    function _borrow(
        address account_,
        uint256 id_,
        uint256 amount_ // stableAmount
    ) internal override {
        uint256 debtAmount_ = _stableToken.requiredDebtAmountFromStable(
            amount_
        );
        uint256 shareAmount_ = _stableToken.requiredShareAmountFromStable(
            amount_
        );

        super._borrow(account_, id_, debtAmount_);
        _stableToken.mint(account_, debtAmount_, shareAmount_);
    }

    function _repay(
        address account_,
        uint256 id_,
        uint256 amount_ // stableAmount
    ) internal override {
        (uint256 debtAmount_, ) = _stableToken.redeem(account_, amount_);
        super._repay(account_, id_, debtAmount_);
    }

    //============ FOX Operations ============//

    function recollateralizeBorrowDebt(
        address account_,
        uint256 id_,
        uint256 amount_
    )
        external
        whenNotPaused
        onlyCdpApprovedOrOwner(_msgSender(), id_)
        returns (uint256 shareAmount_, uint256 bonusAmount_)
    {
        _update(id_);
        _borrow(_msgSender(), id_, amount_);

        (shareAmount_, bonusAmount_) = _stableToken.recollateralize(
            account_,
            amount_
        );
    }

    function recollateralizeDepositCollateral(
        address account_,
        uint256 id_,
        uint256 amount_
    )
        external
        whenNotPaused
        returns (uint256 shareAmount_, uint256 bonusAmount_)
    {
        uint256 _currentLTV = currentLTV(id_);

        _deposit(_msgSender(), id_, amount_);
        _update(id_);

        uint256 borrowAmount_ = borrowAmountToLTV(id_, _currentLTV);
        _borrow(_msgSender(), id_, borrowAmount_);

        (shareAmount_, bonusAmount_) = _stableToken.recollateralize(
            account_,
            borrowAmount_
        );
    }

    function buybackRepayDebt(
        address account_,
        uint256 id_,
        uint256 amount_
    ) external whenNotPaused returns (uint256 debtAmount_) {
        debtAmount_ = _stableToken.buyback(account_, amount_);

        _update(id_);
        _repay(_msgSender(), id_, debtAmount_);
    }

    function buybackWithdrawCollateral(
        address account_,
        uint256 id_,
        uint256 amount_
    )
        external
        whenNotPaused
        onlyCdpApprovedOrOwner(_msgSender(), id_)
        returns (uint256 debtAmount_)
    {
        debtAmount_ = _stableToken.buyback(account_, amount_);

        uint256 _currentLTV = currentLTV(id_);

        _update(id_);
        _repay(_msgSender(), id_, debtAmount_);

        uint256 withdrawAmount_ = withdrawAmountToLTV(id_, _currentLTV);
        _withdraw(_msgSender(), id_, withdrawAmount_);
    }

    //============ Liquidation ============//

    // TODO: Fast liquidation
    // when touch 100% collateral backing level
    // 1 ether * (DENOMINATOR - trustLevel) / DENOMINATOR == 1 ether * maxLTV / DENOMINATOR;

    //============ Coupon ============//

    function buybackCoupon(address account_, uint256 id_)
        external
        whenNotPaused
        returns (uint256 debtAmount_)
    {}

    // TODO: pair annihilation between SIN and NIS
}
