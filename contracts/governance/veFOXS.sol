// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20VotesComp.sol";

contract veFOXS is ERC20VotesComp {
    using SafeERC20 for IERC20;

    event Deposit(address indexed from_, uint256 amount_, uint256 expiration_);
    event Withdraw(address indexed to_, uint256 amount_, uint256 blockNumber_);

    /// @notice The number of blocks to represent 1 day.
    uint256 private constant ONE_DAY_BLOCKS = 86400 / 3; // blocks

    /// @notice The number of blocks to represent 3 months.
    uint256 private constant THREE_MONTHS_BLOCKS = ONE_DAY_BLOCKS * 90; // blocks

    /// @notice The number of blocks to represent 6 months.
    uint256 private constant SIX_MONTHS_BLOCKS = ONE_DAY_BLOCKS * 180; // blocks

    /// @notice The number of blocks to represent 1 year.
    uint256 private constant ONE_YEAR_BLOCKS = ONE_DAY_BLOCKS * 360; // blocks

    struct Stake {
        uint256 collateral; // FOXS
        uint256 debt; // veFOXS
        uint256 expiration;
    }

    /// @notice Stores the amount and the expiration of account.
    mapping(address => Stake) public stakes;

    IERC20 public foxs;

    constructor(address foxs_)
        ERC20("vote-escrowed FOX Share", "veFOXS")
        ERC20Permit("vote-escrowed FOX Share")
    {
        foxs = IERC20(foxs_);
    }

    /// @notice Deposits FOXSes and mints veFOXSes.
    /// @param amount Amount of FOXSes to stake.
    /// @param period Must be 0 (for 3 months), 1 (for 6 months), or 2 (for 1 year).
    /// @return veAmount Newly minted veFOXSes.
    function deposit(uint256 amount, uint256 period)
        external
        returns (uint256 veAmount, uint256 expiration)
    {
        address msgSender = _msgSender();
        Stake storage stake = stakes[msgSender];
        uint256 prevExpiration = stake.expiration;

        foxs.safeTransferFrom(msgSender, address(this), amount);

        expiration = block.number;
        if (period == 0) {
            // 3 months
            expiration += THREE_MONTHS_BLOCKS;
            veAmount = amount * 1;
            _mint(msgSender, veAmount);
        } else if (period == 1) {
            // 6 months
            expiration += SIX_MONTHS_BLOCKS;
            veAmount = amount * 2;
            _mint(msgSender, veAmount);
        } else if (period == 2) {
            // 1 year
            expiration += ONE_YEAR_BLOCKS;
            veAmount = amount * 4;
            _mint(msgSender, veAmount);
        } else {
            revert("veFOXS::deposit: `period` must be 0, 1, or 2");
        }
        if (expiration < prevExpiration) {
            expiration = prevExpiration;
        }

        stake.collateral += amount;
        stake.debt += veAmount;
        stake.expiration = expiration;

        emit Deposit(msgSender, veAmount, expiration);
    }

    function withdraw() external {
        address msgSender = _msgSender();
        Stake storage stake = stakes[msgSender];

        require(stake.expiration < block.number, "veFOXS::withdraw: not yet");
        require(
            balanceOf(msgSender) >= stake.debt,
            "veFOXS::withdraw: not enough veFOXS"
        );

        _burn(msgSender, stake.debt);

        foxs.safeTransfer(msgSender, stake.collateral);

        emit Withdraw(msgSender, stake.collateral, block.number);
    }
}
