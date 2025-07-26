// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {AggregatorInterface} from "src/interfaces/external/AggregatorInterface.sol";
import {ChainlinkRouter, IChainlinkRouter} from "src/ChainlinkRouter.sol";
import {Denominations} from "src/libraries/Denominations.sol";
import {PriceMath} from "src/libraries/PriceMath.sol";
import {BitMap} from "src/types/BitMap.sol";
import {Initializable} from "src/base/Initializable.sol";
import {Ownable} from "src/base/Ownable.sol";
import {FeedConfig} from "src/types/FeedConfig.sol";
import {BaseTest} from "test/shared/env/BaseTest.sol";
import {Chains} from "test/shared/helpers/Chains.sol";
import {SolArray} from "test/shared/helpers/SolArray.sol";

contract ChainlinkRouterTest is Test, BaseTest {
	using Chains for Vm;
	using Denominations for address;

	function setUp() public virtual override {
		super.setUp();

		bytes memory params = abi.encodePacked(
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

		router.register(params);
	}

	function test_chainAgnosticAddressing() public {
		revertToState();

		vm.selectChain(Chains.ETHEREUM, ETHEREUM_FORK_BLOCK);
		address eth = deployRouter(address(this), proxyOwner, bytes32(0));
		assertTrue(eth.code.length != 0);

		vm.selectChain(Chains.OPTIMISM, OPTIMISM_FORK_BLOCK);
		address opt = deployRouter(address(this), proxyOwner, bytes32(0));
		assertTrue(opt.code.length != 0);

		vm.selectChain(Chains.POLYGON, POLYGON_FORK_BLOCK);
		address pol = deployRouter(address(this), proxyOwner, bytes32(0));
		assertTrue(pol.code.length != 0);

		vm.selectChain(Chains.BASE, BASE_FORK_BLOCK);
		address base = deployRouter(address(this), proxyOwner, bytes32(0));
		assertTrue(base.code.length != 0);

		vm.selectChain(Chains.ARBITRUM, ARBITRUM_FORK_BLOCK);
		address arb = deployRouter(address(this), proxyOwner, bytes32(0));
		assertTrue(arb.code.length != 0);

		assertEq(eth, opt);
		assertEq(eth, pol);
		assertEq(eth, base);
		assertEq(eth, arb);
	}

	function test_constructor() public view {
		assertEq(uint256(vm.load(address(logic), INITIALIZED_SLOT)), type(uint64).max);
		assertEq(logic.owner(), address(0));
		assertEq(logic.numAssets(), 0);
	}

	function test_initialize() public view {
		assertEq(router.owner(), address(this));
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
		router.initialize(address(this));
	}

	function test_registerAsset() public {
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

	function test_registerAsset_revertsOnExceededMaxAssets() public {
		vm.expectEmit(true, true, true, true, address(router));

		for (uint256 i = router.numAssets(); i < 256; ++i) {
			address asset = address(uint160(i));
			emit IChainlinkRouter.AssetAdded(asset, i);
			router.registerAsset(asset);
		}

		vm.expectRevert(IChainlinkRouter.ExceededMaxAssets.selector);
		router.registerAsset(LINK);
	}

	function test_registerAsset_revertsOnInvalidAsset() public {
		vm.expectRevert(IChainlinkRouter.InvalidAsset.selector);
		router.registerAsset(address(0));
	}

	function test_registerAsset_revertsIfUnauthorized() public impersonate(unknown) {
		vm.expectRevert(abi.encodeWithSelector(Ownable.UnauthorizedAccount.selector, unknown));
		router.registerAsset(LINK);
	}

	function test_deregisterAsset() public {
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

	function test_deregisterAsset_revertsOnInvalidAsset() public {
		vm.expectRevert(IChainlinkRouter.InvalidAsset.selector);
		router.deregisterAsset(address(0));

		vm.expectRevert(IChainlinkRouter.InvalidAsset.selector);
		router.deregisterAsset(USD);
	}

	function test_deregisterAsset_revertsIfUnauthorized() public impersonate(unknown) {
		vm.expectRevert(abi.encodeWithSelector(Ownable.UnauthorizedAccount.selector, unknown));
		router.deregisterAsset(LINK);
	}

	function test_register() public {
		uint256 initialCount = router.numAssets();

		vm.expectEmit(true, true, true, true, address(router));
		emit IChainlinkRouter.AssetAdded(LINK, initialCount);
		emit IChainlinkRouter.FeedRegistered(LINK_ETH, LINK, WETH);

		router.register(abi.encodePacked(LINK_ETH, LINK, WETH));

		assertEq(router.getAssetId(LINK), initialCount);
		assertEq(router.getAsset(initialCount), LINK);
		assertEq(router.getFeed(LINK, WETH), LINK_ETH);

		emit IChainlinkRouter.FeedRegistered(LINK_USD, LINK, USD);

		router.register(abi.encodePacked(LINK_USD, LINK, USD));

		assertEq(router.getFeed(LINK, USD), LINK_USD);
		assertEq(router.numAssets(), initialCount + 1);
	}

	function test_register_multipleFeeds() public {
		address[] memory feeds = SolArray.addresses(AAVE_ETH, COMP_ETH, LINK_ETH, UNI_ETH);
		address[] memory assets = SolArray.addresses(AAVE, COMP, LINK, UNI);

		uint256 initialCount = router.numAssets();

		vm.expectEmit(true, true, true, true, address(router));

		bytes memory params;
		for (uint256 i; i < feeds.length; ++i) {
			emit IChainlinkRouter.FeedRegistered(feeds[i], assets[i], WETH);
			params = abi.encodePacked(params, feeds[i], assets[i], WETH);
		}

		router.register(params);

		for (uint256 i; i < feeds.length; ++i) {
			assertEq(router.getFeed(assets[i], WETH), feeds[i]);
		}

		assertEq(router.numAssets(), initialCount + assets.length);
	}

	function test_register_all() public {
		revertToState();

		uint256[] memory chainIds = SolArray.uint256s(
			Chains.ETHEREUM,
			Chains.OPTIMISM,
			Chains.POLYGON,
			Chains.BASE,
			Chains.ARBITRUM
		);

		uint256[] memory blockNumbers = SolArray.uint256s(
			ETHEREUM_FORK_BLOCK,
			OPTIMISM_FORK_BLOCK,
			POLYGON_FORK_BLOCK,
			BASE_FORK_BLOCK,
			ARBITRUM_FORK_BLOCK
		);

		for (uint256 i; i < chainIds.length; ++i) {
			vm.selectChain(chainIds[i], blockNumbers[i]);

			deployRouter(address(this), proxyOwner, bytes32(0));

			uint256 initialCount = router.numAssets();
			assertEq(initialCount, 1);

			bytes memory params = runScript("extract", vm.toString(chainIds[i]));
			router.register(params);

			assertGt(router.numAssets(), initialCount);
		}
	}

	function test_register_revertsOnInvalidFeed() public {
		vm.expectRevert(IChainlinkRouter.InvalidFeed.selector);
		router.register(abi.encodePacked(address(0), LINK, WETH));
	}

	function test_register_revertsOnIdenticalAssets() public {
		vm.expectRevert(IChainlinkRouter.IdenticalAssets.selector);
		router.register(abi.encodePacked(LINK_ETH, LINK, LINK));
	}

	function test_register_revertsIfUnauthorized() public impersonate(unknown) {
		vm.expectRevert(abi.encodeWithSelector(Ownable.UnauthorizedAccount.selector, unknown));
		router.register(abi.encodePacked(LINK_ETH, LINK, WETH, LINK_USD, LINK, USD));
	}

	function test_deregister() public {
		router.register(abi.encodePacked(LINK_ETH, LINK, WETH, LINK_USD, LINK, USD));

		uint256 initialCount = router.numAssets();
		uint256 assetId = router.getAssetId(LINK);

		vm.expectEmit(true, true, true, true, address(router));
		emit IChainlinkRouter.FeedDeregistered(LINK, WETH);

		router.deregister(abi.encodePacked(LINK, WETH));

		assertEq(router.getAssetId(LINK), assetId);
		assertEq(router.getAsset(assetId), LINK);
		assertEq(router.getFeed(LINK, WETH), address(0));

		emit IChainlinkRouter.AssetRemoved(LINK, router.getAssetId(LINK));
		emit IChainlinkRouter.FeedDeregistered(LINK, USD);

		router.deregister(abi.encodePacked(LINK, USD));

		assertEq(router.getAssetId(LINK), 0);
		assertEq(router.getAsset(assetId), address(0));
		assertEq(router.getFeed(LINK, USD), address(0));
		assertEq(router.numAssets(), initialCount - 1);
	}

	function test_deregister_multipleFeeds() public {
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
			emit IChainlinkRouter.FeedDeregistered(assets[i], WETH);
			params = abi.encodePacked(params, assets[i], WETH);
		}

		router.deregister(params);

		for (uint256 i; i < assets.length; ++i) {
			assertEq(router.getFeed(assets[i], WETH), address(0));
		}

		assertEq(router.numAssets(), initialCount - assets.length);
	}

	function test_deregister_revertsOnIdenticalAssets() public {
		vm.expectRevert(IChainlinkRouter.IdenticalAssets.selector);
		router.deregister(abi.encodePacked(LINK, LINK));
	}

	function test_deregister_revertsIfUnauthorized() public impersonate(unknown) {
		vm.expectRevert(abi.encodeWithSelector(Ownable.UnauthorizedAccount.selector, unknown));
		router.deregister(abi.encodePacked(LINK, WETH));
	}

	function test_getAssetConfiguration() public view {
		BitMap configuration = router.getAssetConfiguration(USD);
		assertFalse(configuration.isZero());
		assertTrue(configuration.get(router.getAssetId(WETH)));
		assertTrue(configuration.get(router.getAssetId(WBTC)));
		assertTrue(configuration.get(router.getAssetId(USDC)));
		assertTrue(configuration.get(router.getAssetId(USDT)));
	}

	function test_getFeedConfiguration() public view {
		address[] memory feeds = SolArray.addresses(ETH_USD, BTC_USD, USDC_USD, USDT_USD);
		address[] memory assets = SolArray.addresses(WETH, WBTC, USDC, USDT);

		for (uint256 i; i < feeds.length; ++i) {
			FeedConfig configuration = router.getFeedConfiguration(assets[i], USD);
			assertFalse(configuration.isZero());
			assertEq(configuration.feed(), feeds[i]);
			assertEq(configuration.baseId(), router.getAssetId(assets[i]));
			assertEq(configuration.baseDecimals(), assets[i].decimals());
			assertEq(configuration.quoteId(), router.getAssetId(USD));
			assertEq(configuration.quoteDecimals(), 8);
			assertTrue(router.getAssetConfiguration(assets[i]).get(router.getAssetId(USD)));
		}
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
		address[] memory feeds = SolArray.addresses(ETH_USD, BTC_USD, USDC_USD, USDT_USD);
		address[] memory assets = SolArray.addresses(WETH, WBTC, USDC, USDT);

		for (uint256 i; i < feeds.length; ++i) {
			(address[] memory path, uint256 price) = router.query(assets[i], USD);
			uint256 expected = getLatestAnswer(feeds[i]);

			assertEq(path.length, 1);
			assertEq(path[0], feeds[i]);
			assertEq(price, expected);
		}
	}

	function test_query_singleHop_inverted() public view {
		address[] memory feeds = SolArray.addresses(ETH_USD, BTC_USD, USDC_USD, USDT_USD);
		address[] memory assets = SolArray.addresses(WETH, WBTC, USDC, USDT);

		for (uint256 i; i < feeds.length; ++i) {
			(address[] memory path, uint256 price) = router.query(USD, assets[i]);
			uint256 expected = getInverseAnswer(feeds[i], assets[i], USD);

			assertEq(path.length, 1);
			assertEq(path[0], feeds[i]);
			assertEq(price, expected);
		}
	}

	function test_query_2Hops() public view {
		(address[] memory path, uint256 price) = router.query(USDC, WETH);
		uint256 expected = getLatestAnswer(USDC_ETH);

		assertEq(path.length, 2);
		assertEq(path[0], USDC_USD);
		assertEq(path[1], ETH_USD);
		assertApproxEqRelDecimal(price, expected, 0.01e18, 18);
	}

	function test_query_2Hops_inverted() public view {
		(address[] memory path, uint256 price) = router.query(WETH, USDC);
		uint256 expected = getInverseAnswer(USDC_ETH, USDC, WETH);

		assertEq(path.length, 2);
		assertEq(path[0], ETH_USD);
		assertEq(path[1], USDC_USD);
		assertApproxEqRelDecimal(price, expected, 0.01e18, 6);
	}

	function test_query_3Hops() public {
		address[] memory usdFeeds = SolArray.addresses(LINK_USD, AAVE_USD, COMP_USD, UNI_USD);
		address[] memory ethFeeds = SolArray.addresses(LINK_ETH, AAVE_ETH, COMP_ETH, UNI_ETH);
		address[] memory assets = SolArray.addresses(LINK, AAVE, COMP, UNI);

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

		for (uint256 i; i < ethFeeds.length; ++i) {
			(address[] memory path, uint256 price) = router.query(assets[i], USDC);
			uint256 expected = getLatestAnswer(usdFeeds[i]) / 1e2;

			assertEq(path.length, 3);
			assertEq(path[0], ethFeeds[i]);
			assertEq(path[1], ETH_USD);
			assertEq(path[2], USDC_USD);
			assertApproxEqRelDecimal(price, expected, 0.01e18, 6);
		}
	}

	function test_query_3Hops_inverted() public {
		address[] memory usdFeeds = SolArray.addresses(LINK_USD, AAVE_USD, COMP_USD, UNI_USD);
		address[] memory ethFeeds = SolArray.addresses(LINK_ETH, AAVE_ETH, COMP_ETH, UNI_ETH);
		address[] memory assets = SolArray.addresses(LINK, AAVE, COMP, UNI);

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

		for (uint256 i; i < ethFeeds.length; ++i) {
			(address[] memory path, uint256 price) = router.query(USDC, assets[i]);
			uint256 expected = getInverseAnswer(usdFeeds[i], assets[i], USD);

			assertEq(path.length, 3);
			assertEq(path[0], USDC_USD);
			assertEq(path[1], ETH_USD);
			assertEq(path[2], ethFeeds[i]);
			assertApproxEqRelDecimal(price, expected, 0.01e18, assets[i].decimals());
		}
	}

	function test_query_revertsOnNoPath() public {
		vm.expectRevert();
		router.query(LINK, WBTC);
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
