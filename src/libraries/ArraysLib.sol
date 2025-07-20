// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title ArraysLib
/// @notice Optimized sorts and operations for sorted arrays
/// @dev Implementation from https://github.com/Vectorized/solady/blob/main/src/utils/LibSort.sol
library ArraysLib {
	/// @notice Sorts the array in-place with insertion sort
	/// @dev Faster on small and almost sorted arrays (32 or lesser elements)
	function insertionSort(uint256[] memory input) internal pure {
		assembly ("memory-safe") {
			let n := mload(input)
			mstore(input, 0x00)
			let h := add(input, shl(0x05, n))
			let w := not(0x1f)

			// prettier-ignore
			for { let i := add(input, 0x20) } 0x01 {} {
                i := add(i, 0x20)
                if gt(i, h) { break }

                let k := mload(i)
                let j := add(i, w)
                let v := mload(j)
                if iszero(gt(v, k)) { continue }

                for {} 0x01 {} {
                    mstore(add(j, 0x20), v)
                    j := add(j, w)
                    v := mload(j)
                    if iszero(gt(v, k)) { break }
                }

                mstore(add(j, 0x20), k)
            }

			mstore(input, n)
		}
	}

	/// @notice Sorts the array in-place with insertion sort
	function insertionSort(int256[] memory input) internal pure {
		_flip(input);
		insertionSort(toUint256s(input));
		_flip(input);
	}

	/// @notice Sorts the array in-place with insertion sort
	function insertionSort(address[] memory input) internal pure {
		insertionSort(toUint256s(input));
	}

	/// @notice Sorts the array in-place with insertion sort
	function insertionSort(bytes32[] memory input) internal pure {
		insertionSort(toUint256s(input));
	}

	/// @notice Sorts the array in-place with insertion sort
	function insertionSort(bytes4[] memory input) internal pure {
		insertionSort(toUint256s(input));
	}

	/// @notice Sorts the array in-place with insertion sort
	function insertionSort(uint8[] memory input) internal pure {
		insertionSort(toUint256s(input));
	}

	/// @notice Sorts the array in-place with intro-quicksort
	/// @dev Faster on larger arrays (more than 32 elements)
	function sort(uint256[] memory input) internal pure {
		// prettier-ignore
		assembly ("memory-safe") {
			function swap(v0, v1) -> r0, r1 {
				r1 := v0
				r0 := v1
			}

			function mswap(i, j) {
				let t := mload(i)
				mstore(i, mload(j))
				mstore(j, t)
			}

			function sortInner(w, l, h) {
				if iszero(gt(sub(h, l), 0x180)) {
                    let i := add(l, 0x20)
                    if iszero(lt(mload(l), mload(i))) { mswap(i, l) }

                    for {} 0x01 {} {
                        i := add(i, 0x20)
                        if gt(i, h) { break }

                        let k := mload(i)
                        let j := add(i, w)
                        let v := mload(j)
						if iszero(gt(v, k)) { continue }

						for {} 0x01 {} {
                            mstore(add(j, 0x20), v)
                            j := add(j, w)
                            v := mload(j)
                            if iszero(gt(v, k)) { break }
                        }
                        mstore(add(j, 0x20), k)
                    }
                    leave
                }

				let p := add(shl(0x05, shr(0x06, add(l, h))), and(0x1f, l))

				{
                    let e0 := mload(l)
                    let e1 := mload(p)
                    if iszero(lt(e0, e1)) { e0, e1 := swap(e0, e1) }
                    let e2 := mload(h)
                    if iszero(lt(e1, e2)) {
                        e1, e2 := swap(e1, e2)
                        if iszero(lt(e0, e1)) { e0, e1 := swap(e0, e1) }
                    }

                    mstore(h, e2)
                    mstore(p, e1)
                    mstore(l, e0)
                }

				{
                    let x := mload(p)
                    p := h
                    for { let i := l } 0x01 {} {
                        for {} 0x01 {} {
                            i := add(0x20, i)
                            if iszero(gt(x, mload(i))) { break }
                        }
                        let j := p
                        for {} 0x01 {} {
                            j := add(w, j)
                            if iszero(lt(x, mload(j))) { break }
                        }
                        p := j
                        if iszero(lt(i, p)) { break }
                        mswap(i, p)
                    }
                }

				if iszero(eq(add(p, 0x20), h)) { sortInner(w, add(p, 0x20), h) }
				if iszero(eq(p, l)) { sortInner(w, l, p) }
			}

			for { let n := mload(input) } iszero(lt(n, 2)) {} {
                let w := not(0x1f)
                let l := add(input, 0x20)
                let h := add(input, shl(0x05, n))
                let j := h
                for {} iszero(gt(mload(add(w, j)), mload(j))) {} { j := add(w, j) }
                if iszero(gt(j, l)) { break }

                for { j := h } iszero(lt(mload(add(w, j)), mload(j))) {} { j := add(w, j) }
                if iszero(gt(j, l)) {
                    for {} 0x01 {} {
                        let t := mload(l)
                        mstore(l, mload(h))
                        mstore(h, t)
                        h := add(w, h)
                        l := add(l, 0x20)
                        if iszero(lt(l, h)) { break }
                    }
                    break
                }

                mstore(input, 0x00)
                sortInner(w, l, h)
                mstore(input, n)
                break
            }
		}
	}

	/// @notice Sorts the array in-place with intro-quicksort
	function sort(int256[] memory input) internal pure {
		_flip(input);
		sort(toUint256s(input));
		_flip(input);
	}

	/// @notice Sorts the array in-place with intro-quicksort
	function sort(address[] memory input) internal pure {
		sort(toUint256s(input));
	}

	/// @notice Sorts the array in-place with intro-quicksort
	function sort(bytes32[] memory input) internal pure {
		sort(toUint256s(input));
	}

	/// @notice Sorts the array in-place with intro-quicksort
	function sort(bytes4[] memory input) internal pure {
		sort(toUint256s(input));
	}

	/// @notice Sorts the array in-place with intro-quicksort
	function sort(uint8[] memory input) internal pure {
		sort(toUint256s(input));
	}

	/// @notice Removes duplicates from a memory array sorted in ascending order
	function uniquifySorted(uint256[] memory input) internal pure {
		assembly ("memory-safe") {
			if iszero(lt(mload(input), 0x02)) {
				let x := add(input, 0x20)
				let y := add(input, 0x40)
				let guard := add(input, shl(0x05, add(mload(input), 0x01)))

				// prettier-ignore
				for {} 0x01 {} {
                    if iszero(eq(mload(x), mload(y))) {
                        x := add(x, 0x20)
                        mstore(x, mload(y))
                    }
                    y := add(y, 0x20)
                    if eq(y, guard) { break }
                }

				mstore(input, shr(0x05, sub(x, input)))
			}
		}
	}

	/// @notice Removes duplicates from a memory array sorted in ascending order
	function uniquifySorted(int256[] memory input) internal pure {
		uniquifySorted(toUint256s(input));
	}

	/// @notice Removes duplicates from a memory array sorted in ascending order
	function uniquifySorted(address[] memory input) internal pure {
		uniquifySorted(toUint256s(input));
	}

	/// @notice Removes duplicates from a memory array sorted in ascending order
	function uniquifySorted(bytes32[] memory input) internal pure {
		uniquifySorted(toUint256s(input));
	}

	/// @notice Removes duplicates from a memory array sorted in ascending order
	function uniquifySorted(bytes4[] memory input) internal pure {
		uniquifySorted(toUint256s(input));
	}

	/// @notice Removes duplicates from a memory array sorted in ascending order
	function uniquifySorted(uint8[] memory input) internal pure {
		uniquifySorted(toUint256s(input));
	}

	/// @notice Returns whether the array contains `needle`, and the index of `needle`
	function searchSorted(uint256[] memory input, uint256 needle) internal pure returns (bool found, uint256 index) {
		(found, index) = _searchSorted(input, needle, 0);
	}

	/// @notice Returns whether the array contains `needle`, and the index of `needle`
	function searchSorted(int256[] memory input, int256 needle) internal pure returns (bool found, uint256 index) {
		(found, index) = _searchSorted(toUint256s(input), uint256(needle), 1 << 255);
	}

	/// @notice Returns whether the array contains `needle`, and the index of `needle`
	function searchSorted(address[] memory input, address needle) internal pure returns (bool found, uint256 index) {
		(found, index) = _searchSorted(toUint256s(input), uint160(needle), 0);
	}

	/// @notice Returns whether the array contains `needle`, and the index of `needle`
	function searchSorted(bytes32[] memory input, bytes32 needle) internal pure returns (bool found, uint256 index) {
		(found, index) = _searchSorted(toUint256s(input), uint256(needle), 0);
	}

	/// @notice Returns whether the array contains `needle`, and the index of `needle`
	function searchSorted(bytes4[] memory input, bytes4 needle) internal pure returns (bool found, uint256 index) {
		(found, index) = _searchSorted(toUint256s(input), uint256((bytes32(needle))), 0);
	}

	/// @notice Returns whether the array contains `needle`, and the index of `needle`
	function searchSorted(uint8[] memory input, uint8 needle) internal pure returns (bool found, uint256 index) {
		(found, index) = _searchSorted(toUint256s(input), uint256(needle), 0);
	}

	/// @notice Returns whether the array contains `needle`
	function inSorted(uint256[] memory input, uint256 needle) internal pure returns (bool found) {
		(found, ) = searchSorted(input, needle);
	}

	/// @notice Returns whether the array contains `needle`
	function inSorted(int256[] memory input, int256 needle) internal pure returns (bool found) {
		(found, ) = searchSorted(input, needle);
	}

	/// @notice Returns whether the array contains `needle`
	function inSorted(address[] memory input, address needle) internal pure returns (bool found) {
		(found, ) = searchSorted(input, needle);
	}

	/// @notice Returns whether the array contains `needle`
	function inSorted(bytes32[] memory input, bytes32 needle) internal pure returns (bool found) {
		(found, ) = searchSorted(input, needle);
	}

	/// @notice Returns whether the array contains `needle`
	function inSorted(bytes4[] memory input, bytes4 needle) internal pure returns (bool found) {
		(found, ) = searchSorted(input, needle);
	}

	/// @notice Returns whether the array contains `needle`
	function inSorted(uint8[] memory input, uint8 needle) internal pure returns (bool found) {
		(found, ) = searchSorted(input, needle);
	}

	/// @notice Reverses the array in-place
	function reverse(uint256[] memory input) internal pure {
		assembly ("memory-safe") {
			if iszero(lt(mload(input), 0x02)) {
				let s := 0x20
				let w := not(0x1f)
				let h := add(input, shl(0x05, mload(input)))

				// prettier-ignore
				for { input := add(input, s) } 0x01 {} {
                    let t := mload(input)
                    mstore(input, mload(h))
                    mstore(h, t)
                    h := add(h, w)
                    input := add(input, s)
                    if iszero(lt(input, h)) { break }
                }
			}
		}
	}

	/// @notice Reverses the array in-place
	function reverse(int256[] memory input) internal pure {
		reverse(toUint256s(input));
	}

	/// @notice Reverses the array in-place
	function reverse(address[] memory input) internal pure {
		reverse(toUint256s(input));
	}

	/// @notice Reverses the array in-place
	function reverse(bytes32[] memory input) internal pure {
		reverse(toUint256s(input));
	}

	/// @notice Reverses the array in-place
	function reverse(bytes4[] memory input) internal pure {
		reverse(toUint256s(input));
	}

	/// @notice Reverses the array in-place
	function reverse(uint8[] memory input) internal pure {
		reverse(toUint256s(input));
	}

	/// @notice Returns a copy of the array
	function copy(uint256[] memory input) internal pure returns (uint256[] memory output) {
		assembly ("memory-safe") {
			output := mload(0x40)
			let ptr := output
			let guard := add(add(ptr, 0x20), shl(0x05, mload(input)))

			// prettier-ignore
			for { let offset := sub(input, output) } 0x01 {} {
                mstore(ptr, mload(add(ptr, offset)))
                ptr := add(ptr, 0x20)
                if eq(ptr, guard) { break }
            }

			mstore(0x40, ptr)
		}
	}

	/// @notice Returns a copy of the array
	function copy(int256[] memory input) internal pure returns (int256[] memory output) {
		return toInt256s(copy(toUint256s(input)));
	}

	/// @notice Returns a copy of the array
	function copy(address[] memory input) internal pure returns (address[] memory output) {
		return toAddresses(copy(toUint256s(input)));
	}

	/// @notice Returns a copy of the array
	function copy(bytes32[] memory input) internal pure returns (bytes32[] memory output) {
		return toBytes32s(copy(toUint256s(input)));
	}

	/// @notice Returns a copy of the array
	function copy(bytes4[] memory input) internal pure returns (bytes4[] memory output) {
		return toBytes4s(copy(toUint256s(input)));
	}

	/// @notice Returns a copy of the array
	function copy(uint8[] memory input) internal pure returns (uint8[] memory output) {
		return toUint8s(copy(toUint256s(input)));
	}

	/// @notice Returns whether the array is sorted in ascending order
	function isSorted(uint256[] memory input) internal pure returns (bool output) {
		assembly ("memory-safe") {
			output := 0x01
			if iszero(lt(mload(input), 0x02)) {
				let guard := add(input, shl(0x05, mload(input)))

				// prettier-ignore
				for { input := add(input, 0x20) } 0x01 {} {
                    let p := mload(input)
                    input := add(input, 0x20)
                    output := iszero(gt(p, mload(input)))
                    if iszero(mul(output, xor(input, guard))) { break }
                }
			}
		}
	}

	/// @notice Returns whether the array is sorted in ascending order
	function isSorted(int256[] memory input) internal pure returns (bool output) {
		assembly ("memory-safe") {
			output := 0x01
			if iszero(lt(mload(input), 0x02)) {
				let guard := add(input, shl(0x05, mload(input)))

				// prettier-ignore
				for { input := add(input, 0x20) } 0x01 {} {
                    let p := mload(input)
                    input := add(input, 0x20)
                    output := iszero(sgt(p, mload(input)))
                    if iszero(mul(output, xor(input, guard))) { break }
                }
			}
		}
	}

	/// @notice Returns whether the array is sorted in ascending order
	function isSorted(address[] memory input) internal pure returns (bool output) {
		return isSorted(toUint256s(input));
	}

	/// @notice Returns whether the array is sorted in ascending order
	function isSorted(bytes32[] memory input) internal pure returns (bool output) {
		return isSorted(toUint256s(input));
	}

	/// @notice Returns whether the array is sorted in ascending order
	function isSorted(bytes4[] memory input) internal pure returns (bool output) {
		return isSorted(toUint256s(input));
	}

	/// @notice Returns whether the array is sorted in ascending order
	function isSorted(uint8[] memory input) internal pure returns (bool output) {
		return isSorted(toUint256s(input));
	}

	/// @notice Returns whether the array is sorted in strictly ascending order without duplicates
	function isSortedAndUniquified(uint256[] memory input) internal pure returns (bool output) {
		assembly ("memory-safe") {
			output := 0x01
			if iszero(lt(mload(input), 0x02)) {
				let guard := add(input, shl(0x05, mload(input)))

				// prettier-ignore
				for { input := add(input, 0x20) } 0x01 {} {
                    let p := mload(input)
                    input := add(input, 0x20)
                    output := lt(p, mload(input))
                    if iszero(mul(output, xor(input, guard))) { break }
                }
			}
		}
	}

	/// @notice Returns whether the array is sorted in strictly ascending order without duplicates
	function isSortedAndUniquified(int256[] memory input) internal pure returns (bool output) {
		assembly ("memory-safe") {
			output := 0x01
			if iszero(lt(mload(input), 0x02)) {
				let guard := add(input, shl(0x05, mload(input)))

				// prettier-ignore
				for { input := add(input, 0x20) } 0x01 {} {
                    let p := mload(input)
                    input := add(input, 0x20)
                    output := slt(p, mload(input))
                    if iszero(mul(output, xor(input, guard))) { break }
                }
			}
		}
	}

	/// @notice Returns whether the array is sorted in strictly ascending order without duplicates
	function isSortedAndUniquified(address[] memory input) internal pure returns (bool output) {
		return isSortedAndUniquified(toUint256s(input));
	}

	/// @notice Returns whether the array is sorted in strictly ascending order without duplicates
	function isSortedAndUniquified(bytes32[] memory input) internal pure returns (bool output) {
		return isSortedAndUniquified(toUint256s(input));
	}

	/// @notice Returns whether the array is sorted in strictly ascending order without duplicates
	function isSortedAndUniquified(bytes4[] memory input) internal pure returns (bool output) {
		return isSortedAndUniquified(toUint256s(input));
	}

	/// @notice Returns whether the array is sorted in strictly ascending order without duplicates
	function isSortedAndUniquified(uint8[] memory input) internal pure returns (bool output) {
		return isSortedAndUniquified(toUint256s(input));
	}

	/// @notice Returns the sorted set difference of given arrays
	function difference(uint256[] memory x, uint256[] memory y) internal pure returns (uint256[] memory z) {
		return _difference(x, y, 0);
	}

	/// @notice Returns the sorted set difference of given arrays
	function difference(int256[] memory x, int256[] memory y) internal pure returns (int256[] memory z) {
		return toInt256s(_difference(toUint256s(x), toUint256s(y), 1 << 255));
	}

	/// @notice Returns the sorted set difference of given arrays
	function difference(address[] memory x, address[] memory y) internal pure returns (address[] memory z) {
		return toAddresses(_difference(toUint256s(x), toUint256s(y), 0));
	}

	/// @notice Returns the sorted set difference of given arrays
	function difference(bytes32[] memory x, bytes32[] memory y) internal pure returns (bytes32[] memory z) {
		return toBytes32s(_difference(toUint256s(x), toUint256s(y), 0));
	}

	/// @notice Returns the sorted set difference of given arrays
	function difference(bytes4[] memory x, bytes4[] memory y) internal pure returns (bytes4[] memory z) {
		return toBytes4s(_difference(toUint256s(x), toUint256s(y), 0));
	}

	/// @notice Returns the sorted set difference of given arrays
	function difference(uint8[] memory x, uint8[] memory y) internal pure returns (uint8[] memory z) {
		return toUint8s(_difference(toUint256s(x), toUint256s(y), 0));
	}

	/// @notice Returns the sorted set intersection between given arrays
	function intersection(uint256[] memory x, uint256[] memory y) internal pure returns (uint256[] memory z) {
		return _intersection(x, y, 0);
	}

	/// @notice Returns the sorted set intersection between given arrays
	function intersection(int256[] memory x, int256[] memory y) internal pure returns (int256[] memory z) {
		return toInt256s(_intersection(toUint256s(x), toUint256s(y), 1 << 255));
	}

	/// @notice Returns the sorted set intersection between given arrays
	function intersection(address[] memory x, address[] memory y) internal pure returns (address[] memory z) {
		return toAddresses(_intersection(toUint256s(x), toUint256s(y), 0));
	}

	/// @notice Returns the sorted set intersection between given arrays
	function intersection(bytes32[] memory x, bytes32[] memory y) internal pure returns (bytes32[] memory z) {
		return toBytes32s(_intersection(toUint256s(x), toUint256s(y), 0));
	}

	/// @notice Returns the sorted set intersection between given arrays
	function intersection(bytes4[] memory x, bytes4[] memory y) internal pure returns (bytes4[] memory z) {
		return toBytes4s(_intersection(toUint256s(x), toUint256s(y), 0));
	}

	/// @notice Returns the sorted set intersection between given arrays
	function intersection(uint8[] memory x, uint8[] memory y) internal pure returns (uint8[] memory z) {
		return toUint8s(_intersection(toUint256s(x), toUint256s(y), 0));
	}

	/// @notice Returns the sorted set union of given arrays
	function union(uint256[] memory x, uint256[] memory y) internal pure returns (uint256[] memory z) {
		return _union(x, y, 0);
	}

	/// @notice Returns the sorted set union of given arrays
	function union(int256[] memory x, int256[] memory y) internal pure returns (int256[] memory z) {
		return toInt256s(_union(toUint256s(x), toUint256s(y), 1 << 255));
	}

	/// @notice Returns the sorted set union of given arrays
	function union(address[] memory x, address[] memory y) internal pure returns (address[] memory z) {
		return toAddresses(_union(toUint256s(x), toUint256s(y), 0));
	}

	/// @notice Returns the sorted set union of given arrays
	function union(bytes32[] memory x, bytes32[] memory y) internal pure returns (bytes32[] memory z) {
		return toBytes32s(_union(toUint256s(x), toUint256s(y), 0));
	}

	/// @notice Returns the sorted set union of given arrays
	function union(bytes4[] memory x, bytes4[] memory y) internal pure returns (bytes4[] memory z) {
		return toBytes4s(_union(toUint256s(x), toUint256s(y), 0));
	}

	/// @notice Returns the sorted set union of given arrays
	function union(uint8[] memory x, uint8[] memory y) internal pure returns (uint8[] memory z) {
		return toUint8s(_union(toUint256s(x), toUint256s(y), 0));
	}

	/// @notice Returns if the array has any duplicate
	function hasDuplicate(uint256[] memory input) internal pure returns (bool output) {
		assembly ("memory-safe") {
			function p(i, x) -> z {
				z := or(shr(i, x), x)
			}

			let n := mload(input)

			// prettier-ignore
			if iszero(lt(n, 0x02)) {
                let m := mload(0x40)
                let w := not(0x1f)
                let c := and(w, p(16, p(8, p(4, p(2, p(1, mul(0x30, n)))))))
                calldatacopy(m, calldatasize(), add(0x20, c))
                for { let i := add(input, shl(0x05, n)) } 0x01 {} {
                    let r := mulmod(mload(i), 0x100000000000000000000000000000051, not(0xbc))
                    for {} 0x01 { r := add(0x20, r) } {
                        let o := add(m, and(r, c))
                        if iszero(mload(o)) {
                            mstore(o, i)
                            break
                        }
                        if eq(mload(mload(o)), mload(i)) {
                            output := 0x01
                            i := input
                            break
                        }
                    }
                    i := add(i, w)
                    if iszero(lt(input, i)) { break }
                }
                if shr(0x1f, n) { invalid() }
            }
		}
	}

	/// @notice Returns if the array has any duplicate
	function hasDuplicate(int256[] memory input) internal pure returns (bool output) {
		return hasDuplicate(toUint256s(input));
	}

	/// @notice Returns if the array has any duplicate
	function hasDuplicate(address[] memory input) internal pure returns (bool output) {
		return hasDuplicate(toUint256s(input));
	}

	/// @notice Returns if the array has any duplicate
	function hasDuplicate(bytes32[] memory input) internal pure returns (bool output) {
		return hasDuplicate(toUint256s(input));
	}

	/// @notice Returns if the array has any duplicate
	function hasDuplicate(bytes4[] memory input) internal pure returns (bool output) {
		return hasDuplicate(toUint256s(input));
	}

	/// @notice Returns if the array has any duplicate
	function hasDuplicate(uint8[] memory input) internal pure returns (bool output) {
		return hasDuplicate(toUint256s(input));
	}

	/// @notice Cleans the upper 96 bits of the addresses
	function clean(address[] memory input) internal pure {
		assembly ("memory-safe") {
			let mask := shr(0x60, not(0x00))

			// prettier-ignore
			for { let guard := add(input, shl(0x05, mload(input))) } iszero(eq(input, guard)) {} {
                input := add(input, 0x20)
                mstore(input, and(mload(input), mask))
            }
		}
	}

	/// @notice Reinterpret cast to an uint256 array
	function toUint256s(int256[] memory input) internal pure returns (uint256[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	/// @notice Reinterpret cast to an int array
	function toInt256s(uint256[] memory input) internal pure returns (int256[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	/// @notice Reinterpret cast to an uint256 array
	function toUint256s(address[] memory input) internal pure returns (uint256[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	/// @notice Reinterpret cast to an address array
	function toAddresses(uint256[] memory input) internal pure returns (address[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	/// @notice Reinterpret cast to an uint256 array
	function toUint256s(bytes32[] memory input) internal pure returns (uint256[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	/// @notice Reinterpret cast to an bytes32 array
	function toBytes32s(uint256[] memory input) internal pure returns (bytes32[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	/// @notice Reinterpret cast to an uint256 array
	function toUint256s(bytes4[] memory input) internal pure returns (uint256[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	/// @notice Reinterpret cast to an bytes4 array
	function toBytes4s(uint256[] memory input) internal pure returns (bytes4[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	/// @notice Reinterpret cast to an uint256 array
	function toUint256s(uint8[] memory input) internal pure returns (uint256[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	/// @notice Reinterpret cast to an uint8 array
	function toUint8s(uint256[] memory input) internal pure returns (uint8[] memory output) {
		assembly ("memory-safe") {
			output := input
		}
	}

	/// @notice Converts an array of signed integers to unsigned integers suitable for sorting
	function _flip(int256[] memory input) private pure {
		assembly ("memory-safe") {
			let w := shl(0xff, 0x01)

			// prettier-ignore
			for { let guard := add(input, shl(0x05, mload(input))) } iszero(eq(input, guard)) {} {
                input := add(input, 0x20)
                mstore(input, add(mload(input), w))
            }
		}
	}

	/// @notice Returns whether the array contains `needle`, and the index of `needle`
	function _searchSorted(
		uint256[] memory input,
		uint256 needle,
		uint256 signed
	) private pure returns (bool found, uint256 index) {
		assembly ("memory-safe") {
			let w := not(0x00)
			let l := 0x01
			let h := mload(input)
			let t := 0x00

			// prettier-ignore
			for { needle := add(signed, needle) } 0x01 {} {
                index := shr(0x01, add(l, h))
                t := add(signed, mload(add(input, shl(0x05, index))))

                if or(gt(l, h), eq(t, needle)) { break }

                if iszero(gt(needle, t)) {
                    h := add(index, w)
                    continue
                }
                l := add(index, 0x01)
            }

			found := eq(t, needle)
			t := iszero(iszero(index))
			index := mul(add(index, w), t)
			found := and(found, t)
		}
	}

	/// @notice Returns the sorted set difference of given arrays
	/// @dev Behavior is undefined if inputs are not sorted and uniquified.
	function _difference(
		uint256[] memory x,
		uint256[] memory y,
		uint256 signed
	) private pure returns (uint256[] memory z) {
		// prettier-ignore
		assembly ("memory-safe") {
            let s := 0x20
            let xGuard := add(x, shl(0x05, mload(x)))
            let yGuard := add(y, shl(0x05, mload(y)))
            z := mload(0x40)
            x := add(x, s)
            y := add(y, s)
            let k := z

            for {} iszero(or(gt(x, xGuard), gt(y, yGuard))) {} {
                let u := mload(x)
                let v := mload(y)
                if iszero(xor(u, v)) {
                    x := add(x, s)
                    y := add(y, s)
                    continue
                }
                if iszero(lt(add(u, signed), add(v, signed))) {
                    y := add(y, s)
                    continue
                }
                k := add(k, s)
                mstore(k, u)
                x := add(x, s)
            }

            for {} iszero(gt(x, xGuard)) {} {
                k := add(k, s)
                mstore(k, mload(x))
                x := add(x, s)
            }

            mstore(z, shr(0x05, sub(k, z)))
            mstore(0x40, add(k, s))
        }
	}

	/// @notice Returns the sorted set intersection between arrays
	/// @dev Behavior is undefined if inputs are not sorted and uniquified
	function _intersection(
		uint256[] memory x,
		uint256[] memory y,
		uint256 signed
	) private pure returns (uint256[] memory z) {
		assembly ("memory-safe") {
			let s := 0x20
			let xGuard := add(x, shl(0x05, mload(x)))
			let yGuard := add(y, shl(0x05, mload(y)))
			z := mload(0x40)
			x := add(x, s)
			y := add(y, s)
			let k := z

			// prettier-ignore
			for {} iszero(or(gt(x, xGuard), gt(y, yGuard))) {} {
                let u := mload(x)
                let v := mload(y)

                if iszero(xor(u, v)) {
                    k := add(k, s)
                    mstore(k, u)
                    x := add(x, s)
                    y := add(y, s)
                    continue
                }

                if iszero(lt(add(u, signed), add(v, signed))) {
                    y := add(y, s)
                    continue
                }

                x := add(x, s)
            }

			mstore(z, shr(0x05, sub(k, z)))
			mstore(0x40, add(k, s))
		}
	}

	/// @notice Returns the sorted set union of given arrays
	/// @dev Behavior is undefined if inputs are not sorted and uniquified
	function _union(uint256[] memory x, uint256[] memory y, uint256 signed) private pure returns (uint256[] memory z) {
		// prettier-ignore
		assembly ("memory-safe") {
            let s := 0x20
            let xGuard := add(x, shl(0x05, mload(x)))
            let yGuard := add(y, shl(0x05, mload(y)))
            z := mload(0x40)
            x := add(x, s)
            y := add(y, s)
            let k := z

            for {} iszero(or(gt(x, xGuard), gt(y, yGuard))) {} {
                let u := mload(x)
                let v := mload(y)

                if iszero(xor(u, v)) {
                    k := add(k, s)
                    mstore(k, u)
                    x := add(x, s)
                    y := add(y, s)
                    continue
                }

                if iszero(lt(add(u, signed), add(v, signed))) {
                    k := add(k, s)
                    mstore(k, v)
                    y := add(y, s)
                    continue
                }

                k := add(k, s)
                mstore(k, u)
                x := add(x, s)
            }

            for {} iszero(gt(x, xGuard)) {} {
                k := add(k, s)
                mstore(k, mload(x))
                x := add(x, s)
            }

            for {} iszero(gt(y, yGuard)) {} {
                k := add(k, s)
                mstore(k, mload(y))
                y := add(y, s)
            }

            mstore(z, shr(0x05, sub(k, z)))
            mstore(0x40, add(k, s))
        }
	}
}
