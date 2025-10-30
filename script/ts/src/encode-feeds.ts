import { existsSync, readFileSync } from "fs";
import { join } from "path";
import { solidityPacked } from "ethers";

import { FeedModel } from "./types";

const main = async () => {
	const chainId = parseInt(process.argv[2] || "1");

	const path = join(__dirname, `../../../config/feeds/${chainId}.json`);

	if (!existsSync(path)) {
		console.error(`Unsupported chain: ${chainId}`);
		process.exit(1);
	}

	const feeds: FeedModel[] = JSON.parse(readFileSync(path, "utf-8"));

	const data = feeds.reduce(
		(acc, { aggregator, base, quote }) =>
			solidityPacked(
				["bytes", "bytes"],
				[acc, solidityPacked(["address", "address", "address"], [aggregator, base, quote])],
			),
		"0x",
	);

	process.stdout.write(data);
};

main();
