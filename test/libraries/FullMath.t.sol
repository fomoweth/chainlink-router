// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Math} from "@openzeppelin/utils/math/Math.sol";
import {FullMath} from "src/libraries/FullMath.sol";

contract FullMathTest is Test {
	function test_fuzz_mulDiv(uint256 x, uint256 y, uint256 d) public pure {
		vm.assume(d > 0);
		(uint256 xyHi, ) = Math.mul512(x, y);
		vm.assume(xyHi < d);
		assertEq(FullMath.mulDiv(x, y, d), Math.mulDiv(x, y, d));
	}

	function test_fuzz_mulDivRoundingUp(uint256 x, uint256 y, uint256 d) public pure {
		vm.assume(d > 0);
		(uint256 xyHi, ) = Math.mul512(x, y);
		vm.assume(xyHi < d);
		assertEq(FullMath.mulDivRoundingUp(x, y, d), Math.mulDiv(x, y, d, Math.Rounding.Ceil));
	}
}
