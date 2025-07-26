// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {AggregatorInterface} from "src/interfaces/external/AggregatorInterface.sol";
import {Denominations} from "src/libraries/Denominations.sol";
import {ChainlinkRouter} from "src/ChainlinkRouter.sol";
import {Chains} from "test/shared/helpers/Chains.sol";
import {Constants} from "./Constants.sol";
import {Fixtures} from "./Fixtures.sol";
import {JavascriptFfi} from "./JavascriptFfi.sol";

abstract contract BaseTest is Test, Constants, Fixtures, JavascriptFfi {
	using Chains for Vm;
	using Denominations for address;

	address internal immutable proxyOwner = makeAddr("ChainlinkRouter ProxyOwner");
	address internal immutable unknown = makeAddr("Unknown");

	uint256 internal snapshotId = type(uint256).max;

	modifier impersonate(address account) {
		vm.startPrank(account);
		_;
		vm.stopPrank();
	}

	function setUp() public virtual {
		revertToState();

		vm.selectChain(Chains.ETHEREUM, ETHEREUM_FORK_BLOCK);

		deployRouter(address(this), proxyOwner, bytes32(0));

		vm.label(address(logic), "ChainlinkRouter Logic");
		vm.label(address(router), "ChainlinkRouter Proxy");
		vm.label(proxyAdmin, "ChainlinkRouter ProxyAdmin");
	}

	function revertToState() internal virtual {
		if (snapshotId != type(uint256).max) vm.revertToState(snapshotId);
		snapshotId = vm.snapshotState();
	}

	function getInverseAnswer(address feed, address base, address quote) internal view virtual returns (uint256) {
		return 10 ** (base.decimals() + quote.decimals()) / getLatestAnswer(feed);
	}

	function getLatestAnswer(address feed) internal view virtual returns (uint256 answer) {
		return uint256(AggregatorInterface(feed).latestAnswer());
	}
}
