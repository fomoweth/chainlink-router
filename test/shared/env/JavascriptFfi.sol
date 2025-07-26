// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {CommonBase} from "forge-std/Base.sol";

abstract contract JavascriptFfi is CommonBase {
	function runScript(string memory file, string memory args) internal returns (bytes memory result) {
		string[] memory cmd = new string[](4);
		cmd[0] = "npx";
		cmd[1] = "ts-node";
		cmd[2] = string.concat("script/ts/", file, ".ts");
		cmd[3] = args;

		return vm.ffi(cmd);
	}
}
