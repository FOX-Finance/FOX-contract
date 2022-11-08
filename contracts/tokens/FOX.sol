// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../oracle/Oracle.sol";
import "../utils/Interval.sol";
import "../utils/Nonzero.sol";
import "../interfaces/IFOXS.sol";

import "../interfaces/IFOX.sol";

interface IFoxFarm {
    function maxLTV() external view returns (uint256);
}

/**
 * @title Fractional Over Collateralized Stablecoin (FOX)
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets SIN and FOXS, gives FOX as debt.
 */
contract FOX is IFOX, ERC20, Pausable, Ownable, Oracle, Interval, Nonzero {
    using SafeERC20 for IERC20;

    //============ Params ============//

    IERC20 private immutable _debtToken;
    IERC20 private immutable _shareToken;
    IFoxFarm private _foxFarm;

    uint256 private constant _TARGET_PRICE = 10000; // $1
    uint256 private _stablePrice = _TARGET_PRICE;
    uint256 private _sharePrice = 4000; // TODO: initial share price
    // treats SIN and Stablecoin are always $1.

    uint256 private constant _DENOMINATOR = 10000;
    uint256 private constant _BABY_STEP = 25; // 0.25%
    uint256 private constant _BIG_STEP = _BABY_STEP * 2; // 0.50%
    uint256 private constant _GIANT_STEP = _BABY_STEP * 3; // 0.75%
    uint256 private constant _ULTRA_STEP = _BABY_STEP * 4; // 1.00%
    uint256 public step;

    uint256 private constant _TIME_PERIOD = 1 hours;
    // uint256 public trustLevel = 200; // 0 ~ 10000 (0% ~ 100%) // TODO: initial trust level
    uint256 public trustLevel = 2000; // TODO: test purpose

    address private _feeTo;
    uint256 public mintFeeRatio; // (feeRatio / _DENOMINATOR)
    uint256 public burnFeeRatio; // (feeRatio / _DENOMINATOR)

    uint256 public bonusRatio; // recollateralization bonus

    //============ Initialize ============//

    constructor(
        address oracleFeeder_,
        address feeTo_,
        address debtToken_, // SIN
        address shareToken_, // FOXS
        uint256 mintFeeRatio_, // 20 as default
        uint256 burnFeeRatio_, // 45 as default
        uint256 bonusRatio_ // 75 as default
    )
        ERC20("Fractional Over Collateralized Stablecoin", "FOX")
        nonzeroAddress(oracleFeeder_)
        Oracle(oracleFeeder_)
        nonzeroAddress(debtToken_)
        nonzeroAddress(shareToken_)
    {
        _feeTo = feeTo_; // can be zero address
        _debtToken = IERC20(debtToken_);
        _shareToken = IERC20(shareToken_);

        step = _ULTRA_STEP; // TODO: automatically adjusting

        mintFeeRatio = mintFeeRatio_;
        burnFeeRatio = burnFeeRatio_;

        bonusRatio = bonusRatio_;
    }

    function initialize(address foxFarm_) external onlyOwner {
        _foxFarm = IFoxFarm(foxFarm_);

        emit Initialize(foxFarm_);
    }

    //============ Owner ============//

    function setFeeTo(address newFeeTo) external onlyOwner {
        address prevFeeTo = _feeTo;
        _feeTo = newFeeTo;
        emit SetFeeTo(prevFeeTo, _feeTo);
    }

    function setMintFeeRatio(uint256 newMintFeeRatio) external onlyOwner {
        uint256 prevMintFeeRatio = mintFeeRatio;
        mintFeeRatio = newMintFeeRatio;
        emit SetMintFeeRatio(prevMintFeeRatio, mintFeeRatio);
    }

    function setBurnFeeRatio(uint256 newBunrFeeRatio) external onlyOwner {
        uint256 prevBunrFeeRatio = burnFeeRatio;
        burnFeeRatio = newBunrFeeRatio;
        emit SetBurnFeeRatio(prevBunrFeeRatio, burnFeeRatio);
    }

    function setBonusRatio(uint256 newBonusRatio) external onlyOwner {
        uint256 prevBonusRatio = bonusRatio;
        bonusRatio = newBonusRatio;
        emit SetBonusRatio(prevBonusRatio, bonusRatio);
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

    function updateStablePrice(uint256 newStablePrice, uint256 confidence)
        external
        onlyOracleFeeder
    {
        // TODO: confidence interval, delta -> pause

        uint256 prevPrice = _stablePrice;
        _stablePrice = newStablePrice;
        emit UpdatePrice(address(this), prevPrice, _stablePrice);
    }

    function updateStablePriceWithTrustLevel(
        uint256 newStablePrice,
        uint256 confidence
    ) external onlyOracleFeeder {
        // TODO: confidence interval, delta -> pause

        uint256 prevPrice = _stablePrice;
        _stablePrice = newStablePrice;
        emit UpdatePrice(address(this), prevPrice, _stablePrice);

        _updateTrustLevel();
    }

    function updateSharePrice(uint256 newSharePrice, uint256 confidence)
        external
        onlyOracleFeeder
    {
        // TODO: confidence interval, delta -> pause

        uint256 prevPrice = _sharePrice;
        _sharePrice = newSharePrice;
        emit UpdatePrice(address(_shareToken), prevPrice, _stablePrice);
    }

    //============ Trust-related Functions ============//

    function updateTrustLevel() external onlyOwner {
        _updateTrustLevel();
    }

    function _updateTrustLevel() internal interval(_TIME_PERIOD) {
        if (deltaTrust() < 0) {
            trustLevel -= step;
        } else if (
            (address(_foxFarm) == address(0)) ||
            (_foxFarm.maxLTV() + trustLevel + step <= _DENOMINATOR)
        ) {
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

    //============ Trust-related View Functions ============//

    function stablePrice() public view returns (uint256) {
        return _stablePrice;
    }

    function sharePrice() public view returns (uint256) {
        return _sharePrice;
    }

    function currentTrustLevel() public view returns (uint256) {
        return
            ((totalSupply() - _debtToken.balanceOf(address(this))) *
                _DENOMINATOR) / totalSupply();
    }

    /**
     * @notice Returns error of stablecoin price.
     * @dev Over-trusted when `deltaTrust()` > 0.
     * Under-trusted when `deltaTrust()` < 0.
     * Neutal-trusted when `deltaTrust()` == 0.
     */
    function deltaTrust() public view returns (int256) {
        return int256(_stablePrice) - int256(_TARGET_PRICE);
    }

    function deltaTrustLevel() public view returns (int256) {
        return int256(currentTrustLevel()) - int256(trustLevel);
    }

    //============ View Functions ============//

    function requiredStableAmountFromDebt(uint256 debtAmount_)
        public
        view
        returns (uint256 stableAmount_)
    {
        stableAmount_ =
            (debtAmount_ * _DENOMINATOR) /
            (_DENOMINATOR - trustLevel);
    }

    /// @dev Uses to `repay()` in `close()`. Must consider burn fee.
    function requiredStableAmountFromDebtWithBurnFee(uint256 debtAmount_)
        public
        view
        returns (uint256 stableAmount_)
    {
        stableAmount_ =
            (debtAmount_ * _DENOMINATOR * _DENOMINATOR) /
            ((_DENOMINATOR - trustLevel) * (_DENOMINATOR - burnFeeRatio));
    }

    function requiredShareAmountFromDebt(uint256 debtAmount_)
        public
        view
        returns (uint256 shareAmount_)
    {
        shareAmount_ =
            (debtAmount_ * trustLevel * _DENOMINATOR) /
            ((_DENOMINATOR - trustLevel) * _sharePrice);
    }

    function requiredShareAmountFromStable(uint256 stableAmount_)
        public
        view
        returns (uint256 shareAmount_)
    {
        shareAmount_ = (stableAmount_ * trustLevel) / (_sharePrice);
    }

    /// @dev Uses to `borrow()`. Must consider mint fee.
    function requiredShareAmountFromStableWithMintFee(uint256 stableAmount_)
        public
        view
        returns (uint256 shareAmount_)
    {
        shareAmount_ =
            (stableAmount_ * _DENOMINATOR * trustLevel) /
            ((_DENOMINATOR - mintFeeRatio) * _sharePrice);
    }

    function requiredShareAmountFromStableWithBurnFee(uint256 stableAmount_)
        public
        view
        returns (uint256 shareAmount_)
    {
        uint256 burnFee_ = (stableAmount_ * burnFeeRatio) / _DENOMINATOR;
        shareAmount_ =
            ((stableAmount_ - burnFee_) * _DENOMINATOR * trustLevel) /
            (_DENOMINATOR * _sharePrice);
    }

    function requiredDebtAmountFromShare(uint256 shareAmount_)
        public
        view
        returns (uint256 debtAmount_)
    {
        debtAmount_ =
            ((_DENOMINATOR - trustLevel) * shareAmount_ * _sharePrice) /
            (trustLevel * _DENOMINATOR);
    }

    function requiredDebtAmountFromStable(uint256 stableAmount_)
        public
        view
        returns (uint256 debtAmount_)
    {
        debtAmount_ =
            (stableAmount_ * (_DENOMINATOR - trustLevel)) /
            (_DENOMINATOR);
    }

    /// @dev Uses to `borrow()`. Must consider mint fee.
    function requiredDebtAmountFromStableWithMintFee(uint256 stableAmount_)
        public
        view
        returns (uint256 debtAmount_)
    {
        debtAmount_ =
            (stableAmount_ * (_DENOMINATOR - trustLevel)) /
            (_DENOMINATOR - mintFeeRatio);
    }

    function requiredDebtAmountFromStableWithBurnFee(uint256 stableAmount_)
        public
        view
        returns (uint256 debtAmount_)
    {
        uint256 burnFee_ = (stableAmount_ * burnFeeRatio) / _DENOMINATOR;
        debtAmount_ =
            ((stableAmount_ - burnFee_) * (_DENOMINATOR - trustLevel)) /
            (_DENOMINATOR);
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
            // require(
            //     _requiredDebtAmount <= debtAmount_,
            //     "FOX::_mintInternal: Not enough debtTokens."
            // );
            _requiredShareAmount = shareAmount_;
        } else {
            _requiredDebtAmount = debtAmount_;
        }

        stableAmount_ =
            _requiredDebtAmount +
            (_requiredShareAmount * _sharePrice) /
            (_DENOMINATOR);
    }

    function expectedMintAmountWithMintFee(
        uint256 debtAmount_,
        uint256 shareAmount_
    ) public view returns (uint256 stableAmount_, uint256 mintFee_) {
        stableAmount_ = expectedMintAmount(debtAmount_, shareAmount_);
        mintFee_ = (stableAmount_ * mintFeeRatio) / _DENOMINATOR;
        stableAmount_ -= mintFee_;
    }

    function expectedRedeemAmount(uint256 stableAmount_)
        public
        view
        returns (uint256 debtAmount_, uint256 shareAmount_)
    {
        debtAmount_ = requiredDebtAmountFromStable(stableAmount_);
        shareAmount_ = requiredShareAmountFromStable(stableAmount_);
    }

    function expectedRedeemAmountWithBurnFee(uint256 stableAmount_)
        public
        view
        returns (
            uint256 debtAmount_,
            uint256 shareAmount_,
            uint256 burnFee_
        )
    {
        burnFee_ = (stableAmount_ * burnFeeRatio) / _DENOMINATOR;
        (debtAmount_, shareAmount_) = expectedRedeemAmount(
            stableAmount_ - burnFee_
        );
    }

    //////////////

    /// @notice Indicates allowable recoll amount
    function shortfallRecollateralizeAmount()
        public
        view
        returns (uint256 debtAmount_)
    {
        return
            (totalSupply() * (_DENOMINATOR - trustLevel)) /
            _DENOMINATOR -
            _debtToken.balanceOf(address(this));
    }

    /// @notice Indicates allowable buyback amount
    function surplusBuybackAmount() public view returns (uint256 debtAmount_) {
        return
            _debtToken.balanceOf(address(this)) -
            (totalSupply() * (_DENOMINATOR - trustLevel)) /
            _DENOMINATOR;
    }

    function exchangedShareAmountFromDebt(uint256 debtAmount_)
        public
        view
        returns (uint256 shareAmount_)
    {
        shareAmount_ = (debtAmount_ * _DENOMINATOR) / (_sharePrice);
    }

    function exchangedDebtAmountFromShare(uint256 shareAmount_)
        public
        view
        returns (uint256 debtAmount_)
    {
        debtAmount_ = (shareAmount_ * _sharePrice) / _DENOMINATOR;
    }

    //============ Mint & Redeem ============//

    function mint(
        address toAccount_,
        uint256 debtAmount_,
        uint256 shareAmount_
    ) external whenNotPaused returns (uint256 stableAmount_) {
        address _fromAccount = _msgSender();

        // send
        _debtToken.safeTransferFrom(_fromAccount, address(this), debtAmount_);
        _shareToken.safeTransferFrom(_fromAccount, address(this), shareAmount_);

        // fee
        if (_feeTo != address(0)) {
            uint256 _fee;
            (stableAmount_, _fee) = expectedMintAmountWithMintFee(
                debtAmount_,
                shareAmount_
            );
            _mint(_feeTo, _fee);
        } else {
            stableAmount_ = expectedMintAmount(debtAmount_, shareAmount_);
        }

        // calculate
        _mint(toAccount_, stableAmount_);
    }

    function redeem(address toAccount_, uint256 stableAmount_)
        external
        whenNotPaused
        returns (uint256 debtAmount_, uint256 shareAmount_)
    {
        // send
        _burn(_msgSender(), stableAmount_);

        // fee
        if (_feeTo != address(0)) {
            uint256 _fee;
            (debtAmount_, shareAmount_, _fee) = expectedRedeemAmountWithBurnFee(
                stableAmount_
            );
            _mint(_feeTo, _fee);
        } else {
            (debtAmount_, shareAmount_) = expectedRedeemAmount(stableAmount_);
        }

        // receive
        _debtToken.safeTransfer(toAccount_, debtAmount_);
        _shareToken.safeTransfer(toAccount_, shareAmount_);
    }

    //============ Recollateralize & Buyback ============//

    function recollateralize(address toAccount_, uint256 debtAmount_)
        external
        whenNotPaused
        returns (uint256 shareAmount_, uint256 bonusAmount_)
    {
        uint256 _shortfallAmount = shortfallRecollateralizeAmount(); // also checks recollateralizing condition
        _shortfallAmount = _shortfallAmount >= debtAmount_
            ? debtAmount_
            : _shortfallAmount;

        // send
        _debtToken.safeTransferFrom(
            _msgSender(),
            address(this),
            _shortfallAmount
        );

        // calculate
        shareAmount_ = exchangedShareAmountFromDebt(_shortfallAmount);
        bonusAmount_ = (shareAmount_ * bonusRatio) / _DENOMINATOR;

        // receive (mint)
        // _shareToken.safeTransfer(toAccount_, shareAmount_);
        IFOXS(address(_shareToken)).mintTo(
            toAccount_,
            shareAmount_ + bonusAmount_
        );
    }

    function buyback(address toAccount_, uint256 shareAmount_)
        external
        whenNotPaused
        returns (uint256 debtAmount_)
    {
        // also checks recollateralizing condition
        uint256 _exchangedSurplusShareAmount = exchangedShareAmountFromDebt(
            surplusBuybackAmount()
        );
        _exchangedSurplusShareAmount = _exchangedSurplusShareAmount >=
            shareAmount_
            ? shareAmount_
            : _exchangedSurplusShareAmount;

        // send (burn)
        // _shareToken.safeTransferFrom(
        //     _msgSender(),
        //     address(this),
        //     _exchangedSurplusShareAmount
        // );
        IFOXS(address(_shareToken)).burnFrom(
            _msgSender(),
            _exchangedSurplusShareAmount
        );

        // calculate
        debtAmount_ = exchangedDebtAmountFromShare(
            _exchangedSurplusShareAmount
        );

        // receive
        _debtToken.safeTransfer(toAccount_, debtAmount_);
    }

    // TODO: can get surplus FOXS
    function skim(address toAccount_)
        external
        whenNotPaused
        returns (uint256 shareAmount_)
    {}

    //============ ERC20-related Functions ============//

    function approveMax(address spender) public {
        _approve(_msgSender(), spender, type(uint256).max);
    }
}
