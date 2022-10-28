// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ISIN.sol";

// import "./interfaces/IWETH.sol";

/**
 * @title Collateralized Debt Position.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets WETH as collateral, gives SIN as debt.
 * @dev Abstract contract.
 */
abstract contract CDPNFT is
    ERC721("Collateralized Debt Position", "CDPNFT"),
    Pausable,
    Ownable
{
    using SafeERC20 for IERC20;

    //============ Params ============//

    address public immutable feeTo;
    IERC20 public immutable collateralToken;
    IERC20 public immutable debtToken;

    uint256 public constant DENOMINATOR = 1000;
    uint256 public constant minimumCollateral = 0.005 ether;
    uint256 public maxLTV; // (maxLTV / DENOMINATOR)
    uint256 public feeRatio; // (feeRatio / DENOMINATOR)
    uint256 public cap; // total debt cap

    //============ CDP ============//

    struct CDP {
        uint256 collateral;
        uint256 debt;
        uint256 fee; // as SIN
        uint256 latestUpdate;
    }
    mapping(uint256 => CDP) public cdps;
    uint256 public id;

    //============ Events ============//

    event Open(address indexed account_, uint256 indexed id_);
    event Close(address indexed account_, uint256 indexed id_);
    event Deposit(
        address indexed account_,
        uint256 indexed id_,
        uint256 amount
    );
    event Withdraw(
        address indexed account_,
        uint256 indexed id_,
        uint256 amount
    );
    event Borrow(address indexed account_, uint256 indexed id_, uint256 amount);
    event Repay(address indexed account_, uint256 indexed id_, uint256 amount);

    event Update(
        uint256 indexed id_,
        uint256 prevFee,
        uint256 currFee,
        uint256 prevTimestamp,
        uint256 currTimestamp
    );

    event SetMaxLTV(uint256 prevMaxLTV, uint256 currMaxLTV);
    event SetFeeRatio(uint256 prevFeeRatio, uint256 currFeeRatio);
    event SetCap(uint256 prevCap, uint256 currCap);

    //============ Modifiers ============//

    modifier nonzeroAddress(address account_) {
        require(
            account_ != address(0),
            "CDPNFT::nonzeroAddress: Account must be nonzero."
        );
        _;
    }

    //============ Initialize ============//

    constructor(
        address feeTo_,
        address collateralToken_,
        address debtToken_,
        uint256 maxLTV_,
        uint256 feeRatio_,
        uint256 cap_
    )
        nonzeroAddress(feeTo_)
        nonzeroAddress(collateralToken_)
        nonzeroAddress(debtToken_)
    {
        feeTo = feeTo_; // can be zero address
        collateralToken = IERC20(collateralToken_);
        debtToken = IERC20(debtToken_);

        maxLTV = maxLTV_;
        feeRatio = feeRatio_;
        cap = cap_;
    }

    //============ Owner ============//

    function setMaxLTV(uint256 newMaxLTV) external onlyOwner {
        uint256 prevMaxLTV = maxLTV;
        maxLTV = newMaxLTV;
        emit SetMaxLTV(prevMaxLTV, maxLTV);
    }

    function setFeeRatio(uint256 newFeeRatio) external onlyOwner {
        uint256 prevFeeRatio = feeRatio;
        feeRatio = newFeeRatio;
        emit SetFeeRatio(prevFeeRatio, feeRatio);
    }

    function setCap(uint256 newCap) external onlyOwner {
        uint256 prevCap = cap;
        cap = newCap;
        emit SetCap(prevCap, cap);
    }

    //============ Pausable ============//

    /**
     * @notice Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    //============ View Functions ============//

    /**
     * @notice CDP risk indicator.
     */
    function isSafe(uint256 id_) public view returns (bool) {
        return healthFactor(id_) < 1;
    }

    function currentLTV(uint256 id_) public view returns (uint256 ltv) {
        CDP memory _cdp = cdps[id_];
        ltv = (_cdp.debt * DENOMINATOR) / _cdp.collateral;
    }

    function healthFactor(uint256 id_) public view returns (uint256 health) {
        CDP memory _cdp = cdps[id_];
        health =
            (_cdp.debt * DENOMINATOR * DENOMINATOR) /
            (_cdp.collateral * maxLTV);
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
        _close(_msgSender(), id_);
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
        _withdraw(_msgSender(), id_, amount_);
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
        _borrow(_msgSender(), id_, amount_);
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

    // TODO: liquidation (based on `isSafe()`)

    // TODO: global liquidation (onlyOwner)

    //============ Internal Functions ============//

    function _open(address account_) internal returns (uint256 id_) {
        id_ = id++;

        _safeMint(account_, id_); // mint NFT

        // cdps[id_].collateral = 0;
        // cdps[id_].debt = 0;

        emit Open(account_, id_);
    }

    function _close(address account_, uint256 id_) internal {
        CDP storage _cdp = cdps[id_];

        require(
            _isApprovedOrOwner(account_, id_),
            "CDPNFT::_close: Not a valid caller."
        );

        if (_cdp.debt != 0) {
            _repay(account_, id_, _cdp.debt + _cdp.fee);
        }
        if (_cdp.collateral != 0) {
            _withdraw(account_, id_, _cdp.collateral);
        }

        delete cdps[id_];

        emit Close(account_, id_);
    }

    function _deposit(
        address account_,
        uint256 id_,
        uint256 amount_
    ) internal {
        CDP storage _cdp = cdps[id_];

        // require(_isApprovedOrOwner(_sender, id_)); // Anyone

        _cdp.collateral += amount_;
        collateralToken.safeTransferFrom(account_, address(this), amount_);

        require(
            _cdp.collateral >= minimumCollateral,
            "CDPNFT::_deposit: Not enough collateral."
        );

        emit Deposit(account_, id_, amount_);
    }

    function _withdraw(
        address account_,
        uint256 id_,
        uint256 amount_
    ) internal {
        CDP storage _cdp = cdps[id_];

        require(
            _isApprovedOrOwner(account_, id_),
            "CDPNFT::_withdraw: Not a valid caller."
        );

        _cdp.collateral -= amount_;
        collateralToken.safeTransfer(account_, amount_);

        require(
            isSafe(id_),
            "CDPNFT::_withdraw: CDP operation exceeds max LTV."
        );
        require(
            _cdp.collateral == 0 || _cdp.collateral >= minimumCollateral,
            "CDPNFT::_withdraw: Not enough collateral."
        );

        emit Withdraw(account_, id_, amount_);
    }

    function _borrow(
        address account_,
        uint256 id_,
        uint256 amount_
    ) internal virtual {
        CDP storage _cdp = cdps[id_];

        require(
            _isApprovedOrOwner(account_, id_),
            "CDPNFT::_borrow: Not a valid caller."
        );

        _cdp.debt += amount_;
        ISIN(address(debtToken)).mintTo(account_, amount_);

        require(isSafe(id_), "CDPNFT::_borrow: CDP operation exceeds max LTV.");
        require(
            debtToken.totalSupply() <= cap,
            "CDPNFT::_borrow: Cannot borrow SIN anymore."
        );

        emit Borrow(account_, id_, amount_);
    }

    function _repay(
        address account_,
        uint256 id_,
        uint256 amount_
    ) internal virtual {
        CDP storage _cdp = cdps[id_];

        address _feeTo = feeTo != address(0) ? feeTo : account_;

        // repay fee first
        if (_cdp.fee >= amount_) {
            _cdp.fee -= amount_;
            debtToken.safeTransferFrom(account_, _feeTo, amount_);
        } else if (_cdp.fee != 0) {
            debtToken.safeTransferFrom(account_, _feeTo, _cdp.fee);
            _cdp.debt -= (amount_ - _cdp.fee);
            ISIN(address(debtToken)).burnFrom(account_, amount_ - _cdp.fee);
            _cdp.fee = 0;
        }

        emit Repay(account_, id_, amount_);
    }

    /**
     * @dev Updates fee and timestamp.
     */
    function _update(uint256 id_) internal returns (uint256 additionalFee) {
        CDP storage _cdp = cdps[id_];

        uint256 prevTimestamp = _cdp.latestUpdate;
        uint256 currTimestamp = block.timestamp;
        uint256 prevFee = _cdp.fee;
        uint256 currFee;

        additionalFee =
            (_cdp.debt * (currTimestamp - prevTimestamp) * feeRatio) /
            (DENOMINATOR * 365 * 24 * 60 * 60);
        _cdp.fee += additionalFee;

        _cdp.latestUpdate = currTimestamp;
        currFee = _cdp.fee;

        emit Update(id_, prevFee, currFee, prevTimestamp, currTimestamp);
    }
}
