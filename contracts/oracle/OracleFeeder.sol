// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IFoxFarm.sol";
import "../interfaces/IFOX.sol";

import "../interfaces/IOracleFeeder.sol";

interface IInterval {
    function isPassInterval(uint256 TIME_PERIOD) external view returns (bool);
}

/**
 * @title Oracle feeder.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Update price of collateral, share, and stable token.
 */
contract OracleFeeder is IOracleFeeder, Pausable, Ownable {
    //============ Params ============//

    IFoxFarm public foxFarm; // FoxFarm
    IFOX public fox;

    uint256 private constant _TIME_PERIOD = 1 hours;

    uint256 private constant _DENOMINATOR = 10000;

    //============ Initialize ============//

    constructor() {}

    function initialize(address foxFarm_, address fox_) external onlyOwner {
        foxFarm = IFoxFarm(foxFarm_);
        fox = IFOX(fox_);

        emit Initialize(foxFarm_, fox_);
    }

    //============ Pausable ============//

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //============ Oracle Feeder Functions ============//

    function updateAllPrice(
        uint256 newCollateralPrice,
        uint256 newStablePrice,
        uint256 newSharePrice,
        uint256 confidence
    ) external onlyOwner {
        _updateCollateralPrice(newCollateralPrice, confidence);
        _updateStablePrice(newStablePrice, confidence);
        _updateSharePrice(newSharePrice, confidence);
    }

    function updateCollateralPrice(
        uint256 newCollateralPrice,
        uint256 confidence
    ) external onlyOwner {
        _updateCollateralPrice(newCollateralPrice, confidence);
    }

    function updateStablePrice(uint256 newStablePrice, uint256 confidence)
        external
        onlyOwner
    {
        _updateStablePrice(newStablePrice, confidence);
    }

    function updateSharePrice(uint256 newSharePrice, uint256 confidence)
        external
        onlyOwner
    {
        _updateSharePrice(newSharePrice, confidence);
    }

    //============ Internal Functions ============//

    function _updateCollateralPrice(
        uint256 newCollateralPrice,
        uint256 confidence
    ) internal onlyOwner {
        foxFarm.updateCollateralPrice(newCollateralPrice, confidence);
    }

    function _updateStablePrice(uint256 newStablePrice, uint256 confidence)
        internal
        onlyOwner
    {
        if (IInterval(address(fox)).isPassInterval(_TIME_PERIOD)) {
            fox.updateStablePriceWithTrustLevel(newStablePrice, confidence);
        } else {
            fox.updateStablePrice(newStablePrice, confidence);
        }
    }

    function _updateSharePrice(uint256 newSharePrice, uint256 confidence)
        internal
        onlyOwner
    {
        fox.updateSharePrice(newSharePrice, confidence);
    }
}
