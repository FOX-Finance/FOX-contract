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

    function requiredShareAmountFromCollateralWithLtv(
        uint256 id_,
        uint256 collateralAmount_,
        uint256 ltv_
    ) public view returns (uint256 shareAmount_) {
        if (id_ >= id) {
            shareAmount_ = _stableToken.requiredShareAmountFromDebt(
                (collateralAmount_ * _collateralPrice * ltv_) /
                    (_DENOMINATOR * _DENOMINATOR)
            );
        } else {
            // TODO: toLtv
            // CollateralizedDebtPosition memory _cdp = cdps[id_];
            // shareAmount_ = _stableToken.requiredShareAmountFromDebt(
            //     ((_cdp.collateral + collateralAmount_) *
            //         _collateralPrice *
            //         ltv_) /
            //         (_DENOMINATOR * _DENOMINATOR) +
            //         (_cdp.debt + _cdp.fee)
            // );
        }
    }

    function requiredCollateralAmountFromShareWithLtv(
        uint256 id_,
        uint256 shareAmount_,
        uint256 ltv_
    ) public view returns (uint256 collateralAmount_) {
        if (id_ >= id) {
            collateralAmount_ =
                (_stableToken.requiredDebtAmountFromShare(shareAmount_) *
                    _DENOMINATOR *
                    _DENOMINATOR) /
                (ltv_ * _collateralPrice);
        } else {
            // TODO: toLtv
            // CollateralizedDebtPosition memory _cdp = cdps[id_];
            // collateralAmount_ =
            //     (_stableToken.requiredDebtAmountFromShare(shareAmount_) *
            //         _DENOMINATOR *
            //         _DENOMINATOR +
            //         _cdp.debt +
            //         _cdp.fee) /
            //     (ltv_ * _collateralPrice) +
            //     _cdp.collateral;
        }
    }

    function requiredCollateralAmountFromStableWithLtv(
        uint256 id_,
        uint256 stableAmount_,
        uint256 ltv_
    ) public view returns (uint256 collateralAmount_) {
        if (id_ >= id) {
            collateralAmount_ =
                (_stableToken.requiredDebtAmountFromStable(stableAmount_) *
                    _DENOMINATOR *
                    _DENOMINATOR) /
                (ltv_ * _collateralPrice);
        } else {
            CollateralizedDebtPosition memory _cdp = cdps[id_];
            collateralAmount_ =
                (_stableToken.requiredDebtAmountFromStable(stableAmount_) *
                    _DENOMINATOR *
                    _DENOMINATOR +
                    _cdp.debt +
                    _cdp.fee) /
                (ltv_ * _collateralPrice) +
                _cdp.collateral;
        }
    }

    function expectedMintAmountWithLtv(
        uint256 id_,
        uint256 collateralAmount_,
        uint256 ltv_,
        uint256 shareAmount_
    ) public view returns (uint256 stableAmount_) {
        if (id_ >= id) {
            stableAmount_ = _stableToken.expectedMintAmount(
                (collateralAmount_ * _collateralPrice * ltv_) /
                    (_DENOMINATOR * _DENOMINATOR),
                shareAmount_
            );
        } else {
            CollateralizedDebtPosition memory _cdp = cdps[id_];
            stableAmount_ = _stableToken.expectedMintAmount(
                ((collateralAmount_ + _cdp.collateral) *
                    _collateralPrice *
                    ltv_) /
                    (_DENOMINATOR * _DENOMINATOR) +
                    _cdp.debt +
                    _cdp.fee,
                shareAmount_
            );
        }
    }

    function expectedMintAmountToLtv(
        uint256 id_,
        uint256 newCollateralAmount_,
        uint256 ltv_,
        uint256 newShareAmount_
    ) public view returns (uint256 newStableAmount_) {
        if (id_ >= id) {
            newStableAmount_ = _stableToken.expectedMintAmount(
                (newCollateralAmount_ * _collateralPrice * ltv_) /
                    (_DENOMINATOR * _DENOMINATOR),
                newShareAmount_
            );
        } else {
            CollateralizedDebtPosition memory _cdp = cdps[id_];
            newStableAmount_ = _stableToken.expectedMintAmount(
                (ltv_ *
                    (_cdp.collateral + newCollateralAmount_) *
                    _collateralPrice) /
                    (_DENOMINATOR * _DENOMINATOR) -
                    (_cdp.debt + _cdp.fee),
                newShareAmount_
            );
        }
    }

    function expectedRedeemAmountWithLtv(
        uint256 id_,
        uint256 stableAmount_,
        uint256 ltv_
    ) public view returns (uint256 collateralAmount_, uint256 shareAmount_) {
        if (id_ >= id) {
            collateralAmount_ =
                (_stableToken.requiredDebtAmountFromStable(stableAmount_) *
                    _DENOMINATOR *
                    _DENOMINATOR) /
                (ltv_ * _collateralPrice);
            shareAmount_ = _stableToken.requiredShareAmountFromStable(
                stableAmount_
            );
        } else {
            CollateralizedDebtPosition memory _cdp = cdps[id_];
            collateralAmount_ =
                (_stableToken.requiredDebtAmountFromStable(stableAmount_) *
                    _DENOMINATOR *
                    _DENOMINATOR +
                    _cdp.debt +
                    _cdp.fee) /
                (ltv_ * _collateralPrice) +
                _cdp.collateral;
            shareAmount_ = _stableToken.requiredShareAmountFromStable(
                stableAmount_
            );
        }
    }

    function expectedRedeemAmountToLtv(
        uint256 id_,
        uint256 paidStableAmount_,
        uint256 ltv_
    )
        public
        view
        returns (uint256 collateralAmountToWithdraw_, uint256 newShareAmount_)
    {
        if (id_ >= id) {
            collateralAmountToWithdraw_ =
                (_stableToken.requiredDebtAmountFromStable(paidStableAmount_) *
                    _DENOMINATOR *
                    _DENOMINATOR) /
                (ltv_ * _collateralPrice);
            newShareAmount_ = _stableToken.requiredShareAmountFromStable(
                paidStableAmount_
            );
        } else {
            CollateralizedDebtPosition memory _cdp = cdps[id_];
            collateralAmountToWithdraw_ =
                _cdp.collateral - (_stableToken.requiredDebtAmountFromStable(paidStableAmount_) *
                    _DENOMINATOR *
                    _DENOMINATOR) /
                (ltv_ * _collateralPrice);
            newShareAmount_ = _stableToken.requiredShareAmountFromStable(
                paidStableAmount_
            );
        }
    }

    function exchangedShareAmountFromCollateralWithLtv(
        uint256 id_,
        uint256 collateralAmount_,
        uint256 ltv_
    ) public view returns (uint256 shareAmount_) {
        if (id_ >= id) {
            shareAmount_ = _stableToken.exchangedShareAmountFromDebt(
                (collateralAmount_ * _collateralPrice * ltv_) /
                    (_DENOMINATOR * _DENOMINATOR)
            );
        } else {
            CollateralizedDebtPosition memory _cdp = cdps[id_];
            shareAmount_ = _stableToken.exchangedShareAmountFromDebt(
                ((collateralAmount_ + _cdp.collateral) *
                    _collateralPrice *
                    ltv_) /
                    (_DENOMINATOR * _DENOMINATOR) +
                    _cdp.debt +
                    _cdp.fee
            );
        }
    }

    function exchangedCollateralAmountFromShareWithLtv(
        uint256 id_,
        uint256 shareAmount_,
        uint256 ltv_
    ) public view returns (uint256 collateralAmount_) {
        if (id_ >= id) {
            collateralAmount_ =
                (_stableToken.exchangedDebtAmountFromShare(shareAmount_) *
                    _DENOMINATOR *
                    _DENOMINATOR) /
                (ltv_ * _collateralPrice);
        } else {
            CollateralizedDebtPosition memory _cdp = cdps[id_];
            collateralAmount_ =
                (_stableToken.exchangedDebtAmountFromShare(shareAmount_) *
                    _DENOMINATOR *
                    _DENOMINATOR +
                    _cdp.debt +
                    _cdp.fee) /
                (ltv_ * _collateralPrice) +
                _cdp.collateral;
        }
    }

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

    function _close(address account_, uint256 id_) internal override {
        CollateralizedDebtPosition storage _cdp = cdps[id_];

        if (_cdp.debt != 0 || _cdp.fee != 0) {
            _repay(
                account_,
                id_,
                _stableToken.requiredStableAmountFromDebt(_cdp.debt + _cdp.fee)
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
        address msgSender = _msgSender();

        _update(id_);
        _borrow(msgSender, id_, amount_);

        _debtToken.safeTransferFrom(msgSender, address(this), amount_);
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
        address msgSender = _msgSender();
        uint256 _currentLTV = currentLTV(id_);

        _deposit(msgSender, id_, amount_);
        _update(id_);

        uint256 borrowAmount_ = borrowAmountToLTV(id_, _currentLTV, 0);
        _borrow(msgSender, id_, borrowAmount_);

        _debtToken.safeTransferFrom(msgSender, address(this), amount_);
        (shareAmount_, bonusAmount_) = _stableToken.recollateralize(
            account_,
            borrowAmount_
        );
    }

    function buybackRepayDebt(
        address account_,
        uint256 id_,
        uint256 amount_
    ) external whenNotPaused onlyGloballyHealthy returns (uint256 debtAmount_) {
        _shareToken.safeTransferFrom(_msgSender(), address(this), amount_);
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
        onlyGloballyHealthy
        returns (uint256 debtAmount_)
    {
        address msgSender = _msgSender();

        _shareToken.safeTransferFrom(msgSender, address(this), amount_);
        debtAmount_ = _stableToken.buyback(account_, amount_);

        uint256 _currentLTV = currentLTV(id_);

        _update(id_);
        _repay(msgSender, id_, debtAmount_);

        uint256 withdrawAmount_ = withdrawAmountToLTV(id_, _currentLTV, 0);
        _withdraw(msgSender, id_, withdrawAmount_);
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
