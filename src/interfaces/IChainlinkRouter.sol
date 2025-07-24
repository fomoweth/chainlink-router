// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {BitMap} from "src/types/BitMap.sol";
import {FeedConfig} from "src/types/FeedConfig.sol";

/// @title IChainlinkRouter - Interface for routing price queries through Chainlink feeds
/// @notice Defines the contract interface for finding price paths and querying feeds
/// @dev Provides methods for both direct and multi-hop price discovery
/// @author fomoweth
interface IChainlinkRouter {
	/// @notice Thrown when no price feed path can be found between two assets
	/// @param base The base asset for which no path was found
	/// @param quote The quote asset for which no path was found
	error FeedNotFound(address base, address quote);

	/// @notice Finds optimal price path between two assets and returns the calculated price
	/// @dev Uses breadth-first search algorithm to discover shortest routing path
	/// 	 Handles automatic intermediate asset discovery and price accumulation
	/// @param base The base asset address to price
	/// @param quote The quote asset address to price against
	/// @return path Array of feed addresses used in the pricing path
	/// @return answer The calculated price after following the complete path
	function query(address base, address quote) external view returns (address[] memory path, uint256 answer);

	/// @notice Gets the feed address for a specific asset pair (bidirectional lookup)
	/// @dev Searches both base/quote and quote/base directions
	/// @param base The base asset address
	/// @param quote The quote asset address
	/// @return feed The address of the Chainlink aggregator
	function queryFeed(address base, address quote) external view returns (address feed);

	/// @notice Gets the feed address for a specific asset pair (unidirectional lookup)
	/// @dev Only searches in the exact base/quote direction specified
	/// @param base The base asset address
	/// @param quote The quote asset address
	/// @return feed The address of the Chainlink aggregator
	function getFeed(address base, address quote) external view returns (address feed);

	/// @notice Gets the complete feed configuration for an asset pair
	/// @param base The base asset address
	/// @param quote The quote asset address
	/// @return config The packed feed configuration containing all feed metadata
	function getFeedConfiguration(address base, address quote) external view returns (FeedConfig config);

	/// @notice Gets the BitMap configuration for an asset's connections
	/// @dev Shows which other assets this asset has direct feeds with
	/// @param asset The asset address to query
	/// @return configuration The BitMap representing connected assets
	function getAssetConfiguration(address asset) external view returns (BitMap configuration);

	/// @notice Gets the unique identifier for an asset
	/// @param asset The asset address
	/// @return id The unique identifier assigned to the asset
	function getAssetId(address asset) external view returns (uint256 id);

	/// @notice Gets the asset address from its unique identifier
	/// @param id The asset identifier (0-255)
	/// @return asset The address of the asset
	function getAsset(uint256 id) external view returns (address asset);

	/// @notice Gets the total number of registered assets
	/// @return The count of assets currently registered in the system
	function numAssets() external view returns (uint256);
}
