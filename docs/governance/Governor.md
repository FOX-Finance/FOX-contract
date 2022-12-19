## `Governor`






### `constructor(address veFoxs_, uint256 votingPeriod_, uint256 votingDelay_, uint256 proposalThreshold_)` (public)

Used to initialize the contract




### `propose(address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, string description) → uint256` (public)

Function used to propose a new proposal. Sender must have delegates above the proposal threshold




### `queue(uint256 proposalId)` (external)

Queues a proposal of state succeeded




### `queueOrRevertInternal(address target, uint256 value, string signature, bytes data, uint256 eta)` (internal)





### `execute(uint256 proposalId)` (external)

Executes a queued proposal if eta has passed




### `cancel(uint256 proposalId)` (external)

Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold




### `getActions(uint256 proposalId) → address[] targets, uint256[] values, string[] signatures, bytes[] calldatas` (external)

Gets actions of a proposal




### `getReceipt(uint256 proposalId, address voter) → struct GovernorStorage.Receipt` (external)

Gets the receipt for a voter on a given proposal




### `state(uint256 proposalId) → enum GovernorStorage.ProposalState` (public)

Gets the state of a proposal




### `castVote(uint256 proposalId, uint8 support)` (external)

Cast a vote for a proposal




### `castVoteWithReason(uint256 proposalId, uint8 support, string reason)` (external)

Cast a vote for a proposal with a reason




### `castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s)` (external)

Cast a vote for a proposal by signature


External function that accepts EIP-712 signatures for voting on proposals.

### `castVoteInternal(address voter, uint256 proposalId, uint8 support) → uint96` (internal)

Internal function that caries out voting logic





