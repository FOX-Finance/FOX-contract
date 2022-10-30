// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IveFOXS {
    //============ Params ============//

    struct Stake {
        uint256 collateral; // FOXS
        uint256 debt; // veFOXS
        uint256 expiration;
    }

    //============ Events ============//

    event Deposit(address indexed from_, uint256 amount_, uint256 expiration_);
    event Withdraw(address indexed to_, uint256 amount_, uint256 blockNumber_);

    //============ Functions ============//

    function deposit(uint256 amount, uint256 period)
        external
        returns (uint256 veAmount, uint256 expiration);

    function withdraw() external;

    //============ View Functions ============//

    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint96);
}
