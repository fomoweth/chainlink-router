import { config } from "dotenv";
import { execSync } from "child_process";
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "fs";
import { dirname, join, resolve } from "path";

import {
	BroadcastTransaction,
	ContractInfo,
	ContractInput,
	Deployment,
	DeploymentHistory,
	DeploymentRecord,
	MultiDeployment,
	Strict,
} from "./types";
import {
	format,
	getChain,
	getChecksumAddress,
	getContractABI,
	getContractPath,
	getProjectName,
	getProjectUrl,
	getProxyAdmin,
	getProxyImplementation,
	getRevision,
	getRpcUrl,
	isAddress,
} from "./utils";

const ROOT = dirname(resolve(process.cwd(), ".."));
const BROADCAST = join(ROOT, "broadcast");
const DEPLOYMENTS = join(ROOT, "deployments");

const PROJECT_URL = getProjectUrl();
const PROJECT_NAME = getProjectName();

config({ path: join(ROOT, ".env"), quiet: true });

interface CLIArguments {
	chain: string;
	scriptName: string;
	forceFlag: boolean;
	skipFlag: boolean;
}

interface HTMLParameters {
	tag: string;
	content?: string;
	attributes?: Record<string, any>;
}

// Modified from https://github.com/0xPolygon/forge-chronicles

const main = async (): Promise<void> => {
	const { chain, scriptName, forceFlag, skipFlag } = validateAndExtractInputs();

	const rpcApiKey = process.env.RPC_API_KEY;
	if (!rpcApiKey) {
		console.error("\nError: Missing API key for RPC provider.\n");
		process.exit(1);
	}

	// Generate Forge artifacts
	prepareArtifacts();

	let json: DeploymentRecord | undefined;

	if (chain === "multi") {
		// Multi deployment: process all chains

		const { deployments } = <MultiDeployment>(
			JSON.parse(readFileSync(join(BROADCAST, "multi", `${scriptName}-latest`, "run.json")!, "utf-8"))
		);

		// Process each chain deployment
		for (const deployment of deployments) {
			const { chain: chainId } = deployment;

			try {
				if (!skipFlag) {
					// Extract and save JSON from deployment data
					json = await processDeployment(deployment, getRpcUrl(chainId, rpcApiKey), forceFlag);
				} else {
					// Use existing JSON file
					console.log(`\nSkipping json extraction for chain ${chainId}, using existing json file\n`);

					const path = join(DEPLOYMENTS, "json", `${chainId}.json`);

					if (existsSync(path)) {
						json = JSON.parse(readFileSync(path, "utf-8"));
					} else {
						console.warn(`\nWarning: ${path} does not exist, skipping chain ${chainId}\n`);
						continue;
					}
				}

				if (!!json) {
					renderAndSaveDeployment(json);
					console.log(`\nSuccessfully processed chain ${chainId}\n`);
				}
			} catch (error) {
				// Continue with other chains instead of failing completely
				console.error(`\nError: processing chain ${chainId}:`, error);
			}
		}

		renderAndSaveIndexPage();
		console.log("\nDeployment index file updated\n");
		console.log("\nMulti-deployment processing completed\n");
	} else {
		// Single deployment: process specific chain

		if (!skipFlag) {
			const data = <Deployment>(
				JSON.parse(readFileSync(join(BROADCAST, scriptName, chain, "run-latest.json")!, "utf-8"))
			);

			json = await processDeployment(data, getRpcUrl(data.chain, rpcApiKey), forceFlag);
		} else {
			console.log("\nSkipping json extraction, using existing json file\n");

			json = JSON.parse(readFileSync(join(DEPLOYMENTS, "json", `${chain}.json`)!, "utf-8"));
		}

		if (!!json) {
			renderAndSaveDeployment(json);
			console.log(`\nSuccessfully processed chain ${chain}\n`);

			renderAndSaveIndexPage();
			console.log("\nDeployment index file updated\n");
		}
	}
};

const processDeployment = async (
	{ chain: chainId, commit, timestamp, transactions }: Deployment,
	rpcUrl: string,
	forceFlag: boolean
): Promise<DeploymentRecord | undefined> => {
	const path = join(DEPLOYMENTS, "json", `${chainId}.json`);

	const directory = dirname(path);
	if (!existsSync(directory)) mkdirSync(directory, { recursive: true });

	const deployment: DeploymentRecord = !!existsSync(path)
		? JSON.parse(readFileSync(path, "utf-8"))
		: { chainId, latest: {}, history: [] };

	if (!!deployment.history.length && deployment.history[0].commit === commit) {
		if (!forceFlag) {
			console.error(`\nError: Commit ${commit} already processed\n`);
			process.exit(1);
		}
	} else {
		forceFlag = false;
	}

	const createTransactions = transactions.reduce((acc: Array<Strict<BroadcastTransaction>>, tx) => {
		if (tx.transactionType === "CREATE" || tx.transactionType === "CREATE2") {
			if (!!tx.contractName) {
				return acc.concat(processProperties({ ...tx, arguments: tx.arguments || [] }));
			}
			console.warn("\nContract name not unique or not found. Skipping.\n");
		}
		return acc;
	}, []);

	const contracts = createTransactions
		.reduce(
			(
				acc: Array<Omit<ContractInfo, "commit" | "timestamp"> & { contractName: string; input: ContractInput }>,
				{ arguments: constructorArguments, contractAddress, contractName, hash },
				idx
			) => {
				if (contractName === "ForgeProxy" || contractName === "TransparentUpgradeableProxy") {
					console.warn(`\nSkipping unexpected proxy: ${contractName} (${contractAddress})\n`);
					return acc;
				}

				for (const { contracts } of deployment.history) {
					if (!!contracts.hasOwnProperty(contractName)) {
						const { address, hash: txHash } = contracts[contractName];
						if (address === contractAddress && txHash === hash) {
							console.warn(`\nSkipping duplicate contract: ${contractName}(${contractAddress})\n`);
							return acc;
						}
					}
				}

				if (!!deployment.latest.hasOwnProperty(contractName)) {
					// CASE: existing upgradeable contract (new implementation)
					if (!!deployment.latest[contractName].proxy) {
						const { address: proxyAddress, hash: proxyHash } = deployment.latest[contractName];

						if (getProxyImplementation(proxyAddress, rpcUrl) !== contractAddress) {
							console.error(`\n${contractName} not upgraded to ${contractAddress}\n`);
							process.exit(1);
						}

						const contract = <ContractInfo>processProperties({
							address: proxyAddress,
							hash: proxyHash,
							proxy: true,
							implementation: contractAddress,
							proxyAdmin: getProxyAdmin(proxyAddress, rpcUrl),
							version: getRevision(proxyAddress, rpcUrl),
						});

						deployment.latest[contractName] = {
							...contract,
							timestamp,
							commit,
						};

						return acc.concat({
							contractName,
							...contract,
							input: { constructor: parseConstructorInputs(contractName, constructorArguments) },
						});
					}
				} else {
					const createTransaction = createTransactions
						.slice(idx + 1)
						.find(
							(tx) =>
								(tx.contractName === "ForgeProxy" ||
									tx.contractName === "TransparentUpgradeableProxy") &&
								getChecksumAddress(tx.arguments[0]) === contractAddress
						);

					// CASE: new upgradeable contract
					if (!!createTransaction) {
						const { contractAddress: proxyAddress, hash: proxyHash } = createTransaction;

						const contract = <ContractInfo>processProperties({
							address: proxyAddress,
							hash: proxyHash,
							implementation: contractAddress,
							proxy: true,
							proxyAdmin: getProxyAdmin(proxyAddress, rpcUrl),
							version: getRevision(proxyAddress, rpcUrl),
						});

						deployment.latest[contractName] = {
							...contract,
							timestamp,
							commit,
						};

						return acc.concat({
							contractName,
							...contract,
							input: {
								constructor: parseConstructorInputs(contractName, constructorArguments),
								initializer: createTransaction.arguments[2],
							},
						});
					}
				}

				// CASE: new & existing non-upgradeable contracts
				const contract = <ContractInfo>processProperties({
					address: contractAddress,
					hash,
					proxy: false,
					version: getRevision(contractAddress, rpcUrl),
				});

				deployment.latest[contractName] = {
					...contract,
					timestamp,
					commit,
				};

				return acc.concat({
					contractName,
					...contract,
					input: { constructor: parseConstructorInputs(contractName, constructorArguments) },
				});
			},
			[]
		)
		.sort((a, b) => (a.contractName.toLowerCase() < b.contractName.toLowerCase() ? -1 : 1))
		.reduce(
			(acc, { contractName, ...rest }) => ({ ...acc, [contractName]: rest }),
			{} as DeploymentHistory["contracts"]
		);

	if (!Object.keys(contracts).length) {
		console.log("\nNo new contracts found.\n");
		return;
	}

	if (!!deployment.history.length && !!forceFlag) deployment.history.shift();

	deployment.history.unshift({ contracts, timestamp, commit });

	deployment.history.sort((a, b) => b.timestamp - a.timestamp);

	deployment.latest = Object.keys(deployment.latest)
		.sort((a, b) => (a.toLowerCase() < b.toLowerCase() ? -1 : 1))
		.reduce((acc, contractName) => ({ ...acc, [contractName]: deployment.latest[contractName] }), {});

	writeFileSync(path, JSON.stringify(deployment, null, 4), "utf-8");

	return deployment;
};

const renderAndSaveIndexPage = (): void => {
	const chainIds = readdirSync(DEPLOYMENTS)
		.reduce((acc: number[], file) => {
			if (!!file.match(/\.md$/) && file !== "index.md") {
				const chainId = parseInt(file.replace(".md", ""));
				if (!isNaN(chainId)) acc.push(chainId);
			}

			return acc;
		}, [])
		.sort((a, b) => a - b);

	let content = `# ${PROJECT_NAME} Deployments\n\n`;
	content += "This repository contains deployment information for the following networks:\n\n";
	content += "| 	Chain ID	| 	Network		|	Deployment Details 	|\n";
	content += "|---------------|---------------|-----------------------|\n";

	chainIds.forEach((chainId) => {
		content += `| ${chainId} | ${getChain(chainId).name} | [View Deployment](./${chainId}.md) |\n`;
	});

	writeFileSync(join(DEPLOYMENTS, "index.md"), content, "utf-8");
};

const renderAndSaveDeployment = ({ chainId, history, latest }: DeploymentRecord): void => {
	const { chainAlias, explorerUrl } = getChain(chainId);
	let content = `# ${format(chainAlias, "display")} Deployment`;

	content += `\n\n### Table of Contents`;
	content += renderTableOfContents(latest, history);

	content += "\n\n## Summary\n";
	content += renderDeploymentSummary(latest, explorerUrl);

	content += `\n\n## Contracts\n\n`;
	content += renderDeploymentDetails(latest, explorerUrl);

	content += `\n\n## Deployment History`;
	content += renderDeploymentHistory(history, explorerUrl);

	writeFileSync(join(DEPLOYMENTS, `${chainId}.md`), content, "utf-8");
	console.log(`\nChain ${chainId} deployment record generated\n`);
};

const renderTableOfContents = (contracts: DeploymentRecord["latest"], history: DeploymentRecord["history"]) => {
	let content = "\n\n-\t[Summary](#summary)";

	content += "\n-\t[Contracts](#contracts)\n\t-\t";
	content += Object.keys(contracts)
		.map((contractName) => `[${format(contractName, "display")}](#${format(contractName, "link")})`)
		.join("\n\t-\t");

	content += `\n-\t[Deployment History](#deployment-history)\n\t-\t`;
	content += history
		.map(
			({ timestamp }) =>
				`[${format(timestamp, "timestamp-long")}](#${format(format(timestamp, "timestamp-long"), "link")})`
		)
		.join("\n\t-\t");

	return content;
};

const renderDeploymentSummary = (contracts: DeploymentRecord["latest"], explorerUrl: string) => {
	const headers: Array<HTMLParameters> = [
		{ tag: "th", content: "Contract" },
		{ tag: "th", content: "Address" },
		{ tag: "th", content: "Version" },
	];

	const rows: Array<Array<HTMLParameters>> = Object.entries(contracts).reduce(
		(acc, [contractName, { address, version }]) =>
			acc.concat([
				[
					{ tag: "td", content: renderAnchor(getContractPath(contractName), contractName) },
					{ tag: "td", content: renderAnchor(`${explorerUrl}/address/${address}`, address) },
					{ tag: "td", content: renderElement({ tag: "code", content: format(version, "version") }) },
				],
			]),
		[headers]
	);

	return renderTable({ rows });
};

const renderDeploymentDetails = (contracts: DeploymentRecord["latest"], explorerUrl: string) => {
	return Object.entries(contracts)
		.map(
			([contractName, contract]) =>
				`### ${format(contractName, "display")!}\n${renderDeploymentDetail(
					contract,
					explorerUrl
				)}${renderImplementationHistory(contract, explorerUrl)}`
		)
		.join("\n\n---\n\n");
};

const renderDeploymentDetail = (
	{ address, commit, hash, implementation, proxyAdmin, timestamp, version }: ContractInfo,
	explorerUrl: string
) => {
	const rows: Array<Array<HTMLParameters>> = [];

	rows.push([
		{ tag: "td", content: "Commit" },
		{
			tag: "td",
			content: renderAnchor(
				PROJECT_URL.concat(`/commit/${commit}`),
				renderElement({ tag: "code", content: commit })
			),
		},
	]);

	rows.push([
		{ tag: "td", content: "Address" },
		{
			tag: "td",
			content: renderAnchor(`${explorerUrl}/address/${address}`, address),
		},
	]);

	if (!!implementation) {
		rows.push([
			{ tag: "td", content: "Implementation" },
			{
				tag: "td",
				content: renderAnchor(`${explorerUrl}/address/${implementation}`, implementation),
			},
		]);
	}

	if (!!proxyAdmin) {
		rows.push([
			{ tag: "td", content: "Proxy Admin" },
			{
				tag: "td",
				content: renderAnchor(`${explorerUrl}/address/${proxyAdmin}`, proxyAdmin),
			},
		]);
	}

	rows.push([
		{ tag: "td", content: "Deployment Transaction" },
		{
			tag: "td",
			content: renderAnchor(`${explorerUrl}/tx/${hash}`, hash),
		},
	]);

	rows.push([
		{ tag: "td", content: "Deployment Date" },
		{
			tag: "td",
			content: renderElement({ tag: "code", content: format(timestamp, "timestamp-long") }),
		},
	]);

	rows.push([
		{ tag: "td", content: "Version" },
		{
			tag: "td",
			content: renderElement({ tag: "code", content: !!version ? `v${version}.0.0` : "N/A" }),
		},
	]);

	return renderTable({ rows });
};

const renderImplementationHistory = ({ commit, hash, implementation, version }: ContractInfo, explorerUrl: string) => {
	if (!implementation) return "";

	return `\n\n<details>\n<summary>Implementation History</summary>${renderTable({
		rows: [
			[
				{ tag: "th", content: "Commit" },
				{ tag: "th", content: "Address" },
				{ tag: "th", content: "Deployment Transaction" },
				{ tag: "th", content: "Version" },
			],
			[
				{
					tag: "td",
					content: renderAnchor(
						`${PROJECT_URL}/commit/${commit}`,
						renderElement({ tag: "code", content: commit })
					),
				},
				{
					tag: "td",
					content: renderAnchor(`${explorerUrl}/address/${implementation}`, implementation),
				},
				{ tag: "td", content: renderAnchor(`${explorerUrl}/tx/${hash}`, hash) },
				{ tag: "td", content: renderElement({ tag: "code", content: format(version, "version") }) },
			],
		],
	})}\n</details>`;
};

const renderDeploymentHistory = (history: DeploymentRecord["history"], explorerUrl: string) => {
	return history.reduce(
		(acc, { commit, contracts, timestamp }) =>
			acc.concat(
				`\n\n#### ${format(timestamp, "timestamp-long")}\n${Object.entries(contracts)
					.map(
						([contractName, contract]) =>
							`\n<details>\n<summary>${renderAnchor(
								getContractPath(contractName),
								contractName
							)}</summary>${renderDeploymentDetail(
								{ commit, timestamp, ...contract },
								explorerUrl
							)}\n</details>`
					)
					.join("\n")}`
			),
		""
	);
};

const renderElement = ({
	tag,
	content,
	attributes,
}: {
	tag: string;
	content?: string;
	attributes?: Record<string, any>;
}): string => {
	return `<${tag
		.concat(
			!!attributes
				? Object.entries(attributes).reduce((acc, [key, value]) => acc.concat(formatAttribute(key, value)), " ")
				: "",
			!!content ? `>${content}</${tag}>` : " />"
		)
		.trim()}`;
};

const renderAnchor = (href: string, text: string) => {
	return renderElement({ tag: "a", content: text, attributes: { href, target: "_blank" } });
};

const renderTable = ({
	caption,
	columns,
	rows,
}: {
	caption?: Pick<HTMLParameters, "content" | "attributes">;
	columns?: {
		colgroup?: Array<HTMLParameters>;
		cols?: Array<HTMLParameters>;
	};
	rows: Array<Array<HTMLParameters>>;
}) => {
	let content = "";

	if (!!caption) content += `\n\t${renderElement({ tag: "caption", ...caption })}`;

	if (!!columns) {
		const { colgroup, cols } = columns;

		if (!!colgroup) {
			content += `\n\t${colgroup.map(renderElement).join("\n\t")}`;
		} else if (!!cols) {
			content += `\n\t<colgroup>\n\t\t${cols.map(renderElement).join("\nt\t\t")}\n\t</colgroup>`;
		} else {
			throw new Error(`Missing parameters for rendering 'colgroup' element`);
		}
	}

	content += rows.reduce(
		(acc, row) => acc.concat(`\n\t<tr>\n\t\t${row.map(renderElement).join("\n\t\t")}\n\t</tr>`),
		""
	);

	return `\n<table>${content}\n</table>`;
};

const formatAttribute = (key: string, value?: any): string => {
	if (value === null || value === undefined) return "";
	if (!!Array.isArray(value)) value = value.join(" ");
	return `${key}="${value.toString().trim()}" `;
};

const parseConstructorInputs = (contractName: string, args: string[] | null): Record<string, any> => {
	const inputs: Record<string, any> = {};

	const constructor = getContractABI(contractName).find(({ type }) => type === "constructor");

	if (!!constructor && !!args) {
		if (constructor.inputs.length !== args.length) {
			console.error("\nError: Couldn't match constructor inputs\n");
			process.exit(1);
		}

		constructor.inputs.forEach((input, index) => {
			const name = format(input.name || index, "argument")!;

			if (input.type === "tuple" && !!input.components) {
				// if input is a mapping, extract individual key value pairs
				inputs[name] = {};

				// trim the brackets and split by comma
				const data = args[index].slice(1, args[index].length - 2).split(", ");

				for (let i = 0; i < input.components.length; i++) {
					inputs[name][format(input.components[i].name || i, "argument")!] = data[i];
				}
			} else {
				inputs[name] = args[index];
			}
		});
	}

	return inputs;
};

const processProperties = <T extends Record<string, any>>(properties: T): Strict<T> => {
	return Object.entries(properties).reduce(
		(acc, [key, value]) =>
			value !== null && value !== undefined
				? { ...acc, [key]: !!isAddress(value) ? getChecksumAddress(value)! : value }
				: acc,
		{} as Strict<T>
	);
};

const prepareArtifacts = (): void => {
	execSync("forge build");
};

const validateAndExtractInputs = (): CLIArguments => {
	const args = process.argv.slice(2);

	let chain = "multi";
	let scriptName = "Deploy.s.sol";
	let forceFlag = false;
	let skipFlag = false;

	for (let i = 0; i < args.length; i++) {
		switch (args[i]) {
			case "-c":
			case "--chain":
				if (i + 1 < args.length && args[i + 1].charAt(0) !== "-") {
					const value = args[i + 1];
					if (value === "multi" || !isNaN(parseInt(value))) {
						chain = value;
						i++;
						break;
					} else {
						console.error("\nError: --chain flag requires either a chain ID number or 'multi'\n");
						process.exit(1);
					}
				} else {
					console.error("\nError: --chain flag requires either a chain ID number or 'multi'\n");
					process.exit(1);
				}

			case "-n":
			case "--name":
				if (i + 1 < args.length && args[i + 1].charAt(0) !== "-") {
					scriptName = args[i + 1];
					if (scriptName && !scriptName.endsWith(".s.sol")) scriptName += ".s.sol";
					i++;
					break;
				} else {
					console.error("\nError: --name flag requires the name of the script to be executed\n");
					process.exit(1);
				}

			case "-f":
			case "--force":
				forceFlag = true;
				break;

			case "-s":
			case "--skip":
				skipFlag = true;
				break;

			default:
				process.exit(1);
		}
	}

	if (!existsSync(join(ROOT, `script/${scriptName}`))) {
		console.error(`\nError: script/${scriptName || "<scriptName>"} does not exist\n`);
		process.exit(1);
	}

	return {
		chain,
		scriptName,
		forceFlag,
		skipFlag,
	};
};

main().catch((error) => {
	console.error("\nFatal error:", error);
	process.exit(1);
});
