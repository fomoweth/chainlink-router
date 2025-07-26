// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {CommonBase} from "forge-std/Base.sol";
import {Vm} from "forge-std/Vm.sol";
import {ChainlinkRouter} from "src/ChainlinkRouter.sol";
import {ProxyHelpers} from "test/shared/helpers/ProxyHelpers.sol";
import {Constants} from "./Constants.sol";

abstract contract Fixtures is CommonBase {
	using ProxyHelpers for Vm;

	ChainlinkRouter internal logic;
	ChainlinkRouter internal router;
	address internal proxyAdmin;

	function deployRouter(address owner, address proxyOwner, bytes32 salt) internal virtual returns (address proxy) {
		bytes memory data = abi.encodeCall(ChainlinkRouter.initialize, (owner));

		logic = new ChainlinkRouter{salt: salt}();

		router = ChainlinkRouter(proxy = vm.deployProxy(address(logic), proxyOwner, data, salt));

		proxyAdmin = vm.computeProxyAdminAddress(address(router));

		vm.assertEq(vm.getProxyImplementation(address(router)), address(logic));
		vm.assertEq(vm.getProxyAdmin(address(router)), proxyAdmin);
		vm.assertEq(vm.getProxyOwner(proxyAdmin), proxyOwner);
		vm.assertEq(router.numAssets(), 1);
		vm.assertEq(router.owner(), owner);
	}
}
