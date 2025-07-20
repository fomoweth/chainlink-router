// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Initializable
/// @notice Revision-based initializable mixin for upgradeable contracts with transient storage optimization
/// @dev Uses EIP-1153 transient storage for gas-efficient initialization state management
///		 Modified from https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol
/// @author fomoweth
abstract contract Initializable {
	/// @notice Thrown when initialization is attempted in invalid state
	/// @dev This occurs when:
	///      - Contract is already initialized with current or higher revision
	///      - Attempting to initialize during construction inappropriately
	///      - Disabling initializers when already initializing or disabled
	error InvalidInitialization();

	/// @notice Thrown when a function requires initializing state but contract is not initializing
	/// @dev Used by `onlyInitializing` modifier to restrict function access
	error NotInitializing();

	/// @notice Emitted when the contract is initialized to a specific revision
	/// @param version The revision number that was initialized
	event Initialized(uint64 version);

	/// @notice Pre-computed keccak256 hash of the {Initialized} event signature
	///	@dev keccak256("Initialized(uint64)")
	uint256 private constant INITIALIZED_EVENT_SIGNATURE =
		0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2;

	/// @notice Transient storage slot for `initializing` flag (EIP-1153)
	/// @dev keccak256(abi.encode(uint256(keccak256("Initializable.transient.initializing")) - 1)) & ~bytes32(uint256(0xff))
	uint256 private constant INITIALIZING_SLOT = 0xeca7f472cf9c3c8c4bc0b06bb5d562cccb95e77b81864611903b081e99f1f800;

	/// @notice Persistent storage slot for initialized revision number
	/// @dev keccak256(abi.encode(uint256(keccak256("Initializable.storage.initialized")) - 1)) & ~bytes32(uint256(0xff))
	uint256 private constant INITIALIZED_SLOT = 0xeb0c2ce5f191d27e756051385ba4f8f2e0c18127de8ff7207a5891e3b49bb400;

	/// @notice Maximum initialization revision number
	/// @dev Used as a sentinel value to permanently disable initializers
	uint64 private constant MAX_REVISION = (1 << 64) - 1;

	/// @notice Allows initialization to a specific revision which can be invoked at most once
	modifier initializer() {
		// Get the target revision from the implementing contract
		uint256 revision = _getRevision();
		bool isTopLevelCall;

		assembly ("memory-safe") {
			// Check if this is a top-level initialization call
			isTopLevelCall := iszero(tload(INITIALIZING_SLOT))

			// Validation logic:
			// 1. If this is a top-level call AND not in constructor AND revision <= current initialized version
			// 2. Then this is an invalid initialization attempt
			if and(
				and(isTopLevelCall, iszero(iszero(extcodesize(address())))),
				iszero(gt(revision, sload(INITIALIZED_SLOT)))
			) {
				mstore(0x00, 0xf92ee8a9) // InvalidInitialization()
				revert(0x1c, 0x04)
			}

			// If this is a top-level call, set up initialization state
			if isTopLevelCall {
				// Mark as `initializing` in transient storage
				tstore(INITIALIZING_SLOT, 0x01)
				// Store the new revision number in persistent storage
				// Mask ensures we only store 64 bits
				sstore(INITIALIZED_SLOT, and(revision, MAX_REVISION))
			}
		}
		_;
		assembly ("memory-safe") {
			// Clean up if this was a top-level call
			if isTopLevelCall {
				// Clear the `initializing` flag (automatic with transient storage, but explicit for clarity)
				tstore(INITIALIZING_SLOT, 0x00)
				// Store revision in memory for event data
				mstore(0x20, and(revision, MAX_REVISION))
				// Emit {Initialized} event
				log1(0x20, 0x20, INITIALIZED_EVENT_SIGNATURE)
			}
		}
	}

	/// @notice Restricts function access to initialization phase only
	/// @dev Functions with this modifier can only be called during initialization
	modifier onlyInitializing() {
		_checkInitializing();
		_;
	}

	/// @notice Permanently disables initializers to prevent future initialization
	function _disableInitializers() internal virtual {
		assembly ("memory-safe") {
			// Check for invalid states:
			// 1. Currently initializing (would break the current initialization)
			// 2. Already disabled (redundant call)
			if or(tload(INITIALIZING_SLOT), eq(sload(INITIALIZED_SLOT), MAX_REVISION)) {
				mstore(0x00, 0xf92ee8a9) // InvalidInitialization()
				revert(0x1c, 0x04)
			}

			// Set revision to maximum value to permanently disable
			sstore(INITIALIZED_SLOT, MAX_REVISION)
			// Emit {Initialized} event with max version to signal disabling
			mstore(0x20, MAX_REVISION)
			log1(0x20, 0x20, INITIALIZED_EVENT_SIGNATURE)
		}
	}

	/// @notice Internal function to verify contract is in initializing state
	function _checkInitializing() internal view virtual {
		assembly ("memory-safe") {
			if iszero(tload(INITIALIZING_SLOT)) {
				mstore(0x00, 0xd7e6bcf8) // NotInitializing()
				revert(0x1c, 0x04)
			}
		}
	}

	/// @notice Abstract function that must be implemented by derived contracts
	/// @dev This defines the target revision for initialization
	///		 Should return a constant value that increases with contract upgrades
	/// @return The revision number for this contract version
	function _getRevision() internal pure virtual returns (uint256);
}
