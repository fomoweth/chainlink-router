import { ChainId } from "../constants";

type RequiredKeys<T> = { [K in keyof T]-?: {} extends Pick<T, K> ? never : K }[keyof T];

export type Strict<T> = { [K in RequiredKeys<T>]: NonNullable<T[K]> };

export interface Chain {
	chainId: ChainId;
	chainAlias: string;
	name: string;
	networkType: "mainnet" | "testnet";
	explorerUrl: string;
	rddUrl: string;
	rpcUrl: {
		alchemy: string;
		infura: string;
	};
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
	pair: Array<string>;
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

export interface ContractArtifact {
	abi: Array<JsonFragment>;
	bytecode: string;
	metadata: Record<string, any>;
}

export interface JsonFragmentType {
	readonly name?: string;
	readonly type: string;
	readonly internalType?: string;
	readonly components?: ReadonlyArray<JsonFragmentType>;
	readonly indexed?: boolean;
}

export interface JsonFragment {
	readonly name?: string;
	readonly type: "constructor" | "error" | "event" | "fallback" | "function" | "struct";
	readonly stateMutability: "payable" | "nonpayable" | "view" | "pure";
	readonly inputs: ReadonlyArray<JsonFragmentType> | [];
	readonly outputs?: ReadonlyArray<JsonFragmentType>;
	readonly anonymous?: boolean;
}

export interface MultiDeployment {
	deployments: Array<Deployment>;
	timestamp: number;
}

export interface Deployment {
	transactions: Array<BroadcastTransaction>;
	receipts: Array<BroadcastReceipt>;
	libraries: Array<any>;
	pending: Array<any>;
	returns: Record<string, any>;
	timestamp: number;
	chain: number;
	commit: string;
}

export interface DeploymentHistory {
	contracts: Record<string, Omit<ContractInfo, "commit" | "timestamp"> & { input: ContractInput }>;
	timestamp: number;
	commit: string;
}

export interface DeploymentRecord {
	chainId: number;
	latest: Record<string, ContractInfo>;
	history: Array<DeploymentHistory>;
}

export interface ContractInfo {
	address: string;
	hash: string;
	implementation?: string;
	proxy: boolean;
	proxyAdmin?: string;
	version?: string;
	commit: string;
	timestamp: number;
}

export interface ContractInput {
	constructor: Record<string, any>;
	initializer?: string;
}

export type TransactionType = "CREATE" | "CREATE2" | "CALL";

export interface BroadcastTransaction {
	hash: string;
	transactionType: TransactionType;
	contractName: string | null;
	contractAddress: string;
	function: string | null;
	arguments: Array<string> | null;
	transaction: {
		from: string;
		to?: string | null;
		gas: string;
		value: string;
		input: string;
		nonce: string;
		chainId: string;
	};
	additionalContracts: Array<{
		transactionType: TransactionType;
		address: string;
		initCode: string;
	}>;
	isFixedGasLimit: boolean;
}

export interface BroadcastReceipt {
	status: "0x0" | "0x1";
	cumulativeGasUsed: string;
	logs: Array<{
		address: string;
		topics: Array<string>;
		data: string;
		blockHash: string;
		blockNumber: string;
		blockTimestamp?: string;
		transactionHash: string;
		transactionIndex: string;
		logIndex: string;
		removed: boolean;
	}>;
	logsBloom: string;
	type: string;
	transactionHash: string;
	transactionIndex: string;
	blockHash: string;
	blockNumber: string;
	gasUsed: string;
	effectiveGasPrice: string;
	from: string;
	to: string;
	contractAddress: string | null;
}
