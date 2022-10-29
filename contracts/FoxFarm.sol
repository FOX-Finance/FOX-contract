// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./tokens/abstractCDP.sol";

/**
 * @title FOX Finance Farm.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets WETH as collateral and FOXS as share, gives FOX as debt.
 * Also it is treasury of collaterals-WETHs- and SINs.
 */
contract FoxFarm is abstractCDP {
    using SafeERC20 for IERC20;

    IERC20 public immutable stableToken;

    //============ Initialize ============//

    constructor(
        address oracleFeeder_,
        address feeTo_,
        address collateralToken_, // WETH
        address debtToken_, // SIN
        address stableToken_, // FOX
        uint256 maxLTV_,
        uint256 cap_,
        uint256 feeRatio_
    )
        abstractCDP(
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
        stableToken = IERC20(stableToken_);
    }

    //============ View Functions ============//

    //============ Liquidation ============//

    function liquidate() external {}

    function globalLiquidate() external {}

    // TODO: Fast liquidation
    // when touch 100% collateral backing level

    //============ Coupon ============//

    // TODO: pair annihilation between SIN and NIS

    //============ FOX Operations (+override) ============//

    // TODO: Price
    // 1 ether * (DENOMINATOR - trustLevel) / DENOMINATOR == 1 ether * maxLTV / DENOMINATOR;

    //============ Recallateralize ============//

    function recollateralizeBorrowDebt() external whenNotPaused {}

    function recollateralizeDepositCollateral() external whenNotPaused {}

    //============ Buyback ============//

    function buybackRepayDebt() external whenNotPaused {}

    function buybackWithdrawCollateral() external whenNotPaused {}

    function buybackCoupon() external whenNotPaused {}

    //============ CDP Operations (+override) ============//

    // open
    // openAndDeposit
    // close
    // deposit
    // withdraw

    // TODO
    // openAndDepositAndBorrow
    // depositAndBorrow

    /**
     * @notice Borrows `amount_` debts.
     * @param id_ CDP number.
     * @param amount_ of FOX.
     */
    function borrow(uint256 id_, uint256 amount_)
        external
        override
        whenNotPaused
    {
        _update(id_);
        _borrow(_msgSender(), id_, amount_); // now contract has SINs.
        uint256 foxsAmount = requiredFoxs(); // get FOXS.
        stableToken.safeTransferFrom(_msgSender(), address(this), foxsAmount);
    }

    /**
     * @notice Repays `amount_` debts.
     */
    function repay(uint256 id_, uint256 amount_)
        external
        override
        whenNotPaused
    {}

    //============ Internal Functions (+override) ============//

    function requiredFoxs() public returns (uint256) {}

    function _borrow(
        address account_,
        uint256 id_,
        uint256 amount_
    ) internal override {
        CDP storage _cdp = cdps[id_];

        require(
            _isApprovedOrOwner(account_, id_),
            "FoxCDP::_borrow: Not a valid caller."
        );

        _cdp.debt += amount_;
        // ISIN(address(_debtToken)).mintTo(account_, amount_);
        ISIN(address(_debtToken)).mintTo(address(this), amount_); // save SINs here

        require(isSafe(id_), "FoxCDP::_borrow: CDP operation exceeds max LTV.");
        require(
            _debtToken.totalSupply() <= cap,
            "FoxCDP::_borrow: Cannot borrow SIN anymore."
        );

        emit Borrow(account_, id_, amount_);
    }

    function _repay(
        address account_,
        uint256 id_,
        uint256 amount_
    ) internal override {
        CDP storage _cdp = cdps[id_];

        // repay fee first
        if (_cdp.fee >= amount_) {
            _cdp.fee -= amount_;
            // _debtToken.safeTransferFrom(account_, _feeTo, amount_);
            _debtToken.safeTransfer(_feeTo, amount_);
        } else if (_cdp.fee != 0) {
            // _debtToken.safeTransferFrom(account_, _feeTo, _cdp.fee);
            _debtToken.safeTransfer(_feeTo, _cdp.fee);
            _cdp.debt -= (amount_ - _cdp.fee);
            // ISIN(address(_debtToken)).burnFrom(account_, amount_ - _cdp.fee);
            ISIN(address(_debtToken)).burn(amount_ - _cdp.fee);
            _cdp.fee = 0;
        }

        emit Repay(account_, id_, amount_);
    }
}
