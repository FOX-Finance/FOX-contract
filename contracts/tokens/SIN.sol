// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ISIN.sol";

abstract contract abstractSIN is ISIN, ERC20, Ownable {
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

    //============ Lock ============//

    mapping(address => bool) private _allowlist;
    bool private _allowAll;

    event AddAllowlist(address newAddr);
    event RemoveAllowlist(address targetAddr);
    event AllowAll(bool prevAllowAll, bool currAllowAll);

    modifier onlyAllowlist() {
        require(
            _allowAll || _allowlist[_msgSender()],
            "FOX:onlyAllowlist: Sender must be allowed."
        );
        _;
    }

    function addAllowlist(address newAddr) external onlyOwner {
        if (!_allowlist[newAddr]) {
            _allowlist[newAddr] = true;
        }
        emit AddAllowlist(newAddr);
    }

    function removeAllowlist(address targetAddr) external onlyOwner {
        if (_allowlist[targetAddr]) {
            _allowlist[targetAddr] = false;
        }
        emit RemoveAllowlist(targetAddr);
    }

    function setAllowAll(bool newAllowAll) external onlyOwner {
        bool prevAllowAll = _allowAll;
        _allowAll = newAllowAll;
        emit AllowAll(prevAllowAll, _allowAll);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override onlyAllowlist {}
}

/**
 * @title Stable INtermidiate-coin (SIN)
 * @author Luke Park (lukepark327@gmail.com)
 * @dev Uses internally to represent debt.
 */
contract SIN is abstractSIN {
    IERC20 public immutable nis;

    constructor(address nis_) ERC20("Stable INtermidiate coin", "SIN") {
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
