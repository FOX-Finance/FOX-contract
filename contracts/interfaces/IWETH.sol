// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount_) external;

    event Deposit(address indexed account_, uint256 amount_);
    event Withdraw(address indexed account_, uint256 amount_);

    //============ ERC20-related Functions ============//

    function approveMax(address spender) external;
}
