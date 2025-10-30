// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {FeedConfig, toFeedConfig} from "src/types/FeedConfig.sol";

contract FeedConfigTest is Test {
    function test_fuzz_toFeedConfig(address feed, uint8 baseId, uint8 baseDecimals, uint8 quoteId, uint8 quoteDecimals)
        public
        pure
    {
        FeedConfig config = toFeedConfig(feed, baseId, baseDecimals, quoteId, quoteDecimals);
        assertEq(config.feed(), feed);
        assertEq(config.baseId(), baseId);
        assertEq(config.baseDecimals(), baseDecimals);
        assertEq(config.quoteId(), quoteId);
        assertEq(config.quoteDecimals(), quoteDecimals);
    }
}
