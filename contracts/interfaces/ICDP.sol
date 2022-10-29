// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICDP {
    struct CollateralizedDebtPosition {
        uint256 collateral;
        uint256 debt;
        uint256 fee; // as SIN
        uint256 latestUpdate;
    }

    //============ Events ============//

    event Open(address indexed account_, uint256 indexed id_);
    event Close(address indexed account_, uint256 indexed id_);
    event Deposit(
        address indexed account_,
        uint256 indexed id_,
        uint256 amount
    );
    event Withdraw(
        address indexed account_,
        uint256 indexed id_,
        uint256 amount
    );
    event Borrow(address indexed account_, uint256 indexed id_, uint256 amount);
    event Repay(address indexed account_, uint256 indexed id_, uint256 amount);

    event Update(
        uint256 indexed id_,
        uint256 prevFee,
        uint256 currFee,
        uint256 prevTimestamp,
        uint256 currTimestamp
    );

    event SetMaxLTV(uint256 prevMaxLTV, uint256 currMaxLTV);
    event SetCap(uint256 prevCap, uint256 currCap);

    event SetFeeTo(address prevFeeTo, address currFeeTo);
    event SetFeeRatio(uint256 prevFeeRatio, uint256 currFeeRatio);
}
