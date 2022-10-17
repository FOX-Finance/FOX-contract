// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Stable INtermidiate coin (SIN)
 * @author Luke Park (lukepark327@gmail.com)
 * @dev Uses internally to represent debt.
 */
contract SIN is ERC20("Stable INtermidiate coin", "SIN"), Ownable {
    function approveMax(address spender) public {
        _approve(_msgSender(), spender, type(uint256).max);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}
