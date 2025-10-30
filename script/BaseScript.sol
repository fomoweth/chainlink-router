// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";

abstract contract BaseScript is Script {
    error UnsupportedChainId(uint256 chainId);

    string private constant DEFAULT_MNEMONIC = "test test test test test test test test test test test junk";

    uint256 internal constant ETHEREUM_CHAIN_ID = 1;
    uint256 internal constant SEPOLIA_CHAIN_ID = 11155111;

    uint256 internal constant OPTIMISM_CHAIN_ID = 10;
    uint256 internal constant OPTIMISM_SEPOLIA_CHAIN_ID = 11155420;

    uint256 internal constant POLYGON_CHAIN_ID = 137;
    uint256 internal constant POLYGON_AMOY_CHAIN_ID = 80002;

    uint256 internal constant BASE_CHAIN_ID = 8453;
    uint256 internal constant BASE_SEPOLIA_CHAIN_ID = 84532;

    uint256 internal constant ARBITRUM_CHAIN_ID = 42161;
    uint256 internal constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;

    address broadcaster;

    modifier broadcast() {
        vm.startBroadcast(broadcaster);
        _;
        vm.stopBroadcast();
    }

    function setUp() public virtual {
        uint256 privateKey = vm.envOr({
            name: "PRIVATE_KEY",
            defaultValue: vm.deriveKey({
                mnemonic: vm.envOr({name: "MNEMONIC", defaultValue: DEFAULT_MNEMONIC}),
                index: uint8(vm.envOr({name: "EOA_INDEX", defaultValue: uint256(0)}))
            })
        });

        broadcaster = vm.rememberKey(privateKey);
    }

    function forkChain(uint256 chainId) internal virtual {
        if (chainId == ETHEREUM_CHAIN_ID) {
            vm.createSelectFork("ethereum");
        } else if (chainId == SEPOLIA_CHAIN_ID) {
            vm.createSelectFork("sepolia");
        } else if (chainId == OPTIMISM_CHAIN_ID) {
            vm.createSelectFork("optimism");
        } else if (chainId == OPTIMISM_SEPOLIA_CHAIN_ID) {
            vm.createSelectFork("optimism-sepolia");
        } else if (chainId == POLYGON_CHAIN_ID) {
            vm.createSelectFork("polygon");
        } else if (chainId == POLYGON_AMOY_CHAIN_ID) {
            vm.createSelectFork("polygon-amoy");
        } else if (chainId == BASE_CHAIN_ID) {
            vm.createSelectFork("base");
        } else if (chainId == BASE_SEPOLIA_CHAIN_ID) {
            vm.createSelectFork("base-sepolia");
        } else if (chainId == ARBITRUM_CHAIN_ID) {
            vm.createSelectFork("arbitrum");
        } else if (chainId == ARBITRUM_SEPOLIA_CHAIN_ID) {
            vm.createSelectFork("arbitrum-sepolia");
        } else {
            revert UnsupportedChainId(chainId);
        }
    }
}
