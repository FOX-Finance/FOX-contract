// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISIN {
    function mint(address account, uint256 amount_) external; // only CDP
    function burn(address account, uint256 amount_) external; // only CDP
}
