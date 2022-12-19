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
        uint256 feeRatio_, // stability fee
        uint256 liquidationPenaltyRatio_,
        uint256 liquidationBufferRatio_
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
            feeRatio_,
            liquidationPenaltyRatio_,
            liquidationBufferRatio_
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

    function _close(address account_, uint256 id_) internal override {
        CollateralizedDebtPosition storage _cdp = _cdps[id_];

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
        delete _cdps[id_];

        emit Close(account_, id_);
    }

    //============ FOX Operations (Mint) ============//

    function mint(
        uint256 id_,
        uint256 depositAmount_,
        uint256 borrowAmount_
    ) external whenNotPaused {
        address msgSender = _msgSender();

        if (id_ < id) {
            require(
                _isApprovedOrOwner(msgSender, id_),
                "CDP::onlyCdpApprovedOrOwner: Not a valid caller."
            );

            // deposit & borrow
            _update(id_);
            _deposit(msgSender, id_, depositAmount_);
            _borrow(msgSender, id_, borrowAmount_);
        } else {
            // open & deposit & borrow
            id_ = _open(msgSender);
            _update(id_);
            _deposit(msgSender, id_, depositAmount_);
            _borrow(msgSender, id_, borrowAmount_);
        }
    }

    //============ FOX Operations (Redeem) ============//

    function redeem(
        uint256 id_,
        uint256 repayAmount_,
        uint256 withdrawAmount_
    ) external whenNotPaused {
        address msgSender = _msgSender();

        if (id_ < id) {
            // repay & withdraw
            _update(id_);
            _repay(msgSender, id_, repayAmount_);
            _withdraw(msgSender, id_, withdrawAmount_);
        } else {
            require(
                _isApprovedOrOwner(msgSender, id_),
                "CDP::onlyCdpApprovedOrOwner: Not a valid caller."
            );

            // (repay & withdraw) & close
            _update(id_);
            _close(msgSender, id_);
        }
    }

    //============ FOX Operations (Recoll) ============//

    function recollateralize(
        address account_,
        uint256 id_,
        uint256 collateralAmount_,
        uint256 ltv_
    )
        external
        updateIdFirst(id_)
        whenNotPaused
        onlyCdpApprovedOrOwner(_msgSender(), id_)
        returns (uint256 shareAmount_, uint256 bonusAmount_)
    {
        _deposit(_msgSender(), id_, collateralAmount_);

        CollateralizedDebtPosition memory _cdp = cdp(id_);
        uint256 debtAmount_ = debtAmountFromCollateralToLtv(
            _cdp.collateral,
            ltv_
        ) - (_cdp.debt + _cdp.fee);

        super._borrow(address(this), id_, debtAmount_);

        (shareAmount_, bonusAmount_) = _stableToken.recollateralize(
            account_,
            debtAmount_
        );
    }

    //============ FOX Operations (Buyback) ============//

    function buyback(
        address account_,
        uint256 id_,
        uint256 shareAmount_,
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

        _shareToken.safeTransferFrom(msgSender, address(this), shareAmount_);
        debtAmount_ = _stableToken.buyback(address(this), shareAmount_);

        super._repay(address(this), id_, debtAmount_);

        CollateralizedDebtPosition memory _cdp = cdp(id_);
        uint256 withdrawAmount_ = _cdp.collateral -
            collateralAmountFromDebtWithLtv(_cdp.debt + _cdp.fee, ltv_);

        _withdraw(account_, id_, withdrawAmount_);
    }

    //============ Coupon Operations ============//

    function buybackCoupon(
        address account_,
        uint256 shareAmount_
    )
        external
        whenNotPaused
        onlyGloballyHealthy
        returns (uint256 pid_, uint256 debtAmount_)
    {
        _shareToken.safeTransferFrom(_msgSender(), address(this), shareAmount_);
        debtAmount_ = _stableToken.buyback(address(this), shareAmount_);

        pid_ = _coupon.mintTo(account_, shareAmount_, debtAmount_);
    }

    /**
     * @notice Pair annihilation between SIN and NIS.
     */
    function pairAnnihilation(
        uint256 cid_,
        uint256 pid_
    ) external updateIdFirst(cid_) whenNotPaused {
        (, uint256 grantAmount_) = _coupon.burn(pid_); // includes _update(pid_);

        CollateralizedDebtPosition storage _cdp = _cdps[cid_];

        if (_cdp.fee >= grantAmount_) {
            _cdp.fee -= grantAmount_;
            totalFee -= _cdp.fee;
        } else if (_cdp.debt + _cdp.fee < grantAmount_) {
            totalDebt -= _cdp.debt;
            _cdp.debt = 0; // -= _cdp.debt;

            totalFee -= _cdp.fee;
            _cdp.fee = 0; // -= _cdp.fee;
        } else {
            _cdp.debt -= (grantAmount_ - _cdp.fee);
            totalDebt -= (grantAmount_ - _cdp.fee);

            totalFee -= _cdp.fee;
            _cdp.fee = 0; // -= _cdp.fee;
        }
    }

    // TODO
    // function buybackCouponWithPairAnnihilation() external {}
}
