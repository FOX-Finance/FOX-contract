// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IFOX.sol";
import "./interfaces/IFoxFarm.sol";

import "./interfaces/IFoxFarmGateway.sol";

contract FoxFarmGateway is IFoxFarmGateway {
    IERC20 private immutable _collateralToken;
    IERC20 private immutable _shareToken;
    IFOX private immutable _stableToken;

    IFoxFarm private immutable _foxFarm;

    uint256 internal constant _DENOMINATOR = 10000;

    constructor(
        IERC20 collateralToken_,
        IERC20 shareToken_,
        IFOX stableToken_,
        IFoxFarm foxFarm_
    ) {
        _collateralToken = collateralToken_;
        _shareToken = shareToken_;
        _stableToken = stableToken_;
        _foxFarm = foxFarm_;
    }

    //============ View Functions (Mint) ============//

    function defaultValuesMint(
        address account_,
        uint256 id_
    )
        external
        view
        returns (
            uint256 collateralAmount_,
            uint256 ltv_, // 40 as default
            uint256 shareAmount_,
            uint256 stableAmount_
        )
    {
        uint256 _hodlCollateralAmount = _collateralToken.balanceOf(account_);
        uint256 _hodlShareAmount = _shareToken.balanceOf(account_);

        uint256 _debtAmount;
        if (id_ < _foxFarm.id()) {
            IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);

            ltv_ = _foxFarm.currentLTV(id_);
            _debtAmount =
                _foxFarm.debtAmountFromCollateralToLtv(
                    _hodlCollateralAmount + _cdp.collateral,
                    ltv_
                ) -
                (_cdp.debt + _cdp.fee);
        } else {
            ltv_ = 4000; // TODO: recommendation LTV
            _debtAmount = _foxFarm.debtAmountFromCollateralToLtv(
                _hodlCollateralAmount,
                ltv_
            );
        }

        (stableAmount_, ) = _stableToken.expectedMintAmountWithMintFee(
            _debtAmount,
            _hodlShareAmount
        ); // refined stableAmount

        collateralAmount_ = _foxFarm.collateralAmountFromDebtWithLtv(
            _stableToken.requiredDebtAmountFromStableWithMintFee(stableAmount_),
            ltv_
        );

        shareAmount_ = _stableToken.requiredShareAmountFromStableWithMintFee(
            stableAmount_
        );
    }

    // TODO: Zapping in case of out of range. (ex. FOXS -> SIN|WETH)
    function ltvRangeWhenMint(
        uint256 id_, // default type(uint256).max
        uint256 collateralAmount_,
        uint256 shareAmount_
    ) public view returns (uint256 upperBound_, uint256 lowerBound_) {
        uint256 _trustLevel = _stableToken.trustLevel();
        if (_trustLevel == 0) {
            return (0, 0);
        }

        if (id_ < _foxFarm.id()) {
            IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);
            upperBound_ = min(
                _foxFarm.maxLTV(),
                _foxFarm.calculatedLtv(
                    _cdp.collateral + collateralAmount_,
                    _stableToken.requiredDebtAmountFromShare(shareAmount_)
                )
            );

            lowerBound_ = _foxFarm.currentLTV(id_);
        } else {
            upperBound_ = min(
                _foxFarm.maxLTV(),
                _foxFarm.calculatedLtv(
                    collateralAmount_,
                    _stableToken.requiredDebtAmountFromShare(shareAmount_)
                )
            );

            lowerBound_ = 1;
        }
    }

    function collateralAmountRangeWhenMint(
        address account_,
        uint256 id_,
        uint256 ltv_,
        uint256 shareAmount_
    ) public view returns (uint256 upperBound_, uint256 lowerBound_) {
        upperBound_ = _collateralToken.balanceOf(account_);

        lowerBound_ = requiredCollateralAmountFromShareToLtv(
            id_,
            shareAmount_,
            ltv_
        );
    }

    function shareAmountRangeWhenMint(
        address account_,
        uint256 id_,
        uint256 collateralAmount_,
        uint256 ltv_
    ) public view returns (uint256 upperBound_, uint256 lowerBound_) {
        upperBound_ = _shareToken.balanceOf(account_);

        lowerBound_ = requiredShareAmountFromCollateralToLtv(
            id_,
            collateralAmount_,
            ltv_
        );
    }

    function requiredCollateralAmountFromShareToLtv(
        uint256 id_,
        uint256 newShareAmount_,
        uint256 ltv_
    ) public view returns (uint256 collateralAmount_) {
        uint256 _debtAmount = _stableToken.requiredDebtAmountFromShare(
            newShareAmount_
        );

        if (id_ < _foxFarm.id()) {
            IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);
            collateralAmount_ = max(
                _foxFarm.collateralAmountFromDebtWithLtv(
                    (_cdp.debt + _cdp.fee) + _debtAmount,
                    ltv_
                ) - _cdp.collateral,
                _foxFarm.minimumCollateral() - _cdp.collateral
            );
        } else {
            collateralAmount_ = max(
                collateralAmount_ = _foxFarm.collateralAmountFromDebtWithLtv(
                    _debtAmount,
                    ltv_
                ),
                _foxFarm.minimumCollateral()
            );
        }
    }

    function requiredShareAmountFromCollateralToLtv(
        uint256 id_,
        uint256 newCollateralAmount_,
        uint256 ltv_
    ) public view returns (uint256 shareAmount_) {
        uint256 _debtAmount;
        if (id_ < _foxFarm.id()) {
            IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);
            _debtAmount =
                _foxFarm.debtAmountFromCollateralToLtv(
                    newCollateralAmount_ + _cdp.collateral,
                    ltv_
                ) -
                (_cdp.debt + _cdp.fee);
        } else {
            _debtAmount = _foxFarm.debtAmountFromCollateralToLtv(
                newCollateralAmount_,
                ltv_
            );
        }

        shareAmount_ = _stableToken.requiredShareAmountFromDebt(_debtAmount);
    }

    function expectedMintAmountToLtv(
        uint256 id_,
        uint256 newCollateralAmount_,
        uint256 ltv_,
        uint256 newShareAmount_
    ) public view returns (uint256 newStableAmount_) {
        uint256 _debtAmount;
        if (id_ < _foxFarm.id()) {
            IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);
            _debtAmount =
                _foxFarm.debtAmountFromCollateralToLtv(
                    newCollateralAmount_ + _cdp.collateral,
                    ltv_
                ) -
                (_cdp.debt + _cdp.fee);
        } else {
            _debtAmount = _foxFarm.debtAmountFromCollateralToLtv(
                newCollateralAmount_,
                ltv_
            );
        } // gas reduce

        (newStableAmount_, ) = _stableToken.expectedMintAmountWithMintFee(
            _debtAmount,
            newShareAmount_
        );
    }

    //============ View Functions (Redeem) ============//

    function defaultValueRedeem(
        address account_,
        uint256 id_
    )
        external
        view
        returns (
            uint256 stableAmount_,
            uint256 collateralAmount_,
            uint256 ltv_,
            uint256 shareAmount_
        )
    {
        stableAmount_ = IERC20(address(_stableToken)).balanceOf(account_);

        ltv_ = _foxFarm.currentLTV(id_);

        uint256 _debtAmount;
        (_debtAmount, shareAmount_, ) = _stableToken
            .expectedRedeemAmountWithBurnFee(stableAmount_);

        IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);
        collateralAmount_ =
            _cdp.collateral -
            _foxFarm.collateralAmountFromDebtWithLtv(
                (_cdp.debt + _cdp.fee) - _debtAmount,
                ltv_
            );
    }

    // TODO: Zapping in case of out of range.
    function ltvRangeWhenRedeem(
        uint256 id_,
        uint256 stableAmount_
    ) public view returns (uint256 upperBound_, uint256 lowerBound_) {
        upperBound_ = _foxFarm.currentLTV(id_);

        uint256 _debtAmount = _stableToken
            .requiredDebtAmountFromStableWithBurnFee(stableAmount_);

        IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);
        lowerBound_ = _foxFarm.calculatedLtv(
            _cdp.collateral,
            (_cdp.debt + _cdp.fee) - _debtAmount
        );
    }

    function stableAmountRangeWhenRedeem(
        address account_,
        uint256 id_
    ) public view returns (uint256 upperBound_, uint256 lowerBound_) {
        uint256 _hodlStableAmount = IERC20(address(_stableToken)).balanceOf(
            account_
        );

        IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);
        upperBound_ = min(
            _hodlStableAmount,
            ((_cdp.debt + _cdp.fee) *
                (_DENOMINATOR - _stableToken.burnFeeRatio()) *
                (_DENOMINATOR - _stableToken.trustLevel())) /
                (_DENOMINATOR * _DENOMINATOR)
        );

        // lowerBound_ = 0;
    }

    function expectedRedeemAmountToLtv(
        uint256 id_,
        uint256 collectedStableAmount_,
        uint256 ltv_
    )
        public
        view
        returns (uint256 emittedCollateralAmount_, uint256 emittedShareAmount_)
    {
        uint256 _debtAmount;
        (_debtAmount, emittedShareAmount_, ) = _stableToken
            .expectedRedeemAmountWithBurnFee(collectedStableAmount_);

        IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);
        emittedCollateralAmount_ =
            _cdp.collateral -
            _foxFarm.collateralAmountFromDebtWithLtv(
                (_cdp.debt + _cdp.fee) - _debtAmount,
                ltv_
            );
    }

    //============ View Functions (Recoll) ============//

    function defaultValuesRecollateralize(
        address account_,
        uint256 id_
    )
        public
        view
        returns (uint256 collateralAmount_, uint256 ltv_, uint256 shareAmount_)
    {
        uint256 _hodlCollateralAmount = _collateralToken.balanceOf(account_);

        ltv_ = _foxFarm.currentLTV(id_);

        IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);
        collateralAmount_ = _foxFarm.collateralAmountFromDebtWithLtv(
            min(
                _foxFarm.debtAmountFromCollateralToLtv(
                    _hodlCollateralAmount + _cdp.collateral,
                    ltv_
                ) - (_cdp.debt + _cdp.fee),
                _stableToken.shortfallRecollateralizeAmount()
            ),
            ltv_
        );

        shareAmount_ = exchangedShareAmountFromCollateralToLtv(
            id_,
            collateralAmount_,
            ltv_
        );
    }

    /// @dev always be same (can be decreased by new collateral amount)
    /// or increasing LTV.
    function ltvRangeWhenRecollateralize(
        uint256 id_,
        uint256 collateralAmount_
    ) public view returns (uint256 upperBound_, uint256 lowerBound_) {
        IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);

        upperBound_ = min(
            _foxFarm.maxLTV(),
            _foxFarm.calculatedLtv(
                _cdp.collateral + collateralAmount_,
                (_cdp.debt + _cdp.fee) +
                    _stableToken.shortfallRecollateralizeAmount()
            )
        );

        lowerBound_ = _foxFarm.calculatedLtv(
            _cdp.collateral + collateralAmount_,
            (_cdp.debt + _cdp.fee)
        );
    }

    /// @dev 0 to shorfall.
    function collateralAmountRangeWhenRecollateralize(
        address account_,
        uint256 id_,
        uint256 ltv_
    ) public view returns (uint256 upperBound_, uint256 lowerBound_) {
        IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);

        upperBound_ = min(
            _collateralToken.balanceOf(account_),
            _foxFarm.collateralAmountFromDebtWithLtv(
                (_cdp.debt + _cdp.fee) +
                    _stableToken.shortfallRecollateralizeAmount(),
                ltv_
            ) - _cdp.collateral
        );

        // lowerBound_ = 0;
    }

    /// @dev No consideration about shortfall.
    function exchangedShareAmountFromCollateralToLtv(
        uint256 id_,
        uint256 collateralAmount_,
        uint256 ltv_
    ) public view returns (uint256 shareAmount_) {
        IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);
        shareAmount_ = _stableToken.exchangedShareAmountFromDebtWithBonus(
            _foxFarm.debtAmountFromCollateralToLtv(
                collateralAmount_ + _cdp.collateral,
                ltv_
            ) - (_cdp.debt + _cdp.fee)
        );
    }

    //============ View Functions (Buyback) ============//

    function defaultValuesBuyback(
        address account_,
        uint256 id_
    )
        external
        view
        returns (uint256 shareAmount_, uint256 collateralAmount_, uint256 ltv_)
    {
        uint256 _hodlShareAmount = _shareToken.balanceOf(account_);

        ltv_ = _foxFarm.currentLTV(id_);

        IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);
        shareAmount_ = _stableToken.exchangedShareAmountFromDebt(
            min(
                min(
                    _stableToken.exchangedDebtAmountFromShare(_hodlShareAmount),
                    (_cdp.debt + _cdp.fee)
                ),
                _stableToken.surplusBuybackAmount()
            )
        );

        collateralAmount_ = exchangedCollateralAmountFromShareToLtv(
            id_,
            shareAmount_,
            ltv_
        );
    }

    /// @dev always be same or decreasing LTV.
    function ltvRangeWhenBuyback(
        uint256 id_,
        uint256 shareAmount_
    ) public view returns (uint256 upperBound_, uint256 lowerBound_) {
        IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);

        upperBound_ = _foxFarm.currentLTV(id_);

        lowerBound_ = _foxFarm.calculatedLtv(
            _cdp.collateral,
            (_cdp.debt + _cdp.fee) -
                min(
                    _stableToken.exchangedDebtAmountFromShare(shareAmount_),
                    _stableToken.surplusBuybackAmount()
                )
        );
    }

    /// @dev 0 to surplus.
    function shareAmountRangeWhenBuyback(
        address account_,
        uint256 id_
    ) public view returns (uint256 upperBound_, uint256 lowerBound_) {
        IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);

        upperBound_ = min(
            _shareToken.balanceOf(account_),
            _stableToken.exchangedShareAmountFromDebt(
                min(
                    _stableToken.surplusBuybackAmount(),
                    _foxFarm.debtAmountFromCollateralToLtv(
                        _cdp.collateral,
                        _foxFarm.maxLTV()
                    ) - (_cdp.debt + _cdp.fee)
                )
            )
        );

        // lowerBound_ = 0;
    }

    /// @dev for buyback
    function exchangedCollateralAmountFromShareToLtv(
        uint256 id_,
        uint256 shareAmount_,
        uint256 ltv_
    ) public view returns (uint256 collateralAmount_) {
        IFoxFarm.CollateralizedDebtPosition memory _cdp = _foxFarm.cdp(id_);
        collateralAmount_ =
            _cdp.collateral -
            _foxFarm.collateralAmountFromDebtWithLtv(
                (_cdp.debt + _cdp.fee) -
                    _stableToken.exchangedDebtAmountFromShare(shareAmount_),
                ltv_
            );
    }

    //============ View Functions (Coupon) ============//

    // TODO (WIP)
}

function max(uint256 a, uint256 b) pure returns (uint256) {
    return a > b ? a : b;
}

function min(uint256 a, uint256 b) pure returns (uint256) {
    return a < b ? a : b;
}
