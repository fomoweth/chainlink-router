import fs from "fs";
import path from "path";
import { ethers } from "ethers";

import { FeedModel } from "./types";

const main = async () => {
	const chainId = parseInt(process.argv[2] || "1");

	const filePath = path.join(__dirname, `../../config/feeds/${chainId}.json`);

	if (!fs.existsSync(filePath)) {
		console.error(`Unsupported chain: ${chainId}`);
		process.exit(1);
	}

	const feeds: FeedModel[] = JSON.parse(fs.readFileSync(filePath, "utf-8"));

	const data = feeds.reduce((acc, { aggregator, base, quote }) => {
		const packed = ethers.solidityPacked(["address", "address", "address"], [aggregator, base, quote]);

		return ethers.solidityPacked(["bytes", "bytes"], [acc, packed]);
	}, "0x");

	process.stdout.write(data);
};

main();
