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

    uint256 internal constant POLYGON = 137;
    uint256 internal constant POLYGON_AMOY = 80002;

    uint256 internal constant BASE = 8453;
    uint256 internal constant BASE_SEPOLIA = 84532;

    uint256 internal constant ARBITRUM = 42161;
    uint256 internal constant ARBITRUM_SEPOLIA = 421614;

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
        } else if (chainId == POLYGON) {
            return "polygon";
        } else if (chainId == POLYGON_AMOY) {
            return "polygon-amoy";
        } else if (chainId == BASE) {
            return "base";
        } else if (chainId == BASE_SEPOLIA) {
            return "base-sepolia";
        } else if (chainId == ARBITRUM) {
            return "arbitrum";
        } else if (chainId == ARBITRUM_SEPOLIA) {
            return "arbitrum-sepolia";
        } else {
            revert UnsupportedChainId(chainId);
        }
    }
}
