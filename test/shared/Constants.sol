// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

abstract contract Constants {
	bytes32 internal constant INITIALIZED_SLOT = 0xeb0c2ce5f191d27e756051385ba4f8f2e0c18127de8ff7207a5891e3b49bb400;

	address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	address internal constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;
	address internal constant USD = 0x0000000000000000000000000000000000000348;

	address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address internal constant ETH_BTC = 0xAc559F25B1619171CbC396a50854A3240b6A4e99;
	address internal constant ETH_USD = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

	address internal constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
	address internal constant WSTETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address internal constant STETH_ETH = 0x86392dC19c0b719886221c78AB11eb8Cf5c52812;
	address internal constant STETH_USD = 0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8;

	address internal constant EETH = 0x5c9C449BbC9a6075A2c061dF312a35fd1E05fF22;
	address internal constant WEETH = 0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee;
	address internal constant WEETH_ETH = 0x5c9C449BbC9a6075A2c061dF312a35fd1E05fF22;
	address internal constant WEETH_USD = 0xf112aF6F0A332B815fbEf3Ff932c057E570b62d3;

	address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
	address internal constant BTC_ETH = 0xdeb288F737066589598e9214E782fa5A8eD689e8;
	address internal constant BTC_USD = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;

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
}
