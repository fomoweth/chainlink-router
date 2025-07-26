export enum ChainId {
	ETHEREUM = 1,
	SEPOLIA = 11155111,
	OPTIMISM = 10,
	OPTIMISM_SEPOLIA = 11155420,
	BNB = 56,
	BNB_TESTNET = 97,
	UNICHAIN = 130,
	UNICHAIN_SEPOLIA = 1301,
	POLYGON = 137,
	POLYGON_AMOY = 80002,
	FANTOM = 250,
	FANTOM_TESTNET = 4002,
	BASE = 8453,
	BASE_SEPOLIA = 84532,
	ARBITRUM = 42161,
	ARBITRUM_SEPOLIA = 421614,
	AVALANCHE = 43114,
	AVALANCHE_FUJI = 43113,
	SCROLL = 534352,
	SCROLL_SEPOLIA = 534351,
	LINEA = 59144,
	LINEA_SEPOLIA = 59141,
}

export interface Chain {
	chainId: ChainId;
	chainAlias: string;
	name: string;
	networkType: "mainnet" | "testnet";
	rddUrl: string;
	queryString: string;
	tags?: ("default" | "smartData" | "rates" | "streams")[];
}

export interface Docs {
	assetClass?: string;
	assetSubClass?: string;
	assetName?: string;
	blockchainName?: string;
	clicProductName?: string;
	deliveryChannelCode?: string;
	marketHours?: string;
	baseAsset?: string;
	baseAssetClic?: string;
	quoteAsset?: string;
	quoteAssetClic?: string;
	underlyingAsset?: string;
	underlyingAssetClic?: string;
	feedCategory?: string;
	feedType?: string;
	hidden?: boolean;
	porAuditor?: string;
	porSource?: string;
	porType?: string;
	productType?: string;
	productTypeCode?: string;
	productSubType?: string;
	shutdownDate?: string;
}

export interface FeedMetadata {
	compareOffchain: string;
	contractAddress: string;
	contractType: string;
	contractVersion: number;
	decimalPlaces: number | null;
	decimals: number;
	ens: null | string;
	feedId: null | string;
	formatDecimalPlaces: number | null;
	healthPrice: string;
	heartbeat: number;
	history: null | boolean;
	multiply: string;
	name: string;
	pair: string[];
	path: string;
	proxyAddress: string;
	secondaryProxyAddress?: string;
	threshold: number;
	valuePrefix: string;
	assetName: string;
	feedCategory: string;
	feedType: string;
	docs: Docs;
	transmissionsAccount: null | string;
}

export interface FeedModel {
	aggregator: string;
	description: string;
	decimals: number;
	base: string;
	quote: string;
}

export interface TokenModel {
	address: string;
	symbol: string;
	decimals: number;
}
