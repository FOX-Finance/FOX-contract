// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ICoupon.sol";

// import "./interfaces/IWETH.sol";

/**
 * @title Discount Coupon Position.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets WETH as collateral, gives minus SIN as debt.
 */
contract Coupon is
    ICoupon,
    ERC721("Discount Coupon Position", "DCP"),
    Pausable,
    Ownable
{
    using SafeERC20 for IERC20;
}
