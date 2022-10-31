// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./utils/Nonzero.sol";
import "./tokens/CDP.sol";
import "./interfaces/IFOX.sol";
import "./interfaces/ICoupon.sol";

interface ApproveMaxERC20 {
    function approveMax(address spender) external;
}

/**
 * @title FOX Finance Farm.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets WETH as collateral and FOXS as share, gives FOX as debt.
 * Also it is treasury of collaterals-WETHs- and SINs.
 */
contract FoxFarm is CDP, Nonzero {
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

        address _fromAccount = _msgSender();
        _debtToken.safeTransferFrom(_fromAccount, address(this), debtAmount_);
        _shareToken.safeTransferFrom(_fromAccount, address(this), shareAmount_);
        _stableToken.mint(account_, debtAmount_, shareAmount_);
    }

    function _repay(
        address account_,
        uint256 id_,
        uint256 amount_ // stableAmount
    ) internal override {
        IERC20(address(_stableToken)).safeTransferFrom(
            _msgSender(),
            address(this),
            amount_
        );
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

        uint256 borrowAmount_ = borrowAmountToLTV(id_, _currentLTV);
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
    ) external whenNotPaused returns (uint256 debtAmount_) {
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
        returns (uint256 debtAmount_)
    {
        address msgSender = _msgSender();

        _shareToken.safeTransferFrom(msgSender, address(this), amount_);
        debtAmount_ = _stableToken.buyback(account_, amount_);

        uint256 _currentLTV = currentLTV(id_);

        _update(id_);
        _repay(msgSender, id_, debtAmount_);

        uint256 withdrawAmount_ = withdrawAmountToLTV(id_, _currentLTV);
        _withdraw(msgSender, id_, withdrawAmount_);
    }

    //============ Coupon Operations ============//

    function buybackCoupon(address account_, uint256 amount_)
        external
        whenNotPaused
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
        _cdp.debt -= grantAmount_;
    }
}
