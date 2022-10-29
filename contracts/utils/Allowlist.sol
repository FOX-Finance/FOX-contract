// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Allowlist is Context {
    //============ Params ============//

    mapping(address => bool) private _allowlist;
    bool private _allowAll;

    //============ Events ============//

    event AddAllowlist(address newAddr);
    event RemoveAllowlist(address targetAddr);
    event AllowAll(bool prevAllowAll, bool currAllowAll);

    //============ Modifiers ============//

    modifier onlyAllowlist() {
        require(
            _allowAll || _allowlist[_msgSender()],
            "Allowlist:onlyAllowlist: Sender must be allowed."
        );
        _;
    }

    //============ Functions ============//

    function _addAllowlist(address newAddr) internal {
        if (!_allowlist[newAddr]) {
            _allowlist[newAddr] = true;
        }
        emit AddAllowlist(newAddr);
    }

    function _removeAllowlist(address targetAddr) internal {
        if (_allowlist[targetAddr]) {
            _allowlist[targetAddr] = false;
        }
        emit RemoveAllowlist(targetAddr);
    }

    function _setAllowAll(bool newAllowAll) internal {
        bool prevAllowAll = _allowAll;
        _allowAll = newAllowAll;
        emit AllowAll(prevAllowAll, _allowAll);
    }
}
