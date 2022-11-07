// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../utils/Nonzero.sol";

import "../interfaces/ISIN.sol";

abstract contract abstractSIN is ISIN, ERC20, Ownable {
    function approveMax(address spender) external {
        _approve(_msgSender(), spender, type(uint256).max);
    }

    function mintTo(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}

/**
 * @title Stable INtermidiate-coin (SIN)
 * @author Luke Park (lukepark327@gmail.com)
 * @dev Uses internally to represent debt.
 */
contract SIN is abstractSIN, Nonzero {
    IERC20 public immutable nis;

    constructor(address nis_)
        nonzeroAddress(nis_)
        ERC20("Stable INtermidiate coin", "SIN")
    {
        nis = IERC20(nis_);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return super.totalSupply() - nis.totalSupply();
    }
}

/**
 * @title NIS Is negative-SIN (NIS)
 * @author Luke Park (lukepark327@gmail.com)
 * @dev Uses internally to represent minus debt in Coupon.
 */
contract NIS is abstractSIN {
    constructor() ERC20("Negative SIN", "NIS") {}
}
