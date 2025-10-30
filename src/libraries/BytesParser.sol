// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title BytesParser
/// @notice Library for parsing packed address parameters from calldata
library BytesParser {
    /// @notice Thrown when attempting to parse beyond available calldata bounds
    error SliceOutOfBounds();

    /// @notice Parses a single address from the beginning of calldata
    /// @dev Extracts 20 bytes (160 bits) from calldata and returns remaining data
    /// @param params Input calldata to parse from
    /// @return result The parsed address from bytes 0-19
    /// @return data Remaining calldata after consuming 20 bytes
    function parseAddress(bytes calldata params) internal pure returns (address result, bytes calldata data) {
        assembly ("memory-safe") {
            // Check if input calldata contains at least 20 bytes (0x14) for one address
            if lt(params.length, 0x14) {
                mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
                revert(0x1c, 0x04)
            }

            // Extract address by right-shifting 96 bits (0x60)
            result := shr(0x60, calldataload(params.offset))

            // Update remaining data slice to point after consumed 20 bytes
            data.offset := add(params.offset, 0x14)
            data.length := sub(params.length, 0x14)
        }
    }

    /// @notice Parses two consecutive addresses representing an asset pair
    /// @dev Extracts base and quote addresses (40 bytes total) from calldata and returns remaining data
    /// @param params Input calldata to parse from
    /// @return base The first address (bytes 0-19) representing base asset
    /// @return quote The second address (bytes 20-39) representing quote asset
    /// @return data Remaining calldata after consuming 40 bytes
    function parseAssetPair(bytes calldata params)
        internal
        pure
        returns (address base, address quote, bytes calldata data)
    {
        assembly ("memory-safe") {
            // Check if input calldata contains at least 40 bytes (0x28) for two addresses
            if lt(params.length, 0x28) {
                mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
                revert(0x1c, 0x04)
            }

            // Parse first address (base asset)
            base := shr(0x60, calldataload(params.offset))

            // Parse second address (quote asset) from offset + 20 bytes
            quote := shr(0x60, calldataload(add(params.offset, 0x14)))

            // Update remaining data slice to point after consumed 40 bytes
            data.offset := add(params.offset, 0x28)
            data.length := sub(params.length, 0x28)
        }
    }

    /// @notice Parses three consecutive addresses for feed configuration
    /// @dev Extracts feed contract address and asset pair (60 bytes total) and returns remaining data
    /// @param params Input calldata to parse from
    /// @return feed The price feed contract address (bytes 0-19)
    /// @return base The base asset address (bytes 20-39)
    /// @return quote The quote asset address (bytes 40-59)
    /// @return data Remaining calldata after consuming 60 bytes
    function parseFeedParams(bytes calldata params)
        internal
        pure
        returns (address feed, address base, address quote, bytes calldata data)
    {
        assembly ("memory-safe") {
            // Check if input calldata contains at least 60 bytes (0x3c) for three addresses
            if lt(params.length, 0x3c) {
                mstore(0x00, 0x3b99b53d) // SliceOutOfBounds()
                revert(0x1c, 0x04)
            }

            // Parse feed contract address
            feed := shr(0x60, calldataload(params.offset))

            // Parse base asset address from offset + 20 bytes
            base := shr(0x60, calldataload(add(params.offset, 0x14)))

            // Parse quote asset address from offset + 40 bytes
            quote := shr(0x60, calldataload(add(params.offset, 0x28)))

            // Update remaining data slice to point after consumed 60 bytes
            data.offset := add(params.offset, 0x3c)
            data.length := sub(params.length, 0x3c)
        }
    }
}
