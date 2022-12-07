## `ITimelock`






### `delay() → uint256` (external)





### `GRACE_PERIOD() → uint256` (external)





### `queuedTransactions(bytes32 hash_) → bool` (external)





### `setDelay(uint256 delay_)` (external)





### `queueTransaction(address target, uint256 value, string signature, bytes data, uint256 eta) → bytes32` (external)





### `cancelTransaction(address target, uint256 value, string signature, bytes data, uint256 eta)` (external)





### `executeTransaction(address target, uint256 value, string signature, bytes data, uint256 eta) → bytes` (external)






