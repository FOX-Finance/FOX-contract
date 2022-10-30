// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFOXS is IERC20 {
    function mint(address account, uint256 amount) external;
}
