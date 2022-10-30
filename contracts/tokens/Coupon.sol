// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./SIN.sol";
import "../utils/Nonzero.sol";

import "../interfaces/ICoupon.sol";

// import "./interfaces/IWETH.sol";

/**
 * @title Coupon. Share Grant Position.
 * @dev Similar with FoxFarm, but no collaterals, only shares and grants.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets FOXS as share, mints NIS as grant.
 */
contract Coupon is
    ICoupon,
    ERC721("Coupon", "FOXSGP"),
    Pausable,
    Ownable,
    Nonzero
{
    using SafeERC20 for IERC20;

    //============ Params ============//

    IERC20 internal immutable _shareToken; // FOXS
    IERC20 internal immutable _grantToken; // NIS

    uint256 private constant _DENOMINATOR = 10000;

    address internal _feeTo;
    uint256 internal _feeRatio; // (_feeRatio / _DENOMINATOR) // stability fee

    // CDP
    mapping(uint256 => ShareGrantPosition) public sgps;
    uint256 public id;
    uint256 public totalShare; // TODO: for coupon
    uint256 public totalGrant; // TODO: for coupon
    uint256 public totalFee; // TODO: for coupon

    //============ Modifiers ============//

    modifier onlySgpApprovedOrOwner(address msgSender, uint256 id_) {
        require(
            _isApprovedOrOwner(msgSender, id_),
            "Coupon::onlySgpApprovedOrOwner: Not a valid caller."
        );
        _;
    }

    //============ Initialize ============//

    constructor(
        address feeTo_,
        address shareToken_, // FOXS
        address grantToken_, // NIS
        uint256 feeRatio_
    ) nonzeroAddress(grantToken_) nonzeroAddress(shareToken_) {
        _feeTo = feeTo_; // can be zero address
        _shareToken = IERC20(shareToken_);
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

    //============ SGP Operations ============//
}
