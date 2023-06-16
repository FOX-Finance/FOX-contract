// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IWETH.sol";

contract WETH is IWETH, ERC20("Wrapped ETH", "WETH") {
    fallback() external payable {
        deposit();
    }

    receive() external payable {
        revert();
    }

    // TODO: test-purpose only
    function mint(address account_, uint256 amount_) public payable {
        _mint(account_, amount_);
    }

    /**
     * @notice Exchange ETH to WETH.
     */
    function deposit() public payable {
        _mint(_msgSender(), msg.value);
        emit Deposit(_msgSender(), msg.value);
    }

    /**
     * @notice Exchange WETH to ETH.
     */
    function withdraw(uint256 amount_) external {
        require(
            balanceOf(_msgSender()) >= amount_,
            "WETH::withdraw: WETH balance of sender must be greater than or equal to amount_."
        );
        _burn(_msgSender(), amount_);
        payable(_msgSender()).transfer(amount_);
        emit Withdraw(_msgSender(), amount_);
    }

    //============ ERC20-related Functions ============//

    function approveMax(address spender) public {
        _approve(_msgSender(), spender, type(uint256).max);
    }
}
