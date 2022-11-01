// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract Interval {
    //============ Params ============//

    uint256 private _lastStepUpdateTime;

    //============ Modifiers ============//

    modifier interval(uint256 TIME_PERIOD) {
        require(isPassInterval(TIME_PERIOD), "Interval::interval: Not yet.");
        _;
        _lastStepUpdateTime = block.timestamp;
    }

    //============ Initialize ============//

    constructor() {
        _lastStepUpdateTime = block.timestamp;
    }

    //============ View Functions ============//

    function isPassInterval(uint256 TIME_PERIOD) public view returns (bool) {
        return TIME_PERIOD < block.timestamp - _lastStepUpdateTime;
    }
}
