// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICoupon {
    //============ Params ============//

    struct PositionDiscountCoupon {
        uint256 share;
        uint256 grant;
        uint256 fee; // as NIS
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

    event SetFeeTo(address prevFeeTo, address currFeeTo);
    event SetFeeRatio(uint256 prevFeeRatio, uint256 currFeeRatio);

    //============ Owner ============//

    function setFeeTo(address newFeeTo) external;

    function setFeeRatio(uint256 newFeeRatio) external;

    //============ Pausable ============//

    function pause() external;

    function unpause() external;

    //============ View Functions ============//

    function pdc(uint256 id_) external view returns (PositionDiscountCoupon memory);

    //============ PDC Operations ============//

    /**
     * @notice Opens a PDC position.
     */
    function mintTo(
        address toAccount_,
        uint256 shareAmount_,
        uint256 grantAmount_
    ) external returns (uint256 id_);

    /**
     * @notice Closes the `id_` PDC position.
     */
    function burn(
        uint256 id_
    ) external returns (uint256 shareAmount_, uint256 grantAmount_);

    /**
     * @notice Update fee.
     */
    function updateFee(uint256 id_) external returns (uint256 additionalFee);
}
