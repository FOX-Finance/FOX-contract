// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IFOX.sol";
import "../interfaces/IOracle.sol";

/**
 * @title Fractional Over Collateralized Stablecoin (FOX)
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets SIN and FOXS, gives FOX as debt.
 */
contract FOX is IFOX, ERC20, Pausable, Ownable {
    using SafeERC20 for IERC20;

    //============ Params ============//

    IOracle private _oracleFeeder;
    address private _feeTo;
    IERC20 private immutable _debtToken;
    IERC20 private immutable _shareToken;

    uint256 private constant _DENOMINATOR = 10000;
    uint256 private constant _BABY_STEP = 25; // 0.25%
    uint256 private constant _BIG_STEP = _BABY_STEP * 2; // 0.50%
    uint256 private constant _GIANT_STEP = _BABY_STEP * 3; // 0.75%
    uint256 private constant _ULTRA_STEP = _BABY_STEP * 4; // 1.00%
    uint256 public step;

    uint256 private constant _TARGET_PRICE = 1 ether;
    uint256 private _stablePrice = _TARGET_PRICE;
    uint256 private _sharePrice = _TARGET_PRICE; // TODO
    // treats SIN and Stablecoin are always $1.

    uint256 private constant _TIME_PERIOD = 1 hours;
    uint256 private _lastStepUpdateTime;
    uint256 public trustLevel = 0; // 0 ~ 10000 (0% ~ 100%)

    mapping(address => bool) private _allowlist;
    bool private _allowAll;

    uint256 private _mintFeeRatio; // (feeRatio / _DENOMINATOR)
    uint256 private _burnFeeRatio; // (feeRatio / _DENOMINATOR)

    //============ Events ============//

    event UpdateOracleFeeder(address prevOracleFeeder, address currOracle);
    event UpdateStablePrice(uint256 prevPrice, uint256 currPrice);
    event UpdateSharePrice(uint256 prevPrice, uint256 currPrice);

    event AddAllowlist(address newAddr);
    event RemoveAllowlist(address targetAddr);
    event AllowAll(bool prevAllowAll, bool currAllowAll);

    event SetMintFeeRatio(uint256 prevMintFeeRatio, uint256 currMintFeeRatio);
    event SetBurnFeeRatio(uint256 prevBurnFeeRatio, uint256 currBurnFeeRatio);

    //============ Modifiers ============//

    modifier nonzeroAddress(address account_) {
        require(
            account_ != address(0),
            "FOX::nonzeroAddress: Account must be nonzero."
        );
        _;
    }

    modifier onlyOracleFeeder() {
        require(
            _msgSender() == address(_oracleFeeder),
            "FOX::onlyOracleFeeder: Sender must be same as _oracleFeeder."
        );
        _;
    }

    modifier onlyAllowlist() {
        require(
            _allowAll || _allowlist[_msgSender()],
            "FOX:onlyAllowlist: Sender must be allowed."
        );
        _;
    }

    //============ Initialize ============//

    constructor(
        address oracleFeeder_,
        address feeTo_,
        address debtToken_,
        address shareToken_,
        uint256 mintFeeRatio_, // 20 as default
        uint256 burnFeeRatio_ // 45 as default
    )
        nonzeroAddress(oracleFeeder_)
        ERC20("Fractional Over Collateralized Stablecoin", "FOX")
    {
        _feeTo = feeTo_; // can be zero address
        _debtToken = IERC20(debtToken_);
        _shareToken = IERC20(shareToken_);

        _oracleFeeder = IOracle(oracleFeeder_);
        step = _ULTRA_STEP;
        _lastStepUpdateTime = block.timestamp;

        _mintFeeRatio = mintFeeRatio_;
        _burnFeeRatio = burnFeeRatio_;
    }

    //============ Owner ============//

    function setMintFeeRatio(uint256 newMintFeeRatio) external onlyOwner {
        uint256 prevMintFeeRatio = _mintFeeRatio;
        _mintFeeRatio = newMintFeeRatio;
        emit SetMintFeeRatio(prevMintFeeRatio, _mintFeeRatio);
    }

    function setBunrFeeRatio(uint256 newBunrFeeRatio) external onlyOwner {
        uint256 prevBunrFeeRatio = _burnFeeRatio;
        _burnFeeRatio = newBunrFeeRatio;
        emit SetBurnFeeRatio(prevBunrFeeRatio, _burnFeeRatio);
    }

    function addAllowlist(address newAddr) external onlyOwner {
        if (!_allowlist[newAddr]) {
            _allowlist[newAddr] = true;
        }
        emit AddAllowlist(newAddr);
    }

    function removeAllowlist(address targetAddr) external onlyOwner {
        if (_allowlist[targetAddr]) {
            _allowlist[targetAddr] = false;
        }
        emit RemoveAllowlist(targetAddr);
    }

    function setAllowAll(bool newAllowAll) external onlyOwner {
        bool prevAllowAll = _allowAll;
        _allowAll = newAllowAll;
        emit AllowAll(prevAllowAll, _allowAll);
    }

    //============ Oracle Functions ============//

    function updateOracleFeeder(address newOracleFeeder) external onlyOwner {
        address prevOracleFeeder = address(_oracleFeeder);
        _oracleFeeder = IOracle(newOracleFeeder);
        emit UpdateOracleFeeder(prevOracleFeeder, address(_oracleFeeder));
    }

    function updateStablePrice(uint256 newStablePrice, uint256 confidence)
        external
        onlyOracleFeeder
    {
        // TODO: confidence interval, delta -> pause

        uint256 prevPrice = _stablePrice;
        _stablePrice = newStablePrice;
        emit UpdateStablePrice(prevPrice, _stablePrice);
    }

    function updateStablePriceWithTrustLevel(
        uint256 newStablePrice,
        uint256 confidence
    ) external onlyOracleFeeder {
        // TODO: confidence interval, delta -> pause

        uint256 prevPrice = _stablePrice;
        _stablePrice = newStablePrice;
        emit UpdateStablePrice(prevPrice, _stablePrice);

        _updateTrustLevel();
    }

    function updateSharePrice(uint256 newSharePrice, uint256 confidence)
        external
        onlyOracleFeeder
    {
        // TODO: confidence interval, delta -> pause

        uint256 prevPrice = _sharePrice;
        _sharePrice = newSharePrice;
        emit UpdateSharePrice(prevPrice, _sharePrice);
    }

    //============ Trust-related Functions ============//

    function updateTrustLevel() external onlyOwner {
        _updateTrustLevel();
    }

    function _updateTrustLevel() internal {
        require(
            _TIME_PERIOD < block.timestamp - _lastStepUpdateTime,
            "FOX::_updateTrustLevel: Not yet."
        );
        if (trust() < 0) {
            trustLevel -= step;
        } else {
            trustLevel += step;
        }
    }

    function updateStep(Step step_) external onlyOwner {
        if (step_ == Step.baby) {
            step = _BABY_STEP;
        } else if (step_ == Step.big) {
            step = _BIG_STEP;
        } else if (step_ == Step.giant) {
            step = _GIANT_STEP;
        } else if (step_ == Step.ultra) {
            step = _ULTRA_STEP;
        } else {
            revert("FOX::updateStep: Not a valid step.");
        }
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

    function getStablePrice() external view onlyAllowlist returns (uint256) {
        return _stablePrice;
    }

    function getSharePrice() external view onlyAllowlist returns (uint256) {
        return _sharePrice;
    }

    /**
     * @notice Returns error of stablecoin price.
     * @dev Over-trusted when `trust()` > 0.
     * Under-trusted when `trust()` < 0.
     * Neutal-trusted when `trust()` == 0.
     */
    function trust() public view returns (int256) {
        return int256(_stablePrice - _TARGET_PRICE);
    }

    function requiredShareAmountFromDebt(uint256 debtAmount_)
        public
        view
        returns (uint256)
    {
        return
            (debtAmount_ * trustLevel) /
            ((_DENOMINATOR - trustLevel) * _sharePrice);
    }

    function requiredShareAmountFromStable(uint256 stableAmount_)
        public
        view
        returns (uint256)
    {
        return (stableAmount_ * trustLevel) / (_DENOMINATOR * _sharePrice);
    }

    function requiredDebtAmountFromShare(uint256 shareAmount_)
        public
        view
        returns (uint256)
    {
        return (shareAmount_ * _sharePrice * _DENOMINATOR) / trustLevel;
    }

    function requiredDebtAmountFromStable(uint256 stableAmount_)
        public
        view
        returns (uint256)
    {
        return (stableAmount_ * (_DENOMINATOR - trustLevel)) / (_DENOMINATOR);
    }

    function expectedMintAmount(uint256 debtAmount_, uint256 shareAmount_)
        public
        view
        returns (uint256 stableAmount_)
    {
        // calculate min amount to mint
        uint256 _requiredDebtAmount;
        uint256 _requiredShareAmount = requiredShareAmountFromDebt(debtAmount_);
        if (_requiredShareAmount > shareAmount_) {
            _requiredDebtAmount = requiredDebtAmountFromShare(shareAmount_);
            require(
                _requiredDebtAmount <= debtAmount_,
                "FOX::_mintInternal: Not enough debtTokens."
            );
            _requiredShareAmount = shareAmount_;
        } else {
            _requiredDebtAmount = debtAmount_;
        }

        stableAmount_ =
            _requiredDebtAmount +
            _requiredShareAmount *
            _sharePrice;
    }

    function expectedRedeemAmount(uint256 stableAmount_)
        public
        view
        returns (uint256 debtAmount_, uint256 shareAmount_)
    {
        debtAmount_ = requiredDebtAmountFromStable(stableAmount_);
        shareAmount_ = requiredShareAmountFromStable(stableAmount_);
    }

    //============ Mint & Redeem ============//

    function mint(
        address toAccount_,
        uint256 debtAmount_,
        uint256 shareAmount_
    ) external whenNotPaused returns (uint256 stableAmount_) {
        address fromAccount_ = _msgSender();

        // send
        IERC20(_debtToken).safeTransferFrom(
            fromAccount_,
            address(this),
            debtAmount_
        );
        IERC20(_shareToken).safeTransferFrom(
            fromAccount_,
            address(this),
            shareAmount_
        );

        // calculate
        stableAmount_ = expectedMintAmount(debtAmount_, shareAmount_);

        // receive
        uint256 _fee = (stableAmount_ * _mintFeeRatio) / _DENOMINATOR;
        _mint(_feeTo, _fee);
        _mint(toAccount_, stableAmount_ - _fee);
    }

    function redeem(address toAccount_, uint256 stableAmount_)
        external
        whenNotPaused
        returns (uint256 debtAmount_, uint256 shareAmount_)
    {
        address fromAccount_ = _msgSender();

        // send
        _burn(fromAccount_, stableAmount_);

        // calculate
        (debtAmount_, shareAmount_) = expectedRedeemAmount(stableAmount_);

        // receive
        uint256 _debtFee = (debtAmount_ * _burnFeeRatio) / _DENOMINATOR;
        IERC20(_debtToken).safeTransferFrom(
            address(this),
            toAccount_,
            debtAmount_ - _debtFee
        );
        uint256 _shareFee = (shareAmount_ * _burnFeeRatio) / _DENOMINATOR;
        IERC20(_shareToken).safeTransferFrom(
            address(this),
            toAccount_,
            shareAmount_ - _shareFee
        );
    }

    //============ Recallateralize ============//

    function recollateralizeBorrowDebt() external whenNotPaused {}

    function recollateralizeDepositCollateral() external whenNotPaused {}

    //============ Buyback ============//

    function buybackRepayDebt() external whenNotPaused {}

    function buybackWithdrawCollateral() external whenNotPaused {}

    function buybackCoupon() external whenNotPaused {}

    //============ ERC20-related Functions ============//

    function approveMax(address spender) public {
        _approve(_msgSender(), spender, type(uint256).max);
    }
}
