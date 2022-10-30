// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../utils/Allowlist.sol";
import "../utils/Nonzero.sol";

import "../interfaces/ISIN.sol";

abstract contract abstractSIN is ISIN, Allowlist, ERC20, Ownable {
    function approveMax(address spender) public {
        _approve(_msgSender(), spender, type(uint256).max);
    }

    function mintTo(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    //============ Owner ============//

    function addAllowlist(address newAddr) external onlyOwner {
        _addAllowlist(newAddr);
    }

    function removeAllowlist(address targetAddr) external onlyOwner {
        _removeAllowlist(targetAddr);
    }

    function setAllowAll(bool newAllowAll) external onlyOwner {
        _setAllowAll(newAllowAll);
    }

    //============ Lock ============//

    function transfer(address to, uint256 amount)
        public
        override
        onlyAllowlist
        returns (bool)
    {
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override onlyAllowlist returns (bool) {
        return super.transferFrom(from, to, amount);
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
