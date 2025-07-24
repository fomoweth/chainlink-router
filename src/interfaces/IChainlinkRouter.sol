// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BitMap} from "src/types/BitMap.sol";
import {FeedConfig} from "src/types/FeedConfig.sol";

/// @title IChainlinkRouter
/// @notice Interface for ChainlinkRouter, a price oracle router built on Chainlink Aggregators
/// @dev This interface defines the standard functions and events required to register assets and feeds,
///      query on-chain prices (direct or multi-hop), and inspect registry metadata. It supports bidirectional
///      feed resolution and price path derivation using intermediate assets.
/// @author fomoweth
interface IChainlinkRouter {
	/// @notice Thrown when attempting to register an asset that already exists
	/// @param asset The address of the asset that already exists in the registry
	error AssetAlreadyExists(address asset);

	/// @notice Thrown when attempting to operate on an asset that doesn't exist
	/// @param asset The address of the asset that was not found in the registry
	error AssetNotExists(address asset);

	/// @notice Thrown when the maximum number of supported assets is exceeded
	/// @dev Current limit is 256 assets due to BitMap implementation constraints
	error ExceededMaxAssets();

	/// @notice Thrown when no price feed path can be found between two assets
	/// @param base The base asset for which no path was found
	/// @param quote The quote asset for which no path was found
	error FeedNotFound(address base, address quote);

	/// @notice Thrown when base and quote assets are identical
	/// @dev Price feeds require two different assets to form a valid trading pair
	error IdenticalAssets();

	/// @notice Thrown when an invalid asset address is provided
	/// @dev Typically occurs when address(0) is used or other validation fails
	error InvalidAsset();

	/// @notice Thrown when an invalid feed address is provided
	/// @dev Occurs when feed address is address(0) or fails other validation
	error InvalidFeed();

	/// @notice Emitted when a new asset is registered in the system
	/// @param asset The address of the registered asset
	/// @param assetId The unique identifier assigned to the asset (0-255)
	event AssetAdded(address indexed asset, uint256 indexed assetId);

	/// @notice Emitted when an asset is removed from the system
	/// @param asset The address of the removed asset
	/// @param assetId The unique identifier that was assigned to the asset
	event AssetRemoved(address indexed asset, uint256 indexed assetId);

	/// @notice Emitted when a new price feed is registered
	/// @param feed The address of the Chainlink aggregator contract
	/// @param base The address of the base asset in the price pair
	/// @param quote The address of the quote asset in the price pair
	event FeedAdded(address indexed feed, address indexed base, address indexed quote);

	/// @notice Emitted when a price feed is removed from the registry
	/// @param base The address of the base asset in the removed price pair
	/// @param quote The address of the quote asset in the removed price pair
	event FeedRemoved(address indexed base, address indexed quote);

	/// @notice Queries optimal price path between two assets and returns the calculated price
	/// @dev Uses breadth-first search algorithm to discover shortest routing path
	/// 	 Handles automatic intermediate asset discovery and price accumulation
	/// @param base The base asset address to price
	/// @param quote The quote asset address to price against
	/// @return path Array of feed addresses used for price derivation
	/// @return answer The calculated price after following the complete path
	function query(address base, address quote) external view returns (address[] memory path, uint256 answer);

	/// @notice Returns the feed address for a specific asset pair (bidirectional lookup)
	/// @dev Searches both base/quote and quote/base directions
	/// @param base The base asset address
	/// @param quote The quote asset address
	/// @return feed The address of the Chainlink aggregator
	function queryFeed(address base, address quote) external view returns (address feed);

	/// @notice Returns the feed address for a specific asset pair (unidirectional lookup)
	/// @dev Only searches in the exact base/quote direction specified
	/// @param base The base asset address
	/// @param quote The quote asset address
	/// @return feed The address of the Chainlink aggregator
	function getFeed(address base, address quote) external view returns (address feed);

	/// @notice Returns the complete feed configuration for an asset pair
	/// @param base The base asset address
	/// @param quote The quote asset address
	/// @return config The packed feed configuration containing all feed metadata
	function getFeedConfiguration(address base, address quote) external view returns (FeedConfig config);

	/// @notice Returns the asset address from its unique identifier
	/// @param id The asset identifier (0-255)
	/// @return asset The address of the asset
	function getAsset(uint256 id) external view returns (address asset);

	/// @notice Returns the BitMap configuration for an asset's connections
	/// @dev Shows which other assets this asset has direct feeds with
	/// @param asset The asset address to query
	/// @return configuration The BitMap representing connected assets
	function getAssetConfiguration(address asset) external view returns (BitMap configuration);

	/// @notice Returns the unique identifier for an asset
	/// @param asset The asset address
	/// @return id The unique identifier assigned to the asset
	function getAssetId(address asset) external view returns (uint256 id);

	/// @notice Returns the total number of registered assets
	/// @return The count of assets currently registered in the system
	function numAssets() external view returns (uint256);

	/// @notice Registers new feeds in batch
	/// @dev Processes feeds sequentially until all calldata is consumed
	/// @param params Packed bytes containing feed configurations (20 bytes each for feed, base, quote)
	function register(bytes calldata params) external payable;

	/// @notice Deregisters existing feeds in batch
	/// @dev Removes feed configurations and cleans up unused assets
	/// @param params Packed bytes containing asset pairs (20 bytes each for base, quote)
	function deregister(bytes calldata params) external payable;

	/// @notice Registers a new asset in the system
	/// @param asset The address of the asset to register
	function registerAsset(address asset) external payable;

	/// @notice Deregisters an existing asset and removes all associated feeds from the system
	/// @param asset The address of the asset to deregister
	function deregisterAsset(address asset) external payable;
}
