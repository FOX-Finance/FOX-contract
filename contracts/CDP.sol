// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/ISIN.sol";

// import "./interfaces/IWETH.sol";

/**
 * @title Collateralized Debt Position in FOX Finance.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets WETH as collateral, gives SIN as debt.
 * Also it is treasury of collaterals and SINs.
 * @dev Abstract contract.
 */
abstract contract FoxCDP is
    ERC721("Fox Collateralized Debt Position", "FoxCDP"),
    Pausable
{
    using SafeERC20 for IERC20;

    //============ Params ============//

    address public immutable factory;
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
        uint256 fee;
        uint256 latestUpdate;
    }
    mapping(uint256 => CDP) public cdps;
    uint256 public id;

    //============ Events ============//

    event Initialize(
        address factory,
        address feeTo,
        address indexed collateralToken,
        address indexed debtToken,
        uint256 maxLTV,
        uint256 feeRatio,
        uint256 cap
    );

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

    //============ Modifiers ============//

    modifier onlyFactory() {
        require(
            msg.sender == factory,
            "FoxCDP::onlyFactory: Sender must be factory."
        );
        _;
    }

    modifier nonzeroAddress(address account_) {
        require(
            account_ != address(0),
            "FoxCDP::nonzeroAddress: Account must be nonzero."
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
        factory = msg.sender;
        feeTo = feeTo_; // can be zero address
        collateralToken = IERC20(collateralToken_);
        debtToken = IERC20(debtToken_);

        maxLTV = maxLTV_;
        feeRatio = feeRatio_;
        cap = cap_;

        emit Initialize(
            msg.sender,
            feeTo_,
            collateralToken_,
            debtToken_,
            maxLTV_,
            feeRatio,
            cap_
        );
    }

    //============ Pausable ============//

    /**
     * @notice Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyFactory {
        _pause();
    }

    /**
     * @notice Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyFactory {
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
    function open() external whenNotPaused returns (uint256 id_) {
        id_ = _open(msg.sender);
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
        whenNotPaused
        returns (uint256 id_)
    {
        id_ = _open(msg.sender);
        _deposit(msg.sender, id_, amount_);
        _update(id_);
    }

    /**
     * @notice Closes the `id_` CDP position.
     */
    function close(uint256 id_) external whenNotPaused {
        _update(id_);
        _close(msg.sender, id_);
    }

    /**
     * @dev Deposits collateral into CDP.
     *
     * Requirements:
     *
     * - Do `approve` first.
     */
    function deposit(uint256 id_, uint256 amount_) external whenNotPaused {
        _deposit(msg.sender, id_, amount_);
        _update(id_);
    }

    /**
     * @notice Withdraws collateral from `this` to `msg.sender`.
     */
    function withdraw(uint256 id_, uint256 amount_) external whenNotPaused {
        _update(id_);
        _withdraw(msg.sender, id_, amount_);
    }

    /**
     * @notice Borrows `amount_` debts.
     */
    function borrow(uint256 id_, uint256 amount_) external whenNotPaused {
        _update(id_);
        _borrow(msg.sender, id_, amount_);
    }

    /**
     * @notice Repays `amount_` debts.
     */
    function repay(uint256 id_, uint256 amount_) external whenNotPaused {
        _update(id_);
        _repay(msg.sender, id_, amount_);
    }

    /**
     * @notice Update fee.
     */
    function updateFee(uint256 id_) external returns (uint256 additionalFee) {
        return _update(id_);
    }

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
            "FoxCDP::_close: Not a valid caller."
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
            "FoxCDP::_deposit: Not enough collateral."
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
            "FoxCDP::_withdraw: Not a valid caller."
        );

        _cdp.collateral -= amount_;
        collateralToken.safeTransfer(account_, amount_);

        require(
            isSafe(id_),
            "FoxCDP::_withdraw: CDP operation exceeds max LTV."
        );
        require(
            _cdp.collateral == 0 || _cdp.collateral >= minimumCollateral,
            "FoxCDP::_withdraw: Not enough collateral."
        );

        emit Withdraw(account_, id_, amount_);
    }

    function _borrow(
        address account_,
        uint256 id_,
        uint256 amount_
    ) internal {
        CDP storage _cdp = cdps[id_];

        require(
            _isApprovedOrOwner(account_, id_),
            "FoxCDP::_borrow: Not a valid caller."
        );

        _cdp.debt += amount_;
        ISIN(address(debtToken)).mintTo(account_, amount_);

        require(isSafe(id_), "FoxCDP::_borrow: CDP operation exceeds max LTV.");
        require(
            debtToken.totalSupply() <= cap,
            "FoxCDP::_borrow: Cannot borrow SIN anymore."
        );

        emit Borrow(account_, id_, amount_);
    }

    function _repay(
        address account_,
        uint256 id_,
        uint256 amount_
    ) internal {
        CDP storage _cdp = cdps[id_];

        if (_cdp.fee >= amount_) {
            // repay fee first
            _cdp.fee -= amount_;
            debtToken.safeTransferFrom(account_, feeTo, amount_);
        } else if (_cdp.fee != 0) {
            debtToken.safeTransferFrom(account_, feeTo, _cdp.fee);
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
