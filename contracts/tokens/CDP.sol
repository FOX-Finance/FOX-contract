// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../oracle/Oracle.sol";
import "../interfaces/ISIN.sol";

import "../interfaces/ICDP.sol";

// import "./interfaces/IWETH.sol";

/**
 * @title Collateralized Debt Position.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets WETH as collateral, gives SIN as debt.
 * @dev Abstract contract.
 */
abstract contract CDP is ICDP, ERC721, Pausable, Ownable, Oracle {
    using SafeERC20 for IERC20;

    //============ Params ============//

    IERC20 internal immutable _collateralToken;
    IERC20 internal immutable _debtToken;

    uint256 internal _collateralPrice = 30000; // TODO: initial collateral price
    // treats SIN is always $1.

    uint256 internal constant _DENOMINATOR = 10000;
    uint256 internal constant _minimumCollateral = 0.005 ether;
    uint256 public maxLTV; // (maxLTV / _DENOMINATOR)
    uint256 public cap; // total debt cap

    address internal _feeTo;
    uint256 internal _feeRatio; // (_feeRatio / _DENOMINATOR) // stability fee // TODO: default value

    uint256 internal _liquidationRatio; // (_liquidationRatio / _DENOMINATOR) // liquidation penalty fee // TODO: default value

    // CDP
    mapping(uint256 => CollateralizedDebtPosition) public _cdps;
    uint256 public id;
    uint256 public totalCollateral;
    uint256 public totalDebt;
    uint256 public totalFee;

    //============ Modifiers ============//

    modifier onlyCdpApprovedOrOwner(address msgSender, uint256 id_) {
        require(
            _isApprovedOrOwner(msgSender, id_),
            "CDP::onlyCdpApprovedOrOwner: Not a valid caller."
        );
        _;
    }

    modifier onlyGloballyHealthy() {
        require(
            globalHealthFactor() < _DENOMINATOR,
            "CDP::onlyGloballyHealthy: Not healty."
        );
        _;
    }

    modifier updateIdFirst(uint256 id_) {
        _update(id_);
        _;
    }

    modifier updateIdLast(uint256 id_) {
        _;
        _update(id_);
    }

    modifier idRangeCheck(uint256 id_) {
        require(id_ < id, "CDP::idRangeCheck: Invalid range of id.");
        _;
    }

    //============ Initialize ============//

    constructor(
        string memory name_,
        string memory symbol_,
        address oracleFeeder_,
        address feeTo_,
        address collateralToken_,
        address debtToken_,
        uint256 maxLTV_,
        uint256 cap_,
        uint256 feeRatio_,
        uint256 liquidationRatio_
    ) ERC721(name_, symbol_) Oracle(oracleFeeder_) {
        _feeTo = feeTo_; // can be zero address
        _collateralToken = IERC20(collateralToken_);
        _debtToken = IERC20(debtToken_);
        maxLTV = maxLTV_;
        cap = cap_;
        _feeRatio = feeRatio_;
        _liquidationRatio = liquidationRatio_;
    }

    //============ Owner ============//

    function setMaxLTV(uint256 newMaxLTV) external virtual onlyOwner {
        uint256 prevMaxLTV = maxLTV;
        maxLTV = newMaxLTV;
        emit SetMaxLTV(prevMaxLTV, maxLTV);
    }

    function setCap(uint256 newCap) external virtual onlyOwner {
        uint256 prevCap = cap;
        cap = newCap;
        emit SetCap(prevCap, cap);
    }

    function setFeeTo(address newFeeTo) external virtual onlyOwner {
        address prevFeeTo = _feeTo;
        _feeTo = newFeeTo;
        emit SetFeeTo(prevFeeTo, _feeTo);
    }

    function setFeeRatio(uint256 newFeeRatio) external virtual onlyOwner {
        uint256 prevFeeRatio = _feeRatio;
        _feeRatio = newFeeRatio;
        emit SetFeeRatio(prevFeeRatio, _feeRatio);
    }

    function setLiquidationRatio(
        uint256 newLiquidationRatio
    ) external virtual onlyOwner {
        uint256 prevLiquidationRatio = _liquidationRatio;
        _liquidationRatio = newLiquidationRatio;
        emit SetFeeRatio(prevLiquidationRatio, _liquidationRatio);
    }

    //============ Pausable ============//

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //============ Oracle Functions ============//

    function updateOracleFeeder(address newOracleFeeder) external onlyOwner {
        _updateOracleFeeder(newOracleFeeder);
    }

    function updateCollateralPrice(
        uint256 newCollateralPrice,
        uint256 confidence
    ) external onlyOracleFeeder {
        // TODO: confidence interval, delta -> pause

        uint256 prevPrice = _collateralPrice;
        _collateralPrice = newCollateralPrice;
        emit UpdatePrice(
            address(_collateralToken),
            prevPrice,
            _collateralPrice
        );
    }

    //============ Health Functions ============//

    /**
     * @notice CDP risk indicator.
     */
    function isSafe(uint256 id_) public view returns (bool) {
        return (healthFactor(id_) < _DENOMINATOR);
    }

    /// @dev multiplied by _DENOMINATOR.
    function globalLTV() public view virtual returns (uint256 ltv_) {
        ltv_ = calculatedLtv(totalDebt, totalCollateral);
    }

    /// @dev multiplied by _DENOMINATOR.
    function currentLTV(
        uint256 id_
    ) public view virtual returns (uint256 ltv_) {
        if (id_ >= id) {
            return 0;
        } else {
            CollateralizedDebtPosition memory _cdp = _cdps[id_];
            ltv_ = calculatedLtv(_cdp.collateral, _cdp.debt + _cdp.fee);
        }
    }

    /// @dev multiplied by _DENOMINATOR.
    function healthFactor(
        uint256 id_
    ) public view virtual returns (uint256 health) {
        CollateralizedDebtPosition memory _cdp = _cdps[id_];

        if (_cdp.collateral == 0) {
            if (_cdp.debt == 0) {
                return 0;
            } else {
                return _DENOMINATOR;
            }
        }

        health =
            ((_cdp.debt + _cdp.fee) *
                _DENOMINATOR *
                _DENOMINATOR *
                _DENOMINATOR) /
            (_cdp.collateral * _collateralPrice * maxLTV);
    }

    /// @dev multiplied by _DENOMINATOR.
    function globalHealthFactor() public view virtual returns (uint256 health) {
        if (totalCollateral != 0 && _collateralPrice != 0 && maxLTV != 0) {
            health =
                (totalDebt * _DENOMINATOR * _DENOMINATOR * _DENOMINATOR) /
                (totalCollateral * _collateralPrice * maxLTV);
        }
    }

    //============ View Functions ============//

    function cdp(
        uint256 id_
    ) external view returns (CollateralizedDebtPosition memory) {
        return _cdps[id_];
    }

    function cdpInfo(
        uint256 id_
    )
        external
        view
        returns (uint256 collateralAmount_, uint256 ltv_, uint256 fee_)
    {
        CollateralizedDebtPosition memory _cdp = _cdps[id_];
        collateralAmount_ = _cdp.collateral;
        ltv_ = currentLTV(id_);
        fee_ = _cdp.fee;
    }

    /// @dev multiplied by _DENOMINATOR.
    function calculatedLtv(
        uint256 collateralAmount_,
        uint256 debtAmount_
    ) public view virtual returns (uint256 ltv_) {
        ltv_ =
            (debtAmount_ * _DENOMINATOR * _DENOMINATOR) /
            (collateralAmount_ * _collateralPrice);
    }

    function collateralToken() public view virtual returns (address) {
        return address(_collateralToken);
    }

    function debtToken() public view virtual returns (address) {
        return address(_debtToken);
    }

    function collateralPrice() public view virtual returns (uint256) {
        return _collateralPrice;
    }

    function minimumCollateral() public view virtual returns (uint256) {
        return _minimumCollateral;
    }

    //============ View Functions (CDP) ============//

    function debtAmountFromCollateralToLtv(
        uint256 collateralAmount_,
        uint256 ltv_
    ) public view returns (uint256 debtAmount_) {
        debtAmount_ =
            (collateralAmount_ * _collateralPrice * ltv_) /
            (_DENOMINATOR * _DENOMINATOR);
    }

    function collateralAmountFromDebtWithLtv(
        uint256 debtAmount_,
        uint256 ltv_
    ) public view returns (uint256 collateralAmount_) {
        collateralAmount_ =
            (debtAmount_ * _DENOMINATOR * _DENOMINATOR) /
            (ltv_ * _collateralPrice);
    }

    //============ CDP Operations ============//

    /**
     * @notice Opens a CDP position.
     */
    function open()
        external
        virtual
        updateIdLast(id_)
        whenNotPaused
        returns (uint256 id_)
    {
        id_ = _open(_msgSender());
    }

    /**
     * @notice Opens a CDP position
     * and deposits `amount_` into the created CDP.
     *
     * Requirements:
     *
     * - Do `approve` first.
     */
    function openAndDeposit(
        uint256 amount_
    ) external virtual whenNotPaused returns (uint256 id_) {
        address msgSender = _msgSender();

        id_ = _open(msgSender);
        _update(id_);
        _deposit(msgSender, id_, amount_);
    }

    function openAndDepositAndBorrow(
        uint256 depositAmount_,
        uint256 borrowAmount_
    ) external whenNotPaused returns (uint256 id_) {
        address msgSender = _msgSender();

        id_ = _open(msgSender);
        _update(id_);
        _deposit(msgSender, id_, depositAmount_);
        _borrow(msgSender, id_, borrowAmount_);
    }

    /**
     * @notice Closes the `id_` CDP position.
     */
    function close(
        uint256 id_
    ) external updateIdFirst(id_) onlyCdpApprovedOrOwner(_msgSender(), id_) {
        _close(_msgSender(), id_);
    }

    /**
     * @dev Deposits collateral into CDP.
     *
     * Requirements:
     *
     * - Do `approve` first.
     */
    function deposit(
        uint256 id_,
        uint256 amount_
    ) external updateIdFirst(id_) whenNotPaused {
        _deposit(_msgSender(), id_, amount_);
    }

    function depositAndBorrow(
        uint256 id_,
        uint256 depositAmount_,
        uint256 borrowAmount_
    )
        external
        whenNotPaused
        updateIdFirst(id_)
        onlyCdpApprovedOrOwner(_msgSender(), id_)
    {
        _deposit(_msgSender(), id_, depositAmount_);
        _borrow(_msgSender(), id_, borrowAmount_);
    }

    /**
     * @notice Withdraws collateral from `this` to `_msgSender()`.
     */
    function withdraw(
        uint256 id_,
        uint256 amount_
    ) external updateIdFirst(id_) onlyCdpApprovedOrOwner(_msgSender(), id_) {
        _withdraw(_msgSender(), id_, amount_);
    }

    /**
     * @notice Borrows `amount_` debts.
     */
    function borrow(
        uint256 id_,
        uint256 amount_
    )
        external
        updateIdFirst(id_)
        whenNotPaused
        onlyCdpApprovedOrOwner(_msgSender(), id_)
    {
        _borrow(_msgSender(), id_, amount_);
    }

    /**
     * @notice Repays `amount_` debts.
     */
    function repay(uint256 id_, uint256 amount_) external updateIdFirst(id_) {
        _repay(_msgSender(), id_, amount_);
    }

    function repayAndWithdraw(
        uint256 id_,
        uint256 repayAmount_,
        uint256 withdrawAmount_
    ) external updateIdFirst(id_) {
        address msgSender = _msgSender();
        _repay(msgSender, id_, repayAmount_);
        _withdraw(msgSender, id_, withdrawAmount_);
    }

    // TODO: auction
    function liquidate(
        uint256 id_,
        uint256 amount_
    ) external updateIdFirst(id_) {
        _liquidate(_msgSender(), id_, amount_, _liquidationRatio);
    }

    /**
     * @notice Liquidation fee is deducted when paused.
     * @dev First `pause()`, then `globalLiquidate()`.
     */
    function globalLiquidate(
        uint256 id_,
        uint256 amount_
    )
        external
        updateIdFirst(id_)
        whenPaused
        onlyCdpApprovedOrOwner(_msgSender(), id_)
    {
        _liquidate(_msgSender(), id_, amount_, 0);
    }

    /**
     * @notice Update fee.
     */
    function updateFee(uint256 id_) external returns (uint256 additionalFee) {
        return _update(id_);
    }

    //============ Internal Functions ============//

    function _open(
        address account_
    ) internal onlyGloballyHealthy returns (uint256 id_) {
        id_ = id++;

        _safeMint(account_, id_); // mint NFT

        // _cdps[id_].collateral = 0;
        // _cdps[id_].debt = 0;

        emit Open(account_, id_);
    }

    function _close(address account_, uint256 id_) internal virtual {
        CollateralizedDebtPosition storage _cdp = _cdps[id_];

        if (_cdp.debt != 0 || _cdp.fee != 0) {
            _repay(account_, id_, _cdp.debt + _cdp.fee);
        }
        if (_cdp.collateral != 0) {
            _withdraw(account_, id_, _cdp.collateral);
        }

        _burn(id_);
        delete _cdps[id_];

        emit Close(account_, id_);
    }

    function _deposit(address account_, uint256 id_, uint256 amount_) internal {
        CollateralizedDebtPosition storage _cdp = _cdps[id_];

        // require(_isApprovedOrOwner(_sender, id_)); // Anyone

        _cdp.collateral += amount_;
        totalCollateral += amount_;
        _collateralToken.safeTransferFrom(account_, address(this), amount_);

        require(
            _cdp.collateral >= _minimumCollateral,
            "CDP::_deposit: Not enough collateral."
        );

        emit Deposit(account_, id_, amount_);
    }

    function _withdraw(
        address account_,
        uint256 id_,
        uint256 amount_
    ) internal {
        CollateralizedDebtPosition storage _cdp = _cdps[id_];

        _cdp.collateral -= amount_;
        totalCollateral -= amount_;
        _collateralToken.safeTransfer(account_, amount_);

        require(isSafe(id_), "CDP::_withdraw: CDP operation exceeds max LTV.");
        require(
            _cdp.collateral == 0 || _cdp.collateral >= _minimumCollateral,
            "CDP::_withdraw: Not enough collateral."
        );

        emit Withdraw(account_, id_, amount_);
    }

    function _borrow(
        address account_,
        uint256 id_,
        uint256 amount_
    ) internal virtual onlyGloballyHealthy {
        CollateralizedDebtPosition storage _cdp = _cdps[id_];

        _cdp.debt += amount_;
        totalDebt += amount_;
        ISIN(address(_debtToken)).mintTo(account_, amount_);

        require(isSafe(id_), "CDP::_borrow: CDP operation exceeds max LTV.");
        require(
            _debtToken.totalSupply() <= cap,
            "CDP::_borrow: Cannot borrow SIN anymore."
        );

        emit Borrow(account_, id_, amount_);
    }

    function _repay(
        address account_, // from
        uint256 id_,
        uint256 amount_
    ) internal virtual {
        CollateralizedDebtPosition storage _cdp = _cdps[id_];

        // fee
        if ((_feeTo != address(0)) && (_cdp.fee != 0)) {
            address feeTo = _feeTo;

            // repay fee first
            if (_cdp.fee >= amount_) {
                _cdp.fee -= amount_;
                totalFee -= amount_;
                if (account_ == address(this)) {
                    _debtToken.safeTransfer(feeTo, amount_);
                } else {
                    _debtToken.safeTransferFrom(account_, feeTo, amount_);
                }
            } else {
                if (account_ == address(this)) {
                    _debtToken.safeTransfer(feeTo, _cdp.fee);
                } else {
                    _debtToken.safeTransferFrom(account_, feeTo, _cdp.fee);
                }
                _cdp.debt -= (amount_ - _cdp.fee);
                totalDebt -= (amount_ - _cdp.fee);
                ISIN(address(_debtToken)).burnFrom(
                    account_,
                    (amount_ - _cdp.fee)
                );
                _cdp.fee = 0;
            }
        } else {
            _cdp.debt -= amount_;
            totalDebt -= amount_;
            ISIN(address(_debtToken)).burnFrom(account_, amount_);
        }

        emit Repay(account_, id_, amount_);
    }

    /**
     * @dev Updates fee and timestamp.
     */
    function _update(uint256 id_) internal returns (uint256 additionalFee) {
        if (_feeTo == address(0)) {
            return 0;
        }

        CollateralizedDebtPosition storage _cdp = _cdps[id_];

        uint256 prevTimestamp = _cdp.latestUpdate;
        uint256 currTimestamp = block.timestamp;
        uint256 prevFee = _cdp.fee;
        uint256 currFee;

        additionalFee =
            (_cdp.debt * (currTimestamp - prevTimestamp) * _feeRatio) /
            (_DENOMINATOR * 365 * 24 * 60 * 60);
        _cdp.fee += additionalFee;
        totalFee += additionalFee;

        _cdp.latestUpdate = currTimestamp;
        currFee = _cdp.fee;

        emit Update(id_, prevFee, currFee, prevTimestamp, currTimestamp);
    }

    function _liquidate(
        address account_, // from & to
        uint256 id_,
        uint256 amount_,
        uint256 liquidationRatio_
    ) internal virtual {
        require(!isSafe(id_), "CDP::liquidate: CDP must be unsafe.");

        // _close(_msgSender(), id_);

        // repay
        _repay(account_, id_, amount_);

        // withdraw
        uint256 _collateralAmountWithPenalty = (amount_ *
            (_DENOMINATOR + liquidationRatio_)) / _collateralPrice;

        CollateralizedDebtPosition storage _cdp = _cdps[id_];

        _cdp.collateral -= _collateralAmountWithPenalty;
        totalCollateral -= _collateralAmountWithPenalty;
        _collateralToken.safeTransfer(account_, _collateralAmountWithPenalty);

        emit Liquidate(account_, id_, amount_, _collateralAmountWithPenalty);
    }
}
