// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ISIN.sol";
import "../utils/Nonzero.sol";

import "../interfaces/ICoupon.sol";

// import "./interfaces/IWETH.sol";

/**
 * @title Coupon. Position Discount Coupon.
 * @dev Similar with FoxFarm, but no collaterals, only shares and grants.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets FOXS as share, mints NIS as grant.
 */
contract Coupon is
    ICoupon,
    ERC721("FoxFarm PDC", "PDC"),
    Pausable,
    Ownable,
    Nonzero
{
    using SafeERC20 for IERC20;

    //============ Params ============//

    IERC20 internal immutable _grantToken; // NIS

    uint256 private constant _DENOMINATOR = 10000;

    // fee
    address internal _feeTo;
    uint256 internal _feeRatio; // (_feeRatio / _DENOMINATOR) // stability fee

    // CDP
    mapping(uint256 => PositionDiscountCoupon) internal _pdcs;
    uint256 public id;
    uint256 public totalShare;
    uint256 public totalGrant;
    uint256 public totalFee;

    //============ Modifiers ============//

    modifier onlyPdcApprovedOrOwner(address msgSender, uint256 id_) {
        require(
            _isApprovedOrOwner(msgSender, id_),
            "Coupon::onlyPdcApprovedOrOwner: Not a valid caller."
        );
        _;
    }

    //============ Initialize ============//

    constructor(
        address feeTo_,
        address grantToken_, // NIS
        uint256 feeRatio_
    ) nonzeroAddress(grantToken_) {
        _feeTo = feeTo_; // can be zero address
        _grantToken = IERC20(grantToken_);
        _feeRatio = feeRatio_;
    }

    //============ Owner ============//

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

    //============ View Functions ============//

    function pdc(
        uint256 id_
    ) public view returns (PositionDiscountCoupon memory) {
        PositionDiscountCoupon memory _pdc = _pdcs[id_];
        _pdc.fee =
            (_pdc.grant * (block.timestamp - _pdc.latestUpdate) * _feeRatio) /
            (_DENOMINATOR * 365 * 24 * 60 * 60);

        return _pdc;
    }

    //============ PDC Operations ============//

    /**
     * @notice Opens a PDC position.
     */
    function mintTo(
        address toAccount_,
        uint256 shareAmount_,
        uint256 grantAmount_
    ) external virtual whenNotPaused onlyOwner returns (uint256 id_) {
        address msgSender = _msgSender();

        // open
        id_ = id++;
        _safeMint(toAccount_, id_); // mint NFT
        emit Open(msgSender, id_);

        _update(id_);

        // deposit
        PositionDiscountCoupon storage _pdc = _pdcs[id_];
        _pdc.share += shareAmount_;
        totalShare += shareAmount_;
        emit Deposit(msgSender, id_, shareAmount_);

        // borrow
        _pdc.grant += grantAmount_;
        totalGrant += grantAmount_;
        ISIN(address(_grantToken)).mintTo(address(this), grantAmount_);
        emit Borrow(msgSender, id_, grantAmount_);
    }

    /**
     * @notice Closes the `id_` PDC position.
     */
    function burn(
        uint256 id_
    )
        external
        virtual
        whenNotPaused
        onlyPdcApprovedOrOwner(_msgSender(), id_)
        returns (uint256 shareAmount_, uint256 grantAmount_)
    {
        _update(id_);

        address msgSender = _msgSender();
        PositionDiscountCoupon storage _pdc = _pdcs[id_];
        uint256 _feeAmount = _pdc.fee;

        shareAmount_ = _pdc.share;
        grantAmount_ = _feeTo != address(0)
            ? _pdc.grant - _feeAmount
            : _pdc.grant;

        // repay
        ISIN(address(_grantToken)).burnFrom(
            address(this),
            grantAmount_ + _feeAmount
        );
        totalGrant -= grantAmount_;
        totalFee -= _feeAmount;
        emit Repay(msgSender, id_, grantAmount_);

        // withdraw
        totalShare -= shareAmount_;
        emit Withdraw(msgSender, id_, shareAmount_);

        // close
        _burn(id_);
        delete _pdcs[id_];
        emit Close(msgSender, id_);
    }

    /**
     * @notice Update fee.
     */
    function updateFee(uint256 id_) external returns (uint256 additionalFee) {
        return _update(id_);
    }

    //============ Internal Functions ============//

    /**
     * @dev Updates fee and timestamp.
     */
    function _update(uint256 id_) internal returns (uint256 additionalFee) {
        PositionDiscountCoupon storage _pdc = _pdcs[id_];

        uint256 prevTimestamp = _pdc.latestUpdate;
        uint256 prevFee = _pdc.fee;

        additionalFee =
            (_pdc.grant * (block.timestamp - prevTimestamp) * _feeRatio) /
            (_DENOMINATOR * 365 * 24 * 60 * 60);
        _pdc.fee += additionalFee;
        totalFee += additionalFee;

        _pdc.latestUpdate = block.timestamp;

        emit Update(id_, prevFee, _pdc.fee, prevTimestamp, block.timestamp);
    }
}
