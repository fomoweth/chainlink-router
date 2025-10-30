// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Ownable
/// @notice Simple single owner authorization mixin
/// @dev Modified from https://github.com/Vectorized/solady/blob/main/src/auth/Ownable.sol
/// @author fomoweth
abstract contract Ownable {
    /// @notice Thrown when an invalid owner address is provided
    error InvalidNewOwner();

    /// @notice Thrown when unauthorized account attempts restricted operation
    error UnauthorizedAccount(address account);

    /// @notice Emitted when the ownership is transferred
    /// @dev Compatible with EIP-173 for indexer support
    /// @param previousOwner The address of the previous owner
    /// @param newOwner The address of the new owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Pre-computed keccak256 hash of the {OwnershipTransferred} event signature
    /// @dev keccak256("OwnershipTransferred(address,address)")
    uint256 private constant OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /// @notice Storage slot for owner address
    /// @dev keccak256(abi.encode(uint256(keccak256("Ownable.storage.owner")) - 1)) & ~bytes32(uint256(0xff))
    uint256 private constant OWNER_SLOT = 0xb037133c75dfcd4f094c94d0d9c23d2de13583ebafe40c8a35ad4c5b3b86e300;

    /// @notice Restricts function access to the contract owner only
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /// @notice Transfers ownership of the contract to a new account
    /// @param account The address to transfer ownership to
    function transferOwnership(address account) public payable virtual onlyOwner {
        _checkNewOwner(account);
        _setOwner(account);
    }

    /// @notice Renounces ownership, leaving the contract without an owner
    function renounceOwnership() public payable virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @notice Internal function to set the owner
    function _setOwner(address account) internal virtual {
        assembly ("memory-safe") {
            // Clean the upper 96 bits of the address to ensure it's properly formatted
            account := shr(0x60, shl(0x60, account))
            // Emit {OwnershipTransferred} event
            log3(0x00, 0x00, OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(OWNER_SLOT), account)
            // Store the new owner in the owner slot
            sstore(OWNER_SLOT, or(account, shl(0xff, iszero(account))))
        }
    }

    /// @notice Returns the address of the current owner
    /// @return account The current owner address
    function owner() public view virtual returns (address account) {
        assembly ("memory-safe") {
            account := sload(OWNER_SLOT)
        }
    }

    /// @notice Internal function to validate new owner address
    function _checkNewOwner(address account) internal view virtual {
        assembly ("memory-safe") {
            if iszero(shl(0x60, account)) {
                mstore(0x00, 0x54a56786) // InvalidNewOwner()
                revert(0x1c, 0x04)
            }
        }
    }

    /// @notice Internal function to check if caller is the owner
    function _checkOwner() internal view virtual {
        assembly ("memory-safe") {
            if iszero(eq(caller(), sload(OWNER_SLOT))) {
                mstore(0x00, 0x32b2baa3) // UnauthorizedAccount(address)
                mstore(0x20, caller())
                revert(0x1c, 0x24)
            }
        }
    }
}
