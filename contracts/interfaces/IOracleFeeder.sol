// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOracleFeeder {
    //============ Events ============//

    event Initialize(address indexed foxFarm, address indexed fox);

    //============ Pausable ============//

    function pause() external;

    function unpause() external;

    //============ Oracle Feeder Functions ============//

    function updateAllPrice(
        uint256 newCollateralPrice,
        uint256 newStablePrice,
        uint256 newSharePrice,
        uint256 confidence
    ) external;

    function updateCollateralPrice(
        uint256 newCollateralPrice,
        uint256 confidence
    ) external;

    function updateStablePrice(uint256 newStablePrice, uint256 confidence)
        external;

    function updateSharePrice(uint256 newSharePrice, uint256 confidence)
        external;
}
