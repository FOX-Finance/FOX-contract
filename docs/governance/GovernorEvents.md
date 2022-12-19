## `GovernorEvents`







### `ProposalCreated(uint256 id, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 startBlock, uint256 endBlock, string description)`

An event emitted when a new proposal is created



### `VoteCast(address voter, uint256 proposalId, uint8 support, uint256 votes, string reason)`

An event emitted when a vote has been cast on a proposal




### `ProposalCanceled(uint256 id)`

An event emitted when a proposal has been canceled



### `ProposalQueued(uint256 id, uint256 eta)`

An event emitted when a proposal has been queued in the Timelock



### `ProposalExecuted(uint256 id)`

An event emitted when a proposal has been executed in the Timelock



