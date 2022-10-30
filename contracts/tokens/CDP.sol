// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../oracle/Oracle.sol";
import "../utils/Interval.sol";
import "../interfaces/ISIN.sol";

import "../interfaces/ICDP.sol";

// import "./interfaces/IWETH.sol";

/**
 * @title Collateralized Debt Position.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets WETH as collateral, gives SIN as debt.
 * @dev Abstract contract.
 */
abstract contract CDP is ICDP, Oracle, Interval, ERC721, Pausable, Ownable {
    using SafeERC20 for IERC20;

    //============ Params ============//

    IERC20 internal immutable _collateralToken;
    IERC20 internal immutable _debtToken;

    uint256 private _collateralPrice = 10000; // TODO: initial collateral price
    // treats SIN is always $1.

    uint256 private constant _DENOMINATOR = 10000;
    uint256 private constant _minimumCollateral = 0.005 ether;
    uint256 public maxLTV; // (maxLTV / _DENOMINATOR)
    uint256 public cap; // total debt cap

    uint256 private constant _TIME_PERIOD = 1 hours;

    address internal _feeTo;
    uint256 internal _feeRatio; // (_feeRatio / _DENOMINATOR) // stability fee

    // CDP
    mapping(uint256 => CollateralizedDebtPosition) public cdps;
    uint256 public id;

    //============ Modifiers ============//

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
        uint256 feeRatio_
    ) ERC721(name_, symbol_) Oracle(oracleFeeder_) {
        _feeTo = feeTo_; // can be zero address
        _collateralToken = IERC20(collateralToken_);
        _debtToken = IERC20(debtToken_);

        maxLTV = maxLTV_;
        cap = cap_;

        _feeRatio = feeRatio_;
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

    //============ View Functions ============//

    /**
     * @notice CDP risk indicator.
     */
    function isSafe(uint256 id_) public view virtual returns (bool) {
        return healthFactor(id_) < 1;
    }

    /**
     *@dev multiplied by _DENOMINATOR.
     */
    function currentLTV(uint256 id_) public view virtual returns (uint256 ltv) {
        CollateralizedDebtPosition memory _cdp = cdps[id_];
        ltv =
            (_cdp.debt * _DENOMINATOR * _DENOMINATOR) /
            (_cdp.collateral * _collateralPrice);
    }

    /**
     *@dev multiplied by _DENOMINATOR.
     */
    function healthFactor(uint256 id_)
        public
        view
        virtual
        returns (uint256 health)
    {
        CollateralizedDebtPosition memory _cdp = cdps[id_];
        health =
            (_cdp.debt * _DENOMINATOR * _DENOMINATOR * _DENOMINATOR) /
            (_cdp.collateral * _collateralPrice * maxLTV);
    }

    //============ CDP Operations ============//

    /**
     * @notice Opens a CDP position.
     */
    function open() external virtual whenNotPaused returns (uint256 id_) {
        id_ = _open(_msgSender());
        _update(id_);
    }

    /**
     * @notice Opens a CDP position
     * and deposits `amount_` into the created CDP.
     *
     * Requirements:
     *
     * - Do `approve` first.
     */
    function openAndDeposit(uint256 amount_)
        external
        virtual
        whenNotPaused
        returns (uint256 id_)
    {
        id_ = _open(_msgSender());
        _deposit(_msgSender(), id_, amount_);
        _update(id_);
    }

    // TODO: openAndDepositAndBorrow

    /**
     * @notice Closes the `id_` CDP position.
     */
    function close(uint256 id_) external virtual whenNotPaused {
        _update(id_);

        address msgSender = _msgSender();

        require(
            _isApprovedOrOwner(msgSender, id_),
            "CDP::_close: Not a valid caller."
        );

        _close(msgSender, id_);
    }

    /**
     * @dev Deposits collateral into CDP.
     *
     * Requirements:
     *
     * - Do `approve` first.
     */
    function deposit(uint256 id_, uint256 amount_)
        external
        virtual
        whenNotPaused
    {
        _deposit(_msgSender(), id_, amount_);
        _update(id_);
    }

    // TODO: depositAndBorrow

    /**
     * @notice Withdraws collateral from `this` to `_msgSender()`.
     */
    function withdraw(uint256 id_, uint256 amount_)
        external
        virtual
        whenNotPaused
    {
        _update(id_);

        address msgSender = _msgSender();

        require(
            _isApprovedOrOwner(msgSender, id_),
            "CDP::_withdraw: Not a valid caller."
        );

        _withdraw(msgSender, id_, amount_);
    }

    /**
     * @notice Borrows `amount_` debts.
     */
    function borrow(uint256 id_, uint256 amount_)
        external
        virtual
        whenNotPaused
    {
        _update(id_);

        address msgSender = _msgSender();

        require(
            _isApprovedOrOwner(msgSender, id_),
            "CDP::_borrow: Not a valid caller."
        );

        _borrow(msgSender, id_, amount_);
    }

    /**
     * @notice Repays `amount_` debts.
     */
    function repay(uint256 id_, uint256 amount_)
        external
        virtual
        whenNotPaused
    {
        _update(id_);
        _repay(_msgSender(), id_, amount_);
    }

    /**
     * @notice Update fee.
     */
    function updateFee(uint256 id_)
        external
        virtual
        returns (uint256 additionalFee)
    {
        return _update(id_);
    }

    // TODO: auction
    function liquidate(uint256 id_) external {
        _update(id_);

        require(!isSafe(id_), "CDP::liquidate: CDP must be unsafe.");

        _close(_msgSender(), id_);
    }

    // TODO
    function globalLiquidate() external onlyOwner whenPaused {}

    //============ Internal Functions ============//

    function _open(address account_) internal returns (uint256 id_) {
        id_ = id++;

        _safeMint(account_, id_); // mint NFT

        // cdps[id_].collateral = 0;
        // cdps[id_].debt = 0;

        emit Open(account_, id_);
    }

    function _close(address account_, uint256 id_) internal {
        CollateralizedDebtPosition storage _cdp = cdps[id_];

        if (_cdp.debt != 0) {
            _repay(account_, id_, _cdp.debt + _cdp.fee);
        }
        if (_cdp.collateral != 0) {
            _withdraw(account_, id_, _cdp.collateral);
        }

        _burn(id_);
        delete cdps[id_];

        emit Close(account_, id_);
    }

    function _deposit(
        address account_,
        uint256 id_,
        uint256 amount_
    ) internal {
        CollateralizedDebtPosition storage _cdp = cdps[id_];

        // require(_isApprovedOrOwner(_sender, id_)); // Anyone

        _cdp.collateral += amount_;
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
        CollateralizedDebtPosition storage _cdp = cdps[id_];

        _cdp.collateral -= amount_;
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
    ) internal virtual {
        CollateralizedDebtPosition storage _cdp = cdps[id_];

        _cdp.debt += amount_;
        ISIN(address(_debtToken)).mintTo(account_, amount_);

        require(isSafe(id_), "CDP::_borrow: CDP operation exceeds max LTV.");
        require(
            _debtToken.totalSupply() <= cap,
            "CDP::_borrow: Cannot borrow SIN anymore."
        );

        emit Borrow(account_, id_, amount_);
    }

    function _repay(
        address account_,
        uint256 id_,
        uint256 amount_
    ) internal virtual {
        CollateralizedDebtPosition storage _cdp = cdps[id_];

        address feeTo = _feeTo != address(0) ? _feeTo : account_;

        // repay fee first
        if (_cdp.fee >= amount_) {
            _cdp.fee -= amount_;
            _debtToken.safeTransferFrom(account_, feeTo, amount_);
        } else if (_cdp.fee != 0) {
            _debtToken.safeTransferFrom(account_, feeTo, _cdp.fee);
            _cdp.debt -= (amount_ - _cdp.fee);
            ISIN(address(_debtToken)).burnFrom(account_, amount_ - _cdp.fee);
            _cdp.fee = 0;
        }

        emit Repay(account_, id_, amount_);
    }

    /**
     * @dev Updates fee and timestamp.
     */
    function _update(uint256 id_) internal returns (uint256 additionalFee) {
        CollateralizedDebtPosition storage _cdp = cdps[id_];

        uint256 prevTimestamp = _cdp.latestUpdate;
        uint256 currTimestamp = block.timestamp;
        uint256 prevFee = _cdp.fee;
        uint256 currFee;

        additionalFee =
            (_cdp.debt * (currTimestamp - prevTimestamp) * _feeRatio) /
            (_DENOMINATOR * 365 * 24 * 60 * 60);
        _cdp.fee += additionalFee;

        _cdp.latestUpdate = currTimestamp;
        currFee = _cdp.fee;

        emit Update(id_, prevFee, currFee, prevTimestamp, currTimestamp);
    }
}
