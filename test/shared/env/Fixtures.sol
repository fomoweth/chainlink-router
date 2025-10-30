// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {CommonBase} from "forge-std/Base.sol";
import {Vm} from "forge-std/Vm.sol";
import {ChainlinkRouter} from "src/ChainlinkRouter.sol";
import {ProxyHelpers} from "test/shared/helpers/ProxyHelpers.sol";

abstract contract Fixtures is CommonBase {
    using ProxyHelpers for address;

    ChainlinkRouter internal logic;
    ChainlinkRouter internal router;
    address internal proxyAdmin;

    function deployRouter(address owner, address proxyOwner, bytes32 salt) internal virtual returns (address proxy) {
        bytes memory data = abi.encodeCall(ChainlinkRouter.initialize, (owner));

        logic = new ChainlinkRouter{salt: salt}();
        router = ChainlinkRouter(proxy = address(logic).deployProxy(proxyOwner, data, salt));
        proxyAdmin = address(router).computeProxyAdminAddress();

        vm.assertEq(address(router).getProxyImplementation(), address(logic));
        vm.assertEq(address(router).getProxyAdmin(), proxyAdmin);
        vm.assertEq(proxyAdmin.getProxyOwner(), proxyOwner);
    }
}
