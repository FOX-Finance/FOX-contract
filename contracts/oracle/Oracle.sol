// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

import "../interfaces/IOracle.sol";

contract Oracle is IOracle, Context {
    //============ Params ============//

    address private _oracleFeeder;

    //============ Events ============//

    event UpdateOracleFeeder(address prevOracleFeeder, address currOracle);
    event UpdatePrice(
        address indexed token,
        uint256 prevPrice,
        uint256 currPrice
    );

    //============ Modifiers ============//

    modifier onlyOracleFeeder() {
        require(
            _msgSender() == address(_oracleFeeder),
            "Oracle::onlyOracleFeeder: Sender must be same as _oracleFeeder."
        );
        _;
    }

    //============ Initialize ============//

    constructor(address oracleFeeder_) {
        // can be zero (Coupon)
        // require(
        //     oracleFeeder_ != address(0),
        //     "Oracle::nonzeroAddress: Account must be nonzero."
        // );

        _oracleFeeder = oracleFeeder_;
    }

    //============ Functions ============//

    function _updateOracleFeeder(address newOracleFeeder) internal {
        address prevOracleFeeder = address(_oracleFeeder);
        _oracleFeeder = newOracleFeeder;
        emit UpdateOracleFeeder(prevOracleFeeder, address(_oracleFeeder));
    }
}
