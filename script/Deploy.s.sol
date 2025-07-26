// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {stdJson} from "forge-std/StdJson.sol";
import {ForgeProxy} from "@proxy-forge/ForgeProxy.sol";
import {ChainlinkRouter} from "src/ChainlinkRouter.sol";
import {BaseScript} from "./BaseScript.sol";

contract Deploy is BaseScript {
	using stdJson for string;

	bytes32 internal constant DEFAULT_SALT = bytes32("chainlink.router.1.0.0");

	bytes32 internal salt;
	address internal owner;
	address internal proxyOwner;

	function setUp() public virtual override {
		super.setUp();

		salt = vm.envOr({name: "SALT", defaultValue: DEFAULT_SALT});
		owner = vm.envOr({name: "OWNER", defaultValue: broadcaster});
		proxyOwner = vm.envOr({name: "PROXY_OWNER", defaultValue: broadcaster});
	}

	function run() external {
		string[] memory chainAliases = vm.envString("CHAINS", ",");
		for (uint256 i; i < chainAliases.length; ++i) {
			vm.createSelectFork(chainAliases[i]);
			deployToChain(chainAliases[i]);
		}
	}

	function deployToChain(string memory chainAlias) internal virtual broadcast {
		bytes memory data = abi.encodeCall(ChainlinkRouter.initialize, (owner));

		address logic = address(new ChainlinkRouter{salt: salt}());
		address proxy = address(new ForgeProxy{salt: salt}(logic, proxyOwner, data));
		address proxyAdmin = vm.computeCreateAddress(proxy, 1);

		string memory deployment = "deployment";
		deployment.serialize("chainAlias", chainAlias);
		deployment.serialize("chainId", block.chainid);
		deployment.serialize("logic", logic);
		deployment.serialize("owner", proxyOwner);
		deployment.serialize("proxy", proxy);
		deployment.serialize("proxyAdmin", proxyAdmin);
		deployment.serialize("salt", vm.toString(salt));
		deployment.serialize("timestamp", block.timestamp);
		deployment = deployment.serialize("broadcaster", broadcaster);

		string memory path = string.concat("./deployments/", vm.toString(block.chainid), ".json");
		deployment.write(path);
	}
}
