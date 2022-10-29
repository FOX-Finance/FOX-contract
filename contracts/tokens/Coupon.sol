// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./CDP.sol";
import "./SIN.sol";
import "../utils/Nonzero.sol";

import "../interfaces/ICoupon.sol";

// import "./interfaces/IWETH.sol";

/**
 * @title Discount Coupon Position.
 * @dev Similar with FoxFarm, but no collaterals.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets WETH as collateral, gives minus SIN as debt.
 */
contract Coupon is CDP, Nonzero {
    using SafeERC20 for IERC20;

    //============ Params ============//

    uint256 private constant _DENOMINATOR = 10000;

    //============ Modifiers ============//

    modifier range(uint256 id_) {
        require(id_ <= id, "Coupon::range: Invalid range.");
        _;
    }

    //============ Initialize ============//

    constructor(
        address feeTo_,
        address shareToken_, // FOXS
        address grantToken_, // NIS
        uint256 feeRatio_
    )
        nonzeroAddress(grantToken_)
        CDP(
            "FoxFarm",
            "FOXCDP",
            address(0), // no oracle
            feeTo_,
            address(0),
            grantToken_, // minus debtToken_ // NIS
            _DENOMINATOR, // maxLTV_ // 100%
            type(uint256).max, // cap_
            feeRatio_
        )
        nonzeroAddress(shareToken_)
    {}

    //============ Owner (override) ============//

    function setMaxLTV(uint256 newMaxLTV) external override onlyOwner {}

    function setCap(uint256 newCap) external override onlyOwner {}

    //============ View Functions ============//

    /**
     * @notice Coupon is always safe.
     */
    function isSafe(uint256 id_)
        public
        view
        override
        range(id_)
        returns (bool)
    {
        return true;
    }

    function currentLTV(uint256 id_)
        public
        view
        override
        range(id_)
        returns (uint256 ltv)
    {
        return 0;
    }

    function healthFactor(uint256 id_)
        public
        view
        override
        range(id_)
        returns (uint256 health)
    {
        return 0;
    }

    //============ CDP Operations (override) ============//
}
