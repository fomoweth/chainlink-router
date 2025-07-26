import fs from "fs";
import path from "path";

enum ChainId {
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

interface Chain {
	chainId: ChainId;
	chainAlias: string;
	name: string;
	networkType: "mainnet" | "testnet";
	rddUrl: string;
	queryString: string;
	tags?: ("default" | "smartData" | "rates" | "streams")[];
}

interface Docs {
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

interface FeedMetadata {
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

interface FeedModel {
	aggregator: string;
	description: string;
	decimals: number;
	base: string;
	quote: string;
}

interface TokenModel {
	address: string;
	symbol: string;
	decimals: number;
}

const CHAINS: Chain[] = [
	{
		chainId: ChainId.ARBITRUM,
		chainAlias: "arbitrum",
		name: "Arbitrum One",
		networkType: "mainnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-ethereum-mainnet-arbitrum-1.json",
		queryString: "arbitrum-mainnet",
		tags: ["streams", "smartData"],
	},
	{
		chainId: ChainId.ARBITRUM_SEPOLIA,
		chainAlias: "arbitrum-sepolia",
		name: "Arbitrum One Sepolia",
		networkType: "testnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-ethereum-testnet-sepolia-arbitrum-1.json",
		queryString: "arbitrum-sepolia",
		tags: ["rates", "streams"],
	},
	{
		chainId: ChainId.AVALANCHE,
		chainAlias: "avalanche",
		name: "Avalanche",
		networkType: "mainnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-avalanche-mainnet.json",
		queryString: "avalanche-mainnet",
		tags: ["smartData", "streams"],
	},
	{
		chainId: ChainId.AVALANCHE_FUJI,
		chainAlias: "avalanche-fuji",
		name: "Avalanche Fuji",
		networkType: "testnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-avalanche-fuji-testnet.json",
		queryString: "avalanche-fuji",
		tags: ["smartData", "rates", "streams"],
	},
	{
		chainId: ChainId.BASE,
		chainAlias: "base",
		name: "Base",
		networkType: "mainnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-ethereum-mainnet-base-1.json",
		queryString: "base-mainnet",
		tags: ["smartData"],
	},
	{
		chainId: ChainId.BASE_SEPOLIA,
		chainAlias: "base-sepolia",
		name: "Base Sepolia",
		networkType: "testnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-ethereum-testnet-sepolia-base-1.json",
		queryString: "base-sepolia",
	},
	{
		chainId: ChainId.BNB,
		chainAlias: "bnb",
		name: "BNB Chain",
		networkType: "mainnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-bsc-mainnet.json",
		queryString: "bnb-mainnet",
		tags: ["smartData"],
	},
	{
		chainId: ChainId.BNB_TESTNET,
		chainAlias: "bnb-testnet",
		name: "BNB Chain Testnet",
		networkType: "testnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-bsc-testnet.json",
		queryString: "bnb-testnet",
	},
	{
		chainId: ChainId.ETHEREUM,
		chainAlias: "ethereum",
		name: "Ethereum",
		networkType: "mainnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-mainnet.json",
		queryString: "ethereum-mainnet",
		tags: ["smartData"],
	},
	{
		chainId: ChainId.SEPOLIA,
		chainAlias: "sepolia",
		name: "Sepolia Testnet",
		networkType: "testnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-ethereum-testnet-sepolia.json",
		queryString: "ethereum-sepolia",
		tags: ["rates"],
	},
	{
		chainId: ChainId.FANTOM,
		chainAlias: "fantom",
		name: "Fantom",
		networkType: "mainnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-fantom-mainnet.json",
		queryString: "fantom-mainnet",
	},
	{
		chainId: ChainId.FANTOM_TESTNET,
		chainAlias: "fantom-testnet",
		name: "Fantom Testnet",
		networkType: "testnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-fantom-testnet.json",
		queryString: "fantom-testnet",
	},
	{
		chainId: ChainId.LINEA,
		chainAlias: "linea",
		name: "Linea",
		networkType: "mainnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-ethereum-mainnet-linea-1.json",
		queryString: "linea-mainnet",
	},
	{
		chainId: ChainId.OPTIMISM,
		chainAlias: "optimism",
		name: "Optimism",
		networkType: "mainnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-ethereum-mainnet-optimism-1.json",
		queryString: "optimism-mainnet",
	},
	{
		chainId: ChainId.OPTIMISM_SEPOLIA,
		chainAlias: "optimism-sepolia",
		name: "Optimism Sepolia",
		networkType: "testnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-ethereum-testnet-sepolia-optimism-1.json",
		queryString: "optimism-sepolia",
	},
	{
		chainId: ChainId.POLYGON,
		chainAlias: "polygon",
		name: "Polygon",
		networkType: "mainnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-matic-mainnet.json",
		queryString: "polygon-mainnet",
		tags: ["smartData"],
	},
	{
		chainId: ChainId.POLYGON_AMOY,
		chainAlias: "polygon-amoy",
		name: "Polygon Amoy",
		networkType: "testnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-polygon-testnet-amoy.json",
		queryString: "polygon-amoy",
		tags: ["smartData"],
	},
	{
		chainId: ChainId.SCROLL,
		chainAlias: "scroll",
		name: "Scroll",
		networkType: "mainnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-ethereum-mainnet-scroll-1.json",
		queryString: "scroll-mainnet",
		tags: ["smartData"],
	},
	{
		chainId: ChainId.SCROLL_SEPOLIA,
		chainAlias: "scroll-sepolia",
		name: "Scroll Sepolia",
		networkType: "testnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-ethereum-testnet-sepolia-scroll-1.json",
		queryString: "scroll-sepolia",
	},
	{
		chainId: ChainId.UNICHAIN_SEPOLIA,
		chainAlias: "unichain-sepolia",
		name: "Unichain Sepolia",
		networkType: "testnet",
		rddUrl: "https://reference-data-directory.vercel.app/feeds-ethereum-testnet-sepolia-unichain-1.json",
		queryString: "unichain-sepolia",
	},
];

const main = async () => {
	const chain = CHAINS.find((chain) =>
		isNaN(+process.argv[2])
			? chain.chainAlias === process.argv[2]
			: chain.chainId === parseInt(process.argv[2])
	)!;

	const tokens: TokenModel[] = JSON.parse(
		fs.readFileSync(path.join(__dirname, "../../config/tokens", `${chain.chainId}.json`), {
			encoding: "utf8",
		})
	);

	const res = await fetch(chain.rddUrl);
	const data: FeedMetadata[] = await res.json();

	const feedsMap: { [key: string]: FeedModel } = data.reduce((acc, feed) => {
		if (!!feed.proxyAddress && feed.feedType === "Crypto") {
			const path = feed.path
				.replace("calc-", "")
				.replace("calculated-", "")
				.replace(" exchangerate", "")
				.replace("-exchange-rate", "");

			const [baseAsset, quoteAsset] = path.split("-").map((ticker) => {
				if (ticker === "usd") return "0x0000000000000000000000000000000000000348";
				if (ticker === "eth") ticker = "weth";
				if (ticker === "btc") ticker = "wbtc";
				if (ticker === "pol") ticker = "matic";

				return tokens.find(({ symbol }) => symbol.toLowerCase() === ticker)?.address;
			});

			if (!!baseAsset && !!quoteAsset) {
				const key = `${baseAsset}-${quoteAsset}`;

				if (!acc[key]) {
					return {
						...acc,
						[key]: {
							aggregator: feed.proxyAddress,
							description: feed.name,
							decimals: feed.decimals,
							base: baseAsset,
							quote: quoteAsset,
						},
					};
				}
			}
		}

		return acc;
	}, {} as { [key: string]: FeedModel });

	const feeds: FeedModel[] = Object.values(feedsMap).sort((a, b) =>
		a.description.toLowerCase() < b.description.toLowerCase() ? -1 : 1
	);

	fs.writeFileSync(
		path.join(__dirname, "../../config/feeds", `${chain.chainId}.json`),
		JSON.stringify(feeds, null, 4)
	);

	console.log(`\n${feeds.length} feeds saved\n`);
};

main();
