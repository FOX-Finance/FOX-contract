// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

import "../interfaces/IOracle.sol";

contract Oracle is IOracle, Context {
    //============ Params ============//

    address private _oracleFeeder;

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
        _oracleFeeder = oracleFeeder_;
    }

    //============ Functions ============//

    function _updateOracleFeeder(address newOracleFeeder) internal {
        address prevOracleFeeder = address(_oracleFeeder);
        _oracleFeeder = newOracleFeeder;
        emit UpdateOracleFeeder(prevOracleFeeder, address(_oracleFeeder));
    }
}
