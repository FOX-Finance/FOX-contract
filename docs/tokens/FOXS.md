## `FOXS`

Users can deposit FOXS and FOXS-USDC LP into this contract
to earn newly minted FOXS.




### `mintTo(address account, uint256 amount)` (external)





### `burn(uint256 amount)` (external)





### `burnFrom(address account, uint256 amount)` (external)





### `poolLength() → uint256 pools` (public)

Returns the number of pools.



### `add(uint256 allocPoint_, contract IERC20 token_)` (public)

Add a new token to the pool. Can only be called by the owner.
DO NOT add the same token token more than once. Rewards will be messed up if you do.




### `set(uint256 pid_, uint256 allocPoint_)` (public)

Update the given pool's allocation point. Can only be called by the owner.




### `pendingToken(uint256 pid_, address user_) → uint256 pending` (public)

View function to see pending tokens on frontend.




### `update(uint256 pid_) → struct IFOXS.PoolInfo pool` (public)

Update reward variables of the given pool.




### `deposit(uint256 pid_, uint256 amount_, address to_)` (public)

Deposit tokens for FOXS allocation.




### `withdraw(uint256 pid_, uint256 amount_, address to_)` (public)

Withdraw tokens.




### `harvest(uint256 pid_, address to_)` (public)

Harvest proceeds for transaction sender to `to`.




### `withdrawAndHarvest(uint256 pid_, uint256 amount_, address to_)` (public)

Withdraw tokens and harvest proceeds for transaction sender to `to`.




### `emergencyWithdraw(uint256 pid_, address to_)` (public)

Withdraw without caring about rewards. EMERGENCY ONLY.




### `_safeTokenTransfer(address to_, uint256 amount_)` (internal)

Safe token transfer function,
just in case if rounding error causes this contract to not have enough Tokens.



### `_mint(address account, uint256 amount)` (internal)



See {ERC20-_mint}.

### `approveMax(address spender)` (public)






