# ChainlinkRouter

> A price oracle router that aggregates and derives price feeds using Chainlink Aggregators

## Overview

ChainlinkRouter is an on-chain oracle routing system that provides dynamic price discovery across token pairs using Chainlink Aggregators.
If a direct price feed doesn’t exist, the router derives the price through intermediate assets using multi-hop pathfinding logic.

### Key Features

-   **Direct and Multi-Hop Price Resolution**
    Automatically finds the shortest feed path between two assets using a breadth-first traversal
-   **Price Derivation Engine**
    Supports derived price computation (A/B = A/C \* C/B), feed inversion, and precision normalization
-   **Bitmap-Based Graph Storage**
    Assets are tracked in a paged bitmap structure for efficient gas usage and scalable pathfinding
-   **Batch Feed and Asset Management**
    Efficiently register or deregister multiple feeds in single transactions

## Deployment

You can checkout the deployment information [here](https://github.com/fomoweth/chainlink-router/blob/main/deployments/index.md)

### Usage

```solidity
// Query ETH/BTC price (may route through USD)
(address[] memory path, uint256 price) = router.query(WETH_ADDRESS, WBTC_ADDRESS);

// Check if direct feed exists
bool hasDirect = router.queryFeed(WETH_ADDRESS, USD_ADDRESS) != address(0);

// Get asset connections
BitMap connections = router.getAssetConfiguration(WETH_ADDRESS);
```

### Registration Example

```solidity
// https://en.wikipedia.org/wiki/ISO_4217
address USD_ADDRESS = 0x0000000000000000000000000000000000000348;

// Register multiple feeds in batch
bytes memory params = abi.encodePacked(
    ETH_USD_FEED, WETH_ADDRESS, USD_ADDRESS,	// ETH/USD
    BTC_USD_FEED, WBTC_ADDRESS, USD_ADDRESS,	// BTC/USD
    USDC_USD_FEED, USDC_ADDRESS, USD_ADDRESS,	// USDC/USD
	ETH_BTC_FEED, WETH_ADDRESS, WBTC_ADDRESS,	// ETH/BTC
	BTC_ETH_FEED, WBTC_ADDRESS, WETH_ADDRESS,	// BTC/ETH
	USDC_ETH_FEED, USDC_ADDRESS, WETH_ADDRESS	// USDC/ETH
);

router.register(params);

// Deregister multiple feeds in batch
bytes memory params = abi.encodePacked(
    WETH_ADDRESS, USD_ADDRESS,		// ETH/USD
    WBTC_ADDRESS, USD_ADDRESS,		// BTC/USD
    USDC_ADDRESS, USD_ADDRESS,   	// USDC/USD
	WETH_ADDRESS, WBTC_ADDRESS,		// ETH/BTC
	WBTC_ADDRESS, WETH_ADDRESS,		// BTC/ETH
	USDC_ADDRESS, WETH_ADDRESS		// USDC/ETH
);

router.deregister(params);
```

### Routing Examples

#### Direct Path (1 hop)

```
ETH ──[ETH/USD Feed]──> USD
Price: 8000 USD per ETH
```

#### Two-hop Path

```
ETH ──[ETH/USD]──> USD ──[USD/BTC]──> BTC
Calculation: ETH/USD ÷ BTC/USD = ETH/BTC
Result: 8000 ÷ 160000 = 0.05 BTC per ETH
```

#### Complex Multi-hop

```
TokenA ──[A/USD]──> USD ──[USD/ETH]──> ETH ──[ETH/B]──> TokenB
Automatic pathfinding through optimal intermediate assets
```

## API Reference

### Core Functions

#### `query(address base, address quote)`

Finds optimal price path and calculates final price.

**Parameters:**

-   `base` - Base asset address to price
-   `quote` - Quote asset address to price against

**Returns:**

-   `path` - Array of feed addresses used in routing
-   `answer` - Calculated price with proper decimal scaling

#### `queryFeed(address base, address quote)`

Gets feed address for asset pair (bidirectional search).

**Returns:**

-   `feed` - Chainlink aggregator address or `address(0)` if not found

#### `register(bytes calldata params)`

Registers multiple feeds in batch format.

**Parameters:**

-   `params` - Packed bytes: `[feed1][base1][quote1][feed2][base2][quote2]...`

#### `deregister(bytes calldata params)`

Deregisters multiple feeds in batch format and cleans up unused assets.

**Parameters:**

-   `params` - Packed bytes: `[base1][quote1][base2][quote2]...`

#### `registerAsset(address asset)`

Registers a single asset in the system.

**Parameters:**

-   `asset` - Address of the asset to register

#### `deregisterAsset(address asset)`

Deregisters an asset and removes all associated feeds.

**Parameters:**

-   `asset` - Address of the asset to deregister

**Note:** USD cannot be deregistered as it serves as the primary reference currency.

### View Functions

| Function                                            | Description             | Returns      |
| --------------------------------------------------- | ----------------------- | ------------ |
| `getFeed(address base, address quote)`              | Feed address            | `address`    |
| `getFeedConfiguration(address base, address quote)` | Complete feed config    | `FeedConfig` |
| `getAsset(uint256 id)`                              | Asset address from ID   | `address`    |
| `getAssetConfiguration(address asset)`              | Asset's connections     | `BitMap`     |
| `getAssetId(address asset)`                         | Asset ID from address   | `uint256`    |
| `numAssets()`                                       | Total registered assets | `uint256`    |

## Testing

### Run Test Suite

```bash
# Run all tests
forge test

# Run with detailed traces
forge test -vvv

# Run with gas reporting
forge test --gas-report

# Run specific test file
forge test --match-path test/ChainlinkRouter.t.sol
```

### Known Limitations

-   Maximum 256 assets due to BitMap constraints
-   Dependent on Chainlink feed reliability and freshness
-   Gas costs increase with routing complexity
-   Requires manual feed registration and maintenance

## FAQ

<details>
<summary><strong>How does multi-hop routing work?</strong></summary>

The router uses a breadth-first search algorithm to find the shortest path between assets. It maintains a graph of asset relationships using BitMaps, allowing O(1) queries for connected assets. When no direct feed exists, it automatically discovers intermediate assets through BitMap intersection operations.

</details>

<details>
<summary><strong>What happens if a Chainlink feed fails?</strong></summary>

The router will revert the transaction with detailed error information. It validates that all prices are positive and that feeds are accessible. Consider implementing circuit breakers or fallback mechanisms in your integration.

</details>

<details>
<summary><strong>How are decimal places handled?</strong></summary>

The router automatically normalizes decimal places across different assets. Each feed stores metadata about base and quote asset decimals, and the PriceMath library handles conversions to ensure consistent pricing regardless of underlying asset decimal configurations.

</details>

## Resources

-   [Chainlink Price Feeds Doc](https://docs.chain.link/data-feeds/price-feeds)
-   [Chainlink Data Feeds](https://data.chain.link/feeds)

## Author

-   [@fomoweth](https://github.com/fomoweth)
