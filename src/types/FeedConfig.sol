// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

type FeedConfig is uint256;

using FeedConfigLibrary for FeedConfig global;

/// @notice Packs multiple feed-related parameters into a single FeedConfig
/// @dev Bit layout structure:
/// 	 - [255:192]: zero-bits (64 bits)		Unused zero-bits to match a total uint256
/// 	 - [191:184]: quoteDecimals (8 bits)	Decimal places of quote currency
/// 	 - [183:176]: quoteId (8 bits)			Quote currency identifier
/// 	 - [175:168]: baseDecimals (8 bits)		Decimal places of base currency
/// 	 - [167:160]: baseId (8 bits)			Base currency identifier
/// 	 - [159:0]:	  feed (160 bits)			Feed contract address
/// @param feed Address of the price feed contract
/// @param baseId Unique identifier for the base asset
/// @param baseDecimals Number of decimal places for the base asset
/// @param quoteId Unique identifier for the quote asset
/// @param quoteDecimals Number of decimal places for the quote asset
/// @return result FeedConfig with all information packed
function toFeedConfig(address feed, uint8 baseId, uint8 baseDecimals, uint8 quoteId, uint8 quoteDecimals)
    pure
    returns (FeedConfig result)
{
    assembly ("memory-safe") {
        result :=
            or(
                or(
                    or(shl(184, and(0xff, quoteDecimals)), shl(176, and(0xff, quoteId))),
                    or(shl(168, and(0xff, baseDecimals)), shl(160, and(0xff, baseId)))
                ),
                and(0xffffffffffffffffffffffffffffffffffffffff, feed)
            )
    }
}

/// @title FeedConfigLibrary
/// @notice Provides utility functions to extract individual data from packed FeedConfig
/// @author fomoweth
library FeedConfigLibrary {
    /// @notice Extracts feed contract address from bits 0-159
    /// @param self Target FeedConfig
    /// @return result Address of the feed contract
    function feed(FeedConfig self) internal pure returns (address result) {
        assembly ("memory-safe") {
            result := and(0xffffffffffffffffffffffffffffffffffffffff, self)
        }
    }

    /// @notice Extracts base asset ID from bits 168-183
    /// @param self Target FeedConfig
    /// @return result Unique identifier of the base asset
    function baseId(FeedConfig self) internal pure returns (uint8 result) {
        assembly ("memory-safe") {
            result := and(0xff, shr(160, self))
        }
    }

    /// @notice Extracts base asset decimal places from from bits 184-191
    /// @param self Target FeedConfig
    /// @return result Number of decimal places for the base asset
    function baseDecimals(FeedConfig self) internal pure returns (uint8 result) {
        assembly ("memory-safe") {
            result := and(0xff, shr(168, self))
        }
    }

    /// @notice Extracts quote asset ID from bits 192-207
    /// @param self Target FeedConfig
    /// @return result Unique identifier of the quote asset
    function quoteId(FeedConfig self) internal pure returns (uint8 result) {
        assembly ("memory-safe") {
            result := and(0xff, shr(176, self))
        }
    }

    /// @notice Extracts quote asset decimal places from bits 208-215
    /// @param self Target FeedConfig
    /// @return result Number of decimal places for the quote asset
    function quoteDecimals(FeedConfig self) internal pure returns (uint8 result) {
        assembly ("memory-safe") {
            result := and(0xff, shr(184, self))
        }
    }

    /// @notice Checks if FeedConfig is empty (zero)
    /// @param self FeedConfig to check
    /// @return result True if FeedConfig is zero, false otherwise
    function isZero(FeedConfig self) internal pure returns (bool result) {
        assembly ("memory-safe") {
            result := iszero(self)
        }
    }
}
