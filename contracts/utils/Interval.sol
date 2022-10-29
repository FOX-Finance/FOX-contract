// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract Interval {
    //============ Params ============//

    uint256 private _lastStepUpdateTime;

    //============ Modifiers ============//

    modifier interval(uint256 TIME_PERIOD) {
        require(
            TIME_PERIOD < block.timestamp - _lastStepUpdateTime,
            "Interval::interval: Not yet."
        );
        _;
        _lastStepUpdateTime = block.timestamp;
    }

    //============ Initialize ============//

    constructor() {
        _lastStepUpdateTime = block.timestamp;
    }
}
