import fs from "fs";
import path from "path";

import { CHAINS } from "./constants";
import { FeedMetadata, FeedModel, TokenModel } from "./types";

const main = async () => {
	const argument = process.argv[2];

	const chain = CHAINS.find(({ chainAlias, chainId }) =>
		isNaN(+argument) ? chainAlias === argument : chainId === parseInt(argument)
	);

	if (!chain) {
		console.error(`Unsupported chain: ${argument}`);
		process.exit(1);
	}

	const tokens: TokenModel[] = JSON.parse(
		fs.readFileSync(path.join(__dirname, `../../config/tokens/${chain.chainId}.json`), "utf-8")
	);

	const res = await fetch(chain.rddUrl);
	const data: FeedMetadata[] = await res.json();

	const cached: Set<string> = new Set();

	const feeds: FeedModel[] = data
		.reduce((acc, { decimals, feedType, name: description, path, proxyAddress: aggregator }) => {
			if (!!aggregator && feedType === "Crypto") {
				path = path
					.replace("calc-", "")
					.replace("calculated-", "")
					.replace(" exchangerate", "")
					.replace("-exchange-rate", "");

				const [base, quote] = path.split("-").map((ticker) => {
					if (ticker === "usd") return "0x0000000000000000000000000000000000000348";
					if (ticker === "eth") ticker = "weth";
					if (ticker === "btc") ticker = "wbtc";
					if (ticker === "pol") ticker = "matic";

					return tokens.find(({ symbol }) => symbol.toLowerCase() === ticker)?.address;
				});

				if (!!base && !!quote && base !== quote) {
					const key = `${base}-${quote}`;

					if (!cached.has(key)) {
						cached.add(key);
						return acc.concat({ aggregator, description, decimals, base, quote });
					}
				}
			}

			return acc;
		}, [] as FeedModel[])
		.sort((a, b) => (a.description.toLowerCase() < b.description.toLowerCase() ? -1 : 1));

	fs.writeFileSync(path.join(__dirname, `../../config/feeds/${chain.chainId}.json`), JSON.stringify(feeds, null, 4));

	console.log(`\n${feeds.length} feeds saved\n`);
};

main();
