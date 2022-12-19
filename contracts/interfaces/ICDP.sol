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

    function collateralToken() external view returns (address);

    function debtToken() external view returns (address);

    function collateralPrice() external view returns (uint256);

    function minimumCollateral() external view returns (uint256);

    function maxLTV() external view returns (uint256);

    function cap() external view returns (uint256);

    function id() external view returns (uint256);

    function totalCollateral() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function totalFee() external view returns (uint256);

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

    event Liquidate(
        address indexed account_,
        uint256 indexed id_,
        uint256 debtAmount_,
        uint256 collateralAmount_
    );

    event SetMaxLTV(uint256 prevMaxLTV, uint256 currMaxLTV);
    event SetCap(uint256 prevCap, uint256 currCap);

    event SetFeeTo(address prevFeeTo, address currFeeTo);
    event SetFeeRatio(uint256 prevFeeRatio, uint256 currFeeRatio);
    event SetLiquidationPenaltyRatio(
        uint256 prevLiquidationPenaltyRatio,
        uint256 currLiquidationPenaltyRatio
    );
    event SetLiquidationProtocolFeeRatio(
        uint256 prevLiquidationProtocolFeeRatio,
        uint256 currLiquidationProtocolFeeRatio
    );
    event SetLiquidationBufferRatio(
        uint256 prevLiquidationBufferRatio,
        uint256 currLiquidationBufferRatio
    );

    //============ Owner ============//

    function setMaxLTV(uint256 newMaxLTV) external;

    function setCap(uint256 newCap) external;

    function setFeeTo(address newFeeTo) external;

    function setFeeRatio(uint256 newFeeRatio) external;

    function setLiquidationPenaltyRatio(
        uint256 newLiquidationPenaltyRatio
    ) external;

    function setLiquidationProtocolFeeRatio(
        uint256 newLiquidationProtocolFeeRatio
    ) external;

    function setLiquidationBufferRatio(
        uint256 newLiquidationBufferRatio
    ) external;

    //============ Pausable ============//

    function pause() external;

    function unpause() external;

    //============ Oracle Functions ============//

    function updateOracleFeeder(address newOracleFeeder) external;

    function updateCollateralPrice(
        uint256 newCollateralPrice,
        uint256 confidence
    ) external;

    //============ Health Functions ============//

    function isSafe(uint256 id_) external view returns (bool);

    function globalLTV() external view returns (uint256 ltv_);

    function currentLTV(uint256 id_) external view returns (uint256 ltv_);

    function healthFactor(uint256 id_) external view returns (uint256 health);

    function globalHealthFactor() external view returns (uint256 health);

    //============ View Functions ============//

    function cdp(
        uint256 id_
    ) external view returns (CollateralizedDebtPosition memory);

    function calculatedLtv(
        uint256 collateralAmount_,
        uint256 debtAmount_
    ) external view returns (uint256 ltv_);

    //============ View Functions (CDP) ============//

    function debtAmountFromCollateralToLtv(
        uint256 collateralAmount_,
        uint256 ltv_
    ) external view returns (uint256 debtAmount_);

    function collateralAmountFromDebtWithLtv(
        uint256 debtAmount_,
        uint256 ltv_
    ) external view returns (uint256 collateralAmount_);

    function debtAmountRangeWhenLiquidate(
        uint256 id_
    ) external view returns (uint256 upperBound_, uint256 lowerBound_);

    //============ CDP Operations ============//

    function open() external returns (uint256 id_);

    function openAndDeposit(uint256 amount_) external returns (uint256 id_);

    function openAndDepositAndBorrow(
        uint256 depositAmount_,
        uint256 borrowAmount_
    ) external returns (uint256 id_);

    function close(uint256 id_) external;

    function deposit(uint256 id_, uint256 amount_) external;

    function depositAndBorrow(
        uint256 id_,
        uint256 depositAmount_,
        uint256 borrowAmount_
    ) external;

    function withdraw(uint256 id_, uint256 amount_) external;

    function borrow(uint256 id_, uint256 amount_) external;

    function repay(uint256 id_, uint256 amount_) external;

    function repayAndWithdraw(
        uint256 id_,
        uint256 repayAmount_,
        uint256 withdrawAmount_
    ) external;

    function liquidate(uint256 id_, uint256 amount_) external;

    function globalLiquidate(uint256 id_, uint256 amount_) external;

    function updateFee(uint256 id_) external returns (uint256 additionalFee);
}
