// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IFOX {
    enum Step {
        baby,
        big,
        giant,
        ultra
    }
    
    function approveMax(address spender) external;
}
