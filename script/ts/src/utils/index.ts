import { execSync } from "child_process";
import { existsSync, readdirSync, readFileSync } from "fs";
import { dirname, join, resolve } from "path";

import { ChainId, CHAINS, ERC1967_ADMIN_SLOT, ERC1967_IMPLEMENTATION_SLOT } from "../constants";
import { Chain, ContractArtifact } from "../types";

export const format = (
	value: any,
	option: "argument" | "contract" | "display" | "link" | "timestamp-long" | "timestamp-short" | "version"
): string | undefined => {
	if (typeof value === "number" || typeof value === "bigint") value = value.toString();
	if (!value || typeof value !== "string") return;

	switch (option) {
		case "argument":
			return value.replace(/^-+|-+$/g, "");

		case "contract":
			return value.replace(/([A-Z])/g, " $1").replace(/[_-]/g, " ");

		case "display":
			return value
				.replace(/([a-z])([A-Z])/g, "$1 $2")
				.split(/[\s\-_]+/)
				.filter((word) => word.length > 0)
				.map((word) => word.charAt(0).toUpperCase().concat(word.slice(1).toLowerCase()))
				.join(" ");

		case "link":
			return value
				.replace(/([a-z])([A-Z])/g, "$1-$2")
				.replace(/[\s_]+/g, "-")
				.toLowerCase()
				.replace(/-+/g, "-")
				.replace(/^-+|-+$/g, "");

		case "timestamp-long":
		case "timestamp-short":
			if (!!isNaN(+value)) throw new Error(`Timestamp must be a number: ${value}`);
			return new Date(+value * 1000)
				.toLocaleDateString("en-US", {
					month: option.replace(/^timestamp-/i, "") as "long" | "short",
					day: "numeric",
					year: "numeric",
				})
				.replace(",", "");

		case "version":
			return !!value ? value.concat(".0.0") : "N/A";

		default:
			throw new Error(`Unsupported prettify option: ${option}`);
	}
};

export const getChain = (chainId: number): Chain => {
	const chain = CHAINS.find((chain) => chain.chainId === chainId);
	if (!chain) throw new Error(`Unsupported chain ID: ${chainId}`);

	return chain;
};

export const getContractABI = (contractName: string): ContractArtifact["abi"] => {
	const root = dirname(resolve(process.cwd(), ".."));
	const path = join(root, "out", `${contractName}.sol`, `${contractName}.json`);
	if (!existsSync(path)) throw new Error(`Contract ABI not found for: ${contractName}`);

	return (<ContractArtifact>JSON.parse(readFileSync(path, "utf-8"))).abi;
};

export const getContractPath = (
	contractName: string,
	option: { baseDir: string; maxDepth: number } = { baseDir: "src", maxDepth: 5 }
): string => {
	if (contractName === "ForgeProxy" || contractName === "ForgeProxyAdmin") {
		return execSync("git remote get-url origin | cut -d '/' -f 1-4", { encoding: "utf-8" })
			.trim()
			.concat(`/proxy-forge/blob/main/src/${contractName}.sol`);
	}

	const pattern = new RegExp(`^${contractName}\\.sol$`, "i");
	const root = dirname(resolve(process.cwd(), ".."));

	const searchDirectory = (baseDir: string, depth: number): string | undefined => {
		if (depth > option.maxDepth) return;

		try {
			const entries = readdirSync(join(root, baseDir), { withFileTypes: true });
			for (const entry of entries) {
				if (!!entry.isFile() && !!pattern.test(entry.name)) {
					return join(baseDir, entry.name);
				} else if (!!entry.isDirectory()) {
					const path = searchDirectory(join(baseDir, entry.name), depth + 1);
					if (!!path) return path;
				}
			}
		} catch (error) {
			// Directory not accessible, skip
		}
	};

	const path = searchDirectory(option.baseDir, 0);
	if (!path) throw new Error(`No contract files found for: ${contractName}`);

	return `${getProjectUrl()}/blob/main/${path}`;
};

export const getChecksumAddress = (address?: string | null): string | undefined => {
	try {
		if (!!isAddress(address)) return execSync(`cast to-check-sum-address ${address}`, { encoding: "utf-8" }).trim();
	} catch (e) {}
};

export const getProxyAdmin = (proxy: string, rpcUrl: string): string | undefined => {
	try {
		return execSync(
			`cast storage ${proxy} ${ERC1967_ADMIN_SLOT} --rpc-url ${rpcUrl} | cast parse-bytes32-address`,
			{
				encoding: "utf-8",
			}
		)
			.trim()
			.replaceAll('"', "");
	} catch (e) {}
};

export const getProxyImplementation = (proxy: string, rpcUrl: string): string | undefined => {
	try {
		return execSync(
			`cast storage ${proxy} ${ERC1967_IMPLEMENTATION_SLOT} --rpc-url ${rpcUrl} | cast parse-bytes32-address`,
			{ encoding: "utf-8" }
		)
			.trim()
			.replaceAll('"', "");
	} catch (e) {}
};

export const getRevision = (address: string, rpcUrl: string): string | undefined => {
	try {
		return execSync(`cast call ${address} 'REVISION()(uint256)' --rpc-url ${rpcUrl}`, { encoding: "utf-8" })
			.trim()
			.replaceAll('"', "");
	} catch (e) {}
};

export const getProjectName = (): string => {
	return format(
		execSync("git remote get-url origin | cut -d '/' -f 5 | cut -d '.' -f 1", { encoding: "utf-8" }).trim(),
		"display"
	)!;
};

export const getProjectUrl = (): string => {
	return execSync("git remote get-url origin", { encoding: "utf-8" })
		.trim()
		.replace(/\.git$/, "");
};

export const getRpcUrl = (chainId: number, apiKey: string): string => {
	const rpcUrl = process.env[`RPC_${ChainId[chainId]}`];
	if (!rpcUrl) throw new Error(`Unsupported chain ID: ${chainId}`);

	return rpcUrl.replace("${RPC_API_KEY}", apiKey);
};

export const isAddress = (value: any): value is `0x${string}` => {
	return typeof value === "string" && !!value.match(/^(0x)?([0-9A-Fa-f]{40})$/);
};

export const isTransactionHash = (value: any): value is `0x${string}` => {
	return typeof value === "string" && !!value.match(/^(0x)?([0-9A-Fa-f]{64})$/);
};

export const parseChainId = (chainId: number | string): ChainId => {
	if (!!isNaN(+chainId)) throw new Error(`Invalid chain ID: ${chainId}`);
	return ChainId[ChainId[+chainId] as keyof typeof ChainId];
};
