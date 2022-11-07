// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICDP {
    //============ Params ============//

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

    //============ Owner ============//

    function setMaxLTV(uint256 newMaxLTV) external;

    function setCap(uint256 newCap) external;

    function setFeeTo(address newFeeTo) external;

    function setFeeRatio(uint256 newFeeRatio) external;

    //============ Pausable ============//

    function pause() external;

    function unpause() external;

    //============ Oracle Functions ============//

    function updateOracleFeeder(address newOracleFeeder) external;

    function updateCollateralPrice(
        uint256 newCollateralPrice,
        uint256 confidence
    ) external;

    //============ View Functions ============//

    function cdpInfo(uint256 id_)
        external
        view
        returns (
            uint256 collateralAmount_,
            uint256 ltv_,
            uint256 fee_
        );

    function maxLTV() external view returns (uint256);

    function isSafe(uint256 id_) external view returns (bool);

    function currentLTV(uint256 id_) external view returns (uint256 ltv);

    function globalLTV() external view returns (uint256 ltv);

    function healthFactor(uint256 id_) external view returns (uint256 health);

    function globalHealthFactor() external view returns (uint256 health);

    function getCollateralPrice() external view returns (uint256);

    function borrowDebtAmountToLTV(
        uint256 id_,
        uint256 ltv_,
        uint256 collateralAmount_
    ) external view returns (uint256 debtAmount_);

    function withdrawCollateralAmountToLTV(
        uint256 id_,
        uint256 ltv_,
        uint256 debtAmount_
    ) external view returns (uint256 collateralAmount_);

    //============ CDP Operations ============//

    function open() external returns (uint256 id_);

    function openAndDeposit(uint256 amount_) external returns (uint256 id_);

    function close(uint256 id_) external;

    function deposit(uint256 id_, uint256 amount_) external;

    function withdraw(uint256 id_, uint256 amount_) external;

    function borrow(uint256 id_, uint256 amount_) external;

    function repay(uint256 id_, uint256 amount_) external;

    function updateFee(uint256 id_) external returns (uint256 additionalFee);

    function liquidate(uint256 id_) external;

    function globalLiquidate() external;
}
