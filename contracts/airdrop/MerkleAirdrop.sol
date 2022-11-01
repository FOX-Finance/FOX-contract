// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Airdrop contract.
 * @author Luke Park (lukepark327@gmail.com)
 * @notice Claim FOXS if you are qualified; DAI or FRAX users.
 * @dev Uses Merkle proofs.
 */
contract MerkleAirdrop is Pausable, Ownable {
    using SafeERC20 for IERC20;
    using MerkleProof for bytes32[];

    //============ Params ============//

    IERC20 public immutable token;

    bytes32 public immutable merkleRoot;
    mapping(address => bool) public hasClaimed;

    //============ Events ============//

    event Withdraw(address indexed token, uint256 amount);
    event Charge(address indexed token, uint256 amount);
    event Claim(
        address indexed fromAccount,
        address indexed toAccount,
        address indexed token,
        uint256 amount
    );

    //============ Initialize ============//

    constructor(address token_, bytes32 merkleRoot_) {
        token = IERC20(token_);
        merkleRoot = merkleRoot_;
    }

    //============ Owner ============//

    function withdraw(address toAccount_, uint256 amount_) external onlyOwner {
        token.safeTransfer(toAccount_, amount_);

        emit Withdraw(address(token), amount_);
    }

    //============ Pausable ============//

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //============ Functions ============//

    function charge(uint256 amount_) external {
        token.safeTransferFrom(_msgSender(), address(this), amount_);

        emit Charge(address(token), amount_);
    }

    function claim(
        address toAccount_,
        uint256 amount_,
        bytes32[] calldata proof_
    ) external {
        address _fromAccount = _msgSender();

        require(
            !hasClaimed[_fromAccount],
            "MerkleProof::claim: Already claimed."
        );

        bytes32 leaf = keccak256(abi.encodePacked(_fromAccount, amount_));
        bool isValidLeaf = proof_.verify(merkleRoot, leaf);
        require(isValidLeaf, "MerkleProof::claim: Not a valid leaf.");

        hasClaimed[_fromAccount] = true;

        token.safeTransfer(toAccount_, amount_);

        emit Claim(_fromAccount, toAccount_, address(token), amount_);
    }
}
