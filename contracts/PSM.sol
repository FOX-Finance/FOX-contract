// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ISIN.sol";

import "./interfaces/IPSM.sol";

/**
 * @title Peg Stablization Module.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets USDC, gives SIN.
 */
contract PSM is IPSM, Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    //============ Params ============//

    IERC20 internal immutable _collateralToken; // USDC
    ISIN internal immutable _debtToken; // SIN

    uint256 internal constant _DENOMINATOR = 10000;

    address internal _feeTo;
    uint256 internal _exchangeRatio; // (_exchangeRatio / _DENOMINATOR) // PSM fee // TODO: default value
    uint256 internal _refundRatio; // (_refundRatio / _DENOMINATOR) // PSM fee // TODO: default value

    //============ Initialize ============//

    constructor(
        address collateralToken_,
        address debtToken_,
        address feeTo_,
        uint256 exchangeRatio_,
        uint256 refundRatio_
    ) {
        _collateralToken = IERC20(collateralToken_);
        _debtToken = ISIN(debtToken_);

        _feeTo = feeTo_; // can be zero address
        _exchangeRatio = exchangeRatio_;
        _refundRatio = refundRatio_;

        _pause(); // lock `refund()`
    }

    //============ Owner ============//

    function setFeeTo(address newFeeTo) external virtual onlyOwner {
        address prevFeeTo = _feeTo;
        _feeTo = newFeeTo;
        emit SetFeeTo(prevFeeTo, _feeTo);
    }

    function setExchangeRatio(
        uint256 newExchangeRatio
    ) external virtual onlyOwner {
        uint256 prevExchangeRatio = _exchangeRatio;
        _exchangeRatio = newExchangeRatio;
        emit SetExchangeRatio(prevExchangeRatio, _exchangeRatio);
    }

    function setRefundRatio(uint256 newRefundRatio) external virtual onlyOwner {
        uint256 prevRefundRatio = _refundRatio;
        _refundRatio = newRefundRatio;
        emit SetExchangeRatio(prevRefundRatio, _refundRatio);
    }

    //============ Pausable ============//

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //============ Functions ============//

    function exchange(address account, uint256 amount) external nonReentrant {
        _collateralToken.safeTransferFrom(account, address(this), amount);

        if (_feeTo != address(0)) {
            address feeTo = _feeTo;
            uint256 feeAmount = (amount * _exchangeRatio) / _DENOMINATOR;
            _debtToken.mintTo(feeTo, feeAmount);
            _debtToken.mintTo(account, amount - feeAmount);
        } else {
            _debtToken.mintTo(account, amount);
        }
    }

    function refund(
        address account,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        _debtToken.burnFrom(account, amount);

        if (_feeTo != address(0)) {
            address feeTo = _feeTo;
            uint256 feeAmount = (amount * _refundRatio) / _DENOMINATOR;
            _collateralToken.safeTransfer(feeTo, feeAmount);
            _collateralToken.safeTransfer(account, amount - feeAmount);
        } else {
            _collateralToken.safeTransfer(account, amount);
        }
    }
}
