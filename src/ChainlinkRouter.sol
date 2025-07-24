// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IChainlinkRouter} from "src/interfaces/IChainlinkRouter.sol";
import {BytesParser} from "src/libraries/BytesParser.sol";
import {Denominations} from "src/libraries/Denominations.sol";
import {PriceMath} from "src/libraries/PriceMath.sol";
import {BitMap} from "src/types/BitMap.sol";
import {FeedConfig} from "src/types/FeedConfig.sol";
import {ChainlinkRegistry} from "./ChainlinkRegistry.sol";

/// @title ChainlinkRouter - Advanced routing system for Chainlink price feeds
/// @notice Provides intelligent price discovery through multi-hop routing between assets
/// @dev Extends ChainlinkRegistry with sophisticated path-finding algorithms
/// 	 Supports up to 4-hop routing with automatic intermediate asset discovery
/// 	 Uses BitMap operations for efficient relationship queries
/// @author fomoweth
contract ChainlinkRouter is IChainlinkRouter, ChainlinkRegistry {
	using BytesParser for bytes;
	using Denominations for address;
	using PriceMath for uint256;

	/// @notice Maximum number of hops allowed in a price routing path
	uint8 private constant MAX_HOPS = 4;

	/// @notice Contract revision number for upgrade tracking
	uint256 public constant REVISION = 0x01;

	/// @notice Constructor disables initializers for implementation contract
	/// @dev Prevents direct initialization of the implementation contract in proxy pattern
	constructor() {
		_disableInitializers();
	}

	/// @notice Initializes the contract with initial owner and feed configurations
	/// @dev Sets up USD as the primary asset and processes packed feed parameters
	/// @param params Packed bytes containing initialOwner and feed configurations (20 bytes each for feed, base, quote)
	function initialize(bytes calldata params) external initializer {
		// Set initial owner
		address initialOwner;
		(initialOwner, params) = params.parseAddress();
		_checkNewOwner(initialOwner);
		_setOwner(initialOwner);

		Storage storage $ = _getStorage();
		// Register USD as the primary reference asset with ID 0
		_registerAsset($, Denominations.USD);

		address feed;
		address base;
		address quote;

		// Process all initial feed configurations
		while (true) {
			if (params.length == 0) return;
			(feed, base, quote, params) = params.parseFeedParams();
			_registerFeed($, feed, base, quote);
		}
	}

	/// @inheritdoc IChainlinkRouter
	function query(address base, address quote) external view returns (address[] memory path, uint256 accumulated) {
		if (base == quote) revert IdenticalAssets();

		FeedConfig[] memory feeds;
		uint256 hops;
		(feeds, accumulated, hops) = _queryPath(base, quote);

		// Resize the array to match actual hops used + 1 for path length
		assembly ("memory-safe") {
			if lt(hops, MAX_HOPS) {
				mstore(feeds, add(hops, 0x01))
			}
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
		Storage storage $ = _getStorage();
		return $.feeds[base][quote].feed();
	}

	/// @inheritdoc IChainlinkRouter
	function getFeedConfiguration(address base, address quote) external view returns (FeedConfig) {
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

	/// @notice Internal function to find optimal routing path and accumulate prices across hops
	/// @dev Implements iterative deepening search with automatic intermediate discovery
	/// 	 Accumulates prices across multiple hops while maintaining precision
	/// @param base Starting asset for the path
	/// @param quote Target asset for the path
	/// @return feeds Array of FeedConfig objects used in the path
	/// @return accumulated Final calculated price after all hops
	/// @return hops Number of routing hops required
	function _queryPath(
		address base,
		address quote
	) internal view virtual returns (FeedConfig[] memory feeds, uint256 accumulated, uint256 hops) {
		Storage storage $ = _getStorage();
		feeds = new FeedConfig[](MAX_HOPS);
		address baseCurrent = base;
		address quoteCurrent = quote;

		while (hops < MAX_HOPS) {
			// Try to find direct feed between current assets
			FeedConfig feed = _queryFeed($, baseCurrent, quoteCurrent);

			if (feed.isZero()) {
				// No direct feed found, search for intermediate asset
				address intermediate = _queryIntermediate($, baseCurrent, quoteCurrent);
				if (intermediate == address(0)) revert FeedNotFound(baseCurrent, quoteCurrent);

				// Route through intermediate asset
				feed = _queryFeed($, baseCurrent, quoteCurrent = intermediate);
			}

			feeds[hops] = feed;

			uint256 answer = _fetchAnswer(feed);

			if (hops == 0) {
				// First hop: establish base price with potential inversion
				accumulated = _queryDirection($, feed, quoteCurrent, baseCurrent)
					? answer.invert(feed.quoteDecimals(), feed.baseDecimals())
					: answer;
			} else {
				// Subsequent hops: accumulate price through derivation
				accumulated = _accumulateAnswer($, feed, baseCurrent, quoteCurrent, accumulated, answer);
			}

			// Check if we've reached the target
			if (quoteCurrent == quote) break;

			// Continue routing towards target
			baseCurrent = quoteCurrent;
			quoteCurrent = quote;

			unchecked {
				++hops;
			}
		}

		if (quoteCurrent != quote) revert FeedNotFound(base, quote);
	}

	/// @notice Internal function to find the intermediate asset for routing between two assets
	/// @dev Uses BitMap intersection to find common connections, falls back to base connections
	/// @param $ Storage reference for gas optimization
	/// @param base The source asset
	/// @param quote The target asset
	/// @return intermediate The address of the intermediate asset
	function _queryIntermediate(
		Storage storage $,
		address base,
		address quote
	) internal view virtual returns (address intermediate) {
		BitMap baseConfiguration = $.configurationMaps[base];
		BitMap quoteConfiguration = $.configurationMaps[quote];

		// Find assets connected to both base and quote (optimal routing)
		BitMap intersection = baseConfiguration & quoteConfiguration;

		// If no common connections, use any asset connected to base
		if (intersection.isZero()) intersection = baseConfiguration;

		uint256 assetId = intersection.findFirstSet();
		return $.assets[assetId];
	}

	/// @notice Internal function to accumulate price data across multiple routing hops
	/// @dev Handles price derivation with proper decimal normalization and inversion
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
		bool inverse = _queryDirection($, feed, base, quote);

		// Calculate derived price from accumulated price and current feed price
		result = accumulated.derive(
			inverse ? answer.invert(feed.quoteDecimals(), feed.baseDecimals()) : answer,
			base.decimals(),
			inverse ? feed.baseDecimals() : feed.quoteDecimals(),
			quote.decimals()
		);
	}

	/// @notice Internal function to fetch the latest price from a Chainlink aggregator
	/// @param feed The FeedConfig containing the aggregator address
	/// @return answer The latest price from the feed
	function _fetchAnswer(FeedConfig feed) internal view virtual returns (uint256 answer) {
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

	/// @notice Internal function to find a feed for an asset pair with bidirectional search
	/// @dev Checks both base/quote and quote/base directions for feed existence
	/// @param $ Storage reference for gas optimization
	/// @param base The base asset address
	/// @param quote The quote asset address
	/// @return feed The found FeedConfig, or zero if no feed exists
	function _queryFeed(
		Storage storage $,
		address base,
		address quote
	) internal view virtual returns (FeedConfig feed) {
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
	function _queryDirection(
		Storage storage $,
		FeedConfig feed,
		address base,
		address quote
	) internal view returns (bool inverse) {
		return feed.baseId() == $.assetIds[base] && feed.quoteId() == $.assetIds[quote];
	}

	/// @notice Internal function to get the contract revision number for upgrade compatibility
	/// @dev Required override from parent contract for version tracking
	/// @return The current contract revision
	function _getRevision() internal pure virtual override returns (uint256) {
		return REVISION;
	}
}
