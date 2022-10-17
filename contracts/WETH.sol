// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IWETH.sol";

contract WETH is IWETH, ERC20("Wrapped ETH", "WETH") {
    fallback() external payable {
        deposit();
    }

    receive() external payable {
        revert();
    }

    /**
     * @notice Exchange ETH to WETH.
     */
    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Exchange WETH to ETH.
     */
    function withdraw(uint256 amount_) external {
        require(
            balanceOf(msg.sender) >= amount_,
            "WETH::withdraw: WETH balance of sender must be greater than or equal to amount_."
        );
        _burn(msg.sender, amount_);
        payable(msg.sender).transfer(amount_);
        emit Withdraw(msg.sender, amount_);
    }
}
