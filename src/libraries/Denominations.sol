// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Denominations
/// @notice Conventional representation of non-ERC20 assets
/// @dev Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
library Denominations {
	address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	address internal constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
	address internal constant USD = 0x0000000000000000000000000000000000000348;
	address internal constant GBP = 0x000000000000000000000000000000000000033a;
	address internal constant EUR = 0x00000000000000000000000000000000000003d2;
	address internal constant JPY = 0x0000000000000000000000000000000000000188;
	address internal constant KRW = 0x000000000000000000000000000000000000019a;
	address internal constant CNY = 0x000000000000000000000000000000000000009c;
	address internal constant AUD = 0x0000000000000000000000000000000000000024;
	address internal constant CAD = 0x000000000000000000000000000000000000007c;
	address internal constant CHF = 0x00000000000000000000000000000000000002F4;
	address internal constant ARS = 0x0000000000000000000000000000000000000020;
	address internal constant PHP = 0x0000000000000000000000000000000000000260;
	address internal constant NZD = 0x000000000000000000000000000000000000022A;
	address internal constant SGD = 0x00000000000000000000000000000000000002be;
	address internal constant NGN = 0x0000000000000000000000000000000000000236;
	address internal constant ZAR = 0x00000000000000000000000000000000000002c6;
	address internal constant RUB = 0x0000000000000000000000000000000000000283;
	address internal constant INR = 0x0000000000000000000000000000000000000164;
	address internal constant BRL = 0x00000000000000000000000000000000000003Da;

	function decimals(address target) internal view returns (uint8 unit) {
		assembly ("memory-safe") {
			switch eq(target, ETH)
			case 0x00 {
				switch or(eq(target, USD), eq(target, BTC))
				case 0x00 {
					mstore(0x00, 0x313ce567) // decimals()

					if iszero(staticcall(gas(), target, 0x1c, 0x04, 0x00, 0x20)) {
						let ptr := mload(0x40)
						returndatacopy(ptr, 0x00, returndatasize())
						revert(ptr, returndatasize())
					}

					unit := mload(0x00)
				}
				default {
					unit := 8
				}
			}
			default {
				unit := 18
			}
		}
	}
}
