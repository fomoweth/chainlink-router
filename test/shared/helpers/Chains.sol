// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Vm} from "forge-std/Vm.sol";

library Chains {
	error UnsupportedChainId(uint256 chainId);

	uint256 internal constant ANVIL = 31337;

	uint256 internal constant ETHEREUM = 1;
	uint256 internal constant SEPOLIA = 11155111;

	uint256 internal constant OPTIMISM = 10;
	uint256 internal constant OPTIMISM_SEPOLIA = 11155420;

	uint256 internal constant BNB = 56;
	uint256 internal constant BNB_TESTNET = 97;

	uint256 internal constant UNICHAIN = 130;
	uint256 internal constant UNICHAIN_SEPOLIA = 1301;

	uint256 internal constant POLYGON = 137;
	uint256 internal constant POLYGON_AMOY = 80002;

	uint256 internal constant FANTOM = 250;
	uint256 internal constant FANTOM_TESTNET = 4002;

	uint256 internal constant FRAXTAL = 252;
	uint256 internal constant FRAXTAL_SEPOLIA = 2523;

	uint256 internal constant BASE = 8453;
	uint256 internal constant BASE_SEPOLIA = 84532;

	uint256 internal constant ARBITRUM = 42161;
	uint256 internal constant ARBITRUM_SEPOLIA = 421614;

	uint256 internal constant AVALANCHE = 43114;
	uint256 internal constant AVALANCHE_FUJI = 43113;

	uint256 internal constant SCROLL = 534352;
	uint256 internal constant SCROLL_SEPOLIA = 534351;

	uint256 internal constant LINEA = 59144;
	uint256 internal constant LINEA_SEPOLIA = 59141;

	function selectChain(Vm vm, uint256 chainId) internal returns (uint256 forkId) {
		return selectChain(vm, chainId, 0);
	}

	function selectChain(Vm vm, uint256 chainId, uint256 blockNumber) internal returns (uint256 forkId) {
		if (chainId == block.chainid) {
			if (blockNumber != 0) vm.rollFork(blockNumber);
			return vm.activeFork();
		}

		forkId = blockNumber != 0
			? vm.createSelectFork(getRpcUrl(vm, chainId), blockNumber)
			: vm.createSelectFork(getRpcUrl(vm, chainId));
	}

	function getRpcUrl(Vm vm, uint256 chainId) internal view returns (string memory rpcUrl) {
		return vm.rpcUrl(getChainAlias(chainId));
	}

	function getBlockNumber() internal view returns (uint48 bn) {
		assembly ("memory-safe") {
			bn := and(sub(shl(48, 1), 1), number())
		}
	}

	function getBlockTimestamp() internal view returns (uint48 bts) {
		assembly ("memory-safe") {
			bts := and(sub(shl(48, 1), 1), timestamp())
		}
	}

	function getChainId() internal view returns (uint256 id) {
		assembly ("memory-safe") {
			id := chainid()
		}
	}

	function getChainAlias() internal view returns (string memory) {
		return getChainAlias(getChainId());
	}

	function getChainAlias(uint256 chainId) internal pure returns (string memory) {
		if (chainId == ETHEREUM) {
			return "ethereum";
		} else if (chainId == SEPOLIA) {
			return "sepolia";
		} else if (chainId == OPTIMISM) {
			return "optimism";
		} else if (chainId == OPTIMISM_SEPOLIA) {
			return "optimism_sepolia";
		} else if (chainId == BNB) {
			return "bnb";
		} else if (chainId == BNB_TESTNET) {
			return "bnb-testnet";
		} else if (chainId == POLYGON) {
			return "polygon";
		} else if (chainId == POLYGON_AMOY) {
			return "polygon-amoy";
		} else if (chainId == UNICHAIN) {
			return "unichain";
		} else if (chainId == UNICHAIN_SEPOLIA) {
			return "unichain-sepolia";
		} else if (chainId == FANTOM) {
			return "fantom";
		} else if (chainId == FANTOM_TESTNET) {
			return "fantom-testnet";
		} else if (chainId == FRAXTAL) {
			return "fraxtal";
		} else if (chainId == FRAXTAL_SEPOLIA) {
			return "fraxtal-sepolia";
		} else if (chainId == BASE) {
			return "base";
		} else if (chainId == BASE_SEPOLIA) {
			return "base-sepolia";
		} else if (chainId == ARBITRUM) {
			return "arbitrum";
		} else if (chainId == ARBITRUM_SEPOLIA) {
			return "arbitrum-sepolia";
		} else if (chainId == AVALANCHE) {
			return "avalanche";
		} else if (chainId == AVALANCHE_FUJI) {
			return "avalanche-fuji";
		} else if (chainId == SCROLL) {
			return "scroll";
		} else if (chainId == SCROLL_SEPOLIA) {
			return "scroll-sepolia";
		} else if (chainId == LINEA) {
			return "linea";
		} else if (chainId == LINEA_SEPOLIA) {
			return "linea-sepolia";
		} else {
			revert UnsupportedChainId(chainId);
		}
	}
}
