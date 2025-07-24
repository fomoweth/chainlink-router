// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, stdJson} from "forge-std/Script.sol";
import {ForgeProxy} from "@proxy-forge/ForgeProxy.sol";
import {ChainlinkRouter} from "src/ChainlinkRouter.sol";

contract Deploy is Script {
	using stdJson for string;

	error UnsupportedChainId(uint256 chainId);

	string private constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

	bytes32 internal constant SALT = bytes32("chainlink.router.1.0.0");

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

	address internal constant USD = 0x0000000000000000000000000000000000000348;

	modifier broadcast(string memory chainAlias, address broadcaster) {
		vm.createSelectFork(chainAlias);
		vm.startBroadcast(broadcaster);
		_;
		vm.stopBroadcast();
	}

	function run() external {
		address deployer = configureBroadcaster();
		bytes32 salt = vm.envOr({name: "SALT", defaultValue: SALT});
		address initialOwner = vm.envOr({name: "OWNER", defaultValue: deployer});

		string[] memory chainAliases = vm.envString("CHAINS", ",");
		for (uint256 i; i < chainAliases.length; ++i) {
			deployToChain(chainAliases[i], salt, initialOwner, deployer);
		}
	}

	function deployToChain(
		string memory chainAlias,
		bytes32 salt,
		address owner,
		address deployer
	) internal virtual broadcast(chainAlias, deployer) {
		bytes memory params = getInitializerParameters(block.chainid, deployer);
		bytes memory data = abi.encodeCall(ChainlinkRouter.initialize, (params));

		address logic = address(new ChainlinkRouter{salt: salt}());
		address proxy = address(new ForgeProxy{salt: salt}(logic, owner, data));
		address proxyAdmin = vm.computeCreateAddress(proxy, 1);

		string memory deployment = "deployment";
		deployment.serialize("chainAlias", chainAlias);
		deployment.serialize("chainId", block.chainid);
		deployment.serialize("logic", logic);
		deployment.serialize("owner", owner);
		deployment.serialize("proxy", proxy);
		deployment.serialize("proxyAdmin", proxyAdmin);
		deployment.serialize("salt", vm.toString(salt));
		deployment.serialize("timestamp", block.timestamp);
		deployment = deployment.serialize("deployer", deployer);

		string memory path = string.concat("./deployments/", vm.toString(block.chainid), ".json");
		deployment.write(path);
	}

	function configureBroadcaster() internal virtual returns (address) {
		uint256 privateKey = vm.envOr({
			name: "PRIVATE_KEY",
			defaultValue: vm.deriveKey({
				mnemonic: vm.envOr({name: "MNEMONIC", defaultValue: TEST_MNEMONIC}),
				index: uint8(vm.envOr({name: "EOA_INDEX", defaultValue: uint256(0)}))
			})
		});

		return vm.rememberKey(privateKey);
	}

	function getInitializerParameters(
		uint256 chainId,
		address initialOwner
	) internal pure virtual returns (bytes memory arguments) {
		if (chainId == ETHEREUM_CHAIN_ID) {
			arguments = abi.encodePacked(
				initialOwner,
				0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, // ETH / USD
				0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
				USD,
				0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c, // BTC / USD
				0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, // WBTC
				USD,
				0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6, // USDC / USD
				0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
				USD,
				0x3E7d1eAB13ad0104d2750B8863b489D65364e32D, // USDT / USD
				0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
				USD
			);
		} else if (chainId == SEPOLIA_CHAIN_ID) {
			arguments = abi.encodePacked(
				initialOwner,
				0x694AA1769357215DE4FAC081bf1f309aDC325306, // ETH / USD
				0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c, // WETH
				USD,
				0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43, // BTC / USD
				0x29f2D40B0605204364af54EC677bD022dA425d03, // WBTC
				USD,
				0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E, // USDC / USD
				0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8, // USDC
				USD
			);
		} else if (chainId == OPTIMISM_CHAIN_ID) {
			arguments = abi.encodePacked(
				initialOwner,
				0x13e3Ee699D1909E989722E753853AE30b17e08c5, // ETH / USD
				0x4200000000000000000000000000000000000006, // WETH
				USD,
				0x718A5788b89454aAE3A028AE9c111A29Be6c2a6F, // BTC / USD
				0x68f180fcCe6836688e9084f035309E29Bf0A2095, // WBTC
				USD,
				0x16a9FA2FDa030272Ce99B29CF780dFA30361E0f3, // USDC / USD
				0x7F5c764cBc14f9669B88837ca1490cCa17c31607, // USDC
				USD,
				0xECef79E109e997bCA29c1c0897ec9d7b03647F5E, // USDT / USD
				0x94b008aA00579c1307B0EF2c499aD98a8ce58e58, // USDT
				USD
			);
		} else if (chainId == OPTIMISM_SEPOLIA_CHAIN_ID) {
			arguments = abi.encodePacked(
				initialOwner,
				0x61Ec26aA57019C486B10502285c5A3D4A4750AD7, // ETH / USD
				0x4200000000000000000000000000000000000006, // WETH
				USD,
				0x3015aa11f5c2D4Bd0f891E708C8927961b38cE7D, // BTC / USD
				0xC14b762bD6b4C7f40bB06E5613d0C2A1cB0f7E9c, // WBTC
				USD,
				0x6e44e50E3cc14DD16e01C590DC1d7020cb36eD4C, // USDC / USD
				0x5fd84259d66Cd46123540766Be93DFE6D43130D7, // USDC
				USD,
				0xF83696ca1b8a266163bE252bE2B94702D4929392, // USDT / USD
				0xB9467B24117FD79D56F396ADC3cCDB695D905ae4, // USDT
				USD
			);
		} else if (chainId == POLYGON_CHAIN_ID) {
			arguments = abi.encodePacked(
				initialOwner,
				0xF9680D99D6C9589e2a93a78A04A279e509205945, // ETH / USD
				0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619, // WETH
				USD,
				0xc907E116054Ad103354f2D350FD2514433D57F6f, // BTC / USD
				0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6, // WBTC
				USD,
				0x31Ebeb03223AaC82C8EB24C77624Ea40F4D849Fb, // USDC / USD
				0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, // USDC.e
				USD,
				0x31Ebeb03223AaC82C8EB24C77624Ea40F4D849Fb, // USDC / USD
				0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359, // USDC
				USD,
				0x0A6513e40db6EB1b165753AD52E80663aeA50545, // USDT / USD
				0xc2132D05D31c914a87C6611C10748AEb04B58e8F, // USDT
				USD,
				0xAB594600376Ec9fD91F8e885dADF0CE036862dE0, // MATIC / USD
				0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, // MATIC
				USD
			);
		} else if (chainId == POLYGON_AMOY_CHAIN_ID) {
			arguments = abi.encodePacked(
				initialOwner,
				0xF0d50568e3A7e8259E16663972b11910F89BD8e7, // ETH / USD
				0x52eF3d68BaB452a294342DC3e5f464d7f610f72E, // WETH
				USD,
				0xe7656e23fE8077D438aEfbec2fAbDf2D8e070C4f, // BTC / USD
				0x7E00DbB94A0802F7032301A13a6bf73Da5AFDd36, // WBTC
				USD,
				0x1b8739bB4CdF0089d07097A9Ae5Bd274b29C6F16, // USDC / USD
				0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582, // USDC
				USD,
				0x3aC23DcB4eCfcBd24579e1f34542524d0E4eDeA8, // USDT / USD
				0xbCF39d8616d15FD146dd5dB4a86b4f244A9Bc772, // USDT
				USD,
				0x001382149eBa3441043c1c66972b4772963f5D43, // MATIC / USD
				0xA5733b3A8e62A8faF43b0376d5fAF46E89B3033E, // MATIC
				USD
			);
		} else if (chainId == BASE_CHAIN_ID) {
			arguments = abi.encodePacked(
				initialOwner,
				0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70, // ETH / USD
				0x4200000000000000000000000000000000000006, // WETH
				USD,
				0x64c911996D3c6aC71f9b455B1E8E7266BcbD848F, // BTC / USD
				0x0555E30da8f98308EdB960aa94C0Db47230d2B9c, // WBTC
				USD,
				0x7e860098F58bBFC8648a4311b374B1D669a2bc6B, // USDC / USD
				0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, // USDC
				USD,
				0x7e860098F58bBFC8648a4311b374B1D669a2bc6B, // USDC / USD
				0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA, // USDbC
				USD,
				0xf19d560eB8d2ADf07BD6D13ed03e1D11215721F9, // USDT / USD
				0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2, // USDT
				USD
			);
		} else if (chainId == BASE_SEPOLIA_CHAIN_ID) {
			arguments = abi.encodePacked(
				initialOwner,
				0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1, // ETH / USD
				0x4200000000000000000000000000000000000006, // WETH
				USD,
				0x0FB99723Aee6f420beAD13e6bBB79b7E6F034298, // BTC / USD
				0x54114591963CF60EF3aA63bEfD6eC263D98145a4, // WBTC
				USD,
				0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165, // USDC / USD
				0xba50Cd2A20f6DA35D788639E581bca8d0B5d4D5f, // USDC
				USD,
				0x3ec8593F930EA45ea58c968260e6e9FF53FC934f, // USDT / USD
				0x0a215D8ba66387DCA84B284D18c3B4ec3de6E54a, // USDT
				USD
			);
		} else if (chainId == ARBITRUM_CHAIN_ID) {
			arguments = abi.encodePacked(
				initialOwner,
				0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612, // ETH / USD
				0x82aF49447D8a07e3bd95BD0d56f35241523fBab1, // WETH
				USD,
				0x6ce185860a4963106506C203335A2910413708e9, // BTC / USD
				0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f, // WBTC
				USD,
				0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3, // USDC / USD
				0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8, // USDC.e
				USD,
				0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3, // USDC / USD
				0xaf88d065e77c8cC2239327C5EDb3A432268e5831, // USDC
				USD,
				0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7, // USDT / USD
				0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9, // USDT
				USD
			);
		} else if (chainId == ARBITRUM_SEPOLIA_CHAIN_ID) {
			arguments = abi.encodePacked(
				initialOwner,
				0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165, // ETH / USD
				0x1dF462e2712496373A347f8ad10802a5E95f053D, // WETH
				USD,
				0x56a43EB56Da12C0dc1D972ACb089c06a5dEF8e69, // BTC / USD
				0x806D0637Fbbfb4EB9efD5119B0895A5C7Cbc66e7, // WBTC
				USD,
				0x0153002d20B96532C639313c2d54c3dA09109309, // USDC / USD
				0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d, // USDC
				USD,
				0x80EDee6f667eCc9f63a0a6f55578F870651f06A4, // USDT / USD
				0x7AC8519283B1bba6d683FF555A12318Ec9265229, // USDT
				USD
			);
		} else {
			revert UnsupportedChainId(chainId);
		}
	}
}
