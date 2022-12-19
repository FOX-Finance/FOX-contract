## `Timelock`






### `constructor(uint256 delay_)` (public)





### `receive()` (external)





### `setDelay(uint256 delay_)` (public)





### `queueTransaction(address target, uint256 value, string signature, bytes data, uint256 eta) → bytes32` (public)





### `cancelTransaction(address target, uint256 value, string signature, bytes data, uint256 eta)` (public)





### `executeTransaction(address target, uint256 value, string signature, bytes data, uint256 eta) → bytes` (public)





### `getBlockTimestamp() → uint256` (internal)






### `NewDelay(uint256 newDelay)`





### `CancelTransaction(bytes32 txHash, address target, uint256 value, string signature, bytes data, uint256 eta)`





### `ExecuteTransaction(bytes32 txHash, address target, uint256 value, string signature, bytes data, uint256 eta)`





### `QueueTransaction(bytes32 txHash, address target, uint256 value, string signature, bytes data, uint256 eta)`





