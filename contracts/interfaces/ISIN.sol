// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISIN {
    function mintTo(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}
