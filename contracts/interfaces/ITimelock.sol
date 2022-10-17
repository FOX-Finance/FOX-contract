// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITimelock {
    function delay() external view returns(uint256);
    function GRACE_PERIOD() external view returns (uint256);
    function queuedTransactions(bytes32 hash_) external view returns (bool);

    function setDelay(uint256 delay_) external;

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) external;

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) external payable returns (bytes memory);
}
