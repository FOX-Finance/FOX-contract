// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ICoupon.sol";

import "./CDP.sol";
import "./SIN.sol";

// import "./interfaces/IWETH.sol";

/**
 * @title Discount Coupon Position.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets WETH as collateral, gives minus SIN as debt.
 */
contract Coupon is CDP {
    using SafeERC20 for IERC20;

    //============ Initialize ============//

    constructor(
        address feeTo_,
        address collateralToken_, // WETH
        address grantToken_, // NIS
        uint256 maxLTV_,
        uint256 cap_,
        uint256 feeRatio_
    )
        CDP(
            "FoxFarm",
            "FOXCDP",
            address(0), // no oracle
            feeTo_,
            collateralToken_,
            grantToken_, // debtToken_
            maxLTV_,
            type(uint256).max,
            feeRatio_
        )
    {}
}
