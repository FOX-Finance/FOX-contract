// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./utils/Nonzero.sol";
import "./tokens/CDP.sol";
import "./interfaces/IFOX.sol";
import "./interfaces/ICoupon.sol";

import "./interfaces/IFoxFarm.sol";

interface ApproveMaxERC20 {
    function approveMax(address spender) external;
}

/**
 * @title FOX Finance Farm.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets WETH as collateral and FOXS as share, gives FOX as debt.
 * Also it is treasury of collaterals-WETHs- and SINs.
 */
contract FoxFarm is IFoxFarm, CDP, Nonzero {
    using SafeERC20 for IERC20;

    //============ Params ============//

    IERC20 internal immutable _shareToken;
    IFOX internal immutable _stableToken;
    ICoupon internal immutable _coupon;

    //============ Initialize ============//

    constructor(
        address oracleFeeder_,
        address feeTo_,
        address collateralToken_, // WETH
        address debtToken_, // SIN
        address shareToken_, // FOXS
        address stableToken_, // FOX
        address coupon_,
        uint256 maxLTV_,
        uint256 cap_,
        uint256 feeRatio_ // stability fee
    )
        nonzeroAddress(oracleFeeder_)
        nonzeroAddress(collateralToken_)
        nonzeroAddress(debtToken_)
        nonzeroAddress(shareToken_)
        CDP(
            "FoxFarm CDP",
            "CDP",
            oracleFeeder_,
            feeTo_,
            collateralToken_,
            debtToken_,
            maxLTV_,
            cap_,
            feeRatio_
        )
        nonzeroAddress(stableToken_)
        nonzeroAddress(coupon_)
    {
        _shareToken = IERC20(shareToken_);
        _stableToken = IFOX(stableToken_);
        _coupon = ICoupon(coupon_);

        initialize();
    }

    function initialize() public {
        ApproveMaxERC20(address(_debtToken)).approveMax(address(_stableToken));
        ApproveMaxERC20(address(_shareToken)).approveMax(address(_stableToken));
    }

    //============ View Functions ============//

    //============ View Functions (Mint) ============//

    function defaultValuesMint(address account_, uint256 id_)
        external
        view
        returns (
            uint256 collateralAmount_,
            uint256 ltv_, // 40 as default
            uint256 shareAmount_,
            uint256 stableAmount_
        )
    {
        uint256 _hodlCollateralAmount = _collateralToken.balanceOf(account_);
        uint256 _hodlShareAmount = _shareToken.balanceOf(account_);

        uint256 _debtAmount;
        if (id_ < id) {
            ltv_ = currentLTV(id_);
            _debtAmount = borrowDebtAmountToLTV(
                id_,
                _hodlCollateralAmount,
                ltv_
            );
        } else {
            ltv_ = 4000;
            _debtAmount = expectedDebtAmountFromCollateralToLtv(
                _hodlCollateralAmount,
                ltv_
            );
        }

        (stableAmount_, ) = _stableToken.expectedMintAmountWithMintFee(
            _debtAmount,
            _hodlShareAmount
        );

        collateralAmount_ = requiredCollateralAmountFromDebtWithLtv(
            _stableToken.requiredDebtAmountFromStableWithMintFee(stableAmount_),
            ltv_
        );

        shareAmount_ = _stableToken.requiredShareAmountFromStableWithMintFee(
            stableAmount_
        );
    }

    // TODO: Zapping in case of out of range. (ex. FOXS -> SIN|WETH)
    /// @dev LTV range has no `equal` range (only less than and more than) unlike amount-range.
    function ltvRangeWhenMint(
        uint256 id_, // default type(uint256).max
        uint256 collateralAmount_,
        uint256 shareAmount_
    ) public view returns (uint256 upperBound_, uint256 lowerBound_) {
        uint256 _trustLevel = _stableToken.trustLevel();
        if (_trustLevel == 0) {
            return (0, 0);
        }

        if (id_ < id) {
            CollateralizedDebtPosition memory _cdp = cdps[id_];
            upperBound_ = min(
                maxLTV,
                (shareAmount_ *
                    _stableToken.sharePrice() *
                    (_DENOMINATOR - _trustLevel) *
                    _DENOMINATOR) /
                    (_trustLevel *
                        (_cdp.collateral + collateralAmount_) *
                        _collateralPrice) +
                    1
            );

            lowerBound_ =
                (_cdp.debt * _DENOMINATOR * _DENOMINATOR) /
                ((_cdp.collateral + collateralAmount_) * _collateralPrice) -
                1;
        } else {
            upperBound_ = min(
                maxLTV,
                (shareAmount_ *
                    _stableToken.sharePrice() *
                    (_DENOMINATOR - _trustLevel) *
                    _DENOMINATOR) /
                    (_trustLevel * (collateralAmount_) * _collateralPrice) +
                    1
            );

            // lowerBound_ = 1 - 1;
        }
    }

    function collateralAmountRangeWhenMint(
        address account_,
        uint256 id_,
        uint256 ltv_,
        uint256 shareAmount_
    ) public view returns (uint256 upperBound_, uint256 lowerBound_) {
        upperBound_ = _collateralToken.balanceOf(account_);

        lowerBound_ = requiredCollateralAmountFromShareToLtv(
            id_,
            shareAmount_,
            ltv_
        );
    }

    function shareAmountRangeWhenMint(
        address account_,
        uint256 id_,
        uint256 collateralAmount_,
        uint256 ltv_
    ) public view returns (uint256 upperBound_, uint256 lowerBound_) {
        upperBound_ = _shareToken.balanceOf(account_);

        lowerBound_ = requiredShareAmountFromCollateralToLtv(
            id_,
            collateralAmount_,
            ltv_
        );
    }

    function requiredShareAmountFromCollateralToLtv(
        uint256 id_,
        uint256 newCollateralAmount_,
        uint256 ltv_
    ) public view returns (uint256 shareAmount_) {
        uint256 _debtAmount;
        if (id_ < id) {
            _debtAmount = borrowDebtAmountToLTV(
                id_,
                newCollateralAmount_,
                ltv_
            );
        } else {
            _debtAmount = expectedDebtAmountFromCollateralToLtv(
                newCollateralAmount_,
                ltv_
            );
        }

        shareAmount_ = _stableToken.requiredShareAmountFromDebt(_debtAmount);
    }

    function requiredCollateralAmountFromShareToLtv(
        uint256 id_,
        uint256 newShareAmount_,
        uint256 ltv_
    ) public view returns (uint256 collateralAmount_) {
        uint256 _debtAmount = _stableToken.requiredDebtAmountFromShare(
            newShareAmount_
        );

        if (id_ < id) {
            CollateralizedDebtPosition memory _cdp = cdps[id_];
            collateralAmount_ =
                requiredCollateralAmountFromDebtWithLtv(
                    (_cdp.debt + _debtAmount),
                    ltv_
                ) -
                _cdp.collateral;

            collateralAmount_ = max(
                collateralAmount_,
                _minimumCollateral - _cdp.collateral
            );
        } else {
            collateralAmount_ = requiredCollateralAmountFromDebtWithLtv(
                _debtAmount,
                ltv_
            );

            collateralAmount_ = max(collateralAmount_, _minimumCollateral);
        }
    }

    function expectedMintAmountToLtv(
        uint256 id_,
        uint256 newCollateralAmount_,
        uint256 ltv_,
        uint256 newShareAmount_
    ) public view returns (uint256 newStableAmount_) {
        uint256 _debtAmount = borrowDebtAmountToLTV(
            id_,
            newCollateralAmount_,
            ltv_
        );

        (newStableAmount_, ) = _stableToken.expectedMintAmountWithMintFee(
            _debtAmount,
            newShareAmount_
        );
    }

    //============ View Functions (Redeem) ============//

    function defaultValueRedeem(address account_, uint256 id_)
        external
        view
        idRangeCheck(id_)
        returns (
            uint256 stableAmount_,
            uint256 collateralAmount_,
            uint256 ltv_,
            uint256 shareAmount_
        )
    {
        stableAmount_ = IERC20(address(_stableToken)).balanceOf(account_);

        ltv_ = currentLTV(id_);

        uint256 _debtAmount;
        (_debtAmount, shareAmount_, ) = _stableToken
            .expectedRedeemAmountWithBurnFee(stableAmount_);

        collateralAmount_ = requiredCollateralAmountFromDebtWithLtv(
            _debtAmount,
            ltv_
        );
    }

    // TODO: Zapping in case of out of range.
    /// @dev LTV range has no `equal` range (only less than and more than) unlike amount-range.
    function ltvRangeWhenRedeem(uint256 id_, uint256 stableAmount_)
        public
        view
        idRangeCheck(id_)
        returns (uint256 upperBound_, uint256 lowerBound_)
    {
        CollateralizedDebtPosition memory _cdp = cdps[id_];

        upperBound_ = currentLTV(id_) + 1;

        uint256 _debtAmount = _stableToken
            .requiredDebtAmountFromStableWithBurnFee(stableAmount_);

        lowerBound_ =
            ((_cdp.debt - _debtAmount) * _DENOMINATOR * _DENOMINATOR) /
            (_cdp.collateral * _collateralPrice) -
            1;
    }

    function stableAmountRangeWhenRedeem(address account_, uint256 id_)
        public
        view
        idRangeCheck(id_)
        returns (uint256 upperBound_, uint256 lowerBound_)
    {
        upperBound_ = IERC20(address(_stableToken)).balanceOf(account_);

        // lowerBound_ = 0;
    }

    function expectedRedeemAmountToLtv(
        uint256 id_,
        uint256 collectedStableAmount_,
        uint256 ltv_
    )
        public
        view
        idRangeCheck(id_)
        returns (uint256 emittedCollateralAmount_, uint256 emittedShareAmount_)
    {
        uint256 _debtAmount;
        (_debtAmount, emittedShareAmount_, ) = _stableToken
            .expectedRedeemAmountWithBurnFee(collectedStableAmount_);

        CollateralizedDebtPosition memory _cdp = cdps[id_];
        emittedCollateralAmount_ =
            _cdp.collateral -
            requiredCollateralAmountFromDebtWithLtv(
                _cdp.debt - _debtAmount,
                ltv_
            );
    }

    //============ View Functions (Recoll) ============//

    function defaultValuesRecollateralize(address account_, uint256 id_)
        public
        view
        idRangeCheck(id_)
        returns (
            uint256 collateralAmount_,
            uint256 ltv_,
            uint256 shareAmount_
        )
    {
        uint256 _hodlCollateralAmount = _collateralToken.balanceOf(account_);

        ltv_ = currentLTV(id_);

        collateralAmount_ = requiredCollateralAmountFromDebtWithLtv(
            min(
                expectedDebtAmountFromCollateralToLtv(
                    _hodlCollateralAmount,
                    ltv_
                ),
                _stableToken.shortfallRecollateralizeAmount()
            ),
            ltv_
        );

        shareAmount_ = exchangedShareAmountFromCollateralToLtv(
            id_,
            collateralAmount_,
            ltv_
        );
    }

    /// @dev always be same or increasing LTV.
    /// @dev LTV range has no `equal` range (only less than and more than) unlike amount-range.
    function ltvRangeWhenRecollateralize(uint256 id_, uint256 collateralAmount_)
        public
        view
        idRangeCheck(id_)
        returns (uint256 upperBound_, uint256 lowerBound_)
    {
        CollateralizedDebtPosition memory _cdp = cdps[id_];

        uint256 _deptAmount = borrowDebtAmountToLTV(
            id_,
            maxLTV,
            collateralAmount_
        );
        uint256 _shortfallAmount = _stableToken
            .shortfallRecollateralizeAmount();
        _shortfallAmount = _shortfallAmount >= _deptAmount
            ? _deptAmount
            : _shortfallAmount;

        upperBound_ =
            ((_cdp.debt + _cdp.fee + _shortfallAmount) *
                _DENOMINATOR *
                _DENOMINATOR) /
            (_cdp.collateral * _collateralPrice);

        lowerBound_ = currentLTV(id_);
    }

    /// @dev 0 to shorfall.
    function collateralAmountRangeWhenRecollateralize(uint256 id_, uint256 ltv_)
        public
        view
        idRangeCheck(id_)
        returns (uint256 upperBound_, uint256 lowerBound_)
    {
        upperBound_ =
            (_stableToken.shortfallRecollateralizeAmount() *
                _DENOMINATOR *
                _DENOMINATOR) /
            (ltv_ * _collateralPrice);

        // lowerBound_ = 0;
    }

    /// @dev for recoll
    function exchangedShareAmountFromCollateralToLtv(
        uint256 id_,
        uint256 collateralAmount_,
        uint256 ltv_
    ) public view idRangeCheck(id_) returns (uint256 shareAmount_) {
        shareAmount_ = _stableToken.exchangedShareAmountFromDebtWithBonus(
            borrowDebtAmountToLTV(id_, ltv_, collateralAmount_)
        );
    }

    //============ View Functions (Buyback) ============//

    /// @dev always be same or decreasing LTV.
    function ltvRangeWhenBuyback(uint256 id_, uint256 shareAmount_)
        public
        view
        idRangeCheck(id_)
        returns (uint256 upperBound_, uint256 lowerBound_)
    {
        CollateralizedDebtPosition memory _cdp = cdps[id_];

        upperBound_ = currentLTV(id_);

        uint256 _exchangedSurplusShareAmount = _stableToken
            .exchangedShareAmountFromDebt(_stableToken.surplusBuybackAmount());
        _exchangedSurplusShareAmount = _exchangedSurplusShareAmount >=
            shareAmount_
            ? shareAmount_
            : _exchangedSurplusShareAmount;
        uint256 _debtAmount = _stableToken.exchangedDebtAmountFromShare(
            _exchangedSurplusShareAmount
        );

        lowerBound_ =
            ((_cdp.debt - _debtAmount + _cdp.fee) *
                _DENOMINATOR *
                _DENOMINATOR) /
            (_cdp.collateral * _collateralPrice);
    }

    /// @dev 0 to surplus.
    function shareAmountRangeWhenBuyback(uint256 id_)
        public
        view
        idRangeCheck(id_)
        returns (uint256 upperBound_, uint256 lowerBound_)
    {
        CollateralizedDebtPosition memory _cdp = cdps[id_];

        upperBound_ = _stableToken.exchangedShareAmountFromDebt(
            _stableToken.surplusBuybackAmount()
        );

        // lowerBound_ = 0;
    }

    /// @dev for buyback
    function exchangedCollateralAmountFromShareToLtv(
        uint256 id_,
        uint256 shareAmount_,
        uint256 ltv_
    ) public view returns (uint256 collateralAmount_) {
        collateralAmount_ = withdrawCollateralAmountToLTV(
            id_,
            ltv_,
            _stableToken.exchangedDebtAmountFromShare(shareAmount_)
        );
    }

    //============ CDP Internal Operations (override) ============//

    function _borrow(
        address account_,
        uint256 id_,
        uint256 amount_ // stableAmount
    ) internal override {
        uint256 debtAmount_ = _stableToken
            .requiredDebtAmountFromStableWithMintFee(amount_);
        uint256 shareAmount_ = _stableToken
            .requiredShareAmountFromStableWithMintFee(amount_);

        super._borrow(address(this), id_, debtAmount_);

        _shareToken.safeTransferFrom(_msgSender(), address(this), shareAmount_);
        _stableToken.mint(account_, debtAmount_, shareAmount_);
    }

    function _repay(
        address account_,
        uint256 id_,
        uint256 amount_ // stableAmount
    ) internal override {
        address _fromAccount = _msgSender();

        IERC20(address(_stableToken)).safeTransferFrom(
            _fromAccount,
            address(this),
            amount_
        );
        (uint256 debtAmount_, uint256 shareAmount_) = _stableToken.redeem(
            address(this),
            amount_
        );

        super._repay(address(this), id_, debtAmount_);

        _shareToken.safeTransfer(account_, shareAmount_);
    }

    // TODO: test
    function _close(address account_, uint256 id_) internal override {
        CollateralizedDebtPosition storage _cdp = cdps[id_];

        if (_cdp.debt != 0 || _cdp.fee != 0) {
            _repay(
                account_,
                id_,
                _stableToken.requiredStableAmountFromDebtWithBurnFee(
                    _cdp.debt + _cdp.fee
                )
            );
        }
        if (_cdp.collateral != 0) {
            _withdraw(account_, id_, _cdp.collateral);
        }

        _burn(id_);
        delete cdps[id_];

        emit Close(account_, id_);
    }

    //============ FOX Operations ============//

    function recollateralizeBorrowDebtToLtv(
        address account_,
        uint256 id_,
        uint256 ltv_
    )
        external
        updateIdFirst(id_)
        whenNotPaused
        onlyCdpApprovedOrOwner(_msgSender(), id_)
        returns (uint256 shareAmount_, uint256 bonusAmount_)
    {
        uint256 debtAmount_ = borrowDebtAmountToLTV(id_, ltv_, 0);

        super._borrow(address(this), id_, debtAmount_);

        (shareAmount_, bonusAmount_) = _stableToken.recollateralize(
            account_,
            debtAmount_
        );
    }

    function recollateralizeDepositCollateral(
        address account_,
        uint256 id_,
        uint256 amount_ // collateralAmount
    )
        external
        updateIdFirst(id_)
        whenNotPaused
        onlyCdpApprovedOrOwner(_msgSender(), id_)
        returns (uint256 shareAmount_, uint256 bonusAmount_)
    {
        uint256 _ltv = currentLTV(id_);

        _deposit(_msgSender(), id_, amount_);

        uint256 debtAmount_ = borrowDebtAmountToLTV(id_, _ltv, 0);

        super._borrow(address(this), id_, debtAmount_);

        (shareAmount_, bonusAmount_) = _stableToken.recollateralize(
            account_,
            debtAmount_
        );
    }

    function buybackRepayDebt(uint256 id_, uint256 shareAmount_)
        external
        updateIdFirst(id_)
        whenNotPaused
        onlyGloballyHealthy
        returns (uint256 debtAmount_)
    {
        _shareToken.safeTransferFrom(_msgSender(), address(this), shareAmount_);

        debtAmount_ = _stableToken.buyback(address(this), shareAmount_);

        super._repay(address(this), id_, debtAmount_);
    }

    function buybackWithdrawCollateral(
        address account_,
        uint256 id_,
        uint256 amount_, // shareAmount
        uint256 ltv_
    )
        external
        updateIdFirst(id_)
        whenNotPaused
        onlyCdpApprovedOrOwner(_msgSender(), id_)
        onlyGloballyHealthy
        returns (uint256 debtAmount_)
    {
        address msgSender = _msgSender();

        _shareToken.safeTransferFrom(msgSender, address(this), amount_);
        debtAmount_ = _stableToken.buyback(address(this), amount_);

        super._repay(address(this), id_, debtAmount_);

        uint256 withdrawAmount_ = withdrawCollateralAmountToLTV(id_, ltv_, 0);
        _withdraw(account_, id_, withdrawAmount_);
    }

    //============ Coupon Operations ============//

    function buybackCoupon(address account_, uint256 amount_)
        external
        whenNotPaused
        onlyGloballyHealthy
        returns (uint256 cid_, uint256 debtAmount_)
    {
        _shareToken.safeTransferFrom(_msgSender(), address(this), amount_);
        debtAmount_ = _stableToken.buyback(address(this), amount_);

        cid_ = _coupon.mintTo(account_, amount_, debtAmount_);
    }

    /**
     * @notice Pair annihilation between SIN and NIS.
     */
    function pairAnnihilation(uint256 id_, uint256 cid_)
        external
        whenNotPaused
    {
        (, uint256 grantAmount_) = _coupon.burn(cid_);

        CollateralizedDebtPosition storage _cdp = cdps[id_];

        if (_cdp.fee >= grantAmount_) {
            _cdp.fee -= grantAmount_;
        } else {
            _cdp.fee = 0;
            _cdp.debt -= (grantAmount_ - _cdp.fee);
        }
    }
}

function max(uint256 a, uint256 b) pure returns (uint256) {
    return a > b ? a : b;
}

function min(uint256 a, uint256 b) pure returns (uint256) {
    return a < b ? a : b;
}
