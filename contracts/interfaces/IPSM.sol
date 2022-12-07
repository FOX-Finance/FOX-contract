// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPSM {
    //============ Events ============//

    event SetFeeTo(address prevFeeTo, address currFeeTo);
    event SetExchangeRatio(
        uint256 prevExchangeRatio,
        uint256 currExchangeRatio
    );
    event SetRefundRatio(uint256 prevRefundRatio, uint256 currRefundRatio);

    //============ Owner ============//

    function setFeeTo(address newFeeTo) external;

    function setExchangeRatio(uint256 newExchangeRatio) external;

    function setRefundRatio(uint256 newRefundRatio) external;

    //============ Pausable ============//

    function pause() external;

    function unpause() external;

    //============ Functions ============//

    function exchange(address account, uint256 amount) external;

    function refund(address account, uint256 amount) external;
}
