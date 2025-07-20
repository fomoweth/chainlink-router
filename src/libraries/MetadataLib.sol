// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title MetadataLib
/// @notice can produce symbols and decimals from inconsistent or absent ERC20 implementations
/// @dev Implementation from https://github.com/Vectorized/solady/blob/main/src/utils/MetadataReaderLib.sol
library MetadataLib {
	/// @dev Default gas stipend for contract reads. High enough for most practical use cases
	/// (able to SLOAD about 1000 bytes of data), but low enough to prevent griefing
	uint256 internal constant GAS_STIPEND = 100000;

	/// @dev Default string byte length limit
	uint256 internal constant STRING_LIMIT = 1000;

	function name(address target) internal view returns (string memory) {
		return _readString(target, _ptr(0x06fdde03), STRING_LIMIT, GAS_STIPEND);
	}

	function name(address target, uint256 limit) internal view returns (string memory) {
		return _readString(target, _ptr(0x06fdde03), limit, GAS_STIPEND);
	}

	function name(address target, uint256 limit, uint256 gasStipend) internal view returns (string memory) {
		return _readString(target, _ptr(0x06fdde03), limit, gasStipend);
	}

	function symbol(address target) internal view returns (string memory) {
		return _readString(target, _ptr(0x95d89b41), STRING_LIMIT, GAS_STIPEND);
	}

	function symbol(address target, uint256 limit) internal view returns (string memory) {
		return _readString(target, _ptr(0x95d89b41), limit, GAS_STIPEND);
	}

	function symbol(address target, uint256 limit, uint256 gasStipend) internal view returns (string memory) {
		return _readString(target, _ptr(0x95d89b41), limit, gasStipend);
	}

	function readString(address target, bytes memory data) internal view returns (string memory) {
		return _readString(target, _ptr(data), STRING_LIMIT, GAS_STIPEND);
	}

	function readString(address target, bytes memory data, uint256 limit) internal view returns (string memory) {
		return _readString(target, _ptr(data), limit, GAS_STIPEND);
	}

	function readString(
		address target,
		bytes memory data,
		uint256 limit,
		uint256 gasStipend
	) internal view returns (string memory) {
		return _readString(target, _ptr(data), limit, gasStipend);
	}

	function decimals(address target) internal view returns (uint8 unit) {
		return decimals(target, GAS_STIPEND);
	}

	function decimals(address target, uint256 gasStipend) internal view returns (uint8 unit) {
		// 0x313ce567: decimals()
		unit = uint8(_readUint(target, _ptr(0x313ce567), gasStipend));
		// 0x2e0f2625: DECIMALS()
		if (unit == 0) unit = uint8(_readUint(target, _ptr(0x2e0f2625), gasStipend));
	}

	function readUint(address target, bytes memory data) internal view returns (uint256) {
		return _readUint(target, _ptr(data), GAS_STIPEND);
	}

	function readUint(address target, bytes memory data, uint256 gasStipend) internal view returns (uint256) {
		return _readUint(target, _ptr(data), gasStipend);
	}

	function _readString(
		address target,
		bytes32 ptr,
		uint256 limit,
		uint256 gasStipend
	) private view returns (string memory result) {
		assembly ("memory-safe") {
			function min(x_, y_) -> _z {
				_z := xor(x_, mul(xor(x_, y_), lt(y_, x_)))
			}

			// prettier-ignore
			for {} staticcall(gasStipend, target, add(ptr, 0x20), mload(ptr), 0x00, 0x20) {} {
				let m := mload(0x40)
				let s := add(0x20, m)

				if iszero(lt(returndatasize(), 0x40)) {
					let o := mload(0x00)

					if iszero(gt(o, sub(returndatasize(), 0x20))) {
						returndatacopy(m, o, 0x20)

						if iszero(gt(mload(m), sub(returndatasize(), add(o, 0x20)))) {
							let n := min(mload(m), limit)
							mstore(m, n)
							returndatacopy(s, add(o, 0x20), n)
							mstore(add(s, n), 0)
							mstore(0x40, add(0x20, add(s, n)))
							result := m
							break
						}
					}
				}

				let n := min(returndatasize(), limit)
				returndatacopy(s, 0, n)
				mstore8(add(s, n), 0)
				let i := s
				for {} byte(0, mload(i)) { i := add(i, 1) } {}
				mstore(m, sub(i, s))
				mstore(i, 0)
				mstore(0x40, add(0x20, i))
				result := m
				break
			}
		}
	}

	function _readUint(address target, bytes32 ptr, uint256 gasStipend) private view returns (uint256 result) {
		assembly ("memory-safe") {
			result := mul(
				mload(0x20),
				and(gt(returndatasize(), 0x1f), staticcall(gasStipend, target, add(ptr, 0x20), mload(ptr), 0x20, 0x20))
			)
		}
	}

	function _ptr(uint256 selector) private pure returns (bytes32 result) {
		assembly ("memory-safe") {
			mstore(0x04, selector)
			mstore(result, 0x04)
		}
	}

	function _ptr(bytes memory data) private pure returns (bytes32 result) {
		assembly ("memory-safe") {
			result := data
		}
	}
}
