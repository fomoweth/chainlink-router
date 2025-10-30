# Chainlink Router

> An on-chain oracle router that aggregates and derives prices across Chainlink price feeds — embodying the philosophy “derive, not depend.”

## Table of Contents

-   [Overview](#overview)
-   [Key Features](#key-features)
-   [Architecture](#architecture)
    -   [Architectural Decisions and Design Principles](#architectural-decisions-and-design-principles)
    -   [Project Structure](#project-structure)
    -   [Core Components](#core-components)
        -   [ChainlinkRouter](#chainlinkrouter)
        -   [Libraries](#libraries)
        -   [Custom Types](#custom-types)
        -   [TypeScript Tooling Ecosystem](#typescript-tooling-ecosystem)
-   [Deployments](#deployments)
-   [Usage](#usage)
    -   [Installation](#installation)
    -   [Quick Examples](#quick-examples)
        -   [Routing Queries](#routing-queries)
        -   [Direct Path Routing](#direct-path-routing)
        -   [Automatic Multi-hop Routing](#automatic-multi-hop-routing)
        -   [Solidity Examples](#solidity-examples)
    -   [Scripting](#scripting)
        -   [Deploy](#deploy)
        -   [Feed Registration](#feed-registration)
        -   [TypeScript Utilities](#typescript-utilities)
    -   [Testing](#testing)
-   [API Reference](#api-reference)
    -   [Query & Pricing](#query--pricing)
    -   [System Management](#system-management-owner-only)
    -   [View Functions](#view-functions)
    -   [Known Limitations](#known-limitations)
-   [Resources](#resources)

## Overview

**ChainlinkRouter** is an on-chain oracle routing system that provides dynamic price discovery across token pairs using **Chainlink Aggregators**.  
If a direct price feed doesn’t exist, the router derives the price through intermediate assets using multi-hop path-finding logic.

At its core, **ChainlinkRouter** follows a design philosophy — **“derive, not depend.”**  
Rather than relying on a single price feed, it **derives** prices across multiple connected feeds, ensuring complete price coverage even for non-direct or exotic pairs.

## Key Features

-   **ERC-7201 Storage Pattern**: Namespaced storage for proxy upgrade compatibility
-   **Direct and Multi-Hop Price Resolution**: Automatically finds the shortest feed path using breadth-first traversal
-   **Price Derivation Engine**: Supports derived computation (A/B = A/C × C/B), feed inversion, and precision normalization
-   **Bitmap-Based Graph Storage**: Tracks assets in a paged bitmap structure for efficient, gas-optimized lookups
-   **Batch Feed and Asset Management**: Register or deregister multiple feeds within a single transaction

## Architecture

### Architectural Decisions and Design Principles

The ChainlinkRouter architecture was guided by the principle of **derive, not depend** — ensuring that price discovery remains deterministic, decentralized, and fully composable across connected Chainlink feeds.

-   **Gas Optimization Focus**:

    -   Assembly-optimized bitmap operations for minimal runtime overhead
    -   Packed structs to reduce slot usage in persistent storage
    -   Batch-oriented feed management to minimize repeated state writes

-   **Scalability Considerations**:

    -   256-asset limit designed for efficient bitmap indexing and path resolution
    -   Maximum 4-hop traversal depth to balance accuracy and gas efficiency
    -   Lazy cleanup mechanisms to minimize gas impact on deregistration

-   **Security & Reliability**:
    -   Strict input validation for feed and asset registration
    -   Positive-only price validation to prevent inverted feed corruption
    -   Automatic dependency cleanup on feed removal to maintain referential integrity

### Project Structure

```text
chainlink-router/
├── config/
│   ├── feeds/...
│   └── tokens/...
├── deployments/...
├── script/
│   ├── ...
│   ├── Deploy.s.sol
│   ├── Register.s.sol
│   └── ts/
│       └── src/
│           ├── ...
│           ├── encode-feeds.ts
│           ├── extract.ts
│           └── fetch-feeds.ts
├── src/
│   ├── base/
│   │   ├── Initializable.sol
│   │   └── Ownable.sol
│   ├── interfaces/
│   │   ├── external
│   │   │   └── AggregatorInterface.sol
│   │   └── IChainlinkRouter.sol
│   ├── libraries/
│   │   ├── BytesParser.sol
│   │   ├── Denominations.sol
│   │   ├── FullMath.sol
│   │   └── PriceMath.sol
│   ├── types/
│   │   ├── BitMap.sol
│   │   └── FeedConfig.sol
│   └── ChainlinkRouter.sol
└── test/
    ├── ...
    └── ChainlinkRouter.t.sol
```

### Core Components

#### ChainlinkRouter

The centerpiece contract that implements a sophisticated price routing engine.

#### Libraries

-   **BytesParser**: Efficient batch parameter parsing for feed registration
-   **PriceMath**: Price inversion, derivation, and decimal normalization

#### Custom Types

-   **BitMap**: Custom 256-bit bitmap with assembly-optimized operations
-   **FeedConfig**: Packed struct containing feed metadata (160-bit address + 96-bit config)

#### TypeScript Tooling Ecosystem

Utilities in `script/ts/`:

-   **Feed Management**: `fetch-feeds.ts` pulls live Chainlink data
-   **Data Encoding**: `encode-feeds.ts` prepares batch registration parameters
-   **Deployment Extraction**: `extract.ts` generates deployment documentation from broadcast results

## Deployments

ChainlinkRouter is deployed at `0xbB4a04e5F24127440fA933343F2b34f309AebdDe` on [Ethereum](https://etherscan.io/address/0xbB4a04e5F24127440fA933343F2b34f309AebdDe), [Optimism](https://optimistic.etherscan.io/address/0xbB4a04e5F24127440fA933343F2b34f309AebdDe), [Base](https://basescan.org/address/0xbB4a04e5F24127440fA933343F2b34f309AebdDe), and [Arbitrum One](https://arbiscan.io/address/0xbB4a04e5F24127440fA933343F2b34f309AebdDe).

You can check out the deployment information [here](https://github.com/fomoweth/chainlink-router/blob/main/deployments/index.md).

## Usage

### Installation

```bash
# Clone the repository
git clone https://github.com/fomoweth/chainlink-router.git

# Install dependencies and build the project
cd chainlink-router && forge install && forge build

# Install NPM dependencies
cd script/ts && npm install
```

Create a `.env` file:

```bash
# Populate your environment variables following the `.env.example`
cp .env.example .env
```

### Quick Examples

#### Routing Queries

Use `cast` to query real-time prices and routing paths directly from the deployed router:

```bash
cast call <ROUTER_ADDRESS> \
"query(address,address)(address[],uint256)" \
<BASE_ADDRESS> \
<QUOTE_ADDRESS> \
--rpc-url <RPC_URL>
```

#### Direct Path Routing

Example: `ETH` → `BTC`

```bash
source .env

cast call 0xbB4a04e5F24127440fA933343F2b34f309AebdDe \
"query(address,address)(address[],uint256)" \
0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 \
0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599 \
--rpc-url $RPC_ETHEREUM
```

Output:

```
path: [0xAc559F25B1619171CbC396a50854A3240b6A4e99]
price: 3536665 (0.03536665 BTC per ETH)
```

#### Automatic Multi-hop Routing

When no direct path exists, the router constructs a composite price route by chaining intermediate reference feeds such as `USD` or `ETH`.

```
Base ──[Base/USD]──> USD ──[USD/Quote]──> Quote
Base/Quote = (Base/USD) ÷ (Quote/USD)

Base ──[Base/ETH]──> ETH ──[ETH/Quote]──> Quote
Base/Quote = (Base/ETH) ÷ (Quote/ETH)
```

Example: `LINK` → `USD` → `USDC`

```bash
cast call 0xbB4a04e5F24127440fA933343F2b34f309AebdDe \
"query(address,address)(address[],uint256)" \
0x514910771AF9Ca656af840dff83E8264EcF986CA \
0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 \
--rpc-url $RPC_ETHEREUM
```

Output:

```
path: [0x76F8C9E423C228E83DCB11d17F0Bd8aEB0Ca01bb, 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6]
price: 17929238 (17.929238 USDC per LINK)
```

The router deterministically discovers composite price paths by linking intermediary reference feeds, ensuring complete price derivation coverage across all connected assets.

```
Base ──[Base/USD]──> USD ──[USD/ETH]──> ETH ──[ETH/Quote]──> Quote
Base/Quote = (Base/USD) × (USD/ETH) × (ETH/Quote)
```

This routing logic ensures complete price discovery by leveraging existing Chainlink feed connectivity between reference assets, powered by a **bitmap-based breadth-first traversal** engine.

#### Solidity Examples

Routing Queries:

```solidity
// Query ETH/BTC price (may route through USD)
(address[] memory path, uint256 price) = router.query(WETH_ADDRESS, WBTC_ADDRESS);

// Check if direct feed exists
bool hasDirect = router.queryFeed(WETH_ADDRESS, WBTC_ADDRESS) != address(0);

// Get asset connections
BitMap connections = router.getAssetConfiguration(WETH_ADDRESS);
```

Feed Registration:

```solidity
// https://en.wikipedia.org/wiki/ISO_4217
address USD_ADDRESS = 0x0000000000000000000000000000000000000348;

// Register multiple feeds in batch
bytes memory params = abi.encodePacked(
    ETH_USD_FEED, WETH_ADDRESS, USD_ADDRESS,    // ETH/USD
    BTC_USD_FEED, WBTC_ADDRESS, USD_ADDRESS,	// BTC/USD
    USDC_USD_FEED, USDC_ADDRESS, USD_ADDRESS,	// USDC/USD
	ETH_BTC_FEED, WETH_ADDRESS, WBTC_ADDRESS,	// ETH/BTC
	BTC_ETH_FEED, WBTC_ADDRESS, WETH_ADDRESS,	// BTC/ETH
	USDC_ETH_FEED, USDC_ADDRESS, WETH_ADDRESS	// USDC/ETH
);

router.register(params);

// Deregister multiple feeds in batch
bytes memory params = abi.encodePacked(
    WETH_ADDRESS, USD_ADDRESS,  // ETH/USD
    WBTC_ADDRESS, USD_ADDRESS,	// BTC/USD
    USDC_ADDRESS, USD_ADDRESS,  // USDC/USD
	WETH_ADDRESS, WBTC_ADDRESS,	// ETH/BTC
	WBTC_ADDRESS, WETH_ADDRESS,	// BTC/ETH
	USDC_ADDRESS, WETH_ADDRESS	// USDC/ETH
);

router.deregister(params);
```

### Scripting

#### Deploy

Deploy **ChainlinkRouter** across multiple networks (as defined in your `.env`):

```bash
forge script \
script/Deploy.s.sol:Deploy \
--multi \
--slow \
--broadcast \
--verify
```

#### Feed Registration

Register all Chainlink feeds defined in `config/feeds/`:

```bash
forge script \
script/Register.s.sol:Register \
--broadcast \
--chain <CHAIN>
```

#### TypeScript Utilities

The TypeScript scripts located under `script/ts/src/` streamline encoding, feed syncing, and deployment documentation.

##### Encode Feed Registration Parameters

```bash
cd script/ts && npx ts-node src/encode-feeds.ts
```

##### Fetch Live Feed Metadata

```bash
cd script/ts && npx ts-node src/fetch-feeds.ts
```

##### Extract Deployment Details

```bash
cd script/ts && npx ts-node src/extract.ts
```

### Testing

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/ChainlinkRouter.t.sol
```

## API Reference

The **ChainlinkRouter** exposes a set of view and management functions for price discovery, feed registration, and asset graph introspection.

### Query & Pricing

```solidity
function query(address base, address quote) external view returns (address[] memory path, uint256 answer);
```

Finds the optimal path and computes the derived price between `base` and `quote` using breadth-first traversal.

**Input Parameters**

| Name  | Type      | Description                    |
| ----- | --------- | ------------------------------ |
| base  | `address` | The address of the base asset  |
| quote | `address` | The address of the quote asset |

**Return Values**

| Name   | Type        | Description                                                    |
| ------ | ----------- | -------------------------------------------------------------- |
| path   | `address[]` | The ordered array of the aggregators used for price derivation |
| answer | `uint256`   | The final price (normalized decimals)                          |

```solidity
function queryFeed(address base, address quote) external view returns (address feed);
```

Retrieves the Chainlink aggregator address for a given asset pair (bidirectional lookup).

**Input Parameters**

| Name  | Type      | Description                    |
| ----- | --------- | ------------------------------ |
| base  | `address` | The address of the base asset  |
| quote | `address` | The address of the quote asset |

**Return Values**

| Name | Type      | Description                                                         |
| ---- | --------- | ------------------------------------------------------------------- |
| feed | `address` | The address of the Chainlink Aggregator, `address(0)` if not exists |

---

### System Management (Owner-Only)

```solidity
function register(bytes calldata params) external payable;
```

Registers multiple feeds and automatically adds new assets if not exists.

**Input Parameters**

| Name   | Type    | Description                              |
| ------ | ------- | ---------------------------------------- |
| params | `bytes` | Packed bytes of `[feed][base][quote]...` |

```solidity
function deregister(bytes calldata params) external payable;
```

Deregisters multiple feeds and automatically cleans up unused assets.

**Input Parameters**

| Name   | Type    | Description                        |
| ------ | ------- | ---------------------------------- |
| params | `bytes` | Packed bytes of `[base][quote]...` |

```solidity
function registerAsset(address asset) external payable;
```

Manually adds a new asset to the graph. Automatically called during feed registration.

**Input Parameters**

| Name  | Type      | Description              |
| ----- | --------- | ------------------------ |
| asset | `address` | The address of the asset |

```solidity
function deregisterAsset(address asset) external payable;
```

Removes an asset and its associated feeds. `USD` **cannot be deregistered**, as it serves as the reference asset.

**Input Parameters**

| Name  | Type      | Description              |
| ----- | --------- | ------------------------ |
| asset | `address` | The address of the asset |

---

### View Functions

```solidity
function getFeed(address base, address quote) external view returns (address);
```

Returns the address of the associated feed for an asset pair.

**Input Parameters**

| Name  | Type      | Description                    |
| ----- | --------- | ------------------------------ |
| base  | `address` | The address of the base asset  |
| quote | `address` | The address of the quote asset |

**Return Values**

| Type      | Description                             |
| --------- | --------------------------------------- |
| `address` | The address of the Chainlink Aggregator |

```solidity
function getFeedConfiguration(address base, address quote) external view returns (FeedConfig);
```

Returns the feed configuration for an asset pair.

**Input Parameters**

| Name  | Type      | Description                    |
| ----- | --------- | ------------------------------ |
| base  | `address` | The address of the base asset  |
| quote | `address` | The address of the quote asset |

**Return Values**

| Type                   | Description                                            |
| ---------------------- | ------------------------------------------------------ |
| `FeedConfig (uint256)` | The packed feed configuration containing feed metadata |

```solidity
function getAsset(uint256 id) external view returns (address);
```

Returns the address of an asset associated with the given ID.

**Input Parameters**

| Name | Type      | Description                        |
| ---- | --------- | ---------------------------------- |
| id   | `uint256` | The unique identifier of the asset |

**Return Values**

| Type      | Description                                     |
| --------- | ----------------------------------------------- |
| `address` | The address of the asset associated with the ID |

```solidity
function getAssetConfiguration(address asset) external view returns (BitMap);
```

Returns the bitmap representation of an asset’s connected price feeds.

**Input Parameters**

| Name  | Type      | Description              |
| ----- | --------- | ------------------------ |
| asset | `address` | The address of the asset |

**Return Values**

| Type               | Description                              |
| ------------------ | ---------------------------------------- |
| `BitMap (uint256)` | The bitmap representing connected assets |

```solidity
function getAssetId(address asset) external view returns (uint256);
```

Returns the unique identifier for an asset.

**Input Parameters**

| Name  | Type      | Description              |
| ----- | --------- | ------------------------ |
| asset | `address` | The address of the asset |

**Return Values**

| Type      | Description                                 |
| --------- | ------------------------------------------- |
| `uint256` | The unique identifier assigned to the asset |

```solidity
function numAssets() external view returns (uint256);
```

Returns the total number of registered assets.

**Return Values**

| Type      | Description                                                             |
| --------- | ----------------------------------------------------------------------- |
| `uint256` | The total number of assets currently registered in the system (max 256) |

---

### Known Limitations

-   Maximum 256 assets due to BitMap constraints
-   Dependent on Chainlink feed reliability and freshness
-   Gas costs increase with routing complexity
-   Requires manual feed registration and maintenance

## Resources

-   [Chainlink Data Feeds](https://data.chain.link/feeds)
-   [Chainlink Price Feeds Doc](https://docs.chain.link/data-feeds/price-feeds)
-   [Getting a different price denomination](https://docs.chain.link/data-feeds/using-data-feeds#getting-a-different-price-denomination)
