// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICoupon {
    //============ Params ============//

    struct ShareGrantPosition {
        uint256 share;
        uint256 grant;
        uint256 fee; // as NIS
        uint256 latestUpdate;
    }

    //============ Events ============//

    event SetFeeTo(address prevFeeTo, address currFeeTo);
    event SetFeeRatio(uint256 prevFeeRatio, uint256 currFeeRatio);
}
