// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface AggregatorInterface {
	event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

	event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

	// V2 AggregatorInterface

	function latestAnswer() external view returns (int256);

	function latestTimestamp() external view returns (uint256);

	function latestRound() external view returns (uint256);

	function getAnswer(uint256 roundId) external view returns (int256);

	function getTimestamp(uint256 roundId) external view returns (uint256);

	// V3 AggregatorV3Interface

	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	function getRoundData(
		uint80 roundId
	) external view returns (uint80 round, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	function latestRoundData()
		external
		view
		returns (uint80 round, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
