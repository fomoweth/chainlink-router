// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {stdJson} from "forge-std/StdJson.sol";
import {ChainlinkRouter} from "src/ChainlinkRouter.sol";
import {BaseScript} from "./BaseScript.sol";

contract Register is BaseScript {
	using stdJson for string;

	ChainlinkRouter internal router;

	function setUp() public virtual override {
		super.setUp();

		forkChain(block.chainid);

		string memory json = vm.readFile(string.concat("./deployments/", vm.toString(block.chainid), ".json"));

		router = ChainlinkRouter(json.readAddress("$.proxy"));
		vm.assertTrue(address(router).code.length != 0);
	}

	function run() external broadcast {
		string[] memory cmd = new string[](4);
		cmd[0] = "npx";
		cmd[1] = "ts-node";
		cmd[2] = "script/ts/extract-feeds.ts";
		cmd[3] = vm.toString(block.chainid);

		bytes memory params = vm.ffi(cmd);
		router.register(params);
	}
}
