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

    IOracle public immutable oracleFeeder;
    address public immutable feeTo;
    IERC20 public immutable debtToken;
    IERC20 public immutable shareToken;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public constant BABY_STEP = 25; // 0.25%
    uint256 public constant BIG_STEP = BABY_STEP * 2; // 0.50%
    uint256 public constant GIANT_STEP = BABY_STEP * 3; // 0.75%
    uint256 public constant ULTRA_STEP = BABY_STEP * 4; // 1.00%
    uint256 public step;

    uint256 public constant TARGET_PRICE = 1 * (10**decimals());
    uint256 private _stablePrice = TARGET_PRICE;
    uint256 public constant TIME_PERIOD = 1 hours;
    uint256 public lastStepUpdateTime;
    uint256 public trustLevel = 0; // 0 ~ 10000 (0% ~ 100%)

    mapping(address => bool) public allowlist;

    uint256 public mintFeeRatio; // (feeRatio / DENOMINATOR)
    uint256 public burnFeeRatio; // (feeRatio / DENOMINATOR)

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
            _msgSender() == oracleFeeder,
            "FOX::onlyOracleFeeder: Sender must be same as oracleFeeder."
        );
        _;
    }

    modifier onlyAllowlist() {
        require(
            allowlist[_msgSender()],
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
        feeTo = feeTo_; // can be zero address
        debtToken = IERC20(debtToken_);
        shareToken = IERC20(shareToken_);

        oracleFeeder = IOracle(oracleFeeder_);
        step = ULTRA_STEP;
        lastStepUpdateTime = block.timestamp;

        mintFeeRatio = mintFeeRatio;
        burnFeeRatio = burnFeeRatio;
    }

    //============ Events ============//

    event UpdatePrice(uint256 prevPrice, uint256 currPrice);
    event UpdateOracleFeeder(address prevOracleFeeder, address currOracle);

    event AddAllowlist(address newAddr);
    event RemoveAllowlist(address targetAddr);

    event SetMintFeeRatio(uint256 prevMintFeeRatio, uint256 currMintFeeRatio);
    event SetBurnFeeRatio(uint256 prevBurnFeeRatio, uint256 currBurnFeeRatio);

    //============ Owner ============//

    function setMintFeeRatio(uint256 newMintFeeRatio) external onlyOwner {
        uint256 prevMintFeeRatio = mintFeeRatio;
        mintFeeRatio = newMintFeeRatio;
        emit SetMintFeeRatio(prevMintFeeRatio, mintFeeRatio);
    }

    function setBunrFeeRatio(uint256 newBunrFeeRatio) external onlyOwner {
        uint256 prevBunrFeeRatio = burnFeeRatio;
        burnFeeRatio = newBunrFeeRatio;
        emit SetBurnFeeRatio(prevBunrFeeRatio, burnFeeRatio);
    }

    //============ Trust-related Functions ============//

    function updateOracleFeeder(address newOracleFeeder) external onlyOwner {
        address prevOracleFeeder = oracleFeeder;
        oracleFeeder = newOracleFeeder;
        emit UpdateOracleFeeder(prevOracleFeeder, oracleFeeder);
    }

    function updatePrice(
        uint256 newStablePrice,
        uint256 confidence,
        bool trustLevelUpdate
    ) external onlyOracleFeeder {
        // TODO: confidence interval, delta -> pause

        uint256 prevPrice = _stablePrice;
        _stablePrice = newStablePrice;
        emit UpdatePrice(prevPrice, _stablePrice);

        if (trustLevelUpdate) {
            _updateTrustLevel();
        }
    }

    function updateTrustLevel() external onlyOwner {
        _updateTrustLevel();
    }

    function _updateTrustLevel() internal {
        require(
            TIME_PERIOD < block.timestamp - lastStepUpdateTime,
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
            step = BABY_STEP;
        } else if (step_ == Step.big) {
            step = BIG_STEP;
        } else if (step_ == Step.giant) {
            step = GIANT_STEP;
        } else if (step_ == Step.ultra) {
            step = ULTRA_STEP;
        } else {
            revert("FOX::updateStep: Not a valid step.");
        }
    }

    function addAllowlist(address newAddr) external onlyOwner {
        !allowlist[newAddr] ? allowlist[newAddr] = true : ();
        emit AddAllowlist(newAddr);
    }

    function removeAllowlist(address targetAddr) external onlyOwner {
        allowlist[targetAddr] ? allowlist[targetAddr] = false : ();
        emit RemoveAllowlist(targetAddr);
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

    function getPrice() external view onlyAllowlist returns (uint256) {
        return _stablePrice;
    }

    /**
     * @notice Returns error of stablecoin price.
     * @dev Over-trusted when `trust()` > 0.
     * Under-trusted when `trust()` < 0.
     * Neutal-trusted when `trust()` == 0.
     */
    function trust() public view returns (int256) {
        return _stablePrice - TARGET_PRICE;
    }

    function requiredFoxsAmount(uint256 debtAmount_)
        public
        view
        returns (uint256)
    {
        return (debtAmount_ * trustLevel) / DENOMINATOR;
    }

    function requiredSinAmount(uint256 shareAmount_)
        public
        view
        returns (uint256)
    {
        return (shareAmount_ * DENOMINATOR) / trustLevel;
    }

    function expectedMintAmount() public view returns (uint256) {}

    function expectedRedeemAmount() public view returns (uint256) {}

    //============ Mint & Redeem ============//

    function mint(
        address toAccount_,
        uint256 debtAmount_,
        uint256 shareAmount_
    ) external whenNotPaused returns (uint256 stableAmount_) {
        _mintInternal(_msgSender(), toAccount_, debtAmount_, shareAmount_);
    }

    function _mintInternal(
        address fromAccount_,
        address toAccount_,
        uint256 debtAmount_,
        uint256 shareAmount_
    ) internal whenNotPaused returns (uint256 stableAmount_) {
        // transfer
        IERC20(debtToken).safeTransferFrom(
            fromAccount_,
            address(this),
            debtAmount_
        );
        IERC20(shareToken).safeTransferFrom(
            fromAccount_,
            address(this),
            shareAmount_
        );

        // calculate min amount to mint
        uint256 _requiredSinAmount;
        uint256 _requiredFoxsAmount = requiredFoxsAmount(debtAmount_);
        if (_requiredFoxsAmount > shareAmount_) {
            _requiredSinAmount = requiredSinAmount(shareAmount_);
            require(
                _requiredSinAmount <= debtAmount_,
                "FOX::_mintInternal: Not enough debtTokens."
            );
            _requiredFoxsAmount = shareAmount_;
        } else {
            _requiredSinAmount = debtAmount_;
        }

        // mint
        stableAmount_ = _requiredSinAmount + _requiredFoxsAmount;
        uint256 _fee = (stableAmount_ * mintFeeRatio) / DENOMINATOR;
        _mint(feeTo, _fee);
        _mint(toAccount_, stableAmount_ - _fee);
    }

    function redeem(address toAccount_, uint256 stableAmount_)
        external
        whenNotPaused
    {
        _redeem(_msgSender(), amount);
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
