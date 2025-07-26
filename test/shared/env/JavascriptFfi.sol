// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {CommonBase} from "forge-std/Base.sol";

abstract contract JavascriptFfi is CommonBase {
	function runScript(string memory scriptName, string memory args) internal returns (bytes memory result) {
		string[] memory cmd = new string[](8);
		cmd[0] = "npm";
		cmd[1] = "--silent";
		cmd[2] = "--prefix";
		cmd[3] = "./script/ts";
		cmd[4] = "run";
		cmd[5] = scriptName;
		cmd[6] = "--";
		cmd[7] = args;

		return vm.ffi(cmd);
	}
}
