// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IChainlinkRouter} from "src/interfaces/IChainlinkRouter.sol";
import {BytesParser} from "src/libraries/BytesParser.sol";
import {Denominations} from "src/libraries/Denominations.sol";
import {PriceMath} from "src/libraries/PriceMath.sol";
import {BitMap} from "src/types/BitMap.sol";
import {FeedConfig, toFeedConfig} from "src/types/FeedConfig.sol";
import {Initializable} from "src/base/Initializable.sol";
import {Ownable} from "src/base/Ownable.sol";

/// @title ChainlinkRouter - Advanced multi-hop price routing system for Chainlink feeds
/// @notice A price oracle router that aggregates and derives price feeds using Chainlink Aggregators
/// @dev This contract allows querying of asset prices via direct or multi-hop routes using registered Chainlink feeds
/// 	 It leverages a bitwise-optimized bitmap system for efficient asset registration and graph traversal
///
///		 Key Features:
/// 	 - Multi-hop routing: Automatically finds price paths through intermediate assets when direct feeds don't exist
/// 	 - Bidirectional feed support: Can use feeds in both directions (A/B or B/A) with automatic price inversion
/// 	 - Gas-optimized storage: Uses ERC-7201 pattern for upgradeable proxy compatibility
/// 	 - Efficient relationship tracking: BitMap-based asset connection mapping for O(1) relationship queries
/// 	 - Batch operations: Supports registering/deregistering multiple feeds in single transactions
/// 	 - Comprehensive asset management: Automatic asset registration/cleanup with ID assignment (0-255)
/// 	 - Decimal normalization: Handles different decimal precisions across assets seamlessly
/// 	 - Price accumulation: Mathematical derivation of prices across multiple routing hops
///
/// 	 Architecture:
/// 	 The contract combines a registry system for managing Chainlink feeds with an intelligent routing engine.
/// 	 It maintains a graph of asset relationships using BitMaps, enabling efficient pathfinding algorithms.
/// 	 Each asset is assigned a unique 8-bit ID (0-255) for compact storage and BitMap operations.
/// 	 USD is reserved as asset ID 0 and serves as a common reference point for routing.
///
/// 	 Routing Algorithm:
/// 	 1. Direct Path: Check for direct feed between source and target assets
/// 	 2. Intermediate Discovery: Find common connected assets using BitMap intersection
/// 	 3. Multi-hop Routing: Chain multiple feeds together with price accumulation
/// 	 4. Price Calculation: Handle decimal normalization and direction inversion automatically
///
/// @author fomoweth
contract ChainlinkRouter is IChainlinkRouter, Initializable, Ownable {
    using BytesParser for bytes;
    using Denominations for address;
    using PriceMath for uint256;

    /// @custom:storage-location erc7201:chainlink.router.storage
    struct Storage {
        mapping(address base => mapping(address quote => FeedConfig configuration)) feeds;
        mapping(address asset => BitMap configuration) configurationMaps;
        mapping(address asset => uint8 assetId) assetIds;
        mapping(uint256 assetId => address asset) assets;
        uint16 numAssets;
    }

    /// @notice Storage slot calculated using ERC-7201 pattern
    /// @dev keccak256(abi.encode(uint256(keccak256("chainlink.router.storage")) - 1)) & ~bytes32(uint256(0xff))
    uint256 private constant STORAGE_SLOT = 0xb4b1a749a23d159bc5ca72fecf3e094397bd4f0cb6afce4c7164622c60453c00;

    /// @notice Maximum number of assets supported by the system
    uint256 internal constant MAX_ASSETS = 256;

    /// @notice Maximum number of hops allowed in a price routing path
    uint256 internal constant MAX_HOPS = 4;

    /// @notice Reserved asset ID for USD denomination
    uint256 internal constant USD_ID = 0;

    /// @notice Contract revision number for upgrade tracking
    uint256 public constant REVISION = 0x01;

    /// @dev Constructor disables initializers to prevent direct initialization of implementation contract
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract by setting the owner and registering USD
    /// @param initialOwner The address that will be granted ownership of the contract
    function initialize(address initialOwner) external initializer {
        _checkNewOwner(initialOwner);
        _setOwner(initialOwner);
        _registerAsset(_getStorage(), Denominations.USD);
    }

    /// @inheritdoc IChainlinkRouter
    function register(bytes calldata params) external payable onlyOwner {
        Storage storage $ = _getStorage();
        address feed;
        address base;
        address quote;

        while (true) {
            if (params.length == 0) return;
            (feed, base, quote, params) = params.parseFeedParams();
            _registerFeed($, feed, base, quote);
        }
    }

    /// @inheritdoc IChainlinkRouter
    function deregister(bytes calldata params) external payable onlyOwner {
        Storage storage $ = _getStorage();
        address base;
        address quote;

        while (true) {
            if (params.length == 0) return;
            (base, quote, params) = params.parseAssetPair();
            _deregisterFeed($, base, quote);
        }
    }

    /// @inheritdoc IChainlinkRouter
    function registerAsset(address asset) external payable onlyOwner {
        _registerAsset(_getStorage(), asset);
    }

    /// @inheritdoc IChainlinkRouter
    function deregisterAsset(address asset) external payable onlyOwner {
        _deregisterAsset(_getStorage(), asset);
    }

    /// @notice Internal function to register a price feed
    /// @dev Handles asset registration, BitMap updates, and feed storage
    /// 	 Automatically registers assets if they don't exist
    /// @param $ Storage reference for gas optimization
    /// @param feed Address of the Chainlink aggregator contract
    /// @param base Address of the base asset
    /// @param quote Address of the quote asset
    function _registerFeed(Storage storage $, address feed, address base, address quote) internal virtual {
        if (feed == address(0)) revert InvalidFeed();
        if (base == quote) revert IdenticalAssets();

        // Register assets if they don't exist, otherwise get existing IDs
        uint8 baseId = $.assetIds[base];
        if (base != Denominations.USD && baseId == USD_ID) baseId = _registerAsset($, base);

        uint8 quoteId = $.assetIds[quote];
        if (quote != Denominations.USD && quoteId == USD_ID) quoteId = _registerAsset($, quote);

        // Update asset configurations to reflect the new price feed relationship
        $.configurationMaps[base] = $.configurationMaps[base].set(quoteId);
        $.configurationMaps[quote] = $.configurationMaps[quote].set(baseId);

        // Store the feed configuration with all necessary metadata
        $.feeds[base][quote] = toFeedConfig(feed, baseId, base.decimals(), quoteId, quote.decimals());

        emit FeedRegistered(feed, base, quote);
    }

    /// @notice Internal function to deregister a price feed
    /// @dev Removes feed configuration and cleans up unused assets
    /// 	 Automatically deregisters assets that have no remaining feeds (except USD)
    /// @param $ Storage reference for gas optimization
    /// @param base Address of the base asset
    /// @param quote Address of the quote asset
    function _deregisterFeed(Storage storage $, address base, address quote) internal virtual {
        if (base == quote) revert IdenticalAssets();

        // Remove the feed relationship from both assets' BitMaps
        $.configurationMaps[base] = $.configurationMaps[base].unset($.assetIds[quote]);
        $.configurationMaps[quote] = $.configurationMaps[quote].unset($.assetIds[base]);

        // Clean up assets that no longer have any feeds (preserve USD)
        if (base != Denominations.USD && $.configurationMaps[base].isZero()) _deregisterAsset($, base);
        if (quote != Denominations.USD && $.configurationMaps[quote].isZero()) _deregisterAsset($, quote);

        // Clear the feed configuration
        $.feeds[base][quote] = FeedConfig.wrap(0);

        emit FeedDeregistered(base, quote);
    }

    /// @notice Internal function to register a new asset
    /// @dev Assigns a unique ID and updates all relevant mappings
    /// @param $ Storage reference for gas optimization
    /// @param asset Address of the asset to register
    /// @return assetId The assigned asset ID (0-255)
    function _registerAsset(Storage storage $, address asset) internal virtual returns (uint8 assetId) {
        if ($.numAssets == MAX_ASSETS) revert ExceededMaxAssets();
        if (asset == address(0)) revert InvalidAsset();
        if (asset != Denominations.USD && $.assetIds[asset] != USD_ID) revert AssetAlreadyExists(asset);

        unchecked {
            // Find the first available asset ID slot
            while (assetId < $.numAssets) {
                if ($.assets[assetId] == address(0)) break;
                ++assetId;
            }
            ++$.numAssets;
        }

        // Register the asset with its assigned ID
        $.assets[assetId] = asset;
        $.assetIds[asset] = assetId;

        emit AssetAdded(asset, assetId);
    }

    /// @notice Internal function to deregister an asset
    /// @dev Removes all associated feeds and cleans up storage
    /// @param $ Storage reference for gas optimization
    /// @param asset Address of the asset to remove
    /// @return assetId The asset ID that was freed
    function _deregisterAsset(Storage storage $, address asset) internal virtual returns (uint8 assetId) {
        if (asset == address(0) || asset == Denominations.USD) revert InvalidAsset();
        if ((assetId = $.assetIds[asset]) == USD_ID) revert AssetNotExists(asset);

        // Get the asset's current configuration BitMap
        BitMap configuration = $.configurationMaps[asset];

        // Remove this asset from all other assets' configuration maps
        while (!configuration.isZero()) {
            uint256 tokenId = configuration.findFirstSet();
            address token = $.assets[tokenId];
            configuration.unset(tokenId);
            $.configurationMaps[token] = $.configurationMaps[token].unset(assetId);
        }

        // Clear the asset's configuration and update counters
        $.configurationMaps[asset] = configuration;
        --$.numAssets;

        // Clean up storage mappings
        delete $.assets[assetId];
        delete $.assetIds[asset];

        emit AssetRemoved(asset, assetId);
    }

    /// @inheritdoc IChainlinkRouter
    function query(address base, address quote) external view returns (address[] memory path, uint256 accumulated) {
        if (base == quote) revert IdenticalAssets();

        FeedConfig[] memory feeds;
        uint256 hops;
        (feeds, accumulated, hops) = _queryPath(base, quote);

        // Resize the array to match actual hops used + 1 for path length
        assembly ("memory-safe") {
            if lt(hops, MAX_HOPS) { mstore(feeds, add(hops, 0x01)) }
            path := feeds
        }
    }

    /// @inheritdoc IChainlinkRouter
    function queryFeed(address base, address quote) external view returns (address feed) {
        if (base == quote) revert IdenticalAssets();
        Storage storage $ = _getStorage();
        return _queryFeed($, base, quote).feed();
    }

    /// @inheritdoc IChainlinkRouter
    function getFeed(address base, address quote) external view returns (address feed) {
        if (base == quote) revert IdenticalAssets();
        Storage storage $ = _getStorage();
        return $.feeds[base][quote].feed();
    }

    /// @inheritdoc IChainlinkRouter
    function getFeedConfiguration(address base, address quote) external view returns (FeedConfig) {
        if (base == quote) revert IdenticalAssets();
        Storage storage $ = _getStorage();
        return $.feeds[base][quote];
    }

    /// @inheritdoc IChainlinkRouter
    function getAssetConfiguration(address asset) external view returns (BitMap) {
        Storage storage $ = _getStorage();
        return $.configurationMaps[asset];
    }

    /// @inheritdoc IChainlinkRouter
    function getAssetId(address asset) external view returns (uint256) {
        Storage storage $ = _getStorage();
        return $.assetIds[asset];
    }

    /// @inheritdoc IChainlinkRouter
    function getAsset(uint256 id) external view returns (address) {
        Storage storage $ = _getStorage();
        return $.assets[id];
    }

    /// @inheritdoc IChainlinkRouter
    function numAssets() external view returns (uint256) {
        Storage storage $ = _getStorage();
        return $.numAssets;
    }

    /// @notice Internal function to find optimal routing path and calculate accumulated price across hops
    /// @dev Implements iterative path-finding algorithm with automatic intermediate asset discovery
    /// 	 Uses breadth-first approach to find shortest path with maximum 4-hop limit
    /// 	 Handles price accumulation with proper decimal normalization and direction inversion
    /// @param base Starting asset address for the pricing path
    /// @param quote Target asset address for the pricing path
    /// @return path Array of FeedConfig objects representing the complete routing path
    /// @return accumulated Final calculated price after traversing all hops with proper scaling
    /// @return hops Number of routing hops required
    /// @dev Algorithm flow:
    /// 	 1. Try direct path (base -> quote)
    /// 	 2. If no direct path, find intermediate asset (base -> intermediate -> quote)
    /// 	 3. Accumulate prices with proper inversion and decimal handling
    /// 	 4. Repeat until target reached or max hops exceeded
    function _queryPath(address base, address quote)
        internal
        view
        virtual
        returns (FeedConfig[] memory path, uint256 accumulated, uint256 hops)
    {
        // Retrieve storage reference using ERC-7201 pattern
        Storage storage $ = _getStorage();

        // Pre-allocate array for maximum possible hops
        path = new FeedConfig[](MAX_HOPS);

        // Track current position in the routing path
        address baseCurrent = base;
        address quoteCurrent = quote;

        while (hops < MAX_HOPS) {
            // Attempt to find direct feed between current base and quote
            FeedConfig feed = _queryFeed($, baseCurrent, quoteCurrent);

            if (feed.isZero()) {
                // No direct feed found, search for intermediate asset
                address intermediate = _queryIntermediate($, baseCurrent, quoteCurrent);

                // Validate that intermediate asset was found
                if (intermediate == address(0)) revert FeedNotFound(baseCurrent, quoteCurrent);

                // Route through intermediate asset
                feed = _queryFeed($, baseCurrent, quoteCurrent = intermediate);
            }

            // Store the feed configuration for this hop
            path[hops] = feed;

            // Fetch current price from the Chainlink aggregator
            uint256 answer = _fetchLatestAnswer(feed);

            if (hops == 0) {
                // First hop: establish base price with potential inversion
                accumulated = _queryDirection($, feed, quoteCurrent, baseCurrent)
                    ? answer.invert(feed.quoteDecimals(), feed.baseDecimals())
                    : answer;
            } else {
                // Subsequent hops: accumulate price through derivation
                accumulated = _accumulateAnswer($, feed, baseCurrent, quoteCurrent, accumulated, answer);
            }

            // Check if the target asset was reached
            if (quoteCurrent == quote) break;

            // Continue routing towards target asset
            baseCurrent = quoteCurrent;
            quoteCurrent = quote;

            unchecked {
                ++hops;
            }
        }

        // Validate that the target asset was reached successfully
        if (quoteCurrent != quote) revert FeedNotFound(base, quote);
    }

    /// @notice Internal function to find the intermediate asset for routing between two assets
    /// @dev Uses BitMap intersection to find common connections, falls back to base connections
    /// @param $ Storage reference for gas optimization
    /// @param base The source asset
    /// @param quote The target asset
    /// @return intermediate The address of the intermediate asset
    function _queryIntermediate(Storage storage $, address base, address quote)
        internal
        view
        virtual
        returns (address intermediate)
    {
        BitMap baseConfiguration = $.configurationMaps[base];
        BitMap quoteConfiguration = $.configurationMaps[quote];

        // Find assets connected to both base and quote (optimal routing)
        BitMap intersection = baseConfiguration & quoteConfiguration;

        // If no common connections, use any asset connected to base
        if (intersection.isZero()) intersection = baseConfiguration;

        uint256 assetId = intersection.findFirstSet();
        return $.assets[assetId];
    }

    /// @notice Internal function to find a feed for an asset pair with bidirectional search
    /// @dev Checks both base/quote and quote/base directions for feed existence
    /// @param $ Storage reference for gas optimization
    /// @param base The base asset address
    /// @param quote The quote asset address
    /// @return feed The found FeedConfig, or zero if no feed exists
    function _queryFeed(Storage storage $, address base, address quote)
        internal
        view
        virtual
        returns (FeedConfig feed)
    {
        // Try direct lookup first, then reverse direction
        if ((feed = $.feeds[base][quote]).isZero()) feed = $.feeds[quote][base];
    }

    /// @notice Internal function to determine if a feed requires price inversion for the desired direction
    /// @dev Compares feed's stored base/quote IDs with requested asset IDs
    /// @param $ Storage reference for gas optimization
    /// @param feed The feed configuration to check
    /// @param base The desired base asset
    /// @param quote The desired quote asset
    /// @return inverse True if the feed's direction matches the request (no inversion needed)
    function _queryDirection(Storage storage $, FeedConfig feed, address base, address quote)
        internal
        view
        returns (bool inverse)
    {
        return feed.baseId() == $.assetIds[base] && feed.quoteId() == $.assetIds[quote];
    }

    /// @notice Internal function to accumulate price data across multiple routing hops
    /// @dev Handles price derivation with proper decimal normalization and inversion
    /// @dev Combines previously accumulated price with current feed price using mathematical derivation
    /// 	 Handles automatic price inversion when feed direction doesn't match desired routing direction
    /// 	 Essential for multi-hop price discovery where intermediate assets are used
    /// @param $ Storage reference for gas optimization
    /// @param feed The current feed configuration
    /// @param base Current base asset
    /// @param quote Current quote asset
    /// @param accumulated Accumulated price from previous hops
    /// @param answer Current price fetched from feed
    /// @return result Updated accumulated price after this hop
    function _accumulateAnswer(
        Storage storage $,
        FeedConfig feed,
        address base,
        address quote,
        uint256 accumulated,
        uint256 answer
    ) internal view virtual returns (uint256 result) {
        // Determine if the feed's natural direction matches our desired routing direction
        bool inverse = _queryDirection($, feed, base, quote);

        // Extract decimal configuration from the feed metadata
        uint8 baseDecimals = feed.baseDecimals();
        uint8 quoteDecimals = feed.quoteDecimals();

        // Feed is in opposite direction (quote/base instead of base/quote)
        if (inverse) {
            // Invert the price
            answer = answer.invert(baseDecimals, quoteDecimals);

            // Swap decimal configuration to match the inverted price direction
            // This ensures proper decimal handling in subsequent calculations
            quoteDecimals = baseDecimals;
        }

        // Calculate derived price from accumulated price and current feed price
        result = accumulated.derive(answer, base.decimals(), quoteDecimals, quote.decimals());
    }

    /// @notice Internal function to fetch the latest price from a Chainlink aggregator
    /// @param feed The FeedConfig containing the aggregator address
    /// @return answer The latest price from the feed
    function _fetchLatestAnswer(FeedConfig feed) internal view virtual returns (uint256 answer) {
        assembly ("memory-safe") {
            mstore(0x00, 0x50d25bcd) // latestAnswer()

            // Execute static call to the feed address extracted from FeedConfig
            if iszero(staticcall(gas(), shr(0x60, shl(0x60, feed)), 0x1c, 0x04, 0x00, 0x20)) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0x00, returndatasize())
                revert(ptr, returndatasize())
            }

            // Validate that the price is not a negative number nor zero
            if iszero(sgt(mload(0x00), 0x00)) {
                mstore(0x00, 0x00bfc921) // InvalidPrice()
                revert(0x1c, 0x04)
            }

            answer := mload(0x00)
        }
    }

    /// @notice Internal function to get storage reference using ERC-7201 pattern
    /// @return $ Reference to the storage struct
    function _getStorage() internal pure virtual returns (Storage storage $) {
        assembly ("memory-safe") {
            $.slot := STORAGE_SLOT
        }
    }

    /// @notice Internal function to get the contract revision number for upgrade compatibility
    /// @dev Required override from parent contract for version tracking
    /// @return The current contract revision
    function _getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}
