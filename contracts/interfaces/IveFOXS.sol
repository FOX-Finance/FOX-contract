// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IveFOXS {
    function deposit(uint256 amount, uint256 period) external returns (uint256 veAmount, uint256 expiration);
    function withdraw() external;

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
}
