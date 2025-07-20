// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {BitMap} from "src/types/BitMap.sol";

contract BitMapTest is Test {
	function test_fuzz_set(BitMap bitmap, uint256 index) public pure {
		bitmap = bitmap.set(index);
		bool value = bitmap.get(index);
		bool isTrue;
		assembly ("memory-safe") {
			isTrue := iszero(iszero(value))
		}
		assertTrue(value);
		assertTrue(isTrue);
	}

	function test_fuzz_unset(BitMap bitmap, uint256 index) public pure {
		bitmap = bitmap.unset(index);
		bool value = bitmap.get(index);
		bool isFalse;
		assembly ("memory-safe") {
			isFalse := iszero(value)
		}
		assertFalse(value);
		assertTrue(isFalse);
	}

	function test_fuzz_setTo(BitMap bitmap, uint256 index) public pure {
		bool value = bitmap.get(index);
		bitmap = bitmap.setTo(index, !value);
		assertEq(bitmap.get(index), !value);
		bitmap = bitmap.setTo(index, value);
		assertEq(bitmap.get(index), value);
	}

	function test_fuzz_toggle(BitMap bitmap, uint256 index) public pure {
		bool value = bitmap.get(index);
		bitmap = bitmap.toggle(index);
		assertEq(bitmap.get(index), !value);
		bitmap = bitmap.toggle(index);
		assertEq(bitmap.get(index), value);
	}

	function test_count() public pure {
		unchecked {
			for (uint256 i = 1; i < 256; ++i) {
				assertEq(BitMap.wrap(uint256((1 << i) | 1)).count(), 2);
			}
		}
	}

	function test_fuzz_count(BitMap bitmap) public pure {
		uint256 c;
		unchecked {
			for (uint256 t = BitMap.unwrap(bitmap); t != 0; ++c) {
				t &= t - 1;
			}
		}
		assertEq(bitmap.count(), c);
	}

	function test_findFirstSet_revertsWhenZero() public {
		vm.expectRevert();
		BitMap.wrap(0).findFirstSet();
	}

	function test_findFirstSet_powersOfTwo() public pure {
		for (uint256 i = 1; i < 256; ++i) {
			assertEq(BitMap.wrap(1 << i).findFirstSet(), i);
		}
	}

	function test_fuzz_findFirstSet(BitMap bitmap) public pure {
		vm.assume(!bitmap.isZero());
		assertEq(bitmap.findFirstSet(), leastSignificantBitReference(BitMap.unwrap(bitmap)));
	}

	function test_findLastSet_revertsWhenZero() public {
		vm.expectRevert();
		BitMap.wrap(0).findLastSet();
	}

	function test_findLastSet_powersOfTwo() public pure {
		for (uint256 i = 1; i < 255; ++i) {
			assertEq(BitMap.wrap(1 << i).findLastSet(), i);
		}
	}

	function test_fuzz_findLastSet(BitMap bitmap) public pure {
		vm.assume(!bitmap.isZero());
		assertEq(bitmap.findLastSet(), mostSignificantBitReference(BitMap.unwrap(bitmap)));
	}

	function test_isZero() public pure {
		assertTrue(BitMap.wrap(0).isZero());
		assertFalse(BitMap.wrap(1).isZero());
	}

	function mostSignificantBitReference(uint256 x) private pure returns (uint256 i) {
		unchecked {
			while ((x >>= 1) > 0) {
				++i;
			}
		}
	}

	function leastSignificantBitReference(uint256 x) private pure returns (uint256 i) {
		unchecked {
			while ((x >> i) & 1 == 0) {
				++i;
			}
		}
	}
}
