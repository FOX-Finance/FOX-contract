// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOracle {
    //============ Events ============//

    event UpdateOracleFeeder(address prevOracleFeeder, address currOracle);
    event UpdatePrice(
        address indexed token,
        uint256 prevPrice,
        uint256 currPrice
    );
}
