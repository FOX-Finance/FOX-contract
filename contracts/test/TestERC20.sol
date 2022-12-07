// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Test-purpose ERC20 (for USDC).
 * @dev TEST PURPOSE ONLY!
 */
contract TestERC20 is ERC20("Test USDC", "USDC") {
    function approveMax(address spender) external {
        _approve(_msgSender(), spender, type(uint256).max);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}
