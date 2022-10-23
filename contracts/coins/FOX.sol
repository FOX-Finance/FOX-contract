// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IFOX.sol";

/**
 * @title Fractional Over Collateralized Stablecoin (FOX)
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Gets SIN and FOXS, gives FOX as debt.
 */
contract FOX is
    IFOX,
    ERC20("Fractional Over Collateralized Stablecoin", "FOX"),
    Ownable
{
    using SafeERC20 for IERC20;

    function approveMax(address spender) public {
        _approve(_msgSender(), spender, type(uint256).max);
    }

    //============ Mint & Redeem ============//

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function redeem(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    //============ Recallateralize ============//

    function recollateralizeBorrowDebt() external {

    }

    function recollateralizeDepositCollateral() external {

    }

    //============ Buyback ============//

    function buybackRepayDebt() external {

    }

    function buybackWithdrawCollateral() external {

    }

    function buybackCoupon() external {

    }
}
