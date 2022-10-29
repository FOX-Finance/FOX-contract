// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract Nonzero {
    //============ Modifiers ============//

    modifier nonzeroAddress(address account_) {
        require(
            account_ != address(0),
            "Nonzero::nonzeroAddress: Account must be nonzero."
        );
        _;
    }
}
