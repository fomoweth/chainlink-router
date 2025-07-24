// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {FullMath} from "./FullMath.sol";

/// @title PriceMath
/// @notice Provides utility functions for chaining, inverting, and normalizing price data
/// @author fomoweth
library PriceMath {
	/// @notice Thrown when provided decimal parameters are zero
	error InvalidDecimals();

	/// @notice Thrown when provided price is zero
	error InvalidPrice();

	/// @notice Calculates derived price from two prices (basePrice / quotePrice)
	/// @param basePrice The numerator price (e.g., ETH/USD price)
	/// @param quotePrice The denominator price (e.g., BTC/USD price)
	/// @param baseDecimals Current decimal places of the base price
	/// @param quoteDecimals Current decimal places of the quote price
	/// @param decimals Target decimal places for both normalization and final result
	/// @return result The derived price with specified decimal places
	function derive(
		uint256 basePrice,
		uint256 quotePrice,
		uint8 baseDecimals,
		uint8 quoteDecimals,
		uint8 decimals
	) internal pure returns (uint256 result) {
		unchecked {
			result = FullMath.mulDiv(
				normalize(basePrice, baseDecimals, decimals),
				10 ** decimals,
				normalize(quotePrice, quoteDecimals, decimals)
			);
		}
	}

	/// @notice Calculates inverse price: if input price is A/B, returns B/A
	/// @param price The original price to invert
	/// @param baseDecimals Decimal places of the base asset in original price
	/// @param quoteDecimals Decimal places of the quote asset in original price
	/// @return result The inverted price maintaining proper decimal scaling
	function invert(uint256 price, uint8 baseDecimals, uint8 quoteDecimals) internal pure returns (uint256 result) {
		assembly ("memory-safe") {
			// Validate price is not zero to prevent division by zero
			if iszero(price) {
				mstore(0x00, 0x00bfc921) // InvalidPrice()
				revert(0x1c, 0x04)
			}

			// Validate decimals are not zero to prevent invalid scaling
			if or(iszero(baseDecimals), iszero(quoteDecimals)) {
				mstore(0x00, 0xd25598a0) // InvalidDecimals()
				revert(0x1c, 0x04)
			}

			// Calculate inverted price: 10**(baseDecimals + quoteDecimals) / price
			result := div(exp(10, add(baseDecimals, quoteDecimals)), price)
		}
	}

	/// @notice Normalizes price by converting from one decimal precision to another
	/// @param price The price to normalize
	/// @param fromDecimals Current decimal places of the price
	/// @param toDecimals Target decimal places for the result
	/// @return result The normalized price adjusted for decimal conversion
	function normalize(uint256 price, uint8 fromDecimals, uint8 toDecimals) internal pure returns (uint256 result) {
		assembly ("memory-safe") {
			// Validate price is not zero
			if iszero(price) {
				mstore(0x00, 0x00bfc921) // InvalidPrice()
				revert(0x1c, 0x04)
			}

			// Validate decimals are not zero
			if or(iszero(fromDecimals), iszero(toDecimals)) {
				mstore(0x00, 0xd25598a0) // InvalidDecimals()
				revert(0x1c, 0x04)
			}

			switch eq(fromDecimals, toDecimals)
			case 0x00 {
				switch lt(fromDecimals, toDecimals)
				case 0x00 {
					// Scale down
					result := div(price, exp(10, sub(fromDecimals, toDecimals)))
				}
				default {
					// Scale up
					result := mul(price, exp(10, sub(toDecimals, fromDecimals)))
				}
			}
			default {
				// No scaling needed
				result := price
			}
		}
	}
}
