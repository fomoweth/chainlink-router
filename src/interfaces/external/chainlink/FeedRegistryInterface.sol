// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AggregatorInterface} from "./AggregatorInterface.sol";

interface FeedRegistryInterface {
	event FeedProposed(
		address indexed asset,
		address indexed denomination,
		address indexed proposedAggregator,
		address currentAggregator,
		address sender
	);

	event FeedConfirmed(
		address indexed asset,
		address indexed denomination,
		address indexed latestAggregator,
		address previousAggregator,
		uint16 nextPhaseId,
		address sender
	);

	struct Phase {
		uint16 phaseId;
		uint80 startingAggregatorRoundId;
		uint80 endingAggregatorRoundId;
	}

	// V3 AggregatorV3Interface

	function decimals(address base, address quote) external view returns (uint8);

	function description(address base, address quote) external view returns (string memory);

	function version(address base, address quote) external view returns (uint256);

	function latestRoundData(
		address base,
		address quote
	) external view returns (uint80 round, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	function getRoundData(
		address base,
		address quote,
		uint80 roundId
	) external view returns (uint80 round, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	// V2 AggregatorInterface

	function latestAnswer(address base, address quote) external view returns (int256);

	function latestTimestamp(address base, address quote) external view returns (uint256);

	function latestRound(address base, address quote) external view returns (uint256);

	function getAnswer(address base, address quote, uint256 roundId) external view returns (int256);

	function getTimestamp(address base, address quote, uint256 roundId) external view returns (uint256);

	// Registry getters

	function getFeed(address base, address quote) external view returns (AggregatorInterface);

	function getPhaseFeed(address base, address quote, uint16 phaseId) external view returns (AggregatorInterface);

	function isFeedEnabled(address aggregator) external view returns (bool);

	function getPhase(address base, address quote, uint16 phaseId) external view returns (Phase memory phase);

	// Round helpers

	function getRoundFeed(address base, address quote, uint80 roundId) external view returns (AggregatorInterface);

	function getPhaseRange(
		address base,
		address quote,
		uint16 phaseId
	) external view returns (uint80 startingRound, uint80 endingRound);

	function getPreviousRoundId(address base, address quote, uint80 roundId) external view returns (uint80);

	function getNextRoundId(address base, address quote, uint80 roundId) external view returns (uint80 nextRound);

	// Feed management

	function proposeFeed(address asset, address denomination, address aggregator) external;

	function confirmFeed(address asset, address denomination, address aggregator) external;

	// Proposed aggregator

	function getProposedFeed(
		address asset,
		address denomination
	) external view returns (AggregatorInterface proposedAggregator);

	function proposedGetRoundData(
		address asset,
		address denomination,
		uint80 roundId
	) external view returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	function proposedLatestRoundData(
		address asset,
		address denomination
	) external view returns (uint80 id, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	// Phases

	function getCurrentPhaseId(address asset, address denomination) external view returns (uint16 currentPhaseId);
}
