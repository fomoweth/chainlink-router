// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {PriceMath} from "src/libraries/PriceMath.sol";

contract PriceMathTest is Test {
	function test_normalize_sameDecimals() public pure {
		uint256 price = 1000e18; // 1000 with 18 decimals
		uint256 result = PriceMath.normalize(price, 18, 18);
		assertEq(result, price);
	}

	function test_normalize_scaleDown() public pure {
		uint256 price = 1000e18; // 1000 with 18 decimals
		uint256 expected = 1000e6; // 1000 with 6 decimals
		uint256 result = PriceMath.normalize(price, 18, 6);
		assertEq(result, expected);
	}

	function test_normalize_scaleUp() public pure {
		uint256 price = 1000e6; // 1000 with 6 decimals
		uint256 expected = 1000e18; // 1000 with 18 decimals
		uint256 result = PriceMath.normalize(price, 6, 18);
		assertEq(result, expected);
	}

	function test_normalize_revertsIfZeroPrice() public {
		vm.expectRevert(PriceMath.InvalidPrice.selector);
		PriceMath.normalize(0, 18, 6);
	}

	function test_normalize_revertsIfZeroDecimals() public {
		vm.expectRevert(PriceMath.InvalidDecimals.selector);
		PriceMath.normalize(1000e18, 0, 6);

		vm.expectRevert(PriceMath.InvalidDecimals.selector);
		PriceMath.normalize(1000e18, 18, 0);
	}

	function test_fuzz_normalize(uint256 price, uint8 fromDecimals, uint8 toDecimals) public pure {
		price = bound(price, 1, type(uint128).max);
		fromDecimals = uint8(bound(fromDecimals, 1, 18));
		toDecimals = uint8(bound(toDecimals, 1, 18));

		uint256 result = PriceMath.normalize(price, fromDecimals, toDecimals);
		if (fromDecimals == toDecimals) {
			assertEq(result, price);
		} else if (fromDecimals > toDecimals) {
			assertLe(result, price);
		} else {
			assertGe(result, price);
		}
	}

	function test_invert() public pure {
		uint256 price = 4000e8; // ETH/USD = $4000
		uint8 baseDecimals = 18; // ETH decimals
		uint8 quoteDecimals = 8; // USD decimals

		uint256 result = PriceMath.invert(price, baseDecimals, quoteDecimals);
		uint256 expected = 10 ** (baseDecimals + quoteDecimals) / price;
		assertEq(result, expected);
	}

	function test_invert_sameDecimals() public pure {
		uint256 price = 4000e8;
		uint256 result = PriceMath.invert(price, 8, 8);
		uint256 expected = 10 ** (8 + 8) / price;
		assertEq(result, expected);
	}

	function test_invert_differentDecimals() public pure {
		uint256 price = 4000e8;
		uint256 result = PriceMath.invert(price, 8, 6);
		uint256 expected = 10 ** (8 + 6) / price;
		assertEq(result, expected);
	}

	function test_invert_revertsIfZeroPrice() public {
		vm.expectRevert(PriceMath.InvalidPrice.selector);
		PriceMath.invert(0, 18, 8);
	}

	function test_invert_revertsIfZeroDecimals() public {
		vm.expectRevert(PriceMath.InvalidDecimals.selector);
		PriceMath.invert(1000e8, 0, 8);

		vm.expectRevert(PriceMath.InvalidDecimals.selector);
		PriceMath.invert(1000e8, 18, 0);
	}

	function test_derive_sameDecimals() public pure {
		uint256 ethUsdPrice = 4000e8; // $4000
		uint256 btcUsdPrice = 120000e8; // $120000

		// Expected: ETH/BTC = 4000/120000 = 0.03333333... BTC per ETH
		uint256 result = PriceMath.derive(
			ethUsdPrice, // basePrice
			btcUsdPrice, // quotePrice
			8, // baseDecimals
			8, // quoteDecimals
			8 // targetDecimals
		);

		uint256 expected = 3333333; // 0.03333333... with 8 decimals
		assertEq(result, expected);
	}

	function test_derive_differentDecimals() public pure {
		uint256 priceA = 100e6; // $100 with 6 decimals
		uint256 priceB = 50e18; // $50 with 18 decimals

		uint256 result = PriceMath.derive(
			priceA, // basePrice
			priceB, // quotePrice
			6, // baseDecimals
			18, // quoteDecimals
			8 // targetDecimals
		);

		// Expected: 100/50 = 2, with 8 decimals = 2e8
		uint256 expected = 2e8;
		assertEq(result, expected);
	}

	function test_derive_revertsIfZeroPrice() public {
		vm.expectRevert(PriceMath.InvalidPrice.selector);
		PriceMath.derive(0, 1000e8, 8, 8, 8);

		vm.expectRevert(PriceMath.InvalidPrice.selector);
		PriceMath.derive(1000e8, 0, 8, 8, 8);
	}

	function test_derive_revertsIfZeroDecimals() public {
		vm.expectRevert(PriceMath.InvalidDecimals.selector);
		PriceMath.derive(1000e8, 1000e8, 0, 8, 8);

		vm.expectRevert(PriceMath.InvalidDecimals.selector);
		PriceMath.derive(1000e8, 1000e8, 8, 0, 8);

		vm.expectRevert(PriceMath.InvalidDecimals.selector);
		PriceMath.derive(1000e8, 1000e8, 8, 8, 0);
	}
}
