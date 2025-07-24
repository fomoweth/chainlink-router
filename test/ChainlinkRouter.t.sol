// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {AggregatorInterface} from "src/interfaces/external/AggregatorInterface.sol";
import {ChainlinkRouter, IChainlinkRouter} from "src/ChainlinkRouter.sol";
import {PriceMath} from "src/libraries/PriceMath.sol";
import {BitMap} from "src/types/BitMap.sol";
import {Initializable} from "src/base/Initializable.sol";
import {Ownable} from "src/base/Ownable.sol";
import {FeedConfig} from "src/types/FeedConfig.sol";
import {ProxyHelpers} from "test/shared/ProxyHelpers.sol";
import {SolArray} from "test/shared/SolArray.sol";

contract ChainlinkRouterTest is Test {
	using ProxyHelpers for Vm;

	bytes32 internal constant INITIALIZED_SLOT = 0xeb0c2ce5f191d27e756051385ba4f8f2e0c18127de8ff7207a5891e3b49bb400;

	uint256 internal constant ETHEREUM_FORK_BLOCK = 22962547;

	address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	address internal constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
	address internal constant USD = 0x0000000000000000000000000000000000000348;

	address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address internal constant ETH_BTC = 0xAc559F25B1619171CbC396a50854A3240b6A4e99;
	address internal constant ETH_USD = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

	address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
	address internal constant BTC_ETH = 0xdeb288F737066589598e9214E782fa5A8eD689e8;
	address internal constant BTC_USD = 0x4a3411ac2948B33c69666B35cc6d055B27Ea84f1;

	address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
	address internal constant USDC_ETH = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4;
	address internal constant USDC_USD = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;

	address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
	address internal constant USDT_ETH = 0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46;
	address internal constant USDT_USD = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;

	address internal constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
	address internal constant AAVE_ETH = 0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012;
	address internal constant AAVE_USD = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;

	address internal constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
	address internal constant COMP_ETH = 0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699;
	address internal constant COMP_USD = 0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5;

	address internal constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
	address internal constant LINK_ETH = 0xDC530D9457755926550b59e8ECcdaE7624181557;
	address internal constant LINK_USD = 0xC7e9b623ed51F033b32AE7f1282b1AD62C28C183;

	address internal constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
	address internal constant UNI_ETH = 0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e;
	address internal constant UNI_USD = 0x553303d460EE0afB37EdFf9bE42922D8FF63220e;

	address internal immutable admin = makeAddr("Admin");
	address internal immutable unknown = makeAddr("Unknown");
	address internal immutable proxyOwner = makeAddr("ChainlinkRouter ProxyOwner");

	ChainlinkRouter internal logic;
	ChainlinkRouter internal router;
	address internal proxyAdmin;

	modifier impersonate(address account) {
		vm.startPrank(account);
		_;
		vm.stopPrank();
	}

	function setUp() public {
		vm.createSelectFork(vm.envOr("RPC_ETHEREUM", getChain(1).rpcUrl), ETHEREUM_FORK_BLOCK);

		bytes memory params = abi.encodePacked(
			admin,
			ETH_USD,
			WETH,
			USD,
			BTC_USD,
			WBTC,
			USD,
			USDC_USD,
			USDC,
			USD,
			USDT_USD,
			USDT,
			USD
		);

		bytes memory data = abi.encodeCall(ChainlinkRouter.initialize, (params));

		logic = new ChainlinkRouter();

		router = ChainlinkRouter(vm.deployProxy(address(logic), proxyOwner, data, bytes32(0)));

		proxyAdmin = vm.computeProxyAdminAddress(address(router));

		assertEq(vm.getProxyImplementation(address(router)), address(logic));
		assertEq(vm.getProxyAdmin(address(router)), proxyAdmin);
		assertEq(vm.getProxyOwner(proxyAdmin), proxyOwner);

		vm.label(address(logic), "ChainlinkRouter Logic");
		vm.label(address(router), "ChainlinkRouter Proxy");
		vm.label(proxyAdmin, "ChainlinkRouter ProxyAdmin");
	}

	function test_constructor() public view {
		assertEq(uint256(vm.load(address(logic), INITIALIZED_SLOT)), type(uint64).max);
		assertEq(logic.owner(), address(0));
		assertEq(logic.numAssets(), 0);
	}

	function test_initialize() public view {
		assertEq(router.owner(), admin);
		assertEq(router.numAssets(), 5);
		assertEq(router.getAssetId(USD), 0);
		assertEq(router.getAsset(0), USD);

		address[] memory feeds = SolArray.addresses(ETH_USD, BTC_USD, USDC_USD, USDT_USD);
		address[] memory assets = SolArray.addresses(WETH, WBTC, USDC, USDT);

		for (uint256 i; i < feeds.length; ++i) {
			assertEq(router.getAssetId(assets[i]), i + 1);
			assertEq(router.getAsset(i + 1), assets[i]);
			assertEq(router.getFeed(assets[i], USD), feeds[i]);
		}
	}

	function test_initialize_revertsOnReinitialization() public {
		vm.expectRevert(Initializable.InvalidInitialization.selector);
		router.initialize(abi.encodePacked(admin));
	}

	function test_registerAsset() public impersonate(admin) {
		uint256 initialCount = router.numAssets();

		vm.expectEmit(true, true, true, true, address(router));
		emit IChainlinkRouter.AssetAdded(LINK, initialCount);

		router.registerAsset(LINK);

		assertEq(router.getAssetId(LINK), initialCount);
		assertEq(router.getAsset(initialCount), LINK);
		assertEq(router.numAssets(), initialCount + 1);

		vm.expectRevert(abi.encodeWithSelector(IChainlinkRouter.AssetAlreadyExists.selector, LINK));
		router.registerAsset(LINK);
	}

	function test_registerAsset_revertsOnExceededMaxAssets() public impersonate(admin) {
		vm.expectEmit(true, true, true, true, address(router));

		for (uint256 i = router.numAssets(); i < 256; ++i) {
			address asset = address(uint160(i));
			emit IChainlinkRouter.AssetAdded(asset, i);
			router.registerAsset(asset);
		}

		vm.expectRevert(IChainlinkRouter.ExceededMaxAssets.selector);
		router.registerAsset(LINK);
	}

	function test_registerAsset_revertsOnInvalidAsset() public impersonate(admin) {
		vm.expectRevert(IChainlinkRouter.InvalidAsset.selector);
		router.registerAsset(address(0));
	}

	function test_registerAsset_revertsIfUnauthorized() public impersonate(unknown) {
		vm.expectRevert(abi.encodeWithSelector(Ownable.UnauthorizedAccount.selector, unknown));
		router.registerAsset(LINK);
	}

	function test_deregisterAsset() public impersonate(admin) {
		vm.expectRevert(abi.encodeWithSelector(IChainlinkRouter.AssetNotExists.selector, LINK));
		router.deregisterAsset(LINK);

		router.registerAsset(LINK);

		uint256 initialCount = router.numAssets();
		uint256 assetId = router.getAssetId(LINK);

		vm.expectEmit(true, true, true, true, address(router));
		emit IChainlinkRouter.AssetRemoved(LINK, assetId);

		router.deregisterAsset(LINK);

		assertEq(router.getAssetId(LINK), 0);
		assertEq(router.getAsset(assetId), address(0));
		assertEq(router.numAssets(), initialCount - 1);
	}

	function test_deregisterAsset_revertsOnInvalidAsset() public impersonate(admin) {
		vm.expectRevert(IChainlinkRouter.InvalidAsset.selector);
		router.deregisterAsset(address(0));

		vm.expectRevert(IChainlinkRouter.InvalidAsset.selector);
		router.deregisterAsset(USD);
	}

	function test_deregisterAsset_revertsIfUnauthorized() public impersonate(unknown) {
		vm.expectRevert(abi.encodeWithSelector(Ownable.UnauthorizedAccount.selector, unknown));
		router.deregisterAsset(LINK);
	}

	function test_register() public impersonate(admin) {
		uint256 initialCount = router.numAssets();

		vm.expectEmit(true, true, true, true, address(router));
		emit IChainlinkRouter.AssetAdded(LINK, initialCount);
		emit IChainlinkRouter.FeedAdded(LINK_ETH, LINK, WETH);

		router.register(abi.encodePacked(LINK_ETH, LINK, WETH));

		assertEq(router.getAssetId(LINK), initialCount);
		assertEq(router.getAsset(initialCount), LINK);
		assertEq(router.getFeed(LINK, WETH), LINK_ETH);

		emit IChainlinkRouter.FeedAdded(LINK_USD, LINK, USD);

		router.register(abi.encodePacked(LINK_USD, LINK, USD));

		assertEq(router.getFeed(LINK, USD), LINK_USD);
		assertEq(router.numAssets(), initialCount + 1);
	}

	function test_register_multipleFeeds() public impersonate(admin) {
		address[] memory feeds = SolArray.addresses(AAVE_ETH, COMP_ETH, LINK_ETH, UNI_ETH);

		address[] memory assets = SolArray.addresses(AAVE, COMP, LINK, UNI);

		uint256 initialCount = router.numAssets();

		vm.expectEmit(true, true, true, true, address(router));

		bytes memory params;
		for (uint256 i; i < feeds.length; ++i) {
			emit IChainlinkRouter.FeedAdded(feeds[i], assets[i], WETH);
			params = abi.encodePacked(params, feeds[i], assets[i], WETH);
		}

		router.register(params);

		for (uint256 i; i < feeds.length; ++i) {
			assertEq(router.getFeed(assets[i], WETH), feeds[i]);
		}

		assertEq(router.numAssets(), initialCount + assets.length);
	}

	function test_register_revertsOnInvalidFeed() public impersonate(admin) {
		vm.expectRevert(IChainlinkRouter.InvalidFeed.selector);
		router.register(abi.encodePacked(address(0), LINK, WETH));
	}

	function test_register_revertsOnIdenticalAssets() public impersonate(admin) {
		vm.expectRevert(IChainlinkRouter.IdenticalAssets.selector);
		router.register(abi.encodePacked(LINK_ETH, LINK, LINK));
	}

	function test_register_revertsIfUnauthorized() public impersonate(unknown) {
		vm.expectRevert(abi.encodeWithSelector(Ownable.UnauthorizedAccount.selector, unknown));
		router.register(abi.encodePacked(LINK_ETH, LINK, WETH, LINK_USD, LINK, USD));
	}

	function test_deregister() public impersonate(admin) {
		router.register(abi.encodePacked(LINK_ETH, LINK, WETH, LINK_USD, LINK, USD));

		uint256 initialCount = router.numAssets();
		uint256 assetId = router.getAssetId(LINK);

		vm.expectEmit(true, true, true, true, address(router));
		emit IChainlinkRouter.FeedRemoved(LINK, WETH);

		router.deregister(abi.encodePacked(LINK, WETH));

		assertEq(router.getAssetId(LINK), assetId);
		assertEq(router.getAsset(assetId), LINK);
		assertEq(router.getFeed(LINK, WETH), address(0));

		emit IChainlinkRouter.AssetRemoved(LINK, router.getAssetId(LINK));
		emit IChainlinkRouter.FeedRemoved(LINK, USD);

		router.deregister(abi.encodePacked(LINK, USD));

		assertEq(router.getAssetId(LINK), 0);
		assertEq(router.getAsset(assetId), address(0));
		assertEq(router.getFeed(LINK, USD), address(0));
		assertEq(router.numAssets(), initialCount - 1);
	}

	function test_deregister_multipleFeeds() public impersonate(admin) {
		address[] memory feeds = SolArray.addresses(AAVE_ETH, COMP_ETH, LINK_ETH, UNI_ETH);

		address[] memory assets = SolArray.addresses(AAVE, COMP, LINK, UNI);

		bytes memory params;
		for (uint256 i; i < feeds.length; ++i) {
			params = abi.encodePacked(params, feeds[i], assets[i], WETH);
		}

		router.register(params);

		uint256 initialCount = router.numAssets();

		vm.expectEmit(true, true, true, true, address(router));

		params = "";
		for (uint256 i; i < assets.length; ++i) {
			emit IChainlinkRouter.FeedRemoved(assets[i], WETH);
			params = abi.encodePacked(params, assets[i], WETH);
		}

		router.deregister(params);

		for (uint256 i; i < assets.length; ++i) {
			assertEq(router.getFeed(assets[i], WETH), address(0));
		}

		assertEq(router.numAssets(), initialCount - assets.length);
	}

	function test_deregister_revertsOnIdenticalAssets() public impersonate(admin) {
		vm.expectRevert(IChainlinkRouter.IdenticalAssets.selector);
		router.deregister(abi.encodePacked(LINK, LINK));
	}

	function test_deregister_revertsIfUnauthorized() public impersonate(unknown) {
		vm.expectRevert(abi.encodeWithSelector(Ownable.UnauthorizedAccount.selector, unknown));
		router.deregister(abi.encodePacked(LINK, WETH));
	}

	function test_getAssetConfiguration() public view {
		BitMap configuration = router.getAssetConfiguration(USD);
		assertTrue(!configuration.isZero());
		assertTrue(configuration.get(router.getAssetId(WETH)));
		assertTrue(configuration.get(router.getAssetId(WBTC)));
		assertTrue(configuration.get(router.getAssetId(USDC)));
		assertTrue(configuration.get(router.getAssetId(USDT)));
	}

	function test_getFeedConfiguration() public view {
		FeedConfig configuration = router.getFeedConfiguration(WETH, USD);
		assertTrue(!configuration.isZero());
		assertEq(configuration.feed(), ETH_USD);
		assertEq(configuration.baseId(), router.getAssetId(WETH));
		assertEq(configuration.baseDecimals(), 18);
		assertEq(configuration.quoteId(), router.getAssetId(USD));
		assertEq(configuration.quoteDecimals(), 8);
	}

	function test_getFeedConfiguration_revertsOnIdenticalAssets() public {
		vm.expectRevert(IChainlinkRouter.IdenticalAssets.selector);
		router.getFeedConfiguration(WETH, WETH);
	}

	function test_queryFeed_findsDirectFeed() public view {
		assertEq(router.queryFeed(WETH, USD), ETH_USD);
	}

	function test_queryFeed_findsBidirectionalFeed() public view {
		assertEq(router.queryFeed(USD, WETH), ETH_USD);
	}

	function test_queryFeed_revertsOnIdenticalAssets() public {
		vm.expectRevert(IChainlinkRouter.IdenticalAssets.selector);
		router.queryFeed(WETH, WETH);
	}

	function test_getFeed_exactDirectionOnly() public view {
		assertEq(router.getFeed(WETH, USD), ETH_USD);
		assertEq(router.getFeed(USD, WETH), address(0));
	}

	function test_getFeed_revertsOnIdenticalAssets() public {
		vm.expectRevert(IChainlinkRouter.IdenticalAssets.selector);
		router.getFeed(WETH, WETH);
	}

	function test_query_singleHop() public view {
		(address[] memory path, uint256 price) = router.query(WETH, USD);
		uint256 expected = uint256(AggregatorInterface(ETH_USD).latestAnswer());

		assertEq(path.length, 1);
		assertEq(path[0], ETH_USD);
		assertEq(price, expected);
	}

	function test_query_singleHop_inverted() public view {
		(address[] memory path, uint256 price) = router.query(USD, WETH);
		uint256 expected = 10 ** (18 + 8) / uint256(AggregatorInterface(ETH_USD).latestAnswer());

		assertEq(path.length, 1);
		assertEq(path[0], ETH_USD);
		assertEq(price, expected);
	}

	function test_query_2Hops() public view {
		(address[] memory path, uint256 price) = router.query(USDC, WETH);
		uint256 expected = uint256(AggregatorInterface(USDC_ETH).latestAnswer());

		assertEq(path.length, 2);
		assertEq(path[0], USDC_USD);
		assertEq(path[1], ETH_USD);
		assertApproxEqAbs(price, expected, 0.000001e18);
	}

	function test_query_2Hops_inverted() public view {
		(address[] memory path, uint256 price) = router.query(WETH, USDC);
		uint256 expected = 10 ** (6 + 18) / uint256(AggregatorInterface(USDC_ETH).latestAnswer());

		assertEq(path.length, 2);
		assertEq(path[0], ETH_USD);
		assertEq(path[1], USDC_USD);
		assertApproxEqAbs(price, expected, 12e6);
	}

	function test_query_3Hops_inverted() public impersonate(admin) {
		bytes memory params = abi.encodePacked(
			LINK_ETH,
			LINK,
			WETH,
			AAVE_ETH,
			AAVE,
			WETH,
			COMP_ETH,
			COMP,
			WETH,
			UNI_ETH,
			UNI,
			WETH
		);
		router.register(params);

		address[] memory path;
		uint256 price;
		uint256 expected;

		(path, price) = router.query(USDC, LINK);
		expected = 10 ** (18 + 8) / uint256(AggregatorInterface(LINK_USD).latestAnswer());

		assertEq(path.length, 3);
		assertEq(path[0], USDC_USD);
		assertEq(path[1], ETH_USD);
		assertEq(path[2], LINK_ETH);
		assertApproxEqAbs(price, expected, 0.001e18);

		(path, price) = router.query(USDC, AAVE);
		expected = 10 ** (18 + 8) / uint256(AggregatorInterface(AAVE_USD).latestAnswer());

		assertEq(path.length, 3);
		assertEq(path[0], USDC_USD);
		assertEq(path[1], ETH_USD);
		assertEq(path[2], AAVE_ETH);
		assertApproxEqAbs(price, expected, 0.001e18);

		(path, price) = router.query(USDC, COMP);
		expected = 10 ** (18 + 8) / uint256(AggregatorInterface(COMP_USD).latestAnswer());

		assertEq(path.length, 3);
		assertEq(path[0], USDC_USD);
		assertEq(path[1], ETH_USD);
		assertEq(path[2], COMP_ETH);
		assertApproxEqAbs(price, expected, 0.001e18);

		(path, price) = router.query(USDC, UNI);
		expected = 10 ** (18 + 8) / uint256(AggregatorInterface(UNI_USD).latestAnswer());

		assertEq(path.length, 3);
		assertEq(path[0], USDC_USD);
		assertEq(path[1], ETH_USD);
		assertEq(path[2], UNI_ETH);
		assertApproxEqAbs(price, expected, 0.001e18);
	}

	function test_query_3Hops() public impersonate(admin) {
		bytes memory params = abi.encodePacked(
			LINK_ETH,
			LINK,
			WETH,
			AAVE_ETH,
			AAVE,
			WETH,
			COMP_ETH,
			COMP,
			WETH,
			UNI_ETH,
			UNI,
			WETH
		);
		router.register(params);

		address[] memory path;
		uint256 price;
		uint256 expected;

		(path, price) = router.query(LINK, USDC);
		expected = uint256(AggregatorInterface(LINK_USD).latestAnswer()) / 1e2;

		assertEq(path.length, 3);
		assertEq(path[0], LINK_ETH);
		assertEq(path[1], ETH_USD);
		assertEq(path[2], USDC_USD);
		assertApproxEqAbs(price, expected, 1e6);

		(path, price) = router.query(AAVE, USDC);
		expected = uint256(AggregatorInterface(AAVE_USD).latestAnswer()) / 1e2;

		assertEq(path.length, 3);
		assertEq(path[0], AAVE_ETH);
		assertEq(path[1], ETH_USD);
		assertEq(path[2], USDC_USD);
		assertApproxEqAbs(price, expected, 1e6);

		(path, price) = router.query(COMP, USDC);
		expected = uint256(AggregatorInterface(COMP_USD).latestAnswer()) / 1e2;

		assertEq(path.length, 3);
		assertEq(path[0], COMP_ETH);
		assertEq(path[1], ETH_USD);
		assertEq(path[2], USDC_USD);
		assertApproxEqAbs(price, expected, 1e6);

		(path, price) = router.query(UNI, USDC);
		expected = uint256(AggregatorInterface(UNI_USD).latestAnswer()) / 1e2;

		assertEq(path.length, 3);
		assertEq(path[0], UNI_ETH);
		assertEq(path[1], ETH_USD);
		assertEq(path[2], USDC_USD);
		assertApproxEqAbs(price, expected, 1e6);
	}

	function test_query_revertsOnNoPath() public {
		vm.expectRevert();
		router.query(LINK, USD);
	}

	function test_query_revertsOnIdenticalAssets() public {
		vm.expectRevert(IChainlinkRouter.IdenticalAssets.selector);
		router.query(WETH, WETH);
	}

	function test_query_revertsOnNegativePrice() public {
		vm.mockCall(ETH_USD, abi.encodeCall(AggregatorInterface.latestAnswer, ()), abi.encode(int256(-1)));

		vm.expectRevert(PriceMath.InvalidPrice.selector);
		router.query(WETH, USD);
	}

	function test_query_revertsOnZeroPrice() public {
		vm.mockCall(ETH_USD, abi.encodeCall(AggregatorInterface.latestAnswer, ()), abi.encode(0));

		vm.expectRevert(PriceMath.InvalidPrice.selector);
		router.query(WETH, USD);
	}
}
