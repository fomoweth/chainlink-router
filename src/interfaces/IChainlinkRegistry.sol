// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title IChainlinkRegistry - Interface for Chainlink price feed registry
/// @notice Defines the contract interface for managing Chainlink price feeds and assets
/// @dev This interface provides standardized methods for feed and asset lifecycle management
/// @author fomoweth
interface IChainlinkRegistry {
	/// @notice Thrown when attempting to register an asset that already exists
	/// @param asset The address of the asset that already exists in the registry
	error AssetAlreadyExists(address asset);

	/// @notice Thrown when attempting to operate on an asset that doesn't exist
	/// @param asset The address of the asset that was not found in the registry
	error AssetNotExists(address asset);

	/// @notice Thrown when the maximum number of supported assets is exceeded
	/// @dev Current limit is 256 assets due to BitMap implementation constraints
	error ExceededMaxAssets();

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

	/// @notice Registers multiple price feeds from packed calldata
	/// @dev Processes feeds sequentially until all calldata is consumed
	/// @param params Packed bytes containing feed configurations (20 bytes each for feed, base, quote)
	function register(bytes calldata params) external payable;

	/// @notice Deregisters multiple price feeds from packed calldata
	/// @dev Removes feed configurations and cleans up unused assets
	/// @param params Packed bytes containing asset pairs to remove (20 bytes each for base, quote)
	function deregister(bytes calldata params) external payable;

	/// @notice Registers an asset in the system
	/// @param asset The address of the asset to register
	function registerAsset(address asset) external payable;

	/// @notice Deregisters an asset from the system
	/// @dev Removes the asset and all associated price feeds
	/// @param asset The address of the asset to remove
	function deregisterAsset(address asset) external payable;
}
