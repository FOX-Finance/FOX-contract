// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISIN {
    function approveMax(address spender) external;

    function mintTo(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function addAllowlist(address newAddr) external;

    function removeAllowlist(address targetAddr) external;

    function setAllowAll(bool newAllowAll) external;
}
