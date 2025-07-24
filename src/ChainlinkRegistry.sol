// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IChainlinkRegistry} from "src/interfaces/IChainlinkRegistry.sol";
import {BytesParser} from "src/libraries/BytesParser.sol";
import {Denominations} from "src/libraries/Denominations.sol";
import {BitMap} from "src/types/BitMap.sol";
import {FeedConfig, toFeedConfig} from "src/types/FeedConfig.sol";
import {Initializable} from "src/base/Initializable.sol";
import {Ownable} from "src/base/Ownable.sol";

/// @title ChainlinkRegistry - Registry for managing Chainlink price feed configurations
/// @notice Abstract contract that provides comprehensive management of Chainlink price feeds
/// @dev Uses ERC-7201 storage pattern for upgradeable proxy compatibility
/// 	 Implements efficient storage using BitMaps for asset relationship tracking
/// @author fomoweth
abstract contract ChainlinkRegistry is IChainlinkRegistry, Initializable, Ownable {
	using BytesParser for bytes;
	using Denominations for address;

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
	///	@dev Limited by BitMap implementation which uses uint256 (256 bits)
	uint256 internal constant MAX_ASSETS = 256;

	/// @notice Reserved asset ID for USD denomination
	uint256 internal constant USD_ID = 0;

	/// @inheritdoc IChainlinkRegistry
	function register(bytes calldata params) external payable onlyOwner {
		Storage storage $ = _getStorage();
		address feed;
		address base;
		address quote;

		// Process all feed configurations in the calldata
		while (true) {
			if (params.length == 0) return;
			(feed, base, quote, params) = params.parseFeedParams();
			_registerFeed($, feed, base, quote);
		}
	}

	/// @inheritdoc IChainlinkRegistry
	function deregister(bytes calldata params) external payable onlyOwner {
		Storage storage $ = _getStorage();
		address base;
		address quote;

		// Process all asset pairs to deregister
		while (true) {
			if (params.length == 0) return;
			(base, quote, params) = params.parseAssetPair();
			_deregisterFeed($, base, quote);
		}
	}

	/// @inheritdoc IChainlinkRegistry
	function registerAsset(address asset) external payable onlyOwner {
		_registerAsset(_getStorage(), asset);
	}

	/// @inheritdoc IChainlinkRegistry
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

		// Get current asset configurations
		BitMap baseConfiguration = $.configurationMaps[base];
		BitMap quoteConfiguration = $.configurationMaps[quote];

		// Register assets if they don't exist, otherwise get existing IDs
		uint8 baseId = baseConfiguration.isZero() ? _registerAsset($, base) : $.assetIds[base];
		uint8 quoteId = quoteConfiguration.isZero() ? _registerAsset($, quote) : $.assetIds[quote];

		// Update BitMaps to reflect the new price feed relationship
		$.configurationMaps[base] = baseConfiguration.set(quoteId);
		$.configurationMaps[quote] = quoteConfiguration.set(baseId);

		// Store the feed configuration with all necessary metadata
		$.feeds[base][quote] = toFeedConfig(feed, baseId, base.decimals(), quoteId, quote.decimals());

		emit FeedAdded(feed, base, quote);
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

		emit FeedRemoved(base, quote);
	}

	/// @notice Internal function to register a new asset
	/// @dev Assigns a unique ID and updates all relevant mappings
	/// @param $ Storage reference for gas optimization
	/// @param asset Address of the asset to register
	/// @return offset The assigned asset ID (0-255)
	function _registerAsset(Storage storage $, address asset) internal virtual returns (uint8 offset) {
		if ($.numAssets == MAX_ASSETS) revert ExceededMaxAssets();
		if (asset == address(0)) revert InvalidAsset();
		if (asset != Denominations.USD && $.assetIds[asset] != USD_ID) revert AssetAlreadyExists(asset);

		unchecked {
			// Find the first available asset ID slot
			while (offset < $.numAssets) {
				if ($.assets[offset] == address(0)) break;
				++offset;
			}
			++$.numAssets;
		}

		// Register the asset with its assigned ID
		$.assets[offset] = asset;
		$.assetIds[asset] = offset;

		emit AssetAdded(asset, offset);
	}

	/// @notice Internal function to deregister an asset
	/// @dev Removes all associated feeds and cleans up storage
	/// @param $ Storage reference for gas optimization
	/// @param asset Address of the asset to remove
	/// @return offset The asset ID that was freed
	function _deregisterAsset(Storage storage $, address asset) internal virtual returns (uint8 offset) {
		if (asset == address(0) || asset == Denominations.USD) revert InvalidAsset();
		if ((offset = $.assetIds[asset]) == USD_ID) revert AssetNotExists(asset);

		// Get the asset's current configuration BitMap
		BitMap configuration = $.configurationMaps[asset];

		// Remove this asset from all other assets' configuration maps
		while (!configuration.isZero()) {
			uint256 tokenId = configuration.findFirstSet();
			address token = $.assets[tokenId];
			configuration.unset(tokenId);
			$.configurationMaps[token] = $.configurationMaps[token].unset(offset);
		}

		// Clear the asset's configuration and update counters
		$.configurationMaps[asset] = configuration;
		--$.numAssets;

		// Clean up storage mappings
		delete $.assets[offset];
		delete $.assetIds[asset];

		emit AssetRemoved(asset, offset);
	}

	/// @notice Internal function to get storage reference using ERC-7201 pattern
	/// @return $ Reference to the storage struct
	function _getStorage() internal pure virtual returns (Storage storage $) {
		assembly ("memory-safe") {
			$.slot := STORAGE_SLOT
		}
	}
}
