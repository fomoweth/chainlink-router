// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

type BitMap is uint256;

using {eq as ==, neq as !=, gt as >, gte as >=, lt as <, lte as <=, and as &, or as |, xor as ^, not as ~} for BitMap global;
using BitMapLibrary for BitMap global;

function eq(BitMap x, BitMap y) pure returns (bool z) {
	assembly ("memory-safe") {
		z := eq(x, y)
	}
}

function neq(BitMap x, BitMap y) pure returns (bool z) {
	assembly ("memory-safe") {
		z := iszero(eq(x, y))
	}
}

function gt(BitMap x, BitMap y) pure returns (bool z) {
	assembly ("memory-safe") {
		z := gt(x, y)
	}
}

function gte(BitMap x, BitMap y) pure returns (bool z) {
	assembly ("memory-safe") {
		z := iszero(lt(x, y))
	}
}

function lt(BitMap x, BitMap y) pure returns (bool z) {
	assembly ("memory-safe") {
		z := lt(x, y)
	}
}

function lte(BitMap x, BitMap y) pure returns (bool z) {
	assembly ("memory-safe") {
		z := iszero(gt(x, y))
	}
}

function and(BitMap x, BitMap y) pure returns (BitMap z) {
	assembly ("memory-safe") {
		z := and(x, y)
	}
}

function or(BitMap x, BitMap y) pure returns (BitMap z) {
	assembly ("memory-safe") {
		z := or(x, y)
	}
}

function xor(BitMap x, BitMap y) pure returns (BitMap z) {
	assembly ("memory-safe") {
		z := xor(x, y)
	}
}

function not(BitMap x) pure returns (BitMap z) {
	assembly ("memory-safe") {
		z := not(x)
	}
}

/// @title BitMapLibrary
/// @notice Bit-level manipulation utilities for a 256-bit BitMap
/// @author fomoweth
library BitMapLibrary {
	/// @notice Sets the bit at a given index to 1
	/// @param x The input bitmap
	/// @param index Bit position to set
	/// @return z The updated bitmap
	function set(BitMap x, uint256 index) internal pure returns (BitMap z) {
		assembly ("memory-safe") {
			z := or(x, shl(and(index, 0xff), 1))
		}
	}

	/// @notice Clears the bit at a given index (set to 0)
	/// @param x The input bitmap
	/// @param index Bit position to unset
	/// @return z The updated bitmap
	function unset(BitMap x, uint256 index) internal pure returns (BitMap z) {
		assembly ("memory-safe") {
			z := and(x, not(shl(and(index, 0xff), 1)))
		}
	}

	/// @notice Sets a bit at the specified index to a specific value
	/// @param x The input bitmap
	/// @param index Bit position to set or unset (0~255)
	/// @param value Whether to set (true) or unset (false)
	/// @return z The updated bitmap
	function setTo(BitMap x, uint256 index, bool value) internal pure returns (BitMap z) {
		assembly ("memory-safe") {
			let mask := and(index, 0xff)
			z := or(and(x, not(shl(mask, 1))), shl(mask, iszero(iszero(value))))
		}
	}

	/// @notice Toggles the bit at a given index (flip 1 ↔ 0)
	/// @param x The input bitmap
	/// @param index Bit position to toggle
	/// @return z The updated bitmap
	function toggle(BitMap x, uint256 index) internal pure returns (BitMap z) {
		assembly ("memory-safe") {
			let mask := and(index, 0xff)
			z := or(and(x, not(shl(mask, 1))), shl(mask, iszero(and(x, shl(mask, 1)))))
		}
	}

	/// @notice Reads the bit at a given index
	/// @param x The input bitmap
	/// @param index Bit position to check
	/// @return z True if bit is set, false otherwise
	function get(BitMap x, uint256 index) internal pure returns (bool z) {
		assembly ("memory-safe") {
			z := and(x, shl(and(index, 0xff), 1))
		}
	}

	/// @notice Counts the number of bits set to 1 in the bitmap
	/// @param x The input bitmap
	/// @return z Number of bits set (0~256)
	function count(BitMap x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			z := sub(x, and(shr(1, x), 0x5555555555555555555555555555555555555555555555555555555555555555))
			z := add(and(z, 0x3333333333333333333333333333333333333333333333333333333333333333),
				and(shr(2, z), 0x3333333333333333333333333333333333333333333333333333333333333333))
			z := and(add(z, shr(4, z)), 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F)
			z := or(shl(8, eq(x, not(0))), shr(248, mul(z, 0x101010101010101010101010101010101010101010101010101010101010101)))
		}
	}

	/// @notice Finds the index of the least significant bit set to 1, reverting if `x` is empty
	/// @param x The input bitmap
	/// @return z The index (0~255) of the first set bit
	function findFirstSet(BitMap x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if iszero(x) { revert(0, 0) }
			x := and(x, sub(0, x))
            z := shl(5, shr(252, shl(shl(2, shr(250, mul(x,
                0xb6db6db6ddddddddd34d34d349249249210842108c6318c639ce739cffffffff))),
                0x8040405543005266443200005020610674053026020000107506200176117077)))
            z := or(z, byte(and(div(0xd76453e0, shr(z, x)), 0x1f),
                0x001f0d1e100c1d070f090b19131c1706010e11080a1a141802121b1503160405))
		}
	}

	/// @notice Finds the index of the most significant bit set to 1, reverting if `x` is empty
	/// @param x The input bitmap
	/// @return z The index (0~255) of the last set bit
	function findLastSet(BitMap x) internal pure returns (uint256 z) {
		assembly ("memory-safe") {
			if iszero(x) { revert(0, 0) }
			z := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
			z := or(z, shl(6, lt(0xffffffffffffffff, shr(z, x))))
			z := or(z, shl(5, lt(0xffffffff, shr(z, x))))
			z := or(z, shl(4, lt(0xffff, shr(z, x))))
			z := or(z, shl(3, lt(0xff, shr(z, x))))
			z := or(z, byte(and(0x1f, shr(shr(z, x), 0x8421084210842108cc6318c6db6d54be)),
                0x0706060506020504060203020504030106050205030304010505030400000000))
		}
	}

	/// @notice Checks if the bitmap is empty (all bits unset)
	/// @param x The input bitmap
	/// @return z True if x == 0, false otherwise
	function isZero(BitMap x) internal pure returns (bool z) {
		assembly ("memory-safe") {
			z := iszero(x)
		}
	}
}
