// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title FullMath
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Modified from https://github.com/Uniswap/v4-core/blob/main/src/libraries/FullMath.sol
/// @author fomoweth
library FullMath {
    /// @notice Thrown when operation failed due to a division by zero
    error DivisionByZero();

    /// @notice Thrown when operation failed due to an overflow
    error Overflow();

    /// @notice Calculates floor(x*y÷d) with full precision
    /// @dev Throws if result overflows a uint256 or d == 0
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @param d The denominator
    /// @return z The 256-bit result
    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            // Check for division by zero
            if iszero(d) {
                mstore(0x00, 0x23d359a3) // DivisionByZero()
                revert(0x1c, 0x04)
            }

            // Compute the 512-bit result of x * y
            let mm := mulmod(x, y, not(0))
            let p0 := mul(x, y) // Least significant 256 bits of the product
            let p1 := sub(sub(mm, p0), lt(mm, p0)) // Most significant 256 bits of the product

            // Check for overflow
            if iszero(lt(p1, d)) {
                mstore(0x00, 0x35278d12) // Overflow()
                revert(0x1c, 0x04)
            }

            // If upper part is zero, result fits in 256 bits
            switch iszero(p1)
            // Handle overflow cases, 512 by 256 division
            case 0 {
                // Compute remainder using mulmod
                let r := mulmod(x, y, d)
                // Subtract 256-bit value from 512-bit value
                p1 := sub(p1, gt(r, p0))
                p0 := sub(p0, r)
                // Factor powers of two out of denominator
                // This optimization reduces the division complexity
                let t := and(d, sub(0, d))
                d := div(d, t) // Remove powers of two from denominator
                // Compute modular inverse of denominator using Newton-Raphson iteration
                let inv := xor(2, mul(3, d))
                // Six iterations of Newton-Raphson (sufficient for 256-bit numbers)
                inv := mul(inv, sub(2, mul(d, inv))) // 8 bits of precision
                inv := mul(inv, sub(2, mul(d, inv))) // 16 bits
                inv := mul(inv, sub(2, mul(d, inv))) // 32 bits
                inv := mul(inv, sub(2, mul(d, inv))) // 64 bits
                inv := mul(inv, sub(2, mul(d, inv))) // 128 bits
                inv := mul(inv, sub(2, mul(d, inv))) // 256 bits
                // Compute final result: z = (p1 * (2^256 - t) / t + p0 / t) * inv
                z := mul(or(mul(p1, add(div(sub(0, t), t), 1)), div(p0, t)), inv)
            }
            // Handle non-overflow cases, 256 by 256 division
            default { z := div(p0, d) }
        }
    }

    /// @notice Calculates ceil(x*y÷d) with full precision
    /// @dev Throws if result overflows a uint256 or d == 0
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @param d The denominator
    /// @return z The 256-bit result rounded up
    function mulDivRoundingUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        z = mulDiv(x, y, d);
        assembly ("memory-safe") {
            // If there's a remainder, add 1 to round up
            if mulmod(x, y, d) {
                z := add(z, 1)
                // Check for overflow after increment
                if iszero(z) {
                    mstore(0x00, 0x35278d12) // Overflow()
                    revert(0x1c, 0x04)
                }
            }
        }
    }
}
