// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Vm} from "forge-std/Vm.sol";
import {ForgeProxy} from "proxy-forge/ForgeProxy.sol";

library ProxyHelpers {
    Vm private constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    bytes32 internal constant ERC1967_ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    bytes32 internal constant ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    bytes32 internal constant PROXY_ADMIN_OWNER_SLOT =
        0x9bc353c4ee8d049c7cb68b79467fc95d9015a8a82334bd0e61ce699e20cb5bd5;

    function deployProxy(address logic, address owner, bytes memory data, bytes32 salt)
        internal
        returns (address proxy)
    {
        return deployProxy(logic, owner, data, salt, 0);
    }

    function deployProxy(address logic, address owner, bytes memory data, bytes32 salt, uint256 value)
        internal
        returns (address proxy)
    {
        return address(new ForgeProxy{salt: salt, value: value}(logic, owner, data));
    }

    function upgradeProxy(address proxy, address logic, bytes memory data) internal {
        upgradeProxy(proxy, logic, data, 0);
    }

    function upgradeProxy(address proxy, address logic, bytes memory data, uint256 value) internal {
        bytes memory payload = abi.encodeWithSignature("upgradeAndCall(address,address,bytes)", proxy, logic, data);

        address proxyAdmin = getProxyAdmin(proxy);
        vm.prank(getProxyOwner(proxyAdmin));

        (bool success,) = proxyAdmin.call{value: value}(payload);
        vm.assertTrue(success);
    }

    function getProxyImplementation(address proxy) internal view returns (address) {
        return fromLast20Bytes(vm.load(proxy, ERC1967_IMPLEMENTATION_SLOT));
    }

    function getProxyAdmin(address proxy) internal view returns (address) {
        return fromLast20Bytes(vm.load(proxy, ERC1967_ADMIN_SLOT));
    }

    function getProxyOwner(address admin) internal view returns (address) {
        return fromLast20Bytes(vm.load(admin, PROXY_ADMIN_OWNER_SLOT));
    }

    function computeProxyAddress(address deployer, bytes32 hash, bytes32 salt) internal pure returns (address proxy) {
        return vm.computeCreate2Address(salt, hash, deployer);
    }

    function computeProxyAddress(address deployer) internal view returns (address proxy) {
        return vm.computeCreateAddress(deployer, vm.getNonce(deployer));
    }

    function computeProxyAdminAddress(address proxy) internal pure returns (address) {
        return vm.computeCreateAddress(proxy, 1);
    }

    function fromLast20Bytes(bytes32 value) internal pure returns (address) {
        return address(uint160(uint256(value)));
    }
}
